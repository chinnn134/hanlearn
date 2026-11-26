# HanLearn core test report

Ngày chốt: 2026-11-22 (Asia/Saigon) · Branch `phase/07` · Issue `HL-07-05`

## Kết luận

**Phase 07 PASS.** Core E2E đã chạy trên Flutter Web và Flutter Android cùng backend
Python/FastAPI và Firebase Emulator. Không còn P0 core/security mở. Hai lỗi tìm thấy
trong Android E2E đã sửa và kiểm chứng lại: Auth Emulator cleartext chỉ được phép ở
debug source set; lỗi mạng không còn lộ `SocketException`/backend URL.

OCR thật và AI thật: **NOT VERIFIED — chưa tích hợp**. Provider mặc định vẫn trả
`503 SERVICE_NOT_CONFIGURED`; không có kết quả CER, latency OCR hay rubric AI ở Phase 07.

## Kết quả gate cuối

| Gate | Kết quả | Bằng chứng |
|---|---|---|
| Dart format | PASS · 34 file, 0 đổi | `dart format --output=none --set-exit-if-changed lib test` |
| Flutter analyze | PASS · 0 issue | Flutter 3.47.9 |
| Flutter tests | PASS · 33/33 | Auth race, API 401, network sanitization, UI/core E2E |
| Web release build | PASS | Firebase Emulator; API `127.0.0.1:8000` |
| Android debug APK | PASS · build/cài/chạy API 35 | Firebase Emulator; API `10.0.2.2:8000` |
| Ruff format/lint | PASS | 24 Python files formatted; lint sạch |
| Backend pytest | PASS · 30/30 | một deprecation warning Starlette/httpx, không làm sai kết quả |
| Python dependency check | PASS | không có dependency hỏng |
| Firestore Rules | PASS · 7/7 | owner, UID khác, guest, schema/timestamp |
| Secret/log/CORS audit | PASS | `security-audit-phase-07.md` |

Lần gate đầu gặp ổ C chỉ còn khoảng 300 MiB, Flutter không copy được file `.dill` tạm.
Đây là lỗi môi trường, không phải assertion. Chạy lại với `TEMP`/`TMP` task riêng trên
ổ D cho kết quả 33/33 và cả hai build PASS.

## E2E matrix

| Bề mặt | Luồng | Kết quả |
|---|---|---|
| Web release / Chromium | login → tra/lưu 2 từ → Flashcard → Quiz 1/2 → Dashboard → logout/login | PASS; 2 saved, 2 learned, 0 due, Quiz 1/2 tồn tại |
| Android 15/API 35 | login → tra `xue` → saved → Flashcard 2/2 → Quiz 1/2 → Dashboard → logout/login | PASS; cùng dữ liệu Firestore |
| Android network | airplane mode → search error → bật mạng → retry | PASS; thông báo thân thiện, phục hồi không restart |
| Android Scanner | gallery/camera UI, giới hạn ảnh, nhập tay | PASS; ghi rõ OCR chưa cấu hình, không upload/nhận dạng giả |
| Rules two-account | owner/other/guest, saved/review/quiz/vocabulary | PASS 7/7; cross-user bị từ chối |

Web E2E live dùng Chromium tích hợp với release bundle. `flutter test --platform chrome`
trên máy này treo ở `loading` kể cả test nhỏ và không được tính PASS. Chrome 157 được
Flutter nhận diện; Phase 08 vẫn phải smoke release bundle trên Chrome sạch như một
release gate riêng.

## Đối chiếu acceptance core

| ID | Trạng thái Phase 07 | Ghi chú |
|---|---|---|
| AC-C01 | PASS cộng dồn | một Flutter codebase build Web/Android; FastAPI health đã kiểm từ Phase 01 |
| AC-C02–C03 | PASS cộng dồn | Auth/profile persistence và Rules hai UID/guest |
| AC-C04–C05 | PASS | tra có nguồn, lưu/idempotent/sync/relogin |
| AC-C06–C07 | PASS | Flashcard, Quiz, scheduler và persistence |
| AC-C08 | PASS | Dashboard dữ liệu thật, server/cache label |
| AC-C09 | PASS core UI | Web file; Android camera/gallery; OCR chưa cấu hình đúng |
| AC-C10 | PASS | E2E hai target, network không crash, không còn P0 |
| AC-C11 | NOT EVALUATED | thuộc Phase 08 build/demo/bàn giao core |

## Defect log

| Mã | Mức | Hiện tượng | Xử lý | Trạng thái |
|---|---|---|---|---|
| D-07-01 | P0 local E2E blocker | Android chặn HTTP Auth Emulator | thêm debug-only `base-config cleartextTrafficPermitted`; main/release không đổi | CLOSED |
| D-07-02 | P1 UX/info disclosure | UI hiển thị raw SocketException và backend URL | repository map lỗi mạng; UI chỉ hiện message đã kiểm soát; regression test | CLOSED |
| D-07-03 | Tooling | Chrome platform runner treo `loading` | không nhận PASS; dùng live Chromium + VM widget E2E; smoke Chrome lại Phase 08 | OPEN, không phải P0 sản phẩm |
| D-07-04 | Environment | ổ C thiếu chỗ cho Flutter temp | chuyển TEMP/TMP task sang ổ D và rerun PASS | CLOSED |

## Quyết định gate

Phase 07 đạt DoD: core E2E pass trên Web/Android, Rules/security pass, không còn P0
core. Cho phép fast-forward `phase/07` vào `main` cục bộ sau commit HL-07-05 và mở
`phase/08`. Không push. Phase 08 phải smoke bản build Chrome/APK sạch và hoàn thiện
README/changelog/demo core; không được gọi bản core là MVP hoàn chỉnh trước Phase 09–11.

