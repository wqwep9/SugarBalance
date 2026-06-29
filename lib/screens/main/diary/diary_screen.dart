import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/diary_entry.dart';
import '../../../models/food_product.dart';
import '../../../providers/diary_provider.dart';
import '../../../widgets/diary/food_products_sheet.dart';

/// Дневник: пролистываемый блок ввода сверху и список сохранённых записей ниже.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _sugarController = TextEditingController();
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _shortInsulinController = TextEditingController();
  final TextEditingController _longInsulinController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  int _pageIndex = 0;
  bool _isAfterMeal = false;
  String? _foodPhotoPath;
  List<FoodProductSelection> _foodSelections = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<DiaryProvider>().loadEntriesIfNeeded());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sugarController.dispose();
    _foodController.dispose();
    _shortInsulinController.dispose();
    _longInsulinController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    FocusScope.of(context).unfocus();
    final provider = context.read<DiaryProvider>();
    provider.clearError();
    final ok = await provider.saveEntry(
      sugarRaw: _sugarController.text,
      foodRaw: _foodController.text,
      foodPhotoPath: _foodPhotoPath,
      shortInsulinRaw: _shortInsulinController.text,
      longInsulinRaw: _longInsulinController.text,
      commentRaw: _commentController.text,
      isAfterMeal: _isAfterMeal,
    );
    if (!mounted) return;
    if (ok) {
      _sugarController.clear();
      _foodController.clear();
      _shortInsulinController.clear();
      _longInsulinController.clear();
      _commentController.clear();
      setState(() {
        _foodPhotoPath = null;
        _foodSelections = [];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Запись сохранена')));
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    }
  }

  Future<void> _pickFoodPhoto(ImageSource source) async {
    final XFile? file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (!mounted || file == null) return;
    setState(() => _foodPhotoPath = file.path);
  }

  Future<void> _openFoodProductsPicker() async {
    final result = await FoodProductsSheet.show(
      context,
      initialSelections: _foodSelections,
    );
    if (!mounted || result == null) return;
    setState(() {
      _foodSelections = result.selections;
      if (result.totalXe > 0) {
        _foodController.text = result.totalXe.toStringAsFixed(2);
      }
    });
  }

  Future<void> _chooseFoodPhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Сделать фото'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Выбрать из галереи'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source != null) {
      await _pickFoodPhoto(source);
    }
  }

  Future<String?> _choosePhotoSourceAndPick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Сделать фото'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Выбрать из галереи'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || source == null) return null;
    final XFile? file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    return file?.path;
  }

  Future<void> _editEntry(DiaryEntry entry) async {
    if (entry.id == null) return;

    final sugar = TextEditingController(
      text: entry.sugarMmolL == null ? '' : entry.sugarMmolL.toString(),
    );
    final food = TextEditingController(
      text: entry.foodXe == null ? '' : entry.foodXe.toString(),
    );
    final shortIns = TextEditingController(
      text: entry.shortInsulinUnits == null
          ? ''
          : entry.shortInsulinUnits.toString(),
    );
    final longIns = TextEditingController(
      text: entry.longInsulinUnits == null
          ? ''
          : entry.longInsulinUnits.toString(),
    );
    final comment = TextEditingController(text: entry.comment ?? '');

    bool isAfterMeal = entry.isAfterMeal;
    String? photoPath = entry.foodPhotoPath;

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Редактировать запись',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDateTime(entry.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.formNavy.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                        ),
                      ),
                      Switch(
                        value: isAfterMeal,
                        onChanged: (v) => setModalState(() => isAfterMeal = v),
                      ),
                      Text(isAfterMeal ? 'После еды' : 'До еды'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _EditField(label: 'Сахар (ммоль/л)', controller: sugar),
                  _EditField(label: 'Еда (ХЕ)', controller: food),
                  _EditField(
                    label: 'Короткий инсулин (ед.)',
                    controller: shortIns,
                  ),
                  _EditField(
                    label: 'Продлённый инсулин (ед.)',
                    controller: longIns,
                  ),
                  _EditField(
                    label: 'Комментарий',
                    controller: comment,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await _choosePhotoSourceAndPick();
                            if (picked == null) return;
                            setModalState(() => photoPath = picked);
                          },
                          icon: const Icon(
                            Icons.add_a_photo_outlined,
                            size: 18,
                          ),
                          label: Text(
                            photoPath == null ? 'Фото еды' : 'Изменить фото',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: photoPath == null
                            ? null
                            : () => setModalState(() => photoPath = null),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  if (photoPath != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(photoPath!),
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Отмена'),
                        ),
                      ),
                      Expanded(
                        child: Consumer<DiaryProvider>(
                          builder: (context, diary, _) {
                            return FilledButton(
                              onPressed: diary.isSaving
                                  ? null
                                  : () => Navigator.of(context).pop(true),
                              child: Text(
                                diary.isSaving ? 'Сохранение…' : 'Сохранить',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || updated != true) {
      sugar.dispose();
      food.dispose();
      shortIns.dispose();
      longIns.dispose();
      comment.dispose();
      return;
    }

    final provider = context.read<DiaryProvider>();
    provider.clearError();
    final ok = await provider.updateEntry(
      entryId: entry.id!,
      createdAtMillis: entry.createdAtMillis,
      sugarRaw: sugar.text,
      foodRaw: food.text,
      foodPhotoPath: photoPath,
      shortInsulinRaw: shortIns.text,
      longInsulinRaw: longIns.text,
      commentRaw: comment.text,
      isAfterMeal: isAfterMeal,
    );

    sugar.dispose();
    food.dispose();
    shortIns.dispose();
    longIns.dispose();
    comment.dispose();

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Запись обновлена')));
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 226, 236, 251),
      appBar: AppBar(
        title: const Text('Дневник'),
        backgroundColor: const Color.fromARGB(255, 226, 236, 251),
      ),
      body: SafeArea(
        child: Consumer<DiaryProvider>(
          builder: (context, diary, _) {
            return RefreshIndicator(
              onRefresh: diary.loadEntries,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ComposerCard(
                    pageController: _pageController,
                    currentPage: _pageIndex,
                    onPageChanged: (v) => setState(() => _pageIndex = v),
                    sugarController: _sugarController,
                    foodController: _foodController,
                    foodSelections: _foodSelections,
                    onPickFoodProducts: () => unawaited(_openFoodProductsPicker()),
                    foodPhotoPath: _foodPhotoPath,
                    onPickFoodPhoto: () => unawaited(_chooseFoodPhotoSource()),
                    onClearFoodPhoto: () =>
                        setState(() => _foodPhotoPath = null),
                    shortInsulinController: _shortInsulinController,
                    longInsulinController: _longInsulinController,
                    commentController: _commentController,
                    isAfterMeal: _isAfterMeal,
                    onMealChanged: (value) {
                      setState(() => _isAfterMeal = value);
                    },
                    onSave: diary.isSaving
                        ? null
                        : () => unawaited(_saveEntry()),
                  ),
                  const SizedBox(height: 20),
                  if (diary.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (diary.entries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Записей пока нет. Добавьте первую запись сверху.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.formNavy,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...diary.entries.map(
                      (e) => _DiaryEntryTile(
                        e,
                        onEdit: () => unawaited(_editEntry(e)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.sugarController,
    required this.foodController,
    required this.foodSelections,
    required this.onPickFoodProducts,
    required this.foodPhotoPath,
    required this.onPickFoodPhoto,
    required this.onClearFoodPhoto,
    required this.shortInsulinController,
    required this.longInsulinController,
    required this.commentController,
    required this.isAfterMeal,
    required this.onMealChanged,
    required this.onSave,
  });

  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final TextEditingController sugarController;
  final TextEditingController foodController;
  final List<FoodProductSelection> foodSelections;
  final VoidCallback onPickFoodProducts;
  final String? foodPhotoPath;
  final VoidCallback onPickFoodPhoto;
  final VoidCallback onClearFoodPhoto;
  final TextEditingController shortInsulinController;
  final TextEditingController longInsulinController;
  final TextEditingController commentController;
  final bool isAfterMeal;
  final ValueChanged<bool> onMealChanged;
  final VoidCallback? onSave;

  /// Фиксированная высота для Сахар / инсулин / комментарий (как было изначально).
  static const double _defaultCardHeight = 285.0;

  /// На «Еде» высота растёт с числом продуктов и масштабом шрифта.
  static double _cardHeight(
    BuildContext context, {
    required int pageIndex,
    required int foodProductsCount,
    required bool hasFoodPhoto,
  }) {
    if (pageIndex != 1) {
      return _defaultCardHeight;
    }

    final scale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);
    const chrome = 118.0;
    const defaultBody = 200.0;

    var body = defaultBody + 36;
    body += foodProductsCount * (24 * scale);
    if (hasFoodPhoto) body += 58 * scale;

    return (chrome + body).clamp(290 * scale, 520 * scale);
  }

  @override
  Widget build(BuildContext context) {
    const pagesCount = 5;
    final cardHeight = _cardHeight(
      context,
      pageIndex: currentPage,
      foodProductsCount: foodSelections.length,
      hasFoodPhoto: foodPhotoPath != null,
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pagesCount, (index) {
              final selected = currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? const Color.fromARGB(255, 162, 235, 197)
                      : Colors.white,
                  border: Border.all(
                    color: const Color.fromARGB(255, 83, 127, 196),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PageView(
              controller: pageController,
              onPageChanged: onPageChanged,
              children: [
                _InputPage(
                  title: 'САХАР',
                  unit: 'ммоль/л',
                  controller: sugarController,
                  hint: 'Например: 8.0',
                  showMealToggle: true,
                  isAfterMeal: isAfterMeal,
                  onMealChanged: onMealChanged,
                ),
                _FoodInputPage(
                  controller: foodController,
                  foodSelections: foodSelections,
                  onPickProducts: onPickFoodProducts,
                  foodPhotoPath: foodPhotoPath,
                  onPickPhoto: onPickFoodPhoto,
                  onClearPhoto: onClearFoodPhoto,
                ),
                _InputPage(
                  title: 'КОРОТКИЙ ИНСУЛИН',
                  unit: 'ед.',
                  controller: shortInsulinController,
                  hint: 'Например: 5.0',
                ),
                _InputPage(
                  title: 'ПРОДЛЁННЫЙ ИНСУЛИН',
                  unit: 'ед.',
                  controller: longInsulinController,
                  hint: 'Например: 12.0',
                ),
                _CommentPage(controller: commentController),
              ],
            ),
          ),
          const Divider(height: 1, color: Color.fromARGB(255, 190, 212, 245)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: currentPage > 0
                      ? () => pageController.previousPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        )
                      : null,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSave,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color.fromARGB(255, 143, 182, 240),
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Готово'),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: currentPage < pagesCount - 1
                      ? () => pageController.nextPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        )
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _InputPage extends StatelessWidget {
  const _InputPage({
    required this.title,
    required this.unit,
    required this.controller,
    required this.hint,
    this.showMealToggle = false,
    this.isAfterMeal = false,
    this.onMealChanged,
  });

  final String title;
  final String unit;
  final TextEditingController controller;
  final String hint;
  final bool showMealToggle;
  final bool isAfterMeal;
  final ValueChanged<bool>? onMealChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.formNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDateTime(DateTime.now()),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.formNavy.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: hint,
              suffixText: unit,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (showMealToggle) ...[
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: false, label: Text('До еды')),
                ButtonSegment<bool>(value: true, label: Text('После еды')),
              ],
              selected: {isAfterMeal},
              onSelectionChanged: (v) => onMealChanged?.call(v.first),
              style: SegmentedButton.styleFrom(
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.formNavy,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentPage extends StatelessWidget {
  const _CommentPage({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Text(
            'КОММЕНТАРИЙ',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.formNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Введите комментарий',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodInputPage extends StatelessWidget {
  const _FoodInputPage({
    required this.controller,
    required this.foodSelections,
    required this.onPickProducts,
    required this.foodPhotoPath,
    required this.onPickPhoto,
    required this.onClearPhoto,
  });

  final TextEditingController controller;
  final List<FoodProductSelection> foodSelections;
  final VoidCallback onPickProducts;
  final String? foodPhotoPath;
  final VoidCallback onPickPhoto;
  final VoidCallback onClearPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsLabel = foodSelections.isEmpty
        ? 'Подобрать продукты'
        : 'Изменить продукты (${foodSelections.length})';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: constraints.maxHeight < 280
                ? const AlwaysScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ЕДА',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.formNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDateTime(DateTime.now()),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.formNavy.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'ХЕ вручную или из продуктов',
                    suffixText: 'ХЕ',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: onPickProducts,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: AppColors.formNavy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant_menu, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          productsLabel,
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                if (foodSelections.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...foodSelections.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${s.name} · ${s.grams.toStringAsFixed(0)} г · '
                        '${s.carbsGrams.toStringAsFixed(1)} г угл. · '
                        '${s.xe.toStringAsFixed(2)} ХЕ',
                        softWrap: true,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.formNavy.withValues(alpha: 0.88),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onPickPhoto,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          foodPhotoPath == null
                              ? 'Добавить фото'
                              : 'Изменить фото',
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                if (foodPhotoPath != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(foodPhotoPath!),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        onPressed: onClearPhoto,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Убрать фото',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DiaryEntryTile extends StatelessWidget {
  const _DiaryEntryTile(this.entry, {required this.onEdit});
  final DiaryEntry entry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 205, 220, 242),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatShortDateTime(entry.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.formNavy,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Редактировать',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (entry.sugarMmolL != null)
                _MetricChip(
                  icon: '🩸',
                  value: entry.sugarMmolL!.toStringAsFixed(1),
                ),
              if (entry.foodXe != null)
                _MetricChip(
                  icon: '🥖',
                  value: entry.foodXe!.toStringAsFixed(1),
                ),
              if (entry.shortInsulinUnits != null)
                _MetricChip(
                  icon: '💉',
                  value: entry.shortInsulinUnits!.toStringAsFixed(1),
                ),
              if (entry.longInsulinUnits != null)
                _MetricChip(
                  icon: '💉',
                  value: entry.longInsulinUnits!.toStringAsFixed(1),
                ),
              if (entry.foodPhotoPath != null &&
                  entry.foodPhotoPath!.isNotEmpty)
                const _MetricChip(icon: '📷', value: 'Фото'),
            ],
          ),
          if (entry.foodPhotoPath != null &&
              entry.foodPhotoPath!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(entry.foodPhotoPath!),
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            ),
          ],
          if (entry.comment != null && entry.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                entry.comment!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.formNavy,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.value});
  final String icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: maxLines > 1
            ? TextInputType.multiline
            : const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

String _formatShortDateTime(DateTime dt) {
  final dd = dt.day.toString().padLeft(2, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$dd.$mm.${dt.year} $hh:$min';
}

String _formatDateTime(DateTime dt) {
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  final day = dt.day;
  final month = months[dt.month - 1];
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$day $month ${dt.year} г. в $hh:$mm';
}
