## 🔐 🔐 보안 및 권한 관리

### **Row Level Security (RLS) 정책**

> 💾 **데이터베이스 쿼리**
> ```sql
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
> ```

### **앱 권한 관리**

> 📱 **Flutter/Dart 코드**
> ```dart
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
> ```


---

