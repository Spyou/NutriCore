import 'package:flutter/material.dart';
import 'package:nutri_check/domain/entities/product.dart';

class CategoryHelper {
  static Map<String, dynamic> getCategoryFromProduct(Product product) {
    final productName = (product.name).toLowerCase();
    final categories = (product.categories ?? '').toLowerCase();
    final brands = (product.brands ?? '').toLowerCase();

    final fullText = '$productName $categories $brands';

    if (_containsAny(fullText, [
      'chocolate',
      'candy',
      'sweet',
      'cookie',
      'biscuit',
      'cake',
      'pastry',
      'dessert',
      'ice cream',
      'cadbury',
      'nestle',
      'kitkat',
      'snickers',
    ])) {
      return {'name': 'Sweets & Desserts', 'icon': Icons.cake};
    }

    if (_containsAny(fullText, [
      'milk',
      'cheese',
      'yogurt',
      'yoghurt',
      'butter',
      'cream',
      'dairy',
      'lassi',
      'curd',
      'paneer',
      'amul',
      'mother dairy',
    ])) {
      return {'name': 'Dairy Products', 'icon': Icons.water_drop};
    }

    if (_containsAny(fullText, [
      'drink',
      'juice',
      'soda',
      'cola',
      'pepsi',
      'coca',
      'water',
      'tea',
      'coffee',
      'beverage',
      'shake',
      'smoothie',
      'thumsup',
    ])) {
      return {'name': 'Beverages', 'icon': Icons.local_drink};
    }

    if (_containsAny(fullText, [
      'bread',
      'bun',
      'roll',
      'toast',
      'bakery',
      'croissant',
      'muffin',
      'bagel',
      'baguette',
    ])) {
      return {'name': 'Bakery', 'icon': Icons.bakery_dining};
    }

    if (_containsAny(fullText, [
      'fruit',
      'apple',
      'banana',
      'orange',
      'grape',
      'berry',
      'mango',
      'pineapple',
      'strawberry',
      'kiwi',
      'peach',
    ])) {
      return {'name': 'Fruits', 'icon': Icons.apple};
    }

    if (_containsAny(fullText, [
      'vegetable',
      'carrot',
      'broccoli',
      'spinach',
      'lettuce',
      'tomato',
      'cucumber',
      'pepper',
      'onion',
      'potato',
    ])) {
      return {'name': 'Vegetables', 'icon': Icons.eco};
    }

    if (_containsAny(fullText, [
      'meat',
      'chicken',
      'beef',
      'pork',
      'fish',
      'salmon',
      'tuna',
      'protein',
      'egg',
      'seafood',
    ])) {
      return {'name': 'Meat & Protein', 'icon': Icons.restaurant};
    }

    if (_containsAny(fullText, [
      'cereal',
      'rice',
      'wheat',
      'oat',
      'grain',
      'pasta',
      'noodle',
      'quinoa',
      'barley',
      'corn',
    ])) {
      return {'name': 'Grains & Cereals', 'icon': Icons.grass};
    }

    if (_containsAny(fullText, [
      'nut',
      'almond',
      'peanut',
      'cashew',
      'walnut',
      'seed',
      'sunflower',
      'pumpkin',
    ])) {
      return {'name': 'Nuts & Seeds', 'icon': Icons.scatter_plot};
    }

    if (_containsAny(fullText, [
      'snack',
      'chip',
      'crisp',
      'popcorn',
      'pretzel',
      'cracker',
      'fast food',
      'fries',
      'burger',
      'pizza',
    ])) {
      return {'name': 'Snacks & Fast Food', 'icon': Icons.fastfood};
    }

    if (_containsAny(fullText, [
      'sauce',
      'ketchup',
      'mayo',
      'mustard',
      'honey',
      'jam',
      'syrup',
      'vinegar',
      'oil',
      'spice',
    ])) {
      return {'name': 'Condiments', 'icon': Icons.water_drop_outlined};
    }

    return {'name': 'Food Product', 'icon': Icons.restaurant_menu};
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}
