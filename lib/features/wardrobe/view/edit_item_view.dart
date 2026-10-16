import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/data/seed_data.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../../shared/widgets/select_field.dart';
import '../cubit/wardrobe_cubit.dart';
import '../wardrobe_tokens.dart';

/// Prototype `pages['edit-item']`.
class EditItemView extends StatefulWidget {
  const EditItemView({super.key, required this.id});

  final String id;

  @override
  State<EditItemView> createState() => _EditItemViewState();
}

class _EditItemViewState extends State<EditItemView> {
  late TextEditingController _nameController;
  late String _category;
  late String _color;
  late String _occasion;
  late String _season;
  bool _initialized = false;

  void _initFrom(WardrobeCubit wardrobe) {
    if (_initialized) return;
    final item = wardrobe.itemOrFallback(widget.id);
    _nameController = TextEditingController(text: item.name);
    _category = item.category;
    _color = item.color;
    _occasion = item.occasion;
    _season = item.season;
    _initialized = true;
  }

  void _save(BuildContext context, WardrobeCubit wardrobe) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.show(context, 'Enter an item name');
      return;
    }
    final item = wardrobe.itemOrFallback(widget.id);
    wardrobe.updateItem(
      item.copyWith(
        name: name,
        category: _category,
        color: _color,
        occasion: _occasion,
        season: _season,
      ),
    );
    AppToast.show(context, 'Clothing updated');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.clothing(widget.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeCubit>();
    _initFrom(wardrobe);
    final item = wardrobe.itemOrFallback(widget.id);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHead(
            title: 'Edit Item',
            fallbackRoute: AppRoutes.clothing(widget.id),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: WardrobeTokens.editHeroBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 105,
                  height: 105,
                  decoration: BoxDecoration(
                    color: WardrobeTokens.detailPhotoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(child: GarmentImage(id: item.imageId)),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EDITING YOUR WARDROBE',
                        style: AppTextStyles.dmSans(
                          size: 9,
                          weight: FontWeight.w800,
                          letterSpacing: 1.35,
                          color: WardrobeTokens.eyebrow,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        item.name,
                        style: AppTextStyles.dmSans(
                          size: 15,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Keep garment details accurate for better AI styling.',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          color: WardrobeTokens.editHeroBody,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Clothing name',
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            style: AppTextStyles.dmSans(size: 12),
            decoration: const InputDecoration(isDense: true),
          ),
          SelectField(
            label: 'Category',
            options: SeedData.categories,
            value: _category,
            onChanged: (v) => setState(() => _category = v),
          ),
          SelectField(
            label: 'Color',
            options: SeedData.colors,
            value: _color,
            onChanged: (v) => setState(() => _color = v),
          ),
          SelectField(
            label: 'Best for',
            options: SeedData.occasions,
            value: _occasion,
            onChanged: (v) => setState(() => _occasion = v),
          ),
          SelectField(
            label: 'Season',
            options: SeedData.seasons,
            value: _season,
            onChanged: (v) => setState(() => _season = v),
          ),
          const SizedBox(height: 7),
          PrimaryButton(
            label: 'Save changes',
            onPressed: () => _save(context, wardrobe),
          ),
        ],
      ),
    );
  }
}
