# iPad 물리 디바이스 테스트 매뉴얼

> 최종 업데이트: 2026-03-14

## 목차

1. [사전 준비](#1-사전-준비)
2. [iPad 설정](#2-ipad-설정)
3. [빌드 및 실행](#3-빌드-및-실행)
4. [iOS 26 Debug 모드 제한사항](#4-ios-26-debug-모드-제한사항)
5. [트러블슈팅](#5-트러블슈팅)

---

## 1. 사전 준비

### Mac 측 요구사항

- Xcode 최신 버전 (현재: Xcode 16+)
- Flutter SDK (현재: 3.29.1, iOS 26 debug용은 3.35+ 필요)
- CocoaPods (`sudo gem install cocoapods`)
- Apple Developer 계정 (Team ID: TTUHHR96GR)
- USB-C 케이블 (iPad 연결용)

### 현재 테스트 디바이스

| 항목 | 값 |
|------|-----|
| 기기명 | WY IPAD |
| UDID | `00008103-0011491E0EBB001E` |
| iOS | 26.3.1 |
| Bundle ID | `com.bdr.bdrTournamentRecorder` |

---

## 2. iPad 설정

### 2-1. 개발자 모드 활성화

1. **설정** > **개인정보 보호 및 보안** > **개발자 모드** 활성화
2. iPad 재시작 요구 시 재시작
3. 재시작 후 "개발자 모드 활성화" 확인 팝업에서 **활성화** 선택

### 2-2. 앱 신뢰 설정 (첫 설치 시)

1. 앱 설치 후 아이콘 탭하면 "신뢰할 수 없는 개발자" 알림 표시
2. **설정** > **일반** > **VPN 및 기기 관리**
3. 개발자 앱 아래 Apple Development 인증서 선택
4. **"[개발자명] 신뢰"** 탭

### 2-3. Mac IP 확인

```bash
# 현재 Mac의 로컬 IP 확인
ipconfig getifaddr en0
```

iPad와 Mac이 **같은 Wi-Fi 네트워크**에 연결되어 있어야 합니다.

---

## 3. 빌드 및 실행

### 3-1. mybdr Next.js 서버 실행 (Mac에서)

```bash
cd /Users/grizrider/CC/mybdr
npm run dev
```

서버가 `http://localhost:3000`에서 실행 중이어야 합니다.

### 3-2. Profile 모드 빌드 및 설치 (권장)

iOS 26에서는 debug 모드가 동작하지 않으므로 profile 모드를 사용합니다.

```bash
cd /Users/grizrider/CC/BDR/bdr_stat

# 1단계: 빌드
flutter build ios --profile --dart-define=DEV_SERVER_IP=172.30.1.38

# 2단계: iPad에 설치
xcrun devicectl device install app \
  --device 00008103-0011491E0EBB001E \
  build/ios/iphoneos/Runner.app
```

> IP가 바뀌었을 경우 `ipconfig getifaddr en0`으로 확인 후 `DEV_SERVER_IP` 값을 변경하세요.

### 3-3. Release 모드 빌드

프로덕션 환경 테스트 시:

```bash
flutter build ios --release --dart-define=ENV=production
xcrun devicectl device install app \
  --device 00008103-0011491E0EBB001E \
  build/ios/iphoneos/Runner.app
```

### 3-4. flutter run 사용 (Profile 모드)

빌드와 설치를 한 번에 하려면:

```bash
flutter run --profile \
  -d 00008103-0011491E0EBB001E \
  --dart-define=DEV_SERVER_IP=172.30.1.38
```

> 주의: Xcode 자동화 권한 팝업이 뜰 수 있습니다. "허용"을 선택하세요.
> 팝업이 뜨지 않는데 설치가 실패하면, 아래 3-2 방식(빌드 후 수동 설치)을 사용하세요.

### 3-5. 시뮬레이터 실행 (비교용)

시뮬레이터에서는 debug 모드가 정상 동작합니다:

```bash
flutter run -d C801474B-36EA-481C-AE29-B2B19EFF0A03
```

시뮬레이터는 Mac의 localhost에 직접 접근 가능하므로 `DEV_SERVER_IP` 지정이 불필요합니다.

---

## 4. iOS 26 Debug 모드 제한사항

### 문제

iOS 26 (beta)에서 메모리 보호 정책이 강화되어 Flutter의 JIT 컴파일이 차단됩니다.
Debug 모드 실행 시 다음 에러가 발생합니다:

```
error: mprotect failed: 13 (Permission denied)
```

공식 이슈: https://github.com/flutter/flutter/issues/163984

### 영향

| 기능 | Debug | Profile | Release |
|------|-------|---------|---------|
| 앱 실행 | 불가 | 가능 | 가능 |
| Hot Reload | 불가 | 불가 | 불가 |
| Hot Restart | 불가 | 불가 | 불가 |
| 브레이크포인트 | 불가 | 불가 | 불가 |
| 성능 프로파일링 | 불가 | 가능 | 불가 |
| DevTools 연결 | 불가 | 가능 | 불가 |

### 해결 방법

**방법 1 (권장)**: Flutter 3.35+ 로 업그레이드

```bash
flutter upgrade
```

3.35 이상에서 iOS 26 debug 모드 지원이 추가되었습니다.

**방법 2**: Profile 모드 사용 (현재 방식)

Hot Reload는 사용할 수 없지만, DevTools 프로파일링은 가능합니다.

**방법 3**: iOS 18.x 디바이스 사용

iOS 18.3 이하 기기에서는 debug 모드가 정상 동작합니다.

---

## 5. 트러블슈팅

### 5-1. `Pods_Runner framework not found` 에러

Xcode에서 빌드 시 링커 에러가 발생하는 경우:

```bash
cd /Users/grizrider/CC/BDR/bdr_stat

# 1. 전체 클린
flutter clean

# 2. 의존성 재설치
flutter pub get

# 3. Pods 완전 재설치
cd ios
rm -rf Pods Podfile.lock
pod install

# 4. DerivedData 삭제
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# 5. 빌드 확인
cd ..
flutter build ios --profile --dart-define=DEV_SERVER_IP=$(ipconfig getifaddr en0)
```

**원인**: CocoaPods의 xcconfig가 프로젝트 빌드 설정과 충돌하면 Pods 프레임워크가
링크되지 않습니다. `flutter clean` + `pod install` 재실행으로 해결됩니다.

### 5-2. `flutter run --profile` 설치 실패

```
Could not run build/ios/iphoneos/Runner.app on 00008103-...
Try launching Xcode and selecting "Product > Run"
```

**해결**: 빌드와 설치를 분리합니다.

```bash
# 빌드만
flutter build ios --profile --dart-define=DEV_SERVER_IP=172.30.1.38

# 수동 설치
xcrun devicectl device install app \
  --device 00008103-0011491E0EBB001E \
  build/ios/iphoneos/Runner.app
```

또는 Xcode에서 직접 실행:

```bash
open ios/Runner.xcworkspace
```

Xcode에서 Target Device를 "WY IPAD"로 선택 > Product > Run (Profile scheme)

### 5-3. 코드 서명 에러

```
Signing for "Runner" requires a development team
```

**해결**: `ios/Runner.xcodeproj/project.pbxproj`에서 `DEVELOPMENT_TEAM`이
`TTUHHR96GR`로 설정되어 있는지 확인합니다. 또는 Xcode에서:

1. Runner.xcworkspace 열기
2. Runner 프로젝트 > Signing & Capabilities
3. Team 선택 > 본인 Apple Developer 계정

### 5-4. 네트워크 연결 안 됨 (앱에서 API 호출 실패)

**체크리스트**:

1. Mac과 iPad가 같은 Wi-Fi에 연결되어 있는가?
2. mybdr Next.js 서버가 실행 중인가? (`npm run dev`)
3. Mac 방화벽이 3000번 포트를 차단하고 있지 않은가?
4. `DEV_SERVER_IP`에 올바른 IP가 지정되었는가?

```bash
# Mac IP 재확인
ipconfig getifaddr en0

# iPad에서 접근 가능한지 테스트 (Mac에서)
curl http://$(ipconfig getifaddr en0):3000/api/v1/health
```

### 5-5. iPad가 Flutter에서 감지되지 않음

```bash
# 연결된 기기 목록 확인
flutter devices

# Xcode에서 기기 확인
xcrun devicectl list devices
```

**체크리스트**:

1. USB 케이블이 연결되어 있는가? (충전 전용 케이블이 아닌 데이터 케이블)
2. iPad에서 "이 컴퓨터를 신뢰하시겠습니까?" 팝업에 "신뢰"를 선택했는가?
3. iPad 개발자 모드가 활성화되어 있는가?

### 5-6. CocoaPods 경고 메시지

```
CocoaPods did not set the base configuration of your project
because your project already has a custom config set.
```

**해결**: 이 경고는 Flutter의 `Debug.xcconfig`/`Release.xcconfig`가 이미 Pods
xcconfig을 `#include`하고 있어서 발생합니다. 대부분의 경우 무시해도 되지만,
Pods 프레임워크 링크 에러가 동반되면 5-1 절차를 따르세요.

---

## 환경별 빌드 커맨드 요약

| 용도 | 커맨드 |
|------|--------|
| 시뮬레이터 개발 | `flutter run -d C801474B-36EA-481C-AE29-B2B19EFF0A03` |
| iPad 개발 테스트 | `flutter build ios --profile --dart-define=DEV_SERVER_IP=$(ipconfig getifaddr en0)` + `xcrun devicectl device install app --device 00008103-0011491E0EBB001E build/ios/iphoneos/Runner.app` |
| iPad 프로덕션 테스트 | `flutter build ios --release --dart-define=ENV=production` + `xcrun devicectl device install app --device 00008103-0011491E0EBB001E build/ios/iphoneos/Runner.app` |
| 앱스토어 배포 | `flutter build ipa --dart-define=ENV=production` |
