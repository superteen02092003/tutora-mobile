import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';

class SolutionMarkdown extends StatelessWidget {
  const SolutionMarkdown({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  List<String> _reflowMath(List<String> lines) {
    final out = <String>[];
    var pending = '';
    for (final line in lines) {
      final merged = pending.isEmpty ? line : '$pending $line';
      final dollarCount = r'$'.allMatches(merged).length;
      if (dollarCount.isOdd) {
        pending = merged;
      } else {
        out.add(merged);
        pending = '';
      }
    }
    if (pending.isNotEmpty) out.add(pending);
    return out;
  }

  List<Widget> _parseBlocks(String raw) {
    final widgets = <Widget>[];
    final lines = _reflowMath(raw.split('\n'));
    final quoteBuffer = <String>[];

    void flushQuote() {
      if (quoteBuffer.isEmpty) return;
      widgets.add(_TipCard(text: quoteBuffer.join('\n')));
      quoteBuffer.clear();
    }

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();

      // Blockquote "> ..." → gom vào card Mẹo.
      if (trimmed.startsWith('>')) {
        quoteBuffer.add(trimmed.replaceFirst(RegExp(r'^>\s?'), ''));
        continue;
      }
      flushQuote();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Đường kẻ ngang "---" / "***" → divider mảnh.
      if (RegExp(r'^([-*_])\1{2,}$').hasMatch(trimmed)) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 0.5, color: AppColors.line2),
          ),
        );
        continue;
      }

      // Công thức đứng riêng: $$...$$
      if (trimmed.startsWith(r'$$') &&
          trimmed.endsWith(r'$$') &&
          trimmed.length > 4) {
        widgets.add(
          _DisplayMath(expr: trimmed.substring(2, trimmed.length - 2)),
        );
        continue;
      }

      // Bullet: "- " hoặc "* "
      final bullet = RegExp(r'^[-*]\s+(.*)').firstMatch(trimmed);
      if (bullet != null) {
        widgets.add(_Bullet(text: bullet.group(1)!));
        continue;
      }

      // Markdown heading "#", "##", "###" → strip ký hiệu, render như heading.
      final atxHeading = RegExp(r'^#{1,6}\s+(.*)').firstMatch(trimmed);
      if (atxHeading != null) {
        widgets.add(_Heading(text: atxHeading.group(1)!));
        continue;
      }

      // "**Đáp án: ...**" → dòng đáp án nổi bật (đầu lời giải, kiểu Gauth).
      if (RegExp(r'^\*\*Đáp án[:：]').hasMatch(trimmed)) {
        widgets.add(_AnswerLine(text: trimmed));
        continue;
      }

      // "**Bước N: ...**" / "**Kết quả...**" → dòng nhấn mạnh (heading).
      final isStepHeading = RegExp(
        r'^\*\*(Bước\s*\d+|Kết quả).*',
      ).hasMatch(trimmed);
      if (isStepHeading) {
        widgets.add(_Heading(text: trimmed));
        continue;
      }

      // Đoạn văn thường (có thể chứa bold + inline math).
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _InlineRich(text: trimmed),
        ),
      );
    }
    flushQuote();
    return widgets;
  }
}

// Heading bước / kết quả
class _Heading extends StatelessWidget {
  const _Heading({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: _InlineRich(
        text: text,
        baseStyle: GoogleFonts.inter(
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

// Banner đáp án (đầu lời giải, kiểu Gauth)
class _AnswerLine extends StatelessWidget {
  const _AnswerLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 2),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.oxblood.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.oxblood, width: 3),
        ),
      ),
      child: _InlineRich(
        text: text,
        baseStyle: GoogleFonts.inter(
          fontSize: 16.5,
          height: 1.45,
          fontWeight: FontWeight.w800,
          color: AppColors.oxblood,
        ),
      ),
    );
  }
}

// Bullet
class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 10, left: 2),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(child: _InlineRich(text: text)),
        ],
      ),
    );
  }
}

// Card "Mẹo nhanh" (blockquote)
class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.gold, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Mẹo nhanh',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _InlineRich(text: text),
        ],
      ),
    );
  }
}

// Công thức đứng riêng, canh giữa, cuộn ngang nếu dài
class _DisplayMath extends StatelessWidget {
  const _DisplayMath({required this.expr});
  final String expr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(
            expr.trim(),
            textStyle: GoogleFonts.inter(fontSize: 17, color: AppColors.ink),
            onErrorFallback: (_) => Text(expr, style: _mono),
          ),
        ),
      ),
    );
  }

  static final TextStyle _mono = GoogleFonts.robotoMono(
    fontSize: 14,
    color: AppColors.ink2,
  );
}

// Dòng inline: **bold** + $inline math$
class _InlineRich extends StatelessWidget {
  const _InlineRich({required this.text, this.baseStyle});
  final String text;
  final TextStyle? baseStyle;

  static final _emphRe = RegExp(
    r'\*\*(.+?)\*\*|\*(\S(?:.*?\S)?)\*',
    dotAll: true,
  );
  static final _mathRe = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$', dotAll: true);

  @override
  Widget build(BuildContext context) {
    final style =
        baseStyle ??
        GoogleFonts.inter(fontSize: 15.5, height: 1.55, color: AppColors.ink2);
    final boldStyle = style.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    );
    final italicStyle = style.copyWith(fontStyle: FontStyle.italic);

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in _emphRe.allMatches(text)) {
      if (m.start > cursor) {
        spans.addAll(_mathAware(text.substring(cursor, m.start), style));
      }
      final bold = m.group(1);
      final italic = m.group(2);
      if (bold != null) {
        spans.addAll(_mathAware(bold, boldStyle));
      } else if (italic != null) {
        spans.addAll(_mathAware(italic, italicStyle));
      }
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.addAll(_mathAware(text.substring(cursor), style));
    }

    return Text.rich(TextSpan(children: spans));
  }

  // Chuyển 1 đoạn text thành spans, render $...$ / $$...$$ thành công thức.
  List<InlineSpan> _mathAware(String segment, TextStyle style) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in _mathRe.allMatches(segment)) {
      if (m.start > cursor) {
        spans.add(
          TextSpan(text: segment.substring(cursor, m.start), style: style),
        );
      }
      final expr = (m.group(1) ?? m.group(2) ?? '').trim();
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(
            expr,
            textStyle: style.copyWith(color: AppColors.ink),
            onErrorFallback: (_) => Text(expr, style: style),
          ),
        ),
      );
      cursor = m.end;
    }
    if (cursor < segment.length) {
      spans.add(TextSpan(text: segment.substring(cursor), style: style));
    }
    return spans;
  }
}
