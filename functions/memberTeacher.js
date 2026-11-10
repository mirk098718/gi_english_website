/**
 * 카드 결제·수강 문서의 강사 uid를 회원 문서 teacherId로 옮길 때 쓰는 순수 함수.
 * 강사 화면은 members.teacherId로 담당 수강생과 연락처를 읽는다.
 */

function memberTeacherPatch(source) {
  const nativeTeacherId = String((source && source.nativeTeacherId) || "").trim();
  const nativeTeacherName = String((source && source.nativeTeacherName) || "").trim();
  const nativeTeacherUid = String((source && source.nativeTeacherUid) || "").trim();
  if (!nativeTeacherId && !nativeTeacherUid) return null;
  const patch = {};
  if (nativeTeacherId) patch.nativeTeacherId = nativeTeacherId;
  if (nativeTeacherName) patch.nativeTeacherName = nativeTeacherName;
  if (nativeTeacherUid) {
    patch.nativeTeacherUid = nativeTeacherUid;
    patch.teacherId = nativeTeacherUid;
  }
  return patch;
}

/** 회원 teacherId가 비어 있고 수강에 강사 uid가 있을 때만 채운다. */
function shouldFillMemberTeacher(member, enrollment) {
  if (!enrollment || enrollment.isActive === false) return false;
  const userId = String(enrollment.userId || "").trim();
  if (!userId) return false;
  const patch = memberTeacherPatch(enrollment);
  if (!patch || !patch.teacherId) return false;
  const current = String((member && member.teacherId) || "").trim();
  return current.length === 0;
}

module.exports = {
  memberTeacherPatch,
  shouldFillMemberTeacher,
};
