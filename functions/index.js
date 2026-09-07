/**
 * 토스페이먼츠 결제 승인 + 수강 배정 Cloud Function (v1, Node 20)
 *
 * 문서용 테스트 시크릿 키(기본값): test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R
 * 실제 상점 키로 반드시 교체하세요.
 *   firebase functions:config:set toss.secret="YOUR_SECRET_KEY"
 */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const https = require("https");

admin.initializeApp();

const DEFAULT_TEST_SECRET = "test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R";

function getTossSecret() {
  try {
    const cfg = functions.config();
    if (cfg.toss && cfg.toss.secret) return cfg.toss.secret;
  } catch (_) {}
  return process.env.TOSS_SECRET_KEY || DEFAULT_TEST_SECRET;
}

function tossConfirm({ secret, paymentKey, orderId, amount }) {
  const body = JSON.stringify({ paymentKey, orderId, amount });
  const authHeader =
    "Basic " + Buffer.from(secret + ":").toString("base64");

  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: "api.tosspayments.com",
        path: "/v1/payments/confirm",
        method: "POST",
        headers: {
          Authorization: authHeader,
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(body),
        },
      },
      (res) => {
        let raw = "";
        res.on("data", (chunk) => (raw += chunk));
        res.on("end", () => {
          let json = {};
          try {
            json = JSON.parse(raw || "{}");
          } catch (_) {}
          resolve({ ok: res.statusCode >= 200 && res.statusCode < 300, status: res.statusCode, body: json });
        });
      }
    );
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

exports.confirmTossPayment = functions
  .region("asia-northeast3")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }

    const { paymentKey, orderId, amount } = data || {};
    if (!paymentKey || !orderId || amount == null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "paymentKey, orderId, amount가 필요합니다."
      );
    }

    const amountNum = Number(amount);
    if (!Number.isFinite(amountNum) || amountNum <= 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "결제 금액이 올바르지 않습니다."
      );
    }

    const db = admin.firestore();
    const paymentRef = db.collection("payments").doc(orderId);
    const paymentSnap = await paymentRef.get();

    if (!paymentSnap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "주문 정보를 찾을 수 없습니다."
      );
    }

    const payment = paymentSnap.data();
    if (payment.userId !== context.auth.uid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "본인 주문만 승인할 수 있습니다."
      );
    }

    if (payment.status === "paid") {
      return {
        ok: true,
        message: "이미 결제 완료된 주문입니다.",
        alreadyPaid: true,
      };
    }

    if (Number(payment.amount) !== amountNum) {
      await paymentRef.update({
        status: "failed",
        failReason: "금액 불일치",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      throw new functions.https.HttpsError(
        "failed-precondition",
        "결제 금액이 주문 금액과 일치하지 않습니다."
      );
    }

    const secret = getTossSecret();
    const tossRes = await tossConfirm({
      secret,
      paymentKey,
      orderId,
      amount: amountNum,
    });
    const tossBody = tossRes.body || {};

    if (!tossRes.ok) {
      await paymentRef.update({
        status: "failed",
        failReason: tossBody.message || tossBody.code || "승인 실패",
        paymentKey,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      throw new functions.https.HttpsError(
        "aborted",
        tossBody.message || "토스 결제 승인에 실패했습니다."
      );
    }

    const courseId = payment.courseId;
    const totalSessions = payment.totalSessions || 8;
    const userId = payment.userId;

    const existing = await db
      .collection("enrollments")
      .where("userId", "==", userId)
      .get();

    let enrollmentRef = null;
    for (const doc of existing.docs) {
      if (doc.data().courseId === courseId) {
        enrollmentRef = doc.ref;
        break;
      }
    }

    const enrollmentPayload = {
      userId,
      email: payment.email || "",
      memberName: payment.memberName || "",
      courseId,
      isActive: true,
      totalSessions,
      isPaid: true,
      paidAmount: amountNum,
      paymentNote: "토스페이먼츠 자동결제",
      nativeTeacherId: payment.nativeTeacherId || "",
      nativeTeacherName: payment.nativeTeacherName || "",
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (enrollmentRef) {
      const prev = (await enrollmentRef.get()).data() || {};
      const completed = Number(prev.completedSessions || 0);
      await enrollmentRef.update({
        ...enrollmentPayload,
        completedSessions: completed,
        remainingSessions: Math.max(0, totalSessions - completed),
      });
    } else {
      await db.collection("enrollments").add({
        ...enrollmentPayload,
        completedSessions: 0,
        remainingSessions: totalSessions,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await paymentRef.update({
      status: "paid",
      paymentKey,
      method: tossBody.method || "CARD",
      tossResponse: {
        status: tossBody.status,
        approvedAt: tossBody.approvedAt || null,
        method: tossBody.method || null,
      },
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      awaitingServerConfirm: false,
    });

    if (payment.nativeTeacherId) {
      await db.collection("members").doc(userId).set(
        {
          nativeTeacherId: payment.nativeTeacherId || "",
          nativeTeacherName: payment.nativeTeacherName || "",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    return { ok: true, message: "결제가 완료되었고 수강이 배정되었습니다." };
  });
