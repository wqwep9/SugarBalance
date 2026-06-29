/// Параметры из scaler_params.json — НЕ редактируйте вручную после генерации
class ModelConstants {
  static const List<double> mean = [
    6.849382716049384,
    0.04115973059449126,
    17.722586417950257
  ]; // ← замените на реальные из JSON
  static const List<double> std  = [1.680470499723814,
    0.3681438221794412,
    34.16476326192573
  ]; // ← замените на реальные из JSON
  
  static const double minGlucose = 3.0;
  static const double maxGlucose = 22.0;
  static const double confidenceThreshold = 0.40;
}