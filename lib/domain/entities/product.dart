class Product {
  final String id;
  final String? barcode;
  final String name;
  final String? brands;
  final String? categories;
  final List<String> categoriesTags;
  final String? imageFrontUrl;
  final String? imageFrontSmallUrl;
  final String? imageNutritionUrl;
  final String? imageIngredientsUrl;
  final Nutriments? nutriments;
  final String? nutriscoreGrade;
  final int? novaGroup;
  final String? ecoscoreGrade;
  final String? ingredientsText;
  final List<String> allergens;
  final List<String> additives;
  final List<String> labels;
  final String? quantity;
  final String? servingSize;
  final String? packaging;
  final String? stores;
  final String? countries;
  final DateTime? lastModified;

  Product({
    required this.id,
    this.barcode,
    required this.name,
    this.brands,
    this.categories,
    this.categoriesTags = const [],
    this.imageFrontUrl,
    this.imageFrontSmallUrl,
    this.imageNutritionUrl,
    this.imageIngredientsUrl,
    this.nutriments,
    this.nutriscoreGrade,
    this.novaGroup,
    this.ecoscoreGrade,
    this.ingredientsText,
    this.allergens = const [],
    this.additives = const [],
    this.labels = const [],
    this.quantity,
    this.servingSize,
    this.packaging,
    this.stores,
    this.countries,
    this.lastModified,
  });
}

class Nutriments {
  final double? energyKcal100g;
  final double? energyKcalServing;
  final double? proteins100g;
  final double? proteinsServing;
  final double? carbohydrates100g;
  final double? carbohydratesServing;
  final double? sugars100g;
  final double? sugarsServing;
  final double? fat100g;
  final double? fatServing;
  final double? saturatedFat100g;
  final double? saturatedFatServing;
  final double? fiber100g;
  final double? fiberServing;
  final double? salt100g;
  final double? saltServing;
  final double? sodium100g;
  final double? sodiumServing;

  Nutriments({
    this.energyKcal100g,
    this.energyKcalServing,
    this.proteins100g,
    this.proteinsServing,
    this.carbohydrates100g,
    this.carbohydratesServing,
    this.sugars100g,
    this.sugarsServing,
    this.fat100g,
    this.fatServing,
    this.saturatedFat100g,
    this.saturatedFatServing,
    this.fiber100g,
    this.fiberServing,
    this.salt100g,
    this.saltServing,
    this.sodium100g,
    this.sodiumServing,
  });
}
