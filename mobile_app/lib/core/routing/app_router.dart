import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/unauthorized_screen.dart';
import '../../features/business/business_shell.dart';
import '../../features/business/cases/business_cases_screen.dart';
import '../../features/business/dashboard/business_dashboard_screen.dart';
import '../../features/business/notices/notice_detail_screen.dart';
import '../../features/business/notices/notices_screen.dart';
import '../../features/business/payments/payments_screen.dart';
import '../../features/business/self_check/self_check_history_screen.dart';
import '../../features/business/self_check/self_check_screen.dart';
import '../../features/inspector/inspection/inspection_flow_screen.dart';
import '../../features/inspector/business_search/business_search_screen.dart';
import '../../features/inspector/cases/inspector_cases_screen.dart';
import '../../features/inspector/cases/case_detail_screen.dart';
import '../../features/inspector/dashboard/inspector_dashboard_screen.dart';
import '../../features/inspector/inspector_shell.dart';
import '../../features/inspector/inspections/inspections_screen.dart';
import '../../features/inspector/inspections/inspection_detail_screen.dart';

/// Route names (typed navigation).
abstract final class RouteNames {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const unauthorized = '/unauthorized';
  static const inspectorShell = '/inspector';
  static const inspectorDashboard = '/inspector/dashboard';
  static const inspectorInspections = '/inspector/inspections';
  static const inspectionDetail = '/inspector/inspections/:id';
  static const inspectionFlow = '/inspector/inspection-flow/:id';
  static const businessSearch = '/inspector/business-search';
  static const inspectorCases = '/inspector/cases';
  static const caseDetail = '/inspector/cases/:id';
  static const businessShell = '/business';
  static const businessDashboard = '/business/dashboard';
  static const selfCheck = '/business/self-check';
  static const selfCheckHistory = '/business/self-check/history';
  static const businessCases = '/business/cases';
  static const businessNotices = '/business/notices';
  static const businessNoticeDetail = '/business/notices/:id';
  static const payments = '/business/payments';
}

/// Inline case id segment helper.
String caseDetailPath(String id) => '/inspector/cases/$id';
String inspectionDetailPath(String id) => '/inspector/inspections/$id';
String inspectionFlowPath(String id) => '/inspector/inspection-flow/$id';
String businessNoticeDetailPath(String id) => '/business/notices/$id';

final routerProvider = Provider<GoRouter>((ref) {
  // Refresh signal for go_router. We must NOT `ref.watch` the auth state
  // here — that would rebuild the whole GoRouter on every auth change and
  // reset navigation to the initial location. Instead, auth state changes
  // bump a ValueNotifier wired as `refreshListenable`, and the redirect
  // callback reads the CURRENT auth state via `ref.read`.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final status = authState.status;
      final location = state.matchedLocation;
      final isAuthRoute =
          location == RouteNames.login || location == RouteNames.register;

      // Still restoring session → force splash.
      if (status == AuthStatus.initial || authState.isRestoring) {
        return location == RouteNames.splash ? null : RouteNames.splash;
      }

      // Session resolved → splash is transitional; never stay on it.
      if (location == RouteNames.splash) {
        return status == AuthStatus.authenticated
            ? (authState.isInspector
                ? RouteNames.inspectorDashboard
                : RouteNames.businessDashboard)
            : RouteNames.login;
      }

      // Unauthenticated → everything except login/register goes to login.
      if (status == AuthStatus.unauthenticated) {
        return isAuthRoute ? null : RouteNames.login;
      }

      // Authenticated: skip login/register → role dashboard.
      if (isAuthRoute) {
        return authState.isInspector
            ? RouteNames.inspectorDashboard
            : RouteNames.businessDashboard;
      }

      // Role-based route protection.
      final isInspectorRoute = location.startsWith('/inspector');
      final isBusinessRoute = location.startsWith('/business');
      if (isInspectorRoute && !authState.isInspector) return RouteNames.unauthorized;
      if (isBusinessRoute && !authState.isBusiness) return RouteNames.unauthorized;

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.unauthorized,
        builder: (context, state) => const UnauthorizedScreen(),
      ),

      // ---------------------------------------------------------- inspector
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => InspectorShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.inspectorDashboard,
              builder: (context, state) => const InspectorDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.inspectorInspections,
              builder: (context, state) => const InspectionsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => InspectionDetailScreen(
                    inspectionId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.businessSearch,
              builder: (context, state) => const BusinessSearchScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.inspectorCases,
              builder: (context, state) => const InspectorCasesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => CaseDetailScreen(
                    caseId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: RouteNames.inspectionFlow,
        builder: (context, state) => InspectionFlowScreen(
          inspectionId: state.pathParameters['id']!,
        ),
      ),

      // ----------------------------------------------------------- business
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => BusinessShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.businessDashboard,
              builder: (context, state) => const BusinessDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.selfCheck,
              builder: (context, state) => const SelfCheckScreen(),
              routes: [
                GoRoute(
                  path: 'history',
                  builder: (context, state) => const SelfCheckHistoryScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.businessCases,
              builder: (context, state) => const BusinessCasesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.businessNotices,
              builder: (context, state) => const BusinessNoticesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => BusinessNoticeDetailScreen(
                    noticeId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.payments,
              builder: (context, state) => const PaymentsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
