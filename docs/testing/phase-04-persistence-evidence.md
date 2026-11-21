# Phase 04 — bằng chứng persistence học tập

Ngày kiểm tra: 2026-11-21  
Project: `hanlearn-7553f`  
Issue: `HL-04-05`

## Phạm vi

- Rules Emulator cho `review_schedule` và `quiz_results`.
- Deploy đúng file Rules đã test lên production.
- Flutter Web gọi repository thật: lưu hai từ, đánh giá hai Flashcard, hoàn thành Quiz, đăng xuất/đăng nhập lại.
- Đọc production bằng Firebase ID token của chính tài khoản test để đối chiếu dữ liệu; không dùng Admin SDK/bypass Rules.

Không lưu email, mật khẩu hoặc ID token kiểm thử trong repo. Tài khoản test có UID `hGKfxOdDvvd002eueCt1beglpug1`; chỉ chứa dữ liệu thử của dự án.

## Kết quả

| Kiểm tra | Kết quả |
|---|---|
| `dart format lib test` | PASS |
| `flutter analyze` | PASS, không warning |
| `flutter test` | PASS 19/19 |
| `npm --prefix firebase run test:rules` với Firestore Emulator | PASS 7/7 nhóm |
| `firebase deploy --only firestore:rules --project hanlearn-7553f --non-interactive` | PASS, compile và release thành công |
| Web lưu `朋友`, `学习`, đánh giá Flashcard rồi Quiz | PASS, UI không báo lỗi ghi |
| Logout/login và mở Saved Words | PASS, còn đúng hai từ |
| REST owner đọc `review_schedule` | PASS, 2 document; mỗi document `reviewCount=2`, interval lần lượt 1 và 2 ngày sau Flashcard + Quiz |
| REST owner đọc `quiz_results` | PASS, 1 document: score 2, total 2, answered 2, skipped 0 |

Rules chứng minh guest/UID khác không đọc hoặc tạo dữ liệu; schedule sai ID/type/interval/count bị từ chối; Quiz result sai score/skipped/word count bị từ chối; Quiz result là append-only và schedule không cho xóa.

## Ghi chú môi trường

Máy phát triển có HTTPS inspection nên Firebase CLI/Python verifier dùng CA cục bộ đã được người dùng cài (`NODE_EXTRA_CA_CERTS`/`REQUESTS_CA_BUNDLE`); CA không nằm trong repo. Đồng hồ Windows chậm khoảng sáu phút, nên backend test local dùng giới hạn clock skew tối đa 600 giây đã có trong Settings; mặc định production vẫn là 0 và host production phải đồng bộ giờ. Rules chỉ dung sai tối đa 10 phút cho `lastReviewedAt`, còn `updatedAt`/`createdAt` bắt buộc server timestamp.

Android và màn Today Review/Due Count được kiểm trong `HL-04-06`; bằng chứng này chỉ đóng persistence/repository của `HL-04-05`.
