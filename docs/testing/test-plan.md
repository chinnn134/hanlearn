# HanLearn core test plan

Phiên bản: Phase 07 · 2026-11-22 (Asia/Saigon)

## Mục tiêu và phạm vi

Xác minh bản core HanLearn trên một codebase Flutter cho Web và Android, backend
Python/FastAPI, Firebase Auth/Firestore/Rules. Phạm vi gồm Auth, từ điển nhập tay,
Saved Words, Flashcard, Quiz/lịch ôn, Dashboard, Scanner preview/nhập tay, lỗi mạng,
quyền dữ liệu và secret hygiene.

OCR thật và AI thật không thuộc gate này: **NOT VERIFIED — chưa tích hợp**. Mock
contract chỉ kiểm schema/fallback, không được dùng để nhận OCR/AI đã hoàn thành.

## Môi trường chuẩn

| Bề mặt | Môi trường | Cấu hình test |
|---|---|---|
| Flutter Web | Windows, Flutter 3.47.9/Dart 3.13.7, Chromium desktop 1280 × 720 | release bundle; API `127.0.0.1:8000`; Firebase Emulator |
| Flutter Android | AVD HanLearn_API35_D, Android 15/API 35, x86_64, 1080 × 2400 | debug APK; API `10.0.2.2:8000`; Firebase Emulator |
| Backend | Python 3.13.7, FastAPI 0.165.0, Pydantic 2.14.4 | local loopback; SQLite corpus release |
| Firebase | CLI 14.27.0; Auth 9099, Firestore 8080; rules-unit-testing 5.0.2 | project cô lập `demo-hanlearn`, UID owner/other/guest |
| Android build | Java 23.0.2 | Windows root trust store chỉ là cấu hình máy dev |

Không ghi tài khoản/mật khẩu test, token, private key hoặc `.env` thật vào báo cáo.

## Ma trận kiểm thử

| Nhóm | Tự động | Live Web | Live Android | Tiêu chí |
|---|---|---|---|---|
| Auth/profile | auth session + widget | login/logout/relogin | login/logout/relogin | UID hiện hành, persistence, profile retry |
| Dictionary | repository + 30 API tests | tra/mở/lưu | tra `xue`/mở/lưu | token, source, empty/error/retry |
| Learning | scheduler/quiz/widget | Flashcard + Quiz | Flashcard 2/2 + Quiz 1/2 | score, schedule, persistence |
| Dashboard | widget | 2 saved/2 learned/Quiz | 2 saved/2 learned/Quiz | dữ liệu thật, server/cache label đúng |
| Scanner core | widget/contract | file preview/nhập tay | gallery/camera UI/nhập tay | không nhận OCR giả, giới hạn ảnh rõ |
| Network | repository/widget | API error không loop | airplane-mode + retry | không crash/lộ exception/URL |
| Data security | Rules 7 nhóm | owner | owner | other UID/guest bị chặn, schema khóa |
| Backend security | Ruff/pytest/audit | CORS configured origin | Firebase bearer token | không secrets/log payload; Auth Emulator local-only |

## Lệnh gate

```powershell
# Flutter
cd apps/flutter_app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release `
  --dart-define=USE_FIREBASE_EMULATOR=true `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000
flutter build apk --debug `
  --dart-define=USE_FIREBASE_EMULATOR=true `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Backend
python -m ruff format --check backend
python -m ruff check backend
python -m pytest backend/tests -q
python -m pip check

# Firebase Rules, khi Firestore Emulator đang chạy
cd firebase
npm run test:rules
```

Nếu ổ hệ thống không đủ chỗ cho file tạm Flutter, đặt `TEMP`/`TMP` vào một thư
mục task riêng trên ổ còn dung lượng; không xóa dữ liệu dự án để vượt lỗi môi trường.

## E2E bắt buộc

Trên cả Web và Android: login → nhập/tra → lưu → Flashcard → Quiz → Dashboard →
logout/login → đối chiếu dữ liệu. Android thêm airplane-mode error/retry và Scanner
camera/gallery UI; Web thêm release bundle sạch. Bằng chứng chi tiết nằm ở
`phase-07-web-e2e.md` và `phase-07-android-e2e.md`.

## Phân loại lỗi và cổng

- P0: mất/cross-user data, auth bypass, secret leak, core flow không thể hoàn thành,
  crash/blocker trên cả target. P0 mở làm Phase 07 chưa đạt.
- P1: lỗi một target có workaround, lỗi UX/security không làm mất dữ liệu; phải ghi
  owner/phase xử lý.
- P2: cosmetic/tooling không ảnh hưởng kết luận.
- Gate đạt khi test tự động/build/E2E core pass, Rules an toàn và không còn P0 core.

