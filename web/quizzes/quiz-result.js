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
    "gleam-level2-lesson1": {
      courseId: "basic_grammar_speaking",
      weekNumber: 1,
      title: "기초 1강 연습문제"
    },
    "gleam-level2-lesson2": {
      courseId: "basic_grammar_speaking",
      weekNumber: 2,
      title: "기초 2강 연습문제"
    },
    "gleam-level2-lesson3": {
      courseId: "basic_grammar_speaking",
      weekNumber: 3,
      title: "기초 3강 연습문제"
    },
    "gleam-level2-lesson4": {
      courseId: "basic_grammar_speaking",
      weekNumber: 4,
      title: "기초 4강 연습문제"
    },
    "gleam-level2-lesson5": {
      courseId: "basic_grammar_speaking",
      weekNumber: 5,
      title: "기초 5강 연습문제"
    },
    "gleam-level2-lesson6": {
      courseId: "basic_grammar_speaking",
      weekNumber: 6,
      title: "기초 6강 연습문제"
    },
    "gleam-level2-lesson7": {
      courseId: "basic_grammar_speaking",
      weekNumber: 7,
      title: "기초 7강 연습문제"
    },
    "gleam-level2-lesson8": {
      courseId: "basic_grammar_speaking",
      weekNumber: 8,
      title: "기초 8강 연습문제"
    },
    "gleam-level2-lesson9": {
      courseId: "basic_grammar_speaking",
      weekNumber: 9,
      title: "기초 9강 연습문제"
    },
    "gleam-level2-lesson10": {
      courseId: "basic_grammar_speaking",
      weekNumber: 10,
      title: "기초 10강 연습문제"
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
    "gleam-level1-lesson5": {
      courseId: "beginner_phonics",
      weekNumber: 5,
      title: "왕초보 5강 연습문제"
    },
    "gleam-level1-lesson6": {
      courseId: "beginner_phonics",
      weekNumber: 6,
      title: "왕초보 6강 연습문제"
    },
    "gleam-level1-lesson7": {
      courseId: "beginner_phonics",
      weekNumber: 7,
      title: "왕초보 7강 연습문제"
    },
    "gleam-level1-lesson8": {
      courseId: "beginner_phonics",
      weekNumber: 8,
      title: "왕초보 8강 연습문제"
    },
    "gleam-level1-lesson9": {
      courseId: "beginner_phonics",
      weekNumber: 9,
      title: "왕초보 9강 연습문제"
    },
    "gleam-level1-lesson10": {
      courseId: "beginner_phonics",
      weekNumber: 10,
      title: "왕초보 10강 연습문제"
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
    },
    "gleam-level3-lesson3": {
      courseId: "intermediate_grammar_speaking",
      weekNumber: 3,
      title: "중급 3강 연습문제"
    },
    "gleam-level3-lesson4": {
      courseId: "intermediate_grammar_speaking",
      weekNumber: 4,
      title: "중급 4강 연습문제"
    },
    "gleam-level3-lesson5": {
      courseId: "intermediate_grammar_speaking",
      weekNumber: 5,
      title: "중급 5강 연습문제"
    },
    "gleam-level3-lesson6": {
      courseId: "intermediate_grammar_speaking",
      weekNumber: 6,
      title: "중급 6강 연습문제"
    },
    "gleam-level3-lesson7": {
      courseId: "intermediate_grammar_speaking",
      weekNumber: 7,
      title: "중급 7강 연습문제"
    },
    "gleam-level3-lesson8": {
      courseId: "intermediate_grammar_speaking",
      weekNumber: 8,
      title: "중급 8강 연습문제"
    },
    "gleam-level3-lesson9": {
      courseId: "intermediate_grammar_speaking",
      weekNumber: 9,
      title: "중급 9강 연습문제"
    },
    "gleam-level3-lesson10": {
      courseId: "intermediate_grammar_speaking",
      weekNumber: 10,
      title: "중급 10강 연습문제"
    },
    "gleam-level5-lesson1": {
      courseId: "advanced_premium_speaking",
      weekNumber: 1,
      title: "고급 1강 연습문제"
    },
    "gleam-level5-lesson2": {
      courseId: "advanced_premium_speaking",
      weekNumber: 2,
      title: "고급 2강 연습문제"
    },
    "gleam-level5-lesson3": {
      courseId: "advanced_premium_speaking",
      weekNumber: 3,
      title: "고급 3강 연습문제"
    },
    "gleam-level5-lesson4": {
      courseId: "advanced_premium_speaking",
      weekNumber: 4,
      title: "고급 4강 연습문제"
    },
    "gleam-level5-lesson5": {
      courseId: "advanced_premium_speaking",
      weekNumber: 5,
      title: "고급 5강 연습문제"
    },
    "gleam-level5-lesson6": {
      courseId: "advanced_premium_speaking",
      weekNumber: 6,
      title: "고급 6강 연습문제"
    },
    "gleam-level5-lesson7": {
      courseId: "advanced_premium_speaking",
      weekNumber: 7,
      title: "고급 7강 연습문제"
    },
    "gleam-level5-lesson8": {
      courseId: "advanced_premium_speaking",
      weekNumber: 8,
      title: "고급 8강 연습문제"
    },
    "gleam-level5-lesson9": {
      courseId: "advanced_premium_speaking",
      weekNumber: 9,
      title: "고급 9강 연습문제"
    },
    "gleam-level5-lesson10": {
      courseId: "advanced_premium_speaking",
      weekNumber: 10,
      title: "고급 10강 연습문제"
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

  function percentFor(correct, total) {
    if (!total) return 0;
    return Math.round((correct * 100) / total);
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
      section.innerHTML = '<h2>최근 결과</h2><p class="score"></p><p class="status"></p><div class="essays"></div><p class="note">완료를 누르면 이 점수와 주관식 답이 내 강의실에 바로 저장됩니다. 다시 풀고 완료하면 방금 풀이로 바뀝니다.</p>';
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
        score.textContent = title + correct + " / 25문제 · " + percentFor(correct, 25) + "%";
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

    var pendingFinish = false;
    var siteSavePending = false;
    var savedMessage = "문제풀이를 완료하고 결과를 저장했습니다. 내 강의실에서 점수와 주관식 답을 볼 수 있습니다.";

    function previewFrom(snapshot) {
      return {
        title: meta ? meta.title : "",
        correctCount: snapshot.correct,
        essays: snapshot.essays || []
      };
    }

    function notifySite(snapshot) {
      if (!window.opener || window.opener === window || !meta || !snapshot) return false;
      try {
        window.opener.postMessage({
          type: "gleam-quiz-result",
          payload: buildPayload(meta, snapshot, user ? user.uid : "")
        }, window.location.origin);
        siteSavePending = true;
        return true;
      } catch (error) {
        return false;
      }
    }

    window.addEventListener("message", function (event) {
      if (!event.data || event.origin !== window.location.origin) return;
      if (event.data.type === "gleam-quiz-saved") {
        siteSavePending = false;
        renderSaved(queued ? previewFrom(queued) : {}, savedMessage);
      } else if (event.data.type === "gleam-quiz-save-failed" && siteSavePending && !user) {
        siteSavePending = false;
        renderSaved(null, "점수 저장에 실패했습니다. 웹사이트에 로그인한 뒤 완료를 다시 눌러 주세요.");
      }
    });

    function schedule(snapshot) {
      if (!shouldSave(snapshot) || !meta) return;
      var key = snapshotKey(snapshot);
      if (key === lastSavedKey) return;
      clearTimeout(timer);
      timer = setTimeout(function () {
        save(snapshot, key);
      }, 400);
    }

    function save(snapshot, key, doneMessage) {
      if (!user || !meta || !shouldSave(snapshot)) {
        if (authReady && !user) {
          renderSaved(null, doneMessage
            ? "웹사이트에 로그인한 뒤 완료를 눌러야 점수와 주관식 답이 강의실과 예약 강사에게 남습니다."
            : "웹사이트에 로그인한 뒤 풀면 점수와 주관식 답이 강의실과 예약 강사에게 남습니다.");
        }
        return;
      }
      var payload = buildPayload(meta, snapshot, user.uid);
      payload.updatedAt = window.firebase.firestore.FieldValue.serverTimestamp();
      window.firebase.firestore().collection("quiz_results").doc(user.uid + "_" + meta.quizId).set(payload).then(function () {
        lastSavedKey = key;
        renderSaved(payload, doneMessage || "최근 점수로 저장했습니다. 주관식도 방금 답으로 바뀌었습니다.");
      }).catch(function () {
        renderSaved(payload, "점수 저장에 실패했습니다. 로그인 상태를 확인해 주세요.");
      });
    }

    function commitFinish(snapshot) {
      if (!shouldSave(snapshot) || !meta) return;
      clearTimeout(timer);
      var key = snapshotKey(snapshot);
      var handed = notifySite(snapshot);
      if (!user) {
        if (handed) {
          renderSaved(previewFrom(snapshot), "문제풀이를 완료하고 강의실에 저장하는 중입니다.");
          setTimeout(function () {
            if (!siteSavePending || user) return;
            siteSavePending = false;
            renderSaved(null, "웹사이트에 로그인한 뒤 완료를 눌러야 점수와 주관식 답이 내 강의실에 남습니다.");
          }, 2500);
        } else {
          renderSaved(null, "웹사이트에 로그인한 뒤 완료를 눌러야 점수와 주관식 답이 내 강의실에 남습니다.");
        }
        return;
      }
      if (key === lastSavedKey) {
        renderSaved(previewFrom(snapshot), savedMessage);
        return;
      }
      save(snapshot, key, savedMessage);
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
        pendingFinish = false;
        if (!authReady) return;
        schedule(snapshot);
      },
      finish: function (snapshot) {
        queued = snapshot;
        pendingFinish = true;
        if (!meta) return;
        if (!authReady) {
          if (!notifySite(snapshot)) {
            renderSaved(null, "웹사이트에 로그인한 뒤 완료를 눌러야 점수와 주관식 답이 내 강의실에 남습니다.");
            return;
          }
          renderSaved(previewFrom(snapshot), "문제풀이를 완료하고 강의실에 저장하는 중입니다.");
          setTimeout(function () {
            if (!siteSavePending || user) return;
            siteSavePending = false;
            renderSaved(null, "웹사이트에 로그인한 뒤 완료를 눌러야 점수와 주관식 답이 내 강의실에 남습니다.");
          }, 2500);
          return;
        }
        pendingFinish = false;
        commitFinish(snapshot);
      },
      start: function (readSnapshot) {
        read = readSnapshot;
        meta = META[quizIdFromPath(window.location.pathname)];
        if (!meta) return;
        meta = {
          quizId: quizIdFromPath(window.location.pathname),
          courseId: meta.courseId,
          weekNumber: meta.weekNumber,
          title: meta.title
        };
        if (typeof window === "undefined" || !window.firebase) return;
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
          if (!queued) return;
          if (pendingFinish) {
            pendingFinish = false;
            commitFinish(queued);
          } else {
            schedule(queued);
          }
        });
      }
    };
  }

  var browser = typeof window === "undefined" ? null : createBrowser();
  return {
    META: META,
    quizIdFromPath: quizIdFromPath,
    percentFor: percentFor,
    shouldSave: shouldSave,
    buildPayload: buildPayload,
    report: function (snapshot) {
      if (browser) browser.report(snapshot);
    },
    finish: function (snapshot) {
      if (browser) browser.finish(snapshot);
    },
    start: function (readSnapshot) {
      if (browser) browser.start(readSnapshot);
    }
  };
});
