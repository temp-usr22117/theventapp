import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theventapp/widgets/floating_nav_bar.dart';

void main() {
  testWidgets('ModernFloatingNavBar renders and handles taps', (WidgetTester tester) async {
    int selectedTab = 0;
    bool postTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) {
              return ModernFloatingNavBar(
                currentIndex: selectedTab,
                onTabSelected: (index) {
                  setState(() => selectedTab = index);
                },
                onPostTap: () {
                  postTapped = true;
                },
              );
            },
          ),
        ),
      ),
    );

    // Verify Home, Post, Profile are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Post'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Tap Profile
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(selectedTab, 1);

    // Tap Home
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(selectedTab, 0);

    // Tap Post
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    expect(postTapped, isTrue);
  });

  testWidgets('ModernFloatingNavBar handles horizontal sliding gestures', (WidgetTester tester) async {
    int selectedTab = 0;
    bool postTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) {
              return ModernFloatingNavBar(
                currentIndex: selectedTab,
                onTabSelected: (index) {
                  setState(() => selectedTab = index);
                },
                onPostTap: () {
                  postTapped = true;
                },
              );
            },
          ),
        ),
      ),
    );

    final navBarFinder = find.byType(ModernFloatingNavBar);
    expect(navBarFinder, findsOneWidget);

    // Drag from left to right across the bar
    final center = tester.getCenter(navBarFinder);
    final leftOrigin = Offset(center.dx - 120, center.dy);
    final rightDestination = Offset(center.dx + 120, center.dy);

    final gesture = await tester.startGesture(leftOrigin);
    await tester.pump();

    // Slide toward right (Profile)
    await gesture.moveTo(rightDestination);
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selectedTab, 1);

    // Now slide back to left (Home)
    final gestureBack = await tester.startGesture(rightDestination);
    await tester.pump();
    await gestureBack.moveTo(leftOrigin);
    await tester.pumpAndSettle();
    await gestureBack.up();
    await tester.pumpAndSettle();

    expect(selectedTab, 0);

    // Slide onto center (Post) and release
    final gestureCenter = await tester.startGesture(leftOrigin);
    await tester.pump();
    await gestureCenter.moveTo(center);
    await tester.pumpAndSettle();
    await gestureCenter.up();
    await tester.pumpAndSettle();

    expect(postTapped, isTrue);
  });
}
