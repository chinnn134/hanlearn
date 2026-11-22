# HanLearn AI — danh sách GitHub Issues cho Kanban

> Phiên bản 3.3 · Nguồn: `plan.md` v2.2 · Phase 00–06 đã đạt DoD; không push.
> Thứ tự: **core Phase 00–08 → OCR thật Phase 09 → AI API thật Phase 10 → nghiệm thu Phase 11**.
> Kiến trúc cố định: **Flutter Web + Flutter Android từ một codebase, backend Python/FastAPI**. Không `git push` nếu người dùng chưa yêu cầu.

## Cách dùng trong GitHub Projects

- Tạo các milestone `Phase-00` đến `Phase-11`; tạo label `phase-00` đến `phase-11`, `flutter`, `backend`, `firebase`, `dictionary`, `learning`, `ocr`, `ai`, `testing`, `docs`, `security`, `release`, `priority-p0`, `priority-p1`, `priority-p2`.
- Dùng cột `Backlog → Todo → In Progress → In Review → Done`. Chỉ giữ 1–2 issue ở `In Progress`; chỉ mở phase sau khi DoD phase trước đạt theo `plan.md`.
- Mỗi hàng dưới đây là **một GitHub Issue**. Dùng cột **Tiêu đề** làm title; body gồm **Mục tiêu/Phạm vi** (theo title và phase), **Tiêu chí xong** (cột tương ứng), **Phụ thuộc** (mã issue), **Kiểm thử/bằng chứng**. Gán milestone `Phase-xx` và các label ghi ở đầu mỗi phase. Mã `HL-xx-yy` là mã backlog ổn định; sau khi tạo issue có thể ghi số `#...` vào bảng mà không đổi mã.
- Các hàng hiện để `Backlog`. Chuyển sang `Todo` khi dependency đã xong; `In Review` khi code/tài liệu/test đã có và commit cục bộ đã tạo; `Done` khi tiêu chí xong được kiểm chứng trên nền tảng áp dụng. Mock/contract không được tính là OCR hoặc AI thật.
- Ước lượng là **ngày công tham khảo cho solo developer**, có thể sửa theo thực tế. Nếu một hàng vượt 2 ngày, tách issue con trước khi bắt đầu, giữ liên kết với mã gốc.
- Trợ lý tự tạo branch cục bộ `phase/xx` khi mở phase và tự tạo commit sau mỗi issue hoàn thành; người dùng không cần thao tác Git hộ. Mỗi hàng `HL-xx-yy` tương ứng **đúng một commit mới** trên branch cùng phase; subject chứa `[HL-xx-yy]`. Gộp code, test và tài liệu của issue vào commit đó. Chỉ sau khi cả phase đạt DoD mới fast-forward `main` cục bộ; không push.

**Tiến độ cục bộ:** Phase 00–06 đã tích hợp `main` cục bộ. Trên `phase/07`, `HL-07-01` DONE (`ee332ac`), `HL-07-02` DONE (`ae55c76`), `HL-07-03` đã PASS E2E live và đang chờ commit; `HL-07-04`–`HL-07-05` chờ dependency. Chưa tạo GitHub Issues online, chưa push.

Quy trình Git mẫu: từ `main` đã có phase trước, tạo `git switch -c phase/00`; hoàn thành HL-00-01 rồi commit `docs(requirements): write PRD [HL-00-01]`. Sau khi tất cả issue Phase 00 và DoD đạt, chuyển về `main`, chạy `git merge --ff-only phase/00`, rồi mới tạo `phase/01`. Lặp lại đến Phase 11. Nếu fast-forward không thực hiện được, kiểm tra và xử lý lịch sử branch trước; không ép merge hoặc push.

### Mẫu body khi tạo một issue

```md
## Mục tiêu
[Giá trị/đầu ra của issue]

## Phạm vi
[File/chức năng liên quan; Web, Android, backend Python]

## Phụ thuộc
[Mã HL-xx-yy hoặc issue #...]

## Tiêu chí chấp nhận
- [ ] [Tiêu chí xong trong bảng]
- [ ] Kiểm tra thực tế và ghi bằng chứng/lệnh test
- [ ] Trên branch `phase/xx`, cập nhật plan.md/docs liên quan, git add đúng file và tạo một commit duy nhất có mã `[HL-xx-yy]`; không push

## Ghi chú
[Quyết định, blocker, NOT VERIFIED nếu có]
```

## Phase 00 — Yêu cầu và kiến trúc

Milestone `Phase-00`; label chung `phase-00`, `docs`. **DoD:** PRD, sơ đồ, API contract và acceptance criteria phân biệt bản core/MVP cuối.

| ID | Tiêu đề issue | Phụ thuộc | Ước lượng | Tiêu chí xong / bằng chứng |
|---|---|---|---:|---|
| HL-00-01 | Viết PRD và ranh giới bản core/MVP cuối | — | 1.5 | `product-requirements.md` có persona, use case, MVP, ngoài phạm vi, tiêu chí chấp nhận; OCR/AI ở cuối. |
| HL-00-02 | Vẽ user flow nhập tay và luồng OCR/AI tương lai | HL-00-01 | 1 | Flow Auth → tra/lưu → học → tiến độ và ảnh → OCR → sửa → tra; Web/Android rõ. |
| HL-00-03 | Wireframe Web và Android cho các màn chính | HL-00-02 | 2 | Login, Home, Text Input, Dictionary, Saved Words, Flashcard, Quiz, Progress, Profile, Scanner/Result/Edit có wireframe. |
| HL-00-04 | Thiết kế kiến trúc Flutter, Firebase và backend Python | HL-00-01 | 1 | Sơ đồ một codebase Flutter hai target, Firebase, Python/FastAPI, OCR/AI adapters và ID token. |
| HL-00-05 | Thiết kế Firestore schema và quy tắc sở hữu dữ liệu | HL-00-04 | 1 | Collections, UID, field/type, timestamps, từ điển chung, scan history dự kiến được ghi rõ. |
| HL-00-06 | Viết API/error contract và giới hạn tích hợp | HL-00-04 | 1.5 | `openapi-contract.md` có search/detail, OCR, AI, lỗi chuẩn, auth, giới hạn ảnh/quota, text gốc/text sửa. |
| HL-00-07 | Chốt nguồn dữ liệu và kế hoạch đánh giá OCR | HL-00-01 | 1 | Ghi quyền dùng từ điển/ảnh, ground truth, dev/test, CER, yêu cầu service; ADR cho quyết định còn mở. |
| HL-00-08 | Viết acceptance criteria và rà DoD Phase 00 | HL-00-03, HL-00-05, HL-00-06, HL-00-07 | 1 | `acceptance-criteria.md` kiểm được core/MVP cuối; đối chiếu toàn bộ Phase 00 trong `plan.md`. |

## Phase 01 — Khởi tạo dự án

Milestone `Phase-01`; label chung `phase-01`. **DoD:** Flutter Web, Flutter Android và backend Python chạy; lint/test/setup tái lập.

| ID | Tiêu đề issue | Phụ thuộc | Ước lượng | Tiêu chí xong / bằng chứng |
|---|---|---|---:|---|
| HL-01-01 | Chuẩn bị repo, cấu trúc thư mục và Git hygiene | HL-00-08 | 1 | Repo có `apps/flutter_app`, `backend`, `docs`, `.gitignore`, `.env.example`; không chứa secret; commit cục bộ. |
| HL-01-02 | Khởi tạo Flutter một codebase cho Web và Android | HL-01-01 | 1.5 | App chạy trên Chrome và Android emulator/thiết bị, cùng source; ghi lệnh và kết quả. |
| HL-01-03 | Dựng Riverpod, router, theme và screen core skeleton | HL-01-02 | 2 | Điều hướng và trạng thái loading/empty/error cơ bản hoạt động trên cả hai target; mock được gắn rõ. |
| HL-01-04 | Khởi tạo backend Python/FastAPI và health check | HL-01-01 | 1.5 | `/health` trả 200; `/api/v1`, Pydantic/config/CORS allowlist; backend chạy riêng được. |
| HL-01-05 | Thiết lập lint, format, test nền và CI | HL-01-02, HL-01-04 | 1.5 | Flutter/Python lint và test mẫu pass trong máy và CI; dependency có phiên bản rõ. |
| HL-01-06 | Viết README setup/run/test cho ba thành phần | HL-01-05 | 1 | Người khác làm theo để chạy Web, Android, backend Python và test; ghi biến môi trường cần thiết. |

## Phase 02 — Firebase Auth, Firestore và Rules

Milestone `Phase-02`; label chung `phase-02`, `firebase`. **DoD:** login/logout, dữ liệu riêng theo UID, đồng bộ Web/Android, A không truy cập B. Bằng chứng Emulator cho các issue không tự đóng cổng production của phase; provider, Rules và luồng hai target trên project thật phải được kiểm tra trước khi chuyển phase.

| ID | Tiêu đề issue | Phụ thuộc | Ước lượng | Tiêu chí xong / bằng chứng |
|---|---|---|---:|---|
| HL-02-00 | Chuẩn bị Firebase Emulator và bootstrap Flutter Web/Android | HL-01-06 | 1 | Auth/Firestore Emulator chạy với demo project; Flutter Web/Android build, Android mở app không lỗi khởi tạo; Rules local mặc định từ chối. Không tính là kết nối project thật. |
| HL-02-01 | Cấu hình Firebase project thật cho Flutter Web và Android | HL-02-00 | 1.5 | Cả hai target kết nối đúng project `hanlearn-7553f`/môi trường; có App ID/API key/metadata từng target; không lộ service account. Emulator local không thay bằng chứng project thật. |
| HL-02-02 | Làm đăng nhập, đăng xuất và auth persistence | HL-02-01 | 2 | Ít nhất một login method, logout, loading/error hoạt động trên Web và Android. |
| HL-02-03 | Tạo user document và repository dữ liệu cá nhân | HL-02-02 | 1.5 | `users/{uid}` tạo idempotent, dùng Firestore Timestamp; read/write đúng UID. |
| HL-02-04 | Viết Firestore Rules cho users và từ điển chung | HL-02-03 | 1.5 | Rules giới hạn UID/field/type; vocabulary client chỉ đọc; mặc định từ chối truy cập không hợp lệ. |
| HL-02-05 | Test Rules hai tài khoản và lỗi mạng | HL-02-04 | 1.5 | Emulator tests chứng minh A không đọc/ghi B; retry/error states được kiểm tra. |
| HL-02-06 | Kiểm chứng đồng bộ Auth/Firestore hai nền tảng | HL-02-05 | 1 | Cùng UID đọc dữ liệu trên Flutter Web và Android; ghi bằng chứng và DoD. |
| HL-02-07 | Deploy và xác minh Firestore Rules trên project thật | HL-02-06 | 0.5 | Rules trong repo qua Emulator tests, deploy lên `hanlearn-7553f`, đọc lại release trùng nội dung repo; guest bị từ chối; ghi bằng chứng và không push. |
| HL-02-08 | Nghiệm thu Auth và đồng bộ Web/Android trên project thật | HL-02-07 | 1 | Email/Password được bật; Web/Android đăng nhập, cùng UID đồng bộ hồ sơ, UID khác bị từ chối trên `hanlearn-7553f`; ghi bằng chứng production và giữ bí mật tài khoản thử nghiệm. |

## Phase 03 — Từ điển, nhập tay và lưu từ

Milestone `Phase-03`; label chung `phase-03`, `dictionary`. **DoD:** nhập/dán chữ → tra cứu có nguồn → lưu/bỏ lưu → đồng bộ hai nền tảng, không cần OCR/AI.

| ID | Tiêu đề issue | Phụ thuộc | Ước lượng | Tiêu chí xong / bằng chứng |
|---|---|---|---:|---|
| HL-03-01 | Chọn nguồn từ điển và schema mục từ | HL-02-06, HL-00-07 | 1 | Pin OpenCidian commit/checksum theo CC BY-SA 4.0; schema có giản thể/phồn thể, Pinyin, nghĩa Việt, ví dụ rỗng khi thiếu, HSK theo version, provenance; quyết định SQLite backend/search/ID ổn định được ghi. |
| HL-03-02 | Viết seed/import candidate từ điển idempotent | HL-03-01 | 2 | Build 300–500 candidate chạy lặp cùng checksum; validation/reject report, schema/index/test; không bịa nghĩa/ví dụ và chưa nhận đã review độc lập. |
| HL-03-03 | Làm API search Hanzi/Pinyin | HL-03-02 | 1.5 | Backend Python search candidate có giới hạn/phân trang và xử lý không tìm thấy; API tests pass; response giữ nguồn/giới hạn chất lượng. |
| HL-03-04 | Làm API detail mục từ và nguồn dữ liệu | HL-03-02 | 1 | Detail trả mục từ/nguồn đúng contract; API tests pass; attribution có thể truy vết. |
| HL-03-05 | Làm UI nhập/dán chữ và kết quả tra | HL-03-03, HL-03-04 | 2 | Web và Android nhập/chọn chữ, tra, xem Hanzi/Pinyin/nghĩa/ví dụ; empty/error rõ. |
| HL-03-06 | Làm lưu/bỏ lưu từ không trùng | HL-03-05 | 2 | Saved Words trên hai target; Firestore không có bản lưu trùng; Rules cho `saved_words` giới hạn UID/field/type; offline/error hợp lý. |
| HL-03-07 | Kiểm thử luồng nhập tay → tra → lưu | HL-03-06, HL-03-08 | 1 | Widget/repository/API tests và demo Web/Android; TTS chỉ thêm nếu đã có giải pháp tin cậy. |
| HL-03-08 | Review tiếng Việt và khóa corpus phát hành | HL-03-02 | 1.5 | Manifest audit bao phủ 500 candidate; self-review mẫu đều theo workflow solo của baseline, ghi reviewer/phương pháp/giới hạn/flags và mục sửa/loại; build lại checksum/số thật; không dùng LLM làm nguồn chuẩn hay nhận là chứng nhận chuyên gia độc lập. |

## Phase 04 — Flashcard, Quiz và lịch ôn

Milestone `Phase-04`; label chung `phase-04`, `learning`. **DoD:** saved word → Flashcard → Quiz → dueAt mới; dữ liệu còn sau đăng xuất/đăng nhập trên hai nền tảng.

| ID | Tiêu đề issue | Phụ thuộc | Ước lượng | Tiêu chí xong / bằng chứng |
|---|---|---|---:|---|
| HL-04-01 | Làm Flashcard từ saved words | HL-03-07 | 2 | Mặt Hanzi/Pinyin/nghĩa/ví dụ, flip/next/previous, biết/chưa biết trên Web và Android. |
| HL-04-02 | Thiết kế bộ câu hỏi Quiz và scoring | HL-03-07 | 1.5 | Đáp án hợp lệ/không trùng, score/total, câu bỏ qua không tính đúng; ADR nếu tạo đề ở client. |
| HL-04-03 | Làm màn Quiz và lời giải | HL-04-02 | 2 | Làm bài/xem lời giải/kết quả trên Web/Android; trạng thái ít từ hoặc trống hợp lý. |
| HL-04-04 | Định nghĩa và test thuật toán lịch ôn | HL-04-01 | 1.5 | Công thức interval/dueAt rõ; test rating, timezone, ngày đến hạn và dữ liệu trống. |
| HL-04-05 | Lưu review schedule và quiz results | HL-04-03, HL-04-04 | 1.5 | Cập nhật nhất quán theo UID, còn dữ liệu sau logout/login; test repository. |
| HL-04-06 | Làm Today Review, Due Count và kiểm thử vòng học | HL-04-05 | 1.5 | Màn đến hạn/trạng thái xong và E2E vòng học Web/Android có bằng chứng. |

## Phase 05 — Dashboard và UX core

Milestone `Phase-05`; label chung `phase-05`, `flutter`. **DoD:** hành trình học core liền mạch, không cần DB/terminal, chạy được Web/Android.

| ID | Tiêu đề issue | Phụ thuộc | Ước lượng | Tiêu chí xong / bằng chứng |
|---|---|---|---:|---|
| HL-05-01 | Làm Dashboard chỉ số học tập | HL-04-06 | 2 | Tổng từ lưu/đã học/đến hạn, quiz gần đây, lịch sử học; scan history chỉ khi OCR thật. |
| HL-05-02 | Làm Profile và Settings thiết yếu | HL-02-06 | 1 | Tên hiển thị, logout, cấu hình demo cần thiết; dữ liệu đúng UID. |
| HL-05-03 | Chuẩn hóa responsive, trạng thái UI và accessibility | HL-05-01, HL-05-02 | 2 | Web/mobile layout, loading/empty/error/retry, xác nhận xóa, contrast/tap targets hợp lý. |
| HL-05-04 | Kiểm tra offline, đồng bộ và Firestore reads | HL-05-03 | 1.5 | UI báo sync thật; pagination/listener không đọc quá mức; thử đứt mạng và hai thiết bị. |
| HL-05-05 | Demo và đóng DoD bản core chức năng | HL-05-04 | 1 | Nhập tay → tra/lưu → học/quiz → dashboard trên cả Web/Android, ghi bằng chứng. |

## Phase 06 — UI ảnh và hợp đồng tích hợp OCR/AI

Milestone `Phase-06`; label chung `phase-06`. **DoD:** UI ảnh và contract chạy/test; không có tuyên bố OCR/AI thật.

| ID | Tiêu đề issue | Phụ thuộc | Ước lượng | Tiêu chí xong / bằng chứng |
|---|---|---|---:|---|
| HL-06-01 | Làm upload ảnh và preview trên Flutter Web | HL-05-05 | 1.5 | Chọn file/preview, định dạng/byte/pixel/EXIF/lỗi được xử lý; chưa gọi OCR thật. |
| HL-06-02 | Làm camera/gallery và preview trên Flutter Android | HL-05-05 | 2 | Permission, chụp/chọn ảnh, preview và lỗi hoạt động trên emulator/thiết bị. |
| HL-06-03 | Làm Scanner/Result/Edit chế độ chưa có OCR | HL-06-01, HL-06-02 | 1.5 | Hiển thị “OCR chưa được cấu hình”, nhập/sửa text thủ công rồi tra; không có kết quả giả. |
| HL-06-04 | Chốt OCR API contract và backend adapter | HL-00-06, HL-06-03 | 1.5 | Multipart/response text/detections/box/confidence/latency/error và contract tests với mock. |
| HL-06-05 | Chốt AI API contract và backend adapter | HL-00-06, HL-03-07 | 1.5 | Explain schema/auth/quota/fallback và contract tests với mock; không gọi AI thật. |
| HL-06-06 | Viết hướng dẫn cấu hình service và kiểm DoD | HL-06-04, HL-06-05 | 1 | `.env.example`/docs nêu OCR endpoint/auth, AI key, health/timeout/error; không chứa secret. |

## Phase 07 — Kiểm thử core và bảo mật

Milestone `Phase-07`; label chung `phase-07`, `testing`. **DoD:** core E2E pass, không còn P0 core; OCR/AI ghi `NOT VERIFIED`.

| ID | Tiêu đề issue | Phụ thuộc | Ước lượng | Tiêu chí xong / bằng chứng |
|---|---|---|---:|---|
| HL-07-01 · DONE | Tăng coverage unit/widget/API cho core | HL-06-06 | 2 | Auth, dictionary, saved words, scheduler, UI state và lỗi API có test có ý nghĩa. |
| HL-07-02 · DONE | Chạy Rules/security tests hai tài khoản | HL-07-01 | 1.5 | Cross-user read/write bị từ chối; rà secrets/log/CORS/quyền dữ liệu, ghi kết quả. |
| HL-07-03 · PASS, chờ commit | Chạy E2E core trên Flutter Web | HL-07-01 | 1.5 | Live Chromium release bundle PASS toàn luồng và giữ dữ liệu sau relogin; widget E2E PASS. Chrome test runner treo `loading`, ghi rõ không tính PASS. |
| HL-07-04 | Chạy E2E core trên Flutter Android | HL-07-01 | 1.5 | Cùng luồng pass trên emulator/thiết bị; lỗi mạng/UI ảnh cơ bản được ghi. |
| HL-07-05 | Viết test matrix/report core và xử lý P0 | HL-07-02, HL-07-03, HL-07-04 | 2 | `test-plan.md`, `test-report-core.md` có OS/phiên bản/lệnh/kết quả; P0 core xử lý; OCR/AI NOT VERIFIED. |

## Phase 08 — Build và bàn giao bản core

Milestone `Phase-08`; label chung `phase-08`, `release`. **DoD:** Flutter Web, Android APK và backend Python chạy/demo được; gắn nhãn core, chưa là MVP cuối.

| ID | Tiêu đề issue | Phụ thuộc | Ước lượng | Tiêu chí xong / bằng chứng |
|---|---|---|---:|---|
| HL-08-01 | Build và smoke test Flutter Web core | HL-07-05 | 1.5 | Web release build chạy thật với backend/Firebase core; ghi URL/config và kết quả. |
| HL-08-02 | Build và smoke test Flutter Android APK core | HL-07-05 | 1.5 | APK cài/chạy được trên thiết bị/emulator, kết nối backend đúng; ghi kết quả. |
| HL-08-03 | Chuẩn bị backend Python và hướng dẫn demo core | HL-08-01, HL-08-02 | 1.5 | Backend runnable/hosting hoặc local, README URL Web/emulator/thiết bị, HTTPS/CORS/secrets nếu public. |
| HL-08-04 | Chốt changelog và giới hạn bản core | HL-08-03 | 1 | Bản core có hướng dẫn nhập tay; OCR/AI chưa tích hợp được ghi rõ; không tag `v1.0.0-mvp`. |

## Phase 09 — Tích hợp OCR thật

Milestone `Phase-09`; label chung `phase-09`, `ocr`. **DoD:** ảnh → OCR service thật → sửa → tra/lưu trên Web/Android; có CER/latency tái lập. Service chưa có thì phase `BLOCKED`.

| ID | Tiêu đề issue | Phụ thuộc | Ước lượng | Tiêu chí xong / bằng chứng |
|---|---|---|---:|---|
| HL-09-01 | Chốt OCR service thực tế và cấu hình | HL-08-04 | 1 | Endpoint/auth/response/giới hạn được xác nhận; nếu nội bộ thì PaddleOCR model/version/máy được khóa. |
| HL-09-02 | Hiện thực Python OcrProvider và OCR API | HL-09-01, HL-06-04 | 2 | Ảnh hợp lệ/lỗi/oversize/empty/timeout xử lý đúng; model không reload mỗi request nếu nội bộ. |
| HL-09-03 | Nối Flutter Web/Android với OCR thật và Result/Edit | HL-09-02 | 2 | Ảnh → OCR → confidence → sửa → xác nhận → tra/lưu trên cả hai target; không lưu ảnh lâu dài mặc định. |
| HL-09-04 | Tạo manifest/ground truth và cố định dev/test | HL-09-01 | 2 | Ảnh có nguồn/quyền dùng, metadata và ground truth; mục tiêu 200–300 nếu khả thi, công bố cỡ mẫu thật. |
| HL-09-05 | Viết pipeline đánh giá CER/latency/failure | HL-09-04, HL-09-02 | 2 | Normalize trước đo; CER=(S+D+I)/N, raw predictions, latency, service/model version, lệnh tái chạy. |
| HL-09-06 | So sánh ảnh gốc và xử lý ảnh khi khả thi | HL-09-05 | 1.5 | Thử OpenCV khi điều khiển pipeline; service hộp đen thì ghi giới hạn/phép thử thực tế. |
| HL-09-07 | Test OCR tích hợp và đóng DoD Phase 09 | HL-09-03, HL-09-05, HL-09-06 | 2 | Web/Android ảnh tốt/xấu/lỗi mạng pass; metrics/bằng chứng thật, không dùng mock làm kết luận. |

## Phase 10 — Tích hợp AI API thật

Milestone `Phase-10`; label chung `phase-10`, `ai`. **DoD:** giải thích từ API thật qua backend Python; key không lộ; validation/quota/fallback và rubric. Thiếu key thì `BLOCKED`.

| ID | Tiêu đề issue | Phụ thuộc | Ước lượng | Tiêu chí xong / bằng chứng |
|---|---|---|---:|---|
| HL-10-01 | Chốt AI provider/model, API key và quota | HL-08-04 | 1 | Provider/model, giá/quota và cách giữ key ở backend environment/secret store được ghi. |
| HL-10-02 | Hiện thực Python AiExplainProvider và API | HL-10-01, HL-06-05 | 2 | Prompt tiếng Việt, ví dụ Trung/Pinyin/dịch, bộ thủ có căn cứ; gọi API thật qua backend. |
| HL-10-03 | Thêm schema validation, timeout, rate limit và fallback | HL-10-02 | 2 | JSON/Pydantic hợp lệ, giới hạn dài, retry/quota, log metadata an toàn; lỗi vẫn tra từ được. |
| HL-10-04 | Nối AI Explanation card trên Flutter Web/Android | HL-10-03 | 1.5 | AI có nhãn, không ghi đè từ điển, fallback hiển thị đúng trên hai target. |
| HL-10-05 | Đánh giá thủ công 30–50 mẫu AI | HL-10-03 | 2 | Rubric nghĩa/Pinyin/ngữ cảnh/tự nhiên, lỗi và giới hạn; không dùng model tự chấm làm chân lý. |
| HL-10-06 | Test key/quota/fallback và đóng DoD Phase 10 | HL-10-04, HL-10-05 | 1.5 | API thật và UI Web/Android pass; key không xuất hiện trong app/repo/log. |

## Phase 11 — Nghiệm thu cuối và hồ sơ bảo vệ

Milestone `Phase-11`; label chung `phase-11`, `release`. **DoD:** MVP đầy đủ Web/Android + backend Python, thực nghiệm tái kiểm, báo cáo và release cùng phiên bản, không còn P0.

| ID | Tiêu đề issue | Phụ thuộc | Ước lượng | Tiêu chí xong / bằng chứng |
|---|---|---:|---:|---|
| HL-11-01 | Chạy E2E đầy đủ trên Flutter Web | HL-09-07, HL-10-06 | 1.5 | Login → ảnh/OCR/sửa → tra/lưu → học/quiz → dashboard → AI pass; lỗi/offline được ghi. |
| HL-11-02 | Chạy E2E đầy đủ trên Flutter Android | HL-09-07, HL-10-06 | 1.5 | Cùng luồng pass trên Android APK; hai tài khoản tách biệt, mạng lỗi không crash. |
| HL-11-03 | Tổng hợp CER, latency và kết quả nghiên cứu | HL-09-07 | 2 | Raw/normalized CER, median/p95, failure rate, cỡ mẫu/giới hạn, số đo thật dù không đạt CER mục tiêu. |
| HL-11-04 | Rà bảo mật, P0, quota và smoke test release | HL-11-01, HL-11-02 | 2 | Rules/secrets/log/quota/CORS và bản build thật đã kiểm; không còn P0. |
| HL-11-05 | Hoàn thiện README, API và báo cáo đồ án | HL-11-03, HL-11-04 | 2 | Docs/test report/results CSV, kiến trúc và báo cáo theo yêu cầu trường có kết quả tái kiểm. |
| HL-11-06 | Làm slide tiếng Anh và video demo | HL-11-05 | 2 | Slide khoảng 12–16 trang, video khoảng 3–6 phút trình bày luồng thật, không lộ secret. |
| HL-11-07 | Chốt release và checklist nghiệm thu MVP | HL-11-06 | 1 | Web/APK/backend/docs/changelog cùng phiên bản; tag `v1.0.0-mvp` chỉ khi mọi DoD đạt. |

## Quy tắc đồng bộ backlog

Khi `plan.md` đổi, cập nhật issue tương ứng tại đây và trên GitHub Projects trong cùng lượt: thêm/sửa tiêu chí, dependency, phase và nhãn; ghi mã thay đổi yêu cầu (CR-xxx) vào issue chịu tác động. Không chuyển issue sang Done chỉ vì đã tạo commit; cần bằng chứng kiểm tra. Issue là đơn vị commit: nếu việc quá lớn, chia issue trước; mỗi issue hoàn thành tạo đúng một commit trên branch phase tương ứng, chỉ stage file liên quan. Sau DoD phase, fast-forward `main` cục bộ. **Không push**.
