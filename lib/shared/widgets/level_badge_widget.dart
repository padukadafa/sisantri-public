import 'package:flutter/material.dart';
import 'package:sisantri/shared/models/level_model.dart';

class LevelBadgeWidget extends StatelessWidget {
  final int totalPoin;
  final double size;
  final bool showTitle;

  const LevelBadgeWidget({
    super.key,
    required this.totalPoin,
    this.size = 48,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final level = LevelModel.fromPoin(totalPoin);
    final color = Color(int.parse(level.color.replaceFirst('#', '0xFF')));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(level.badge, style: TextStyle(fontSize: size * 0.5)),
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 4),
          Text(
            'Lv.${level.level}',
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
