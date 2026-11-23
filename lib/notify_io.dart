// Notificações do sistema (Android). Na web o app usa notify_stub.dart.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'logic.dart';

class Notifier {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool get supported => true;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'noite_quest_alarmes',
      'Alarmes do Noite Quest',
      channelDescription: 'Avisos de jogo, de sono e despertador',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
    ),
  );

  static Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('America/Fortaleza'));
      } catch (_) {}
      await _plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      _ready = true;
    } catch (_) {}
  }

  static Future<void> _at(int id, DateTime at, String title, String body) async {
    final when = tz.TZDateTime.from(at, tz.local);
    try {
      await _plugin.zonedSchedule(id, title, body, when, _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
    } catch (_) {
      await _plugin.zonedSchedule(id, title, body, when, _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
    }
  }

  /// Troca todos os alarmes agendados pelos da lista (os do cronômetro ficam).
  static Future<void> schedule(List<Alarm> alarms) async {
    await init();
    if (!_ready) return;
    try {
      for (var id = 0; id < 80; id++) {
        await _plugin.cancel(id);
      }
      for (final a in alarms) {
        await _at(a.id, a.at, a.title, a.body);
      }
    } catch (_) {}
  }

  static Future<void> showNow(String title, String body) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(99, title, body, _details);
    } catch (_) {}
  }

  /// Avisos do cronômetro de jogo: 10 min antes do fim e no fim.
  static Future<void> scheduleSession(DateTime warnAt, DateTime endAt, String game) async {
    await init();
    if (!_ready) return;
    try {
      if (warnAt.isAfter(DateTime.now())) {
        await _at(90, warnAt, 'Última partida!', 'Faltam 10 min de $game. Termina essa e não começa outra.');
      }
      if (endAt.isAfter(DateTime.now())) {
        await _at(91, endAt, 'Tempo esgotado!', 'Acabou o tempo de $game. Salva o jogo e desliga.');
      }
    } catch (_) {}
  }

  static Future<void> cancelSession() async {
    try {
      await _plugin.cancel(90);
      await _plugin.cancel(91);
    } catch (_) {}
  }
}
