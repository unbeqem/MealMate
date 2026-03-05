import 'package:flutter/material.dart';

/// Placeholder screen for meal plan templates.
///
/// Full implementation is added in Plan 05-04. This placeholder allows the
/// /planner/templates route to be registered without a build error.
class TemplateListScreen extends StatelessWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      body: const Center(child: Text('Templates — coming soon')),
    );
  }
}
