# 📚 목차

  - 1 스플래시  온보딩 화면
    - 11 스플래시 화면
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세
      - BLoC 구조
    - 12 온보딩 화면
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세

---

## ✨ 1. 스플래시 & 온보딩 화면

### ✨ **1.1 스플래시 화면**

#### **화면 구성**
- 에뷰리띵 로고와 브랜드 슬로건 "에뷰리띵 하나로 뷰티 비용 걱정 끝!"
- 로딩 인디케이터
- 앱 초기화 진행 상태

#### **데이터베이스 상호작용**
> 💾 **데이터베이스 쿼리**
> ```sql
-- 사용자 세션 확인
SELECT * FROM auth.users WHERE id = current_user_id;

-- 사용자 프로필 정보 조회
SELECT user_status, last_login_at FROM public.users WHERE id = auth.uid();
> ```

#### **기능 및 로직**
1. **앱 초기화**
   - Supabase 클라이언트 초기화
   - FCM 토큰 등록/업데이트
   - 권한 상태 확인 (위치, 알림)

2. **세션 확인**
   - `auth.users` 테이블에서 현재 로그인 상태 확인
   - `users.last_login_at` 업데이트
   - `user_status`가 'active'인지 확인

3. **화면 전환 로직**
   - 로그인 상태 + 온보딩 완료 → 메인 화면
   - 로그인 상태 + 온보딩 미완료 → 온보딩 화면
   - 비로그인 상태 → 로그인/회원가입 화면

#### **UI/UX 구현 상세**
- 🎯 **로고**: `AnimatedContainer`로 페이드인 + 스케일 애니메이션 (1초)
- 💬 **슬로건**: `TypeWriter` 효과로 글자 하나씩 나타남 (0.5초 지연)
- ⏳ **로딩 인디케이터**: `CircularProgressIndicator.adaptive()` 하단 중앙
- 🌈 **배경**: 그라데이션 배경 (`LinearGradient`)
- 🔄 **전환**: `PageRouteBuilder`로 페이드 전환 (300ms)

#### **BLoC 구조**
> 📱 **Flutter/Dart 코드**
> ```dart
// SplashBloc
// Events: AppStarted
// States: SplashInitial, SplashLoading, SplashNavigateToMain, SplashNavigateToAuth
> ```

### 👋 **1.2 온보딩 화면**

#### **화면 구성**
- 2-3장의 슬라이드 (서비스 핵심 가치 전달)
- 슬라이드 1: "내 주변 뷰티샵 찾기"
- 슬라이드 2: "예약하고 포인트 받기"
- 슬라이드 3: "포인트로 할인받기"
- 페이지 인디케이터, 스킵/다음 버튼

#### **데이터베이스 상호작용**
> 💾 **데이터베이스 쿼리**
> ```sql
-- 온보딩 완료 상태 저장
UPDATE public.user_settings 
SET onboarding_completed = true 
WHERE user_id = auth.uid();
> ```

#### **기능 및 로직**
1. **슬라이드 탐색**
   - PageView 위젯으로 구현
   - 자동 슬라이드 및 수동 탐색 지원

2. **완료 처리**
   - `user_settings` 테이블에 온보딩 완료 플래그 저장
   - 메인 화면으로 자동 전환

#### **UI/UX 구현 상세**
- 📱 **슬라이드**: `PageView.builder`로 구현, `PageController`로 제어
- 📍 **인디케이터**: `AnimatedContainer`로 점 크기/색상 변화
- 🔘 **스킵 버튼**: `TextButton` 우상단, 탭 시 `bounceIn` 애니메이션
- 🔘 **다음 버튼**: `ElevatedButton` 하단, 슬라이드 전환 시 `slideInUp`
- 🖼️ **이미지**: `Hero` 위젯으로 슬라이드 간 부드러운 전환
- 📝 **텍스트**: `AnimatedSwitcher`로 페이드 인/아웃 (400ms)
- 👆 **제스처**: 스와이프 제스처로 슬라이드 변경, `hapticFeedback` 추가


---

