import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theventapp/utils/responsive.dart';
import 'package:theventapp/widgets/desktop_sidebar.dart';
import 'package:theventapp/widgets/floating_nav_bar.dart';

void main() {
  group('Responsive Breakpoint Tests', () {
    testWidgets('identifies wide/desktop screen correctly and hides bottom nav bar',
        (tester) async {
      // Set desktop window size
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool isCollapsed = false;
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final isWide = Responsive.isWide(context);
                expect(isWide, isTrue);
                expect(Responsive.isDesktop(context), isTrue);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DesktopSidebar(
                      currentIndex: selectedTab,
                      onTabSelected: (idx) => selectedTab = idx,
                      onPostTap: () {},
                      isCollapsed: isCollapsed,
                      onToggleCollapse: () => isCollapsed = !isCollapsed,
                      onLogout: () {},
                    ),
                    const Expanded(child: Center(child: Text('Content Area'))),
                  ],
                );
              },
            ),
            bottomNavigationBar: null,
          ),
        ),
      );

      // Verify desktop sidebar is present
      expect(find.byType(DesktopSidebar), findsOneWidget);
      expect(find.text('TheVent'), findsOneWidget);
      expect(find.text('Home Feed'), findsOneWidget);
      expect(find.text('Create Vent'), findsOneWidget);

      // Verify bottom nav bar is NOT present
      expect(find.byType(ModernFloatingNavBar), findsNothing);
    });

    testWidgets('identifies mobile screen correctly and renders bottom nav bar',
        (tester) async {
      // Set mobile window size
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final isWide = Responsive.isWide(context);
                expect(isWide, isFalse);
                expect(Responsive.isMobile(context), isTrue);

                return const Center(child: Text('Mobile Feed'));
              },
            ),
            bottomNavigationBar: ModernFloatingNavBar(
              currentIndex: selectedTab,
              onTabSelected: (idx) => selectedTab = idx,
              onPostTap: () {},
            ),
          ),
        ),
      );

      // Verify bottom nav bar is rendered on mobile
      expect(find.byType(ModernFloatingNavBar), findsOneWidget);
      expect(find.byType(DesktopSidebar), findsNothing);
    });
  });
}
