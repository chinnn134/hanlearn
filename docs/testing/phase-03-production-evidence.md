# Phase 03 — bằng chứng production Web/Android

Ngày: 2026-11-21. Branch: `phase/03`. Issue: `HL-03-07`. Firebase project: `hanlearn-7553f`.

## Phạm vi và môi trường

- Backend Python/FastAPI chạy local trên port 8000 với corpus SQLite release; Flutter Web dùng `127.0.0.1:8000`, Android emulator dùng `10.0.2.2:8000`.
- Web và Android là hai target của cùng `apps/flutter_app`; Android 15 API 35, package `com.hanlearn.app`.
- Hai tài khoản thử nghiệm production A/B được tạo riêng cho E2E. Tài liệu không lưu email, mật khẩu, ID token hay UID đầy đủ.
- Máy thử nghiệm dùng TLS inspection cục bộ và đồng hồ Windows báo `not synchronized`, lệch khoảng 6 phút. Chỉ tiến trình local đặt `REQUESTS_CA_BUNDLE` ngoài repo và `FIREBASE_TOKEN_CLOCK_SKEW_SECONDS=600`. Mặc định repo là `0`; host deploy phải đồng bộ NTP, không dùng skew này như cấu hình production.

## Kết quả đầu-cuối

| Cổng | Bằng chứng thực tế | Kết quả |
|---|---|---|
| Token backend | Firebase Auth REST cấp ID token thật; backend `google-auth` kiểm chữ ký Google, expiry, issuer `securetoken.google.com`, audience `hanlearn-7553f` và UID; search/detail `学习` trả 200 | PASS |
| Web tra cứu | Flutter Web đăng nhập A, nhập `学习`, nhận `xué xí`, nghĩa Việt, phồn thể `學習`, source `opencidian-17873f1`, attribution CC BY-SA 4.0 | PASS |
| Web lưu | Bấm `Lưu từ`; nút đổi `Bỏ lưu`; Saved Words hiện `学习  xué xí` | PASS |
| Đồng bộ Android | Android đăng nhập đúng tài khoản A; Saved Words đọc cùng document và hiện `学习  xué xí` | PASS |
| Android bỏ lưu | Bấm `Bỏ lưu 学习`; Android chuyển sang `Bạn chưa lưu từ nào.` | PASS |
| Đồng bộ về Web | Reload Web cùng UID A; màn Saved Words chuyển sang `Bạn chưa lưu từ nào.` | PASS |
| Cách ly production | Token tài khoản B đọc path saved word của A trả HTTP 403; guest trả HTTP 403; hai UID khác nhau | PASS |
| Rules production | `firebase deploy --only firestore:rules --project hanlearn-7553f` compile và release thành công | PASS |

`saved_words/{vocabId}` dùng chính `vocabId` làm document ID và transaction chỉ tạo khi chưa tồn tại, nên thao tác lưu lặp không tạo duplicate và không đổi `savedAt`. Rules production chỉ cho owner get/list/create/delete đúng schema, cấm update và mọi truy cập UID khác/guest.

## Kiểm tra tái lập

| Lệnh/cổng | Kết quả |
|---|---|
| Ruff format/check trên clean lock environment | PASS |
| `pytest backend/tests -q` | 17 passed |
| `flutter analyze` | No issues found |
| `flutter test` | 7 passed |
| `flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000` | PASS |
| Android debug build/install/run với `API_BASE_URL=http://10.0.2.2:8000` | PASS |
| `npm --prefix firebase run test:rules` | 5 passed |

Android build ban đầu lộ hai vấn đề tái lập: Gradle heap 8 GiB làm JVM cạn native memory, và Kotlin incremental cache không xử lý source/cache khác ổ. `gradle.properties` được hạ heap xuống 2 GiB, tắt Kotlin incremental và chạy compiler in-process; sau `flutter clean` + `flutter pub get` với Pub cache trên ổ D, APK build/cài thành công. Đây là cấu hình build, không thay chức năng ứng dụng.

## Kết luận

DoD Phase 03 đạt trên project thật: nhập/dán → backend xác minh token → tra thông tin có nguồn → lưu/bỏ lưu → đồng bộ Web/Android, đồng thời UID khác và guest bị Rules từ chối. OCR, AI và TTS không được thêm sớm; chúng vẫn theo phase đã định.
