# HanLearn AI — sitemap và wireframe mức thấp

> Issue `HL-00-03` · 2026-11-20 · Nguồn: `product-requirements.md`, `user-flows.md`. Wireframe mô tả cấu trúc/thứ tự nội dung, chưa chốt màu, font hay kích thước pixel.

## 1. Nguyên tắc chung

- Một codebase Flutter cho Web và Android; nội dung/chức năng giống nhau, cách xếp khối đổi theo chiều rộng.
- **Web:** vùng điều hướng cạnh trái hoặc trên, vùng nội dung ở giữa, form và card có chiều rộng dễ đọc. **Android:** thanh tiêu đề, nội dung cuộn dọc, điều hướng dưới cho mục chính; nút chính dễ chạm và không bị bàn phím che.
- Các màn đăng nhập/tra từ/học tập có loading, empty, error/retry. Nút lưu chỉ báo thành công khi Firestore xác nhận; các màn không phơi dữ liệu của UID khác.
- OCR và AI thực tế chỉ có ở Phase 09/10. Trước đó scanner hiển thị trạng thái chưa cấu hình và đường nhập tay; AI card không hứa hẹn nội dung giả.
- Text trong ví dụ là dữ liệu minh họa cho wireframe, **không** phải mục từ đã seed hay kết quả OCR thật.

## 2. Sitemap

```text
Guest
└─ Login
   └─ Authenticated shell
      ├─ Home
      │  ├─ Text Input ─→ Dictionary Search ─→ Dictionary Detail ─→ Save/Unsave
      │  ├─ Scanner ─→ Result/Edit ─→ Dictionary Search  [OCR thật ở Phase 09]
      │  ├─ Today Review ─→ Flashcard
      │  └─ Progress
      ├─ Saved Words ─→ Dictionary Detail / Flashcard / Quiz
      ├─ Quiz ─→ Result ─→ Review Schedule
      └─ Profile/Settings ─→ Logout
```

Luồng AI mở từ **Dictionary Detail** và chỉ có nội dung thật ở Phase 10. **Scan History** gắn với Home/Progress sau khi có bản quét đã được người dùng xác nhận ở Phase 09.

## 3. Khung điều hướng

### Web — khung authenticated

```text
┌────────────────┬─────────────────────────────────────────────────────────────┐
│ HanLearn AI    │ [Tiêu đề màn]                        [Trạng thái tài khoản] │
│────────────────│─────────────────────────────────────────────────────────────│
│ Home           │                                                             │
│ Tra từ         │                    NỘI DUNG MÀN                            │
│ Từ đã lưu      │                  (chiều rộng dễ đọc)                        │
│ Ôn tập         │                                                             │
│ Tiến độ        │                                                             │
│ Scanner        │                                                             │
│ Hồ sơ          │                                                             │
└────────────────┴─────────────────────────────────────────────────────────────┘
```

### Android — khung authenticated

```text
┌────────────────────────────────────┐
│ [← nếu là màn con] Tiêu đề     ⋮    │
├────────────────────────────────────┤
│                                    │
│      NỘI DUNG CUỘN DỌC             │
│                                    │
├────────────────────────────────────┤
│ Home   Tra từ   Ôn tập   Tiến độ   │
└────────────────────────────────────┘
```

Saved Words, Scanner và Profile có thể vào từ Home/overflow hoặc một mục điều hướng nếu kiểm tra thực tế cho thấy phù hợp; Phase 08 chốt navigation cuối. Mọi màn con có lối quay lại rõ. Trên Android, CTA chính nằm trong vùng nhìn/chạm thuận tiện, nhưng không đè lên nội dung khi bàn phím mở.

## 4. Wireframe từng màn

### WF-01 — Login (UC-01, core)

```text
WEB                                      ANDROID
┌──────────────────────────────────┐     ┌────────────────────────┐
│             Logo                 │     │       HanLearn AI      │
│       Học chữ Hán dễ hơn         │     │                        │
│   ┌──────────────────────────┐   │     │ [Phương thức đăng nhập]│
│   │ Phương thức đăng nhập    │   │     │ [Đăng nhập]            │
│   │ [Đăng nhập]              │   │     │                        │
│   │ lỗi / đang xử lý         │   │     │ lỗi / đang xử lý       │
│   └──────────────────────────┘   │     │                        │
└──────────────────────────────────┘     └────────────────────────┘
```

Ít nhất một phương thức Auth; cụ thể được chốt ở Phase 02. Khi phiên hợp lệ, đi Home. Lỗi không xóa dữ liệu người dùng vừa nhập nếu phương thức có form.

### WF-02 — Home (UC-01/02/04/06, core)

```text
WEB                                      ANDROID
┌──────────────────────────────────┐     ┌────────────────────────┐
│ Xin chào, [tên]                  │     │ Xin chào, [tên]        │
│ [Nhập chữ để tra] [Chọn ảnh]      │     │ [Nhập chữ để tra]      │
│ ┌────────────┐ ┌──────────────┐   │     │ [Chọn ảnh / Scanner]   │
│ │ Đến hạn ôn │ │ Từ đã lưu    │   │     │ ────────────────────── │
│ └────────────┘ └──────────────┘   │     │ Đến hạn ôn  Từ đã lưu  │
│ [Tiếp tục Flashcard] [Làm Quiz]   │     │ [Ôn Flashcard]         │
│ [Quiz gần đây / hoạt động học]    │     │ [Làm Quiz]             │
└──────────────────────────────────┘     │ Quiz gần đây           │
                                         └────────────────────────┘
```

Core ưu tiên đường **nhập tay**. Scan History chỉ xuất hiện khi có bản quét thật; số liệu lỗi/tải có trạng thái rõ.

### WF-03 — Text Input + Dictionary Search (UC-02, core)

```text
WEB                                      ANDROID
┌──────────────────────────────────┐     ┌────────────────────────┐
│ [Hanzi hoặc Pinyin..........] 🔍  │     │ [Nhập Hanzi/Pinyin] 🔍  │
│ [Gợi ý nhập/chọn đoạn]            │     │ [Gợi ý nhập/chọn đoạn]  │
│ ───── Kết quả / trống / lỗi ────  │     │ Kết quả / trống / lỗi   │
│ [Hanzi]  [Pinyin]  [Nghĩa ngắn]  │     │ [Hanzi] [Pinyin]        │
│ [Hanzi]  [Pinyin]  [Nghĩa ngắn]  │     │ [Nghĩa ngắn]            │
│ [Phân trang / tải thêm]           │     │ [Tải thêm]             │
└──────────────────────────────────┘     └────────────────────────┘
```

Cho dán text từ ngoài hoặc nhận text đã sửa từ OCR. Với chuỗi nhiều chữ, người dùng được chọn đoạn để tra; không ép phân từ tự động. Trạng thái không có mục từ không biến thành mục từ AI tự bịa.

### WF-04 — Dictionary Detail (UC-02/03/08, core + AI cuối)

```text
WEB                                      ANDROID
┌──────────────────────────────────┐     ┌────────────────────────┐
│ [Hanzi lớn]      [Lưu/Bỏ lưu]    │     │ [Hanzi lớn] [☆/★]      │
│ Pinyin / Nghĩa tiếng Việt        │     │ Pinyin                 │
│ Ví dụ tiếng Trung               │     │ Nghĩa tiếng Việt       │
│ Pinyin ví dụ / Dịch             │     │ Ví dụ + dịch           │
│ Nguồn dữ liệu / HSK nếu có       │     │ Nguồn / HSK nếu có      │
│ ─── AI giải thích (Phase 10) ──  │     │ AI giải thích (P10)    │
└──────────────────────────────────┘     └────────────────────────┘
```

Nguồn dữ liệu luôn phân biệt với giải thích AI. AI card chỉ hiện khi đã tích hợp; lỗi AI không ẩn dữ liệu từ điển. TTS nếu có nguồn/platform phù hợp mới thêm.

### WF-05 — Saved Words (UC-03, core)

```text
WEB                                      ANDROID
┌──────────────────────────────────┐     ┌────────────────────────┐
│ Từ đã lưu       [Ôn] [Quiz]      │     │ Từ đã lưu             │
│ [Tìm/lọc]                        │     │ [Tìm/lọc]              │
│ Hanzi | Pinyin | Nghĩa | Due     │     │ Hanzi  Pinyin          │
│ ───────────────────────────────  │     │ Nghĩa  Due  [Bỏ lưu]   │
│ ... [Bỏ lưu]                     │     │ [Ôn]       [Quiz]      │
└──────────────────────────────────┘     └────────────────────────┘
```

Empty state dẫn về Dictionary. Bỏ lưu cần xác nhận nếu làm mất lịch ôn/dữ liệu học, chi tiết xử lý được chốt ở Phase 04–05.

### WF-06 — Flashcard / Today Review (UC-04/05, core)

```text
WEB                                      ANDROID
┌──────────────────────────────────┐     ┌────────────────────────┐
│ Hôm nay: [số từ đến hạn]          │     │ Hôm nay: [số đến hạn]  │
│ [Trước] ┌────────────────┐ [Sau]  │     │ ┌────────────────────┐ │
│         │ Hanzi / lật thẻ│        │     │ │ Hanzi / lật thẻ    │ │
│         │ Pinyin/nghĩa   │        │     │ │ Pinyin/nghĩa      │ │
│         └────────────────┘        │     │ └────────────────────┘ │
│ [Chưa biết]         [Đã biết]     │     │ [Chưa biết] [Đã biết]  │
└──────────────────────────────────┘     └────────────────────────┘
```

Mặt sau thêm ví dụ khi có. Đánh giá cập nhật lịch ôn sau xác nhận lưu; trạng thái hoàn thành khi hết thẻ. Nếu chưa có saved word hoặc chưa đến hạn, hiển thị giải thích và đường vào Saved Words.

### WF-07 — Quiz và kết quả (UC-05, core)

```text
WEB                                      ANDROID
┌──────────────────────────────────┐     ┌────────────────────────┐
│ Câu 2/10              [Tiến độ]  │     │ Câu 2/10  [Tiến độ]    │
│ Hanzi hoặc Pinyin?                │     │ Hanzi hoặc Pinyin?     │
│ ( ) Lựa chọn A   ( ) Lựa chọn B   │     │ ( ) Lựa chọn A         │
│ ( ) Lựa chọn C   ( ) Lựa chọn D   │     │ ( ) Lựa chọn B         │
│ [Bỏ qua]             [Trả lời]    │     │ ( ) Lựa chọn C         │
│ ─── Kết quả: score/total ─────   │     │ ( ) Lựa chọn D         │
│ [Lời giải từng câu] [Ôn tiếp]    │     │ [Bỏ qua] [Trả lời]     │
└──────────────────────────────────┘     │ Kết quả/lời giải       │
                                         └────────────────────────┘
```

Không đủ saved words thì giải thích vì sao chưa tạo được Quiz. Lời giải dùng dữ liệu đã xác minh; câu bỏ qua không tính là đúng. Kết quả lưu đúng UID.

### WF-08 — Progress/Dashboard (UC-06/09, core + OCR cuối)

```text
WEB                                      ANDROID
┌──────────────────────────────────┐     ┌────────────────────────┐
│ [Từ lưu] [Đã học] [Đến hạn]       │     │ [Từ lưu] [Đã học]      │
│ ─── Quiz gần đây ───────────────  │     │ [Đến hạn]              │
│ ngày | score/total               │     │ Quiz gần đây           │
│ ─── Lịch sử học ────────────────  │     │ Lịch sử học            │
│ ─── Scan History (P09) ─────────  │     │ Scan History (P09)     │
└──────────────────────────────────┘     └────────────────────────┘
```

Scan History không hiện khối giả ở bản core. Dữ liệu chưa đồng bộ hiển thị trạng thái thật; không tính số từ “đã học” nếu chưa chốt cách tính ở Phase 04/05.

### WF-09 — Profile/Settings (UC-01, core)

```text
WEB                                      ANDROID
┌──────────────────────────────────┐     ┌────────────────────────┐
│ [Tên hiển thị]                    │     │ [Tên hiển thị]         │
│ [Email nếu có]                    │     │ [Email nếu có]         │
│ [Sửa tên]                         │     │ [Sửa tên]              │
│ [Thông tin phiên bản]             │     │ [Thông tin phiên bản]  │
│ [Đăng xuất]                       │     │ [Đăng xuất]            │
└──────────────────────────────────┘     └────────────────────────┘
```

Chỉ thêm settings phục vụ demo; đăng xuất xóa trạng thái phiên trên thiết bị và quay về Login, không xóa dữ liệu server.

### WF-10 — Scanner, Result/Edit, Scan History (UC-07/09)

```text
WEB                                      ANDROID
┌──────────────────────────────────┐     ┌────────────────────────┐
│ [Chọn ảnh] [Preview]             │     │ [Camera] [Gallery]     │
│ loại/size/lỗi ảnh                │     │ [Preview]              │
│ [OCR chưa cấu hình] (trước P09)  │     │ [OCR chưa cấu hình]    │
│ [Nhập text thủ công]              │     │ [Nhập text thủ công]    │
│ ── Sau P09 ────────────────────  │     │ ── Sau P09 ─────────  │
│ [Quét] → [Text/box/confidence]   │     │ [Quét] [Text/conf.]     │
│ [Sửa text] [Xác nhận] [Quét lại] │     │ [Sửa] [Xác nhận]       │
│ [Lịch sử text đã xác nhận]        │     │ [Lịch sử text]         │
└──────────────────────────────────┘     └────────────────────────┘
```

Trước Phase 09 không có nút quét hoạt động giả. Sau Phase 09, sửa/confirm là bước bắt buộc trước khi lưu scan history và tra/lưu từ. Nếu service lỗi hoặc ảnh không hợp lệ, vẫn có đường nhập tay. Android yêu cầu quyền camera/gallery phù hợp; Web dùng file picker.

## 5. Trạng thái và hành vi xuyên màn hình

| Trạng thái | Cách thể hiện | Hành động tiếp |
|---|---|---|
| Loading | Spinner/skeleton ở vùng dữ liệu, CTA tránh gửi lặp | Chờ hoặc hủy nếu có thể |
| Empty | Lý do cụ thể và CTA (nhập từ/lưu từ) | Đi đúng màn tạo dữ liệu |
| Error | Thông báo dễ hiểu, giữ input khi phù hợp | Thử lại hoặc nhập tay |
| Saving/Syncing | Hiển thị đang lưu/chưa đồng bộ | Không xác nhận thành công sớm |
| OCR/AI chưa cấu hình | Nhãn rõ trên màn liên quan | Dùng core, không hiển thị mock như thật |

## 6. Truy vết và bước tiếp theo

| Wireframe | Flow | PRD use case | Phase triển khai |
|---|---|---|---|
| WF-01 | F01 | UC-01 | 02 |
| WF-02 | F01/F02/F03 | UC-01/02/04/06 | 01/05 |
| WF-03 | F02 | UC-02 | 03 |
| WF-04 | F02/F06 | UC-02/03/08 | 03/10 |
| WF-05 | F02/F03 | UC-03 | 03 |
| WF-06 | F03 | UC-04/05 | 04 |
| WF-07 | F03 | UC-05 | 04 |
| WF-08 | F03/F05 | UC-06/09 | 05/09 |
| WF-09 | F01 | UC-01 | 05 |
| WF-10 | F04/F05 | UC-07/09 | 06/09 |

Các quyết định chi tiết về breakpoints, màu/typography, số mục bottom nav và tác động bàn phím được thử/chốt khi triển khai và ở Phase 08 UX. Không coi wireframe là bằng chứng tính năng đã chạy.
