# Phase 04 — bằng chứng nghiệm thu Flashcard, Quiz và lịch ôn

Ngày kiểm tra: 2026-11-21

Firebase project: `hanlearn-7553f`
Phạm vi: Flutter Web, Flutter Android, backend Python và Firestore Rules production.

## Kết quả chức năng

- Flashcard đọc đúng Saved Words, hỗ trợ lật thẻ, trước/sau và bốn mức đánh giá.
- Quiz chỉ tạo câu hỏi từ dữ liệu từ điển đã xác thực, loại đáp án trùng, hiển thị lời giải và score/total.
- Today Review tính saved word chưa có schedule là đến hạn; schedule có `dueAt` trong tương lai không đến hạn; khi không còn thẻ đến hạn hiển thị trạng thái hoàn tất.
- Web production đã lưu hai từ, học Flashcard, hoàn thành Quiz 2/2, đăng xuất/đăng nhập và đọc lại dữ liệu.
- Android đăng nhập cùng tài khoản, đọc cùng Saved Words/schedule, hiển thị Today Review hoàn tất, mở Flashcard và hoàn thành Quiz 2/2.
- Kiểm tra REST bằng token owner sau luồng Android xác nhận hai schedule đều có `reviewCount=3` và có hai quiz result, mỗi result đạt 2/2. Không lưu email, mật khẩu hay token thử nghiệm vào repo.

## Kiểm tra tự động và build

| Thành phần | Kết quả |
|---|---|
| `dart format` / `flutter analyze` | Đạt, không có cảnh báo phân tích |
| Flutter tests | 21/21 đạt, gồm Today Review chưa có schedule, loại lịch tương lai và Completed State |
| Flutter Web release | Build thành công với backend local; bản build chạy và hiển thị Today Review production |
| Flutter Android debug | Build, cài và chạy thành công trên Android 15 AVD `HanLearn_API35_D` |
| Backend Ruff | Format/check đạt |
| Backend pytest | 17/17 đạt; còn một cảnh báo deprecation từ Starlette, không ảnh hưởng kết quả |
| Firestore Rules Emulator | 7/7 nhóm đạt khi chạy qua `firebase emulators:exec --only firestore` |
| Firestore production | Rules đã deploy; owner đọc/ghi đúng schema, guest/UID khác bị từ chối theo bằng chứng persistence |

## Ghi chú môi trường

- AVD `HanLearn_API35` đặt dữ liệu ở ổ C không khởi động được do thiếu dung lượng. Kiểm thử Android chuyển sang AVD tương đương `HanLearn_API35_D` đặt dữ liệu ở ổ D và hoàn tất; đây là giới hạn máy kiểm thử, không phải lỗi ứng dụng.
- Máy kiểm thử dùng CA cục bộ cho TLS bị phần mềm bảo mật kiểm tra và cho phép clock skew hữu hạn khi xác minh token trong môi trường kiểm thử. Cấu hình production mặc định vẫn yêu cầu đồng hồ đồng bộ và clock skew bằng 0.
- Tài khoản thử nghiệm và token chỉ dùng trong phiên kiểm tra, không được ghi vào Git.

## Kết luận

Phase 04 đạt Definition of Done: cùng dữ liệu production tồn tại qua logout/login và được sử dụng trên cả Flutter Web lẫn Flutter Android; Flashcard, Quiz, scheduler, Today Review và Rules đều có kiểm thử. Phase tiếp theo có thể bắt đầu từ `main` sau khi `phase/04` được fast-forward cục bộ; không push.
