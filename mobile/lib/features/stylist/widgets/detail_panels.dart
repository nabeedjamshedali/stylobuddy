import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../models/look_piece.dart';
import '../stylist_tokens.dart';

/// `.od-wardrobe-note`.
class DetailWardrobeNote extends StatelessWidget {
  const DetailWardrobeNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '✓',
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w800,
              color: StylistTokens.odSave,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'Every item is from your wardrobe',
              style: AppTextStyles.dmSans(
                size: 10,
                color: StylistTokens.odNote,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: StylistTokens.odPanelBorder),
      ),
      child: child,
    );
  }
}

/// "Why this outfit works" panel with the three criteria chips.
class DetailWhyPanel extends StatelessWidget {
  const DetailWhyPanel({super.key, required this.why, required this.occasion});

  final String why;
  final String occasion;

  @override
  Widget build(BuildContext context) {
    final criteria = ['Visual harmony', 'Balanced proportions', '$occasion ready'];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                Text(
                  '✦',
                  style: AppTextStyles.dmSans(
                    size: 19,
                    color: StylistTokens.odSave,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  'Why this outfit works',
                  style: AppTextStyles.dmSans(
                    size: 13,
                    weight: FontWeight.w700,
                    letterSpacing: -.2,
                  ),
                ),
              ],
            ),
          ),
          Text(
            why,
            style: AppTextStyles.dmSans(
              size: 11,
              height: 1.75,
              color: StylistTokens.odPanelBody,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in criteria)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: StylistTokens.odCriteriaBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: StylistTokens.odCriteriaBorder),
                  ),
                  child: Text(
                    c,
                    style: AppTextStyles.dmSans(
                      size: 9,
                      color: StylistTokens.odCriteriaInk,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Your pieces" panel with a swap button per piece.
class DetailItemsPanel extends StatelessWidget {
  const DetailItemsPanel({
    super.key,
    required this.pieces,
    required this.onSwap,
  });

  final List<LookPiece> pieces;
  final ValueChanged<LookPiece> onSwap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                Text(
                  'Your pieces',
                  style: AppTextStyles.dmSans(
                    size: 13,
                    weight: FontWeight.w700,
                    letterSpacing: -.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${pieces.length} items',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: StylistTokens.odCount,
                  ),
                ),
              ],
            ),
          ),
          for (final piece in pieces)
            _ItemRow(piece: piece, onSwap: () => onSwap(piece)),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.piece, required this.onSwap});

  final LookPiece piece;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final button = Opacity(
      opacity: piece.locked ? .5 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: piece.locked ? null : onSwap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: StylistTokens.odSwapBg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: StylistTokens.odSwapBorder),
          ),
          child: Text(
            piece.locked ? 'Locked' : 'Swap',
            style: AppTextStyles.dmSans(size: 10, color: StylistTokens.odSwapInk),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: StylistTokens.odItemBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: StylistTokens.odThumbBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: GarmentImage(id: piece.imageId),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  piece.name,
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${piece.item.category} · ${piece.item.color}',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    color: StylistTokens.odItemSub,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          piece.locked
              ? Tooltip(
                  message: 'Unlock this piece in Match My Clothes first',
                  triggerMode: TooltipTriggerMode.tap,
                  child: button,
                )
              : button,
        ],
      ),
    );
  }
}

/// `.od-actions`: Save / Plan / Share / New suggestions.
class DetailActions extends StatelessWidget {
  const DetailActions({
    super.key,
    required this.onSave,
    required this.onPlan,
    required this.onShare,
    required this.onRefresh,
  });

  final VoidCallback onSave;
  final VoidCallback onPlan;
  final VoidCallback onShare;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Action(
                  label: '♡ Save Outfit',
                  background: StylistTokens.odSave,
                  ink: AppColors.white,
                  onTap: onSave,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _Action(
                  label: '▦ Plan Outfit',
                  background: AppColors.white,
                  ink: StylistTokens.odSave,
                  border: StylistTokens.odSave,
                  onTap: onPlan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _Action(
                  label: '↗ Share look',
                  background: StylistTokens.odLightBg,
                  ink: StylistTokens.odLightInk,
                  border: StylistTokens.odLightBorder,
                  onTap: onShare,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _Action(
                  label: '↻ New suggestions',
                  background: StylistTokens.odLightBg,
                  ink: StylistTokens.odLightInk,
                  border: StylistTokens.odLightBorder,
                  onTap: onRefresh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.background,
    required this.ink,
    required this.onTap,
    this.border,
  });

  final String label;
  final Color background;
  final Color ink;
  final Color? border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 43),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
          border: border == null ? null : Border.all(color: border!),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: ink,
          ),
        ),
      ),
    );
  }
}
