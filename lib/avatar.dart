// O personagem do jogador em 8-bit: cabelo escuro, óculos pretos, bigode e cavanhaque,
// casaco azul, camisa preta, calça jeans e tênis branco. Muda de cara conforme a saúde.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const Map<String, Color> avPal = {
  'H': Color(0xFF2A1F24), // cabelo
  'h': Color(0xFF4A3A3E), // brilho do cabelo
  'S': Color(0xFFC58A5C), // pele
  's': Color(0xFFA06A45), // sombra da pele
  'l': Color(0xFFD9A070), // luz da pele
  'G': Color(0xFF15141C), // armação dos óculos
  'E': Color(0xFFEDE6E2), // branco do olho / reflexo da lente
  'P': Color(0xFF2A1F24), // pupila
  'M': Color(0xFF4E3226), // bigode e cavanhaque
  'm': Color(0xFF8A4A3A), // boca
  'W': Color(0xFFF4F4F4), // dentes e tênis
  'w': Color(0xFFC9C9C9), // sola do tênis
  'J': Color(0xFF2F6FD6), // casaco azul
  'j': Color(0xFF1F4FA0), // dobra do casaco
  'T': Color(0xFF17171C), // camisa preta
  'D': Color(0xFF3F63A3), // jeans
  'd': Color(0xFF2C4A7D), // costura do jeans
  'B': Color(0xFF7FD0FF), // lágrima
  'g': Color(0xFF8D88B8), // controle
  'y': Color(0xFFFFD23F), // botões do controle
};

// 16 colunas x 26 linhas
const List<String> _base = [
  '....HHHHHHH.....',
  '...HHHHHhHHH....',
  '..HHhHHHHHHhH...',
  '..HHHHHHHHHHH...',
  '..HlSSSSSSSlH...',
  '.sSGGGGSGGGGSs..',
  '.sSGEPGSGPEGSs..', // 6: olhos
  '..SGllGSGllGS...',
  '..SSSSSsSSSSS...', // 8: abaixo dos olhos
  '..SSSMMMMMSSS...',
  '...SSSmmmSSS....', // 10: boca
  '....SMMMMMS.....', // 11: queixo
  '.....SSSSS......',
  '...JJJTTTJJJ....',
  '..JJJJTTTJJJJ...',
  '.JJjJJTTTJJjJJ..',
  '.JJjJJTTTJJjJJ..',
  '.SJjJJTTTJJjJS..', // 17: mãos
  '..JJJJJJJJJJJ...',
  '...DDDDDDDDD....',
  '...DDDDdDDDD....',
  '...DDDD.DDDD....',
  '...DDDd.dDDD....',
  '...DDDD.DDDD....',
  '..WWWWW.WWWWW...',
  '..wwwww.wwwww...',
];

/// top: muito bem · good: bem · ok · tired: cansado · bad: mal · start: começando
List<String> avatarRows(String mood, {bool blink = false, bool playing = false, bool sleeping = false}) {
  final r = List<String>.from(_base);
  // olhos
  if (blink || sleeping || mood == 'tired') {
    r[6] = '.sSGPPGSGPPGSs..';
  }
  if (mood == 'tired' || mood == 'bad') {
    r[8] = '..SSsSSsSSsSS...'; // olheiras
  }
  // boca
  switch (mood) {
    case 'top':
      r[10] = '...SmWWWWWmS....';
      r[11] = '....SMmmmMS.....';
      break;
    case 'good':
    case 'start':
      r[10] = '...SSmSSSmSS....';
      r[11] = '....SMmmmMS.....';
      break;
    case 'bad':
      r[10] = '...SSSmmmSSS....';
      r[11] = '....SmMMMmS.....';
      r[8] = '..BSsSSsSSsSS...'; // lágrima
      break;
    case 'tired':
      r[10] = '...SSSSmSSSS....';
      break;
    default:
      break;
  }
  if (sleeping) {
    r[10] = '...SSSSSSSSS....';
  }
  if (playing) {
    r[16] = '.JJjgggggggjJJ..';
    r[17] = '.SJgyggggyggJS..';
  }
  return r;
}

void drawAvatar(Canvas c, List<String> rows, double x, double y, double s) {
  final p = Paint()..isAntiAlias = false;
  for (var r = 0; r < rows.length; r++) {
    for (var col = 0; col < rows[r].length; col++) {
      final color = avPal[rows[r][col]];
      if (color == null) continue;
      p.color = color;
      c.drawRect(Rect.fromLTWH(x + col * s, y + r * s, s + 0.4, s + 0.4), p);
    }
  }
}

/// Deslocamento vertical da animação para cada humor.
double avatarBob(String mood, int frame) {
  switch (mood) {
    case 'top':
      const jump = [0, -3, -6, -3, 0, 0];
      return jump[frame % jump.length].toDouble();
    case 'good':
    case 'start':
      return (frame % 4 < 2) ? 0 : -1;
    case 'ok':
      return (frame % 6 < 3) ? 0 : -1;
    case 'tired':
      return (frame % 8 < 4) ? 0 : 1;
    default:
      return 1;
  }
}

/// Efeitos em volta do personagem (brilhos, nuvem de chuva, Zzz).
void drawAvatarFx(Canvas c, String mood, int frame, double x, double y, double s, {bool sleeping = false}) {
  final p = Paint()..isAntiAlias = false;
  void px(double cx, double cy, Color col, [double w = 1, double h = 1]) {
    p.color = col;
    c.drawRect(Rect.fromLTWH(x + cx * s, y + cy * s, w * s, h * s), p);
  }

  if (sleeping) {
    final o = (frame % 3).toDouble();
    const z = Color(0xFFF7F3FF);
    px(15, -2 - o, z, 3, 1);
    px(16, -1 - o, z);
    px(15, 0 - o, z, 3, 1);
    return;
  }
  if (mood == 'top') {
    const gold = Color(0xFFFFD23F);
    final spots = [
      [-3.0, 2.0], [17.0, 4.0], [-2.0, 12.0], [18.0, 14.0], [16.0, -1.0], [-4.0, 7.0],
    ];
    for (var i = 0; i < spots.length; i++) {
      if ((frame + i) % 3 == 0) continue;
      final sx = spots[i][0], sy = spots[i][1];
      px(sx, sy - 1, gold);
      px(sx - 1, sy, gold, 3, 1);
      px(sx, sy + 1, gold);
    }
  }
  if (mood == 'bad') {
    const cloud = Color(0xFF8D88B8);
    const dark = Color(0xFF5B54A8);
    px(3, -7, cloud, 10, 2);
    px(2, -6, cloud, 12, 2);
    px(4, -8, dark, 4, 1);
    px(9, -8, dark, 3, 1);
    const drop = Color(0xFF7FD0FF);
    for (var i = 0; i < 4; i++) {
      final dx = 4.0 + i * 3;
      final dy = -3.0 + ((frame + i) % 3);
      px(dx, dy, drop);
    }
  }
  if (mood == 'tired') {
    const z = Color(0xFFB3ACDF);
    final o = (frame % 4).toDouble();
    px(14, -1 - o, z, 2, 1);
  }
}

class _AvatarPainter extends CustomPainter {
  final String mood;
  final int frame;
  final bool playing, sleeping;
  _AvatarPainter(this.mood, this.frame, this.playing, this.sleeping);

  @override
  void paint(Canvas canvas, Size size) {
    // área lógica de 26 x 36 px: personagem 16 x 26 no meio, com espaço para efeitos
    final s = math.min(size.width / 26, size.height / 36);
    final ox = (size.width - 26 * s) / 2 + 5 * s;
    final oy = (size.height - 36 * s) / 2 + 9 * s;
    final blink = frame % 14 == 0;
    final rows = avatarRows(mood, blink: blink, playing: playing, sleeping: sleeping);
    final bob = sleeping ? 0.0 : avatarBob(mood, frame);
    // sombra no chão
    final sh = Paint()..color = const Color(0x55000000);
    canvas.drawRect(Rect.fromLTWH(ox + 2 * s, oy + 26 * s, 12 * s, 1 * s), sh);
    drawAvatar(canvas, rows, ox, oy + bob * s, s);
    drawAvatarFx(canvas, mood, frame, ox, oy + bob * s, s, sleeping: sleeping);
  }

  @override
  bool shouldRepaint(_AvatarPainter o) =>
      o.mood != mood || o.frame != frame || o.playing != playing || o.sleeping != sleeping;
}

class AvatarView extends StatefulWidget {
  final String mood;
  final bool playing, sleeping;
  final double size;
  const AvatarView({super.key, required this.mood, this.playing = false, this.sleeping = false, this.size = 150});
  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> {
  int frame = 0;
  Timer? t;
  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(milliseconds: 220), (_) => setState(() => frame++));
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size * 26 / 36,
        height: widget.size,
        child: CustomPaint(painter: _AvatarPainter(widget.mood, frame, widget.playing, widget.sleeping)),
      );
}
