import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/food_xe_calculator.dart';
import '../../models/food_product.dart';
import '../../services/open_food_facts_service.dart';

/// Результат окна подбора продуктов.
class FoodProductsSheetResult {
  const FoodProductsSheetResult({
    required this.selections,
    required this.totalXe,
  });

  final List<FoodProductSelection> selections;
  final double totalXe;
}

/// Окно: поиск продуктов (Open Food Facts), порции в граммах, сумма ХЕ.
class FoodProductsSheet extends StatefulWidget {
  const FoodProductsSheet({
    super.key,
    this.initialSelections = const [],
  });

  final List<FoodProductSelection> initialSelections;

  /// Показать нижнее окно и вернуть выбранные продукты + сумму ХЕ.
  static Future<FoodProductsSheetResult?> show(
    BuildContext context, {
    List<FoodProductSelection> initialSelections = const [],
  }) {
    return showModalBottomSheet<FoodProductsSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FoodProductsSheet(initialSelections: initialSelections),
    );
  }

  @override
  State<FoodProductsSheet> createState() => _FoodProductsSheetState();
}

class _FoodProductsSheetState extends State<FoodProductsSheet> {
  final _searchController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  final _service = OpenFoodFactsService();

  List<FoodProductSearchHit> _hits = [];
  List<FoodProductSelection> _selections = [];
  FoodProductSearchHit? _pendingProduct;
  bool _searching = false;
  String? _searchError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selections = List.from(widget.initialSelections);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _gramsController.dispose();
    _service.dispose();
    super.dispose();
  }

  double get _totalXe => FoodXeCalculator.totalXe(_selections.map((e) => e.xe));

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_runSearch());
    });
  }

  Future<void> _runSearch() async {
    final q = _searchController.text.trim();
    if (q.length < 2) {
      setState(() {
        _hits = [];
        _searchError = null;
        _searching = false;
      });
      return;
    }

    setState(() {
      _searching = true;
      _searchError = null;
    });

    try {
      final hits = await _service.search(q);
      if (!mounted) return;
      setState(() {
        _hits = hits;
        _searching = false;
      });
    } on OpenFoodFactsException catch (e) {
      if (!mounted) return;
      setState(() {
        _hits = [];
        _searching = false;
        _searchError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hits = [];
        _searching = false;
        _searchError = 'Нет сети или сервер недоступен';
      });
    }
  }

  void _selectHit(FoodProductSearchHit hit) {
    if (!hit.hasCarbsData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет данных об углеводах для этого продукта'),
        ),
      );
      return;
    }
    setState(() {
      _pendingProduct = hit;
      _gramsController.text = '100';
    });
  }

  void _addPendingProduct() {
    final hit = _pendingProduct;
    if (hit == null || !hit.hasCarbsData) return;

    final gramsText = _gramsController.text.trim().replaceAll(',', '.');
    final grams = double.tryParse(gramsText);
    if (grams == null || grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите массу в граммах')),
      );
      return;
    }

    final carbs = FoodXeCalculator.carbsInPortion(
      carbsPer100g: hit.carbsPer100g!,
      grams: grams,
    );
    final xe = FoodXeCalculator.xeFromCarbs(carbs);

    setState(() {
      _selections.add(
        FoodProductSelection(
          name: hit.name,
          grams: grams,
          carbsPer100g: hit.carbsPer100g!,
          carbsGrams: carbs,
          xe: xe,
        ),
      );
      _pendingProduct = null;
    });
  }

  void _removeSelection(int index) {
    setState(() => _selections.removeAt(index));
  }

  void _apply() {
    Navigator.of(context).pop(
      FoodProductsSheetResult(
        selections: List.unmodifiable(_selections),
        totalXe: _totalXe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Подбор продуктов',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.formNavy,
                          ),
                    ),
                  ),
                  TextButton(onPressed: _apply, child: const Text('Готово')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Например: гречка, яблоко, хлеб',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _hits = [];
                              _searchError = null;
                            });
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (_) => _scheduleSearch(),
                onSubmitted: (_) => unawaited(_runSearch()),
              ),
            ),
            if (_searchError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  _searchError!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            if (_pendingProduct != null) _buildPendingCard(),
            if (_selections.isNotEmpty) _buildSelectionsList(),
            _buildTotalBar(),
            const Divider(height: 1),
            Expanded(child: _buildHitsList()),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '1 ХЕ = 12 г углеводов · Open Food Facts',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.5),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard() {
    final hit = _pendingProduct!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Material(
        color: AppColors.accentBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                hit.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.formNavy,
                ),
              ),
              Text(
                'Углеводы: ${hit.carbsPer100g!.toStringAsFixed(1)} г / 100 г',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.formNavy.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gramsController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Масса',
                        suffixText: 'г',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addPendingProduct,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: AppColors.formNavy,
                    ),
                    child: const Text('Добавить'),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _pendingProduct = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionsList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выбрано (${_selections.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.formNavy,
            ),
          ),
          const SizedBox(height: 6),
          ...List.generate(_selections.length, (i) {
            final s = _selections[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                title: Text(
                  s.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${s.grams.toStringAsFixed(0)} г · '
                  '${s.carbsGrams.toStringAsFixed(1)} г угл. · '
                  '${s.xe.toStringAsFixed(2)} ХЕ',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _removeSelection(i),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          const Text(
            'Итого:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.formNavy,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_totalXe.toStringAsFixed(2)} ХЕ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color.fromARGB(255, 0, 120, 80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHitsList() {
    if (_searchController.text.trim().length < 2) {
      return Center(
        child: Text(
          'Введите название продукта',
          style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.5)),
        ),
      );
    }
    if (_hits.isEmpty && !_searching) {
      return const Center(child: Text('Ничего не найдено'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _hits.length,
      itemBuilder: (context, index) {
        final hit = _hits[index];
        final hasCarbs = hit.hasCarbsData;
        return ListTile(
          title: Text(
            hit.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            hasCarbs
                ? 'Углеводы: ${hit.carbsPer100g!.toStringAsFixed(1)} г / 100 г'
                : 'Нет данных об углеводах',
          ),
          trailing: hasCarbs
              ? const Icon(Icons.add_circle_outline)
              : Icon(Icons.help_outline, color: Colors.grey.shade400),
          onTap: () => _selectHit(hit),
        );
      },
    );
  }
}
