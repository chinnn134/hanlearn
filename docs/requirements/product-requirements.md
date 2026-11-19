# HanLearn AI — Product Requirements Document

> Phiên bản 0.1 · Issue `HL-00-01` · Ngày 2026-11-20 · Trạng thái: baseline yêu cầu sản phẩm cho Phase 00.
> Nguồn: `HanLearn_AI_SOLO_PHASE_PLAN.md`, `plan.md` và các yêu cầu CR-001 đến CR-006. Khi có yêu cầu mới, cập nhật PRD, plan và backlog tương ứng.

## 1. Mục đích

HanLearn AI giúp người học tiếng Trung biến chữ Hán nhìn thấy hoặc nhập vào thành từ vựng có thể học và ôn lại. Sản phẩm phải demo được một chu trình liên tục, có dữ liệu cá nhân đồng bộ giữa Web và Android, và có kết quả đánh giá OCR định lượng phục vụ đồ án.

Đồ án do một người phát triển theo phase. **Một codebase Flutter/Dart** phát hành **Flutter Web và Flutter Android**; backend ứng dụng viết bằng **Python/FastAPI/Pydantic**. Firebase Authentication và Cloud Firestore đảm nhiệm đăng nhập, lưu và đồng bộ dữ liệu cá nhân; Security Rules bảo vệ theo UID. OCR và AI là tích hợp cuối sau khi bản học tập core đã hoàn chỉnh.

## 2. Người dùng và nhu cầu

| Nhóm | Nhu cầu chính | Tình huống thành công |
|---|---|---|
| Người mới học tiếng Trung | Tra chữ/từ giản thể nhanh, hiểu Pinyin và nghĩa tiếng Việt | Nhập chữ Hán, tìm mục từ có nguồn, lưu để học lại |
| Người học đang ôn từ vựng | Duy trì việc ôn trên Web và Android | Mở từ đã lưu, học Flashcard, làm Quiz, xem từ đến hạn và tiến độ |
| Người học gặp chữ trong ảnh | Đưa nội dung in vào luồng học | Chụp/tải ảnh, xem OCR, sửa lỗi rồi tra và lưu từ |
| Người chấm đồ án | Xem demo và kiểm tra kết quả nghiên cứu | Chạy bản Web/APK, xem báo cáo test, phương pháp CER và số đo thật |

Các nhóm trên là giả định sản phẩm để thiết kế MVP, chưa phải kết quả khảo sát người dùng. Không mở rộng sang giáo viên, mạng xã hội hoặc hội thoại giọng nói trong MVP.

## 3. Hai mốc bàn giao

### 3.1 Bản core — hoàn thành trước OCR và AI thật

Người dùng đăng nhập, nhập/dán chữ Hán giản thể, tra theo Hanzi/Pinyin, xem nghĩa Việt/ví dụ có nguồn, lưu/bỏ lưu từ, học Flashcard, làm Quiz, nhận lịch ôn và xem dashboard. Dữ liệu của cùng tài khoản đồng bộ giữa Flutter Web và Flutter Android. Có giao diện chọn ảnh/preview và điểm nối service ở Phase 06, nhưng khi chưa có OCR phải hiển thị rõ **“OCR chưa được cấu hình”** và cho phép nhập văn bản thủ công. Bản core được kiểm thử/build/demo riêng và luôn được gọi là **core**, chưa là MVP cuối.

### 3.2 MVP cuối — sau tích hợp OCR và AI

Từ bản core, bổ sung ảnh chữ Hán giản thể **in** → OCR service thật qua backend Python → kết quả có thể sửa → xác nhận → tra/lưu. Bổ sung AI giải thích và tạo ví dụ qua API key ở backend, có nhãn AI, kiểm tra đầu ra, quota và fallback về dữ liệu từ điển. Cuối cùng có kiểm thử toàn luồng Web/Android, ground truth, CER/latency thực đo, báo cáo, slide, video và bản phát hành. OCR có thể dùng service riêng; nhà cung cấp và endpoint chưa chốt. AI provider/model/key chưa chốt. Không coi mock hoặc contract test là bằng chứng tích hợp thật.

## 4. Use case ưu tiên

| ID | Use case | Điểm vào | Kết quả mong đợi | Mốc |
|---|---|---|---|---|
| UC-01 | Đăng nhập và tiếp tục học trên thiết bị khác | Login | Cùng UID thấy dữ liệu cá nhân; UID khác không truy cập được | Core |
| UC-02 | Tra từ bằng nhập/dán Hanzi hoặc Pinyin | Text Input/Dictionary | Mục từ có Hanzi, Pinyin, nghĩa Việt, ví dụ và nguồn; kết quả trống/lỗi được giải thích | Core |
| UC-03 | Lưu và bỏ lưu từ | Dictionary/Saved Words | Không tạo bản lưu trùng; danh sách đồng bộ | Core |
| UC-04 | Học Flashcard | Saved Words/Review | Xem mặt trước/sau, đánh giá biết/chưa biết | Core |
| UC-05 | Làm Quiz và nhận lịch ôn | Quiz/Today Review | Có điểm số, lời giải và ngày ôn tiếp theo theo quy tắc rõ | Core |
| UC-06 | Xem tiến độ | Dashboard | Thấy số từ lưu/đã học/đến hạn và quiz gần đây | Core |
| UC-07 | Chụp/tải ảnh để lấy chữ | Scanner | OCR thật trả text; người dùng sửa/xác nhận trước tra/lưu | MVP cuối |
| UC-08 | Xem giải thích AI | Dictionary | Giải thích/ví dụ được gắn nhãn, không ghi đè từ điển; lỗi AI không chặn tra từ | MVP cuối |
| UC-09 | Xem lịch sử quét | Scan History | Thấy text đã xác nhận gắn với tài khoản, không lưu ảnh nhạy cảm lâu dài mặc định | MVP cuối |

## 5. Yêu cầu chức năng

### 5.1 Nền tảng và tài khoản

| ID | Yêu cầu | Mốc | Tiêu chí chấp nhận sản phẩm |
|---|---|---|---|
| FR-01 | Có Flutter Web và Flutter Android từ cùng codebase | Core | Các luồng core chạy trên trình duyệt và emulator/thiết bị Android; bản cuối có Web release và APK |
| FR-02 | Backend ứng dụng viết bằng Python/FastAPI | Core | API có thể chạy riêng, có `/health`, client gọi đúng môi trường; OCR/AI đi qua adapter backend |
| FR-03 | Đăng nhập/đăng xuất bằng Firebase Auth | Core | Ít nhất một phương thức đăng nhập hoạt động trên cả hai nền tảng; trạng thái phiên được duy trì |
| FR-04 | Dữ liệu cá nhân thuộc UID và đồng bộ | Core | Cùng UID thấy dữ liệu ở Web/Android; tài khoản A không đọc/ghi dữ liệu B qua Rules |

### 5.2 Tra cứu và học tập

| ID | Yêu cầu | Mốc | Tiêu chí chấp nhận sản phẩm |
|---|---|---|---|
| FR-05 | Nhập/dán/chọn chữ để tra cứu | Core | Người dùng vào được Dictionary không cần OCR; có trạng thái trống/lỗi/mạng |
| FR-06 | Tra Hanzi/Pinyin có dữ liệu nguồn | Core | Hiển thị nghĩa Việt, Pinyin, ví dụ và nguồn khi có; không bịa dữ liệu thiếu; HSK chỉ khi xác minh |
| FR-07 | Lưu/bỏ lưu từ | Core | Không trùng saved word; dữ liệu còn sau đăng xuất/đăng nhập và thấy trên nền tảng khác |
| FR-08 | Flashcard | Core | Hanzi ở mặt trước, Pinyin/nghĩa/ví dụ ở mặt sau; điều hướng và đánh giá biết/chưa biết |
| FR-09 | Quiz | Core | Câu hỏi từ saved words, không có đáp án trùng/không hợp lệ; score/total và lời giải rõ |
| FR-10 | Lịch ôn | Core | Kết quả học/quiz cập nhật dueAt theo công thức đã ghi; timezone và tập từ trống được xử lý |
| FR-11 | Dashboard và lịch sử học | Core | Hiển thị số từ lưu/đã học/đến hạn, quiz gần đây; scan history chỉ xuất hiện khi có OCR thật |

### 5.3 Tích hợp cuối

| ID | Yêu cầu | Mốc | Tiêu chí chấp nhận sản phẩm |
|---|---|---|---|
| FR-12 | Chọn/chụp ảnh và xem preview | Core (UI), MVP cuối (OCR) | Web upload; Android camera/gallery; trước tích hợp có thông báo chưa cấu hình, không có kết quả giả |
| FR-13 | OCR chữ Hán giản thể in từ ảnh | MVP cuối | Service thật trả text/detections/confidence khi có; lỗi ảnh/mạng/timeout rõ, không crash |
| FR-14 | Sửa, xác nhận và lưu kết quả OCR | MVP cuối | Người dùng sửa text trước tra/lưu; chỉ lưu text sau xác nhận, không lưu ảnh nhạy cảm dài hạn mặc định |
| FR-15 | AI giải thích/ví dụ qua API key | MVP cuối | Key chỉ ở backend; output có cấu trúc, gắn nhãn AI, giới hạn quota; lỗi AI fallback về từ điển |

## 6. Yêu cầu phi chức năng và chất lượng

| ID | Yêu cầu | Cách xác minh dự kiến |
|---|---|---|
| NFR-01 | Giao diện Web/Android responsive và dễ hiểu | Kiểm tra kích thước màn hình chính, loading/empty/error/retry, contrast/tap targets cơ bản |
| NFR-02 | Dữ liệu cá nhân được bảo vệ | Firebase Emulator Suite thử hai UID; backend xác minh Firebase ID token khi xử lý tài nguyên cá nhân |
| NFR-03 | Secrets không nằm trong client/Git/log | Rà cấu hình, `.env.example`, bản build và log; API key/service account giữ phía server |
| NFR-04 | Không báo thành công nếu chưa kiểm chứng | Test report phân biệt real service, mock và `NOT VERIFIED`; bản core được gắn nhãn rõ |
| NFR-05 | OCR đo được và có thể tái lập | Dataset có nguồn/quyền dùng, ground truth, dev/test cố định, CER=(S+D+I)/N, latency, version service/model |
| NFR-06 | Ứng dụng không mất luồng học khi dịch vụ phụ lỗi | Lỗi mạng, OCR, AI được hiển thị; dữ liệu từ điển và nhập tay vẫn dùng được theo phạm vi từng mốc |
| NFR-07 | Có kiểm thử theo từng phần và đầu-cuối | Flutter widget/integration tests, pytest/API tests, Rules tests và smoke test Web/APK |

Mục tiêu nghiên cứu OCR đề xuất từ tài liệu nguồn: **CER ≤ 10% trên tập chữ Hán in rõ được định nghĩa trước**. Đây là mục tiêu, không phải cam kết; báo số đo thật và giới hạn dù không đạt. Mục tiêu seed từ điển 300–500 mục và dataset 200–300 ảnh là định hướng theo nguồn lực, phải ghi số thực tế và quyền sử dụng. Không đặt SLO latency hoặc tỷ lệ chính xác khác khi chưa có baseline.

## 7. Ngoài phạm vi và điều kiện bổ sung

- Không nhận dạng chữ Hán viết tay tự do; không chấm phát âm AI; không hội thoại giọng nói, mạng xã hội học tập hoặc Windows production.
- TTS chỉ làm khi có nguồn/giải pháp tương thích và đáng tin cậy; không được dùng âm thanh giả hoặc nguồn thiếu quyền.
- Không tự thay Flutter Web/Android bằng stack khác hoặc backend Python bằng ngôn ngữ khác.
- Không tự giảm OCR/AI khỏi MVP cuối chỉ vì tích hợp muộn hoặc thiếu key/service; ghi blocker và phạm vi bản core.
- Không dùng AI làm nguồn sự thật của từ điển; nghĩa/Pinyin/ví dụ nguồn phải có căn cứ và quyền sử dụng.

## 8. Tiêu chí nghiệm thu ở cấp sản phẩm

### Bản core

- [ ] Flutter Web và Flutter Android đều chạy với backend Python và Firebase đã cấu hình.
- [ ] UC-01 đến UC-06 chạy đầu-cuối trên cả hai nền tảng; dữ liệu cùng UID đồng bộ, khác UID cô lập.
- [ ] Ảnh có thể được chọn/preview theo Phase 06, nhưng OCR chưa cấu hình được báo rõ; nhập tay luôn dùng được.
- [ ] Build Web/APK core và test report có bằng chứng thật, nêu rõ OCR/AI chưa được tích hợp.

### MVP cuối

- [ ] Các tiêu chí core vẫn đạt; UC-07 đến UC-09 dùng service OCR/AI thật qua backend Python.
- [ ] Người dùng sửa OCR trước khi lưu/tra; AI có nhãn/validation/quota/fallback; secret không lộ.
- [ ] OCR có ground truth và CER/latency tái lập; thực nghiệm và test matrix Web/Android có kết quả thật.
- [ ] Web release, Android APK, backend, README, báo cáo, slide và video demo cùng phiên bản; không còn lỗi P0.

## 9. Các quyết định để dành cho issue sau

Những mục dưới đây **chưa được chốt** và không ngăn HL-00-01 hoàn thành; issue liên quan sẽ quyết định trước khi triển khai:

| Quyết định | Issue/phase dự kiến | Giới hạn hiện tại |
|---|---|---|
| Auth method cụ thể (Email/Password hoặc Google) | Phase 00/02 | Ít nhất một phương thức; phải chạy Web/Android |
| Nguồn từ điển, giấy phép, seed thực tế | HL-00-07, Phase 03 | Chỉ dùng nguồn hợp pháp, không bịa nghĩa |
| Data model/API field và lỗi chi tiết | HL-00-05, HL-00-06 | Phải nhất quán Flutter/backend/Firebase |
| Quy tắc lịch ôn và Quiz sinh ở client/server | Phase 04 | Công thức và scoring phải rõ, có test |
| OCR service/model/endpoint | Phase 09 | Có thể là service riêng, cần adapter; chỉ nhận đạt khi tích hợp thật |
| AI provider/model/API key/quota | Phase 10 | Key ở backend, có validation/fallback |
| Hosting backend và môi trường demo | Phase 08/11 | Web/Android kết nối được; giữ secret an toàn |

## 10. Truy vết

PRD này là đầu ra của `HL-00-01`. `HL-00-02` sẽ cụ thể hóa flow; `HL-00-03` wireframe; `HL-00-04` kiến trúc; `HL-00-05` schema; `HL-00-06` API; `HL-00-07` nguồn dữ liệu/đánh giá OCR; `HL-00-08` acceptance criteria toàn Phase 00. Mọi thay đổi yêu cầu sau này phải cập nhật `plan.md`, `kanban_management.md` và các mục PRD chịu tác động trong cùng issue.
