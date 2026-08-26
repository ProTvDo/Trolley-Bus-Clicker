import 'package:flutter/foundation.dart';
// in_app_update IS a direct dependency in pubspec.yaml - this is a known
// analyzer false positive: https://github.com/dart-lang/sdk/issues/59481
// ignore: depend_on_referenced_packages
import 'package:in_app_update/in_app_update.dart';

/// Wraps Play Core's flexible in-app update flow. Checked once at startup:
/// if a newer version is published, it downloads silently in the
/// background while the player keeps playing the current one; [ready]
/// flips to true once the download finishes so the UI can offer a
/// "restart to install" prompt.
///
/// Android-only (and only when installed via Play Store) - every failure
/// path (iOS, web, sideloaded/debug build, offline) is swallowed, since
/// checking for updates must never block or crash the game itself.
class AppUpdateService {
  AppUpdateService._();
  static final instance = AppUpdateService._();

  final ValueNotifier<bool> ready = ValueNotifier(false);

  Future<void> checkAndStart() async {
    if (kIsWeb) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable && info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        ready.value = true;
      }
    } catch (_) {
      // Not installed via Play Store, offline, unsupported platform, etc.
    }
  }

  Future<void> completeUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (_) {
      // Best-effort - if this fails the banner just stays until next launch.
    }
  }
}
