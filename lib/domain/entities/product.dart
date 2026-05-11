import 'package:equatable/equatable.dart';

class Product extends Equatable {
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

  const Product({
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

  Product copyWith({
    String? barcode,
    String? name,
    String? brands,
    String? categories,
    List<String>? categoriesTags,
    String? imageFrontUrl,
    String? imageFrontSmallUrl,
    String? imageNutritionUrl,
    String? imageIngredientsUrl,
    Nutriments? nutriments,
    String? nutriscoreGrade,
    int? novaGroup,
    String? ecoscoreGrade,
    String? ingredientsText,
    List<String>? allergens,
    List<String>? additives,
    List<String>? labels,
    String? quantity,
    String? servingSize,
    String? packaging,
    String? stores,
    String? countries,
    DateTime? lastModified,
  }) {
    return Product(
      id: id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brands: brands ?? this.brands,
      categories: categories ?? this.categories,
      categoriesTags: categoriesTags ?? this.categoriesTags,
      imageFrontUrl: imageFrontUrl ?? this.imageFrontUrl,
      imageFrontSmallUrl: imageFrontSmallUrl ?? this.imageFrontSmallUrl,
      imageNutritionUrl: imageNutritionUrl ?? this.imageNutritionUrl,
      imageIngredientsUrl: imageIngredientsUrl ?? this.imageIngredientsUrl,
      nutriments: nutriments ?? this.nutriments,
      nutriscoreGrade: nutriscoreGrade ?? this.nutriscoreGrade,
      novaGroup: novaGroup ?? this.novaGroup,
      ecoscoreGrade: ecoscoreGrade ?? this.ecoscoreGrade,
      ingredientsText: ingredientsText ?? this.ingredientsText,
      allergens: allergens ?? this.allergens,
      additives: additives ?? this.additives,
      labels: labels ?? this.labels,
      quantity: quantity ?? this.quantity,
      servingSize: servingSize ?? this.servingSize,
      packaging: packaging ?? this.packaging,
      stores: stores ?? this.stores,
      countries: countries ?? this.countries,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  List<Object?> get props => [id, barcode, name, nutriments];
}

class Nutriments extends Equatable {
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

  const Nutriments({
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

  Nutriments copyWith({
    double? energyKcal100g,
    double? energyKcalServing,
    double? proteins100g,
    double? proteinsServing,
    double? carbohydrates100g,
    double? carbohydratesServing,
    double? sugars100g,
    double? sugarsServing,
    double? fat100g,
    double? fatServing,
    double? saturatedFat100g,
    double? saturatedFatServing,
    double? fiber100g,
    double? fiberServing,
    double? salt100g,
    double? saltServing,
    double? sodium100g,
    double? sodiumServing,
  }) {
    return Nutriments(
      energyKcal100g: energyKcal100g ?? this.energyKcal100g,
      energyKcalServing: energyKcalServing ?? this.energyKcalServing,
      proteins100g: proteins100g ?? this.proteins100g,
      proteinsServing: proteinsServing ?? this.proteinsServing,
      carbohydrates100g: carbohydrates100g ?? this.carbohydrates100g,
      carbohydratesServing: carbohydratesServing ?? this.carbohydratesServing,
      sugars100g: sugars100g ?? this.sugars100g,
      sugarsServing: sugarsServing ?? this.sugarsServing,
      fat100g: fat100g ?? this.fat100g,
      fatServing: fatServing ?? this.fatServing,
      saturatedFat100g: saturatedFat100g ?? this.saturatedFat100g,
      saturatedFatServing: saturatedFatServing ?? this.saturatedFatServing,
      fiber100g: fiber100g ?? this.fiber100g,
      fiberServing: fiberServing ?? this.fiberServing,
      salt100g: salt100g ?? this.salt100g,
      saltServing: saltServing ?? this.saltServing,
      sodium100g: sodium100g ?? this.sodium100g,
      sodiumServing: sodiumServing ?? this.sodiumServing,
    );
  }

  Nutriments operator +(Nutriments other) {
    return Nutriments(
      energyKcal100g: (energyKcal100g ?? 0) + (other.energyKcal100g ?? 0),
      energyKcalServing:
          (energyKcalServing ?? 0) + (other.energyKcalServing ?? 0),
      proteins100g: (proteins100g ?? 0) + (other.proteins100g ?? 0),
      proteinsServing: (proteinsServing ?? 0) + (other.proteinsServing ?? 0),
      carbohydrates100g:
          (carbohydrates100g ?? 0) + (other.carbohydrates100g ?? 0),
      carbohydratesServing:
          (carbohydratesServing ?? 0) + (other.carbohydratesServing ?? 0),
      sugars100g: (sugars100g ?? 0) + (other.sugars100g ?? 0),
      sugarsServing: (sugarsServing ?? 0) + (other.sugarsServing ?? 0),
      fat100g: (fat100g ?? 0) + (other.fat100g ?? 0),
      fatServing: (fatServing ?? 0) + (other.fatServing ?? 0),
      saturatedFat100g: (saturatedFat100g ?? 0) + (other.saturatedFat100g ?? 0),
      saturatedFatServing:
          (saturatedFatServing ?? 0) + (other.saturatedFatServing ?? 0),
      fiber100g: (fiber100g ?? 0) + (other.fiber100g ?? 0),
      fiberServing: (fiberServing ?? 0) + (other.fiberServing ?? 0),
      salt100g: (salt100g ?? 0) + (other.salt100g ?? 0),
      saltServing: (saltServing ?? 0) + (other.saltServing ?? 0),
      sodium100g: (sodium100g ?? 0) + (other.sodium100g ?? 0),
      sodiumServing: (sodiumServing ?? 0) + (other.sodiumServing ?? 0),
    );
  }

  Nutriments operator *(double factor) {
    return Nutriments(
      energyKcal100g: (energyKcal100g ?? 0) * factor,
      energyKcalServing: (energyKcalServing ?? 0) * factor,
      proteins100g: (proteins100g ?? 0) * factor,
      proteinsServing: (proteinsServing ?? 0) * factor,
      carbohydrates100g: (carbohydrates100g ?? 0) * factor,
      carbohydratesServing: (carbohydratesServing ?? 0) * factor,
      sugars100g: (sugars100g ?? 0) * factor,
      sugarsServing: (sugarsServing ?? 0) * factor,
      fat100g: (fat100g ?? 0) * factor,
      fatServing: (fatServing ?? 0) * factor,
      saturatedFat100g: (saturatedFat100g ?? 0) * factor,
      saturatedFatServing: (saturatedFatServing ?? 0) * factor,
      fiber100g: (fiber100g ?? 0) * factor,
      fiberServing: (fiberServing ?? 0) * factor,
      salt100g: (salt100g ?? 0) * factor,
      saltServing: (saltServing ?? 0) * factor,
      sodium100g: (sodium100g ?? 0) * factor,
      sodiumServing: (sodiumServing ?? 0) * factor,
    );
  }

  @override
  List<Object?> get props => [
    energyKcal100g,
    proteins100g,
    carbohydrates100g,
    fat100g,
    fiber100g,
    sugars100g,
    sodium100g,
  ];
}
