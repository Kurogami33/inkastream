import 'package:android_intent_plus/android_intent.dart';

class ExternalPlayer {
  static const _vlc = 'org.videolan.vlc';
  static const _mx = 'com.mxtech.videoplayer.ad';
  static const _mxPro = 'com.mxtech.videoplayer.pro';

  /// Intenta VLC, luego MX Player, luego cualquier reproductor.
  /// Devuelve el nombre del reproductor usado, o null si ninguno abrió.
  static Future<String?> open(String url, {String title = ''}) async {
    final options = <MapEntry<String, String?>>[
      const MapEntry('VLC', _vlc),
      const MapEntry('MX Player', _mx),
      const MapEntry('MX Player Pro', _mxPro),
      const MapEntry('otro reproductor', null),
    ];
    for (final o in options) {
      try {
        final intent = AndroidIntent(
          action: 'action_view',
          data: url,
          type: 'video/*',
          package: o.value,
          arguments: <String, dynamic>{'title': title},
        );
        if (o.value != null) {
          final ok = await intent.canResolveActivity() ?? false;
          if (!ok) continue;
        }
        await intent.launch();
        return o.key;
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
