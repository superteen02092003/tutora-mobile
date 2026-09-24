/// Nội dung đồng ý ghi âm gia sư đưa phụ huynh đọc trước khi ghi buổi đầu.
///
/// Đổi nội dung thì tăng [consentTextVersion] — backend lưu phiên bản vào
/// `recorder.students.consent_version` và chặn ghi âm với phiên bản cũ.
/// Số phiên bản chỉ dùng nội bộ, không hiện trong nội dung app.
///
/// v2 (2026-09-24): thời hạn xoá bản ghi 180 → 90 ngày.
const String consentTextVersion = 'v2';

const String consentTextTitle = 'Đồng ý ghi âm buổi học';

const String consentTextBody =
    'Gia sư sẽ ghi âm các buổi học của con bằng ứng dụng Tutora. Bản ghi được '
    'xử lý bằng AI (Google Gemini) để tạo báo cáo ngắn về nội dung, bài tập và '
    'nhận xét; gia sư kiểm tra trước khi gửi. Báo cáo được gửi qua Zalo tới số '
    'điện thoại của phụ huynh. File ghi âm được lưu riêng tư, gia sư không nghe '
    'lại được, chỉ Tutora dùng khi cần xử lý khiếu nại, và tự động xoá sau 90 '
    'ngày. Phụ huynh có thể rút lại đồng ý bất cứ lúc nào qua gia sư hoặc tại '
    'tutora.vn/policies/data-deletion. Chi tiết: tutora.vn/policies/privacy-app';
