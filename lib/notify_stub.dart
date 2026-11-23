// Na web não há notificação agendada do sistema: o app mostra o alarme na tela enquanto está aberto.
import 'logic.dart';

class Notifier {
  static bool get supported => false;
  static Future<void> init() async {}
  static Future<void> schedule(List<Alarm> alarms) async {}
  static Future<void> showNow(String title, String body) async {}
  static Future<void> scheduleSession(DateTime warnAt, DateTime endAt, String game) async {}
  static Future<void> cancelSession() async {}
}
