import 'package:flutter/material.dart';

import '../models/scanned_document.dart';

/// Widget for selecting filters in the editor screen
class FilterSelector extends StatelessWidget {
  final FilterType selectedFilter;
  final Function(FilterType) onFilterSelected;

  const FilterSelector({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: FilterType.values.length,
        itemBuilder: (context, index) {
          final filter = FilterType.values[index];
          final isSelected = filter == selectedFilter;
          
          return _buildFilterOption(filter, isSelected);
        },
      ),
    );
  }

  Widget _buildFilterOption(FilterType filter, bool isSelected) {
    return GestureDetector(
      onTap: () => onFilterSelected(filter),
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // Filter preview box
            Container(
              width: 60,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
                color: _getFilterPreviewColor(filter),
              ),
              child: Center(
                child: Icon(
                  _getFilterIcon(filter),
                  size: 24,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
            
            // Filter name
            const SizedBox(height: 4),
            Text(
              filter.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getFilterPreviewColor(FilterType filter) {
    switch (filter) {
      case FilterType.none:
        return Colors.white;
      case FilterType.grayscale:
        return Colors.grey[400]!;
      case FilterType.blackAndWhite:
        return Colors.black;
      case FilterType.magicColor:
        return Colors.lightBlue[100]!;
      case FilterType.lighten:
        return Colors.yellow[100]!;
      case FilterType.darken:
        return Colors.grey[800]!;
    }
  }

  IconData _getFilterIcon(FilterType filter) {
    switch (filter) {
      case FilterType.none:
        return Icons.filter_none;
      case FilterType.grayscale:
        return Icons.grain;
      case FilterType.blackAndWhite:
        return Icons.contrast;
      case FilterType.magicColor:
        return Icons.auto_awesome;
      case FilterType.lighten:
        return Icons.brightness_high;
      case FilterType.darken:
        return Icons.brightness_low;
    }
  }
}
