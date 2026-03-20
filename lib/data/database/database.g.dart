// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LocalTournamentsTable extends LocalTournaments
    with TableInfo<$LocalTournamentsTable, LocalTournament> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTournamentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _apiTokenMeta = const VerificationMeta(
    'apiToken',
  );
  @override
  late final GeneratedColumn<String> apiToken = GeneratedColumn<String>(
    'api_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameRulesJsonMeta = const VerificationMeta(
    'gameRulesJson',
  );
  @override
  late final GeneratedColumn<String> gameRulesJson = GeneratedColumn<String>(
    'game_rules_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _venueNameMeta = const VerificationMeta(
    'venueName',
  );
  @override
  late final GeneratedColumn<String> venueName = GeneratedColumn<String>(
    'venue_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _venueAddressMeta = const VerificationMeta(
    'venueAddress',
  );
  @override
  late final GeneratedColumn<String> venueAddress = GeneratedColumn<String>(
    'venue_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    apiToken,
    status,
    gameRulesJson,
    venueName,
    venueAddress,
    startDate,
    endDate,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_tournaments';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTournament> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('api_token')) {
      context.handle(
        _apiTokenMeta,
        apiToken.isAcceptableOrUnknown(data['api_token']!, _apiTokenMeta),
      );
    } else if (isInserting) {
      context.missing(_apiTokenMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('game_rules_json')) {
      context.handle(
        _gameRulesJsonMeta,
        gameRulesJson.isAcceptableOrUnknown(
          data['game_rules_json']!,
          _gameRulesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gameRulesJsonMeta);
    }
    if (data.containsKey('venue_name')) {
      context.handle(
        _venueNameMeta,
        venueName.isAcceptableOrUnknown(data['venue_name']!, _venueNameMeta),
      );
    }
    if (data.containsKey('venue_address')) {
      context.handle(
        _venueAddressMeta,
        venueAddress.isAcceptableOrUnknown(
          data['venue_address']!,
          _venueAddressMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTournament map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTournament(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      apiToken:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}api_token'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      gameRulesJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}game_rules_json'],
          )!,
      venueName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venue_name'],
      ),
      venueAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venue_address'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      syncedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}synced_at'],
          )!,
    );
  }

  @override
  $LocalTournamentsTable createAlias(String alias) {
    return $LocalTournamentsTable(attachedDatabase, alias);
  }
}

class LocalTournament extends DataClass implements Insertable<LocalTournament> {
  final String id;
  final String name;
  final String apiToken;
  final String status;
  final String gameRulesJson;
  final String? venueName;
  final String? venueAddress;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime syncedAt;
  const LocalTournament({
    required this.id,
    required this.name,
    required this.apiToken,
    required this.status,
    required this.gameRulesJson,
    this.venueName,
    this.venueAddress,
    this.startDate,
    this.endDate,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['api_token'] = Variable<String>(apiToken);
    map['status'] = Variable<String>(status);
    map['game_rules_json'] = Variable<String>(gameRulesJson);
    if (!nullToAbsent || venueName != null) {
      map['venue_name'] = Variable<String>(venueName);
    }
    if (!nullToAbsent || venueAddress != null) {
      map['venue_address'] = Variable<String>(venueAddress);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalTournamentsCompanion toCompanion(bool nullToAbsent) {
    return LocalTournamentsCompanion(
      id: Value(id),
      name: Value(name),
      apiToken: Value(apiToken),
      status: Value(status),
      gameRulesJson: Value(gameRulesJson),
      venueName:
          venueName == null && nullToAbsent
              ? const Value.absent()
              : Value(venueName),
      venueAddress:
          venueAddress == null && nullToAbsent
              ? const Value.absent()
              : Value(venueAddress),
      startDate:
          startDate == null && nullToAbsent
              ? const Value.absent()
              : Value(startDate),
      endDate:
          endDate == null && nullToAbsent
              ? const Value.absent()
              : Value(endDate),
      syncedAt: Value(syncedAt),
    );
  }

  factory LocalTournament.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTournament(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      apiToken: serializer.fromJson<String>(json['apiToken']),
      status: serializer.fromJson<String>(json['status']),
      gameRulesJson: serializer.fromJson<String>(json['gameRulesJson']),
      venueName: serializer.fromJson<String?>(json['venueName']),
      venueAddress: serializer.fromJson<String?>(json['venueAddress']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'apiToken': serializer.toJson<String>(apiToken),
      'status': serializer.toJson<String>(status),
      'gameRulesJson': serializer.toJson<String>(gameRulesJson),
      'venueName': serializer.toJson<String?>(venueName),
      'venueAddress': serializer.toJson<String?>(venueAddress),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  LocalTournament copyWith({
    String? id,
    String? name,
    String? apiToken,
    String? status,
    String? gameRulesJson,
    Value<String?> venueName = const Value.absent(),
    Value<String?> venueAddress = const Value.absent(),
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> endDate = const Value.absent(),
    DateTime? syncedAt,
  }) => LocalTournament(
    id: id ?? this.id,
    name: name ?? this.name,
    apiToken: apiToken ?? this.apiToken,
    status: status ?? this.status,
    gameRulesJson: gameRulesJson ?? this.gameRulesJson,
    venueName: venueName.present ? venueName.value : this.venueName,
    venueAddress: venueAddress.present ? venueAddress.value : this.venueAddress,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  LocalTournament copyWithCompanion(LocalTournamentsCompanion data) {
    return LocalTournament(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      apiToken: data.apiToken.present ? data.apiToken.value : this.apiToken,
      status: data.status.present ? data.status.value : this.status,
      gameRulesJson:
          data.gameRulesJson.present
              ? data.gameRulesJson.value
              : this.gameRulesJson,
      venueName: data.venueName.present ? data.venueName.value : this.venueName,
      venueAddress:
          data.venueAddress.present
              ? data.venueAddress.value
              : this.venueAddress,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTournament(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('apiToken: $apiToken, ')
          ..write('status: $status, ')
          ..write('gameRulesJson: $gameRulesJson, ')
          ..write('venueName: $venueName, ')
          ..write('venueAddress: $venueAddress, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    apiToken,
    status,
    gameRulesJson,
    venueName,
    venueAddress,
    startDate,
    endDate,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTournament &&
          other.id == this.id &&
          other.name == this.name &&
          other.apiToken == this.apiToken &&
          other.status == this.status &&
          other.gameRulesJson == this.gameRulesJson &&
          other.venueName == this.venueName &&
          other.venueAddress == this.venueAddress &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.syncedAt == this.syncedAt);
}

class LocalTournamentsCompanion extends UpdateCompanion<LocalTournament> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> apiToken;
  final Value<String> status;
  final Value<String> gameRulesJson;
  final Value<String?> venueName;
  final Value<String?> venueAddress;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LocalTournamentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.apiToken = const Value.absent(),
    this.status = const Value.absent(),
    this.gameRulesJson = const Value.absent(),
    this.venueName = const Value.absent(),
    this.venueAddress = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTournamentsCompanion.insert({
    required String id,
    required String name,
    required String apiToken,
    required String status,
    required String gameRulesJson,
    this.venueName = const Value.absent(),
    this.venueAddress = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       apiToken = Value(apiToken),
       status = Value(status),
       gameRulesJson = Value(gameRulesJson),
       syncedAt = Value(syncedAt);
  static Insertable<LocalTournament> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? apiToken,
    Expression<String>? status,
    Expression<String>? gameRulesJson,
    Expression<String>? venueName,
    Expression<String>? venueAddress,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (apiToken != null) 'api_token': apiToken,
      if (status != null) 'status': status,
      if (gameRulesJson != null) 'game_rules_json': gameRulesJson,
      if (venueName != null) 'venue_name': venueName,
      if (venueAddress != null) 'venue_address': venueAddress,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTournamentsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? apiToken,
    Value<String>? status,
    Value<String>? gameRulesJson,
    Value<String?>? venueName,
    Value<String?>? venueAddress,
    Value<DateTime?>? startDate,
    Value<DateTime?>? endDate,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocalTournamentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      apiToken: apiToken ?? this.apiToken,
      status: status ?? this.status,
      gameRulesJson: gameRulesJson ?? this.gameRulesJson,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (apiToken.present) {
      map['api_token'] = Variable<String>(apiToken.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (gameRulesJson.present) {
      map['game_rules_json'] = Variable<String>(gameRulesJson.value);
    }
    if (venueName.present) {
      map['venue_name'] = Variable<String>(venueName.value);
    }
    if (venueAddress.present) {
      map['venue_address'] = Variable<String>(venueAddress.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTournamentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('apiToken: $apiToken, ')
          ..write('status: $status, ')
          ..write('gameRulesJson: $gameRulesJson, ')
          ..write('venueName: $venueName, ')
          ..write('venueAddress: $venueAddress, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTournamentTeamsTable extends LocalTournamentTeams
    with TableInfo<$LocalTournamentTeamsTable, LocalTournamentTeam> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTournamentTeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tournamentIdMeta = const VerificationMeta(
    'tournamentId',
  );
  @override
  late final GeneratedColumn<String> tournamentId = GeneratedColumn<String>(
    'tournament_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<int> teamId = GeneratedColumn<int>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamNameMeta = const VerificationMeta(
    'teamName',
  );
  @override
  late final GeneratedColumn<String> teamName = GeneratedColumn<String>(
    'team_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamLogoUrlMeta = const VerificationMeta(
    'teamLogoUrl',
  );
  @override
  late final GeneratedColumn<String> teamLogoUrl = GeneratedColumn<String>(
    'team_logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _primaryColorMeta = const VerificationMeta(
    'primaryColor',
  );
  @override
  late final GeneratedColumn<String> primaryColor = GeneratedColumn<String>(
    'primary_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secondaryColorMeta = const VerificationMeta(
    'secondaryColor',
  );
  @override
  late final GeneratedColumn<String> secondaryColor = GeneratedColumn<String>(
    'secondary_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seedNumberMeta = const VerificationMeta(
    'seedNumber',
  );
  @override
  late final GeneratedColumn<int> seedNumber = GeneratedColumn<int>(
    'seed_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _winsMeta = const VerificationMeta('wins');
  @override
  late final GeneratedColumn<int> wins = GeneratedColumn<int>(
    'wins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lossesMeta = const VerificationMeta('losses');
  @override
  late final GeneratedColumn<int> losses = GeneratedColumn<int>(
    'losses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tournamentId,
    teamId,
    teamName,
    teamLogoUrl,
    primaryColor,
    secondaryColor,
    groupName,
    seedNumber,
    wins,
    losses,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_tournament_teams';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTournamentTeam> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tournament_id')) {
      context.handle(
        _tournamentIdMeta,
        tournamentId.isAcceptableOrUnknown(
          data['tournament_id']!,
          _tournamentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tournamentIdMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('team_name')) {
      context.handle(
        _teamNameMeta,
        teamName.isAcceptableOrUnknown(data['team_name']!, _teamNameMeta),
      );
    } else if (isInserting) {
      context.missing(_teamNameMeta);
    }
    if (data.containsKey('team_logo_url')) {
      context.handle(
        _teamLogoUrlMeta,
        teamLogoUrl.isAcceptableOrUnknown(
          data['team_logo_url']!,
          _teamLogoUrlMeta,
        ),
      );
    }
    if (data.containsKey('primary_color')) {
      context.handle(
        _primaryColorMeta,
        primaryColor.isAcceptableOrUnknown(
          data['primary_color']!,
          _primaryColorMeta,
        ),
      );
    }
    if (data.containsKey('secondary_color')) {
      context.handle(
        _secondaryColorMeta,
        secondaryColor.isAcceptableOrUnknown(
          data['secondary_color']!,
          _secondaryColorMeta,
        ),
      );
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    if (data.containsKey('seed_number')) {
      context.handle(
        _seedNumberMeta,
        seedNumber.isAcceptableOrUnknown(data['seed_number']!, _seedNumberMeta),
      );
    }
    if (data.containsKey('wins')) {
      context.handle(
        _winsMeta,
        wins.isAcceptableOrUnknown(data['wins']!, _winsMeta),
      );
    }
    if (data.containsKey('losses')) {
      context.handle(
        _lossesMeta,
        losses.isAcceptableOrUnknown(data['losses']!, _lossesMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTournamentTeam map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTournamentTeam(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      tournamentId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}tournament_id'],
          )!,
      teamId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}team_id'],
          )!,
      teamName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}team_name'],
          )!,
      teamLogoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_logo_url'],
      ),
      primaryColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_color'],
      ),
      secondaryColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_color'],
      ),
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      ),
      seedNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed_number'],
      ),
      wins:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}wins'],
          )!,
      losses:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}losses'],
          )!,
      syncedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}synced_at'],
          )!,
    );
  }

  @override
  $LocalTournamentTeamsTable createAlias(String alias) {
    return $LocalTournamentTeamsTable(attachedDatabase, alias);
  }
}

class LocalTournamentTeam extends DataClass
    implements Insertable<LocalTournamentTeam> {
  final int id;
  final String tournamentId;
  final int teamId;
  final String teamName;
  final String? teamLogoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? groupName;
  final int? seedNumber;
  final int wins;
  final int losses;
  final DateTime syncedAt;
  const LocalTournamentTeam({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.groupName,
    this.seedNumber,
    required this.wins,
    required this.losses,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tournament_id'] = Variable<String>(tournamentId);
    map['team_id'] = Variable<int>(teamId);
    map['team_name'] = Variable<String>(teamName);
    if (!nullToAbsent || teamLogoUrl != null) {
      map['team_logo_url'] = Variable<String>(teamLogoUrl);
    }
    if (!nullToAbsent || primaryColor != null) {
      map['primary_color'] = Variable<String>(primaryColor);
    }
    if (!nullToAbsent || secondaryColor != null) {
      map['secondary_color'] = Variable<String>(secondaryColor);
    }
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    if (!nullToAbsent || seedNumber != null) {
      map['seed_number'] = Variable<int>(seedNumber);
    }
    map['wins'] = Variable<int>(wins);
    map['losses'] = Variable<int>(losses);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalTournamentTeamsCompanion toCompanion(bool nullToAbsent) {
    return LocalTournamentTeamsCompanion(
      id: Value(id),
      tournamentId: Value(tournamentId),
      teamId: Value(teamId),
      teamName: Value(teamName),
      teamLogoUrl:
          teamLogoUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(teamLogoUrl),
      primaryColor:
          primaryColor == null && nullToAbsent
              ? const Value.absent()
              : Value(primaryColor),
      secondaryColor:
          secondaryColor == null && nullToAbsent
              ? const Value.absent()
              : Value(secondaryColor),
      groupName:
          groupName == null && nullToAbsent
              ? const Value.absent()
              : Value(groupName),
      seedNumber:
          seedNumber == null && nullToAbsent
              ? const Value.absent()
              : Value(seedNumber),
      wins: Value(wins),
      losses: Value(losses),
      syncedAt: Value(syncedAt),
    );
  }

  factory LocalTournamentTeam.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTournamentTeam(
      id: serializer.fromJson<int>(json['id']),
      tournamentId: serializer.fromJson<String>(json['tournamentId']),
      teamId: serializer.fromJson<int>(json['teamId']),
      teamName: serializer.fromJson<String>(json['teamName']),
      teamLogoUrl: serializer.fromJson<String?>(json['teamLogoUrl']),
      primaryColor: serializer.fromJson<String?>(json['primaryColor']),
      secondaryColor: serializer.fromJson<String?>(json['secondaryColor']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      seedNumber: serializer.fromJson<int?>(json['seedNumber']),
      wins: serializer.fromJson<int>(json['wins']),
      losses: serializer.fromJson<int>(json['losses']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tournamentId': serializer.toJson<String>(tournamentId),
      'teamId': serializer.toJson<int>(teamId),
      'teamName': serializer.toJson<String>(teamName),
      'teamLogoUrl': serializer.toJson<String?>(teamLogoUrl),
      'primaryColor': serializer.toJson<String?>(primaryColor),
      'secondaryColor': serializer.toJson<String?>(secondaryColor),
      'groupName': serializer.toJson<String?>(groupName),
      'seedNumber': serializer.toJson<int?>(seedNumber),
      'wins': serializer.toJson<int>(wins),
      'losses': serializer.toJson<int>(losses),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  LocalTournamentTeam copyWith({
    int? id,
    String? tournamentId,
    int? teamId,
    String? teamName,
    Value<String?> teamLogoUrl = const Value.absent(),
    Value<String?> primaryColor = const Value.absent(),
    Value<String?> secondaryColor = const Value.absent(),
    Value<String?> groupName = const Value.absent(),
    Value<int?> seedNumber = const Value.absent(),
    int? wins,
    int? losses,
    DateTime? syncedAt,
  }) => LocalTournamentTeam(
    id: id ?? this.id,
    tournamentId: tournamentId ?? this.tournamentId,
    teamId: teamId ?? this.teamId,
    teamName: teamName ?? this.teamName,
    teamLogoUrl: teamLogoUrl.present ? teamLogoUrl.value : this.teamLogoUrl,
    primaryColor: primaryColor.present ? primaryColor.value : this.primaryColor,
    secondaryColor:
        secondaryColor.present ? secondaryColor.value : this.secondaryColor,
    groupName: groupName.present ? groupName.value : this.groupName,
    seedNumber: seedNumber.present ? seedNumber.value : this.seedNumber,
    wins: wins ?? this.wins,
    losses: losses ?? this.losses,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  LocalTournamentTeam copyWithCompanion(LocalTournamentTeamsCompanion data) {
    return LocalTournamentTeam(
      id: data.id.present ? data.id.value : this.id,
      tournamentId:
          data.tournamentId.present
              ? data.tournamentId.value
              : this.tournamentId,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      teamName: data.teamName.present ? data.teamName.value : this.teamName,
      teamLogoUrl:
          data.teamLogoUrl.present ? data.teamLogoUrl.value : this.teamLogoUrl,
      primaryColor:
          data.primaryColor.present
              ? data.primaryColor.value
              : this.primaryColor,
      secondaryColor:
          data.secondaryColor.present
              ? data.secondaryColor.value
              : this.secondaryColor,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      seedNumber:
          data.seedNumber.present ? data.seedNumber.value : this.seedNumber,
      wins: data.wins.present ? data.wins.value : this.wins,
      losses: data.losses.present ? data.losses.value : this.losses,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTournamentTeam(')
          ..write('id: $id, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('teamId: $teamId, ')
          ..write('teamName: $teamName, ')
          ..write('teamLogoUrl: $teamLogoUrl, ')
          ..write('primaryColor: $primaryColor, ')
          ..write('secondaryColor: $secondaryColor, ')
          ..write('groupName: $groupName, ')
          ..write('seedNumber: $seedNumber, ')
          ..write('wins: $wins, ')
          ..write('losses: $losses, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tournamentId,
    teamId,
    teamName,
    teamLogoUrl,
    primaryColor,
    secondaryColor,
    groupName,
    seedNumber,
    wins,
    losses,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTournamentTeam &&
          other.id == this.id &&
          other.tournamentId == this.tournamentId &&
          other.teamId == this.teamId &&
          other.teamName == this.teamName &&
          other.teamLogoUrl == this.teamLogoUrl &&
          other.primaryColor == this.primaryColor &&
          other.secondaryColor == this.secondaryColor &&
          other.groupName == this.groupName &&
          other.seedNumber == this.seedNumber &&
          other.wins == this.wins &&
          other.losses == this.losses &&
          other.syncedAt == this.syncedAt);
}

class LocalTournamentTeamsCompanion
    extends UpdateCompanion<LocalTournamentTeam> {
  final Value<int> id;
  final Value<String> tournamentId;
  final Value<int> teamId;
  final Value<String> teamName;
  final Value<String?> teamLogoUrl;
  final Value<String?> primaryColor;
  final Value<String?> secondaryColor;
  final Value<String?> groupName;
  final Value<int?> seedNumber;
  final Value<int> wins;
  final Value<int> losses;
  final Value<DateTime> syncedAt;
  const LocalTournamentTeamsCompanion({
    this.id = const Value.absent(),
    this.tournamentId = const Value.absent(),
    this.teamId = const Value.absent(),
    this.teamName = const Value.absent(),
    this.teamLogoUrl = const Value.absent(),
    this.primaryColor = const Value.absent(),
    this.secondaryColor = const Value.absent(),
    this.groupName = const Value.absent(),
    this.seedNumber = const Value.absent(),
    this.wins = const Value.absent(),
    this.losses = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  LocalTournamentTeamsCompanion.insert({
    this.id = const Value.absent(),
    required String tournamentId,
    required int teamId,
    required String teamName,
    this.teamLogoUrl = const Value.absent(),
    this.primaryColor = const Value.absent(),
    this.secondaryColor = const Value.absent(),
    this.groupName = const Value.absent(),
    this.seedNumber = const Value.absent(),
    this.wins = const Value.absent(),
    this.losses = const Value.absent(),
    required DateTime syncedAt,
  }) : tournamentId = Value(tournamentId),
       teamId = Value(teamId),
       teamName = Value(teamName),
       syncedAt = Value(syncedAt);
  static Insertable<LocalTournamentTeam> custom({
    Expression<int>? id,
    Expression<String>? tournamentId,
    Expression<int>? teamId,
    Expression<String>? teamName,
    Expression<String>? teamLogoUrl,
    Expression<String>? primaryColor,
    Expression<String>? secondaryColor,
    Expression<String>? groupName,
    Expression<int>? seedNumber,
    Expression<int>? wins,
    Expression<int>? losses,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tournamentId != null) 'tournament_id': tournamentId,
      if (teamId != null) 'team_id': teamId,
      if (teamName != null) 'team_name': teamName,
      if (teamLogoUrl != null) 'team_logo_url': teamLogoUrl,
      if (primaryColor != null) 'primary_color': primaryColor,
      if (secondaryColor != null) 'secondary_color': secondaryColor,
      if (groupName != null) 'group_name': groupName,
      if (seedNumber != null) 'seed_number': seedNumber,
      if (wins != null) 'wins': wins,
      if (losses != null) 'losses': losses,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  LocalTournamentTeamsCompanion copyWith({
    Value<int>? id,
    Value<String>? tournamentId,
    Value<int>? teamId,
    Value<String>? teamName,
    Value<String?>? teamLogoUrl,
    Value<String?>? primaryColor,
    Value<String?>? secondaryColor,
    Value<String?>? groupName,
    Value<int?>? seedNumber,
    Value<int>? wins,
    Value<int>? losses,
    Value<DateTime>? syncedAt,
  }) {
    return LocalTournamentTeamsCompanion(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamLogoUrl: teamLogoUrl ?? this.teamLogoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      groupName: groupName ?? this.groupName,
      seedNumber: seedNumber ?? this.seedNumber,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tournamentId.present) {
      map['tournament_id'] = Variable<String>(tournamentId.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<int>(teamId.value);
    }
    if (teamName.present) {
      map['team_name'] = Variable<String>(teamName.value);
    }
    if (teamLogoUrl.present) {
      map['team_logo_url'] = Variable<String>(teamLogoUrl.value);
    }
    if (primaryColor.present) {
      map['primary_color'] = Variable<String>(primaryColor.value);
    }
    if (secondaryColor.present) {
      map['secondary_color'] = Variable<String>(secondaryColor.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (seedNumber.present) {
      map['seed_number'] = Variable<int>(seedNumber.value);
    }
    if (wins.present) {
      map['wins'] = Variable<int>(wins.value);
    }
    if (losses.present) {
      map['losses'] = Variable<int>(losses.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTournamentTeamsCompanion(')
          ..write('id: $id, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('teamId: $teamId, ')
          ..write('teamName: $teamName, ')
          ..write('teamLogoUrl: $teamLogoUrl, ')
          ..write('primaryColor: $primaryColor, ')
          ..write('secondaryColor: $secondaryColor, ')
          ..write('groupName: $groupName, ')
          ..write('seedNumber: $seedNumber, ')
          ..write('wins: $wins, ')
          ..write('losses: $losses, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalTournamentPlayersTable extends LocalTournamentPlayers
    with TableInfo<$LocalTournamentPlayersTable, LocalTournamentPlayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTournamentPlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tournamentTeamIdMeta = const VerificationMeta(
    'tournamentTeamId',
  );
  @override
  late final GeneratedColumn<int> tournamentTeamId = GeneratedColumn<int>(
    'tournament_team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userNicknameMeta = const VerificationMeta(
    'userNickname',
  );
  @override
  late final GeneratedColumn<String> userNickname = GeneratedColumn<String>(
    'user_nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileImageUrlMeta = const VerificationMeta(
    'profileImageUrl',
  );
  @override
  late final GeneratedColumn<String> profileImageUrl = GeneratedColumn<String>(
    'profile_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jerseyNumberMeta = const VerificationMeta(
    'jerseyNumber',
  );
  @override
  late final GeneratedColumn<int> jerseyNumber = GeneratedColumn<int>(
    'jersey_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
    'position',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isStarterMeta = const VerificationMeta(
    'isStarter',
  );
  @override
  late final GeneratedColumn<bool> isStarter = GeneratedColumn<bool>(
    'is_starter',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_starter" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _bdrDnaCodeMeta = const VerificationMeta(
    'bdrDnaCode',
  );
  @override
  late final GeneratedColumn<String> bdrDnaCode = GeneratedColumn<String>(
    'bdr_dna_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tournamentTeamId,
    userId,
    userName,
    userNickname,
    profileImageUrl,
    jerseyNumber,
    position,
    role,
    isStarter,
    isActive,
    bdrDnaCode,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_tournament_players';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTournamentPlayer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tournament_team_id')) {
      context.handle(
        _tournamentTeamIdMeta,
        tournamentTeamId.isAcceptableOrUnknown(
          data['tournament_team_id']!,
          _tournamentTeamIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tournamentTeamIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    } else if (isInserting) {
      context.missing(_userNameMeta);
    }
    if (data.containsKey('user_nickname')) {
      context.handle(
        _userNicknameMeta,
        userNickname.isAcceptableOrUnknown(
          data['user_nickname']!,
          _userNicknameMeta,
        ),
      );
    }
    if (data.containsKey('profile_image_url')) {
      context.handle(
        _profileImageUrlMeta,
        profileImageUrl.isAcceptableOrUnknown(
          data['profile_image_url']!,
          _profileImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('jersey_number')) {
      context.handle(
        _jerseyNumberMeta,
        jerseyNumber.isAcceptableOrUnknown(
          data['jersey_number']!,
          _jerseyNumberMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('is_starter')) {
      context.handle(
        _isStarterMeta,
        isStarter.isAcceptableOrUnknown(data['is_starter']!, _isStarterMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('bdr_dna_code')) {
      context.handle(
        _bdrDnaCodeMeta,
        bdrDnaCode.isAcceptableOrUnknown(
          data['bdr_dna_code']!,
          _bdrDnaCodeMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTournamentPlayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTournamentPlayer(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      tournamentTeamId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}tournament_team_id'],
          )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      userName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_name'],
          )!,
      userNickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_nickname'],
      ),
      profileImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_image_url'],
      ),
      jerseyNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jersey_number'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position'],
      ),
      role:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}role'],
          )!,
      isStarter:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_starter'],
          )!,
      isActive:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_active'],
          )!,
      bdrDnaCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bdr_dna_code'],
      ),
      syncedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}synced_at'],
          )!,
    );
  }

  @override
  $LocalTournamentPlayersTable createAlias(String alias) {
    return $LocalTournamentPlayersTable(attachedDatabase, alias);
  }
}

class LocalTournamentPlayer extends DataClass
    implements Insertable<LocalTournamentPlayer> {
  final int id;
  final int tournamentTeamId;
  final int? userId;
  final String userName;
  final String? userNickname;
  final String? profileImageUrl;
  final int? jerseyNumber;
  final String? position;
  final String role;
  final bool isStarter;
  final bool isActive;
  final String? bdrDnaCode;
  final DateTime syncedAt;
  const LocalTournamentPlayer({
    required this.id,
    required this.tournamentTeamId,
    this.userId,
    required this.userName,
    this.userNickname,
    this.profileImageUrl,
    this.jerseyNumber,
    this.position,
    required this.role,
    required this.isStarter,
    required this.isActive,
    this.bdrDnaCode,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tournament_team_id'] = Variable<int>(tournamentTeamId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    map['user_name'] = Variable<String>(userName);
    if (!nullToAbsent || userNickname != null) {
      map['user_nickname'] = Variable<String>(userNickname);
    }
    if (!nullToAbsent || profileImageUrl != null) {
      map['profile_image_url'] = Variable<String>(profileImageUrl);
    }
    if (!nullToAbsent || jerseyNumber != null) {
      map['jersey_number'] = Variable<int>(jerseyNumber);
    }
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<String>(position);
    }
    map['role'] = Variable<String>(role);
    map['is_starter'] = Variable<bool>(isStarter);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || bdrDnaCode != null) {
      map['bdr_dna_code'] = Variable<String>(bdrDnaCode);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LocalTournamentPlayersCompanion toCompanion(bool nullToAbsent) {
    return LocalTournamentPlayersCompanion(
      id: Value(id),
      tournamentTeamId: Value(tournamentTeamId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      userName: Value(userName),
      userNickname:
          userNickname == null && nullToAbsent
              ? const Value.absent()
              : Value(userNickname),
      profileImageUrl:
          profileImageUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(profileImageUrl),
      jerseyNumber:
          jerseyNumber == null && nullToAbsent
              ? const Value.absent()
              : Value(jerseyNumber),
      position:
          position == null && nullToAbsent
              ? const Value.absent()
              : Value(position),
      role: Value(role),
      isStarter: Value(isStarter),
      isActive: Value(isActive),
      bdrDnaCode:
          bdrDnaCode == null && nullToAbsent
              ? const Value.absent()
              : Value(bdrDnaCode),
      syncedAt: Value(syncedAt),
    );
  }

  factory LocalTournamentPlayer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTournamentPlayer(
      id: serializer.fromJson<int>(json['id']),
      tournamentTeamId: serializer.fromJson<int>(json['tournamentTeamId']),
      userId: serializer.fromJson<int?>(json['userId']),
      userName: serializer.fromJson<String>(json['userName']),
      userNickname: serializer.fromJson<String?>(json['userNickname']),
      profileImageUrl: serializer.fromJson<String?>(json['profileImageUrl']),
      jerseyNumber: serializer.fromJson<int?>(json['jerseyNumber']),
      position: serializer.fromJson<String?>(json['position']),
      role: serializer.fromJson<String>(json['role']),
      isStarter: serializer.fromJson<bool>(json['isStarter']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      bdrDnaCode: serializer.fromJson<String?>(json['bdrDnaCode']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tournamentTeamId': serializer.toJson<int>(tournamentTeamId),
      'userId': serializer.toJson<int?>(userId),
      'userName': serializer.toJson<String>(userName),
      'userNickname': serializer.toJson<String?>(userNickname),
      'profileImageUrl': serializer.toJson<String?>(profileImageUrl),
      'jerseyNumber': serializer.toJson<int?>(jerseyNumber),
      'position': serializer.toJson<String?>(position),
      'role': serializer.toJson<String>(role),
      'isStarter': serializer.toJson<bool>(isStarter),
      'isActive': serializer.toJson<bool>(isActive),
      'bdrDnaCode': serializer.toJson<String?>(bdrDnaCode),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  LocalTournamentPlayer copyWith({
    int? id,
    int? tournamentTeamId,
    Value<int?> userId = const Value.absent(),
    String? userName,
    Value<String?> userNickname = const Value.absent(),
    Value<String?> profileImageUrl = const Value.absent(),
    Value<int?> jerseyNumber = const Value.absent(),
    Value<String?> position = const Value.absent(),
    String? role,
    bool? isStarter,
    bool? isActive,
    Value<String?> bdrDnaCode = const Value.absent(),
    DateTime? syncedAt,
  }) => LocalTournamentPlayer(
    id: id ?? this.id,
    tournamentTeamId: tournamentTeamId ?? this.tournamentTeamId,
    userId: userId.present ? userId.value : this.userId,
    userName: userName ?? this.userName,
    userNickname: userNickname.present ? userNickname.value : this.userNickname,
    profileImageUrl:
        profileImageUrl.present ? profileImageUrl.value : this.profileImageUrl,
    jerseyNumber: jerseyNumber.present ? jerseyNumber.value : this.jerseyNumber,
    position: position.present ? position.value : this.position,
    role: role ?? this.role,
    isStarter: isStarter ?? this.isStarter,
    isActive: isActive ?? this.isActive,
    bdrDnaCode: bdrDnaCode.present ? bdrDnaCode.value : this.bdrDnaCode,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  LocalTournamentPlayer copyWithCompanion(
    LocalTournamentPlayersCompanion data,
  ) {
    return LocalTournamentPlayer(
      id: data.id.present ? data.id.value : this.id,
      tournamentTeamId:
          data.tournamentTeamId.present
              ? data.tournamentTeamId.value
              : this.tournamentTeamId,
      userId: data.userId.present ? data.userId.value : this.userId,
      userName: data.userName.present ? data.userName.value : this.userName,
      userNickname:
          data.userNickname.present
              ? data.userNickname.value
              : this.userNickname,
      profileImageUrl:
          data.profileImageUrl.present
              ? data.profileImageUrl.value
              : this.profileImageUrl,
      jerseyNumber:
          data.jerseyNumber.present
              ? data.jerseyNumber.value
              : this.jerseyNumber,
      position: data.position.present ? data.position.value : this.position,
      role: data.role.present ? data.role.value : this.role,
      isStarter: data.isStarter.present ? data.isStarter.value : this.isStarter,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      bdrDnaCode:
          data.bdrDnaCode.present ? data.bdrDnaCode.value : this.bdrDnaCode,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTournamentPlayer(')
          ..write('id: $id, ')
          ..write('tournamentTeamId: $tournamentTeamId, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('userNickname: $userNickname, ')
          ..write('profileImageUrl: $profileImageUrl, ')
          ..write('jerseyNumber: $jerseyNumber, ')
          ..write('position: $position, ')
          ..write('role: $role, ')
          ..write('isStarter: $isStarter, ')
          ..write('isActive: $isActive, ')
          ..write('bdrDnaCode: $bdrDnaCode, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tournamentTeamId,
    userId,
    userName,
    userNickname,
    profileImageUrl,
    jerseyNumber,
    position,
    role,
    isStarter,
    isActive,
    bdrDnaCode,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTournamentPlayer &&
          other.id == this.id &&
          other.tournamentTeamId == this.tournamentTeamId &&
          other.userId == this.userId &&
          other.userName == this.userName &&
          other.userNickname == this.userNickname &&
          other.profileImageUrl == this.profileImageUrl &&
          other.jerseyNumber == this.jerseyNumber &&
          other.position == this.position &&
          other.role == this.role &&
          other.isStarter == this.isStarter &&
          other.isActive == this.isActive &&
          other.bdrDnaCode == this.bdrDnaCode &&
          other.syncedAt == this.syncedAt);
}

class LocalTournamentPlayersCompanion
    extends UpdateCompanion<LocalTournamentPlayer> {
  final Value<int> id;
  final Value<int> tournamentTeamId;
  final Value<int?> userId;
  final Value<String> userName;
  final Value<String?> userNickname;
  final Value<String?> profileImageUrl;
  final Value<int?> jerseyNumber;
  final Value<String?> position;
  final Value<String> role;
  final Value<bool> isStarter;
  final Value<bool> isActive;
  final Value<String?> bdrDnaCode;
  final Value<DateTime> syncedAt;
  const LocalTournamentPlayersCompanion({
    this.id = const Value.absent(),
    this.tournamentTeamId = const Value.absent(),
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.userNickname = const Value.absent(),
    this.profileImageUrl = const Value.absent(),
    this.jerseyNumber = const Value.absent(),
    this.position = const Value.absent(),
    this.role = const Value.absent(),
    this.isStarter = const Value.absent(),
    this.isActive = const Value.absent(),
    this.bdrDnaCode = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  LocalTournamentPlayersCompanion.insert({
    this.id = const Value.absent(),
    required int tournamentTeamId,
    this.userId = const Value.absent(),
    required String userName,
    this.userNickname = const Value.absent(),
    this.profileImageUrl = const Value.absent(),
    this.jerseyNumber = const Value.absent(),
    this.position = const Value.absent(),
    required String role,
    this.isStarter = const Value.absent(),
    this.isActive = const Value.absent(),
    this.bdrDnaCode = const Value.absent(),
    required DateTime syncedAt,
  }) : tournamentTeamId = Value(tournamentTeamId),
       userName = Value(userName),
       role = Value(role),
       syncedAt = Value(syncedAt);
  static Insertable<LocalTournamentPlayer> custom({
    Expression<int>? id,
    Expression<int>? tournamentTeamId,
    Expression<int>? userId,
    Expression<String>? userName,
    Expression<String>? userNickname,
    Expression<String>? profileImageUrl,
    Expression<int>? jerseyNumber,
    Expression<String>? position,
    Expression<String>? role,
    Expression<bool>? isStarter,
    Expression<bool>? isActive,
    Expression<String>? bdrDnaCode,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tournamentTeamId != null) 'tournament_team_id': tournamentTeamId,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (userNickname != null) 'user_nickname': userNickname,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (jerseyNumber != null) 'jersey_number': jerseyNumber,
      if (position != null) 'position': position,
      if (role != null) 'role': role,
      if (isStarter != null) 'is_starter': isStarter,
      if (isActive != null) 'is_active': isActive,
      if (bdrDnaCode != null) 'bdr_dna_code': bdrDnaCode,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  LocalTournamentPlayersCompanion copyWith({
    Value<int>? id,
    Value<int>? tournamentTeamId,
    Value<int?>? userId,
    Value<String>? userName,
    Value<String?>? userNickname,
    Value<String?>? profileImageUrl,
    Value<int?>? jerseyNumber,
    Value<String?>? position,
    Value<String>? role,
    Value<bool>? isStarter,
    Value<bool>? isActive,
    Value<String?>? bdrDnaCode,
    Value<DateTime>? syncedAt,
  }) {
    return LocalTournamentPlayersCompanion(
      id: id ?? this.id,
      tournamentTeamId: tournamentTeamId ?? this.tournamentTeamId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userNickname: userNickname ?? this.userNickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      position: position ?? this.position,
      role: role ?? this.role,
      isStarter: isStarter ?? this.isStarter,
      isActive: isActive ?? this.isActive,
      bdrDnaCode: bdrDnaCode ?? this.bdrDnaCode,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tournamentTeamId.present) {
      map['tournament_team_id'] = Variable<int>(tournamentTeamId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (userNickname.present) {
      map['user_nickname'] = Variable<String>(userNickname.value);
    }
    if (profileImageUrl.present) {
      map['profile_image_url'] = Variable<String>(profileImageUrl.value);
    }
    if (jerseyNumber.present) {
      map['jersey_number'] = Variable<int>(jerseyNumber.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (isStarter.present) {
      map['is_starter'] = Variable<bool>(isStarter.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (bdrDnaCode.present) {
      map['bdr_dna_code'] = Variable<String>(bdrDnaCode.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTournamentPlayersCompanion(')
          ..write('id: $id, ')
          ..write('tournamentTeamId: $tournamentTeamId, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('userNickname: $userNickname, ')
          ..write('profileImageUrl: $profileImageUrl, ')
          ..write('jerseyNumber: $jerseyNumber, ')
          ..write('position: $position, ')
          ..write('role: $role, ')
          ..write('isStarter: $isStarter, ')
          ..write('isActive: $isActive, ')
          ..write('bdrDnaCode: $bdrDnaCode, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalMatchesTable extends LocalMatches
    with TableInfo<$LocalMatchesTable, LocalMatche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMatchesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverUuidMeta = const VerificationMeta(
    'serverUuid',
  );
  @override
  late final GeneratedColumn<String> serverUuid = GeneratedColumn<String>(
    'server_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localUuidMeta = const VerificationMeta(
    'localUuid',
  );
  @override
  late final GeneratedColumn<String> localUuid = GeneratedColumn<String>(
    'local_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tournamentIdMeta = const VerificationMeta(
    'tournamentId',
  );
  @override
  late final GeneratedColumn<String> tournamentId = GeneratedColumn<String>(
    'tournament_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeTeamIdMeta = const VerificationMeta(
    'homeTeamId',
  );
  @override
  late final GeneratedColumn<int> homeTeamId = GeneratedColumn<int>(
    'home_team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _awayTeamIdMeta = const VerificationMeta(
    'awayTeamId',
  );
  @override
  late final GeneratedColumn<int> awayTeamId = GeneratedColumn<int>(
    'away_team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeTeamNameMeta = const VerificationMeta(
    'homeTeamName',
  );
  @override
  late final GeneratedColumn<String> homeTeamName = GeneratedColumn<String>(
    'home_team_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _awayTeamNameMeta = const VerificationMeta(
    'awayTeamName',
  );
  @override
  late final GeneratedColumn<String> awayTeamName = GeneratedColumn<String>(
    'away_team_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeScoreMeta = const VerificationMeta(
    'homeScore',
  );
  @override
  late final GeneratedColumn<int> homeScore = GeneratedColumn<int>(
    'home_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _awayScoreMeta = const VerificationMeta(
    'awayScore',
  );
  @override
  late final GeneratedColumn<int> awayScore = GeneratedColumn<int>(
    'away_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quarterScoresJsonMeta = const VerificationMeta(
    'quarterScoresJson',
  );
  @override
  late final GeneratedColumn<String> quarterScoresJson =
      GeneratedColumn<String>(
        'quarter_scores_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _currentQuarterMeta = const VerificationMeta(
    'currentQuarter',
  );
  @override
  late final GeneratedColumn<int> currentQuarter = GeneratedColumn<int>(
    'current_quarter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _gameClockSecondsMeta = const VerificationMeta(
    'gameClockSeconds',
  );
  @override
  late final GeneratedColumn<int> gameClockSeconds = GeneratedColumn<int>(
    'game_clock_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(600),
  );
  static const VerificationMeta _shotClockSecondsMeta = const VerificationMeta(
    'shotClockSeconds',
  );
  @override
  late final GeneratedColumn<int> shotClockSeconds = GeneratedColumn<int>(
    'shot_clock_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(24),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('scheduled'),
  );
  static const VerificationMeta _teamFoulsJsonMeta = const VerificationMeta(
    'teamFoulsJson',
  );
  @override
  late final GeneratedColumn<String> teamFoulsJson = GeneratedColumn<String>(
    'team_fouls_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _homeTimeoutsRemainingMeta =
      const VerificationMeta('homeTimeoutsRemaining');
  @override
  late final GeneratedColumn<int> homeTimeoutsRemaining = GeneratedColumn<int>(
    'home_timeouts_remaining',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _awayTimeoutsRemainingMeta =
      const VerificationMeta('awayTimeoutsRemaining');
  @override
  late final GeneratedColumn<int> awayTimeoutsRemaining = GeneratedColumn<int>(
    'away_timeouts_remaining',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _roundNameMeta = const VerificationMeta(
    'roundName',
  );
  @override
  late final GeneratedColumn<String> roundName = GeneratedColumn<String>(
    'round_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roundNumberMeta = const VerificationMeta(
    'roundNumber',
  );
  @override
  late final GeneratedColumn<int> roundNumber = GeneratedColumn<int>(
    'round_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mvpPlayerIdMeta = const VerificationMeta(
    'mvpPlayerId',
  );
  @override
  late final GeneratedColumn<int> mvpPlayerId = GeneratedColumn<int>(
    'mvp_player_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    serverUuid,
    localUuid,
    tournamentId,
    homeTeamId,
    awayTeamId,
    homeTeamName,
    awayTeamName,
    homeScore,
    awayScore,
    quarterScoresJson,
    currentQuarter,
    gameClockSeconds,
    shotClockSeconds,
    status,
    teamFoulsJson,
    homeTimeoutsRemaining,
    awayTimeoutsRemaining,
    roundName,
    roundNumber,
    groupName,
    mvpPlayerId,
    scheduledAt,
    startedAt,
    endedAt,
    isSynced,
    syncedAt,
    syncError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_matches';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMatche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('server_uuid')) {
      context.handle(
        _serverUuidMeta,
        serverUuid.isAcceptableOrUnknown(data['server_uuid']!, _serverUuidMeta),
      );
    }
    if (data.containsKey('local_uuid')) {
      context.handle(
        _localUuidMeta,
        localUuid.isAcceptableOrUnknown(data['local_uuid']!, _localUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_localUuidMeta);
    }
    if (data.containsKey('tournament_id')) {
      context.handle(
        _tournamentIdMeta,
        tournamentId.isAcceptableOrUnknown(
          data['tournament_id']!,
          _tournamentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tournamentIdMeta);
    }
    if (data.containsKey('home_team_id')) {
      context.handle(
        _homeTeamIdMeta,
        homeTeamId.isAcceptableOrUnknown(
          data['home_team_id']!,
          _homeTeamIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_homeTeamIdMeta);
    }
    if (data.containsKey('away_team_id')) {
      context.handle(
        _awayTeamIdMeta,
        awayTeamId.isAcceptableOrUnknown(
          data['away_team_id']!,
          _awayTeamIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_awayTeamIdMeta);
    }
    if (data.containsKey('home_team_name')) {
      context.handle(
        _homeTeamNameMeta,
        homeTeamName.isAcceptableOrUnknown(
          data['home_team_name']!,
          _homeTeamNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_homeTeamNameMeta);
    }
    if (data.containsKey('away_team_name')) {
      context.handle(
        _awayTeamNameMeta,
        awayTeamName.isAcceptableOrUnknown(
          data['away_team_name']!,
          _awayTeamNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_awayTeamNameMeta);
    }
    if (data.containsKey('home_score')) {
      context.handle(
        _homeScoreMeta,
        homeScore.isAcceptableOrUnknown(data['home_score']!, _homeScoreMeta),
      );
    }
    if (data.containsKey('away_score')) {
      context.handle(
        _awayScoreMeta,
        awayScore.isAcceptableOrUnknown(data['away_score']!, _awayScoreMeta),
      );
    }
    if (data.containsKey('quarter_scores_json')) {
      context.handle(
        _quarterScoresJsonMeta,
        quarterScoresJson.isAcceptableOrUnknown(
          data['quarter_scores_json']!,
          _quarterScoresJsonMeta,
        ),
      );
    }
    if (data.containsKey('current_quarter')) {
      context.handle(
        _currentQuarterMeta,
        currentQuarter.isAcceptableOrUnknown(
          data['current_quarter']!,
          _currentQuarterMeta,
        ),
      );
    }
    if (data.containsKey('game_clock_seconds')) {
      context.handle(
        _gameClockSecondsMeta,
        gameClockSeconds.isAcceptableOrUnknown(
          data['game_clock_seconds']!,
          _gameClockSecondsMeta,
        ),
      );
    }
    if (data.containsKey('shot_clock_seconds')) {
      context.handle(
        _shotClockSecondsMeta,
        shotClockSeconds.isAcceptableOrUnknown(
          data['shot_clock_seconds']!,
          _shotClockSecondsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('team_fouls_json')) {
      context.handle(
        _teamFoulsJsonMeta,
        teamFoulsJson.isAcceptableOrUnknown(
          data['team_fouls_json']!,
          _teamFoulsJsonMeta,
        ),
      );
    }
    if (data.containsKey('home_timeouts_remaining')) {
      context.handle(
        _homeTimeoutsRemainingMeta,
        homeTimeoutsRemaining.isAcceptableOrUnknown(
          data['home_timeouts_remaining']!,
          _homeTimeoutsRemainingMeta,
        ),
      );
    }
    if (data.containsKey('away_timeouts_remaining')) {
      context.handle(
        _awayTimeoutsRemainingMeta,
        awayTimeoutsRemaining.isAcceptableOrUnknown(
          data['away_timeouts_remaining']!,
          _awayTimeoutsRemainingMeta,
        ),
      );
    }
    if (data.containsKey('round_name')) {
      context.handle(
        _roundNameMeta,
        roundName.isAcceptableOrUnknown(data['round_name']!, _roundNameMeta),
      );
    }
    if (data.containsKey('round_number')) {
      context.handle(
        _roundNumberMeta,
        roundNumber.isAcceptableOrUnknown(
          data['round_number']!,
          _roundNumberMeta,
        ),
      );
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    if (data.containsKey('mvp_player_id')) {
      context.handle(
        _mvpPlayerIdMeta,
        mvpPlayerId.isAcceptableOrUnknown(
          data['mvp_player_id']!,
          _mvpPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMatche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMatche(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      serverUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_uuid'],
      ),
      localUuid:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}local_uuid'],
          )!,
      tournamentId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}tournament_id'],
          )!,
      homeTeamId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}home_team_id'],
          )!,
      awayTeamId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}away_team_id'],
          )!,
      homeTeamName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}home_team_name'],
          )!,
      awayTeamName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}away_team_name'],
          )!,
      homeScore:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}home_score'],
          )!,
      awayScore:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}away_score'],
          )!,
      quarterScoresJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}quarter_scores_json'],
          )!,
      currentQuarter:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}current_quarter'],
          )!,
      gameClockSeconds:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}game_clock_seconds'],
          )!,
      shotClockSeconds:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}shot_clock_seconds'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      teamFoulsJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}team_fouls_json'],
          )!,
      homeTimeoutsRemaining:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}home_timeouts_remaining'],
          )!,
      awayTimeoutsRemaining:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}away_timeouts_remaining'],
          )!,
      roundName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}round_name'],
      ),
      roundNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_number'],
      ),
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      ),
      mvpPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mvp_player_id'],
      ),
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      isSynced:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_synced'],
          )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $LocalMatchesTable createAlias(String alias) {
    return $LocalMatchesTable(attachedDatabase, alias);
  }
}

class LocalMatche extends DataClass implements Insertable<LocalMatche> {
  final int id;
  final int? serverId;
  final String? serverUuid;
  final String localUuid;
  final String tournamentId;
  final int homeTeamId;
  final int awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final String quarterScoresJson;
  final int currentQuarter;
  final int gameClockSeconds;
  final int shotClockSeconds;
  final String status;
  final String teamFoulsJson;
  final int homeTimeoutsRemaining;
  final int awayTimeoutsRemaining;
  final String? roundName;
  final int? roundNumber;
  final String? groupName;
  final int? mvpPlayerId;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool isSynced;
  final DateTime? syncedAt;
  final String? syncError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalMatche({
    required this.id,
    this.serverId,
    this.serverUuid,
    required this.localUuid,
    required this.tournamentId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.quarterScoresJson,
    required this.currentQuarter,
    required this.gameClockSeconds,
    required this.shotClockSeconds,
    required this.status,
    required this.teamFoulsJson,
    required this.homeTimeoutsRemaining,
    required this.awayTimeoutsRemaining,
    this.roundName,
    this.roundNumber,
    this.groupName,
    this.mvpPlayerId,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    required this.isSynced,
    this.syncedAt,
    this.syncError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || serverUuid != null) {
      map['server_uuid'] = Variable<String>(serverUuid);
    }
    map['local_uuid'] = Variable<String>(localUuid);
    map['tournament_id'] = Variable<String>(tournamentId);
    map['home_team_id'] = Variable<int>(homeTeamId);
    map['away_team_id'] = Variable<int>(awayTeamId);
    map['home_team_name'] = Variable<String>(homeTeamName);
    map['away_team_name'] = Variable<String>(awayTeamName);
    map['home_score'] = Variable<int>(homeScore);
    map['away_score'] = Variable<int>(awayScore);
    map['quarter_scores_json'] = Variable<String>(quarterScoresJson);
    map['current_quarter'] = Variable<int>(currentQuarter);
    map['game_clock_seconds'] = Variable<int>(gameClockSeconds);
    map['shot_clock_seconds'] = Variable<int>(shotClockSeconds);
    map['status'] = Variable<String>(status);
    map['team_fouls_json'] = Variable<String>(teamFoulsJson);
    map['home_timeouts_remaining'] = Variable<int>(homeTimeoutsRemaining);
    map['away_timeouts_remaining'] = Variable<int>(awayTimeoutsRemaining);
    if (!nullToAbsent || roundName != null) {
      map['round_name'] = Variable<String>(roundName);
    }
    if (!nullToAbsent || roundNumber != null) {
      map['round_number'] = Variable<int>(roundNumber);
    }
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    if (!nullToAbsent || mvpPlayerId != null) {
      map['mvp_player_id'] = Variable<int>(mvpPlayerId);
    }
    if (!nullToAbsent || scheduledAt != null) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalMatchesCompanion toCompanion(bool nullToAbsent) {
    return LocalMatchesCompanion(
      id: Value(id),
      serverId:
          serverId == null && nullToAbsent
              ? const Value.absent()
              : Value(serverId),
      serverUuid:
          serverUuid == null && nullToAbsent
              ? const Value.absent()
              : Value(serverUuid),
      localUuid: Value(localUuid),
      tournamentId: Value(tournamentId),
      homeTeamId: Value(homeTeamId),
      awayTeamId: Value(awayTeamId),
      homeTeamName: Value(homeTeamName),
      awayTeamName: Value(awayTeamName),
      homeScore: Value(homeScore),
      awayScore: Value(awayScore),
      quarterScoresJson: Value(quarterScoresJson),
      currentQuarter: Value(currentQuarter),
      gameClockSeconds: Value(gameClockSeconds),
      shotClockSeconds: Value(shotClockSeconds),
      status: Value(status),
      teamFoulsJson: Value(teamFoulsJson),
      homeTimeoutsRemaining: Value(homeTimeoutsRemaining),
      awayTimeoutsRemaining: Value(awayTimeoutsRemaining),
      roundName:
          roundName == null && nullToAbsent
              ? const Value.absent()
              : Value(roundName),
      roundNumber:
          roundNumber == null && nullToAbsent
              ? const Value.absent()
              : Value(roundNumber),
      groupName:
          groupName == null && nullToAbsent
              ? const Value.absent()
              : Value(groupName),
      mvpPlayerId:
          mvpPlayerId == null && nullToAbsent
              ? const Value.absent()
              : Value(mvpPlayerId),
      scheduledAt:
          scheduledAt == null && nullToAbsent
              ? const Value.absent()
              : Value(scheduledAt),
      startedAt:
          startedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(startedAt),
      endedAt:
          endedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(endedAt),
      isSynced: Value(isSynced),
      syncedAt:
          syncedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(syncedAt),
      syncError:
          syncError == null && nullToAbsent
              ? const Value.absent()
              : Value(syncError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMatche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMatche(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      serverUuid: serializer.fromJson<String?>(json['serverUuid']),
      localUuid: serializer.fromJson<String>(json['localUuid']),
      tournamentId: serializer.fromJson<String>(json['tournamentId']),
      homeTeamId: serializer.fromJson<int>(json['homeTeamId']),
      awayTeamId: serializer.fromJson<int>(json['awayTeamId']),
      homeTeamName: serializer.fromJson<String>(json['homeTeamName']),
      awayTeamName: serializer.fromJson<String>(json['awayTeamName']),
      homeScore: serializer.fromJson<int>(json['homeScore']),
      awayScore: serializer.fromJson<int>(json['awayScore']),
      quarterScoresJson: serializer.fromJson<String>(json['quarterScoresJson']),
      currentQuarter: serializer.fromJson<int>(json['currentQuarter']),
      gameClockSeconds: serializer.fromJson<int>(json['gameClockSeconds']),
      shotClockSeconds: serializer.fromJson<int>(json['shotClockSeconds']),
      status: serializer.fromJson<String>(json['status']),
      teamFoulsJson: serializer.fromJson<String>(json['teamFoulsJson']),
      homeTimeoutsRemaining: serializer.fromJson<int>(
        json['homeTimeoutsRemaining'],
      ),
      awayTimeoutsRemaining: serializer.fromJson<int>(
        json['awayTimeoutsRemaining'],
      ),
      roundName: serializer.fromJson<String?>(json['roundName']),
      roundNumber: serializer.fromJson<int?>(json['roundNumber']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      mvpPlayerId: serializer.fromJson<int?>(json['mvpPlayerId']),
      scheduledAt: serializer.fromJson<DateTime?>(json['scheduledAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'serverUuid': serializer.toJson<String?>(serverUuid),
      'localUuid': serializer.toJson<String>(localUuid),
      'tournamentId': serializer.toJson<String>(tournamentId),
      'homeTeamId': serializer.toJson<int>(homeTeamId),
      'awayTeamId': serializer.toJson<int>(awayTeamId),
      'homeTeamName': serializer.toJson<String>(homeTeamName),
      'awayTeamName': serializer.toJson<String>(awayTeamName),
      'homeScore': serializer.toJson<int>(homeScore),
      'awayScore': serializer.toJson<int>(awayScore),
      'quarterScoresJson': serializer.toJson<String>(quarterScoresJson),
      'currentQuarter': serializer.toJson<int>(currentQuarter),
      'gameClockSeconds': serializer.toJson<int>(gameClockSeconds),
      'shotClockSeconds': serializer.toJson<int>(shotClockSeconds),
      'status': serializer.toJson<String>(status),
      'teamFoulsJson': serializer.toJson<String>(teamFoulsJson),
      'homeTimeoutsRemaining': serializer.toJson<int>(homeTimeoutsRemaining),
      'awayTimeoutsRemaining': serializer.toJson<int>(awayTimeoutsRemaining),
      'roundName': serializer.toJson<String?>(roundName),
      'roundNumber': serializer.toJson<int?>(roundNumber),
      'groupName': serializer.toJson<String?>(groupName),
      'mvpPlayerId': serializer.toJson<int?>(mvpPlayerId),
      'scheduledAt': serializer.toJson<DateTime?>(scheduledAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'syncError': serializer.toJson<String?>(syncError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalMatche copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    Value<String?> serverUuid = const Value.absent(),
    String? localUuid,
    String? tournamentId,
    int? homeTeamId,
    int? awayTeamId,
    String? homeTeamName,
    String? awayTeamName,
    int? homeScore,
    int? awayScore,
    String? quarterScoresJson,
    int? currentQuarter,
    int? gameClockSeconds,
    int? shotClockSeconds,
    String? status,
    String? teamFoulsJson,
    int? homeTimeoutsRemaining,
    int? awayTimeoutsRemaining,
    Value<String?> roundName = const Value.absent(),
    Value<int?> roundNumber = const Value.absent(),
    Value<String?> groupName = const Value.absent(),
    Value<int?> mvpPlayerId = const Value.absent(),
    Value<DateTime?> scheduledAt = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    bool? isSynced,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalMatche(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    serverUuid: serverUuid.present ? serverUuid.value : this.serverUuid,
    localUuid: localUuid ?? this.localUuid,
    tournamentId: tournamentId ?? this.tournamentId,
    homeTeamId: homeTeamId ?? this.homeTeamId,
    awayTeamId: awayTeamId ?? this.awayTeamId,
    homeTeamName: homeTeamName ?? this.homeTeamName,
    awayTeamName: awayTeamName ?? this.awayTeamName,
    homeScore: homeScore ?? this.homeScore,
    awayScore: awayScore ?? this.awayScore,
    quarterScoresJson: quarterScoresJson ?? this.quarterScoresJson,
    currentQuarter: currentQuarter ?? this.currentQuarter,
    gameClockSeconds: gameClockSeconds ?? this.gameClockSeconds,
    shotClockSeconds: shotClockSeconds ?? this.shotClockSeconds,
    status: status ?? this.status,
    teamFoulsJson: teamFoulsJson ?? this.teamFoulsJson,
    homeTimeoutsRemaining: homeTimeoutsRemaining ?? this.homeTimeoutsRemaining,
    awayTimeoutsRemaining: awayTimeoutsRemaining ?? this.awayTimeoutsRemaining,
    roundName: roundName.present ? roundName.value : this.roundName,
    roundNumber: roundNumber.present ? roundNumber.value : this.roundNumber,
    groupName: groupName.present ? groupName.value : this.groupName,
    mvpPlayerId: mvpPlayerId.present ? mvpPlayerId.value : this.mvpPlayerId,
    scheduledAt: scheduledAt.present ? scheduledAt.value : this.scheduledAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    isSynced: isSynced ?? this.isSynced,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    syncError: syncError.present ? syncError.value : this.syncError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalMatche copyWithCompanion(LocalMatchesCompanion data) {
    return LocalMatche(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      serverUuid:
          data.serverUuid.present ? data.serverUuid.value : this.serverUuid,
      localUuid: data.localUuid.present ? data.localUuid.value : this.localUuid,
      tournamentId:
          data.tournamentId.present
              ? data.tournamentId.value
              : this.tournamentId,
      homeTeamId:
          data.homeTeamId.present ? data.homeTeamId.value : this.homeTeamId,
      awayTeamId:
          data.awayTeamId.present ? data.awayTeamId.value : this.awayTeamId,
      homeTeamName:
          data.homeTeamName.present
              ? data.homeTeamName.value
              : this.homeTeamName,
      awayTeamName:
          data.awayTeamName.present
              ? data.awayTeamName.value
              : this.awayTeamName,
      homeScore: data.homeScore.present ? data.homeScore.value : this.homeScore,
      awayScore: data.awayScore.present ? data.awayScore.value : this.awayScore,
      quarterScoresJson:
          data.quarterScoresJson.present
              ? data.quarterScoresJson.value
              : this.quarterScoresJson,
      currentQuarter:
          data.currentQuarter.present
              ? data.currentQuarter.value
              : this.currentQuarter,
      gameClockSeconds:
          data.gameClockSeconds.present
              ? data.gameClockSeconds.value
              : this.gameClockSeconds,
      shotClockSeconds:
          data.shotClockSeconds.present
              ? data.shotClockSeconds.value
              : this.shotClockSeconds,
      status: data.status.present ? data.status.value : this.status,
      teamFoulsJson:
          data.teamFoulsJson.present
              ? data.teamFoulsJson.value
              : this.teamFoulsJson,
      homeTimeoutsRemaining:
          data.homeTimeoutsRemaining.present
              ? data.homeTimeoutsRemaining.value
              : this.homeTimeoutsRemaining,
      awayTimeoutsRemaining:
          data.awayTimeoutsRemaining.present
              ? data.awayTimeoutsRemaining.value
              : this.awayTimeoutsRemaining,
      roundName: data.roundName.present ? data.roundName.value : this.roundName,
      roundNumber:
          data.roundNumber.present ? data.roundNumber.value : this.roundNumber,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      mvpPlayerId:
          data.mvpPlayerId.present ? data.mvpPlayerId.value : this.mvpPlayerId,
      scheduledAt:
          data.scheduledAt.present ? data.scheduledAt.value : this.scheduledAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMatche(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('serverUuid: $serverUuid, ')
          ..write('localUuid: $localUuid, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('homeTeamId: $homeTeamId, ')
          ..write('awayTeamId: $awayTeamId, ')
          ..write('homeTeamName: $homeTeamName, ')
          ..write('awayTeamName: $awayTeamName, ')
          ..write('homeScore: $homeScore, ')
          ..write('awayScore: $awayScore, ')
          ..write('quarterScoresJson: $quarterScoresJson, ')
          ..write('currentQuarter: $currentQuarter, ')
          ..write('gameClockSeconds: $gameClockSeconds, ')
          ..write('shotClockSeconds: $shotClockSeconds, ')
          ..write('status: $status, ')
          ..write('teamFoulsJson: $teamFoulsJson, ')
          ..write('homeTimeoutsRemaining: $homeTimeoutsRemaining, ')
          ..write('awayTimeoutsRemaining: $awayTimeoutsRemaining, ')
          ..write('roundName: $roundName, ')
          ..write('roundNumber: $roundNumber, ')
          ..write('groupName: $groupName, ')
          ..write('mvpPlayerId: $mvpPlayerId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    serverId,
    serverUuid,
    localUuid,
    tournamentId,
    homeTeamId,
    awayTeamId,
    homeTeamName,
    awayTeamName,
    homeScore,
    awayScore,
    quarterScoresJson,
    currentQuarter,
    gameClockSeconds,
    shotClockSeconds,
    status,
    teamFoulsJson,
    homeTimeoutsRemaining,
    awayTimeoutsRemaining,
    roundName,
    roundNumber,
    groupName,
    mvpPlayerId,
    scheduledAt,
    startedAt,
    endedAt,
    isSynced,
    syncedAt,
    syncError,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMatche &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.serverUuid == this.serverUuid &&
          other.localUuid == this.localUuid &&
          other.tournamentId == this.tournamentId &&
          other.homeTeamId == this.homeTeamId &&
          other.awayTeamId == this.awayTeamId &&
          other.homeTeamName == this.homeTeamName &&
          other.awayTeamName == this.awayTeamName &&
          other.homeScore == this.homeScore &&
          other.awayScore == this.awayScore &&
          other.quarterScoresJson == this.quarterScoresJson &&
          other.currentQuarter == this.currentQuarter &&
          other.gameClockSeconds == this.gameClockSeconds &&
          other.shotClockSeconds == this.shotClockSeconds &&
          other.status == this.status &&
          other.teamFoulsJson == this.teamFoulsJson &&
          other.homeTimeoutsRemaining == this.homeTimeoutsRemaining &&
          other.awayTimeoutsRemaining == this.awayTimeoutsRemaining &&
          other.roundName == this.roundName &&
          other.roundNumber == this.roundNumber &&
          other.groupName == this.groupName &&
          other.mvpPlayerId == this.mvpPlayerId &&
          other.scheduledAt == this.scheduledAt &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.isSynced == this.isSynced &&
          other.syncedAt == this.syncedAt &&
          other.syncError == this.syncError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalMatchesCompanion extends UpdateCompanion<LocalMatche> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String?> serverUuid;
  final Value<String> localUuid;
  final Value<String> tournamentId;
  final Value<int> homeTeamId;
  final Value<int> awayTeamId;
  final Value<String> homeTeamName;
  final Value<String> awayTeamName;
  final Value<int> homeScore;
  final Value<int> awayScore;
  final Value<String> quarterScoresJson;
  final Value<int> currentQuarter;
  final Value<int> gameClockSeconds;
  final Value<int> shotClockSeconds;
  final Value<String> status;
  final Value<String> teamFoulsJson;
  final Value<int> homeTimeoutsRemaining;
  final Value<int> awayTimeoutsRemaining;
  final Value<String?> roundName;
  final Value<int?> roundNumber;
  final Value<String?> groupName;
  final Value<int?> mvpPlayerId;
  final Value<DateTime?> scheduledAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> endedAt;
  final Value<bool> isSynced;
  final Value<DateTime?> syncedAt;
  final Value<String?> syncError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LocalMatchesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.serverUuid = const Value.absent(),
    this.localUuid = const Value.absent(),
    this.tournamentId = const Value.absent(),
    this.homeTeamId = const Value.absent(),
    this.awayTeamId = const Value.absent(),
    this.homeTeamName = const Value.absent(),
    this.awayTeamName = const Value.absent(),
    this.homeScore = const Value.absent(),
    this.awayScore = const Value.absent(),
    this.quarterScoresJson = const Value.absent(),
    this.currentQuarter = const Value.absent(),
    this.gameClockSeconds = const Value.absent(),
    this.shotClockSeconds = const Value.absent(),
    this.status = const Value.absent(),
    this.teamFoulsJson = const Value.absent(),
    this.homeTimeoutsRemaining = const Value.absent(),
    this.awayTimeoutsRemaining = const Value.absent(),
    this.roundName = const Value.absent(),
    this.roundNumber = const Value.absent(),
    this.groupName = const Value.absent(),
    this.mvpPlayerId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalMatchesCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.serverUuid = const Value.absent(),
    required String localUuid,
    required String tournamentId,
    required int homeTeamId,
    required int awayTeamId,
    required String homeTeamName,
    required String awayTeamName,
    this.homeScore = const Value.absent(),
    this.awayScore = const Value.absent(),
    this.quarterScoresJson = const Value.absent(),
    this.currentQuarter = const Value.absent(),
    this.gameClockSeconds = const Value.absent(),
    this.shotClockSeconds = const Value.absent(),
    this.status = const Value.absent(),
    this.teamFoulsJson = const Value.absent(),
    this.homeTimeoutsRemaining = const Value.absent(),
    this.awayTimeoutsRemaining = const Value.absent(),
    this.roundName = const Value.absent(),
    this.roundNumber = const Value.absent(),
    this.groupName = const Value.absent(),
    this.mvpPlayerId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : localUuid = Value(localUuid),
       tournamentId = Value(tournamentId),
       homeTeamId = Value(homeTeamId),
       awayTeamId = Value(awayTeamId),
       homeTeamName = Value(homeTeamName),
       awayTeamName = Value(awayTeamName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalMatche> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? serverUuid,
    Expression<String>? localUuid,
    Expression<String>? tournamentId,
    Expression<int>? homeTeamId,
    Expression<int>? awayTeamId,
    Expression<String>? homeTeamName,
    Expression<String>? awayTeamName,
    Expression<int>? homeScore,
    Expression<int>? awayScore,
    Expression<String>? quarterScoresJson,
    Expression<int>? currentQuarter,
    Expression<int>? gameClockSeconds,
    Expression<int>? shotClockSeconds,
    Expression<String>? status,
    Expression<String>? teamFoulsJson,
    Expression<int>? homeTimeoutsRemaining,
    Expression<int>? awayTimeoutsRemaining,
    Expression<String>? roundName,
    Expression<int>? roundNumber,
    Expression<String>? groupName,
    Expression<int>? mvpPlayerId,
    Expression<DateTime>? scheduledAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<bool>? isSynced,
    Expression<DateTime>? syncedAt,
    Expression<String>? syncError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (serverUuid != null) 'server_uuid': serverUuid,
      if (localUuid != null) 'local_uuid': localUuid,
      if (tournamentId != null) 'tournament_id': tournamentId,
      if (homeTeamId != null) 'home_team_id': homeTeamId,
      if (awayTeamId != null) 'away_team_id': awayTeamId,
      if (homeTeamName != null) 'home_team_name': homeTeamName,
      if (awayTeamName != null) 'away_team_name': awayTeamName,
      if (homeScore != null) 'home_score': homeScore,
      if (awayScore != null) 'away_score': awayScore,
      if (quarterScoresJson != null) 'quarter_scores_json': quarterScoresJson,
      if (currentQuarter != null) 'current_quarter': currentQuarter,
      if (gameClockSeconds != null) 'game_clock_seconds': gameClockSeconds,
      if (shotClockSeconds != null) 'shot_clock_seconds': shotClockSeconds,
      if (status != null) 'status': status,
      if (teamFoulsJson != null) 'team_fouls_json': teamFoulsJson,
      if (homeTimeoutsRemaining != null)
        'home_timeouts_remaining': homeTimeoutsRemaining,
      if (awayTimeoutsRemaining != null)
        'away_timeouts_remaining': awayTimeoutsRemaining,
      if (roundName != null) 'round_name': roundName,
      if (roundNumber != null) 'round_number': roundNumber,
      if (groupName != null) 'group_name': groupName,
      if (mvpPlayerId != null) 'mvp_player_id': mvpPlayerId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (syncError != null) 'sync_error': syncError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalMatchesCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String?>? serverUuid,
    Value<String>? localUuid,
    Value<String>? tournamentId,
    Value<int>? homeTeamId,
    Value<int>? awayTeamId,
    Value<String>? homeTeamName,
    Value<String>? awayTeamName,
    Value<int>? homeScore,
    Value<int>? awayScore,
    Value<String>? quarterScoresJson,
    Value<int>? currentQuarter,
    Value<int>? gameClockSeconds,
    Value<int>? shotClockSeconds,
    Value<String>? status,
    Value<String>? teamFoulsJson,
    Value<int>? homeTimeoutsRemaining,
    Value<int>? awayTimeoutsRemaining,
    Value<String?>? roundName,
    Value<int?>? roundNumber,
    Value<String?>? groupName,
    Value<int?>? mvpPlayerId,
    Value<DateTime?>? scheduledAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? endedAt,
    Value<bool>? isSynced,
    Value<DateTime?>? syncedAt,
    Value<String?>? syncError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return LocalMatchesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      serverUuid: serverUuid ?? this.serverUuid,
      localUuid: localUuid ?? this.localUuid,
      tournamentId: tournamentId ?? this.tournamentId,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      quarterScoresJson: quarterScoresJson ?? this.quarterScoresJson,
      currentQuarter: currentQuarter ?? this.currentQuarter,
      gameClockSeconds: gameClockSeconds ?? this.gameClockSeconds,
      shotClockSeconds: shotClockSeconds ?? this.shotClockSeconds,
      status: status ?? this.status,
      teamFoulsJson: teamFoulsJson ?? this.teamFoulsJson,
      homeTimeoutsRemaining:
          homeTimeoutsRemaining ?? this.homeTimeoutsRemaining,
      awayTimeoutsRemaining:
          awayTimeoutsRemaining ?? this.awayTimeoutsRemaining,
      roundName: roundName ?? this.roundName,
      roundNumber: roundNumber ?? this.roundNumber,
      groupName: groupName ?? this.groupName,
      mvpPlayerId: mvpPlayerId ?? this.mvpPlayerId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (serverUuid.present) {
      map['server_uuid'] = Variable<String>(serverUuid.value);
    }
    if (localUuid.present) {
      map['local_uuid'] = Variable<String>(localUuid.value);
    }
    if (tournamentId.present) {
      map['tournament_id'] = Variable<String>(tournamentId.value);
    }
    if (homeTeamId.present) {
      map['home_team_id'] = Variable<int>(homeTeamId.value);
    }
    if (awayTeamId.present) {
      map['away_team_id'] = Variable<int>(awayTeamId.value);
    }
    if (homeTeamName.present) {
      map['home_team_name'] = Variable<String>(homeTeamName.value);
    }
    if (awayTeamName.present) {
      map['away_team_name'] = Variable<String>(awayTeamName.value);
    }
    if (homeScore.present) {
      map['home_score'] = Variable<int>(homeScore.value);
    }
    if (awayScore.present) {
      map['away_score'] = Variable<int>(awayScore.value);
    }
    if (quarterScoresJson.present) {
      map['quarter_scores_json'] = Variable<String>(quarterScoresJson.value);
    }
    if (currentQuarter.present) {
      map['current_quarter'] = Variable<int>(currentQuarter.value);
    }
    if (gameClockSeconds.present) {
      map['game_clock_seconds'] = Variable<int>(gameClockSeconds.value);
    }
    if (shotClockSeconds.present) {
      map['shot_clock_seconds'] = Variable<int>(shotClockSeconds.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (teamFoulsJson.present) {
      map['team_fouls_json'] = Variable<String>(teamFoulsJson.value);
    }
    if (homeTimeoutsRemaining.present) {
      map['home_timeouts_remaining'] = Variable<int>(
        homeTimeoutsRemaining.value,
      );
    }
    if (awayTimeoutsRemaining.present) {
      map['away_timeouts_remaining'] = Variable<int>(
        awayTimeoutsRemaining.value,
      );
    }
    if (roundName.present) {
      map['round_name'] = Variable<String>(roundName.value);
    }
    if (roundNumber.present) {
      map['round_number'] = Variable<int>(roundNumber.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (mvpPlayerId.present) {
      map['mvp_player_id'] = Variable<int>(mvpPlayerId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMatchesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('serverUuid: $serverUuid, ')
          ..write('localUuid: $localUuid, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('homeTeamId: $homeTeamId, ')
          ..write('awayTeamId: $awayTeamId, ')
          ..write('homeTeamName: $homeTeamName, ')
          ..write('awayTeamName: $awayTeamName, ')
          ..write('homeScore: $homeScore, ')
          ..write('awayScore: $awayScore, ')
          ..write('quarterScoresJson: $quarterScoresJson, ')
          ..write('currentQuarter: $currentQuarter, ')
          ..write('gameClockSeconds: $gameClockSeconds, ')
          ..write('shotClockSeconds: $shotClockSeconds, ')
          ..write('status: $status, ')
          ..write('teamFoulsJson: $teamFoulsJson, ')
          ..write('homeTimeoutsRemaining: $homeTimeoutsRemaining, ')
          ..write('awayTimeoutsRemaining: $awayTimeoutsRemaining, ')
          ..write('roundName: $roundName, ')
          ..write('roundNumber: $roundNumber, ')
          ..write('groupName: $groupName, ')
          ..write('mvpPlayerId: $mvpPlayerId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalPlayerStatsTable extends LocalPlayerStats
    with TableInfo<$LocalPlayerStatsTable, LocalPlayerStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlayerStatsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _localMatchIdMeta = const VerificationMeta(
    'localMatchId',
  );
  @override
  late final GeneratedColumn<int> localMatchId = GeneratedColumn<int>(
    'local_match_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tournamentTeamPlayerIdMeta =
      const VerificationMeta('tournamentTeamPlayerId');
  @override
  late final GeneratedColumn<int> tournamentTeamPlayerId = GeneratedColumn<int>(
    'tournament_team_player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tournamentTeamIdMeta = const VerificationMeta(
    'tournamentTeamId',
  );
  @override
  late final GeneratedColumn<int> tournamentTeamId = GeneratedColumn<int>(
    'tournament_team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isStarterMeta = const VerificationMeta(
    'isStarter',
  );
  @override
  late final GeneratedColumn<bool> isStarter = GeneratedColumn<bool>(
    'is_starter',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_starter" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isOnCourtMeta = const VerificationMeta(
    'isOnCourt',
  );
  @override
  late final GeneratedColumn<bool> isOnCourt = GeneratedColumn<bool>(
    'is_on_court',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_on_court" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _minutesPlayedMeta = const VerificationMeta(
    'minutesPlayed',
  );
  @override
  late final GeneratedColumn<int> minutesPlayed = GeneratedColumn<int>(
    'minutes_played',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastEnteredAtMeta = const VerificationMeta(
    'lastEnteredAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastEnteredAt =
      GeneratedColumn<DateTime>(
        'last_entered_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fieldGoalsMadeMeta = const VerificationMeta(
    'fieldGoalsMade',
  );
  @override
  late final GeneratedColumn<int> fieldGoalsMade = GeneratedColumn<int>(
    'field_goals_made',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fieldGoalsAttemptedMeta =
      const VerificationMeta('fieldGoalsAttempted');
  @override
  late final GeneratedColumn<int> fieldGoalsAttempted = GeneratedColumn<int>(
    'field_goals_attempted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _twoPointersMadeMeta = const VerificationMeta(
    'twoPointersMade',
  );
  @override
  late final GeneratedColumn<int> twoPointersMade = GeneratedColumn<int>(
    'two_pointers_made',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _twoPointersAttemptedMeta =
      const VerificationMeta('twoPointersAttempted');
  @override
  late final GeneratedColumn<int> twoPointersAttempted = GeneratedColumn<int>(
    'two_pointers_attempted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _threePointersMadeMeta = const VerificationMeta(
    'threePointersMade',
  );
  @override
  late final GeneratedColumn<int> threePointersMade = GeneratedColumn<int>(
    'three_pointers_made',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _threePointersAttemptedMeta =
      const VerificationMeta('threePointersAttempted');
  @override
  late final GeneratedColumn<int> threePointersAttempted = GeneratedColumn<int>(
    'three_pointers_attempted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _freeThrowsMadeMeta = const VerificationMeta(
    'freeThrowsMade',
  );
  @override
  late final GeneratedColumn<int> freeThrowsMade = GeneratedColumn<int>(
    'free_throws_made',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _freeThrowsAttemptedMeta =
      const VerificationMeta('freeThrowsAttempted');
  @override
  late final GeneratedColumn<int> freeThrowsAttempted = GeneratedColumn<int>(
    'free_throws_attempted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _offensiveReboundsMeta = const VerificationMeta(
    'offensiveRebounds',
  );
  @override
  late final GeneratedColumn<int> offensiveRebounds = GeneratedColumn<int>(
    'offensive_rebounds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _defensiveReboundsMeta = const VerificationMeta(
    'defensiveRebounds',
  );
  @override
  late final GeneratedColumn<int> defensiveRebounds = GeneratedColumn<int>(
    'defensive_rebounds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalReboundsMeta = const VerificationMeta(
    'totalRebounds',
  );
  @override
  late final GeneratedColumn<int> totalRebounds = GeneratedColumn<int>(
    'total_rebounds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _assistsMeta = const VerificationMeta(
    'assists',
  );
  @override
  late final GeneratedColumn<int> assists = GeneratedColumn<int>(
    'assists',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stealsMeta = const VerificationMeta('steals');
  @override
  late final GeneratedColumn<int> steals = GeneratedColumn<int>(
    'steals',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _blocksMeta = const VerificationMeta('blocks');
  @override
  late final GeneratedColumn<int> blocks = GeneratedColumn<int>(
    'blocks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _turnoversMeta = const VerificationMeta(
    'turnovers',
  );
  @override
  late final GeneratedColumn<int> turnovers = GeneratedColumn<int>(
    'turnovers',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _personalFoulsMeta = const VerificationMeta(
    'personalFouls',
  );
  @override
  late final GeneratedColumn<int> personalFouls = GeneratedColumn<int>(
    'personal_fouls',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _technicalFoulsMeta = const VerificationMeta(
    'technicalFouls',
  );
  @override
  late final GeneratedColumn<int> technicalFouls = GeneratedColumn<int>(
    'technical_fouls',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unsportsmanlikeFoulsMeta =
      const VerificationMeta('unsportsmanlikeFouls');
  @override
  late final GeneratedColumn<int> unsportsmanlikeFouls = GeneratedColumn<int>(
    'unsportsmanlike_fouls',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _plusMinusMeta = const VerificationMeta(
    'plusMinus',
  );
  @override
  late final GeneratedColumn<int> plusMinus = GeneratedColumn<int>(
    'plus_minus',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fouledOutMeta = const VerificationMeta(
    'fouledOut',
  );
  @override
  late final GeneratedColumn<bool> fouledOut = GeneratedColumn<bool>(
    'fouled_out',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fouled_out" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ejectedMeta = const VerificationMeta(
    'ejected',
  );
  @override
  late final GeneratedColumn<bool> ejected = GeneratedColumn<bool>(
    'ejected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ejected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isManuallyEditedMeta = const VerificationMeta(
    'isManuallyEdited',
  );
  @override
  late final GeneratedColumn<bool> isManuallyEdited = GeneratedColumn<bool>(
    'is_manually_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_manually_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localMatchId,
    tournamentTeamPlayerId,
    tournamentTeamId,
    isStarter,
    isOnCourt,
    minutesPlayed,
    lastEnteredAt,
    points,
    fieldGoalsMade,
    fieldGoalsAttempted,
    twoPointersMade,
    twoPointersAttempted,
    threePointersMade,
    threePointersAttempted,
    freeThrowsMade,
    freeThrowsAttempted,
    offensiveRebounds,
    defensiveRebounds,
    totalRebounds,
    assists,
    steals,
    blocks,
    turnovers,
    personalFouls,
    technicalFouls,
    unsportsmanlikeFouls,
    plusMinus,
    fouledOut,
    ejected,
    isManuallyEdited,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_player_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPlayerStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_match_id')) {
      context.handle(
        _localMatchIdMeta,
        localMatchId.isAcceptableOrUnknown(
          data['local_match_id']!,
          _localMatchIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localMatchIdMeta);
    }
    if (data.containsKey('tournament_team_player_id')) {
      context.handle(
        _tournamentTeamPlayerIdMeta,
        tournamentTeamPlayerId.isAcceptableOrUnknown(
          data['tournament_team_player_id']!,
          _tournamentTeamPlayerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tournamentTeamPlayerIdMeta);
    }
    if (data.containsKey('tournament_team_id')) {
      context.handle(
        _tournamentTeamIdMeta,
        tournamentTeamId.isAcceptableOrUnknown(
          data['tournament_team_id']!,
          _tournamentTeamIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tournamentTeamIdMeta);
    }
    if (data.containsKey('is_starter')) {
      context.handle(
        _isStarterMeta,
        isStarter.isAcceptableOrUnknown(data['is_starter']!, _isStarterMeta),
      );
    }
    if (data.containsKey('is_on_court')) {
      context.handle(
        _isOnCourtMeta,
        isOnCourt.isAcceptableOrUnknown(data['is_on_court']!, _isOnCourtMeta),
      );
    }
    if (data.containsKey('minutes_played')) {
      context.handle(
        _minutesPlayedMeta,
        minutesPlayed.isAcceptableOrUnknown(
          data['minutes_played']!,
          _minutesPlayedMeta,
        ),
      );
    }
    if (data.containsKey('last_entered_at')) {
      context.handle(
        _lastEnteredAtMeta,
        lastEnteredAt.isAcceptableOrUnknown(
          data['last_entered_at']!,
          _lastEnteredAtMeta,
        ),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    }
    if (data.containsKey('field_goals_made')) {
      context.handle(
        _fieldGoalsMadeMeta,
        fieldGoalsMade.isAcceptableOrUnknown(
          data['field_goals_made']!,
          _fieldGoalsMadeMeta,
        ),
      );
    }
    if (data.containsKey('field_goals_attempted')) {
      context.handle(
        _fieldGoalsAttemptedMeta,
        fieldGoalsAttempted.isAcceptableOrUnknown(
          data['field_goals_attempted']!,
          _fieldGoalsAttemptedMeta,
        ),
      );
    }
    if (data.containsKey('two_pointers_made')) {
      context.handle(
        _twoPointersMadeMeta,
        twoPointersMade.isAcceptableOrUnknown(
          data['two_pointers_made']!,
          _twoPointersMadeMeta,
        ),
      );
    }
    if (data.containsKey('two_pointers_attempted')) {
      context.handle(
        _twoPointersAttemptedMeta,
        twoPointersAttempted.isAcceptableOrUnknown(
          data['two_pointers_attempted']!,
          _twoPointersAttemptedMeta,
        ),
      );
    }
    if (data.containsKey('three_pointers_made')) {
      context.handle(
        _threePointersMadeMeta,
        threePointersMade.isAcceptableOrUnknown(
          data['three_pointers_made']!,
          _threePointersMadeMeta,
        ),
      );
    }
    if (data.containsKey('three_pointers_attempted')) {
      context.handle(
        _threePointersAttemptedMeta,
        threePointersAttempted.isAcceptableOrUnknown(
          data['three_pointers_attempted']!,
          _threePointersAttemptedMeta,
        ),
      );
    }
    if (data.containsKey('free_throws_made')) {
      context.handle(
        _freeThrowsMadeMeta,
        freeThrowsMade.isAcceptableOrUnknown(
          data['free_throws_made']!,
          _freeThrowsMadeMeta,
        ),
      );
    }
    if (data.containsKey('free_throws_attempted')) {
      context.handle(
        _freeThrowsAttemptedMeta,
        freeThrowsAttempted.isAcceptableOrUnknown(
          data['free_throws_attempted']!,
          _freeThrowsAttemptedMeta,
        ),
      );
    }
    if (data.containsKey('offensive_rebounds')) {
      context.handle(
        _offensiveReboundsMeta,
        offensiveRebounds.isAcceptableOrUnknown(
          data['offensive_rebounds']!,
          _offensiveReboundsMeta,
        ),
      );
    }
    if (data.containsKey('defensive_rebounds')) {
      context.handle(
        _defensiveReboundsMeta,
        defensiveRebounds.isAcceptableOrUnknown(
          data['defensive_rebounds']!,
          _defensiveReboundsMeta,
        ),
      );
    }
    if (data.containsKey('total_rebounds')) {
      context.handle(
        _totalReboundsMeta,
        totalRebounds.isAcceptableOrUnknown(
          data['total_rebounds']!,
          _totalReboundsMeta,
        ),
      );
    }
    if (data.containsKey('assists')) {
      context.handle(
        _assistsMeta,
        assists.isAcceptableOrUnknown(data['assists']!, _assistsMeta),
      );
    }
    if (data.containsKey('steals')) {
      context.handle(
        _stealsMeta,
        steals.isAcceptableOrUnknown(data['steals']!, _stealsMeta),
      );
    }
    if (data.containsKey('blocks')) {
      context.handle(
        _blocksMeta,
        blocks.isAcceptableOrUnknown(data['blocks']!, _blocksMeta),
      );
    }
    if (data.containsKey('turnovers')) {
      context.handle(
        _turnoversMeta,
        turnovers.isAcceptableOrUnknown(data['turnovers']!, _turnoversMeta),
      );
    }
    if (data.containsKey('personal_fouls')) {
      context.handle(
        _personalFoulsMeta,
        personalFouls.isAcceptableOrUnknown(
          data['personal_fouls']!,
          _personalFoulsMeta,
        ),
      );
    }
    if (data.containsKey('technical_fouls')) {
      context.handle(
        _technicalFoulsMeta,
        technicalFouls.isAcceptableOrUnknown(
          data['technical_fouls']!,
          _technicalFoulsMeta,
        ),
      );
    }
    if (data.containsKey('unsportsmanlike_fouls')) {
      context.handle(
        _unsportsmanlikeFoulsMeta,
        unsportsmanlikeFouls.isAcceptableOrUnknown(
          data['unsportsmanlike_fouls']!,
          _unsportsmanlikeFoulsMeta,
        ),
      );
    }
    if (data.containsKey('plus_minus')) {
      context.handle(
        _plusMinusMeta,
        plusMinus.isAcceptableOrUnknown(data['plus_minus']!, _plusMinusMeta),
      );
    }
    if (data.containsKey('fouled_out')) {
      context.handle(
        _fouledOutMeta,
        fouledOut.isAcceptableOrUnknown(data['fouled_out']!, _fouledOutMeta),
      );
    }
    if (data.containsKey('ejected')) {
      context.handle(
        _ejectedMeta,
        ejected.isAcceptableOrUnknown(data['ejected']!, _ejectedMeta),
      );
    }
    if (data.containsKey('is_manually_edited')) {
      context.handle(
        _isManuallyEditedMeta,
        isManuallyEdited.isAcceptableOrUnknown(
          data['is_manually_edited']!,
          _isManuallyEditedMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlayerStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlayerStat(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      localMatchId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}local_match_id'],
          )!,
      tournamentTeamPlayerId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}tournament_team_player_id'],
          )!,
      tournamentTeamId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}tournament_team_id'],
          )!,
      isStarter:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_starter'],
          )!,
      isOnCourt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_on_court'],
          )!,
      minutesPlayed:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}minutes_played'],
          )!,
      lastEnteredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_entered_at'],
      ),
      points:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}points'],
          )!,
      fieldGoalsMade:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}field_goals_made'],
          )!,
      fieldGoalsAttempted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}field_goals_attempted'],
          )!,
      twoPointersMade:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}two_pointers_made'],
          )!,
      twoPointersAttempted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}two_pointers_attempted'],
          )!,
      threePointersMade:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}three_pointers_made'],
          )!,
      threePointersAttempted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}three_pointers_attempted'],
          )!,
      freeThrowsMade:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}free_throws_made'],
          )!,
      freeThrowsAttempted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}free_throws_attempted'],
          )!,
      offensiveRebounds:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}offensive_rebounds'],
          )!,
      defensiveRebounds:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}defensive_rebounds'],
          )!,
      totalRebounds:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}total_rebounds'],
          )!,
      assists:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}assists'],
          )!,
      steals:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}steals'],
          )!,
      blocks:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}blocks'],
          )!,
      turnovers:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}turnovers'],
          )!,
      personalFouls:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}personal_fouls'],
          )!,
      technicalFouls:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}technical_fouls'],
          )!,
      unsportsmanlikeFouls:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}unsportsmanlike_fouls'],
          )!,
      plusMinus:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}plus_minus'],
          )!,
      fouledOut:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}fouled_out'],
          )!,
      ejected:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}ejected'],
          )!,
      isManuallyEdited:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_manually_edited'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $LocalPlayerStatsTable createAlias(String alias) {
    return $LocalPlayerStatsTable(attachedDatabase, alias);
  }
}

class LocalPlayerStat extends DataClass implements Insertable<LocalPlayerStat> {
  final int id;
  final int localMatchId;
  final int tournamentTeamPlayerId;
  final int tournamentTeamId;
  final bool isStarter;
  final bool isOnCourt;
  final int minutesPlayed;
  final DateTime? lastEnteredAt;
  final int points;
  final int fieldGoalsMade;
  final int fieldGoalsAttempted;
  final int twoPointersMade;
  final int twoPointersAttempted;
  final int threePointersMade;
  final int threePointersAttempted;
  final int freeThrowsMade;
  final int freeThrowsAttempted;
  final int offensiveRebounds;
  final int defensiveRebounds;
  final int totalRebounds;
  final int assists;
  final int steals;
  final int blocks;
  final int turnovers;
  final int personalFouls;
  final int technicalFouls;
  final int unsportsmanlikeFouls;
  final int plusMinus;
  final bool fouledOut;
  final bool ejected;
  final bool isManuallyEdited;
  final DateTime updatedAt;
  const LocalPlayerStat({
    required this.id,
    required this.localMatchId,
    required this.tournamentTeamPlayerId,
    required this.tournamentTeamId,
    required this.isStarter,
    required this.isOnCourt,
    required this.minutesPlayed,
    this.lastEnteredAt,
    required this.points,
    required this.fieldGoalsMade,
    required this.fieldGoalsAttempted,
    required this.twoPointersMade,
    required this.twoPointersAttempted,
    required this.threePointersMade,
    required this.threePointersAttempted,
    required this.freeThrowsMade,
    required this.freeThrowsAttempted,
    required this.offensiveRebounds,
    required this.defensiveRebounds,
    required this.totalRebounds,
    required this.assists,
    required this.steals,
    required this.blocks,
    required this.turnovers,
    required this.personalFouls,
    required this.technicalFouls,
    required this.unsportsmanlikeFouls,
    required this.plusMinus,
    required this.fouledOut,
    required this.ejected,
    required this.isManuallyEdited,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_match_id'] = Variable<int>(localMatchId);
    map['tournament_team_player_id'] = Variable<int>(tournamentTeamPlayerId);
    map['tournament_team_id'] = Variable<int>(tournamentTeamId);
    map['is_starter'] = Variable<bool>(isStarter);
    map['is_on_court'] = Variable<bool>(isOnCourt);
    map['minutes_played'] = Variable<int>(minutesPlayed);
    if (!nullToAbsent || lastEnteredAt != null) {
      map['last_entered_at'] = Variable<DateTime>(lastEnteredAt);
    }
    map['points'] = Variable<int>(points);
    map['field_goals_made'] = Variable<int>(fieldGoalsMade);
    map['field_goals_attempted'] = Variable<int>(fieldGoalsAttempted);
    map['two_pointers_made'] = Variable<int>(twoPointersMade);
    map['two_pointers_attempted'] = Variable<int>(twoPointersAttempted);
    map['three_pointers_made'] = Variable<int>(threePointersMade);
    map['three_pointers_attempted'] = Variable<int>(threePointersAttempted);
    map['free_throws_made'] = Variable<int>(freeThrowsMade);
    map['free_throws_attempted'] = Variable<int>(freeThrowsAttempted);
    map['offensive_rebounds'] = Variable<int>(offensiveRebounds);
    map['defensive_rebounds'] = Variable<int>(defensiveRebounds);
    map['total_rebounds'] = Variable<int>(totalRebounds);
    map['assists'] = Variable<int>(assists);
    map['steals'] = Variable<int>(steals);
    map['blocks'] = Variable<int>(blocks);
    map['turnovers'] = Variable<int>(turnovers);
    map['personal_fouls'] = Variable<int>(personalFouls);
    map['technical_fouls'] = Variable<int>(technicalFouls);
    map['unsportsmanlike_fouls'] = Variable<int>(unsportsmanlikeFouls);
    map['plus_minus'] = Variable<int>(plusMinus);
    map['fouled_out'] = Variable<bool>(fouledOut);
    map['ejected'] = Variable<bool>(ejected);
    map['is_manually_edited'] = Variable<bool>(isManuallyEdited);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalPlayerStatsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlayerStatsCompanion(
      id: Value(id),
      localMatchId: Value(localMatchId),
      tournamentTeamPlayerId: Value(tournamentTeamPlayerId),
      tournamentTeamId: Value(tournamentTeamId),
      isStarter: Value(isStarter),
      isOnCourt: Value(isOnCourt),
      minutesPlayed: Value(minutesPlayed),
      lastEnteredAt:
          lastEnteredAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastEnteredAt),
      points: Value(points),
      fieldGoalsMade: Value(fieldGoalsMade),
      fieldGoalsAttempted: Value(fieldGoalsAttempted),
      twoPointersMade: Value(twoPointersMade),
      twoPointersAttempted: Value(twoPointersAttempted),
      threePointersMade: Value(threePointersMade),
      threePointersAttempted: Value(threePointersAttempted),
      freeThrowsMade: Value(freeThrowsMade),
      freeThrowsAttempted: Value(freeThrowsAttempted),
      offensiveRebounds: Value(offensiveRebounds),
      defensiveRebounds: Value(defensiveRebounds),
      totalRebounds: Value(totalRebounds),
      assists: Value(assists),
      steals: Value(steals),
      blocks: Value(blocks),
      turnovers: Value(turnovers),
      personalFouls: Value(personalFouls),
      technicalFouls: Value(technicalFouls),
      unsportsmanlikeFouls: Value(unsportsmanlikeFouls),
      plusMinus: Value(plusMinus),
      fouledOut: Value(fouledOut),
      ejected: Value(ejected),
      isManuallyEdited: Value(isManuallyEdited),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalPlayerStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlayerStat(
      id: serializer.fromJson<int>(json['id']),
      localMatchId: serializer.fromJson<int>(json['localMatchId']),
      tournamentTeamPlayerId: serializer.fromJson<int>(
        json['tournamentTeamPlayerId'],
      ),
      tournamentTeamId: serializer.fromJson<int>(json['tournamentTeamId']),
      isStarter: serializer.fromJson<bool>(json['isStarter']),
      isOnCourt: serializer.fromJson<bool>(json['isOnCourt']),
      minutesPlayed: serializer.fromJson<int>(json['minutesPlayed']),
      lastEnteredAt: serializer.fromJson<DateTime?>(json['lastEnteredAt']),
      points: serializer.fromJson<int>(json['points']),
      fieldGoalsMade: serializer.fromJson<int>(json['fieldGoalsMade']),
      fieldGoalsAttempted: serializer.fromJson<int>(
        json['fieldGoalsAttempted'],
      ),
      twoPointersMade: serializer.fromJson<int>(json['twoPointersMade']),
      twoPointersAttempted: serializer.fromJson<int>(
        json['twoPointersAttempted'],
      ),
      threePointersMade: serializer.fromJson<int>(json['threePointersMade']),
      threePointersAttempted: serializer.fromJson<int>(
        json['threePointersAttempted'],
      ),
      freeThrowsMade: serializer.fromJson<int>(json['freeThrowsMade']),
      freeThrowsAttempted: serializer.fromJson<int>(
        json['freeThrowsAttempted'],
      ),
      offensiveRebounds: serializer.fromJson<int>(json['offensiveRebounds']),
      defensiveRebounds: serializer.fromJson<int>(json['defensiveRebounds']),
      totalRebounds: serializer.fromJson<int>(json['totalRebounds']),
      assists: serializer.fromJson<int>(json['assists']),
      steals: serializer.fromJson<int>(json['steals']),
      blocks: serializer.fromJson<int>(json['blocks']),
      turnovers: serializer.fromJson<int>(json['turnovers']),
      personalFouls: serializer.fromJson<int>(json['personalFouls']),
      technicalFouls: serializer.fromJson<int>(json['technicalFouls']),
      unsportsmanlikeFouls: serializer.fromJson<int>(
        json['unsportsmanlikeFouls'],
      ),
      plusMinus: serializer.fromJson<int>(json['plusMinus']),
      fouledOut: serializer.fromJson<bool>(json['fouledOut']),
      ejected: serializer.fromJson<bool>(json['ejected']),
      isManuallyEdited: serializer.fromJson<bool>(json['isManuallyEdited']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localMatchId': serializer.toJson<int>(localMatchId),
      'tournamentTeamPlayerId': serializer.toJson<int>(tournamentTeamPlayerId),
      'tournamentTeamId': serializer.toJson<int>(tournamentTeamId),
      'isStarter': serializer.toJson<bool>(isStarter),
      'isOnCourt': serializer.toJson<bool>(isOnCourt),
      'minutesPlayed': serializer.toJson<int>(minutesPlayed),
      'lastEnteredAt': serializer.toJson<DateTime?>(lastEnteredAt),
      'points': serializer.toJson<int>(points),
      'fieldGoalsMade': serializer.toJson<int>(fieldGoalsMade),
      'fieldGoalsAttempted': serializer.toJson<int>(fieldGoalsAttempted),
      'twoPointersMade': serializer.toJson<int>(twoPointersMade),
      'twoPointersAttempted': serializer.toJson<int>(twoPointersAttempted),
      'threePointersMade': serializer.toJson<int>(threePointersMade),
      'threePointersAttempted': serializer.toJson<int>(threePointersAttempted),
      'freeThrowsMade': serializer.toJson<int>(freeThrowsMade),
      'freeThrowsAttempted': serializer.toJson<int>(freeThrowsAttempted),
      'offensiveRebounds': serializer.toJson<int>(offensiveRebounds),
      'defensiveRebounds': serializer.toJson<int>(defensiveRebounds),
      'totalRebounds': serializer.toJson<int>(totalRebounds),
      'assists': serializer.toJson<int>(assists),
      'steals': serializer.toJson<int>(steals),
      'blocks': serializer.toJson<int>(blocks),
      'turnovers': serializer.toJson<int>(turnovers),
      'personalFouls': serializer.toJson<int>(personalFouls),
      'technicalFouls': serializer.toJson<int>(technicalFouls),
      'unsportsmanlikeFouls': serializer.toJson<int>(unsportsmanlikeFouls),
      'plusMinus': serializer.toJson<int>(plusMinus),
      'fouledOut': serializer.toJson<bool>(fouledOut),
      'ejected': serializer.toJson<bool>(ejected),
      'isManuallyEdited': serializer.toJson<bool>(isManuallyEdited),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalPlayerStat copyWith({
    int? id,
    int? localMatchId,
    int? tournamentTeamPlayerId,
    int? tournamentTeamId,
    bool? isStarter,
    bool? isOnCourt,
    int? minutesPlayed,
    Value<DateTime?> lastEnteredAt = const Value.absent(),
    int? points,
    int? fieldGoalsMade,
    int? fieldGoalsAttempted,
    int? twoPointersMade,
    int? twoPointersAttempted,
    int? threePointersMade,
    int? threePointersAttempted,
    int? freeThrowsMade,
    int? freeThrowsAttempted,
    int? offensiveRebounds,
    int? defensiveRebounds,
    int? totalRebounds,
    int? assists,
    int? steals,
    int? blocks,
    int? turnovers,
    int? personalFouls,
    int? technicalFouls,
    int? unsportsmanlikeFouls,
    int? plusMinus,
    bool? fouledOut,
    bool? ejected,
    bool? isManuallyEdited,
    DateTime? updatedAt,
  }) => LocalPlayerStat(
    id: id ?? this.id,
    localMatchId: localMatchId ?? this.localMatchId,
    tournamentTeamPlayerId:
        tournamentTeamPlayerId ?? this.tournamentTeamPlayerId,
    tournamentTeamId: tournamentTeamId ?? this.tournamentTeamId,
    isStarter: isStarter ?? this.isStarter,
    isOnCourt: isOnCourt ?? this.isOnCourt,
    minutesPlayed: minutesPlayed ?? this.minutesPlayed,
    lastEnteredAt:
        lastEnteredAt.present ? lastEnteredAt.value : this.lastEnteredAt,
    points: points ?? this.points,
    fieldGoalsMade: fieldGoalsMade ?? this.fieldGoalsMade,
    fieldGoalsAttempted: fieldGoalsAttempted ?? this.fieldGoalsAttempted,
    twoPointersMade: twoPointersMade ?? this.twoPointersMade,
    twoPointersAttempted: twoPointersAttempted ?? this.twoPointersAttempted,
    threePointersMade: threePointersMade ?? this.threePointersMade,
    threePointersAttempted:
        threePointersAttempted ?? this.threePointersAttempted,
    freeThrowsMade: freeThrowsMade ?? this.freeThrowsMade,
    freeThrowsAttempted: freeThrowsAttempted ?? this.freeThrowsAttempted,
    offensiveRebounds: offensiveRebounds ?? this.offensiveRebounds,
    defensiveRebounds: defensiveRebounds ?? this.defensiveRebounds,
    totalRebounds: totalRebounds ?? this.totalRebounds,
    assists: assists ?? this.assists,
    steals: steals ?? this.steals,
    blocks: blocks ?? this.blocks,
    turnovers: turnovers ?? this.turnovers,
    personalFouls: personalFouls ?? this.personalFouls,
    technicalFouls: technicalFouls ?? this.technicalFouls,
    unsportsmanlikeFouls: unsportsmanlikeFouls ?? this.unsportsmanlikeFouls,
    plusMinus: plusMinus ?? this.plusMinus,
    fouledOut: fouledOut ?? this.fouledOut,
    ejected: ejected ?? this.ejected,
    isManuallyEdited: isManuallyEdited ?? this.isManuallyEdited,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalPlayerStat copyWithCompanion(LocalPlayerStatsCompanion data) {
    return LocalPlayerStat(
      id: data.id.present ? data.id.value : this.id,
      localMatchId:
          data.localMatchId.present
              ? data.localMatchId.value
              : this.localMatchId,
      tournamentTeamPlayerId:
          data.tournamentTeamPlayerId.present
              ? data.tournamentTeamPlayerId.value
              : this.tournamentTeamPlayerId,
      tournamentTeamId:
          data.tournamentTeamId.present
              ? data.tournamentTeamId.value
              : this.tournamentTeamId,
      isStarter: data.isStarter.present ? data.isStarter.value : this.isStarter,
      isOnCourt: data.isOnCourt.present ? data.isOnCourt.value : this.isOnCourt,
      minutesPlayed:
          data.minutesPlayed.present
              ? data.minutesPlayed.value
              : this.minutesPlayed,
      lastEnteredAt:
          data.lastEnteredAt.present
              ? data.lastEnteredAt.value
              : this.lastEnteredAt,
      points: data.points.present ? data.points.value : this.points,
      fieldGoalsMade:
          data.fieldGoalsMade.present
              ? data.fieldGoalsMade.value
              : this.fieldGoalsMade,
      fieldGoalsAttempted:
          data.fieldGoalsAttempted.present
              ? data.fieldGoalsAttempted.value
              : this.fieldGoalsAttempted,
      twoPointersMade:
          data.twoPointersMade.present
              ? data.twoPointersMade.value
              : this.twoPointersMade,
      twoPointersAttempted:
          data.twoPointersAttempted.present
              ? data.twoPointersAttempted.value
              : this.twoPointersAttempted,
      threePointersMade:
          data.threePointersMade.present
              ? data.threePointersMade.value
              : this.threePointersMade,
      threePointersAttempted:
          data.threePointersAttempted.present
              ? data.threePointersAttempted.value
              : this.threePointersAttempted,
      freeThrowsMade:
          data.freeThrowsMade.present
              ? data.freeThrowsMade.value
              : this.freeThrowsMade,
      freeThrowsAttempted:
          data.freeThrowsAttempted.present
              ? data.freeThrowsAttempted.value
              : this.freeThrowsAttempted,
      offensiveRebounds:
          data.offensiveRebounds.present
              ? data.offensiveRebounds.value
              : this.offensiveRebounds,
      defensiveRebounds:
          data.defensiveRebounds.present
              ? data.defensiveRebounds.value
              : this.defensiveRebounds,
      totalRebounds:
          data.totalRebounds.present
              ? data.totalRebounds.value
              : this.totalRebounds,
      assists: data.assists.present ? data.assists.value : this.assists,
      steals: data.steals.present ? data.steals.value : this.steals,
      blocks: data.blocks.present ? data.blocks.value : this.blocks,
      turnovers: data.turnovers.present ? data.turnovers.value : this.turnovers,
      personalFouls:
          data.personalFouls.present
              ? data.personalFouls.value
              : this.personalFouls,
      technicalFouls:
          data.technicalFouls.present
              ? data.technicalFouls.value
              : this.technicalFouls,
      unsportsmanlikeFouls:
          data.unsportsmanlikeFouls.present
              ? data.unsportsmanlikeFouls.value
              : this.unsportsmanlikeFouls,
      plusMinus: data.plusMinus.present ? data.plusMinus.value : this.plusMinus,
      fouledOut: data.fouledOut.present ? data.fouledOut.value : this.fouledOut,
      ejected: data.ejected.present ? data.ejected.value : this.ejected,
      isManuallyEdited:
          data.isManuallyEdited.present
              ? data.isManuallyEdited.value
              : this.isManuallyEdited,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlayerStat(')
          ..write('id: $id, ')
          ..write('localMatchId: $localMatchId, ')
          ..write('tournamentTeamPlayerId: $tournamentTeamPlayerId, ')
          ..write('tournamentTeamId: $tournamentTeamId, ')
          ..write('isStarter: $isStarter, ')
          ..write('isOnCourt: $isOnCourt, ')
          ..write('minutesPlayed: $minutesPlayed, ')
          ..write('lastEnteredAt: $lastEnteredAt, ')
          ..write('points: $points, ')
          ..write('fieldGoalsMade: $fieldGoalsMade, ')
          ..write('fieldGoalsAttempted: $fieldGoalsAttempted, ')
          ..write('twoPointersMade: $twoPointersMade, ')
          ..write('twoPointersAttempted: $twoPointersAttempted, ')
          ..write('threePointersMade: $threePointersMade, ')
          ..write('threePointersAttempted: $threePointersAttempted, ')
          ..write('freeThrowsMade: $freeThrowsMade, ')
          ..write('freeThrowsAttempted: $freeThrowsAttempted, ')
          ..write('offensiveRebounds: $offensiveRebounds, ')
          ..write('defensiveRebounds: $defensiveRebounds, ')
          ..write('totalRebounds: $totalRebounds, ')
          ..write('assists: $assists, ')
          ..write('steals: $steals, ')
          ..write('blocks: $blocks, ')
          ..write('turnovers: $turnovers, ')
          ..write('personalFouls: $personalFouls, ')
          ..write('technicalFouls: $technicalFouls, ')
          ..write('unsportsmanlikeFouls: $unsportsmanlikeFouls, ')
          ..write('plusMinus: $plusMinus, ')
          ..write('fouledOut: $fouledOut, ')
          ..write('ejected: $ejected, ')
          ..write('isManuallyEdited: $isManuallyEdited, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    localMatchId,
    tournamentTeamPlayerId,
    tournamentTeamId,
    isStarter,
    isOnCourt,
    minutesPlayed,
    lastEnteredAt,
    points,
    fieldGoalsMade,
    fieldGoalsAttempted,
    twoPointersMade,
    twoPointersAttempted,
    threePointersMade,
    threePointersAttempted,
    freeThrowsMade,
    freeThrowsAttempted,
    offensiveRebounds,
    defensiveRebounds,
    totalRebounds,
    assists,
    steals,
    blocks,
    turnovers,
    personalFouls,
    technicalFouls,
    unsportsmanlikeFouls,
    plusMinus,
    fouledOut,
    ejected,
    isManuallyEdited,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlayerStat &&
          other.id == this.id &&
          other.localMatchId == this.localMatchId &&
          other.tournamentTeamPlayerId == this.tournamentTeamPlayerId &&
          other.tournamentTeamId == this.tournamentTeamId &&
          other.isStarter == this.isStarter &&
          other.isOnCourt == this.isOnCourt &&
          other.minutesPlayed == this.minutesPlayed &&
          other.lastEnteredAt == this.lastEnteredAt &&
          other.points == this.points &&
          other.fieldGoalsMade == this.fieldGoalsMade &&
          other.fieldGoalsAttempted == this.fieldGoalsAttempted &&
          other.twoPointersMade == this.twoPointersMade &&
          other.twoPointersAttempted == this.twoPointersAttempted &&
          other.threePointersMade == this.threePointersMade &&
          other.threePointersAttempted == this.threePointersAttempted &&
          other.freeThrowsMade == this.freeThrowsMade &&
          other.freeThrowsAttempted == this.freeThrowsAttempted &&
          other.offensiveRebounds == this.offensiveRebounds &&
          other.defensiveRebounds == this.defensiveRebounds &&
          other.totalRebounds == this.totalRebounds &&
          other.assists == this.assists &&
          other.steals == this.steals &&
          other.blocks == this.blocks &&
          other.turnovers == this.turnovers &&
          other.personalFouls == this.personalFouls &&
          other.technicalFouls == this.technicalFouls &&
          other.unsportsmanlikeFouls == this.unsportsmanlikeFouls &&
          other.plusMinus == this.plusMinus &&
          other.fouledOut == this.fouledOut &&
          other.ejected == this.ejected &&
          other.isManuallyEdited == this.isManuallyEdited &&
          other.updatedAt == this.updatedAt);
}

class LocalPlayerStatsCompanion extends UpdateCompanion<LocalPlayerStat> {
  final Value<int> id;
  final Value<int> localMatchId;
  final Value<int> tournamentTeamPlayerId;
  final Value<int> tournamentTeamId;
  final Value<bool> isStarter;
  final Value<bool> isOnCourt;
  final Value<int> minutesPlayed;
  final Value<DateTime?> lastEnteredAt;
  final Value<int> points;
  final Value<int> fieldGoalsMade;
  final Value<int> fieldGoalsAttempted;
  final Value<int> twoPointersMade;
  final Value<int> twoPointersAttempted;
  final Value<int> threePointersMade;
  final Value<int> threePointersAttempted;
  final Value<int> freeThrowsMade;
  final Value<int> freeThrowsAttempted;
  final Value<int> offensiveRebounds;
  final Value<int> defensiveRebounds;
  final Value<int> totalRebounds;
  final Value<int> assists;
  final Value<int> steals;
  final Value<int> blocks;
  final Value<int> turnovers;
  final Value<int> personalFouls;
  final Value<int> technicalFouls;
  final Value<int> unsportsmanlikeFouls;
  final Value<int> plusMinus;
  final Value<bool> fouledOut;
  final Value<bool> ejected;
  final Value<bool> isManuallyEdited;
  final Value<DateTime> updatedAt;
  const LocalPlayerStatsCompanion({
    this.id = const Value.absent(),
    this.localMatchId = const Value.absent(),
    this.tournamentTeamPlayerId = const Value.absent(),
    this.tournamentTeamId = const Value.absent(),
    this.isStarter = const Value.absent(),
    this.isOnCourt = const Value.absent(),
    this.minutesPlayed = const Value.absent(),
    this.lastEnteredAt = const Value.absent(),
    this.points = const Value.absent(),
    this.fieldGoalsMade = const Value.absent(),
    this.fieldGoalsAttempted = const Value.absent(),
    this.twoPointersMade = const Value.absent(),
    this.twoPointersAttempted = const Value.absent(),
    this.threePointersMade = const Value.absent(),
    this.threePointersAttempted = const Value.absent(),
    this.freeThrowsMade = const Value.absent(),
    this.freeThrowsAttempted = const Value.absent(),
    this.offensiveRebounds = const Value.absent(),
    this.defensiveRebounds = const Value.absent(),
    this.totalRebounds = const Value.absent(),
    this.assists = const Value.absent(),
    this.steals = const Value.absent(),
    this.blocks = const Value.absent(),
    this.turnovers = const Value.absent(),
    this.personalFouls = const Value.absent(),
    this.technicalFouls = const Value.absent(),
    this.unsportsmanlikeFouls = const Value.absent(),
    this.plusMinus = const Value.absent(),
    this.fouledOut = const Value.absent(),
    this.ejected = const Value.absent(),
    this.isManuallyEdited = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalPlayerStatsCompanion.insert({
    this.id = const Value.absent(),
    required int localMatchId,
    required int tournamentTeamPlayerId,
    required int tournamentTeamId,
    this.isStarter = const Value.absent(),
    this.isOnCourt = const Value.absent(),
    this.minutesPlayed = const Value.absent(),
    this.lastEnteredAt = const Value.absent(),
    this.points = const Value.absent(),
    this.fieldGoalsMade = const Value.absent(),
    this.fieldGoalsAttempted = const Value.absent(),
    this.twoPointersMade = const Value.absent(),
    this.twoPointersAttempted = const Value.absent(),
    this.threePointersMade = const Value.absent(),
    this.threePointersAttempted = const Value.absent(),
    this.freeThrowsMade = const Value.absent(),
    this.freeThrowsAttempted = const Value.absent(),
    this.offensiveRebounds = const Value.absent(),
    this.defensiveRebounds = const Value.absent(),
    this.totalRebounds = const Value.absent(),
    this.assists = const Value.absent(),
    this.steals = const Value.absent(),
    this.blocks = const Value.absent(),
    this.turnovers = const Value.absent(),
    this.personalFouls = const Value.absent(),
    this.technicalFouls = const Value.absent(),
    this.unsportsmanlikeFouls = const Value.absent(),
    this.plusMinus = const Value.absent(),
    this.fouledOut = const Value.absent(),
    this.ejected = const Value.absent(),
    this.isManuallyEdited = const Value.absent(),
    required DateTime updatedAt,
  }) : localMatchId = Value(localMatchId),
       tournamentTeamPlayerId = Value(tournamentTeamPlayerId),
       tournamentTeamId = Value(tournamentTeamId),
       updatedAt = Value(updatedAt);
  static Insertable<LocalPlayerStat> custom({
    Expression<int>? id,
    Expression<int>? localMatchId,
    Expression<int>? tournamentTeamPlayerId,
    Expression<int>? tournamentTeamId,
    Expression<bool>? isStarter,
    Expression<bool>? isOnCourt,
    Expression<int>? minutesPlayed,
    Expression<DateTime>? lastEnteredAt,
    Expression<int>? points,
    Expression<int>? fieldGoalsMade,
    Expression<int>? fieldGoalsAttempted,
    Expression<int>? twoPointersMade,
    Expression<int>? twoPointersAttempted,
    Expression<int>? threePointersMade,
    Expression<int>? threePointersAttempted,
    Expression<int>? freeThrowsMade,
    Expression<int>? freeThrowsAttempted,
    Expression<int>? offensiveRebounds,
    Expression<int>? defensiveRebounds,
    Expression<int>? totalRebounds,
    Expression<int>? assists,
    Expression<int>? steals,
    Expression<int>? blocks,
    Expression<int>? turnovers,
    Expression<int>? personalFouls,
    Expression<int>? technicalFouls,
    Expression<int>? unsportsmanlikeFouls,
    Expression<int>? plusMinus,
    Expression<bool>? fouledOut,
    Expression<bool>? ejected,
    Expression<bool>? isManuallyEdited,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localMatchId != null) 'local_match_id': localMatchId,
      if (tournamentTeamPlayerId != null)
        'tournament_team_player_id': tournamentTeamPlayerId,
      if (tournamentTeamId != null) 'tournament_team_id': tournamentTeamId,
      if (isStarter != null) 'is_starter': isStarter,
      if (isOnCourt != null) 'is_on_court': isOnCourt,
      if (minutesPlayed != null) 'minutes_played': minutesPlayed,
      if (lastEnteredAt != null) 'last_entered_at': lastEnteredAt,
      if (points != null) 'points': points,
      if (fieldGoalsMade != null) 'field_goals_made': fieldGoalsMade,
      if (fieldGoalsAttempted != null)
        'field_goals_attempted': fieldGoalsAttempted,
      if (twoPointersMade != null) 'two_pointers_made': twoPointersMade,
      if (twoPointersAttempted != null)
        'two_pointers_attempted': twoPointersAttempted,
      if (threePointersMade != null) 'three_pointers_made': threePointersMade,
      if (threePointersAttempted != null)
        'three_pointers_attempted': threePointersAttempted,
      if (freeThrowsMade != null) 'free_throws_made': freeThrowsMade,
      if (freeThrowsAttempted != null)
        'free_throws_attempted': freeThrowsAttempted,
      if (offensiveRebounds != null) 'offensive_rebounds': offensiveRebounds,
      if (defensiveRebounds != null) 'defensive_rebounds': defensiveRebounds,
      if (totalRebounds != null) 'total_rebounds': totalRebounds,
      if (assists != null) 'assists': assists,
      if (steals != null) 'steals': steals,
      if (blocks != null) 'blocks': blocks,
      if (turnovers != null) 'turnovers': turnovers,
      if (personalFouls != null) 'personal_fouls': personalFouls,
      if (technicalFouls != null) 'technical_fouls': technicalFouls,
      if (unsportsmanlikeFouls != null)
        'unsportsmanlike_fouls': unsportsmanlikeFouls,
      if (plusMinus != null) 'plus_minus': plusMinus,
      if (fouledOut != null) 'fouled_out': fouledOut,
      if (ejected != null) 'ejected': ejected,
      if (isManuallyEdited != null) 'is_manually_edited': isManuallyEdited,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalPlayerStatsCompanion copyWith({
    Value<int>? id,
    Value<int>? localMatchId,
    Value<int>? tournamentTeamPlayerId,
    Value<int>? tournamentTeamId,
    Value<bool>? isStarter,
    Value<bool>? isOnCourt,
    Value<int>? minutesPlayed,
    Value<DateTime?>? lastEnteredAt,
    Value<int>? points,
    Value<int>? fieldGoalsMade,
    Value<int>? fieldGoalsAttempted,
    Value<int>? twoPointersMade,
    Value<int>? twoPointersAttempted,
    Value<int>? threePointersMade,
    Value<int>? threePointersAttempted,
    Value<int>? freeThrowsMade,
    Value<int>? freeThrowsAttempted,
    Value<int>? offensiveRebounds,
    Value<int>? defensiveRebounds,
    Value<int>? totalRebounds,
    Value<int>? assists,
    Value<int>? steals,
    Value<int>? blocks,
    Value<int>? turnovers,
    Value<int>? personalFouls,
    Value<int>? technicalFouls,
    Value<int>? unsportsmanlikeFouls,
    Value<int>? plusMinus,
    Value<bool>? fouledOut,
    Value<bool>? ejected,
    Value<bool>? isManuallyEdited,
    Value<DateTime>? updatedAt,
  }) {
    return LocalPlayerStatsCompanion(
      id: id ?? this.id,
      localMatchId: localMatchId ?? this.localMatchId,
      tournamentTeamPlayerId:
          tournamentTeamPlayerId ?? this.tournamentTeamPlayerId,
      tournamentTeamId: tournamentTeamId ?? this.tournamentTeamId,
      isStarter: isStarter ?? this.isStarter,
      isOnCourt: isOnCourt ?? this.isOnCourt,
      minutesPlayed: minutesPlayed ?? this.minutesPlayed,
      lastEnteredAt: lastEnteredAt ?? this.lastEnteredAt,
      points: points ?? this.points,
      fieldGoalsMade: fieldGoalsMade ?? this.fieldGoalsMade,
      fieldGoalsAttempted: fieldGoalsAttempted ?? this.fieldGoalsAttempted,
      twoPointersMade: twoPointersMade ?? this.twoPointersMade,
      twoPointersAttempted: twoPointersAttempted ?? this.twoPointersAttempted,
      threePointersMade: threePointersMade ?? this.threePointersMade,
      threePointersAttempted:
          threePointersAttempted ?? this.threePointersAttempted,
      freeThrowsMade: freeThrowsMade ?? this.freeThrowsMade,
      freeThrowsAttempted: freeThrowsAttempted ?? this.freeThrowsAttempted,
      offensiveRebounds: offensiveRebounds ?? this.offensiveRebounds,
      defensiveRebounds: defensiveRebounds ?? this.defensiveRebounds,
      totalRebounds: totalRebounds ?? this.totalRebounds,
      assists: assists ?? this.assists,
      steals: steals ?? this.steals,
      blocks: blocks ?? this.blocks,
      turnovers: turnovers ?? this.turnovers,
      personalFouls: personalFouls ?? this.personalFouls,
      technicalFouls: technicalFouls ?? this.technicalFouls,
      unsportsmanlikeFouls: unsportsmanlikeFouls ?? this.unsportsmanlikeFouls,
      plusMinus: plusMinus ?? this.plusMinus,
      fouledOut: fouledOut ?? this.fouledOut,
      ejected: ejected ?? this.ejected,
      isManuallyEdited: isManuallyEdited ?? this.isManuallyEdited,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localMatchId.present) {
      map['local_match_id'] = Variable<int>(localMatchId.value);
    }
    if (tournamentTeamPlayerId.present) {
      map['tournament_team_player_id'] = Variable<int>(
        tournamentTeamPlayerId.value,
      );
    }
    if (tournamentTeamId.present) {
      map['tournament_team_id'] = Variable<int>(tournamentTeamId.value);
    }
    if (isStarter.present) {
      map['is_starter'] = Variable<bool>(isStarter.value);
    }
    if (isOnCourt.present) {
      map['is_on_court'] = Variable<bool>(isOnCourt.value);
    }
    if (minutesPlayed.present) {
      map['minutes_played'] = Variable<int>(minutesPlayed.value);
    }
    if (lastEnteredAt.present) {
      map['last_entered_at'] = Variable<DateTime>(lastEnteredAt.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (fieldGoalsMade.present) {
      map['field_goals_made'] = Variable<int>(fieldGoalsMade.value);
    }
    if (fieldGoalsAttempted.present) {
      map['field_goals_attempted'] = Variable<int>(fieldGoalsAttempted.value);
    }
    if (twoPointersMade.present) {
      map['two_pointers_made'] = Variable<int>(twoPointersMade.value);
    }
    if (twoPointersAttempted.present) {
      map['two_pointers_attempted'] = Variable<int>(twoPointersAttempted.value);
    }
    if (threePointersMade.present) {
      map['three_pointers_made'] = Variable<int>(threePointersMade.value);
    }
    if (threePointersAttempted.present) {
      map['three_pointers_attempted'] = Variable<int>(
        threePointersAttempted.value,
      );
    }
    if (freeThrowsMade.present) {
      map['free_throws_made'] = Variable<int>(freeThrowsMade.value);
    }
    if (freeThrowsAttempted.present) {
      map['free_throws_attempted'] = Variable<int>(freeThrowsAttempted.value);
    }
    if (offensiveRebounds.present) {
      map['offensive_rebounds'] = Variable<int>(offensiveRebounds.value);
    }
    if (defensiveRebounds.present) {
      map['defensive_rebounds'] = Variable<int>(defensiveRebounds.value);
    }
    if (totalRebounds.present) {
      map['total_rebounds'] = Variable<int>(totalRebounds.value);
    }
    if (assists.present) {
      map['assists'] = Variable<int>(assists.value);
    }
    if (steals.present) {
      map['steals'] = Variable<int>(steals.value);
    }
    if (blocks.present) {
      map['blocks'] = Variable<int>(blocks.value);
    }
    if (turnovers.present) {
      map['turnovers'] = Variable<int>(turnovers.value);
    }
    if (personalFouls.present) {
      map['personal_fouls'] = Variable<int>(personalFouls.value);
    }
    if (technicalFouls.present) {
      map['technical_fouls'] = Variable<int>(technicalFouls.value);
    }
    if (unsportsmanlikeFouls.present) {
      map['unsportsmanlike_fouls'] = Variable<int>(unsportsmanlikeFouls.value);
    }
    if (plusMinus.present) {
      map['plus_minus'] = Variable<int>(plusMinus.value);
    }
    if (fouledOut.present) {
      map['fouled_out'] = Variable<bool>(fouledOut.value);
    }
    if (ejected.present) {
      map['ejected'] = Variable<bool>(ejected.value);
    }
    if (isManuallyEdited.present) {
      map['is_manually_edited'] = Variable<bool>(isManuallyEdited.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlayerStatsCompanion(')
          ..write('id: $id, ')
          ..write('localMatchId: $localMatchId, ')
          ..write('tournamentTeamPlayerId: $tournamentTeamPlayerId, ')
          ..write('tournamentTeamId: $tournamentTeamId, ')
          ..write('isStarter: $isStarter, ')
          ..write('isOnCourt: $isOnCourt, ')
          ..write('minutesPlayed: $minutesPlayed, ')
          ..write('lastEnteredAt: $lastEnteredAt, ')
          ..write('points: $points, ')
          ..write('fieldGoalsMade: $fieldGoalsMade, ')
          ..write('fieldGoalsAttempted: $fieldGoalsAttempted, ')
          ..write('twoPointersMade: $twoPointersMade, ')
          ..write('twoPointersAttempted: $twoPointersAttempted, ')
          ..write('threePointersMade: $threePointersMade, ')
          ..write('threePointersAttempted: $threePointersAttempted, ')
          ..write('freeThrowsMade: $freeThrowsMade, ')
          ..write('freeThrowsAttempted: $freeThrowsAttempted, ')
          ..write('offensiveRebounds: $offensiveRebounds, ')
          ..write('defensiveRebounds: $defensiveRebounds, ')
          ..write('totalRebounds: $totalRebounds, ')
          ..write('assists: $assists, ')
          ..write('steals: $steals, ')
          ..write('blocks: $blocks, ')
          ..write('turnovers: $turnovers, ')
          ..write('personalFouls: $personalFouls, ')
          ..write('technicalFouls: $technicalFouls, ')
          ..write('unsportsmanlikeFouls: $unsportsmanlikeFouls, ')
          ..write('plusMinus: $plusMinus, ')
          ..write('fouledOut: $fouledOut, ')
          ..write('ejected: $ejected, ')
          ..write('isManuallyEdited: $isManuallyEdited, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalPlayByPlaysTable extends LocalPlayByPlays
    with TableInfo<$LocalPlayByPlaysTable, LocalPlayByPlay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlayByPlaysTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localMatchIdMeta = const VerificationMeta(
    'localMatchId',
  );
  @override
  late final GeneratedColumn<int> localMatchId = GeneratedColumn<int>(
    'local_match_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tournamentTeamPlayerIdMeta =
      const VerificationMeta('tournamentTeamPlayerId');
  @override
  late final GeneratedColumn<int> tournamentTeamPlayerId = GeneratedColumn<int>(
    'tournament_team_player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tournamentTeamIdMeta = const VerificationMeta(
    'tournamentTeamId',
  );
  @override
  late final GeneratedColumn<int> tournamentTeamId = GeneratedColumn<int>(
    'tournament_team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quarterMeta = const VerificationMeta(
    'quarter',
  );
  @override
  late final GeneratedColumn<int> quarter = GeneratedColumn<int>(
    'quarter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameClockSecondsMeta = const VerificationMeta(
    'gameClockSeconds',
  );
  @override
  late final GeneratedColumn<int> gameClockSeconds = GeneratedColumn<int>(
    'game_clock_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shotClockSecondsMeta = const VerificationMeta(
    'shotClockSeconds',
  );
  @override
  late final GeneratedColumn<int> shotClockSeconds = GeneratedColumn<int>(
    'shot_clock_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionSubtypeMeta = const VerificationMeta(
    'actionSubtype',
  );
  @override
  late final GeneratedColumn<String> actionSubtype = GeneratedColumn<String>(
    'action_subtype',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isMadeMeta = const VerificationMeta('isMade');
  @override
  late final GeneratedColumn<bool> isMade = GeneratedColumn<bool>(
    'is_made',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_made" IN (0, 1))',
    ),
  );
  static const VerificationMeta _pointsScoredMeta = const VerificationMeta(
    'pointsScored',
  );
  @override
  late final GeneratedColumn<int> pointsScored = GeneratedColumn<int>(
    'points_scored',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _courtXMeta = const VerificationMeta('courtX');
  @override
  late final GeneratedColumn<double> courtX = GeneratedColumn<double>(
    'court_x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courtYMeta = const VerificationMeta('courtY');
  @override
  late final GeneratedColumn<double> courtY = GeneratedColumn<double>(
    'court_y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courtZoneMeta = const VerificationMeta(
    'courtZone',
  );
  @override
  late final GeneratedColumn<int> courtZone = GeneratedColumn<int>(
    'court_zone',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shotDistanceMeta = const VerificationMeta(
    'shotDistance',
  );
  @override
  late final GeneratedColumn<double> shotDistance = GeneratedColumn<double>(
    'shot_distance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assistPlayerIdMeta = const VerificationMeta(
    'assistPlayerId',
  );
  @override
  late final GeneratedColumn<int> assistPlayerId = GeneratedColumn<int>(
    'assist_player_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reboundPlayerIdMeta = const VerificationMeta(
    'reboundPlayerId',
  );
  @override
  late final GeneratedColumn<int> reboundPlayerId = GeneratedColumn<int>(
    'rebound_player_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blockPlayerIdMeta = const VerificationMeta(
    'blockPlayerId',
  );
  @override
  late final GeneratedColumn<int> blockPlayerId = GeneratedColumn<int>(
    'block_player_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stealPlayerIdMeta = const VerificationMeta(
    'stealPlayerId',
  );
  @override
  late final GeneratedColumn<int> stealPlayerId = GeneratedColumn<int>(
    'steal_player_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fouledPlayerIdMeta = const VerificationMeta(
    'fouledPlayerId',
  );
  @override
  late final GeneratedColumn<int> fouledPlayerId = GeneratedColumn<int>(
    'fouled_player_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subInPlayerIdMeta = const VerificationMeta(
    'subInPlayerId',
  );
  @override
  late final GeneratedColumn<int> subInPlayerId = GeneratedColumn<int>(
    'sub_in_player_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subOutPlayerIdMeta = const VerificationMeta(
    'subOutPlayerId',
  );
  @override
  late final GeneratedColumn<int> subOutPlayerId = GeneratedColumn<int>(
    'sub_out_player_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFlagrantMeta = const VerificationMeta(
    'isFlagrant',
  );
  @override
  late final GeneratedColumn<bool> isFlagrant = GeneratedColumn<bool>(
    'is_flagrant',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_flagrant" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isTechnicalMeta = const VerificationMeta(
    'isTechnical',
  );
  @override
  late final GeneratedColumn<bool> isTechnical = GeneratedColumn<bool>(
    'is_technical',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_technical" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isFastbreakMeta = const VerificationMeta(
    'isFastbreak',
  );
  @override
  late final GeneratedColumn<bool> isFastbreak = GeneratedColumn<bool>(
    'is_fastbreak',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_fastbreak" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSecondChanceMeta = const VerificationMeta(
    'isSecondChance',
  );
  @override
  late final GeneratedColumn<bool> isSecondChance = GeneratedColumn<bool>(
    'is_second_chance',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_second_chance" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isFromTurnoverMeta = const VerificationMeta(
    'isFromTurnover',
  );
  @override
  late final GeneratedColumn<bool> isFromTurnover = GeneratedColumn<bool>(
    'is_from_turnover',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_from_turnover" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _homeScoreAtTimeMeta = const VerificationMeta(
    'homeScoreAtTime',
  );
  @override
  late final GeneratedColumn<int> homeScoreAtTime = GeneratedColumn<int>(
    'home_score_at_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _awayScoreAtTimeMeta = const VerificationMeta(
    'awayScoreAtTime',
  );
  @override
  late final GeneratedColumn<int> awayScoreAtTime = GeneratedColumn<int>(
    'away_score_at_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedActionIdMeta = const VerificationMeta(
    'linkedActionId',
  );
  @override
  late final GeneratedColumn<String> linkedActionId = GeneratedColumn<String>(
    'linked_action_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localId,
    localMatchId,
    tournamentTeamPlayerId,
    tournamentTeamId,
    quarter,
    gameClockSeconds,
    shotClockSeconds,
    actionType,
    actionSubtype,
    isMade,
    pointsScored,
    courtX,
    courtY,
    courtZone,
    shotDistance,
    assistPlayerId,
    reboundPlayerId,
    blockPlayerId,
    stealPlayerId,
    fouledPlayerId,
    subInPlayerId,
    subOutPlayerId,
    isFlagrant,
    isTechnical,
    isFastbreak,
    isSecondChance,
    isFromTurnover,
    homeScoreAtTime,
    awayScoreAtTime,
    description,
    linkedActionId,
    isSynced,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_play_by_plays';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPlayByPlay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('local_match_id')) {
      context.handle(
        _localMatchIdMeta,
        localMatchId.isAcceptableOrUnknown(
          data['local_match_id']!,
          _localMatchIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localMatchIdMeta);
    }
    if (data.containsKey('tournament_team_player_id')) {
      context.handle(
        _tournamentTeamPlayerIdMeta,
        tournamentTeamPlayerId.isAcceptableOrUnknown(
          data['tournament_team_player_id']!,
          _tournamentTeamPlayerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tournamentTeamPlayerIdMeta);
    }
    if (data.containsKey('tournament_team_id')) {
      context.handle(
        _tournamentTeamIdMeta,
        tournamentTeamId.isAcceptableOrUnknown(
          data['tournament_team_id']!,
          _tournamentTeamIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tournamentTeamIdMeta);
    }
    if (data.containsKey('quarter')) {
      context.handle(
        _quarterMeta,
        quarter.isAcceptableOrUnknown(data['quarter']!, _quarterMeta),
      );
    } else if (isInserting) {
      context.missing(_quarterMeta);
    }
    if (data.containsKey('game_clock_seconds')) {
      context.handle(
        _gameClockSecondsMeta,
        gameClockSeconds.isAcceptableOrUnknown(
          data['game_clock_seconds']!,
          _gameClockSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gameClockSecondsMeta);
    }
    if (data.containsKey('shot_clock_seconds')) {
      context.handle(
        _shotClockSecondsMeta,
        shotClockSeconds.isAcceptableOrUnknown(
          data['shot_clock_seconds']!,
          _shotClockSecondsMeta,
        ),
      );
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('action_subtype')) {
      context.handle(
        _actionSubtypeMeta,
        actionSubtype.isAcceptableOrUnknown(
          data['action_subtype']!,
          _actionSubtypeMeta,
        ),
      );
    }
    if (data.containsKey('is_made')) {
      context.handle(
        _isMadeMeta,
        isMade.isAcceptableOrUnknown(data['is_made']!, _isMadeMeta),
      );
    }
    if (data.containsKey('points_scored')) {
      context.handle(
        _pointsScoredMeta,
        pointsScored.isAcceptableOrUnknown(
          data['points_scored']!,
          _pointsScoredMeta,
        ),
      );
    }
    if (data.containsKey('court_x')) {
      context.handle(
        _courtXMeta,
        courtX.isAcceptableOrUnknown(data['court_x']!, _courtXMeta),
      );
    }
    if (data.containsKey('court_y')) {
      context.handle(
        _courtYMeta,
        courtY.isAcceptableOrUnknown(data['court_y']!, _courtYMeta),
      );
    }
    if (data.containsKey('court_zone')) {
      context.handle(
        _courtZoneMeta,
        courtZone.isAcceptableOrUnknown(data['court_zone']!, _courtZoneMeta),
      );
    }
    if (data.containsKey('shot_distance')) {
      context.handle(
        _shotDistanceMeta,
        shotDistance.isAcceptableOrUnknown(
          data['shot_distance']!,
          _shotDistanceMeta,
        ),
      );
    }
    if (data.containsKey('assist_player_id')) {
      context.handle(
        _assistPlayerIdMeta,
        assistPlayerId.isAcceptableOrUnknown(
          data['assist_player_id']!,
          _assistPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('rebound_player_id')) {
      context.handle(
        _reboundPlayerIdMeta,
        reboundPlayerId.isAcceptableOrUnknown(
          data['rebound_player_id']!,
          _reboundPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('block_player_id')) {
      context.handle(
        _blockPlayerIdMeta,
        blockPlayerId.isAcceptableOrUnknown(
          data['block_player_id']!,
          _blockPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('steal_player_id')) {
      context.handle(
        _stealPlayerIdMeta,
        stealPlayerId.isAcceptableOrUnknown(
          data['steal_player_id']!,
          _stealPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('fouled_player_id')) {
      context.handle(
        _fouledPlayerIdMeta,
        fouledPlayerId.isAcceptableOrUnknown(
          data['fouled_player_id']!,
          _fouledPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('sub_in_player_id')) {
      context.handle(
        _subInPlayerIdMeta,
        subInPlayerId.isAcceptableOrUnknown(
          data['sub_in_player_id']!,
          _subInPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('sub_out_player_id')) {
      context.handle(
        _subOutPlayerIdMeta,
        subOutPlayerId.isAcceptableOrUnknown(
          data['sub_out_player_id']!,
          _subOutPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('is_flagrant')) {
      context.handle(
        _isFlagrantMeta,
        isFlagrant.isAcceptableOrUnknown(data['is_flagrant']!, _isFlagrantMeta),
      );
    }
    if (data.containsKey('is_technical')) {
      context.handle(
        _isTechnicalMeta,
        isTechnical.isAcceptableOrUnknown(
          data['is_technical']!,
          _isTechnicalMeta,
        ),
      );
    }
    if (data.containsKey('is_fastbreak')) {
      context.handle(
        _isFastbreakMeta,
        isFastbreak.isAcceptableOrUnknown(
          data['is_fastbreak']!,
          _isFastbreakMeta,
        ),
      );
    }
    if (data.containsKey('is_second_chance')) {
      context.handle(
        _isSecondChanceMeta,
        isSecondChance.isAcceptableOrUnknown(
          data['is_second_chance']!,
          _isSecondChanceMeta,
        ),
      );
    }
    if (data.containsKey('is_from_turnover')) {
      context.handle(
        _isFromTurnoverMeta,
        isFromTurnover.isAcceptableOrUnknown(
          data['is_from_turnover']!,
          _isFromTurnoverMeta,
        ),
      );
    }
    if (data.containsKey('home_score_at_time')) {
      context.handle(
        _homeScoreAtTimeMeta,
        homeScoreAtTime.isAcceptableOrUnknown(
          data['home_score_at_time']!,
          _homeScoreAtTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_homeScoreAtTimeMeta);
    }
    if (data.containsKey('away_score_at_time')) {
      context.handle(
        _awayScoreAtTimeMeta,
        awayScoreAtTime.isAcceptableOrUnknown(
          data['away_score_at_time']!,
          _awayScoreAtTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_awayScoreAtTimeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('linked_action_id')) {
      context.handle(
        _linkedActionIdMeta,
        linkedActionId.isAcceptableOrUnknown(
          data['linked_action_id']!,
          _linkedActionIdMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlayByPlay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlayByPlay(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      localId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}local_id'],
          )!,
      localMatchId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}local_match_id'],
          )!,
      tournamentTeamPlayerId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}tournament_team_player_id'],
          )!,
      tournamentTeamId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}tournament_team_id'],
          )!,
      quarter:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}quarter'],
          )!,
      gameClockSeconds:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}game_clock_seconds'],
          )!,
      shotClockSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shot_clock_seconds'],
      ),
      actionType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}action_type'],
          )!,
      actionSubtype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_subtype'],
      ),
      isMade: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_made'],
      ),
      pointsScored:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}points_scored'],
          )!,
      courtX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}court_x'],
      ),
      courtY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}court_y'],
      ),
      courtZone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}court_zone'],
      ),
      shotDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shot_distance'],
      ),
      assistPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}assist_player_id'],
      ),
      reboundPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rebound_player_id'],
      ),
      blockPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}block_player_id'],
      ),
      stealPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steal_player_id'],
      ),
      fouledPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fouled_player_id'],
      ),
      subInPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sub_in_player_id'],
      ),
      subOutPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sub_out_player_id'],
      ),
      isFlagrant:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_flagrant'],
          )!,
      isTechnical:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_technical'],
          )!,
      isFastbreak:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_fastbreak'],
          )!,
      isSecondChance:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_second_chance'],
          )!,
      isFromTurnover:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_from_turnover'],
          )!,
      homeScoreAtTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}home_score_at_time'],
          )!,
      awayScoreAtTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}away_score_at_time'],
          )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      linkedActionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_action_id'],
      ),
      isSynced:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_synced'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $LocalPlayByPlaysTable createAlias(String alias) {
    return $LocalPlayByPlaysTable(attachedDatabase, alias);
  }
}

class LocalPlayByPlay extends DataClass implements Insertable<LocalPlayByPlay> {
  final int id;
  final String localId;
  final int localMatchId;
  final int tournamentTeamPlayerId;
  final int tournamentTeamId;
  final int quarter;
  final int gameClockSeconds;
  final int? shotClockSeconds;
  final String actionType;
  final String? actionSubtype;
  final bool? isMade;
  final int pointsScored;
  final double? courtX;
  final double? courtY;
  final int? courtZone;
  final double? shotDistance;
  final int? assistPlayerId;
  final int? reboundPlayerId;
  final int? blockPlayerId;
  final int? stealPlayerId;
  final int? fouledPlayerId;
  final int? subInPlayerId;
  final int? subOutPlayerId;
  final bool isFlagrant;
  final bool isTechnical;
  final bool isFastbreak;
  final bool isSecondChance;
  final bool isFromTurnover;
  final int homeScoreAtTime;
  final int awayScoreAtTime;
  final String? description;
  final String? linkedActionId;
  final bool isSynced;
  final DateTime createdAt;
  const LocalPlayByPlay({
    required this.id,
    required this.localId,
    required this.localMatchId,
    required this.tournamentTeamPlayerId,
    required this.tournamentTeamId,
    required this.quarter,
    required this.gameClockSeconds,
    this.shotClockSeconds,
    required this.actionType,
    this.actionSubtype,
    this.isMade,
    required this.pointsScored,
    this.courtX,
    this.courtY,
    this.courtZone,
    this.shotDistance,
    this.assistPlayerId,
    this.reboundPlayerId,
    this.blockPlayerId,
    this.stealPlayerId,
    this.fouledPlayerId,
    this.subInPlayerId,
    this.subOutPlayerId,
    required this.isFlagrant,
    required this.isTechnical,
    required this.isFastbreak,
    required this.isSecondChance,
    required this.isFromTurnover,
    required this.homeScoreAtTime,
    required this.awayScoreAtTime,
    this.description,
    this.linkedActionId,
    required this.isSynced,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_id'] = Variable<String>(localId);
    map['local_match_id'] = Variable<int>(localMatchId);
    map['tournament_team_player_id'] = Variable<int>(tournamentTeamPlayerId);
    map['tournament_team_id'] = Variable<int>(tournamentTeamId);
    map['quarter'] = Variable<int>(quarter);
    map['game_clock_seconds'] = Variable<int>(gameClockSeconds);
    if (!nullToAbsent || shotClockSeconds != null) {
      map['shot_clock_seconds'] = Variable<int>(shotClockSeconds);
    }
    map['action_type'] = Variable<String>(actionType);
    if (!nullToAbsent || actionSubtype != null) {
      map['action_subtype'] = Variable<String>(actionSubtype);
    }
    if (!nullToAbsent || isMade != null) {
      map['is_made'] = Variable<bool>(isMade);
    }
    map['points_scored'] = Variable<int>(pointsScored);
    if (!nullToAbsent || courtX != null) {
      map['court_x'] = Variable<double>(courtX);
    }
    if (!nullToAbsent || courtY != null) {
      map['court_y'] = Variable<double>(courtY);
    }
    if (!nullToAbsent || courtZone != null) {
      map['court_zone'] = Variable<int>(courtZone);
    }
    if (!nullToAbsent || shotDistance != null) {
      map['shot_distance'] = Variable<double>(shotDistance);
    }
    if (!nullToAbsent || assistPlayerId != null) {
      map['assist_player_id'] = Variable<int>(assistPlayerId);
    }
    if (!nullToAbsent || reboundPlayerId != null) {
      map['rebound_player_id'] = Variable<int>(reboundPlayerId);
    }
    if (!nullToAbsent || blockPlayerId != null) {
      map['block_player_id'] = Variable<int>(blockPlayerId);
    }
    if (!nullToAbsent || stealPlayerId != null) {
      map['steal_player_id'] = Variable<int>(stealPlayerId);
    }
    if (!nullToAbsent || fouledPlayerId != null) {
      map['fouled_player_id'] = Variable<int>(fouledPlayerId);
    }
    if (!nullToAbsent || subInPlayerId != null) {
      map['sub_in_player_id'] = Variable<int>(subInPlayerId);
    }
    if (!nullToAbsent || subOutPlayerId != null) {
      map['sub_out_player_id'] = Variable<int>(subOutPlayerId);
    }
    map['is_flagrant'] = Variable<bool>(isFlagrant);
    map['is_technical'] = Variable<bool>(isTechnical);
    map['is_fastbreak'] = Variable<bool>(isFastbreak);
    map['is_second_chance'] = Variable<bool>(isSecondChance);
    map['is_from_turnover'] = Variable<bool>(isFromTurnover);
    map['home_score_at_time'] = Variable<int>(homeScoreAtTime);
    map['away_score_at_time'] = Variable<int>(awayScoreAtTime);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || linkedActionId != null) {
      map['linked_action_id'] = Variable<String>(linkedActionId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalPlayByPlaysCompanion toCompanion(bool nullToAbsent) {
    return LocalPlayByPlaysCompanion(
      id: Value(id),
      localId: Value(localId),
      localMatchId: Value(localMatchId),
      tournamentTeamPlayerId: Value(tournamentTeamPlayerId),
      tournamentTeamId: Value(tournamentTeamId),
      quarter: Value(quarter),
      gameClockSeconds: Value(gameClockSeconds),
      shotClockSeconds:
          shotClockSeconds == null && nullToAbsent
              ? const Value.absent()
              : Value(shotClockSeconds),
      actionType: Value(actionType),
      actionSubtype:
          actionSubtype == null && nullToAbsent
              ? const Value.absent()
              : Value(actionSubtype),
      isMade:
          isMade == null && nullToAbsent ? const Value.absent() : Value(isMade),
      pointsScored: Value(pointsScored),
      courtX:
          courtX == null && nullToAbsent ? const Value.absent() : Value(courtX),
      courtY:
          courtY == null && nullToAbsent ? const Value.absent() : Value(courtY),
      courtZone:
          courtZone == null && nullToAbsent
              ? const Value.absent()
              : Value(courtZone),
      shotDistance:
          shotDistance == null && nullToAbsent
              ? const Value.absent()
              : Value(shotDistance),
      assistPlayerId:
          assistPlayerId == null && nullToAbsent
              ? const Value.absent()
              : Value(assistPlayerId),
      reboundPlayerId:
          reboundPlayerId == null && nullToAbsent
              ? const Value.absent()
              : Value(reboundPlayerId),
      blockPlayerId:
          blockPlayerId == null && nullToAbsent
              ? const Value.absent()
              : Value(blockPlayerId),
      stealPlayerId:
          stealPlayerId == null && nullToAbsent
              ? const Value.absent()
              : Value(stealPlayerId),
      fouledPlayerId:
          fouledPlayerId == null && nullToAbsent
              ? const Value.absent()
              : Value(fouledPlayerId),
      subInPlayerId:
          subInPlayerId == null && nullToAbsent
              ? const Value.absent()
              : Value(subInPlayerId),
      subOutPlayerId:
          subOutPlayerId == null && nullToAbsent
              ? const Value.absent()
              : Value(subOutPlayerId),
      isFlagrant: Value(isFlagrant),
      isTechnical: Value(isTechnical),
      isFastbreak: Value(isFastbreak),
      isSecondChance: Value(isSecondChance),
      isFromTurnover: Value(isFromTurnover),
      homeScoreAtTime: Value(homeScoreAtTime),
      awayScoreAtTime: Value(awayScoreAtTime),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
      linkedActionId:
          linkedActionId == null && nullToAbsent
              ? const Value.absent()
              : Value(linkedActionId),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
    );
  }

  factory LocalPlayByPlay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlayByPlay(
      id: serializer.fromJson<int>(json['id']),
      localId: serializer.fromJson<String>(json['localId']),
      localMatchId: serializer.fromJson<int>(json['localMatchId']),
      tournamentTeamPlayerId: serializer.fromJson<int>(
        json['tournamentTeamPlayerId'],
      ),
      tournamentTeamId: serializer.fromJson<int>(json['tournamentTeamId']),
      quarter: serializer.fromJson<int>(json['quarter']),
      gameClockSeconds: serializer.fromJson<int>(json['gameClockSeconds']),
      shotClockSeconds: serializer.fromJson<int?>(json['shotClockSeconds']),
      actionType: serializer.fromJson<String>(json['actionType']),
      actionSubtype: serializer.fromJson<String?>(json['actionSubtype']),
      isMade: serializer.fromJson<bool?>(json['isMade']),
      pointsScored: serializer.fromJson<int>(json['pointsScored']),
      courtX: serializer.fromJson<double?>(json['courtX']),
      courtY: serializer.fromJson<double?>(json['courtY']),
      courtZone: serializer.fromJson<int?>(json['courtZone']),
      shotDistance: serializer.fromJson<double?>(json['shotDistance']),
      assistPlayerId: serializer.fromJson<int?>(json['assistPlayerId']),
      reboundPlayerId: serializer.fromJson<int?>(json['reboundPlayerId']),
      blockPlayerId: serializer.fromJson<int?>(json['blockPlayerId']),
      stealPlayerId: serializer.fromJson<int?>(json['stealPlayerId']),
      fouledPlayerId: serializer.fromJson<int?>(json['fouledPlayerId']),
      subInPlayerId: serializer.fromJson<int?>(json['subInPlayerId']),
      subOutPlayerId: serializer.fromJson<int?>(json['subOutPlayerId']),
      isFlagrant: serializer.fromJson<bool>(json['isFlagrant']),
      isTechnical: serializer.fromJson<bool>(json['isTechnical']),
      isFastbreak: serializer.fromJson<bool>(json['isFastbreak']),
      isSecondChance: serializer.fromJson<bool>(json['isSecondChance']),
      isFromTurnover: serializer.fromJson<bool>(json['isFromTurnover']),
      homeScoreAtTime: serializer.fromJson<int>(json['homeScoreAtTime']),
      awayScoreAtTime: serializer.fromJson<int>(json['awayScoreAtTime']),
      description: serializer.fromJson<String?>(json['description']),
      linkedActionId: serializer.fromJson<String?>(json['linkedActionId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localId': serializer.toJson<String>(localId),
      'localMatchId': serializer.toJson<int>(localMatchId),
      'tournamentTeamPlayerId': serializer.toJson<int>(tournamentTeamPlayerId),
      'tournamentTeamId': serializer.toJson<int>(tournamentTeamId),
      'quarter': serializer.toJson<int>(quarter),
      'gameClockSeconds': serializer.toJson<int>(gameClockSeconds),
      'shotClockSeconds': serializer.toJson<int?>(shotClockSeconds),
      'actionType': serializer.toJson<String>(actionType),
      'actionSubtype': serializer.toJson<String?>(actionSubtype),
      'isMade': serializer.toJson<bool?>(isMade),
      'pointsScored': serializer.toJson<int>(pointsScored),
      'courtX': serializer.toJson<double?>(courtX),
      'courtY': serializer.toJson<double?>(courtY),
      'courtZone': serializer.toJson<int?>(courtZone),
      'shotDistance': serializer.toJson<double?>(shotDistance),
      'assistPlayerId': serializer.toJson<int?>(assistPlayerId),
      'reboundPlayerId': serializer.toJson<int?>(reboundPlayerId),
      'blockPlayerId': serializer.toJson<int?>(blockPlayerId),
      'stealPlayerId': serializer.toJson<int?>(stealPlayerId),
      'fouledPlayerId': serializer.toJson<int?>(fouledPlayerId),
      'subInPlayerId': serializer.toJson<int?>(subInPlayerId),
      'subOutPlayerId': serializer.toJson<int?>(subOutPlayerId),
      'isFlagrant': serializer.toJson<bool>(isFlagrant),
      'isTechnical': serializer.toJson<bool>(isTechnical),
      'isFastbreak': serializer.toJson<bool>(isFastbreak),
      'isSecondChance': serializer.toJson<bool>(isSecondChance),
      'isFromTurnover': serializer.toJson<bool>(isFromTurnover),
      'homeScoreAtTime': serializer.toJson<int>(homeScoreAtTime),
      'awayScoreAtTime': serializer.toJson<int>(awayScoreAtTime),
      'description': serializer.toJson<String?>(description),
      'linkedActionId': serializer.toJson<String?>(linkedActionId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalPlayByPlay copyWith({
    int? id,
    String? localId,
    int? localMatchId,
    int? tournamentTeamPlayerId,
    int? tournamentTeamId,
    int? quarter,
    int? gameClockSeconds,
    Value<int?> shotClockSeconds = const Value.absent(),
    String? actionType,
    Value<String?> actionSubtype = const Value.absent(),
    Value<bool?> isMade = const Value.absent(),
    int? pointsScored,
    Value<double?> courtX = const Value.absent(),
    Value<double?> courtY = const Value.absent(),
    Value<int?> courtZone = const Value.absent(),
    Value<double?> shotDistance = const Value.absent(),
    Value<int?> assistPlayerId = const Value.absent(),
    Value<int?> reboundPlayerId = const Value.absent(),
    Value<int?> blockPlayerId = const Value.absent(),
    Value<int?> stealPlayerId = const Value.absent(),
    Value<int?> fouledPlayerId = const Value.absent(),
    Value<int?> subInPlayerId = const Value.absent(),
    Value<int?> subOutPlayerId = const Value.absent(),
    bool? isFlagrant,
    bool? isTechnical,
    bool? isFastbreak,
    bool? isSecondChance,
    bool? isFromTurnover,
    int? homeScoreAtTime,
    int? awayScoreAtTime,
    Value<String?> description = const Value.absent(),
    Value<String?> linkedActionId = const Value.absent(),
    bool? isSynced,
    DateTime? createdAt,
  }) => LocalPlayByPlay(
    id: id ?? this.id,
    localId: localId ?? this.localId,
    localMatchId: localMatchId ?? this.localMatchId,
    tournamentTeamPlayerId:
        tournamentTeamPlayerId ?? this.tournamentTeamPlayerId,
    tournamentTeamId: tournamentTeamId ?? this.tournamentTeamId,
    quarter: quarter ?? this.quarter,
    gameClockSeconds: gameClockSeconds ?? this.gameClockSeconds,
    shotClockSeconds:
        shotClockSeconds.present
            ? shotClockSeconds.value
            : this.shotClockSeconds,
    actionType: actionType ?? this.actionType,
    actionSubtype:
        actionSubtype.present ? actionSubtype.value : this.actionSubtype,
    isMade: isMade.present ? isMade.value : this.isMade,
    pointsScored: pointsScored ?? this.pointsScored,
    courtX: courtX.present ? courtX.value : this.courtX,
    courtY: courtY.present ? courtY.value : this.courtY,
    courtZone: courtZone.present ? courtZone.value : this.courtZone,
    shotDistance: shotDistance.present ? shotDistance.value : this.shotDistance,
    assistPlayerId:
        assistPlayerId.present ? assistPlayerId.value : this.assistPlayerId,
    reboundPlayerId:
        reboundPlayerId.present ? reboundPlayerId.value : this.reboundPlayerId,
    blockPlayerId:
        blockPlayerId.present ? blockPlayerId.value : this.blockPlayerId,
    stealPlayerId:
        stealPlayerId.present ? stealPlayerId.value : this.stealPlayerId,
    fouledPlayerId:
        fouledPlayerId.present ? fouledPlayerId.value : this.fouledPlayerId,
    subInPlayerId:
        subInPlayerId.present ? subInPlayerId.value : this.subInPlayerId,
    subOutPlayerId:
        subOutPlayerId.present ? subOutPlayerId.value : this.subOutPlayerId,
    isFlagrant: isFlagrant ?? this.isFlagrant,
    isTechnical: isTechnical ?? this.isTechnical,
    isFastbreak: isFastbreak ?? this.isFastbreak,
    isSecondChance: isSecondChance ?? this.isSecondChance,
    isFromTurnover: isFromTurnover ?? this.isFromTurnover,
    homeScoreAtTime: homeScoreAtTime ?? this.homeScoreAtTime,
    awayScoreAtTime: awayScoreAtTime ?? this.awayScoreAtTime,
    description: description.present ? description.value : this.description,
    linkedActionId:
        linkedActionId.present ? linkedActionId.value : this.linkedActionId,
    isSynced: isSynced ?? this.isSynced,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalPlayByPlay copyWithCompanion(LocalPlayByPlaysCompanion data) {
    return LocalPlayByPlay(
      id: data.id.present ? data.id.value : this.id,
      localId: data.localId.present ? data.localId.value : this.localId,
      localMatchId:
          data.localMatchId.present
              ? data.localMatchId.value
              : this.localMatchId,
      tournamentTeamPlayerId:
          data.tournamentTeamPlayerId.present
              ? data.tournamentTeamPlayerId.value
              : this.tournamentTeamPlayerId,
      tournamentTeamId:
          data.tournamentTeamId.present
              ? data.tournamentTeamId.value
              : this.tournamentTeamId,
      quarter: data.quarter.present ? data.quarter.value : this.quarter,
      gameClockSeconds:
          data.gameClockSeconds.present
              ? data.gameClockSeconds.value
              : this.gameClockSeconds,
      shotClockSeconds:
          data.shotClockSeconds.present
              ? data.shotClockSeconds.value
              : this.shotClockSeconds,
      actionType:
          data.actionType.present ? data.actionType.value : this.actionType,
      actionSubtype:
          data.actionSubtype.present
              ? data.actionSubtype.value
              : this.actionSubtype,
      isMade: data.isMade.present ? data.isMade.value : this.isMade,
      pointsScored:
          data.pointsScored.present
              ? data.pointsScored.value
              : this.pointsScored,
      courtX: data.courtX.present ? data.courtX.value : this.courtX,
      courtY: data.courtY.present ? data.courtY.value : this.courtY,
      courtZone: data.courtZone.present ? data.courtZone.value : this.courtZone,
      shotDistance:
          data.shotDistance.present
              ? data.shotDistance.value
              : this.shotDistance,
      assistPlayerId:
          data.assistPlayerId.present
              ? data.assistPlayerId.value
              : this.assistPlayerId,
      reboundPlayerId:
          data.reboundPlayerId.present
              ? data.reboundPlayerId.value
              : this.reboundPlayerId,
      blockPlayerId:
          data.blockPlayerId.present
              ? data.blockPlayerId.value
              : this.blockPlayerId,
      stealPlayerId:
          data.stealPlayerId.present
              ? data.stealPlayerId.value
              : this.stealPlayerId,
      fouledPlayerId:
          data.fouledPlayerId.present
              ? data.fouledPlayerId.value
              : this.fouledPlayerId,
      subInPlayerId:
          data.subInPlayerId.present
              ? data.subInPlayerId.value
              : this.subInPlayerId,
      subOutPlayerId:
          data.subOutPlayerId.present
              ? data.subOutPlayerId.value
              : this.subOutPlayerId,
      isFlagrant:
          data.isFlagrant.present ? data.isFlagrant.value : this.isFlagrant,
      isTechnical:
          data.isTechnical.present ? data.isTechnical.value : this.isTechnical,
      isFastbreak:
          data.isFastbreak.present ? data.isFastbreak.value : this.isFastbreak,
      isSecondChance:
          data.isSecondChance.present
              ? data.isSecondChance.value
              : this.isSecondChance,
      isFromTurnover:
          data.isFromTurnover.present
              ? data.isFromTurnover.value
              : this.isFromTurnover,
      homeScoreAtTime:
          data.homeScoreAtTime.present
              ? data.homeScoreAtTime.value
              : this.homeScoreAtTime,
      awayScoreAtTime:
          data.awayScoreAtTime.present
              ? data.awayScoreAtTime.value
              : this.awayScoreAtTime,
      description:
          data.description.present ? data.description.value : this.description,
      linkedActionId:
          data.linkedActionId.present
              ? data.linkedActionId.value
              : this.linkedActionId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlayByPlay(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('localMatchId: $localMatchId, ')
          ..write('tournamentTeamPlayerId: $tournamentTeamPlayerId, ')
          ..write('tournamentTeamId: $tournamentTeamId, ')
          ..write('quarter: $quarter, ')
          ..write('gameClockSeconds: $gameClockSeconds, ')
          ..write('shotClockSeconds: $shotClockSeconds, ')
          ..write('actionType: $actionType, ')
          ..write('actionSubtype: $actionSubtype, ')
          ..write('isMade: $isMade, ')
          ..write('pointsScored: $pointsScored, ')
          ..write('courtX: $courtX, ')
          ..write('courtY: $courtY, ')
          ..write('courtZone: $courtZone, ')
          ..write('shotDistance: $shotDistance, ')
          ..write('assistPlayerId: $assistPlayerId, ')
          ..write('reboundPlayerId: $reboundPlayerId, ')
          ..write('blockPlayerId: $blockPlayerId, ')
          ..write('stealPlayerId: $stealPlayerId, ')
          ..write('fouledPlayerId: $fouledPlayerId, ')
          ..write('subInPlayerId: $subInPlayerId, ')
          ..write('subOutPlayerId: $subOutPlayerId, ')
          ..write('isFlagrant: $isFlagrant, ')
          ..write('isTechnical: $isTechnical, ')
          ..write('isFastbreak: $isFastbreak, ')
          ..write('isSecondChance: $isSecondChance, ')
          ..write('isFromTurnover: $isFromTurnover, ')
          ..write('homeScoreAtTime: $homeScoreAtTime, ')
          ..write('awayScoreAtTime: $awayScoreAtTime, ')
          ..write('description: $description, ')
          ..write('linkedActionId: $linkedActionId, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    localId,
    localMatchId,
    tournamentTeamPlayerId,
    tournamentTeamId,
    quarter,
    gameClockSeconds,
    shotClockSeconds,
    actionType,
    actionSubtype,
    isMade,
    pointsScored,
    courtX,
    courtY,
    courtZone,
    shotDistance,
    assistPlayerId,
    reboundPlayerId,
    blockPlayerId,
    stealPlayerId,
    fouledPlayerId,
    subInPlayerId,
    subOutPlayerId,
    isFlagrant,
    isTechnical,
    isFastbreak,
    isSecondChance,
    isFromTurnover,
    homeScoreAtTime,
    awayScoreAtTime,
    description,
    linkedActionId,
    isSynced,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlayByPlay &&
          other.id == this.id &&
          other.localId == this.localId &&
          other.localMatchId == this.localMatchId &&
          other.tournamentTeamPlayerId == this.tournamentTeamPlayerId &&
          other.tournamentTeamId == this.tournamentTeamId &&
          other.quarter == this.quarter &&
          other.gameClockSeconds == this.gameClockSeconds &&
          other.shotClockSeconds == this.shotClockSeconds &&
          other.actionType == this.actionType &&
          other.actionSubtype == this.actionSubtype &&
          other.isMade == this.isMade &&
          other.pointsScored == this.pointsScored &&
          other.courtX == this.courtX &&
          other.courtY == this.courtY &&
          other.courtZone == this.courtZone &&
          other.shotDistance == this.shotDistance &&
          other.assistPlayerId == this.assistPlayerId &&
          other.reboundPlayerId == this.reboundPlayerId &&
          other.blockPlayerId == this.blockPlayerId &&
          other.stealPlayerId == this.stealPlayerId &&
          other.fouledPlayerId == this.fouledPlayerId &&
          other.subInPlayerId == this.subInPlayerId &&
          other.subOutPlayerId == this.subOutPlayerId &&
          other.isFlagrant == this.isFlagrant &&
          other.isTechnical == this.isTechnical &&
          other.isFastbreak == this.isFastbreak &&
          other.isSecondChance == this.isSecondChance &&
          other.isFromTurnover == this.isFromTurnover &&
          other.homeScoreAtTime == this.homeScoreAtTime &&
          other.awayScoreAtTime == this.awayScoreAtTime &&
          other.description == this.description &&
          other.linkedActionId == this.linkedActionId &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt);
}

class LocalPlayByPlaysCompanion extends UpdateCompanion<LocalPlayByPlay> {
  final Value<int> id;
  final Value<String> localId;
  final Value<int> localMatchId;
  final Value<int> tournamentTeamPlayerId;
  final Value<int> tournamentTeamId;
  final Value<int> quarter;
  final Value<int> gameClockSeconds;
  final Value<int?> shotClockSeconds;
  final Value<String> actionType;
  final Value<String?> actionSubtype;
  final Value<bool?> isMade;
  final Value<int> pointsScored;
  final Value<double?> courtX;
  final Value<double?> courtY;
  final Value<int?> courtZone;
  final Value<double?> shotDistance;
  final Value<int?> assistPlayerId;
  final Value<int?> reboundPlayerId;
  final Value<int?> blockPlayerId;
  final Value<int?> stealPlayerId;
  final Value<int?> fouledPlayerId;
  final Value<int?> subInPlayerId;
  final Value<int?> subOutPlayerId;
  final Value<bool> isFlagrant;
  final Value<bool> isTechnical;
  final Value<bool> isFastbreak;
  final Value<bool> isSecondChance;
  final Value<bool> isFromTurnover;
  final Value<int> homeScoreAtTime;
  final Value<int> awayScoreAtTime;
  final Value<String?> description;
  final Value<String?> linkedActionId;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  const LocalPlayByPlaysCompanion({
    this.id = const Value.absent(),
    this.localId = const Value.absent(),
    this.localMatchId = const Value.absent(),
    this.tournamentTeamPlayerId = const Value.absent(),
    this.tournamentTeamId = const Value.absent(),
    this.quarter = const Value.absent(),
    this.gameClockSeconds = const Value.absent(),
    this.shotClockSeconds = const Value.absent(),
    this.actionType = const Value.absent(),
    this.actionSubtype = const Value.absent(),
    this.isMade = const Value.absent(),
    this.pointsScored = const Value.absent(),
    this.courtX = const Value.absent(),
    this.courtY = const Value.absent(),
    this.courtZone = const Value.absent(),
    this.shotDistance = const Value.absent(),
    this.assistPlayerId = const Value.absent(),
    this.reboundPlayerId = const Value.absent(),
    this.blockPlayerId = const Value.absent(),
    this.stealPlayerId = const Value.absent(),
    this.fouledPlayerId = const Value.absent(),
    this.subInPlayerId = const Value.absent(),
    this.subOutPlayerId = const Value.absent(),
    this.isFlagrant = const Value.absent(),
    this.isTechnical = const Value.absent(),
    this.isFastbreak = const Value.absent(),
    this.isSecondChance = const Value.absent(),
    this.isFromTurnover = const Value.absent(),
    this.homeScoreAtTime = const Value.absent(),
    this.awayScoreAtTime = const Value.absent(),
    this.description = const Value.absent(),
    this.linkedActionId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalPlayByPlaysCompanion.insert({
    this.id = const Value.absent(),
    required String localId,
    required int localMatchId,
    required int tournamentTeamPlayerId,
    required int tournamentTeamId,
    required int quarter,
    required int gameClockSeconds,
    this.shotClockSeconds = const Value.absent(),
    required String actionType,
    this.actionSubtype = const Value.absent(),
    this.isMade = const Value.absent(),
    this.pointsScored = const Value.absent(),
    this.courtX = const Value.absent(),
    this.courtY = const Value.absent(),
    this.courtZone = const Value.absent(),
    this.shotDistance = const Value.absent(),
    this.assistPlayerId = const Value.absent(),
    this.reboundPlayerId = const Value.absent(),
    this.blockPlayerId = const Value.absent(),
    this.stealPlayerId = const Value.absent(),
    this.fouledPlayerId = const Value.absent(),
    this.subInPlayerId = const Value.absent(),
    this.subOutPlayerId = const Value.absent(),
    this.isFlagrant = const Value.absent(),
    this.isTechnical = const Value.absent(),
    this.isFastbreak = const Value.absent(),
    this.isSecondChance = const Value.absent(),
    this.isFromTurnover = const Value.absent(),
    required int homeScoreAtTime,
    required int awayScoreAtTime,
    this.description = const Value.absent(),
    this.linkedActionId = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
  }) : localId = Value(localId),
       localMatchId = Value(localMatchId),
       tournamentTeamPlayerId = Value(tournamentTeamPlayerId),
       tournamentTeamId = Value(tournamentTeamId),
       quarter = Value(quarter),
       gameClockSeconds = Value(gameClockSeconds),
       actionType = Value(actionType),
       homeScoreAtTime = Value(homeScoreAtTime),
       awayScoreAtTime = Value(awayScoreAtTime),
       createdAt = Value(createdAt);
  static Insertable<LocalPlayByPlay> custom({
    Expression<int>? id,
    Expression<String>? localId,
    Expression<int>? localMatchId,
    Expression<int>? tournamentTeamPlayerId,
    Expression<int>? tournamentTeamId,
    Expression<int>? quarter,
    Expression<int>? gameClockSeconds,
    Expression<int>? shotClockSeconds,
    Expression<String>? actionType,
    Expression<String>? actionSubtype,
    Expression<bool>? isMade,
    Expression<int>? pointsScored,
    Expression<double>? courtX,
    Expression<double>? courtY,
    Expression<int>? courtZone,
    Expression<double>? shotDistance,
    Expression<int>? assistPlayerId,
    Expression<int>? reboundPlayerId,
    Expression<int>? blockPlayerId,
    Expression<int>? stealPlayerId,
    Expression<int>? fouledPlayerId,
    Expression<int>? subInPlayerId,
    Expression<int>? subOutPlayerId,
    Expression<bool>? isFlagrant,
    Expression<bool>? isTechnical,
    Expression<bool>? isFastbreak,
    Expression<bool>? isSecondChance,
    Expression<bool>? isFromTurnover,
    Expression<int>? homeScoreAtTime,
    Expression<int>? awayScoreAtTime,
    Expression<String>? description,
    Expression<String>? linkedActionId,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localId != null) 'local_id': localId,
      if (localMatchId != null) 'local_match_id': localMatchId,
      if (tournamentTeamPlayerId != null)
        'tournament_team_player_id': tournamentTeamPlayerId,
      if (tournamentTeamId != null) 'tournament_team_id': tournamentTeamId,
      if (quarter != null) 'quarter': quarter,
      if (gameClockSeconds != null) 'game_clock_seconds': gameClockSeconds,
      if (shotClockSeconds != null) 'shot_clock_seconds': shotClockSeconds,
      if (actionType != null) 'action_type': actionType,
      if (actionSubtype != null) 'action_subtype': actionSubtype,
      if (isMade != null) 'is_made': isMade,
      if (pointsScored != null) 'points_scored': pointsScored,
      if (courtX != null) 'court_x': courtX,
      if (courtY != null) 'court_y': courtY,
      if (courtZone != null) 'court_zone': courtZone,
      if (shotDistance != null) 'shot_distance': shotDistance,
      if (assistPlayerId != null) 'assist_player_id': assistPlayerId,
      if (reboundPlayerId != null) 'rebound_player_id': reboundPlayerId,
      if (blockPlayerId != null) 'block_player_id': blockPlayerId,
      if (stealPlayerId != null) 'steal_player_id': stealPlayerId,
      if (fouledPlayerId != null) 'fouled_player_id': fouledPlayerId,
      if (subInPlayerId != null) 'sub_in_player_id': subInPlayerId,
      if (subOutPlayerId != null) 'sub_out_player_id': subOutPlayerId,
      if (isFlagrant != null) 'is_flagrant': isFlagrant,
      if (isTechnical != null) 'is_technical': isTechnical,
      if (isFastbreak != null) 'is_fastbreak': isFastbreak,
      if (isSecondChance != null) 'is_second_chance': isSecondChance,
      if (isFromTurnover != null) 'is_from_turnover': isFromTurnover,
      if (homeScoreAtTime != null) 'home_score_at_time': homeScoreAtTime,
      if (awayScoreAtTime != null) 'away_score_at_time': awayScoreAtTime,
      if (description != null) 'description': description,
      if (linkedActionId != null) 'linked_action_id': linkedActionId,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalPlayByPlaysCompanion copyWith({
    Value<int>? id,
    Value<String>? localId,
    Value<int>? localMatchId,
    Value<int>? tournamentTeamPlayerId,
    Value<int>? tournamentTeamId,
    Value<int>? quarter,
    Value<int>? gameClockSeconds,
    Value<int?>? shotClockSeconds,
    Value<String>? actionType,
    Value<String?>? actionSubtype,
    Value<bool?>? isMade,
    Value<int>? pointsScored,
    Value<double?>? courtX,
    Value<double?>? courtY,
    Value<int?>? courtZone,
    Value<double?>? shotDistance,
    Value<int?>? assistPlayerId,
    Value<int?>? reboundPlayerId,
    Value<int?>? blockPlayerId,
    Value<int?>? stealPlayerId,
    Value<int?>? fouledPlayerId,
    Value<int?>? subInPlayerId,
    Value<int?>? subOutPlayerId,
    Value<bool>? isFlagrant,
    Value<bool>? isTechnical,
    Value<bool>? isFastbreak,
    Value<bool>? isSecondChance,
    Value<bool>? isFromTurnover,
    Value<int>? homeScoreAtTime,
    Value<int>? awayScoreAtTime,
    Value<String?>? description,
    Value<String?>? linkedActionId,
    Value<bool>? isSynced,
    Value<DateTime>? createdAt,
  }) {
    return LocalPlayByPlaysCompanion(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      localMatchId: localMatchId ?? this.localMatchId,
      tournamentTeamPlayerId:
          tournamentTeamPlayerId ?? this.tournamentTeamPlayerId,
      tournamentTeamId: tournamentTeamId ?? this.tournamentTeamId,
      quarter: quarter ?? this.quarter,
      gameClockSeconds: gameClockSeconds ?? this.gameClockSeconds,
      shotClockSeconds: shotClockSeconds ?? this.shotClockSeconds,
      actionType: actionType ?? this.actionType,
      actionSubtype: actionSubtype ?? this.actionSubtype,
      isMade: isMade ?? this.isMade,
      pointsScored: pointsScored ?? this.pointsScored,
      courtX: courtX ?? this.courtX,
      courtY: courtY ?? this.courtY,
      courtZone: courtZone ?? this.courtZone,
      shotDistance: shotDistance ?? this.shotDistance,
      assistPlayerId: assistPlayerId ?? this.assistPlayerId,
      reboundPlayerId: reboundPlayerId ?? this.reboundPlayerId,
      blockPlayerId: blockPlayerId ?? this.blockPlayerId,
      stealPlayerId: stealPlayerId ?? this.stealPlayerId,
      fouledPlayerId: fouledPlayerId ?? this.fouledPlayerId,
      subInPlayerId: subInPlayerId ?? this.subInPlayerId,
      subOutPlayerId: subOutPlayerId ?? this.subOutPlayerId,
      isFlagrant: isFlagrant ?? this.isFlagrant,
      isTechnical: isTechnical ?? this.isTechnical,
      isFastbreak: isFastbreak ?? this.isFastbreak,
      isSecondChance: isSecondChance ?? this.isSecondChance,
      isFromTurnover: isFromTurnover ?? this.isFromTurnover,
      homeScoreAtTime: homeScoreAtTime ?? this.homeScoreAtTime,
      awayScoreAtTime: awayScoreAtTime ?? this.awayScoreAtTime,
      description: description ?? this.description,
      linkedActionId: linkedActionId ?? this.linkedActionId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (localMatchId.present) {
      map['local_match_id'] = Variable<int>(localMatchId.value);
    }
    if (tournamentTeamPlayerId.present) {
      map['tournament_team_player_id'] = Variable<int>(
        tournamentTeamPlayerId.value,
      );
    }
    if (tournamentTeamId.present) {
      map['tournament_team_id'] = Variable<int>(tournamentTeamId.value);
    }
    if (quarter.present) {
      map['quarter'] = Variable<int>(quarter.value);
    }
    if (gameClockSeconds.present) {
      map['game_clock_seconds'] = Variable<int>(gameClockSeconds.value);
    }
    if (shotClockSeconds.present) {
      map['shot_clock_seconds'] = Variable<int>(shotClockSeconds.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (actionSubtype.present) {
      map['action_subtype'] = Variable<String>(actionSubtype.value);
    }
    if (isMade.present) {
      map['is_made'] = Variable<bool>(isMade.value);
    }
    if (pointsScored.present) {
      map['points_scored'] = Variable<int>(pointsScored.value);
    }
    if (courtX.present) {
      map['court_x'] = Variable<double>(courtX.value);
    }
    if (courtY.present) {
      map['court_y'] = Variable<double>(courtY.value);
    }
    if (courtZone.present) {
      map['court_zone'] = Variable<int>(courtZone.value);
    }
    if (shotDistance.present) {
      map['shot_distance'] = Variable<double>(shotDistance.value);
    }
    if (assistPlayerId.present) {
      map['assist_player_id'] = Variable<int>(assistPlayerId.value);
    }
    if (reboundPlayerId.present) {
      map['rebound_player_id'] = Variable<int>(reboundPlayerId.value);
    }
    if (blockPlayerId.present) {
      map['block_player_id'] = Variable<int>(blockPlayerId.value);
    }
    if (stealPlayerId.present) {
      map['steal_player_id'] = Variable<int>(stealPlayerId.value);
    }
    if (fouledPlayerId.present) {
      map['fouled_player_id'] = Variable<int>(fouledPlayerId.value);
    }
    if (subInPlayerId.present) {
      map['sub_in_player_id'] = Variable<int>(subInPlayerId.value);
    }
    if (subOutPlayerId.present) {
      map['sub_out_player_id'] = Variable<int>(subOutPlayerId.value);
    }
    if (isFlagrant.present) {
      map['is_flagrant'] = Variable<bool>(isFlagrant.value);
    }
    if (isTechnical.present) {
      map['is_technical'] = Variable<bool>(isTechnical.value);
    }
    if (isFastbreak.present) {
      map['is_fastbreak'] = Variable<bool>(isFastbreak.value);
    }
    if (isSecondChance.present) {
      map['is_second_chance'] = Variable<bool>(isSecondChance.value);
    }
    if (isFromTurnover.present) {
      map['is_from_turnover'] = Variable<bool>(isFromTurnover.value);
    }
    if (homeScoreAtTime.present) {
      map['home_score_at_time'] = Variable<int>(homeScoreAtTime.value);
    }
    if (awayScoreAtTime.present) {
      map['away_score_at_time'] = Variable<int>(awayScoreAtTime.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (linkedActionId.present) {
      map['linked_action_id'] = Variable<String>(linkedActionId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlayByPlaysCompanion(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('localMatchId: $localMatchId, ')
          ..write('tournamentTeamPlayerId: $tournamentTeamPlayerId, ')
          ..write('tournamentTeamId: $tournamentTeamId, ')
          ..write('quarter: $quarter, ')
          ..write('gameClockSeconds: $gameClockSeconds, ')
          ..write('shotClockSeconds: $shotClockSeconds, ')
          ..write('actionType: $actionType, ')
          ..write('actionSubtype: $actionSubtype, ')
          ..write('isMade: $isMade, ')
          ..write('pointsScored: $pointsScored, ')
          ..write('courtX: $courtX, ')
          ..write('courtY: $courtY, ')
          ..write('courtZone: $courtZone, ')
          ..write('shotDistance: $shotDistance, ')
          ..write('assistPlayerId: $assistPlayerId, ')
          ..write('reboundPlayerId: $reboundPlayerId, ')
          ..write('blockPlayerId: $blockPlayerId, ')
          ..write('stealPlayerId: $stealPlayerId, ')
          ..write('fouledPlayerId: $fouledPlayerId, ')
          ..write('subInPlayerId: $subInPlayerId, ')
          ..write('subOutPlayerId: $subOutPlayerId, ')
          ..write('isFlagrant: $isFlagrant, ')
          ..write('isTechnical: $isTechnical, ')
          ..write('isFastbreak: $isFastbreak, ')
          ..write('isSecondChance: $isSecondChance, ')
          ..write('isFromTurnover: $isFromTurnover, ')
          ..write('homeScoreAtTime: $homeScoreAtTime, ')
          ..write('awayScoreAtTime: $awayScoreAtTime, ')
          ..write('description: $description, ')
          ..write('linkedActionId: $linkedActionId, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RecentTournamentsTable extends RecentTournaments
    with TableInfo<$RecentTournamentsTable, RecentTournament> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentTournamentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tournamentIdMeta = const VerificationMeta(
    'tournamentId',
  );
  @override
  late final GeneratedColumn<String> tournamentId = GeneratedColumn<String>(
    'tournament_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tournamentNameMeta = const VerificationMeta(
    'tournamentName',
  );
  @override
  late final GeneratedColumn<String> tournamentName = GeneratedColumn<String>(
    'tournament_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apiTokenMeta = const VerificationMeta(
    'apiToken',
  );
  @override
  late final GeneratedColumn<String> apiToken = GeneratedColumn<String>(
    'api_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _connectedAtMeta = const VerificationMeta(
    'connectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> connectedAt = GeneratedColumn<DateTime>(
    'connected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tournamentId,
    tournamentName,
    apiToken,
    connectedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_tournaments';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentTournament> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tournament_id')) {
      context.handle(
        _tournamentIdMeta,
        tournamentId.isAcceptableOrUnknown(
          data['tournament_id']!,
          _tournamentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tournamentIdMeta);
    }
    if (data.containsKey('tournament_name')) {
      context.handle(
        _tournamentNameMeta,
        tournamentName.isAcceptableOrUnknown(
          data['tournament_name']!,
          _tournamentNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tournamentNameMeta);
    }
    if (data.containsKey('api_token')) {
      context.handle(
        _apiTokenMeta,
        apiToken.isAcceptableOrUnknown(data['api_token']!, _apiTokenMeta),
      );
    } else if (isInserting) {
      context.missing(_apiTokenMeta);
    }
    if (data.containsKey('connected_at')) {
      context.handle(
        _connectedAtMeta,
        connectedAt.isAcceptableOrUnknown(
          data['connected_at']!,
          _connectedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tournamentId};
  @override
  RecentTournament map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentTournament(
      tournamentId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}tournament_id'],
          )!,
      tournamentName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}tournament_name'],
          )!,
      apiToken:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}api_token'],
          )!,
      connectedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}connected_at'],
          )!,
    );
  }

  @override
  $RecentTournamentsTable createAlias(String alias) {
    return $RecentTournamentsTable(attachedDatabase, alias);
  }
}

class RecentTournament extends DataClass
    implements Insertable<RecentTournament> {
  final String tournamentId;
  final String tournamentName;
  final String apiToken;
  final DateTime connectedAt;
  const RecentTournament({
    required this.tournamentId,
    required this.tournamentName,
    required this.apiToken,
    required this.connectedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tournament_id'] = Variable<String>(tournamentId);
    map['tournament_name'] = Variable<String>(tournamentName);
    map['api_token'] = Variable<String>(apiToken);
    map['connected_at'] = Variable<DateTime>(connectedAt);
    return map;
  }

  RecentTournamentsCompanion toCompanion(bool nullToAbsent) {
    return RecentTournamentsCompanion(
      tournamentId: Value(tournamentId),
      tournamentName: Value(tournamentName),
      apiToken: Value(apiToken),
      connectedAt: Value(connectedAt),
    );
  }

  factory RecentTournament.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentTournament(
      tournamentId: serializer.fromJson<String>(json['tournamentId']),
      tournamentName: serializer.fromJson<String>(json['tournamentName']),
      apiToken: serializer.fromJson<String>(json['apiToken']),
      connectedAt: serializer.fromJson<DateTime>(json['connectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tournamentId': serializer.toJson<String>(tournamentId),
      'tournamentName': serializer.toJson<String>(tournamentName),
      'apiToken': serializer.toJson<String>(apiToken),
      'connectedAt': serializer.toJson<DateTime>(connectedAt),
    };
  }

  RecentTournament copyWith({
    String? tournamentId,
    String? tournamentName,
    String? apiToken,
    DateTime? connectedAt,
  }) => RecentTournament(
    tournamentId: tournamentId ?? this.tournamentId,
    tournamentName: tournamentName ?? this.tournamentName,
    apiToken: apiToken ?? this.apiToken,
    connectedAt: connectedAt ?? this.connectedAt,
  );
  RecentTournament copyWithCompanion(RecentTournamentsCompanion data) {
    return RecentTournament(
      tournamentId:
          data.tournamentId.present
              ? data.tournamentId.value
              : this.tournamentId,
      tournamentName:
          data.tournamentName.present
              ? data.tournamentName.value
              : this.tournamentName,
      apiToken: data.apiToken.present ? data.apiToken.value : this.apiToken,
      connectedAt:
          data.connectedAt.present ? data.connectedAt.value : this.connectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentTournament(')
          ..write('tournamentId: $tournamentId, ')
          ..write('tournamentName: $tournamentName, ')
          ..write('apiToken: $apiToken, ')
          ..write('connectedAt: $connectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tournamentId, tournamentName, apiToken, connectedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentTournament &&
          other.tournamentId == this.tournamentId &&
          other.tournamentName == this.tournamentName &&
          other.apiToken == this.apiToken &&
          other.connectedAt == this.connectedAt);
}

class RecentTournamentsCompanion extends UpdateCompanion<RecentTournament> {
  final Value<String> tournamentId;
  final Value<String> tournamentName;
  final Value<String> apiToken;
  final Value<DateTime> connectedAt;
  final Value<int> rowid;
  const RecentTournamentsCompanion({
    this.tournamentId = const Value.absent(),
    this.tournamentName = const Value.absent(),
    this.apiToken = const Value.absent(),
    this.connectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentTournamentsCompanion.insert({
    required String tournamentId,
    required String tournamentName,
    required String apiToken,
    required DateTime connectedAt,
    this.rowid = const Value.absent(),
  }) : tournamentId = Value(tournamentId),
       tournamentName = Value(tournamentName),
       apiToken = Value(apiToken),
       connectedAt = Value(connectedAt);
  static Insertable<RecentTournament> custom({
    Expression<String>? tournamentId,
    Expression<String>? tournamentName,
    Expression<String>? apiToken,
    Expression<DateTime>? connectedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tournamentId != null) 'tournament_id': tournamentId,
      if (tournamentName != null) 'tournament_name': tournamentName,
      if (apiToken != null) 'api_token': apiToken,
      if (connectedAt != null) 'connected_at': connectedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentTournamentsCompanion copyWith({
    Value<String>? tournamentId,
    Value<String>? tournamentName,
    Value<String>? apiToken,
    Value<DateTime>? connectedAt,
    Value<int>? rowid,
  }) {
    return RecentTournamentsCompanion(
      tournamentId: tournamentId ?? this.tournamentId,
      tournamentName: tournamentName ?? this.tournamentName,
      apiToken: apiToken ?? this.apiToken,
      connectedAt: connectedAt ?? this.connectedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tournamentId.present) {
      map['tournament_id'] = Variable<String>(tournamentId.value);
    }
    if (tournamentName.present) {
      map['tournament_name'] = Variable<String>(tournamentName.value);
    }
    if (apiToken.present) {
      map['api_token'] = Variable<String>(apiToken.value);
    }
    if (connectedAt.present) {
      map['connected_at'] = Variable<DateTime>(connectedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentTournamentsCompanion(')
          ..write('tournamentId: $tournamentId, ')
          ..write('tournamentName: $tournamentName, ')
          ..write('apiToken: $apiToken, ')
          ..write('connectedAt: $connectedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalEditLogsTable extends LocalEditLogs
    with TableInfo<$LocalEditLogsTable, LocalEditLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalEditLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _localMatchIdMeta = const VerificationMeta(
    'localMatchId',
  );
  @override
  late final GeneratedColumn<int> localMatchId = GeneratedColumn<int>(
    'local_match_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<int> targetId = GeneratedColumn<int>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetLocalIdMeta = const VerificationMeta(
    'targetLocalId',
  );
  @override
  late final GeneratedColumn<String> targetLocalId = GeneratedColumn<String>(
    'target_local_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editTypeMeta = const VerificationMeta(
    'editType',
  );
  @override
  late final GeneratedColumn<String> editType = GeneratedColumn<String>(
    'edit_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldNameMeta = const VerificationMeta(
    'fieldName',
  );
  @override
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
    'field_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _oldValueMeta = const VerificationMeta(
    'oldValue',
  );
  @override
  late final GeneratedColumn<String> oldValue = GeneratedColumn<String>(
    'old_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newValueMeta = const VerificationMeta(
    'newValue',
  );
  @override
  late final GeneratedColumn<String> newValue = GeneratedColumn<String>(
    'new_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editorPlayerIdMeta = const VerificationMeta(
    'editorPlayerId',
  );
  @override
  late final GeneratedColumn<int> editorPlayerId = GeneratedColumn<int>(
    'editor_player_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
    'edited_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localMatchId,
    targetType,
    targetId,
    targetLocalId,
    editType,
    fieldName,
    oldValue,
    newValue,
    description,
    editorPlayerId,
    editedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_edit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalEditLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_match_id')) {
      context.handle(
        _localMatchIdMeta,
        localMatchId.isAcceptableOrUnknown(
          data['local_match_id']!,
          _localMatchIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localMatchIdMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('target_local_id')) {
      context.handle(
        _targetLocalIdMeta,
        targetLocalId.isAcceptableOrUnknown(
          data['target_local_id']!,
          _targetLocalIdMeta,
        ),
      );
    }
    if (data.containsKey('edit_type')) {
      context.handle(
        _editTypeMeta,
        editType.isAcceptableOrUnknown(data['edit_type']!, _editTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_editTypeMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(
        _fieldNameMeta,
        fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta),
      );
    }
    if (data.containsKey('old_value')) {
      context.handle(
        _oldValueMeta,
        oldValue.isAcceptableOrUnknown(data['old_value']!, _oldValueMeta),
      );
    }
    if (data.containsKey('new_value')) {
      context.handle(
        _newValueMeta,
        newValue.isAcceptableOrUnknown(data['new_value']!, _newValueMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('editor_player_id')) {
      context.handle(
        _editorPlayerIdMeta,
        editorPlayerId.isAcceptableOrUnknown(
          data['editor_player_id']!,
          _editorPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalEditLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalEditLog(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      localMatchId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}local_match_id'],
          )!,
      targetType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}target_type'],
          )!,
      targetId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}target_id'],
          )!,
      targetLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_local_id'],
      ),
      editType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}edit_type'],
          )!,
      fieldName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_name'],
      ),
      oldValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}old_value'],
      ),
      newValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_value'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      editorPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}editor_player_id'],
      ),
      editedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}edited_at'],
          )!,
    );
  }

  @override
  $LocalEditLogsTable createAlias(String alias) {
    return $LocalEditLogsTable(attachedDatabase, alias);
  }
}

class LocalEditLog extends DataClass implements Insertable<LocalEditLog> {
  final int id;
  final int localMatchId;
  final String targetType;
  final int targetId;
  final String? targetLocalId;
  final String editType;
  final String? fieldName;
  final String? oldValue;
  final String? newValue;
  final String? description;
  final int? editorPlayerId;
  final DateTime editedAt;
  const LocalEditLog({
    required this.id,
    required this.localMatchId,
    required this.targetType,
    required this.targetId,
    this.targetLocalId,
    required this.editType,
    this.fieldName,
    this.oldValue,
    this.newValue,
    this.description,
    this.editorPlayerId,
    required this.editedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_match_id'] = Variable<int>(localMatchId);
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<int>(targetId);
    if (!nullToAbsent || targetLocalId != null) {
      map['target_local_id'] = Variable<String>(targetLocalId);
    }
    map['edit_type'] = Variable<String>(editType);
    if (!nullToAbsent || fieldName != null) {
      map['field_name'] = Variable<String>(fieldName);
    }
    if (!nullToAbsent || oldValue != null) {
      map['old_value'] = Variable<String>(oldValue);
    }
    if (!nullToAbsent || newValue != null) {
      map['new_value'] = Variable<String>(newValue);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || editorPlayerId != null) {
      map['editor_player_id'] = Variable<int>(editorPlayerId);
    }
    map['edited_at'] = Variable<DateTime>(editedAt);
    return map;
  }

  LocalEditLogsCompanion toCompanion(bool nullToAbsent) {
    return LocalEditLogsCompanion(
      id: Value(id),
      localMatchId: Value(localMatchId),
      targetType: Value(targetType),
      targetId: Value(targetId),
      targetLocalId:
          targetLocalId == null && nullToAbsent
              ? const Value.absent()
              : Value(targetLocalId),
      editType: Value(editType),
      fieldName:
          fieldName == null && nullToAbsent
              ? const Value.absent()
              : Value(fieldName),
      oldValue:
          oldValue == null && nullToAbsent
              ? const Value.absent()
              : Value(oldValue),
      newValue:
          newValue == null && nullToAbsent
              ? const Value.absent()
              : Value(newValue),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
      editorPlayerId:
          editorPlayerId == null && nullToAbsent
              ? const Value.absent()
              : Value(editorPlayerId),
      editedAt: Value(editedAt),
    );
  }

  factory LocalEditLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalEditLog(
      id: serializer.fromJson<int>(json['id']),
      localMatchId: serializer.fromJson<int>(json['localMatchId']),
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<int>(json['targetId']),
      targetLocalId: serializer.fromJson<String?>(json['targetLocalId']),
      editType: serializer.fromJson<String>(json['editType']),
      fieldName: serializer.fromJson<String?>(json['fieldName']),
      oldValue: serializer.fromJson<String?>(json['oldValue']),
      newValue: serializer.fromJson<String?>(json['newValue']),
      description: serializer.fromJson<String?>(json['description']),
      editorPlayerId: serializer.fromJson<int?>(json['editorPlayerId']),
      editedAt: serializer.fromJson<DateTime>(json['editedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localMatchId': serializer.toJson<int>(localMatchId),
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<int>(targetId),
      'targetLocalId': serializer.toJson<String?>(targetLocalId),
      'editType': serializer.toJson<String>(editType),
      'fieldName': serializer.toJson<String?>(fieldName),
      'oldValue': serializer.toJson<String?>(oldValue),
      'newValue': serializer.toJson<String?>(newValue),
      'description': serializer.toJson<String?>(description),
      'editorPlayerId': serializer.toJson<int?>(editorPlayerId),
      'editedAt': serializer.toJson<DateTime>(editedAt),
    };
  }

  LocalEditLog copyWith({
    int? id,
    int? localMatchId,
    String? targetType,
    int? targetId,
    Value<String?> targetLocalId = const Value.absent(),
    String? editType,
    Value<String?> fieldName = const Value.absent(),
    Value<String?> oldValue = const Value.absent(),
    Value<String?> newValue = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<int?> editorPlayerId = const Value.absent(),
    DateTime? editedAt,
  }) => LocalEditLog(
    id: id ?? this.id,
    localMatchId: localMatchId ?? this.localMatchId,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    targetLocalId:
        targetLocalId.present ? targetLocalId.value : this.targetLocalId,
    editType: editType ?? this.editType,
    fieldName: fieldName.present ? fieldName.value : this.fieldName,
    oldValue: oldValue.present ? oldValue.value : this.oldValue,
    newValue: newValue.present ? newValue.value : this.newValue,
    description: description.present ? description.value : this.description,
    editorPlayerId:
        editorPlayerId.present ? editorPlayerId.value : this.editorPlayerId,
    editedAt: editedAt ?? this.editedAt,
  );
  LocalEditLog copyWithCompanion(LocalEditLogsCompanion data) {
    return LocalEditLog(
      id: data.id.present ? data.id.value : this.id,
      localMatchId:
          data.localMatchId.present
              ? data.localMatchId.value
              : this.localMatchId,
      targetType:
          data.targetType.present ? data.targetType.value : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      targetLocalId:
          data.targetLocalId.present
              ? data.targetLocalId.value
              : this.targetLocalId,
      editType: data.editType.present ? data.editType.value : this.editType,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      oldValue: data.oldValue.present ? data.oldValue.value : this.oldValue,
      newValue: data.newValue.present ? data.newValue.value : this.newValue,
      description:
          data.description.present ? data.description.value : this.description,
      editorPlayerId:
          data.editorPlayerId.present
              ? data.editorPlayerId.value
              : this.editorPlayerId,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalEditLog(')
          ..write('id: $id, ')
          ..write('localMatchId: $localMatchId, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('targetLocalId: $targetLocalId, ')
          ..write('editType: $editType, ')
          ..write('fieldName: $fieldName, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('description: $description, ')
          ..write('editorPlayerId: $editorPlayerId, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localMatchId,
    targetType,
    targetId,
    targetLocalId,
    editType,
    fieldName,
    oldValue,
    newValue,
    description,
    editorPlayerId,
    editedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalEditLog &&
          other.id == this.id &&
          other.localMatchId == this.localMatchId &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.targetLocalId == this.targetLocalId &&
          other.editType == this.editType &&
          other.fieldName == this.fieldName &&
          other.oldValue == this.oldValue &&
          other.newValue == this.newValue &&
          other.description == this.description &&
          other.editorPlayerId == this.editorPlayerId &&
          other.editedAt == this.editedAt);
}

class LocalEditLogsCompanion extends UpdateCompanion<LocalEditLog> {
  final Value<int> id;
  final Value<int> localMatchId;
  final Value<String> targetType;
  final Value<int> targetId;
  final Value<String?> targetLocalId;
  final Value<String> editType;
  final Value<String?> fieldName;
  final Value<String?> oldValue;
  final Value<String?> newValue;
  final Value<String?> description;
  final Value<int?> editorPlayerId;
  final Value<DateTime> editedAt;
  const LocalEditLogsCompanion({
    this.id = const Value.absent(),
    this.localMatchId = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.targetLocalId = const Value.absent(),
    this.editType = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.description = const Value.absent(),
    this.editorPlayerId = const Value.absent(),
    this.editedAt = const Value.absent(),
  });
  LocalEditLogsCompanion.insert({
    this.id = const Value.absent(),
    required int localMatchId,
    required String targetType,
    required int targetId,
    this.targetLocalId = const Value.absent(),
    required String editType,
    this.fieldName = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.description = const Value.absent(),
    this.editorPlayerId = const Value.absent(),
    required DateTime editedAt,
  }) : localMatchId = Value(localMatchId),
       targetType = Value(targetType),
       targetId = Value(targetId),
       editType = Value(editType),
       editedAt = Value(editedAt);
  static Insertable<LocalEditLog> custom({
    Expression<int>? id,
    Expression<int>? localMatchId,
    Expression<String>? targetType,
    Expression<int>? targetId,
    Expression<String>? targetLocalId,
    Expression<String>? editType,
    Expression<String>? fieldName,
    Expression<String>? oldValue,
    Expression<String>? newValue,
    Expression<String>? description,
    Expression<int>? editorPlayerId,
    Expression<DateTime>? editedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localMatchId != null) 'local_match_id': localMatchId,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (targetLocalId != null) 'target_local_id': targetLocalId,
      if (editType != null) 'edit_type': editType,
      if (fieldName != null) 'field_name': fieldName,
      if (oldValue != null) 'old_value': oldValue,
      if (newValue != null) 'new_value': newValue,
      if (description != null) 'description': description,
      if (editorPlayerId != null) 'editor_player_id': editorPlayerId,
      if (editedAt != null) 'edited_at': editedAt,
    });
  }

  LocalEditLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? localMatchId,
    Value<String>? targetType,
    Value<int>? targetId,
    Value<String?>? targetLocalId,
    Value<String>? editType,
    Value<String?>? fieldName,
    Value<String?>? oldValue,
    Value<String?>? newValue,
    Value<String?>? description,
    Value<int?>? editorPlayerId,
    Value<DateTime>? editedAt,
  }) {
    return LocalEditLogsCompanion(
      id: id ?? this.id,
      localMatchId: localMatchId ?? this.localMatchId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetLocalId: targetLocalId ?? this.targetLocalId,
      editType: editType ?? this.editType,
      fieldName: fieldName ?? this.fieldName,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      description: description ?? this.description,
      editorPlayerId: editorPlayerId ?? this.editorPlayerId,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localMatchId.present) {
      map['local_match_id'] = Variable<int>(localMatchId.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<int>(targetId.value);
    }
    if (targetLocalId.present) {
      map['target_local_id'] = Variable<String>(targetLocalId.value);
    }
    if (editType.present) {
      map['edit_type'] = Variable<String>(editType.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (oldValue.present) {
      map['old_value'] = Variable<String>(oldValue.value);
    }
    if (newValue.present) {
      map['new_value'] = Variable<String>(newValue.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (editorPlayerId.present) {
      map['editor_player_id'] = Variable<int>(editorPlayerId.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalEditLogsCompanion(')
          ..write('id: $id, ')
          ..write('localMatchId: $localMatchId, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('targetLocalId: $targetLocalId, ')
          ..write('editType: $editType, ')
          ..write('fieldName: $fieldName, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('description: $description, ')
          ..write('editorPlayerId: $editorPlayerId, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalTournamentsTable localTournaments = $LocalTournamentsTable(
    this,
  );
  late final $LocalTournamentTeamsTable localTournamentTeams =
      $LocalTournamentTeamsTable(this);
  late final $LocalTournamentPlayersTable localTournamentPlayers =
      $LocalTournamentPlayersTable(this);
  late final $LocalMatchesTable localMatches = $LocalMatchesTable(this);
  late final $LocalPlayerStatsTable localPlayerStats = $LocalPlayerStatsTable(
    this,
  );
  late final $LocalPlayByPlaysTable localPlayByPlays = $LocalPlayByPlaysTable(
    this,
  );
  late final $RecentTournamentsTable recentTournaments =
      $RecentTournamentsTable(this);
  late final $LocalEditLogsTable localEditLogs = $LocalEditLogsTable(this);
  late final Index idxMatchTournament = Index(
    'idx_match_tournament',
    'CREATE INDEX idx_match_tournament ON local_matches (tournament_id)',
  );
  late final Index idxMatchStatus = Index(
    'idx_match_status',
    'CREATE INDEX idx_match_status ON local_matches (status)',
  );
  late final Index idxMatchSync = Index(
    'idx_match_sync',
    'CREATE INDEX idx_match_sync ON local_matches (is_synced)',
  );
  late final Index idxPlayerStatsMatch = Index(
    'idx_player_stats_match',
    'CREATE INDEX idx_player_stats_match ON local_player_stats (local_match_id)',
  );
  late final Index idxPlayerStatsPlayer = Index(
    'idx_player_stats_player',
    'CREATE INDEX idx_player_stats_player ON local_player_stats (tournament_team_player_id)',
  );
  late final Index idxPlayerStatsMatchTeam = Index(
    'idx_player_stats_match_team',
    'CREATE INDEX idx_player_stats_match_team ON local_player_stats (local_match_id, tournament_team_id)',
  );
  late final Index idxPbpMatch = Index(
    'idx_pbp_match',
    'CREATE INDEX idx_pbp_match ON local_play_by_plays (local_match_id)',
  );
  late final Index idxPbpQuarter = Index(
    'idx_pbp_quarter',
    'CREATE INDEX idx_pbp_quarter ON local_play_by_plays (local_match_id, quarter)',
  );
  late final Index idxPbpTimeline = Index(
    'idx_pbp_timeline',
    'CREATE INDEX idx_pbp_timeline ON local_play_by_plays (local_match_id, quarter, game_clock_seconds)',
  );
  late final Index idxPbpPlayer = Index(
    'idx_pbp_player',
    'CREATE INDEX idx_pbp_player ON local_play_by_plays (tournament_team_player_id)',
  );
  late final Index idxPbpAction = Index(
    'idx_pbp_action',
    'CREATE INDEX idx_pbp_action ON local_play_by_plays (local_match_id, action_type)',
  );
  late final Index idxPbpSync = Index(
    'idx_pbp_sync',
    'CREATE INDEX idx_pbp_sync ON local_play_by_plays (is_synced)',
  );
  late final Index idxEditLogMatch = Index(
    'idx_edit_log_match',
    'CREATE INDEX idx_edit_log_match ON local_edit_logs (local_match_id)',
  );
  late final Index idxEditLogTime = Index(
    'idx_edit_log_time',
    'CREATE INDEX idx_edit_log_time ON local_edit_logs (edited_at)',
  );
  late final TournamentDao tournamentDao = TournamentDao(this as AppDatabase);
  late final MatchDao matchDao = MatchDao(this as AppDatabase);
  late final PlayerStatsDao playerStatsDao = PlayerStatsDao(
    this as AppDatabase,
  );
  late final PlayByPlayDao playByPlayDao = PlayByPlayDao(this as AppDatabase);
  late final EditLogDao editLogDao = EditLogDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localTournaments,
    localTournamentTeams,
    localTournamentPlayers,
    localMatches,
    localPlayerStats,
    localPlayByPlays,
    recentTournaments,
    localEditLogs,
    idxMatchTournament,
    idxMatchStatus,
    idxMatchSync,
    idxPlayerStatsMatch,
    idxPlayerStatsPlayer,
    idxPlayerStatsMatchTeam,
    idxPbpMatch,
    idxPbpQuarter,
    idxPbpTimeline,
    idxPbpPlayer,
    idxPbpAction,
    idxPbpSync,
    idxEditLogMatch,
    idxEditLogTime,
  ];
}

typedef $$LocalTournamentsTableCreateCompanionBuilder =
    LocalTournamentsCompanion Function({
      required String id,
      required String name,
      required String apiToken,
      required String status,
      required String gameRulesJson,
      Value<String?> venueName,
      Value<String?> venueAddress,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$LocalTournamentsTableUpdateCompanionBuilder =
    LocalTournamentsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> apiToken,
      Value<String> status,
      Value<String> gameRulesJson,
      Value<String?> venueName,
      Value<String?> venueAddress,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$LocalTournamentsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTournamentsTable> {
  $$LocalTournamentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiToken => $composableBuilder(
    column: $table.apiToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameRulesJson => $composableBuilder(
    column: $table.gameRulesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get venueName => $composableBuilder(
    column: $table.venueName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get venueAddress => $composableBuilder(
    column: $table.venueAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTournamentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTournamentsTable> {
  $$LocalTournamentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiToken => $composableBuilder(
    column: $table.apiToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameRulesJson => $composableBuilder(
    column: $table.gameRulesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get venueName => $composableBuilder(
    column: $table.venueName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get venueAddress => $composableBuilder(
    column: $table.venueAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTournamentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTournamentsTable> {
  $$LocalTournamentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get apiToken =>
      $composableBuilder(column: $table.apiToken, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get gameRulesJson => $composableBuilder(
    column: $table.gameRulesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get venueName =>
      $composableBuilder(column: $table.venueName, builder: (column) => column);

  GeneratedColumn<String> get venueAddress => $composableBuilder(
    column: $table.venueAddress,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalTournamentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTournamentsTable,
          LocalTournament,
          $$LocalTournamentsTableFilterComposer,
          $$LocalTournamentsTableOrderingComposer,
          $$LocalTournamentsTableAnnotationComposer,
          $$LocalTournamentsTableCreateCompanionBuilder,
          $$LocalTournamentsTableUpdateCompanionBuilder,
          (
            LocalTournament,
            BaseReferences<
              _$AppDatabase,
              $LocalTournamentsTable,
              LocalTournament
            >,
          ),
          LocalTournament,
          PrefetchHooks Function()
        > {
  $$LocalTournamentsTableTableManager(
    _$AppDatabase db,
    $LocalTournamentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$LocalTournamentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$LocalTournamentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalTournamentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> apiToken = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> gameRulesJson = const Value.absent(),
                Value<String?> venueName = const Value.absent(),
                Value<String?> venueAddress = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTournamentsCompanion(
                id: id,
                name: name,
                apiToken: apiToken,
                status: status,
                gameRulesJson: gameRulesJson,
                venueName: venueName,
                venueAddress: venueAddress,
                startDate: startDate,
                endDate: endDate,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String apiToken,
                required String status,
                required String gameRulesJson,
                Value<String?> venueName = const Value.absent(),
                Value<String?> venueAddress = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalTournamentsCompanion.insert(
                id: id,
                name: name,
                apiToken: apiToken,
                status: status,
                gameRulesJson: gameRulesJson,
                venueName: venueName,
                venueAddress: venueAddress,
                startDate: startDate,
                endDate: endDate,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTournamentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTournamentsTable,
      LocalTournament,
      $$LocalTournamentsTableFilterComposer,
      $$LocalTournamentsTableOrderingComposer,
      $$LocalTournamentsTableAnnotationComposer,
      $$LocalTournamentsTableCreateCompanionBuilder,
      $$LocalTournamentsTableUpdateCompanionBuilder,
      (
        LocalTournament,
        BaseReferences<_$AppDatabase, $LocalTournamentsTable, LocalTournament>,
      ),
      LocalTournament,
      PrefetchHooks Function()
    >;
typedef $$LocalTournamentTeamsTableCreateCompanionBuilder =
    LocalTournamentTeamsCompanion Function({
      Value<int> id,
      required String tournamentId,
      required int teamId,
      required String teamName,
      Value<String?> teamLogoUrl,
      Value<String?> primaryColor,
      Value<String?> secondaryColor,
      Value<String?> groupName,
      Value<int?> seedNumber,
      Value<int> wins,
      Value<int> losses,
      required DateTime syncedAt,
    });
typedef $$LocalTournamentTeamsTableUpdateCompanionBuilder =
    LocalTournamentTeamsCompanion Function({
      Value<int> id,
      Value<String> tournamentId,
      Value<int> teamId,
      Value<String> teamName,
      Value<String?> teamLogoUrl,
      Value<String?> primaryColor,
      Value<String?> secondaryColor,
      Value<String?> groupName,
      Value<int?> seedNumber,
      Value<int> wins,
      Value<int> losses,
      Value<DateTime> syncedAt,
    });

class $$LocalTournamentTeamsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTournamentTeamsTable> {
  $$LocalTournamentTeamsTableFilterComposer({
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

  ColumnFilters<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamName => $composableBuilder(
    column: $table.teamName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamLogoUrl => $composableBuilder(
    column: $table.teamLogoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryColor => $composableBuilder(
    column: $table.primaryColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondaryColor => $composableBuilder(
    column: $table.secondaryColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seedNumber => $composableBuilder(
    column: $table.seedNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wins => $composableBuilder(
    column: $table.wins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get losses => $composableBuilder(
    column: $table.losses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTournamentTeamsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTournamentTeamsTable> {
  $$LocalTournamentTeamsTableOrderingComposer({
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

  ColumnOrderings<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamName => $composableBuilder(
    column: $table.teamName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamLogoUrl => $composableBuilder(
    column: $table.teamLogoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryColor => $composableBuilder(
    column: $table.primaryColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondaryColor => $composableBuilder(
    column: $table.secondaryColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seedNumber => $composableBuilder(
    column: $table.seedNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wins => $composableBuilder(
    column: $table.wins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get losses => $composableBuilder(
    column: $table.losses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTournamentTeamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTournamentTeamsTable> {
  $$LocalTournamentTeamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get teamName =>
      $composableBuilder(column: $table.teamName, builder: (column) => column);

  GeneratedColumn<String> get teamLogoUrl => $composableBuilder(
    column: $table.teamLogoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryColor => $composableBuilder(
    column: $table.primaryColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondaryColor => $composableBuilder(
    column: $table.secondaryColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<int> get seedNumber => $composableBuilder(
    column: $table.seedNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wins =>
      $composableBuilder(column: $table.wins, builder: (column) => column);

  GeneratedColumn<int> get losses =>
      $composableBuilder(column: $table.losses, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalTournamentTeamsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTournamentTeamsTable,
          LocalTournamentTeam,
          $$LocalTournamentTeamsTableFilterComposer,
          $$LocalTournamentTeamsTableOrderingComposer,
          $$LocalTournamentTeamsTableAnnotationComposer,
          $$LocalTournamentTeamsTableCreateCompanionBuilder,
          $$LocalTournamentTeamsTableUpdateCompanionBuilder,
          (
            LocalTournamentTeam,
            BaseReferences<
              _$AppDatabase,
              $LocalTournamentTeamsTable,
              LocalTournamentTeam
            >,
          ),
          LocalTournamentTeam,
          PrefetchHooks Function()
        > {
  $$LocalTournamentTeamsTableTableManager(
    _$AppDatabase db,
    $LocalTournamentTeamsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalTournamentTeamsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$LocalTournamentTeamsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalTournamentTeamsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tournamentId = const Value.absent(),
                Value<int> teamId = const Value.absent(),
                Value<String> teamName = const Value.absent(),
                Value<String?> teamLogoUrl = const Value.absent(),
                Value<String?> primaryColor = const Value.absent(),
                Value<String?> secondaryColor = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<int?> seedNumber = const Value.absent(),
                Value<int> wins = const Value.absent(),
                Value<int> losses = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
              }) => LocalTournamentTeamsCompanion(
                id: id,
                tournamentId: tournamentId,
                teamId: teamId,
                teamName: teamName,
                teamLogoUrl: teamLogoUrl,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                groupName: groupName,
                seedNumber: seedNumber,
                wins: wins,
                losses: losses,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tournamentId,
                required int teamId,
                required String teamName,
                Value<String?> teamLogoUrl = const Value.absent(),
                Value<String?> primaryColor = const Value.absent(),
                Value<String?> secondaryColor = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<int?> seedNumber = const Value.absent(),
                Value<int> wins = const Value.absent(),
                Value<int> losses = const Value.absent(),
                required DateTime syncedAt,
              }) => LocalTournamentTeamsCompanion.insert(
                id: id,
                tournamentId: tournamentId,
                teamId: teamId,
                teamName: teamName,
                teamLogoUrl: teamLogoUrl,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                groupName: groupName,
                seedNumber: seedNumber,
                wins: wins,
                losses: losses,
                syncedAt: syncedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTournamentTeamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTournamentTeamsTable,
      LocalTournamentTeam,
      $$LocalTournamentTeamsTableFilterComposer,
      $$LocalTournamentTeamsTableOrderingComposer,
      $$LocalTournamentTeamsTableAnnotationComposer,
      $$LocalTournamentTeamsTableCreateCompanionBuilder,
      $$LocalTournamentTeamsTableUpdateCompanionBuilder,
      (
        LocalTournamentTeam,
        BaseReferences<
          _$AppDatabase,
          $LocalTournamentTeamsTable,
          LocalTournamentTeam
        >,
      ),
      LocalTournamentTeam,
      PrefetchHooks Function()
    >;
typedef $$LocalTournamentPlayersTableCreateCompanionBuilder =
    LocalTournamentPlayersCompanion Function({
      Value<int> id,
      required int tournamentTeamId,
      Value<int?> userId,
      required String userName,
      Value<String?> userNickname,
      Value<String?> profileImageUrl,
      Value<int?> jerseyNumber,
      Value<String?> position,
      required String role,
      Value<bool> isStarter,
      Value<bool> isActive,
      Value<String?> bdrDnaCode,
      required DateTime syncedAt,
    });
typedef $$LocalTournamentPlayersTableUpdateCompanionBuilder =
    LocalTournamentPlayersCompanion Function({
      Value<int> id,
      Value<int> tournamentTeamId,
      Value<int?> userId,
      Value<String> userName,
      Value<String?> userNickname,
      Value<String?> profileImageUrl,
      Value<int?> jerseyNumber,
      Value<String?> position,
      Value<String> role,
      Value<bool> isStarter,
      Value<bool> isActive,
      Value<String?> bdrDnaCode,
      Value<DateTime> syncedAt,
    });

class $$LocalTournamentPlayersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTournamentPlayersTable> {
  $$LocalTournamentPlayersTableFilterComposer({
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

  ColumnFilters<int> get tournamentTeamId => $composableBuilder(
    column: $table.tournamentTeamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userNickname => $composableBuilder(
    column: $table.userNickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileImageUrl => $composableBuilder(
    column: $table.profileImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStarter => $composableBuilder(
    column: $table.isStarter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bdrDnaCode => $composableBuilder(
    column: $table.bdrDnaCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTournamentPlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTournamentPlayersTable> {
  $$LocalTournamentPlayersTableOrderingComposer({
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

  ColumnOrderings<int> get tournamentTeamId => $composableBuilder(
    column: $table.tournamentTeamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userNickname => $composableBuilder(
    column: $table.userNickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileImageUrl => $composableBuilder(
    column: $table.profileImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStarter => $composableBuilder(
    column: $table.isStarter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bdrDnaCode => $composableBuilder(
    column: $table.bdrDnaCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTournamentPlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTournamentPlayersTable> {
  $$LocalTournamentPlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tournamentTeamId => $composableBuilder(
    column: $table.tournamentTeamId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get userNickname => $composableBuilder(
    column: $table.userNickname,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profileImageUrl => $composableBuilder(
    column: $table.profileImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get isStarter =>
      $composableBuilder(column: $table.isStarter, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get bdrDnaCode => $composableBuilder(
    column: $table.bdrDnaCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalTournamentPlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTournamentPlayersTable,
          LocalTournamentPlayer,
          $$LocalTournamentPlayersTableFilterComposer,
          $$LocalTournamentPlayersTableOrderingComposer,
          $$LocalTournamentPlayersTableAnnotationComposer,
          $$LocalTournamentPlayersTableCreateCompanionBuilder,
          $$LocalTournamentPlayersTableUpdateCompanionBuilder,
          (
            LocalTournamentPlayer,
            BaseReferences<
              _$AppDatabase,
              $LocalTournamentPlayersTable,
              LocalTournamentPlayer
            >,
          ),
          LocalTournamentPlayer,
          PrefetchHooks Function()
        > {
  $$LocalTournamentPlayersTableTableManager(
    _$AppDatabase db,
    $LocalTournamentPlayersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalTournamentPlayersTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$LocalTournamentPlayersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalTournamentPlayersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> tournamentTeamId = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<String> userName = const Value.absent(),
                Value<String?> userNickname = const Value.absent(),
                Value<String?> profileImageUrl = const Value.absent(),
                Value<int?> jerseyNumber = const Value.absent(),
                Value<String?> position = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<bool> isStarter = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> bdrDnaCode = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
              }) => LocalTournamentPlayersCompanion(
                id: id,
                tournamentTeamId: tournamentTeamId,
                userId: userId,
                userName: userName,
                userNickname: userNickname,
                profileImageUrl: profileImageUrl,
                jerseyNumber: jerseyNumber,
                position: position,
                role: role,
                isStarter: isStarter,
                isActive: isActive,
                bdrDnaCode: bdrDnaCode,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int tournamentTeamId,
                Value<int?> userId = const Value.absent(),
                required String userName,
                Value<String?> userNickname = const Value.absent(),
                Value<String?> profileImageUrl = const Value.absent(),
                Value<int?> jerseyNumber = const Value.absent(),
                Value<String?> position = const Value.absent(),
                required String role,
                Value<bool> isStarter = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> bdrDnaCode = const Value.absent(),
                required DateTime syncedAt,
              }) => LocalTournamentPlayersCompanion.insert(
                id: id,
                tournamentTeamId: tournamentTeamId,
                userId: userId,
                userName: userName,
                userNickname: userNickname,
                profileImageUrl: profileImageUrl,
                jerseyNumber: jerseyNumber,
                position: position,
                role: role,
                isStarter: isStarter,
                isActive: isActive,
                bdrDnaCode: bdrDnaCode,
                syncedAt: syncedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTournamentPlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTournamentPlayersTable,
      LocalTournamentPlayer,
      $$LocalTournamentPlayersTableFilterComposer,
      $$LocalTournamentPlayersTableOrderingComposer,
      $$LocalTournamentPlayersTableAnnotationComposer,
      $$LocalTournamentPlayersTableCreateCompanionBuilder,
      $$LocalTournamentPlayersTableUpdateCompanionBuilder,
      (
        LocalTournamentPlayer,
        BaseReferences<
          _$AppDatabase,
          $LocalTournamentPlayersTable,
          LocalTournamentPlayer
        >,
      ),
      LocalTournamentPlayer,
      PrefetchHooks Function()
    >;
typedef $$LocalMatchesTableCreateCompanionBuilder =
    LocalMatchesCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String?> serverUuid,
      required String localUuid,
      required String tournamentId,
      required int homeTeamId,
      required int awayTeamId,
      required String homeTeamName,
      required String awayTeamName,
      Value<int> homeScore,
      Value<int> awayScore,
      Value<String> quarterScoresJson,
      Value<int> currentQuarter,
      Value<int> gameClockSeconds,
      Value<int> shotClockSeconds,
      Value<String> status,
      Value<String> teamFoulsJson,
      Value<int> homeTimeoutsRemaining,
      Value<int> awayTimeoutsRemaining,
      Value<String?> roundName,
      Value<int?> roundNumber,
      Value<String?> groupName,
      Value<int?> mvpPlayerId,
      Value<DateTime?> scheduledAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      Value<bool> isSynced,
      Value<DateTime?> syncedAt,
      Value<String?> syncError,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$LocalMatchesTableUpdateCompanionBuilder =
    LocalMatchesCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String?> serverUuid,
      Value<String> localUuid,
      Value<String> tournamentId,
      Value<int> homeTeamId,
      Value<int> awayTeamId,
      Value<String> homeTeamName,
      Value<String> awayTeamName,
      Value<int> homeScore,
      Value<int> awayScore,
      Value<String> quarterScoresJson,
      Value<int> currentQuarter,
      Value<int> gameClockSeconds,
      Value<int> shotClockSeconds,
      Value<String> status,
      Value<String> teamFoulsJson,
      Value<int> homeTimeoutsRemaining,
      Value<int> awayTimeoutsRemaining,
      Value<String?> roundName,
      Value<int?> roundNumber,
      Value<String?> groupName,
      Value<int?> mvpPlayerId,
      Value<DateTime?> scheduledAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      Value<bool> isSynced,
      Value<DateTime?> syncedAt,
      Value<String?> syncError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$LocalMatchesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMatchesTable> {
  $$LocalMatchesTableFilterComposer({
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

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverUuid => $composableBuilder(
    column: $table.serverUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localUuid => $composableBuilder(
    column: $table.localUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get homeTeamId => $composableBuilder(
    column: $table.homeTeamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awayTeamId => $composableBuilder(
    column: $table.awayTeamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeTeamName => $composableBuilder(
    column: $table.homeTeamName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get awayTeamName => $composableBuilder(
    column: $table.awayTeamName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get homeScore => $composableBuilder(
    column: $table.homeScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awayScore => $composableBuilder(
    column: $table.awayScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quarterScoresJson => $composableBuilder(
    column: $table.quarterScoresJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentQuarter => $composableBuilder(
    column: $table.currentQuarter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gameClockSeconds => $composableBuilder(
    column: $table.gameClockSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shotClockSeconds => $composableBuilder(
    column: $table.shotClockSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamFoulsJson => $composableBuilder(
    column: $table.teamFoulsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get homeTimeoutsRemaining => $composableBuilder(
    column: $table.homeTimeoutsRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awayTimeoutsRemaining => $composableBuilder(
    column: $table.awayTimeoutsRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roundName => $composableBuilder(
    column: $table.roundName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mvpPlayerId => $composableBuilder(
    column: $table.mvpPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMatchesTable> {
  $$LocalMatchesTableOrderingComposer({
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

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverUuid => $composableBuilder(
    column: $table.serverUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localUuid => $composableBuilder(
    column: $table.localUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get homeTeamId => $composableBuilder(
    column: $table.homeTeamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awayTeamId => $composableBuilder(
    column: $table.awayTeamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeTeamName => $composableBuilder(
    column: $table.homeTeamName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get awayTeamName => $composableBuilder(
    column: $table.awayTeamName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get homeScore => $composableBuilder(
    column: $table.homeScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awayScore => $composableBuilder(
    column: $table.awayScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quarterScoresJson => $composableBuilder(
    column: $table.quarterScoresJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentQuarter => $composableBuilder(
    column: $table.currentQuarter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gameClockSeconds => $composableBuilder(
    column: $table.gameClockSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shotClockSeconds => $composableBuilder(
    column: $table.shotClockSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamFoulsJson => $composableBuilder(
    column: $table.teamFoulsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get homeTimeoutsRemaining => $composableBuilder(
    column: $table.homeTimeoutsRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awayTimeoutsRemaining => $composableBuilder(
    column: $table.awayTimeoutsRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roundName => $composableBuilder(
    column: $table.roundName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mvpPlayerId => $composableBuilder(
    column: $table.mvpPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMatchesTable> {
  $$LocalMatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get serverUuid => $composableBuilder(
    column: $table.serverUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localUuid =>
      $composableBuilder(column: $table.localUuid, builder: (column) => column);

  GeneratedColumn<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get homeTeamId => $composableBuilder(
    column: $table.homeTeamId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get awayTeamId => $composableBuilder(
    column: $table.awayTeamId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get homeTeamName => $composableBuilder(
    column: $table.homeTeamName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get awayTeamName => $composableBuilder(
    column: $table.awayTeamName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get homeScore =>
      $composableBuilder(column: $table.homeScore, builder: (column) => column);

  GeneratedColumn<int> get awayScore =>
      $composableBuilder(column: $table.awayScore, builder: (column) => column);

  GeneratedColumn<String> get quarterScoresJson => $composableBuilder(
    column: $table.quarterScoresJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentQuarter => $composableBuilder(
    column: $table.currentQuarter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gameClockSeconds => $composableBuilder(
    column: $table.gameClockSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shotClockSeconds => $composableBuilder(
    column: $table.shotClockSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get teamFoulsJson => $composableBuilder(
    column: $table.teamFoulsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get homeTimeoutsRemaining => $composableBuilder(
    column: $table.homeTimeoutsRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<int> get awayTimeoutsRemaining => $composableBuilder(
    column: $table.awayTimeoutsRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roundName =>
      $composableBuilder(column: $table.roundName, builder: (column) => column);

  GeneratedColumn<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<int> get mvpPlayerId => $composableBuilder(
    column: $table.mvpPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalMatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMatchesTable,
          LocalMatche,
          $$LocalMatchesTableFilterComposer,
          $$LocalMatchesTableOrderingComposer,
          $$LocalMatchesTableAnnotationComposer,
          $$LocalMatchesTableCreateCompanionBuilder,
          $$LocalMatchesTableUpdateCompanionBuilder,
          (
            LocalMatche,
            BaseReferences<_$AppDatabase, $LocalMatchesTable, LocalMatche>,
          ),
          LocalMatche,
          PrefetchHooks Function()
        > {
  $$LocalMatchesTableTableManager(_$AppDatabase db, $LocalMatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalMatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$LocalMatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$LocalMatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String?> serverUuid = const Value.absent(),
                Value<String> localUuid = const Value.absent(),
                Value<String> tournamentId = const Value.absent(),
                Value<int> homeTeamId = const Value.absent(),
                Value<int> awayTeamId = const Value.absent(),
                Value<String> homeTeamName = const Value.absent(),
                Value<String> awayTeamName = const Value.absent(),
                Value<int> homeScore = const Value.absent(),
                Value<int> awayScore = const Value.absent(),
                Value<String> quarterScoresJson = const Value.absent(),
                Value<int> currentQuarter = const Value.absent(),
                Value<int> gameClockSeconds = const Value.absent(),
                Value<int> shotClockSeconds = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> teamFoulsJson = const Value.absent(),
                Value<int> homeTimeoutsRemaining = const Value.absent(),
                Value<int> awayTimeoutsRemaining = const Value.absent(),
                Value<String?> roundName = const Value.absent(),
                Value<int?> roundNumber = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<int?> mvpPlayerId = const Value.absent(),
                Value<DateTime?> scheduledAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalMatchesCompanion(
                id: id,
                serverId: serverId,
                serverUuid: serverUuid,
                localUuid: localUuid,
                tournamentId: tournamentId,
                homeTeamId: homeTeamId,
                awayTeamId: awayTeamId,
                homeTeamName: homeTeamName,
                awayTeamName: awayTeamName,
                homeScore: homeScore,
                awayScore: awayScore,
                quarterScoresJson: quarterScoresJson,
                currentQuarter: currentQuarter,
                gameClockSeconds: gameClockSeconds,
                shotClockSeconds: shotClockSeconds,
                status: status,
                teamFoulsJson: teamFoulsJson,
                homeTimeoutsRemaining: homeTimeoutsRemaining,
                awayTimeoutsRemaining: awayTimeoutsRemaining,
                roundName: roundName,
                roundNumber: roundNumber,
                groupName: groupName,
                mvpPlayerId: mvpPlayerId,
                scheduledAt: scheduledAt,
                startedAt: startedAt,
                endedAt: endedAt,
                isSynced: isSynced,
                syncedAt: syncedAt,
                syncError: syncError,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String?> serverUuid = const Value.absent(),
                required String localUuid,
                required String tournamentId,
                required int homeTeamId,
                required int awayTeamId,
                required String homeTeamName,
                required String awayTeamName,
                Value<int> homeScore = const Value.absent(),
                Value<int> awayScore = const Value.absent(),
                Value<String> quarterScoresJson = const Value.absent(),
                Value<int> currentQuarter = const Value.absent(),
                Value<int> gameClockSeconds = const Value.absent(),
                Value<int> shotClockSeconds = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> teamFoulsJson = const Value.absent(),
                Value<int> homeTimeoutsRemaining = const Value.absent(),
                Value<int> awayTimeoutsRemaining = const Value.absent(),
                Value<String?> roundName = const Value.absent(),
                Value<int?> roundNumber = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<int?> mvpPlayerId = const Value.absent(),
                Value<DateTime?> scheduledAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => LocalMatchesCompanion.insert(
                id: id,
                serverId: serverId,
                serverUuid: serverUuid,
                localUuid: localUuid,
                tournamentId: tournamentId,
                homeTeamId: homeTeamId,
                awayTeamId: awayTeamId,
                homeTeamName: homeTeamName,
                awayTeamName: awayTeamName,
                homeScore: homeScore,
                awayScore: awayScore,
                quarterScoresJson: quarterScoresJson,
                currentQuarter: currentQuarter,
                gameClockSeconds: gameClockSeconds,
                shotClockSeconds: shotClockSeconds,
                status: status,
                teamFoulsJson: teamFoulsJson,
                homeTimeoutsRemaining: homeTimeoutsRemaining,
                awayTimeoutsRemaining: awayTimeoutsRemaining,
                roundName: roundName,
                roundNumber: roundNumber,
                groupName: groupName,
                mvpPlayerId: mvpPlayerId,
                scheduledAt: scheduledAt,
                startedAt: startedAt,
                endedAt: endedAt,
                isSynced: isSynced,
                syncedAt: syncedAt,
                syncError: syncError,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMatchesTable,
      LocalMatche,
      $$LocalMatchesTableFilterComposer,
      $$LocalMatchesTableOrderingComposer,
      $$LocalMatchesTableAnnotationComposer,
      $$LocalMatchesTableCreateCompanionBuilder,
      $$LocalMatchesTableUpdateCompanionBuilder,
      (
        LocalMatche,
        BaseReferences<_$AppDatabase, $LocalMatchesTable, LocalMatche>,
      ),
      LocalMatche,
      PrefetchHooks Function()
    >;
typedef $$LocalPlayerStatsTableCreateCompanionBuilder =
    LocalPlayerStatsCompanion Function({
      Value<int> id,
      required int localMatchId,
      required int tournamentTeamPlayerId,
      required int tournamentTeamId,
      Value<bool> isStarter,
      Value<bool> isOnCourt,
      Value<int> minutesPlayed,
      Value<DateTime?> lastEnteredAt,
      Value<int> points,
      Value<int> fieldGoalsMade,
      Value<int> fieldGoalsAttempted,
      Value<int> twoPointersMade,
      Value<int> twoPointersAttempted,
      Value<int> threePointersMade,
      Value<int> threePointersAttempted,
      Value<int> freeThrowsMade,
      Value<int> freeThrowsAttempted,
      Value<int> offensiveRebounds,
      Value<int> defensiveRebounds,
      Value<int> totalRebounds,
      Value<int> assists,
      Value<int> steals,
      Value<int> blocks,
      Value<int> turnovers,
      Value<int> personalFouls,
      Value<int> technicalFouls,
      Value<int> unsportsmanlikeFouls,
      Value<int> plusMinus,
      Value<bool> fouledOut,
      Value<bool> ejected,
      Value<bool> isManuallyEdited,
      required DateTime updatedAt,
    });
typedef $$LocalPlayerStatsTableUpdateCompanionBuilder =
    LocalPlayerStatsCompanion Function({
      Value<int> id,
      Value<int> localMatchId,
      Value<int> tournamentTeamPlayerId,
      Value<int> tournamentTeamId,
      Value<bool> isStarter,
      Value<bool> isOnCourt,
      Value<int> minutesPlayed,
      Value<DateTime?> lastEnteredAt,
      Value<int> points,
      Value<int> fieldGoalsMade,
      Value<int> fieldGoalsAttempted,
      Value<int> twoPointersMade,
      Value<int> twoPointersAttempted,
      Value<int> threePointersMade,
      Value<int> threePointersAttempted,
      Value<int> freeThrowsMade,
      Value<int> freeThrowsAttempted,
      Value<int> offensiveRebounds,
      Value<int> defensiveRebounds,
      Value<int> totalRebounds,
      Value<int> assists,
      Value<int> steals,
      Value<int> blocks,
      Value<int> turnovers,
      Value<int> personalFouls,
      Value<int> technicalFouls,
      Value<int> unsportsmanlikeFouls,
      Value<int> plusMinus,
      Value<bool> fouledOut,
      Value<bool> ejected,
      Value<bool> isManuallyEdited,
      Value<DateTime> updatedAt,
    });

class $$LocalPlayerStatsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPlayerStatsTable> {
  $$LocalPlayerStatsTableFilterComposer({
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

  ColumnFilters<int> get localMatchId => $composableBuilder(
    column: $table.localMatchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tournamentTeamPlayerId => $composableBuilder(
    column: $table.tournamentTeamPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tournamentTeamId => $composableBuilder(
    column: $table.tournamentTeamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStarter => $composableBuilder(
    column: $table.isStarter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOnCourt => $composableBuilder(
    column: $table.isOnCourt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutesPlayed => $composableBuilder(
    column: $table.minutesPlayed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastEnteredAt => $composableBuilder(
    column: $table.lastEnteredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fieldGoalsMade => $composableBuilder(
    column: $table.fieldGoalsMade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fieldGoalsAttempted => $composableBuilder(
    column: $table.fieldGoalsAttempted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get twoPointersMade => $composableBuilder(
    column: $table.twoPointersMade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get twoPointersAttempted => $composableBuilder(
    column: $table.twoPointersAttempted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get threePointersMade => $composableBuilder(
    column: $table.threePointersMade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get threePointersAttempted => $composableBuilder(
    column: $table.threePointersAttempted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get freeThrowsMade => $composableBuilder(
    column: $table.freeThrowsMade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get freeThrowsAttempted => $composableBuilder(
    column: $table.freeThrowsAttempted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offensiveRebounds => $composableBuilder(
    column: $table.offensiveRebounds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defensiveRebounds => $composableBuilder(
    column: $table.defensiveRebounds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalRebounds => $composableBuilder(
    column: $table.totalRebounds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assists => $composableBuilder(
    column: $table.assists,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steals => $composableBuilder(
    column: $table.steals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blocks => $composableBuilder(
    column: $table.blocks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get turnovers => $composableBuilder(
    column: $table.turnovers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get personalFouls => $composableBuilder(
    column: $table.personalFouls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get technicalFouls => $composableBuilder(
    column: $table.technicalFouls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unsportsmanlikeFouls => $composableBuilder(
    column: $table.unsportsmanlikeFouls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plusMinus => $composableBuilder(
    column: $table.plusMinus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fouledOut => $composableBuilder(
    column: $table.fouledOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ejected => $composableBuilder(
    column: $table.ejected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isManuallyEdited => $composableBuilder(
    column: $table.isManuallyEdited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPlayerStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPlayerStatsTable> {
  $$LocalPlayerStatsTableOrderingComposer({
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

  ColumnOrderings<int> get localMatchId => $composableBuilder(
    column: $table.localMatchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tournamentTeamPlayerId => $composableBuilder(
    column: $table.tournamentTeamPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tournamentTeamId => $composableBuilder(
    column: $table.tournamentTeamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStarter => $composableBuilder(
    column: $table.isStarter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOnCourt => $composableBuilder(
    column: $table.isOnCourt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutesPlayed => $composableBuilder(
    column: $table.minutesPlayed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastEnteredAt => $composableBuilder(
    column: $table.lastEnteredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fieldGoalsMade => $composableBuilder(
    column: $table.fieldGoalsMade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fieldGoalsAttempted => $composableBuilder(
    column: $table.fieldGoalsAttempted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get twoPointersMade => $composableBuilder(
    column: $table.twoPointersMade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get twoPointersAttempted => $composableBuilder(
    column: $table.twoPointersAttempted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get threePointersMade => $composableBuilder(
    column: $table.threePointersMade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get threePointersAttempted => $composableBuilder(
    column: $table.threePointersAttempted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get freeThrowsMade => $composableBuilder(
    column: $table.freeThrowsMade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get freeThrowsAttempted => $composableBuilder(
    column: $table.freeThrowsAttempted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offensiveRebounds => $composableBuilder(
    column: $table.offensiveRebounds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defensiveRebounds => $composableBuilder(
    column: $table.defensiveRebounds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalRebounds => $composableBuilder(
    column: $table.totalRebounds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assists => $composableBuilder(
    column: $table.assists,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steals => $composableBuilder(
    column: $table.steals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blocks => $composableBuilder(
    column: $table.blocks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get turnovers => $composableBuilder(
    column: $table.turnovers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get personalFouls => $composableBuilder(
    column: $table.personalFouls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get technicalFouls => $composableBuilder(
    column: $table.technicalFouls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unsportsmanlikeFouls => $composableBuilder(
    column: $table.unsportsmanlikeFouls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plusMinus => $composableBuilder(
    column: $table.plusMinus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fouledOut => $composableBuilder(
    column: $table.fouledOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ejected => $composableBuilder(
    column: $table.ejected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isManuallyEdited => $composableBuilder(
    column: $table.isManuallyEdited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPlayerStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPlayerStatsTable> {
  $$LocalPlayerStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get localMatchId => $composableBuilder(
    column: $table.localMatchId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tournamentTeamPlayerId => $composableBuilder(
    column: $table.tournamentTeamPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tournamentTeamId => $composableBuilder(
    column: $table.tournamentTeamId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStarter =>
      $composableBuilder(column: $table.isStarter, builder: (column) => column);

  GeneratedColumn<bool> get isOnCourt =>
      $composableBuilder(column: $table.isOnCourt, builder: (column) => column);

  GeneratedColumn<int> get minutesPlayed => $composableBuilder(
    column: $table.minutesPlayed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastEnteredAt => $composableBuilder(
    column: $table.lastEnteredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<int> get fieldGoalsMade => $composableBuilder(
    column: $table.fieldGoalsMade,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fieldGoalsAttempted => $composableBuilder(
    column: $table.fieldGoalsAttempted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get twoPointersMade => $composableBuilder(
    column: $table.twoPointersMade,
    builder: (column) => column,
  );

  GeneratedColumn<int> get twoPointersAttempted => $composableBuilder(
    column: $table.twoPointersAttempted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get threePointersMade => $composableBuilder(
    column: $table.threePointersMade,
    builder: (column) => column,
  );

  GeneratedColumn<int> get threePointersAttempted => $composableBuilder(
    column: $table.threePointersAttempted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get freeThrowsMade => $composableBuilder(
    column: $table.freeThrowsMade,
    builder: (column) => column,
  );

  GeneratedColumn<int> get freeThrowsAttempted => $composableBuilder(
    column: $table.freeThrowsAttempted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offensiveRebounds => $composableBuilder(
    column: $table.offensiveRebounds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defensiveRebounds => $composableBuilder(
    column: $table.defensiveRebounds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalRebounds => $composableBuilder(
    column: $table.totalRebounds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get assists =>
      $composableBuilder(column: $table.assists, builder: (column) => column);

  GeneratedColumn<int> get steals =>
      $composableBuilder(column: $table.steals, builder: (column) => column);

  GeneratedColumn<int> get blocks =>
      $composableBuilder(column: $table.blocks, builder: (column) => column);

  GeneratedColumn<int> get turnovers =>
      $composableBuilder(column: $table.turnovers, builder: (column) => column);

  GeneratedColumn<int> get personalFouls => $composableBuilder(
    column: $table.personalFouls,
    builder: (column) => column,
  );

  GeneratedColumn<int> get technicalFouls => $composableBuilder(
    column: $table.technicalFouls,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unsportsmanlikeFouls => $composableBuilder(
    column: $table.unsportsmanlikeFouls,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plusMinus =>
      $composableBuilder(column: $table.plusMinus, builder: (column) => column);

  GeneratedColumn<bool> get fouledOut =>
      $composableBuilder(column: $table.fouledOut, builder: (column) => column);

  GeneratedColumn<bool> get ejected =>
      $composableBuilder(column: $table.ejected, builder: (column) => column);

  GeneratedColumn<bool> get isManuallyEdited => $composableBuilder(
    column: $table.isManuallyEdited,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalPlayerStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPlayerStatsTable,
          LocalPlayerStat,
          $$LocalPlayerStatsTableFilterComposer,
          $$LocalPlayerStatsTableOrderingComposer,
          $$LocalPlayerStatsTableAnnotationComposer,
          $$LocalPlayerStatsTableCreateCompanionBuilder,
          $$LocalPlayerStatsTableUpdateCompanionBuilder,
          (
            LocalPlayerStat,
            BaseReferences<
              _$AppDatabase,
              $LocalPlayerStatsTable,
              LocalPlayerStat
            >,
          ),
          LocalPlayerStat,
          PrefetchHooks Function()
        > {
  $$LocalPlayerStatsTableTableManager(
    _$AppDatabase db,
    $LocalPlayerStatsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$LocalPlayerStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$LocalPlayerStatsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalPlayerStatsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> localMatchId = const Value.absent(),
                Value<int> tournamentTeamPlayerId = const Value.absent(),
                Value<int> tournamentTeamId = const Value.absent(),
                Value<bool> isStarter = const Value.absent(),
                Value<bool> isOnCourt = const Value.absent(),
                Value<int> minutesPlayed = const Value.absent(),
                Value<DateTime?> lastEnteredAt = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<int> fieldGoalsMade = const Value.absent(),
                Value<int> fieldGoalsAttempted = const Value.absent(),
                Value<int> twoPointersMade = const Value.absent(),
                Value<int> twoPointersAttempted = const Value.absent(),
                Value<int> threePointersMade = const Value.absent(),
                Value<int> threePointersAttempted = const Value.absent(),
                Value<int> freeThrowsMade = const Value.absent(),
                Value<int> freeThrowsAttempted = const Value.absent(),
                Value<int> offensiveRebounds = const Value.absent(),
                Value<int> defensiveRebounds = const Value.absent(),
                Value<int> totalRebounds = const Value.absent(),
                Value<int> assists = const Value.absent(),
                Value<int> steals = const Value.absent(),
                Value<int> blocks = const Value.absent(),
                Value<int> turnovers = const Value.absent(),
                Value<int> personalFouls = const Value.absent(),
                Value<int> technicalFouls = const Value.absent(),
                Value<int> unsportsmanlikeFouls = const Value.absent(),
                Value<int> plusMinus = const Value.absent(),
                Value<bool> fouledOut = const Value.absent(),
                Value<bool> ejected = const Value.absent(),
                Value<bool> isManuallyEdited = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalPlayerStatsCompanion(
                id: id,
                localMatchId: localMatchId,
                tournamentTeamPlayerId: tournamentTeamPlayerId,
                tournamentTeamId: tournamentTeamId,
                isStarter: isStarter,
                isOnCourt: isOnCourt,
                minutesPlayed: minutesPlayed,
                lastEnteredAt: lastEnteredAt,
                points: points,
                fieldGoalsMade: fieldGoalsMade,
                fieldGoalsAttempted: fieldGoalsAttempted,
                twoPointersMade: twoPointersMade,
                twoPointersAttempted: twoPointersAttempted,
                threePointersMade: threePointersMade,
                threePointersAttempted: threePointersAttempted,
                freeThrowsMade: freeThrowsMade,
                freeThrowsAttempted: freeThrowsAttempted,
                offensiveRebounds: offensiveRebounds,
                defensiveRebounds: defensiveRebounds,
                totalRebounds: totalRebounds,
                assists: assists,
                steals: steals,
                blocks: blocks,
                turnovers: turnovers,
                personalFouls: personalFouls,
                technicalFouls: technicalFouls,
                unsportsmanlikeFouls: unsportsmanlikeFouls,
                plusMinus: plusMinus,
                fouledOut: fouledOut,
                ejected: ejected,
                isManuallyEdited: isManuallyEdited,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int localMatchId,
                required int tournamentTeamPlayerId,
                required int tournamentTeamId,
                Value<bool> isStarter = const Value.absent(),
                Value<bool> isOnCourt = const Value.absent(),
                Value<int> minutesPlayed = const Value.absent(),
                Value<DateTime?> lastEnteredAt = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<int> fieldGoalsMade = const Value.absent(),
                Value<int> fieldGoalsAttempted = const Value.absent(),
                Value<int> twoPointersMade = const Value.absent(),
                Value<int> twoPointersAttempted = const Value.absent(),
                Value<int> threePointersMade = const Value.absent(),
                Value<int> threePointersAttempted = const Value.absent(),
                Value<int> freeThrowsMade = const Value.absent(),
                Value<int> freeThrowsAttempted = const Value.absent(),
                Value<int> offensiveRebounds = const Value.absent(),
                Value<int> defensiveRebounds = const Value.absent(),
                Value<int> totalRebounds = const Value.absent(),
                Value<int> assists = const Value.absent(),
                Value<int> steals = const Value.absent(),
                Value<int> blocks = const Value.absent(),
                Value<int> turnovers = const Value.absent(),
                Value<int> personalFouls = const Value.absent(),
                Value<int> technicalFouls = const Value.absent(),
                Value<int> unsportsmanlikeFouls = const Value.absent(),
                Value<int> plusMinus = const Value.absent(),
                Value<bool> fouledOut = const Value.absent(),
                Value<bool> ejected = const Value.absent(),
                Value<bool> isManuallyEdited = const Value.absent(),
                required DateTime updatedAt,
              }) => LocalPlayerStatsCompanion.insert(
                id: id,
                localMatchId: localMatchId,
                tournamentTeamPlayerId: tournamentTeamPlayerId,
                tournamentTeamId: tournamentTeamId,
                isStarter: isStarter,
                isOnCourt: isOnCourt,
                minutesPlayed: minutesPlayed,
                lastEnteredAt: lastEnteredAt,
                points: points,
                fieldGoalsMade: fieldGoalsMade,
                fieldGoalsAttempted: fieldGoalsAttempted,
                twoPointersMade: twoPointersMade,
                twoPointersAttempted: twoPointersAttempted,
                threePointersMade: threePointersMade,
                threePointersAttempted: threePointersAttempted,
                freeThrowsMade: freeThrowsMade,
                freeThrowsAttempted: freeThrowsAttempted,
                offensiveRebounds: offensiveRebounds,
                defensiveRebounds: defensiveRebounds,
                totalRebounds: totalRebounds,
                assists: assists,
                steals: steals,
                blocks: blocks,
                turnovers: turnovers,
                personalFouls: personalFouls,
                technicalFouls: technicalFouls,
                unsportsmanlikeFouls: unsportsmanlikeFouls,
                plusMinus: plusMinus,
                fouledOut: fouledOut,
                ejected: ejected,
                isManuallyEdited: isManuallyEdited,
                updatedAt: updatedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPlayerStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPlayerStatsTable,
      LocalPlayerStat,
      $$LocalPlayerStatsTableFilterComposer,
      $$LocalPlayerStatsTableOrderingComposer,
      $$LocalPlayerStatsTableAnnotationComposer,
      $$LocalPlayerStatsTableCreateCompanionBuilder,
      $$LocalPlayerStatsTableUpdateCompanionBuilder,
      (
        LocalPlayerStat,
        BaseReferences<_$AppDatabase, $LocalPlayerStatsTable, LocalPlayerStat>,
      ),
      LocalPlayerStat,
      PrefetchHooks Function()
    >;
typedef $$LocalPlayByPlaysTableCreateCompanionBuilder =
    LocalPlayByPlaysCompanion Function({
      Value<int> id,
      required String localId,
      required int localMatchId,
      required int tournamentTeamPlayerId,
      required int tournamentTeamId,
      required int quarter,
      required int gameClockSeconds,
      Value<int?> shotClockSeconds,
      required String actionType,
      Value<String?> actionSubtype,
      Value<bool?> isMade,
      Value<int> pointsScored,
      Value<double?> courtX,
      Value<double?> courtY,
      Value<int?> courtZone,
      Value<double?> shotDistance,
      Value<int?> assistPlayerId,
      Value<int?> reboundPlayerId,
      Value<int?> blockPlayerId,
      Value<int?> stealPlayerId,
      Value<int?> fouledPlayerId,
      Value<int?> subInPlayerId,
      Value<int?> subOutPlayerId,
      Value<bool> isFlagrant,
      Value<bool> isTechnical,
      Value<bool> isFastbreak,
      Value<bool> isSecondChance,
      Value<bool> isFromTurnover,
      required int homeScoreAtTime,
      required int awayScoreAtTime,
      Value<String?> description,
      Value<String?> linkedActionId,
      Value<bool> isSynced,
      required DateTime createdAt,
    });
typedef $$LocalPlayByPlaysTableUpdateCompanionBuilder =
    LocalPlayByPlaysCompanion Function({
      Value<int> id,
      Value<String> localId,
      Value<int> localMatchId,
      Value<int> tournamentTeamPlayerId,
      Value<int> tournamentTeamId,
      Value<int> quarter,
      Value<int> gameClockSeconds,
      Value<int?> shotClockSeconds,
      Value<String> actionType,
      Value<String?> actionSubtype,
      Value<bool?> isMade,
      Value<int> pointsScored,
      Value<double?> courtX,
      Value<double?> courtY,
      Value<int?> courtZone,
      Value<double?> shotDistance,
      Value<int?> assistPlayerId,
      Value<int?> reboundPlayerId,
      Value<int?> blockPlayerId,
      Value<int?> stealPlayerId,
      Value<int?> fouledPlayerId,
      Value<int?> subInPlayerId,
      Value<int?> subOutPlayerId,
      Value<bool> isFlagrant,
      Value<bool> isTechnical,
      Value<bool> isFastbreak,
      Value<bool> isSecondChance,
      Value<bool> isFromTurnover,
      Value<int> homeScoreAtTime,
      Value<int> awayScoreAtTime,
      Value<String?> description,
      Value<String?> linkedActionId,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
    });

class $$LocalPlayByPlaysTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPlayByPlaysTable> {
  $$LocalPlayByPlaysTableFilterComposer({
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

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localMatchId => $composableBuilder(
    column: $table.localMatchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tournamentTeamPlayerId => $composableBuilder(
    column: $table.tournamentTeamPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tournamentTeamId => $composableBuilder(
    column: $table.tournamentTeamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quarter => $composableBuilder(
    column: $table.quarter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gameClockSeconds => $composableBuilder(
    column: $table.gameClockSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shotClockSeconds => $composableBuilder(
    column: $table.shotClockSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionSubtype => $composableBuilder(
    column: $table.actionSubtype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMade => $composableBuilder(
    column: $table.isMade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointsScored => $composableBuilder(
    column: $table.pointsScored,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get courtX => $composableBuilder(
    column: $table.courtX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get courtY => $composableBuilder(
    column: $table.courtY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get courtZone => $composableBuilder(
    column: $table.courtZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get shotDistance => $composableBuilder(
    column: $table.shotDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assistPlayerId => $composableBuilder(
    column: $table.assistPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reboundPlayerId => $composableBuilder(
    column: $table.reboundPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blockPlayerId => $composableBuilder(
    column: $table.blockPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stealPlayerId => $composableBuilder(
    column: $table.stealPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fouledPlayerId => $composableBuilder(
    column: $table.fouledPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subInPlayerId => $composableBuilder(
    column: $table.subInPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subOutPlayerId => $composableBuilder(
    column: $table.subOutPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFlagrant => $composableBuilder(
    column: $table.isFlagrant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTechnical => $composableBuilder(
    column: $table.isTechnical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFastbreak => $composableBuilder(
    column: $table.isFastbreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSecondChance => $composableBuilder(
    column: $table.isSecondChance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFromTurnover => $composableBuilder(
    column: $table.isFromTurnover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get homeScoreAtTime => $composableBuilder(
    column: $table.homeScoreAtTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awayScoreAtTime => $composableBuilder(
    column: $table.awayScoreAtTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedActionId => $composableBuilder(
    column: $table.linkedActionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPlayByPlaysTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPlayByPlaysTable> {
  $$LocalPlayByPlaysTableOrderingComposer({
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

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localMatchId => $composableBuilder(
    column: $table.localMatchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tournamentTeamPlayerId => $composableBuilder(
    column: $table.tournamentTeamPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tournamentTeamId => $composableBuilder(
    column: $table.tournamentTeamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quarter => $composableBuilder(
    column: $table.quarter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gameClockSeconds => $composableBuilder(
    column: $table.gameClockSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shotClockSeconds => $composableBuilder(
    column: $table.shotClockSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionSubtype => $composableBuilder(
    column: $table.actionSubtype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMade => $composableBuilder(
    column: $table.isMade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointsScored => $composableBuilder(
    column: $table.pointsScored,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get courtX => $composableBuilder(
    column: $table.courtX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get courtY => $composableBuilder(
    column: $table.courtY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get courtZone => $composableBuilder(
    column: $table.courtZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get shotDistance => $composableBuilder(
    column: $table.shotDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assistPlayerId => $composableBuilder(
    column: $table.assistPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reboundPlayerId => $composableBuilder(
    column: $table.reboundPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blockPlayerId => $composableBuilder(
    column: $table.blockPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stealPlayerId => $composableBuilder(
    column: $table.stealPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fouledPlayerId => $composableBuilder(
    column: $table.fouledPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subInPlayerId => $composableBuilder(
    column: $table.subInPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subOutPlayerId => $composableBuilder(
    column: $table.subOutPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFlagrant => $composableBuilder(
    column: $table.isFlagrant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTechnical => $composableBuilder(
    column: $table.isTechnical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFastbreak => $composableBuilder(
    column: $table.isFastbreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSecondChance => $composableBuilder(
    column: $table.isSecondChance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFromTurnover => $composableBuilder(
    column: $table.isFromTurnover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get homeScoreAtTime => $composableBuilder(
    column: $table.homeScoreAtTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awayScoreAtTime => $composableBuilder(
    column: $table.awayScoreAtTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedActionId => $composableBuilder(
    column: $table.linkedActionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPlayByPlaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPlayByPlaysTable> {
  $$LocalPlayByPlaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get localMatchId => $composableBuilder(
    column: $table.localMatchId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tournamentTeamPlayerId => $composableBuilder(
    column: $table.tournamentTeamPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tournamentTeamId => $composableBuilder(
    column: $table.tournamentTeamId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quarter =>
      $composableBuilder(column: $table.quarter, builder: (column) => column);

  GeneratedColumn<int> get gameClockSeconds => $composableBuilder(
    column: $table.gameClockSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shotClockSeconds => $composableBuilder(
    column: $table.shotClockSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actionSubtype => $composableBuilder(
    column: $table.actionSubtype,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMade =>
      $composableBuilder(column: $table.isMade, builder: (column) => column);

  GeneratedColumn<int> get pointsScored => $composableBuilder(
    column: $table.pointsScored,
    builder: (column) => column,
  );

  GeneratedColumn<double> get courtX =>
      $composableBuilder(column: $table.courtX, builder: (column) => column);

  GeneratedColumn<double> get courtY =>
      $composableBuilder(column: $table.courtY, builder: (column) => column);

  GeneratedColumn<int> get courtZone =>
      $composableBuilder(column: $table.courtZone, builder: (column) => column);

  GeneratedColumn<double> get shotDistance => $composableBuilder(
    column: $table.shotDistance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get assistPlayerId => $composableBuilder(
    column: $table.assistPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reboundPlayerId => $composableBuilder(
    column: $table.reboundPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get blockPlayerId => $composableBuilder(
    column: $table.blockPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stealPlayerId => $composableBuilder(
    column: $table.stealPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fouledPlayerId => $composableBuilder(
    column: $table.fouledPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subInPlayerId => $composableBuilder(
    column: $table.subInPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subOutPlayerId => $composableBuilder(
    column: $table.subOutPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFlagrant => $composableBuilder(
    column: $table.isFlagrant,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTechnical => $composableBuilder(
    column: $table.isTechnical,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFastbreak => $composableBuilder(
    column: $table.isFastbreak,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSecondChance => $composableBuilder(
    column: $table.isSecondChance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFromTurnover => $composableBuilder(
    column: $table.isFromTurnover,
    builder: (column) => column,
  );

  GeneratedColumn<int> get homeScoreAtTime => $composableBuilder(
    column: $table.homeScoreAtTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get awayScoreAtTime => $composableBuilder(
    column: $table.awayScoreAtTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedActionId => $composableBuilder(
    column: $table.linkedActionId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalPlayByPlaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPlayByPlaysTable,
          LocalPlayByPlay,
          $$LocalPlayByPlaysTableFilterComposer,
          $$LocalPlayByPlaysTableOrderingComposer,
          $$LocalPlayByPlaysTableAnnotationComposer,
          $$LocalPlayByPlaysTableCreateCompanionBuilder,
          $$LocalPlayByPlaysTableUpdateCompanionBuilder,
          (
            LocalPlayByPlay,
            BaseReferences<
              _$AppDatabase,
              $LocalPlayByPlaysTable,
              LocalPlayByPlay
            >,
          ),
          LocalPlayByPlay,
          PrefetchHooks Function()
        > {
  $$LocalPlayByPlaysTableTableManager(
    _$AppDatabase db,
    $LocalPlayByPlaysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$LocalPlayByPlaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$LocalPlayByPlaysTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalPlayByPlaysTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<int> localMatchId = const Value.absent(),
                Value<int> tournamentTeamPlayerId = const Value.absent(),
                Value<int> tournamentTeamId = const Value.absent(),
                Value<int> quarter = const Value.absent(),
                Value<int> gameClockSeconds = const Value.absent(),
                Value<int?> shotClockSeconds = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String?> actionSubtype = const Value.absent(),
                Value<bool?> isMade = const Value.absent(),
                Value<int> pointsScored = const Value.absent(),
                Value<double?> courtX = const Value.absent(),
                Value<double?> courtY = const Value.absent(),
                Value<int?> courtZone = const Value.absent(),
                Value<double?> shotDistance = const Value.absent(),
                Value<int?> assistPlayerId = const Value.absent(),
                Value<int?> reboundPlayerId = const Value.absent(),
                Value<int?> blockPlayerId = const Value.absent(),
                Value<int?> stealPlayerId = const Value.absent(),
                Value<int?> fouledPlayerId = const Value.absent(),
                Value<int?> subInPlayerId = const Value.absent(),
                Value<int?> subOutPlayerId = const Value.absent(),
                Value<bool> isFlagrant = const Value.absent(),
                Value<bool> isTechnical = const Value.absent(),
                Value<bool> isFastbreak = const Value.absent(),
                Value<bool> isSecondChance = const Value.absent(),
                Value<bool> isFromTurnover = const Value.absent(),
                Value<int> homeScoreAtTime = const Value.absent(),
                Value<int> awayScoreAtTime = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> linkedActionId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocalPlayByPlaysCompanion(
                id: id,
                localId: localId,
                localMatchId: localMatchId,
                tournamentTeamPlayerId: tournamentTeamPlayerId,
                tournamentTeamId: tournamentTeamId,
                quarter: quarter,
                gameClockSeconds: gameClockSeconds,
                shotClockSeconds: shotClockSeconds,
                actionType: actionType,
                actionSubtype: actionSubtype,
                isMade: isMade,
                pointsScored: pointsScored,
                courtX: courtX,
                courtY: courtY,
                courtZone: courtZone,
                shotDistance: shotDistance,
                assistPlayerId: assistPlayerId,
                reboundPlayerId: reboundPlayerId,
                blockPlayerId: blockPlayerId,
                stealPlayerId: stealPlayerId,
                fouledPlayerId: fouledPlayerId,
                subInPlayerId: subInPlayerId,
                subOutPlayerId: subOutPlayerId,
                isFlagrant: isFlagrant,
                isTechnical: isTechnical,
                isFastbreak: isFastbreak,
                isSecondChance: isSecondChance,
                isFromTurnover: isFromTurnover,
                homeScoreAtTime: homeScoreAtTime,
                awayScoreAtTime: awayScoreAtTime,
                description: description,
                linkedActionId: linkedActionId,
                isSynced: isSynced,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String localId,
                required int localMatchId,
                required int tournamentTeamPlayerId,
                required int tournamentTeamId,
                required int quarter,
                required int gameClockSeconds,
                Value<int?> shotClockSeconds = const Value.absent(),
                required String actionType,
                Value<String?> actionSubtype = const Value.absent(),
                Value<bool?> isMade = const Value.absent(),
                Value<int> pointsScored = const Value.absent(),
                Value<double?> courtX = const Value.absent(),
                Value<double?> courtY = const Value.absent(),
                Value<int?> courtZone = const Value.absent(),
                Value<double?> shotDistance = const Value.absent(),
                Value<int?> assistPlayerId = const Value.absent(),
                Value<int?> reboundPlayerId = const Value.absent(),
                Value<int?> blockPlayerId = const Value.absent(),
                Value<int?> stealPlayerId = const Value.absent(),
                Value<int?> fouledPlayerId = const Value.absent(),
                Value<int?> subInPlayerId = const Value.absent(),
                Value<int?> subOutPlayerId = const Value.absent(),
                Value<bool> isFlagrant = const Value.absent(),
                Value<bool> isTechnical = const Value.absent(),
                Value<bool> isFastbreak = const Value.absent(),
                Value<bool> isSecondChance = const Value.absent(),
                Value<bool> isFromTurnover = const Value.absent(),
                required int homeScoreAtTime,
                required int awayScoreAtTime,
                Value<String?> description = const Value.absent(),
                Value<String?> linkedActionId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                required DateTime createdAt,
              }) => LocalPlayByPlaysCompanion.insert(
                id: id,
                localId: localId,
                localMatchId: localMatchId,
                tournamentTeamPlayerId: tournamentTeamPlayerId,
                tournamentTeamId: tournamentTeamId,
                quarter: quarter,
                gameClockSeconds: gameClockSeconds,
                shotClockSeconds: shotClockSeconds,
                actionType: actionType,
                actionSubtype: actionSubtype,
                isMade: isMade,
                pointsScored: pointsScored,
                courtX: courtX,
                courtY: courtY,
                courtZone: courtZone,
                shotDistance: shotDistance,
                assistPlayerId: assistPlayerId,
                reboundPlayerId: reboundPlayerId,
                blockPlayerId: blockPlayerId,
                stealPlayerId: stealPlayerId,
                fouledPlayerId: fouledPlayerId,
                subInPlayerId: subInPlayerId,
                subOutPlayerId: subOutPlayerId,
                isFlagrant: isFlagrant,
                isTechnical: isTechnical,
                isFastbreak: isFastbreak,
                isSecondChance: isSecondChance,
                isFromTurnover: isFromTurnover,
                homeScoreAtTime: homeScoreAtTime,
                awayScoreAtTime: awayScoreAtTime,
                description: description,
                linkedActionId: linkedActionId,
                isSynced: isSynced,
                createdAt: createdAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPlayByPlaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPlayByPlaysTable,
      LocalPlayByPlay,
      $$LocalPlayByPlaysTableFilterComposer,
      $$LocalPlayByPlaysTableOrderingComposer,
      $$LocalPlayByPlaysTableAnnotationComposer,
      $$LocalPlayByPlaysTableCreateCompanionBuilder,
      $$LocalPlayByPlaysTableUpdateCompanionBuilder,
      (
        LocalPlayByPlay,
        BaseReferences<_$AppDatabase, $LocalPlayByPlaysTable, LocalPlayByPlay>,
      ),
      LocalPlayByPlay,
      PrefetchHooks Function()
    >;
typedef $$RecentTournamentsTableCreateCompanionBuilder =
    RecentTournamentsCompanion Function({
      required String tournamentId,
      required String tournamentName,
      required String apiToken,
      required DateTime connectedAt,
      Value<int> rowid,
    });
typedef $$RecentTournamentsTableUpdateCompanionBuilder =
    RecentTournamentsCompanion Function({
      Value<String> tournamentId,
      Value<String> tournamentName,
      Value<String> apiToken,
      Value<DateTime> connectedAt,
      Value<int> rowid,
    });

class $$RecentTournamentsTableFilterComposer
    extends Composer<_$AppDatabase, $RecentTournamentsTable> {
  $$RecentTournamentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tournamentName => $composableBuilder(
    column: $table.tournamentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiToken => $composableBuilder(
    column: $table.apiToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecentTournamentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentTournamentsTable> {
  $$RecentTournamentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tournamentName => $composableBuilder(
    column: $table.tournamentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiToken => $composableBuilder(
    column: $table.apiToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecentTournamentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentTournamentsTable> {
  $$RecentTournamentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tournamentName => $composableBuilder(
    column: $table.tournamentName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get apiToken =>
      $composableBuilder(column: $table.apiToken, builder: (column) => column);

  GeneratedColumn<DateTime> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => column,
  );
}

class $$RecentTournamentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecentTournamentsTable,
          RecentTournament,
          $$RecentTournamentsTableFilterComposer,
          $$RecentTournamentsTableOrderingComposer,
          $$RecentTournamentsTableAnnotationComposer,
          $$RecentTournamentsTableCreateCompanionBuilder,
          $$RecentTournamentsTableUpdateCompanionBuilder,
          (
            RecentTournament,
            BaseReferences<
              _$AppDatabase,
              $RecentTournamentsTable,
              RecentTournament
            >,
          ),
          RecentTournament,
          PrefetchHooks Function()
        > {
  $$RecentTournamentsTableTableManager(
    _$AppDatabase db,
    $RecentTournamentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RecentTournamentsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$RecentTournamentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$RecentTournamentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tournamentId = const Value.absent(),
                Value<String> tournamentName = const Value.absent(),
                Value<String> apiToken = const Value.absent(),
                Value<DateTime> connectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentTournamentsCompanion(
                tournamentId: tournamentId,
                tournamentName: tournamentName,
                apiToken: apiToken,
                connectedAt: connectedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tournamentId,
                required String tournamentName,
                required String apiToken,
                required DateTime connectedAt,
                Value<int> rowid = const Value.absent(),
              }) => RecentTournamentsCompanion.insert(
                tournamentId: tournamentId,
                tournamentName: tournamentName,
                apiToken: apiToken,
                connectedAt: connectedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecentTournamentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecentTournamentsTable,
      RecentTournament,
      $$RecentTournamentsTableFilterComposer,
      $$RecentTournamentsTableOrderingComposer,
      $$RecentTournamentsTableAnnotationComposer,
      $$RecentTournamentsTableCreateCompanionBuilder,
      $$RecentTournamentsTableUpdateCompanionBuilder,
      (
        RecentTournament,
        BaseReferences<
          _$AppDatabase,
          $RecentTournamentsTable,
          RecentTournament
        >,
      ),
      RecentTournament,
      PrefetchHooks Function()
    >;
typedef $$LocalEditLogsTableCreateCompanionBuilder =
    LocalEditLogsCompanion Function({
      Value<int> id,
      required int localMatchId,
      required String targetType,
      required int targetId,
      Value<String?> targetLocalId,
      required String editType,
      Value<String?> fieldName,
      Value<String?> oldValue,
      Value<String?> newValue,
      Value<String?> description,
      Value<int?> editorPlayerId,
      required DateTime editedAt,
    });
typedef $$LocalEditLogsTableUpdateCompanionBuilder =
    LocalEditLogsCompanion Function({
      Value<int> id,
      Value<int> localMatchId,
      Value<String> targetType,
      Value<int> targetId,
      Value<String?> targetLocalId,
      Value<String> editType,
      Value<String?> fieldName,
      Value<String?> oldValue,
      Value<String?> newValue,
      Value<String?> description,
      Value<int?> editorPlayerId,
      Value<DateTime> editedAt,
    });

class $$LocalEditLogsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalEditLogsTable> {
  $$LocalEditLogsTableFilterComposer({
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

  ColumnFilters<int> get localMatchId => $composableBuilder(
    column: $table.localMatchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetLocalId => $composableBuilder(
    column: $table.targetLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get editType => $composableBuilder(
    column: $table.editType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editorPlayerId => $composableBuilder(
    column: $table.editorPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalEditLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalEditLogsTable> {
  $$LocalEditLogsTableOrderingComposer({
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

  ColumnOrderings<int> get localMatchId => $composableBuilder(
    column: $table.localMatchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetLocalId => $composableBuilder(
    column: $table.targetLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editType => $composableBuilder(
    column: $table.editType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editorPlayerId => $composableBuilder(
    column: $table.editorPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalEditLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalEditLogsTable> {
  $$LocalEditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get localMatchId => $composableBuilder(
    column: $table.localMatchId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get targetLocalId => $composableBuilder(
    column: $table.targetLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get editType =>
      $composableBuilder(column: $table.editType, builder: (column) => column);

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get oldValue =>
      $composableBuilder(column: $table.oldValue, builder: (column) => column);

  GeneratedColumn<String> get newValue =>
      $composableBuilder(column: $table.newValue, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get editorPlayerId => $composableBuilder(
    column: $table.editorPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);
}

class $$LocalEditLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalEditLogsTable,
          LocalEditLog,
          $$LocalEditLogsTableFilterComposer,
          $$LocalEditLogsTableOrderingComposer,
          $$LocalEditLogsTableAnnotationComposer,
          $$LocalEditLogsTableCreateCompanionBuilder,
          $$LocalEditLogsTableUpdateCompanionBuilder,
          (
            LocalEditLog,
            BaseReferences<_$AppDatabase, $LocalEditLogsTable, LocalEditLog>,
          ),
          LocalEditLog,
          PrefetchHooks Function()
        > {
  $$LocalEditLogsTableTableManager(_$AppDatabase db, $LocalEditLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalEditLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$LocalEditLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$LocalEditLogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> localMatchId = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<int> targetId = const Value.absent(),
                Value<String?> targetLocalId = const Value.absent(),
                Value<String> editType = const Value.absent(),
                Value<String?> fieldName = const Value.absent(),
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> editorPlayerId = const Value.absent(),
                Value<DateTime> editedAt = const Value.absent(),
              }) => LocalEditLogsCompanion(
                id: id,
                localMatchId: localMatchId,
                targetType: targetType,
                targetId: targetId,
                targetLocalId: targetLocalId,
                editType: editType,
                fieldName: fieldName,
                oldValue: oldValue,
                newValue: newValue,
                description: description,
                editorPlayerId: editorPlayerId,
                editedAt: editedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int localMatchId,
                required String targetType,
                required int targetId,
                Value<String?> targetLocalId = const Value.absent(),
                required String editType,
                Value<String?> fieldName = const Value.absent(),
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> editorPlayerId = const Value.absent(),
                required DateTime editedAt,
              }) => LocalEditLogsCompanion.insert(
                id: id,
                localMatchId: localMatchId,
                targetType: targetType,
                targetId: targetId,
                targetLocalId: targetLocalId,
                editType: editType,
                fieldName: fieldName,
                oldValue: oldValue,
                newValue: newValue,
                description: description,
                editorPlayerId: editorPlayerId,
                editedAt: editedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalEditLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalEditLogsTable,
      LocalEditLog,
      $$LocalEditLogsTableFilterComposer,
      $$LocalEditLogsTableOrderingComposer,
      $$LocalEditLogsTableAnnotationComposer,
      $$LocalEditLogsTableCreateCompanionBuilder,
      $$LocalEditLogsTableUpdateCompanionBuilder,
      (
        LocalEditLog,
        BaseReferences<_$AppDatabase, $LocalEditLogsTable, LocalEditLog>,
      ),
      LocalEditLog,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalTournamentsTableTableManager get localTournaments =>
      $$LocalTournamentsTableTableManager(_db, _db.localTournaments);
  $$LocalTournamentTeamsTableTableManager get localTournamentTeams =>
      $$LocalTournamentTeamsTableTableManager(_db, _db.localTournamentTeams);
  $$LocalTournamentPlayersTableTableManager get localTournamentPlayers =>
      $$LocalTournamentPlayersTableTableManager(
        _db,
        _db.localTournamentPlayers,
      );
  $$LocalMatchesTableTableManager get localMatches =>
      $$LocalMatchesTableTableManager(_db, _db.localMatches);
  $$LocalPlayerStatsTableTableManager get localPlayerStats =>
      $$LocalPlayerStatsTableTableManager(_db, _db.localPlayerStats);
  $$LocalPlayByPlaysTableTableManager get localPlayByPlays =>
      $$LocalPlayByPlaysTableTableManager(_db, _db.localPlayByPlays);
  $$RecentTournamentsTableTableManager get recentTournaments =>
      $$RecentTournamentsTableTableManager(_db, _db.recentTournaments);
  $$LocalEditLogsTableTableManager get localEditLogs =>
      $$LocalEditLogsTableTableManager(_db, _db.localEditLogs);
}
