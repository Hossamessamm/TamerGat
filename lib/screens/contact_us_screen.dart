import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/contact_model.dart';
import '../services/contact_service.dart';
import '../utils/app_theme.dart';
import '../utils/contact_link_resolver.dart';

/// Loads official contact channels from [GET /api/Contact/getAll].
class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  late Future<ContactResponse?> _future;

  @override
  void initState() {
    super.initState();
    _future = ContactService.getAllContacts();
  }

  Future<void> _retry() async {
    setState(() {
      _future = ContactService.getAllContacts();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Contact us',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<ContactResponse?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _ErrorBody(
                message: snapshot.hasError
                    ? snapshot.error.toString()
                    : 'Could not load contact information.',
                onRetry: _retry,
              );
            }
            final response = snapshot.data!;
            if (!response.success || response.contacts.isEmpty) {
              return _ErrorBody(
                message: response.message ?? 'No contact channels are available yet.',
                onRetry: _retry,
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _future = ContactService.getAllContacts();
                });
                await _future;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  Text(
                    'Reach us through the channels below. Information is loaded from our server.',
                    style: GoogleFonts.notoSans(
                      fontSize: 15,
                      height: 1.45,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...response.contacts.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ContactCard(contact: c),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 15,
                height: 1.45,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Contact contact;

  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final channels = <_Channel>[];
    for (final raw in <String?>[
      contact.whatsAppNumber,
      contact.facebookPage,
      contact.youTubeChannel,
      contact.tiktokChannel,
    ]) {
      if (raw == null || raw.trim().isEmpty) continue;
      final resolved = resolveContactLink(raw.trim());
      if (resolved == null) continue;
      channels.add(
        _Channel(
          label: resolved.label,
          value: resolved.value,
          icon: resolved.icon,
          iconBg: resolved.iconBg,
          iconColor: resolved.iconColor,
          onOpen: () async {
            if (resolved.openMethod == ContactOpenMethod.whatsAppPhone) {
              await _openWhatsApp(resolved.value);
            } else {
              await _openWebUrl(resolved.value);
            }
          },
        ),
      );
    }

    if (channels.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppTheme.dividerColor.withValues(alpha: 0.6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'No channels listed for this entry.',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shadowColor: const Color(0xFF0A1628).withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppTheme.dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < channels.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: AppTheme.dividerColor.withValues(alpha: 0.5)),
            _ChannelTile(channel: channels[i]),
          ],
        ],
      ),
    );
  }

  static Future<void> _openWhatsApp(String raw) async {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final text = Uri.encodeComponent('Hello, I would like to contact TamerGAT');
    final appUri = Uri.parse('whatsapp://send?phone=$digits&text=$text');
    final webUri = Uri.parse('https://wa.me/$digits?text=$text');
    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> _openWebUrl(String raw) async {
    try {
      final uri = normalizeContactUri(raw);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class _Channel {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Future<void> Function() onOpen;

  _Channel({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onOpen,
  });
}

class _ChannelTile extends StatelessWidget {
  final _Channel channel;

  const _ChannelTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => channel.onOpen(),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: channel.iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(channel.icon, color: channel.iconColor, size: 26),
      ),
      title: Text(
        channel.label,
        style: GoogleFonts.notoSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          channel.value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.notoSans(
            fontSize: 13,
            height: 1.35,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
      trailing: Icon(
        Icons.open_in_new_rounded,
        color: AppTheme.textSecondary.withValues(alpha: 0.85),
        size: 22,
      ),
    );
  }
}
