# ADR: thuật toán lịch ôn bản core

- Trạng thái: accepted
- Ngày: 2026-11-21
- Issue: `HL-04-04`

## Quyết định

Bản core dùng lịch ôn có bốn rating, tính thuần trong Dart và lưu thời điểm UTC:

| Rating | Interval mới | Due mới |
|---|---:|---|
| `again` | 0 ngày | sau 10 phút |
| `hard` | lần đầu 1 ngày; sau đó `ceil(interval × 1,2)` | review time + interval |
| `good` | lần đầu 1 ngày; sau đó `interval × 2` | review time + interval |
| `easy` | lần đầu 3 ngày; sau đó `interval × 3` | review time + interval |

Interval bị chặn tối đa 365 ngày. Mỗi rating tăng `reviewCount` một lần và ghi `lastReviewedAt`. `dueAt <= now` được coi là đến hạn. Mọi đầu vào được đổi sang UTC trước khi tính; UI có thể hiển thị theo timezone thiết bị nhưng không được thay đổi instant lưu trữ.

Flashcard “Chưa biết” ánh xạ `again`, “Đã biết” ánh xạ `good`. Quiz đúng ánh xạ `good`; sai hoặc bỏ qua ánh xạ `again`. Việc ghi nhiều schedule cùng một Quiz result phải dùng một Firestore batch để không tạo trạng thái nửa vời.

## Lý do và giới hạn

Thuật toán này dễ giải thích, tái lập và đủ cho phạm vi đồ án; nó không tự nhận là SM-2. Chưa có `easeFactor` vì không dùng trong công thức. Chất lượng tối ưu ghi nhớ chưa được chứng minh; nếu thay bằng SM-2/FSRS cần migration schema, test so sánh và ADR thay thế. Thiết bị có đồng hồ sai có thể tạo due time sai; server timestamp dùng để audit thời điểm ghi nhưng client cần một `reviewedAt` nhất quán trong batch.
