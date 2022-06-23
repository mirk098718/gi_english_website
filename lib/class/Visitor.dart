class Visitor {
  String childName;
  int childAge;
  String parentName;
  String parentNumber;


  Visitor({required this.childName, required this.childAge, required this.parentName, required this.parentNumber});

  Map<String, dynamic> toJson() {
    return {
      'childName': childName,
      'childAge': childAge,
      'parentName': parentName,
      'parentNumber': parentNumber,
    };
  }

  Visitor.fromJson(Map<String, dynamic> json)
      : childName = json['childName'],
        childAge = json['childAge'],
        parentName = json['parentName'],
        parentNumber = json['parentNumber'];
}
