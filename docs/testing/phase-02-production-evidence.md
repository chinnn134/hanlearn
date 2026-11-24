# Phase 02 — bằng chứng Firebase project thật

Ngày: 2026-11-20. Project: `hanlearn-7553f`. Branch: `phase/02`. Chỉ dùng lệnh đọc cấu hình, kiểm tra build và deploy Rules đã được người dùng xác nhận; không ghi token, mật khẩu hoặc tài khoản production vào repo.

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

## Cổng HL-02-08 còn mở

`GET /admin/v2/projects/hanlearn-7553f/config` trả `CONFIGURATION_NOT_FOUND`. API `initializeAuth` trả `BILLING_NOT_ENABLED`; [tài liệu Google](https://docs.cloud.google.com/identity-platform/docs/reference/rest/v2/projects.identityPlatform/initializeAuth) mô tả cách API này dành cho project bật billing. Người dùng sẽ bật Authentication và Email/Password trong Firebase Console. Sau đó cần thử đăng ký/đăng nhập, đọc và sửa hồ sơ hai chiều trên Flutter Web/Android với project thật, cùng kiểm tra cách ly UID. Guest 403 và build thành công chưa đủ chứng minh toàn bộ DoD Phase 02.

Chưa fast-forward `main`, chưa push.
