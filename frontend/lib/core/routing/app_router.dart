import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/login/login_screen.dart';
import '../../features/authentication/register/register_screen.dart';
import '../../features/authentication/welcome/welcome_screen.dart';
import '../../features/authentication/forgot_password/forgot_password_screen.dart';
import '../../features/booking/booking_review_screen.dart';
import '../../features/bookings/my_tickets_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/notifications/inbox_screen.dart';
import '../../features/offers/offers_screen.dart';
import '../../features/passenger/passenger_screen.dart';
import '../../features/payment/method/payment_method_screen.dart';
import '../../features/payment/mock_app/payment_app_screen.dart';
import '../../features/payment/mock_web/payment_web_screen.dart';
import '../../features/payment/processing/payment_processing_screen.dart';
import '../../features/payment/qr/payment_qr_screen.dart';
import '../../features/payment/result/payment_result_screen.dart';
import '../../features/pnr/pnr_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/search/location_picker_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/bus/bus_results_screen.dart';
import '../../features/train/train_details_screen.dart';
import '../../features/bus/bus_details_screen.dart';
import '../../features/ticket/e_ticket_screen.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/misc.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final shellIndex = StateProvider<int>((ref) => 0);
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final auth = ref.read(authProvider).valueOrNull;
      final authed = auth?.authenticated ?? false;
      final path = state.matchedLocation;

      final publicRoutes = {'/splash', '/welcome', '/login', '/register', '/forgot-password', '/otp'};
      final isPublic = publicRoutes.any(path.startsWith);

      if (authed && isPublic) return '/home';
      if (!authed && !isPublic && path != '/splash') return '/welcome';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/otp', builder: (_, __) => const OtpScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _AppShell(navigationShell: navigationShell, currentIndexProvider: shellIndex),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/bookings', builder: (_, __) => const MyTicketsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/offers', builder: (_, __) => const OffersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),

      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/search/location', builder: (_, state) => LocationPickerScreen(mode: state.uri.queryParameters['mode'] ?? 'source')),
      GoRoute(path: '/search/results/bus', builder: (_, __) => const BusSearchResultsScreen()),
      GoRoute(path: '/search/results/train', builder: (_, __) => const TrainSearchResultsScreen()),
      GoRoute(path: '/bus/:id', builder: (_, state) => BusDetailsScreen(scheduleId: int.parse(state.pathParameters['id']!))),
      GoRoute(path: '/bus/:id/seats', builder: (_, state) => BusSeatsScreen(scheduleId: int.parse(state.pathParameters['id']!))),
      GoRoute(path: '/train/:id', builder: (_, state) => TrainDetailsScreen(scheduleId: int.parse(state.pathParameters['id']!))),
      GoRoute(path: '/train/:id/coaches', builder: (_, state) => TrainCoachesScreen(scheduleId: int.parse(state.pathParameters['id']!))),
      GoRoute(path: '/train/coaches/:coachId/berths', builder: (_, state) => TrainBerthsScreen(coachId: int.parse(state.pathParameters['coachId']!))),
      GoRoute(path: '/passengers', builder: (_, __) => const PassengerScreen()),
      GoRoute(path: '/booking/review', builder: (_, __) => const BookingReviewScreen()),
      GoRoute(path: '/payment/method', builder: (_, __) => const PaymentMethodScreen()),
      GoRoute(path: '/payment/app', builder: (_, __) => const PaymentAppScreen()),
      GoRoute(path: '/payment/web', builder: (_, __) => const PaymentWebScreen()),
      GoRoute(path: '/payment/qr', builder: (_, __) => const PaymentQrScreen()),
      GoRoute(path: '/payment/processing', builder: (_, __) => const PaymentProcessingScreen()),
      GoRoute(path: '/payment/result', builder: (_, state) => PaymentResultScreen(outcome: state.uri.queryParameters['status'] ?? '')),
      GoRoute(path: '/ticket/:pnr', builder: (_, state) => ETicketScreen(pnr: state.pathParameters['pnr']!)),
      GoRoute(path: '/pnr', builder: (_, __) => const PnrScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

class _AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final StateProvider<int> currentIndexProvider;

  const _AppShell({required this.navigationShell, required this.currentIndexProvider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentIndexProvider);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: TripGoBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(currentIndexProvider.notifier).state = index;
          navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
        },
      ),
    );
  }
}