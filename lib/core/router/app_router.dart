import 'package:go_router/go_router.dart';

import '../../features/events/presentation/screens/event_archive_screen.dart';
import '../../features/events/presentation/screens/event_form_screen.dart';
import '../../features/events/presentation/screens/events_list_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const EventsListScreen(),
    ),
    GoRoute(
      path: '/events/new',
      builder: (context, state) => const EventFormScreen(),
    ),
    GoRoute(
      path: '/events/:id/edit',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null ? '/' : null;
      },
      builder: (context, state) => EventFormScreen(
        eventId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/events/archives',
      builder: (context, state) => const EventArchiveScreen(),
    ),
  ],
);
