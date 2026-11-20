# HanLearn AI — API v1 contract

> Issue `HL-00-06` · 2026-11-20 · Hợp đồng thiết kế cho backend **Python/FastAPI/Pydantic**, chưa phải OpenAPI sinh từ server đã chạy. Khi Phase 01/03/09/10 triển khai, schema FastAPI và Flutter client phải được đối chiếu với tài liệu này; thay đổi phải cập nhật cùng issue.

## 1. Quy ước chung

- Base path: `/api/v1` (trừ `GET /health`). JSON UTF-8; `Content-Type: application/json` cho API JSON, `multipart/form-data` cho OCR.
- Mọi route `/api/v1` yêu cầu `Authorization: Bearer <Firebase ID token>`. Backend xác minh token, lấy UID từ token. Không nhận UID tự do trong body/query để quyết định quyền. `GET /health` không yêu cầu auth và không công bố secret/cấu hình chi tiết.
- Response thành công là JSON theo schema từng route, không có wrapper `success`. Error dùng envelope thống nhất ở mục 6. Header `X-Request-Id` hoặc field `request_id` cho trace; backend tạo ID nếu client không gửi.
- Bản core dùng dictionary API thật. OCR/AI route chỉ được bật cho người dùng khi provider thật đã cấu hình ở Phase 09/10; trước đó trả `503 SERVICE_NOT_CONFIGURED`, không trả kết quả giả.
- Flutter có thể đọc/ghi Firestore trực tiếp cho saved words/review/quiz/scan history dưới Security Rules. Backend không tạo API CRUD trùng lặp khi chưa có ADR chứng minh cần thiết.

## 2. Route inventory và trạng thái triển khai

| Method | Route | Phase | Auth | Vai trò |
|---|---|---:|---|---|
| GET | `/health` | 01 | Không | Liveness backend Python |
| GET | `/api/v1/dictionary/search` | 03 | Có | Tra Hanzi/Pinyin |
| GET | `/api/v1/dictionary/{vocabId}` | 03 | Có | Chi tiết mục từ có nguồn |
| POST | `/api/v1/ocr/recognize` | 09 (contract 06) | Có | Ảnh → OCR thật |
| POST | `/api/v1/ai/explain` | 10 (contract 06) | Có | Giải thích/ví dụ AI thật |

`POST /api/v1/learning/quiz` và `/api/v1/learning/review` trong tài liệu nguồn là **phương án**, chưa đưa vào contract MVP core. Phase 04 quyết định client hay server tính Quiz/lịch ôn bằng ADR; nếu chọn server thì thêm route/schema/test trước triển khai. Dữ liệu cá nhân vẫn được bảo vệ theo UID.

## 3. Health

`GET /health` → `200`:

```json
{ "status": "ok" }
```

Health kiểm tiến trình API, không hứa OCR/AI sẵn sàng. Nếu cần readiness riêng ở Phase 08–10, tạo endpoint riêng và không tiết lộ key/model nhạy cảm.

## 4. Dictionary

### `GET /api/v1/dictionary/search`

Query:

| Field | Type | Quy tắc |
|---|---|---|
| `q` | string | Bắt buộc; trim; 1–64 ký tự Unicode; hỗ trợ Hanzi hoặc Pinyin theo corpus nguồn |
| `limit` | int | Mặc định 20, min 1, max 50 |
| `cursor` | string | Optional, opaque; không tự giải mã ở client |

`200`:

```json
{
  "items": [
    {
      "vocabId": "sample-001",
      "hanzi": "学习",
      "pinyin": "xuéxí",
      "meaningVi": "học tập",
      "levels": {"hsk2": 2, "hsk3": 1},
      "sourceId": "opencidian-17873f1"
    }
  ],
  "nextCursor": null,
  "request_id": "req-example"
}
```

Ví dụ là **hình dạng dữ liệu**, không phải bằng chứng từ đã seed hay giấy phép nguồn. Không có kết quả → `items: []`, không phải lỗi. `nextCursor` null khi hết trang. Phase 03 chuẩn hóa Pinyin dấu/số/không dấu, có/không khoảng trắng theo `dictionary-corpus-decision.md`; thứ tự exact Hanzi → prefix Hanzi → exact Pinyin → prefix Pinyin và tie-break ổn định. Backend không dùng LLM để điền mục từ vắng mặt.

### `GET /api/v1/dictionary/{vocabId}`

`vocabId`: string ID ổn định từ corpus, URL encoded, dài 1–128 ký tự; không dùng Hanzi làm ID bắt buộc. `200`:

```json
{
  "vocabId": "sample-001",
  "sourceEntryId": "学习|學習|xue2 xi2",
  "hanzi": "学习",
  "traditional": "學習",
  "pinyin": "xuéxí",
  "pinyinNumeric": "xue2 xi2",
  "meaningVi": "học tập",
  "meaningViSenses": ["học tập"],
  "hanViet": [],
  "examples": [],
  "levels": {"hsk2": 2, "hsk3": 1},
  "sourceId": "opencidian-17873f1",
  "sourceRefs": {"entry": "cc-cedict", "meaningVi": "cvdict", "levels": "hsk"},
  "license": "CC-BY-SA-4.0",
  "attribution": "OpenCidian by Perxel; ...",
  "request_id": "req-example"
}
```

`examples` có thể rỗng; chỉ hiện ví dụ có nguồn/xác minh. Không có ID → `404 NOT_FOUND`. `sourceEntryId`, `sourceRefs`, `license` và `attribution` cho phép truy vết corpus pin; UI có thể rút gọn attribution nhưng phải có nơi xem đầy đủ. Không ghi API key hoặc dữ liệu cá nhân vào response.

## 5. OCR và AI — contract chuẩn bị, service thật ở cuối

### `POST /api/v1/ocr/recognize`

- Multipart field `image` bắt buộc, một file JPEG/PNG. Giới hạn thiết kế ban đầu: **8 MiB/file, 20 megapixel**; backend kiểm cả byte lẫn pixel sau decode, EXIF orientation, từ chối ảnh hỏng/không hỗ trợ. Giá trị có thể giảm theo service thực tế ở Phase 09 bằng ADR + cập nhật contract/client/test.
- MIME và nội dung file phải phù hợp; không tin extension/MIME do client khai. Timeout backend ↔ service cấu hình được, có giới hạn; lúc timeout trả lỗi rõ để client cho quét lại/nhập tay.
- Box nếu provider hỗ trợ: bốn điểm `[x, y]` theo pixel của ảnh gốc **sau khi áp EXIF orientation**; backend map tọa độ nếu service resize. Nếu provider không có box/confidence, `detections: []` hoặc `confidence: null`, không bịa số.

`200`:

```json
{
  "text": "学习中文",
  "detections": [
    {
      "text": "学习中文",
      "confidence": 0.96,
      "box": [[10, 20], [180, 20], [180, 65], [10, 65]]
    }
  ],
  "processing_time_ms": 420,
  "provider_version": "example-version",
  "request_id": "req-example"
}
```

Các số/text trên chỉ minh họa schema, **không phải benchmark**. `confidence` nằm 0–1 hoặc null. `processing_time_ms` là thời gian backend đo cho request OCR, không bao gồm thời gian người dùng chọn/sửa ảnh; định nghĩa đo cuối cùng phải nhất quán báo cáo CER/latency. OCR empty có thể trả `200` với `text: ""`, `detections: []` để UI cho quét lại/nhập tay; lỗi provider dùng `503/504`. Không lưu ảnh lâu dài mặc định. Flutter chỉ ghi `scan_history` sau người dùng sửa/xác nhận theo data model.

### `POST /api/v1/ai/explain`

`application/json` request:

```json
{
  "vocabId": "sample-001",
  "contextZh": "我学习中文。"
}
```

`vocabId` bắt buộc và phải trỏ tới mục từ đã xác minh; `contextZh` optional, trim, tối đa **500 ký tự**. Backend lấy Hanzi/Pinyin/nghĩa chuẩn từ corpus theo ID, không tin các field chuẩn nếu client tự gửi. Request được tính quota theo UID đã xác minh. Quota ban đầu thiết kế: **tối đa 2 request/phút và 20 request/ngày/UID**; cấu hình ở backend, điều chỉnh khi Phase 10 chốt chi phí/provider bằng ADR + cập nhật test. Giới hạn độ dài output được validate trong Pydantic (giải thích ≤ 1000 ký tự; tối đa 3 ví dụ).

`200`:

```json
{
  "vocabId": "sample-001",
  "explanationVi": "Giải thích ngắn gọn dựa trên nghĩa đã xác minh.",
  "examples": [
    { "zh": "我学习中文。", "pinyin": "Wǒ xuéxí Zhōngwén.", "vi": "Tôi học tiếng Trung." }
  ],
  "radicalNoteVi": null,
  "generatedByAi": true,
  "request_id": "req-example"
}
```

Đây là **hình dạng response, không phải output model đã kiểm chứng**. `radicalNoteVi` null khi không có căn cứ phân tích bộ thủ. Backend validate schema, độ dài và so với dữ liệu chuẩn khi khả thi; nếu output không đạt, trả lỗi/fallback. Client giữ từ điển trên màn và gắn nhãn nội dung AI; không ghi đè nghĩa/Pinyin chuẩn. Key chỉ nằm server-side.

## 6. Error envelope

Mọi lỗi API trả JSON:

```json
{
  "error": {
    "code": "INVALID_IMAGE",
    "message": "Ảnh không hợp lệ hoặc không đọc được."
  },
  "request_id": "req-example"
}
```

`message` dành cho UI, không chứa stack trace, key, ảnh, token hay nội dung nhạy cảm. Client dùng `code` để chọn hành động, không phân tích chuỗi message. Mã dự kiến:

| HTTP | Code | Khi nào | Hành động UI |
|---:|---|---|---|
| 400 | `INVALID_QUERY` | Query trống/sai định dạng | Hướng dẫn nhập lại |
| 401 | `UNAUTHENTICATED` | Thiếu/expired/invalid ID token | Đăng nhập lại/refresh phiên |
| 403 | `FORBIDDEN` | Không có quyền tài nguyên | Không hiển thị dữ liệu |
| 404 | `NOT_FOUND` | Vocab ID không tồn tại | Quay lại kết quả tìm kiếm |
| 413 | `IMAGE_TOO_LARGE` | Vượt byte/pixel | Chọn ảnh nhỏ hơn |
| 415 | `UNSUPPORTED_IMAGE` | Không phải JPEG/PNG hợp lệ | Chọn định dạng hỗ trợ |
| 422 | `INVALID_IMAGE` / `INVALID_REQUEST` | Decode lỗi, schema sai | Sửa input/chọn ảnh khác |
| 429 | `RATE_LIMITED` / `QUOTA_EXCEEDED` | Giới hạn AI/OCR | Thử lại sau; từ điển vẫn dùng |
| 500 | `INTERNAL_ERROR` | Lỗi backend không dự đoán | Thử lại, báo lỗi có request ID |
| 503 | `SERVICE_NOT_CONFIGURED` / `SERVICE_UNAVAILABLE` | OCR/AI chưa cấu hình hoặc provider lỗi | Nhập tay/dùng từ điển |
| 504 | `SERVICE_TIMEOUT` | Provider quá thời gian | Quét/thử lại hoặc nhập tay |

Backend không trả 500 cho lỗi xác thực, file sai hoặc quota đã biết. Dùng `Retry-After` với 429/503 khi tính được. Không log payload ảnh hoặc API key. Tất cả route có API tests cho success, validation, auth và lỗi phù hợp khi triển khai.

## 7. Firestore và frontend alignment

| Dữ liệu | Nguồn API/Firestore | Ghi chú |
|---|---|---|
| Từ điển chung | Python dictionary API đọc SQLite corpus đã pin/duyệt | Client không đọc SQLite hoặc ghi vocabulary |
| Hồ sơ/từ đã lưu/lịch ôn/Quiz | Firestore SDK trong Flutter dưới Rules | Không tạo CRUD FastAPI trùng lặp nếu không có ADR |
| Lịch sử quét | Firestore `users/{uid}/scan_history/{scanId}` sau xác nhận | Backend OCR không tự ghi history khi user chưa sửa |
| Giải thích AI | Python AI API, không phải corpus | Gắn nhãn và fallback |

Flutter Web cần CORS allowlist theo origin môi trường; Android không dùng CORS nhưng vẫn cần URL/backend hợp lệ và TLS nếu public. Base URL nằm trong cấu hình build/runtime, không hardcode localhost cho bản Android thiết bị. Mọi thay đổi API phải cập nhật file này, Pydantic schema, Flutter client và test cùng issue.

## 8. Các tham số cần xác nhận khi service được chọn

| Tham số | Hiện tại | Cổng quyết định |
|---|---|---|
| OCR provider, auth, nội dung response thực | Chưa chốt | Phase 09 |
| OCR có box/confidence hay không | Optional trong contract | Phase 09, không bịa dữ liệu |
| OCR max size/timeout cuối | Default 8 MiB/20 MP, timeout config | Phase 09 theo service và đo thực tế |
| AI provider/model, cost, quota cuối | Default 2/phút, 20/ngày/UID | Phase 10 và ADR chi phí |
| Pinyin normalization/search strategy | Đã chốt ở HL-03-01; hiện thực/test ở HL-03-02/03 | Theo `dictionary-corpus-decision.md` |
| Quiz/review xử lý client hay server | Chưa có endpoint trong contract | Phase 04 ADR |

Không dùng các lựa chọn còn mở làm bằng chứng implementation đã hoàn thành. PRD, schema Firestore và contract này là baseline để viết acceptance criteria `HL-00-08`.
