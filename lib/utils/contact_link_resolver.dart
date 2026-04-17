import 'package:flutter/material.dart';

/// How the UI should open this contact value.
enum ContactOpenMethod {
  /// Plain phone / digits — use WhatsApp deep link with [value].
  whatsAppPhone,

  /// Open [value] as a URL in an external browser / app.
  externalUrl,
}

/// Visual + open behavior for a single contact row, inferred from the raw string
/// (URL host, path, or phone) so icons match the actual destination.
class ContactLinkResolved {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final ContactOpenMethod openMethod;

  const ContactLinkResolved({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.openMethod,
  });
}

Uri normalizeContactUri(String raw) {
  final t = raw.trim();
  if (t.isEmpty) throw ArgumentError('empty');
  if (t.startsWith('http://') || t.startsWith('https://')) {
    return Uri.parse(t);
  }
  return Uri.parse('https://$t');
}

bool _looksLikePhoneOnly(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return false;
  if (t.contains('://')) return false;
  // Avoid treating host-like strings as phones (e.g. "example.com").
  if (RegExp(r'[a-zA-Z]{2,}\.[a-zA-Z]{2,}').hasMatch(t)) return false;
  final digits = t.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 8;
}

ContactLinkResolved? resolveContactLink(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  if (_looksLikePhoneOnly(trimmed)) {
    return ContactLinkResolved(
      label: 'WhatsApp',
      value: trimmed,
      icon: Icons.chat_rounded,
      iconBg: const Color(0xFFDCFCE7),
      iconColor: const Color(0xFF16A34A),
      openMethod: ContactOpenMethod.whatsAppPhone,
    );
  }

  late final Uri uri;
  try {
    uri = normalizeContactUri(trimmed);
  } catch (_) {
    return ContactLinkResolved(
      label: 'Link',
      value: trimmed,
      icon: Icons.link_rounded,
      iconBg: const Color(0xFFF1F5F9),
      iconColor: const Color(0xFF475569),
      openMethod: ContactOpenMethod.externalUrl,
    );
  }

  final host = uri.host.toLowerCase();

  if (host.contains('wa.me') || host.contains('whatsapp')) {
    return ContactLinkResolved(
      label: 'WhatsApp',
      value: trimmed,
      icon: Icons.chat_rounded,
      iconBg: const Color(0xFFDCFCE7),
      iconColor: const Color(0xFF16A34A),
      openMethod: ContactOpenMethod.externalUrl,
    );
  }

  if (host == 't.me' || host.contains('telegram.')) {
    return ContactLinkResolved(
      label: 'Telegram',
      value: trimmed,
      icon: Icons.send_rounded,
      iconBg: const Color(0xFFE0F2FE),
      iconColor: const Color(0xFF0284C7),
      openMethod: ContactOpenMethod.externalUrl,
    );
  }

  if (host.contains('facebook.') || host.contains('fb.com') || host == 'fb.watch') {
    return ContactLinkResolved(
      label: 'Facebook',
      value: trimmed,
      icon: Icons.facebook,
      iconBg: const Color(0xFFE0E7FF),
      iconColor: const Color(0xFF4F46E5),
      openMethod: ContactOpenMethod.externalUrl,
    );
  }

  if (host.contains('instagram.com')) {
    return ContactLinkResolved(
      label: 'Instagram',
      value: trimmed,
      icon: Icons.camera_alt_outlined,
      iconBg: const Color(0xFFFCE7F3),
      iconColor: const Color(0xFFC026D3),
      openMethod: ContactOpenMethod.externalUrl,
    );
  }

  if (host.contains('youtube.') || host.contains('youtu.be')) {
    return ContactLinkResolved(
      label: 'YouTube',
      value: trimmed,
      icon: Icons.play_circle_filled_rounded,
      iconBg: const Color(0xFFFFEDD5),
      iconColor: const Color(0xFFEA580C),
      openMethod: ContactOpenMethod.externalUrl,
    );
  }

  if (host.contains('tiktok.com')) {
    return ContactLinkResolved(
      label: 'TikTok',
      value: trimmed,
      icon: Icons.music_note_rounded,
      iconBg: const Color(0xFFFCE7F3),
      iconColor: const Color(0xFFDB2777),
      openMethod: ContactOpenMethod.externalUrl,
    );
  }

  if (host.contains('twitter.com') || host == 'x.com' || host == 'www.x.com') {
    return ContactLinkResolved(
      label: 'X',
      value: trimmed,
      icon: Icons.tag,
      iconBg: const Color(0xFFE5E7EB),
      iconColor: const Color(0xFF111827),
      openMethod: ContactOpenMethod.externalUrl,
    );
  }

  if (host.contains('linkedin.com')) {
    return ContactLinkResolved(
      label: 'LinkedIn',
      value: trimmed,
      icon: Icons.work_outline_rounded,
      iconBg: const Color(0xFFE0F2FE),
      iconColor: const Color(0xFF0A66C2),
      openMethod: ContactOpenMethod.externalUrl,
    );
  }

  return ContactLinkResolved(
    label: 'Link',
    value: trimmed,
    icon: Icons.link_rounded,
    iconBg: const Color(0xFFF1F5F9),
    iconColor: const Color(0xFF475569),
    openMethod: ContactOpenMethod.externalUrl,
  );
}
