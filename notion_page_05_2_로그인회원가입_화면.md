# 📚 목차

  - 2 로그인회원가입 화면
    - 21 소셜 로그인 화면
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세
    - 22 회원가입 화면
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세
    - 23 회원가입 완료 화면
      - 화면 구성
      - 기능 및 로직
      - UIUX 구현 상세

---

## 🔐 2. 로그인/회원가입 화면

### 🔐 **2.1 소셜 로그인 화면**

#### **화면 구성**
- 카카오, 애플, 구글 로그인 버튼
- 서비스 이용약관 및 개인정보처리방침 링크
- "회원가입" 버튼

#### **데이터베이스 상호작용**
> 💾 **데이터베이스 쿼리**
> ```sql
-- 소셜 로그인 사용자 정보 생성/업데이트
INSERT INTO public.users (
    id, email, name, social_provider, social_provider_id,
    referral_code, created_at
) VALUES (
    auth.uid(), $email, $name, $provider, $provider_id,
    generate_referral_code(), NOW()
) ON CONFLICT (id) DO UPDATE SET
    last_login_at = NOW();

-- 기본 사용자 설정 생성
INSERT INTO public.user_settings (user_id) 
VALUES (auth.uid()) 
ON CONFLICT (user_id) DO NOTHING;
> ```

#### **기능 및 로직**
1. **Supabase Auth 연동**
   - 각 소셜 프로바이더별 OAuth 플로우
   - `social_provider` enum 값으로 저장
   - `auth.users`와 `public.users` 테이블 동기화

2. **신규 사용자 처리**
   - 자동으로 고유 `referral_code` 생성
   - 기본 `user_settings` 레코드 생성
   - 회원가입 화면으로 이동 (추가 정보 입력)

3. **기존 사용자 처리**
   - `last_login_at` 업데이트
   - 메인 화면으로 바로 이동

#### **UI/UX 구현 상세**
- 🎯 **로고**: 상단 중앙, `FadeInDown` 애니메이션 (800ms)
- 🔘 **소셜 버튼들**: `Column`으로 배치, 각각 다른 지연시간으로 `slideInLeft`
  - 💛 **카카오**: 노란색 `ElevatedButton`, 카카오 로고 + "카카오로 시작하기"
  - 🍎 **애플**: 검은색/흰색 테마별, 애플 로고 + "Apple로 계속하기"  
  - 🔵 **구글**: 흰색 테두리, 구글 로고 + "Google로 계속하기"
- 🔘 **버튼 상태**: 탭 시 `scale` 애니메이션 (150ms), 로딩 시 `CircularProgressIndicator`
- **약관 링크**: `RichText`로 밑줄, 탭 시 `InAppWebView` 모달
- 🔘 **회원가입 버튼**: `OutlinedButton`, 하단 배치
- **키보드 대응**: `SingleChildScrollView` + `Padding`

### 📝 **2.2 회원가입 화면**

#### **화면 구성**
- 이름 입력 필드
- 성별 선택 (male, female, other, prefer_not_to_say)
- 생년월일 선택 (DatePicker)
- 전화번호 입력 및 인증
- 이메일 입력 (선택사항)
- 추천인 코드 입력 (선택사항)
- 필수/선택 약관 동의 체크박스
- 가입 완료 버튼

#### **데이터베이스 상호작용**
> 💾 **데이터베이스 쿼리**
> ```sql
-- 사용자 정보 업데이트
UPDATE public.users SET
    name = $name,
    gender = $gender::user_gender,
    birth_date = $birth_date,
    phone_number = $phone_number,
    phone_verified = $phone_verified,
    email = $email,
    referred_by_code = $referral_code,
    terms_accepted_at = NOW(),
    privacy_accepted_at = NOW(),
    marketing_consent = $marketing_consent
WHERE id = auth.uid();

-- 추천인 확인 및 통계 업데이트
UPDATE public.users SET 
    total_referrals = total_referrals + 1
WHERE referral_code = $referred_by_code;
> ```

#### **기능 및 로직**
1. **PASS인증 연동**
   - 한국 휴대폰 인증 서비스
   - `phone_verified` 플래그 업데이트
   - 본인인증 완료 후 추가 정보 입력 가능

2. **추천인 시스템**
   - 입력된 추천인 코드 유효성 검증
   - 추천인의 `total_referrals` 카운트 증가
   - 추천 관계 데이터 저장

3. **약관 동의**
   - 필수 약관: 서비스 이용약관, 개인정보처리방침
   - 선택 약관: 마케팅 정보 수신 동의
   - 동의 시점 `terms_accepted_at`, `privacy_accepted_at` 저장

#### **UI/UX 구현 상세**
- 📍 **진행 인디케이터**: 상단 `LinearProgressIndicator`, 단계별 진행률 표시
- **이름 필드**: `TextFormField` + `validator`, 포커스 시 테두리 색상 변화
- **성별 선택**: `ToggleButtons` 또는 `SegmentedButton`, 선택 시 `scale` 효과
- **생년월일**: `DatePicker` 모달, 선택 완료 시 `slideInRight` 애니메이션
- **전화번호**: 
  - `TextFormField` + 한국 형식 마스킹 (`010-0000-0000`)
  - 🔘 **인증 버튼**: `ElevatedButton`, 인증 중 `CircularProgressIndicator`
  - **타이머**: `AnimatedSwitcher`로 카운트다운 (3분)
- **추천인 코드**: `TextFormField`, 입력 시 실시간 유효성 검사, 체크 아이콘
- **약관 동의**: 
  - `CheckboxListTile` 그룹, 전체 동의 토글 기능
  - 약관 보기 시 `BottomSheet` 슬라이드업
- 🔘 **완료 버튼**: `AnimatedContainer`, 모든 필수 입력 완료 시 활성화
- **키보드**: `autofocus` 순서 제어, `textInputAction.next`

### 📝 **2.3 회원가입 완료 화면**

#### **화면 구성**
- 환영 메시지
- 가입 완료 확인
- "시작하기" 버튼

#### **기능 및 로직**
- 메인 화면으로 이동
- 첫 로그인 플래그 설정

#### **UI/UX 구현 상세**
- **축하 애니메이션**: `Lottie` 또는 `Rive` 애니메이션 (파티클, 폭죽 효과)
- **환영 메시지**: `AnimatedTextKit`로 타이핑 효과
- **프로필 미리보기**: `CircleAvatar` + 기본 이미지, `pulse` 애니메이션
- 🔘 **시작하기 버튼**: `Hero` 위젯, 탭 시 메인 화면으로 확장 전환
- 🌈 **배경**: 성공을 나타내는 그라데이션 + 떠다니는 파티클
- **haptic**: 성공 햅틱 피드백 (`HapticFeedback.lightImpact`)


---

