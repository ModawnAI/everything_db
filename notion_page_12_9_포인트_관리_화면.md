# 📚 목차

  - 9 포인트 관리 화면
    - 91 포인트 메인
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세
    - 92 포인트 상세 내역
      - 화면 구성
      - 데이터베이스 상호작용
      - UIUX 구현 상세

---

## 🎯 9. 포인트 관리 화면

### 🏠 **9.1 포인트 메인**

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
> 💾 **데이터베이스 쿼리**
> ```sql
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
> ```

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
- 🃏 **포인트 요약 카드**:
  - 🃏 **메인 카드**: 그라데이션 배경 + 큰 폰트로 총 포인트
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

- 🔽 **필터**: `FilterChip` 그룹, 전체/적립/사용 필터
- ⏳ **로딩**: `Shimmer` 효과로 스켈레톤 UI

### 🎯 **9.2 포인트 상세 내역**

#### **화면 구성**
- 기간별 필터 (전체, 적립, 사용)
- 상세 거래 목록
- 페이지네이션

#### **데이터베이스 상호작용**
> 💾 **데이터베이스 쿼리**
> ```sql
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
> ```

#### **UI/UX 구현 상세**
- 🔍 **검색 헤더**:
  - 🔽 **위치 필터**: `DropdownButton` + 현재 위치 표시
  - 🔍 **검색창**: `TextField` + 돋보기 아이콘, 포커스 시 확장

- ⚏ **피드 그리드**:
  - `StaggeredGridView` 또는 `GridView.masonry`로 Pinterest 스타일
  - 🖼️ **이미지**: `CachedNetworkImage` + `Hero` 애니메이션
  - **오버레이**: 그라데이션 + 사용자 정보/좋아요 수

- 🃏 **게시물 카드**: 탭 시 상세 뷰로 `Hero` 전환
- 🔘 **작성 버튼**: `FloatingActionButton` + 카메라 아이콘
- ♾️ **무한 스크롤**: `GridView.builder` + 하단 로딩

- 🔽 **필터**: 해시태그, 카테고리별 필터 칩들
- 🎯 **새로고침**: `RefreshIndicator` + 당겨서 새로고침
- **기간 선택**: 
  - `DateRangePicker` 버튼, 선택된 기간 표시
  - **빠른 선택**: "이번 달", "지난 3개월" 등 `Chip` 버튼들

- 🔽 **필터 탭**: `TabBar` + 3개 탭 (전체/적립/사용)
- 📋 **상세 리스트**: 
  - 날짜별 그룹핑, 각 그룹은 `Card` 형태
  - **트랜잭션**: `ListTile` + 타입별 아이콘
  - **애니메이션**: 새 데이터 로드 시 `fadeIn` 효과

- **페이지네이션**: 스크롤 하단 도달 시 추가 로드
- **빈 상태**: 해당 기간 내역 없을 때 안내 메시지


---

