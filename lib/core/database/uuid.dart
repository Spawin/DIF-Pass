import 'package:uuid/uuid.dart';

/// Shared generator for the `sync_id` client defaults (table definitions)
/// and the v2 -> v3 backfill (app_database.dart).
///
/// ponytail: one plain instance, no caching singleton class. `Uuid()` holds
/// only a small RNG; a per-call `Uuid()` would also be fine, this just keeps
/// the call sites short.
final Uuid uuidGen = Uuid();
