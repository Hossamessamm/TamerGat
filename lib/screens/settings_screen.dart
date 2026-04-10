import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tamergat_app/services/app_config_service.dart';

import '../utils/app_theme.dart';
import 'legal_document_screen.dart';
import 'profile_screen.dart';

/// Hub with four actions that open full-screen pages.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Floating pill nav on home sits ~88px + safe area; keep tiles scrollable above it.
    final navClearance = 88.0 + bottomInset;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Text(
            'Settings',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + navClearance),
          children: [
            Text(
              'Account & policies',
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.person_rounded,
              iconBg: const Color(0xFFE0E7FF),
              iconColor: const Color(0xFF4F46E5),
              title: 'My profile',
              subtitle: 'Your details & contact',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),
            Consumer<AppConfigService>(
              builder: (context, appConfig, _) {
                if (appConfig.isInReviewVersionEqual()) {
                  return const SizedBox();
                }
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    _SettingsTile(
                      icon: Icons.currency_exchange_rounded,
                      iconBg: const Color(0xFFFFEDD5),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Refund policy',
                      subtitle: 'سياسة الاسترجاع — refunds & eligibility',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LegalDocumentScreen(
                              title: 'Refund policy',
                              assetPath: 'assets/legal/refund_policy.txt',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.shield_outlined,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF16A34A),
              title: 'Privacy policy',
              subtitle: 'سياسة الخصوصية — how we use your data',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalDocumentScreen(
                      title: 'Privacy policy',
                      assetPath: 'assets/legal/privacy_policy.txt',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.article_outlined,
              iconBg: const Color(0xFFE0F2FE),
              iconColor: const Color(0xFF0284C7),
              title: 'Terms & conditions',
              subtitle: 'الشروط والأحكام — usage & responsibilities',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalDocumentScreen(
                      title: 'Terms & conditions',
                      assetPath: 'assets/legal/terms_and_conditions.txt',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: const Color(0xFF0A1628).withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        onTap: onTap,
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        title: Text(
          title,
          style: GoogleFonts.notoSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              height: 1.35,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textSecondary.withValues(alpha: 0.85),
          size: 28,
        ),
      ),
    );
  }
}
