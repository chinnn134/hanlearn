# HanLearn AI

HanLearn AI được xây dựng từ **một codebase Flutter cho Web và Android** cùng **backend Python/FastAPI**. Firebase Authentication và Firestore quản lý đăng nhập và dữ liệu học đồng bộ. Các chức năng học tập core được hoàn thành trước; OCR và AI tích hợp ở các phase cuối.

Hiện trạng: **Phase 01 đang thực hiện**. Flutter app và backend chưa được khởi tạo. README này là điểm vào repo; lệnh setup/run đã kiểm chứng sẽ được bổ sung ở `HL-01-06`.

## Tài liệu dự án

- [Kế hoạch](plan.md) và [quy tắc](rule.md)
- [Backlog Kanban](kanban_management.md)
- [Yêu cầu sản phẩm](docs/requirements/product-requirements.md)
- [Kiến trúc hệ thống](docs/architecture/system-architecture.md)
- [Hợp đồng API](docs/api/openapi-contract.md)
- [Tiêu chí nghiệm thu](docs/testing/acceptance-criteria.md)

## Cấu trúc dự kiến

```text
apps/flutter_app/  Flutter Web và Android
backend/           Python/FastAPI
docs/              Yêu cầu, kiến trúc, API và kiểm thử
firebase/          Firestore Rules và indexes (Phase 02)
ai/                Dataset và đánh giá OCR (Phase 09)
```

Cấu hình local có mẫu trong `.env.example`; chỉ giá trị không nhạy cảm được đưa vào Git. Mỗi phase có branch cục bộ `phase/xx`, mỗi issue có một commit cục bộ mang mã `[HL-xx-yy]`. Không push nếu người dùng chưa yêu cầu rõ.
