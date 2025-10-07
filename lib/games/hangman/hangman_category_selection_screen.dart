import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Define the categories here or import from where HangmanScreen defines them
// For now, let's duplicate for simplicity, but ideally, this should be shared.
final Map<String, List<String>> _hangmanWordCategories = {
  'Animals': ['TIGER', 'LION', 'BEAR', 'ZEBRA', 'MONKEY', 'ELEPHANT'],
  'Fruits': ['APPLE', 'BANANA', 'ORANGE', 'GRAPE', 'MANGO', 'PEACH'],
  'Programming': [
    'FLUTTER',
    'DART',
    'WIDGET',
    'MOBILE',
    'NGAMES',
    'PYTHON',
    'JAVA',
  ],
  'Countries': [
    'INDIA',
    'NEPAL',
    'CHINA',
    'JAPAN',
    'BRAZIL',
    'CANADA',
    'FRANCE',
  ],
};

// Helper to get an icon for a category (can be expanded)
IconData _getIconForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'animals':
      return Icons.pets_rounded;
    case 'fruits':
      return Icons.apple_rounded;
    case 'programming':
      return Icons.code_rounded;
    case 'countries':
      return Icons.public_rounded;
    default:
      return Icons.category_rounded;
  }
}

class HangmanCategorySelectionScreen extends StatelessWidget {
  const HangmanCategorySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _hangmanWordCategories.keys.toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Back to Home',
        ),
        title: const Text('Choose a Category'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two columns
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.2, // Adjust for desired tile shape
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final icon = _getIconForCategory(category);
          return Card(
            elevation: 3.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: theme.colorScheme.secondaryContainer.withOpacity(0.8),
            clipBehavior: Clip.antiAlias, // Ensures InkWell ripple is contained
            child: InkWell(
              onTap: () {
                context.go('/game/hangman', extra: category);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      category,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
