# HanLearn AI

HanLearn dùng **một codebase Flutter** cho Web và Android, cùng backend **Python/FastAPI**. Phase 02 đã có đăng ký, đăng nhập email/mật khẩu, duy trì phiên và đăng xuất bằng Firebase Auth; đã kiểm chứng trên Auth Emulator cho cả hai nền tảng. Firestore, từ điển, học tập, OCR và AI đang được triển khai theo từng phase.

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

Mở `http://localhost:3000`. `.env.example` cho phép origin này qua CORS. Lệnh mặc định dùng Firebase project `hanlearn-7553f` qua `lib/firebase_options.dart`. Backend Python có thể chạy riêng vì UI chưa gọi API. Khi API client được thêm, URL backend công khai sẽ truyền qua `--dart-define=API_BASE_URL=http://127.0.0.1:8000`; biến này hiện chưa được ứng dụng đọc.

### Firebase Emulator trong Phase 02

Phase 02 đang triển khai. Để thử đăng ký/đăng nhập bằng Firebase Auth Emulator, mở terminal ở thư mục gốc:

```powershell
firebase emulators:start --only 'auth,firestore' --project demo-hanlearn
```

Trong terminal Flutter, thêm `--dart-define=USE_FIREBASE_EMULATOR=true` vào `flutter run` hoặc `flutter build`. Cùng codebase dùng `localhost` cho Web và `10.0.2.2` cho Android Emulator. `firebase/firestore.rules` cho owner đọc/tạo/sửa `users/{uid}`, tài khoản đăng nhập đọc `vocabulary`; các collection khác vẫn bị từ chối. Demo project không chứa dữ liệu Firebase production và không cần đăng nhập Firebase CLI.

Test Rules tự động khi Firestore Emulator đang chạy:

```powershell
npm ci --prefix firebase
npm --prefix firebase run test:rules
```

Bộ test dùng project demo riêng, hai UID và guest, không tạo tài khoản thật. Widget test Flutter kiểm tra lỗi tải hồ sơ và thử lại. Job `firestore-rules` trong CI chạy bộ test này bằng Emulator; kết quả hosted chỉ có sau khi workflow chạy trên GitHub.

Web và Android app đã đăng ký trong Firebase project `hanlearn-7553f`; FlutterFire tạo `lib/firebase_options.dart` cho hai target. File này chỉ có cấu hình SDK công khai, không chứa service account. `.env` ở gốc dành cho backend và không được Flutter đóng gói. Android dùng package `com.hanlearn.app`. Để dùng Auth với project thật, bật **Email/Password** trong Firebase Console → Authentication → Sign-in method; Auth chưa được khởi tạo ở lần kiểm tra gần nhất. Repository hồ sơ `users/{uid}` đã có; Rules cho owner và từ điển chỉ đọc đã qua test Emulator hai UID, được deploy lên project thật và đọc lại release trùng file repo (`docs/testing/phase-02-production-evidence.md`). Đồng bộ hồ sơ Web ↔ Android hai chiều đã được kiểm chứng trên Emulator (`docs/testing/phase-02-evidence.md`); đồng bộ production chưa nghiệm thu. Không đưa OCR/AI key vào Flutter.

Nếu Android build trên Windows báo lỗi Kotlin incremental cache do repo và Pub cache ở hai ổ khác nhau, đặt `PUB_CACHE` cùng ổ với repo trước `flutter pub get` và build (ví dụ `$env:PUB_CACHE='D:\PubCache'`). Máy phát triển này cũng cần `$env:JAVA_TOOL_OPTIONS='-Djavax.net.ssl.trustStoreType=Windows-ROOT'` để Gradle tải Firebase từ Google Maven qua kho chứng chỉ Windows. Đây là cấu hình môi trường cục bộ, không phải yêu cầu của CI Linux.

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
