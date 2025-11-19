import 'package:flutter/material.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:provider/provider.dart';

class YearbookBrowser extends StatelessWidget {
  const YearbookBrowser({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final batch = user.batchYear ?? '2024';

    return Scaffold(
      appBar: AppBar(title: Text("Batch $batch Yearbook")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 20),
            Text(
              "Yearbook for Batch $batch",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("This page will display the grid of graduates for this specific year."),
            ),
            // Placeholder for future GridView implementation
            const Text("(Grid feature coming soon)"),
          ],
        ),
      ),
    );
  }
}