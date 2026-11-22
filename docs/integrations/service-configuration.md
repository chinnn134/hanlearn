# Cấu hình adapter OCR và AI

Ngày cập nhật: 2026-11-22 · Issue `HL-06-06`

## Trạng thái hiện tại

Phase 06 chỉ khóa API contract và provider port. `POST /api/v1/ocr/recognize` và `POST /api/v1/ai/explain` đều yêu cầu Firebase ID token, nhưng adapter mặc định trả `503 SERVICE_NOT_CONFIGURED`. Không có ảnh nào được gửi tới OCR và không có API AI nào được gọi. Mock trong test không phải service thật.

`GET /health` chỉ là liveness của FastAPI (`{"status":"ok"}`), không phải readiness của OCR/AI. Không dùng endpoint này để tuyên bố provider đã sẵn sàng.

## Biến môi trường backend

Sao chép `.env.example` thành `.env` cục bộ hoặc dùng secret store của môi trường deploy. Không commit `.env` hay giá trị key thật.

| Biến | Mặc định/mục đích | Trạng thái Phase 06 |
|---|---|---|
| `OCR_SERVICE_URL` | Endpoint service OCR ngoài | Được đọc vào config; chưa có HTTP adapter |
| `OCR_SERVICE_API_KEY` | Credential OCR server-side | Chưa được sử dụng; không đưa vào Flutter |
| `OCR_TIMEOUT_SECONDS` | 1–120 giây, mặc định 30 | Contract config; Phase 09 áp vào adapter thật |
| `MAX_IMAGE_BYTES` | 8 MiB | Đang được API OCR thực thi |
| `MAX_IMAGE_PIXELS` | 20 triệu pixel | Đang được API OCR thực thi |
| `AI_API_BASE_URL` | Base URL provider AI | Được đọc vào config; chưa có provider thật |
| `AI_API_KEY` | API key server-side | Chưa được sử dụng; không đưa vào Flutter |
| `AI_MODEL` | Model sẽ khóa ở Phase 10 | Chưa chốt |
| `AI_TIMEOUT_SECONDS` | 1–120 giây, mặc định 30 | Contract config; Phase 10 áp vào provider thật |
| `AI_REQUESTS_PER_MINUTE` | Mặc định 2/UID | Đang áp bằng limiter in-memory một process |
| `AI_REQUESTS_PER_DAY` | Mặc định 20/UID | Đang áp bằng limiter in-memory một process |

Chỉ điền URL/key **không tự bật** service: `create_app()` vẫn gắn `UnconfiguredOcrProvider` và `UnconfiguredAiProvider`. Phase 09/10 phải hiện thực adapter, test service thật và thay provider rõ ràng. Thiết kế này ngăn cấu hình dang dở bị hiểu nhầm là tính năng hoạt động.

## Ràng buộc adapter thật

- OCR: gửi JPEG/PNG đã qua validation; không tin MIME/extension; giới hạn byte/pixel, timeout và map lỗi provider sang `503/504`. Không log token, key hoặc payload ảnh; không lưu ảnh lâu dài mặc định. WebP chỉ được preview/nhập tay ở Phase 06, chưa thuộc OCR API contract.
- AI: nhận `vocabId` rồi lấy Hanzi/Pinyin/nghĩa từ corpus backend; không tin dữ liệu chuẩn do client gửi. Validate structured output, tối đa ba ví dụ, gắn `generatedByAi=true`, không ghi đè từ điển.
- Multi-instance: thay limiter in-memory bằng store dùng chung có thao tác atomic trước production nhiều instance; quota phải theo UID đã xác minh.
- Secret: dùng biến môi trường/secret manager, xoay key khi lộ; redact Authorization và provider headers khỏi log. Flutter chỉ nhận `API_BASE_URL` công khai.

## Timeout và lỗi client

| HTTP/code | Ý nghĩa | Hành động UI |
|---|---|---|
| `413 IMAGE_TOO_LARGE` | Vượt byte/pixel | Chọn ảnh nhỏ hơn hoặc nhập tay |
| `415 UNSUPPORTED_IMAGE` | Không phải JPEG/PNG hợp lệ | Chọn định dạng hỗ trợ |
| `422 INVALID_IMAGE` | File rỗng/hỏng | Chọn ảnh khác hoặc nhập tay |
| `429 RATE_LIMITED` / `QUOTA_EXCEEDED` | Vượt quota AI | Giữ từ điển, thử lại sau |
| `503 SERVICE_NOT_CONFIGURED` | Chưa nối provider | Hiện trạng thái chưa cấu hình; không retry nền |
| `503 SERVICE_UNAVAILABLE` | Provider lỗi tạm thời | Giữ luồng nhập tay/từ điển |
| `504 SERVICE_TIMEOUT` | Quá timeout | Cho người dùng thử lại có chủ đích |

Không retry vô hạn. OCR/AI lỗi không được làm mất nội dung người dùng đã nhập/sửa và không được biến fallback từ điển thành nội dung “AI”.

## Kiểm tra trước khi bật provider

1. Chạy contract tests bằng mock và xác nhận adapter mặc định trả 503.
2. Dùng credential test riêng, kiểm auth/timeout/invalid output/quota và log redaction.
3. Chạy service thật trên Flutter Web và Android; lưu provider/model version cùng evidence.
4. Chỉ thay nhãn “chưa được cấu hình” sau khi Phase 09/10 đạt DoD bằng service thật. Cập nhật contract, `.env.example`, test và tài liệu trong cùng issue.
