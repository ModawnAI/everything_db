# 📚 목차

  - 4 샵 탐색 및 검색 결과 화면
    - 41 검색 화면
      - 화면 구성
      - 데이터베이스 상호작용
      - 기능 및 로직
      - UIUX 구현 상세
      - BLoC 구조

---

## 🔍 4. 샵 탐색 및 검색 결과 화면

### 🔍 **4.1 검색 화면**

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
> 💾 **데이터베이스 쿼리**
> ```sql
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
> ```

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
- 🔍 **검색창**:
  - `TextField` + `debouncer` (500ms), 검색 중 로딩 아이콘
  - **자동완성**: `TypeAhead` 위젯, 드롭다운 검색 제안
  - 🔍 **최근 검색**: `Chip` 위젯들, 탭 시 즉시 검색
  - 🔍 **음성 검색**: `FloatingActionButton` + 음성 인식

- 🔘 **필터 버튼**: 
  - `FilterChip` 그룹, 활성화 시 색상 변화
  - 필터 적용 시 `Badge`로 개수 표시
  - 🔽 **필터 시트**: `BottomSheet` 슬라이드업, 다중 선택

- **정렬 옵션**:
  - `DropdownButton` 또는 `PopupMenuButton`
  - 선택 변경 시 리스트 `AnimatedList` 재정렬

- 📊 **결과 목록**:
  - 🃏 **카드**: `Card` + 그림자, 탭 시 `Hero` 전환
  - 📋 **리스트/그리드 토글**: `IconButton`, 전환 시 `AnimatedSwitcher`
  - ♾️ **무한 스크롤**: 하단 도달 시 `CircularProgressIndicator`
  - 📊 **빈 결과**: `Lottie` 애니메이션 + "검색 결과가 없어요" 메시지

- 🗺️ **지도 뷰**: `GoogleMap` 위젯, 마커 클러스터링, 줌 컨트롤

#### **BLoC 구조**
> 📱 **Flutter/Dart 코드**
> ```dart
// SearchBloc
// Events: SearchShops, ApplyFilters, ChangeSort, LoadMore
// States: SearchInitial, SearchLoading, SearchLoaded, SearchError
> ```


---

