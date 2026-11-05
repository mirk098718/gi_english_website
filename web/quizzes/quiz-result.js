/* 연습문제 최근 결과를 Firestore에 남긴다.
   같은 퀴즈 문서는 하나다. 25문제를 다시 채점하면 점수와 주관식이 그 풀이로 바뀐다. */
(function (factory) {
  var api = factory();
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  if (typeof window !== "undefined") window.GleamQuiz = api;
})(function () {
  var META = {
    "gleam-level1-lesson1": {
      courseId: "beginner_phonics",
      weekNumber: 1,
      title: "왕초보 1강 연습문제"
    },
    "gleam-level2-lesson02": {
      courseId: "beginner_phonics",
      weekNumber: 2,
      title: "왕초보 2강 연습문제"
    },
    "gleam-level1-lesson3": {
      courseId: "beginner_phonics",
      weekNumber: 3,
      title: "왕초보 3강 연습문제"
    },
    "gleam-level1-lesson4": {
      courseId: "beginner_phonics",
      weekNumber: 4,
      title: "왕초보 4강 연습문제"
    },
    "gleam-level3-lesson1": {
      courseId: "intermediate_grammar_speaking",
      weekNumber: 1,
      title: "중급 1강 연습문제"
    },
    "gleam-level3-lesson2": {
      courseId: "intermediate_grammar_speaking",
      weekNumber: 2,
      title: "중급 2강 연습문제"
    }
  };

  var firebaseConfig = {
    apiKey: "AIzaSyC8nWDyhU0EeZH1LB3hGlya9cbGKOOohBQ",
    authDomain: "gleam-island.firebaseapp.com",
    projectId: "gleam-island",
    storageBucket: "gleam-island.appspot.com",
    messagingSenderId: "129043838101",
    appId: "1:129043838101:web:2acd494b5a96f04703979c"
  };

  function quizIdFromPath(pathname) {
    var name = String(pathname || "").split("?")[0].split("#")[0].split("/").pop() || "";
    if (name.slice(-10) !== "-quiz.html") return "";
    return name.slice(0, -10);
  }

  function shouldSave(snapshot) {
    if (!snapshot || snapshot.complete !== true) return false;
    if (snapshot.total !== 25) return false;
    var correct = snapshot.correct;
    return typeof correct === "number" && correct >= 0 && correct <= 25;
  }

  function buildPayload(meta, snapshot, userId) {
    return {
      userId: userId,
      quizId: meta.quizId,
      title: meta.title,
      courseId: meta.courseId,
      weekNumber: meta.weekNumber,
      correctCount: snapshot.correct,
      totalCount: 25,
      completed: true,
      essays: (snapshot.essays || []).slice(0, 8).map(function (essay) {
        return {
          index: essay.index || 0,
          title: String(essay.title || "").slice(0, 80),
          prompt: String(essay.prompt || "").slice(0, 500),
          answer: String(essay.answer || "").slice(0, 2000)
        };
      })
    };
  }

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function createBrowser() {
    var read = null;
    var user = null;
    var authReady = false;
    var queued = null;
    var timer = null;
    var lastSavedKey = "";
    var meta = null;

    function snapshotKey(snapshot) {
      var answers = (snapshot.essays || []).map(function (essay) {
        return essay.answer || "";
      }).join("\n");
      return snapshot.correct + "|" + answers;
    }

    function ensurePanel() {
      if (typeof document === "undefined") return null;
      var existing = document.getElementById("gleamSaved");
      if (existing) return existing;
      var main = document.querySelector("main.wrap");
      if (!main) return null;
      if (!document.getElementById("gleamSavedStyle")) {
        var style = document.createElement("style");
        style.id = "gleamSavedStyle";
        style.textContent = [
          "#gleamSaved{margin:18px 0 0; background:var(--card); border:1.5px solid var(--line); border-radius:18px; padding:16px 16px 14px}",
          "#gleamSaved h2{font-family:var(--disp); font-size:1.15rem; color:var(--coffee); font-weight:400}",
          "#gleamSaved .score{font-weight:800; color:var(--ok); margin:6px 0}",
          "#gleamSaved .note, #gleamSaved .status{font-size:.82rem; color:var(--sub); font-weight:700}",
          "#gleamSaved .essay{margin-top:10px; padding-top:10px; border-top:1px solid var(--line)}",
          "#gleamSaved .essay b{display:block; margin-bottom:2px}",
          "#gleamSaved .prompt{color:var(--sub); font-size:.82rem}",
          "#gleamSaved .answer{white-space:pre-wrap}"
        ].join("");
        document.head.appendChild(style);
      }
      var section = document.createElement("section");
      section.id = "gleamSaved";
      section.hidden = true;
      section.innerHTML = '<h2>최근 결과</h2><p class="score"></p><p class="status"></p><div class="essays"></div><p class="note">다시 풀고 25문제를 모두 채점하면 이 점수와 주관식 답이 방금 풀이로 바뀝니다.</p>';
      main.insertBefore(section, main.firstChild);
      return section;
    }

    function renderSaved(data, status) {
      var panel = ensurePanel();
      if (!panel) return;
      var correct = data && typeof data.correctCount === "number" ? data.correctCount : null;
      panel.hidden = correct == null && !status;
      var score = panel.querySelector(".score");
      var statusEl = panel.querySelector(".status");
      var essaysEl = panel.querySelector(".essays");
      if (correct == null) {
        score.textContent = "";
        essaysEl.innerHTML = "";
      } else {
        var title = data.title ? data.title + " · " : "";
        score.textContent = title + correct + " / 25문제 · " + correct + "점";
        var essays = Array.isArray(data.essays) ? data.essays : [];
        essaysEl.innerHTML = essays.map(function (essay) {
          var heading = essay.title || ("주관식 " + (essay.index || ""));
          var prompt = essay.prompt ? '<div class="prompt">' + escapeHtml(essay.prompt) + "</div>" : "";
          var answer = essay.answer ? escapeHtml(essay.answer) : "작성하지 않음";
          return '<div class="essay"><b>' + escapeHtml(heading) + "</b>" + prompt + '<div class="answer">' + answer + "</div></div>";
        }).join("");
      }
      statusEl.textContent = status || "";
    }

    function schedule(snapshot) {
      if (!shouldSave(snapshot) || !meta) return;
      var key = snapshotKey(snapshot);
      if (key === lastSavedKey) return;
      clearTimeout(timer);
      timer = setTimeout(function () {
        save(snapshot, key);
      }, 400);
    }

    function save(snapshot, key) {
      if (!user || !meta || !shouldSave(snapshot)) {
        if (authReady && !user) {
          renderSaved(null, "웹사이트에 로그인한 뒤 풀면 점수와 주관식 답이 강의실과 예약 강사에게 남습니다.");
        }
        return;
      }
      var payload = buildPayload(meta, snapshot, user.uid);
      payload.updatedAt = window.firebase.firestore.FieldValue.serverTimestamp();
      window.firebase.firestore().collection("quiz_results").doc(user.uid + "_" + meta.quizId).set(payload).then(function () {
        lastSavedKey = key;
        renderSaved(payload, "최근 점수로 저장했습니다. 주관식도 방금 답으로 바뀌었습니다.");
      }).catch(function () {
        renderSaved(payload, "점수 저장에 실패했습니다. 로그인 상태를 확인해 주세요.");
      });
    }

    function loadSaved() {
      if (!user || !meta) return;
      window.firebase.firestore().collection("quiz_results").doc(user.uid + "_" + meta.quizId).get().then(function (snap) {
        if (!snap.exists) return;
        renderSaved(snap.data() || {}, "이전에 저장한 최근 결과입니다.");
      }).catch(function () {});
    }

    return {
      report: function (snapshot) {
        queued = snapshot;
        if (!authReady) return;
        schedule(snapshot);
      },
      start: function (readSnapshot) {
        read = readSnapshot;
        if (typeof window === "undefined" || !window.firebase) return;
        meta = META[quizIdFromPath(window.location.pathname)];
        if (!meta) return;
        meta = {
          quizId: quizIdFromPath(window.location.pathname),
          courseId: meta.courseId,
          weekNumber: meta.weekNumber,
          title: meta.title
        };
        try {
          if (!window.firebase.apps.length) window.firebase.initializeApp(firebaseConfig);
        } catch (error) {
          return;
        }
        document.querySelectorAll("#essayList textarea").forEach(function (el) {
          el.addEventListener("input", function () {
            if (read) window.GleamQuiz.report(read());
          });
        });
        var auth = window.firebase.auth();
        auth.setPersistence(window.firebase.auth.Auth.Persistence.LOCAL).catch(function () {});
        auth.onAuthStateChanged(function (next) {
          user = next || null;
          authReady = true;
          if (user) loadSaved();
          else renderSaved(null, "웹사이트에 로그인한 뒤 풀면 점수와 주관식 답이 강의실과 예약 강사에게 남습니다.");
          if (queued) schedule(queued);
        });
      }
    };
  }

  var browser = typeof window === "undefined" ? null : createBrowser();
  return {
    META: META,
    quizIdFromPath: quizIdFromPath,
    shouldSave: shouldSave,
    buildPayload: buildPayload,
    report: function (snapshot) {
      if (browser) browser.report(snapshot);
    },
    start: function (readSnapshot) {
      if (browser) browser.start(readSnapshot);
    }
  };
});
