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
const crypto = require("crypto");

admin.initializeApp();

const DEFAULT_TEST_SECRET = "test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R";
const DEADLINE_WEEKS_PER_SESSION = 2;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

function toJsDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === "function") return value.toDate();
  return null;
}

function startOfKstDay(date) {
  const kst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  return new Date(
    Date.UTC(kst.getUTCFullYear(), kst.getUTCMonth(), kst.getUTCDate()) -
      9 * 60 * 60 * 1000
  );
}

function addDays(date, days) {
  return new Date(date.getTime() + days * MS_PER_DAY);
}

function expiresAtFromStart(start, totalSessions) {
  const total = Math.max(0, Number(totalSessions) || 0);
  return addDays(startOfKstDay(start), total * DEADLINE_WEEKS_PER_SESSION * 7);
}

function remainingDeadlineWeeks(expiresAt, now) {
  const leftDays = Math.floor(
    (startOfKstDay(expiresAt).getTime() - startOfKstDay(now).getTime()) /
      MS_PER_DAY
  );
  if (leftDays < 0) return 0;
  return Math.floor((leftDays + 6) / 7);
}

function isoWeekKeyKst(date) {
  const kst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  const d = new Date(
    Date.UTC(kst.getUTCFullYear(), kst.getUTCMonth(), kst.getUTCDate())
  );
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const weekNo = Math.ceil(((d - yearStart) / MS_PER_DAY + 1) / 7);
  return d.getUTCFullYear() + "-" + String(weekNo).padStart(2, "0");
}

function kstWeekRange(now) {
  const today = startOfKstDay(now);
  const kst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  const day = kst.getUTCDay();
  const mondayOffset = day === 0 ? -6 : 1 - day;
  const monday = addDays(today, mondayOffset);
  const sundayEnd = addDays(monday, 7);
  return { monday, sundayEnd };
}

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
      nativeTeacherUid: payment.nativeTeacherUid || "",
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (enrollmentRef) {
      const prev = (await enrollmentRef.get()).data() || {};
      const completed = Number(prev.completedSessions || 0);
      const payload = {
        ...enrollmentPayload,
        completedSessions: completed,
        remainingSessions: Math.max(0, totalSessions - completed),
      };
      if (!prev.expiresAt) {
        const start = toJsDate(prev.createdAt) || new Date();
        payload.expiresAt = admin.firestore.Timestamp.fromDate(
          expiresAtFromStart(start, totalSessions)
        );
      }
      await enrollmentRef.update(payload);
    } else {
      await db.collection("enrollments").add({
        ...enrollmentPayload,
        completedSessions: 0,
        remainingSessions: totalSessions,
        expiresAt: admin.firestore.Timestamp.fromDate(
          expiresAtFromStart(new Date(), totalSessions)
        ),
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
          nativeTeacherUid: payment.nativeTeacherUid || "",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    return { ok: true, message: "결제가 완료되었고 수강이 배정되었습니다." };
  });

async function assertOwner(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "로그인이 필요합니다."
    );
  }
  const snap = await admin
    .firestore()
    .collection("admins")
    .doc(context.auth.uid)
    .get();
  if (!snap.exists) {
    throw new functions.https.HttpsError("permission-denied", "권한이 없습니다.");
  }
  const data = snap.data() || {};
  if (data.isActive === false) {
    throw new functions.https.HttpsError("permission-denied", "권한이 없습니다.");
  }
  const role = data.role;
  if (role && role !== "owner") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "메인 관리자만 강사 비밀번호를 설정할 수 있습니다."
    );
  }
}

function authErrorCode(err) {
  return (err && (err.code || (err.errorInfo && err.errorInfo.code))) || "";
}

/// 기존 강사에게 로그인 비밀번호를 만들거나 바꾼다.
/// Auth 계정이 없으면 강사 문서 id와 같은 uid로 계정을 다시 만든다.
exports.setTeacherPassword = functions
  .region("asia-northeast3")
  .https.onCall(async (data, context) => {
    await assertOwner(context);

    const teacherUid = (data && data.teacherUid ? String(data.teacherUid) : "").trim();
    const password = data && data.password ? String(data.password) : "";
    if (!teacherUid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "강사 정보가 없습니다."
      );
    }
    if (password.length < 6) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "비밀번호는 6자 이상으로 설정해주세요."
      );
    }
    if (teacherUid === context.auth.uid) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "메인 관리자 비밀번호는 여기서 바꾸지 않습니다."
      );
    }

    const db = admin.firestore();
    const adminRef = db.collection("admins").doc(teacherUid);
    const adminSnap = await adminRef.get();
    if (!adminSnap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "강사 계정을 찾을 수 없습니다."
      );
    }
    const teacher = adminSnap.data() || {};
    if (teacher.role !== "teacher") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "서브 강사만 비밀번호를 설정할 수 있습니다."
      );
    }
    const email = String(teacher.email || "").trim();
    const name = String(teacher.name || "").trim();
    if (!email || !email.includes("@")) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "강사 이메일이 없습니다."
      );
    }

    const payload = {
      email,
      password,
      displayName: name || email,
      emailVerified: true,
      disabled: teacher.isActive === false,
    };

    try {
      await admin.auth().getUser(teacherUid);
      await admin.auth().updateUser(teacherUid, payload);
    } catch (err) {
      const code = authErrorCode(err);
      if (code !== "auth/user-not-found") {
        throw new functions.https.HttpsError(
          "internal",
          "비밀번호 설정에 실패했습니다."
        );
      }
      try {
        await admin.auth().createUser({ uid: teacherUid, ...payload });
      } catch (createErr) {
        const createCode = authErrorCode(createErr);
        if (createCode !== "auth/email-already-exists") {
          console.error("createUser 실패", createErr);
          throw new functions.https.HttpsError(
            "internal",
            "로그인 계정을 만들지 못했습니다."
          );
        }
        const existing = await admin.auth().getUserByEmail(email);
        if (existing.uid === teacherUid) {
          await admin.auth().updateUser(teacherUid, payload);
        } else {
          const otherAdmin = await db.collection("admins").doc(existing.uid).get();
          if (otherAdmin.exists) {
            throw new functions.https.HttpsError(
              "already-exists",
              "이 이메일은 다른 계정에 이미 사용 중입니다."
            );
          }
          await admin.auth().deleteUser(existing.uid);
          await admin.auth().createUser({ uid: teacherUid, ...payload });
        }
      }
    }

    await adminRef.set(
      {
        hasLoginPassword: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { ok: true };
  });

function publicTeacherProfileId(teacherUid, data) {
  const existing = String((data && data.nativeProfileId) || "");
  if (existing && existing.indexOf("native_temp_") !== 0) return existing;
  if (!data || data.role !== "teacher") return "native_owner_gi";
  return "native_" + teacherUid;
}

function resolveBookingOffer(data, isOwner) {
  const raw = String((data && data.bookingOffer) || "");
  if (raw === "both" || raw === "coteach" || raw === "off") return raw;
  if (data && (Object.prototype.hasOwnProperty.call(data, "selectableAtCheckout") ||
      Object.prototype.hasOwnProperty.call(data, "acceptsCoTeaching"))) {
    const checkout = data.selectableAtCheckout !== false;
    const coteach = data.acceptsCoTeaching !== false;
    if (!checkout && !coteach) return "off";
    if (!checkout) return "coteach";
    return "both";
  }
  return isOwner ? "coteach" : "both";
}

/// 수강생 강사 선택 화면용. admins는 수강생이 직접 읽지 못하므로 서버에서 공개 프로필만 내려준다.
exports.listSelectableTeachers = functions
  .region("asia-northeast3")
  .https.onCall(async () => {
    const db = admin.firestore();
    const snap = await db.collection("admins").get();
    const teachers = [];

    for (const doc of snap.docs) {
      const data = doc.data() || {};
      if (data.isActive === false) continue;
      const name = String(data.name || "").trim();
      if (!name) continue;
      const id = publicTeacherProfileId(doc.id, data);
      const isOwner = data.role !== "teacher";
      const bookingOffer = resolveBookingOffer(data, isOwner);
      teachers.push({
        id,
        name,
        nationality: String(data.nationality || ""),
        intro: String(data.intro || ""),
        photoUrl: String(data.photoUrl || ""),
        accountUid: doc.id,
        isOwner,
        bookingOffer,
        selectableAtCheckout: bookingOffer === "both",
        acceptsCoTeaching: bookingOffer === "both" || bookingOffer === "coteach",
      });

      db.collection("native_teacher_accounts")
        .doc(id)
        .set(
          {
            teacherUid: doc.id,
            name,
            email: String(data.email || ""),
            nationality: String(data.nationality || ""),
            intro: String(data.intro || ""),
            photoUrl: String(data.photoUrl || ""),
            isActive: data.isActive !== false,
            bookingOffer,
            selectableAtCheckout: bookingOffer === "both",
            acceptsCoTeaching:
              bookingOffer === "both" || bookingOffer === "coteach",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        )
        .catch((err) => console.error("native profile sync", id, err));
    }

    teachers.sort((a, b) => {
      if (a.isOwner && !b.isOwner) return -1;
      if (!a.isOwner && b.isOwner) return 1;
      return String(a.name).localeCompare(String(b.name));
    });

    return { teachers };
  });

function getSmsConfig() {
  try {
    const cfg = functions.config();
    if (cfg.sms && cfg.sms.key && cfg.sms.secret && cfg.sms.from) {
      return {
        apiKey: String(cfg.sms.key),
        apiSecret: String(cfg.sms.secret),
        from: String(cfg.sms.from).replace(/[^0-9]/g, ""),
      };
    }
  } catch (_) {}
  const apiKey = process.env.SOLAPI_API_KEY || "";
  const apiSecret = process.env.SOLAPI_API_SECRET || "";
  const from = (process.env.SOLAPI_FROM || "").replace(/[^0-9]/g, "");
  if (apiKey && apiSecret && from) {
    return { apiKey, apiSecret, from };
  }
  return null;
}

function normalizePhone(raw) {
  let value = String(raw || "").replace(/[^0-9]/g, "");
  if (value.startsWith("82") && value.length >= 12) {
    value = "0" + value.slice(2);
  }
  return value;
}

function isMobilePhone(raw) {
  return /^01[016789]\d{7,8}$/.test(normalizePhone(raw));
}

function formatBookingTime(time) {
  const parts = String(time || "").trim().split(":");
  const hour = parseInt(parts[0], 10);
  if (Number.isNaN(hour)) return String(time || "").trim();
  const minute = String(parts[1] || "00").padStart(2, "0");
  const period = hour >= 12 ? "PM" : "AM";
  let hour12 = hour % 12;
  if (hour12 === 0) hour12 = 12;
  return `${hour12}:${minute} ${period}`;
}

function formatLessonWhen(data) {
  const days = ["일", "월", "화", "수", "목", "금", "토"];
  let date = data && data.date && data.date.toDate ? data.date.toDate() : new Date();
  const kst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  const y = kst.getUTCFullYear();
  const m = String(kst.getUTCMonth() + 1).padStart(2, "0");
  const d = String(kst.getUTCDate()).padStart(2, "0");
  const weekday = days[kst.getUTCDay()];
  const time = formatBookingTime((data && data.time) || "");
  return `${y}.${m}.${d} (${weekday}) ${time}`.trim();
}

function solapiAuth(apiKey, apiSecret) {
  const date = new Date().toISOString();
  const salt = crypto.randomBytes(16).toString("hex");
  const signature = crypto
    .createHmac("sha256", apiSecret)
    .update(date + salt)
    .digest("hex");
  return `HMAC-SHA256 apiKey=${apiKey}, date=${date}, salt=${salt}, signature=${signature}`;
}

function sendSms({ to, text }) {
  const cfg = getSmsConfig();
  if (!cfg) {
    console.log("SMS skipped: Solapi 설정이 없습니다.");
    return Promise.resolve({ skipped: true });
  }
  const body = JSON.stringify({
    message: {
      to: normalizePhone(to),
      from: cfg.from,
      text,
    },
  });
  const auth = solapiAuth(cfg.apiKey, cfg.apiSecret);

  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: "api.solapi.com",
        path: "/messages/v4/send",
        method: "POST",
        headers: {
          Authorization: auth,
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
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({ ok: true, body: json });
          } else {
            console.error("SMS 전송 실패", res.statusCode, json);
            resolve({ ok: false, status: res.statusCode, body: json });
          }
        });
      }
    );
    req.on("error", (err) => {
      console.error("SMS 요청 오류", err);
      resolve({ ok: false, error: String(err) });
    });
    req.write(body);
    req.end();
  });
}

async function writeNotification({ userId, title, body, type, bookingId }) {
  if (!userId) return;
  await admin.firestore().collection("notifications").add({
    userId,
    title,
    body,
    type,
    bookingId: bookingId || "",
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function memberPhone(userId, fallback) {
  if (isMobilePhone(fallback)) return normalizePhone(fallback);
  if (!userId) return "";
  const snap = await admin.firestore().collection("members").doc(userId).get();
  const phone = snap.exists ? String((snap.data() || {}).phone || "") : "";
  return isMobilePhone(phone) ? normalizePhone(phone) : "";
}

async function teacherPhone(teacherUid) {
  if (!teacherUid) return "";
  const snap = await admin.firestore().collection("admins").doc(teacherUid).get();
  const phone = snap.exists ? String((snap.data() || {}).phone || "") : "";
  return isMobilePhone(phone) ? normalizePhone(phone) : "";
}

exports.onWeekBookingCreated = functions
  .region("asia-northeast3")
  .firestore.document("week_bookings/{bookingId}")
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const teacherUid = String(data.teacherId || data.nativeTeacherUid || "");
    const when = formatLessonWhen(data);
    const student = String(data.memberName || data.email || "수강생");
    const title = "새 수업 예약";
    const body = `${student}님이 ${when} 화상수업을 신청했습니다. 스케줄에서 확인해 주세요.`;
    if (teacherUid) {
      await writeNotification({
        userId: teacherUid,
        title,
        body,
        type: "booking_requested",
        bookingId: context.params.bookingId,
      });
      const phone = await teacherPhone(teacherUid);
      if (phone) {
        await sendSms({
          to: phone,
          text: `[글림교육] ${student}님의 ${when} 수업 예약이 들어왔습니다. 스케줄에서 확인해 주세요.`,
        });
      }
    }
  });

function scheduledAtFromBooking(data) {
  if (data && data.scheduledAt && typeof data.scheduledAt.toDate === "function") {
    return data.scheduledAt.toDate();
  }
  const date = data && data.date && data.date.toDate ? data.date.toDate() : null;
  if (!date) return null;
  const parts = String((data && data.time) || "00:00").split(":");
  const hour = parseInt(parts[0], 10);
  const minute = parseInt(parts[1], 10);
  if (Number.isNaN(hour)) return null;
  const kst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  return new Date(
    Date.UTC(
      kst.getUTCFullYear(),
      kst.getUTCMonth(),
      kst.getUTCDate(),
      hour,
      Number.isNaN(minute) ? 0 : minute,
      0
    ) - 9 * 60 * 60 * 1000
  );
}

function sessionIdForBooking(bookingId) {
  return "booking_" + bookingId;
}

async function ensureSessionForBooking(bookingId, data) {
  const sessionId = sessionIdForBooking(bookingId);
  const ref = admin.firestore().collection("online_sessions").doc(sessionId);
  const existing = await ref.get();
  if (existing.exists) {
    if (!data.sessionId) {
      await admin.firestore().collection("week_bookings").doc(bookingId).update({
        sessionId,
      });
    }
    return sessionId;
  }

  const courseId = String((data && data.courseId) || "");
  const weekNumber = Number((data && data.weekNumber) || 0);
  const memberName = String((data && data.memberName) || "").trim();
  const weekTitle = String((data && data.weekTitle) || "")
    .trim()
    .replace(/(\d+)\s*주차/g, "$1회차");
  const teacherUid = String((data && (data.teacherId || data.nativeTeacherUid)) || "");
  const titleParts = [];
  if (memberName) titleParts.push(memberName);
  if (weekNumber > 0) titleParts.push(weekNumber + "회차");
  if (
    weekTitle &&
    weekTitle !== weekNumber + "주차" &&
    weekTitle !== weekNumber + "회차"
  ) {
    titleParts.push(weekTitle);
  }
  titleParts.push("화상수업");
  const scheduled = scheduledAtFromBooking(data);

  await ref.set({
    courseId,
    title: titleParts.join(" · "),
    order: weekNumber > 0 ? weekNumber : 1,
    meetingUrl: "https://meet.jit.si/GleamIsland-" + courseId + "-" + bookingId,
    isLive: false,
    scheduledAt: scheduled ? admin.firestore.Timestamp.fromDate(scheduled) : null,
    bookingId,
    userId: String((data && data.userId) || ""),
    teacherId: teacherUid,
    memberName,
    weekNumber,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await admin.firestore().collection("week_bookings").doc(bookingId).set(
    {
      sessionId,
      scheduledAt: scheduled
        ? admin.firestore.Timestamp.fromDate(scheduled)
        : admin.firestore.FieldValue.delete(),
      reminderSent: false,
    },
    { merge: true }
  );
  return sessionId;
}

exports.onWeekBookingUpdated = functions
  .region("asia-northeast3")
  .firestore.document("week_bookings/{bookingId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const bookingId = context.params.bookingId;

    if (after.status === "confirmed" && !after.sessionId) {
      await ensureSessionForBooking(bookingId, after);
    }

    if (before.status === after.status) return null;
    if (after.status !== "confirmed" && after.status !== "rejected") return null;

    const userId = String(after.userId || "");
    const when = formatLessonWhen(after);
    const confirmed = after.status === "confirmed";
    const title = confirmed ? "화상수업이 확정되었습니다" : "화상수업 예약이 거절되었습니다";
    const body = confirmed
      ? `${when} 화상수업이 확정되었습니다. 내 강의실에서 확인해 주세요.`
      : `${when} 예약이 거절되었습니다. 다른 시간을 다시 신청해 주세요.`;

    await writeNotification({
      userId,
      title,
      body,
      type: confirmed ? "booking_confirmed" : "booking_rejected",
      bookingId,
    });

    const phone = await memberPhone(userId, after.phone);
    if (phone) {
      await sendSms({
        to: phone,
        text: confirmed
          ? `[글림교육] ${when} 화상수업이 확정되었습니다. 내 강의실에서 확인해 주세요.`
          : `[글림교육] ${when} 예약이 거절되었습니다. 다른 시간을 다시 신청해 주세요.`,
      });
    } else {
      console.log("학생 연락처가 없어 SMS를 건너뜁니다.", userId);
    }
    return null;
  });

exports.sendLessonReminders = functions
  .region("asia-northeast3")
  .pubsub.schedule("every 1 minutes")
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    const now = Date.now();
    const from = admin.firestore.Timestamp.fromDate(
      new Date(now - 2 * 60 * 1000)
    );
    const to = admin.firestore.Timestamp.fromDate(
      new Date(now + 5 * 60 * 1000)
    );
    const snap = await admin
      .firestore()
      .collection("week_bookings")
      .where("scheduledAt", ">=", from)
      .where("scheduledAt", "<=", to)
      .get();

    let sent = 0;
    for (const doc of snap.docs) {
      const data = doc.data() || {};
      if (data.status !== "confirmed") continue;
      if (data.reminderSent === true) continue;

      await doc.ref.update({
        reminderSent: true,
        reminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const when = formatLessonWhen(data);
      const student = String(data.memberName || data.email || "수강생");
      const userId = String(data.userId || "");
      const teacherUid = String(data.teacherId || data.nativeTeacherUid || "");
      const studentBody = `5분 뒤 화상수업이 시작됩니다. ${when} 내 강의실에서 입장해 주세요.`;
      const teacherBody = `5분 뒤 ${student}님 화상수업이 시작됩니다. ${when} 호스트로 입장해 주세요.`;

      await writeNotification({
        userId,
        title: "화상수업 5분 전",
        body: studentBody,
        type: "lesson_reminder",
        bookingId: doc.id,
      });
      await writeNotification({
        userId: teacherUid,
        title: "화상수업 5분 전",
        body: teacherBody,
        type: "lesson_reminder",
        bookingId: doc.id,
      });

      const studentPhone = await memberPhone(userId, data.phone);
      if (studentPhone) {
        await sendSms({
          to: studentPhone,
          text: `[글림교육] ${studentBody}`,
        });
      } else {
        console.log("학생 연락처가 없어 5분 전 SMS를 건너뜁니다.", userId);
      }

      const staffPhone = await teacherPhone(teacherUid);
      if (staffPhone) {
        await sendSms({
          to: staffPhone,
          text: `[글림교육] ${teacherBody}`,
        });
      } else {
        console.log("강사 연락처가 없어 5분 전 SMS를 건너뜁니다.", teacherUid);
      }
      sent += 1;
    }
    console.log("수업 5분 전 알림 처리", { matched: snap.size, sent });
    return null;
  });

exports.onOnlineSessionUpdated = functions
  .region("asia-northeast3")
  .firestore.document("online_sessions/{sessionId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    if (after.sessionCredited === true) return null;
    if (before.isLive !== true || after.isLive !== false) return null;

    const db = admin.firestore();
    const sessionRef = change.after.ref;
    const userId = String(after.userId || "");
    const courseId = String(after.courseId || "");
    if (!userId || !courseId) {
      console.log(
        "수업 종료 차감 건너뜀: userId/courseId 없음",
        context.params.sessionId
      );
      return null;
    }

    const enrollSnap = await db
      .collection("enrollments")
      .where("userId", "==", userId)
      .get();
    let enrollmentRef = null;
    for (const doc of enrollSnap.docs) {
      if (String((doc.data() || {}).courseId || "") === courseId) {
        enrollmentRef = doc.ref;
        break;
      }
    }
    if (!enrollmentRef) {
      console.log("수업 종료 차감 건너뜀: 수강 배정 없음", userId, courseId);
      return null;
    }

    const weekNumber = Number(after.weekNumber || after.order || 0);
    let credited = false;
    let nextCompleted = 0;
    let totalSessions = 0;

    await db.runTransaction(async (tx) => {
      const sessionSnap = await tx.get(sessionRef);
      const session = sessionSnap.data() || {};
      if (session.sessionCredited === true) return;

      const enrollSnapTx = await tx.get(enrollmentRef);
      if (!enrollSnapTx.exists) return;
      const enroll = enrollSnapTx.data() || {};
      const total = Number(enroll.totalSessions || 0);
      const current = Number(enroll.completedSessions || 0);
      totalSessions = total;
      if (total <= 0 || current >= total) {
        tx.update(sessionRef, {
          sessionCredited: true,
          creditedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      const next = current + 1;
      nextCompleted = next;
      credited = true;
      tx.update(enrollmentRef, {
        completedSessions: next,
        remainingSessions: Math.max(0, total - next),
        lastSessionAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.set(enrollmentRef.collection("session_logs").doc(), {
        delta: 1,
        completedAfter: next,
        totalSessions: total,
        adminName: "화상수업 종료",
        sessionId: context.params.sessionId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(sessionRef, {
        sessionCredited: true,
        creditedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    if (credited) {
      const opened = nextCompleted < totalSessions ? nextCompleted + 1 : 0;
      const label = weekNumber || nextCompleted;
      await writeNotification({
        userId,
        title: "화상수업 이수",
        body: opened
          ? `${label}회차 화상수업을 마쳤습니다. ${opened}회차가 열렸습니다.`
          : `${label}회차 화상수업을 마쳤습니다. 전 회차를 모두 이수했습니다.`,
        type: "session_completed",
        bookingId: String(after.bookingId || ""),
      });
    }
    return null;
  });

exports.sendWeeklyEnrollmentReminders = functions
  .region("asia-northeast3")
  .pubsub.schedule("0 10 * * 1")
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();
    const weekKey = isoWeekKeyKst(now);
    const { monday, sundayEnd } = kstWeekRange(now);
    const [enrollSnap, bookingSnap] = await Promise.all([
      db.collection("enrollments").get(),
      db.collection("week_bookings").get(),
    ]);

    const bookedThisWeek = new Set();
    for (const doc of bookingSnap.docs) {
      const data = doc.data() || {};
      if (data.status !== "pending" && data.status !== "confirmed") continue;
      const date = toJsDate(data.date) || toJsDate(data.scheduledAt);
      if (!date) continue;
      if (date < monday || date >= sundayEnd) continue;
      const userId = String(data.userId || "");
      if (userId) bookedThisWeek.add(userId);
    }

    let sent = 0;
    let backfilled = 0;
    for (const doc of enrollSnap.docs) {
      const data = doc.data() || {};
      if (data.isActive === false) continue;
      const userId = String(data.userId || "");
      if (!userId) continue;
      const total = Number(data.totalSessions || 0);
      const completed = Number(data.completedSessions || 0);
      const remaining =
        data.remainingSessions != null
          ? Number(data.remainingSessions)
          : Math.max(0, total - completed);
      if (remaining <= 0) continue;

      const updates = {};
      let expires = toJsDate(data.expiresAt);
      const start = toJsDate(data.createdAt) || now;
      if (!expires) {
        expires = expiresAtFromStart(start, total);
        updates.expiresAt = admin.firestore.Timestamp.fromDate(expires);
        backfilled += 1;
      }
      if (expires.getTime() < startOfKstDay(now).getTime() && remaining > 0) {
        expires = addDays(
          startOfKstDay(now),
          remaining * DEADLINE_WEEKS_PER_SESSION * 7
        );
        updates.expiresAt = admin.firestore.Timestamp.fromDate(expires);
        backfilled += 1;
      }

      const weeksLeft = remainingDeadlineWeeks(expires, now);
      const already = String(data.lastWeeklyReminderWeek || "");
      const shouldAlways = weeksLeft <= 4;
      const hasBooking = bookedThisWeek.has(userId);
      const shouldSend = already !== weekKey && (shouldAlways || !hasBooking);

      if (!shouldSend) {
        if (Object.keys(updates).length > 0) {
          updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
          await doc.ref.update(updates);
        }
        continue;
      }

      let title = "이번 주 화상수업 예약";
      let body = `이번 주 화상수업 예약이 없습니다. 남은 ${remaining}회 · 기한 ${weeksLeft}주 남음. 내 강의실에서 예약해 주세요.`;
      if (weeksLeft <= 1) {
        title = "수강 기한이 이번 주까지입니다";
        body = `수강 기한이 이번 주까지입니다. 남은 화상수업 ${remaining}회. 지금 예약해 주세요.`;
      } else if (weeksLeft <= 4) {
        title = "수강 기한이 얼마 남지 않았습니다";
        body = `수강 기한이 ${weeksLeft}주 남았습니다. 남은 화상수업 ${remaining}회. 내 강의실에서 예약해 주세요.`;
      }

      await writeNotification({
        userId,
        title,
        body,
        type: "weekly_enrollment",
      });
      const phone = await memberPhone(userId, data.phone);
      if (phone) {
        await sendSms({
          to: phone,
          text: `[글림교육] ${body}`,
        });
      } else {
        console.log("학생 연락처가 없어 주간 알림 SMS를 건너뜁니다.", userId);
      }

      updates.lastWeeklyReminderWeek = weekKey;
      updates.lastWeeklyReminderAt = admin.firestore.FieldValue.serverTimestamp();
      updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      await doc.ref.update(updates);
      sent += 1;
    }

    console.log("주간 수강 기한 알림", {
      enrollments: enrollSnap.size,
      sent,
      backfilled,
      weekKey,
    });
    return null;
  });

exports.onLessonFeedbackWritten = functions
  .region("asia-northeast3")
  .firestore.document("lesson_feedbacks/{feedbackId}")
  .onWrite(async (change) => {
    if (!change.after.exists) return null;
    const after = change.after.data() || {};
    if (after.alertSentAt) return null;
    const userId = String(after.userId || "");
    if (!userId) return null;
    const before = change.before.exists ? change.before.data() || {} : null;
    if (before && String(before.content || "") === String(after.content || "")) {
      return null;
    }
    const teacher = String(after.teacherName || "").trim() || "강사";
    const weekNumber = Number(after.weekNumber || 0);
    const week = weekNumber > 0 ? `${weekNumber}회차` : "화상수업";
    const isNew = !change.before.exists;
    await writeNotification({
      userId,
      title: "강사 피드백",
      body: isNew
        ? `${teacher} 선생님이 ${week} 피드백을 남겼습니다. 내 강의실에서 확인해 주세요.`
        : `${teacher} 선생님이 ${week} 피드백을 수정했습니다. 내 강의실에서 확인해 주세요.`,
      type: "lesson_feedback",
      bookingId: String(after.bookingId || change.after.id),
    });
    await change.after.ref.set(
      { alertSentAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
    return null;
  });
