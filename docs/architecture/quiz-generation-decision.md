# ADR: tạo bộ câu hỏi Quiz ở Flutter client

- Trạng thái: accepted cho bản core
- Ngày: 2026-11-21
- Issue: `HL-04-02`

## Bối cảnh

Quiz Phase 04 chỉ dùng các mục từ người dùng đã lưu. Flutter đã tải chi tiết các mục này qua Dictionary API có xác thực. Bản core không cần ngân hàng đề chung, chống gian lận hay thuật toán thích nghi phía server.

## Quyết định

Tạo câu hỏi trắc nghiệm Hanzi → nghĩa Việt bằng logic Dart thuần trên client. Mỗi `vocabId` sinh tối đa một câu. Đáp án được chuẩn hóa khoảng trắng/chữ hoa thường để loại trùng; đáp án đúng luôn nằm trong 2–4 lựa chọn. Khi không có ít nhất hai nghĩa khác nhau, engine trả danh sách rỗng để UI giải thích cần lưu thêm từ.

Thứ tự đáp án được trộn bằng seed. Production có thể cấp seed theo lượt; test dùng seed cố định để tái lập. Chấm điểm dùng map `questionId → selectedAnswer`: câu không có lựa chọn là bỏ qua và không bao giờ được tính đúng. Kết quả giữ `correct`, `answered`, `skipped`, `total` riêng biệt.

## Hệ quả và ranh giới

- Không gửi lại toàn bộ tập từ lên backend, giảm API/Firestore read và cho phản hồi tức thì sau khi dữ liệu đã tải.
- Logic thuần dễ unit test và dùng giống nhau trên Flutter Web/Android.
- Đây không phải cơ chế thi cử an toàn: người dùng có thể xem dữ liệu client. Nếu sau này cần đề thích nghi, analytics tập trung hoặc chống gian lận, thêm Quiz API versioned và ghi ADR thay thế.
- Không sinh nghĩa/Pinyin/ví dụ mới và không dùng AI; mọi nội dung lấy từ corpus đã khóa.
