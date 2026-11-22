# HanLearn AI — kế hoạch thực thi

> Phiên bản 0.8, cập nhật 2026-11-20 theo CR-001 đến CR-006; người dùng đã xác nhận bắt đầu. Nguồn nền: `HanLearn_AI_SOLO_PHASE_PLAN.md`. Quy tắc: `rule.md`. Backlog issue: `kanban_management.md`. Phase 00 đang thực hiện trên branch `phase/00`.

## 1. Mục tiêu và thay đổi thứ tự

**Kiến trúc bắt buộc:** một codebase **Flutter/Dart** xuất ra **hai ứng dụng Web và Android**; backend viết bằng **Python**, dùng FastAPI/Pydantic cho API và tích hợp dịch vụ. Cả Web lẫn Android phải hoàn thành chức năng tương ứng và được kiểm thử trên bản chạy thật. Flutter có thể dùng Firebase SDK cho Auth/Firestore theo kiến trúc đã chốt; các API ứng dụng và adapter OCR/AI thuộc backend Python. Không thay Web bằng framework khác, không thay Android bằng native/React Native, không thay backend Python bằng ngôn ngữ khác nếu chưa có quyết định mới của người dùng.

Sản phẩm cuối: đăng nhập → chụp/tải ảnh chữ Hán giản thể in → OCR → sửa văn bản → tra Hanzi/Pinyin/nghĩa Việt/ví dụ → lưu từ → Flashcard/Quiz/lịch ôn → tiến độ; có AI giải thích/ví dụ được kiểm chứng, thực nghiệm OCR và hồ sơ đồ án.

**Theo yêu cầu mới:** hoàn thành toàn bộ nền tảng và chức năng học tập **trước**. OCR và AI là hai phase tích hợp tính năng cuối. Trong bản core, người dùng **nhập/dán chữ Hán thủ công** để tra và học. Màn hình ảnh được chuẩn bị nhưng phải thông báo “OCR chưa được cấu hình” cho đến khi có service thật. OCR có thể là service riêng do người dùng tích hợp sau; AI sẽ dùng API key qua backend. Chưa chốt nhà cung cấp/service/model. Thiết kế backend adapter để thay đổi provider mà không sửa luồng Flutter. API key không nằm trong app hoặc Git.

Đổi thứ tự **không xóa OCR/AI khỏi nghiệm thu MVP cuối**. Nếu chưa có OCR service hoặc AI API key, vẫn có thể bàn giao bản _core_ đã kiểm chứng, nhưng phải ghi `BLOCKED` cho tích hợp và không gọi bản core là MVP hoàn chỉnh. Giữ Firebase Auth/Firestore/Rules, từ điển có nguồn hợp pháp, học tập, test Web/Android, báo cáo CER/latency và demo. Ngoài phạm vi: chữ viết tay tự do, chấm phát âm AI, hội thoại giọng nói, mạng xã hội học tập, Windows production. TTS chỉ thêm khi có giải pháp phù hợp. Ước lượng 10–12 tuần của tài liệu gốc chỉ tham khảo.

## 2. Workflow mỗi lượt

1. Đọc `rule.md`, file này, `kanban_management.md`, tài liệu nguồn và hiện trạng repo; xác định phase/DoD/dependency và một issue nhỏ có thể kiểm chứng.
2. Trước khi code: nêu mục tiêu, file dự kiến, cách làm, kiểm thử và rủi ro. Chỉ làm phase đang mở; phần chuẩn bị tích hợp phải ghi rõ là contract/UI, chưa phải service thật.
3. Sau mỗi task nhỏ: chạy kiểm tra phù hợp, cập nhật checklist/nhật ký, kiểm tra diff, `git add` đúng file của task và tạo commit cục bộ có thông điệp rõ. Báo file đổi, lệnh/kết quả thật, commit và blocker. Không `git push` nếu người dùng chưa yêu cầu rõ. Mock/stub/contract test không chứng minh OCR/AI thật.
4. Yêu cầu mới được xử lý theo mục 5; cập nhật các issue Kanban chịu tác động trong cùng lượt. Chỉ chuyển phase khi DoD có bằng chứng. Với tính năng người dùng, bằng chứng phải bao gồm Flutter Web **và** Flutter Android; với API, phải có backend Python chạy và được kiểm tra. Trạng thái: `NOT STARTED`, `IN PROGRESS`, `BLOCKED`, `DONE`; một phase triển khai chính tại một thời điểm.

## 3. Roadmap mới

| Phase | Phạm vi                                                    | Phụ thuộc               | Cổng bàn giao                                      | Trạng thái  |
| ----- | ---------------------------------------------------------- | ----------------------- | -------------------------------------------------- | ----------- |
| 00    | Yêu cầu, kiến trúc, contract                               | —                       | PRD, flow, schema, API, acceptance criteria        | IN PROGRESS |
| 01    | Khởi tạo Flutter Web + Android, backend Python/FastAPI, CI | 00                      | Cả Web/Android chạy, Python `/health`, README      | NOT STARTED |
| 02    | Firebase Auth, Firestore, Rules                            | 01                      | Đăng nhập, dữ liệu riêng, đồng bộ                  | NOT STARTED |
| 03    | Từ điển, nhập tay, lưu từ                                  | 02                      | Nhập/dán → tra → lưu/bỏ lưu                        | NOT STARTED |
| 04    | Flashcard, Quiz, lịch ôn                                   | 03                      | Học → quiz → lịch ôn                               | NOT STARTED |
| 05    | Dashboard, lịch sử học, UX                                 | 02–04                   | Luồng học core liền mạch                           | NOT STARTED |
| 06    | UI ảnh và contract OCR/AI                                  | 00–05                   | Image picker/preview, adapter, chưa có OCR/AI thật | NOT STARTED |
| 07    | Kiểm thử core, bảo mật                                     | 01–06                   | E2E nhập tay, Rules, Web/Android                   | NOT STARTED |
| 08    | Build và demo bản core                                     | 07                      | Web/APK core, hướng dẫn chạy và giới hạn           | NOT STARTED |
| 09    | **Tích hợp OCR thật**                                      | 06, 08; service sẵn     | Ảnh → OCR → sửa → tra/lưu; CER/latency             | NOT STARTED |
| 10    | **Tích hợp AI API thật**                                   | 03, 08; key/service sẵn | Giải thích, validation/quota/fallback/rubric       | NOT STARTED |
| 11    | Nghiệm thu cuối, báo cáo, release                          | 09, 10                  | E2E đầy đủ, thực nghiệm, hồ sơ bảo vệ              | NOT STARTED |

Phase 09 và 10 là hai phase cuối của **phát triển tính năng**; Phase 11 kiểm thử và phát hành sau tích hợp. Có thể đổi thứ tự 09/10 bằng quyết định ghi vào nhật ký nếu service AI sẵn trước. Các số phase trong tài liệu nguồn là lộ trình cũ. Mốc M1 hết 03: nhập tay/tra/lưu; M2 hết 05: học và tiến độ; M3 hết 08: bản core chạy; M4 hết 11: MVP có OCR/AI thật.

## 4. Chi tiết phase và Definition of Done

### Phase 00 — Yêu cầu và kiến trúc

- [x] Viết `docs/requirements/product-requirements.md`: persona, use case, core trước tích hợp, MVP cuối, ngoài phạm vi, tiêu chí chấp nhận. Bằng chứng: `HL-00-01`.
- [ ] Vẽ flow/wireframe Web/mobile cho Auth, Home, nhập chữ, Dictionary, Saved Words, Flashcard, Quiz, Progress, Profile; bổ sung flow ảnh → OCR → sửa và AI explain ở cuối.
- [ ] Thiết kế một Flutter codebase cho Web/Android ↔ Firebase và ↔ backend Python/FastAPI; backend `OcrProvider`/`AiExplainProvider`, xác minh Firebase ID token ở endpoint cá nhân.
- [ ] Chốt Firestore collections, UID/timestamps, API/error contract, giới hạn ảnh/quota AI, phân biệt text OCR gốc và text sửa.
- [ ] Chọn nguồn/quyền dùng từ điển; định nghĩa dataset OCR, ground truth, dev/test, CER; ghi ADR cho lựa chọn chưa chốt.
- **DoD:** PRD, sơ đồ, `docs/api/openapi-contract.md`, `docs/testing/acceptance-criteria.md` có cổng core và MVP cuối; không còn chức năng lõi mơ hồ.

### Phase 01 — Khởi tạo

- [ ] Dùng Git repo cục bộ đã khởi tạo; tạo GitHub repo/Projects khi có quyền, milestone theo roadmap mới và issue từ `kanban_management.md` (0,5–2 ngày/issue). Commit từng task nhỏ; không push nếu chưa được yêu cầu.
- [ ] Tạo một codebase Flutter/Dart `apps/flutter_app` với target Web và Android, Riverpod, router, theme, localization cơ bản, feature-first và trạng thái loading/empty/error.
- [ ] Tạo backend Python/FastAPI `backend/app`, `/health`, `/api/v1`, Pydantic, CORS allowlist, config local/staging, dependency khóa phiên bản.
- [ ] Viết `.gitignore`, `.env.example`, README setup/run/test, lint/format và CI nền.
- **DoD:** cùng codebase Flutter chạy trên trình duyệt Web và Android emulator/thiết bị; backend Python chạy riêng, `/health` trả 200; lint/test pass, setup tái lập cho đủ ba thành phần.

### Phase 02 — Auth và dữ liệu

- [ ] Cấu hình Firebase Web/Android; ít nhất một phương thức đăng nhập, logout, persistence, trạng thái lỗi/tải.
- [ ] Tạo idempotent `users/{uid}`; schema `vocabulary`, `saved_words`, `review_schedule`, `quiz_results`; dự trù `scan_history` cho Phase 09.
- [ ] Firestore Rules giới hạn UID, field/type; từ điển chung chỉ đọc; backend kiểm ID token nếu xử lý dữ liệu cá nhân.
- [ ] Emulator tests cùng/khác UID, test retry/lỗi mạng và đồng bộ Web/Android.
- **DoD:** A không đọc/ghi dữ liệu B; cùng UID thấy dữ liệu trên hai nền tảng; đăng nhập/đăng xuất đúng.

### Phase 03 — Từ điển và nhập chữ thủ công

- [ ] Chọn dữ liệu có quyền dùng, lưu metadata nguồn; chuẩn hóa giản thể, Pinyin dấu thanh, nghĩa Việt, ví dụ, HSK nếu xác minh.
- [ ] Seed mục phổ biến (mục tiêu 300–500, báo số thật), import idempotent/validation, không bịa nghĩa.
- [ ] API search Hanzi/Pinyin và detail, phân trang/giới hạn, fallback từ không có trong corpus.
- [ ] UI nhập/dán/chọn chữ, Dictionary/Saved Words, lưu/bỏ lưu không trùng, offline/error; TTS nếu tương thích.
- **DoD:** nhập tay → tra thông tin có nguồn → lưu/bỏ lưu → thấy trên Web/Android; test search/repository qua. Không phụ thuộc OCR/AI.

### Phase 04 — Flashcard và Quiz

- [ ] Flashcard Hanzi ↔ Pinyin/nghĩa/ví dụ, flip, điều hướng, biết/chưa biết.
- [ ] Quiz từ saved words, đáp án hợp lệ/không trùng, lời giải, score/total; ADR nếu tạo đề client thay vì server.
- [ ] Chọn công thức lịch ôn đơn giản/SM-2; test rating, interval, dueAt, timezone, dữ liệu trống.
- [ ] Lưu review schedule/quiz results nhất quán; Today Review, Due Count, Completed State.
- **DoD:** trên cả Flutter Web và Flutter Android: lưu từ → học → quiz → lịch ôn mới → logout/login dữ liệu còn; scheduler tests pass.

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

| ID     | Ngày       | Cập nhật                                                                                  | Tác động/quyết định                                                                             | Trạng thái          |
| ------ | ---------- | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | ------------------- |
| CR-000 | 2026-11-19 | Lập kế hoạch từ tài liệu nguồn                                                            | Tạo plan/rule; thứ tự ban đầu đã được CR-001 thay thế                                           | SUPERSEDED          |
| CR-001 | 2026-11-19 | Người dùng yêu cầu OCR và AI cuối; OCR có thể là service riêng, AI dùng API key           | Core 00–08 → OCR 09 → AI 10 → nghiệm thu 11; giữ MVP cuối                                       | APPROVED 2026-11-20 |
| CR-002 | 2026-11-19 | Người dùng nhấn mạnh hai nền tảng Web và Android đều bằng Flutter; backend bằng Python    | Ghi kiến trúc bắt buộc và cổng DoD/kiểm thử cho đủ hai client cùng backend Python               | APPROVED 2026-11-20 |
| CR-003 | 2026-11-19 | Người dùng yêu cầu tự động add và tạo commit sau mỗi task nhỏ, không push                 | Thêm cổng commit cục bộ sau task, chỉ stage file liên quan; khởi tạo Git cục bộ để áp dụng ngay | APPLIED             |
| CR-004 | 2026-11-19 | Người dùng muốn quản lý dự án bằng GitHub Issues/Kanban và yêu cầu `kanban_management.md` | Tạo backlog 73 issue theo Phase 00–11, có dependency/DoD/ước lượng; đồng bộ khi plan thay đổi   | APPLIED             |

## 6. Nhật ký tiến độ và nghiệm thu

| Ngày       | Phase           | Bằng chứng/kết quả                                                                                                 | Còn lại                                                 |
| ---------- | --------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------- |
| 2026-11-19 | Chuẩn bị        | Sửa `plan.md`, `rule.md` theo CR-001/CR-002/CR-003; khởi tạo Git và commit tài liệu kế hoạch, chưa triển khai code | Người dùng duyệt, sau đó mở Phase 00                    |
| 2026-11-19 | Chuẩn bị Kanban | Tạo `kanban_management.md` với 73 issue, cập nhật plan/rule theo CR-004; chưa tạo issue online                     | Người dùng đưa backlog vào GitHub Projects khi sẵn sàng |

# <<<<<<< HEAD

| 2026-11-20 | Chuẩn bị workflow Git | Cập nhật plan/rule/Kanban theo CR-005; chưa mở Phase 00 | Sau khi duyệt, tạo `phase/00` và bắt đầu HL-00-01 |
| 2026-11-20 | Phân công thao tác Git | Ghi rõ trợ lý chịu trách nhiệm tạo branch/commit theo CR-006; chưa mở Phase 00 | Sau khi duyệt, trợ lý tự tạo `phase/00` và bắt đầu HL-00-01 |
| 2026-11-20 | Phase 00 · HL-00-01 | Người dùng xác nhận bắt đầu; tạo branch `phase/00`; viết PRD về persona, use case, core/MVP cuối, phạm vi và tiêu chí chấp nhận; rà nội dung với plan và backlog | Tiếp tục HL-00-02 sau khi commit issue này; Phase 00 chưa đạt DoD |

> > > > > > > 2217e0c (docs(requirements): define core and final MVP [HL-00-01])

- [ ] Flutter Web và Flutter Android APK đều chạy với backend Python; Firebase Auth/Firestore/Rules an toàn và đồng bộ.
- [ ] Nhập tay, từ điển có nguồn, lưu từ, Flashcard/Quiz/lịch ôn/dashboard.
- [ ] OCR service thật qua backend, UI sửa text, ground truth/CER/latency và giới hạn được ghi.
- [ ] AI API thật qua key backend, nội dung gắn nhãn, validation/quota/fallback/rubric.
- [ ] Test Web/Android, README, report, slide, video, release/changelog, không chứa secret.

**Bước tiếp theo:** trên `phase/00`, làm `HL-00-02` user flow sau khi hoàn thành commit `HL-00-01`. Chọn service/key cụ thể ở Phase 09–10 khi sẵn sàng.
