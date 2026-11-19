# HANLEARN AI — KẾ HOẠCH TRIỂN KHAI THEO PHASE (SOLO DEVELOPER)

> Phiên bản: 1.0 · Dựa trên kế hoạch HanLearn AI đã cung cấp · Một người phát triển toàn bộ · Định hướng Web + Android · Thời lượng đề xuất: **10–12 tuần linh hoạt** (không phải cam kết tiến độ)

## 0. Tổng quan và nguyên tắc triển khai

**Tên đề tài:** HanLearn AI — Ứng dụng học tiếng Trung đa nền tảng tích hợp AI nhận dạng chữ Hán và cá nhân hóa học tập.

**Mục tiêu:** Xây dựng sản phẩm có thể demo đầu-cuối: **đăng nhập → chụp/tải ảnh chữ Hán → OCR → kiểm tra/sửa kết quả → tra Pinyin/nghĩa/ví dụ → lưu từ → học Flashcard/Quiz → xem tiến độ**, đồng thời có thực nghiệm định lượng OCR để phục vụ báo cáo đồ án.

### Phạm vi MVP — bắt buộc
- Flutter Web và Android với giao diện responsive, các trạng thái loading/empty/error đầy đủ.
- Firebase Authentication, Firestore, bảo vệ dữ liệu cá nhân bằng Security Rules.
- OCR **chữ Hán giản thể in** từ ảnh qua Python/FastAPI + PaddleOCR; hỗ trợ hiệu chỉnh thủ công.
- Tra từ theo Hanzi/Pinyin, hiển thị nghĩa tiếng Việt, ví dụ, phát âm nếu nguồn TTS phù hợp.
- LLM giải thích từ/cấu tạo/bộ thủ và sinh ví dụ **có kiểm tra, không thay thế từ điển nguồn**.
- Lưu từ; Flashcard, Quiz; gợi ý lịch ôn dựa trên lịch sử đúng/sai.
- Dashboard tiến độ, lịch sử quét, đồng bộ dữ liệu giữa Web/Android.
- Unit/API/widget/integration test tối thiểu; thực nghiệm CER và thời gian OCR; build, tài liệu, demo.

**Ngoài phạm vi MVP:** nhận dạng chữ viết tay tự do, chấm phát âm AI, hội thoại giọng nói, mạng xã hội học tập, Windows production. Chỉ làm sau khi MVP ổn định.

### Công nghệ cố định (theo tài liệu gốc)
| Thành phần | Công nghệ | Vai trò |
|---|---|---|
| Client | Flutter, Dart, Riverpod | UI Web/Android, trạng thái, điều hướng |
| Backend | Python, FastAPI, Pydantic | OCR, từ điển, LLM, API |
| OCR | PaddleOCR | Nhận dạng chữ Hán |
| Xử lý ảnh | OpenCV | Ảnh gốc/tiền xử lý để so sánh |
| AI ngôn ngữ | LLM API | Giải thích, ví dụ có kiểm tra |
| Data/Auth | Cloud Firestore, Firebase Authentication | Lưu/đồng bộ và đăng nhập |
| Kiểm thử | Flutter Test, pytest | Kiểm thử chức năng và API |
| Quản lý | GitHub, GitHub Projects, GitHub Actions | Lịch sử, issue, CI |

**Nguyên tắc làm solo:** thực hiện **từng phase tuần tự**, chỉ chuyển phase khi đạt Definition of Done (DoD). Tránh làm đẹp giao diện trước khi chứng minh được OCR hoạt động. Mỗi phase có mã nguồn + kiểm thử + tài liệu + commit; AI chỉ triển khai công việc thuộc phase đang mở. Không đưa secret, Firebase service account hay LLM API key vào Git.

## 1. Tổng roadmap

| Phase | Tên giai đoạn | Ước lượng | Phụ thuộc | Mốc bàn giao |
|---|---|---:|---|---|
| 00 | Khảo sát, khóa phạm vi và thiết kế | 3–4 ngày | Không | Bộ yêu cầu, sơ đồ, backlog |
| 01 | Khởi tạo monorepo, môi trường, CI | 3–5 ngày | 00 | Flutter Web/Android và FastAPI chạy |
| 02 | Firebase Auth, Firestore, bảo mật | 5–7 ngày | 01 | Đăng nhập, lưu/đọc dữ liệu cá nhân |
| 03 | OCR baseline + dataset thực nghiệm | 5–7 ngày | 01 | OCR nhận ảnh, có ground truth |
| 04 | Xử lý ảnh, OCR API, scanner UI | 7–10 ngày | 02, 03 | Quét → OCR → sửa thủ công |
| 05 | Từ điển, tra cứu, học từ | 5–7 ngày | 02, 04 | Tra từ và lưu từ vựng |
| 06 | AI giải nghĩa / tạo ví dụ | 4–6 ngày | 05 | LLM an toàn, kiểm chứng, có fallback |
| 07 | Flashcard, Quiz, ôn tập | 7–10 ngày | 05 | Học → kiểm tra → lịch ôn |
| 08 | Dashboard, lịch sử, đồng bộ và UX | 5–7 ngày | 02, 04, 07 | Hành trình học hoàn chỉnh |
| 09 | Test end-to-end, tối ưu, thực nghiệm | 7–10 ngày | 00–08 | Kết quả CER, test, app ổn định |
| 10 | Deploy/build, báo cáo, slide, video demo | 5–7 ngày | 09 | Hồ sơ bảo vệ và bản chạy |

Thời lượng là **ước lượng công sức**, có thể chồng lấn việc ghi tài liệu và test; không bắt buộc hoàn thành đúng 8 tuần như kế hoạch nhóm ban đầu. **Ưu tiên khi thiếu thời gian:** 00→01→03→04→05→02→07→09→10; LLM và dashboard nâng cao có thể tinh giản nhưng phải ghi rõ phạm vi bản demo.

## 2. Chi tiết từng phase

### PHASE 00 — Phân tích yêu cầu và thiết kế kiến trúc
**Mục tiêu:** khóa MVP, hành trình người dùng và hợp đồng tích hợp trước khi viết tính năng.

**Checklist công việc**
- [ ] Viết `docs/requirements/product-requirements.md`: persona, use case, chức năng bắt buộc/không làm, tiêu chí chấp nhận.
- [ ] Viết user flow: Guest → Login → Home → Scanner → Result/Edit → Dictionary → Save → Flashcard/Quiz → Progress.
- [ ] Vẽ sitemap và wireframe Web/mobile cho Login, Home, Scanner, OCR Result, Dictionary, Flashcard, Quiz, Progress, Profile.
- [ ] Chọn đơn vị dữ liệu OCR (đoạn văn, dòng, ô tọa độ); quy định UTF-8, giản thể và cách lưu text đã sửa.
- [ ] Thiết kế sơ đồ hệ thống Flutter → FastAPI → PaddleOCR/Dictionary/LLM; Flutter → Firebase Auth/Firestore; FastAPI kiểm tra Firebase ID Token ở endpoint cần bảo vệ.
- [ ] Chốt Firestore collections, API contract, lỗi API chuẩn, giới hạn kích thước ảnh, giới hạn gọi LLM.
- [ ] Định nghĩa success metrics và tập ảnh cho thí nghiệm; quy tắc giấy phép dữ liệu từ điển.
- [ ] Tạo backlog GitHub theo **phase**, không theo thành viên.

**Đầu ra:** `docs/requirements/`, `docs/architecture/`, `docs/api/openapi-contract.md`, `docs/testing/acceptance-criteria.md`.

**DoD:** Liệt kê được luồng demo, thành phần cần làm, điểm gọi API, cấu trúc lưu dữ liệu, phạm vi MVP rõ ràng; không còn tính năng lõi chưa được định nghĩa.

### PHASE 01 — Khởi tạo dự án và môi trường
**Mục tiêu:** một repository có thể chạy và test trên máy cá nhân.

**Checklist công việc**
- [ ] Tạo GitHub repo `hanlearn-ai` và Projects board: `Backlog → Todo → In Progress → In Review → Done`; tạo milestone `Phase-00` ... `Phase-10`.
- [ ] Tạo Flutter app Web/Android trong `apps/flutter_app` và cấu trúc feature-first; setup Riverpod, router, theme, typography, colors, localization cơ bản.
- [ ] Tạo FastAPI `backend/app/main.py`, router `/api/v1`, health check `/health`, cấu hình CORS theo origin Web được phép.
- [ ] Thiết lập Python virtualenv, `requirements.txt`/lock file, `.env.example`, phân tách config local/staging.
- [ ] Tạo README: prereqs, lệnh setup/run Flutter Web/Android, backend, test, biến môi trường.
- [ ] Thiết lập `.gitignore`, format/lint (Dart + Python), GitHub Actions chạy lint/test cơ bản.
- [ ] Tạo skeleton các screen với mock data, trạng thái loading/error, không phụ thuộc OCR thật.

**Gợi ý lệnh cơ bản** (điều chỉnh theo Windows PowerShell/CMD hoặc Bash):
```bash
flutter create --platforms=android,web apps/flutter_app
cd apps/flutter_app
flutter pub get
flutter run -d chrome
# Tại thư mục gốc: thiết lập Python venv, cài dependencies backend
python -m venv .venv
# Kích hoạt venv phù hợp hệ điều hành rồi:
pip install -r backend/requirements.txt
uvicorn backend.app.main:app --reload
```
Đảm bảo package imports/backend layout tương thích cách chạy `uvicorn` đã chọn.

**Đầu ra:** skeleton monorepo, Home/Login mock, `/health`, CI baseline, `README.md`.

**DoD:** Flutter chạy Web và Android emulator/thiết bị; backend health trả 200; test/lint chạy qua; tài liệu setup tái lập được.

### PHASE 02 — Xác thực và cơ sở dữ liệu Firebase
**Mục tiêu:** thông tin cá nhân được quản lý an toàn, đồng bộ hai nền tảng.

**Checklist công việc**
- [ ] Tạo Firebase project, cấu hình Web/Android bằng FlutterFire; đăng ký app và giới hạn cấu hình môi trường.
- [ ] Bật phương thức đăng nhập (chọn Email/Password hoặc Google; hoàn thành ít nhất một), logout, auth state persistence.
- [ ] Thiết kế collections và field như bảng dưới; timestamps chuẩn kiểu Firestore Timestamp.
- [ ] Tạo `users/{uid}` sau đăng nhập lần đầu, idempotent; trạng thái user loading/error.
- [ ] Viết `firestore.rules`: user chỉ truy cập dữ liệu nhánh UID mình, giới hạn field/type hợp lý, từ điển chung chỉ đọc từ client.
- [ ] Dùng Firebase Emulator Suite kiểm thử đọc/ghi khác UID phải bị từ chối.
- [ ] Backend xác thực Firebase ID token nếu endpoint thao tác tài nguyên cá nhân; tuyệt đối không tin UID do client gửi tự do.
- [ ] Tạo repository layer và test auth/session, retry/lỗi mạng.

**Mẫu mô hình dữ liệu tối thiểu**
| Path | Trường chính | Lưu ý |
|---|---|---|
| `users/{uid}` | `displayName`, `email`, `createdAt` | UID là document ID |
| `vocabulary/{vocabId}` | `hanzi`, `pinyin`, `meaningVi`, `level`, `examples` | Dữ liệu từ điển chung, client chỉ đọc |
| `users/{uid}/saved_words/{vocabId}` | `vocabId`, `savedAt`, `masteryLevel` | Chống lưu trùng |
| `users/{uid}/scan_history/{scanId}` | `recognizedText`, `createdAt` | Không lưu ảnh nhạy cảm mặc định |
| `users/{uid}/review_schedule/{vocabId}` | `vocabId`, `dueAt`, `intervalDays`, `easeFactor` | Lịch ôn |
| `users/{uid}/quiz_results/{resultId}` | `score`, `totalQuestions`, `createdAt` | Điểm số/lịch sử |

**Đầu ra:** Firebase configs an toàn, Auth screens hoàn chỉnh, rules + rule tests, repository layer.

**DoD:** Đăng nhập/đăng xuất hoạt động; tạo/đọc dữ liệu đúng tài khoản; tài khoản A không truy cập được dữ liệu B; Web/Android cùng UID nhìn thấy dữ liệu đồng bộ.

### PHASE 03 — POC OCR và xây bộ dữ liệu đánh giá
**Mục tiêu:** xác nhận tính khả thi OCR trước khi đầu tư toàn bộ UI.

**Checklist công việc**
- [ ] Nghiên cứu/chọn phiên bản PaddleOCR phù hợp tiếng Trung giản thể, khóa phiên bản phụ thuộc và ghi model/version.
- [ ] Chuẩn bị 10 ảnh đầu tiên để chạy baseline và khám phá lỗi phổ biến (rõ/mờ/nghiêng/tối/đa dòng).
- [ ] Xây script `ai/experiments/run_baseline.py`: input ảnh → detections/text/confidence/boxes → JSON.
- [ ] Xây bộ ảnh đánh giá **200–300 ảnh có ground truth** nếu có đủ nguồn lực; tối thiểu tách dev/test và lưu metadata loại ảnh, quyền sử dụng.
- [ ] Viết script tính CER = (S + D + I) / N, lưu raw predictions, thời gian xử lý, phiên bản mô hình và cấu hình máy.
- [ ] Quy định normalize Unicode, khoảng trắng, dấu câu/truyền thống vs giản thể trước đánh giá; giữ cả raw metrics và normalized metrics khi cần.
- [ ] Ghi nhận tốc độ CPU/RAM, chọn baseline phù hợp laptop.

**Đầu ra:** POC OCR, dataset manifest và `ground_truth.csv`, notebook/script tính CER, báo cáo baseline.

**DoD:** OCR đọc được tối thiểu ảnh mẫu chữ in giản thể; mỗi ảnh test có ground truth; tái chạy được lệnh đánh giá ra cùng cấu trúc bảng kết quả.

### PHASE 04 — Pipeline xử lý ảnh + OCR API + Scanner
**Mục tiêu:** trải nghiệm hoàn chỉnh từ ảnh đến văn bản có thể sửa.

**Checklist công việc**
- [ ] Viết OpenCV pipeline ảnh gốc, grayscale/contrast, denoise/deskew; không mặc định mọi xử lý luôn tốt hơn.
- [ ] Chuẩn hóa EXIF orientation, resize có kiểm soát, giới hạn loại ảnh/dung lượng/số pixel, xử lý ảnh hỏng.
- [ ] Tạo OCR service singleton/lazy-load model; lưu model một lần thay vì reload từng request.
- [ ] Viết `POST /api/v1/ocr/recognize` dạng multipart image, response `text`, `detections[{text, confidence, box}]`, `processing_time_ms` và thông báo lỗi hợp lý.
- [ ] Viết pytest cho ảnh hợp lệ/không hợp lệ, kích thước quá mức, kết quả rỗng, timeout và model mock.
- [ ] Flutter Web: upload ảnh; Android: camera/gallery với quyền truy cập phù hợp; preview, crop (nếu khả thi), upload progress.
- [ ] UI OCR result: text, các đoạn nhận dạng, sửa tay trước khi tra/lưu; cảnh báo kết quả độ tin cậy thấp.
- [ ] Lưu `recognizedText` sau khi user xác nhận vào `scan_history` (khi đã đăng nhập); cho phép quét lại.

**Ví dụ response (minh họa, không phải benchmark):**
```json
{
  "success": true,
  "text": "学习中文",
  "detections": [{"text": "学习中文", "confidence": 0.96, "box": [[10,20],[180,20],[180,65],[10,65]]}],
  "processing_time_ms": 420
}
```

**Đầu ra:** OCR REST API, Scanner Web/Android, OCR Result/Edit, lịch sử bản quét.

**DoD:** Chọn/chụp ảnh → OCR → sửa chữ → xác nhận; test ảnh xấu và lỗi mạng không crash; API schema đúng; ảnh không bị lưu lâu dài ngoài chủ đích.

### PHASE 05 — Từ điển, tra từ và quản lý từ đã lưu
**Mục tiêu:** biến kết quả OCR thành đơn vị học được.

**Checklist công việc**
- [ ] Chọn nguồn dữ liệu từ vựng có giấy phép phù hợp; chuẩn hóa giản thể, Pinyin dấu thanh, nghĩa tiếng Việt, HSK level (nếu xác định), ví dụ và metadata nguồn.
- [ ] Chuẩn bị seed 300–500 mục phổ biến (hoặc ít hơn nếu thực tế), script import idempotent và validation; không bịa nghĩa để lấp chỗ trống.
- [ ] Tạo `GET /api/v1/dictionary/search?q=...` hỗ trợ search Hanzi/Pinyin, phân trang/giới hạn trả về; định nghĩa fallback từ đơn không có trong data.
- [ ] Tạo `GET /api/v1/dictionary/{id}` (API bổ sung so với kế hoạch gốc) phục vụ trang chi tiết từ.
- [ ] Tách chuỗi OCR thành các từ/đoạn chọn tra; cho phép chọn thủ công thay vì ép tách từ tự động.
- [ ] Xây Dictionary UI có Hanzi, Pinyin, nghĩa, ví dụ, nút nghe qua TTS đáng tin cậy nếu tương thích platform.
- [ ] Lưu/xóa favorite/saved words; chống trùng; xử lý offline/error; viết test search và repository.

**Đầu ra:** seed dictionary, API search/detail, dictionary screens và saved words.

**DoD:** Nhập/chọn từ từ OCR → tra được thông tin đã có nguồn → lưu, bỏ lưu → thấy từ trên thiết bị khác.

### PHASE 06 — AI NLP/LLM giải thích có kiểm chứng
**Mục tiêu:** tăng tính thông minh nhưng không để LLM tự tạo dữ liệu từ điển không kiểm soát.

**Checklist công việc**
- [ ] Viết `POST /api/v1/ai/explain` nhận Hanzi, Pinyin/meaning đã xác minh (nếu có) và ngữ cảnh.
- [ ] Thiết kế prompt chỉ giải thích tiếng Việt dễ hiểu, có ví dụ tiếng Trung + Pinyin + dịch, phân tích bộ thủ **khi có căn cứ**, không khẳng định sai nguồn gốc chữ.
- [ ] Bắt LLM trả structured JSON qua Pydantic; validate schema, giới hạn độ dài, retries/timeouts hợp lý, sanitize nội dung.
- [ ] Thêm rate limit/quota per user, log chỉ metadata cần thiết, không ghi API key hoặc dữ liệu nhạy cảm.
- [ ] Nếu LLM lỗi: UI vẫn hiển thị dữ liệu từ điển; AI explanation là phần phụ trợ.
- [ ] Tạo 30–50 từ/câu kiểm thử mẫu, rubric: đúng nghĩa, đúng Pinyin, tự nhiên, đúng ngữ cảnh; đánh dấu lỗi thủ công, không lấy kết quả tự chấm của model làm chân lý.
- [ ] Tích hợp AI Explanation card vào trang tra từ; phân biệt rõ nội dung do AI sinh.

**Đầu ra:** AI explain API, validator, bộ đánh giá nội dung và fallback.

**DoD:** AI chỉ chạy qua backend; kết quả có cấu trúc hợp lệ và phân biệt với dữ liệu từ điển; sai/timeout không làm hỏng luồng tra từ.

### PHASE 07 — Flashcard, Quiz và thuật toán ôn tập
**Mục tiêu:** tạo chu trình học có phản hồi và cá nhân hóa.

**Checklist công việc**
- [ ] Thiết kế Flashcard mặt trước Hanzi, mặt sau Pinyin/nghĩa/ví dụ; flip, next/previous, trạng thái biết/chưa biết.
- [ ] Tạo Quiz từ tập saved words: nhiều lựa chọn nghĩa/Pinyin, không có đáp án trùng/không hợp lệ; hiển thị lời giải.
- [ ] Quy định scoring minh bạch: `score/totalQuestions`, không tính câu bị bỏ qua là đúng.
- [ ] Tạo `POST /api/v1/learning/quiz` để tạo đề nếu cần server; hoặc tạo đề phía client từ dữ liệu đã xác minh, ghi rõ quyết định trong ADR.
- [ ] Định nghĩa và test thuật toán ôn theo kết quả: phiên bản đơn giản SM-2 hoặc quy tắc interval có công thức rõ ràng. API `POST /api/v1/learning/review` tính `dueAt`, `intervalDays`, `easeFactor` (nếu xử lý server).
- [ ] Mỗi lượt đánh giá flashcard/quiz cập nhật `review_schedule` và lưu quiz_results bằng thao tác nhất quán.
- [ ] Tạo màn hình Today Review, Due Count, Completed State; test timezone/dueAt và dữ liệu trống.

**Đầu ra:** Flashcard, Quiz, review scheduler, lịch sử kết quả.

**DoD:** Lưu một từ → học flashcard → làm quiz → cập nhật lần ôn tới → dữ liệu còn sau đăng xuất/đăng nhập; test logic lịch ôn.

### PHASE 08 — Dashboard, đồng bộ và hoàn thiện UX
**Mục tiêu:** một sản phẩm thống nhất, không còn các màn hình kỹ thuật rời rạc.

**Checklist công việc**
- [ ] Dashboard: tổng từ đã lưu, từ đã học, số từ đến hạn ôn, quiz gần đây, lịch sử quét.
- [ ] Tạo Profile/Settings: đăng xuất, tên hiển thị, tùy chọn cơ bản; chỉ thêm tính năng có ích cho demo.
- [ ] Chuẩn hóa design system: kích cỡ, màu, typography, spacing, responsive breakpoints, bottom nav mobile/sidebar web.
- [ ] Thống nhất loading skeleton, empty/error/retry states, snackbar thông báo, confirm trước thao tác xóa.
- [ ] Kiểm thử cross-device, kiểm soát pagination/listeners, tránh đọc Firestore quá mức; cache hợp lý.
- [ ] Accessibility cơ bản: text contrast, semantics, tap targets; xử lý ảnh màn hình lớn/nhỏ.
- [ ] Kiểm tra thao tác offline/đứt mạng; hiển thị trạng thái đồng bộ thay vì hứa dữ liệu đã lưu khi chưa xác nhận.

**Đầu ra:** dashboard và UI được polish, flow liên tục Web và Android.

**DoD:** Demo đầu-cuối không cần can thiệp database/terminal; trải nghiệm dùng được ở màn hình điện thoại và trình duyệt.

### PHASE 09 — Kiểm thử, tối ưu và nghiên cứu AI
**Mục tiêu:** chứng minh độ tin cậy hệ thống và có kết quả định lượng để bảo vệ.

**Checklist công việc**
- [ ] Test matrix Web Chrome, Android emulator/real device, backend CPU; ghi phiên bản OS, thư viện và cấu hình máy.
- [ ] Unit test: parsing OCR, search/filter dictionary, scheduler, scoring, validation; Flutter widget test các trạng thái chính.
- [ ] API tests: auth token hợp lệ/không hợp lệ, file ảnh lỗi, 4xx/5xx, rate limit, timeout; Firestore rules tests.
- [ ] Integration/E2E: đăng nhập → OCR → sửa → tra từ → lưu → flashcard → quiz → dashboard; logout/login; hai tài khoản độc lập.
- [ ] Thực nghiệm TN1 OCR ảnh gốc; TN2 grayscale/contrast; TN3 denoise/deskew; TN4 2 cấu hình/mô hình; TN5 rubric đánh giá AI giải nghĩa.
- [ ] Chia data dev/test cố định, không tune bằng test rồi báo điểm cuối cùng; ghi số mẫu theo nhóm ánh sáng, độ nghiêng, chất lượng và đa dòng.
- [ ] Tính CER, median/p95 latency, failure rate, CPU/RAM nếu đo được; so sánh và mô tả trường hợp tiền xử lý làm tệ đi.
- [ ] Mục tiêu nghiên cứu đề xuất: **CER ≤ 10% trên tập chữ Hán in rõ đã định nghĩa trước**; báo số đo thực tế dù không đạt mục tiêu.
- [ ] Xử lý bug theo mức P0/P1/P2, kiểm tra secrets, quota/cost API và crash logging không lộ thông tin.

**Đầu ra:** `docs/testing/test-plan.md`, `test-report.md`, `ai/evaluation/results.csv`, bảng/biểu đồ, logs đã ẩn thông tin nhạy cảm.

**DoD:** Toàn bộ hành trình quan trọng pass; reproducible experiments; mọi số liệu có phương pháp đo rõ ràng; lỗi P0 đã xử lý.

### PHASE 10 — Build, triển khai, báo cáo và bảo vệ
**Mục tiêu:** có bản phát hành và bộ hồ sơ hoàn chỉnh.

**Checklist công việc**
- [ ] Chọn hosting backend chạy được PaddleOCR và phù hợp giới hạn tài nguyên; có phương án fallback demo backend trên laptop trong cùng mạng với Android.
- [ ] Đặt origin CORS production, HTTPS nếu triển khai public; biến môi trường, quota, endpoint `/health`; không public Firebase credentials đặc quyền.
- [ ] Build Flutter Web release và APK Android; kiểm tra URL backend khác nhau trên Web/emulator/điện thoại.
- [ ] Chạy smoke test trên bản build thật và lưu hướng dẫn demo khi mạng mất.
- [ ] Hoàn thiện README với install/run/test/deploy, screenshots, link repo, sơ đồ kiến trúc, API.
- [ ] Báo cáo đề xuất 35–45 trang nội dung: (1) Tổng quan; (2) Lý thuyết OCR, PaddleOCR, CV; (3) Yêu cầu, kiến trúc, DB; (4) Thiết kế và triển khai; (5) Kiểm thử, thực nghiệm, kết quả; (6) Kết luận, hạn chế, hướng phát triển.
- [ ] Slide tiếng Anh 12–16 trang: problem/goal, architecture, OCR method, app flow, experiment tables, demo, challenges, future work.
- [ ] Quay video 3–6 phút demo trọn luồng, không hiển thị API keys/thông tin nhạy cảm.
- [ ] Tag bản phát hành `v1.0.0-mvp`, tạo changelog, snapshot dữ liệu test và checklist nghiệm thu.

**Đầu ra:** Web release, APK, backend runnable, Word/PDF report nếu giảng viên yêu cầu, slide tiếng Anh, video demo, repository tài liệu.

**DoD:** Người chấm có thể chạy hoặc xem demo; kết quả nghiên cứu tái kiểm tra được; toàn bộ tài liệu và release rõ phiên bản.

## 3. Cấu trúc monorepo đề xuất

```text
hanlearn-ai/
├── apps/
│   └── flutter_app/
│       ├── lib/
│       │   ├── core/                  # router, theme, config, network, errors
│       │   ├── features/
│       │   │   ├── auth/
│       │   │   ├── home/
│       │   │   ├── scanner/
│       │   │   ├── dictionary/
│       │   │   ├── saved_words/
│       │   │   ├── flashcards/
│       │   │   ├── quiz/
│       │   │   └── progress/
│       │   └── main.dart
│       └── test/
├── backend/
│   ├── app/
│   │   ├── api/v1/
│   │   ├── core/                      # config, auth, exception handlers
│   │   ├── schemas/
│   │   ├── services/                  # ocr, image, dictionary, llm, review
│   │   └── main.py
│   ├── tests/
│   └── requirements.txt
├── ai/
│   ├── datasets/                     # manifest/ground truth; chú ý license
│   ├── preprocessing/
│   ├── experiments/
│   └── evaluation/
├── firebase/
│   ├── firestore.rules
│   └── firestore.indexes.json
├── docs/
│   ├── requirements/
│   ├── architecture/
│   ├── api/
│   ├── testing/
│   └── report/
├── .github/workflows/
├── .env.example
├── .gitignore
├── README.md
└── PLAN.md                              # Có thể đặt nội dung file này tại đây
```

## 4. Hợp đồng API đề xuất

| Method | Route | Input | Output / lưu ý |
|---|---|---|---|
| GET | `/health` | — | Health check |
| POST | `/api/v1/ocr/recognize` | Multipart image | OCR text, detections, boxes, confidence, latency |
| GET | `/api/v1/dictionary/search?q=...` | Hanzi/Pinyin | Kết quả tra cứu có nguồn |
| GET | `/api/v1/dictionary/{vocabId}` | ID từ | Chi tiết từ |
| POST | `/api/v1/ai/explain` | Từ, ngữ cảnh | Giải thích AI có schema, quota/auth |
| POST | `/api/v1/learning/quiz` | Danh sách word ID / options | Bộ câu hỏi hợp lệ; có thể thay bằng client-only nếu đã chốt |
| POST | `/api/v1/learning/review` | Word ID, rating, schedule hiện tại | Schedule mới; auth bắt buộc nếu thao tác dữ liệu cá nhân |

**Chuẩn hóa lỗi:** JSON gồm `error.code`, `error.message`, `request_id` (nếu có); HTTP 400/401/403/413/422/429/500/503 phân biệt đúng. Với AI route, key nằm trên backend. Nếu Flutter đọc/ghi Firestore trực tiếp thì backend không tạo API CRUD trùng lặp trừ khi có lý do thiết kế.

## 5. Chiến lược GitHub Projects dành cho 1 người

Không có Assignee theo thành viên hay chia task song song. Quản lý **mỗi phase là một milestone/epic**, issue chia theo đầu ra nhỏ có thể kiểm chứng (0.5–2 ngày). Label: `phase-00`...`phase-10`, `flutter`, `backend`, `ocr`, `nlp`, `firebase`, `testing`, `docs`, `bug`, `priority-p0/p1/p2`. Một lần chỉ giữ **1–2 Issue In Progress**.

**Mẫu Issue**
```md
## Mục tiêu
[Đầu ra cụ thể]
## Phạm vi
[Được làm / không làm]
## Công việc
- [ ] ...
## Tiêu chí chấp nhận
- [ ] ...
## Kiểm thử
- [ ] Lệnh test / thao tác demo
## Phụ thuộc
- Issue #... / Phase ...
## Tài liệu cần cập nhật
- docs/...
```

**Commit convention:** `feat(scanner): ...`, `feat(ocr): ...`, `fix(auth): ...`, `test(api): ...`, `docs(plan): ...`. Giữ `main` chạy ổn định; dùng nhánh `phase/04-ocr-scanner` hoặc `feature/ocr-api` cho thay đổi lớn, merge sau test. Solo developer có thể tự review bằng checklist PR; không ghi yêu cầu phải được người thứ hai duyệt như tài liệu nhóm cũ.

## 6. Cách làm việc với AI coding assistant

### Quy tắc bắt buộc
1. AI phải **đọc `PLAN.md`, README, cấu trúc repo và file liên quan** trước khi sửa; không tự đổi stack, thêm tính năng ngoài phạm vi.
2. Chỉ thực hiện **một issue thuộc phase hiện tại**; không tạo hàng loạt màn hình mock rồi tuyên bố hoàn thành MVP.
3. Trước khi code: nêu file sẽ sửa, cách triển khai, lệnh kiểm thử, rủi ro. Sau khi code: liệt kê file đổi, lệnh đã chạy, kết quả thực tế, việc còn lại.
4. Không hardcode secrets; luôn duy trì `.env.example`; nếu cần quyền/credentials thật thì mô tả bước cấu hình thủ công.
5. Không mô phỏng thành công giả của OCR, database, tests hoặc deployment. Nếu chưa kiểm chứng, ghi `NOT VERIFIED`.
6. Mỗi API thay đổi phải cập nhật docs/schema + client tương ứng; mỗi bug fix có regression test hợp lý.
7. Giữ code phân lớp (UI/provider/repository/service); xử lý timeouts, network errors và async cancellation.
8. Tránh kiến trúc quá phức tạp cho MVP, ưu tiên code có thể chạy và đo được.

### Prompt triển khai một phase (copy dùng lại)
```text
Bạn là Senior Full-stack Flutter + Python/FastAPI + Computer Vision Engineer.
Hãy đọc PLAN.md và hiện trạng repository HanLearn AI.
Chỉ triển khai PHASE [SỐ] — [TÊN].
Yêu cầu:
1. Kiểm tra những task của phase đã hoàn thành/chưa hoàn thành dựa trên code thật.
2. Đề xuất thứ tự issue nhỏ, ưu tiên dependency; sau đó triển khai issue đầu tiên.
3. Tuân thủ stack Flutter/Riverpod, FastAPI, PaddleOCR/OpenCV, Firebase.
4. Không làm ngoài phase nếu không cần thiết; không thay thế tính năng thật bằng mock mà không ghi rõ.
5. Viết unit/API/widget tests tương ứng và chạy kiểm tra thực tế nếu môi trường hỗ trợ.
6. Cập nhật README/docs/PLAN checklist tương ứng.
7. Cuối cùng báo cáo: file đã thay đổi, lệnh chạy, kết quả test, blocker, issue tiếp theo.
Điều kiện xong: phải thỏa toàn bộ DoD của phase; nếu chưa đạt, giữ trạng thái IN PROGRESS.
```

## 7. Mốc kiểm chứng sản phẩm

| Mốc | Luồng cần demo | Bằng chứng |
|---|---|---|
| M1 — Kết thúc Phase 03 | Flutter hoạt động, login cơ bản, OCR POC chạy ảnh mẫu | Screenshot, API output, dataset manifest |
| M2 — Kết thúc Phase 05 | Chụp/tải ảnh → OCR → sửa → tra → lưu | Video ngắn Web + Android |
| M3 — Kết thúc Phase 08 | Flashcard → Quiz → lịch ôn → Dashboard → đồng bộ | E2E checklist, Firestore test data |
| M4 — Kết thúc Phase 10 | Build release, đo CER, report, slides, demo | APK/Web build, experiment CSV, báo cáo |

## 8. Rủi ro, quyết định cắt giảm

| Rủi ro | Giảm thiểu / phương án cắt giảm |
|---|---|
| OCR nhận sai, ảnh khó | Chỉ nhắm chữ in giản thể, cho phép sửa text; đo CER theo nhóm ảnh |
| Laptop hạn chế CPU/RAM | Model nhỏ, resize, cache model, batch eval nhỏ; demo local |
| Dataset thiếu/giấy phép không rõ | Chỉ dùng ảnh/từ điển có quyền sử dụng; công bố kích thước test thực tế |
| LLM sai về nghĩa/bộ thủ | Tra từ điển làm nguồn chuẩn, ghi nhãn AI-generated, validation & fallback |
| Chi phí/giới hạn API | Rate limit + quota + cache có kiểm soát, bật tắt AI explain |
| Web/mobile khác nhau | Test image picker, permission, API base URL và network từ đầu |
| Firebase security rules sai | Test read/write cross-user qua Emulator Suite |
| Trễ tiến độ | Đóng băng scope; tập trung OCR + tra từ + lưu + Flashcard + Firebase + thực nghiệm; giản lược AI explain nâng cao |

## 9. Checklist tổng nghiệm thu cuối đồ án

- [ ] Có 1 GitHub repo rõ kiến trúc, README dễ làm theo, commit history, không chứa secret.
- [ ] Flutter Web chạy và Android APK chạy được.
- [ ] Firebase Auth + Firestore hoạt động, có Security Rules và kiểm thử cô lập người dùng.
- [ ] OCR chữ Hán giản thể in có UI sửa kết quả, API xử lý lỗi.
- [ ] Từ điển Hanzi/Pinyin/nghĩa Việt/ví dụ có nguồn dữ liệu phù hợp.
- [ ] AI giải thích/cho ví dụ (nếu nằm trong phạm vi bản chốt), có kiểm chứng/fallback.
- [ ] Lưu từ, Flashcard, Quiz, lịch ôn tập, tiến độ học.
- [ ] Có bộ ảnh ground truth, script CER và ít nhất TN1–TN4; đánh giá AI TN5 nếu có AI.
- [ ] Có unit/API/integration tests, báo cáo lỗi và test matrix Web/Android.
- [ ] Có báo cáo Word theo yêu cầu, slide tiếng Anh, video demo, hướng dẫn chạy.

---

**Khởi động ngay:** Bắt đầu **PHASE 00**. Chỉ đánh dấu hoàn thành sau khi có `product-requirements.md`, sơ đồ kiến trúc, cấu trúc dữ liệu, API contract và bộ tiêu chí chấp nhận; sau đó mới sang Phase 01.

*Lưu ý về nguồn*: Kế hoạch này được **tái cấu trúc** từ bản HanLearn AI 8 tuần/4 thành viên đã cung cấp, giữ phạm vi, stack, 5 nhóm tính năng và kế hoạch thực nghiệm chính; các chi tiết mới như Phase 00–10, DoD, chiến lược solo, giới hạn API và checklist kỹ thuật là đề xuất triển khai để một người sử dụng cùng AI coding assistant.
