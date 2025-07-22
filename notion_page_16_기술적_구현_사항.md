# 📚 목차

  - 기술적 구현 사항
    - 상태 관리 아키텍처
    - 데이터베이스 모델 정의
    - 에러 처리 및 로깅
    - 성능 최적화

---

## 🔧 🔧 기술적 구현 사항

### 🏗️ **상태 관리 아키텍처**

> 📱 **Flutter/Dart 코드**
> ```dart
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
> ```

### **데이터베이스 모델 정의**

> 📱 **Flutter/Dart 코드**
> ```dart
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
> ```

### **에러 처리 및 로깅**

> 📱 **Flutter/Dart 코드**
> ```dart
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
> ```

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

