# Jalon 1 - Socle - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the DIF Pass Flutter project skeleton so that later milestones (Events, Beneficiaries, Tickets, Check-in, Backup) build on a working, tested foundation: FVM-pinned toolchain, feature-first `core/` layer, the DIF theme, i18n (FR/EN), go_router, and a Drift database with all six MVP tables.

**Architecture:** A single Flutter project at the repo root (package name `dif_pass`, Android/iOS applicationId `com.difcorporation.difpass`). This milestone only builds `lib/core/` and `lib/l10n/` plus a temporary placeholder screen; `lib/features/*` and `lib/shared/` are deliberately not created yet, they start in jalon 2 (Events) so we never scaffold empty folders with no real content.

**Tech Stack:** Flutter (FVM-pinned, see below) + Riverpod (`flutter_riverpod`) + go_router + Drift (SQLite) + `flutter_localizations`/`intl` (ARB) + `google_fonts`.

## Global Constraints

- Flutter version: pinned via FVM to **3.44.7** (stable channel, already cached locally on this machine; chosen over the very recently released 3.47.1 for maturity and to avoid a slow SDK download). Every Flutter/Dart command is prefixed `fvm flutter` / `fvm dart`.
- Application ID (Android `applicationId` and iOS `PRODUCT_BUNDLE_IDENTIFIER`): `com.difcorporation.difpass`.
- Never hand-edit generated `.g.dart` files. Regenerate with `fvm dart run build_runner build --delete-conflicting-outputs`.
- No em dashes (tirets cadratins) in code, comments, or commit messages.
- Git branch names are descriptive; this milestone's work happens on its own branch, not on `main`.
- No "Generated with Claude" / "Co-Authored-By: Claude" in commits or PRs.
- Interface language: French + English from the start, ARB is the source of truth, never retrofit i18n.
- Target platforms: Android + iOS.

---

### Task 1: Bootstrap the Flutter project via FVM

**Files:**
- Create: entire Flutter project skeleton at repo root (`pubspec.yaml`, `lib/main.dart`, `test/widget_test.dart`, `android/`, `ios/`, `.fvmrc`, `.gitignore` additions)
- Modify: `android/app/build.gradle.kts`, `ios/Runner.xcodeproj/project.pbxproj` (application id correction)

**Interfaces:**
- Produces: a Flutter project named `dif_pass` at the repo root, FVM-pinned to 3.44.7, with applicationId/bundle id `com.difcorporation.difpass`. All later tasks add files under this project's `lib/` and `test/`.

- [ ] **Step 1: Create the milestone branch**

```bash
git checkout -b chore/jalon-1-socle
```

- [ ] **Step 2: Install and pin the Flutter version with FVM**

```bash
fvm install 3.44.7
fvm use 3.44.7
```

Expected: `.fvmrc` is created at the repo root containing `{"flutter": "3.44.7"}` (or equivalent FVM config).

- [ ] **Step 3: Scaffold the Flutter project in place**

```bash
fvm flutter create --org com.difcorporation --project-name dif_pass --platforms android,ios --description "DIF Pass, gestion de tickets et controle de presence pour evenements" .
```

Expected: exit code 0, `pubspec.yaml`, `lib/main.dart`, `test/widget_test.dart`, `android/`, `ios/` created without touching `Prompt_Lancement_Claude_Code_DIF_Pass.md` or `docs/`.

- [ ] **Step 4: Verify the default toolchain works**

```bash
fvm flutter test
```

Expected: PASS (the default counter-app widget test that ships with `flutter create`).

- [ ] **Step 5: Correct the application id to `com.difcorporation.difpass`**

`flutter create --org com.difcorporation --project-name dif_pass` generates the id `com.difcorporation.dif_pass` (with the underscore from the project name). Replace every occurrence of `com.difcorporation.dif_pass` with `com.difcorporation.difpass` in:
- `android/app/build.gradle.kts` (covers both the `namespace` and `applicationId` entries)
- `ios/Runner.xcodeproj/project.pbxproj` (covers `PRODUCT_BUNDLE_IDENTIFIER` for the Runner and RunnerTests targets)

Verify no occurrences of the old id remain:

```bash
grep -rn "com.difcorporation.dif_pass" android/app/build.gradle.kts ios/Runner.xcodeproj/project.pbxproj
```

Expected: no output (no matches).

- [ ] **Step 6: Keep the local FVM cache out of git**

Append to `.gitignore`:

```
.fvm/
```

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Bootstrap dif_pass Flutter project via FVM 3.44.7"
```

---

### Task 2: Add project dependencies

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: the project scaffold from Task 1.
- Produces: `flutter_riverpod`, `go_router`, `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`, `qr_flutter`, `mobile_scanner`, `pdf`, `printing`, `csv`, `share_plus`, `flutter_animate`, `google_fonts`, `file_picker`, `shared_preferences`, `flutter_localizations`, `intl` available as imports; `drift_dev` and `build_runner` available for code generation. All later tasks in this plan rely on these being present.

- [ ] **Step 1: Add runtime dependencies**

```bash
fvm flutter pub add flutter_riverpod go_router drift sqlite3_flutter_libs path_provider path qr_flutter mobile_scanner pdf printing csv share_plus flutter_animate google_fonts file_picker shared_preferences
```

Expected: exit code 0, all packages listed under `dependencies:` in `pubspec.yaml`.

- [ ] **Step 2: Add the localization dependencies**

```bash
fvm flutter pub add flutter_localizations --sdk=flutter
fvm flutter pub add intl
```

Expected: exit code 0, `flutter_localizations` (sourced from the Flutter SDK) and `intl` listed under `dependencies:`.

- [ ] **Step 3: Add dev dependencies for Drift code generation**

```bash
fvm flutter pub add dev:drift_dev dev:build_runner
```

Expected: exit code 0, `drift_dev` and `build_runner` listed under `dev_dependencies:`.

- [ ] **Step 4: Verify resolution and static analysis**

```bash
fvm flutter pub get
fvm flutter analyze
```

Expected: both commands exit 0 with no errors (warnings about unused default files are fine at this stage).

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "Add DIF Pass runtime and dev dependencies"
```

---

### Task 3: DIF theme (`theme.dart`)

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_typography.dart`
- Create: `lib/core/theme/app_theme.dart`
- Test: `test/core/theme/app_theme_test.dart`

**Interfaces:**
- Consumes: `google_fonts` (Task 2).
- Produces: `AppColors` (static color constants), `buildAppTextTheme(ColorScheme) -> TextTheme`, `ticketMonoStyle(ColorScheme) -> TextStyle`, `buildAppTheme() -> ThemeData`. Task 7 calls `buildAppTheme()` directly.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/theme/app_theme_test.dart
import 'package:dif_pass/core/theme/app_colors.dart';
import 'package:dif_pass/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildAppTheme uses the DIF Pass indigo accent as primary color', () {
    final theme = buildAppTheme();

    expect(theme.colorScheme.primary, AppColors.indigo);
    expect(theme.scaffoldBackgroundColor, AppColors.paper);
    expect(theme.useMaterial3, isTrue);
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/core/theme/app_theme_test.dart
```

Expected: FAIL (compile error, `package:dif_pass/core/theme/app_theme.dart` does not exist).

- [ ] **Step 3: Implement the theme files**

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const ink = Color(0xFF1B1F3B);
  static const paper = Color(0xFFF0F1F5);
  static const ochre = Color(0xFFE8A33D);
  static const teal = Color(0xFF1F6E5C);
  static const indigo = Color(0xFF5B6EE8);
}
```

```dart
// lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme buildAppTextTheme(ColorScheme colorScheme) {
  final base = ThemeData(colorScheme: colorScheme).textTheme;
  final display = GoogleFonts.bigShouldersDisplayTextTheme(base);
  final body = GoogleFonts.ibmPlexSansTextTheme(base);

  return body.copyWith(
    displayLarge: display.displayLarge,
    displayMedium: display.displayMedium,
    displaySmall: display.displaySmall,
    headlineLarge: display.headlineLarge,
    headlineMedium: display.headlineMedium,
    headlineSmall: display.headlineSmall,
    titleLarge: display.titleLarge,
  );
}

// Used for ticket identifiers, live counters, and other data-like text.
TextStyle ticketMonoStyle(ColorScheme colorScheme) {
  return GoogleFonts.ibmPlexMono(color: colorScheme.onSurface);
}
```

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    brightness: Brightness.light,
    primary: AppColors.indigo,
    secondary: AppColors.teal,
    tertiary: AppColors.ochre,
    surface: AppColors.paper,
    onSurface: AppColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.paper,
    textTheme: buildAppTextTheme(colorScheme),
  );
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/core/theme/app_theme_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme test/core/theme
git commit -m "Add DIF Pass theme"
```

---

### Task 4: i18n setup (ARB, FR/EN)

**Files:**
- Create: `l10n.yaml`
- Create: `lib/l10n/app_en.arb`
- Create: `lib/l10n/app_fr.arb`
- Modify: `pubspec.yaml` (add `flutter: generate: true`)
- Test: `test/l10n_test.dart`

**Interfaces:**
- Consumes: `flutter_localizations`, `intl` (Task 2).
- Produces: generated `AppLocalizations` class, importable as `package:dif_pass/l10n/app_localizations.dart`, exposing `AppLocalizations.localizationsDelegates`, `AppLocalizations.supportedLocales`, and getters `appTitle` and `homeWelcome`. Tasks 5 and 7 depend on this import path and these getters.

- [ ] **Step 1: Write the failing test**

```dart
// test/l10n_test.dart
import 'package:flutter/material.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'AppLocalizations exposes French and English copy from the ARB files',
      (tester) async {
    Future<AppLocalizations> loadFor(Locale locale) async {
      late AppLocalizations localizations;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              localizations = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return localizations;
    }

    final fr = await loadFor(const Locale('fr'));
    expect(fr.homeWelcome, 'Bienvenue sur DIF Pass');

    final en = await loadFor(const Locale('en'));
    expect(en.homeWelcome, 'Welcome to DIF Pass');
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/l10n_test.dart
```

Expected: FAIL (`package:dif_pass/l10n/app_localizations.dart` does not exist yet).

- [ ] **Step 3: Implement the ARB files and generate localizations**

```yaml
# l10n.yaml (repo root)
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

With no `output-dir` set, this generates `app_localizations.dart` directly into `lib/l10n/` (alongside the ARB files), importable as a normal package file: `package:dif_pass/l10n/app_localizations.dart`. This avoids the older, now-deprecated Flutter synthetic-package mechanism (`package:flutter_gen/...`), which is no longer generated automatically by current Flutter SDKs and would otherwise require hand-rolling a fake local `flutter_gen` package as a path dependency just to get that import path to resolve, a needless extra package for no real benefit. (An earlier version of this note also set `synthetic-package: false` explicitly; that flag is itself deprecated in current Flutter SDKs and emits a warning, and is unnecessary since non-synthetic output is already the default once no `output-dir` forces the old location, so it is omitted here.)

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en",
  "appTitle": "DIF Pass",
  "homeWelcome": "Welcome to DIF Pass"
}
```

```json
// lib/l10n/app_fr.arb
{
  "@@locale": "fr",
  "appTitle": "DIF Pass",
  "homeWelcome": "Bienvenue sur DIF Pass"
}
```

In `pubspec.yaml`, under the existing `flutter:` section, add:

```yaml
flutter:
  generate: true
```

Generate the localization code:

```bash
fvm flutter gen-l10n
```

Expected: exit code 0, no output errors.

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/l10n_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add l10n.yaml lib/l10n pubspec.yaml test/l10n_test.dart
git commit -m "Set up i18n with FR/EN ARB files"
```

---

### Task 5: Router (`go_router`) and placeholder home screen

**Files:**
- Create: `lib/core/router/app_router.dart`
- Test: `test/core/router/app_router_test.dart`

**Interfaces:**
- Consumes: `AppLocalizations` (Task 4).
- Produces: `appRouter` (a `GoRouter`) in `lib/core/router/app_router.dart`, with a single route `/`. Task 7 passes this to `MaterialApp.router(routerConfig: appRouter)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/router/app_router_test.dart
import 'package:dif_pass/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app router shows the placeholder home screen at /',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: appRouter,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    expect(find.text('Welcome to DIF Pass'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/core/router/app_router_test.dart
```

Expected: FAIL (`package:dif_pass/core/router/app_router.dart` does not exist).

- [ ] **Step 3: Implement the router**

```dart
// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _PlaceholderHomeScreen(),
    ),
  ],
);

// ponytail: temporary landing screen, replaced by the real events list
// screen in jalon 2 (Evenements).
class _PlaceholderHomeScreen extends StatelessWidget {
  const _PlaceholderHomeScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(child: Text(l10n.homeWelcome)),
    );
  }
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/core/router/app_router_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/router test/core/router
git commit -m "Add go_router with placeholder home screen"
```

---

### Task 6: Drift database (six MVP tables)

**Files:**
- Create: `lib/core/database/tables/events_table.dart`
- Create: `lib/core/database/tables/custom_fields_table.dart`
- Create: `lib/core/database/tables/beneficiaries_table.dart`
- Create: `lib/core/database/tables/beneficiary_values_table.dart`
- Create: `lib/core/database/tables/tickets_table.dart`
- Create: `lib/core/database/tables/checkins_table.dart`
- Create: `lib/core/database/app_database.dart`
- Create (generated): `lib/core/database/app_database.g.dart`
- Test: `test/core/database/app_database_test.dart`

**Interfaces:**
- Consumes: `drift`, `drift_dev`, `path`, `path_provider`, `sqlite3_flutter_libs` (Task 2).
- Produces: `AppDatabase` class with table getters `events`, `customFields`, `beneficiaries`, `beneficiaryValues`, `tickets`, `checkIns`; generated Companion classes (`EventsCompanion`, etc.); `AppDatabase()` (production, file-backed) and `AppDatabase.forTesting(QueryExecutor)` (in-memory) constructors. Task 7's `appDatabaseProvider` depends on `AppDatabase()`.

Note: `presenceMode` (Events) and `fieldType` (CustomFields) are plain `TextColumn`s rather than Drift's `textEnum<T>()` helper. Converting to/from the `PresenceMode`/`CustomFieldType` Dart enums happens in the repository layer starting jalon 2, keeping this table layer free of app-level enum imports.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/database/app_database_test.dart
import 'package:dif_pass/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppDatabase can insert and read back an event', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final id = await db.into(db.events).insert(
          EventsCompanion.insert(
            shortCode: 'EVT1',
            name: 'Gala DIF 2026',
            date: DateTime(2026, 12, 1),
            presenceMode: 'simple',
          ),
        );

    final saved = await (db.select(db.events)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    expect(saved.name, 'Gala DIF 2026');
    expect(saved.presenceMode, 'simple');
    expect(saved.archivedAt, isNull);
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/core/database/app_database_test.dart
```

Expected: FAIL (`package:dif_pass/core/database/app_database.dart` does not exist).

- [ ] **Step 3: Implement the tables and the database**

```dart
// lib/core/database/tables/events_table.dart
import 'package:drift/drift.dart';

@DataClassName('EventEntity')
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shortCode => text()();
  TextColumn get name => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get location => text().nullable()();
  BlobColumn get logo => blob().nullable()();
  // ponytail: plain text ('simple' | 'multiple') instead of Drift's
  // textEnum<T>() sugar, converted to PresenceMode in the repository layer.
  TextColumn get presenceMode => text()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

```dart
// lib/core/database/tables/custom_fields_table.dart
import 'package:drift/drift.dart';

import 'events_table.dart';

@DataClassName('CustomFieldEntity')
class CustomFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer().references(Events, #id)();
  TextColumn get label => text()();
  // plain text ('text' | 'number'), same reasoning as Events.presenceMode.
  TextColumn get fieldType => text()();
  IntColumn get sortOrder => integer()();
  BoolColumn get showOnTicket => boolean().withDefault(const Constant(false))();
}
```

```dart
// lib/core/database/tables/beneficiaries_table.dart
import 'package:drift/drift.dart';

import 'events_table.dart';

@DataClassName('BeneficiaryEntity')
class Beneficiaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer().references(Events, #id)();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

```dart
// lib/core/database/tables/beneficiary_values_table.dart
import 'package:drift/drift.dart';

import 'beneficiaries_table.dart';
import 'custom_fields_table.dart';

@DataClassName('BeneficiaryValueEntity')
class BeneficiaryValues extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get beneficiaryId => integer().references(Beneficiaries, #id)();
  IntColumn get customFieldId => integer().references(CustomFields, #id)();
  TextColumn get value => text()();
}
```

```dart
// lib/core/database/tables/tickets_table.dart
import 'package:drift/drift.dart';

import 'beneficiaries_table.dart';
import 'events_table.dart';

@DataClassName('TicketEntity')
class Tickets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get beneficiaryId => integer().references(Beneficiaries, #id)();
  IntColumn get eventId => integer().references(Events, #id)();
  TextColumn get readableId => text()();
  TextColumn get randomPart => text()();
  TextColumn get qrPayload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {eventId, readableId},
      ];
}
```

```dart
// lib/core/database/tables/checkins_table.dart
import 'package:drift/drift.dart';

import 'events_table.dart';
import 'tickets_table.dart';

@DataClassName('CheckInEntity')
class CheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ticketId => integer().references(Tickets, #id)();
  IntColumn get eventId => integer().references(Events, #id)();
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();
}
```

```dart
// lib/core/database/app_database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/beneficiaries_table.dart';
import 'tables/beneficiary_values_table.dart';
import 'tables/checkins_table.dart';
import 'tables/custom_fields_table.dart';
import 'tables/events_table.dart';
import 'tables/tickets_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Events,
  CustomFields,
  Beneficiaries,
  BeneficiaryValues,
  Tickets,
  CheckIns,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dif_pass.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

Generate the Drift code:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Expected: exit code 0, `lib/core/database/app_database.g.dart` is created.

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/core/database/app_database_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/database test/core/database
git commit -m "Add Drift database with the six MVP tables"
```

---

### Task 7: Wire everything into `main.dart`

**Files:**
- Create: `lib/core/database/database_provider.dart`
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `buildAppTheme()` (Task 3), `appRouter` + `AppLocalizations` (Tasks 4-5), `AppDatabase` (Task 6), `flutter_riverpod` (Task 2).
- Produces: `DifPassApp` widget (`lib/main.dart`), `appDatabaseProvider` (`Provider<AppDatabase>`, `lib/core/database/database_provider.dart`) for later features to read the database through Riverpod.

- [ ] **Step 1: Write the failing test**

Replace the default counter-app test with the app smoke test:

```dart
// test/widget_test.dart
import 'package:dif_pass/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DifPassApp boots to the placeholder home screen',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DifPassApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to DIF Pass'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test, verify it fails**

```bash
fvm flutter test test/widget_test.dart
```

Expected: FAIL (`DifPassApp` is not defined; `lib/main.dart` still has the default counter app).

- [ ] **Step 3: Implement the database provider and `main.dart`**

```dart
// lib/core/database/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
```

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:dif_pass/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: DifPassApp()));
}

class DifPassApp extends StatelessWidget {
  const DifPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DIF Pass',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
```

- [ ] **Step 4: Run the test, verify it passes**

```bash
fvm flutter test test/widget_test.dart
```

Expected: PASS.

- [ ] **Step 5: Run the full test suite and analyzer as a milestone-wide check**

```bash
fvm flutter test
fvm flutter analyze
```

Expected: all tests PASS, analyzer reports no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/database/database_provider.dart lib/main.dart test/widget_test.dart
git commit -m "Wire theme, router, i18n and database into DifPassApp"
```

---

## Milestone acceptance

Jalon 1 (Socle) is done when, from a clean checkout on this branch:

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test
fvm flutter analyze
```

all succeed, and `fvm flutter run` boots to a screen showing "Welcome to DIF Pass" / "Bienvenue sur DIF Pass" depending on system locale, themed in DIF Pass Indigo.
