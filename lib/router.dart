import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard_page.dart';
import 'login_page.dart';
import 'tactics_board_page.dart';
import 'ui_kit_page.dart';

String? _pendingDeepLink;

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isLoginRoute = state.matchedLocation == '/';

    if (!isLoggedIn && !isLoginRoute) {
      _pendingDeepLink = state.uri.toString();
      return '/';
    }
    if (isLoggedIn && isLoginRoute) {
      final dest = _pendingDeepLink;
      _pendingDeepLink = null;
      return dest ?? '/dashboard';
    }
    return null;
  },
  refreshListenable: _AuthChangeNotifier(),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/board/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        // extra может содержать BoardModel для быстрого открытия без доп. запроса
        final extra = state.extra as Map<String, dynamic>?;
        return TacticsBoardPage(
          boardId: id,
          boardTitle: extra?['title'] as String?,
          initialSnapshot: extra?['snapshot'] as Map<String, dynamic>?,
        );
      },
    ),
    GoRoute(
      path: '/ui-kit',
      builder: (context, state) => const UiKitPage(),
    ),
  ],
);

/// Notifies GoRouter когда меняется auth-состояние Supabase.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}
