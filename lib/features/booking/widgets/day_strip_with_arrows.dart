import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayStripWithArrows extends StatelessWidget {
  final ScrollController controller;
  final List<DateTime> days;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const DayStripWithArrows({
    super.key,
    required this.controller,
    required this.days,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    void scrollBy(double dx) {
      if (!controller.hasClients) return;
      final max = controller.position.maxScrollExtent;
      final next = (controller.offset + dx).clamp(0.0, max);
      controller.animateTo(
        next,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }

    return Row(
      children: [
        IconButton(
          tooltip: 'Previous days',
          onPressed: () => scrollBy(-220),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: SizedBox(
            height: 46,
            child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final day = days[i];
                final isSelected = i == selectedIndex;
                final label = DateFormat('EEE d').format(day);

                return ChoiceChip(
                  selected: isSelected,
                  label: Text(label),
                  onSelected: (_) => onSelected(i),
                );
              },
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next days',
          onPressed: () => scrollBy(220),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}