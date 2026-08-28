import 'package:dif_pass/core/database/app_database.dart';
import 'package:dif_pass/features/events/data/drift_event_repository.dart';
import 'package:dif_pass/features/events/domain/custom_field.dart';
import 'package:dif_pass/features/events/domain/custom_field_type.dart';
import 'package:dif_pass/features/events/domain/presence_mode.dart';
import 'package:dif_pass/features/events/domain/ticket_template.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftEventRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftEventRepository(db);
  });

  tearDown(() => db.close());

  test('createEvent derives a unique shortCode from the inserted id', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );

    final event = await repository.getEvent(id);
    expect(event.shortCode, 'EVT$id');
    expect(event.name, 'Gala DIF 2026');
    expect(event.presenceMode, PresenceMode.simple);
    expect(event.isArchived, isFalse);
  });

  test('createEvent also creates the given custom fields', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [
        NewCustomFieldFixture(),
      ],
    );

    final fields = await repository.watchCustomFields(id).first;
    expect(fields, hasLength(1));
    expect(fields.single.label, 'Table number');
    expect(fields.single.type, CustomFieldType.number);
    expect(fields.single.showOnTicket, isTrue);
  });

  test('watchActiveEvents excludes archived events and sorts by date ascending', () async {
    final laterId = await repository.createEvent(
      name: 'Later event',
      date: DateTime(2026, 12, 20),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    final soonerId = await repository.createEvent(
      name: 'Sooner event',
      date: DateTime(2026, 12, 5),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    final archivedId = await repository.createEvent(
      name: 'Archived event',
      date: DateTime(2026, 11, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    await repository.archiveEvent(archivedId);

    final active = await repository.watchActiveEvents().first;
    expect(active.map((e) => e.id).toList(), [soonerId, laterId]);
  });

  test('watchArchivedEvents returns only archived events', () async {
    final activeId = await repository.createEvent(
      name: 'Active event',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    final archivedId = await repository.createEvent(
      name: 'Archived event',
      date: DateTime(2026, 11, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    await repository.archiveEvent(archivedId);

    final archived = await repository.watchArchivedEvents().first;
    expect(archived.map((e) => e.id).toList(), [archivedId]);
    expect(archived.single.isArchived, isTrue);

    final active = await repository.watchActiveEvents().first;
    expect(active.map((e) => e.id).toList(), [activeId]);
  });

  test('archiveEvent then restoreEvent clears archivedAt', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );

    await repository.archiveEvent(id);
    expect((await repository.getEvent(id)).isArchived, isTrue);

    await repository.restoreEvent(id);
    expect((await repository.getEvent(id)).isArchived, isFalse);
  });

  test('canEditCustomFields is true with no tickets and false once one exists', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    expect(await repository.canEditCustomFields(id), isTrue);

    final beneficiaryId = await db.into(db.beneficiaries).insert(
          BeneficiariesCompanion.insert(eventId: id, name: 'Jane Doe'),
        );
    await db.into(db.tickets).insert(
          TicketsCompanion.insert(
            beneficiaryId: beneficiaryId,
            eventId: id,
            readableId: '0001',
            randomPart: 'X7K9',
            qrPayload: '${(await repository.getEvent(id)).shortCode}-0001-X7K9',
          ),
        );

    expect(await repository.canEditCustomFields(id), isFalse);
  });

  test('canEditPresenceMode is true with no check-ins and false once one exists', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    expect(await repository.canEditPresenceMode(id), isTrue);

    final beneficiaryId = await db.into(db.beneficiaries).insert(
          BeneficiariesCompanion.insert(eventId: id, name: 'Jane Doe'),
        );
    final ticketId = await db.into(db.tickets).insert(
          TicketsCompanion.insert(
            beneficiaryId: beneficiaryId,
            eventId: id,
            readableId: '0001',
            randomPart: 'X7K9',
            qrPayload: 'EVT-0001-X7K9',
          ),
        );
    await db.into(db.checkIns).insert(
          CheckInsCompanion.insert(ticketId: ticketId, eventId: id),
        );

    expect(await repository.canEditPresenceMode(id), isFalse);
  });

  test('replaceCustomFields replaces the full set for an event', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [NewCustomFieldFixture()],
    );

    await repository.replaceCustomFields(id, const [
      NewCustomField(
        label: 'Category',
        type: CustomFieldType.text,
        sortOrder: 0,
      ),
    ]);

    final fields = await repository.watchCustomFields(id).first;
    expect(fields, hasLength(1));
    expect(fields.single.label, 'Category');
    expect(fields.single.type, CustomFieldType.text);
  });

  test('deleteEventPermanently removes the event and its custom fields', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [NewCustomFieldFixture()],
    );
    await repository.archiveEvent(id);

    await repository.deleteEventPermanently(id);

    expect(await repository.watchArchivedEvents().first, isEmpty);
    expect(await (db.select(db.customFields)).get(), isEmpty);
  });

  test(
      'deleteEventPermanently cascades through beneficiaries, tickets, check-ins, and beneficiary values',
      () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [NewCustomFieldFixture()],
    );
    final customFieldId = (await repository.watchCustomFields(id).first).single.id;
    final beneficiaryId = await db.into(db.beneficiaries).insert(
          BeneficiariesCompanion.insert(eventId: id, name: 'Jane Doe'),
        );
    final ticketId = await db.into(db.tickets).insert(
          TicketsCompanion.insert(
            beneficiaryId: beneficiaryId,
            eventId: id,
            readableId: '0001',
            randomPart: 'X7K9',
            qrPayload: 'EVT-0001-X7K9',
          ),
        );
    await db.into(db.checkIns).insert(
          CheckInsCompanion.insert(ticketId: ticketId, eventId: id),
        );
    await db.into(db.beneficiaryValues).insert(
          BeneficiaryValuesCompanion.insert(
            beneficiaryId: beneficiaryId,
            customFieldId: customFieldId,
            value: '12',
          ),
        );

    await repository.deleteEventPermanently(id);

    expect(await db.select(db.beneficiaries).get(), isEmpty);
    expect(await db.select(db.tickets).get(), isEmpty);
    expect(await db.select(db.checkIns).get(), isEmpty);
    expect(await db.select(db.beneficiaryValues).get(), isEmpty);
  });

  test('updateTicketTemplate persists the chosen template, defaulting to standard', () async {
    final id = await repository.createEvent(
      name: 'Gala DIF 2026',
      date: DateTime(2026, 12, 1),
      presenceMode: PresenceMode.simple,
      customFields: const [],
    );
    expect((await repository.getEvent(id)).ticketTemplate, TicketTemplate.standard);

    await repository.updateTicketTemplate(id, TicketTemplate.elegant);

    expect((await repository.getEvent(id)).ticketTemplate, TicketTemplate.elegant);
  });
}

// Small named fixture so every test that just needs "one custom field"
// does not repeat the same three-argument constructor call.
class NewCustomFieldFixture extends NewCustomField {
  const NewCustomFieldFixture()
      : super(
          label: 'Table number',
          type: CustomFieldType.number,
          sortOrder: 0,
          showOnTicket: true,
        );
}
