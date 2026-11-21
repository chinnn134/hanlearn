# HanLearn AI — kế hoạch thực thi

> Phiên bản 2.1, cập nhật 2026-11-21 theo CR-001 đến CR-007; người dùng đã xác nhận bắt đầu. Nguồn nền: `HanLearn_AI_SOLO_PHASE_PLAN.md`. Quy tắc: `rule.md`. Backlog issue: `kanban_management.md`. Phase 00–04 đã đạt DoD cục bộ và production; không push.

## 1. Mục tiêu và thay đổi thứ tự

**Kiến trúc bắt buộc:** một codebase **Flutter/Dart** xuất ra **hai ứng dụng Web và Android**; backend viết bằng **Python**, dùng FastAPI/Pydantic cho API và tích hợp dịch vụ. Cả Web lẫn Android phải hoàn thành chức năng tương ứng và được kiểm thử trên bản chạy thật. Flutter có thể dùng Firebase SDK cho Auth/Firestore theo kiến trúc đã chốt; các API ứng dụng và adapter OCR/AI thuộc backend Python. Không thay Web bằng framework khác, không thay Android bằng native/React Native, không thay backend Python bằng ngôn ngữ khác nếu chưa có quyết định mới của người dùng.

Sản phẩm cuối: đăng nhập → chụp/tải ảnh chữ Hán giản thể in → OCR → sửa văn bản → tra Hanzi/Pinyin/nghĩa Việt/ví dụ → lưu từ → Flashcard/Quiz/lịch ôn → tiến độ; có AI giải thích/ví dụ được kiểm chứng, thực nghiệm OCR và hồ sơ đồ án.

**Theo yêu cầu mới:** hoàn thành toàn bộ nền tảng và chức năng học tập **trước**. OCR và AI là hai phase tích hợp tính năng cuối. Trong bản core, người dùng **nhập/dán chữ Hán thủ công** để tra và học. Màn hình ảnh được chuẩn bị nhưng phải thông báo “OCR chưa được cấu hình” cho đến khi có service thật. OCR có thể là service riêng do người dùng tích hợp sau; AI sẽ dùng API key qua backend. Chưa chốt nhà cung cấp/service/model. Thiết kế backend adapter để thay đổi provider mà không sửa luồng Flutter. API key không nằm trong app hoặc Git.

Đổi thứ tự **không xóa OCR/AI khỏi nghiệm thu MVP cuối**. Nếu chưa có OCR service hoặc AI API key, vẫn có thể bàn giao bản *core* đã kiểm chứng, nhưng phải ghi `BLOCKED` cho tích hợp và không gọi bản core là MVP hoàn chỉnh. Giữ Firebase Auth/Firestore/Rules, từ điển có nguồn hợp pháp, học tập, test Web/Android, báo cáo CER/latency và demo. Ngoài phạm vi: chữ viết tay tự do, chấm phát âm AI, hội thoại giọng nói, mạng xã hội học tập, Windows production. TTS chỉ thêm khi có giải pháp phù hợp. Ước lượng 10–12 tuần của tài liệu gốc chỉ tham khảo.

## 2. Workflow mỗi lượt

1. Đọc `rule.md`, file này, `kanban_management.md`, tài liệu nguồn và hiện trạng repo; xác định phase/DoD/dependency và issue `HL-xx-yy` nhỏ có thể kiểm chứng. Mỗi issue là một đơn vị commit; tách issue nếu quá lớn.
2. **Trợ lý tự tạo** branch cục bộ `phase/xx` từ `main` đã tích hợp phase trước khi mở phase. Trước mỗi issue, trợ lý xác nhận đang ở đúng branch; nêu mục tiêu, file dự kiến, cách làm, kiểm thử và rủi ro. Chỉ làm issue của phase đang mở.
3. Sau mỗi issue, **trợ lý tự** chạy kiểm tra, cập nhật checklist/nhật ký/docs, kiểm tra diff, `git add` đúng file của issue rồi tạo **một commit cục bộ duy nhất** mang mã `[HL-xx-yy]`. Báo file đổi, lệnh/kết quả thật, commit và blocker. Người dùng không cần thao tác Git thay trợ lý. Không gom hai issue vào một commit hoặc tạo commit không có issue trên branch phase. Không `git push`. Mock/stub/contract test không chứng minh OCR/AI thật.
4. Yêu cầu mới được xử lý theo mục 5; cập nhật các issue Kanban chịu tác động trong cùng lượt. Chỉ chuyển phase khi DoD có bằng chứng. Với tính năng người dùng, bằng chứng phải bao gồm Flutter Web **và** Flutter Android; với API, phải có backend Python chạy và được kiểm tra. Khi phase đạt DoD, fast-forward `main` cục bộ từ branch phase, rồi mới mở branch phase tiếp theo. Trạng thái: `NOT STARTED`, `IN PROGRESS`, `BLOCKED`, `DONE`; một phase triển khai chính tại một thời điểm.

## 3. Roadmap mới

| Phase | Phạm vi | Phụ thuộc | Cổng bàn giao | Trạng thái |
|---|---|---|---|---|
| 00 | Yêu cầu, kiến trúc, contract | — | PRD, flow, schema, API, acceptance criteria | DONE |
| 01 | Khởi tạo Flutter Web + Android, backend Python/FastAPI, CI | 00 | Cả Web/Android chạy, Python `/health`, README | DONE cục bộ; hosted CI chưa chạy vì không push |
| 02 | Firebase Auth, Firestore, Rules | 01 | Đăng nhập, dữ liệu riêng, đồng bộ | DONE |
| 03 | Từ điển, nhập tay, lưu từ | 02 | Nhập/dán → tra → lưu/bỏ lưu | DONE |
| 04 | Flashcard, Quiz, lịch ôn | 03 | Học → quiz → lịch ôn | DONE |
| 05 | Dashboard, lịch sử học, UX | 02–04 | Luồng học core liền mạch | IN PROGRESS |
| 06 | UI ảnh và contract OCR/AI | 00–05 | Image picker/preview, adapter, chưa có OCR/AI thật | NOT STARTED |
| 07 | Kiểm thử core, bảo mật | 01–06 | E2E nhập tay, Rules, Web/Android | NOT STARTED |
| 08 | Build và demo bản core | 07 | Web/APK core, hướng dẫn chạy và giới hạn | NOT STARTED |
| 09 | **Tích hợp OCR thật** | 06, 08; service sẵn | Ảnh → OCR → sửa → tra/lưu; CER/latency | NOT STARTED |
| 10 | **Tích hợp AI API thật** | 03, 08; key/service sẵn | Giải thích, validation/quota/fallback/rubric | NOT STARTED |
| 11 | Nghiệm thu cuối, báo cáo, release | 09, 10 | E2E đầy đủ, thực nghiệm, hồ sơ bảo vệ | NOT STARTED |

Phase 09 và 10 là hai phase cuối của **phát triển tính năng**; Phase 11 kiểm thử và phát hành sau tích hợp. Có thể đổi thứ tự 09/10 bằng quyết định ghi vào nhật ký nếu service AI sẵn trước. Các số phase trong tài liệu nguồn là lộ trình cũ. Mốc M1 hết 03: nhập tay/tra/lưu; M2 hết 05: học và tiến độ; M3 hết 08: bản core chạy; M4 hết 11: MVP có OCR/AI thật.

## 4. Chi tiết phase và Definition of Done

### Phase 00 — Yêu cầu và kiến trúc

- [x] Viết `docs/requirements/product-requirements.md`: persona, use case, core trước tích hợp, MVP cuối, ngoài phạm vi, tiêu chí chấp nhận. Bằng chứng: `HL-00-01`.
- [x] Vẽ flow/wireframe Web/mobile cho Auth, Home, nhập chữ, Dictionary, Saved Words, Flashcard, Quiz, Progress, Profile; bổ sung flow ảnh → OCR → sửa và AI explain ở cuối. Bằng chứng: `HL-00-02`, `HL-00-03`.
- [x] Thiết kế một Flutter codebase cho Web/Android ↔ Firebase và ↔ backend Python/FastAPI; backend `OcrProvider`/`AiExplainProvider`, xác minh Firebase ID token ở endpoint cá nhân. Bằng chứng: `HL-00-04`.
- [x] Chốt Firestore collections, UID/timestamps, API/error contract, giới hạn ảnh/quota AI, phân biệt text OCR gốc và text sửa. Bằng chứng: `HL-00-05`, `HL-00-06`; các tham số phụ thuộc provider có cổng quyết định Phase 09/10.
- [x] Chọn nguồn/quyền dùng từ điển; định nghĩa dataset OCR, ground truth, dev/test, CER; ghi cổng quyết định cho phần chưa chốt. Bằng chứng: `HL-00-07`, `docs/requirements/data-sources.md`, `docs/testing/ocr-evaluation-plan.md`.
- **DoD: ĐẠT (thiết kế).** PRD, flow/wireframe, sơ đồ, schema, `docs/api/openapi-contract.md`, `docs/testing/acceptance-criteria.md` có cổng core và MVP cuối; các lựa chọn triển khai còn mở có issue/phase chốt rõ. Bằng chứng: `HL-00-01` đến `HL-00-08` và mục 6 của acceptance criteria. Chưa có ứng dụng/test runtime ở Phase 00.

### Phase 01 — Khởi tạo

- [x] Chuẩn bị Git repo cục bộ đã có remote GitHub, cấu trúc thư mục, `.gitignore`, `.env.example` và README đầu vào (`HL-01-01`). Backlog 73 issue có trong `kanban_management.md`; người dùng sẽ đưa issue lên Kanban GitHub khi sẵn sàng. Mỗi phase một branch `phase/xx`, mỗi issue một commit `[HL-xx-yy]`; không push.
- [x] Tạo một codebase Flutter/Dart `apps/flutter_app` với target Web và Android, Riverpod, router, theme, localization cơ bản, feature-first và trạng thái loading/empty/error. Bằng chứng: `HL-01-02`, `HL-01-03`; các màn tính năng vẫn được gắn nhãn chưa triển khai.
- [x] Tạo backend Python/FastAPI `backend/app`, `/health`, namespace `/api/v1`, Pydantic, CORS allowlist, config local/staging, dependency khóa phiên bản. Bằng chứng: `HL-01-04`; các route v1 có auth sẽ được thêm theo issue chức năng, không mở endpoint giả.
- [x] `.gitignore`, `.env.example`, lint/format và CI nền đã có (`HL-01-01`, `HL-01-05`). Python runtime/dev có lockfile; Flutter có `pubspec.lock`. CI workflow mới chỉ kiểm tra cú pháp cục bộ, chưa chạy trên GitHub vì chưa push.
- [x] Viết README setup/run/test đã kiểm chứng cho Web, Android và backend (`HL-01-06`); nêu rõ UI/API chưa tích hợp và CI chưa chạy trên GitHub.
- **DoD: ĐẠT cục bộ.** Cùng codebase Flutter đã chạy Chrome headless và Android 15 emulator; backend Python chạy riêng, `/health` trả 200; lint/test pass, README setup/run/test đủ ba thành phần. CI YAML đã parse, GitHub Actions chưa chạy vì chưa push. Flutter chưa gọi backend ở Phase 01.

### Phase 02 — Auth và dữ liệu

- [x] Chuẩn bị Firebase Emulator/bootstrap Flutter hai target (`HL-02-00`): app demo riêng, Auth/Firestore emulator, Rules mặc định từ chối, Web và Android build; Android app mở không còn exception khởi tạo. Đây là môi trường local, chưa chứng minh project thật.
- [x] Đăng ký Firebase Web/Android app cho project `hanlearn-7553f`, sinh `firebase_options.dart`, đổi Android package thành `com.hanlearn.app`; build và mở Home ở Web/Android với cấu hình thật (`HL-02-01`). Chưa kiểm chứng Auth hay đọc/ghi Firestore.
- [x] Thêm đăng ký/đăng nhập email-mật khẩu, logout, persistence, trạng thái lỗi/tải (`HL-02-02`). Đã kiểm chứng trên Firebase Auth Emulator ở Web/Android; bật provider và kiểm chứng production vẫn là bước môi trường riêng trước DoD Phase 02.
- [x] Tạo idempotent `users/{uid}` và repository hồ sơ (`HL-02-03`): UID từ Firebase Auth hiện hành, Firestore Timestamp, đọc/sửa tên trên Web/Android với Emulator rules thử nghiệm. Schema các collection khác đã có trong thiết kế; triển khai dữ liệu theo phase tương ứng, `scan_history` chỉ Phase 09.
- [x] Firestore Rules cho `users/{uid}` giới hạn UID, field/type/timestamp; `vocabulary` chỉ đọc với tài khoản đăng nhập (`HL-02-04`). Collection cá nhân chưa triển khai vẫn deny-all, mở theo phase tương ứng; backend phải kiểm ID token khi sau này xử lý dữ liệu cá nhân.
- [x] Emulator tests Rules với owner/UID khác/guest, field/type/timestamp sai và từ điển chỉ đọc; widget test lỗi tải hồ sơ và retry (`HL-02-05`).
- [x] Kiểm chứng cùng UID đọc và sửa hồ sơ hai chiều trên Flutter Web/Android với Auth/Firestore Emulator (`HL-02-06`); bằng chứng ở `docs/testing/phase-02-evidence.md`. Kiểm tra production riêng trước DoD phase.
- [x] Deploy và đọc lại Firestore Rules trên project thật (`HL-02-07`): ruleset đang phát hành trùng file repo, guest đọc hồ sơ bị 403; bằng chứng ở `docs/testing/phase-02-production-evidence.md`.
- [x] Bật Email/Password và nghiệm thu Auth/Firestore production trên Flutter Web/Android (`HL-02-08`): Web/Android cùng UID đồng bộ hồ sơ hai chiều; token UID khác và guest bị từ chối; không lưu mật khẩu/token trong repo.
- **DoD: ĐẠT trên project thật.** Auth Email/Password, hồ sơ `users/{uid}`, đồng bộ Web ↔ Android, cách ly hai UID và guest đều đã được kiểm chứng trên `hanlearn-7553f`; Rules release khớp repo. Bằng chứng: `docs/testing/phase-02-production-evidence.md`. Sau commit `HL-02-08`, fast-forward `main` cục bộ rồi mở Phase 03; không push.

### Phase 03 — Từ điển và nhập chữ thủ công

- [x] Chọn OpenCidian commit `17873f1…`, khóa manifest/checksum/CC BY-SA 4.0; chốt schema, search normalization, ID ổn định và SQLite backend (`HL-03-01`).
- [x] Build 500 candidate HSK phổ biến vào SQLite bằng importer Python idempotent; validation/reject report/checksum thật, không bịa nghĩa/ví dụ (`HL-03-02`).
- [x] Audit có manifest cho đủ 500 candidate, self-review trực quan mẫu đều 100 record theo workflow solo của baseline, ghi flags/sửa/loại và build lại đúng checksum; công bố rõ không phải chứng nhận chuyên gia độc lập (`HL-03-08`).
- [x] Backend Python xác minh Firebase ID token và API search Hanzi/Pinyin trên SQLite, limit/cursor/ranking/empty/validation (`HL-03-03`).
- [x] API detail theo `vocabId`, trả schema đầy đủ và license/attribution/source refs; 404/validation/auth được test (`HL-03-04`).
- [x] Flutter Dictionary nhập/dán Hanzi/Pinyin, gọi API bằng Firebase token, kết quả/detail/nguồn, loading/empty/error/retry responsive; Web/Android build (`HL-03-05`).
- [x] Saved Words lưu/bỏ lưu không trùng bằng document `vocabId`, danh sách responsive và trạng thái loading/empty/error; Rules khóa UID/field/type/timestamp và cấm update (`HL-03-06`).
- [x] E2E production cùng UID: Web tra/lưu `学习`, Android thấy và bỏ lưu, Web reload thấy danh sách trống; token UID khác và guest đều bị từ chối (`HL-03-07`).
- **DoD: ĐẠT trên project thật.** Nhập tay → backend xác minh Firebase token → tra thông tin có nguồn → lưu/bỏ lưu → đồng bộ Web/Android; corpus đã khóa, Rules production và test search/repository qua. Bằng chứng: `docs/testing/phase-03-production-evidence.md`. Không phụ thuộc OCR/AI/TTS.

### Phase 04 — Flashcard và Quiz

- [x] Flashcard Hanzi ↔ Pinyin/nghĩa/ví dụ, flip, điều hướng, biết/chưa biết.
- [x] Quiz từ saved words, đáp án hợp lệ/không trùng, lời giải, score/total; ADR tạo đề client từ dữ liệu từ điển đã xác thực.
- [x] Công thức lịch ôn bốn mức; test rating, interval, dueAt, timezone, dữ liệu trống.
- [x] Lưu review schedule/quiz results nhất quán; Today Review, Due Count, Completed State.
- **DoD: ĐẠT trên project thật.** Flutter Web và Flutter Android cùng tài khoản đã đọc Saved Words, chạy Flashcard/Quiz, cập nhật lịch ôn và hiển thị Today Review hoàn tất. Logout/login giữ dữ liệu; Rules owner/schema/transaction và scheduler tests pass. Bằng chứng: `docs/testing/phase-04-persistence-evidence.md`, `docs/testing/phase-04-evidence.md`.

### Phase 05 — Dashboard và UX core

- [ ] Dashboard tổng từ lưu/đã học/đến hạn, quiz gần đây, lịch sử học; lịch sử quét chỉ hiện khi có OCR thật.
- [ ] Profile/Settings, responsive Web/mobile, loading/empty/error/retry, xác nhận xóa, accessibility cơ bản.
- [ ] Kiểm tra offline, pagination/listeners, trạng thái sync thật, mức đọc Firestore và cross-device.
- **DoD:** demo nhập tay → học → tiến độ không cần DB/terminal, dùng được trên Web/Android.

### Phase 06 — UI ảnh và hợp đồng tích hợp

- [ ] Web upload, Android camera/gallery, preview, quyền, giới hạn loại/byte/pixel/EXIF, crop nếu khả thi.
- [ ] Scanner/Result/Edit hiển thị “OCR chưa được cấu hình”; cho nhập/sửa text thủ công để tiếp tục tra; không tạo kết quả OCR giả.
- [ ] Chốt `POST /api/v1/ocr/recognize` multipart, text/detections/box/confidence/latency/lỗi chuẩn; adapter gọi service ngoài hoặc PaddleOCR nội bộ khi quyết định.
- [ ] Chốt `POST /api/v1/ai/explain`, schema, auth/quota/fallback; contract tests với mock, chưa gọi AI thật.
- [ ] Hướng dẫn config OCR endpoint/auth và AI API key qua backend environment, health/timeout/error; không chứa secret thật.
- **DoD:** UI ảnh/nhập tay và contract test pass; trạng thái chưa có service đúng. Không được nhận OCR/AI hoàn thành.

### Phase 07 — Kiểm thử core

- [ ] Unit/widget/API/Rules cho Auth, dictionary, saved words, học tập, lỗi mạng, hai tài khoản.
- [ ] E2E Web/Android: login → nhập chữ → tra → lưu → Flashcard → Quiz → dashboard → logout/login; UI ảnh và contract validation.
- [ ] Kiểm tra secrets/log/CORS/quyền dữ liệu; sửa P0 core; ghi matrix OS/thiết bị/phiên bản trong `docs/testing/test-plan.md`, `test-report-core.md`.
- **DoD:** core E2E pass, không còn P0 core; OCR/AI ghi `NOT VERIFIED — chưa tích hợp`.

### Phase 08 — Build/demo core

- [ ] Build Flutter Web/APK, smoke test bản build thật với backend/Firebase core.
- [ ] README install/run/test, backend URL cho Web/emulator/thiết bị, demo nhập tay và giới hạn OCR/AI.
- [ ] Chọn hosting backend phù hợp hoặc demo local, HTTPS/CORS/secrets nếu public; changelog core, chưa tag `v1.0.0-mvp`.
- **DoD:** bản core Flutter Web, Flutter Android APK và backend Python đều chạy/demo tái lập, giao tiếp đúng, giới hạn rõ; chưa phải nghiệm thu MVP cuối.

### Phase 09 — OCR thật

- [ ] Chốt OCR service thực tế: endpoint, auth, response, giới hạn. Nếu PaddleOCR nội bộ, khóa model/version và cấu hình máy.
- [ ] Hiện thực `OcrProvider` và API OCR; validate ảnh/EXIF/size/pixel, file hỏng/timeout/empty; model chỉ load một lần nếu nội bộ.
- [ ] Nối Scanner → OCR thật → Result/Edit → xác nhận → tra/lưu; cảnh báo confidence thấp; chỉ lưu text sau xác nhận, không lưu ảnh nhạy cảm dài hạn mặc định.
- [ ] Dataset manifest/ground truth có quyền dùng, dev/test cố định, mục tiêu 200–300 ảnh nếu khả thi; định nghĩa normalize, CER = (S+D+I)/N, latency/failure.
- [ ] So sánh ảnh gốc và OpenCV preprocessing khi điều khiển được pipeline; nếu service ngoài là hộp đen, ghi phép thử khả thi/giới hạn, không bịa thực nghiệm.
- [ ] Test service thật trên Web/Android, ảnh xấu/lỗi mạng; lưu service/model version/cấu hình.
- **DoD:** OCR thật chữ giản thể in, sửa rồi tra/lưu được; metrics và dataset tái lập. Thiếu service thì `BLOCKED`.

### Phase 10 — AI API thật

- [ ] Chọn API provider/model, quota/chi phí; key chỉ trong backend environment/secret store.
- [ ] Hiện thực `AiExplainProvider`/API explain; prompt tiếng Việt, ví dụ Trung/Pinyin/dịch, bộ thủ chỉ khi có căn cứ.
- [ ] Structured JSON/Pydantic, validation theo từ điển khi khả thi, giới hạn độ dài, timeout/retry/rate limit/quota và log an toàn.
- [ ] UI gắn nhãn AI, fallback về từ điển khi lỗi; không ghi đè dữ liệu xác minh.
- [ ] Đánh giá thủ công 30–50 mẫu theo rubric nghĩa/Pinyin/ngữ cảnh/tự nhiên, ghi lỗi và giới hạn.
- **DoD:** gọi API thật qua backend, key không lộ, quota/fallback hoạt động, kết quả schema hợp lệ và rubric được lưu. Thiếu key thì `BLOCKED`.

### Phase 11 — Nghiệm thu cuối

- [ ] E2E Web/Android: login → ảnh → OCR → sửa → tra → lưu → học/quiz/lịch ôn → dashboard → AI explain; hai tài khoản/offline/lỗi mạng.
- [ ] Báo CER raw/normalized, median/p95 latency, failure rate, cỡ mẫu/giới hạn; mục tiêu nghiên cứu CER ≤ 10% trên tập chữ in rõ được định nghĩa trước, công bố số thật dù không đạt.
- [ ] Sửa P0, kiểm secrets/quota/Rules, release smoke test; `docs/testing/test-report.md`, `ai/evaluation/results.csv`.
- [ ] Hoàn thiện README/API/sơ đồ, báo cáo theo yêu cầu trường (nguồn gợi ý 35–45 trang), slide tiếng Anh 12–16 trang, video 3–6 phút, changelog; chỉ tag `v1.0.0-mvp` khi đầy đủ.
- **DoD:** người chấm chạy/xem demo đầy đủ trên Flutter Web và Flutter Android với backend Python; số liệu tái kiểm tra được, Web/APK/backend/tài liệu cùng phiên bản, không còn P0.

## 5. Quy trình thay đổi yêu cầu

Ghi mỗi cập nhật bằng ID, ngày, nguồn, tác động, quyết định/trạng thái. Sửa trực tiếp mục tiêu, roadmap, dependency, checklist, DoD, test và nghiệm thu tương ứng. Nếu là ràng buộc lâu dài, sửa `rule.md` cùng lượt. Không để ghi chú mới mâu thuẫn với thân plan. Yêu cầu xung đột hoặc mơ hồ ở điểm quyết định phải được nêu rõ để người dùng chốt, trong khi tiếp tục phần việc độc lập.

| ID | Ngày | Cập nhật | Tác động/quyết định | Trạng thái |
|---|---|---|---|---|
| CR-000 | 2026-11-19 | Lập kế hoạch từ tài liệu nguồn | Tạo plan/rule; thứ tự ban đầu đã được CR-001 thay thế | SUPERSEDED |
| CR-001 | 2026-11-19 | Người dùng yêu cầu OCR và AI cuối; OCR có thể là service riêng, AI dùng API key | Core 00–08 → OCR 09 → AI 10 → nghiệm thu 11; giữ MVP cuối | APPROVED 2026-11-20 |
| CR-002 | 2026-11-19 | Người dùng nhấn mạnh hai nền tảng Web và Android đều bằng Flutter; backend bằng Python | Ghi kiến trúc bắt buộc và cổng DoD/kiểm thử cho đủ hai client cùng backend Python | APPROVED 2026-11-20 |
| CR-003 | 2026-11-19 | Người dùng yêu cầu tự động add và tạo commit sau mỗi task nhỏ, không push | Thêm cổng commit cục bộ sau task, chỉ stage file liên quan; khởi tạo Git cục bộ để áp dụng ngay | APPLIED |
| CR-004 | 2026-11-19 | Người dùng muốn quản lý dự án bằng GitHub Issues/Kanban và yêu cầu `kanban_management.md` | Tạo backlog 73 issue theo Phase 00–11, có dependency/DoD/ước lượng; đồng bộ khi plan thay đổi | APPLIED |
| CR-005 | 2026-11-20 | Người dùng yêu cầu mỗi phase là một branch, mỗi commit trong branch tương ứng một issue | Branch `phase/xx`; một issue nhỏ một commit có mã `HL-xx-yy`; tích hợp `main` bằng fast-forward cục bộ sau DoD, không push | APPLIED |
| CR-006 | 2026-11-20 | Người dùng giao trợ lý chịu trách nhiệm tạo branch và commit | Trợ lý tự thực hiện toàn bộ thao tác Git cục bộ theo issue/phase; người dùng không phải tạo branch/commit hộ; vẫn không push | APPLIED |
| CR-007 | 2026-11-20 | Người dùng báo đã tạo Firebase DB, đặt Project ID `hanlearn-7553f` trong `.env` và chưa tạo Web/Android app; yêu cầu tiếp tục Phase 02 | Tách bước local Emulator/bootstrap thành `HL-02-00` để có commit kiểm chứng riêng; `HL-02-01` vẫn yêu cầu tạo/cấu hình app Web/Android và kiểm chứng project thật. Không hạ DoD Auth/đồng bộ. | APPLIED |

## 6. Nhật ký tiến độ và nghiệm thu

| Ngày | Phase | Bằng chứng/kết quả | Còn lại |
|---|---|---|---|
| 2026-11-19 | Chuẩn bị | Sửa `plan.md`, `rule.md` theo CR-001/CR-002/CR-003; khởi tạo Git và commit tài liệu kế hoạch, chưa triển khai code | Người dùng duyệt, sau đó mở Phase 00 |
| 2026-11-19 | Chuẩn bị Kanban | Tạo `kanban_management.md` với 73 issue, cập nhật plan/rule theo CR-004; chưa tạo issue online | Người dùng đưa backlog vào GitHub Projects khi sẵn sàng |
| 2026-11-20 | Chuẩn bị workflow Git | Cập nhật plan/rule/Kanban theo CR-005; chưa mở Phase 00 | Sau khi duyệt, tạo `phase/00` và bắt đầu HL-00-01 |
| 2026-11-20 | Phân công thao tác Git | Ghi rõ trợ lý chịu trách nhiệm tạo branch/commit theo CR-006; chưa mở Phase 00 | Sau khi duyệt, trợ lý tự tạo `phase/00` và bắt đầu HL-00-01 |
| 2026-11-20 | Phase 00 · HL-00-01 | Người dùng xác nhận bắt đầu; tạo branch `phase/00`; viết PRD về persona, use case, core/MVP cuối, phạm vi và tiêu chí chấp nhận; rà nội dung với plan và backlog | Tiếp tục HL-00-02 sau khi commit issue này; Phase 00 chưa đạt DoD |
| 2026-11-20 | Phase 00 · HL-00-02 | Viết `docs/requirements/user-flows.md` với F01–F06, trạng thái lỗi/phục hồi, khác biệt Web/Android và truy vết UC; kiểm tra flow theo PRD | Tiếp tục HL-00-03 wireframe; checklist flow/wireframe chưa đóng |
| 2026-11-20 | Phase 00 · HL-00-03 | Viết sitemap và `docs/requirements/wireframes.md` với WF-01–WF-10 cho Web/Android, trạng thái core và tích hợp cuối; truy vết UC/flow | Tiếp tục HL-00-04 kiến trúc; Phase 00 chưa đạt DoD |
| 2026-11-20 | Phase 00 · HL-00-04 | Viết `docs/architecture/system-architecture.md`: thành phần Flutter/Firebase/Python, luồng core/OCR/AI, ranh bảo mật và adapter | Tiếp tục HL-00-05 schema; Phase 00 chưa đạt DoD |
| 2026-11-20 | Phase 00 · HL-00-05 | Viết `docs/architecture/firestore-data-model.md`: collections, fields/type, owner UID, timestamp, quyền truy cập, query/index và quyết định còn mở | Tiếp tục HL-00-06 API/error contract; Phase 00 chưa đạt DoD |
| 2026-11-20 | Phase 00 · HL-00-06 | Viết `docs/api/openapi-contract.md`: route, request/response, token, giới hạn ảnh/AI, error envelope và cổng OCR/AI chưa cấu hình | Tiếp tục HL-00-07 nguồn dữ liệu/đánh giá OCR; Phase 00 chưa đạt DoD |
| 2026-11-20 | Phase 00 · HL-00-07 | Kiểm tra nguồn OpenCidian/CVDICT/CC-CEDICT và giấy phép công bố; viết kế hoạch ảnh tự tạo/tự chụp, ground truth, dev/test, CER/latency; chưa seed/đo | Tiếp tục HL-00-08 acceptance criteria và rà DoD |
| 2026-11-20 | Phase 00 · HL-00-08 | Viết `docs/testing/acceptance-criteria.md` với core/final gates, test matrix và rà đầu ra HL-00-01–08; Phase 00 đạt DoD thiết kế | Sau commit, fast-forward `main` cục bộ rồi mở Phase 01 |
| 2026-11-20 | Phase 01 · HL-01-01 | Đã fast-forward `phase/00` vào `main`, mở `phase/01`; thêm cấu trúc `apps/flutter_app`/`backend`, `.gitignore`, `.env.example`, README đầu vào; kiểm Git hygiene | Tiếp tục HL-01-02 Flutter Web/Android; Flutter CLI kiểm phiên bản báo lỗi SSL khi tự fetch tags, SDK local vẫn hiện 3.47.9 |
| 2026-11-20 | Phase 01 · HL-01-02 | `flutter create --platforms=android,web`; Flutter 3.47.9/Dart 3.13.7. `flutter analyze` và `flutter test` pass; `flutter build web` pass; Chrome headless chạy HTTP 200; `flutter build apk --debug` pass, cài/mở APK trên Android 15 emulator, `pidof` thấy tiến trình. Emulator/cấu hình nằm ngoài repo. | Tiếp tục HL-01-03 Riverpod/router/theme; app hiện còn Flutter counter mặc định. `flutter doctor` cảnh báo Windows desktop không liên quan target; sdkmanager cũ không tải manifest, Android CLI thay thế đã cài emulator/system image. |
| 2026-11-20 | Phase 01 · HL-01-03 | Thêm Riverpod 3.5.0, go_router 18.1.4, Flutter localization tiếng Việt, theme, shell responsive, Home/Login và placeholder rõ phase cho các màn; thay counter test bằng test điều hướng và layout hẹp/rộng. `dart format`, `flutter analyze`, 2 widget tests, Web build, Android debug APK build/cài/mở emulator đều qua. | Tiếp tục HL-01-04 backend Python/FastAPI; Auth/từ điển/OCR/AI vẫn chưa có chức năng thật. |

- [ ] Flutter Web và Flutter Android APK đều chạy với backend Python; Firebase Auth/Firestore/Rules an toàn và đồng bộ.
- [ ] Nhập tay, từ điển có nguồn, lưu từ, Flashcard/Quiz/lịch ôn/dashboard.
- [ ] OCR service thật qua backend, UI sửa text, ground truth/CER/latency và giới hạn được ghi.
- [ ] AI API thật qua key backend, nội dung gắn nhãn, validation/quota/fallback/rubric.
- [ ] Test Web/Android, README, report, slide, video, release/changelog, không chứa secret.

| 2026-11-20 | Phase 01 · HL-01-04 | Tạo FastAPI/Pydantic Settings, router namespace `/api/v1`, `/health`, CORS allowlist; staging/production buộc origin HTTPS khai báo rõ. Khóa dependency Python trong `backend/requirements.lock`. Chạy Uvicorn riêng: `/health` 200 `{"status":"ok"}`, preflight 200 với localhost:3000, origin ngoài danh sách không có header CORS; `pip check` pass. | Tiếp tục HL-01-05 lint/format/test/CI. Firebase/OCR/AI chưa cấu hình. |

| 2026-11-20 | Phase 01 · HL-01-05 | Thêm pytest cho health/CORS/config (6 pass), Ruff format/lint pass, Flutter format/analyze/2 widget tests pass. Thêm Python dev lock và `.github/workflows/ci.yml` cho backend, Flutter Web/Android debug build; YAML parse pass. Workflow chưa chạy trên GitHub vì không push. | Tiếp tục HL-01-06 README setup/run/test và kiểm DoD Phase 01. |

| 2026-11-20 | Phase 01 · HL-01-06 | Viết lại README lệnh setup/run/test cho Python, Flutter Web và Android, CORS/env, lockfile, CI; kiểm tra nội dung với lệnh và kết quả Phase 01. DoD Phase 01 đạt cục bộ; hosted CI chưa chạy vì không push. | Sau commit, fast-forward `main` cục bộ rồi mở `phase/02`. Firebase cần cấu hình để nghiệm thu Auth/sync thật. |

| 2026-11-20 | Phase 02 · HL-02-00 | Đã fast-forward `phase/01` vào `main`, mở `phase/02`. Thêm Firebase Core/Auth/Firestore, bootstrap demo project, local Auth/Firestore Emulator và Rules mặc định từ chối; `flutter analyze`, 2 widget tests, Web build, Android debug APK build/cài/mở đều qua sau khi sửa default app. Auth/Firestore Emulator hub báo cả hai service hoạt động. Android dùng Pub cache trên D: và Windows root trust store để khắc phục lỗi Kotlin cache/TLS cục bộ. | Tiếp tục HL-02-01: `.env` đã có Project ID thật theo người dùng, nhưng Flutter còn cần Web/Android App ID, API key, Messaging Sender ID và Web Auth Domain; Firebase CLI cần đăng nhập lại để tự tạo cấu hình. Chưa xác nhận kết nối project thật, Auth hay sync. |

| 2026-11-20 | Phase 02 · HL-02-01 | Firebase CLI đã đăng nhập lại; bổ sung CA cục bộ cho Node để giữ TLS validation. Xác nhận project `hanlearn-7553f` ban đầu chưa có app, tạo `HanLearn Web` và `HanLearn Android` (`com.hanlearn.app`), FlutterFire sinh `lib/firebase_options.dart`. Dùng cấu hình SDK theo target; demo Emulator vẫn tách riêng. `flutter analyze`, 2 widget tests, Web build, Android debug APK build/cài/mở Home đều qua; bản Web phục vụ local trả HTTP 200 và Home hiển thị trực tiếp. | Tiếp tục HL-02-02 Auth; chưa kiểm chứng login, Firestore read/write hoặc sync. Chrome test runner đọc Firestore bị kẹt ở bước load nên không dùng làm bằng chứng. |
| 2026-11-20 | Phase 02 · HL-02-02 | Thêm `AuthRepository`, session stream và router guard, form đăng ký/đăng nhập email-mật khẩu, hồ sơ/đăng xuất, loading/error. Android debug cho phép HTTP tới Emulator cục bộ. 3 widget tests, `flutter analyze`, Web build qua. Trên Auth Emulator: Android đăng nhập, mở lại vẫn vào Home, hồ sơ hiện email, đăng xuất quay về Login; Web đăng nhập cùng UID, reload vẫn vào Home, hồ sơ hiện email, đăng xuất quay về Login. | Tiếp tục HL-02-03 user document/Firestore. Email/Password provider của project thật và đăng nhập production chưa kiểm chứng; cần bật trong Firebase Console trước DoD Phase 02. OCR/AI vẫn cuối. |
| 2026-11-20 | Phase 02 · HL-02-03 | Thêm `UserProfileRepository` và model, transaction tạo `users/{uid}` một lần, đọc từ server và sửa `displayName`; UID kiểm tra với Auth hiện hành, timestamp do Firestore server tạo. Session tự đảm bảo hồ sơ khi đăng nhập, Profile hiển thị loading/error/retry và sửa tên. `flutter analyze`, 3 widget tests, Web build, Android debug APK build qua. Với Auth/Firestore Emulator và rules thử nghiệm riêng tại `D:\Temp` (không commit): Android tạo/sửa hồ sơ, mở lại giữ `createdAt` và tên; Web tạo/sửa hồ sơ và đọc lại được. REST Emulator xác nhận 4 field và `createdAt` không đổi sau đăng nhập lại. | Tiếp tục `HL-02-04` Rules chính thức. `firebase/firestore.rules` trong repo vẫn deny-all; cấu hình production và bảo mật hai UID chưa nghiệm thu. |
| 2026-11-20 | Phase 02 · HL-02-04 | Viết `firebase/firestore.rules`: hồ sơ chỉ owner `get/create/update`, field/timestamp/email hợp lệ, không list/delete; `vocabulary` chỉ authenticated read; wildcard deny-all cho đường dẫn khác. Firebase Emulator nạp rules thành công. Android tạo hồ sơ và sửa tên với rules trong repo. REST Emulator: own get 200, other UID 403, guest get 403, vocabulary write 403; authenticated vocab get chưa có doc trả 404, guest 403. | Tiếp tục `HL-02-05` test Rules tự động cho hai tài khoản, field/type sai và lỗi mạng. Chưa deploy Rules lên project thật; không nhận production đã an toàn. |
| 2026-11-20 | Phase 02 · HL-02-05 | Thêm Rules unit tests dùng `@firebase/rules-unit-testing` 5.0.2/Firebase JS 12.9.0 tương thích Node 22, khóa bằng `firebase/package-lock.json`; 4 nhóm test Emulator qua: owner create/read/update giữ `createdAt`, UID khác/guest/list/delete bị từ chối, field/type/timestamp/email sai bị từ chối, từ điển chỉ đọc và collection chưa triển khai bị từ chối. Widget test mô phỏng lỗi tải hồ sơ rồi retry thành công; `flutter analyze` và 4 widget tests qua. Thêm job CI `firestore-rules`; hosted CI chưa chạy vì không push. | Tiếp tục `HL-02-06` đồng bộ Web/Android cùng UID. Rules chưa deploy production; trạng thái mất mạng thật trên thiết bị chưa được đo, widget test chỉ mô phỏng lỗi repository. |
| 2026-11-20 | Phase 02 · HL-02-06 | Auth/Firestore Emulator cùng UID `VSWeCC6BkgyIOTHXVzNYu7ijksSx`: Android lưu `RuleTest` → Web đọc; Web sửa `WebSync02` → Android mở lại đọc; Android sửa `AndroidSync02` → Web reload đọc. REST Emulator xác nhận một document `users/{uid}`, `displayName=AndroidSync02`, `createdAt` giữ nguyên. Web build và Android debug APK chạy trên hai target; bằng chứng và lệnh ở `docs/testing/phase-02-evidence.md`. | Issue đạt trên Emulator. Phase 02 còn cổng production: xác minh/bật Email/Password provider, deploy/kiểm Rules và thử Web/Android với project thật. Chưa fast-forward `main`, chưa push. |
| 2026-11-20 | Phase 02 · HL-02-07 | Firebase CLI với TLS CA cục bộ xác nhận database `(default)` và hai app Web/Android. Auth config API trả `CONFIGURATION_NOT_FOUND`. Thử khởi tạo Auth qua API trả `BILLING_NOT_ENABLED`, nên người dùng sẽ bật Email/Password qua Console. Deploy `firebase/firestore.rules` lên `hanlearn-7553f` thành công; đọc Rules release `662f0926-44ca-4263-91cd-0258d8e5b02f`, nội dung trùng repo; guest GET `users/{uid}` trả 403. 4/4 Rules tests, `flutter analyze`, 4/4 widget tests, Web build và Android debug APK build qua với cấu hình thật. Chi tiết ở `docs/testing/phase-02-production-evidence.md`. | Chỉ phần Rules production đạt. Tiếp tục `HL-02-08` sau khi Email/Password được bật: kiểm chứng đăng nhập, cùng UID Web/Android, UID khác. Chưa fast-forward `main`, chưa push. |
| 2026-11-21 | Phase 02 · HL-02-08 | Người dùng đã bật Email/Password; config xác nhận `email.enabled=true`. Web tạo/đọc hồ sơ, Android đăng nhập cùng UID; Android sửa tên thành `AndroidProd02` thì Web đọc được, Web sửa thành `WebProd02` thì Android đọc được. Firestore REST: owner A đọc A trả 200, token B đọc A trả 403, guest trả 403; hai UID khác nhau. `flutter analyze`, 4/4 widget tests, Web build và Android release APK build qua. Avast TLS inspection chỉ được hỗ trợ bằng CA do user cài và network security config thuộc `src/debug`; `aapt` xác nhận APK release không có cấu hình debug/cleartext này. | Phase 02 đạt DoD production. Commit đúng một issue, fast-forward `main` cục bộ, mở `phase/03`; không push. |
| 2026-11-21 | Phase 03 · HL-03-01 | Đã fast-forward Phase 02 vào `main` và mở `phase/03`. Xác minh trực tiếp OpenCidian tại commit `17873f10941c11ae4e410c91efdcb51c04b23c01`, CC BY-SA 4.0, checksum license/schema/lock; chốt manifest máy đọc. Quyết định corpus đã duyệt nằm trong SQLite read-only của backend, `vocabId` SHA-256 ổn định, Pinyin search normalize, HSK giữ riêng theo phiên bản và ví dụ thiếu giữ rỗng; cập nhật schema/API/attribution. | Tiếp tục `HL-03-02`: build nguồn pin, tạo import idempotent/artifact checksum, duyệt 300–500 mục hoặc báo số thật; không push. |
| 2026-11-21 | Phase 03 · HL-03-02 | Build OpenCidian pin thành công: 125.397 entry nguồn. Importer Python chọn 500 mục HSK 3.0 level 1 có nghĩa Việt, loại tên riêng/record sai cấu trúc và gộp trùng Hanzi+Pinyin; SQLite 380.928 bytes, SHA-256 `cb1e7939…68edb`. Hai lần build cho hash giống nhau; Ruff và 9/9 pytest qua. Spot-check 80 mục ghi nhận polyphone hợp lệ; không tạo nghĩa/ví dụ bằng AI. | Artifact là candidate đã validate nguồn/cấu trúc. Thêm `HL-03-08` review tiếng Việt độc lập trước DoD; có thể tiếp tục API search/detail trên candidate. |
| 2026-11-21 | Phase 03 · HL-03-03 | Thêm Firebase Admin Python 7.8.0 và lockfile tái lập; mọi `/api/v1/dictionary/search` yêu cầu ID token được Firebase xác minh. Search SQLite read-only hỗ trợ Hanzi/Pinyin dấu, số, không dấu/có-không khoảng trắng; exact/prefix ranking, limit 1–50, cursor gắn query, empty/invalid states. Ruff và 12/12 pytest qua, gồm unauthorized, pagination không trùng và bad cursor. | Tiếp tục `HL-03-04` detail/attribution; production token và Flutter client được kiểm ở các issue UI/E2E. |
| 2026-11-21 | Phase 03 · HL-03-04 | Detail API đọc SQLite read-only theo `vocabId`, trả giản/phồn thể, Pinyin dấu/số, nghĩa/senses Việt, Hán Việt, HSK theo version, examples, field-level source refs, CC BY-SA 4.0 và attribution nhúng từ corpus metadata. Không có ID trả 404; auth vẫn bắt buộc. Ruff và 13/13 pytest qua. | Tiếp tục `HL-03-05` Flutter client/UI nhập–tra; API production smoke với token thật ở E2E. |
| 2026-11-21 | Phase 03 · HL-03-05 | Thêm HTTP 1.6.0, `API_BASE_URL`, Firebase ID token header và model/repository Dictionary. Màn responsive cho nhập/dán, search, detail, attribution, examples trống, loading/empty/error/retry. `flutter analyze`, 6 tests, Web build và Android debug APK build qua; Android dùng `10.0.2.2`, Web dùng `127.0.0.1`. Kotlin cache cũ cần clean/stop daemon trước build Android. | Tiếp tục `HL-03-06` Saved Words + Rules. Test thực với backend/Firebase production ở `HL-03-07`; không coi widget fake là E2E. |
| 2026-11-21 | Phase 03 · HL-03-06 | Thêm repository Firestore `users/{uid}/saved_words/{vocabId}`, transaction tạo idempotent với server timestamp, lưu/bỏ lưu từ màn detail và danh sách Saved Words responsive. Rules chỉ cho owner get/list/create/delete đúng ba field, `masteryLevel = 0`, `savedAt == request.time`, cấm update/guest/UID khác. `flutter analyze`, 7/7 Flutter tests và 5/5 Rules emulator tests qua. | Tiếp tục `HL-03-08` khóa corpus, rồi `HL-03-07` kiểm thử thật Web/Android và deploy Rules; chưa coi emulator/widget test là E2E production. |
| 2026-11-21 | Phase 03 · HL-03-08 | Audit đủ 500 record bằng manifest máy đọc; kiểm source/schema/ID/Pinyin/nghĩa Việt/HSK/provenance/examples, spot-check trực quan 100 record. 500 accepted, 0 sửa/loại; flags: 46 nhiều nghĩa, 17 biến thể/ngữ cảnh, 3 register nhạy cảm. Rebuild từ source pin với allowlist giữ nguyên SHA-256 `cb1e7939…68edb`; review manifest SHA-256 `62b1db94…c93ff`; Ruff và 14/14 pytest qua. Không nhận là review độc lập/chuyên gia và không dùng AI sinh trường chuẩn. | Tiếp tục `HL-03-07` E2E production Web/Android và deploy Rules; đây là cổng runtime cuối của Phase 03. |
| 2026-11-21 | Phase 03 · HL-03-07 | Deploy Rules Saved Words lên `hanlearn-7553f`. Sửa verifier sang `google-auth` chính thức để kiểm chữ ký/expiry/issuer/audience mà không cần ADC; clean lockfile và 17/17 pytest qua. Web production tra/detail/lưu `学习`; Android cùng UID thấy từ, bỏ lưu; Web reload thấy trống. UID B và guest đọc nhánh A đều 403. Flutter analyze, 7/7 tests, Web build và Android debug build/install/run qua; Rules 5/5. Gradle giảm heap, tắt incremental và compiler in-process để build ổn định trên Windows/cross-drive cache. | Phase 03 đạt DoD; fast-forward `main` cục bộ sau commit. Phase tiếp theo là `phase/04`, không push. |

| 2026-11-21 | Phase 04 · HL-04-01 | Đã fast-forward Phase 03 vào `main` và mở `phase/04`. Thêm Flashcard responsive từ Saved Words: mặt Hanzi, lật xem Pinyin/nghĩa/ví dụ đã xác minh, trước/sau, biết/chưa biết, tiến độ lượt học, empty/error/retry. Rating hiện chỉ thuộc lượt học; chưa nhận là lịch ôn bền vững trước `HL-04-05`. `dart format`, `flutter analyze` và 9/9 Flutter tests qua, gồm layout Android hẹp. | Tiếp tục `HL-04-02` thiết kế/scoring Quiz. Build và E2E thật Web/Android được khóa ở `HL-04-06`; không push. |
| 2026-11-21 | Phase 04 · HL-04-02 | Chốt ADR tạo Quiz phía Flutter client từ chi tiết Saved Words đã xác thực; không sinh dữ liệu mới. Thêm engine Dart thuần loại vocab/đáp án trùng, bắt buộc 2–4 lựa chọn và seed tái lập; scoring tách correct/answered/skipped/total, câu bỏ qua không tính đúng. `dart format`, `flutter analyze`, 12/12 Flutter tests qua, gồm 3 unit tests engine. | Tiếp tục `HL-04-03` UI Quiz/lời giải/kết quả và trạng thái thiếu từ. |
| 2026-11-21 | Phase 04 · HL-04-03 | Nối Quiz vào router và Saved Words: loading/error/retry, trạng thái cần ít nhất hai nghĩa khác nhau, chọn hoặc bỏ qua từng câu, khóa lựa chọn sau chấm, hiện đáp án/lời giải và tổng kết correct/answered/skipped/total. UI hẹp có cuộn và RadioGroup hỗ trợ bàn phím/semantics. `dart format`, `flutter analyze`, 14/14 Flutter tests qua, gồm làm bài và trạng thái thiếu từ. | Tiếp tục `HL-04-04` thuật toán lịch ôn và unit tests; kết quả Quiz mới ở session cho đến `HL-04-05`. |
| 2026-11-21 | Phase 04 · HL-04-04 | Chốt ADR lịch ôn bốn rating ở Flutter: again 10 phút/interval 0; hard/good/easy tăng ngày theo công thức, chặn 365; mọi instant lưu/tính UTC và due khi `dueAt <= now`. Cập nhật schema bỏ `easeFactor` không dùng. Thêm model/scheduler thuần và 5 test cho khởi tạo, rating, giới hạn, timezone, due sort/empty. `dart format`, `flutter analyze`, 19/19 Flutter tests qua. | Tiếp tục `HL-04-05` Firestore repository, batch nguyên tử, Rules và nối Flashcard/Quiz. |
| 2026-11-21 | Phase 04 · HL-04-05 | Thêm Firestore LearningRepository theo UID; Flashcard ghi một schedule trong transaction, Quiz ghi result + mọi schedule trong cùng transaction và chỉ chuyển completed khi ghi thành công. Rules owner/schema/count/append-only qua 7/7 nhóm Emulator rồi deploy production. Flutter analyze và 19/19 tests qua. Web production lưu 2 từ → Flashcard → Quiz 2/2 → logout/login; owner REST xác nhận 2 schedule `reviewCount=2` và 1 result còn nguyên. Bằng chứng ở `docs/testing/phase-04-persistence-evidence.md`. | Tiếp tục `HL-04-06` Today Review/Due Count và E2E Web/Android đầy đủ; Rules production đã sẵn sàng. |
| 2026-11-21 | Phase 04 · HL-04-06 | Thêm Today Review và Due Count: saved word chưa có schedule được xem là đến hạn, schedule tương lai bị loại, hoàn thành khi không còn thẻ đến hạn. Route `/progress`, Home và shell cùng trỏ vào luồng ôn; Flashcard hỗ trợ `dueOnly`. Flutter analyze, 21/21 tests, Web release build, Android debug build/install/run, backend Ruff + 17/17 pytest và Rules 7/7 qua. Web và Android production cùng tài khoản hiển thị trạng thái hoàn tất; Android tiếp tục Flashcard/Quiz 2/2, REST xác nhận 2 schedule `reviewCount=3` và 2 result còn nguyên. Bằng chứng ở `docs/testing/phase-04-evidence.md`. | Phase 04 đạt DoD; commit đúng một issue rồi fast-forward `main` cục bộ. Phase tiếp theo là `phase/05`; không push. |
| 2026-11-21 | Phase 05 · HL-05-01 | Đã fast-forward Phase 04 vào `main` và mở `phase/05`. Home trở thành Dashboard: tổng từ lưu, từ đã học, đến hạn (kể cả chưa có schedule), 5 Quiz gần nhất và 5 lượt ôn gần nhất; trạng thái loading/error/retry/empty, responsive 1–3 cột. Chỉ đọc hữu hạn, không listener nền; lịch sử quét ghi rõ chờ OCR thật. Flutter analyze sạch và 22/22 tests qua. | Tiếp tục `HL-05-02` Profile/Settings; không push. |
| 2026-11-21 | Phase 05 · HL-05-02 | Mở rộng Profile bằng route Settings: hiển thị email và UID đang sở hữu dữ liệu, trạng thái backend từ `API_BASE_URL`, nhãn OCR/AI chưa tích hợp và ghi rõ API key chỉ ở backend. Giữ sửa tên/logout hiện có, không thêm secret hay cấu hình provider giả. Flutter analyze sạch và 23/23 tests qua. | Tiếp tục `HL-05-03` chuẩn hóa responsive/state/accessibility. |
| 2026-11-21 | Phase 05 · HL-05-03 | Chuẩn hóa UX core: xác nhận trước khi bỏ lưu từ ở danh sách và detail, giữ lịch ôn/Quiz; nút toàn app có vùng chạm tối thiểu 48px; Profile/Settings giới hạn chiều rộng Web. Bổ sung kiểm thử màn 320px với text scale 1.5 và hồi quy hộp thoại xác nhận. Flutter analyze sạch và 24/24 tests qua. | Tiếp tục `HL-05-04` offline/sync/read audit. |

**Bước tiếp theo:** hoàn thành và commit `HL-05-03`, sau đó làm `HL-05-04` trên `phase/05`; không push.
