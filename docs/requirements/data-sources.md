# HanLearn AI — nguồn dữ liệu và quyền sử dụng

> Issue `HL-00-07` · Kiểm tra nguồn ngày 2026-11-20. Đây là quyết định nguồn cho thiết kế; Phase 03 phải khóa release/hash, kiểm tra dữ liệu thực tế và ghi attribution trước khi import. Không có dữ liệu bên thứ ba nào đã được tải/seed vào repo ở issue này.

## 1. Quyết định nguồn từ điển

**Nguồn ưu tiên cho seed MVP:** [OpenCidian data của Perxel](https://github.com/OpenCidian/opencidian-data). Repo công bố dữ liệu Trung–Việt có Hanzi giản thể, Pinyin, nghĩa Việt, nguồn theo từng field, và build từ các nguồn được pin; tác giả ghi dữ liệu theo **CC BY-SA 4.0**, code theo MIT. [README nguồn và giấy phép](https://github.com/OpenCidian/opencidian-data#licence), [LICENSE-DATA](https://github.com/OpenCidian/opencidian-data/blob/main/LICENSE-DATA). Đây là lựa chọn dựa trên cấu trúc truy vết nguồn và khả năng lấy nghĩa Việt, không phải khẳng định mọi mục đều chính xác.

Nguồn gốc chính được OpenCidian ghi: [CC-CEDICT](https://cc-cedict.org/editor/editor.php?handler=Download) cho mục từ/Pinyin và [CVDICT của Phong Phan](https://github.com/ph0ngp/CVDICT) cho nghĩa tiếng Việt. Cả hai trang nguồn công bố **CC BY-SA 4.0**. CVDICT nói rõ nhiều nghĩa được dịch với hỗ trợ AI và có thể còn lỗi; vì vậy seed MVP phải **duyệt thủ công** các mục được chọn, không coi dữ liệu mở là đồng nghĩa với đúng tuyệt đối. Không tự trộn nghĩa từ web/app không có quyền tái sử dụng.

### Cách dùng ở Phase 03

1. Pin một release/tag/commit của OpenCidian; lưu URL, commit/release, SHA-256 file tải, ngày truy cập và license vào manifest của seed. Không tải “latest” rồi để dữ liệu thay đổi ngầm giữa các lần test.
2. Chọn mục từ chữ Hán giản thể in phổ biến, có `pinyin` và `vi.senses` hiện hữu; mục tiêu 300–500 mục nếu kiểm duyệt được, báo số thực. Mục thiếu nghĩa/Pinyin hoặc nghĩa đáng ngờ thì bỏ qua/chờ hiệu đính, không dùng LLM tự điền như nguồn chuẩn.
3. Mỗi record import giữ `sourceId` và nguồn gốc field theo khả năng schema; hiển thị nhãn nguồn trong Dictionary Detail, kèm trang attribution đầy đủ ở README/app. Ghi việc chuyển đổi/rút gọn dữ liệu và điều kiện chia sẻ lại dữ liệu dẫn xuất theo CC BY-SA 4.0. Giữ giấy phép dữ liệu trong bản phân phối theo yêu cầu nguồn.
4. Ví dụ câu Trung/Pinyin/dịch **không được giả định có sẵn** trong OpenCidian. Chỉ nhập ví dụ do dự án tự biên soạn và được kiểm tra thủ công, hoặc từ nguồn có quyền rõ ràng; thiếu ví dụ thì `examples: []` và UI hiển thị đúng. Không ghi AI-generated example thành ví dụ từ điển chuẩn.
5. HSK/level chỉ dùng khi trường/version nguồn rõ và được kiểm tra; nếu không, để `null`. TTS là quyết định riêng, không thuộc license từ điển.

### Điều kiện trước khi seed được chấp nhận

| Mục | Bằng chứng cần lưu | Nếu chưa đạt |
|---|---|---|
| License/attribution | LICENSE-DATA, metadata nguồn, text credit và link | Không import/phát hành dữ liệu đó |
| Pin phiên bản | Commit/tag/release và checksum | Không nhận import tái lập |
| Chất lượng tiếng Việt | Mẫu kiểm thủ công, danh sách mục bỏ/sửa và người kiểm | Chỉ seed mục đã qua kiểm |
| Pinyin/giản thể | Kiểm định dạng và ví dụ lỗi phổ biến | Bỏ/hiệu đính record lỗi |
| Ví dụ | Nguồn hoặc hồ sơ tự biên soạn/kiểm tra | Giữ `examples: []` |
| Nguồn mỗi mục | `sourceId`/metadata truy vết | Không đưa mục vào corpus chuẩn |

**Nguồn dự phòng:** nếu OpenCidian không phù hợp với bản phân phối, có thể dùng trực tiếp [CVDICT](https://github.com/ph0ngp/CVDICT) + [CC-CEDICT](https://cc-cedict.org/editor/editor.php?handler=Download) theo license tương ứng, nhưng cần tự ghép/kiểm dữ liệu và ghi ADR đổi nguồn. Không tự động thay nguồn chỉ vì API/import khó.

## 2. Ảnh và ground truth OCR

Ưu tiên **ảnh do dự án tự tạo hoặc tự chụp** từ nội dung chữ Hán do dự án tự soạn, không chứa dữ liệu cá nhân/đề thi/sách có quyền hạn chế. Có thể dựng ảnh in bằng [Noto Sans SC](https://github.com/google/fonts/tree/main/ofl/notosanssc), mà [OFL.txt của Google Fonts](https://github.com/google/fonts/blob/main/ofl/notosanssc/OFL.txt) công bố theo SIL OFL 1.1. Nếu phân phối font cùng công cụ/dataset, giữ copyright và license của font. Ảnh tự chụp từ tờ in tự soạn cần ghi người tạo, ngày, thiết bị và quyền sử dụng. Không lấy ngẫu nhiên ảnh trên web rồi mặc định được tái phân phối.

Ảnh **synthetic** giúp kiểm layout/font/độ rõ nhưng không đại diện đầy đủ cho ảnh camera. Bộ đánh giá cuối cần có ảnh camera thực ở các nhóm sáng/tối, nghiêng, mờ, đa dòng. Nếu lấy ảnh do người khác cung cấp, lưu giấy cho phép và phạm vi sử dụng/tái phân phối riêng; không commit ảnh khi quyền chưa rõ.

Manifest tối thiểu: `image_id`, `path_or_private_ref`, `sha256`, `source_type` (self_generated/self_captured/third_party), `creator`, `license_or_permission`, `capture_date`, `device`, `printed_simplified`, `lighting`, `skew`, `blur`, `line_count`, `split`, `ground_truth_ref`. Không đưa tên thật, vị trí hoặc metadata nhạy cảm không cần thiết vào bản công khai.

## 3. Việc chưa làm ở HL-00-07

- Chưa tải/copy dữ liệu OpenCidian/CVDICT hoặc font vào repo.
- Chưa chọn chính xác 300–500 mục, chưa hiệu đính nghĩa/ví dụ; thuộc Phase 03.
- Chưa thu ảnh, chưa có ground truth hay CER; thuộc Phase 09.
- Chưa xác nhận điều kiện lưu ảnh của OCR service ngoài; phải kiểm trước khi gửi ảnh người dùng ở Phase 09.

Các khoản trên là cổng việc thực, không được báo đã có dataset hoặc chất lượng OCR. Nếu nguồn/giấy phép thay đổi, rà lại nguồn trước import và cập nhật tài liệu này, plan và backlog.
