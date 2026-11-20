# HanLearn AI

HanLearn dùng **một codebase Flutter** cho Web và Android, cùng backend **Python/FastAPI**. Phase 02 đã hoàn tất đăng ký, đăng nhập email/mật khẩu, duy trì phiên, đăng xuất và hồ sơ Firestore; luồng đã được kiểm chứng trên Emulator lẫn Firebase project thật cho cả hai nền tảng. Từ điển, học tập, OCR và AI được triển khai theo các phase tiếp theo.

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

Kết quả: `{"status":"ok"}` với HTTP 200. Tài liệu OpenAPI sinh bởi FastAPI ở `http://127.0.0.1:8000/docs`. Namespace `/api/v1` có Dictionary search/detail yêu cầu Firebase ID token. `/health` chỉ báo tiến trình API sống, không báo Firebase/OCR/AI sẵn sàng.

## Chạy Flutter Web

```powershell
Set-Location apps\flutter_app
flutter pub get --enforce-lockfile
flutter run -d chrome --web-port=3000 `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Mở `http://localhost:3000`. `.env.example` cho phép origin này qua CORS. App dùng Firebase project `hanlearn-7553f` và gửi ID token tới backend Dictionary API. `API_BASE_URL` là bắt buộc cho tra từ; không chứa API key.

### Firebase Emulator và Rules

Để thử đăng ký/đăng nhập bằng Firebase Auth Emulator, mở terminal ở thư mục gốc:

```powershell
firebase emulators:start --only 'auth,firestore' --project demo-hanlearn
```

Trong terminal Flutter, thêm `--dart-define=USE_FIREBASE_EMULATOR=true` vào `flutter run` hoặc `flutter build`. Cùng codebase dùng `localhost` cho Web và `10.0.2.2` cho Android Emulator. `firebase/firestore.rules` cho owner đọc/tạo/sửa `users/{uid}`, owner đọc/tạo/xóa `saved_words` đúng schema và tài khoản đăng nhập đọc `vocabulary`; các collection chưa đến phase vẫn bị từ chối. Demo project không chứa dữ liệu Firebase production và không cần đăng nhập Firebase CLI.

Test Rules tự động khi Firestore Emulator đang chạy:

```powershell
npm ci --prefix firebase
npm --prefix firebase run test:rules
```

Bộ test dùng project demo riêng, hai UID và guest, không tạo tài khoản thật. Widget test Flutter kiểm tra lỗi tải hồ sơ và thử lại. Job `firestore-rules` trong CI chạy bộ test này bằng Emulator; kết quả hosted chỉ có sau khi workflow chạy trên GitHub.

Web và Android app đã đăng ký trong Firebase project `hanlearn-7553f`; FlutterFire tạo `lib/firebase_options.dart` cho hai target. File này chỉ có cấu hình SDK công khai, không chứa service account. `.env` ở gốc dành cho backend và không được Flutter đóng gói. Android dùng package `com.hanlearn.app`. **Email/Password đã bật**. Repository hồ sơ `users/{uid}` đã có; Rules cho owner và từ điển chỉ đọc đã qua test Emulator hai UID, được deploy và đọc lại khớp file repo. Đồng bộ hồ sơ Web ↔ Android hai chiều và cách ly UID đã được nghiệm thu trên production (`docs/testing/phase-02-production-evidence.md`); bằng chứng Emulator ở `docs/testing/phase-02-evidence.md`. Không đưa OCR/AI key vào Flutter.

Máy phát triển có HTTPS inspection có thể cần cài CA tương ứng vào Android emulator. Cấu hình `src/debug` cho phép debug build tin CA do user cài để kiểm thử cục bộ; APK release không mang cấu hình này và vẫn dùng trust store mặc định. Không commit CA vào repository.

Nguồn corpus Phase 03 được khóa tại OpenCidian commit `17873f10941c11ae4e410c91efdcb51c04b23c01`, dữ liệu theo CC BY-SA 4.0. Ghi công: **OpenCidian by Perxel**, CC-CEDICT, CVDICT và các upstream được liệt kê trong metadata nguồn. HanLearn sẽ build tập con đã duyệt thành SQLite cho backend; Flutter chỉ tra qua API. Xem `backend/data/dictionary/source-manifest.json` và `docs/architecture/dictionary-corpus-decision.md`.

Corpus phát hành nội bộ hiện có 500 mục trong `backend/data/dictionary/hanlearn_dictionary.sqlite3`. Build lại bằng `backend/scripts/build_dictionary.py` với `dist/entries.jsonl`, `dist/meta.json` từ đúng OpenCidian commit đã pin và `--review backend/data/dictionary/review-manifest.json`; báo cáo nằm ở `backend/data/dictionary/build-report.json`. `HL-03-08` đã audit đủ 500 record và spot-check có hệ thống 100 record theo workflow solo của tài liệu nền. Đây không phải chứng nhận ngôn ngữ độc lập/chuyên gia; ứng dụng vẫn giữ attribution và không tuyên bố nghĩa luôn tuyệt đối chính xác.

Dictionary API dùng `google-auth` để xác minh mật mã chữ ký, expiry, issuer và audience của Firebase ID token theo project; không chỉ giải mã JWT và không cần service-account/ADC cho thao tác chỉ-verify này. Backend cần `FIREBASE_PROJECT_ID`; host production phải đồng bộ đồng hồ và giữ `FIREBASE_TOKEN_CLOCK_SKEW_SECONDS=0` (override có giới hạn chỉ dành cho môi trường test cô lập). `GET /api/v1/dictionary/search?q=...` đọc SQLite read-only, hỗ trợ Hanzi/Pinyin và cursor. Không mở route v1 công khai hoặc đưa service-account JSON vào repository.

Nếu Android build trên Windows báo lỗi Kotlin incremental cache do repo và Pub cache ở hai ổ khác nhau, đặt `PUB_CACHE` cùng ổ với repo trước `flutter pub get` và build (ví dụ `$env:PUB_CACHE='D:\PubCache'`). Máy phát triển này cũng cần `$env:JAVA_TOOL_OPTIONS='-Djavax.net.ssl.trustStoreType=Windows-ROOT'` để Gradle tải Firebase từ Google Maven qua kho chứng chỉ Windows. Đây là cấu hình môi trường cục bộ, không phải yêu cầu của CI Linux.

## Chạy Flutter Android

Khởi động emulator hoặc kết nối thiết bị, rồi kiểm tra `flutter devices`. Từ thư mục `apps/flutter_app`:

```powershell
flutter pub get --enforce-lockfile
flutter run -d emulator-5554 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Thay `emulator-5554` bằng ID thật do `flutter devices` báo. Nếu cần build APK debug, truyền cùng `--dart-define`; Android emulator dùng `10.0.2.2` để gọi backend trên máy host. Thiết bị thật cần URL HTTPS/LAN phù hợp, không dùng `127.0.0.1` của máy phát triển.

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
