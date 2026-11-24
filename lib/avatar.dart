// O personagem do jogador: quadros de caminhada de frente e de lado (assets/avatar).
// O humor muda a velocidade, a cor e os efeitos em volta (brilhos, sono, nuvem de chuva).
import 'dart:async';

import 'package:flutter/material.dart';

const frontFrames = [
  'assets/avatar/front_1.png',
  'assets/avatar/front_2.png',
  'assets/avatar/front_3.png',
  'assets/avatar/front_4.png',
  'assets/avatar/front_5.png',
  'assets/avatar/front_6.png',
];
const walkFrames = [
  'assets/avatar/walk_1.png',
  'assets/avatar/walk_2.png',
  'assets/avatar/walk_3.png',
  'assets/avatar/walk_4.png',
  'assets/avatar/walk_5.png',
  'assets/avatar/walk_6.png',
];

/// Proporção de cada quadro (largura / altura).
const avatarAspect = 324 / 496;

/// Carrega os quadros antes de aparecerem, pra animação não piscar.
Future<void> precacheAvatar(BuildContext context) async {
  for (final f in [...frontFrames, ...walkFrames]) {
    await precacheImage(AssetImage(f), context);
  }
}

/// Milissegundos por quadro em cada humor (0 = parado).
int avatarFrameMs(String mood, {bool sleeping = false}) {
  if (sleeping) return 0;
  switch (mood) {
    case 'top':
      return 110;
    case 'good':
    case 'start':
      return 150;
    case 'ok':
      return 210;
    case 'tired':
      return 360;
    default:
      return 0; // mal: fica parado
  }
}

/// Filtro de cor: cansado fica mais apagado, mal fica quase sem cor.
ColorFilter? avatarFilter(String mood, {bool sleeping = false}) {
  if (sleeping) {
    return const ColorFilter.matrix([
      0.6, 0, 0, 0, 0, //
      0, 0.6, 0, 0, 0,
      0, 0, 0.75, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }
  if (mood == 'tired') {
    return const ColorFilter.matrix([
      0.8, 0.05, 0.05, 0, 0, //
      0.05, 0.8, 0.05, 0, 0,
      0.05, 0.05, 0.85, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }
  if (mood == 'bad') {
    return const ColorFilter.matrix([
      0.45, 0.35, 0.12, 0, 0, //
      0.25, 0.55, 0.12, 0, 0,
      0.25, 0.35, 0.4, 0, 10,
      0, 0, 0, 1, 0,
    ]);
  }
  return null;
}

/// Pulinho do humor "muito bem" (em fração da altura).
double avatarHop(String mood, int frame) {
  if (mood != 'top') return 0;
  const hop = [0.0, -0.02, -0.035, -0.02, 0.0, 0.0];
  return hop[frame % hop.length];
}

/// Efeitos desenhados por cima do personagem.
class AvatarFxPainter extends CustomPainter {
  final String mood;
  final int frame;
  final bool sleeping;
  final bool playing;
  AvatarFxPainter(this.mood, this.frame, {this.sleeping = false, this.playing = false});

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.height / 64; // "pixel" do efeito
    final p = Paint()..isAntiAlias = false;
    void px(double x, double y, Color c, [double w = 1, double h = 1]) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), p);
    }

    final cols = size.width / u;
    if (sleeping || mood == 'tired') {
      const z = Color(0xFFF7F3FF);
      final rise = (frame % 6).toDouble();
      final x = cols * 0.68;
      final y = 6 - rise;
      // letra Z em pixels
      px(x, y, z, 4, 1);
      px(x + 2, y + 1, z);
      px(x + 1, y + 2, z);
      px(x, y + 3, z, 4, 1);
      if (sleeping) {
        px(x + 5, y - 4, z, 3, 1);
        px(x + 6, y - 3, z);
        px(x + 5, y - 2, z, 3, 1);
      }
    }
    if (mood == 'top' && !sleeping) {
      const gold = Color(0xFFFFD23F);
      final spots = [
        [0.08, 0.18], [0.86, 0.12], [0.04, 0.5], [0.9, 0.45], [0.8, 0.78], [0.12, 0.8],
      ];
      for (var i = 0; i < spots.length; i++) {
        if ((frame + i) % 3 == 0) continue;
        final sx = spots[i][0] * cols, sy = spots[i][1] * 64;
        px(sx, sy - 1, gold);
        px(sx - 1, sy, gold, 3, 1);
        px(sx, sy + 1, gold);
      }
    }
    if (mood == 'bad' && !sleeping) {
      const cloud = Color(0xFF8D88B8);
      const dark = Color(0xFF5B54A8);
      const drop = Color(0xFF7FD0FF);
      final cx = cols / 2 - 8;
      px(cx + 2, 0, cloud, 12, 2);
      px(cx, 1.5, cloud, 16, 3);
      px(cx + 3, 4.5, dark, 10, 1);
      for (var i = 0; i < 5; i++) {
        final dy = ((frame + i * 2) % 4) * 1.5;
        px(cx + 1.5 + i * 3.2, 6 + dy, drop, 1, 2);
      }
    }
    if (playing && !sleeping) {
      // controle na mão
      const k = Color(0xFF8D88B8);
      const y = Color(0xFFFFD23F);
      final x = cols / 2 - 4;
      px(x, 30, k, 8, 3);
      px(x - 1, 31, k, 1, 3);
      px(x + 8, 31, k, 1, 3);
      px(x + 1, 31, y);
      px(x + 6, 31, const Color(0xFFFF5A5A));
    }
  }

  @override
  bool shouldRepaint(AvatarFxPainter o) =>
      o.mood != mood || o.frame != frame || o.sleeping != sleeping || o.playing != playing;
}

/// Personagem parado no lugar, de frente (cartão "Meu personagem" e alarmes).
class AvatarView extends StatefulWidget {
  final String mood;
  final bool playing, sleeping;
  final double size; // altura
  const AvatarView({super.key, required this.mood, this.playing = false, this.sleeping = false, this.size = 170});
  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> {
  int frame = 1;
  Timer? t;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(AvatarView old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood || old.sleeping != widget.sleeping) _start();
  }

  void _start() {
    t?.cancel();
    final ms = avatarFrameMs(widget.mood, sleeping: widget.sleeping);
    // mesmo parado, os efeitos (chuva, Zzz) continuam se mexendo
    t = Timer.periodic(Duration(milliseconds: ms == 0 ? 260 : ms), (_) => setState(() => frame++));
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moving = avatarFrameMs(widget.mood, sleeping: widget.sleeping) > 0;
    final idx = moving ? frame % frontFrames.length : 1;
    final h = widget.size;
    final w = h * avatarAspect;
    Widget img = Image.asset(frontFrames[idx],
        width: w, height: h, fit: BoxFit.contain, filterQuality: FilterQuality.none, gaplessPlayback: true);
    final f = avatarFilter(widget.mood, sleeping: widget.sleeping);
    if (f != null) img = ColorFiltered(colorFilter: f, child: img);
    return SizedBox(
      width: w + h * 0.25,
      height: h,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
        Positioned(
          bottom: 2,
          child: Container(width: w * 0.7, height: h * 0.03, color: const Color(0x55000000)),
        ),
        Transform.translate(offset: Offset(0, avatarHop(widget.mood, frame) * h), child: img),
        Positioned.fill(
          child: CustomPaint(
              painter: AvatarFxPainter(widget.mood, frame, sleeping: widget.sleeping, playing: widget.playing)),
        ),
      ]),
    );
  }
}

/// Personagem andando pela cena noturna, de um lado pro outro.
class WalkingAvatar extends StatefulWidget {
  final String mood;
  final bool playing, sleeping;
  const WalkingAvatar({super.key, required this.mood, this.playing = false, this.sleeping = false});
  @override
  State<WalkingAvatar> createState() => _WalkingAvatarState();
}

class _WalkingAvatarState extends State<WalkingAvatar> {
  int frame = 0;
  double x = 0.45; // posição (0 a 1)
  int dir = 1;
  Timer? t;

  bool get standing => widget.sleeping || widget.playing || widget.mood == 'bad';

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(WalkingAvatar old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood || old.sleeping != widget.sleeping || old.playing != widget.playing) _start();
  }

  void _start() {
    t?.cancel();
    final ms = avatarFrameMs(widget.mood, sleeping: widget.sleeping);
    t = Timer.periodic(Duration(milliseconds: ms == 0 ? 260 : ms), (_) {
      setState(() {
        frame++;
        if (!standing) {
          final step = widget.mood == 'top' ? 0.018 : (widget.mood == 'tired' ? 0.006 : 0.011);
          x += step * dir;
          if (x > 0.78) {
            x = 0.78;
            dir = -1;
          } else if (x < 0.12) {
            x = 0.12;
            dir = 1;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final h = c.maxHeight * 0.66;
      final w = h * avatarAspect;
      final ground = c.maxHeight * (116 / 130);
      final left = (c.maxWidth - w) * x;
      final frames = standing ? frontFrames : walkFrames;
      final idx = standing ? (widget.playing ? frame % frontFrames.length : 1) : frame % walkFrames.length;
      Widget img = Image.asset(frames[idx],
          width: w, height: h, fit: BoxFit.contain, filterQuality: FilterQuality.none, gaplessPlayback: true);
      final f = avatarFilter(widget.mood, sleeping: widget.sleeping);
      if (f != null) img = ColorFiltered(colorFilter: f, child: img);
      if (!standing && dir < 0) {
        img = Transform(alignment: Alignment.center, transform: Matrix4.diagonal3Values(-1, 1, 1), child: img);
      }
      final hop = avatarHop(widget.mood, frame) * h;
      return Stack(children: [
        Positioned(
          left: left,
          top: ground - h + hop,
          width: w,
          height: h,
          child: Stack(children: [
            img,
            Positioned.fill(
              child: CustomPaint(
                  painter: AvatarFxPainter(widget.mood, frame, sleeping: widget.sleeping, playing: widget.playing)),
            ),
          ]),
        ),
      ]);
    });
  }
}
