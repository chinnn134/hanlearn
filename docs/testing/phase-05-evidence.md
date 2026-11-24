# Phase 05 — bằng chứng Dashboard và UX core

Ngày kiểm tra: 2026-11-21

Firebase project: `hanlearn-7553f`

## Phạm vi nghiệm thu

- Dashboard tổng hợp Saved Words, từ đã học, từ đến hạn, Quiz gần đây và lịch sử ôn.
- Profile/Settings hiển thị đúng phiên đăng nhập, UID sở hữu dữ liệu và trạng thái cấu hình core/OCR/AI.
- UX responsive, vùng chạm tối thiểu, xác nhận trước khi bỏ lưu và trạng thái loading/empty/error/retry.
- Metadata Firestore phân biệt dữ liệu server với cache/offline; truy vấn có giới hạn và không listener nền.

## Kết quả production

### Flutter Web

- Bản Web release chạy trên `http://localhost:3000` với Firebase production.
- Phiên Web production hiện có hiển thị Dashboard empty hợp lệ: 0 từ lưu, 0 từ học, 0 đến hạn, chưa có Quiz/lịch sử; nhãn “Đã đồng bộ từ máy chủ”.
- Profile tải đúng tài khoản và tên đã đồng bộ từ Phase 02; Settings/route đã được kiểm tra bằng widget test.
- Khi smoke test tra từ bằng phiên cũ, backend trả 401 do ID token hết hạn. Client đã được sửa để force-refresh token đúng một lần sau 401 và có unit test. Web release được build lại sau sửa.
- Tab đang chạy bị service worker giữ bundle cũ nên không dùng phiên đó làm bằng chứng live cho retry mới; không xóa site data vì việc đó sẽ xóa phiên đăng nhập. Bản sửa được chứng minh bằng unit test và artifact build, cần smoke lại trên phiên/bản deploy sạch ở Phase 07/08.

### Flutter Android

- Android debug APK build, cài và chạy trên Android 15 AVD `HanLearn_API35_D`.
- Tài khoản production đã dùng ở Phase 04 vẫn còn nguyên dữ liệu: 2 từ đã lưu, 2 từ đã học, 0 từ đến hạn; hai Quiz gần đây đều 2/2; hai lịch ôn đều có 3 lượt.
- Khi bật airplane mode và mở lại app, Dashboard đọc cache và hiện “Dữ liệu lưu cục bộ”, không nhận nhầm là đã đồng bộ.
- Sau khi tắt airplane mode và mở lại, Dashboard trở về “Đã đồng bộ từ máy chủ”. Airplane mode đã được khôi phục trước khi kết thúc kiểm thử.
- Settings hiển thị đúng UID của tài khoản Phase 04 và ghi rõ backend đã cấu hình, OCR/AI chưa tích hợp.

## Kiểm tra tự động và build

| Kiểm tra | Kết quả |
|---|---|
| `dart format` và `flutter analyze` | Đạt, không có lỗi phân tích |
| Flutter unit/widget tests | 26/26 đạt, gồm Dashboard, cache metadata, responsive 320px/text scale 1.5, xác nhận bỏ lưu và token refresh sau 401 |
| Flutter Web release build | Đạt với `API_BASE_URL=http://127.0.0.1:8000` |
| Flutter Android debug build | Đạt với `API_BASE_URL=http://10.0.2.2:8000` |
| Backend Ruff | Format/check đạt |
| Backend pytest | 17/17 đạt; một cảnh báo deprecation từ Starlette |
| Firestore Rules Emulator | 7/7 nhóm đạt |

## Đối chiếu DoD cộng dồn

- Nhập tay → tra → lưu/bỏ lưu production Web/Android: `docs/testing/phase-03-production-evidence.md`.
- Flashcard → Quiz → lịch ôn và persistence production: `docs/testing/phase-04-evidence.md`.
- Dashboard/UX/offline production: tài liệu này.

Phase 05 đạt DoD bản core chức năng trên hai target. Việc smoke lại token retry trên bundle Web sạch được giữ thành kiểm tra hồi quy Phase 07/08; không ảnh hưởng Dashboard/Firestore nhưng không được bỏ khỏi test report core.
