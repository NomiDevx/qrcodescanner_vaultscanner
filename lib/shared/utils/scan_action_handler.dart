import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/scanner/domain/scan_result_model.dart';

/// Detects the scan type from raw barcode/QR content.
ScanType detectScanType(String raw) {
  final lower = raw.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return ScanType.url;
  }
  if (lower.startsWith('tel:')) return ScanType.phone;
  if (lower.startsWith('mailto:')) return ScanType.email;
  if (lower.startsWith('smsto:') || lower.startsWith('sms:')) return ScanType.sms;
  if (raw.startsWith('WIFI:') || lower.startsWith('wifi:')) return ScanType.wifi;
  if (raw.startsWith('BEGIN:VCARD') || raw.startsWith('BEGIN:MECARD')) {
    return ScanType.vcard;
  }
  if (lower.startsWith('geo:')) return ScanType.geo;
  return ScanType.text;
}

/// Parsed WiFi network credentials.
class WifiCredentials {
  final String ssid;
  final String password;
  final String security;

  const WifiCredentials({
    required this.ssid,
    required this.password,
    required this.security,
  });
}

/// Parses WiFi QR format: WIFI:T:WPA;S:MyNetwork;P:mypassword;;
WifiCredentials parseWifi(String raw) {
  String extract(String key) {
    final regex = RegExp('$key:([^;]*)');
    final match = regex.firstMatch(raw);
    return match?.group(1) ?? '';
  }

  return WifiCredentials(
    ssid: extract('S'),
    password: extract('P'),
    security: extract('T'),
  );
}

/// Returns the display label for a scan type.
String scanTypeLabel(ScanType type) {
  switch (type) {
    case ScanType.url:
      return 'URL';
    case ScanType.phone:
      return 'Phone';
    case ScanType.email:
      return 'Email';
    case ScanType.sms:
      return 'SMS';
    case ScanType.wifi:
      return 'WiFi';
    case ScanType.vcard:
      return 'Contact';
    case ScanType.geo:
      return 'Location';
    case ScanType.text:
      return 'Text';
  }
}

/// Returns the icon for a scan type.
IconData scanTypeIcon(ScanType type) {
  switch (type) {
    case ScanType.url:
      return Icons.link_rounded;
    case ScanType.phone:
      return Icons.phone_rounded;
    case ScanType.email:
      return Icons.email_rounded;
    case ScanType.sms:
      return Icons.sms_rounded;
    case ScanType.wifi:
      return Icons.wifi_rounded;
    case ScanType.vcard:
      return Icons.contact_page_rounded;
    case ScanType.geo:
      return Icons.location_on_rounded;
    case ScanType.text:
      return Icons.text_fields_rounded;
  }
}

/// Handles the primary action for a scan result.
/// Returns false if the action could not be performed.
Future<bool> handleScanAction(
  BuildContext context,
  String raw,
  ScanType type,
) async {
  try {
    switch (type) {
      case ScanType.url:
        final uri = Uri.parse(raw);
        return await launchUrl(uri, mode: LaunchMode.externalApplication);

      case ScanType.phone:
        final tel = raw.startsWith('tel:') ? raw : 'tel:$raw';
        return await launchUrl(Uri.parse(tel));

      case ScanType.email:
        final mailto = raw.startsWith('mailto:') ? raw : 'mailto:$raw';
        return await launchUrl(Uri.parse(mailto));

      case ScanType.sms:
        final smsUri = raw.startsWith('sms') ? raw : 'sms:$raw';
        return await launchUrl(Uri.parse(smsUri));

      case ScanType.geo:
        final geoUri = raw.startsWith('geo:') ? raw : 'geo:$raw';
        return await launchUrl(Uri.parse(geoUri),
            mode: LaunchMode.externalApplication);

      case ScanType.vcard:
        // Attempt to open vCard via intent
        return await launchUrl(
          Uri.dataFromString(raw, mimeType: 'text/x-vcard'),
          mode: LaunchMode.externalApplication,
        );

      case ScanType.wifi:
      case ScanType.text:
        return false;
    }
  } catch (_) {
    return false;
  }
}

/// Returns the label for the primary action button.
String primaryActionLabel(ScanType type) {
  switch (type) {
    case ScanType.url:
      return 'Open in Browser';
    case ScanType.phone:
      return 'Dial Number';
    case ScanType.email:
      return 'Send Email';
    case ScanType.sms:
      return 'Send SMS';
    case ScanType.wifi:
      return 'Copy Password';
    case ScanType.vcard:
      return 'Add to Contacts';
    case ScanType.geo:
      return 'Open in Maps';
    case ScanType.text:
      return 'Copy Text';
  }
}

/// Returns the icon for the primary action button.
IconData primaryActionIcon(ScanType type) {
  switch (type) {
    case ScanType.url:
      return Icons.open_in_browser_rounded;
    case ScanType.phone:
      return Icons.call_rounded;
    case ScanType.email:
      return Icons.send_rounded;
    case ScanType.sms:
      return Icons.message_rounded;
    case ScanType.wifi:
      return Icons.vpn_key_rounded;
    case ScanType.vcard:
      return Icons.person_add_rounded;
    case ScanType.geo:
      return Icons.map_rounded;
    case ScanType.text:
      return Icons.copy_rounded;
  }
}
