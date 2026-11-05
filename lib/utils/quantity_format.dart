/// Formato amigable de cantidades: 0.5 -> "1/2", 1.25 -> "1 1/4".
library;

const _plurals = {
  'taza': 'tazas',
  'unidad': 'unidades',
  'diente': 'dientes',
  'rama': 'ramas',
  'atado': 'atados',
  'lata': 'latas',
  'rebanada': 'rebanadas',
  'hoja': 'hojas',
  'filete': 'filetes',
};

const _fractions = <(double, String)>[
  (0.25, '1/4'),
  (1 / 3, '1/3'),
  (0.5, '1/2'),
  (2 / 3, '2/3'),
  (0.75, '3/4'),
];

String formatNumber(double value) {
  if (value <= 0) return '0';
  // Para cantidades grandes (gramos, ml) redondeamos a enteros.
  if (value >= 10) return value.round().toString();

  var whole = value.floor();
  final frac = value - whole;
  String? fracText;
  if (frac >= 0.12) {
    if (frac > 0.875) {
      whole += 1;
    } else {
      var bestDiff = double.infinity;
      for (final (fraction, label) in _fractions) {
        final diff = (frac - fraction).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          fracText = label;
        }
      }
    }
  }
  if (whole == 0) return fracText ?? '0';
  return fracText == null ? '$whole' : '$whole $fracText';
}

String formatUnit(String unit, double quantity) {
  if (quantity <= 1) return unit;
  return _plurals[unit] ?? unit;
}

/// Devuelve el texto de la cantidad, por ejemplo "2 tazas" o "al gusto".
String formatQuantity(double? quantity, String? unit) {
  if (quantity == null) return 'al gusto';
  final number = formatNumber(quantity);
  if (unit == null) return number;
  return '$number ${formatUnit(unit, quantity)}';
}

/// Convierte unidades grandes a pequeñas para poder sumarlas.
/// Devuelve (cantidad, unidad base).
(double, String) normalizeUnit(double quantity, String unit) {
  switch (unit) {
    case 'kg':
      return (quantity * 1000, 'g');
    case 'l':
      return (quantity * 1000, 'ml');
    default:
      return (quantity, unit);
  }
}

/// Presenta unidades base de forma legible (1500 g -> 1.5 kg).
String formatShoppingQuantity(double quantity, String unit) {
  if (unit == 'g' && quantity >= 1000) {
    return '${_trim(quantity / 1000)} kg';
  }
  if (unit == 'ml' && quantity >= 1000) {
    return '${_trim(quantity / 1000)} l';
  }
  return formatQuantity(quantity, unit);
}

String _trim(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// "1 porción", "1 1/4 porciones", "1 1/2 porciones".
String formatPortions(double portions) =>
    '${formatNumber(portions)} ${portions <= 1 ? 'porción' : 'porciones'}';
