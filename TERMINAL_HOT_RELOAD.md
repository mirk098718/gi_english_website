# Hot Reload 사용 방법 (어느 터미널에서 할지)

## 둘 중 어디가 Flutter 터미널인지 구분하기

### ❌ **쉘 터미널** (여기서 `r` 넣으면 Hot reload 안 됨)
- 맨 아래에 **`namheekim@Namhees-MacBook-Pro gi_english_website %`** 같은 **쉘 프롬프트**가 보임
- 여기서 `r` 입력 시 → **Hot reload가 아니라** 쉘 명령(예: `flutter pub get` 등)이 실행됨
- **터미널 2**, **터미널 10**이 이 경우에 해당

### ✅ **Flutter 실행 터미널** (여기서만 `r`이 Hot reload)
- 화면에 **"Flutter run key commands."** / **"r Hot reload. 🔥🔥🔥"** 문구가 보임
- **`%` 같은 쉘 프롬프트가 없음** (Flutter가 입력을 기다리는 상태)
- `flutter run -d chrome`을 **직접 실행한 그 터미널**이 이쪽

---

## Hot reload가 안 될 때 할 일

1. **새 터미널 하나**를 연다 (Cursor 하단 터미널에서 `+` 또는 새 터미널).
2. 그 터미널에서만 아래를 실행한다.
   ```bash
   cd /Users/namheekim/Project/gi_english_website
   flutter run -d chrome
   ```
3. 빌드가 끝나면 **"Flutter run key commands."** / **"r Hot reload"** 가 보인다.
4. **반드시 그 터미널 탭을 클릭**해서 포커스를 준 뒤, 키보드에서 **`r`** 한 글자만 입력한다.
5. 이때는 Hot reload가 동작한다. (레이아웃/이미지 변경은 **`R`** 대문자 Hot Restart가 나을 수 있음)

---

## 정리

| 보이는 것 | 이 터미널에서 `r` 입력 시 |
|-----------|---------------------------|
| `%` 프롬프트 (쉘) | ❌ Hot reload 안 됨 → 쉘 명령 실행 |
| "Flutter run key commands." (프롬프트 없음) | ✅ Hot reload 됨 |

**지금 쓰는 터미널 2, 10에는 `%`가 보이므로** Hot reload용 터미널이 아닙니다.  
**새 터미널을 열고** `flutter run -d chrome`만 실행한 **그 터미널**에서 `r`을 눌러야 합니다.
