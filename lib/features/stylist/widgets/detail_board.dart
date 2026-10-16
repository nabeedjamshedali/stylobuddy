import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../models/look_piece.dart';
import '../stylist_tokens.dart';

/// Prototype `.od-board`: 1.25fr/1fr grid, 113px rows, first piece spans two
/// rows. Tapping a piece opens its clothing detail.
class DetailBoard extends StatelessWidget {
  const DetailBoard({super.key, required this.pieces, required this.onOpen});

  final List<LookPiece> pieces;
  final ValueChanged<LookPiece> onOpen;

  static const _row = 113.0;
  static const _gap = 7.0;

  Widget _cell(LookPiece piece, {double? height}) => SizedBox(
    height: height ?? _row,
    child: _Garment(piece: piece, onTap: () => onOpen(piece)),
  );

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (pieces.isNotEmpty) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 125,
              child: _cell(pieces[0], height: _row * 2 + _gap),
            ),
            const SizedBox(width: _gap),
            Expanded(
              flex: 100,
              child: Column(
                children: [
                  if (pieces.length > 1) _cell(pieces[1]),
                  if (pieces.length > 2) ...[
                    const SizedBox(height: _gap),
                    _cell(pieces[2]),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
      for (var i = 3; i < pieces.length; i += 2) {
        rows.add(const SizedBox(height: _gap));
        rows.add(
          Row(
            children: [
              Expanded(flex: 125, child: _cell(pieces[i])),
              const SizedBox(width: _gap),
              Expanded(
                flex: 100,
                child: i + 1 < pieces.length
                    ? _cell(pieces[i + 1])
                    : const SizedBox(height: _row),
              ),
            ],
          ),
        );
      }
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: StylistTokens.odBoardBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(children: rows),
    );
  }
}

class _Garment extends StatelessWidget {
  const _Garment({required this.piece, required this.onTap});

  final LookPiece piece;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Tooltip(
        message: 'View ${piece.name}',
        child: Container(
          padding: const EdgeInsets.all(5),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: StylistTokens.odGarmentBorder),
          ),
          child: Column(
            children: [
              Expanded(child: GarmentImage(id: piece.imageId)),
              Padding(
                padding: const EdgeInsets.only(top: 3, bottom: 1),
                child: Text(
                  '${piece.name}${piece.locked ? ' · Locked' : ''}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w600,
                    height: 1.25,
                    color: StylistTokens.odGarmentLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
