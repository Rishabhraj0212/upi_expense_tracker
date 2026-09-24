// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransactionType>($TransactionsTable.$convertertype);
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantNameMeta = const VerificationMeta(
    'merchantName',
  );
  @override
  late final GeneratedColumn<String> merchantName = GeneratedColumn<String>(
    'merchant_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _upiIdMeta = const VerificationMeta('upiId');
  @override
  late final GeneratedColumn<String> upiId = GeneratedColumn<String>(
    'upi_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountHintMeta = const VerificationMeta(
    'accountHint',
  );
  @override
  late final GeneratedColumn<String> accountHint = GeneratedColumn<String>(
    'account_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mergedSourcesMeta = const VerificationMeta(
    'mergedSources',
  );
  @override
  late final GeneratedColumn<String> mergedSources = GeneratedColumn<String>(
    'merged_sources',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceAppMeta = const VerificationMeta(
    'sourceApp',
  );
  @override
  late final GeneratedColumn<String> sourceApp = GeneratedColumn<String>(
    'source_app',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceAddressMeta = const VerificationMeta(
    'sourceAddress',
  );
  @override
  late final GeneratedColumn<String> sourceAddress = GeneratedColumn<String>(
    'source_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
  late final GeneratedColumnWithTypeConverter<TransactionSyncStatus, String>
  syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransactionSyncStatus>(
        $TransactionsTable.$convertersyncStatus,
      );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteRowRefMeta = const VerificationMeta(
    'remoteRowRef',
  );
  @override
  late final GeneratedColumn<String> remoteRowRef = GeneratedColumn<String>(
    'remote_row_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amountPaise,
    type,
    occurredAt,
    receivedAt,
    merchantName,
    upiId,
    bankName,
    accountHint,
    referenceId,
    mergedSources,
    sourceApp,
    sourceAddress,
    rawText,
    category,
    note,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    remoteRowRef,
    lastSyncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('merchant_name')) {
      context.handle(
        _merchantNameMeta,
        merchantName.isAcceptableOrUnknown(
          data['merchant_name']!,
          _merchantNameMeta,
        ),
      );
    }
    if (data.containsKey('upi_id')) {
      context.handle(
        _upiIdMeta,
        upiId.isAcceptableOrUnknown(data['upi_id']!, _upiIdMeta),
      );
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    }
    if (data.containsKey('account_hint')) {
      context.handle(
        _accountHintMeta,
        accountHint.isAcceptableOrUnknown(
          data['account_hint']!,
          _accountHintMeta,
        ),
      );
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    }
    if (data.containsKey('merged_sources')) {
      context.handle(
        _mergedSourcesMeta,
        mergedSources.isAcceptableOrUnknown(
          data['merged_sources']!,
          _mergedSourcesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mergedSourcesMeta);
    }
    if (data.containsKey('source_app')) {
      context.handle(
        _sourceAppMeta,
        sourceApp.isAcceptableOrUnknown(data['source_app']!, _sourceAppMeta),
      );
    }
    if (data.containsKey('source_address')) {
      context.handle(
        _sourceAddressMeta,
        sourceAddress.isAcceptableOrUnknown(
          data['source_address']!,
          _sourceAddressMeta,
        ),
      );
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('remote_row_ref')) {
      context.handle(
        _remoteRowRefMeta,
        remoteRowRef.isAcceptableOrUnknown(
          data['remote_row_ref']!,
          _remoteRowRefMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      type: $TransactionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      merchantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_name'],
      ),
      upiId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upi_id'],
      ),
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      ),
      accountHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_hint'],
      ),
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      ),
      mergedSources: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merged_sources'],
      )!,
      sourceApp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_app'],
      ),
      sourceAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_address'],
      ),
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $TransactionsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      remoteRowRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_row_ref'],
      ),
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionType, String, String> $convertertype =
      const EnumNameConverter<TransactionType>(TransactionType.values);
  static JsonTypeConverter2<TransactionSyncStatus, String, String>
  $convertersyncStatus = const EnumNameConverter<TransactionSyncStatus>(
    TransactionSyncStatus.values,
  );
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;
  final int amountPaise;
  final TransactionType type;
  final DateTime occurredAt;
  final DateTime receivedAt;
  final String? merchantName;
  final String? upiId;
  final String? bankName;
  final String? accountHint;
  final String? referenceId;

  /// Comma-separated SourceType names, e.g. "sms,notification".
  final String mergedSources;
  final String? sourceApp;
  final String? sourceAddress;
  final String rawText;
  final String? category;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TransactionSyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final String? remoteRowRef;
  final String? lastSyncError;
  const TransactionRow({
    required this.id,
    required this.amountPaise,
    required this.type,
    required this.occurredAt,
    required this.receivedAt,
    this.merchantName,
    this.upiId,
    this.bankName,
    this.accountHint,
    this.referenceId,
    required this.mergedSources,
    this.sourceApp,
    this.sourceAddress,
    required this.rawText,
    this.category,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncedAt,
    this.remoteRowRef,
    this.lastSyncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount_paise'] = Variable<int>(amountPaise);
    {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type),
      );
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['received_at'] = Variable<DateTime>(receivedAt);
    if (!nullToAbsent || merchantName != null) {
      map['merchant_name'] = Variable<String>(merchantName);
    }
    if (!nullToAbsent || upiId != null) {
      map['upi_id'] = Variable<String>(upiId);
    }
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    if (!nullToAbsent || accountHint != null) {
      map['account_hint'] = Variable<String>(accountHint);
    }
    if (!nullToAbsent || referenceId != null) {
      map['reference_id'] = Variable<String>(referenceId);
    }
    map['merged_sources'] = Variable<String>(mergedSources);
    if (!nullToAbsent || sourceApp != null) {
      map['source_app'] = Variable<String>(sourceApp);
    }
    if (!nullToAbsent || sourceAddress != null) {
      map['source_address'] = Variable<String>(sourceAddress);
    }
    map['raw_text'] = Variable<String>(rawText);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $TransactionsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || remoteRowRef != null) {
      map['remote_row_ref'] = Variable<String>(remoteRowRef);
    }
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      amountPaise: Value(amountPaise),
      type: Value(type),
      occurredAt: Value(occurredAt),
      receivedAt: Value(receivedAt),
      merchantName: merchantName == null && nullToAbsent
          ? const Value.absent()
          : Value(merchantName),
      upiId: upiId == null && nullToAbsent
          ? const Value.absent()
          : Value(upiId),
      bankName: bankName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankName),
      accountHint: accountHint == null && nullToAbsent
          ? const Value.absent()
          : Value(accountHint),
      referenceId: referenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceId),
      mergedSources: Value(mergedSources),
      sourceApp: sourceApp == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceApp),
      sourceAddress: sourceAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceAddress),
      rawText: Value(rawText),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      remoteRowRef: remoteRowRef == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteRowRef),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      type: $TransactionsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      merchantName: serializer.fromJson<String?>(json['merchantName']),
      upiId: serializer.fromJson<String?>(json['upiId']),
      bankName: serializer.fromJson<String?>(json['bankName']),
      accountHint: serializer.fromJson<String?>(json['accountHint']),
      referenceId: serializer.fromJson<String?>(json['referenceId']),
      mergedSources: serializer.fromJson<String>(json['mergedSources']),
      sourceApp: serializer.fromJson<String?>(json['sourceApp']),
      sourceAddress: serializer.fromJson<String?>(json['sourceAddress']),
      rawText: serializer.fromJson<String>(json['rawText']),
      category: serializer.fromJson<String?>(json['category']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: $TransactionsTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      remoteRowRef: serializer.fromJson<String?>(json['remoteRowRef']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'type': serializer.toJson<String>(
        $TransactionsTable.$convertertype.toJson(type),
      ),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'merchantName': serializer.toJson<String?>(merchantName),
      'upiId': serializer.toJson<String?>(upiId),
      'bankName': serializer.toJson<String?>(bankName),
      'accountHint': serializer.toJson<String?>(accountHint),
      'referenceId': serializer.toJson<String?>(referenceId),
      'mergedSources': serializer.toJson<String>(mergedSources),
      'sourceApp': serializer.toJson<String?>(sourceApp),
      'sourceAddress': serializer.toJson<String?>(sourceAddress),
      'rawText': serializer.toJson<String>(rawText),
      'category': serializer.toJson<String?>(category),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<String>(
        $TransactionsTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'remoteRowRef': serializer.toJson<String?>(remoteRowRef),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
    };
  }

  TransactionRow copyWith({
    int? id,
    int? amountPaise,
    TransactionType? type,
    DateTime? occurredAt,
    DateTime? receivedAt,
    Value<String?> merchantName = const Value.absent(),
    Value<String?> upiId = const Value.absent(),
    Value<String?> bankName = const Value.absent(),
    Value<String?> accountHint = const Value.absent(),
    Value<String?> referenceId = const Value.absent(),
    String? mergedSources,
    Value<String?> sourceApp = const Value.absent(),
    Value<String?> sourceAddress = const Value.absent(),
    String? rawText,
    Value<String?> category = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    TransactionSyncStatus? syncStatus,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> remoteRowRef = const Value.absent(),
    Value<String?> lastSyncError = const Value.absent(),
  }) => TransactionRow(
    id: id ?? this.id,
    amountPaise: amountPaise ?? this.amountPaise,
    type: type ?? this.type,
    occurredAt: occurredAt ?? this.occurredAt,
    receivedAt: receivedAt ?? this.receivedAt,
    merchantName: merchantName.present ? merchantName.value : this.merchantName,
    upiId: upiId.present ? upiId.value : this.upiId,
    bankName: bankName.present ? bankName.value : this.bankName,
    accountHint: accountHint.present ? accountHint.value : this.accountHint,
    referenceId: referenceId.present ? referenceId.value : this.referenceId,
    mergedSources: mergedSources ?? this.mergedSources,
    sourceApp: sourceApp.present ? sourceApp.value : this.sourceApp,
    sourceAddress: sourceAddress.present
        ? sourceAddress.value
        : this.sourceAddress,
    rawText: rawText ?? this.rawText,
    category: category.present ? category.value : this.category,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    remoteRowRef: remoteRowRef.present ? remoteRowRef.value : this.remoteRowRef,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      type: data.type.present ? data.type.value : this.type,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      merchantName: data.merchantName.present
          ? data.merchantName.value
          : this.merchantName,
      upiId: data.upiId.present ? data.upiId.value : this.upiId,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      accountHint: data.accountHint.present
          ? data.accountHint.value
          : this.accountHint,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      mergedSources: data.mergedSources.present
          ? data.mergedSources.value
          : this.mergedSources,
      sourceApp: data.sourceApp.present ? data.sourceApp.value : this.sourceApp,
      sourceAddress: data.sourceAddress.present
          ? data.sourceAddress.value
          : this.sourceAddress,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      category: data.category.present ? data.category.value : this.category,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      remoteRowRef: data.remoteRowRef.present
          ? data.remoteRowRef.value
          : this.remoteRowRef,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('merchantName: $merchantName, ')
          ..write('upiId: $upiId, ')
          ..write('bankName: $bankName, ')
          ..write('accountHint: $accountHint, ')
          ..write('referenceId: $referenceId, ')
          ..write('mergedSources: $mergedSources, ')
          ..write('sourceApp: $sourceApp, ')
          ..write('sourceAddress: $sourceAddress, ')
          ..write('rawText: $rawText, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('remoteRowRef: $remoteRowRef, ')
          ..write('lastSyncError: $lastSyncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    amountPaise,
    type,
    occurredAt,
    receivedAt,
    merchantName,
    upiId,
    bankName,
    accountHint,
    referenceId,
    mergedSources,
    sourceApp,
    sourceAddress,
    rawText,
    category,
    note,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncedAt,
    remoteRowRef,
    lastSyncError,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.amountPaise == this.amountPaise &&
          other.type == this.type &&
          other.occurredAt == this.occurredAt &&
          other.receivedAt == this.receivedAt &&
          other.merchantName == this.merchantName &&
          other.upiId == this.upiId &&
          other.bankName == this.bankName &&
          other.accountHint == this.accountHint &&
          other.referenceId == this.referenceId &&
          other.mergedSources == this.mergedSources &&
          other.sourceApp == this.sourceApp &&
          other.sourceAddress == this.sourceAddress &&
          other.rawText == this.rawText &&
          other.category == this.category &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.remoteRowRef == this.remoteRowRef &&
          other.lastSyncError == this.lastSyncError);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<int> amountPaise;
  final Value<TransactionType> type;
  final Value<DateTime> occurredAt;
  final Value<DateTime> receivedAt;
  final Value<String?> merchantName;
  final Value<String?> upiId;
  final Value<String?> bankName;
  final Value<String?> accountHint;
  final Value<String?> referenceId;
  final Value<String> mergedSources;
  final Value<String?> sourceApp;
  final Value<String?> sourceAddress;
  final Value<String> rawText;
  final Value<String?> category;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<TransactionSyncStatus> syncStatus;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> remoteRowRef;
  final Value<String?> lastSyncError;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.type = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.merchantName = const Value.absent(),
    this.upiId = const Value.absent(),
    this.bankName = const Value.absent(),
    this.accountHint = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.mergedSources = const Value.absent(),
    this.sourceApp = const Value.absent(),
    this.sourceAddress = const Value.absent(),
    this.rawText = const Value.absent(),
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.remoteRowRef = const Value.absent(),
    this.lastSyncError = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int amountPaise,
    required TransactionType type,
    required DateTime occurredAt,
    required DateTime receivedAt,
    this.merchantName = const Value.absent(),
    this.upiId = const Value.absent(),
    this.bankName = const Value.absent(),
    this.accountHint = const Value.absent(),
    this.referenceId = const Value.absent(),
    required String mergedSources,
    this.sourceApp = const Value.absent(),
    this.sourceAddress = const Value.absent(),
    required String rawText,
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required TransactionSyncStatus syncStatus,
    this.lastSyncedAt = const Value.absent(),
    this.remoteRowRef = const Value.absent(),
    this.lastSyncError = const Value.absent(),
  }) : amountPaise = Value(amountPaise),
       type = Value(type),
       occurredAt = Value(occurredAt),
       receivedAt = Value(receivedAt),
       mergedSources = Value(mergedSources),
       rawText = Value(rawText),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<int>? amountPaise,
    Expression<String>? type,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? receivedAt,
    Expression<String>? merchantName,
    Expression<String>? upiId,
    Expression<String>? bankName,
    Expression<String>? accountHint,
    Expression<String>? referenceId,
    Expression<String>? mergedSources,
    Expression<String>? sourceApp,
    Expression<String>? sourceAddress,
    Expression<String>? rawText,
    Expression<String>? category,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? remoteRowRef,
    Expression<String>? lastSyncError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (type != null) 'type': type,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (receivedAt != null) 'received_at': receivedAt,
      if (merchantName != null) 'merchant_name': merchantName,
      if (upiId != null) 'upi_id': upiId,
      if (bankName != null) 'bank_name': bankName,
      if (accountHint != null) 'account_hint': accountHint,
      if (referenceId != null) 'reference_id': referenceId,
      if (mergedSources != null) 'merged_sources': mergedSources,
      if (sourceApp != null) 'source_app': sourceApp,
      if (sourceAddress != null) 'source_address': sourceAddress,
      if (rawText != null) 'raw_text': rawText,
      if (category != null) 'category': category,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (remoteRowRef != null) 'remote_row_ref': remoteRowRef,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? amountPaise,
    Value<TransactionType>? type,
    Value<DateTime>? occurredAt,
    Value<DateTime>? receivedAt,
    Value<String?>? merchantName,
    Value<String?>? upiId,
    Value<String?>? bankName,
    Value<String?>? accountHint,
    Value<String?>? referenceId,
    Value<String>? mergedSources,
    Value<String?>? sourceApp,
    Value<String?>? sourceAddress,
    Value<String>? rawText,
    Value<String?>? category,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<TransactionSyncStatus>? syncStatus,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? remoteRowRef,
    Value<String?>? lastSyncError,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      amountPaise: amountPaise ?? this.amountPaise,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      receivedAt: receivedAt ?? this.receivedAt,
      merchantName: merchantName ?? this.merchantName,
      upiId: upiId ?? this.upiId,
      bankName: bankName ?? this.bankName,
      accountHint: accountHint ?? this.accountHint,
      referenceId: referenceId ?? this.referenceId,
      mergedSources: mergedSources ?? this.mergedSources,
      sourceApp: sourceApp ?? this.sourceApp,
      sourceAddress: sourceAddress ?? this.sourceAddress,
      rawText: rawText ?? this.rawText,
      category: category ?? this.category,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      remoteRowRef: remoteRowRef ?? this.remoteRowRef,
      lastSyncError: lastSyncError ?? this.lastSyncError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type.value),
      );
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (merchantName.present) {
      map['merchant_name'] = Variable<String>(merchantName.value);
    }
    if (upiId.present) {
      map['upi_id'] = Variable<String>(upiId.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (accountHint.present) {
      map['account_hint'] = Variable<String>(accountHint.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (mergedSources.present) {
      map['merged_sources'] = Variable<String>(mergedSources.value);
    }
    if (sourceApp.present) {
      map['source_app'] = Variable<String>(sourceApp.value);
    }
    if (sourceAddress.present) {
      map['source_address'] = Variable<String>(sourceAddress.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $TransactionsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (remoteRowRef.present) {
      map['remote_row_ref'] = Variable<String>(remoteRowRef.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('merchantName: $merchantName, ')
          ..write('upiId: $upiId, ')
          ..write('bankName: $bankName, ')
          ..write('accountHint: $accountHint, ')
          ..write('referenceId: $referenceId, ')
          ..write('mergedSources: $mergedSources, ')
          ..write('sourceApp: $sourceApp, ')
          ..write('sourceAddress: $sourceAddress, ')
          ..write('rawText: $rawText, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('remoteRowRef: $remoteRowRef, ')
          ..write('lastSyncError: $lastSyncError')
          ..write(')'))
        .toString();
  }
}

class $RawCapturesTable extends RawCaptures
    with TableInfo<$RawCapturesTable, CaptureRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawCapturesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SourceType, String> sourceType =
      GeneratedColumn<String>(
        'source_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SourceType>($RawCapturesTable.$convertersourceType);
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _text_Meta = const VerificationMeta('text_');
  @override
  late final GeneratedColumn<String> text_ = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    at,
    sourceType,
    origin,
    text_,
    result,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_captures';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaptureRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('text')) {
      context.handle(
        _text_Meta,
        text_.isAcceptableOrUnknown(data['text']!, _text_Meta),
      );
    } else if (isInserting) {
      context.missing(_text_Meta);
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CaptureRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaptureRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      sourceType: $RawCapturesTable.$convertersourceType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source_type'],
        )!,
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      ),
      text_: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      result: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result'],
      )!,
    );
  }

  @override
  $RawCapturesTable createAlias(String alias) {
    return $RawCapturesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SourceType, String, String> $convertersourceType =
      const EnumNameConverter<SourceType>(SourceType.values);
}

class CaptureRow extends DataClass implements Insertable<CaptureRow> {
  final int id;
  final DateTime at;
  final SourceType sourceType;
  final String? origin;
  final String text_;
  final String result;
  const CaptureRow({
    required this.id,
    required this.at,
    required this.sourceType,
    this.origin,
    required this.text_,
    required this.result,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    {
      map['source_type'] = Variable<String>(
        $RawCapturesTable.$convertersourceType.toSql(sourceType),
      );
    }
    if (!nullToAbsent || origin != null) {
      map['origin'] = Variable<String>(origin);
    }
    map['text'] = Variable<String>(text_);
    map['result'] = Variable<String>(result);
    return map;
  }

  RawCapturesCompanion toCompanion(bool nullToAbsent) {
    return RawCapturesCompanion(
      id: Value(id),
      at: Value(at),
      sourceType: Value(sourceType),
      origin: origin == null && nullToAbsent
          ? const Value.absent()
          : Value(origin),
      text_: Value(text_),
      result: Value(result),
    );
  }

  factory CaptureRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaptureRow(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      sourceType: $RawCapturesTable.$convertersourceType.fromJson(
        serializer.fromJson<String>(json['sourceType']),
      ),
      origin: serializer.fromJson<String?>(json['origin']),
      text_: serializer.fromJson<String>(json['text_']),
      result: serializer.fromJson<String>(json['result']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'sourceType': serializer.toJson<String>(
        $RawCapturesTable.$convertersourceType.toJson(sourceType),
      ),
      'origin': serializer.toJson<String?>(origin),
      'text_': serializer.toJson<String>(text_),
      'result': serializer.toJson<String>(result),
    };
  }

  CaptureRow copyWith({
    int? id,
    DateTime? at,
    SourceType? sourceType,
    Value<String?> origin = const Value.absent(),
    String? text_,
    String? result,
  }) => CaptureRow(
    id: id ?? this.id,
    at: at ?? this.at,
    sourceType: sourceType ?? this.sourceType,
    origin: origin.present ? origin.value : this.origin,
    text_: text_ ?? this.text_,
    result: result ?? this.result,
  );
  CaptureRow copyWithCompanion(RawCapturesCompanion data) {
    return CaptureRow(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      origin: data.origin.present ? data.origin.value : this.origin,
      text_: data.text_.present ? data.text_.value : this.text_,
      result: data.result.present ? data.result.value : this.result,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaptureRow(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('sourceType: $sourceType, ')
          ..write('origin: $origin, ')
          ..write('text_: $text_, ')
          ..write('result: $result')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, sourceType, origin, text_, result);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaptureRow &&
          other.id == this.id &&
          other.at == this.at &&
          other.sourceType == this.sourceType &&
          other.origin == this.origin &&
          other.text_ == this.text_ &&
          other.result == this.result);
}

class RawCapturesCompanion extends UpdateCompanion<CaptureRow> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<SourceType> sourceType;
  final Value<String?> origin;
  final Value<String> text_;
  final Value<String> result;
  const RawCapturesCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.origin = const Value.absent(),
    this.text_ = const Value.absent(),
    this.result = const Value.absent(),
  });
  RawCapturesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required SourceType sourceType,
    this.origin = const Value.absent(),
    required String text_,
    required String result,
  }) : at = Value(at),
       sourceType = Value(sourceType),
       text_ = Value(text_),
       result = Value(result);
  static Insertable<CaptureRow> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? sourceType,
    Expression<String>? origin,
    Expression<String>? text_,
    Expression<String>? result,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (sourceType != null) 'source_type': sourceType,
      if (origin != null) 'origin': origin,
      if (text_ != null) 'text': text_,
      if (result != null) 'result': result,
    });
  }

  RawCapturesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<SourceType>? sourceType,
    Value<String?>? origin,
    Value<String>? text_,
    Value<String>? result,
  }) {
    return RawCapturesCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      sourceType: sourceType ?? this.sourceType,
      origin: origin ?? this.origin,
      text_: text_ ?? this.text_,
      result: result ?? this.result,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(
        $RawCapturesTable.$convertersourceType.toSql(sourceType.value),
      );
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (text_.present) {
      map['text'] = Variable<String>(text_.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RawCapturesCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('sourceType: $sourceType, ')
          ..write('origin: $origin, ')
          ..write('text_: $text_, ')
          ..write('result: $result')
          ..write(')'))
        .toString();
  }
}

class $SyncSettingsTableTable extends SyncSettingsTable
    with TableInfo<$SyncSettingsTableTable, SyncSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncPreference, String>
  syncPreference =
      GeneratedColumn<String>(
        'sync_preference',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncPreference>(
        $SyncSettingsTableTable.$convertersyncPreference,
      );
  @override
  late final GeneratedColumnWithTypeConverter<GoogleConnectionState, String>
  connectionState =
      GeneratedColumn<String>(
        'connection_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<GoogleConnectionState>(
        $SyncSettingsTableTable.$converterconnectionState,
      );
  static const VerificationMeta _googleAccountEmailMeta =
      const VerificationMeta('googleAccountEmail');
  @override
  late final GeneratedColumn<String> googleAccountEmail =
      GeneratedColumn<String>(
        'google_account_email',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _spreadsheetIdMeta = const VerificationMeta(
    'spreadsheetId',
  );
  @override
  late final GeneratedColumn<String> spreadsheetId = GeneratedColumn<String>(
    'spreadsheet_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spreadsheetNameMeta = const VerificationMeta(
    'spreadsheetName',
  );
  @override
  late final GeneratedColumn<String> spreadsheetName = GeneratedColumn<String>(
    'spreadsheet_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoSyncEnabledMeta = const VerificationMeta(
    'autoSyncEnabled',
  );
  @override
  late final GeneratedColumn<bool> autoSyncEnabled = GeneratedColumn<bool>(
    'auto_sync_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_sync_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lastSuccessfulSyncAtMeta =
      const VerificationMeta('lastSuccessfulSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessfulSyncAt =
      GeneratedColumn<DateTime>(
        'last_successful_sync_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<SyncRunState, String>
  lastSyncRunState =
      GeneratedColumn<String>(
        'last_sync_run_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncRunState>(
        $SyncSettingsTableTable.$converterlastSyncRunState,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncPreference,
    connectionState,
    googleAccountEmail,
    spreadsheetId,
    spreadsheetName,
    autoSyncEnabled,
    lastSuccessfulSyncAt,
    lastSyncRunState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('google_account_email')) {
      context.handle(
        _googleAccountEmailMeta,
        googleAccountEmail.isAcceptableOrUnknown(
          data['google_account_email']!,
          _googleAccountEmailMeta,
        ),
      );
    }
    if (data.containsKey('spreadsheet_id')) {
      context.handle(
        _spreadsheetIdMeta,
        spreadsheetId.isAcceptableOrUnknown(
          data['spreadsheet_id']!,
          _spreadsheetIdMeta,
        ),
      );
    }
    if (data.containsKey('spreadsheet_name')) {
      context.handle(
        _spreadsheetNameMeta,
        spreadsheetName.isAcceptableOrUnknown(
          data['spreadsheet_name']!,
          _spreadsheetNameMeta,
        ),
      );
    }
    if (data.containsKey('auto_sync_enabled')) {
      context.handle(
        _autoSyncEnabledMeta,
        autoSyncEnabled.isAcceptableOrUnknown(
          data['auto_sync_enabled']!,
          _autoSyncEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_autoSyncEnabledMeta);
    }
    if (data.containsKey('last_successful_sync_at')) {
      context.handle(
        _lastSuccessfulSyncAtMeta,
        lastSuccessfulSyncAt.isAcceptableOrUnknown(
          data['last_successful_sync_at']!,
          _lastSuccessfulSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      syncPreference: $SyncSettingsTableTable.$convertersyncPreference.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_preference'],
        )!,
      ),
      connectionState: $SyncSettingsTableTable.$converterconnectionState
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}connection_state'],
            )!,
          ),
      googleAccountEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_account_email'],
      ),
      spreadsheetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spreadsheet_id'],
      ),
      spreadsheetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spreadsheet_name'],
      ),
      autoSyncEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_sync_enabled'],
      )!,
      lastSuccessfulSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_successful_sync_at'],
      ),
      lastSyncRunState: $SyncSettingsTableTable.$converterlastSyncRunState
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}last_sync_run_state'],
            )!,
          ),
    );
  }

  @override
  $SyncSettingsTableTable createAlias(String alias) {
    return $SyncSettingsTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncPreference, String, String>
  $convertersyncPreference = const EnumNameConverter<SyncPreference>(
    SyncPreference.values,
  );
  static JsonTypeConverter2<GoogleConnectionState, String, String>
  $converterconnectionState = const EnumNameConverter<GoogleConnectionState>(
    GoogleConnectionState.values,
  );
  static JsonTypeConverter2<SyncRunState, String, String>
  $converterlastSyncRunState = const EnumNameConverter<SyncRunState>(
    SyncRunState.values,
  );
}

class SyncSettingsRow extends DataClass implements Insertable<SyncSettingsRow> {
  final int id;
  final SyncPreference syncPreference;
  final GoogleConnectionState connectionState;
  final String? googleAccountEmail;
  final String? spreadsheetId;
  final String? spreadsheetName;
  final bool autoSyncEnabled;
  final DateTime? lastSuccessfulSyncAt;
  final SyncRunState lastSyncRunState;
  const SyncSettingsRow({
    required this.id,
    required this.syncPreference,
    required this.connectionState,
    this.googleAccountEmail,
    this.spreadsheetId,
    this.spreadsheetName,
    required this.autoSyncEnabled,
    this.lastSuccessfulSyncAt,
    required this.lastSyncRunState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['sync_preference'] = Variable<String>(
        $SyncSettingsTableTable.$convertersyncPreference.toSql(syncPreference),
      );
    }
    {
      map['connection_state'] = Variable<String>(
        $SyncSettingsTableTable.$converterconnectionState.toSql(
          connectionState,
        ),
      );
    }
    if (!nullToAbsent || googleAccountEmail != null) {
      map['google_account_email'] = Variable<String>(googleAccountEmail);
    }
    if (!nullToAbsent || spreadsheetId != null) {
      map['spreadsheet_id'] = Variable<String>(spreadsheetId);
    }
    if (!nullToAbsent || spreadsheetName != null) {
      map['spreadsheet_name'] = Variable<String>(spreadsheetName);
    }
    map['auto_sync_enabled'] = Variable<bool>(autoSyncEnabled);
    if (!nullToAbsent || lastSuccessfulSyncAt != null) {
      map['last_successful_sync_at'] = Variable<DateTime>(lastSuccessfulSyncAt);
    }
    {
      map['last_sync_run_state'] = Variable<String>(
        $SyncSettingsTableTable.$converterlastSyncRunState.toSql(
          lastSyncRunState,
        ),
      );
    }
    return map;
  }

  SyncSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SyncSettingsTableCompanion(
      id: Value(id),
      syncPreference: Value(syncPreference),
      connectionState: Value(connectionState),
      googleAccountEmail: googleAccountEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(googleAccountEmail),
      spreadsheetId: spreadsheetId == null && nullToAbsent
          ? const Value.absent()
          : Value(spreadsheetId),
      spreadsheetName: spreadsheetName == null && nullToAbsent
          ? const Value.absent()
          : Value(spreadsheetName),
      autoSyncEnabled: Value(autoSyncEnabled),
      lastSuccessfulSyncAt: lastSuccessfulSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessfulSyncAt),
      lastSyncRunState: Value(lastSyncRunState),
    );
  }

  factory SyncSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      syncPreference: $SyncSettingsTableTable.$convertersyncPreference.fromJson(
        serializer.fromJson<String>(json['syncPreference']),
      ),
      connectionState: $SyncSettingsTableTable.$converterconnectionState
          .fromJson(serializer.fromJson<String>(json['connectionState'])),
      googleAccountEmail: serializer.fromJson<String?>(
        json['googleAccountEmail'],
      ),
      spreadsheetId: serializer.fromJson<String?>(json['spreadsheetId']),
      spreadsheetName: serializer.fromJson<String?>(json['spreadsheetName']),
      autoSyncEnabled: serializer.fromJson<bool>(json['autoSyncEnabled']),
      lastSuccessfulSyncAt: serializer.fromJson<DateTime?>(
        json['lastSuccessfulSyncAt'],
      ),
      lastSyncRunState: $SyncSettingsTableTable.$converterlastSyncRunState
          .fromJson(serializer.fromJson<String>(json['lastSyncRunState'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncPreference': serializer.toJson<String>(
        $SyncSettingsTableTable.$convertersyncPreference.toJson(syncPreference),
      ),
      'connectionState': serializer.toJson<String>(
        $SyncSettingsTableTable.$converterconnectionState.toJson(
          connectionState,
        ),
      ),
      'googleAccountEmail': serializer.toJson<String?>(googleAccountEmail),
      'spreadsheetId': serializer.toJson<String?>(spreadsheetId),
      'spreadsheetName': serializer.toJson<String?>(spreadsheetName),
      'autoSyncEnabled': serializer.toJson<bool>(autoSyncEnabled),
      'lastSuccessfulSyncAt': serializer.toJson<DateTime?>(
        lastSuccessfulSyncAt,
      ),
      'lastSyncRunState': serializer.toJson<String>(
        $SyncSettingsTableTable.$converterlastSyncRunState.toJson(
          lastSyncRunState,
        ),
      ),
    };
  }

  SyncSettingsRow copyWith({
    int? id,
    SyncPreference? syncPreference,
    GoogleConnectionState? connectionState,
    Value<String?> googleAccountEmail = const Value.absent(),
    Value<String?> spreadsheetId = const Value.absent(),
    Value<String?> spreadsheetName = const Value.absent(),
    bool? autoSyncEnabled,
    Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
    SyncRunState? lastSyncRunState,
  }) => SyncSettingsRow(
    id: id ?? this.id,
    syncPreference: syncPreference ?? this.syncPreference,
    connectionState: connectionState ?? this.connectionState,
    googleAccountEmail: googleAccountEmail.present
        ? googleAccountEmail.value
        : this.googleAccountEmail,
    spreadsheetId: spreadsheetId.present
        ? spreadsheetId.value
        : this.spreadsheetId,
    spreadsheetName: spreadsheetName.present
        ? spreadsheetName.value
        : this.spreadsheetName,
    autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
    lastSuccessfulSyncAt: lastSuccessfulSyncAt.present
        ? lastSuccessfulSyncAt.value
        : this.lastSuccessfulSyncAt,
    lastSyncRunState: lastSyncRunState ?? this.lastSyncRunState,
  );
  SyncSettingsRow copyWithCompanion(SyncSettingsTableCompanion data) {
    return SyncSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      syncPreference: data.syncPreference.present
          ? data.syncPreference.value
          : this.syncPreference,
      connectionState: data.connectionState.present
          ? data.connectionState.value
          : this.connectionState,
      googleAccountEmail: data.googleAccountEmail.present
          ? data.googleAccountEmail.value
          : this.googleAccountEmail,
      spreadsheetId: data.spreadsheetId.present
          ? data.spreadsheetId.value
          : this.spreadsheetId,
      spreadsheetName: data.spreadsheetName.present
          ? data.spreadsheetName.value
          : this.spreadsheetName,
      autoSyncEnabled: data.autoSyncEnabled.present
          ? data.autoSyncEnabled.value
          : this.autoSyncEnabled,
      lastSuccessfulSyncAt: data.lastSuccessfulSyncAt.present
          ? data.lastSuccessfulSyncAt.value
          : this.lastSuccessfulSyncAt,
      lastSyncRunState: data.lastSyncRunState.present
          ? data.lastSyncRunState.value
          : this.lastSyncRunState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncSettingsRow(')
          ..write('id: $id, ')
          ..write('syncPreference: $syncPreference, ')
          ..write('connectionState: $connectionState, ')
          ..write('googleAccountEmail: $googleAccountEmail, ')
          ..write('spreadsheetId: $spreadsheetId, ')
          ..write('spreadsheetName: $spreadsheetName, ')
          ..write('autoSyncEnabled: $autoSyncEnabled, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('lastSyncRunState: $lastSyncRunState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncPreference,
    connectionState,
    googleAccountEmail,
    spreadsheetId,
    spreadsheetName,
    autoSyncEnabled,
    lastSuccessfulSyncAt,
    lastSyncRunState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncSettingsRow &&
          other.id == this.id &&
          other.syncPreference == this.syncPreference &&
          other.connectionState == this.connectionState &&
          other.googleAccountEmail == this.googleAccountEmail &&
          other.spreadsheetId == this.spreadsheetId &&
          other.spreadsheetName == this.spreadsheetName &&
          other.autoSyncEnabled == this.autoSyncEnabled &&
          other.lastSuccessfulSyncAt == this.lastSuccessfulSyncAt &&
          other.lastSyncRunState == this.lastSyncRunState);
}

class SyncSettingsTableCompanion extends UpdateCompanion<SyncSettingsRow> {
  final Value<int> id;
  final Value<SyncPreference> syncPreference;
  final Value<GoogleConnectionState> connectionState;
  final Value<String?> googleAccountEmail;
  final Value<String?> spreadsheetId;
  final Value<String?> spreadsheetName;
  final Value<bool> autoSyncEnabled;
  final Value<DateTime?> lastSuccessfulSyncAt;
  final Value<SyncRunState> lastSyncRunState;
  const SyncSettingsTableCompanion({
    this.id = const Value.absent(),
    this.syncPreference = const Value.absent(),
    this.connectionState = const Value.absent(),
    this.googleAccountEmail = const Value.absent(),
    this.spreadsheetId = const Value.absent(),
    this.spreadsheetName = const Value.absent(),
    this.autoSyncEnabled = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.lastSyncRunState = const Value.absent(),
  });
  SyncSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required SyncPreference syncPreference,
    required GoogleConnectionState connectionState,
    this.googleAccountEmail = const Value.absent(),
    this.spreadsheetId = const Value.absent(),
    this.spreadsheetName = const Value.absent(),
    required bool autoSyncEnabled,
    this.lastSuccessfulSyncAt = const Value.absent(),
    required SyncRunState lastSyncRunState,
  }) : syncPreference = Value(syncPreference),
       connectionState = Value(connectionState),
       autoSyncEnabled = Value(autoSyncEnabled),
       lastSyncRunState = Value(lastSyncRunState);
  static Insertable<SyncSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? syncPreference,
    Expression<String>? connectionState,
    Expression<String>? googleAccountEmail,
    Expression<String>? spreadsheetId,
    Expression<String>? spreadsheetName,
    Expression<bool>? autoSyncEnabled,
    Expression<DateTime>? lastSuccessfulSyncAt,
    Expression<String>? lastSyncRunState,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncPreference != null) 'sync_preference': syncPreference,
      if (connectionState != null) 'connection_state': connectionState,
      if (googleAccountEmail != null)
        'google_account_email': googleAccountEmail,
      if (spreadsheetId != null) 'spreadsheet_id': spreadsheetId,
      if (spreadsheetName != null) 'spreadsheet_name': spreadsheetName,
      if (autoSyncEnabled != null) 'auto_sync_enabled': autoSyncEnabled,
      if (lastSuccessfulSyncAt != null)
        'last_successful_sync_at': lastSuccessfulSyncAt,
      if (lastSyncRunState != null) 'last_sync_run_state': lastSyncRunState,
    });
  }

  SyncSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<SyncPreference>? syncPreference,
    Value<GoogleConnectionState>? connectionState,
    Value<String?>? googleAccountEmail,
    Value<String?>? spreadsheetId,
    Value<String?>? spreadsheetName,
    Value<bool>? autoSyncEnabled,
    Value<DateTime?>? lastSuccessfulSyncAt,
    Value<SyncRunState>? lastSyncRunState,
  }) {
    return SyncSettingsTableCompanion(
      id: id ?? this.id,
      syncPreference: syncPreference ?? this.syncPreference,
      connectionState: connectionState ?? this.connectionState,
      googleAccountEmail: googleAccountEmail ?? this.googleAccountEmail,
      spreadsheetId: spreadsheetId ?? this.spreadsheetId,
      spreadsheetName: spreadsheetName ?? this.spreadsheetName,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      lastSyncRunState: lastSyncRunState ?? this.lastSyncRunState,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (syncPreference.present) {
      map['sync_preference'] = Variable<String>(
        $SyncSettingsTableTable.$convertersyncPreference.toSql(
          syncPreference.value,
        ),
      );
    }
    if (connectionState.present) {
      map['connection_state'] = Variable<String>(
        $SyncSettingsTableTable.$converterconnectionState.toSql(
          connectionState.value,
        ),
      );
    }
    if (googleAccountEmail.present) {
      map['google_account_email'] = Variable<String>(googleAccountEmail.value);
    }
    if (spreadsheetId.present) {
      map['spreadsheet_id'] = Variable<String>(spreadsheetId.value);
    }
    if (spreadsheetName.present) {
      map['spreadsheet_name'] = Variable<String>(spreadsheetName.value);
    }
    if (autoSyncEnabled.present) {
      map['auto_sync_enabled'] = Variable<bool>(autoSyncEnabled.value);
    }
    if (lastSuccessfulSyncAt.present) {
      map['last_successful_sync_at'] = Variable<DateTime>(
        lastSuccessfulSyncAt.value,
      );
    }
    if (lastSyncRunState.present) {
      map['last_sync_run_state'] = Variable<String>(
        $SyncSettingsTableTable.$converterlastSyncRunState.toSql(
          lastSyncRunState.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('syncPreference: $syncPreference, ')
          ..write('connectionState: $connectionState, ')
          ..write('googleAccountEmail: $googleAccountEmail, ')
          ..write('spreadsheetId: $spreadsheetId, ')
          ..write('spreadsheetName: $spreadsheetName, ')
          ..write('autoSyncEnabled: $autoSyncEnabled, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('lastSyncRunState: $lastSyncRunState')
          ..write(')'))
        .toString();
  }
}

class $ExpenseCategoriesTable extends ExpenseCategories
    with TableInfo<$ExpenseCategoriesTable, ExpenseCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseCategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
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
    name,
    normalizedName,
    isDefault,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {normalizedName},
  ];
  @override
  ExpenseCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExpenseCategoriesTable createAlias(String alias) {
    return $ExpenseCategoriesTable(attachedDatabase, alias);
  }
}

class ExpenseCategoryRow extends DataClass
    implements Insertable<ExpenseCategoryRow> {
  final int id;
  final String name;
  final String normalizedName;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExpenseCategoryRow({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExpenseCategoriesCompanion toCompanion(bool nullToAbsent) {
    return ExpenseCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExpenseCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseCategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExpenseCategoryRow copyWith({
    int? id,
    String? name,
    String? normalizedName,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExpenseCategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExpenseCategoryRow copyWithCompanion(ExpenseCategoriesCompanion data) {
    return ExpenseCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseCategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, normalizedName, isDefault, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseCategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExpenseCategoriesCompanion extends UpdateCompanion<ExpenseCategoryRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ExpenseCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ExpenseCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String normalizedName,
    this.isDefault = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       normalizedName = Value(normalizedName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExpenseCategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ExpenseCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<bool>? isDefault,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ExpenseCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      isDefault: isDefault ?? this.isDefault,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
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
    return (StringBuffer('ExpenseCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CategoryRulesTable extends CategoryRules
    with TableInfo<$CategoryRulesTable, CategoryRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryRulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _merchantKeyMeta = const VerificationMeta(
    'merchantKey',
  );
  @override
  late final GeneratedColumn<String> merchantKey = GeneratedColumn<String>(
    'merchant_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
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
    merchantKey,
    category,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('merchant_key')) {
      context.handle(
        _merchantKeyMeta,
        merchantKey.isAcceptableOrUnknown(
          data['merchant_key']!,
          _merchantKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantKeyMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {merchantKey},
  ];
  @override
  CategoryRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      merchantKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_key'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoryRulesTable createAlias(String alias) {
    return $CategoryRulesTable(attachedDatabase, alias);
  }
}

class CategoryRuleRow extends DataClass implements Insertable<CategoryRuleRow> {
  final int id;
  final String merchantKey;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CategoryRuleRow({
    required this.id,
    required this.merchantKey,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['merchant_key'] = Variable<String>(merchantKey);
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoryRulesCompanion toCompanion(bool nullToAbsent) {
    return CategoryRulesCompanion(
      id: Value(id),
      merchantKey: Value(merchantKey),
      category: Value(category),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRuleRow(
      id: serializer.fromJson<int>(json['id']),
      merchantKey: serializer.fromJson<String>(json['merchantKey']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'merchantKey': serializer.toJson<String>(merchantKey),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CategoryRuleRow copyWith({
    int? id,
    String? merchantKey,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CategoryRuleRow(
    id: id ?? this.id,
    merchantKey: merchantKey ?? this.merchantKey,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoryRuleRow copyWithCompanion(CategoryRulesCompanion data) {
    return CategoryRuleRow(
      id: data.id.present ? data.id.value : this.id,
      merchantKey: data.merchantKey.present
          ? data.merchantKey.value
          : this.merchantKey,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRuleRow(')
          ..write('id: $id, ')
          ..write('merchantKey: $merchantKey, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, merchantKey, category, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRuleRow &&
          other.id == this.id &&
          other.merchantKey == this.merchantKey &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoryRulesCompanion extends UpdateCompanion<CategoryRuleRow> {
  final Value<int> id;
  final Value<String> merchantKey;
  final Value<String> category;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CategoryRulesCompanion({
    this.id = const Value.absent(),
    this.merchantKey = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CategoryRulesCompanion.insert({
    this.id = const Value.absent(),
    required String merchantKey,
    required String category,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : merchantKey = Value(merchantKey),
       category = Value(category),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryRuleRow> custom({
    Expression<int>? id,
    Expression<String>? merchantKey,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (merchantKey != null) 'merchant_key': merchantKey,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CategoryRulesCompanion copyWith({
    Value<int>? id,
    Value<String>? merchantKey,
    Value<String>? category,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CategoryRulesCompanion(
      id: id ?? this.id,
      merchantKey: merchantKey ?? this.merchantKey,
      category: category ?? this.category,
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
    if (merchantKey.present) {
      map['merchant_key'] = Variable<String>(merchantKey.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
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
    return (StringBuffer('CategoryRulesCompanion(')
          ..write('id: $id, ')
          ..write('merchantKey: $merchantKey, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $RawCapturesTable rawCaptures = $RawCapturesTable(this);
  late final $SyncSettingsTableTable syncSettingsTable =
      $SyncSettingsTableTable(this);
  late final $ExpenseCategoriesTable expenseCategories =
      $ExpenseCategoriesTable(this);
  late final $CategoryRulesTable categoryRules = $CategoryRulesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    rawCaptures,
    syncSettingsTable,
    expenseCategories,
    categoryRules,
  ];
}

typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required int amountPaise,
      required TransactionType type,
      required DateTime occurredAt,
      required DateTime receivedAt,
      Value<String?> merchantName,
      Value<String?> upiId,
      Value<String?> bankName,
      Value<String?> accountHint,
      Value<String?> referenceId,
      required String mergedSources,
      Value<String?> sourceApp,
      Value<String?> sourceAddress,
      required String rawText,
      Value<String?> category,
      Value<String?> note,
      required DateTime createdAt,
      required DateTime updatedAt,
      required TransactionSyncStatus syncStatus,
      Value<DateTime?> lastSyncedAt,
      Value<String?> remoteRowRef,
      Value<String?> lastSyncError,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<int> amountPaise,
      Value<TransactionType> type,
      Value<DateTime> occurredAt,
      Value<DateTime> receivedAt,
      Value<String?> merchantName,
      Value<String?> upiId,
      Value<String?> bankName,
      Value<String?> accountHint,
      Value<String?> referenceId,
      Value<String> mergedSources,
      Value<String?> sourceApp,
      Value<String?> sourceAddress,
      Value<String> rawText,
      Value<String?> category,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<TransactionSyncStatus> syncStatus,
      Value<DateTime?> lastSyncedAt,
      Value<String?> remoteRowRef,
      Value<String?> lastSyncError,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
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

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get upiId => $composableBuilder(
    column: $table.upiId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountHint => $composableBuilder(
    column: $table.accountHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mergedSources => $composableBuilder(
    column: $table.mergedSources,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceApp => $composableBuilder(
    column: $table.sourceApp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceAddress => $composableBuilder(
    column: $table.sourceAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
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

  ColumnWithTypeConverterFilters<
    TransactionSyncStatus,
    TransactionSyncStatus,
    String
  >
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteRowRef => $composableBuilder(
    column: $table.remoteRowRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
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

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get upiId => $composableBuilder(
    column: $table.upiId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountHint => $composableBuilder(
    column: $table.accountHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mergedSources => $composableBuilder(
    column: $table.mergedSources,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceApp => $composableBuilder(
    column: $table.sourceApp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceAddress => $composableBuilder(
    column: $table.sourceAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
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

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteRowRef => $composableBuilder(
    column: $table.remoteRowRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TransactionType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get upiId =>
      $composableBuilder(column: $table.upiId, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get accountHint => $composableBuilder(
    column: $table.accountHint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mergedSources => $composableBuilder(
    column: $table.mergedSources,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceApp =>
      $composableBuilder(column: $table.sourceApp, builder: (column) => column);

  GeneratedColumn<String> get sourceAddress => $composableBuilder(
    column: $table.sourceAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionSyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteRowRef => $composableBuilder(
    column: $table.remoteRowRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            TransactionRow,
            BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>,
          ),
          TransactionRow,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<TransactionType> type = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<String?> merchantName = const Value.absent(),
                Value<String?> upiId = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> accountHint = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                Value<String> mergedSources = const Value.absent(),
                Value<String?> sourceApp = const Value.absent(),
                Value<String?> sourceAddress = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<TransactionSyncStatus> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> remoteRowRef = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                amountPaise: amountPaise,
                type: type,
                occurredAt: occurredAt,
                receivedAt: receivedAt,
                merchantName: merchantName,
                upiId: upiId,
                bankName: bankName,
                accountHint: accountHint,
                referenceId: referenceId,
                mergedSources: mergedSources,
                sourceApp: sourceApp,
                sourceAddress: sourceAddress,
                rawText: rawText,
                category: category,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                remoteRowRef: remoteRowRef,
                lastSyncError: lastSyncError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int amountPaise,
                required TransactionType type,
                required DateTime occurredAt,
                required DateTime receivedAt,
                Value<String?> merchantName = const Value.absent(),
                Value<String?> upiId = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> accountHint = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                required String mergedSources,
                Value<String?> sourceApp = const Value.absent(),
                Value<String?> sourceAddress = const Value.absent(),
                required String rawText,
                Value<String?> category = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required TransactionSyncStatus syncStatus,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> remoteRowRef = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                amountPaise: amountPaise,
                type: type,
                occurredAt: occurredAt,
                receivedAt: receivedAt,
                merchantName: merchantName,
                upiId: upiId,
                bankName: bankName,
                accountHint: accountHint,
                referenceId: referenceId,
                mergedSources: mergedSources,
                sourceApp: sourceApp,
                sourceAddress: sourceAddress,
                rawText: rawText,
                category: category,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncedAt: lastSyncedAt,
                remoteRowRef: remoteRowRef,
                lastSyncError: lastSyncError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        TransactionRow,
        BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>,
      ),
      TransactionRow,
      PrefetchHooks Function()
    >;
typedef $$RawCapturesTableCreateCompanionBuilder =
    RawCapturesCompanion Function({
      Value<int> id,
      required DateTime at,
      required SourceType sourceType,
      Value<String?> origin,
      required String text_,
      required String result,
    });
typedef $$RawCapturesTableUpdateCompanionBuilder =
    RawCapturesCompanion Function({
      Value<int> id,
      Value<DateTime> at,
      Value<SourceType> sourceType,
      Value<String?> origin,
      Value<String> text_,
      Value<String> result,
    });

class $$RawCapturesTableFilterComposer
    extends Composer<_$AppDatabase, $RawCapturesTable> {
  $$RawCapturesTableFilterComposer({
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

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SourceType, SourceType, String>
  get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get text_ => $composableBuilder(
    column: $table.text_,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RawCapturesTableOrderingComposer
    extends Composer<_$AppDatabase, $RawCapturesTable> {
  $$RawCapturesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get text_ => $composableBuilder(
    column: $table.text_,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RawCapturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RawCapturesTable> {
  $$RawCapturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SourceType, String> get sourceType =>
      $composableBuilder(
        column: $table.sourceType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get text_ =>
      $composableBuilder(column: $table.text_, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);
}

class $$RawCapturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RawCapturesTable,
          CaptureRow,
          $$RawCapturesTableFilterComposer,
          $$RawCapturesTableOrderingComposer,
          $$RawCapturesTableAnnotationComposer,
          $$RawCapturesTableCreateCompanionBuilder,
          $$RawCapturesTableUpdateCompanionBuilder,
          (
            CaptureRow,
            BaseReferences<_$AppDatabase, $RawCapturesTable, CaptureRow>,
          ),
          CaptureRow,
          PrefetchHooks Function()
        > {
  $$RawCapturesTableTableManager(_$AppDatabase db, $RawCapturesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RawCapturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RawCapturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RawCapturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<SourceType> sourceType = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String> text_ = const Value.absent(),
                Value<String> result = const Value.absent(),
              }) => RawCapturesCompanion(
                id: id,
                at: at,
                sourceType: sourceType,
                origin: origin,
                text_: text_,
                result: result,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required SourceType sourceType,
                Value<String?> origin = const Value.absent(),
                required String text_,
                required String result,
              }) => RawCapturesCompanion.insert(
                id: id,
                at: at,
                sourceType: sourceType,
                origin: origin,
                text_: text_,
                result: result,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RawCapturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RawCapturesTable,
      CaptureRow,
      $$RawCapturesTableFilterComposer,
      $$RawCapturesTableOrderingComposer,
      $$RawCapturesTableAnnotationComposer,
      $$RawCapturesTableCreateCompanionBuilder,
      $$RawCapturesTableUpdateCompanionBuilder,
      (
        CaptureRow,
        BaseReferences<_$AppDatabase, $RawCapturesTable, CaptureRow>,
      ),
      CaptureRow,
      PrefetchHooks Function()
    >;
typedef $$SyncSettingsTableTableCreateCompanionBuilder =
    SyncSettingsTableCompanion Function({
      Value<int> id,
      required SyncPreference syncPreference,
      required GoogleConnectionState connectionState,
      Value<String?> googleAccountEmail,
      Value<String?> spreadsheetId,
      Value<String?> spreadsheetName,
      required bool autoSyncEnabled,
      Value<DateTime?> lastSuccessfulSyncAt,
      required SyncRunState lastSyncRunState,
    });
typedef $$SyncSettingsTableTableUpdateCompanionBuilder =
    SyncSettingsTableCompanion Function({
      Value<int> id,
      Value<SyncPreference> syncPreference,
      Value<GoogleConnectionState> connectionState,
      Value<String?> googleAccountEmail,
      Value<String?> spreadsheetId,
      Value<String?> spreadsheetName,
      Value<bool> autoSyncEnabled,
      Value<DateTime?> lastSuccessfulSyncAt,
      Value<SyncRunState> lastSyncRunState,
    });

class $$SyncSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncSettingsTableTable> {
  $$SyncSettingsTableTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SyncPreference, SyncPreference, String>
  get syncPreference => $composableBuilder(
    column: $table.syncPreference,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    GoogleConnectionState,
    GoogleConnectionState,
    String
  >
  get connectionState => $composableBuilder(
    column: $table.connectionState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get googleAccountEmail => $composableBuilder(
    column: $table.googleAccountEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spreadsheetId => $composableBuilder(
    column: $table.spreadsheetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spreadsheetName => $composableBuilder(
    column: $table.spreadsheetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoSyncEnabled => $composableBuilder(
    column: $table.autoSyncEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncRunState, SyncRunState, String>
  get lastSyncRunState => $composableBuilder(
    column: $table.lastSyncRunState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$SyncSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncSettingsTableTable> {
  $$SyncSettingsTableTableOrderingComposer({
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

  ColumnOrderings<String> get syncPreference => $composableBuilder(
    column: $table.syncPreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get connectionState => $composableBuilder(
    column: $table.connectionState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get googleAccountEmail => $composableBuilder(
    column: $table.googleAccountEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spreadsheetId => $composableBuilder(
    column: $table.spreadsheetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spreadsheetName => $composableBuilder(
    column: $table.spreadsheetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoSyncEnabled => $composableBuilder(
    column: $table.autoSyncEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncRunState => $composableBuilder(
    column: $table.lastSyncRunState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncSettingsTableTable> {
  $$SyncSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncPreference, String> get syncPreference =>
      $composableBuilder(
        column: $table.syncPreference,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<GoogleConnectionState, String>
  get connectionState => $composableBuilder(
    column: $table.connectionState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get googleAccountEmail => $composableBuilder(
    column: $table.googleAccountEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get spreadsheetId => $composableBuilder(
    column: $table.spreadsheetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get spreadsheetName => $composableBuilder(
    column: $table.spreadsheetName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoSyncEnabled => $composableBuilder(
    column: $table.autoSyncEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncRunState, String> get lastSyncRunState =>
      $composableBuilder(
        column: $table.lastSyncRunState,
        builder: (column) => column,
      );
}

class $$SyncSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncSettingsTableTable,
          SyncSettingsRow,
          $$SyncSettingsTableTableFilterComposer,
          $$SyncSettingsTableTableOrderingComposer,
          $$SyncSettingsTableTableAnnotationComposer,
          $$SyncSettingsTableTableCreateCompanionBuilder,
          $$SyncSettingsTableTableUpdateCompanionBuilder,
          (
            SyncSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $SyncSettingsTableTable,
              SyncSettingsRow
            >,
          ),
          SyncSettingsRow,
          PrefetchHooks Function()
        > {
  $$SyncSettingsTableTableTableManager(
    _$AppDatabase db,
    $SyncSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<SyncPreference> syncPreference = const Value.absent(),
                Value<GoogleConnectionState> connectionState =
                    const Value.absent(),
                Value<String?> googleAccountEmail = const Value.absent(),
                Value<String?> spreadsheetId = const Value.absent(),
                Value<String?> spreadsheetName = const Value.absent(),
                Value<bool> autoSyncEnabled = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
                Value<SyncRunState> lastSyncRunState = const Value.absent(),
              }) => SyncSettingsTableCompanion(
                id: id,
                syncPreference: syncPreference,
                connectionState: connectionState,
                googleAccountEmail: googleAccountEmail,
                spreadsheetId: spreadsheetId,
                spreadsheetName: spreadsheetName,
                autoSyncEnabled: autoSyncEnabled,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                lastSyncRunState: lastSyncRunState,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required SyncPreference syncPreference,
                required GoogleConnectionState connectionState,
                Value<String?> googleAccountEmail = const Value.absent(),
                Value<String?> spreadsheetId = const Value.absent(),
                Value<String?> spreadsheetName = const Value.absent(),
                required bool autoSyncEnabled,
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
                required SyncRunState lastSyncRunState,
              }) => SyncSettingsTableCompanion.insert(
                id: id,
                syncPreference: syncPreference,
                connectionState: connectionState,
                googleAccountEmail: googleAccountEmail,
                spreadsheetId: spreadsheetId,
                spreadsheetName: spreadsheetName,
                autoSyncEnabled: autoSyncEnabled,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                lastSyncRunState: lastSyncRunState,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncSettingsTableTable,
      SyncSettingsRow,
      $$SyncSettingsTableTableFilterComposer,
      $$SyncSettingsTableTableOrderingComposer,
      $$SyncSettingsTableTableAnnotationComposer,
      $$SyncSettingsTableTableCreateCompanionBuilder,
      $$SyncSettingsTableTableUpdateCompanionBuilder,
      (
        SyncSettingsRow,
        BaseReferences<_$AppDatabase, $SyncSettingsTableTable, SyncSettingsRow>,
      ),
      SyncSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$ExpenseCategoriesTableCreateCompanionBuilder =
    ExpenseCategoriesCompanion Function({
      Value<int> id,
      required String name,
      required String normalizedName,
      Value<bool> isDefault,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$ExpenseCategoriesTableUpdateCompanionBuilder =
    ExpenseCategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> normalizedName,
      Value<bool> isDefault,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$ExpenseCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseCategoriesTable> {
  $$ExpenseCategoriesTableFilterComposer({
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

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
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

class $$ExpenseCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseCategoriesTable> {
  $$ExpenseCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
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

class $$ExpenseCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseCategoriesTable> {
  $$ExpenseCategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ExpenseCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseCategoriesTable,
          ExpenseCategoryRow,
          $$ExpenseCategoriesTableFilterComposer,
          $$ExpenseCategoriesTableOrderingComposer,
          $$ExpenseCategoriesTableAnnotationComposer,
          $$ExpenseCategoriesTableCreateCompanionBuilder,
          $$ExpenseCategoriesTableUpdateCompanionBuilder,
          (
            ExpenseCategoryRow,
            BaseReferences<
              _$AppDatabase,
              $ExpenseCategoriesTable,
              ExpenseCategoryRow
            >,
          ),
          ExpenseCategoryRow,
          PrefetchHooks Function()
        > {
  $$ExpenseCategoriesTableTableManager(
    _$AppDatabase db,
    $ExpenseCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ExpenseCategoriesCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
                isDefault: isDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String normalizedName,
                Value<bool> isDefault = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ExpenseCategoriesCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
                isDefault: isDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpenseCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseCategoriesTable,
      ExpenseCategoryRow,
      $$ExpenseCategoriesTableFilterComposer,
      $$ExpenseCategoriesTableOrderingComposer,
      $$ExpenseCategoriesTableAnnotationComposer,
      $$ExpenseCategoriesTableCreateCompanionBuilder,
      $$ExpenseCategoriesTableUpdateCompanionBuilder,
      (
        ExpenseCategoryRow,
        BaseReferences<
          _$AppDatabase,
          $ExpenseCategoriesTable,
          ExpenseCategoryRow
        >,
      ),
      ExpenseCategoryRow,
      PrefetchHooks Function()
    >;
typedef $$CategoryRulesTableCreateCompanionBuilder =
    CategoryRulesCompanion Function({
      Value<int> id,
      required String merchantKey,
      required String category,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$CategoryRulesTableUpdateCompanionBuilder =
    CategoryRulesCompanion Function({
      Value<int> id,
      Value<String> merchantKey,
      Value<String> category,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CategoryRulesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryRulesTable> {
  $$CategoryRulesTableFilterComposer({
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

  ColumnFilters<String> get merchantKey => $composableBuilder(
    column: $table.merchantKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
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

class $$CategoryRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryRulesTable> {
  $$CategoryRulesTableOrderingComposer({
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

  ColumnOrderings<String> get merchantKey => $composableBuilder(
    column: $table.merchantKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
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

class $$CategoryRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryRulesTable> {
  $$CategoryRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get merchantKey => $composableBuilder(
    column: $table.merchantKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoryRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryRulesTable,
          CategoryRuleRow,
          $$CategoryRulesTableFilterComposer,
          $$CategoryRulesTableOrderingComposer,
          $$CategoryRulesTableAnnotationComposer,
          $$CategoryRulesTableCreateCompanionBuilder,
          $$CategoryRulesTableUpdateCompanionBuilder,
          (
            CategoryRuleRow,
            BaseReferences<_$AppDatabase, $CategoryRulesTable, CategoryRuleRow>,
          ),
          CategoryRuleRow,
          PrefetchHooks Function()
        > {
  $$CategoryRulesTableTableManager(_$AppDatabase db, $CategoryRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> merchantKey = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CategoryRulesCompanion(
                id: id,
                merchantKey: merchantKey,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String merchantKey,
                required String category,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => CategoryRulesCompanion.insert(
                id: id,
                merchantKey: merchantKey,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryRulesTable,
      CategoryRuleRow,
      $$CategoryRulesTableFilterComposer,
      $$CategoryRulesTableOrderingComposer,
      $$CategoryRulesTableAnnotationComposer,
      $$CategoryRulesTableCreateCompanionBuilder,
      $$CategoryRulesTableUpdateCompanionBuilder,
      (
        CategoryRuleRow,
        BaseReferences<_$AppDatabase, $CategoryRulesTable, CategoryRuleRow>,
      ),
      CategoryRuleRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$RawCapturesTableTableManager get rawCaptures =>
      $$RawCapturesTableTableManager(_db, _db.rawCaptures);
  $$SyncSettingsTableTableTableManager get syncSettingsTable =>
      $$SyncSettingsTableTableTableManager(_db, _db.syncSettingsTable);
  $$ExpenseCategoriesTableTableManager get expenseCategories =>
      $$ExpenseCategoriesTableTableManager(_db, _db.expenseCategories);
  $$CategoryRulesTableTableManager get categoryRules =>
      $$CategoryRulesTableTableManager(_db, _db.categoryRules);
}
