import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MealMate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Find Ingredients'),
                subtitle: const Text('Search, browse, and select ingredients'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/ingredients'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text('Browse Recipes'),
                subtitle: const Text('Search, filter, and discover recipes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/recipes'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Meal Planner'),
                subtitle: const Text('Plan your weekly meals'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/planner'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
