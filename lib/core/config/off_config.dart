import 'package:openfoodfacts/openfoodfacts.dart';

class OpenFoodFactsConfig {
  static void initialize() {
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'NutriCheck',
      version: '1.0.0',
      system: 'Flutter App',
      url: 'https://github.com/spyou/nutri-check',
    );

    OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
      OpenFoodFactsLanguage.ENGLISH,
    ];

    OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.INDIA;
  }
}
