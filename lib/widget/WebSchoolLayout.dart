import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/School1on1Page.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolAllDayPage.dart';
import 'package:gi_english_website/pages/SchoolCampPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityFAQPage.dart';
import 'package:gi_english_website/pages/SchoolCommunityNoticePage.dart';
import 'package:gi_english_website/pages/SchoolConsultationPage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumElePage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumMiddleSchoolPage.dart';
import 'package:gi_english_website/pages/SchoolGalleryPage.dart';
import 'package:gi_english_website/pages/SchoolMainPage.dart';
import 'package:gi_english_website/pages/SchoolMapPage.dart';
import 'package:gi_english_website/pages/SchoolNZPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/pages/SchoolSystemPage.dart';
import 'package:gi_english_website/pages/SchoolTeachersPage.dart';
import 'package:gi_english_website/pages/WorkingAdminLoginPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/AuthService.dart';

class WebSchoolLayout extends StatefulWidget {
  final Widget content;
  final double height = 51;

  WebSchoolLayout({Key? key, required this.content}) : super(key: key);

  @override
  _WebSchoolLayoutState createState() => _WebSchoolLayoutState();
}

class _WebSchoolLayoutState extends State<WebSchoolLayout> {
  final idController = TextEditingController();
  final pwController = TextEditingController();
  bool _isAdmin = false;

  bool menu1Transparent = true;
  bool menu2Transparent = true;
  bool menu3Transparent = true;
  bool menu4Transparent = true;
  bool menu5Transparent = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    bool isAdmin = await AuthService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              top: 80, bottom: 0, left: 0, right: 0, child: widget.content),
          Positioned(top: 0, left: 0, right: 0, child: appBar(context)),
        ],
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    print('🔧 WebSchoolLayout: 관리자 로그인 다이얼로그 호출됨');
    // WorkingAdminLoginPage로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkingAdminLoginPage(category: 'general'),
      ),
    ).then((_) {
      // 로그인 후 돌아왔을 때 관리자 상태 다시 확인
      _checkAdminStatus();
    });
  }

  Future<void> _logout() async {
    try {
      await AuthService.signOut();
      setState(() {
        _isAdmin = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('로그아웃되었습니다.', style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그아웃 중 오류가 발생했습니다.',
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSimpleAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('관리자 로그인', style: TextStyle(fontFamily: "NotoSansKR")),
        content: Text('개발 중입니다. 임시로 자동 로그인됩니다.',
            style: TextStyle(fontFamily: "NotoSansKR")),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogin(context, "gienglish.paju@gmail.com", "gleam701");
            },
            child: Text('확인', style: TextStyle(fontFamily: "NotoSansKR")),
          ),
        ],
      ),
    );
  }

  void _showSimpleLoginDialog(BuildContext context) {
    print('📋 WebSchoolLayout: _showSimpleLoginDialog 시작');
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String email = '';
    String password = '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        print('🎨 WebSchoolLayout: Dialog builder 호출됨');
        return Dialog(
          child: Container(
            width: 400,
            padding: EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Palette.primary),
                      SizedBox(width: 8),
                      Text(
                        '관리자 로그인',
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    autofocus: true,
                    initialValue: '',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      hintText: 'gienglish.paju@gmail.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    style: TextStyle(fontFamily: "NotoSansKR"),
                    onChanged: (value) {
                      print('📧 WebSchoolLayout: 이메일 입력됨 - "$value"');
                      email = value.trim();
                    },
                    onTap: () {
                      print('👆 WebSchoolLayout: 이메일 필드 클릭됨');
                    },
                    onFieldSubmitted: (value) {
                      print('⏎ WebSchoolLayout: 이메일 필드에서 Enter 키 눌림');
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    initialValue: '',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      hintText: 'gleam701',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    style: TextStyle(fontFamily: "NotoSansKR"),
                    onChanged: (value) {
                      print(
                          '🔐 WebSchoolLayout: 비밀번호 입력됨 - "${value.length}자"');
                      password = value.trim();
                    },
                    onTap: () {
                      print('👆 WebSchoolLayout: 비밀번호 필드 클릭됨');
                    },
                    onFieldSubmitted: (value) {
                      print('⏎ WebSchoolLayout: 비밀번호 필드에서 Enter 키 눌림');
                      if (formKey.currentState!.validate()) {
                        Navigator.of(context).pop();
                        _performLogin(context, email, password);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          print('❌ WebSchoolLayout: 취소 버튼 클릭됨');
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontFamily: "NotoSansKR",
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          print('✅ WebSchoolLayout: 로그인 버튼 클릭됨');
                          print('📧 현재 이메일: "$email"');
                          print('🔐 현재 비밀번호: "${password.length}자"');
                          if (formKey.currentState!.validate()) {
                            Navigator.of(context).pop();
                            _performLogin(context, email, password);
                          } else {
                            print('❌ WebSchoolLayout: 폼 유효성 검사 실패');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          '로그인',
                          style: TextStyle(fontFamily: "NotoSansKR"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _oldShowAdminLoginDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final FocusNode emailFocusNode = FocusNode();
    final FocusNode passwordFocusNode = FocusNode();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // 다이얼로그가 빌드된 후 즉시 포커스 설정
        Future.delayed(Duration(milliseconds: 100), () {
          emailFocusNode.requestFocus();
        });

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Palette.primary),
                  SizedBox(width: 8),
                  Text(
                    '관리자 로그인',
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Focus(
                      autofocus: true,
                      child: TextFormField(
                        controller: emailController,
                        focusNode: emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: '이메일',
                          hintText: 'gienglish.paju@gmail.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: TextStyle(fontFamily: "NotoSansKR"),
                        onFieldSubmitted: (value) {
                          passwordFocusNode.requestFocus();
                        },
                        onTap: () {
                          // 클릭 시에도 포커스 강제 설정
                          emailFocusNode.requestFocus();
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      focusNode: passwordFocusNode,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        hintText: 'gleam701',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: TextStyle(fontFamily: "NotoSansKR"),
                      onFieldSubmitted: (value) {
                        // Enter 키로 로그인 실행
                        _performLogin(context, emailController.text.trim(),
                            passwordController.text.trim());
                      },
                      onTap: () {
                        // 클릭 시에도 포커스 강제 설정
                        passwordFocusNode.requestFocus();
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _performLogin(context, emailController.text.trim(),
                        passwordController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    '로그인',
                    style: TextStyle(fontFamily: "NotoSansKR"),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _performLogin(
      BuildContext context, String email, String password) async {
    print('🚀 WebSchoolLayout: _performLogin 시작');
    print('📧 받은 이메일: "$email"');
    print('🔐 받은 비밀번호: "${password.length}자"');

    if (email.isEmpty || password.isEmpty) {
      print('❌ WebSchoolLayout: 빈 필드 감지');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이메일과 비밀번호를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('🔍 WebSchoolLayout: 로그인 정보 확인 중...');
      if (email == "gienglish.paju@gmail.com" && password == "gleam701") {
        print('✅ WebSchoolLayout: 로그인 정보 일치!');
        await AuthService.saveAdminSession(email, name: "관리자");
        print('💾 WebSchoolLayout: 관리자 세션 저장 완료');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('관리자 로그인에 성공했습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ WebSchoolLayout: 로그인 정보 불일치');
        print('🔍 예상 이메일: "gienglish.paju@gmail.com"');
        print('🔍 예상 비밀번호: "gleam701"');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 정보가 올바르지 않습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('💥 WebSchoolLayout: 로그인 오류 - $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget menuItem(String menuStr, Widget menuColumn) {
    return Column(
      children: [
        Container(
            height: widget.height,
            alignment: Alignment.center,
            child: Text(
              menuStr,
              style:
                  TextStyle(color: Palette.white, fontWeight: FontWeight.bold),
            )),
        menuColumn
      ],
    );
  }

  labelInColorContainer(Color selectedColor, String label) {
    return Container(
      alignment: Alignment.center,
      color: selectedColor,
      width: 140,
      height: 35,
      child: Text(label, style: TextStyle(color: Palette.white)),
    );
  }

  Widget menu1Column() {
    return Opacity(
      opacity: menu1Transparent ? 0 : 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolAboutPage());
            },
            child: labelInColorContainer(Palette.accent, "Gi글림아일랜드"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolTeachersPage());
            },
            child: labelInColorContainer(Palette.accent, "교원소개"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolSystemPage());
            },
            child: labelInColorContainer(Palette.accent, "운영System"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolMapPage());
            },
            child: labelInColorContainer(Palette.accent, "오시는 길"),
          )
        ],
      ),
    );
  }

  Widget menu2Column() {
    return Opacity(
      opacity: menu2Transparent ? 0 : 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolProgramPage());
            },
            child: labelInColorContainer(Palette.accent, "정규프로그램"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolAllDayPage());
            },
            child: labelInColorContainer(Palette.accent, "올데이케어"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolCampPage());
            },
            child: labelInColorContainer(Palette.accent, "방학캠프"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolNZPage());
            },
            child: labelInColorContainer(Palette.accent, "뉴질랜드프로그램"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, School1on1Page());
            },
            child: labelInColorContainer(Palette.accent, "1ON1프로그램"),
          )
        ],
      ),
    );
  }

  Widget menu3Column() {
    return Opacity(
      opacity: menu3Transparent ? 0 : 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolCurriculumMiddleSchoolPage());
            },
            child: labelInColorContainer(Palette.accent, "정규 중등부"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolCurriculumElePage());
            },
            child: labelInColorContainer(Palette.accent, "정규 초등부"),
          ),
        ],
      ),
    );
  }

  Widget menu4Column() {
    return Opacity(
      opacity: menu4Transparent ? 0 : 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolCommunityNoticePage());
            },
            child: labelInColorContainer(Palette.accent, "Notice Board"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolGalleryPage());
            },
            child: labelInColorContainer(Palette.accent, "Gallery"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolConsultationPage());
            },
            child: labelInColorContainer(Palette.accent, "입학상담"),
          ),
          InkWell(
            onTap: () {
              MenuUtil.push(context, SchoolCommunityFAQPage());
            },
            child: labelInColorContainer(Palette.accent, "FAQ"),
          )
        ],
      ),
    );
  }

  Widget appBar(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Palette.secondaryDark, Color(0xFF022C22)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 0,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),

        Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(top: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  MenuUtil.push(context, SchoolAboutPage());
                },
                child: Text(
                  "About",
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: "NotoSansKR",
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                width: 0.5,
                height: 10,
                color: Colors.white.withOpacity(0.3),
              ),
              InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolProgramPage());
                  },
                  child: Text(
                    "Program",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: "NotoSansKR",
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  )),
              Container(
                margin: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                width: 0.5,
                height: 10,
                color: Colors.white.withOpacity(0.3),
              ),
              InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolCurriculumElePage());
                  },
                  child: Text(
                    "Curriculum",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: "NotoSansKR",
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  )),
              Container(
                margin: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                width: 0.5,
                height: 10,
                color: Colors.white.withOpacity(0.3),
              ),
              InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolGalleryPage());
                  },
                  child: Text(
                    "Community",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: "NotoSansKR",
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  )),
              SizedBox(width: 20),
              // 관리자 로그인/로그아웃 버튼
              if (!_isAdmin)
                InkWell(
                  onTap: () {
                    _showAdminLoginDialog(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              if (_isAdmin) ...[
                InkWell(
                  onTap: () {
                    _logout();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "로그아웃",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: "NotoSansKR",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "관리자",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: "NotoSansKR",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(width: 20),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.only(top: 15.5, bottom: 15.5, left: 15),
          width: 300,
          alignment: Alignment.centerLeft,
          child: InkWell(
            child: Container(
                height: 49, child: Image.asset("assets/giEmblem.png")),
            onTap: () {
              MenuUtil.push(context, SchoolMainPage());
            },
          ),
        ),
        // Positioned(
        //   right:5, top: 5,
        //   child: Container(
        //     alignment: Alignment.topRight,
        //     padding: EdgeInsets.only(top: 5, bottom: 5, right: 10),
        //     child:InkWell(
        //       child: Container(width:30, height: 30, child: Image.asset("assets/loginButton.png")),
        //       onTap: () {
        //         showDialog(
        //             context: context,
        //             builder: (context) {
        //               return AlertDialog(
        //                   title: Text("로그인", textAlign: TextAlign.center,),
        //                   content: Container(
        //                     width: 280,
        //                     height: 240,
        //                     child: Column(
        //                       children: [
        //                         Divider(),
        //                         SizedBox(height: 10),
        //                         Expanded(
        //                           child: MyWidget.roundEdgeTextField(
        //                               "ID를 입력해주세요", idController),
        //                         ),
        //                         Expanded(
        //                           child: MyWidget.roundEdgeTextField(
        //                               "Password를 입력해주세요", pwController),
        //                         ),
        //                         SizedBox(height: 10),
        //                         Container(
        //                           width: 150,
        //                           height: 50,
        //                           child: ElevatedButton(
        //                             style: ElevatedButton.styleFrom(
        //                               primary: Palette.accent,
        //                               onPrimary: Palette.black,),
        //                             onPressed: () {},
        //                             child: Text("Login", style: TextStyle(fontFamily: "Jalnan"),),
        //                           ),
        //                         )
        //                       ],
        //                     ),
        //                   ));
        //             });
        //       },
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
