// Pixel art original do Noite Quest, desenhada a partir de mapas de caracteres.
import 'package:flutter/material.dart';

const Map<String, Color> pal = {
  'K': Color(0xFF0B0920),
  'R': Color(0xFFFF5D8F),
  'S': Color(0xFFFFC9A3),
  'M': Color(0xFFB3475F),
  'B': Color(0xFF56CFFF),
  'G': Color(0xFF8D88B8),
  'g': Color(0xFFFFD23F),
  'Y': Color(0xFFFFD23F),
  'y': Color(0xFFE6A800),
  'W': Color(0xFFF7F3FF),
  'O': Color(0xFFFF9F43),
  'r': Color(0xFFFF5A5A),
  'D': Color(0xFF6B4B2A),
  'd': Color(0xFF8A6436),
  'P': Color(0xFFB3ACDF),
};

const Map<String, List<String>> spr = {
  'hero': [
    '....KKKKKK......', '...KRRRRRRK.....', '..KRRRRRRRRK....', '..KKKKKKKKKKKK..',
    '..KSSSSSSSK.....', '..KSKSSSKSK.....', '..KSSSSSSSK.....', '...KSSMMSK......',
    '....KKKKK.......', '..KBBBBBBBK.....', '.KBBGGGGGBBK....', '.KSKGgGgGKSK....',
    '..KKGGGGGKK.....', '...KBBKBBK......', '...KBBKBBK......', '...KKK.KKK......',
  ],
  'moon': [
    '....YYYY....', '..YYYYYY....', '.YYYYYy.....', '.YYYYy......', 'YYYYYy......', 'YYYYy.......',
    'YYYYy.......', 'YYYYYy......', '.YYYYy......', '.YYYYYy.....', '..YYYYYY....', '....YYYY....',
  ],
  'star': ['...Y....', '...Y....', '..YYY...', 'YYYYYYY.', '..YYY...', '.YY.YY..', 'YY...YY.', '........'],
  'fire': ['...O....', '..OO....', '..OrO...', '.OrrO.O.', '.OrYrOO.', 'OrYYYrO.', 'OrYYYrO.', '.OOOOO..'],
  'lock': ['..KKKK..', '.K....K.', '.K....K.', 'KKKKKKKK', 'KggggggK', 'KgggKggK', 'KgggKggK', 'KKKKKKKK'],
  'chest': [
    '..KKKKKK..', '.KdddddK..', 'KdDDDDDdK.', 'KKKKgKKKKK', 'KdDDgDDDdK', 'KdDDDDDDdK', 'KdDDDDDDdK', 'KKKKKKKKKK',
  ],
  'chestOpen': [
    'KYYYYYYYYK', 'KYgYYgYYgK', 'KKKKKKKKKK', 'KdDDgDDDdK', 'KdDDDDDDdK', 'KdDDDDDDdK', 'KdDDDDDDdK', 'KKKKKKKKKK',
  ],
  'x': ['rr....rr', '.rr..rr.', '..rrrr..', '...rr...', '..rrrr..', '.rr..rr.', 'rr....rr', '........'],
  'dot': ['........', '........', '...PP...', '..PPPP..', '..PPPP..', '...PP...', '........', '........'],
  'bed': ['K.........', 'K.........', 'KWW.......', 'KWWBBBBBBK', 'KBBBBBBBBK', 'KKKKKKKKKK', 'K........K'],
  'zz': ['KKKKK...', '...K....', '..K.....', 'KKKKK...', '........', '...KKK..', '....K...', '...KKK..'],
  'heart': ['.rr.rr..', 'rrrrrrr.', 'rrrrrrr.', 'rrrrrrr.', '.rrrrr..', '..rrr...', '...r....'],
  'heartHalf': ['.rr.PP..', 'rrrr..P.', 'rrrr..P.', 'rrrr..P.', '.rrr.P..', '..rrP...', '...r....'],
  'heartEmpty': ['.PP.PP..', 'P..P..P.', 'P.....P.', 'P.....P.', '.P...P..', '..P.P...', '...P....'],
  'sun': ['....Y....', '..Y.Y.Y..', '...YYY...', '.YYYYYYY.', 'YYYYYYYYY', '.YYYYYYY.', '...YYY...', '..Y.Y.Y..', '....Y....'],
};

void drawSprite(Canvas c, String name, double x, double y, double s) {
  final m = spr[name];
  if (m == null) return;
  final p = Paint()..isAntiAlias = false;
  for (var r = 0; r < m.length; r++) {
    for (var col = 0; col < m[r].length; col++) {
      final color = pal[m[r][col]];
      if (color == null) continue;
      p.color = color;
      c.drawRect(Rect.fromLTWH(x + col * s, y + r * s, s + 0.4, s + 0.4), p);
    }
  }
}

class _SpritePainter extends CustomPainter {
  final String name;
  _SpritePainter(this.name);
  @override
  void paint(Canvas canvas, Size size) {
    final m = spr[name]!;
    drawSprite(canvas, name, 0, 0, size.width / m[0].length);
  }

  @override
  bool shouldRepaint(_SpritePainter old) => old.name != name;
}

class Sprite extends StatelessWidget {
  final String name;
  final double scale;
  const Sprite(this.name, {super.key, this.scale = 3});
  @override
  Widget build(BuildContext context) {
    final m = spr[name]!;
    return SizedBox(
      width: m[0].length * scale,
      height: m.length * scale,
      child: CustomPaint(painter: _SpritePainter(name)),
    );
  }
}

/// Cena noturna: céu, estrelas piscando, lua, prédios e o herói.
class ScenePainter extends CustomPainter {
  final int frame;
  final bool playing, sleeping, won;
  final String mood;
  ScenePainter(this.frame, {this.playing = false, this.sleeping = false, this.won = false, this.mood = 'start'});

  static final _stars = List.generate(46, (i) => [(i * 73) % 318 + 1, (i * 37) % 70 + 2, i % 5]);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320, size.height / 130);
    final p = Paint()..isAntiAlias = false;
    void rect(double x, double y, double w, double h, Color c) {
      p.color = c;
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), p);
    }

    rect(0, 0, 320, 130, const Color(0xFF15123B));
    rect(0, 60, 320, 40, const Color(0xFF1B1750));
    for (final s in _stars) {
      final on = (frame + s[2]) % 5 != 0;
      final c = on ? const Color(0xFFF7F3FF) : const Color(0xFF5B54A8);
      rect(s[0].toDouble(), s[1].toDouble(), 1, 1, c);
      if (s[2] == 0) {
        rect(s[0] - 1.0, s[1].toDouble(), 3, 1, c);
        rect(s[0].toDouble(), s[1] - 1.0, 1, 3, c);
      }
    }
    drawSprite(canvas, 'moon', 266, 12, 2);
    const city = Color(0xFF0E0C2E);
    for (final b in const [
      [0, 92, 18, 38], [20, 86, 14, 44], [36, 96, 22, 34], [60, 82, 12, 48], [200, 90, 16, 40],
      [218, 80, 20, 50], [240, 94, 26, 36], [268, 86, 14, 44], [284, 98, 36, 32],
    ]) {
      rect(b[0].toDouble(), b[1].toDouble(), b[2].toDouble(), b[3].toDouble(), city);
    }
    for (final w in const [[24, 92], [28, 100], [64, 88], [64, 96], [222, 86], [230, 94], [226, 104], [272, 92]]) {
      rect(w[0].toDouble(), w[1].toDouble(), 2, 2, const Color(0xFFFFD23F));
    }
    rect(0, 116, 320, 14, const Color(0xFF2A6B4F));
    for (var x = 0; x < 320; x += 4) {
      rect(x.toDouble(), 116, 2, 2, const Color(0xFF3EE0A1));
    }
    // o personagem é desenhado por cima, com os quadros de animação (WalkingAvatar)
    if (won && !sleeping) drawSprite(canvas, 'star', 296, 96.0 - (frame % 2) * 2, 2);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ScenePainter old) =>
      old.frame != frame || old.playing != playing || old.sleeping != sleeping || old.won != won || old.mood != mood;
}
