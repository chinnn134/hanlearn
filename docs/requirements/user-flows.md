# HanLearn AI — user flows

> Issue `HL-00-02` · 2026-11-20 · Nguồn yêu cầu: `product-requirements.md` (UC-01 đến UC-09). Đây là flow sản phẩm; layout cụ thể thuộc `HL-00-03`.

## Quy ước

- `Core`: có trước OCR/AI thật, dùng nhập/dán văn bản thủ công.
- `MVP cuối`: mở rộng core bằng OCR service thật và AI API thật qua backend Python.
- Cùng một Flutter codebase chạy Web và Android; đường vào ảnh khác nhau nhưng trạng thái sau khi đã chọn ảnh phải nhất quán.
- Chỉ dữ liệu đã được người dùng xác nhận mới được ghi vào lịch sử quét. Các bước tra và học không phụ thuộc AI hoạt động.

## F01 — Tài khoản và vào ứng dụng (core)

```mermaid
flowchart TD
    A[Mở Flutter Web hoặc Android] --> B{Có phiên đăng nhập hợp lệ?}
    B -- Không --> C[Login]
    C --> D{Đăng nhập thành công?}
    D -- Không --> E[Thông báo lỗi và thử lại]
    E --> C
    D -- Có --> F[Tạo hoặc đọc users/uid]
    B -- Có --> F
    F --> G[Home]
    G --> H[Đăng xuất]
    H --> C
```

**Điều kiện:** Firebase khả dụng; ít nhất một phương thức đăng nhập được cấu hình ở Phase 02. Khi mất mạng/phiên hết hạn, thông báo trạng thái và cho thử lại; không hiển thị dữ liệu người khác. Cùng UID trên hai nền tảng đi đến cùng dữ liệu cá nhân.

## F02 — Nhập tay, tra cứu và lưu từ (core)

```mermaid
flowchart TD
    A[Home] --> B[Text Input hoặc Dictionary]
    B --> C[Nhập hoặc dán Hanzi/Pinyin]
    C --> D{Chuỗi hợp lệ?}
    D -- Không --> E[Hướng dẫn nhập lại]
    E --> C
    D -- Có --> F[Tra từ qua backend Python]
    F --> G{Có kết quả?}
    G -- Lỗi mạng/API --> H[Thông báo và thử lại]
    H --> F
    G -- Không --> I[Không có mục từ; chọn đoạn khác hoặc nhập lại]
    I --> C
    G -- Có --> J[Dictionary Detail có nguồn]
    J --> K{Đã lưu?}
    K -- Chưa --> L[Lưu vào saved_words theo UID]
    K -- Rồi --> M[Bỏ lưu nếu người dùng chọn]
    L --> N[Saved Words]
    M --> N
```

**Quy tắc:** không tự tạo nghĩa/Pinyin để lấp dữ liệu thiếu; có thể chọn thủ công một đoạn chữ để tra. Lưu trùng phải idempotent. Nếu Firestore chưa xác nhận lưu, UI không thông báo đã đồng bộ. Việc tra từ vẫn khả dụng khi AI lỗi hoặc chưa tích hợp.

## F03 — Học, kiểm tra và xem tiến độ (core)

```mermaid
flowchart TD
    A[Home hoặc Saved Words] --> B{Có từ đã lưu?}
    B -- Không --> C[Empty state: mời tra và lưu từ]
    B -- Có --> D[Flashcard]
    D --> E[Xem mặt sau và đánh giá biết/chưa biết]
    E --> F[Cập nhật review schedule]
    F --> G[Quiz từ saved words]
    G --> H[Xem điểm và lời giải]
    H --> I[Lưu quiz_results và lịch ôn]
    I --> J[Today Review / Dashboard]
    J --> K[Xem từ đến hạn và tiến độ]
```

**Quy tắc:** câu bỏ qua không tính đúng; Quiz không đưa lựa chọn trùng/không hợp lệ. Lịch ôn có công thức và timezone được chốt ở Phase 04. Khi mất mạng, hiển thị trạng thái lưu/sync thật; không báo hoàn tất trước khi dữ liệu cá nhân được xác nhận. Đăng xuất/đăng nhập hoặc đổi nền tảng vẫn thấy dữ liệu đã đồng bộ.

## F04 — Chọn ảnh trước khi OCR sẵn sàng (core, Phase 06)

```mermaid
flowchart TD
    A[Home hoặc Scanner] --> B{Nền tảng?}
    B -- Web --> C[Chọn ảnh từ thiết bị]
    B -- Android --> D[Camera hoặc Gallery và quyền truy cập]
    C --> E[Kiểm tra định dạng/kích thước và preview]
    D --> E
    E --> F[Thông báo OCR chưa được cấu hình]
    F --> G[Nhập/dán/sửa text thủ công]
    G --> H[Tra từ theo F02]
```

**Quy tắc:** không tạo kết quả OCR giả. Ảnh lỗi/không được cấp quyền có trạng thái lỗi và đường thử lại. Chọn ảnh một mình không làm phát sinh lịch sử quét.

## F05 — Ảnh → OCR → sửa → tra (MVP cuối, Phase 09)

```mermaid
flowchart TD
    A[Scanner: Web upload hoặc Android camera/gallery] --> B[Validate ảnh và preview]
    B --> C[Gửi ảnh đến backend Python]
    C --> D[Backend gọi OCR service thật]
    D --> E{Kết quả?}
    E -- Lỗi/timeout/rỗng --> F[Thông báo, quét lại hoặc nhập tay]
    F --> A
    E -- Có --> G[Result/Edit: text, detection và confidence nếu có]
    G --> H[Người dùng sửa và xác nhận]
    H --> I[Lưu text đã xác nhận vào scan_history theo UID]
    I --> J[Chọn chữ hoặc đoạn để tra theo F02]
```

**Quy tắc:** OCR chỉ nhận chữ Hán giản thể in trong MVP. Confidence thấp phải được cảnh báo khi service cung cấp confidence. Không lưu ảnh nhạy cảm dài hạn mặc định. Giữ phân biệt text OCR ban đầu và text sửa theo schema được chốt ở `HL-00-05`/`HL-00-06`. Nếu backend/service lỗi, đường nhập tay vẫn dùng được.

## F06 — Giải thích AI (MVP cuối, Phase 10)

```mermaid
flowchart TD
    A[Dictionary Detail có mục từ đã xác minh] --> B[Người dùng chọn xem giải thích AI]
    B --> C[Flutter gọi backend Python]
    C --> D[Backend gọi AI API bằng key phía server]
    D --> E{Đầu ra hợp lệ và trong quota?}
    E -- Không --> F[Giữ dữ liệu từ điển; báo AI tạm không khả dụng]
    E -- Có --> G[AI Explanation card gắn nhãn]
    G --> H[Ví dụ Trung/Pinyin/dịch và giải thích có kiểm tra]
```

**Quy tắc:** AI không ghi đè nghĩa/Pinyin từ điển; phân tích bộ thủ chỉ khi có căn cứ. Key không gửi về client. Không lấy output model làm dữ liệu chuẩn.

## Ma trận luồng và màn hình

| Flow | Màn hình chính | Web | Android | Mốc |
|---|---|---|---|---|
| F01 | Login, Home, Profile | Có | Có | Core |
| F02 | Text Input, Dictionary, Saved Words | Có | Có | Core |
| F03 | Flashcard, Quiz, Today Review, Dashboard | Có | Có | Core |
| F04 | Scanner/Preview/Manual Edit | Upload file | Camera/Gallery | Core UI |
| F05 | Scanner, Result/Edit, Scan History | Upload file | Camera/Gallery | MVP cuối |
| F06 | Dictionary Detail, AI Explanation | Có | Có | MVP cuối |

## Lỗi và đường phục hồi chung

| Tình huống | Trạng thái hiển thị | Người dùng có thể làm tiếp |
|---|---|---|
| Chưa đăng nhập/phiên hết hạn | Yêu cầu đăng nhập | Đăng nhập lại; không xem dữ liệu cá nhân |
| Không có mục từ | Empty state có ngữ cảnh | Nhập/chọn đoạn khác |
| Mất mạng khi tra/lưu | Lỗi và trạng thái sync thật | Thử lại; không nhận đã lưu khi chưa xác nhận |
| Không có saved word | Empty state Flashcard/Quiz | Quay về Dictionary để lưu từ |
| OCR chưa cấu hình | Thông báo rõ | Nhập tay |
| OCR ảnh lỗi/timeout/không có text | Lỗi có thể thử lại | Quét lại hoặc nhập tay |
| AI lỗi/quá quota | AI tạm không khả dụng | Tiếp tục dùng dữ liệu từ điển |

## Truy vết

F01 → UC-01; F02 → UC-02/UC-03; F03 → UC-04/UC-05/UC-06; F04/F05 → UC-07/UC-09; F06 → UC-08 trong `product-requirements.md`. Wireframe cụ thể của từng màn thuộc `HL-00-03`; API và lưu dữ liệu thuộc `HL-00-05`/`HL-00-06`.
