# 📚 목차

  - 10 추천인 관리 화면
    - 101 추천인 현황
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세
    - 102 추천 친구 상세
      - 화면 구성
      - 데이터베이스 상호작용
      - UIUX 구현 상세

---

## 👥 10. 추천인 관리 화면

### 👥 **10.1 추천인 현황**

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
> 💾 **데이터베이스 쿼리**
> ```sql
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
> ```

#### **기능 및 로직**
1. **인플루언서 자격 체크 (PRD 2.2 정책)**
   - 추천한 친구 50명 이상
   - 추천받은 친구 50명 모두 1회 이상 결제 완료
   - 자격 충족 시 자동으로 인플루언서 상태 변경

2. **리워드 강화**
   - 인플루언서는 추천 포인트 2배 적립
   - `transaction_type = 'influencer_bonus'`로 별도 기록

#### **UI/UX 구현 상세**
- 🎯 **수익 조회 헤더**:
  - **기간 선택**: `DateRangePicker` + 달력 아이콘 버튼
  - **총 수익**: 큰 카드 + `CountUp` 애니메이션
  - **친구 수**: 기여한 친구 수 표시

- 🃏 **진행률 카드**:
  - **인플루언서 자격**: `LinearProgressIndicator` + 백분율
  - **현재 상태**: 50명 중 현재 추천 수 / 결제 완료 수
  - **혜택 안내**: 인플루언서 되면 2배 적립 강조

- 📦 **추천 코드 섹션**:
  - **코드 표시**: `Container` + 점선 테두리, 코드 강조
  - 🔘 **복사 버튼**: `IconButton` + 복사 아이콘, 탭 시 클립보드 복사
  - 🔘 **공유 버튼**: `ElevatedButton`, 탭 시 `Share.share()` 호출
  - **피드백**: 복사/공유 완료 시 `SnackBar` 표시

- **친구 목록**: 마스킹된 이름 + 포인트 적립 내역

### **10.2 추천 친구 상세**

#### **화면 구성**
- 추천한 친구 목록 (마스킹)
- 각 친구별 포인트 적립 내역
- 확장/축소 가능한 아코디언 형태

#### **데이터베이스 상호작용**
> 💾 **데이터베이스 쿼리**
> ```sql
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
> ```

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

