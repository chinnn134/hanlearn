# Phase 07 Web core E2E — HL-07-03

Ngày chạy: 2026-11-22 (Asia/Saigon)

## Phạm vi và môi trường

- Flutter Web release build phục vụ tại `http://127.0.0.1:3002`.
- Trình duyệt Chromium tích hợp của Codex trên Windows; viewport desktop 1280 × 720.
- Python/FastAPI tại `http://127.0.0.1:8000`.
- Firebase Auth + Firestore Emulator, project cô lập `demo-hanlearn`.
- OCR và AI thật không nằm trong phạm vi: `NOT VERIFIED — chưa tích hợp`.

Backend chỉ chấp nhận token Auth Emulator khi đồng thời có `APP_ENV=local` và
`FIREBASE_AUTH_EMULATOR_HOST` là loopback kèm port. Staging/production và host từ
xa bị Settings từ chối; khi bỏ biến này backend vẫn dùng xác minh chữ ký Firebase
production như trước.

## Kịch bản live browser

1. Đăng nhập tài khoản test chỉ tồn tại trong Auth Emulator.
2. Tra `学习`, lưu từ; tra `朋友`, lưu từ qua API từ điển thật của backend.
3. Mở Flashcard, lật và đánh giá cả hai từ; Firestore ghi hai review schedule.
4. Làm Quiz hai câu: một đúng, một bỏ qua; lưu kết quả `1/2`.
5. Dashboard hiển thị `2 Từ đã lưu`, `2 Từ đã học`, `0 Đến hạn hôm nay`, Quiz `1/2` và lịch sử học.
6. Đăng xuất, đăng nhập lại cùng tài khoản; Dashboard vẫn hiển thị đúng toàn bộ dữ liệu trên.

Kết quả: **PASS**. Không dùng dữ liệu hay tài khoản Firebase production.

Gate sau thay đổi: Dart format sạch, Flutter analyze sạch, **32/32** Flutter tests
PASS; Ruff sạch và **30/30** backend tests PASS.

Widget E2E xác định cũng bao phủ login → tra/lưu → Flashcard → Quiz → Dashboard
→ logout/login và kiểm tra repository vẫn giữ saved words, review schedules, quiz
result. Test này chạy bằng Flutter VM để cho kết quả ổn định trong CI/local.

## Lệnh tái lập

```powershell
firebase emulators:start --only 'auth,firestore' --project demo-hanlearn

$env:APP_ENV='local'
$env:FIREBASE_PROJECT_ID='demo-hanlearn'
$env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'
$env:ALLOWED_ORIGINS='http://127.0.0.1:3002'
python -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000

flutter build web --release --dart-define=USE_FIREBASE_EMULATOR=true `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000
flutter test test/widget_test.dart --plain-name "web core E2E persists learning data across logout and login"
```

## Hạn chế công cụ đã quan sát

`flutter test --platform chrome` trên máy này dừng ở trạng thái `loading`, kể cả
với test Dart nhỏ không render UI; tiến trình đã được dừng và **không** được tính là
PASS. Kết luận Web dựa trên E2E live bằng Chromium với bundle release và widget E2E
Flutter VM, không dựa trên runner bị treo. Phase 08 sẽ smoke lại bundle Web sạch.

Một phiên Firebase production cũ trên bundle trước đó trả 401 sau đúng một lần
forced refresh; UI hiện retry/error đúng thiết kế và không lặp vô hạn. Không tạo tài
khoản production mới chỉ để thử. Đây không phải lỗi của luồng emulator sạch ở trên.
