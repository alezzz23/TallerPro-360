// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
mixin _$CachedOrdersDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedOrdersTable get cachedOrders => attachedDatabase.cachedOrders;
}
mixin _$SyncQueueDaoMixin on DatabaseAccessor<AppDatabase> {
  $OfflineSyncQueueTable get offlineSyncQueue =>
      attachedDatabase.offlineSyncQueue;
}

class $CachedOrdersTable extends CachedOrders
    with TableInfo<$CachedOrdersTable, CachedOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jsonBlobMeta =
      const VerificationMeta('jsonBlob');
  @override
  late final GeneratedColumn<String> jsonBlob = GeneratedColumn<String>(
      'json_blob', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _serverEtagMeta =
      const VerificationMeta('serverEtag');
  @override
  late final GeneratedColumn<String> serverEtag = GeneratedColumn<String>(
      'server_etag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [orderId, jsonBlob, cachedAt, serverEtag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_orders';
  @override
  VerificationContext validateIntegrity(Insertable<CachedOrder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('json_blob')) {
      context.handle(_jsonBlobMeta,
          jsonBlob.isAcceptableOrUnknown(data['json_blob']!, _jsonBlobMeta));
    } else if (isInserting) {
      context.missing(_jsonBlobMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('server_etag')) {
      context.handle(
          _serverEtagMeta,
          serverEtag.isAcceptableOrUnknown(
              data['server_etag']!, _serverEtagMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {orderId};
  @override
  CachedOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedOrder(
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id'])!,
      jsonBlob: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json_blob'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
      serverEtag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_etag']),
    );
  }

  @override
  $CachedOrdersTable createAlias(String alias) {
    return $CachedOrdersTable(attachedDatabase, alias);
  }
}

class CachedOrder extends DataClass implements Insertable<CachedOrder> {
  /// UUID string — primary key
  final String orderId;

  /// Full JSON blob of the assembled DashboardOrder
  final String jsonBlob;

  /// When this entry was last fetched from the server
  final DateTime cachedAt;

  /// Server ETag (optional, for conditional requests)
  final String? serverEtag;
  const CachedOrder(
      {required this.orderId,
      required this.jsonBlob,
      required this.cachedAt,
      this.serverEtag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['order_id'] = Variable<String>(orderId);
    map['json_blob'] = Variable<String>(jsonBlob);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    if (!nullToAbsent || serverEtag != null) {
      map['server_etag'] = Variable<String>(serverEtag);
    }
    return map;
  }

  CachedOrdersCompanion toCompanion(bool nullToAbsent) {
    return CachedOrdersCompanion(
      orderId: Value(orderId),
      jsonBlob: Value(jsonBlob),
      cachedAt: Value(cachedAt),
      serverEtag: serverEtag == null && nullToAbsent
          ? const Value.absent()
          : Value(serverEtag),
    );
  }

  factory CachedOrder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedOrder(
      orderId: serializer.fromJson<String>(json['orderId']),
      jsonBlob: serializer.fromJson<String>(json['jsonBlob']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      serverEtag: serializer.fromJson<String?>(json['serverEtag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'orderId': serializer.toJson<String>(orderId),
      'jsonBlob': serializer.toJson<String>(jsonBlob),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'serverEtag': serializer.toJson<String?>(serverEtag),
    };
  }

  CachedOrder copyWith(
          {String? orderId,
          String? jsonBlob,
          DateTime? cachedAt,
          Value<String?> serverEtag = const Value.absent()}) =>
      CachedOrder(
        orderId: orderId ?? this.orderId,
        jsonBlob: jsonBlob ?? this.jsonBlob,
        cachedAt: cachedAt ?? this.cachedAt,
        serverEtag: serverEtag.present ? serverEtag.value : this.serverEtag,
      );
  CachedOrder copyWithCompanion(CachedOrdersCompanion data) {
    return CachedOrder(
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      jsonBlob: data.jsonBlob.present ? data.jsonBlob.value : this.jsonBlob,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      serverEtag:
          data.serverEtag.present ? data.serverEtag.value : this.serverEtag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedOrder(')
          ..write('orderId: $orderId, ')
          ..write('jsonBlob: $jsonBlob, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('serverEtag: $serverEtag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(orderId, jsonBlob, cachedAt, serverEtag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedOrder &&
          other.orderId == this.orderId &&
          other.jsonBlob == this.jsonBlob &&
          other.cachedAt == this.cachedAt &&
          other.serverEtag == this.serverEtag);
}

class CachedOrdersCompanion extends UpdateCompanion<CachedOrder> {
  final Value<String> orderId;
  final Value<String> jsonBlob;
  final Value<DateTime> cachedAt;
  final Value<String?> serverEtag;
  final Value<int> rowid;
  const CachedOrdersCompanion({
    this.orderId = const Value.absent(),
    this.jsonBlob = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.serverEtag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedOrdersCompanion.insert({
    required String orderId,
    required String jsonBlob,
    required DateTime cachedAt,
    this.serverEtag = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : orderId = Value(orderId),
        jsonBlob = Value(jsonBlob),
        cachedAt = Value(cachedAt);
  static Insertable<CachedOrder> custom({
    Expression<String>? orderId,
    Expression<String>? jsonBlob,
    Expression<DateTime>? cachedAt,
    Expression<String>? serverEtag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (orderId != null) 'order_id': orderId,
      if (jsonBlob != null) 'json_blob': jsonBlob,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (serverEtag != null) 'server_etag': serverEtag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedOrdersCompanion copyWith(
      {Value<String>? orderId,
      Value<String>? jsonBlob,
      Value<DateTime>? cachedAt,
      Value<String?>? serverEtag,
      Value<int>? rowid}) {
    return CachedOrdersCompanion(
      orderId: orderId ?? this.orderId,
      jsonBlob: jsonBlob ?? this.jsonBlob,
      cachedAt: cachedAt ?? this.cachedAt,
      serverEtag: serverEtag ?? this.serverEtag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (jsonBlob.present) {
      map['json_blob'] = Variable<String>(jsonBlob.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (serverEtag.present) {
      map['server_etag'] = Variable<String>(serverEtag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedOrdersCompanion(')
          ..write('orderId: $orderId, ')
          ..write('jsonBlob: $jsonBlob, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('serverEtag: $serverEtag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineSyncQueueTable extends OfflineSyncQueue
    with TableInfo<$OfflineSyncQueueTable, OfflineSyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineSyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _endpointMeta =
      const VerificationMeta('endpoint');
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
      'endpoint', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _httpMethodMeta =
      const VerificationMeta('httpMethod');
  @override
  late final GeneratedColumn<String> httpMethod = GeneratedColumn<String>(
      'http_method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyJsonMeta =
      const VerificationMeta('bodyJson');
  @override
  late final GeneratedColumn<String> bodyJson = GeneratedColumn<String>(
      'body_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _failureReasonMeta =
      const VerificationMeta('failureReason');
  @override
  late final GeneratedColumn<String> failureReason = GeneratedColumn<String>(
      'failure_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        endpoint,
        httpMethod,
        bodyJson,
        createdAt,
        attemptCount,
        failureReason,
        completed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_sync_queue';
  @override
  VerificationContext validateIntegrity(
      Insertable<OfflineSyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    }
    if (data.containsKey('endpoint')) {
      context.handle(_endpointMeta,
          endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta));
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('http_method')) {
      context.handle(
          _httpMethodMeta,
          httpMethod.isAcceptableOrUnknown(
              data['http_method']!, _httpMethodMeta));
    } else if (isInserting) {
      context.missing(_httpMethodMeta);
    }
    if (data.containsKey('body_json')) {
      context.handle(_bodyJsonMeta,
          bodyJson.isAcceptableOrUnknown(data['body_json']!, _bodyJsonMeta));
    } else if (isInserting) {
      context.missing(_bodyJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    } else if (isInserting) {
      context.missing(_attemptCountMeta);
    }
    if (data.containsKey('failure_reason')) {
      context.handle(
          _failureReasonMeta,
          failureReason.isAcceptableOrUnknown(
              data['failure_reason']!, _failureReasonMeta));
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineSyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineSyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id']),
      endpoint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}endpoint'])!,
      httpMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}http_method'])!,
      bodyJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      failureReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}failure_reason']),
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
    );
  }

  @override
  $OfflineSyncQueueTable createAlias(String alias) {
    return $OfflineSyncQueueTable(attachedDatabase, alias);
  }
}

class OfflineSyncQueueData extends DataClass
    implements Insertable<OfflineSyncQueueData> {
  final int id;

  /// The affected order UUID (nullable for non-order-specific ops)
  final String? orderId;

  /// Full API path, e.g. '/api/v1/orders/xxx/reception-checklist'
  final String endpoint;

  /// HTTP method: 'POST', 'PUT', 'PATCH'
  final String httpMethod;

  /// Serialized JSON body
  final String bodyJson;

  /// When this operation was enqueued
  final DateTime createdAt;

  /// Number of replay attempts (max 3)
  final int attemptCount;

  /// Last failure reason (if any)
  final String? failureReason;

  /// True once successfully replayed
  final bool completed;
  const OfflineSyncQueueData(
      {required this.id,
      this.orderId,
      required this.endpoint,
      required this.httpMethod,
      required this.bodyJson,
      required this.createdAt,
      required this.attemptCount,
      this.failureReason,
      required this.completed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<String>(orderId);
    }
    map['endpoint'] = Variable<String>(endpoint);
    map['http_method'] = Variable<String>(httpMethod);
    map['body_json'] = Variable<String>(bodyJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || failureReason != null) {
      map['failure_reason'] = Variable<String>(failureReason);
    }
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  OfflineSyncQueueCompanion toCompanion(bool nullToAbsent) {
    return OfflineSyncQueueCompanion(
      id: Value(id),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      endpoint: Value(endpoint),
      httpMethod: Value(httpMethod),
      bodyJson: Value(bodyJson),
      createdAt: Value(createdAt),
      attemptCount: Value(attemptCount),
      failureReason: failureReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failureReason),
      completed: Value(completed),
    );
  }

  factory OfflineSyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineSyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      orderId: serializer.fromJson<String?>(json['orderId']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      httpMethod: serializer.fromJson<String>(json['httpMethod']),
      bodyJson: serializer.fromJson<String>(json['bodyJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      failureReason: serializer.fromJson<String?>(json['failureReason']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderId': serializer.toJson<String?>(orderId),
      'endpoint': serializer.toJson<String>(endpoint),
      'httpMethod': serializer.toJson<String>(httpMethod),
      'bodyJson': serializer.toJson<String>(bodyJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'failureReason': serializer.toJson<String?>(failureReason),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  OfflineSyncQueueData copyWith(
          {int? id,
          Value<String?> orderId = const Value.absent(),
          String? endpoint,
          String? httpMethod,
          String? bodyJson,
          DateTime? createdAt,
          int? attemptCount,
          Value<String?> failureReason = const Value.absent(),
          bool? completed}) =>
      OfflineSyncQueueData(
        id: id ?? this.id,
        orderId: orderId.present ? orderId.value : this.orderId,
        endpoint: endpoint ?? this.endpoint,
        httpMethod: httpMethod ?? this.httpMethod,
        bodyJson: bodyJson ?? this.bodyJson,
        createdAt: createdAt ?? this.createdAt,
        attemptCount: attemptCount ?? this.attemptCount,
        failureReason:
            failureReason.present ? failureReason.value : this.failureReason,
        completed: completed ?? this.completed,
      );
  OfflineSyncQueueData copyWithCompanion(OfflineSyncQueueCompanion data) {
    return OfflineSyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      httpMethod:
          data.httpMethod.present ? data.httpMethod.value : this.httpMethod,
      bodyJson: data.bodyJson.present ? data.bodyJson.value : this.bodyJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      failureReason: data.failureReason.present
          ? data.failureReason.value
          : this.failureReason,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineSyncQueueData(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('endpoint: $endpoint, ')
          ..write('httpMethod: $httpMethod, ')
          ..write('bodyJson: $bodyJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('failureReason: $failureReason, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, orderId, endpoint, httpMethod, bodyJson,
      createdAt, attemptCount, failureReason, completed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineSyncQueueData &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.endpoint == this.endpoint &&
          other.httpMethod == this.httpMethod &&
          other.bodyJson == this.bodyJson &&
          other.createdAt == this.createdAt &&
          other.attemptCount == this.attemptCount &&
          other.failureReason == this.failureReason &&
          other.completed == this.completed);
}

class OfflineSyncQueueCompanion extends UpdateCompanion<OfflineSyncQueueData> {
  final Value<int> id;
  final Value<String?> orderId;
  final Value<String> endpoint;
  final Value<String> httpMethod;
  final Value<String> bodyJson;
  final Value<DateTime> createdAt;
  final Value<int> attemptCount;
  final Value<String?> failureReason;
  final Value<bool> completed;
  const OfflineSyncQueueCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.httpMethod = const Value.absent(),
    this.bodyJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.completed = const Value.absent(),
  });
  OfflineSyncQueueCompanion.insert({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    required String endpoint,
    required String httpMethod,
    required String bodyJson,
    required DateTime createdAt,
    required int attemptCount,
    this.failureReason = const Value.absent(),
    required bool completed,
  })  : endpoint = Value(endpoint),
        httpMethod = Value(httpMethod),
        bodyJson = Value(bodyJson),
        createdAt = Value(createdAt),
        attemptCount = Value(attemptCount),
        completed = Value(completed);
  static Insertable<OfflineSyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? orderId,
    Expression<String>? endpoint,
    Expression<String>? httpMethod,
    Expression<String>? bodyJson,
    Expression<DateTime>? createdAt,
    Expression<int>? attemptCount,
    Expression<String>? failureReason,
    Expression<bool>? completed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (endpoint != null) 'endpoint': endpoint,
      if (httpMethod != null) 'http_method': httpMethod,
      if (bodyJson != null) 'body_json': bodyJson,
      if (createdAt != null) 'created_at': createdAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (failureReason != null) 'failure_reason': failureReason,
      if (completed != null) 'completed': completed,
    });
  }

  OfflineSyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String?>? orderId,
      Value<String>? endpoint,
      Value<String>? httpMethod,
      Value<String>? bodyJson,
      Value<DateTime>? createdAt,
      Value<int>? attemptCount,
      Value<String?>? failureReason,
      Value<bool>? completed}) {
    return OfflineSyncQueueCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      endpoint: endpoint ?? this.endpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      bodyJson: bodyJson ?? this.bodyJson,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      failureReason: failureReason ?? this.failureReason,
      completed: completed ?? this.completed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (httpMethod.present) {
      map['http_method'] = Variable<String>(httpMethod.value);
    }
    if (bodyJson.present) {
      map['body_json'] = Variable<String>(bodyJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (failureReason.present) {
      map['failure_reason'] = Variable<String>(failureReason.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineSyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('endpoint: $endpoint, ')
          ..write('httpMethod: $httpMethod, ')
          ..write('bodyJson: $bodyJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('failureReason: $failureReason, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedOrdersTable cachedOrders = $CachedOrdersTable(this);
  late final $OfflineSyncQueueTable offlineSyncQueue =
      $OfflineSyncQueueTable(this);
  late final CachedOrdersDao cachedOrdersDao =
      CachedOrdersDao(this as AppDatabase);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [cachedOrders, offlineSyncQueue];
}

typedef $$CachedOrdersTableCreateCompanionBuilder = CachedOrdersCompanion
    Function({
  required String orderId,
  required String jsonBlob,
  required DateTime cachedAt,
  Value<String?> serverEtag,
  Value<int> rowid,
});
typedef $$CachedOrdersTableUpdateCompanionBuilder = CachedOrdersCompanion
    Function({
  Value<String> orderId,
  Value<String> jsonBlob,
  Value<DateTime> cachedAt,
  Value<String?> serverEtag,
  Value<int> rowid,
});

class $$CachedOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedOrdersTable> {
  $$CachedOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jsonBlob => $composableBuilder(
      column: $table.jsonBlob, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverEtag => $composableBuilder(
      column: $table.serverEtag, builder: (column) => ColumnFilters(column));
}

class $$CachedOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedOrdersTable> {
  $$CachedOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jsonBlob => $composableBuilder(
      column: $table.jsonBlob, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverEtag => $composableBuilder(
      column: $table.serverEtag, builder: (column) => ColumnOrderings(column));
}

class $$CachedOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedOrdersTable> {
  $$CachedOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get jsonBlob =>
      $composableBuilder(column: $table.jsonBlob, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<String> get serverEtag => $composableBuilder(
      column: $table.serverEtag, builder: (column) => column);
}

class $$CachedOrdersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedOrdersTable,
    CachedOrder,
    $$CachedOrdersTableFilterComposer,
    $$CachedOrdersTableOrderingComposer,
    $$CachedOrdersTableAnnotationComposer,
    $$CachedOrdersTableCreateCompanionBuilder,
    $$CachedOrdersTableUpdateCompanionBuilder,
    (
      CachedOrder,
      BaseReferences<_$AppDatabase, $CachedOrdersTable, CachedOrder>
    ),
    CachedOrder,
    PrefetchHooks Function()> {
  $$CachedOrdersTableTableManager(_$AppDatabase db, $CachedOrdersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> orderId = const Value.absent(),
            Value<String> jsonBlob = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<String?> serverEtag = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedOrdersCompanion(
            orderId: orderId,
            jsonBlob: jsonBlob,
            cachedAt: cachedAt,
            serverEtag: serverEtag,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String orderId,
            required String jsonBlob,
            required DateTime cachedAt,
            Value<String?> serverEtag = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedOrdersCompanion.insert(
            orderId: orderId,
            jsonBlob: jsonBlob,
            cachedAt: cachedAt,
            serverEtag: serverEtag,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedOrdersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedOrdersTable,
    CachedOrder,
    $$CachedOrdersTableFilterComposer,
    $$CachedOrdersTableOrderingComposer,
    $$CachedOrdersTableAnnotationComposer,
    $$CachedOrdersTableCreateCompanionBuilder,
    $$CachedOrdersTableUpdateCompanionBuilder,
    (
      CachedOrder,
      BaseReferences<_$AppDatabase, $CachedOrdersTable, CachedOrder>
    ),
    CachedOrder,
    PrefetchHooks Function()>;
typedef $$OfflineSyncQueueTableCreateCompanionBuilder
    = OfflineSyncQueueCompanion Function({
  Value<int> id,
  Value<String?> orderId,
  required String endpoint,
  required String httpMethod,
  required String bodyJson,
  required DateTime createdAt,
  required int attemptCount,
  Value<String?> failureReason,
  required bool completed,
});
typedef $$OfflineSyncQueueTableUpdateCompanionBuilder
    = OfflineSyncQueueCompanion Function({
  Value<int> id,
  Value<String?> orderId,
  Value<String> endpoint,
  Value<String> httpMethod,
  Value<String> bodyJson,
  Value<DateTime> createdAt,
  Value<int> attemptCount,
  Value<String?> failureReason,
  Value<bool> completed,
});

class $$OfflineSyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineSyncQueueTable> {
  $$OfflineSyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endpoint => $composableBuilder(
      column: $table.endpoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get httpMethod => $composableBuilder(
      column: $table.httpMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bodyJson => $composableBuilder(
      column: $table.bodyJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get failureReason => $composableBuilder(
      column: $table.failureReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));
}

class $$OfflineSyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineSyncQueueTable> {
  $$OfflineSyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderId => $composableBuilder(
      column: $table.orderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endpoint => $composableBuilder(
      column: $table.endpoint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get httpMethod => $composableBuilder(
      column: $table.httpMethod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodyJson => $composableBuilder(
      column: $table.bodyJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get failureReason => $composableBuilder(
      column: $table.failureReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));
}

class $$OfflineSyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineSyncQueueTable> {
  $$OfflineSyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get httpMethod => $composableBuilder(
      column: $table.httpMethod, builder: (column) => column);

  GeneratedColumn<String> get bodyJson =>
      $composableBuilder(column: $table.bodyJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<String> get failureReason => $composableBuilder(
      column: $table.failureReason, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$OfflineSyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OfflineSyncQueueTable,
    OfflineSyncQueueData,
    $$OfflineSyncQueueTableFilterComposer,
    $$OfflineSyncQueueTableOrderingComposer,
    $$OfflineSyncQueueTableAnnotationComposer,
    $$OfflineSyncQueueTableCreateCompanionBuilder,
    $$OfflineSyncQueueTableUpdateCompanionBuilder,
    (
      OfflineSyncQueueData,
      BaseReferences<_$AppDatabase, $OfflineSyncQueueTable,
          OfflineSyncQueueData>
    ),
    OfflineSyncQueueData,
    PrefetchHooks Function()> {
  $$OfflineSyncQueueTableTableManager(
      _$AppDatabase db, $OfflineSyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineSyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineSyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineSyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> orderId = const Value.absent(),
            Value<String> endpoint = const Value.absent(),
            Value<String> httpMethod = const Value.absent(),
            Value<String> bodyJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<String?> failureReason = const Value.absent(),
            Value<bool> completed = const Value.absent(),
          }) =>
              OfflineSyncQueueCompanion(
            id: id,
            orderId: orderId,
            endpoint: endpoint,
            httpMethod: httpMethod,
            bodyJson: bodyJson,
            createdAt: createdAt,
            attemptCount: attemptCount,
            failureReason: failureReason,
            completed: completed,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> orderId = const Value.absent(),
            required String endpoint,
            required String httpMethod,
            required String bodyJson,
            required DateTime createdAt,
            required int attemptCount,
            Value<String?> failureReason = const Value.absent(),
            required bool completed,
          }) =>
              OfflineSyncQueueCompanion.insert(
            id: id,
            orderId: orderId,
            endpoint: endpoint,
            httpMethod: httpMethod,
            bodyJson: bodyJson,
            createdAt: createdAt,
            attemptCount: attemptCount,
            failureReason: failureReason,
            completed: completed,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OfflineSyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OfflineSyncQueueTable,
    OfflineSyncQueueData,
    $$OfflineSyncQueueTableFilterComposer,
    $$OfflineSyncQueueTableOrderingComposer,
    $$OfflineSyncQueueTableAnnotationComposer,
    $$OfflineSyncQueueTableCreateCompanionBuilder,
    $$OfflineSyncQueueTableUpdateCompanionBuilder,
    (
      OfflineSyncQueueData,
      BaseReferences<_$AppDatabase, $OfflineSyncQueueTable,
          OfflineSyncQueueData>
    ),
    OfflineSyncQueueData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedOrdersTableTableManager get cachedOrders =>
      $$CachedOrdersTableTableManager(_db, _db.cachedOrders);
  $$OfflineSyncQueueTableTableManager get offlineSyncQueue =>
      $$OfflineSyncQueueTableTableManager(_db, _db.offlineSyncQueue);
}
