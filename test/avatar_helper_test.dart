import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theventapp/utils/avatar_helper.dart';

void main() {
  group('getUserAvatarImageProvider', () {
    test('returns null for null or empty input', () {
      expect(getUserAvatarImageProvider(null), isNull);
      expect(getUserAvatarImageProvider(''), isNull);
      expect(getUserAvatarImageProvider('   '), isNull);
    });

    test('returns NetworkImage for http/https URLs', () {
      final providerHttp =
          getUserAvatarImageProvider('http://example.com/avatar.jpg');
      expect(providerHttp, isA<NetworkImage>());
      expect((providerHttp as NetworkImage).url,
          'http://example.com/avatar.jpg');

      final providerHttps =
          getUserAvatarImageProvider('https://firebasestorage.googleapis.com/o/avatar.jpg');
      expect(providerHttps, isA<NetworkImage>());
      expect((providerHttps as NetworkImage).url,
          'https://firebasestorage.googleapis.com/o/avatar.jpg');
    });

    test('returns MemoryImage for data:image Base64 URIs', () {
      // 1x1 transparent png in base64
      const base64Png =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
      const dataUri = 'data:image/png;base64,$base64Png';

      final provider = getUserAvatarImageProvider(dataUri);
      expect(provider, isA<MemoryImage>());
      final memoryImage = provider as MemoryImage;
      expect(memoryImage.bytes, isNotEmpty);
      expect(memoryImage.bytes, equals(base64Decode(base64Png)));
    });

    test('returns null for invalid base64 data URI', () {
      final provider = getUserAvatarImageProvider('data:image/jpeg;base64,!!!INVALID!!!');
      expect(provider, isNull);
    });
  });

  group('UserAvatar widget', () {
    testWidgets('renders fallback icon when imageUrl is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(imageUrl: null, radius: 24),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('renders backgroundImage when imageUrl is a data URI',
        (tester) async {
      const base64Png =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
      const dataUri = 'data:image/png;base64,$base64Png';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(imageUrl: dataUri, radius: 24),
          ),
        ),
      );

      final circleAvatar =
          tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(circleAvatar.backgroundImage, isA<MemoryImage>());
      expect(find.byIcon(Icons.person_outline), findsNothing);
    });
  });
}
