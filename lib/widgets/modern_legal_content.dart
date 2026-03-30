import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';

/// Parses plain-text legal assets into structured, readable blocks.
List<Widget> buildModernLegalContent(String raw) {
  final lines = raw.split('\n');
  final widgets = <Widget>[];
  var i = 0;

  while (i < lines.length) {
    final line = lines[i];
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      i++;
      continue;
    }

    if (_isSeparatorLine(trimmed)) {
      i++;
      continue;
    }

    if (trimmed == 'العربية' || trimmed == 'English') {
      widgets.add(_LanguageBanner(trimmed));
      i++;
      continue;
    }

    if (RegExp(r'^\d+\.\s').hasMatch(trimmed) ||
        RegExp(r'^SECTION\s+\d+', caseSensitive: false).hasMatch(trimmed)) {
      final title = trimmed;
      i++;
      final body = StringBuffer();
      while (i < lines.length) {
        final l = lines[i];
        final t = l.trim();
        if (t.isEmpty) {
          i++;
          if (body.isNotEmpty) break;
          continue;
        }
        if (_isSeparatorLine(l)) break;
        if (RegExp(r'^\d+\.\s').hasMatch(t)) break;
        if (t == 'العربية' || t == 'English') break;
        if (RegExp(r'^SECTION\s+\d+', caseSensitive: false).hasMatch(t)) break;
        body.writeln(l);
        i++;
      }
      widgets.add(_ModernSectionCard(title: title, body: body.toString().trim()));
      continue;
    }

    if (RegExp(r'^SECTION\s', caseSensitive: false).hasMatch(trimmed)) {
      final title = trimmed;
      i++;
      final body = StringBuffer();
      while (i < lines.length) {
        final l = lines[i];
        final t = l.trim();
        if (t.isEmpty) {
          i++;
          if (body.isNotEmpty) break;
          continue;
        }
        if (_isSeparatorLine(l)) break;
        if (RegExp(r'^\d+\.\s').hasMatch(t)) break;
        if (RegExp(r'^SECTION\s', caseSensitive: false).hasMatch(t)) break;
        body.writeln(l);
        i++;
      }
      widgets.add(_ModernSectionCard(title: title, body: body.toString().trim()));
      continue;
    }

    final buf = StringBuffer();
    while (i < lines.length) {
      final l = lines[i];
      final t = l.trim();
      if (t.isEmpty) {
        i++;
        break;
      }
      if (_isSeparatorLine(l)) break;
      if (t == 'العربية' || t == 'English') break;
      if (RegExp(r'^\d+\.\s').hasMatch(t)) break;
      if (RegExp(r'^SECTION\s', caseSensitive: false).hasMatch(t)) break;
      buf.writeln(l);
      i++;
    }
    final text = buf.toString().trim();
    if (text.isNotEmpty) {
      widgets.add(_IntroOrParagraphCard(text));
    }
  }

  if (widgets.isEmpty) {
    return [
      SelectableText(
        raw,
        style: GoogleFonts.notoSans(
          fontSize: 15,
          height: 1.55,
          color: AppTheme.textPrimary,
        ),
      ),
    ];
  }

  return widgets;
}

bool _isSeparatorLine(String line) {
  if (line.isEmpty) return false;
  return line.replaceAll('═', '').replaceAll('=', '').trim().isEmpty;
}

class _LanguageBanner extends StatelessWidget {
  final String label;

  const _LanguageBanner(this.label);

  @override
  Widget build(BuildContext context) {
    final isAr = label == 'العربية';
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAr
                    ? [const Color(0xFF0A1628), const Color(0xFF1E3A5F)]
                    : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAr ? Icons.translate_rounded : Icons.language_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSectionCard extends StatelessWidget {
  final String title;
  final String body;

  const _ModernSectionCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A1628).withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectableText(
                          title,
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: SelectableText(
                    body,
                    style: GoogleFonts.notoSans(
                      fontSize: 15,
                      height: 1.65,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroOrParagraphCard extends StatelessWidget {
  final String text;

  const _IntroOrParagraphCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.6)),
        ),
        child: SelectableText(
          text,
          style: GoogleFonts.notoSans(
            fontSize: 15,
            height: 1.65,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
