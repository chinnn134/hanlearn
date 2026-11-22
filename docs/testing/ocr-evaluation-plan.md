# HanLearn AI — kế hoạch đánh giá OCR

> Issue `HL-00-07` · 2026-11-20 · Chưa chạy OCR/chưa có số liệu. Kế hoạch này được thực hiện ở Phase 09 sau khi có OCR service thật.

## 1. Câu hỏi nghiên cứu

1. OCR nhận chữ Hán giản thể **in** chính xác đến đâu trên ảnh in rõ, ảnh camera và các điều kiện khó?
2. Tiền xử lý ảnh (nếu điều khiển được pipeline) cải thiện hay làm tệ CER và latency ở nhóm nào?
3. Service/model/cấu hình nào đạt cân bằng phù hợp với máy và demo Web/Android?

Mục tiêu tham khảo từ kế hoạch nguồn: **CER ≤ 10% trên tập chữ Hán giản thể in rõ đã định nghĩa trước**. Kết quả thật được báo dù không đạt. Không suy rộng từ tập synthetic sang tất cả ảnh camera.

## 2. Đơn vị, tập dữ liệu và quyền dùng

- **Đơn vị đánh giá:** text đầy đủ của ảnh theo thứ tự đọc dòng; lưu thêm detection/box nếu service có. Ground truth tự gõ và được người kiểm thứ hai hoặc một lượt kiểm độc lập đối chiếu ảnh. Không dùng OCR prediction làm ground truth.
- **Pilot:** 10 ảnh gồm rõ, tối, mờ, nghiêng, đa dòng để kiểm pipeline/format.
- **Tập chính:** hướng tới 200–300 ảnh có ground truth nếu nguồn lực cho phép, công bố số thật; chia dev/test cố định theo `image_id` trước khi tinh chỉnh. Dự kiến 80% dev, 20% test, cân bằng nhóm ảnh. Không đưa ảnh gần trùng hoặc bản crop của cùng trang vào cả hai split.
- **Quyền dùng:** ảnh tự tạo/tự chụp ưu tiên, font/text có nguồn; ảnh bên thứ ba cần quyền rõ. Manifest theo `docs/requirements/data-sources.md`.
- **Test freeze:** sau khi khóa test, không tune preprocessing/model trên test rồi báo cùng test là điểm cuối. Nếu phải sửa lỗi đánh giá, ghi phiên bản và chạy lại toàn bộ, không chọn số tốt nhất không minh bạch.

## 3. Chuẩn hóa và metric

Lưu `ground_truth_raw`, `prediction_raw` nguyên văn. **Raw CER** tính trên chuỗi Unicode sau decode UTF-8, không sửa nội dung; điều kiện ảnh/font đều là chữ giản thể in. **Normalized CER** được tính thêm theo quy tắc định trước: Unicode NFC, `\r\n`/`\r` → `\n`, trim đầu/cuối và gộp các khoảng trắng liên tiếp thành một dấu cách; dấu câu vẫn được giữ. Không tự chuyển phồn thể → giản thể hoặc xóa chữ sai. Nếu sau pilot cần sửa quy tắc chuẩn hóa, ghi phiên bản rule và áp cho toàn bộ dev/test trước khi chốt báo cáo.

CER = `(S + D + I) / N`, trong đó S là thay thế, D xóa, I chèn, N là số ký tự ground truth. Đơn vị ký tự là Unicode code point sau normalize tương ứng; ảnh có ground truth rỗng được báo riêng và không dùng làm mẫu CER vì N=0. Báo **micro-average** theo tổng S+D+I / tổng N và **theo nhóm ảnh**, kèm số ảnh/ký tự. Không gộp ảnh thất bại vào CER như text tùy tiện mà bỏ qua failure; ảnh thất bại được báo **failure rate** riêng và định nghĩa rõ.

**Latency:** đo thời gian backend từ lúc nhận file hợp lệ đến lúc có response OCR hoặc lỗi provider, không gồm thời gian chụp/upload mạng client hay người dùng sửa. Báo median, p95, số mẫu, CPU/RAM nếu đo được, cấu hình máy, model/service version và kích thước ảnh. Có thể bổ sung end-to-end client latency riêng nhưng không trộn hai định nghĩa.

## 4. Nhóm thử và thực nghiệm

| TN | So sánh | Điều kiện áp dụng |
|---|---|---|
| TN1 | Ảnh gốc → OCR baseline | Luôn có với service thật |
| TN2 | Grayscale/contrast vs ảnh gốc | Chỉ khi backend có quyền tiền xử lý ảnh trước service và input được chấp nhận |
| TN3 | Denoise/deskew vs ảnh gốc | Cùng điều kiện; ghi nhóm ảnh tốt lên/xấu đi |
| TN4 | Hai model/cấu hình/service settings | Chỉ khi có hai lựa chọn thực tế khả dụng; không giả vờ có model thứ hai |

Nếu OCR service ngoài là hộp đen, ghi chính xác các TN làm được; không tuyên bố so sánh nội bộ model/pipeline không truy cập được. Mọi biến thể dùng cùng test split và cùng normalization rule. Chọn cấu hình trên dev, đo cuối trên test. So sánh có bảng theo nhóm lighting/skew/blur/multi-line và ví dụ lỗi đã ẩn thông tin nhạy cảm.

## 5. Đầu ra tái lập

```text
ai/datasets/manifest.csv
ai/datasets/ground_truth.csv
ai/experiments/run_baseline.py
ai/evaluation/evaluate_cer.py
ai/evaluation/results.csv
docs/testing/ocr-experiment-report.md
```

Đường dẫn là kế hoạch, **chưa tồn tại**. Raw predictions cần lưu theo `image_id`, split, service/model version, config, request time, text, detection nếu có, latency và error code. Báo cáo có lệnh chạy, phiên bản dependency, máy chạy, số ảnh mỗi split/nhóm, license/permission và giới hạn. Dataset nhạy cảm hoặc không được tái phân phối thì giữ ngoài Git, chỉ commit manifest đã ẩn thông tin và hướng dẫn tái tạo hợp pháp.
