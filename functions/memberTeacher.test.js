const test = require("node:test");
const assert = require("node:assert/strict");
const {
  memberTeacherPatch,
  shouldFillMemberTeacher,
} = require("./memberTeacher");

test("카드 결제 강사 uid를 회원 teacherId에 남긴다", () => {
  assert.deepEqual(
    memberTeacherPatch({
      nativeTeacherId: "native_emma",
      nativeTeacherName: "Emma",
      nativeTeacherUid: "teacher-uid",
    }),
    {
      nativeTeacherId: "native_emma",
      nativeTeacherName: "Emma",
      nativeTeacherUid: "teacher-uid",
      teacherId: "teacher-uid",
    }
  );
});

test("강사 uid가 없으면 teacherId를 비우지 않는다", () => {
  const patch = memberTeacherPatch({
    nativeTeacherId: "native_emma",
    nativeTeacherName: "Emma",
    nativeTeacherUid: "  ",
  });
  assert.equal(Object.prototype.hasOwnProperty.call(patch, "teacherId"), false);
});

test("강사 정보가 없으면 회원 문서를 건드리지 않는다", () => {
  assert.equal(memberTeacherPatch({}), null);
  assert.equal(memberTeacherPatch(null), null);
});

test("teacherId가 비어 있는 카드 수강생만 강사에게 붙인다", () => {
  const enrollment = {
    userId: "student",
    isActive: true,
    nativeTeacherId: "native_emma",
    nativeTeacherName: "Emma",
    nativeTeacherUid: "teacher-uid",
  };
  assert.equal(shouldFillMemberTeacher({ teacherId: "" }, enrollment), true);
  assert.equal(shouldFillMemberTeacher({ teacherId: "  " }, enrollment), true);
  assert.equal(
    shouldFillMemberTeacher({ teacherId: "other-teacher" }, enrollment),
    false
  );
  assert.equal(
    shouldFillMemberTeacher({ teacherId: "" }, { ...enrollment, isActive: false }),
    false
  );
  assert.equal(
    shouldFillMemberTeacher(
      { teacherId: "" },
      { ...enrollment, nativeTeacherUid: "" }
    ),
    false
  );
});
