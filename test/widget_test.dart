import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmcysas/features/auth/data/auth_repository.dart';
import 'package:pharmcysas/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pharmcysas/main.dart';

class MockAuthRepository implements AuthRepository {
  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          currentProfileProvider.overrideWith((ref) => Future.value(null)),
          currentPharmacyProvider.overrideWith((ref) => Future.value(null)),
        ],
        child: const PharmaCareApp(),
      ),
    );
    // Pump and verify root widget builds
    await tester.pump();
    expect(find.byType(PharmaCareApp), findsOneWidget);
  });
}
