# 📚 목차

  - 7 예약 내역 화면
    - 71 예약 목록
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세
    - 72 예약 상세 화면
      - 화면 구성
      - 데이터베이스 상호작용
      - UIUX 구현 상세

---

## 📅 7. 예약 내역 화면

### 📅 **7.1 예약 목록**

#### **화면 구성**
- **탭 메뉴**: 예정된 예약 / 지난 예약
- **예약 카드**
  - 샵 이미지 및 이름
  - 서비스명
  - 예약 일시
  - 예약 상태 배지
  - 상태별 액션 버튼

#### **데이터베이스 상호작용**
> 💾 **데이터베이스 쿼리**
> ```sql
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
> ```

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

- 🃏 **예약 카드**:
  - `Card` + `ListTile`, 상태별 좌측 컬러 바
  - 🖼️ **샵 이미지**: `CircleAvatar` + `Hero` 애니메이션
  - **예약 정보**: `Column` 레이아웃, 시간은 강조 표시
  - **상태 배지**: `Chip` 위젯, 상태별 색상 구분
    - `requested`: 주황색 + "확인 중" 
    - `confirmed`: 초록색 + "확정됨"
    - `completed`: 파란색 + "완료"
    - `cancelled`: 회색 + "취소됨"

- 🔘 **액션 버튼**:
  - **취소**: `OutlinedButton` + 빨간색, 확인 다이얼로그
  - **연락**: `IconButton` + 전화 아이콘
  - **재예약**: `ElevatedButton` + 서비스 정보 전달
  - **리뷰 작성**: `TextButton` + 별점 아이콘

- **빈 상태**: `Lottie` 애니메이션 + "예약 내역이 없어요" 메시지

- 🎯 **새로고침**: `RefreshIndicator` + 당겨서 새로고침

### 📅 **7.2 예약 상세 화면**

#### **화면 구성**
- 예약 전체 정보
- 결제 내역
- 상태 변경 이력
- 액션 버튼들

#### **데이터베이스 상호작용**
> 💾 **데이터베이스 쿼리**
> ```sql
-- 예약 상세 정보
SELECT r.*, s.name as shop_name, s.address, s.phone_number,
       p.amount as paid_amount, p.payment_method, p.paid_at
FROM public.reservations r
JOIN public.shops s ON r.shop_id = s.id
LEFT JOIN public.payments p ON r.id = p.reservation_id AND p.is_deposit = true
WHERE r.id = $reservation_id AND r.user_id = auth.uid();
> ```

#### **UI/UX 구현 상세**
- 🎯 **헤더**: `SliverAppBar` + 샵 이미지 배경, 스크롤 시 축소
- 🃏 **예약 정보 카드**: 
  - **타임라인**: `Timeline` 위젯으로 예약 진행 상태 표시
  - **서비스 목록**: `ExpansionTile`로 상세 내역 펼치기
  - **가격 정보**: 테이블 형태, 할인/포인트 사용 표시

- **결제 내역**:
  - **결제 방법**: 아이콘 + 마스킹된 카드번호
  - **영수증**: `InkWell` 탭 시 영수증 이미지 표시

- 🔘 **액션 버튼들**: 하단 고정, 상태별 다른 버튼 표시
- **QR 코드**: 확정된 예약 시 QR 코드 표시 (방문 확인용)


---

