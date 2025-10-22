import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'measurement_data.dart';

// START OF ADDITIONS - MODERN UNITS
const List<String> modernLengthUnits = ['ס"מ', 'מטר', 'ק"מ'];
const List<String> modernAreaUnits = ['מ"ר', 'דונם'];
const List<String> modernVolumeUnits = ['סמ"ק', 'ליטר'];
const List<String> modernWeightUnits = ['גרם', 'ק"ג'];
const List<String> modernTimeUnits = ['שניות', 'דקות', 'שעות', 'ימים'];
// END OF ADDITIONS

class MeasurementConverterScreen extends StatefulWidget {
  const MeasurementConverterScreen({super.key});

  @override
  State<MeasurementConverterScreen> createState() =>
      _MeasurementConverterScreenState();
}

class _MeasurementConverterScreenState
    extends State<MeasurementConverterScreen> {
  String _selectedCategory = 'אורך';
  String? _selectedFromUnit;
  String? _selectedToUnit;
  String? _selectedOpinion;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();
  bool _showResultField = false;

  // Maps to remember user selections for each category
  final Map<String, String> _rememberedFromUnits = {};
  final Map<String, String> _rememberedToUnits = {};
  final Map<String, String> _rememberedOpinions = {};
  final Map<String, String> _rememberedInputValues = {};

  // Updated to include modern units
  final Map<String, List<String>> _units = {
    'אורך': lengthConversionFactors.keys.toList()..addAll(modernLengthUnits),
    'שטח': areaConversionFactors.keys.toList()..addAll(modernAreaUnits),
    'נפח': volumeConversionFactors.keys.toList()..addAll(modernVolumeUnits),
    'משקל': weightConversionFactors.keys.toList()..addAll(modernWeightUnits),
    'זמן': timeConversionFactors.keys.toList()..addAll(modernTimeUnits),
  };

  final Map<String, List<String>> _opinions = {
    'אורך': modernLengthFactors.keys.toList(),
    'שטח': modernAreaFactors.keys.toList(),
    'נפח': modernVolumeFactors.keys.toList(),
    'משקל': modernWeightFactors.keys.toList(),
    'זמן': modernTimeFactors.keys.toList(),
  };

  @override
  void initState() {
    super.initState();
    _resetDropdowns();
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _screenFocusNode.dispose();
    super.dispose();
  }

  void _resetDropdowns() {
    setState(() {
      // Restore remembered selections or use defaults
      _selectedFromUnit =
          _rememberedFromUnits[_selectedCategory] ??
          _units[_selectedCategory]!.first;
      _selectedToUnit =
          _rememberedToUnits[_selectedCategory] ??
          _units[_selectedCategory]!.first;
      _selectedOpinion =
          _rememberedOpinions[_selectedCategory] ??
          _opinions[_selectedCategory]?.first;

      // Validate that remembered selections are still valid for current category
      if (!_units[_selectedCategory]!.contains(_selectedFromUnit)) {
        _selectedFromUnit = _units[_selectedCategory]!.first;
      }
      if (!_units[_selectedCategory]!.contains(_selectedToUnit)) {
        _selectedToUnit = _units[_selectedCategory]!.first;
      }
      if (_opinions[_selectedCategory] != null &&
          !_opinions[_selectedCategory]!.contains(_selectedOpinion)) {
        _selectedOpinion = _opinions[_selectedCategory]?.first;
      }

      // Restore remembered input value or clear
      _inputController.text = _rememberedInputValues[_selectedCategory] ?? '';
      _resultController.clear();

      // Update result field visibility based on input
      _showResultField = _inputController.text.isNotEmpty;

      // Convert if there's a remembered input value
      if (_rememberedInputValues[_selectedCategory] != null &&
          _rememberedInputValues[_selectedCategory]!.isNotEmpty) {
        _convert();
      }
    });
  }

  void _saveCurrentSelections() {
    if (_selectedFromUnit != null) {
      _rememberedFromUnits[_selectedCategory] = _selectedFromUnit!;
    }
    if (_selectedToUnit != null) {
      _rememberedToUnits[_selectedCategory] = _selectedToUnit!;
    }
    if (_selectedOpinion != null) {
      _rememberedOpinions[_selectedCategory] = _selectedOpinion!;
    }
    // Save the current input value
    if (_inputController.text.isNotEmpty) {
      _rememberedInputValues[_selectedCategory] = _inputController.text;
    }
  }

  // Helper function to handle small inconsistencies in unit names
  // e.g., 'אצבעות' vs 'אצבע', 'רביעיות' vs 'רביעית'
  String _normalizeUnitName(String unit) {
    const Map<String, String> normalizationMap = {
      'אצבעות': 'אצבע',
      'טפחים': 'טפח',
      'זרתות': 'זרת',
      'אמות': 'אמה',
      'קנים': 'קנה',
      'מילים': 'מיל',
      'פרסאות': 'פרסה',
      'בית רובע': 'בית רובע',
      'בית קב': 'בית קב',
      'בית סאה': 'בית סאה',
      'בית סאתיים': 'בית סאתיים',
      'בית לתך': 'בית לתך',
      'בית כור': 'בית כור',
      'רביעיות': 'רביעית',
      'לוגים': 'לוג',
      'קבים': 'קב',
      'עשרונות': 'עשרון',
      'הינים': 'הין',
      'סאים': 'סאה',
      'איפות': 'איפה',
      'לתכים': 'לתך',
      'כורים': 'כור',
      'דינרים': 'דינר',
      'שקלים': 'שקל',
      'סלעים': 'סלע',
      'טרטימרים': 'טרטימר',
      'מנים': 'מנה',
      'ככרות': 'כיכר',
      'קנטרים': 'קנטר',
    };
    return normalizationMap[unit] ?? unit;
  }

  // Core logic to get the conversion factor from any unit to a base modern unit
  double? _getFactorToBaseUnit(String category, String unit, String opinion) {
    final normalizedUnit = _normalizeUnitName(unit);

    switch (category) {
      case 'אורך': // Base unit: cm
        if (modernLengthUnits.contains(unit)) {
          if (unit == 'ס"מ') return 1.0;
          if (unit == 'מטר') return 100.0;
          if (unit == 'ק"מ') return 100000.0;
        } else {
          final value = modernLengthFactors[opinion]![normalizedUnit];
          if (value == null) return null;
          // Units in data are cm, m, km. Convert all to cm.
          if (['קנה', 'מיל'].contains(normalizedUnit)) {
            return value * 100; // m to cm
          }
          if (['פרסה'].contains(normalizedUnit)) {
            return value * 100000; // km to cm
          }
          return value; // Already in cm
        }
        break;
      case 'שטח': // Base unit: m^2
        if (modernAreaUnits.contains(unit)) {
          if (unit == 'מ"ר') return 1.0;
          if (unit == 'דונם') return 1000.0;
        } else {
          final value = modernAreaFactors[opinion]![normalizedUnit];
          if (value == null) return null;
          // Units in data are m^2, dunam. Convert all to m^2
          if (['בית סאתיים', 'בית לתך', 'בית כור'].contains(normalizedUnit) ||
              (opinion == 'חתם סופר' && normalizedUnit == 'בית סאה')) {
            return value * 1000; // dunam to m^2
          }
          return value; // Already in m^2
        }
        break;
      case 'נפח': // Base unit: cm^3
        if (modernVolumeUnits.contains(unit)) {
          if (unit == 'סמ"ק') return 1.0;
          if (unit == 'ליטר') return 1000.0;
        } else {
          final value = modernVolumeFactors[opinion]![normalizedUnit];
          if (value == null) return null;
          // Units in data are cm^3, L. Convert all to cm^3
          if ([
            'קב',
            'עשרון',
            'הין',
            'סאה',
            'איפה',
            'לתך',
            'כור',
          ].contains(normalizedUnit)) {
            return value * 1000; // L to cm^3
          }
          return value; // Already in cm^3
        }
        break;
      case 'משקל': // Base unit: g
        if (modernWeightUnits.contains(unit)) {
          if (unit == 'גרם') return 1.0;
          if (unit == 'ק"ג') return 1000.0;
        } else {
          final value = modernWeightFactors[opinion]![_normalizeUnitName(unit)];
          if (value == null) return null;
          // Units in data are g, kg. Convert all to g
          if (['כיכר', 'קנטר'].contains(normalizedUnit)) {
            return value * 1000; // kg to g
          }
          return value; // Already in g
        }
        break;
      case 'זמן': // Base unit: seconds
        if (modernTimeUnits.contains(unit)) {
          if (unit == 'שניות') return 1.0;
          if (unit == 'דקות') return 60.0;
          if (unit == 'שעות') return 3600.0;
          if (unit == 'ימים') return 86400.0;
        } else {
          final value = modernTimeFactors[opinion]![unit];
          if (value == null) return null;
          return value; // Already in seconds
        }
        break;
    }
    return null;
  }

  void _convert() {
    final double? input = double.tryParse(_inputController.text);
    if (input == null ||
        _selectedFromUnit == null ||
        _selectedToUnit == null ||
        _inputController.text.isEmpty) {
      setState(() {
        _resultController.clear();
      });
      return;
    }

    // Check if both units are ancient
    final modernUnits = _getModernUnitsForCategory(_selectedCategory);
    bool fromIsAncient = !modernUnits.contains(_selectedFromUnit);
    bool toIsAncient = !modernUnits.contains(_selectedToUnit);

    double result = 0.0;

    // ----- CONVERSION LOGIC -----
    if (fromIsAncient && toIsAncient) {
      // Case 1: Ancient to Ancient conversion (doesn't need opinion)
      double conversionFactor = 1.0;
      switch (_selectedCategory) {
        case 'אורך':
          conversionFactor =
              lengthConversionFactors[_selectedFromUnit]![_selectedToUnit]!;
          break;
        case 'שטח':
          conversionFactor =
              areaConversionFactors[_selectedFromUnit]![_selectedToUnit]!;
          break;
        case 'נפח':
          conversionFactor =
              volumeConversionFactors[_selectedFromUnit]![_selectedToUnit]!;
          break;
        case 'משקל':
          conversionFactor =
              weightConversionFactors[_selectedFromUnit]![_selectedToUnit]!;
          break;
        case 'זמן':
          conversionFactor =
              timeConversionFactors[_selectedFromUnit]![_selectedToUnit]!;
          break;
      }
      result = input * conversionFactor;
    } else {
      // Case 2: Conversion involving any modern unit (requires an opinion)
      if (_selectedOpinion == null) {
        _resultController.text = "נא לבחור שיטה";
        return;
      }

      // Step 1: Convert input from 'FromUnit' to the base unit (e.g., cm for length)
      final factorFrom = _getFactorToBaseUnit(
        _selectedCategory,
        _selectedFromUnit!,
        _selectedOpinion!,
      );
      if (factorFrom == null) {
        _resultController.clear();
        return;
      }
      final valueInBaseUnit = input * factorFrom;

      // Step 2: Convert the value from the base unit to the 'ToUnit'
      final factorTo = _getFactorToBaseUnit(
        _selectedCategory,
        _selectedToUnit!,
        _selectedOpinion!,
      );
      if (factorTo == null) {
        _resultController.clear();
        return;
      }
      result = valueInBaseUnit / factorTo;
    }

    setState(() {
      if (result.isNaN || result.isInfinite) {
        _resultController.clear();
      } else {
        _resultController.text = result
            .toStringAsFixed(4)
            .replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _screenFocusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final String character = event.character ?? '';

            // Check if the pressed key is a number or decimal point
            if (RegExp(r'[0-9.]').hasMatch(character)) {
              // Auto-focus the input field and add the character
              if (!_inputFocusNode.hasFocus) {
                _inputFocusNode.requestFocus();
                // Add the typed character to the input field
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final currentText = _inputController.text;
                  final newText = currentText + character;
                  _inputController.text = newText;
                  _inputController.selection = TextSelection.fromPosition(
                    TextPosition(offset: newText.length),
                  );
                  setState(() {
                    _showResultField = newText.isNotEmpty;
                  });
                  _convert();
                });
                return KeyEventResult.handled;
              }
            }
            // Check if the pressed key is a delete/backspace key
            else if (event.logicalKey == LogicalKeyboardKey.backspace ||
                event.logicalKey == LogicalKeyboardKey.delete) {
              // Auto-focus the input field and handle deletion
              if (!_inputFocusNode.hasFocus) {
                _inputFocusNode.requestFocus();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final currentText = _inputController.text;
                  if (currentText.isNotEmpty) {
                    String newText;
                    if (event.logicalKey == LogicalKeyboardKey.backspace) {
                      // Remove last character
                      newText = currentText.substring(
                        0,
                        currentText.length - 1,
                      );
                    } else {
                      // Delete key - remove first character (or handle as backspace for simplicity)
                      newText = currentText.substring(
                        0,
                        currentText.length - 1,
                      );
                    }
                    _inputController.text = newText;
                    _inputController.selection = TextSelection.fromPosition(
                      TextPosition(offset: newText.length),
                    );
                    setState(() {
                      _showResultField = newText.isNotEmpty;
                    });
                    _convert();
                  }
                });
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCategorySelector(),
                  const SizedBox(height: 24),
                  _buildUnitSelectors(),
                  const SizedBox(height: 24),
                  if (_opinions.containsKey(_selectedCategory) &&
                      _opinions[_selectedCategory]!.isNotEmpty) ...[
                    _buildOpinionSelector(),
                    const SizedBox(height: 24),
                  ],
                  _buildInputField(),
                  if (_showResultField) ...[
                    const SizedBox(height: 24),
                    _buildResultDisplay(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'אורך':
        return Icons.straighten;
      case 'שטח':
        return Icons.crop_square;
      case 'נפח':
        return Icons.water_drop;
      case 'משקל':
        return Icons.scale;
      case 'זמן':
        return Icons.access_time;
      default:
        return Icons.category;
    }
  }

  Widget _buildCategorySelector() {
    final categories = ['אורך', 'שטח', 'נפח', 'משקל', 'זמן'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'סוג המידה',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                const double minButtonWidth = 80.0;
                const double spacing = 10.0;
                final double totalSpacing = spacing * (categories.length - 1);
                final double availableWidth =
                    constraints.maxWidth - totalSpacing;
                final double buttonWidth = availableWidth / categories.length;

                if (buttonWidth < minButtonWidth) {
                  return Wrap(
                    spacing: spacing,
                    runSpacing: 10.0,
                    children: categories
                        .map(
                          (category) =>
                              _buildCategoryButton(category, minButtonWidth),
                        )
                        .toList(),
                  );
                }

                return Row(
                  children: categories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          left: index < categories.length - 1 ? spacing / 2 : 0,
                          right: index > 0 ? spacing / 2 : 0,
                        ),
                        child: _buildCategoryButton(category, null),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String category, double? minWidth) {
    final isSelected = _selectedCategory == category;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (category != _selectedCategory) {
              _saveCurrentSelections();
              setState(() {
                _selectedCategory = category;
                _resetDropdowns();
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _screenFocusNode.requestFocus();
              });
            }
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: minWidth,
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  category,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitSelectors() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildUnitGrid('מ', _selectedFromUnit, (val) {
                setState(() => _selectedFromUnit = val);
                _rememberedFromUnits[_selectedCategory] = val!;
                _convert();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _screenFocusNode.requestFocus();
                });
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 24,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.swap_horiz,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  onPressed: () {
                    setState(() {
                      final temp = _selectedFromUnit;
                      _selectedFromUnit = _selectedToUnit;
                      _selectedToUnit = temp;
                      _convert();
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _screenFocusNode.requestFocus();
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: _buildUnitGrid('אל', _selectedToUnit, (val) {
                setState(() => _selectedToUnit = val);
                _rememberedToUnits[_selectedCategory] = val!;
                _convert();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _screenFocusNode.requestFocus();
                });
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitGrid(
    String label,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    final units = _units[_selectedCategory]!;

    // Separate modern and ancient units
    final modernUnits = _getModernUnitsForCategory(_selectedCategory);
    final ancientUnits = units
        .where((unit) => !modernUnits.contains(unit))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          // Ancient units rows
          if (ancientUnits.isNotEmpty) ...[
            _buildUnitsWrap(ancientUnits, selectedValue, onChanged),
            if (modernUnits.isNotEmpty) const SizedBox(height: 12.0),
          ],
          // Modern units rows (if any)
          if (modernUnits.isNotEmpty)
            _buildUnitsWrap(modernUnits, selectedValue, onChanged),
        ],
      ),
    );
  }

  List<String> _getModernUnitsForCategory(String category) {
    switch (category) {
      case 'אורך':
        return modernLengthUnits;
      case 'שטח':
        return modernAreaUnits;
      case 'נפח':
        return modernVolumeUnits;
      case 'משקל':
        return modernWeightUnits;
      case 'זמן':
        return modernTimeUnits;
      default:
        return [];
    }
  }

  Widget _buildUnitsWrap(
    List<String> units,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    // Calculate the maximum width needed for any unit in this category
    double maxWidth = 0;
    for (String unit in units) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: unit,
          style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.rtl,
      );
      textPainter.layout();
      maxWidth = math.max(maxWidth, textPainter.width + 32.0); // Add padding
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: units.map((unit) {
        return _buildUnitButton(
          unit,
          selectedValue == unit,
          onChanged,
          maxWidth,
        );
      }).toList(),
    );
  }

  Widget _buildUnitButton(
    String unit,
    bool isSelected,
    ValueChanged<String?> onChanged,
    double? fixedWidth,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(unit),
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            width: fixedWidth,
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              unit,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // A map to easily check if a unit is modern
  final Map<String, List<String>> _modernUnits = {
    'אורך': modernLengthUnits,
    'שטח': modernAreaUnits,
    'נפח': modernVolumeUnits,
    'משקל': modernWeightUnits,
    'זמן': modernTimeUnits,
  };

  Widget _buildOpinionSelector() {
    // Check if opinion selector should be shown
    final moderns = _modernUnits[_selectedCategory] ?? [];
    final bool isFromModern = moderns.contains(_selectedFromUnit);
    final bool isToModern = moderns.contains(_selectedToUnit);

    // Show opinion selector ONLY if at least one unit is modern
    bool isOpinionEnabled = isFromModern || isToModern;

    // If not enabled, don't show the selector at all
    if (!isOpinionEnabled) {
      return const SizedBox.shrink();
    }

    final opinions = _opinions[_selectedCategory]!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'שיטה',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                const double spacing = 10.0;
                const double padding = 16.0;

                // Calculate the natural width needed for each opinion text
                List<double> textWidths = opinions.map((opinion) {
                  final textPainter = TextPainter(
                    text: TextSpan(
                      text: opinion,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    textDirection: TextDirection.ltr,
                  );
                  textPainter.layout();
                  return textPainter.width + (padding * 2);
                }).toList();

                final double maxTextWidth = textWidths.reduce(
                  (a, b) => a > b ? a : b,
                );
                final double totalSpacing = spacing * (opinions.length - 1);
                final double totalEqualWidth =
                    (maxTextWidth * opinions.length) + totalSpacing;

                // First preference: Try equal-width buttons if they fit
                if (totalEqualWidth <= constraints.maxWidth) {
                  return Row(
                    children: opinions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final opinion = entry.value;

                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            left: index < opinions.length - 1 ? spacing / 2 : 0,
                            right: index > 0 ? spacing / 2 : 0,
                          ),
                          child: _buildOpinionButton(opinion, null),
                        ),
                      );
                    }).toList(),
                  );
                }

                // Second preference: Try proportional widths if natural sizes fit
                final double totalNaturalWidth =
                    textWidths.reduce((a, b) => a + b) + totalSpacing;
                if (totalNaturalWidth <= constraints.maxWidth) {
                  final double totalFlex = textWidths.reduce((a, b) => a + b);

                  return Row(
                    children: opinions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final opinion = entry.value;
                      final flex = (textWidths[index] / totalFlex * 1000)
                          .round();

                      return Expanded(
                        flex: flex,
                        child: Container(
                          margin: EdgeInsets.only(
                            left: index < opinions.length - 1 ? spacing / 2 : 0,
                            right: index > 0 ? spacing / 2 : 0,
                          ),
                          child: _buildOpinionButton(opinion, null),
                        ),
                      );
                    }).toList(),
                  );
                }

                // Last resort: Use Wrap for multiple rows
                return Wrap(
                  spacing: spacing,
                  runSpacing: 10.0,
                  children: opinions
                      .map((opinion) => _buildOpinionButton(opinion, null))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpinionButton(String opinion, double? minWidth) {
    final isSelected = _selectedOpinion == opinion;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedOpinion = opinion;
              _rememberedOpinions[_selectedCategory] = opinion;
              _convert();
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _screenFocusNode.requestFocus();
            });
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: minWidth,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              opinion,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSecondary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'ערך להמרה',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              decoration: InputDecoration(
                hintText: 'הזן ערך...',
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (value) {
                setState(() {
                  _showResultField = value.isNotEmpty;
                });

                if (value.isNotEmpty) {
                  _rememberedInputValues[_selectedCategory] = value;
                } else {
                  _rememberedInputValues.remove(_selectedCategory);
                }
                _convert();
              },
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'תוצאה',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _resultController.text.isEmpty ? '---' : _resultController.text,
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
