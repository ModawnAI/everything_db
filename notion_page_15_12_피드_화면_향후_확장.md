## 📱 12. 피드 화면 (향후 확장)

### 🏠 **12.1 피드 메인**

#### **화면 구성**
- 위치/키워드 기반 검색
- 그리드 형태 게시물 목록
- 게시물 작성 플로팅 버튼

#### **데이터베이스 상호작용**
> 💾 **데이터베이스 쿼리**
> ```sql
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


---

