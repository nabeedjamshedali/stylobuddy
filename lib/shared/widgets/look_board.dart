import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'garment_image.dart';

enum LookBoardSize { normal, large, third }

/// Prototype `.look-board` (+ `.large` / `.third`, v2 and V22 overrides).
class LookBoard extends StatelessWidget {
  const LookBoard({
    super.key,
    required this.ids,
    this.size = LookBoardSize.normal,
    this.columns,
    this.minHeight,
    this.imageHeight,
    this.padding,
  });

  final List<String> ids;
  final LookBoardSize size;

  /// Optional overrides of the [size] defaults, for context-specific CSS such
  /// as `.outfit-card .look-board.third` (2 cols, 205, image 130).
  final int? columns;
  final double? minHeight;
  final double? imageHeight;
  final EdgeInsets? padding;

  int get _columns => columns ?? (size == LookBoardSize.third ? 3 : 2);

  double get _imageHeight =>
      imageHeight ??
      switch (size) {
        LookBoardSize.normal => 101,
        LookBoardSize.large => 132,
        LookBoardSize.third => 124,
      };

  double get _minHeight =>
      minHeight ??
      switch (size) {
        LookBoardSize.normal => 205,
        LookBoardSize.large => 285,
        LookBoardSize.third => 165,
      };

  EdgeInsets get _padding =>
      padding ?? EdgeInsets.all(size == LookBoardSize.third ? 7 : 14);

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < ids.length; i += _columns) {
      final cells = <Widget>[
        for (var c = 0; c < _columns; c++)
          Expanded(
            child: i + c < ids.length
                ? SizedBox(
                    height: _imageHeight,
                    child: GarmentImage(id: ids[i + c]),
                  )
                : const SizedBox.shrink(),
          ),
      ];
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 4));
      rows.add(Row(children: cells));
    }
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: _minHeight),
      padding: _padding,
      decoration: BoxDecoration(
        color: AppColors.productBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}
