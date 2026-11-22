# Phase 06 — bằng chứng UI ảnh và contract OCR/AI

Ngày kiểm tra: 2026-11-22

## Phạm vi

- Flutter Web chọn JPEG/PNG/WebP, kiểm magic bytes/dung lượng/pixel và preview cục bộ.
- Flutter Android mở Photo Picker hoặc Camera, dùng chung validation/preview và xử lý lỗi quyền.
- Scanner ghi rõ OCR chưa cấu hình, cho nhập/sửa văn bản thủ công rồi chuyển sang Dictionary.
- FastAPI khóa contract OCR/AI với provider thay thế được; mặc định không gọi service thật.

## Kết quả Flutter

| Kiểm tra | Kết quả |
|---|---|
| Dart format + Flutter analyze | Đạt, 33 file không đổi và không có issue |
| Flutter unit/widget tests | 27/27 đạt; gồm preview ảnh cục bộ, camera source và Scanner → Dictionary nhập tay |
| Flutter Web release build | Đạt với `API_BASE_URL=http://127.0.0.1:8000` |
| Flutter Android debug build | Đạt với `API_BASE_URL=http://10.0.2.2:8000` và Windows trust store cho Gradle |
| Android runtime | APK cài/chạy trên AVD API 35; Scanner hiện đúng cảnh báo, nút Camera/Photo Picker và vùng nhập tay |
| Android intents | Camera mở `com.android.camera2/...CaptureActivity`; thư viện mở Android Photo Picker |

Preview byte thực và điều hướng nhập tay được widget test bằng service ảnh giả xác định; không chọn ảnh cá nhân trong AVD. Không có upload, persistence ảnh hoặc `scan_history`. Crop không thêm ở Phase 06 vì chưa có OCR thật và không cần cho preview/nhập tay.

## Kết quả backend và Rules

| Kiểm tra | Kết quả |
|---|---|
| Ruff format/check | Đạt, 24 file format đúng và không có lint |
| Pytest | 25/25 đạt; một cảnh báo deprecation từ Starlette TestClient |
| OCR contract | Auth, success mock, provider chưa cấu hình, oversize, MIME không hỗ trợ và file hỏng đều đạt |
| AI contract | Auth, success mock, vocab từ corpus, validation, provider chưa cấu hình và rate limit đều đạt |
| Firestore Rules Emulator | 7/7 nhóm đạt khi chạy bằng `firebase emulators:exec` |

Lần gọi Rules trực tiếp khi chưa mở Emulator trả lỗi kết nối và không được tính là kết quả test; lần `emulators:exec` ở trên là gate hợp lệ.

## Kết luận DoD

Phase 06 đạt DoD cho UI ảnh/nhập tay và API contract. OCR thật và AI thật vẫn **NOT INTEGRATED / NOT VERIFIED**: adapter mặc định trả `503 SERVICE_NOT_CONFIGURED`, không có benchmark OCR, model AI hoặc API key nào được nghiệm thu. Hướng dẫn cấu hình và điều kiện bật provider nằm tại `docs/integrations/service-configuration.md`.
