# Quy tắc thực thi HanLearn AI

> Phiên bản 0.7, theo CR-001 đến CR-006; người dùng xác nhận bắt đầu ngày 2026-11-20. Đọc cùng `plan.md`, `kanban_management.md` và `HanLearn_AI_SOLO_PHASE_PLAN.md` trước mỗi lượt.

## 1. Nguồn yêu cầu và cập nhật

1. Yêu cầu mới rõ ràng từ người dùng là chỉ đạo hiện hành. Tài liệu nguồn là baseline mục tiêu/MVP; `plan.md` là roadmap hiện hành. CR-001 thay đổi **thứ tự**: hoàn thành core trước, OCR và AI tích hợp cuối.
2. Không âm thầm bỏ hoặc hạ chuẩn yêu cầu gốc. Nếu cập nhật xung đột mục tiêu/stack/DoD cuối, ghi phần xung đột và tác động để người dùng quyết định; tiếp tục phần độc lập đã rõ.
3. Mỗi cập nhật có ID/ngày/nguồn/lý do/tác động/quyết định/trạng thái trong `plan.md`. Sửa tất cả mục bị ảnh hưởng: roadmap, dependency, checklist, DoD, test, nghiệm thu. Ràng buộc lâu dài phải sửa file này cùng lượt. Giữ dấu vết quyết định bị thay thế.

## 2. Thứ tự và ranh giới

1. Làm tuần tự Phase 00–08 cho bản core: kiến trúc, khởi tạo, Auth/Firestore, từ điển và nhập tay, Flashcard/Quiz/lịch ôn, dashboard, UI ảnh/contract, test, build/demo.
2. Sau cổng core mới làm Phase 09 OCR thật và Phase 10 AI thật, rồi Phase 11 nghiệm thu đầy đủ. Có thể đổi thứ tự 09/10 nếu ghi quyết định; cả hai phải xong trước khi gọi MVP hoàn chỉnh.
3. Trước OCR, nhập/dán văn bản thủ công; scanner nói rõ chưa cấu hình OCR. Mock/stub/contract test không phải bằng chứng OCR/AI thật. Bản core phải gắn nhãn core.
4. OCR có thể là service riêng. Dùng backend adapter/API contract; không hardcode endpoint/payload/model chưa chốt. Nếu service ngoài không cho truy cập pipeline, chỉ báo thực nghiệm quan sát được.
5. AI dùng API key qua backend, provider/model chọn ở Phase 10. Key không ở Flutter/Git/log. Dữ liệu từ điển có nguồn là chuẩn; AI có nhãn, validation/quota/fallback, không ghi đè từ điển.
6. Kiến trúc bắt buộc theo CR-002: một codebase Flutter/Dart phục vụ **cả Web và Android**; backend viết bằng **Python** (FastAPI/Pydantic theo kế hoạch). Không coi một nền tảng đã chạy là hoàn thành cả hai. Không thay công nghệ của từng thành phần khi chưa được người dùng quyết định.

## 3. Chất lượng và bằng chứng

1. Giữ Flutter/Dart/Riverpod cho **Web và Android**, Python/FastAPI/Pydantic cho backend, Firebase Auth/Firestore/Rules; thiết kế mở cho OCR service (PaddleOCR là lựa chọn gốc) và AI API. Đổi stack cần quyết định rõ của người dùng.
2. Rules giới hạn UID/field/type và test hai tài khoản. Không đưa secrets/service account/ảnh nhạy cảm vào Git; `.env.example` không có giá trị thật.
3. Một phase chính tại một thời điểm, chỉ chuyển khi DoD có bằng chứng trên cả Flutter Web và Flutter Android đối với chức năng người dùng, cùng backend Python chạy/test được đối với API. Thiếu service, key, thiết bị hoặc môi trường thì ghi `BLOCKED`/`NOT VERIFIED` và điều kiện gỡ chặn; không nhận đạt bằng mock.
4. Trước code nêu mục tiêu, file dự kiến, cách làm/test/rủi ro. Sau code cập nhật `plan.md` với file/lệnh/kết quả/blocker/bước tiếp theo và báo người dùng.
5. API đổi phải cập nhật contract/schema/client/test. Bug fix có kiểm tra hồi quy phù hợp. Xử lý loading/empty/error, offline, timeout/retry và quyền truy cập; giữ lớp UI/provider/repository/service.
6. OCR có ground truth, dev/test cố định, normalize định trước, raw predictions và metadata model/service/máy; báo CER/latency/cỡ mẫu thật dù không đạt mục tiêu. AI có rubric thủ công, không lấy model tự chấm làm kết luận.
7. **Sau mỗi task nhỏ hoàn thành:** tự kiểm tra thay đổi, chỉ `git add` các file thuộc task đó và tạo **một commit cục bộ** với thông điệp mô tả rõ (`feat`, `fix`, `test`, `docs`, v.v.). Không đưa file nhạy cảm, build output hoặc thay đổi của task khác vào commit. Nếu task chưa đạt tiêu chí hoặc không thể commit, ghi rõ lý do/blocker trong `plan.md` và xử lý trước khi nhận task hoàn thành. **Tuyệt đối không `git push`**; chỉ push khi người dùng yêu cầu rõ trong một lượt sau.
8. Quản lý task theo các issue trong `kanban_management.md` và GitHub Projects khi đã tạo; giữ mã `HL-xx-yy` ổn định. Khi yêu cầu mới đổi plan, cập nhật issue/tiêu chí/phụ thuộc/phase tương ứng trong backlog và trên Kanban trong cùng lượt. Không chuyển issue sang Done chỉ vì có commit; cần đạt tiêu chí và bằng chứng kiểm tra.

## 4. Cổng hiện tại

Người dùng đã xác nhận bắt đầu. Phase 00 đang triển khai trên branch `phase/00`; từng issue phải đạt tiêu chí và có đúng một commit cục bộ. Tiếp tục cập nhật plan, rule và backlog khi yêu cầu thay đổi; không push.
