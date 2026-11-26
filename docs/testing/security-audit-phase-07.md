# Phase 07 — audit Rules và bảo mật core

Ngày kiểm tra: 2026-11-22 · Issue `HL-07-02`

## Kết luận

Không phát hiện P0 security trong phạm vi core. Firestore Rules từ chối truy cập chéo UID và dữ liệu sai schema; toàn bộ API v1 yêu cầu Firebase token; CORS không chấp nhận origin ngoài danh sách; không có private key, service account hoặc OCR/AI key được Git track. OCR/AI vẫn chưa tích hợp và provider mặc định trả 503.

## Firestore Rules

Lệnh gate:

```powershell
firebase emulators:exec --only firestore --project demo-hanlearn "npm --prefix firebase run test:rules"
```

Kết quả: 7/7 nhóm đạt trên Firestore Emulator. Fixture dùng guest, owner `alice` và tài khoản khác `bob`; các lần `PERMISSION_DENIED` trong log là assertion từ chối dự kiến.

| Phạm vi | Kết quả |
|---|---|
| `users/{uid}` | Owner đọc/tạo và chỉ sửa display name hợp lệ; guest/UID khác bị từ chối |
| Profile schema | Field lạ, type/email/timestamp sai và delete bị từ chối |
| `vocabulary` | Tài khoản đăng nhập chỉ đọc; mọi client write bị từ chối |
| `saved_words` | Owner-only, ID/schema bất biến, create idempotent và delete có kiểm soát |
| `review_schedule` | Owner-only, type/range và mỗi lần chỉ tăng đúng một review |
| `quiz_results` | Owner-only, append-only và score/count nhất quán |
| Collection khác/scan history | Deny mặc định; chưa mở trước OCR thật |

Một Firestore Emulator cũ còn giữ port 8080 từ lượt trước đã được xác minh đúng command/rules của workspace, dừng theo PID cụ thể rồi chạy lại `emulators:exec` từ đầu. Gate báo cáo ở trên là lần khởi động sạch.

## Secrets và logging

- `.env` khớp rule ignore trong `.gitignore` và không xuất hiện trong `git ls-files`.
- Không có file `*.pem`, `*.p12`, `*.pfx`, service-account hoặc private-key marker được track.
- Scan file ngoài `.env`, dependency/build cache không tìm thấy key dạng OpenAI, private key, service-account email, `AI_API_KEY`/`OCR_SERVICE_API_KEY` có giá trị.
- `firebase_options.dart` chứa Firebase Web/Android client config công khai theo thiết kế SDK; không phải service-account credential. File này không được dùng để cấp quyền—Auth và Rules mới quyết định quyền dữ liệu.
- Backend/Flutter source không có `print`, `debugPrint` hoặc logger ghi token, provider key, ảnh hay prompt. Authorization chỉ được tạo trong HTTP header của Dictionary client và xác minh ở dependency backend.
- `.env.example` chỉ có placeholder/rỗng; key OCR/AI không được đưa qua `--dart-define` hoặc bundle Flutter.

## API auth và CORS

- `GET /health` là route public duy nhất và chỉ trả `{"status":"ok"}`.
- Dictionary, OCR và AI đều có test thiếu/sai Firebase token; backend xác minh signature, expiry, issuer, audience và UID.
- CORS preflight chỉ cho origin cấu hình; wildcard, origin có credential/path, HTTP staging và production thiếu HTTPS bị Settings từ chối.
- Backend Ruff đạt; 27/27 pytest đạt. Cảnh báo Starlette TestClient deprecation là nợ dependency, không phải lỗ hổng hoặc lỗi runtime hiện tại.

## Giới hạn còn lại

- Đây là audit local/source/Emulator, không thay thế pentest độc lập hay scan hạ tầng deploy.
- Limiter AI in-memory chỉ phù hợp một process và phải thay bằng store dùng chung trước multi-instance.
- OCR/AI key/provider thật chưa có nên log redaction đối với SDK provider phải được kiểm lại ở Phase 09/10.
- Phase 08 phải smoke bản build sạch và cấu hình HTTPS/CORS của môi trường bàn giao.
