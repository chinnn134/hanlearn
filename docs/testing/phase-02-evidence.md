# Phase 02 — bằng chứng HL-02-06

Ngày kiểm chứng: 2026-11-20. Branch: `phase/02`. Môi trường: Firebase Auth/Firestore Emulator (`demo-hanlearn`, cổng 9099/8080), Flutter Web tại `http://localhost:3000`, Android 15 Emulator với APK debug `com.hanlearn.app`. Cả hai build dùng `--dart-define=USE_FIREBASE_EMULATOR=true` và cùng tài khoản thử nghiệm miền `.invalid`; không dùng tài khoản production.

## Kết quả đồng bộ hai chiều

| Bước | Thao tác | Kết quả quan sát |
|---|---|---|
| 1 | Android đăng nhập và lưu `RuleTest`; Web đăng nhập cùng tài khoản, mở Hồ sơ | Web hiển thị đúng email thử nghiệm và `Tên hiển thị: RuleTest` |
| 2 | Web sửa tên thành `WebSync02`; Android khởi động lại và mở Hồ sơ | Android hiển thị `Tên hiển thị: WebSync02` |
| 3 | Android sửa tên thành `AndroidSync02`; Web reload trang Hồ sơ | Web hiển thị `Tên hiển thị: AndroidSync02`; phiên đăng nhập Web được giữ |
| 4 | Đọc document từ Firestore Emulator bằng token của cùng UID | Một `users/VSWeCC6BkgyIOTHXVzNYu7ijksSx` có `displayName=AndroidSync02`, các field `email,createdAt,displayName,updatedAt`; `createdAt` không đổi sau các lần sửa |

`flutter build web --no-wasm-dry-run --dart-define=USE_FIREBASE_EMULATOR=true` và `flutter build apk --debug --dart-define=USE_FIREBASE_EMULATOR=true` đều hoàn tất. Web được mở trực tiếp trong trình duyệt, APK được cài và chạy trên Android Emulator. Rules unit tests (4 nhóm) và Flutter widget tests (4 bài) thuộc `HL-02-05`; chúng xác nhận cách ly UID/field và trạng thái retry cục bộ. Trình duyệt và Android đều đã quan sát kết quả dữ liệu trực tiếp với Rules chính thức trong repo.

## Cổng Phase 02 còn mở

- Chưa xác minh Email/Password provider đã bật trên Firebase project thật `hanlearn-7553f`.
- `firebase/firestore.rules` chưa được deploy và kiểm tra trên project thật.
- Chưa thử cùng tài khoản trên Flutter Web và Android với Auth/Firestore production; kết quả Emulator không chứng minh đồng bộ production.
- Hosted CI chưa chạy vì repository chưa push theo yêu cầu. Kiểm tra mất mạng thật trên thiết bị chưa được đo; widget test chỉ mô phỏng lỗi repository.

DoD Phase 02 vẫn **chưa đạt trên project thật**. Giữ branch `phase/02` và chưa mở Phase 03 cho đến khi các cổng production được xử lý và ghi bằng chứng trong `plan.md`.
