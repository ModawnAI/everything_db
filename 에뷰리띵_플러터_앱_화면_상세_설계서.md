# 에뷰리띵 플러터 앱 화면 상세 설계서

## 📱 개요
본 문서는 에뷰리띵 플러터 앱의 모든 화면에 대한 상세한 기능 정의와 데이터베이스 스키마와의 상호작용을 설명합니다. PRD.txt, flutter.md, Supabase 스키마를 기반으로 작성되었습니다.

---

## 🏗️ 아키텍처 개요

### **상태 관리 및 데이터 흐름**
- **BLoC 패턴**: 모든 화면에서 상태 관리
- **Repository 패턴**: Supabase 데이터 접근 추상화
- **의존성 주입**: Provider를 통한 서비스 관리
- **에러 처리**: 통합 에러 처리 시스템

---

## 📋 화면별 상세 설계

## 1. 스플래시 & 온보딩 화면

### **1.1 스플래시 화면**

#### **화면 구성**
- 에뷰리띵 로고와 브랜드 슬로건 "에뷰리띵 하나로 뷰티 비용 걱정 끝!"
- 로딩 인디케이터
- 앱 초기화 진행 상태

#### **데이터베이스 상호작용**
```sql
-- 사용자 세션 확인
SELECT * FROM auth.users WHERE id = current_user_id;

-- 사용자 프로필 정보 조회
SELECT user_status, last_login_at FROM public.users WHERE id = auth.uid();
```

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
- **로고**: `AnimatedContainer`로 페이드인 + 스케일 애니메이션 (1초)
- **슬로건**: `TypeWriter` 효과로 글자 하나씩 나타남 (0.5초 지연)
- **로딩 인디케이터**: `CircularProgressIndicator.adaptive()` 하단 중앙
- **배경**: 그라데이션 배경 (`LinearGradient`)
- **전환**: `PageRouteBuilder`로 페이드 전환 (300ms)

#### **BLoC 구조**
```dart
// SplashBloc
// Events: AppStarted
// States: SplashInitial, SplashLoading, SplashNavigateToMain, SplashNavigateToAuth
```

### **1.2 온보딩 화면**

#### **화면 구성**
- 2-3장의 슬라이드 (서비스 핵심 가치 전달)
- 슬라이드 1: "내 주변 뷰티샵 찾기"
- 슬라이드 2: "예약하고 포인트 받기"
- 슬라이드 3: "포인트로 할인받기"
- 페이지 인디케이터, 스킵/다음 버튼

#### **데이터베이스 상호작용**
```sql
-- 온보딩 완료 상태 저장
UPDATE public.user_settings 
SET onboarding_completed = true 
WHERE user_id = auth.uid();
```

#### **기능 및 로직**
1. **슬라이드 탐색**
   - PageView 위젯으로 구현
   - 자동 슬라이드 및 수동 탐색 지원

2. **완료 처리**
   - `user_settings` 테이블에 온보딩 완료 플래그 저장
   - 메인 화면으로 자동 전환

#### **UI/UX 구현 상세**
- **슬라이드**: `PageView.builder`로 구현, `PageController`로 제어
- **인디케이터**: `AnimatedContainer`로 점 크기/색상 변화
- **스킵 버튼**: `TextButton` 우상단, 탭 시 `bounceIn` 애니메이션
- **다음 버튼**: `ElevatedButton` 하단, 슬라이드 전환 시 `slideInUp`
- **이미지**: `Hero` 위젯으로 슬라이드 간 부드러운 전환
- **텍스트**: `AnimatedSwitcher`로 페이드 인/아웃 (400ms)
- **제스처**: 스와이프 제스처로 슬라이드 변경, `hapticFeedback` 추가

---

## 2. 로그인/회원가입 화면

### **2.1 소셜 로그인 화면**

#### **화면 구성**
- 카카오, 애플, 구글 로그인 버튼
- 서비스 이용약관 및 개인정보처리방침 링크
- "회원가입" 버튼

#### **데이터베이스 상호작용**
```sql
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
```

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
- **로고**: 상단 중앙, `FadeInDown` 애니메이션 (800ms)
- **소셜 버튼들**: `Column`으로 배치, 각각 다른 지연시간으로 `slideInLeft`
  - **카카오**: 노란색 `ElevatedButton`, 카카오 로고 + "카카오로 시작하기"
  - **애플**: 검은색/흰색 테마별, 애플 로고 + "Apple로 계속하기"  
  - **구글**: 흰색 테두리, 구글 로고 + "Google로 계속하기"
- **버튼 상태**: 탭 시 `scale` 애니메이션 (150ms), 로딩 시 `CircularProgressIndicator`
- **약관 링크**: `RichText`로 밑줄, 탭 시 `InAppWebView` 모달
- **회원가입 버튼**: `OutlinedButton`, 하단 배치
- **키보드 대응**: `SingleChildScrollView` + `Padding`

### **2.2 회원가입 화면**

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
```sql
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
```

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
- **진행 인디케이터**: 상단 `LinearProgressIndicator`, 단계별 진행률 표시
- **이름 필드**: `TextFormField` + `validator`, 포커스 시 테두리 색상 변화
- **성별 선택**: `ToggleButtons` 또는 `SegmentedButton`, 선택 시 `scale` 효과
- **생년월일**: `DatePicker` 모달, 선택 완료 시 `slideInRight` 애니메이션
- **전화번호**: 
  - `TextFormField` + 한국 형식 마스킹 (`010-0000-0000`)
  - **인증 버튼**: `ElevatedButton`, 인증 중 `CircularProgressIndicator`
  - **타이머**: `AnimatedSwitcher`로 카운트다운 (3분)
- **추천인 코드**: `TextFormField`, 입력 시 실시간 유효성 검사, 체크 아이콘
- **약관 동의**: 
  - `CheckboxListTile` 그룹, 전체 동의 토글 기능
  - 약관 보기 시 `BottomSheet` 슬라이드업
- **완료 버튼**: `AnimatedContainer`, 모든 필수 입력 완료 시 활성화
- **키보드**: `autofocus` 순서 제어, `textInputAction.next`

### **2.3 회원가입 완료 화면**

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
- **시작하기 버튼**: `Hero` 위젯, 탭 시 메인 화면으로 확장 전환
- **배경**: 성공을 나타내는 그라데이션 + 떠다니는 파티클
- **haptic**: 성공 햅틱 피드백 (`HapticFeedback.lightImpact`)

---

## 3. 메인 화면 (홈)

### **3.1 홈 화면 메인**

#### **화면 구성**
- **상단 헤더**
  - 현재 위치 표시 및 변경 버튼
  - 검색창
  - 알림 아이콘 (읽지 않은 알림 개수 뱃지)

- **내 주변 샵 섹션**
  - 위치 기반 샵 목록 (30개씩 페이징)
  - Pull-to-refresh 기능
  - 거리 표시

- **추천/인기 샵 섹션**
  - 캐러셀 형태의 샵 카드
  - 파트너십 샵 우선 노출

- **카테고리별 탐색**
  - 네일, 속눈썹, 왁싱, 눈썹문신 아이콘
  - 헤어 (비활성화 상태)

- **내가 찜한 샵**
  - 즐겨찾기한 샵 목록

- **이벤트/프로모션 배너**

#### **데이터베이스 상호작용**
```sql
-- 위치 기반 샵 조회 (알고리즘 적용)
SELECT s.*, 
       ST_Distance(s.location, ST_Point($longitude, $latitude)::geography) as distance,
       COUNT(r.id) as total_bookings
FROM public.shops s
LEFT JOIN public.reservations r ON s.id = r.shop_id
WHERE s.shop_status = 'active'
  AND ST_DWithin(s.location, ST_Point($longitude, $latitude)::geography, 10000) -- 10km 반경
ORDER BY 
  CASE WHEN s.shop_type = 'partnered' THEN 0 ELSE 1 END,  -- 입점샵 우선
  s.partnership_started_at DESC,  -- 최신 입점순
  distance ASC
LIMIT 30 OFFSET $offset;

-- 사용자 즐겨찾기 샵 조회
SELECT s.*, uf.created_at as favorited_at
FROM public.user_favorites uf
JOIN public.shops s ON uf.shop_id = s.id
WHERE uf.user_id = auth.uid()
  AND s.shop_status = 'active'
ORDER BY uf.created_at DESC;

-- 읽지 않은 알림 개수
SELECT COUNT(*) FROM public.notifications 
WHERE user_id = auth.uid() AND status = 'unread';
```

#### **기능 및 로직**
1. **위치 서비스**
   - GPS 권한 요청 및 현재 위치 획득
   - Geolocator 패키지 사용
   - 위치 정보를 `geography` 타입으로 저장

2. **샵 노출 알고리즘 (PRD 2.1 정책)**
   - 입점샵(`shop_type = 'partnered'`) 우선 노출
   - 입점샵 내에서는 최신 입점순 (`partnership_started_at DESC`)
   - 이후 거리순 정렬

3. **페이징 및 성능**
   - 초기 30개 로드, 스크롤 시 추가 로드
   - `LIMIT/OFFSET` 방식 또는 cursor-based pagination

4. **실시간 업데이트**
   - 위치 변경 시 자동 재조회
   - Pull-to-refresh로 수동 갱신

#### **UI/UX 구현 상세**
- **상단 헤더**:
  - **위치 버튼**: `InkWell` + 아이콘, 탭 시 위치 선택 `BottomSheet`
  - **검색창**: `TextField` + 힌트 텍스트, 포커스 시 검색 화면으로 네비게이션
  - **알림 아이콘**: `IconButton` + `Badge`, 읽지 않은 개수 표시

- **내 주변 샵 섹션**:
  - **새로고침**: `RefreshIndicator`, 당겨서 새로고침
  - **샵 카드**: `Card` + `Hero` 애니메이션, 탭 시 상세 화면
  - **로딩**: `Shimmer` 효과로 스켈레톤 UI
  - **무한 스크롤**: `ListView.builder` + 하단 도달 시 추가 로드

- **추천 샵 섹션**:
  - **캐러셀**: `PageView.builder` + `PageIndicator`
  - **자동 슬라이드**: 3초 간격, 터치 시 정지
  - **샵 카드**: 그라데이션 오버레이 + 파트너 배지

- **카테고리 섹션**:
  - **그리드**: `GridView.count` (2x2), 각 아이템 `staggered` 애니메이션
  - **아이콘**: 카테고리별 컬러 테마, 탭 시 `bounce` 효과
  - **비활성화**: 헤어 카테고리 회색 처리 + "준비중" 텍스트

- **즐겨찾기**: `AnimatedList`로 추가/제거 애니메이션
- **배너**: `Carousel` + 자동 재생, 탭 시 해당 이벤트 페이지

#### **BLoC 구조**
```dart
// HomeBloc
// Events: LoadNearbyShops, RefreshShops, LocationChanged, LoadFavoriteShops
// States: HomeLoading, HomeLoaded, HomeError
```

### **3.2 하단 네비게이션**

#### **화면 구성**
- 홈, 피드, 검색, 마이예약, MY (5개 탭)
- 각 탭별 뱃지 시스템
- 탭 전환 애니메이션

#### **기능 및 로직**
- Go Router를 통한 탭 기반 네비게이션
- 각 탭의 상태 보존
- 딥링크 지원

#### **UI/UX 구현 상세**
- **탭 컨테이너**: `BottomNavigationBar` + 둥근 모서리, 그림자 효과
- **아이콘**: 선택/비선택 상태별 다른 아이콘, `AnimatedSwitcher`로 전환
- **뱃지**: `Badge` 위젯, 새 알림/예약 시 `bounce` 애니메이션
- **탭 전환**: `AnimatedContainer`로 선택된 탭 하이라이트
- **haptic**: 탭 변경 시 `HapticFeedback.selectionClick`
- **라벨**: 선택된 탭만 라벨 표시, `AnimatedOpacity`로 페이드
- **안전 영역**: `SafeArea`로 하단 여백 처리

---

## 4. 샵 탐색 및 검색 결과 화면

### **4.1 검색 화면**

#### **화면 구성**
- **상단 검색 바**
  - 검색어 입력 필드
  - 필터 버튼
  - 정렬 옵션 버튼

- **검색 결과 목록**
  - 샵 카드 (이미지, 이름, 평점, 거리, 파트너십 상태)
  - 무한 스크롤
  - 목록/지도 뷰 토글

- **필터 옵션**
  - 서비스 카테고리
  - 가격대
  - 거리
  - 평점
  - 영업 상태

#### **데이터베이스 상호작용**
```sql
-- 검색 및 필터링 쿼리
SELECT s.*, 
       ST_Distance(s.location, ST_Point($longitude, $latitude)::geography) as distance,
       array_agg(DISTINCT ss.category) as available_categories,
       MIN(ss.price_min) as min_price,
       MAX(ss.price_max) as max_price
FROM public.shops s
JOIN public.shop_services ss ON s.id = ss.shop_id
WHERE s.shop_status = 'active'
  AND ($search_term IS NULL OR s.name ILIKE '%' || $search_term || '%')
  AND ($category IS NULL OR ss.category = $category::service_category)
  AND ($min_price IS NULL OR ss.price_min >= $min_price)
  AND ($max_price IS NULL OR ss.price_max <= $max_price)
  AND ($max_distance IS NULL OR ST_Distance(s.location, ST_Point($longitude, $latitude)::geography) <= $max_distance)
GROUP BY s.id
ORDER BY 
  CASE $sort_type 
    WHEN 'distance' THEN distance
    WHEN 'price_low' THEN MIN(ss.price_min)
    WHEN 'price_high' THEN MAX(ss.price_max) DESC
    ELSE s.partnership_started_at DESC
  END
LIMIT 30 OFFSET $offset;

-- 최근 검색어 저장
INSERT INTO public.user_search_history (user_id, search_term, created_at)
VALUES (auth.uid(), $search_term, NOW());
```

#### **기능 및 로직**
1. **실시간 검색**
   - 검색어 디바운싱 (500ms)
   - 자동완성 기능
   - 최근 검색어 저장

2. **고급 필터링**
   - 다중 카테고리 선택
   - 가격 범위 슬라이더
   - 거리 기반 필터링
   - 영업시간 필터

3. **정렬 옵션**
   - 거리순 (기본)
   - 평점순
   - 가격 낮은순/높은순
   - 최신 입점순

#### **UI/UX 구현 상세**
- **검색창**:
  - `TextField` + `debouncer` (500ms), 검색 중 로딩 아이콘
  - **자동완성**: `TypeAhead` 위젯, 드롭다운 검색 제안
  - **최근 검색**: `Chip` 위젯들, 탭 시 즉시 검색
  - **음성 검색**: `FloatingActionButton` + 음성 인식

- **필터 버튼**: 
  - `FilterChip` 그룹, 활성화 시 색상 변화
  - 필터 적용 시 `Badge`로 개수 표시
  - **필터 시트**: `BottomSheet` 슬라이드업, 다중 선택

- **정렬 옵션**:
  - `DropdownButton` 또는 `PopupMenuButton`
  - 선택 변경 시 리스트 `AnimatedList` 재정렬

- **결과 목록**:
  - **카드**: `Card` + 그림자, 탭 시 `Hero` 전환
  - **리스트/그리드 토글**: `IconButton`, 전환 시 `AnimatedSwitcher`
  - **무한 스크롤**: 하단 도달 시 `CircularProgressIndicator`
  - **빈 결과**: `Lottie` 애니메이션 + "검색 결과가 없어요" 메시지

- **지도 뷰**: `GoogleMap` 위젯, 마커 클러스터링, 줌 컨트롤

#### **BLoC 구조**
```dart
// SearchBloc
// Events: SearchShops, ApplyFilters, ChangeSort, LoadMore
// States: SearchInitial, SearchLoading, SearchLoaded, SearchError
```

---

## 5. 샵 상세 정보 화면

### **5.1 샵 상세 메인**

#### **화면 구성**
- **상단 이미지 슬라이더**
  - 샵 이미지들
  - 페이지 인디케이터
  - 뒤로가기, 찜하기, 공유 아이콘

- **샵 기본 정보**
  - 샵명, 파트너십 배지
  - 평점 및 리뷰 수
  - 주소, 거리
  - 전화번호 (바로 통화)
  - 영업시간
  - 카카오톡 채널 연결

- **탭 메뉴** (입점샵만)
  - 기본 정보
  - 시술 메뉴
  - 사진
  - 리뷰

#### **데이터베이스 상호작용**
```sql
-- 샵 상세 정보 조회
SELECT s.*,
       array_agg(DISTINCT si.image_url ORDER BY si.display_order) as shop_images,
       COUNT(DISTINCT r.id) as total_reviews,
       AVG(r.rating) as average_rating
FROM public.shops s
LEFT JOIN public.shop_images si ON s.id = si.shop_id
LEFT JOIN public.reviews r ON s.id = r.shop_id AND r.status = 'active'
WHERE s.id = $shop_id AND s.shop_status = 'active'
GROUP BY s.id;

-- 샵 서비스 목록
SELECT ss.*, 
       array_agg(ssi.image_url ORDER BY ssi.display_order) as service_images
FROM public.shop_services ss
LEFT JOIN public.service_images ssi ON ss.id = ssi.service_id
WHERE ss.shop_id = $shop_id AND ss.is_available = true
GROUP BY ss.id
ORDER BY ss.display_order, ss.category;

-- 사용자 즐겨찾기 상태 확인
SELECT EXISTS(
    SELECT 1 FROM public.user_favorites 
    WHERE user_id = auth.uid() AND shop_id = $shop_id
) as is_favorited;
```

#### **기능 및 로직**
1. **이미지 갤러리**
   - `shop_images` 테이블에서 이미지 로드
   - `display_order`로 정렬
   - 캐시된 네트워크 이미지 사용

2. **즐겨찾기 기능**
   - `user_favorites` 테이블 관리
   - 실시간 상태 업데이트
   - 애니메이션 효과

3. **통화 및 메시지 기능**
   - `url_launcher`로 전화 연결
   - 카카오톡 채널 연결 (`kakao_channel_url`)

4. **영업시간 표시**
   - `operating_hours` JSONB 파싱
   - 현재 영업 상태 계산
   - 다음 영업 시간 안내

#### **UI/UX 구현 상세**
- **이미지 슬라이더**:
  - `PageView.builder` + `PhotoView`로 확대/축소
  - **인디케이터**: 하단 점 표시, 현재 페이지 강조
  - **전체화면**: 탭 시 `Hero` 애니메이션으로 갤러리 뷰

- **상단 액션 바**:
  - **뒤로가기**: `IconButton` + 반투명 원형 배경
  - **찜하기**: `AnimatedIcon` (하트), 탭 시 `heartBeat` 애니메이션
  - **공유**: `IconButton`, 탭 시 `Share.share()` 호출

- **샵 정보 섹션**:
  - **이름**: `Text` + 볼드, 파트너 배지 옆에 배치
  - **평점**: `RatingBar.builder` + 별점 애니메이션
  - **주소**: `InkWell`, 탭 시 지도 앱 연결
  - **전화번호**: `ElevatedButton`, 통화 아이콘 + 번호
  - **영업시간**: `ExpansionTile`로 요일별 펼치기/접기
  - **카카오톡**: `OutlinedButton` + 카카오 컬러

- **탭 메뉴** (입점샵):
  - `TabBar` + `TabBarView`, 스크롤 시 `SliverAppBar` 고정
  - 탭 전환 시 `AnimatedSwitcher` 효과

### **5.2 서비스 목록 탭**

#### **화면 구성**
- 카테고리별 서비스 그룹
- 서비스명, 설명, 가격 범위
- 소요 시간, 예약금 정보
- "예약하기" 버튼

#### **데이터베이스 상호작용**
```sql
-- 카테고리별 서비스 조회
SELECT category, 
       array_agg(
           json_build_object(
               'id', id,
               'name', name,
               'description', description,
               'price_min', price_min,
               'price_max', price_max,
               'duration_minutes', duration_minutes,
               'deposit_amount', deposit_amount
           ) ORDER BY display_order
       ) as services
FROM public.shop_services 
WHERE shop_id = $shop_id AND is_available = true
GROUP BY category
ORDER BY category;
```

#### **기능 및 로직**
1. **카테고리 그룹핑**
   - `service_category` enum으로 그룹화
   - 각 카테고리별 섹션 생성

2. **가격 표시**
   - `price_min`/`price_max` 범위 표시
   - 예약금 정보 (`deposit_amount`)

3. **예약 플로우**
   - 서비스 선택 → 예약 요청 화면 이동
   - 선택된 서비스 정보 전달

#### **UI/UX 구현 상세**
- **카테고리 헤더**:
  - `SliverList` + `SliverToBoxAdapter`로 스티키 헤더
  - **카테고리 아이콘**: 각 서비스별 컬러 테마 적용
  - **접기/펼치기**: `ExpansionTile`로 카테고리별 관리

- **서비스 카드**:
  - `Card` + `ListTile` 형태, 그림자 효과
  - **이미지**: 좌측 썸네일, `ClipRRect`로 둥근 모서리
  - **이름/설명**: `Column` 레이아웃, 설명은 2줄 제한
  - **가격**: 우측 상단, 범위 표시 시 "₩50,000 ~ ₩80,000" 형식
  - **소요시간**: 아이콘 + 텍스트, 하단 배치
  - **예약금**: `Chip` 위젯으로 강조

- **예약하기 버튼**:
  - `ElevatedButton` + 그라데이션 배경
  - 탭 시 `scale` 애니메이션 + `hapticFeedback`
  - 선택된 서비스들 `FloatingActionButton`으로 계속 표시

---

## 6. 예약 요청 화면

### **6.1 예약 요청 메인**

#### **화면 구성**
- **단계별 진행 바**
- **서비스 선택 섹션**
  - 선택된 서비스 목록
  - 수량 조절
  - 총 금액 계산

- **날짜/시간 선택 섹션**
  - 캘린더 위젯
  - 시간 슬롯 그리드
  - 예약 불가 시간 표시

- **요청사항 입력**
- **포인트 사용 섹션**
- **결제 정보 섹션**
- **최종 확인 및 주의사항**

#### **데이터베이스 상호작용**
```sql
-- 예약 가능한 시간 슬롯 조회
SELECT generate_series(
    $date::date + interval '9 hours',
    $date::date + interval '18 hours',
    interval '30 minutes'
) as time_slot
EXCEPT
SELECT reservation_datetime
FROM public.reservations
WHERE shop_id = $shop_id 
  AND reservation_date = $date
  AND status IN ('confirmed', 'requested');

-- 사용자 포인트 잔액 조회
SELECT available_points FROM public.users WHERE id = auth.uid();

-- 예약 생성
INSERT INTO public.reservations (
    user_id, shop_id, reservation_date, reservation_time,
    total_amount, deposit_amount, points_used, special_requests
) VALUES (
    auth.uid(), $shop_id, $date, $time,
    $total_amount, $deposit_amount, $points_used, $requests
) RETURNING id;

-- 예약 서비스 연결
INSERT INTO public.reservation_services (
    reservation_id, service_id, quantity, unit_price, total_price
) VALUES ($reservation_id, $service_id, $quantity, $unit_price, $total_price);
```

#### **기능 및 로직**
1. **시간 슬롯 관리**
   - 영업시간 기반 시간 슬롯 생성
   - 기존 예약과 충돌 확인
   - 실시간 예약 상태 업데이트

2. **가격 계산**
   - 서비스별 단가 × 수량
   - 포인트 할인 적용
   - 예약금 계산 (총액의 20-30%)

3. **포인트 시스템**
   - 사용 가능한 포인트 조회
   - 포인트 사용량 검증
   - 7일 제한 규칙 적용

4. **예약 요청 처리**
   - `reservation_status = 'requested'` 상태로 생성
   - 관련 서비스들 연결 테이블에 저장
   - 샵 owner에게 알림 발송

#### **UI/UX 구현 상세**
- **진행 인디케이터**:
  - `StepperWidget` 또는 커스텀 진행 바, 현재 단계 강조
  - 완료된 단계는 체크 마크, 현재 단계는 펄스 애니메이션

- **서비스 선택 섹션**:
  - **서비스 카드**: `Card` + 체크박스, 선택 시 테두리 색상 변화
  - **수량 조절**: `IconButton` (+/-) + 중앙 숫자, `AnimatedSwitcher`로 변화
  - **총액 계산**: 하단 고정, 실시간 업데이트 애니메이션

- **날짜/시간 선택**:
  - **캘린더**: `TableCalendar` 위젯, 예약 불가 날짜 회색 처리
  - **시간 슬롯**: `GridView` + `ChoiceChip`, 선택/불가능 상태 구분
  - **선택 확인**: 선택 완료 시 `checkmark` 애니메이션

- **포인트 사용**:
  - **포인트 표시**: `AnimatedContainer`로 잔액 표시
  - **사용량 입력**: `Slider` + `TextField` 조합
  - **할인 적용**: 실시간 계산 + `CountUp` 애니메이션

- **요청사항**: `TextField` + 힌트 텍스트, 글자 수 제한 표시

- **최종 확인**:
  - **요약 카드**: 모든 선택 정보 + 애니메이션
  - **주의사항**: `ExpansionTile`로 접기/펼치기
  - **예약 요청 버튼**: `Hero` 위젯, 결제 화면으로 전환

#### **BLoC 구조**
```dart
// ReservationBloc
// Events: LoadTimeSlots, SelectService, SelectDateTime, ApplyPoints, CreateReservation
// States: ReservationLoading, ReservationLoaded, ReservationCreated, ReservationError
```

### **6.2 결제 화면**

#### **화면 구성**
- 결제 금액 요약
- 토스페이먼츠 결제 위젯
- 결제 수단 선택
- 결제 완료 처리

#### **데이터베이스 상호작용**
```sql
-- 결제 정보 생성
INSERT INTO public.payments (
    reservation_id, user_id, payment_method, amount,
    payment_provider, provider_order_id, is_deposit
) VALUES (
    $reservation_id, auth.uid(), $payment_method, $amount,
    'toss_payments', $order_id, true
);

-- 결제 완료 시 상태 업데이트
UPDATE public.payments SET
    payment_status = 'deposit_paid',
    provider_transaction_id = $transaction_id,
    paid_at = NOW()
WHERE id = $payment_id;

UPDATE public.reservations SET
    status = 'confirmed'
WHERE id = $reservation_id;
```

#### **기능 및 로직**
1. **토스페이먼츠 연동**
   - 결제 위젯 임베드
   - 결제 완료 콜백 처리
   - 실패 시 재시도 로직

2. **결제 상태 관리**
   - `payment_status` 실시간 업데이트
   - 예약 상태 연동 업데이트

#### **UI/UX 구현 상세**
- **결제 요약**:
  - **총액 카드**: `Card` + 그라데이션, 큰 폰트로 강조
  - **할인 내역**: 포인트 사용액 + 취소선 효과
  - **최종 금액**: `AnimatedSwitcher`로 변화 애니메이션

- **토스페이먼츠 위젯**:
  - `WebView` 임베드 또는 네이티브 SDK
  - **로딩**: `CircularProgressIndicator` + "결제 준비 중..." 메시지
  - **진행률**: 결제 단계별 진행 표시

- **결제 수단**:
  - **카드**: 카드 아이콘 + 브랜드 로고
  - **간편결제**: 카카오페이, 네이버페이 버튼
  - 선택 시 `scale` 애니메이션 + 테두리 강조

- **보안 정보**: `Icon` + 보안 인증 문구

- **완료 처리**:
  - **성공**: `Lottie` 체크마크 애니메이션 + 성공 메시지
  - **실패**: 에러 아이콘 + 재시도 버튼
  - **영수증**: `BottomSheet`로 결제 상세 내역

---

## 7. 예약 내역 화면

### **7.1 예약 목록**

#### **화면 구성**
- **탭 메뉴**: 예정된 예약 / 지난 예약
- **예약 카드**
  - 샵 이미지 및 이름
  - 서비스명
  - 예약 일시
  - 예약 상태 배지
  - 상태별 액션 버튼

#### **데이터베이스 상호작용**
```sql
-- 예정된 예약 조회
SELECT r.*, s.name as shop_name, s.phone_number as shop_phone,
       array_agg(
           json_build_object(
               'service_name', ss.name,
               'quantity', rs.quantity,
               'total_price', rs.total_price
           )
       ) as services
FROM public.reservations r
JOIN public.shops s ON r.shop_id = s.id
JOIN public.reservation_services rs ON r.id = rs.reservation_id
JOIN public.shop_services ss ON rs.service_id = ss.id
WHERE r.user_id = auth.uid()
  AND r.reservation_date >= CURRENT_DATE
  AND r.status NOT IN ('completed', 'cancelled_by_user', 'cancelled_by_shop')
GROUP BY r.id, s.id
ORDER BY r.reservation_datetime ASC;

-- 지난 예약 조회
SELECT r.*, s.name as shop_name,
       array_agg(ss.name) as service_names
FROM public.reservations r
JOIN public.shops s ON r.shop_id = s.id
JOIN public.reservation_services rs ON r.id = rs.reservation_id
JOIN public.shop_services ss ON rs.service_id = ss.id
WHERE r.user_id = auth.uid()
  AND (r.reservation_date < CURRENT_DATE OR r.status IN ('completed', 'cancelled_by_user', 'cancelled_by_shop'))
GROUP BY r.id, s.id
ORDER BY r.reservation_datetime DESC;
```

#### **기능 및 로직**
1. **상태별 액션**
   - `requested`: 취소 가능, "사장님 확인 중" 표시
   - `confirmed`: 취소 가능 (24시간 전), 샵 연락
   - `completed`: 리뷰 작성, 재예약
   - `cancelled_*`: 재예약 가능

2. **실시간 상태 업데이트**
   - 푸시 알림을 통한 상태 변경 반영
   - Pull-to-refresh로 수동 갱신

#### **UI/UX 구현 상세**
- **탭 바**:
  - `TabBar` + 2개 탭 (예정된/지난), 탭 하단 인디케이터
  - 탭 전환 시 `AnimatedSwitcher` + 슬라이드 효과

- **예약 카드**:
  - `Card` + `ListTile`, 상태별 좌측 컬러 바
  - **샵 이미지**: `CircleAvatar` + `Hero` 애니메이션
  - **예약 정보**: `Column` 레이아웃, 시간은 강조 표시
  - **상태 배지**: `Chip` 위젯, 상태별 색상 구분
    - `requested`: 주황색 + "확인 중" 
    - `confirmed`: 초록색 + "확정됨"
    - `completed`: 파란색 + "완료"
    - `cancelled`: 회색 + "취소됨"

- **액션 버튼**:
  - **취소**: `OutlinedButton` + 빨간색, 확인 다이얼로그
  - **연락**: `IconButton` + 전화 아이콘
  - **재예약**: `ElevatedButton` + 서비스 정보 전달
  - **리뷰 작성**: `TextButton` + 별점 아이콘

- **빈 상태**: `Lottie` 애니메이션 + "예약 내역이 없어요" 메시지

- **새로고침**: `RefreshIndicator` + 당겨서 새로고침

### **7.2 예약 상세 화면**

#### **화면 구성**
- 예약 전체 정보
- 결제 내역
- 상태 변경 이력
- 액션 버튼들

#### **데이터베이스 상호작용**
```sql
-- 예약 상세 정보
SELECT r.*, s.name as shop_name, s.address, s.phone_number,
       p.amount as paid_amount, p.payment_method, p.paid_at
FROM public.reservations r
JOIN public.shops s ON r.shop_id = s.id
LEFT JOIN public.payments p ON r.id = p.reservation_id AND p.is_deposit = true
WHERE r.id = $reservation_id AND r.user_id = auth.uid();
```

#### **UI/UX 구현 상세**
- **헤더**: `SliverAppBar` + 샵 이미지 배경, 스크롤 시 축소
- **예약 정보 카드**: 
  - **타임라인**: `Timeline` 위젯으로 예약 진행 상태 표시
  - **서비스 목록**: `ExpansionTile`로 상세 내역 펼치기
  - **가격 정보**: 테이블 형태, 할인/포인트 사용 표시

- **결제 내역**:
  - **결제 방법**: 아이콘 + 마스킹된 카드번호
  - **영수증**: `InkWell` 탭 시 영수증 이미지 표시

- **액션 버튼들**: 하단 고정, 상태별 다른 버튼 표시
- **QR 코드**: 확정된 예약 시 QR 코드 표시 (방문 확인용)

---

## 8. 마이페이지

### **8.1 마이페이지 메인**

#### **화면 구성**
- **프로필 헤더**
  - 프로필 이미지
  - 이름, 인플루언서 인증 마크
  - 보유 포인트 표시

- **메뉴 목록**
  - 내 정보 관리
  - 포인트 관리
  - 내가 추천한 친구들
  - 공지사항
  - 1:1 문의
  - 자주 묻는 질문
  - 설정
  - 로그아웃

#### **데이터베이스 상호작용**
```sql
-- 사용자 프로필 및 통계 조회
SELECT u.name, u.profile_image_url, u.is_influencer, u.available_points,
       u.total_referrals, u.successful_referrals,
       COUNT(DISTINCT r.id) as total_reservations,
       COUNT(DISTINCT r.id) FILTER (WHERE r.status = 'completed') as completed_reservations
FROM public.users u
LEFT JOIN public.reservations r ON u.id = r.user_id
WHERE u.id = auth.uid()
GROUP BY u.id;

-- 읽지 않은 공지사항 수
SELECT COUNT(*) FROM public.announcements 
WHERE is_active = true 
  AND starts_at <= NOW() 
  AND (ends_at IS NULL OR ends_at > NOW())
  AND 'user' = ANY(target_user_type);
```

#### **기능 및 로직**
1. **프로필 이미지 관리**
   - Supabase Storage에 이미지 업로드
   - 이미지 압축 및 최적화

2. **인플루언서 상태 표시**
   - `is_influencer` 플래그 기반
   - 인증 마크 아이콘 표시

#### **UI/UX 구현 상세**
- **프로필 헤더**:
  - **배경**: 그라데이션 또는 패턴 배경
  - **프로필 이미지**: `CircleAvatar` + 테두리, 탭 시 확대 뷰
  - **인플루언서 배지**: `Badge` 위젯 + 금색 크라운 아이콘
  - **포인트**: `AnimatedContainer` + `CountUp` 효과

- **통계 카드**:
  - **그리드**: `GridView.count` (2x2), 각 통계별 카드
  - **애니메이션**: 진입 시 `staggered` 애니메이션
  - **아이콘**: 각 항목별 컬러 아이콘 (예약, 추천, 포인트 등)

- **메뉴 리스트**:
  - `ListView` + `ListTile`, 각 항목별 아이콘
  - **화살표**: 우측 `Icon`, 탭 시 회전 애니메이션
  - **배지**: 읽지 않은 공지사항 개수 표시
  - **섹션 분리**: `Divider` 또는 여백으로 그룹 구분

- **로그아웃**: `AlertDialog`로 확인, 위험한 액션 강조

---

## 9. 포인트 관리 화면

### **9.1 포인트 메인**

#### **화면 구성**
- **포인트 요약**
  - 총 보유 포인트
  - 사용 가능 포인트
  - 대기 중 포인트 (7일 제한)

- **포인트 내역**
  - 최근 거래 내역
  - 적립/사용 구분
  - 날짜별 정렬

#### **데이터베이스 상호작용**
```sql
-- 포인트 요약 정보
SELECT u.total_points, u.available_points,
       COALESCE(pending.pending_points, 0) as pending_points,
       COALESCE(this_month.points_this_month, 0) as points_this_month
FROM public.users u
LEFT JOIN (
    SELECT user_id, SUM(amount) as pending_points
    FROM public.point_transactions 
    WHERE status = 'pending' AND amount > 0
    GROUP BY user_id
) pending ON u.id = pending.user_id
LEFT JOIN (
    SELECT user_id, SUM(amount) as points_this_month
    FROM public.point_transactions 
    WHERE status = 'available' AND amount > 0
      AND created_at >= date_trunc('month', NOW())
    GROUP BY user_id
) this_month ON u.id = this_month.user_id
WHERE u.id = auth.uid();

-- 포인트 거래 내역
SELECT pt.*, 
       CASE 
         WHEN pt.reservation_id IS NOT NULL THEN s.name
         WHEN pt.related_user_id IS NOT NULL THEN '친구 추천'
         ELSE pt.description
       END as source_description
FROM public.point_transactions pt
LEFT JOIN public.reservations r ON pt.reservation_id = r.id
LEFT JOIN public.shops s ON r.shop_id = s.id
WHERE pt.user_id = auth.uid()
ORDER BY pt.created_at DESC
LIMIT 50;
```

#### **기능 및 로직**
1. **포인트 정책 적용 (PRD 2.4, 2.5)**
   - 적립률: 총 시술 금액의 2.5%
   - 적립 한도: 최대 30만원까지
   - 사용 제한: 적립 후 7일 경과 후 사용 가능

2. **포인트 상태 관리**
   - `pending`: 7일 대기 중
   - `available`: 사용 가능
   - `used`: 사용 완료
   - `expired`: 만료됨

#### **UI/UX 구현 상세**
- **포인트 요약 카드**:
  - **메인 카드**: 그라데이션 배경 + 큰 폰트로 총 포인트
  - **서브 정보**: 사용 가능/대기 중 포인트, 작은 카드들
  - **애니메이션**: 진입 시 `slideInUp` + `CountUp` 효과

- **월간 통계**:
  - **차트**: `fl_chart` 라이브러리로 바 차트 또는 라인 차트
  - **범례**: 적립/사용 구분, 색상별 범례

- **포인트 내역**:
  - **그룹핑**: 날짜별 그룹, `StickyHeader` 사용
  - **아이템**: `ListTile` + 좌측 아이콘 (적립/사용)
  - **금액**: 우측 정렬, 적립은 초록색(+), 사용은 빨간색(-)
  - **상세**: 탭 시 `ExpansionTile`로 상세 내역

- **필터**: `FilterChip` 그룹, 전체/적립/사용 필터
- **로딩**: `Shimmer` 효과로 스켈레톤 UI

### **9.2 포인트 상세 내역**

#### **화면 구성**
- 기간별 필터 (전체, 적립, 사용)
- 상세 거래 목록
- 페이지네이션

#### **데이터베이스 상호작용**
```sql
-- 필터링된 포인트 내역
SELECT pt.*, 
       CASE pt.transaction_type
         WHEN 'earned_service' THEN '서비스 이용 적립'
         WHEN 'earned_referral' THEN '친구 추천 적립'
         WHEN 'used_service' THEN '서비스 결제 사용'
         WHEN 'influencer_bonus' THEN '인플루언서 보너스'
         ELSE pt.description
       END as type_description
FROM public.point_transactions pt
WHERE pt.user_id = auth.uid()
  AND ($transaction_type IS NULL OR pt.transaction_type = $transaction_type)
  AND pt.created_at BETWEEN $start_date AND $end_date
ORDER BY pt.created_at DESC
LIMIT 20 OFFSET $offset;
```

#### **UI/UX 구현 상세**
- **검색 헤더**:
  - **위치 필터**: `DropdownButton` + 현재 위치 표시
  - **검색창**: `TextField` + 돋보기 아이콘, 포커스 시 확장

- **피드 그리드**:
  - `StaggeredGridView` 또는 `GridView.masonry`로 Pinterest 스타일
  - **이미지**: `CachedNetworkImage` + `Hero` 애니메이션
  - **오버레이**: 그라데이션 + 사용자 정보/좋아요 수

- **게시물 카드**: 탭 시 상세 뷰로 `Hero` 전환
- **작성 버튼**: `FloatingActionButton` + 카메라 아이콘
- **무한 스크롤**: `GridView.builder` + 하단 로딩

- **필터**: 해시태그, 카테고리별 필터 칩들
- **새로고침**: `RefreshIndicator` + 당겨서 새로고침
- **기간 선택**: 
  - `DateRangePicker` 버튼, 선택된 기간 표시
  - **빠른 선택**: "이번 달", "지난 3개월" 등 `Chip` 버튼들

- **필터 탭**: `TabBar` + 3개 탭 (전체/적립/사용)
- **상세 리스트**: 
  - 날짜별 그룹핑, 각 그룹은 `Card` 형태
  - **트랜잭션**: `ListTile` + 타입별 아이콘
  - **애니메이션**: 새 데이터 로드 시 `fadeIn` 효과

- **페이지네이션**: 스크롤 하단 도달 시 추가 로드
- **빈 상태**: 해당 기간 내역 없을 때 안내 메시지

---

## 10. 추천인 관리 화면

### **10.1 추천인 현황**

#### **화면 구성**
- **기간별 수익 조회**
  - 달력 UI로 기간 설정
  - 해당 기간 총 포인트 수익
  - 기여한 친구들 마스킹 ID 목록

- **추천 통계**
  - 총 추천 친구 수
  - 결제 완료한 친구 수
  - 인플루언서 자격 진행률

- **추천 코드 공유**
  - 개인 추천 코드
  - 복사/공유 기능

#### **데이터베이스 상호작용**
```sql
-- 기간별 추천 수익 조회
SELECT 
    SUM(pt.amount) as total_points,
    COUNT(DISTINCT pt.related_user_id) as contributing_friends,
    array_agg(DISTINCT 
        LEFT(u.name, 2) || REPEAT('*', LENGTH(u.name) - 2)
    ) as masked_friend_names
FROM public.point_transactions pt
JOIN public.users u ON pt.related_user_id = u.id
WHERE pt.user_id = auth.uid()
  AND pt.transaction_type IN ('earned_referral', 'influencer_bonus')
  AND pt.created_at BETWEEN $start_date AND $end_date
  AND pt.status = 'available';

-- 추천인 자격 진행 상황
SELECT 
    u.referral_code,
    u.total_referrals,
    u.successful_referrals,
    u.is_influencer,
    COUNT(DISTINCT paid_users.id) as paid_referrals
FROM public.users u
LEFT JOIN public.users referred ON referred.referred_by_code = u.referral_code
LEFT JOIN (
    SELECT DISTINCT p.user_id as id
    FROM public.payments p 
    WHERE p.payment_status = 'fully_paid'
) paid_users ON referred.id = paid_users.id
WHERE u.id = auth.uid()
GROUP BY u.id;
```

#### **기능 및 로직**
1. **인플루언서 자격 체크 (PRD 2.2 정책)**
   - 추천한 친구 50명 이상
   - 추천받은 친구 50명 모두 1회 이상 결제 완료
   - 자격 충족 시 자동으로 인플루언서 상태 변경

2. **리워드 강화**
   - 인플루언서는 추천 포인트 2배 적립
   - `transaction_type = 'influencer_bonus'`로 별도 기록

#### **UI/UX 구현 상세**
- **수익 조회 헤더**:
  - **기간 선택**: `DateRangePicker` + 달력 아이콘 버튼
  - **총 수익**: 큰 카드 + `CountUp` 애니메이션
  - **친구 수**: 기여한 친구 수 표시

- **진행률 카드**:
  - **인플루언서 자격**: `LinearProgressIndicator` + 백분율
  - **현재 상태**: 50명 중 현재 추천 수 / 결제 완료 수
  - **혜택 안내**: 인플루언서 되면 2배 적립 강조

- **추천 코드 섹션**:
  - **코드 표시**: `Container` + 점선 테두리, 코드 강조
  - **복사 버튼**: `IconButton` + 복사 아이콘, 탭 시 클립보드 복사
  - **공유 버튼**: `ElevatedButton`, 탭 시 `Share.share()` 호출
  - **피드백**: 복사/공유 완료 시 `SnackBar` 표시

- **친구 목록**: 마스킹된 이름 + 포인트 적립 내역

### **10.2 추천 친구 상세**

#### **화면 구성**
- 추천한 친구 목록 (마스킹)
- 각 친구별 포인트 적립 내역
- 확장/축소 가능한 아코디언 형태

#### **데이터베이스 상호작용**
```sql
-- 친구별 상세 적립 내역
SELECT 
    LEFT(u.name, 2) || REPEAT('*', LENGTH(u.name) - 2) as masked_name,
    array_agg(
        json_build_object(
            'date', pt.created_at::date,
            'amount', pt.amount,
            'type', pt.transaction_type
        ) ORDER BY pt.created_at DESC
    ) as point_history
FROM public.users u
JOIN public.point_transactions pt ON u.id = pt.related_user_id
WHERE pt.user_id = auth.uid()
  AND pt.transaction_type IN ('earned_referral', 'influencer_bonus')
GROUP BY u.id, u.name
ORDER BY MAX(pt.created_at) DESC;
```

#### **UI/UX 구현 상세**
- **친구 목록**: 
  - `ListView` + `ExpansionTile` 형태
  - **마스킹된 이름**: "김*지", "박**" 형태로 표시
  - **아바타**: 기본 프로필 이미지 + 마스킹 이름 첫 글자

- **포인트 내역 펼치기**:
  - 탭 시 `slideDown` 애니메이션으로 내역 표시
  - **날짜**: 좌측 정렬, MM/dd 형식
  - **포인트**: 우측 정렬, +150P 형태
  - **타입**: 적립/보너스 구분 아이콘

- **통계 요약**: 각 친구별 총 적립 포인트 표시
- **정렬**: 최근 적립순, 총 포인트순 선택 가능

---

## 11. 설정 화면

### **11.1 설정 메인**

#### **화면 구성**
- **알림 설정**
  - 푸시 알림 전체 ON/OFF
  - 예약 알림
  - 이벤트 알림
  - 마케팅 정보 수신

- **계정 설정**
  - 로그아웃
  - 회원 탈퇴

- **기타 설정**
  - 앱 버전 정보
  - 약관 및 정책
  - 캐시 삭제

#### **데이터베이스 상호작용**
```sql
-- 사용자 설정 조회/업데이트
SELECT * FROM public.user_settings WHERE user_id = auth.uid();

UPDATE public.user_settings SET
    push_notifications_enabled = $push_enabled,
    reservation_notifications = $reservation_enabled,
    event_notifications = $event_enabled,
    marketing_notifications = $marketing_enabled,
    updated_at = NOW()
WHERE user_id = auth.uid();

-- 회원 탈퇴 처리 (소프트 삭제)
UPDATE public.users SET
    user_status = 'deleted',
    email = NULL,
    phone_number = NULL,
    name = '탈퇴한 사용자',
    updated_at = NOW()
WHERE id = auth.uid();
```

#### **기능 및 로직**
1. **알림 설정 관리**
   - FCM 토큰 활성화/비활성화
   - 서버 측 알림 발송 제어

2. **회원 탈퇴**
   - 개인정보 마스킹 처리
   - 예약 내역은 보존 (비즈니스 요구사항)
   - Supabase Auth 계정 삭제

#### **UI/UX 구현 상세**
- **섹션 구분**: `ListView` + 섹션별 헤더와 `Divider`

- **알림 설정 섹션**:
  - **전체 토글**: `SwitchListTile` + 마스터 스위치
  - **세부 설정**: 각각 `SwitchListTile`, 전체 OFF 시 비활성화
  - **설명**: 각 알림 타입별 설명 텍스트

- **계정 설정 섹션**:
  - **로그아웃**: `ListTile` + 아이콘, 탭 시 확인 다이얼로그
  - **회원 탈퇴**: 빨간색 텍스트 + 경고 아이콘
    - 탭 시 다단계 확인 과정 (이유 선택 → 최종 확인)

- **기타 설정 섹션**:
  - **버전 정보**: `ListTile` + 현재 버전, 탭 시 업데이트 확인
  - **약관/정책**: `ListTile` + 화살표, 탭 시 `InAppWebView`
  - **캐시 삭제**: 용량 표시 + 삭제 버튼, 완료 시 성공 토스트

- **위험한 액션**: 빨간색으로 강조, 확인 다이얼로그 필수

---

## 12. 피드 화면 (향후 확장)

### **12.1 피드 메인**

#### **화면 구성**
- 위치/키워드 기반 검색
- 그리드 형태 게시물 목록
- 게시물 작성 플로팅 버튼

#### **데이터베이스 상호작용**
```sql
-- 피드 게시물 조회 (향후 구현)
SELECT p.*, u.name as author_name, u.profile_image_url,
       s.name as tagged_shop_name
FROM public.posts p
JOIN public.users u ON p.author_id = u.id
LEFT JOIN public.shops s ON p.tagged_shop_id = s.id
WHERE p.status = 'active'
  AND ($location IS NULL OR ST_DWithin(p.location, $location, 5000))
ORDER BY p.created_at DESC
LIMIT 20 OFFSET $offset;
```

#### **UI/UX 구현 상세**
- **검색 헤더**:
  - **위치 필터**: `DropdownButton` + 현재 위치 표시
  - **검색창**: `TextField` + 돋보기 아이콘, 포커스 시 확장

- **피드 그리드**:
  - `StaggeredGridView` 또는 `GridView.masonry`로 Pinterest 스타일
  - **이미지**: `CachedNetworkImage` + `Hero` 애니메이션
  - **오버레이**: 그라데이션 + 사용자 정보/좋아요 수

- **게시물 카드**: 탭 시 상세 뷰로 `Hero` 전환
- **작성 버튼**: `FloatingActionButton` + 카메라 아이콘
- **무한 스크롤**: `GridView.builder` + 하단 로딩

- **필터**: 해시태그, 카테고리별 필터 칩들
- **새로고침**: `RefreshIndicator` + 당겨서 새로고침

---

## 🔧 기술적 구현 사항

### **상태 관리 아키텍처**

```dart
// 전체 앱 상태 구조
class AppState {
  final AuthState auth;
  final UserState user;
  final LocationState location;
  final NotificationState notifications;
}

// BLoC 기반 상태 관리
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ShopRepository shopRepository;
  final LocationService locationService;
  
  @override
  Stream<HomeState> mapEventToState(HomeEvent event) async* {
    // 이벤트 처리 로직
  }
}
```

### **데이터베이스 모델 정의**

```dart
// User 모델
class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final UserStatus status;
  final bool isInfluencer;
  final int totalPoints;
  final int availablePoints;
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    // ... 기타 필드
  );
}

// Shop 모델 
class Shop {
  final String id;
  final String name;
  final ShopType type;
  final ShopStatus status;
  final ServiceCategory mainCategory;
  final LatLng location;
  final List<String> imageUrls;
  final Map<String, dynamic> operatingHours;
  
  // ... 구현
}
```

### **에러 처리 및 로깅**

```dart
// 통합 에러 처리
class AppErrorHandler {
  static void handleError(dynamic error, StackTrace stackTrace) {
    // 로깅
    logger.error(error, stackTrace);
    
    // 사용자 알림
    if (error is NetworkException) {
      showSnackBar('네트워크 연결을 확인해주세요');
    } else if (error is ValidationException) {
      showSnackBar(error.message);
    }
  }
}
```

### **성능 최적화**

1. **이미지 캐싱**
   - `cached_network_image` 패키지 사용
   - Supabase Storage CDN 활용

2. **페이징 및 무한 스크롤**
   - cursor-based pagination
   - 초기 로드 최적화

3. **상태 보존**
   - 탭 간 상태 유지
   - 백그라운드 복귀 시 데이터 갱신

---

## 📊 데이터 플로우 다이어그램

```
사용자 로그인
    ↓
Supabase Auth 인증
    ↓
사용자 프로필 로드 (public.users)
    ↓
위치 권한 요청
    ↓
GPS 좌표 획득
    ↓
근처 샵 조회 (공간 인덱스 활용)
    ↓
샵 목록 표시 (알고리즘 적용)
    ↓
사용자 상호작용 (검색, 필터, 예약 등)
    ↓
실시간 데이터 업데이트
```

---

## 🔐 보안 및 권한 관리

### **Row Level Security (RLS) 정책**

```sql
-- 사용자는 자신의 데이터만 접근 가능
CREATE POLICY "Users can read own data" ON public.users
FOR SELECT USING (auth.uid() = id);

-- 샵 오너는 자신의 샵 예약만 조회 가능
CREATE POLICY "Shop owners can read shop reservations" ON public.reservations
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.shops 
        WHERE shops.id = reservations.shop_id 
        AND shops.owner_id = auth.uid()
    )
);
```

### **앱 권한 관리**

```dart
// 권한 요청 플로우
class PermissionManager {
  static Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.request();
    return permission.isGranted;
  }
  
  static Future<bool> requestNotificationPermission() async {
    final permission = await Permission.notification.request();
    return permission.isGranted;
  }
}
```

---

## 🚀 배포 및 운영 고려사항

### **환경별 설정**
- Development, Staging, Production 환경 분리
- 환경별 Supabase 프로젝트 구성
- API 키 및 설정 보안 관리

### **모니터링 및 분석**
- Crashlytics를 통한 크래시 추적
- Firebase Analytics 이벤트 추적
- 사용자 행동 분석 데이터 수집

### **푸시 알림 전략**
- FCM 토큰 관리 및 갱신
- 개인화된 알림 발송
- 알림 성능 모니터링

---

이 설계서는 에뷰리띵 플러터 앱의 모든 화면과 기능에 대한 포괄적인 가이드를 제공합니다. 각 화면의 UI/UX, 데이터베이스 상호작용, 비즈니스 로직을 상세히 설명하여 개발 시 참고할 수 있도록 구성되었습니다.

---

## 🎯 주요 구현 하이라이트

### **애니메이션 및 사용자 경험**
- **진입 애니메이션**: `FadeIn`, `SlideIn`, `Staggered` 효과로 자연스러운 화면 전환
- **상호작용 피드백**: `Scale`, `Bounce`, `Pulse` 애니메이션 + `HapticFeedback`
- **상태 전환**: `AnimatedSwitcher`, `AnimatedContainer`로 부드러운 상태 변화
- **로딩 상태**: `Shimmer`, `Skeleton UI`, `Lottie` 애니메이션으로 기다림 개선

### **사용자 인터페이스 패턴**
- **카드 기반 레이아웃**: 일관된 `Card` + `Hero` 전환으로 연결감 제공
- **색상 시스템**: 상태별 색상 구분 (성공=초록, 경고=주황, 오류=빨강)
- **타이포그래피**: 계층적 텍스트 스타일로 정보 우선순위 표현
- **아이콘 시스템**: 직관적인 아이콘 + 텍스트 조합

### **성능 최적화 전략**
- **이미지 최적화**: `CachedNetworkImage` + CDN 활용
- **메모리 관리**: `ListView.builder` + 지연 로딩
- **네트워크 효율성**: 디바운싱, 페이징, 캐싱 전략
- **배터리 절약**: 위치 서비스 최적화, 백그라운드 제한

### **접근성 고려사항**
- **시각적 접근성**: 충분한 색상 대비, 텍스트 크기 조절 지원
- **터치 접근성**: 최소 44pt 터치 영역, 제스처 대체 수단
- **청각적 접근성**: 햅틱 피드백으로 시각적 피드백 보완
- **인지적 접근성**: 직관적인 네비게이션, 명확한 액션 버튼

이 설계서를 바탕으로 일관되고 직관적인 사용자 경험을 제공하는 고품질의 플러터 앱을 개발할 수 있습니다. 