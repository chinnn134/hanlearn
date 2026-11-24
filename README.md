# HanLearn AI

HanLearn dùng **một codebase Flutter** cho Web và Android, cùng backend **Python/FastAPI**. Phase 01 cung cấp khung ứng dụng và health check. Các màn Auth, từ điển, học tập, OCR và AI đang được triển khai theo từng phase; nút đăng nhập hiện là điều hướng mẫu có nhãn rõ, chưa xác thực người dùng.

## Yêu cầu môi trường

- Git, Python 3.13 và Flutter 3.47.9 (Dart đi kèm). Kiểm tra bằng `python --version`, `flutter --version`, `flutter doctor`.
- Web: Chrome để `flutter run -d chrome`. Android: Android SDK, Java toolchain và Android emulator hoặc thiết bị có trong `flutter devices`.
- Làm việc từ thư mục gốc repo. Các lệnh dưới đây dùng PowerShell; trên macOS/Linux thay `.venv\Scripts\python.exe` bằng `.venv/bin/python`.

## Chạy backend Python

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend\requirements.lock
Copy-Item .env.example .env
.\.venv\Scripts\python.exe -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 --reload
```

Trong terminal khác:

```powershell
curl.exe http://127.0.0.1:8000/health
```

Kết quả: `{"status":"ok"}` với HTTP 200. Tài liệu OpenAPI sinh bởi FastAPI ở `http://127.0.0.1:8000/docs`. Namespace `/api/v1` đã có router nhưng chưa có route chức năng; route từ điển xuất hiện ở Phase 03. `/health` chỉ báo tiến trình API sống, không báo Firebase/OCR/AI sẵn sàng.

## Chạy Flutter Web

```powershell
Set-Location apps\flutter_app
flutter pub get --enforce-lockfile
flutter run -d chrome --web-port=3000
```

Mở `http://localhost:3000`. `.env.example` cho phép origin này qua CORS. Có thể chạy Web riêng mà chưa mở backend vì UI Phase 01 chưa gọi API. Khi API client được thêm, URL backend công khai sẽ truyền qua `--dart-define=API_BASE_URL=http://127.0.0.1:8000`; biến này hiện chưa được ứng dụng đọc.

## Chạy Flutter Android

Khởi động emulator hoặc kết nối thiết bị, rồi kiểm tra `flutter devices`. Từ thư mục `apps/flutter_app`:

```powershell
flutter pub get --enforce-lockfile
flutter run -d emulator-5554
```

Thay `emulator-5554` bằng ID thật do `flutter devices` báo. Nếu cần build APK debug: `flutter build apk --debug`; file nằm ở `apps/flutter_app/build/app/outputs/flutter-apk/app-debug.apk`. Android emulator sẽ dùng `http://10.0.2.2:8000` để gọi backend trên máy host khi API client được thêm. Phase 01 chưa có kết nối API thực trong Flutter.

## Kiểm tra cục bộ

Từ thư mục gốc:

```powershell
.\.venv\Scripts\python.exe -m pip install -r backend\requirements-dev.lock
.\.venv\Scripts\ruff.exe format --check backend
.\.venv\Scripts\ruff.exe check backend
.\.venv\Scripts\python.exe -m pytest backend\tests -q
```

Từ `apps/flutter_app`:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

`.github/workflows/ci.yml` chạy các bước tương ứng trên GitHub Actions. Workflow mới chưa chạy trên GitHub vì dự án chỉ tạo branch/commit cục bộ và **không push** khi chưa có yêu cầu.

## Cấu hình và dữ liệu nhạy cảm

- `.env.example` là mẫu, `.env` bị Git bỏ qua. `APP_ENV=local` dùng origin mặc định `http://localhost:3000`; `ALLOWED_ORIGINS` nhận danh sách origin cụ thể ngăn bằng dấu phẩy. `staging`/`production` buộc khai báo origin HTTPS.
- `FIREBASE_PROJECT_ID` sẽ dùng từ Phase 02. OCR service/key dùng ở Phase 09; AI API base URL/key/model dùng ở Phase 10. Không đặt các key này trong Flutter, `--dart-define` hoặc Git.
- Dependency Python runtime/dev đã khóa trong `backend/requirements.lock` và `backend/requirements-dev.lock`; Dart khóa trong `apps/flutter_app/pubspec.lock`. Khi đổi dependency, cập nhật lockfile cùng issue.

## Tài liệu dự án

- [Kế hoạch và tiến độ](plan.md), [quy tắc triển khai](rule.md), [backlog Kanban](kanban_management.md).
- [Yêu cầu sản phẩm](docs/requirements/product-requirements.md), [kiến trúc](docs/architecture/system-architecture.md), [hợp đồng API](docs/api/openapi-contract.md), [tiêu chí nghiệm thu](docs/testing/acceptance-criteria.md).

Mỗi phase nằm trên branch `phase/xx`, mỗi issue có đúng một commit mang mã `[HL-xx-yy]`. Sau DoD phase, branch được fast-forward vào `main` cục bộ. Không push nếu người dùng chưa yêu cầu.
