
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Function 자료형 -> 변수에 함수를 담겠다는 의지.........
// Function a; //a라는 변수를 만들어라. 거기에는 모든 함수를 넣겠다. -> null이 있음.
// Function(String b) a; //a라는 변수를 만들어라. 거기에는 String 입력이 1개 있는 함수를 넣겠다. -> null이 있음.
// Function() a; //a라는 변수를 만들어라. 거기에는 입력이 없는 함수를 넣겠다. -> null이 있음.
// void Function() a; //a라는 변수를 만들어라. 거기에는 입력이 없고 출력도 없는 함수를 넣겠다. -> null이 있음.
// Function 자료형이 너무 복잡하니깐, 이거를 별명으로 쉽게 만들자.... typeDef

//생성자는 왜 쓰나요?
//사람의 아기가 태어나면, 머리색이랑, 뇌, 눈이랑.. 이런게 결정남.
//만들어지기전에, 필드를 채우겠다.

//클래스 : 설계도
//인스턴스 : 만든 각각의 실체.
//인스턴스 어떻게 만들죠? 클래스명() -> 생성자를 실행함.(필드를 채움) -> 인스턴스가 만들어짐.
//var listener = EasyKeyboardListener();
//listener.눈 = "";

class EasyKeyboardListener extends StatelessWidget {
  //static을 붙이면 클래스 필드 메소드가 된다.
  //(기본값)인스턴스 필드->변수를빌림 (정적속성)
  final focusNode = FocusNode();
  final ValueChanged<String> onValue;
  final Widget child;
  final int inputLimit;
  String input = "";

  //(기본값)인스턴스 메소드->함수를빌림 (동적속성)
  //생성자(특별한 함수(메소드))
  //1. 클래스와 이름이 같다.
  //2. 반환자료형이 없다.
  EasyKeyboardListener(
      {Key? key,
        required this.child,
        required this.inputLimit,
        required this.onValue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(focusNode); // Add this line
    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: (keyEvent) {
        if (keyEvent is KeyDownEvent) {
          input += keyEvent.character ?? "";
          if (input.length >= (inputLimit + 1)) {
            input = input.substring(1);
          }

          onValue(input);
        }
      },
      child: child,
    );
  }
}