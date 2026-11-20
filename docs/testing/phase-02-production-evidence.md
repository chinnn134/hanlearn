# Phase 02 — bằng chứng Firebase project thật

Ngày: 2026-11-20–2026-11-21. Project: `hanlearn-7553f`. Branch: `phase/02`. Chỉ dùng tài khoản thử nghiệm miền `.invalid`; không ghi token hoặc mật khẩu vào repo.

## HL-02-07 — Firestore Rules

| Kiểm tra | Kết quả |
|---|---|
| `firebase firestore:databases:list --project hanlearn-7553f` | Có database `(default)` |
| `firebase apps:list --project hanlearn-7553f` | Có `HanLearn Web` và `HanLearn Android` |
| `npm --prefix firebase run test:rules` | 4/4 nhóm Rules test qua trên Emulator |
| `flutter analyze`; `flutter test` | Không có lỗi analyze; 4/4 widget tests qua |
| `flutter build web --no-wasm-dry-run`; `flutter build apk --debug` | Cả Web build và Android debug APK build thành công với cấu hình project thật (không bật Emulator) |
| `firebase deploy --only firestore:rules --project hanlearn-7553f --non-interactive` | Rules compile và deploy thành công, không deploy thành phần khác |
| Đọc Firebase Rules REST release/ruleset sau deploy | Release `cloud.firestore` trỏ đến ruleset `662f0926-44ca-4263-91cd-0258d8e5b02f`; nội dung file `firebase/firestore.rules` trên server trùng nội dung local sau khi bỏ whitespace đầu/cuối |
| Firestore REST GET `users/hl02-guest-probe` không kèm đăng nhập | HTTP 403 |

Firebase CLI trên máy này cần `NODE_EXTRA_CA_CERTS=D:\Temp\hanlearn-local-root.pem` để dùng kho CA cục bộ; không tắt xác minh TLS. Nội dung Rules cho owner `get/create/update` hồ sơ của UID mình, không cho `list/delete`; người dùng đăng nhập chỉ đọc `vocabulary`, collection khác mặc định từ chối. Rules trên server trước deploy là `deny all`.

## HL-02-08 — Auth và đồng bộ production

Ban đầu Auth chưa được khởi tạo và API `initializeAuth` bị chặn bởi billing. Sau khi người dùng bật Authentication → Email/Password trong Firebase Console, cấu hình project trả `email.enabled=true` và các kiểm tra sau đã chạy với project thật, không bật Emulator:

| Kiểm tra | Kết quả |
|---|---|
| Flutter Web đăng ký/đăng nhập và tạo hồ sơ | Thành công; hồ sơ `users/{uid}` được tạo và đọc lại |
| Flutter Android đăng nhập cùng tài khoản | Thành công; đọc đúng cùng document hồ sơ |
| Android sửa `displayName` → Web reload | Web nhận `AndroidProd02` |
| Web sửa `displayName` → Android mở lại | Android nhận `WebProd02` |
| Token chủ tài khoản A đọc `users/{uidA}` qua Firestore REST | HTTP 200 |
| Token tài khoản B đọc `users/{uidA}` | HTTP 403; UID A và UID B khác nhau |
| Guest đọc `users/{uidA}` | HTTP 403 |
| `flutter analyze`; `flutter test` | Không có lỗi analyze; 4/4 widget tests qua |
| `flutter build web --no-wasm-dry-run` | Thành công |
| `flutter build apk --release` | Thành công sau khi làm sạch cache Kotlin cũ và chạy compiler in-process, không incremental |
| Kiểm manifest APK release bằng Android `aapt` | Không có `networkSecurityConfig`, `usesCleartextTraffic` hoặc `debuggable` |

Máy phát triển có Avast HTTPS inspection. Android 15 emulator ban đầu không tin CA cục bộ nên Firebase Auth báo lỗi certificate. File `android/app/src/debug/res/xml/debug_network_security_config.xml` chỉ cho **debug build** tin CA do người dùng cài trên emulator; CA thật không nằm trong repo. Release manifest không kế thừa cấu hình này và tiếp tục dùng trust store mặc định của Android.

## Kết luận Phase 02

DoD đạt trên project production: Email/Password hoạt động trên Flutter Web và Android, cùng UID đồng bộ hai chiều, UID khác và guest bị từ chối. Rules production đã khớp repo. Hosted CI chưa chạy vì quy tắc dự án không cho push; việc này không thay thế các kiểm tra production ở trên. Sau commit `HL-02-08`, có thể fast-forward `main` cục bộ và mở `phase/03`. Không push.
