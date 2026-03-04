import 'package:meal_mate/features/ingredients/domain/ingredient.dart';
import 'package:openfoodfacts/openfoodfacts.dart' hide Ingredient;

const ingredientCategories = {
  'Produce': 'fruits-and-vegetables',
  'Dairy': 'dairies',
  'Meat': 'meats',
  'Seafood': 'seafood',
  'Grains': 'cereals-and-potatoes',
  'Legumes': 'legumes-and-their-products',
  'Spices': 'spices',
  'Condiments': 'sauces',
  'Oils': 'fats',
  'Beverages': 'beverages',
  'Baking': 'baking-preparations',
  'Nuts & Seeds': 'nuts-and-their-products',
};

class OpenFoodFactsRemoteSource {
  /// Returns a list of ingredient name suggestions for the given query.
  /// Uses the OFf taxonomy suggestions endpoint — returns canonical ingredient strings.
  Future<List<String>> getSuggestions(String query, {int limit = 20}) async {
    final suggestions = await OpenFoodAPIClient.getSuggestions(
      TagType.INGREDIENTS,
      input: query,
      language: OpenFoodFactsLanguage.ENGLISH,
      limit: limit,
    );
    return suggestions;
  }

  /// Searches for products by category tag and maps them to Ingredient domain models.
  /// Parses dietary flags from ingredientsAnalysisTags and labelsTags.
  Future<List<Ingredient>> searchByCategory(String categoryTag) async {
    final configuration = ProductSearchQueryConfiguration(
      parametersList: [
        TagFilter.fromType(
          tagFilterType: TagFilterType.CATEGORIES,
          tagName: categoryTag,
        ),
        const PageSize(size: 50),
      ],
      fields: [
        ProductField.NAME,
        ProductField.CATEGORIES_TAGS,
        ProductField.INGREDIENTS_ANALYSIS_TAGS,
        ProductField.LABELS_TAGS,
      ],
      language: OpenFoodFactsLanguage.ENGLISH,
      country: OpenFoodFactsCountry.USA,
      version: ProductQueryVersion.v3,
    );

    final result = await OpenFoodAPIClient.searchProducts(
      null,
      configuration,
    );

    if (result.products == null) return [];

    // Sort alphabetically by name per locked decision
    return (result.products!
          .where((p) => p.productName != null && p.productName!.isNotEmpty)
          .map((p) => _mapProductToIngredient(p, categoryTag))
          .toList())
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Ingredient _mapProductToIngredient(Product product, String categoryTag) {
    final flags = <String>[];

    final analysis = product.ingredientsAnalysisTags;
    if (analysis != null) {
      if (analysis.veganStatus == VeganStatus.VEGAN) {
        flags.add('vegan');
      }
      if (analysis.vegetarianStatus == VegetarianStatus.VEGETARIAN) {
        flags.add('vegetarian');
      }
    }

    final labelTags = product.labelsTags ?? [];
    if (labelTags.contains('en:gluten-free')) {
      flags.add('gluten-free');
    }
    if (labelTags.contains('en:no-lactose') ||
        labelTags.contains('en:dairy-free')) {
      flags.add('dairy-free');
    }

    // Derive display category from the OFf category tag key
    final displayCategory = ingredientCategories.entries
        .where((e) => e.value == categoryTag)
        .map((e) => e.key)
        .firstOrNull;

    return Ingredient(
      id: product.barcode ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: product.productName ?? '',
      category: displayCategory,
      dietaryFlags: flags,
      cachedAt: DateTime.now(),
    );
  }
}
