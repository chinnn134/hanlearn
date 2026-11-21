# HanLearn AI — Firestore data model

> Issue `HL-00-05` · 2026-11-20 · Schema thiết kế cho MVP. `HL-02-04` đã hiện thực Rules cho `users/{uid}` và `vocabulary`; `HL-03-06` đã mở nhánh `saved_words` tối thiểu và kiểm thử bằng Emulator. API/error contract thuộc `HL-00-06`. Thay đổi schema về sau phải cập nhật client, Rules, index, test và `plan.md`.

## 1. Nguyên tắc dữ liệu

- Firebase Authentication cung cấp UID. Dữ liệu cá nhân nằm dưới `users/{uid}/...`; client chỉ truy cập nhánh có `request.auth.uid == uid`. Không dùng UID tự gửi trong request làm căn cứ quyền.
- Corpus từ điển Phase 03 nằm trong SQLite read-only của backend theo `dictionary-corpus-decision.md`; client tra qua FastAPI. `vocabulary/{vocabId}` vẫn là path được bảo vệ/read-only nhưng chưa bắt buộc seed; dữ liệu cá nhân tham chiếu cùng `vocabId` ổn định.
- Timestamps là Firestore `Timestamp` do server tạo khi có thể; lịch ôn lưu thời điểm UTC, UI đổi sang timezone địa phương để hiển thị. Không lưu ngày dạng chuỗi mơ hồ.
- Mọi collection có danh sách field cho phép, type và giới hạn kích thước; Rules xác minh các điều kiện khả thi. Backend/seed validation bổ sung các điều kiện Rules không biểu đạt được.
- Không lưu ảnh quét mặc định. Lịch sử quét chỉ sinh sau người dùng xác nhận text, giữ text OCR gốc và text đã sửa riêng.
- Field optional phải được xử lý khi thiếu/null theo contract; không tạo dữ liệu từ điển giả để lấp trống.

## 2. Sơ đồ collection

```text
vocabulary/{vocabId}                     dữ liệu chung, client đọc
users/{uid}                              hồ sơ của tài khoản
  saved_words/{vocabId}                 từ đã lưu
  review_schedule/{vocabId}             lịch ôn một từ
  quiz_results/{resultId}               kết quả một phiên Quiz
  scan_history/{scanId}                 text đã xác nhận, chỉ sau Phase 09
```

`vocabId` là ID ổn định do seed/import tạo, được dùng làm ID ở `saved_words`/`review_schedule` để tránh trùng. Không đặt Hanzi trực tiếp làm ID vì một chữ/từ có thể có nhiều cách đọc/nghĩa. `resultId` và `scanId` là ID không đoán theo thứ tự, tạo một lần khi ghi.

## 3. Field schema

### `users/{uid}`

| Field | Kiểu | Bắt buộc | Quy tắc |
|---|---|---|---|
| `displayName` | string | Có | Trim, độ dài hợp lý (đề xuất ≤ 80 ký tự); có thể lấy từ Auth hoặc tên mặc định trung tính |
| `email` | string/null | Không | Chỉ lưu khi Auth provider có email; không dùng làm owner/quyền |
| `createdAt` | Timestamp | Có | Không sửa sau tạo |
| `updatedAt` | Timestamp | Có | Cập nhật khi đổi hồ sơ |

Document này được tạo idempotent sau đăng nhập lần đầu. Email/displayName từ Auth không tự được coi là đã xác minh nếu provider không xác nhận. Bản MVP không lưu mật khẩu hoặc token tại Firestore.

### `vocabulary/{vocabId}`

| Field | Kiểu | Bắt buộc | Quy tắc |
|---|---|---|---|
| `hanzi` | string | Có | Chữ Hán giản thể/cụm từ đã chuẩn hóa, không rỗng |
| `pinyin` | string | Có | Pinyin có dấu thanh hoặc cách thể hiện đã được nguồn xác minh |
| `meaningVi` | string | Có | Nghĩa tiếng Việt có nguồn; không điền AI như dữ liệu chuẩn |
| `examples` | list of map | Không | Mỗi map có `zh`, `pinyin`, `vi` khi nguồn cung cấp và đã xác minh |
| `levels` | map/null | Không | Chỉ `hsk2` 1–6 và `hsk3` 1–7 từ nguồn đã pin; không gộp hai chuẩn thành một level mơ hồ |
| `sourceId` | string | Có | Tham chiếu metadata nguồn/import license trong docs/seed manifest |
| `updatedAt` | Timestamp | Có | Theo lần import/cập nhật dữ liệu chung |

Client tìm qua backend dictionary API, không query/scan Firestore để search. Schema corpus đầy đủ gồm `sourceEntryId`, `traditional`, `pinyinNumeric`, `meaningViSenses`, `hanViet`, `levels` và `sourceRefs`; bảng trên chỉ mô tả projection nếu sau này mirror sang Firestore. Trường `sourceId` phải truy ngược manifest/giấy phép. Seed đầu giữ `examples: []` vì chưa có nguồn ví dụ đã duyệt.

### `users/{uid}/saved_words/{vocabId}`

| Field | Kiểu | Bắt buộc | Quy tắc |
|---|---|---|---|
| `vocabId` | string | Có | Trùng document ID; ID từ corpus chung |
| `savedAt` | Timestamp | Có | Thời điểm lưu đầu tiên, giữ khi lưu lặp |
| `masteryLevel` | int | Có | Giá trị khởi tạo `0`; ý nghĩa/thang cuối cùng chốt cùng thuật toán Phase 04 |

Client dùng transaction: chỉ tạo document khi chưa tồn tại nên thao tác lưu lặp giữ nguyên `savedAt` và không thể tạo duplicate vì `vocabId` chính là document ID. Rules chỉ cho tạo với đúng ba field, `savedAt` bằng server request time và `masteryLevel = 0`; update bị cấm trong Phase 03. Bỏ lưu hiện chỉ xóa document saved word; chưa có `review_schedule` hay lịch sử Quiz ở Phase 03. Phase 04 phải chốt quan hệ dữ liệu trước khi mở Rules cập nhật mastery/lịch ôn. `masteryLevel` chưa phải số liệu dashboard “đã học” cho đến khi Phase 04 chốt quy tắc.

### `users/{uid}/review_schedule/{vocabId}`

| Field | Kiểu | Bắt buộc | Quy tắc |
|---|---|---|---|
| `vocabId` | string | Có | Trùng document ID |
| `dueAt` | Timestamp | Có | Thời điểm đến hạn UTC |
| `intervalDays` | int | Có | `0..365`; công thức trong `review-scheduling-decision.md` |
| `lastReviewedAt` | Timestamp/null | Không | Null trước lượt ôn đầu tiên |
| `reviewCount` | int | Có | Khởi tạo 0, không âm |
| `updatedAt` | Timestamp | Có sau lượt đầu | Server timestamp của lần ghi gần nhất |

Flutter client tính lịch theo ADR Phase 04, luôn đổi instant sang UTC. `again` giữ interval 0 và hẹn sau 10 phút; rating còn lại dùng ngày nguyên, tối đa 365. Khi cập nhật schedule và kết quả liên quan, dùng một Firestore batch để tránh trạng thái nửa vời. Schema không lưu `easeFactor` vì công thức hiện tại không dùng trường này.

### `users/{uid}/quiz_results/{resultId}`

| Field | Kiểu | Bắt buộc | Quy tắc |
|---|---|---|---|
| `score` | int | Có | 0 ≤ score ≤ totalQuestions |
| `totalQuestions` | int | Có | > 0; câu bỏ qua không tính đúng |
| `answeredQuestions` | int | Có | `score <= answeredQuestions <= totalQuestions` |
| `skippedQuestions` | int | Có | `totalQuestions - answeredQuestions` |
| `createdAt` | Timestamp | Có | Thời điểm hoàn thành phiên |
| `wordIds` | list of string | Có | Danh sách ID câu hỏi, 1–100 phần tử và cùng độ dài `totalQuestions` |

Không ghi toàn bộ nội dung từ điển vào kết quả Quiz nếu chỉ cần ID; tránh duplicate và tăng dung lượng.

### `users/{uid}/scan_history/{scanId}` — chỉ sau OCR thật

| Field | Kiểu | Bắt buộc | Quy tắc |
|---|---|---|---|
| `recognizedText` | string | Có | Text OCR gốc, có thể rỗng nếu service trả empty nhưng không tạo history khi chưa xác nhận |
| `correctedText` | string | Có | Text sau khi người dùng sửa/xác nhận; không rỗng nếu tạo history |
| `createdAt` | Timestamp | Có | Thời điểm xác nhận |
| `ocrProviderVersion` | string/null | Không | Chỉ metadata cần thiết, không chứa secret |

Không lưu ảnh, URL ảnh hay full request/response chứa ảnh trong document. Cần giới hạn độ dài text trước khi ghi. Việc xóa lịch sử và retention sẽ chốt trước Phase 09 theo khả năng service ngoài.

## 4. Quyền truy cập và Rules dự kiến

| Path | Guest | User cùng UID | User khác UID | Admin/seed |
|---|---|---|---|---|
| `vocabulary/{vocabId}` | Chưa chốt đọc công khai; mặc định yêu cầu auth | Read only | Read only nếu đã đăng nhập | Write có kiểm soát |
| `users/{uid}` | Deny | Read/create/update field cho phép | Deny | Quản trị theo nhu cầu |
| `users/{uid}/saved_words/*` | Deny | Read/write field cho phép | Deny | Quản trị theo nhu cầu |
| `users/{uid}/review_schedule/*` | Deny | Read/write field cho phép | Deny | Quản trị theo nhu cầu |
| `users/{uid}/quiz_results/*` | Deny | Read/create; update/delete chỉ khi use case xác định | Deny | Quản trị theo nhu cầu |
| `users/{uid}/scan_history/*` | Deny | Read/create/delete; update chỉ khi use case xác định | Deny | Quản trị theo nhu cầu |

Từ điển client **không được ghi** trong mọi trường hợp. Rules Phase 02 cần test `get`, `list`, `create`, `update`, `delete` cho đúng/khác UID, field/type sai, timestamp sai, và document ID khác `vocabId`. Firebase Admin SDK có quyền vượt Rules; chỉ chạy ở backend/script tin cậy, key không vào client/Git. Với endpoint backend dùng tài nguyên cá nhân hoặc quota theo user, xác minh ID token và lấy UID từ token.

## 5. Truy vấn, index và chi phí

| Màn/luồng | Truy vấn dự kiến | Ghi chú |
|---|---|---|
| Saved Words | `users/{uid}/saved_words` theo `savedAt desc`, giới hạn/trang | Tránh listener toàn bộ collection không giới hạn |
| Today Review | `review_schedule` với `dueAt <= now`, order `dueAt`, giới hạn | Cần index nếu query phối hợp filter/order; xác nhận trong Phase 04 |
| Recent Quiz | `quiz_results` theo `createdAt desc`, giới hạn | Dùng số lượng nhỏ cho dashboard |
| Scan History | `scan_history` theo `createdAt desc`, giới hạn | Chỉ Phase 09; không hiện dữ liệu giả ở core |
| Dictionary | Backend search Hanzi/Pinyin trên SQLite read-only, có limit/cursor | Không quét toàn bộ Firestore ở client |

`firebase/firestore.indexes.json` được tạo khi truy vấn thực tế được chốt; chỉ thêm index có test/use case. Dashboard tránh đếm bằng cách tải toàn bộ documents khi dữ liệu lớn; chiến lược count/cache được quyết định trong Phase 05 với số đo thực tế.

## 6. Test data và migration

- Firebase Emulator Suite chứa ít nhất hai UID (`A`, `B`) và các document mẫu. Test chứng minh A không thể đọc/ghi nhánh B, guest bị từ chối, từ điển không bị client sửa.
- Seed vocabulary có script idempotent; tạo ID ổn định, lưu source/version và validation; không nhập dữ liệu thiếu quyền.
- Khi schema đổi, ghi migration/compatibility plan và cập nhật Flutter model, backend schema/API, Rules, indexes và tests trong cùng issue.
- Không đưa dữ liệu tài khoản thật, ảnh nhạy cảm, service account hoặc API key vào fixture/Git.

## 7. Quyết định còn mở

| Quyết định | Thời điểm chốt | Tác động |
|---|---|---|
| Auth method và có bắt buộc email hay không | Đã chọn email/mật khẩu ở HL-02-02; giữ `users.email` optional cho khả năng mở rộng provider sau | Màn Login và hồ sơ hiện hành dùng email |
| Giới hạn chính xác độ dài field/số examples | HL-00-06, Phase 02/03 | Rules, API validation, UI |
| Thang `masteryLevel`, công thức ôn và nơi tính | Phase 04 | Rules, schedule, dashboard |
| Xóa saved word có xóa review schedule không | Phase 04 | UX, dữ liệu cá nhân |
| Có cho user sửa/xóa Quiz result/scan history | Phase 04/09 | Rules, UI, retention |
| OCR provider có lưu ảnh bên ngoài không | Phase 09 | Đồng ý dữ liệu/retention, demo |

Không tự coi các phương án còn mở là quyết định đã duyệt. Các mục có ảnh hưởng tới quyền dữ liệu phải được chốt trước khi viết Rules production.
