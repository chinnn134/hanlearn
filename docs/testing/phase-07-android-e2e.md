# Phase 07 Android core E2E — HL-07-04

Ngày chạy: 2026-11-22 (Asia/Saigon)

## Môi trường

- Windows host; Flutter 3.47.9, Dart 3.13.7.
- AVD `HanLearn_API35_D`, Android 15 / API 35, x86_64, 1080 × 2400.
- APK debug dùng `USE_FIREBASE_EMULATOR=true` và `API_BASE_URL=http://10.0.2.2:8000`.
- Python/FastAPI, Firebase Auth Emulator và Firestore Emulator chạy trên host.
- Tài khoản/dữ liệu chỉ thuộc project test cô lập `demo-hanlearn`.
- OCR và AI thật: `NOT VERIFIED — chưa tích hợp`.

## Kịch bản live Android

1. Cài APK mới, đăng nhập Auth Emulator.
2. Xác nhận hai từ `朋友`, `学习` đã đồng bộ từ Web E2E.
3. Tra `xue` qua FastAPI; mở `学习`, thấy nguồn và trạng thái đã lưu.
4. Flashcard: lật và đánh giá đủ 2/2 thẻ; review schedule ghi vào Firestore.
5. Quiz: chọn đúng câu `朋友`, bỏ qua câu `学习`; kết quả `1/2`, một trả lời và một bỏ qua.
6. Dashboard hiển thị `2 Từ đã lưu`, `2 Từ đã học`, `0 Đến hạn hôm nay`, Quiz mới `1/2` và lịch sử ôn.
7. Đăng xuất rồi đăng nhập lại; Home và dữ liệu người dùng vẫn tải thành công.
8. Scanner hiển thị Photo Picker, camera, giới hạn ảnh và nhãn rõ “OCR chưa được cấu hình”; không upload hoặc nhận dạng giả.

Kết quả: **PASS**.

## Mạng lỗi và phục hồi

- Bật airplane mode rồi tra `xue`: app hiển thị thông báo thân thiện “Không thể kết nối máy chủ. Kiểm tra mạng rồi thử lại.” và nút `Thử lại`.
- Không còn lộ `SocketException`, stack/URL backend trong UI.
- Tắt airplane mode rồi bấm `Thử lại`: danh sách từ điển tải lại thành công mà không cần restart app.

Trong lần chạy đầu, Auth Emulator bị Android chặn do debug network security config
chưa khai báo `base-config cleartextTrafficPermitted`. Đã sửa **chỉ** tại
`android/app/src/debug`; manifest release/main không bật cleartext. APK debug được
build/cài lại và toàn bộ kịch bản trên đã PASS.

## Gate tự động

- Dart format: PASS.
- Flutter analyze: PASS.
- Flutter tests: **33/33 PASS**, gồm hồi quy che chi tiết lỗi mạng.
- Android debug APK build/install: PASS.

## Lệnh chính

```powershell
flutter build apk --debug `
  --dart-define=USE_FIREBASE_EMULATOR=true `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell cmd connectivity airplane-mode enable
adb shell cmd connectivity airplane-mode disable
```
