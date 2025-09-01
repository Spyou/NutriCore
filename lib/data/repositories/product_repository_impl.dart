import 'package:openfoodfacts/openfoodfacts.dart';

import '../../domain/entities/product.dart' as domain;
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<domain.Product?> getProductByBarcode(String barcode) async {
    try {
      final ProductQueryConfiguration configuration = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        version: ProductQueryVersion.v3,
        fields: [
          ProductField.BARCODE,
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.CATEGORIES,
          ProductField.NUTRIMENTS,
          ProductField.NUTRISCORE,
          ProductField.NOVA_GROUP,
          ProductField.INGREDIENTS_TEXT,
          ProductField.ALLERGENS,
          ProductField.LABELS,
          ProductField.IMAGES,
        ],
      );

      final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(
        configuration,
      );

      if (result.status == ProductResultV3.statusSuccess &&
          result.product != null) {
        return _convertToAppProduct(result.product!);
      }
      return null;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  @override
  Future<List<domain.Product>> searchProducts(String query) async {
    try {
      final ProductSearchQueryConfiguration configuration =
          ProductSearchQueryConfiguration(
            parametersList: [
              SearchTerms(terms: [query]),
              PageSize(size: 20),
            ],
            version: ProductQueryVersion.v3,
            language: OpenFoodFactsLanguage.ENGLISH,
            fields: [
              ProductField.BARCODE,
              ProductField.NAME,
              ProductField.BRANDS,
              ProductField.NUTRIMENTS,
              ProductField.NUTRISCORE,
              ProductField.IMAGES,
            ],
          );

      final SearchResult result = await OpenFoodAPIClient.searchProducts(
        null, // No user required for search
        configuration,
      );

      if (result.products != null) {
        return result.products!
            .map((product) => _convertToAppProduct(product))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  domain.Product _convertToAppProduct(Product offProduct) {
    return domain.Product(
      id: offProduct.barcode ?? '',
      barcode: offProduct.barcode,
      name: offProduct.productName ?? 'Unknown Product',
      brands: offProduct.brands,
      categories: offProduct.categories,
      categoriesTags: offProduct.categoriesTags ?? [],
      imageFrontUrl: offProduct.imageFrontUrl,
      imageFrontSmallUrl: offProduct.imageFrontSmallUrl,
      imageNutritionUrl: offProduct.imageNutritionUrl,
      imageIngredientsUrl: offProduct.imageIngredientsUrl,
      nutriments: offProduct.nutriments != null
          ? _convertNutriments(offProduct.nutriments!)
          : null,
      nutriscoreGrade: offProduct.nutriscore?.toUpperCase(),
      novaGroup: offProduct.novaGroup,
      ecoscoreGrade: offProduct.ecoscoreGrade?.toUpperCase(),
      ingredientsText: offProduct.ingredientsText,
      allergens: (offProduct.allergens as List<dynamic>?)?.cast<String>() ?? [],
      additives: (offProduct.additives as List<dynamic>?)?.cast<String>() ?? [],
      labels: offProduct.labelsTags ?? [],
      quantity: offProduct.quantity,
      servingSize: offProduct.servingSize,
      packaging: offProduct.packaging,
      stores: offProduct.stores,
      countries: offProduct.countries,
      lastModified: offProduct.lastModified,
    );
  }

  domain.Nutriments _convertNutriments(Nutriments offNutriments) {
    return domain.Nutriments(
      energyKcal100g: offNutriments
          .getValue(Nutrient.energyKCal, PerSize.oneHundredGrams)
          ?.toDouble(),
      energyKcalServing: offNutriments
          .getValue(Nutrient.energyKCal, PerSize.serving)
          ?.toDouble(),
      proteins100g: offNutriments
          .getValue(Nutrient.proteins, PerSize.oneHundredGrams)
          ?.toDouble(),
      proteinsServing: offNutriments
          .getValue(Nutrient.proteins, PerSize.serving)
          ?.toDouble(),
      carbohydrates100g: offNutriments
          .getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams)
          ?.toDouble(),
      carbohydratesServing: offNutriments
          .getValue(Nutrient.carbohydrates, PerSize.serving)
          ?.toDouble(),
      sugars100g: offNutriments
          .getValue(Nutrient.sugars, PerSize.oneHundredGrams)
          ?.toDouble(),
      sugarsServing: offNutriments
          .getValue(Nutrient.sugars, PerSize.serving)
          ?.toDouble(),
      fat100g: offNutriments
          .getValue(Nutrient.fat, PerSize.oneHundredGrams)
          ?.toDouble(),
      fatServing: offNutriments
          .getValue(Nutrient.fat, PerSize.serving)
          ?.toDouble(),
      saturatedFat100g: offNutriments
          .getValue(Nutrient.saturatedFat, PerSize.oneHundredGrams)
          ?.toDouble(),
      saturatedFatServing: offNutriments
          .getValue(Nutrient.saturatedFat, PerSize.serving)
          ?.toDouble(),
      fiber100g: offNutriments
          .getValue(Nutrient.fiber, PerSize.oneHundredGrams)
          ?.toDouble(),
      fiberServing: offNutriments
          .getValue(Nutrient.fiber, PerSize.serving)
          ?.toDouble(),
      salt100g: offNutriments
          .getValue(Nutrient.salt, PerSize.oneHundredGrams)
          ?.toDouble(),
      saltServing: offNutriments
          .getValue(Nutrient.salt, PerSize.serving)
          ?.toDouble(),
      sodium100g: offNutriments
          .getValue(Nutrient.sodium, PerSize.oneHundredGrams)
          ?.toDouble(),
      sodiumServing: offNutriments
          .getValue(Nutrient.sodium, PerSize.serving)
          ?.toDouble(),
    );
  }
}
