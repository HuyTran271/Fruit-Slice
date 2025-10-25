import 'package:flutter/material.dart';
import '../gamecontroller/GameController.dart';
import '../entity/SliceEffect.dart';
import '../entity/Item.dart';
import '../entity/Particle.dart';

class GamePainter extends CustomPainter {
  final GameController c;
  final List<Offset> trail;
  final List<SliceEffect> sliceEffects;
  final List<Color> trailColors;
  final double devicePixelRatio;

  GamePainter(
    this.c,
    this.trail,
    this.sliceEffects,
    this.trailColors, {
    this.devicePixelRatio = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale canvas theo device pixel ratio
    canvas.scale(1 / devicePixelRatio);

    // Điều chỉnh các kích thước vẽ
    final baseRadius = size.width / 15; // Radius cơ bản cho fruits/items

    // 🎯 Vẽ Fruit
    for (final f in c.fruits) {
      for (final p in f.particles) {
        final paint = Paint()
          ..color = p.color.withOpacity(p.life)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(p.position, p.size, paint);
      }

      if (!f.isSliced && f.emoji != null) {
        canvas.save();
        canvas.translate(f.position.dx, f.position.dy);
        canvas.rotate(f.rotation);
        canvas.scale(f.scale);
        final tp = TextPainter(
          text: TextSpan(text: f.emoji, style: TextStyle(fontSize: f.radius * 2)),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }

    // 🎯 Vẽ Item
    for (final it in c.items) {
      if (!it.isSliced) {
        final glowPaint = Paint()
          ..color = _getItemGlowColor(it).withOpacity(it.glow * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
        canvas.drawCircle(it.position, it.radius * 1.5, glowPaint);

        if (it.emoji != null) {
          canvas.save();
          canvas.translate(it.position.dx, it.position.dy);
          canvas.rotate(it.rotation);
          final tp = TextPainter(
            text: TextSpan(text: it.emoji, style: TextStyle(fontSize: it.radius * 2)),
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
          canvas.restore();
        }
      }
    }

    // 🎯 Vẽ Trail
    if (trail.isNotEmpty) {
      for (int i = 0; i < trail.length - 1; i++) {
        final progress = i / trail.length;

        Color trailColor;
        if (trailColors.length == 1) {
          trailColor = trailColors[0].withOpacity(0.3 + progress * 0.5);
        } else {
          final colorIndex = (progress * (trailColors.length - 1));
          final index1 = colorIndex.floor();
          final index2 = (index1 + 1).clamp(0, trailColors.length - 1);
          final t = colorIndex - index1;
          trailColor = Color.lerp(
            trailColors[index1].withOpacity(0.3),
            trailColors[index2].withOpacity(0.8),
            t,
          )!;
        }

        final paint = Paint()
          ..color = trailColor
          ..strokeWidth = 6 * (1 - progress * 0.5)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawLine(trail[i], trail[i + 1], paint);
      }
    }

    // 🎯 Hiệu ứng chém
    for (final effect in sliceEffects) {
      final tp = TextPainter(
        text: TextSpan(
          text: effect.text,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.yellow.withOpacity(effect.opacity),
            shadows: [Shadow(blurRadius: 5, color: Colors.black.withOpacity(effect.opacity * 0.5))],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, effect.position + Offset(-tp.width / 2, effect.offsetY));
    }
  }

  Color _getItemGlowColor(Item item) {
    if (item is Bomb) return Colors.red;
    if (item is TimeItem) return Colors.blue;
    if (item is X2Item) return Colors.orange;
    return Colors.white;
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
