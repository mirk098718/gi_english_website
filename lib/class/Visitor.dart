class Visitor {
  String childName;
  String childAge;
  String parentName;
  String program;
  String programPeriod;
  String time;
  String level;
  String parentNumber;

  Visitor(this.childName, this.childAge, this.parentName, this.program,
      this.programPeriod, this.level, this.time, this.parentNumber);

  Visitor.init()
      : childName = "",
        childAge = "",
        parentName = "",
        program = "",
        programPeriod = "",
        level = "",
        time = "",
        parentNumber = "";
}
