# 📚 목차

  - 11 설정 화면
    - 111 설정 메인
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세

---

## ⚙️ 11. 설정 화면

### 🏠 **11.1 설정 메인**

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
> 💾 **데이터베이스 쿼리**
> ```sql
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
> ```

#### **기능 및 로직**
1. **알림 설정 관리**
   - FCM 토큰 활성화/비활성화
   - 서버 측 알림 발송 제어

2. **회원 탈퇴**
   - 개인정보 마스킹 처리
   - 예약 내역은 보존 (비즈니스 요구사항)
   - Supabase Auth 계정 삭제

#### **UI/UX 구현 상세**
- 📦 **섹션 구분**: `ListView` + 섹션별 헤더와 `Divider`

- 📦 **알림 설정 섹션**:
  - **전체 토글**: `SwitchListTile` + 마스터 스위치
  - **세부 설정**: 각각 `SwitchListTile`, 전체 OFF 시 비활성화
  - **설명**: 각 알림 타입별 설명 텍스트

- 📦 **계정 설정 섹션**:
  - **로그아웃**: `ListTile` + 아이콘, 탭 시 확인 다이얼로그
  - **회원 탈퇴**: 빨간색 텍스트 + 경고 아이콘
    - 탭 시 다단계 확인 과정 (이유 선택 → 최종 확인)

- 📦 **기타 설정 섹션**:
  - **버전 정보**: `ListTile` + 현재 버전, 탭 시 업데이트 확인
  - **약관/정책**: `ListTile` + 화살표, 탭 시 `InAppWebView`
  - **캐시 삭제**: 용량 표시 + 삭제 버튼, 완료 시 성공 토스트

- **위험한 액션**: 빨간색으로 강조, 확인 다이얼로그 필수


---

