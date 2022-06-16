class User {
  String id;
  String pw;
  List hobbyList;
  double age;
  bool isMale;
  String level;


  User(
      this.id, this.pw, this.hobbyList, this.age, this.isMale, this.level);

  User.init():id="",pw="",hobbyList=[], age=0,isMale=true,level="";

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pw': pw,
      'hobbyList': hobbyList,
      'age': age,
      'isMale': isMale,
      'level': level,
    };
  }

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        pw = json['pw'],
        hobbyList = json['hobbyList'],
        age = json['age'],
        isMale = json['isMale'],
        level = json['level'];
}
