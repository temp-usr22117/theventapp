import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theventapp/utils/responsive.dart';

void main() {
  testWidgets('Floating snackbar clears bottom nav bar with 100 margin on mobile',
      (tester) async {
    // Set mobile dimensions
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() => tester.view.resetPhysicalSize());

    BuildContext? savedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              savedContext = context;
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Failed to upload image'),
                          ],
                        ),
                        backgroundColor: const Color(0xFFD32F2F),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                          bottom: Responsive.isWide(context) ? 20.0 : 100.0,
                          left: 16.0,
                          right: 16.0,
                        ),
                      ),
                    );
                  },
                  child: const Text('Show Error'),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Tap button to show SnackBar
    await tester.tap(find.text('Show Error'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 750)); // Animation finished

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Failed to upload image'), findsOneWidget);

    final SnackBar snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, const Color(0xFFD32F2F));
    expect(snackBar.behavior, SnackBarBehavior.floating);

    final margin = snackBar.margin as EdgeInsets;
    expect(margin.bottom, 100.0);
    expect(margin.left, 16.0);
    expect(margin.right, 16.0);
  });
}
