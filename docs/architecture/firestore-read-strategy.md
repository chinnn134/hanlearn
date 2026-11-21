# Chiến lược đọc Firestore cho bản core

Ngày chốt: 2026-11-21 — `HL-05-04`.

## Nguyên tắc

- Mọi đường dẫn cá nhân nằm dưới `users/{uid}` và repository kiểm UID hiện hành trước khi đọc.
- Dashboard dùng ba truy vấn một lần khi mở hoặc khi người dùng kéo để refresh; không duy trì snapshot listener nền.
- Saved Words và review schedule giới hạn 100 document mỗi truy vấn. Quiz gần đây giới hạn 5 document trên Dashboard và tối đa 100 ở repository.
- `QuerySnapshot.metadata.isFromCache` được truyền lên UI. Chỉ hiển thị “Đã đồng bộ từ máy chủ” khi cả ba truy vấn không đến từ cache; nếu một truy vấn dùng cache, UI ghi “Dữ liệu lưu cục bộ”.
- Khi chạm giới hạn 100, Dashboard cảnh báo số liệu có thể bị giới hạn. Pagination đầy đủ sẽ được thêm khi dữ liệu thực tế vượt ngưỡng; không tăng limit hoặc thêm listener âm thầm.

## Kiểm thử và ngân sách đọc

- Một lần mở/refresh Dashboard hiện đọc tối đa 205 document: 100 saved words + 100 schedules + 5 quiz results.
- Các màn Saved Words, Flashcard và Today Review gọi truy vấn hữu hạn theo hành động người dùng; không poll nền.
- Widget test ép metadata cache và xác nhận UI không nhận nhầm là đã đồng bộ.
- Kiểm thử production hai nền tảng và thay đổi từ thiết bị này xuất hiện ở thiết bị kia thuộc cổng `HL-05-05`.
