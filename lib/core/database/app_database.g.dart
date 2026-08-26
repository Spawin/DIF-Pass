// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EventsTable extends Events with TableInfo<$EventsTable, EventEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _shortCodeMeta = const VerificationMeta(
    'shortCode',
  );
  @override
  late final GeneratedColumn<String> shortCode = GeneratedColumn<String>(
    'short_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoMeta = const VerificationMeta('logo');
  @override
  late final GeneratedColumn<Uint8List> logo = GeneratedColumn<Uint8List>(
    'logo',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _presenceModeMeta = const VerificationMeta(
    'presenceMode',
  );
  @override
  late final GeneratedColumn<String> presenceMode = GeneratedColumn<String>(
    'presence_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shortCode,
    name,
    date,
    location,
    logo,
    presenceMode,
    archivedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('short_code')) {
      context.handle(
        _shortCodeMeta,
        shortCode.isAcceptableOrUnknown(data['short_code']!, _shortCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_shortCodeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('logo')) {
      context.handle(
        _logoMeta,
        logo.isAcceptableOrUnknown(data['logo']!, _logoMeta),
      );
    }
    if (data.containsKey('presence_mode')) {
      context.handle(
        _presenceModeMeta,
        presenceMode.isAcceptableOrUnknown(
          data['presence_mode']!,
          _presenceModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_presenceModeMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      shortCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      logo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}logo'],
      ),
      presenceMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}presence_mode'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class EventEntity extends DataClass implements Insertable<EventEntity> {
  final int id;
  final String shortCode;
  final String name;
  final DateTime date;
  final String? location;
  final Uint8List? logo;
  final String presenceMode;
  final DateTime? archivedAt;
  final DateTime createdAt;
  const EventEntity({
    required this.id,
    required this.shortCode,
    required this.name,
    required this.date,
    this.location,
    this.logo,
    required this.presenceMode,
    this.archivedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['short_code'] = Variable<String>(shortCode);
    map['name'] = Variable<String>(name);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || logo != null) {
      map['logo'] = Variable<Uint8List>(logo);
    }
    map['presence_mode'] = Variable<String>(presenceMode);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      shortCode: Value(shortCode),
      name: Value(name),
      date: Value(date),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      logo: logo == null && nullToAbsent ? const Value.absent() : Value(logo),
      presenceMode: Value(presenceMode),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      createdAt: Value(createdAt),
    );
  }

  factory EventEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventEntity(
      id: serializer.fromJson<int>(json['id']),
      shortCode: serializer.fromJson<String>(json['shortCode']),
      name: serializer.fromJson<String>(json['name']),
      date: serializer.fromJson<DateTime>(json['date']),
      location: serializer.fromJson<String?>(json['location']),
      logo: serializer.fromJson<Uint8List?>(json['logo']),
      presenceMode: serializer.fromJson<String>(json['presenceMode']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shortCode': serializer.toJson<String>(shortCode),
      'name': serializer.toJson<String>(name),
      'date': serializer.toJson<DateTime>(date),
      'location': serializer.toJson<String?>(location),
      'logo': serializer.toJson<Uint8List?>(logo),
      'presenceMode': serializer.toJson<String>(presenceMode),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EventEntity copyWith({
    int? id,
    String? shortCode,
    String? name,
    DateTime? date,
    Value<String?> location = const Value.absent(),
    Value<Uint8List?> logo = const Value.absent(),
    String? presenceMode,
    Value<DateTime?> archivedAt = const Value.absent(),
    DateTime? createdAt,
  }) => EventEntity(
    id: id ?? this.id,
    shortCode: shortCode ?? this.shortCode,
    name: name ?? this.name,
    date: date ?? this.date,
    location: location.present ? location.value : this.location,
    logo: logo.present ? logo.value : this.logo,
    presenceMode: presenceMode ?? this.presenceMode,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  EventEntity copyWithCompanion(EventsCompanion data) {
    return EventEntity(
      id: data.id.present ? data.id.value : this.id,
      shortCode: data.shortCode.present ? data.shortCode.value : this.shortCode,
      name: data.name.present ? data.name.value : this.name,
      date: data.date.present ? data.date.value : this.date,
      location: data.location.present ? data.location.value : this.location,
      logo: data.logo.present ? data.logo.value : this.logo,
      presenceMode: data.presenceMode.present
          ? data.presenceMode.value
          : this.presenceMode,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventEntity(')
          ..write('id: $id, ')
          ..write('shortCode: $shortCode, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('location: $location, ')
          ..write('logo: $logo, ')
          ..write('presenceMode: $presenceMode, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shortCode,
    name,
    date,
    location,
    $driftBlobEquality.hash(logo),
    presenceMode,
    archivedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventEntity &&
          other.id == this.id &&
          other.shortCode == this.shortCode &&
          other.name == this.name &&
          other.date == this.date &&
          other.location == this.location &&
          $driftBlobEquality.equals(other.logo, this.logo) &&
          other.presenceMode == this.presenceMode &&
          other.archivedAt == this.archivedAt &&
          other.createdAt == this.createdAt);
}

class EventsCompanion extends UpdateCompanion<EventEntity> {
  final Value<int> id;
  final Value<String> shortCode;
  final Value<String> name;
  final Value<DateTime> date;
  final Value<String?> location;
  final Value<Uint8List?> logo;
  final Value<String> presenceMode;
  final Value<DateTime?> archivedAt;
  final Value<DateTime> createdAt;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.shortCode = const Value.absent(),
    this.name = const Value.absent(),
    this.date = const Value.absent(),
    this.location = const Value.absent(),
    this.logo = const Value.absent(),
    this.presenceMode = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    required String shortCode,
    required String name,
    required DateTime date,
    this.location = const Value.absent(),
    this.logo = const Value.absent(),
    required String presenceMode,
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : shortCode = Value(shortCode),
       name = Value(name),
       date = Value(date),
       presenceMode = Value(presenceMode);
  static Insertable<EventEntity> custom({
    Expression<int>? id,
    Expression<String>? shortCode,
    Expression<String>? name,
    Expression<DateTime>? date,
    Expression<String>? location,
    Expression<Uint8List>? logo,
    Expression<String>? presenceMode,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shortCode != null) 'short_code': shortCode,
      if (name != null) 'name': name,
      if (date != null) 'date': date,
      if (location != null) 'location': location,
      if (logo != null) 'logo': logo,
      if (presenceMode != null) 'presence_mode': presenceMode,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EventsCompanion copyWith({
    Value<int>? id,
    Value<String>? shortCode,
    Value<String>? name,
    Value<DateTime>? date,
    Value<String?>? location,
    Value<Uint8List?>? logo,
    Value<String>? presenceMode,
    Value<DateTime?>? archivedAt,
    Value<DateTime>? createdAt,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      shortCode: shortCode ?? this.shortCode,
      name: name ?? this.name,
      date: date ?? this.date,
      location: location ?? this.location,
      logo: logo ?? this.logo,
      presenceMode: presenceMode ?? this.presenceMode,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shortCode.present) {
      map['short_code'] = Variable<String>(shortCode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (logo.present) {
      map['logo'] = Variable<Uint8List>(logo.value);
    }
    if (presenceMode.present) {
      map['presence_mode'] = Variable<String>(presenceMode.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('shortCode: $shortCode, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('location: $location, ')
          ..write('logo: $logo, ')
          ..write('presenceMode: $presenceMode, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CustomFieldsTable extends CustomFields
    with TableInfo<$CustomFieldsTable, CustomFieldEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldTypeMeta = const VerificationMeta(
    'fieldType',
  );
  @override
  late final GeneratedColumn<String> fieldType = GeneratedColumn<String>(
    'field_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _showOnTicketMeta = const VerificationMeta(
    'showOnTicket',
  );
  @override
  late final GeneratedColumn<bool> showOnTicket = GeneratedColumn<bool>(
    'show_on_ticket',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_on_ticket" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    label,
    fieldType,
    sortOrder,
    showOnTicket,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomFieldEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('field_type')) {
      context.handle(
        _fieldTypeMeta,
        fieldType.isAcceptableOrUnknown(data['field_type']!, _fieldTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldTypeMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('show_on_ticket')) {
      context.handle(
        _showOnTicketMeta,
        showOnTicket.isAcceptableOrUnknown(
          data['show_on_ticket']!,
          _showOnTicketMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomFieldEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomFieldEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      fieldType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_type'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      showOnTicket: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_on_ticket'],
      )!,
    );
  }

  @override
  $CustomFieldsTable createAlias(String alias) {
    return $CustomFieldsTable(attachedDatabase, alias);
  }
}

class CustomFieldEntity extends DataClass
    implements Insertable<CustomFieldEntity> {
  final int id;
  final int eventId;
  final String label;
  final String fieldType;
  final int sortOrder;
  final bool showOnTicket;
  const CustomFieldEntity({
    required this.id,
    required this.eventId,
    required this.label,
    required this.fieldType,
    required this.sortOrder,
    required this.showOnTicket,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<int>(eventId);
    map['label'] = Variable<String>(label);
    map['field_type'] = Variable<String>(fieldType);
    map['sort_order'] = Variable<int>(sortOrder);
    map['show_on_ticket'] = Variable<bool>(showOnTicket);
    return map;
  }

  CustomFieldsCompanion toCompanion(bool nullToAbsent) {
    return CustomFieldsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      label: Value(label),
      fieldType: Value(fieldType),
      sortOrder: Value(sortOrder),
      showOnTicket: Value(showOnTicket),
    );
  }

  factory CustomFieldEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomFieldEntity(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<int>(json['eventId']),
      label: serializer.fromJson<String>(json['label']),
      fieldType: serializer.fromJson<String>(json['fieldType']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      showOnTicket: serializer.fromJson<bool>(json['showOnTicket']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<int>(eventId),
      'label': serializer.toJson<String>(label),
      'fieldType': serializer.toJson<String>(fieldType),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'showOnTicket': serializer.toJson<bool>(showOnTicket),
    };
  }

  CustomFieldEntity copyWith({
    int? id,
    int? eventId,
    String? label,
    String? fieldType,
    int? sortOrder,
    bool? showOnTicket,
  }) => CustomFieldEntity(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    label: label ?? this.label,
    fieldType: fieldType ?? this.fieldType,
    sortOrder: sortOrder ?? this.sortOrder,
    showOnTicket: showOnTicket ?? this.showOnTicket,
  );
  CustomFieldEntity copyWithCompanion(CustomFieldsCompanion data) {
    return CustomFieldEntity(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      label: data.label.present ? data.label.value : this.label,
      fieldType: data.fieldType.present ? data.fieldType.value : this.fieldType,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      showOnTicket: data.showOnTicket.present
          ? data.showOnTicket.value
          : this.showOnTicket,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomFieldEntity(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('label: $label, ')
          ..write('fieldType: $fieldType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('showOnTicket: $showOnTicket')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, eventId, label, fieldType, sortOrder, showOnTicket);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomFieldEntity &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.label == this.label &&
          other.fieldType == this.fieldType &&
          other.sortOrder == this.sortOrder &&
          other.showOnTicket == this.showOnTicket);
}

class CustomFieldsCompanion extends UpdateCompanion<CustomFieldEntity> {
  final Value<int> id;
  final Value<int> eventId;
  final Value<String> label;
  final Value<String> fieldType;
  final Value<int> sortOrder;
  final Value<bool> showOnTicket;
  const CustomFieldsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.label = const Value.absent(),
    this.fieldType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.showOnTicket = const Value.absent(),
  });
  CustomFieldsCompanion.insert({
    this.id = const Value.absent(),
    required int eventId,
    required String label,
    required String fieldType,
    required int sortOrder,
    this.showOnTicket = const Value.absent(),
  }) : eventId = Value(eventId),
       label = Value(label),
       fieldType = Value(fieldType),
       sortOrder = Value(sortOrder);
  static Insertable<CustomFieldEntity> custom({
    Expression<int>? id,
    Expression<int>? eventId,
    Expression<String>? label,
    Expression<String>? fieldType,
    Expression<int>? sortOrder,
    Expression<bool>? showOnTicket,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (label != null) 'label': label,
      if (fieldType != null) 'field_type': fieldType,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (showOnTicket != null) 'show_on_ticket': showOnTicket,
    });
  }

  CustomFieldsCompanion copyWith({
    Value<int>? id,
    Value<int>? eventId,
    Value<String>? label,
    Value<String>? fieldType,
    Value<int>? sortOrder,
    Value<bool>? showOnTicket,
  }) {
    return CustomFieldsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      label: label ?? this.label,
      fieldType: fieldType ?? this.fieldType,
      sortOrder: sortOrder ?? this.sortOrder,
      showOnTicket: showOnTicket ?? this.showOnTicket,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (fieldType.present) {
      map['field_type'] = Variable<String>(fieldType.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (showOnTicket.present) {
      map['show_on_ticket'] = Variable<bool>(showOnTicket.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomFieldsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('label: $label, ')
          ..write('fieldType: $fieldType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('showOnTicket: $showOnTicket')
          ..write(')'))
        .toString();
  }
}

class $BeneficiariesTable extends Beneficiaries
    with TableInfo<$BeneficiariesTable, BeneficiaryEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BeneficiariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, eventId, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'beneficiaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BeneficiaryEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BeneficiaryEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BeneficiaryEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BeneficiariesTable createAlias(String alias) {
    return $BeneficiariesTable(attachedDatabase, alias);
  }
}

class BeneficiaryEntity extends DataClass
    implements Insertable<BeneficiaryEntity> {
  final int id;
  final int eventId;
  final String name;
  final DateTime createdAt;
  const BeneficiaryEntity({
    required this.id,
    required this.eventId,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<int>(eventId);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BeneficiariesCompanion toCompanion(bool nullToAbsent) {
    return BeneficiariesCompanion(
      id: Value(id),
      eventId: Value(eventId),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory BeneficiaryEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BeneficiaryEntity(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<int>(json['eventId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<int>(eventId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BeneficiaryEntity copyWith({
    int? id,
    int? eventId,
    String? name,
    DateTime? createdAt,
  }) => BeneficiaryEntity(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  BeneficiaryEntity copyWithCompanion(BeneficiariesCompanion data) {
    return BeneficiaryEntity(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BeneficiaryEntity(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventId, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BeneficiaryEntity &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class BeneficiariesCompanion extends UpdateCompanion<BeneficiaryEntity> {
  final Value<int> id;
  final Value<int> eventId;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const BeneficiariesCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BeneficiariesCompanion.insert({
    this.id = const Value.absent(),
    required int eventId,
    required String name,
    this.createdAt = const Value.absent(),
  }) : eventId = Value(eventId),
       name = Value(name);
  static Insertable<BeneficiaryEntity> custom({
    Expression<int>? id,
    Expression<int>? eventId,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BeneficiariesCompanion copyWith({
    Value<int>? id,
    Value<int>? eventId,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return BeneficiariesCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BeneficiariesCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BeneficiaryValuesTable extends BeneficiaryValues
    with TableInfo<$BeneficiaryValuesTable, BeneficiaryValueEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BeneficiaryValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _beneficiaryIdMeta = const VerificationMeta(
    'beneficiaryId',
  );
  @override
  late final GeneratedColumn<int> beneficiaryId = GeneratedColumn<int>(
    'beneficiary_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES beneficiaries (id)',
    ),
  );
  static const VerificationMeta _customFieldIdMeta = const VerificationMeta(
    'customFieldId',
  );
  @override
  late final GeneratedColumn<int> customFieldId = GeneratedColumn<int>(
    'custom_field_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES custom_fields (id)',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    beneficiaryId,
    customFieldId,
    value,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'beneficiary_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<BeneficiaryValueEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('beneficiary_id')) {
      context.handle(
        _beneficiaryIdMeta,
        beneficiaryId.isAcceptableOrUnknown(
          data['beneficiary_id']!,
          _beneficiaryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_beneficiaryIdMeta);
    }
    if (data.containsKey('custom_field_id')) {
      context.handle(
        _customFieldIdMeta,
        customFieldId.isAcceptableOrUnknown(
          data['custom_field_id']!,
          _customFieldIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customFieldIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BeneficiaryValueEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BeneficiaryValueEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      beneficiaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}beneficiary_id'],
      )!,
      customFieldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}custom_field_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $BeneficiaryValuesTable createAlias(String alias) {
    return $BeneficiaryValuesTable(attachedDatabase, alias);
  }
}

class BeneficiaryValueEntity extends DataClass
    implements Insertable<BeneficiaryValueEntity> {
  final int id;
  final int beneficiaryId;
  final int customFieldId;
  final String value;
  const BeneficiaryValueEntity({
    required this.id,
    required this.beneficiaryId,
    required this.customFieldId,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['beneficiary_id'] = Variable<int>(beneficiaryId);
    map['custom_field_id'] = Variable<int>(customFieldId);
    map['value'] = Variable<String>(value);
    return map;
  }

  BeneficiaryValuesCompanion toCompanion(bool nullToAbsent) {
    return BeneficiaryValuesCompanion(
      id: Value(id),
      beneficiaryId: Value(beneficiaryId),
      customFieldId: Value(customFieldId),
      value: Value(value),
    );
  }

  factory BeneficiaryValueEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BeneficiaryValueEntity(
      id: serializer.fromJson<int>(json['id']),
      beneficiaryId: serializer.fromJson<int>(json['beneficiaryId']),
      customFieldId: serializer.fromJson<int>(json['customFieldId']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'beneficiaryId': serializer.toJson<int>(beneficiaryId),
      'customFieldId': serializer.toJson<int>(customFieldId),
      'value': serializer.toJson<String>(value),
    };
  }

  BeneficiaryValueEntity copyWith({
    int? id,
    int? beneficiaryId,
    int? customFieldId,
    String? value,
  }) => BeneficiaryValueEntity(
    id: id ?? this.id,
    beneficiaryId: beneficiaryId ?? this.beneficiaryId,
    customFieldId: customFieldId ?? this.customFieldId,
    value: value ?? this.value,
  );
  BeneficiaryValueEntity copyWithCompanion(BeneficiaryValuesCompanion data) {
    return BeneficiaryValueEntity(
      id: data.id.present ? data.id.value : this.id,
      beneficiaryId: data.beneficiaryId.present
          ? data.beneficiaryId.value
          : this.beneficiaryId,
      customFieldId: data.customFieldId.present
          ? data.customFieldId.value
          : this.customFieldId,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BeneficiaryValueEntity(')
          ..write('id: $id, ')
          ..write('beneficiaryId: $beneficiaryId, ')
          ..write('customFieldId: $customFieldId, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, beneficiaryId, customFieldId, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BeneficiaryValueEntity &&
          other.id == this.id &&
          other.beneficiaryId == this.beneficiaryId &&
          other.customFieldId == this.customFieldId &&
          other.value == this.value);
}

class BeneficiaryValuesCompanion
    extends UpdateCompanion<BeneficiaryValueEntity> {
  final Value<int> id;
  final Value<int> beneficiaryId;
  final Value<int> customFieldId;
  final Value<String> value;
  const BeneficiaryValuesCompanion({
    this.id = const Value.absent(),
    this.beneficiaryId = const Value.absent(),
    this.customFieldId = const Value.absent(),
    this.value = const Value.absent(),
  });
  BeneficiaryValuesCompanion.insert({
    this.id = const Value.absent(),
    required int beneficiaryId,
    required int customFieldId,
    required String value,
  }) : beneficiaryId = Value(beneficiaryId),
       customFieldId = Value(customFieldId),
       value = Value(value);
  static Insertable<BeneficiaryValueEntity> custom({
    Expression<int>? id,
    Expression<int>? beneficiaryId,
    Expression<int>? customFieldId,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (beneficiaryId != null) 'beneficiary_id': beneficiaryId,
      if (customFieldId != null) 'custom_field_id': customFieldId,
      if (value != null) 'value': value,
    });
  }

  BeneficiaryValuesCompanion copyWith({
    Value<int>? id,
    Value<int>? beneficiaryId,
    Value<int>? customFieldId,
    Value<String>? value,
  }) {
    return BeneficiaryValuesCompanion(
      id: id ?? this.id,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      customFieldId: customFieldId ?? this.customFieldId,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (beneficiaryId.present) {
      map['beneficiary_id'] = Variable<int>(beneficiaryId.value);
    }
    if (customFieldId.present) {
      map['custom_field_id'] = Variable<int>(customFieldId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BeneficiaryValuesCompanion(')
          ..write('id: $id, ')
          ..write('beneficiaryId: $beneficiaryId, ')
          ..write('customFieldId: $customFieldId, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $TicketsTable extends Tickets
    with TableInfo<$TicketsTable, TicketEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TicketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _beneficiaryIdMeta = const VerificationMeta(
    'beneficiaryId',
  );
  @override
  late final GeneratedColumn<int> beneficiaryId = GeneratedColumn<int>(
    'beneficiary_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES beneficiaries (id)',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  static const VerificationMeta _readableIdMeta = const VerificationMeta(
    'readableId',
  );
  @override
  late final GeneratedColumn<String> readableId = GeneratedColumn<String>(
    'readable_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _randomPartMeta = const VerificationMeta(
    'randomPart',
  );
  @override
  late final GeneratedColumn<String> randomPart = GeneratedColumn<String>(
    'random_part',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qrPayloadMeta = const VerificationMeta(
    'qrPayload',
  );
  @override
  late final GeneratedColumn<String> qrPayload = GeneratedColumn<String>(
    'qr_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    beneficiaryId,
    eventId,
    readableId,
    randomPart,
    qrPayload,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tickets';
  @override
  VerificationContext validateIntegrity(
    Insertable<TicketEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('beneficiary_id')) {
      context.handle(
        _beneficiaryIdMeta,
        beneficiaryId.isAcceptableOrUnknown(
          data['beneficiary_id']!,
          _beneficiaryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_beneficiaryIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('readable_id')) {
      context.handle(
        _readableIdMeta,
        readableId.isAcceptableOrUnknown(data['readable_id']!, _readableIdMeta),
      );
    } else if (isInserting) {
      context.missing(_readableIdMeta);
    }
    if (data.containsKey('random_part')) {
      context.handle(
        _randomPartMeta,
        randomPart.isAcceptableOrUnknown(data['random_part']!, _randomPartMeta),
      );
    } else if (isInserting) {
      context.missing(_randomPartMeta);
    }
    if (data.containsKey('qr_payload')) {
      context.handle(
        _qrPayloadMeta,
        qrPayload.isAcceptableOrUnknown(data['qr_payload']!, _qrPayloadMeta),
      );
    } else if (isInserting) {
      context.missing(_qrPayloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {eventId, readableId},
  ];
  @override
  TicketEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TicketEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      beneficiaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}beneficiary_id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      )!,
      readableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}readable_id'],
      )!,
      randomPart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}random_part'],
      )!,
      qrPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qr_payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TicketsTable createAlias(String alias) {
    return $TicketsTable(attachedDatabase, alias);
  }
}

class TicketEntity extends DataClass implements Insertable<TicketEntity> {
  final int id;
  final int beneficiaryId;
  final int eventId;
  final String readableId;
  final String randomPart;
  final String qrPayload;
  final DateTime createdAt;
  const TicketEntity({
    required this.id,
    required this.beneficiaryId,
    required this.eventId,
    required this.readableId,
    required this.randomPart,
    required this.qrPayload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['beneficiary_id'] = Variable<int>(beneficiaryId);
    map['event_id'] = Variable<int>(eventId);
    map['readable_id'] = Variable<String>(readableId);
    map['random_part'] = Variable<String>(randomPart);
    map['qr_payload'] = Variable<String>(qrPayload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TicketsCompanion toCompanion(bool nullToAbsent) {
    return TicketsCompanion(
      id: Value(id),
      beneficiaryId: Value(beneficiaryId),
      eventId: Value(eventId),
      readableId: Value(readableId),
      randomPart: Value(randomPart),
      qrPayload: Value(qrPayload),
      createdAt: Value(createdAt),
    );
  }

  factory TicketEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TicketEntity(
      id: serializer.fromJson<int>(json['id']),
      beneficiaryId: serializer.fromJson<int>(json['beneficiaryId']),
      eventId: serializer.fromJson<int>(json['eventId']),
      readableId: serializer.fromJson<String>(json['readableId']),
      randomPart: serializer.fromJson<String>(json['randomPart']),
      qrPayload: serializer.fromJson<String>(json['qrPayload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'beneficiaryId': serializer.toJson<int>(beneficiaryId),
      'eventId': serializer.toJson<int>(eventId),
      'readableId': serializer.toJson<String>(readableId),
      'randomPart': serializer.toJson<String>(randomPart),
      'qrPayload': serializer.toJson<String>(qrPayload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TicketEntity copyWith({
    int? id,
    int? beneficiaryId,
    int? eventId,
    String? readableId,
    String? randomPart,
    String? qrPayload,
    DateTime? createdAt,
  }) => TicketEntity(
    id: id ?? this.id,
    beneficiaryId: beneficiaryId ?? this.beneficiaryId,
    eventId: eventId ?? this.eventId,
    readableId: readableId ?? this.readableId,
    randomPart: randomPart ?? this.randomPart,
    qrPayload: qrPayload ?? this.qrPayload,
    createdAt: createdAt ?? this.createdAt,
  );
  TicketEntity copyWithCompanion(TicketsCompanion data) {
    return TicketEntity(
      id: data.id.present ? data.id.value : this.id,
      beneficiaryId: data.beneficiaryId.present
          ? data.beneficiaryId.value
          : this.beneficiaryId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      readableId: data.readableId.present
          ? data.readableId.value
          : this.readableId,
      randomPart: data.randomPart.present
          ? data.randomPart.value
          : this.randomPart,
      qrPayload: data.qrPayload.present ? data.qrPayload.value : this.qrPayload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TicketEntity(')
          ..write('id: $id, ')
          ..write('beneficiaryId: $beneficiaryId, ')
          ..write('eventId: $eventId, ')
          ..write('readableId: $readableId, ')
          ..write('randomPart: $randomPart, ')
          ..write('qrPayload: $qrPayload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    beneficiaryId,
    eventId,
    readableId,
    randomPart,
    qrPayload,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TicketEntity &&
          other.id == this.id &&
          other.beneficiaryId == this.beneficiaryId &&
          other.eventId == this.eventId &&
          other.readableId == this.readableId &&
          other.randomPart == this.randomPart &&
          other.qrPayload == this.qrPayload &&
          other.createdAt == this.createdAt);
}

class TicketsCompanion extends UpdateCompanion<TicketEntity> {
  final Value<int> id;
  final Value<int> beneficiaryId;
  final Value<int> eventId;
  final Value<String> readableId;
  final Value<String> randomPart;
  final Value<String> qrPayload;
  final Value<DateTime> createdAt;
  const TicketsCompanion({
    this.id = const Value.absent(),
    this.beneficiaryId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.readableId = const Value.absent(),
    this.randomPart = const Value.absent(),
    this.qrPayload = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TicketsCompanion.insert({
    this.id = const Value.absent(),
    required int beneficiaryId,
    required int eventId,
    required String readableId,
    required String randomPart,
    required String qrPayload,
    this.createdAt = const Value.absent(),
  }) : beneficiaryId = Value(beneficiaryId),
       eventId = Value(eventId),
       readableId = Value(readableId),
       randomPart = Value(randomPart),
       qrPayload = Value(qrPayload);
  static Insertable<TicketEntity> custom({
    Expression<int>? id,
    Expression<int>? beneficiaryId,
    Expression<int>? eventId,
    Expression<String>? readableId,
    Expression<String>? randomPart,
    Expression<String>? qrPayload,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (beneficiaryId != null) 'beneficiary_id': beneficiaryId,
      if (eventId != null) 'event_id': eventId,
      if (readableId != null) 'readable_id': readableId,
      if (randomPart != null) 'random_part': randomPart,
      if (qrPayload != null) 'qr_payload': qrPayload,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TicketsCompanion copyWith({
    Value<int>? id,
    Value<int>? beneficiaryId,
    Value<int>? eventId,
    Value<String>? readableId,
    Value<String>? randomPart,
    Value<String>? qrPayload,
    Value<DateTime>? createdAt,
  }) {
    return TicketsCompanion(
      id: id ?? this.id,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      eventId: eventId ?? this.eventId,
      readableId: readableId ?? this.readableId,
      randomPart: randomPart ?? this.randomPart,
      qrPayload: qrPayload ?? this.qrPayload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (beneficiaryId.present) {
      map['beneficiary_id'] = Variable<int>(beneficiaryId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (readableId.present) {
      map['readable_id'] = Variable<String>(readableId.value);
    }
    if (randomPart.present) {
      map['random_part'] = Variable<String>(randomPart.value);
    }
    if (qrPayload.present) {
      map['qr_payload'] = Variable<String>(qrPayload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TicketsCompanion(')
          ..write('id: $id, ')
          ..write('beneficiaryId: $beneficiaryId, ')
          ..write('eventId: $eventId, ')
          ..write('readableId: $readableId, ')
          ..write('randomPart: $randomPart, ')
          ..write('qrPayload: $qrPayload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CheckInsTable extends CheckIns
    with TableInfo<$CheckInsTable, CheckInEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ticketIdMeta = const VerificationMeta(
    'ticketId',
  );
  @override
  late final GeneratedColumn<int> ticketId = GeneratedColumn<int>(
    'ticket_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tickets (id)',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  static const VerificationMeta _scannedAtMeta = const VerificationMeta(
    'scannedAt',
  );
  @override
  late final GeneratedColumn<DateTime> scannedAt = GeneratedColumn<DateTime>(
    'scanned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, ticketId, eventId, scannedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckInEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ticket_id')) {
      context.handle(
        _ticketIdMeta,
        ticketId.isAcceptableOrUnknown(data['ticket_id']!, _ticketIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ticketIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('scanned_at')) {
      context.handle(
        _scannedAtMeta,
        scannedAt.isAcceptableOrUnknown(data['scanned_at']!, _scannedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheckInEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckInEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ticketId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ticket_id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      )!,
      scannedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scanned_at'],
      )!,
    );
  }

  @override
  $CheckInsTable createAlias(String alias) {
    return $CheckInsTable(attachedDatabase, alias);
  }
}

class CheckInEntity extends DataClass implements Insertable<CheckInEntity> {
  final int id;
  final int ticketId;
  final int eventId;
  final DateTime scannedAt;
  const CheckInEntity({
    required this.id,
    required this.ticketId,
    required this.eventId,
    required this.scannedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ticket_id'] = Variable<int>(ticketId);
    map['event_id'] = Variable<int>(eventId);
    map['scanned_at'] = Variable<DateTime>(scannedAt);
    return map;
  }

  CheckInsCompanion toCompanion(bool nullToAbsent) {
    return CheckInsCompanion(
      id: Value(id),
      ticketId: Value(ticketId),
      eventId: Value(eventId),
      scannedAt: Value(scannedAt),
    );
  }

  factory CheckInEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckInEntity(
      id: serializer.fromJson<int>(json['id']),
      ticketId: serializer.fromJson<int>(json['ticketId']),
      eventId: serializer.fromJson<int>(json['eventId']),
      scannedAt: serializer.fromJson<DateTime>(json['scannedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ticketId': serializer.toJson<int>(ticketId),
      'eventId': serializer.toJson<int>(eventId),
      'scannedAt': serializer.toJson<DateTime>(scannedAt),
    };
  }

  CheckInEntity copyWith({
    int? id,
    int? ticketId,
    int? eventId,
    DateTime? scannedAt,
  }) => CheckInEntity(
    id: id ?? this.id,
    ticketId: ticketId ?? this.ticketId,
    eventId: eventId ?? this.eventId,
    scannedAt: scannedAt ?? this.scannedAt,
  );
  CheckInEntity copyWithCompanion(CheckInsCompanion data) {
    return CheckInEntity(
      id: data.id.present ? data.id.value : this.id,
      ticketId: data.ticketId.present ? data.ticketId.value : this.ticketId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      scannedAt: data.scannedAt.present ? data.scannedAt.value : this.scannedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckInEntity(')
          ..write('id: $id, ')
          ..write('ticketId: $ticketId, ')
          ..write('eventId: $eventId, ')
          ..write('scannedAt: $scannedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ticketId, eventId, scannedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckInEntity &&
          other.id == this.id &&
          other.ticketId == this.ticketId &&
          other.eventId == this.eventId &&
          other.scannedAt == this.scannedAt);
}

class CheckInsCompanion extends UpdateCompanion<CheckInEntity> {
  final Value<int> id;
  final Value<int> ticketId;
  final Value<int> eventId;
  final Value<DateTime> scannedAt;
  const CheckInsCompanion({
    this.id = const Value.absent(),
    this.ticketId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.scannedAt = const Value.absent(),
  });
  CheckInsCompanion.insert({
    this.id = const Value.absent(),
    required int ticketId,
    required int eventId,
    this.scannedAt = const Value.absent(),
  }) : ticketId = Value(ticketId),
       eventId = Value(eventId);
  static Insertable<CheckInEntity> custom({
    Expression<int>? id,
    Expression<int>? ticketId,
    Expression<int>? eventId,
    Expression<DateTime>? scannedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ticketId != null) 'ticket_id': ticketId,
      if (eventId != null) 'event_id': eventId,
      if (scannedAt != null) 'scanned_at': scannedAt,
    });
  }

  CheckInsCompanion copyWith({
    Value<int>? id,
    Value<int>? ticketId,
    Value<int>? eventId,
    Value<DateTime>? scannedAt,
  }) {
    return CheckInsCompanion(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      eventId: eventId ?? this.eventId,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ticketId.present) {
      map['ticket_id'] = Variable<int>(ticketId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (scannedAt.present) {
      map['scanned_at'] = Variable<DateTime>(scannedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckInsCompanion(')
          ..write('id: $id, ')
          ..write('ticketId: $ticketId, ')
          ..write('eventId: $eventId, ')
          ..write('scannedAt: $scannedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventsTable events = $EventsTable(this);
  late final $CustomFieldsTable customFields = $CustomFieldsTable(this);
  late final $BeneficiariesTable beneficiaries = $BeneficiariesTable(this);
  late final $BeneficiaryValuesTable beneficiaryValues =
      $BeneficiaryValuesTable(this);
  late final $TicketsTable tickets = $TicketsTable(this);
  late final $CheckInsTable checkIns = $CheckInsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    events,
    customFields,
    beneficiaries,
    beneficiaryValues,
    tickets,
    checkIns,
  ];
}

typedef $$EventsTableCreateCompanionBuilder =
    EventsCompanion Function({
      Value<int> id,
      required String shortCode,
      required String name,
      required DateTime date,
      Value<String?> location,
      Value<Uint8List?> logo,
      required String presenceMode,
      Value<DateTime?> archivedAt,
      Value<DateTime> createdAt,
    });
typedef $$EventsTableUpdateCompanionBuilder =
    EventsCompanion Function({
      Value<int> id,
      Value<String> shortCode,
      Value<String> name,
      Value<DateTime> date,
      Value<String?> location,
      Value<Uint8List?> logo,
      Value<String> presenceMode,
      Value<DateTime?> archivedAt,
      Value<DateTime> createdAt,
    });

final class $$EventsTableReferences
    extends BaseReferences<_$AppDatabase, $EventsTable, EventEntity> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CustomFieldsTable, List<CustomFieldEntity>>
  _customFieldsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.customFields,
    aliasName: 'events__id__custom_fields__event_id',
  );

  $$CustomFieldsTableProcessedTableManager get customFieldsRefs {
    final manager = $$CustomFieldsTableTableManager(
      $_db,
      $_db.customFields,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_customFieldsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BeneficiariesTable, List<BeneficiaryEntity>>
  _beneficiariesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.beneficiaries,
    aliasName: 'events__id__beneficiaries__event_id',
  );

  $$BeneficiariesTableProcessedTableManager get beneficiariesRefs {
    final manager = $$BeneficiariesTableTableManager(
      $_db,
      $_db.beneficiaries,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_beneficiariesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TicketsTable, List<TicketEntity>>
  _ticketsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.tickets,
    aliasName: 'events__id__tickets__event_id',
  );

  $$TicketsTableProcessedTableManager get ticketsRefs {
    final manager = $$TicketsTableTableManager(
      $_db,
      $_db.tickets,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ticketsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CheckInsTable, List<CheckInEntity>>
  _checkInsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.checkIns,
    aliasName: 'events__id__check_ins__event_id',
  );

  $$CheckInsTableProcessedTableManager get checkInsRefs {
    final manager = $$CheckInsTableTableManager(
      $_db,
      $_db.checkIns,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_checkInsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortCode => $composableBuilder(
    column: $table.shortCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presenceMode => $composableBuilder(
    column: $table.presenceMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> customFieldsRefs(
    Expression<bool> Function($$CustomFieldsTableFilterComposer f) f,
  ) {
    final $$CustomFieldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customFields,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomFieldsTableFilterComposer(
            $db: $db,
            $table: $db.customFields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> beneficiariesRefs(
    Expression<bool> Function($$BeneficiariesTableFilterComposer f) f,
  ) {
    final $$BeneficiariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.beneficiaries,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeneficiariesTableFilterComposer(
            $db: $db,
            $table: $db.beneficiaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ticketsRefs(
    Expression<bool> Function($$TicketsTableFilterComposer f) f,
  ) {
    final $$TicketsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tickets,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TicketsTableFilterComposer(
            $db: $db,
            $table: $db.tickets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> checkInsRefs(
    Expression<bool> Function($$CheckInsTableFilterComposer f) f,
  ) {
    final $$CheckInsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkIns,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckInsTableFilterComposer(
            $db: $db,
            $table: $db.checkIns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortCode => $composableBuilder(
    column: $table.shortCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presenceMode => $composableBuilder(
    column: $table.presenceMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shortCode =>
      $composableBuilder(column: $table.shortCode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<Uint8List> get logo =>
      $composableBuilder(column: $table.logo, builder: (column) => column);

  GeneratedColumn<String> get presenceMode => $composableBuilder(
    column: $table.presenceMode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> customFieldsRefs<T extends Object>(
    Expression<T> Function($$CustomFieldsTableAnnotationComposer a) f,
  ) {
    final $$CustomFieldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customFields,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomFieldsTableAnnotationComposer(
            $db: $db,
            $table: $db.customFields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> beneficiariesRefs<T extends Object>(
    Expression<T> Function($$BeneficiariesTableAnnotationComposer a) f,
  ) {
    final $$BeneficiariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.beneficiaries,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeneficiariesTableAnnotationComposer(
            $db: $db,
            $table: $db.beneficiaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ticketsRefs<T extends Object>(
    Expression<T> Function($$TicketsTableAnnotationComposer a) f,
  ) {
    final $$TicketsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tickets,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TicketsTableAnnotationComposer(
            $db: $db,
            $table: $db.tickets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> checkInsRefs<T extends Object>(
    Expression<T> Function($$CheckInsTableAnnotationComposer a) f,
  ) {
    final $$CheckInsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkIns,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckInsTableAnnotationComposer(
            $db: $db,
            $table: $db.checkIns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          EventEntity,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (EventEntity, $$EventsTableReferences),
          EventEntity,
          PrefetchHooks Function({
            bool customFieldsRefs,
            bool beneficiariesRefs,
            bool ticketsRefs,
            bool checkInsRefs,
          })
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> shortCode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<Uint8List?> logo = const Value.absent(),
                Value<String> presenceMode = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                shortCode: shortCode,
                name: name,
                date: date,
                location: location,
                logo: logo,
                presenceMode: presenceMode,
                archivedAt: archivedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String shortCode,
                required String name,
                required DateTime date,
                Value<String?> location = const Value.absent(),
                Value<Uint8List?> logo = const Value.absent(),
                required String presenceMode,
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                shortCode: shortCode,
                name: name,
                date: date,
                location: location,
                logo: logo,
                presenceMode: presenceMode,
                archivedAt: archivedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$EventsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                customFieldsRefs = false,
                beneficiariesRefs = false,
                ticketsRefs = false,
                checkInsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (customFieldsRefs) db.customFields,
                    if (beneficiariesRefs) db.beneficiaries,
                    if (ticketsRefs) db.tickets,
                    if (checkInsRefs) db.checkIns,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (customFieldsRefs)
                        await $_getPrefetchedData<
                          EventEntity,
                          $EventsTable,
                          CustomFieldEntity
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._customFieldsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).customFieldsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (beneficiariesRefs)
                        await $_getPrefetchedData<
                          EventEntity,
                          $EventsTable,
                          BeneficiaryEntity
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._beneficiariesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).beneficiariesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ticketsRefs)
                        await $_getPrefetchedData<
                          EventEntity,
                          $EventsTable,
                          TicketEntity
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._ticketsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).ticketsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (checkInsRefs)
                        await $_getPrefetchedData<
                          EventEntity,
                          $EventsTable,
                          CheckInEntity
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._checkInsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).checkInsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      EventEntity,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (EventEntity, $$EventsTableReferences),
      EventEntity,
      PrefetchHooks Function({
        bool customFieldsRefs,
        bool beneficiariesRefs,
        bool ticketsRefs,
        bool checkInsRefs,
      })
    >;
typedef $$CustomFieldsTableCreateCompanionBuilder =
    CustomFieldsCompanion Function({
      Value<int> id,
      required int eventId,
      required String label,
      required String fieldType,
      required int sortOrder,
      Value<bool> showOnTicket,
    });
typedef $$CustomFieldsTableUpdateCompanionBuilder =
    CustomFieldsCompanion Function({
      Value<int> id,
      Value<int> eventId,
      Value<String> label,
      Value<String> fieldType,
      Value<int> sortOrder,
      Value<bool> showOnTicket,
    });

final class $$CustomFieldsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CustomFieldsTable, CustomFieldEntity> {
  $$CustomFieldsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('custom_fields__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<int>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $BeneficiaryValuesTable,
    List<BeneficiaryValueEntity>
  >
  _beneficiaryValuesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.beneficiaryValues,
        aliasName: 'custom_fields__id__beneficiary_values__custom_field_id',
      );

  $$BeneficiaryValuesTableProcessedTableManager get beneficiaryValuesRefs {
    final manager = $$BeneficiaryValuesTableTableManager(
      $_db,
      $_db.beneficiaryValues,
    ).filter((f) => f.customFieldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _beneficiaryValuesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomFieldsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomFieldsTable> {
  $$CustomFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showOnTicket => $composableBuilder(
    column: $table.showOnTicket,
    builder: (column) => ColumnFilters(column),
  );

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> beneficiaryValuesRefs(
    Expression<bool> Function($$BeneficiaryValuesTableFilterComposer f) f,
  ) {
    final $$BeneficiaryValuesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.beneficiaryValues,
      getReferencedColumn: (t) => t.customFieldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeneficiaryValuesTableFilterComposer(
            $db: $db,
            $table: $db.beneficiaryValues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomFieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomFieldsTable> {
  $$CustomFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showOnTicket => $composableBuilder(
    column: $table.showOnTicket,
    builder: (column) => ColumnOrderings(column),
  );

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomFieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomFieldsTable> {
  $$CustomFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get fieldType =>
      $composableBuilder(column: $table.fieldType, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get showOnTicket => $composableBuilder(
    column: $table.showOnTicket,
    builder: (column) => column,
  );

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> beneficiaryValuesRefs<T extends Object>(
    Expression<T> Function($$BeneficiaryValuesTableAnnotationComposer a) f,
  ) {
    final $$BeneficiaryValuesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.beneficiaryValues,
          getReferencedColumn: (t) => t.customFieldId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BeneficiaryValuesTableAnnotationComposer(
                $db: $db,
                $table: $db.beneficiaryValues,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CustomFieldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomFieldsTable,
          CustomFieldEntity,
          $$CustomFieldsTableFilterComposer,
          $$CustomFieldsTableOrderingComposer,
          $$CustomFieldsTableAnnotationComposer,
          $$CustomFieldsTableCreateCompanionBuilder,
          $$CustomFieldsTableUpdateCompanionBuilder,
          (CustomFieldEntity, $$CustomFieldsTableReferences),
          CustomFieldEntity,
          PrefetchHooks Function({bool eventId, bool beneficiaryValuesRefs})
        > {
  $$CustomFieldsTableTableManager(_$AppDatabase db, $CustomFieldsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomFieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> eventId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> fieldType = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> showOnTicket = const Value.absent(),
              }) => CustomFieldsCompanion(
                id: id,
                eventId: eventId,
                label: label,
                fieldType: fieldType,
                sortOrder: sortOrder,
                showOnTicket: showOnTicket,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int eventId,
                required String label,
                required String fieldType,
                required int sortOrder,
                Value<bool> showOnTicket = const Value.absent(),
              }) => CustomFieldsCompanion.insert(
                id: id,
                eventId: eventId,
                label: label,
                fieldType: fieldType,
                sortOrder: sortOrder,
                showOnTicket: showOnTicket,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomFieldsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({eventId = false, beneficiaryValuesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (beneficiaryValuesRefs) db.beneficiaryValues,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (eventId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.eventId,
                                    referencedTable:
                                        $$CustomFieldsTableReferences
                                            ._eventIdTable(db),
                                    referencedColumn:
                                        $$CustomFieldsTableReferences
                                            ._eventIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (beneficiaryValuesRefs)
                        await $_getPrefetchedData<
                          CustomFieldEntity,
                          $CustomFieldsTable,
                          BeneficiaryValueEntity
                        >(
                          currentTable: table,
                          referencedTable: $$CustomFieldsTableReferences
                              ._beneficiaryValuesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomFieldsTableReferences(
                                db,
                                table,
                                p0,
                              ).beneficiaryValuesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customFieldId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CustomFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomFieldsTable,
      CustomFieldEntity,
      $$CustomFieldsTableFilterComposer,
      $$CustomFieldsTableOrderingComposer,
      $$CustomFieldsTableAnnotationComposer,
      $$CustomFieldsTableCreateCompanionBuilder,
      $$CustomFieldsTableUpdateCompanionBuilder,
      (CustomFieldEntity, $$CustomFieldsTableReferences),
      CustomFieldEntity,
      PrefetchHooks Function({bool eventId, bool beneficiaryValuesRefs})
    >;
typedef $$BeneficiariesTableCreateCompanionBuilder =
    BeneficiariesCompanion Function({
      Value<int> id,
      required int eventId,
      required String name,
      Value<DateTime> createdAt,
    });
typedef $$BeneficiariesTableUpdateCompanionBuilder =
    BeneficiariesCompanion Function({
      Value<int> id,
      Value<int> eventId,
      Value<String> name,
      Value<DateTime> createdAt,
    });

final class $$BeneficiariesTableReferences
    extends
        BaseReferences<_$AppDatabase, $BeneficiariesTable, BeneficiaryEntity> {
  $$BeneficiariesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('beneficiaries__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<int>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $BeneficiaryValuesTable,
    List<BeneficiaryValueEntity>
  >
  _beneficiaryValuesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.beneficiaryValues,
        aliasName: 'beneficiaries__id__beneficiary_values__beneficiary_id',
      );

  $$BeneficiaryValuesTableProcessedTableManager get beneficiaryValuesRefs {
    final manager = $$BeneficiaryValuesTableTableManager(
      $_db,
      $_db.beneficiaryValues,
    ).filter((f) => f.beneficiaryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _beneficiaryValuesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TicketsTable, List<TicketEntity>>
  _ticketsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.tickets,
    aliasName: 'beneficiaries__id__tickets__beneficiary_id',
  );

  $$TicketsTableProcessedTableManager get ticketsRefs {
    final manager = $$TicketsTableTableManager(
      $_db,
      $_db.tickets,
    ).filter((f) => f.beneficiaryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ticketsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BeneficiariesTableFilterComposer
    extends Composer<_$AppDatabase, $BeneficiariesTable> {
  $$BeneficiariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> beneficiaryValuesRefs(
    Expression<bool> Function($$BeneficiaryValuesTableFilterComposer f) f,
  ) {
    final $$BeneficiaryValuesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.beneficiaryValues,
      getReferencedColumn: (t) => t.beneficiaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeneficiaryValuesTableFilterComposer(
            $db: $db,
            $table: $db.beneficiaryValues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ticketsRefs(
    Expression<bool> Function($$TicketsTableFilterComposer f) f,
  ) {
    final $$TicketsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tickets,
      getReferencedColumn: (t) => t.beneficiaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TicketsTableFilterComposer(
            $db: $db,
            $table: $db.tickets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BeneficiariesTableOrderingComposer
    extends Composer<_$AppDatabase, $BeneficiariesTable> {
  $$BeneficiariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BeneficiariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BeneficiariesTable> {
  $$BeneficiariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> beneficiaryValuesRefs<T extends Object>(
    Expression<T> Function($$BeneficiaryValuesTableAnnotationComposer a) f,
  ) {
    final $$BeneficiaryValuesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.beneficiaryValues,
          getReferencedColumn: (t) => t.beneficiaryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BeneficiaryValuesTableAnnotationComposer(
                $db: $db,
                $table: $db.beneficiaryValues,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> ticketsRefs<T extends Object>(
    Expression<T> Function($$TicketsTableAnnotationComposer a) f,
  ) {
    final $$TicketsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tickets,
      getReferencedColumn: (t) => t.beneficiaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TicketsTableAnnotationComposer(
            $db: $db,
            $table: $db.tickets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BeneficiariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BeneficiariesTable,
          BeneficiaryEntity,
          $$BeneficiariesTableFilterComposer,
          $$BeneficiariesTableOrderingComposer,
          $$BeneficiariesTableAnnotationComposer,
          $$BeneficiariesTableCreateCompanionBuilder,
          $$BeneficiariesTableUpdateCompanionBuilder,
          (BeneficiaryEntity, $$BeneficiariesTableReferences),
          BeneficiaryEntity,
          PrefetchHooks Function({
            bool eventId,
            bool beneficiaryValuesRefs,
            bool ticketsRefs,
          })
        > {
  $$BeneficiariesTableTableManager(_$AppDatabase db, $BeneficiariesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BeneficiariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BeneficiariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BeneficiariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> eventId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BeneficiariesCompanion(
                id: id,
                eventId: eventId,
                name: name,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int eventId,
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
              }) => BeneficiariesCompanion.insert(
                id: id,
                eventId: eventId,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BeneficiariesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                eventId = false,
                beneficiaryValuesRefs = false,
                ticketsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (beneficiaryValuesRefs) db.beneficiaryValues,
                    if (ticketsRefs) db.tickets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (eventId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.eventId,
                                    referencedTable:
                                        $$BeneficiariesTableReferences
                                            ._eventIdTable(db),
                                    referencedColumn:
                                        $$BeneficiariesTableReferences
                                            ._eventIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (beneficiaryValuesRefs)
                        await $_getPrefetchedData<
                          BeneficiaryEntity,
                          $BeneficiariesTable,
                          BeneficiaryValueEntity
                        >(
                          currentTable: table,
                          referencedTable: $$BeneficiariesTableReferences
                              ._beneficiaryValuesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BeneficiariesTableReferences(
                                db,
                                table,
                                p0,
                              ).beneficiaryValuesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.beneficiaryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ticketsRefs)
                        await $_getPrefetchedData<
                          BeneficiaryEntity,
                          $BeneficiariesTable,
                          TicketEntity
                        >(
                          currentTable: table,
                          referencedTable: $$BeneficiariesTableReferences
                              ._ticketsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BeneficiariesTableReferences(
                                db,
                                table,
                                p0,
                              ).ticketsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.beneficiaryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BeneficiariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BeneficiariesTable,
      BeneficiaryEntity,
      $$BeneficiariesTableFilterComposer,
      $$BeneficiariesTableOrderingComposer,
      $$BeneficiariesTableAnnotationComposer,
      $$BeneficiariesTableCreateCompanionBuilder,
      $$BeneficiariesTableUpdateCompanionBuilder,
      (BeneficiaryEntity, $$BeneficiariesTableReferences),
      BeneficiaryEntity,
      PrefetchHooks Function({
        bool eventId,
        bool beneficiaryValuesRefs,
        bool ticketsRefs,
      })
    >;
typedef $$BeneficiaryValuesTableCreateCompanionBuilder =
    BeneficiaryValuesCompanion Function({
      Value<int> id,
      required int beneficiaryId,
      required int customFieldId,
      required String value,
    });
typedef $$BeneficiaryValuesTableUpdateCompanionBuilder =
    BeneficiaryValuesCompanion Function({
      Value<int> id,
      Value<int> beneficiaryId,
      Value<int> customFieldId,
      Value<String> value,
    });

final class $$BeneficiaryValuesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BeneficiaryValuesTable,
          BeneficiaryValueEntity
        > {
  $$BeneficiaryValuesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BeneficiariesTable _beneficiaryIdTable(_$AppDatabase db) => db
      .beneficiaries
      .createAlias('beneficiary_values__beneficiary_id__beneficiaries__id');

  $$BeneficiariesTableProcessedTableManager get beneficiaryId {
    final $_column = $_itemColumn<int>('beneficiary_id')!;

    final manager = $$BeneficiariesTableTableManager(
      $_db,
      $_db.beneficiaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_beneficiaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CustomFieldsTable _customFieldIdTable(_$AppDatabase db) => db
      .customFields
      .createAlias('beneficiary_values__custom_field_id__custom_fields__id');

  $$CustomFieldsTableProcessedTableManager get customFieldId {
    final $_column = $_itemColumn<int>('custom_field_id')!;

    final manager = $$CustomFieldsTableTableManager(
      $_db,
      $_db.customFields,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customFieldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BeneficiaryValuesTableFilterComposer
    extends Composer<_$AppDatabase, $BeneficiaryValuesTable> {
  $$BeneficiaryValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$BeneficiariesTableFilterComposer get beneficiaryId {
    final $$BeneficiariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beneficiaryId,
      referencedTable: $db.beneficiaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeneficiariesTableFilterComposer(
            $db: $db,
            $table: $db.beneficiaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomFieldsTableFilterComposer get customFieldId {
    final $$CustomFieldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customFieldId,
      referencedTable: $db.customFields,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomFieldsTableFilterComposer(
            $db: $db,
            $table: $db.customFields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BeneficiaryValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $BeneficiaryValuesTable> {
  $$BeneficiaryValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$BeneficiariesTableOrderingComposer get beneficiaryId {
    final $$BeneficiariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beneficiaryId,
      referencedTable: $db.beneficiaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeneficiariesTableOrderingComposer(
            $db: $db,
            $table: $db.beneficiaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomFieldsTableOrderingComposer get customFieldId {
    final $$CustomFieldsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customFieldId,
      referencedTable: $db.customFields,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomFieldsTableOrderingComposer(
            $db: $db,
            $table: $db.customFields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BeneficiaryValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BeneficiaryValuesTable> {
  $$BeneficiaryValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$BeneficiariesTableAnnotationComposer get beneficiaryId {
    final $$BeneficiariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beneficiaryId,
      referencedTable: $db.beneficiaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeneficiariesTableAnnotationComposer(
            $db: $db,
            $table: $db.beneficiaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomFieldsTableAnnotationComposer get customFieldId {
    final $$CustomFieldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customFieldId,
      referencedTable: $db.customFields,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomFieldsTableAnnotationComposer(
            $db: $db,
            $table: $db.customFields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BeneficiaryValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BeneficiaryValuesTable,
          BeneficiaryValueEntity,
          $$BeneficiaryValuesTableFilterComposer,
          $$BeneficiaryValuesTableOrderingComposer,
          $$BeneficiaryValuesTableAnnotationComposer,
          $$BeneficiaryValuesTableCreateCompanionBuilder,
          $$BeneficiaryValuesTableUpdateCompanionBuilder,
          (BeneficiaryValueEntity, $$BeneficiaryValuesTableReferences),
          BeneficiaryValueEntity,
          PrefetchHooks Function({bool beneficiaryId, bool customFieldId})
        > {
  $$BeneficiaryValuesTableTableManager(
    _$AppDatabase db,
    $BeneficiaryValuesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BeneficiaryValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BeneficiaryValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BeneficiaryValuesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> beneficiaryId = const Value.absent(),
                Value<int> customFieldId = const Value.absent(),
                Value<String> value = const Value.absent(),
              }) => BeneficiaryValuesCompanion(
                id: id,
                beneficiaryId: beneficiaryId,
                customFieldId: customFieldId,
                value: value,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int beneficiaryId,
                required int customFieldId,
                required String value,
              }) => BeneficiaryValuesCompanion.insert(
                id: id,
                beneficiaryId: beneficiaryId,
                customFieldId: customFieldId,
                value: value,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BeneficiaryValuesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({beneficiaryId = false, customFieldId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (beneficiaryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.beneficiaryId,
                                    referencedTable:
                                        $$BeneficiaryValuesTableReferences
                                            ._beneficiaryIdTable(db),
                                    referencedColumn:
                                        $$BeneficiaryValuesTableReferences
                                            ._beneficiaryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (customFieldId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.customFieldId,
                                    referencedTable:
                                        $$BeneficiaryValuesTableReferences
                                            ._customFieldIdTable(db),
                                    referencedColumn:
                                        $$BeneficiaryValuesTableReferences
                                            ._customFieldIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$BeneficiaryValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BeneficiaryValuesTable,
      BeneficiaryValueEntity,
      $$BeneficiaryValuesTableFilterComposer,
      $$BeneficiaryValuesTableOrderingComposer,
      $$BeneficiaryValuesTableAnnotationComposer,
      $$BeneficiaryValuesTableCreateCompanionBuilder,
      $$BeneficiaryValuesTableUpdateCompanionBuilder,
      (BeneficiaryValueEntity, $$BeneficiaryValuesTableReferences),
      BeneficiaryValueEntity,
      PrefetchHooks Function({bool beneficiaryId, bool customFieldId})
    >;
typedef $$TicketsTableCreateCompanionBuilder =
    TicketsCompanion Function({
      Value<int> id,
      required int beneficiaryId,
      required int eventId,
      required String readableId,
      required String randomPart,
      required String qrPayload,
      Value<DateTime> createdAt,
    });
typedef $$TicketsTableUpdateCompanionBuilder =
    TicketsCompanion Function({
      Value<int> id,
      Value<int> beneficiaryId,
      Value<int> eventId,
      Value<String> readableId,
      Value<String> randomPart,
      Value<String> qrPayload,
      Value<DateTime> createdAt,
    });

final class $$TicketsTableReferences
    extends BaseReferences<_$AppDatabase, $TicketsTable, TicketEntity> {
  $$TicketsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BeneficiariesTable _beneficiaryIdTable(_$AppDatabase db) => db
      .beneficiaries
      .createAlias('tickets__beneficiary_id__beneficiaries__id');

  $$BeneficiariesTableProcessedTableManager get beneficiaryId {
    final $_column = $_itemColumn<int>('beneficiary_id')!;

    final manager = $$BeneficiariesTableTableManager(
      $_db,
      $_db.beneficiaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_beneficiaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('tickets__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<int>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CheckInsTable, List<CheckInEntity>>
  _checkInsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.checkIns,
    aliasName: 'tickets__id__check_ins__ticket_id',
  );

  $$CheckInsTableProcessedTableManager get checkInsRefs {
    final manager = $$CheckInsTableTableManager(
      $_db,
      $_db.checkIns,
    ).filter((f) => f.ticketId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_checkInsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TicketsTableFilterComposer
    extends Composer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readableId => $composableBuilder(
    column: $table.readableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get randomPart => $composableBuilder(
    column: $table.randomPart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qrPayload => $composableBuilder(
    column: $table.qrPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BeneficiariesTableFilterComposer get beneficiaryId {
    final $$BeneficiariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beneficiaryId,
      referencedTable: $db.beneficiaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeneficiariesTableFilterComposer(
            $db: $db,
            $table: $db.beneficiaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> checkInsRefs(
    Expression<bool> Function($$CheckInsTableFilterComposer f) f,
  ) {
    final $$CheckInsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkIns,
      getReferencedColumn: (t) => t.ticketId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckInsTableFilterComposer(
            $db: $db,
            $table: $db.checkIns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TicketsTableOrderingComposer
    extends Composer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readableId => $composableBuilder(
    column: $table.readableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get randomPart => $composableBuilder(
    column: $table.randomPart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qrPayload => $composableBuilder(
    column: $table.qrPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BeneficiariesTableOrderingComposer get beneficiaryId {
    final $$BeneficiariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beneficiaryId,
      referencedTable: $db.beneficiaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeneficiariesTableOrderingComposer(
            $db: $db,
            $table: $db.beneficiaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TicketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get readableId => $composableBuilder(
    column: $table.readableId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get randomPart => $composableBuilder(
    column: $table.randomPart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qrPayload =>
      $composableBuilder(column: $table.qrPayload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BeneficiariesTableAnnotationComposer get beneficiaryId {
    final $$BeneficiariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beneficiaryId,
      referencedTable: $db.beneficiaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeneficiariesTableAnnotationComposer(
            $db: $db,
            $table: $db.beneficiaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> checkInsRefs<T extends Object>(
    Expression<T> Function($$CheckInsTableAnnotationComposer a) f,
  ) {
    final $$CheckInsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checkIns,
      getReferencedColumn: (t) => t.ticketId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheckInsTableAnnotationComposer(
            $db: $db,
            $table: $db.checkIns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TicketsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TicketsTable,
          TicketEntity,
          $$TicketsTableFilterComposer,
          $$TicketsTableOrderingComposer,
          $$TicketsTableAnnotationComposer,
          $$TicketsTableCreateCompanionBuilder,
          $$TicketsTableUpdateCompanionBuilder,
          (TicketEntity, $$TicketsTableReferences),
          TicketEntity,
          PrefetchHooks Function({
            bool beneficiaryId,
            bool eventId,
            bool checkInsRefs,
          })
        > {
  $$TicketsTableTableManager(_$AppDatabase db, $TicketsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TicketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TicketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TicketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> beneficiaryId = const Value.absent(),
                Value<int> eventId = const Value.absent(),
                Value<String> readableId = const Value.absent(),
                Value<String> randomPart = const Value.absent(),
                Value<String> qrPayload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TicketsCompanion(
                id: id,
                beneficiaryId: beneficiaryId,
                eventId: eventId,
                readableId: readableId,
                randomPart: randomPart,
                qrPayload: qrPayload,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int beneficiaryId,
                required int eventId,
                required String readableId,
                required String randomPart,
                required String qrPayload,
                Value<DateTime> createdAt = const Value.absent(),
              }) => TicketsCompanion.insert(
                id: id,
                beneficiaryId: beneficiaryId,
                eventId: eventId,
                readableId: readableId,
                randomPart: randomPart,
                qrPayload: qrPayload,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TicketsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({beneficiaryId = false, eventId = false, checkInsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (checkInsRefs) db.checkIns],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (beneficiaryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.beneficiaryId,
                                    referencedTable: $$TicketsTableReferences
                                        ._beneficiaryIdTable(db),
                                    referencedColumn: $$TicketsTableReferences
                                        ._beneficiaryIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (eventId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.eventId,
                                    referencedTable: $$TicketsTableReferences
                                        ._eventIdTable(db),
                                    referencedColumn: $$TicketsTableReferences
                                        ._eventIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (checkInsRefs)
                        await $_getPrefetchedData<
                          TicketEntity,
                          $TicketsTable,
                          CheckInEntity
                        >(
                          currentTable: table,
                          referencedTable: $$TicketsTableReferences
                              ._checkInsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TicketsTableReferences(
                                db,
                                table,
                                p0,
                              ).checkInsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ticketId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TicketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TicketsTable,
      TicketEntity,
      $$TicketsTableFilterComposer,
      $$TicketsTableOrderingComposer,
      $$TicketsTableAnnotationComposer,
      $$TicketsTableCreateCompanionBuilder,
      $$TicketsTableUpdateCompanionBuilder,
      (TicketEntity, $$TicketsTableReferences),
      TicketEntity,
      PrefetchHooks Function({
        bool beneficiaryId,
        bool eventId,
        bool checkInsRefs,
      })
    >;
typedef $$CheckInsTableCreateCompanionBuilder =
    CheckInsCompanion Function({
      Value<int> id,
      required int ticketId,
      required int eventId,
      Value<DateTime> scannedAt,
    });
typedef $$CheckInsTableUpdateCompanionBuilder =
    CheckInsCompanion Function({
      Value<int> id,
      Value<int> ticketId,
      Value<int> eventId,
      Value<DateTime> scannedAt,
    });

final class $$CheckInsTableReferences
    extends BaseReferences<_$AppDatabase, $CheckInsTable, CheckInEntity> {
  $$CheckInsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TicketsTable _ticketIdTable(_$AppDatabase db) =>
      db.tickets.createAlias('check_ins__ticket_id__tickets__id');

  $$TicketsTableProcessedTableManager get ticketId {
    final $_column = $_itemColumn<int>('ticket_id')!;

    final manager = $$TicketsTableTableManager(
      $_db,
      $_db.tickets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ticketIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('check_ins__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<int>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CheckInsTableFilterComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scannedAt => $composableBuilder(
    column: $table.scannedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TicketsTableFilterComposer get ticketId {
    final $$TicketsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ticketId,
      referencedTable: $db.tickets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TicketsTableFilterComposer(
            $db: $db,
            $table: $db.tickets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckInsTableOrderingComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scannedAt => $composableBuilder(
    column: $table.scannedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TicketsTableOrderingComposer get ticketId {
    final $$TicketsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ticketId,
      referencedTable: $db.tickets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TicketsTableOrderingComposer(
            $db: $db,
            $table: $db.tickets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckInsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scannedAt =>
      $composableBuilder(column: $table.scannedAt, builder: (column) => column);

  $$TicketsTableAnnotationComposer get ticketId {
    final $$TicketsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ticketId,
      referencedTable: $db.tickets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TicketsTableAnnotationComposer(
            $db: $db,
            $table: $db.tickets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheckInsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CheckInsTable,
          CheckInEntity,
          $$CheckInsTableFilterComposer,
          $$CheckInsTableOrderingComposer,
          $$CheckInsTableAnnotationComposer,
          $$CheckInsTableCreateCompanionBuilder,
          $$CheckInsTableUpdateCompanionBuilder,
          (CheckInEntity, $$CheckInsTableReferences),
          CheckInEntity,
          PrefetchHooks Function({bool ticketId, bool eventId})
        > {
  $$CheckInsTableTableManager(_$AppDatabase db, $CheckInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ticketId = const Value.absent(),
                Value<int> eventId = const Value.absent(),
                Value<DateTime> scannedAt = const Value.absent(),
              }) => CheckInsCompanion(
                id: id,
                ticketId: ticketId,
                eventId: eventId,
                scannedAt: scannedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ticketId,
                required int eventId,
                Value<DateTime> scannedAt = const Value.absent(),
              }) => CheckInsCompanion.insert(
                id: id,
                ticketId: ticketId,
                eventId: eventId,
                scannedAt: scannedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CheckInsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ticketId = false, eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ticketId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ticketId,
                                referencedTable: $$CheckInsTableReferences
                                    ._ticketIdTable(db),
                                referencedColumn: $$CheckInsTableReferences
                                    ._ticketIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (eventId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.eventId,
                                referencedTable: $$CheckInsTableReferences
                                    ._eventIdTable(db),
                                referencedColumn: $$CheckInsTableReferences
                                    ._eventIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CheckInsTable,
      CheckInEntity,
      $$CheckInsTableFilterComposer,
      $$CheckInsTableOrderingComposer,
      $$CheckInsTableAnnotationComposer,
      $$CheckInsTableCreateCompanionBuilder,
      $$CheckInsTableUpdateCompanionBuilder,
      (CheckInEntity, $$CheckInsTableReferences),
      CheckInEntity,
      PrefetchHooks Function({bool ticketId, bool eventId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$CustomFieldsTableTableManager get customFields =>
      $$CustomFieldsTableTableManager(_db, _db.customFields);
  $$BeneficiariesTableTableManager get beneficiaries =>
      $$BeneficiariesTableTableManager(_db, _db.beneficiaries);
  $$BeneficiaryValuesTableTableManager get beneficiaryValues =>
      $$BeneficiaryValuesTableTableManager(_db, _db.beneficiaryValues);
  $$TicketsTableTableManager get tickets =>
      $$TicketsTableTableManager(_db, _db.tickets);
  $$CheckInsTableTableManager get checkIns =>
      $$CheckInsTableTableManager(_db, _db.checkIns);
}
