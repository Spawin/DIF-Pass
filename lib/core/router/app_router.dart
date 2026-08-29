import 'package:go_router/go_router.dart';

import '../../features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart';
import '../../features/beneficiaries/presentation/screens/beneficiary_form_screen.dart';
import '../../features/beneficiaries/presentation/screens/csv_import_screen.dart';
import '../../features/events/presentation/screens/event_archive_screen.dart';
import '../../features/events/presentation/screens/event_form_screen.dart';
import '../../features/events/presentation/screens/events_list_screen.dart';
import '../../features/tickets/presentation/screens/ticket_preview_screen.dart';
import '../../features/tickets/presentation/screens/tickets_screen.dart';

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
    GoRoute(
      path: '/events/:id/beneficiaries',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null ? '/' : null;
      },
      builder: (context, state) => BeneficiariesListScreen(
        eventId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/events/:id/beneficiaries/new',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null ? '/' : null;
      },
      builder: (context, state) => BeneficiaryFormScreen(
        eventId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/events/:id/beneficiaries/:beneficiaryId/edit',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        final beneficiaryId = int.tryParse(state.pathParameters['beneficiaryId'] ?? '');
        return (id == null || beneficiaryId == null) ? '/' : null;
      },
      builder: (context, state) => BeneficiaryFormScreen(
        eventId: int.parse(state.pathParameters['id']!),
        beneficiaryId: int.parse(state.pathParameters['beneficiaryId']!),
      ),
    ),
    GoRoute(
      path: '/events/:id/beneficiaries/import',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null ? '/' : null;
      },
      builder: (context, state) => CsvImportScreen(
        eventId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/events/:id/tickets',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return id == null ? '/' : null;
      },
      builder: (context, state) => TicketsScreen(
        eventId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/events/:id/tickets/:ticketId',
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        final ticketId = int.tryParse(state.pathParameters['ticketId'] ?? '');
        return (id == null || ticketId == null) ? '/' : null;
      },
      builder: (context, state) => TicketPreviewScreen(
        ticketId: int.parse(state.pathParameters['ticketId']!),
      ),
    ),
  ],
);
