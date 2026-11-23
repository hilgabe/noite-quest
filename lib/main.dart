import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'logic.dart';
import 'sprites.dart';

// ---------------- Cores e fontes ----------------
const sky = Color(0xFF15123B);
const panel = Color(0xFF2A2470);
const panel2 = Color(0xFF352D86);
const edge = Color(0xFF0B0920);
const ink = Color(0xFFF7F3FF);
const dim = Color(0xFFB3ACDF);
const gold = Color(0xFFFFD23F);
const mint = Color(0xFF3EE0A1);
const pink = Color(0xFFFF5D8F);
const cyan = Color(0xFF56CFFF);
const red = Color(0xFFFF5A5A);
const cardBg = Color(0xFF1D1956);
const doneBg = Color(0xFF173D3D);

TextStyle px(double size, [Color color = gold]) =>
    TextStyle(fontFamily: 'PressStart', fontSize: size, color: color, height: 1.6);

TextStyle lb(double size, {Color color = ink, int weight = 700}) => TextStyle(
      fontFamily: 'Pixelify',
      fontSize: size,
      color: color,
      height: 1.25,
      fontWeight: weight >= 700 ? FontWeight.w700 : (weight >= 600 ? FontWeight.w600 : FontWeight.w400),
      fontVariations: [FontVariation('wght', weight.toDouble())],
    );

void main() => runApp(const NoiteQuestApp());

class NoiteQuestApp extends StatelessWidget {
  const NoiteQuestApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noite Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: sky,
        colorScheme: const ColorScheme.dark(primary: gold, secondary: mint, surface: panel),
        fontFamily: 'Pixelify',
        dividerColor: Colors.transparent,
      ),
      home: const Home(),
    );
  }
}

// ---------------- Peças visuais ----------------
class PixBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final Color border;
  const PixBox({super.key, required this.child, this.color = panel, this.padding = const EdgeInsets.all(14), this.border = edge});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: border, width: 4),
          boxShadow: const [BoxShadow(color: edge, offset: Offset(6, 6))],
        ),
        child: child,
      );
}

class PixButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color fg;
  final bool big;
  const PixButton(this.label, {super.key, this.onTap, this.color = gold, this.fg = const Color(0xFF2A1A00), this.big = false});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: big ? 20 : 14, vertical: big ? 16 : 12),
          decoration: BoxDecoration(
            color: enabled ? color : const Color(0xFF4A4580),
            border: Border.all(color: edge, width: 4),
            boxShadow: const [BoxShadow(color: edge, offset: Offset(4, 4))],
          ),
          child: Text(label.toUpperCase(),
              style: lb(big ? 20 : 17, color: enabled ? fg : const Color(0xFF8F89C0))),
        ),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color fg;
  const Tag(this.text, this.color, this.fg, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(color: color, border: Border.all(color: edge, width: 3)),
        child: Text(text.toUpperCase(), style: lb(13, color: fg)),
      );
}

class Bar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  final Color bg;
  const Bar(this.value, this.color, {super.key, this.height = 18, this.bg = const Color(0xFF120F33)});
  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(color: bg, border: Border.all(color: edge, width: 3)),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble(),
          child: Container(color: color),
        ),
      );
}

// ---------------- Cena animada ----------------
class SceneView extends StatefulWidget {
  final bool playing, sleeping, won;
  const SceneView({super.key, this.playing = false, this.sleeping = false, this.won = false});
  @override
  State<SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<SceneView> {
  int frame = 0;
  Timer? t;
  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(milliseconds: 600), (_) => setState(() => frame++));
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: ScenePainter(frame, playing: widget.playing, sleeping: widget.sleeping, won: widget.won),
        child: const SizedBox.expand(),
      );
}

// ---------------- Cronômetro ----------------
class TimerView extends StatefulWidget {
  final Night night;
  final Limits limits;
  const TimerView(this.night, this.limits, {super.key});
  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  Timer? t;
  bool warned = false, over = false;
  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final used = widget.night.playedMin(now.millisecondsSinceEpoch);
    final toDeadline = widget.limits.deadline.difference(now).inSeconds / 60;
    final left = [widget.limits.limit - used, toDeadline].reduce((a, b) => a < b ? a : b);
    final total = [widget.limits.limit.toDouble(), used + (left > 0 ? left : 0)].reduce((a, b) => a < b ? a : b);
    final secs = (left * 60).round();
    final clock = left >= 0
        ? '${pad(secs ~/ 60)}:${pad(secs % 60)}'
        : '-${pad((-secs) ~/ 60)}:${pad((-secs) % 60)}';
    Color c = mint;
    String msg = 'Jogando ${widget.night.game ?? ''}. Bom jogo!';
    if (left <= 0) {
      c = red;
      msg = 'TEMPO ESGOTADO! Salve o jogo e desligue.';
      if (!over) {
        over = true;
        HapticFeedback.heavyImpact();
      }
    } else if (left <= 10) {
      c = gold;
      msg = 'ÚLTIMA PARTIDA! Não comece outra.';
      if (!warned) {
        warned = true;
        HapticFeedback.mediumImpact();
      }
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF0F0C2C), border: Border.all(color: edge, width: 4)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(clock, style: lb(56, color: c).copyWith(height: 1, fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 8),
        Bar(total <= 0 ? 0 : left / total, c, height: 20, bg: const Color(0xFF2A0F2A)),
        const SizedBox(height: 8),
        Text(msg, style: lb(17, weight: 600)),
      ]),
    );
  }
}

// ---------------- Tela principal ----------------
class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final gs = GameState();
  bool loaded = false;
  bool started = false;
  bool showGames = false;
  String nightKey = nightKeyNow();
  Timer? clockTick;

  @override
  void initState() {
    super.initState();
    gs.load().then((_) => setState(() => loaded = true));
    clockTick = Timer.periodic(const Duration(seconds: 30), (_) {
      final k = nightKeyNow();
      setState(() => nightKey = k);
    });
  }

  @override
  void dispose() {
    clockTick?.cancel();
    super.dispose();
  }

  void toast(String t) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: gold,
        shape: const RoundedRectangleBorder(side: BorderSide(color: edge, width: 4)),
        content: Text(t, style: lb(17, color: const Color(0xFF2A1A00))),
        duration: const Duration(seconds: 3),
      ));
  }

  void act(String k, void Function(Night n) f, {String? msg}) {
    final before = gs.progress();
    setState(() => f(gs.night(k)));
    gs.save();
    final after = gs.progress();
    final diff = after.xp - before.xp;
    final parts = <String>[];
    if (diff > 0) parts.add('+$diff XP');
    if (msg != null) parts.add(msg);
    if (after.level > before.level) parts.add('SUBIU DE NÍVEL! Agora você é ${after.rank}.');
    if (parts.isNotEmpty) toast(parts.join(' · '));
  }

  String nightTitle(NightType t) =>
      t == NightType.util ? 'NOITE DE SEMANA' : (t == NightType.domingo ? 'DOMINGO' : 'VÉSPERA DE FOLGA');

  @override
  Widget build(BuildContext context) {
    final k = nightKey;
    final n = gs.nights[k];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: !loaded
                ? Center(child: Text('CARREGANDO SAVE…', style: px(12)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 22, 40),
                    children: [
                      hud(),
                      const SizedBox(height: 18),
                      stage(k, n),
                      if (started) ...[
                        const SizedBox(height: 18),
                        week(k),
                        const SizedBox(height: 18),
                        quests(k),
                        const SizedBox(height: 18),
                        diary(),
                        const SizedBox(height: 18),
                        tipsBox(),
                        const SizedBox(height: 18),
                        routine(),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ----- HUD -----
  Widget hud() {
    final p = gs.progress();
    return PixBox(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('NÍVEL', style: lb(15)),
          Text('${p.level}', style: px(18)),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Bar(p.into / 200, cyan),
            const SizedBox(height: 6),
            Wrap(spacing: 10, children: [
              Text(p.rank, style: lb(15, color: dim, weight: 600)),
              Text('${p.into} / 200 XP', style: lb(15, color: dim, weight: 600)),
            ]),
          ]),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(children: [const Sprite('fire', scale: 2.5), const SizedBox(width: 4), Text('${p.streak}', style: lb(20))]),
          const SizedBox(height: 4),
          Row(children: [const Sprite('star', scale: 2.5), const SizedBox(width: 4), Text('${p.stars}', style: lb(20))]),
        ]),
      ]),
    );
  }

  // ----- Cena / tela de título -----
  Widget stage(String k, Night? n) {
    final d = dateOf(k);
    return PixBox(
      padding: EdgeInsets.zero,
      child: AspectRatio(
        aspectRatio: 320 / 130,
        child: Stack(children: [
          Positioned.fill(
            child: SceneView(
              playing: n?.playing ?? false,
              sleeping: n?.bedAt != null && n?.wakeAt == null,
              won: n?.respected == true,
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              color: edge,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Text('FASE ${dayLabel(k)} · ${dowShort[d.weekday].toUpperCase()}', style: lb(16)),
            ),
          ),
          if (!started)
            Positioned.fill(
              child: Container(
                color: const Color(0x8C0A0823),
                padding: const EdgeInsets.all(10),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  FittedBox(
                    child: Text('NOITE QUEST',
                        style: px(30).copyWith(shadows: const [
                          Shadow(color: edge, offset: Offset(4, 4)),
                          Shadow(color: pink, offset: Offset(-2, -2)),
                        ])),
                  ),
                  const SizedBox(height: 6),
                  Text('JOGUE NA HORA CERTA. DURMA COMO UM CAMPEÃO.',
                      textAlign: TextAlign.center, style: lb(15)),
                  const SizedBox(height: 10),
                  PixButton('▶ Press Start', big: true, onTap: () {
                    setState(() {
                      started = true;
                      showGames = gs.nights[k]?.game == null;
                    });
                  }),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  // ----- Semana e baú -----
  Widget week(String k) {
    final mon = addDays(k, -(dateOf(k).weekday - 1));
    final chest = gs.weekChest(k);
    return PixBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MAPA DA SEMANA', style: px(13)),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (i) {
            final kk = addDays(mon, i);
            final night = gs.nights[kk];
            var s = 'dot';
            if (kk == k) s = 'moon';
            if (night?.respected == true) s = 'star';
            if (night?.respected == false) s = 'x';
            final today = kk == k;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 6 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: today ? panel2 : const Color(0xFF1B1750),
                  border: Border.all(color: today ? gold : edge, width: 3),
                ),
                child: Column(children: [
                  Text(dowShort[i + 1].toUpperCase(), style: lb(14, color: dim)),
                  const SizedBox(height: 6),
                  Sprite(s, scale: s == 'moon' ? 2 : 3),
                  const SizedBox(height: 6),
                  FittedBox(child: Text(dayLabel(kk), style: lb(13, color: dim))),
                ]),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Sprite(chest[2] == 1 ? 'chestOpen' : 'chest', scale: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              chest[1],
              (i) => Container(
                width: 22,
                height: 14,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: i < chest[0] ? mint : const Color(0xFF120F33),
                  border: Border.all(color: edge, width: 3),
                ),
              ),
            ),
          ),
          Text(
            chest[2] == 1
                ? 'BAÚ ABERTO! Sábado você ganhou +${gs.settings.bonus} min de jogo.'
                : 'Baú de sábado: ${chest[0]} de ${chest[1]} noites (seg a qui) cumpridas. Complete todas e ganhe +${gs.settings.bonus} min.',
            style: lb(16, weight: 600),
          ),
        ]),
      ]),
    );
  }

  // ----- Missões -----
  Widget chip(String label, String value) => Container(
        color: edge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: lb(14, color: dim)),
          Text(value, style: lb(28, color: gold)),
        ]),
      );

  Widget quest(Widget badge, String title, int xp, String state, List<Widget> body, {Color? bg}) {
    return Opacity(
      opacity: state == 'locked' ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg ?? (state == 'done' ? doneBg : cardBg),
          border: Border.all(color: edge, width: 4),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: state == 'done' ? mint : panel2,
                  border: Border.all(color: edge, width: 4),
                ),
                child: state == 'done'
                    ? const Sprite('star', scale: 4)
                    : (state == 'locked' ? const Sprite('lock', scale: 4) : badge),
              ),
              if (xp > 0)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: gold, border: Border.all(color: edge, width: 3)),
                    child: Text('+$xp', style: lb(14, color: const Color(0xFF2A1A00))),
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: px(12, ink)),
              const SizedBox(height: 6),
              ...body,
            ]),
          ),
        ]),
      ),
    );
  }

  Widget numBadge(String s) => Text(s, style: px(16, ink));

  Widget rich(List<Object> parts) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text.rich(TextSpan(
          style: lb(17, weight: 400),
          children: parts
              .map((p) => p is String
                  ? TextSpan(text: p)
                  : TextSpan(text: (p as List)[0] as String, style: lb(24, color: gold)))
              .toList(),
        )),
      );

  Widget quests(String k) {
    final n = gs.nights[k] ?? Night(k);
    final l = gs.limitsFor(k);
    final s = gs.settings;
    final d = dateOf(k);
    final playing = n.playing;
    final finished = n.finished;
    final now = DateTime.now();
    final hour = now.hour;

    // Missão da manhã (noite anterior)
    final yk = addDays(k, -1);
    final y = gs.nights[yk];
    String? morning;
    if (hour >= 5 && hour < 14 && y != null && y.bedAt != null && y.wakeAt == null) morning = yk;
    if (morning == null && hour >= 5 && hour < 14 && n.bedAt != null && n.wakeAt == null) morning = k;

    final chips = <Widget>[
      Container(
        color: edge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Text(nightTitle(l.type), style: lb(16)),
      ),
      chip('Pode jogar', '${l.limit} min'),
      chip('Desligar até', fmt(l.offMin)),
      chip('Deitar até', fmt(l.bedMin)),
      if (l.type != NightType.folga) chip('Acordar', '${fmt(hm(s.wake))} a ${fmt(hm(s.wakeMax))}'),
      if (l.bonusEarned) chip('Bônus', '+${s.bonus} min'),
    ];

    // 1. Jogo
    final body1 = <Widget>[];
    if (n.game != null) {
      final g = games.where((x) => x.name == n.game).toList();
      body1.add(Container(
        color: edge,
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ESCOLHIDO: ${n.game!.toUpperCase()}', style: lb(17, color: gold)),
          if (g.isNotEmpty) Text(g.first.tip, style: lb(15, color: dim, weight: 400)),
        ]),
      ));
    } else {
      body1.add(rich([
        l.type == NightType.util
            ? 'Escolha um jogo que caiba na noite de semana. Os vermelhos liberam na sexta.'
            : 'Escolha o jogo da noite. Hoje está tudo liberado.'
      ]));
    }
    if (!finished && !playing) {
      body1.add(const SizedBox(height: 8));
      body1.add(GestureDetector(
        onTap: () => setState(() => showGames = !showGames),
        child: Text(showGames ? '▼ Esconder jogos' : (n.game != null ? '▶ Trocar de jogo' : '▶ Ver jogos'),
            style: lb(16, color: cyan)),
      ));
      if (showGames) {
        body1.add(const SizedBox(height: 8));
        body1.add(LayoutBuilder(builder: (ctx, c) {
          final w = c.maxWidth >= 460 ? (c.maxWidth - 8) / 2 : c.maxWidth;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: games.map((g) {
              final locked = g.cat == 'no' && l.type == NightType.util;
              final sel = n.game == g.name;
              final tag = locked
                  ? const Tag('Bloqueado hoje', pink, Color(0xFF3A0014))
                  : (g.cat == 'ok'
                      ? const Tag('Livre', mint, Color(0xFF00301D))
                      : g.cat == 'mid'
                          ? const Tag('Com limite', gold, Color(0xFF2A1A00))
                          : const Tag('Só sexta e sábado', pink, Color(0xFF3A0014)));
              return Opacity(
                opacity: locked ? 0.45 : 1,
                child: GestureDetector(
                  onTap: locked
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          act(k, (x) => x.game = g.name);
                          setState(() => showGames = false);
                        },
                  child: Container(
                    width: w,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF2D6B4F) : const Color(0xFF15124A),
                      border: Border.all(color: sel ? gold : edge, width: 3),
                      boxShadow: const [BoxShadow(color: edge, offset: Offset(3, 3))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g.name, style: lb(17)),
                      const SizedBox(height: 6),
                      tag,
                      const SizedBox(height: 6),
                      Text(g.tip, style: lb(15, color: dim, weight: 400)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          );
        }));
      }
      body1.add(const SizedBox(height: 12));
      body1.add(PixButton('Hoje não vou jogar', color: panel2, fg: ink, onTap: () {
        act(k, (x) {
          x.skip = true;
          x.game = 'Não joguei';
          x.respected = true;
          x.sessions = [];
        }, msg: 'Noite de descanso! Também vale estrela.');
        setState(() => showGames = false);
      }));
    }

    // 2. Alarme
    final List<Widget> body2 = n.skip
        ? [Text('Hoje é descanso, sem alarme de jogo.', style: lb(16, color: dim, weight: 400))]
        : [
            rich(['Coloque um alarme no celular para ', [fmt(l.offMin - 10)], '. É o aviso de última partida.']),
            n.alarm
                ? Text('ALARME ARMADO ✓', style: lb(18, color: mint))
                : PixButton('Coloquei o alarme', color: cyan, fg: const Color(0xFF00263A),
                    onTap: n.game == null ? null : () => act(k, (x) => x.alarm = true)),
          ];

    // 3. Jogar
    final used = n.playedMin(now.millisecondsSinceEpoch);
    final toDeadline = l.deadline.difference(now).inSeconds / 60;
    final left = (l.limit - used) < toDeadline ? (l.limit - used) : toDeadline;
    final body3 = <Widget>[];
    if (n.skip) {
      body3.add(Text('DESCANSO ESCOLHIDO ✓', style: lb(18, color: mint)));
    } else if (finished && !playing) {
      final m = n.playedMin().round();
      body3.add(Text(
          n.respected == true ? 'DENTRO DO LIMITE ✓ $m DE ${l.limit} MIN' : 'PASSOU DO LIMITE: $m DE ${l.limit} MIN',
          style: lb(18, color: n.respected == true ? mint : pink)));
      if (n.respected != true) body3.add(Text('Sem problema. Amanhã é uma fase nova.', style: lb(16, color: dim, weight: 400)));
    } else if (playing) {
      body3.add(TimerView(n, l));
      body3.add(const SizedBox(height: 12));
      body3.add(PixButton('Parei de jogar', big: true, color: pink, fg: const Color(0xFF3A0014), onTap: () => stopPlay(k)));
    } else {
      body3.add(left > 0.5
          ? rich(['Você tem ', ['${left.floor()} min'], ' de jogo. Desliga até ', [fmt(l.offMin)], '.'])
          : rich(['O horário de jogo de hoje já acabou. Hora de descansar.']));
      body3.add(PixButton(used > 0 ? 'Continuar ▶' : 'Start ▶',
          big: true,
          color: mint,
          fg: const Color(0xFF00301D),
          onTap: (n.game != null && left > 0.5) ? () => startPlay(k) : null));
    }

    // 4. Deitar
    final onTimeBed = n.bedAt != null && n.bedAt! <= l.bedline.millisecondsSinceEpoch + 5 * 60000;
    final List<Widget> body4 = [
      rich(['Meta: deitar até ', [fmt(l.bedMin)], '. Celular longe da cama.']),
      n.bedAt != null
          ? Text('DEITOU ÀS ${fmt(minOfDay(n.bedAt!))}', style: lb(18, color: onTimeBed ? mint : pink))
          : PixButton('Fui deitar', color: cyan, fg: const Color(0xFF00263A), onTap: (finished && !playing)
              ? () {
                  final ok = DateTime.now().isBefore(l.bedline.add(const Duration(minutes: 5)));
                  act(k, (x) => x.bedAt = DateTime.now().millisecondsSinceEpoch,
                      msg: ok ? 'Boa noite, campeão! Zzz…' : 'Boa noite! Amanhã tenta deitar até ${fmt(l.bedMin)}.');
                }
              : null),
    ];

    return PixBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 10, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('MISSÕES DE ${dowLong[d.weekday].toUpperCase()} ${dayLabel(k)}', style: px(13)),
          PixButton(l.type == NightType.folga ? 'Amanhã é folga ✓' : 'Amanhã é folga?', color: panel2, fg: ink, onTap: () {
            final isF = l.type == NightType.folga;
            final natural = d.weekday == 5 || d.weekday == 6;
            act(k, (x) => x.folga = isF ? false : (natural ? null : true),
                msg: isF ? 'Ok, amanhã tem trabalho.' : 'Folga amanhã! Limite maior hoje.');
          }),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: chips),
        if (morning != null) wakeQuest(morning, true),
        quest(numBadge('1'), 'ESCOLHA O JOGO DA NOITE', 10, n.game != null ? 'done' : 'open', body1),
        quest(numBadge('2'), 'ARME O ALARME', 10, (n.skip || n.alarm) ? 'done' : (n.game != null ? 'open' : 'locked'), body2),
        quest(numBadge('3'), 'JOGUE NO TEMPO CERTO', 50, n.respected == true ? 'done' : (n.game != null ? 'open' : 'locked'), body3),
        quest(numBadge('4'), 'HORA DE DORMIR', 20, n.bedAt != null ? 'done' : ((finished && !playing) ? 'open' : 'locked'), body4),
        if (morning != k) wakeQuest(k, false),
      ]),
    );
  }

  Widget wakeQuest(String k, bool isMorning) {
    final n = gs.nights[k] ?? Night(k);
    final work = gs.typeOf(k) != NightType.folga;
    final s = gs.settings;
    const faces = ['😫', '🥱', '😐', '🙂', '😄'];
    final body = <Widget>[
      rich([
        isMorning
            ? 'Bom dia! Como você acordou depois da noite de ${dowLong[dateOf(k).weekday]}?'
            : 'Amanhã cedo, volte aqui e diga como acordou.'
      ]),
      work
          ? rich(['Meta: acordar entre ', [fmt(hm(s.wake))], ' e ', [fmt(hm(s.wakeMax))], ' (no máximo).'])
          : rich(['Amanhã é folga: pode dormir mais.']),
    ];
    if (n.wakeAt != null) {
      final sono = ((n.wakeAt! - (n.bedAt ?? n.wakeAt!)) / 3600000).toStringAsFixed(1).replaceAll('.', ',');
      final ok = !work || gs.wokeOnTime(k);
      body.add(Text(
          'ACORDOU ${fmt(minOfDay(n.wakeAt!))} · DORMIU $sono H${work ? (ok ? ' ✓' : ' · PASSOU DO HORÁRIO') : ' ✓'}',
          style: lb(18, color: ok ? mint : pink)));
    } else {
      body.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(5, (i) {
          final enabled = n.bedAt != null;
          return GestureDetector(
            onTap: !enabled
                ? null
                : () {
                    final now = DateTime.now().millisecondsSinceEpoch;
                    final sono = (now - n.bedAt!) / 3600000;
                    act(k, (x) {
                      x.mood = i + 1;
                      x.wakeAt = now;
                    });
                    final rule = !work
                        ? ''
                        : (gs.wokeOnTime(k) ? ' Acordou no horário!' : ' Passou das ${fmt(hm(s.wakeMax))}, amanhã tenta de novo.');
                    toast('Você dormiu ${sono.toStringAsFixed(1).replaceAll('.', ',')} h.$rule');
                  },
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: panel2,
                border: Border.all(color: edge, width: 4),
                boxShadow: const [BoxShadow(color: edge, offset: Offset(3, 3))],
              ),
              child: Text(faces[i], style: const TextStyle(fontSize: 26)),
            ),
          );
        }),
      ));
    }
    return quest(
      isMorning ? const Sprite('sun', scale: 3) : numBadge('5'),
      isMorning ? 'MISSÃO DA MANHÃ' : 'BOM DIA!',
      work ? 20 : 10,
      n.wakeAt != null ? 'done' : (n.bedAt != null ? 'open' : 'locked'),
      body,
      bg: isMorning && n.wakeAt == null ? const Color(0xFF3B2F12) : null,
    );
  }

  void startPlay(String k) {
    act(k, (x) {
      x.sessions = [...x.sessions, Session(DateTime.now().millisecondsSinceEpoch)];
      x.respected = null;
    }, msg: 'START! Bom jogo.');
  }

  void stopPlay(String k) {
    final l = gs.limitsFor(k);
    final now = DateTime.now().millisecondsSinceEpoch;
    final n = gs.night(k);
    final sessions = n.sessions.map((s) => s.e == null ? Session(s.s, now) : s).toList();
    final total = sessions.fold<int>(0, (a, s) => a + (s.e! - s.s)) / 60000;
    final ok = total <= l.limit + 1 && now <= l.deadline.millisecondsSinceEpoch + 2 * 60000;
    act(k, (x) {
      x.sessions = sessions;
      x.respected = ok;
    }, msg: ok ? 'MISSÃO CUMPRIDA! ${total.round()} min de jogo.' : 'Passou do limite hoje. Amanhã é uma fase nova!');
    if (!ok) HapticFeedback.heavyImpact();
  }

  // ----- Diário -----
  Widget section(String title, List<Widget> children) => PixBox(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: gold,
            collapsedIconColor: gold,
            title: Text(title, style: px(13)),
            childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      );

  Widget diary() {
    final keys = gs.nights.keys.where((k) => gs.nights[k]!.game != null || gs.nights[k]!.bedAt != null).toList()
      ..sort((a, b) => b.compareTo(a));
    const faces = ['😫', '🥱', '😐', '🙂', '😄'];
    return section('DIÁRIO DAS NOITES', [
      if (keys.isEmpty)
        Text('Seu diário começa hoje. Complete as missões e as noites aparecem aqui.', style: lb(16, color: dim, weight: 400)),
      ...keys.take(30).map((k) {
        final n = gs.nights[k]!;
        final l = gs.limitsFor(k);
        final sono = n.wakeAt != null && n.bedAt != null
            ? '${((n.wakeAt! - n.bedAt!) / 3600000).toStringAsFixed(1).replaceAll('.', ',')} h'
            : '–';
        final res = n.respected == true ? '★ cumpriu' : (n.respected == false ? '✕ passou' : '…');
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          color: edge,
          child: Wrap(spacing: 14, runSpacing: 4, children: [
            Text('${dowShort[dateOf(k).weekday]} ${dayLabel(k)}', style: lb(16, color: gold)),
            Text(n.game ?? '–', style: lb(16)),
            Text('${n.skip ? 0 : n.playedMin().round()} de ${l.limit} min', style: lb(16, weight: 400)),
            Text('sono $sono', style: lb(16, weight: 400)),
            if (n.mood != null) Text(faces[n.mood! - 1], style: const TextStyle(fontSize: 18)),
            Text(res, style: lb(16, color: n.respected == true ? mint : (n.respected == false ? pink : dim))),
          ]),
        );
      }),
    ]);
  }

  Widget tipsBox() => section('DICAS DO MESTRE', [
        for (var i = 0; i < tips.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${i + 1}. ${tips[i]}', style: lb(16, weight: 400)),
          ),
      ]);

  // ----- Minha rotina -----
  Future<void> pickTime(String current, void Function(String v) set) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hm(current) ~/ 60, minute: hm(current) % 60),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t == null) return;
    setState(() => set('${pad(t.hour)}:${pad(t.minute)}'));
    gs.save();
  }

  Widget timeRow(String label, String value, void Function(String v) set) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        color: edge,
        child: Row(children: [
          Expanded(child: Text(label, style: lb(16, color: dim, weight: 600))),
          PixButton(fmt(hm(value)), color: panel2, fg: gold, onTap: () => pickTime(value, set)),
        ]),
      );

  Widget numRow(String label, String value, VoidCallback minus, VoidCallback plus) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        color: edge,
        child: Row(children: [
          Expanded(child: Text(label, style: lb(16, color: dim, weight: 600))),
          PixButton('–', color: panel2, fg: ink, onTap: () {
            setState(minus);
            gs.save();
          }),
          SizedBox(width: 70, child: Text(value, textAlign: TextAlign.center, style: lb(20, color: gold))),
          PixButton('+', color: panel2, fg: ink, onTap: () {
            setState(plus);
            gs.save();
          }),
        ]),
      );

  Widget routine() {
    final s = gs.settings;
    int dec(int v, int step, int min) => v - step < min ? min : v - step;
    return section('MINHA ROTINA', [
      Text('Mude se a rotina mudar. Os limites se ajustam sozinhos.', style: lb(15, color: dim, weight: 400)),
      timeRow('Quero acordar às', s.wake, (v) {
        if (hm(v) > hm(s.wakeMax)) {
          toast('O horário de acordar precisa ser antes do máximo (${fmt(hm(s.wakeMax))}).');
          return;
        }
        s.wake = v;
      }),
      timeRow('Acordar no máximo às', s.wakeMax, (v) {
        if (hm(v) < hm(s.wake)) {
          toast('O máximo precisa ser igual ou depois de ${fmt(hm(s.wake))}.');
          return;
        }
        s.wakeMax = v;
      }),
      numRow('Horas de sono', s.sleepH.toStringAsFixed(1).replaceAll('.', ','), () => s.sleepH = s.sleepH - 0.5 < 5 ? 5 : s.sleepH - 0.5,
          () => s.sleepH = s.sleepH + 0.5 > 10 ? 10 : s.sleepH + 0.5),
      numRow('Minutos sem jogo antes de deitar', '${s.wind}', () => s.wind = dec(s.wind, 5, 0), () => s.wind += 5),
      timeRow('A aula termina às', s.classEnd, (v) => s.classEnd = v),
      numRow('Minutos entre trabalho e aula', '${s.extra}', () => s.extra = dec(s.extra, 5, 0), () => s.extra += 5),
      numRow('Limite no domingo (min)', '${s.sunLimit}', () => s.sunLimit = dec(s.sunLimit, 10, 0), () => s.sunLimit += 10),
      numRow('Limite na véspera de folga (min)', '${s.offLimit}', () => s.offLimit = dec(s.offLimit, 10, 0), () => s.offLimit += 10),
      timeRow('Desligar na véspera de folga até', s.offEnd, (v) => s.offEnd = v),
      numRow('Bônus de sábado (min)', '${s.bonus}', () => s.bonus = dec(s.bonus, 10, 0), () => s.bonus += 10),
      const SizedBox(height: 10),
      Text(
        'Noite de semana: ${s.weekdayLimit} min de jogo, desligar ${fmt(s.off)}, deitar ${fmt(s.bed)}, acordar ${fmt(hm(s.wake))} a ${fmt(hm(s.wakeMax))}.',
        style: lb(16, color: gold, weight: 600),
      ),
    ]);
  }
}
