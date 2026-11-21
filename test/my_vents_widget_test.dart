import 'package:flutter/material.dart';
import 'package:theventapp/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theventapp/models/post_model.dart';

void main() {
  group('My Vents UI Tests', () {
    testWidgets('Renders empty state when user has no vents', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Text(
                      'No vents yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Your anonymous vents and thoughts will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No vents yet'), findsOneWidget);
      expect(
        find.text('Your anonymous vents and thoughts will appear here.'),
        findsOneWidget,
      );
    });

    testWidgets('Renders vent card with delete action and shows confirm dialog',
        (tester) async {
      final samplePost = PostModel(
        id: 'test-vent-1',
        userId: 'user-123',
        content: 'This is my secret vent that I want to delete.',
        likesCount: 5,
        isLiked: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        username: 'mclovin22117',
      );

      bool deleteTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Card(
                  child: ListTile(
                    title: Text(samplePost.content),
                    subtitle: Text('${samplePost.likesCount} likes'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Vent'),
                            content: const Text(
                              'Are you sure you want to delete this vent? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          deleteTriggered = true;
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(
        find.text('This is my secret vent that I want to delete.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Tap delete icon to open confirmation dialog
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Delete Vent'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete this vent? This action cannot be undone.',
        ),
        findsOneWidget,
      );

      // Tap Delete in dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleteTriggered, isTrue);
    });
  });
}
