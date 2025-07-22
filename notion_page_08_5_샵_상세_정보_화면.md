# 📚 목차

  - 5 샵 상세 정보 화면
    - 51 샵 상세 메인
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세
    - 52 서비스 목록 탭
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세

---

## 🏪 5. 샵 상세 정보 화면

### 🏠 **5.1 샵 상세 메인**

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
> 💾 **데이터베이스 쿼리**
> ```sql
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
> ```

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
- 🖼️ **이미지 슬라이더**:
  - `PageView.builder` + `PhotoView`로 확대/축소
  - 📍 **인디케이터**: 하단 점 표시, 현재 페이지 강조
  - **전체화면**: 탭 시 `Hero` 애니메이션으로 갤러리 뷰

- **상단 액션 바**:
  - **뒤로가기**: `IconButton` + 반투명 원형 배경
  - **찜하기**: `AnimatedIcon` (하트), 탭 시 `heartBeat` 애니메이션
  - **공유**: `IconButton`, 탭 시 `Share.share()` 호출

- 📦 **샵 정보 섹션**:
  - **이름**: `Text` + 볼드, 파트너 배지 옆에 배치
  - **평점**: `RatingBar.builder` + 별점 애니메이션
  - **주소**: `InkWell`, 탭 시 지도 앱 연결
  - **전화번호**: `ElevatedButton`, 통화 아이콘 + 번호
  - **영업시간**: `ExpansionTile`로 요일별 펼치기/접기
  - 💛 **카카오톡**: `OutlinedButton` + 카카오 컬러

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
> 💾 **데이터베이스 쿼리**
> ```sql
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
> ```

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
- 🎯 **카테고리 헤더**:
  - `SliverList` + `SliverToBoxAdapter`로 스티키 헤더
  - **카테고리 아이콘**: 각 서비스별 컬러 테마 적용
  - **접기/펼치기**: `ExpansionTile`로 카테고리별 관리

- 🃏 **서비스 카드**:
  - `Card` + `ListTile` 형태, 그림자 효과
  - 🖼️ **이미지**: 좌측 썸네일, `ClipRRect`로 둥근 모서리
  - **이름/설명**: `Column` 레이아웃, 설명은 2줄 제한
  - **가격**: 우측 상단, 범위 표시 시 "₩50,000 ~ ₩80,000" 형식
  - **소요시간**: 아이콘 + 텍스트, 하단 배치
  - **예약금**: `Chip` 위젯으로 강조

- 🔘 **예약하기 버튼**:
  - `ElevatedButton` + 그라데이션 배경
  - 탭 시 `scale` 애니메이션 + `hapticFeedback`
  - 선택된 서비스들 `FloatingActionButton`으로 계속 표시


---

