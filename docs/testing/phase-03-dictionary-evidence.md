# Phase 03 — bằng chứng build corpus từ điển

Ngày: 2026-11-21. Branch: `phase/03`. Issue: `HL-03-02`.

## Nguồn và cách build

- OpenCidian pin commit `17873f10941c11ae4e410c91efdcb51c04b23c01`; upstream build báo 125.397 entry, 118.409 entry có nghĩa Việt và 12.634 entry có HSK.
- `npm ci`, `npm run fetch-sources`, `npm run build` chạy thành công trong checkout tạm; checksum mọi upstream được OpenCidian kiểm tra.
- `backend/scripts/build_dictionary.py` chỉ nhận meta đúng commit/license đã pin. Mục được chọn phải có Hanzi giản thể thuần CJK, Pinyin, nghĩa Việt không rỗng và HSK đã xác minh.
- Loại Pinyin viết hoa có khả năng là tên riêng; gộp trùng `(hanzi, pinyinNumeric)`; ưu tiên HSK 3.0 thấp, HSK 2.0 thấp và định nghĩa chính. Không gọi AI và không sinh trường chuẩn còn thiếu.

## Kết quả thực tế

| Kiểm tra | Kết quả |
|---|---|
| Corpus SQLite | 500 mục; tất cả HSK 3.0 level 1 |
| HSK 2.0 trong tập | level 1: 165; level 2: 99; level 3: 61; level 4: 19; level 5: 8; không map HSK 2.0: 148 |
| Artifact | `backend/data/dictionary/hanlearn_dictionary.sqlite3`, 380.928 bytes |
| SHA-256 | `cb1e793905acabdb2d4f6d488946d07d1976da92c78580a81ca821477eb68edb` |
| Build lặp sang path khác | SHA-256 giống hệt; byte-idempotent |
| Python lint/test | Ruff pass; 9/9 pytest pass |
| Ví dụ | `[]` cho mọi mục vì chưa có nguồn ví dụ được duyệt |
| Canonical field do AI tạo | Không |

`build-report.json` giữ toàn bộ số reject theo lý do. Spot-check trực tiếp 80 record đầu xác nhận schema/Unicode/Pinyin/nghĩa Việt đọc được, đồng thời cho thấy corpus giữ các cách đọc đa âm như `上`, `和`, `哪`. Đây là dữ liệu có nguồn, không phải kết luận rằng mọi nghĩa đều hoàn hảo.

## Review khóa corpus — HL-03-08

`backend/scripts/audit_dictionary.py` đã kiểm tra đủ 500 record về ID, headword, Pinyin, nghĩa/senses Việt, HSK, chính sách ví dụ rỗng và provenance. Mỗi record có quyết định/flags trong `review-manifest.json`; 100 record lấy đều theo thứ tự Hanzi/Pinyin (mỗi record thứ năm) đã được đọc trực quan. Kết quả: 500 accepted, 0 corrected, 0 rejected; 46 record nhiều nghĩa, 17 cách đọc/biến thể phụ thuộc ngữ cảnh và 3 nghĩa có register nhạy cảm được gắn cờ để không bị hiểu là lỗi cấu trúc.

Build release nhận review manifest như allowlist bắt buộc, chạy lại từ OpenCidian pin và vẫn cho đúng SHA-256 `cb1e7939…68edb`, chứng minh review không âm thầm đổi trường chuẩn. Manifest review SHA-256 là `62b1db94…c93ff`; Ruff pass và 14/14 pytest pass.

## Giới hạn chất lượng công bố

CVDICT công bố phần lớn nghĩa từng được dịch với hỗ trợ AI và có thể còn lỗi. Review này là self-review có dấu vết của dự án solo — đúng hướng dẫn tài liệu nền rằng solo developer có thể tự review bằng checklist — chứ không phải chứng nhận của người thứ hai/chuyên gia ngôn ngữ. Không dùng LLM để sinh/sửa nghĩa chuẩn, không bịa ví dụ, luôn giữ attribution và không tuyên bố mọi nghĩa hoàn hảo. Nếu phát hành công khai quy mô lớn, review độc lập vẫn là cải tiến được khuyến nghị nhưng không bị trình bày sai là bằng chứng đã có.
