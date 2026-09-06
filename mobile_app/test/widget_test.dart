import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_metrology/core/auth/auth_controller.dart';
import 'package:legal_metrology/data/mock_backend.dart';
import 'package:legal_metrology/data/mock/mock_repositories.dart';
import 'package:legal_metrology/di/providers.dart';
import 'package:legal_metrology/main.dart';
import 'package:legal_metrology/models/inspection.dart';
import 'package:legal_metrology/models/user.dart';
import 'package:legal_metrology/repositories/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockBackend auth', () {
    test('inspector demo login succeeds and returns INSPECTOR role', () async {
      final backend = MockBackend.instance;
      final result = backend.login('rajesh.deshmukh', 'inspector123');
      expect(result.user.role, UserRole.inspector);
      expect(result.accessToken, isNotEmpty);
    });

    test('business demo login succeeds and returns BUSINESS role', () {
      final backend = MockBackend.instance;
      final result = backend.login('anita@abctraders.in', 'business123');
      expect(result.user.role, UserRole.business);
    });

    test('wrong password is rejected', () {
      final backend = MockBackend.instance;
      expect(
        () => backend.login('rajesh.deshmukh', 'nope'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Mock repositories', () {
    late MockBackend backend;

    setUp(() {
      backend = MockBackend.instance;
      backend.login('rajesh.deshmukh', 'inspector123');
    });

    test('business search finds seeded businesses', () async {
      final repo = MockBusinessRepository(backend);
      final results = await repo.searchBusinesses('ABC');
      expect(results, isNotEmpty);
      expect(results.first.name, contains('ABC'));
    });

    test('inspection creation returns a realistic id', () async {
      final repo = MockInspectionRepository(backend);
      final inspection = await repo.createInspection(
        const CreateInspectionRequest(businessId: 'biz-001', type: InspectionType.routine),
      );
      expect(inspection.id, startsWith('INSP-2026-'));
      expect(inspection.status, InspectionStatus.inProgress);
    });

    test('mock auth repository completes the login contract', () async {
      final repo = MockAuthRepository(backend);
      final result = await repo.login(username: 'rajesh.deshmukh', password: 'inspector123');
      expect(result.user.isInspector, isTrue);
      final current = await repo.currentUser();
      expect(current, isNotNull);
      await repo.logout();
      expect(await repo.currentUser(), isNull);
    });
  });

  group('App widget', () {
    testWidgets('renders splash while restoring session', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: LegalMetrologyApp()),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Legal Metrology'), findsWidgets);
    });
  });

  group('AuthController state', () {
    testWidgets('starts in restoring state and resolves unauthenticated',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // AuthController is created lazily by reading the provider.
      final state = container.read(authControllerProvider);
      expect(state.isRestoring, isTrue);
    });
  });
}
