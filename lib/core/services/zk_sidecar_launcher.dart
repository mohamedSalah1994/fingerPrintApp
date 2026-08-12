import 'package:url_launcher/url_launcher.dart';

/// Asks the local Windows helper to start via custom protocol `mecms-zk://`.
/// Requires one-time `zk_sidecar/install_autostart.bat`.
class ZkSidecarLauncher {
  static final Uri _startUri = Uri.parse('mecms-zk://start');

  /// Returns true if the OS accepted the launch request (not that health is OK).
  static Future<bool> requestStart() async {
    try {
      return await launchUrl(
        _startUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
