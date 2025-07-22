# 📚 목차

  - 6 예약 요청 화면
    - 61 예약 요청 메인
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세
      - BLoC 구조
    - 62 결제 화면
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세

---

## 📅 6. 예약 요청 화면

### 🏠 **6.1 예약 요청 메인**

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
> 💾 **데이터베이스 쿼리**
> ```sql
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
> ```

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
- 📍 **진행 인디케이터**:
  - `StepperWidget` 또는 커스텀 진행 바, 현재 단계 강조
  - 완료된 단계는 체크 마크, 현재 단계는 펄스 애니메이션

- 📦 **서비스 선택 섹션**:
  - 🃏 **서비스 카드**: `Card` + 체크박스, 선택 시 테두리 색상 변화
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
  - 🃏 **요약 카드**: 모든 선택 정보 + 애니메이션
  - **주의사항**: `ExpansionTile`로 접기/펼치기
  - 🔘 **예약 요청 버튼**: `Hero` 위젯, 결제 화면으로 전환

#### **BLoC 구조**
> 📱 **Flutter/Dart 코드**
> ```dart
// ReservationBloc
// Events: LoadTimeSlots, SelectService, SelectDateTime, ApplyPoints, CreateReservation
// States: ReservationLoading, ReservationLoaded, ReservationCreated, ReservationError
> ```

### 💳 **6.2 결제 화면**

#### **화면 구성**
- 결제 금액 요약
- 토스페이먼츠 결제 위젯
- 결제 수단 선택
- 결제 완료 처리

#### **데이터베이스 상호작용**
> 💾 **데이터베이스 쿼리**
> ```sql
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
> ```

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
  - 🃏 **총액 카드**: `Card` + 그라데이션, 큰 폰트로 강조
  - **할인 내역**: 포인트 사용액 + 취소선 효과
  - **최종 금액**: `AnimatedSwitcher`로 변화 애니메이션

- **토스페이먼츠 위젯**:
  - `WebView` 임베드 또는 네이티브 SDK
  - ⏳ **로딩**: `CircularProgressIndicator` + "결제 준비 중..." 메시지
  - **진행률**: 결제 단계별 진행 표시

- **결제 수단**:
  - 🃏 **카드**: 카드 아이콘 + 브랜드 로고
  - **간편결제**: 카카오페이, 네이버페이 버튼
  - 선택 시 `scale` 애니메이션 + 테두리 강조

- **보안 정보**: `Icon` + 보안 인증 문구

- **완료 처리**:
  - **성공**: `Lottie` 체크마크 애니메이션 + 성공 메시지
  - **실패**: 에러 아이콘 + 재시도 버튼
  - **영수증**: `BottomSheet`로 결제 상세 내역


---

