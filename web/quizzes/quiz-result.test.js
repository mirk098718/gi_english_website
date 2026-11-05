const test = require("node:test");
const assert = require("node:assert/strict");
const quiz = require("./quiz-result.js");

test("퀴즈 파일 이름에서 저장 키를 만든다", () => {
  assert.equal(
    quiz.quizIdFromPath("/quizzes/gleam-level1-lesson1-quiz.html"),
    "gleam-level1-lesson1"
  );
  assert.equal(quiz.quizIdFromPath("/quizzes/other.html"), "");
});

test("25문제를 모두 채점하기 전에는 저장하지 않는다", () => {
  assert.equal(quiz.shouldSave({ complete: false, total: 25, correct: 10 }), false);
  assert.equal(quiz.shouldSave({ complete: true, total: 24, correct: 10 }), false);
  assert.equal(quiz.shouldSave({ complete: true, total: 25, correct: 18 }), true);
});

test("다시 저장할 문서는 최근 점수와 최근 주관식으로 덮어쓴다", () => {
  const meta = {
    quizId: "gleam-level1-lesson1",
    courseId: "beginner_phonics",
    weekNumber: 1,
    title: "왕초보 1강 연습문제"
  };
  const first = quiz.buildPayload(meta, {
    correct: 20,
    essays: [{ index: 1, title: "기본 표현", prompt: "커피", answer: "I like tea." }]
  }, "student");
  const second = quiz.buildPayload(meta, {
    correct: 14,
    essays: [{ index: 1, title: "기본 표현", prompt: "커피", answer: "I like coffee." }]
  }, "student");

  assert.equal(first.correctCount, 20);
  assert.equal(second.correctCount, 14);
  assert.equal(second.quizId, first.quizId);
  assert.equal(second.userId, first.userId);
  assert.equal(second.essays[0].answer, "I like coffee.");
  assert.equal(second.completed, true);
  assert.equal(second.totalCount, 25);
});
