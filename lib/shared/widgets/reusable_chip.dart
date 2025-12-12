import 'package:flutter/material.dart';

class ReusableChip extends StatelessWidget {
  final void Function()? onTap;
  final String title;
  const ReusableChip({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(title),
        ),
      ),
    );
  }
}
