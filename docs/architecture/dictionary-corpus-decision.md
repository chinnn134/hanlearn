# Quyết định corpus từ điển Phase 03

> Issue `HL-03-01` · Chấp nhận ngày 2026-11-21 · Áp dụng cho backend Python và Flutter Web/Android.

## Bối cảnh và quyết định

HanLearn cần tra giản thể/Pinyin, nghĩa Việt có nguồn và ID ổn định để lưu từ. Firestore không hỗ trợ tìm kiếm prefix Pinyin/Hanzi linh hoạt mà không nhân bản search key/index; client cũng không được quét collection chung. Vì vậy:

1. Nguồn chính là **OpenCidian by Perxel**, pin chính xác commit `17873f10941c11ae4e410c91efdcb51c04b23c01` ngày 2026-11-10. Metadata máy đọc nằm ở `backend/data/dictionary/source-manifest.json`.
2. Dữ liệu dẫn xuất được phát hành theo **CC BY-SA 4.0**, ghi công “OpenCidian by Perxel” và toàn bộ upstream trong `dist/meta.json`. Không xóa provenance hoặc đổi dữ liệu này sang giấy phép đóng.
3. `HL-03-02` build nguồn đã pin, xác minh checksum, duyệt 300–500 mục nếu đạt chất lượng và sinh **SQLite read-only** cho backend. Không commit toàn bộ upstream thô. Artifact sinh phải có SHA-256, số mục thực và attribution đi kèm.
4. FastAPI là cổng tra cứu duy nhất. Firestore `vocabulary` không dùng làm search engine; có thể chưa seed collection này. Dữ liệu cá nhân chỉ lưu `vocabId`, còn nội dung chuẩn luôn đọc từ API corpus.
5. Không dùng LLM để bổ sung nghĩa, Pinyin, ví dụ hoặc level. Mục thiếu trường bắt buộc bị loại; `examples=[]` và level thiếu giữ `null`.

## Schema chuẩn hóa

| Field | Kiểu | Nguồn/quy tắc |
|---|---|---|
| `vocabId` | string | `ocd_` + SHA-256 hex đầy đủ của UTF-8 `sourceEntryId`; ổn định, không chứa dữ liệu người dùng |
| `sourceEntryId` | string | OpenCidian `id` nguyên bản để truy vết |
| `hanzi` | string | `simp`, Unicode NFC, trim, bắt buộc |
| `traditional` | string | `trad`, Unicode NFC, trim, bắt buộc |
| `pinyin` | string | Pinyin có dấu từ nguồn, NFC, collapse whitespace, bắt buộc |
| `pinyinNumeric` | string | `pinyinNum` từ nguồn, lowercase/collapse whitespace, bắt buộc |
| `meaningVi` | string | Các `vi.senses` hợp lệ nối bằng `; ` cho API/list UI |
| `meaningViSenses` | list[string] | Sense tiếng Việt đã trim, giữ thứ tự, bỏ phần tử rỗng/trùng chính xác |
| `hanViet` | list[string] | Các cách đọc Hán Việt theo thứ tự ký tự và provenance nguồn; optional ở API core |
| `levels` | map/null | Chỉ `hsk2` 1–6 và `hsk3` 1–7 khi OpenCidian cung cấp; không suy đoán |
| `examples` | list | Luôn rỗng ở seed đầu vì nguồn mục từ không cấp ví dụ đã duyệt |
| `sourceId` | string | `opencidian-17873f1` |
| `sourceRefs` | map | Ít nhất nguồn Pinyin/mục từ và nguồn nghĩa Việt theo record |

Mọi string giới hạn theo API contract; record vượt giới hạn hoặc không hợp lệ bị ghi vào báo cáo reject, không cắt âm thầm. Collision `vocabId` với `sourceEntryId` khác làm import thất bại.

## Search normalization

- Hanzi: NFC + trim; hỗ trợ exact và prefix trên `hanzi`, không tự chuyển phồn thể thành giản thể ngoài mapping nguồn.
- Pinyin: lowercase; chuẩn hóa `u:`/`ü` thành `v`; bỏ dấu thanh và chữ số thanh cho search key; collapse whitespace. Lưu cả key có khoảng trắng và compact để `xue xi`, `xuexi`, `xuéxí`, `xue2 xi2` cùng tìm được.
- Xếp hạng: exact Hanzi → prefix Hanzi → exact Pinyin → prefix Pinyin; sau đó `hanzi`, `pinyinNumeric`, `vocabId` để kết quả xác định và phân trang ổn định.
- SQLite có unique index trên `vocabId`, index `hanzi`, `pinyinSearch`, `pinyinSearchCompact`; query luôn có `limit` tối đa 50 và cursor opaque.

## Hệ quả và cổng tiếp theo

- Ưu điểm: build/import tái lập, tìm kiếm nhanh, backend Python kiểm soát validation, không tăng chi phí/quyền Firestore cho corpus chung.
- Đánh đổi: backend phải mang artifact SQLite và cập nhật khi đổi corpus; thay nguồn/commit là migration có manifest/checksum mới.
- `HL-03-02` chỉ hoàn tất khi build nguồn pin, tạo artifact idempotent, báo số accepted/rejected và kiểm duyệt mẫu nghĩa Việt. `HL-03-03/04` hiện thực API/schema này. Flutter không truy cập SQLite trực tiếp.
