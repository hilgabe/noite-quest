// Regras do Noite Quest: rotina, limites de cada noite, XP e save local.
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

String pad(int n) => n.toString().padLeft(2, '0');

int hm(String s) {
  final p = s.split(':');
  return (int.tryParse(p[0]) ?? 0) * 60 + (p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0);
}

/// Minutos do dia em "22h10".
String fmt(num minutes) {
  final m = ((minutes.round() % 1440) + 1440) % 1440;
  return '${pad(m ~/ 60)}h${pad(m % 60)}';
}

/// Horário depois da meia-noite (antes das 6h) conta como a mesma noite.
int late(int m) => m < 360 ? m + 1440 : m;

String keyOf(DateTime d) => '${d.year}-${pad(d.month)}-${pad(d.day)}';

DateTime dateOf(String k) {
  final p = k.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String addDays(String k, int n) {
  final d = dateOf(k);
  return keyOf(DateTime(d.year, d.month, d.day + n));
}

/// A noite de hoje. De madrugada (antes das 5h) ainda é a noite anterior.
String nightKeyNow() {
  final d = DateTime.now();
  return d.hour < 5 ? keyOf(DateTime(d.year, d.month, d.day - 1)) : keyOf(d);
}

const dowShort = ['', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
const dowLong = ['', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'];

String dayLabel(String k) => '${k.substring(8)}/${k.substring(5, 7)}';

int minOfDay(int ts) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  return d.hour * 60 + d.minute;
}

class Settings {
  String wake = '05:40';
  String wakeMax = '06:00';
  double sleepH = 7;
  int wind = 30;
  String classEnd = '22:00';
  int extra = 20;
  int sunLimit = 120;
  int offLimit = 180;
  String offEnd = '01:00';
  int bonus = 60;
  String playTime = '17:30';
  Map<String, NotifCfg> notif = defaultNotif();

  Map<String, dynamic> toJson() => {
        'wake': wake,
        'wakeMax': wakeMax,
        'sleepH': sleepH,
        'wind': wind,
        'classEnd': classEnd,
        'extra': extra,
        'sunLimit': sunLimit,
        'offLimit': offLimit,
        'offEnd': offEnd,
        'bonus': bonus,
        'playTime': playTime,
        'notif': notif.map((k, v) => MapEntry(k, v.toJson())),
      };

  static Settings fromJson(Map<String, dynamic>? j) {
    final s = Settings();
    if (j == null) return s;
    s.wake = j['wake'] as String? ?? s.wake;
    s.wakeMax = j['wakeMax'] as String? ?? s.wakeMax;
    s.sleepH = (j['sleepH'] as num?)?.toDouble() ?? s.sleepH;
    s.wind = (j['wind'] as num?)?.toInt() ?? s.wind;
    s.classEnd = j['classEnd'] as String? ?? s.classEnd;
    s.extra = (j['extra'] as num?)?.toInt() ?? s.extra;
    s.sunLimit = (j['sunLimit'] as num?)?.toInt() ?? s.sunLimit;
    s.offLimit = (j['offLimit'] as num?)?.toInt() ?? s.offLimit;
    s.offEnd = j['offEnd'] as String? ?? s.offEnd;
    s.bonus = (j['bonus'] as num?)?.toInt() ?? s.bonus;
    s.playTime = j['playTime'] as String? ?? s.playTime;
    final nj = j['notif'];
    if (nj is Map) {
      for (final e in nj.entries) {
        final key = e.key as String;
        if (s.notif.containsKey(key) && e.value is Map) {
          s.notif[key] = NotifCfg.fromJson(Map<String, dynamic>.from(e.value as Map), s.notif[key]!);
        }
      }
    }
    return s;
  }

  int get bed => ((hm(wake) - (sleepH * 60).round()) % 1440 + 1440) % 1440;
  int get off => ((bed - wind) % 1440 + 1440) % 1440;
  int get afterClass => math.max(0, late(off) - hm(classEnd));
  int get weekdayLimit => extra + afterClass;
  int get offBed => (hm(offEnd) + wind) % 1440;
}

class Session {
  int s;
  int? e;
  Session(this.s, [this.e]);
  Map<String, dynamic> toJson() => {'s': s, if (e != null) 'e': e};
  static Session fromJson(Map<String, dynamic> j) => Session((j['s'] as num).toInt(), (j['e'] as num?)?.toInt());
}

class Night {
  final String date;
  String? game;
  bool alarm = false;
  bool skip = false;
  bool? respected;
  bool? folga;
  List<Session> sessions = [];
  int? bedAt;
  int? wakeAt;
  int? mood;
  int? arrivedAt;
  List<LogEntry> log = [];

  Night(this.date);

  bool get playing => sessions.any((s) => s.e == null);
  bool get finished => respected != null;

  double playedMin([int? now]) {
    final t = now ?? DateTime.now().millisecondsSinceEpoch;
    var ms = 0;
    for (final s in sessions) {
      ms += (s.e ?? t) - s.s;
    }
    return ms / 60000;
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        if (game != null) 'game': game,
        'alarm': alarm,
        'skip': skip,
        if (respected != null) 'respected': respected,
        if (folga != null) 'folga': folga,
        'sessions': sessions.map((s) => s.toJson()).toList(),
        if (bedAt != null) 'bedAt': bedAt,
        if (wakeAt != null) 'wakeAt': wakeAt,
        if (mood != null) 'mood': mood,
        if (arrivedAt != null) 'arrivedAt': arrivedAt,
        'log': log.map((e) => e.toJson()).toList(),
      };

  static Night fromJson(String k, Map<String, dynamic> j) {
    final n = Night(k);
    n.game = j['game'] as String?;
    n.alarm = j['alarm'] == true;
    n.skip = j['skip'] == true;
    n.respected = j['respected'] as bool?;
    n.folga = j['folga'] as bool?;
    n.sessions = ((j['sessions'] as List?) ?? [])
        .map((e) => Session.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    n.bedAt = (j['bedAt'] as num?)?.toInt();
    n.wakeAt = (j['wakeAt'] as num?)?.toInt();
    n.mood = (j['mood'] as num?)?.toInt();
    n.arrivedAt = (j['arrivedAt'] as num?)?.toInt();
    n.log = ((j['log'] as List?) ?? []).map((e) => LogEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    return n;
  }
}

enum NightType { util, domingo, folga }

class Limits {
  final NightType type;
  final int limit;
  final int offMin;
  final int bedMin;
  final bool bonusEarned;
  final int bonusOk;
  final int bonusNeed;
  final DateTime deadline;
  final DateTime bedline;
  Limits(this.type, this.limit, this.offMin, this.bedMin, this.bonusEarned, this.bonusOk, this.bonusNeed,
      this.deadline, this.bedline);
}

class Progress {
  final int xp, stars, streak, level, into;
  final String rank;
  Progress(this.xp, this.stars, this.streak, this.level, this.into, this.rank);
}

const ranks = [
  'Novato Noturno',
  'Aprendiz do Relógio',
  'Guardião do Sono',
  'Cavaleiro da Lua',
  'Mestre do Controle',
  'Lenda do Descanso',
];

class Game {
  final String name;
  final String cat; // ok, mid, no
  final String tip;
  const Game(this.name, this.cat, this.tip);
}

const games = [
  Game('Marvel Snap', 'ok', '5 a 6 partidas rápidas. Fez as missões diárias, fecha.'),
  Game('FIFA 22', 'mid', '2 partidas com tempos de 6 min. Perdeu? Sem revanche.'),
  Game('PES 2021', 'mid', '2 partidas (uns 15 min cada). Perdeu? Sem revanche.'),
  Game('EA Sports FC 26', 'mid', '2 partidas curtas. Mesma regra do FIFA.'),
  Game('GTA V', 'mid', 'Só uma coisa rápida: 1 missão ou 1 corre curto. Golpe longo fica pra sexta.'),
  Game('Dragon Ball FighterZ', 'ok', '5 a 8 lutas. Conte as lutas, não os minutos.'),
  Game('Dragon Ball Xenoverse 2', 'mid', '2 missões paralelas, 1 objetivo por noite.'),
  Game('Titanfall 2', 'mid', '2 partidas de multiplayer. Campanha só no fim de semana.'),
  Game('Counter-Strike 2', 'mid', 'Só Deathmatch (10 min). Premier fica pra sexta.'),
  Game('Stardew Valley', 'ok', '2 dias no jogo. Dormiu no jogo, salvou: desliga.'),
  Game('Need for Speed Heat', 'ok', '4 a 5 corridas escolhidas antes.'),
  Game('Devil May Cry 5', 'mid', '1 missão, só se faltar mais de 30 min.'),
  Game('Warframe', 'mid', '2 a 3 missões rápidas.'),
  Game('Stick Fight', 'ok', 'Rodadas curtas. Avise os amigos a hora de sair.'),
  Game('Ultimate Chicken Horse', 'ok', '2 a 3 partidas.'),
  Game('Gang Beasts', 'ok', 'Rodadas curtas. Avise a hora de sair.'),
  Game('Skyrim', 'no', 'Sem ponto de parada. Escolha 1 missão e salve.'),
  Game('Munchkin Digital', 'no', 'Partidas longas. Fica pra véspera de folga.'),
  Game('The Forest', 'no', 'Só salva em abrigo. Construa um cedo.'),
  Game('Dying Light', 'no', 'Salve num esconderijo e saia.'),
  Game('The Sims 4', 'no', 'Sem fim de partida. Use o alarme.'),
  Game('R.E.P.O.', 'no', 'Com amigos vira a noite. Sexta e sábado.'),
];

const tips = [
  'Conte partidas, não minutos. "2 partidas de FIFA" é mais fácil de cumprir que "meia hora".',
  'Quando o alarme tocar, termine a partida atual e não comece outra.',
  'Pare depois de uma vitória ou logo depois de salvar. Derrota puxa revanche.',
  'GTA em noite de semana: só uma missão rápida. Golpes e sessões longas ficam pra sexta e sábado.',
  'Jogando com amigos, avise no começo a hora que você sai.',
  'Em noite de semana o melhor horário é entre o trabalho e a aula.',
  'Passou do limite um dia? Tudo bem. Amanhã é uma fase nova.',
];

class GameState {
  Settings settings = Settings();
  Map<String, Night> nights = {};
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString('nq_save');
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      settings = Settings.fromJson(j['settings'] as Map<String, dynamic>?);
      final ns = (j['nights'] as Map<String, dynamic>?) ?? {};
      nights = ns.map((k, v) => MapEntry(k, Night.fromJson(k, Map<String, dynamic>.from(v as Map))));
    } catch (_) {}
  }

  Future<void> save() async {
    final data = jsonEncode({
      'settings': settings.toJson(),
      'nights': nights.map((k, v) => MapEntry(k, v.toJson())),
    });
    await _prefs?.setString('nq_save', data);
  }

  Night night(String k) => nights.putIfAbsent(k, () => Night(k));

  NightType typeOf(String k) {
    final n = nights[k];
    final wd = dateOf(k).weekday; // 1 seg ... 7 dom
    if (n?.folga == true) return NightType.folga;
    if (n?.folga == false) return wd == 7 ? NightType.domingo : NightType.util;
    if (wd == 5 || wd == 6) return NightType.folga;
    if (wd == 7) return NightType.domingo;
    return NightType.util;
  }

  Limits limitsFor(String k) {
    final s = settings;
    final t = typeOf(k);
    var limit = t == NightType.util ? s.weekdayLimit : (t == NightType.domingo ? s.sunLimit : s.offLimit);
    var ok = 0, need = 0;
    var earned = false;
    if (dateOf(k).weekday == 6) {
      final mon = addDays(k, -5);
      for (var i = 0; i < 4; i++) {
        final kk = addDays(mon, i);
        if (typeOf(kk) != NightType.util) continue;
        need++;
        if (nights[kk]?.respected == true) ok++;
      }
      earned = need > 0 && ok == need;
      if (earned) limit += s.bonus;
    }
    final offMin = t == NightType.folga ? hm(s.offEnd) : s.off;
    final bedMin = t == NightType.folga ? s.offBed : s.bed;
    final base = dateOf(k);
    return Limits(t, limit, offMin, bedMin, earned, ok, need, base.add(Duration(minutes: late(offMin))),
        base.add(Duration(minutes: late(bedMin))));
  }

  /// Placar do baú da semana que contém a noite k.
  List<int> weekChest(String k) {
    final mon = addDays(k, -(dateOf(k).weekday - 1));
    final l = limitsFor(addDays(mon, 5));
    return [l.bonusOk, l.bonusNeed, l.bonusEarned ? 1 : 0];
  }

  bool wokeOnTime(String k) {
    final n = nights[k];
    if (n?.wakeAt == null || typeOf(k) == NightType.folga) return false;
    return minOfDay(n!.wakeAt!) <= hm(settings.wakeMax);
  }

  int nightXP(String k) {
    final n = nights[k];
    if (n == null) return 0;
    final l = limitsFor(k);
    var xp = 0;
    if (n.game != null) xp += 10;
    if (n.alarm) xp += 10;
    if (n.respected == true) xp += n.skip ? 40 : 50;
    if (n.bedAt != null) {
      xp += n.bedAt! <= l.bedline.millisecondsSinceEpoch + 5 * 60000 ? 20 : 5;
    }
    if (n.wakeAt != null && n.mood != null) xp += 10;
    if (wokeOnTime(k)) xp += 10;
    return xp;
  }

  Progress progress() {
    final keys = nights.keys.toList()..sort();
    final xp = keys.fold<int>(0, (a, k) => a + nightXP(k));
    final stars = keys.where((k) => nights[k]!.respected == true).length;
    var streak = 0;
    var k = nightKeyNow();
    if (nights[k]?.respected == null) k = addDays(k, -1);
    while (nights[k]?.respected == true) {
      streak++;
      k = addDays(k, -1);
    }
    final level = xp ~/ 200 + 1;
    return Progress(xp, stars, streak, level, xp % 200, ranks[math.min(level - 1, ranks.length - 1)]);
  }
}

// ---------------- Registro do que aconteceu ----------------
class LogEntry {
  final int t;
  final String kind;
  final String text;
  LogEntry(this.t, this.kind, this.text);
  Map<String, dynamic> toJson() => {'t': t, 'kind': kind, 'text': text};
  static LogEntry fromJson(Map<String, dynamic> j) =>
      LogEntry((j['t'] as num).toInt(), j['kind'] as String? ?? 'nota', j['text'] as String? ?? '');
}

String clock(int ts) => fmt(minOfDay(ts));

/// "20 min antes" / "35 min depois" / "na hora certa", em relação a uma meta.
String diffText(int minutes, {String before = 'antes', String after = 'depois'}) {
  final m = minutes.abs();
  if (m <= 1) return 'na hora certa';
  final h = m ~/ 60, r = m % 60;
  final txt = h > 0 ? (r > 0 ? '$h h $r min' : '$h h') : '$m min';
  return minutes < 0 ? '$txt $before' : '$txt $after';
}

/// Converte um horário escolhido no relógio para a data certa da noite.
/// De madrugada (antes das 6h) ou de manhã (acordar) cai no dia seguinte.
int tsForNight(String k, int hour, int minute, {bool morning = false}) {
  final base = dateOf(k);
  final m = hour * 60 + minute;
  final nextDay = morning || m < 360;
  return DateTime(base.year, base.month, base.day + (nextDay ? 1 : 0), hour, minute).millisecondsSinceEpoch;
}

// ---------------- Avisos e alarmes ----------------
class NotifCfg {
  bool on;
  String msg;
  int min;
  NotifCfg(this.on, this.msg, [this.min = 0]);
  Map<String, dynamic> toJson() => {'on': on, 'msg': msg, 'min': min};
  static NotifCfg fromJson(Map<String, dynamic> j, NotifCfg d) {
    final m = j['msg'] as String?;
    return NotifCfg(j['on'] as bool? ?? d.on, (m != null && m.trim().isNotEmpty) ? m : d.msg,
        (j['min'] as num?)?.toInt() ?? d.min);
  }
}

const notifKinds = ['play', 'warn', 'off', 'bed', 'wake', 'log'];
const notifNames = {
  'play': 'Hora boa de jogar',
  'warn': 'Última partida',
  'off': 'Hora de desligar',
  'bed': 'Hora de deitar',
  'wake': 'Despertador',
  'log': 'Registrar a manhã',
};
const notifHelp = {
  'play': 'Dias de semana, entre o trabalho e a aula.',
  'warn': 'Minutos antes do horário de desligar.',
  'off': 'No horário de desligar o jogo.',
  'bed': 'No horário de deitar.',
  'wake': 'No horário de acordar, depois de noite de trabalho.',
  'log': 'Minutos depois do horário máximo de acordar.',
};

Map<String, NotifCfg> defaultNotif() => {
      'play': NotifCfg(false, 'Janela de jogo aberta! Joga um pouco antes da aula.'),
      'warn': NotifCfg(true, 'Última partida! Termina essa e não começa outra.', 10),
      'off': NotifCfg(true, 'Hora de desligar o jogo. Salva e sai!'),
      'bed': NotifCfg(true, 'Hora de deitar. Celular longe da cama!'),
      'wake': NotifCfg(true, 'Bom dia! Hora de acordar.'),
      'log': NotifCfg(true, 'Como você acordou? Registra no Noite Quest.', 30),
    };

class Alarm {
  final int id;
  final String kind;
  final DateTime at;
  final String title;
  final String body;
  Alarm(this.id, this.kind, this.at, this.title, this.body);
}

// ---------------- Saúde do personagem ----------------
class Health {
  final int score; // 0 a 100
  final String mood; // top, good, ok, tired, bad, start
  final String label;
  final String speech;
  final int nights;
  Health(this.score, this.mood, this.label, this.speech, this.nights);
}

extension HealthAndAlarms on GameState {
  int nightHealth(String k) {
    final n = nights[k]!;
    final l = limitsFor(k);
    var p = n.respected == true ? 40 : (n.respected == false ? 10 : 20);
    if (n.bedAt != null) {
      final atraso = (n.bedAt! - l.bedline.millisecondsSinceEpoch) / 60000;
      p += atraso <= 5 ? 30 : (atraso <= 30 ? 20 : (atraso <= 60 ? 10 : 0));
    } else {
      p += 10;
    }
    if (n.wakeAt != null && typeOf(k) != NightType.folga) {
      p += wokeOnTime(k) ? 20 : 8;
    } else {
      p += 14;
    }
    if (n.wakeAt != null && n.bedAt != null) {
      final h = (n.wakeAt! - n.bedAt!) / 3600000;
      p += h >= settings.sleepH ? 10 : (h >= settings.sleepH - 1 ? 6 : 0);
    } else {
      p += 6;
    }
    return p;
  }

  Health health() {
    final today = nightKeyNow();
    final keys = <String>[];
    for (var i = 0; i <= 7; i++) {
      final k = addDays(today, -i);
      final n = nights[k];
      if (n == null) continue;
      if (n.respected == null && n.bedAt == null) continue;
      keys.add(k);
    }
    if (keys.isEmpty) {
      return Health(70, 'start', 'Começando', 'Bora começar! Complete as missões de hoje.', 0);
    }
    final score = (keys.map(nightHealth).reduce((a, b) => a + b) / keys.length).round();
    if (score >= 85) return Health(score, 'top', 'Saudável demais', 'Tô voando! Sono em dia e jogo na medida.', keys.length);
    if (score >= 65) return Health(score, 'good', 'Bem', 'Tô bem! Bora manter o ritmo.', keys.length);
    if (score >= 45) return Health(score, 'ok', 'Mais ou menos', 'Tô ok. Dá pra deitar um pouco mais cedo.', keys.length);
    if (score >= 25) return Health(score, 'tired', 'Cansado', 'Tô cansado… hoje deita no horário?', keys.length);
    return Health(score, 'bad', 'Mal', 'Tô mal. Preciso de uma noite de sono de verdade.', keys.length);
  }

  /// Alarmes de uma noite (data k), já com horário e texto.
  List<Alarm> alarmsFor(String k, int dayIndex) {
    final l = limitsFor(k);
    final s = settings;
    final base = dateOf(k);
    final out = <Alarm>[];
    void add(int idx, String kind, DateTime at) {
      final c = s.notif[kind]!;
      if (!c.on) return;
      out.add(Alarm(dayIndex * 10 + idx, kind, at, notifNames[kind]!, '${c.msg} (${fmt(at.hour * 60 + at.minute)})'));
    }

    final work = l.type != NightType.folga;
    if (l.type == NightType.util) add(0, 'play', base.add(Duration(minutes: hm(s.playTime))));
    add(1, 'warn', l.deadline.subtract(Duration(minutes: s.notif['warn']!.min)));
    add(2, 'off', l.deadline);
    add(3, 'bed', l.bedline);
    if (work) {
      final next = DateTime(base.year, base.month, base.day + 1);
      add(4, 'wake', next.add(Duration(minutes: hm(s.wake))));
      add(5, 'log', next.add(Duration(minutes: hm(s.wakeMax) + s.notif['log']!.min)));
    }
    return out;
  }

  /// Próximos alarmes (7 noites), só os que ainda vão acontecer.
  List<Alarm> upcomingAlarms() {
    final now = DateTime.now();
    final k0 = nightKeyNow();
    final out = <Alarm>[];
    for (var i = 0; i < 7; i++) {
      out.addAll(alarmsFor(addDays(k0, i), i).where((a) => a.at.isAfter(now)));
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  void logEvent(String k, String kind, String text, [int? t]) {
    night(k).log.add(LogEntry(t ?? DateTime.now().millisecondsSinceEpoch, kind, text));
  }
}
