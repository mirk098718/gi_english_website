import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/SchoolAboutPage.dart';
import 'package:gi_english_website/pages/SchoolCurriculumElePage.dart';
import 'package:gi_english_website/pages/SchoolGalleryPage.dart';
import 'package:gi_english_website/pages/SchoolMainPage.dart';
import 'package:gi_english_website/pages/SchoolProgramPage.dart';
import 'package:gi_english_website/pages/WorkingAdminLoginPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/AuthService.dart';

class MobileSchoolLayout extends StatefulWidget {
  final Widget content;
  final double height = 52;

  MobileSchoolLayout({Key? key, required this.content}) : super(key: key);

  @override
  _MobileSchoolLayoutState createState() => _MobileSchoolLayoutState();
}

class _MobileSchoolLayoutState extends State<MobileSchoolLayout> {
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
              top: 111, bottom: 0, left: 0, right: 0, child: widget.content),
          Positioned(top: 60, left: 0, right: 0, child: appBar2(context)),
          Positioned(top: 0, left: 0, right: 0, child: appBar1(context))
        ],
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    print('🔧 MobileSchoolLayout: 관리자 로그인 다이얼로그 호출됨');
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
    print('📋 MobileSchoolLayout: _showSimpleLoginDialog 시작');
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String email = '';
    String password = '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        print('🎨 MobileSchoolLayout: Dialog builder 호출됨');
        return Dialog(
          child: Container(
            width: 300,
            padding: EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings,
                          color: Palette.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '관리자 로그인',
                        style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    autofocus: true,
                    initialValue: '',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      hintText: 'gienglish.paju@gmail.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, size: 18),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 14),
                    onChanged: (value) {
                      print('📧 MobileSchoolLayout: 이메일 입력됨 - "$value"');
                      email = value.trim();
                    },
                    onTap: () {
                      print('👆 MobileSchoolLayout: 이메일 필드 클릭됨');
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    initialValue: '',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      hintText: 'gleam701',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, size: 18),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 14),
                    onChanged: (value) {
                      print(
                          '🔐 MobileSchoolLayout: 비밀번호 입력됨 - "${value.length}자"');
                      password = value.trim();
                    },
                    onTap: () {
                      print('👆 MobileSchoolLayout: 비밀번호 필드 클릭됨');
                    },
                    onFieldSubmitted: (value) {
                      print('⏎ MobileSchoolLayout: 비밀번호 필드에서 Enter 키 눌림');
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
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          print('❌ MobileSchoolLayout: 취소 버튼 클릭됨');
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontFamily: "NotoSansKR",
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          print('✅ MobileSchoolLayout: 로그인 버튼 클릭됨');
                          print('📧 현재 이메일: "$email"');
                          print('🔐 현재 비밀번호: "${password.length}자"');
                          if (formKey.currentState!.validate()) {
                            Navigator.of(context).pop();
                            _performLogin(context, email, password);
                          } else {
                            print('❌ MobileSchoolLayout: 폼 유효성 검사 실패');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          '로그인',
                          style:
                              TextStyle(fontFamily: "NotoSansKR", fontSize: 14),
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

  void _performLogin(
      BuildContext context, String email, String password) async {
    print('🚀 MobileSchoolLayout: _performLogin 시작');
    print('📧 받은 이메일: "$email"');
    print('🔐 받은 비밀번호: "${password.length}자"');

    if (email.isEmpty || password.isEmpty) {
      print('❌ MobileSchoolLayout: 빈 필드 감지');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이메일과 비밀번호를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('🔍 MobileSchoolLayout: 로그인 정보 확인 중...');
      if (email == "gienglish.paju@gmail.com" && password == "gleam701") {
        print('✅ MobileSchoolLayout: 로그인 정보 일치!');
        await AuthService.saveAdminSession(email, name: "관리자");
        print('💾 MobileSchoolLayout: 관리자 세션 저장 완료');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('관리자 로그인에 성공했습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ MobileSchoolLayout: 로그인 정보 불일치');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 정보가 올바르지 않습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('💥 MobileSchoolLayout: 로그인 오류 - $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _oldShowAdminLoginDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final FocusNode emailFocusNode = FocusNode();
    final FocusNode passwordFocusNode = FocusNode();

    // 다이얼로그가 열린 후 포커스 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      emailFocusNode.requestFocus();
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings,
                  color: Palette.primary, size: 20),
              SizedBox(width: 8),
              Text(
                '관리자 로그인',
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Container(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  focusNode: emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    hintText: 'gienglish.paju@gmail.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email, size: 20),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: TextStyle(fontFamily: "NotoSansKR", fontSize: 14),
                  onFieldSubmitted: (value) {
                    passwordFocusNode.requestFocus();
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  focusNode: passwordFocusNode,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: 'gleam701',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock, size: 20),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: TextStyle(fontFamily: "NotoSansKR", fontSize: 14),
                  onFieldSubmitted: (value) {
                    // Enter 키로 로그인 실행
                    Navigator.of(context).pop();
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
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                if (email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('이메일과 비밀번호를 입력해주세요.',
                          style: TextStyle(fontFamily: "NotoSansKR")),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  if (email == "gienglish.paju@gmail.com" &&
                      password == "gleam701") {
                    await AuthService.saveAdminSession(email, name: "관리자");
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('관리자 로그인에 성공했습니다!',
                            style: TextStyle(fontFamily: "NotoSansKR")),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('로그인 정보가 올바르지 않습니다.',
                            style: TextStyle(fontFamily: "NotoSansKR")),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('로그인 중 오류가 발생했습니다.',
                          style: TextStyle(fontFamily: "NotoSansKR")),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                '로그인',
                style: TextStyle(fontFamily: "NotoSansKR", fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget appBar1(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 60,
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
          padding: EdgeInsets.symmetric(vertical: 4),
          width: double.maxFinite,
          alignment: Alignment.center,
          child: InkWell(
            child: Container(
                height: 49, child: Image.asset("assets/giEmblem.png")),
            onTap: () {
              MenuUtil.push(context, SchoolMainPage());
            },
          ),
        ),
        // 관리자 로그인/로그아웃 버튼 (모바일)
        if (!_isAdmin)
          Positioned(
            top: 15,
            right: 15,
            child: InkWell(
              onTap: () {
                _showAdminLoginDialog(context);
              },
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        if (_isAdmin)
          Positioned(
            top: 15,
            right: 15,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    _logout();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 2),
                        Text(
                          "로그아웃",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: "NotoSansKR",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.green[600],
                        size: 14,
                      ),
                      SizedBox(width: 2),
                      Text(
                        "관리자",
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 10,
                          fontFamily: "NotoSansKR",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget appBar2(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
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
        SizedBox(
          width: 30,
        ),
        Container(
          color: Colors.transparent,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // InkWell(
                //   child:
                //   Container(
                //       margin: EdgeInsets.only(left: 10, top: 10, bottom: 5),
                //       width:30, height: 30, child: Image.asset("assets/mobileLoginButton.png")),
                //   onTap: () {
                //     showDialog(
                //         context: context,
                //         builder: (context) {
                //           return AlertDialog(
                //               title: Text("로그인", textAlign: TextAlign.center,),
                //               content: Container(
                //                 width: 280,
                //                 height: 240,
                //                 child: Column(
                //                   children: [
                //                     Divider(),
                //                     SizedBox(height: 10),
                //                     Expanded(
                //                       child: MyWidget.roundEdgeTextField(
                //                           "ID를 입력해주세요", idController),
                //                     ),
                //                     Expanded(
                //                       child: MyWidget.roundEdgeTextField(
                //                           "Password를 입력해주세요", pwController),
                //                     ),
                //                     SizedBox(height: 10),
                //                     Container(
                //                       width: 150,
                //                       height: 50,
                //                       child: ElevatedButton(
                //                         style: ElevatedButton.styleFrom(
                //                           primary: Palette.accent,
                //                           onPrimary: Palette.black,),
                //                         onPressed: () {},
                //                         child: Text("Login", style: TextStyle(fontFamily: "Jalnan"),),
                //                       ),
                //                     )
                //                   ],
                //                 ),
                //               ));
                //         });
                //   },
                // ),
                SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolAboutPage());
                  },
                  child: Container(
                    height: widget.height,
                    alignment: Alignment.center,
                    child: Text(
                      "About GI",
                      style: TextStyle(
                          color: Colors.black,
                          fontFamily: "Jalnan",
                          fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(width: 30),
                InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolProgramPage());
                  },
                  child: Container(
                    height: widget.height,
                    alignment: Alignment.center,
                    child: Text(
                      "Program",
                      style: TextStyle(
                          color: Colors.black,
                          fontFamily: "Jalnan",
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(width: 30),
                InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolCurriculumElePage());
                  },
                  child: Container(
                      height: widget.height,
                      alignment: Alignment.center,
                      child: Text(
                        "Curriculum",
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: "Jalnan",
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      )),
                ),
                SizedBox(width: 30),
                InkWell(
                  onTap: () {
                    MenuUtil.push(context, SchoolGalleryPage());
                  },
                  child: Container(
                      height: widget.height,
                      alignment: Alignment.center,
                      child: Text(
                        "Community",
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: "Jalnan",
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      )),
                ),
                SizedBox(width: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
