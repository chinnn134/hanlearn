# HanLearn AI — tiêu chí nghiệm thu

> Issue `HL-00-08` · 2026-11-20 · Đây là **kế hoạch kiểm chứng**, không phải kết quả test của ứng dụng. `PASS/FAIL/NOT VERIFIED` chỉ được ghi khi phase tương ứng có bản chạy và bằng chứng. Nguồn: PRD, user flows, wireframes, architecture, Firestore model, API contract và OCR evaluation plan.

## 1. Cách dùng

- Mỗi tiêu chí có mã ổn định để ghi trong GitHub Issue, test report và demo checklist. Khi yêu cầu đổi, cập nhật tiêu chí, `plan.md` và issue Kanban cùng lượt.
- **Core gate:** Phase 00–08; OCR/AI thật không cần để đạt core, nhưng mọi UI phụ thuộc service phải ghi rõ “chưa cấu hình” và có đường nhập tay.
- **MVP final gate:** Phase 09–11; phải có OCR/AI thật, test và số liệu OCR. Không gọi bản core là MVP cuối.
- Với chức năng người dùng, kiểm tra **Flutter Web và Flutter Android**; backend API chạy bằng **Python/FastAPI**. Test mock chỉ chứng minh contract/logic, không chứng minh service ngoài hay thiết bị thật.
- Bằng chứng gồm lệnh test/log kết quả, môi trường/phiên bản, screenshot hoặc video khi cần, và commit issue `HL-xx-yy`. Kết quả chưa chạy ghi `NOT VERIFIED`, không tự đổi thành PASS.

## 2. Core acceptance matrix

| ID | Yêu cầu/flow | Điều kiện chấp nhận | Cách kiểm | Phase |
|---|---|---|---|---:|
| AC-C01 | FR-01/02, nền tảng | Cùng codebase Flutter chạy trên Chrome và Android emulator/thiết bị; backend Python `/health` trả 200 | Run/build Flutter hai target, HTTP health, README tái lập | 01 |
| AC-C02 | UC-01, FR-03 | Ít nhất một phương thức đăng nhập, logout và auth persistence hoạt động trên Web/Android; phiên lỗi có UI | Flutter widget/integration + thao tác tay hai target | 02 |
| AC-C03 | FR-04, NFR-02 | Cùng UID đồng bộ; A không đọc/ghi dữ liệu B; guest bị chặn | Firebase Emulator Rules tests + thao tác hai tài khoản | 02 |
| AC-C04 | UC-02, FR-05/06 | Nhập/dán Hanzi/Pinyin → kết quả có Hanzi/Pinyin/nghĩa Việt/nguồn; không có kết quả và lỗi có trạng thái riêng | Python API tests + UI Web/Android, data seed có nguồn | 03 |
| AC-C05 | UC-03, FR-07 | Lưu/bỏ lưu không trùng; cùng UID thấy từ trên hai target sau logout/login; không báo đã lưu khi chưa xác nhận | Firestore repository/Rules tests + demo cross-device | 03 |
| AC-C06 | UC-04, FR-08 | Flashcard lật mặt/điều hướng/đánh giá được; không có từ thì có empty state | Widget tests + thao tác Web/Android | 04 |
| AC-C07 | UC-05, FR-09/10 | Quiz không có đáp án trùng, score/total/lời giải đúng; kết quả cập nhật dueAt theo công thức, tồn tại sau login lại | Unit scheduler/scoring + Firestore test + demo hai target | 04 |
| AC-C08 | UC-06, FR-11 | Dashboard hiển thị số từ lưu/đã học/đến hạn và Quiz gần đây từ dữ liệu thật; trạng thái trống/lỗi rõ | Widget/integration + đối chiếu Firestore test data | 05 |
| AC-C09 | FR-12 core UI | Web chọn ảnh; Android camera/gallery/permission; preview và ảnh không hợp lệ có lỗi; chưa có OCR thì báo chưa cấu hình và nhập tay tiếp được | Widget/thiết bị thật hoặc emulator + contract test | 06 |
| AC-C10 | NFR-01/06/07 | Luồng login → nhập tay → tra → lưu → học → Quiz → dashboard → logout/login pass trên Web/Android; lỗi mạng không crash | E2E matrix, test report core và xử lý P0 | 07 |
| AC-C11 | Bản build core | Web release và Android APK chạy với backend Python/Firebase; README có URL môi trường và giới hạn OCR/AI | Build/smoke test bản thật; changelog gắn nhãn core | 08 |

## 3. Final MVP acceptance matrix

| ID | Yêu cầu/flow | Điều kiện chấp nhận | Cách kiểm | Phase |
|---|---|---|---|---:|
| AC-F01 | UC-07, FR-13 | Ảnh chữ Hán giản thể in → OCR service **thật** trả text; Web upload và Android camera/gallery đều hoạt động | Integration test service thật, demo hai target; ảnh tốt/xấu/lỗi mạng | 09 |
| AC-F02 | UC-07/09, FR-14 | Người dùng sửa/xác nhận trước tra/lưu; `recognizedText` và `correctedText` tách; chỉ lưu text sau xác nhận, không lưu ảnh dài hạn mặc định | E2E + kiểm Firestore/retention + Rules tests | 09 |
| AC-F03 | NFR-05 | Có manifest/quyền dùng, ground truth, dev/test cố định; CER raw/normalized, median/p95 latency, failure rate và cấu hình/service version tái lập | Chạy script đánh giá trên test freeze, kiểm raw predictions/results | 09/11 |
| AC-F04 | UC-08, FR-15 | AI API thật gọi bằng key ở backend; output có schema/nhãn; quota/rate limit; lỗi AI không chặn Dictionary | API integration thật, test invalid/timeout/quota, UI hai target, secret scan | 10 |
| AC-F05 | Chất lượng AI | 30–50 mẫu được đánh giá thủ công theo nghĩa/Pinyin/ngữ cảnh/tự nhiên, ghi lỗi và giới hạn; AI không thay từ điển nguồn | Rubric và report có mẫu/đánh giá | 10/11 |
| AC-F06 | Toàn luồng và dữ liệu | Login → ảnh → OCR → sửa → tra → lưu → Flashcard/Quiz/lịch ôn → dashboard → AI chạy trên Web/Android; hai tài khoản độc lập | E2E/smoke test Web APK với backend Python và Firebase | 11 |
| AC-F07 | Nghiên cứu và hồ sơ | Báo CER thật dù không đạt mục tiêu ≤10% tập ảnh in rõ; report/slide/video/README/changelog cùng phiên bản, không còn P0, không lộ secret | Rà test report, result CSV, build, hồ sơ và demo | 11 |

## 4. Điều kiện chặn và ngoại lệ hợp lệ

- Thiếu Android toolchain/thiết bị → không đánh dấu AC-C01/C02/C09/C10/C11 hoặc AC-F01/F06 PASS chỉ bằng Web; ghi `BLOCKED` và môi trường cần bổ sung.
- Thiếu Firebase project/credentials → không nhận Auth/Firestore/Rules đã hoàn thành bằng mock; có thể hoàn tất tài liệu/contract trước.
- Thiếu OCR service thật → Phase 09 và AC-F01/F02/F03 `BLOCKED`, bản core vẫn có thể demo bằng nhập tay. Không đưa kết quả synthetic giả làm OCR thật.
- Thiếu AI key/provider → Phase 10 và AC-F04/F05 `BLOCKED`, từ điển vẫn chạy. Không nhúng key vào Flutter để vượt blocker.
- Dataset dưới 200–300 ảnh hoặc CER >10% không được sửa số; công bố cỡ mẫu/chất lượng thực và giới hạn. Mục tiêu nghiên cứu không tự động là điều kiện phát hành nếu số liệu minh bạch và chức năng thật hoạt động.
- TTS, HSK, crop ảnh, TN2–TN4 khi service ngoài không cho điều khiển pipeline chỉ đưa vào nếu nguồn/lựa chọn khả thi; ghi rõ lý do không thực hiện, không tuyên bố PASS giả.

## 5. Test matrix tối thiểu khi triển khai

| Môi trường | Cần ghi | Tiêu chí liên quan |
|---|---|---|
| Flutter Web | Browser/version, OS, viewport, backend URL, auth state | AC-C01–C11, AC-F01/F04/F06 |
| Flutter Android | Emulator hoặc model thiết bị, Android version, permission, backend URL | AC-C01–C11, AC-F01/F04/F06 |
| Backend Python | Python/package versions, host CPU/RAM, config không lộ secret | API/health/OCR/AI latency |
| Firebase Emulator | Auth/Firestore Rules version, UID A/B, fixture | AC-C03/C05, AC-F02/F06 |
| OCR dataset | Manifest/hash, split, nguồn/quyền, model/service version | AC-F03/F07 |

Lệnh chạy cụ thể được bổ sung vào `docs/testing/test-plan.md` khi repo/test thật tồn tại ở Phase 07/09/11; tài liệu này không liệt kê lệnh chưa kiểm chứng như thể đã chạy.

## 6. Rà Definition of Done Phase 00

| Đầu ra Phase 00 | Bằng chứng thiết kế | Trạng thái |
|---|---|---|
| Mục tiêu, persona, use case, core/MVP, ngoài phạm vi | `docs/requirements/product-requirements.md` (HL-00-01) | Có |
| Luồng demo và lỗi/phục hồi | `docs/requirements/user-flows.md` (HL-00-02) | Có |
| Sitemap và wireframe Web/Android | `docs/requirements/wireframes.md` (HL-00-03) | Có |
| Thành phần Flutter/Python/Firebase và adapter | `docs/architecture/system-architecture.md` (HL-00-04) | Có |
| Dữ liệu cá nhân, UID, collections, timestamps | `docs/architecture/firestore-data-model.md` (HL-00-05) | Có |
| Điểm gọi API, lỗi, giới hạn, auth | `docs/api/openapi-contract.md` (HL-00-06) | Có |
| Nguồn/quyền dùng và kế hoạch OCR/CER | `docs/requirements/data-sources.md`, `docs/testing/ocr-evaluation-plan.md` (HL-00-07) | Có |
| Tiêu chí nghiệm thu core và MVP cuối | File này (HL-00-08) | Có |

**Kết luận thiết kế:** các chức năng lõi và cổng tích hợp đã được định nghĩa đủ để mở Phase 01. Các lựa chọn phương thức Auth, corpus release, thuật toán lịch ôn, OCR/AI provider và hosting là **quyết định triển khai có issue/phase chốt rõ**, không phải chức năng bị bỏ sót. Việc có tài liệu ở Phase 00 **không** là bằng chứng ứng dụng/Rules/service đã hoạt động.
