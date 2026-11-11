/// Hiển thị biểu thức Topi cho gia sư đọc.
///
/// Topi trả đề và đáp án theo cú pháp sympy (`(x - 4)**2`, `3*x`) để backend
/// kiểm tra được đáp án. Gia sư cần đọc như trong vở: `(x - 4)²`, `3x`. Chỉ
/// dùng để hiển thị — dữ liệu gốc giữ nguyên.
library;

const Map<String, String> _superscript = {
  '0': '⁰',
  '1': '¹',
  '2': '²',
  '3': '³',
  '4': '⁴',
  '5': '⁵',
  '6': '⁶',
  '7': '⁷',
  '8': '⁸',
  '9': '⁹',
  '-': '⁻',
};

// `**2`, `^2`, `** -1` → số mũ viết trên.
final RegExp _power = RegExp(r'\s*(?:\*\*|\^)\s*(-?\d+)');

// Dấu nhân trước chữ hoặc ngoặc mở thì bỏ: `2*x` → `2x`, `)*(` → `)(`.
final RegExp _impliedTimes = RegExp(
  r'([0-9A-Za-z)²³¹⁰-⁹])\s*\*\s*(?=[A-Za-z(])',
);

// Dấu nhân còn lại (giữa hai số) → `·`.
final RegExp _times = RegExp(r'\s*\*\s*');

// Topi đôi khi tự viết "Hỏi:" ở đầu câu, trong khi màn đã có nhãn "Hỏi:".
final RegExp _askPrefix = RegExp(r'^\s*hỏi\s*:\s*', caseSensitive: false);

/// `(x - 4)**2` → `(x - 4)²`; `(3*x - 2)*(3*x + 2)` → `(3x - 2)(3x + 2)`;
/// `3 * 2**3` → `3 · 2³`.
String topiMathText(String s) {
  var t = s.replaceAllMapped(
    _power,
    (m) => m[1]!.split('').map((c) => _superscript[c]!).join(),
  );
  t = t.replaceAllMapped(_impliedTimes, (m) => m[1]!);
  return t.replaceAll(_times, ' · ');
}

/// Câu hỏi để gia sư đọc: bỏ "Hỏi:" trùng ở đầu, viết biểu thức như trong vở.
String topiAskText(String s) => topiMathText(s.replaceFirst(_askPrefix, ''));
