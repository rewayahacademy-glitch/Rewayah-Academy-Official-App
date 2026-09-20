// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilsFoyerTable extends ProfilsFoyer
    with TableInfo<$ProfilsFoyerTable, ProfilsFoyerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilsFoyerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identifiantImmuableMeta =
      const VerificationMeta('identifiantImmuable');
  @override
  late final GeneratedColumn<String> identifiantImmuable =
      GeneratedColumn<String>(
        'identifiant_immuable',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _prenomMeta = const VerificationMeta('prenom');
  @override
  late final GeneratedColumn<String> prenom = GeneratedColumn<String>(
    'prenom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeInterfaceMeta = const VerificationMeta(
    'modeInterface',
  );
  @override
  late final GeneratedColumn<String> modeInterface = GeneratedColumn<String>(
    'mode_interface',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('standard'),
  );
  static const VerificationMeta _politiqueCameraMeta = const VerificationMeta(
    'politiqueCamera',
  );
  @override
  late final GeneratedColumn<String> politiqueCamera = GeneratedColumn<String>(
    'politique_camera',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('forbidden'),
  );
  static const VerificationMeta _cleAvatarCacheMeta = const VerificationMeta(
    'cleAvatarCache',
  );
  @override
  late final GeneratedColumn<String> cleAvatarCache = GeneratedColumn<String>(
    'cle_avatar_cache',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _synchroniseAMeta = const VerificationMeta(
    'synchroniseA',
  );
  @override
  late final GeneratedColumn<DateTime> synchroniseA = GeneratedColumn<DateTime>(
    'synchronise_a',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    identifiantImmuable,
    prenom,
    modeInterface,
    politiqueCamera,
    cleAvatarCache,
    synchroniseA,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profils_foyer';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfilsFoyerData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('identifiant_immuable')) {
      context.handle(
        _identifiantImmuableMeta,
        identifiantImmuable.isAcceptableOrUnknown(
          data['identifiant_immuable']!,
          _identifiantImmuableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identifiantImmuableMeta);
    }
    if (data.containsKey('prenom')) {
      context.handle(
        _prenomMeta,
        prenom.isAcceptableOrUnknown(data['prenom']!, _prenomMeta),
      );
    } else if (isInserting) {
      context.missing(_prenomMeta);
    }
    if (data.containsKey('mode_interface')) {
      context.handle(
        _modeInterfaceMeta,
        modeInterface.isAcceptableOrUnknown(
          data['mode_interface']!,
          _modeInterfaceMeta,
        ),
      );
    }
    if (data.containsKey('politique_camera')) {
      context.handle(
        _politiqueCameraMeta,
        politiqueCamera.isAcceptableOrUnknown(
          data['politique_camera']!,
          _politiqueCameraMeta,
        ),
      );
    }
    if (data.containsKey('cle_avatar_cache')) {
      context.handle(
        _cleAvatarCacheMeta,
        cleAvatarCache.isAcceptableOrUnknown(
          data['cle_avatar_cache']!,
          _cleAvatarCacheMeta,
        ),
      );
    }
    if (data.containsKey('synchronise_a')) {
      context.handle(
        _synchroniseAMeta,
        synchroniseA.isAcceptableOrUnknown(
          data['synchronise_a']!,
          _synchroniseAMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_synchroniseAMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfilsFoyerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfilsFoyerData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      identifiantImmuable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identifiant_immuable'],
      )!,
      prenom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prenom'],
      )!,
      modeInterface: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode_interface'],
      )!,
      politiqueCamera: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}politique_camera'],
      )!,
      cleAvatarCache: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cle_avatar_cache'],
      ),
      synchroniseA: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synchronise_a'],
      )!,
    );
  }

  @override
  $ProfilsFoyerTable createAlias(String alias) {
    return $ProfilsFoyerTable(attachedDatabase, alias);
  }
}

class ProfilsFoyerData extends DataClass
    implements Insertable<ProfilsFoyerData> {
  /// Identifiant du profil, identique a celui de la base.
  final String id;

  /// Identifiant immuable, celui qu'un enseignant voit.
  final String identifiantImmuable;

  /// Prenom.
  final String prenom;

  /// Mode d'interface, valeur SQL (`child` ou `standard`).
  final String modeInterface;

  /// Politique camera, valeur SQL (`allowed` ou `forbidden`).
  final String politiqueCamera;

  /// Cle du fichier avatar dans le cache media. Jamais l'URL signee, qui
  /// expire, ni l'original, qui n'est jamais transporte (ADR-012).
  final String? cleAvatarCache;

  /// Derniere synchronisation.
  final DateTime synchroniseA;
  const ProfilsFoyerData({
    required this.id,
    required this.identifiantImmuable,
    required this.prenom,
    required this.modeInterface,
    required this.politiqueCamera,
    this.cleAvatarCache,
    required this.synchroniseA,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['identifiant_immuable'] = Variable<String>(identifiantImmuable);
    map['prenom'] = Variable<String>(prenom);
    map['mode_interface'] = Variable<String>(modeInterface);
    map['politique_camera'] = Variable<String>(politiqueCamera);
    if (!nullToAbsent || cleAvatarCache != null) {
      map['cle_avatar_cache'] = Variable<String>(cleAvatarCache);
    }
    map['synchronise_a'] = Variable<DateTime>(synchroniseA);
    return map;
  }

  ProfilsFoyerCompanion toCompanion(bool nullToAbsent) {
    return ProfilsFoyerCompanion(
      id: Value(id),
      identifiantImmuable: Value(identifiantImmuable),
      prenom: Value(prenom),
      modeInterface: Value(modeInterface),
      politiqueCamera: Value(politiqueCamera),
      cleAvatarCache: cleAvatarCache == null && nullToAbsent
          ? const Value.absent()
          : Value(cleAvatarCache),
      synchroniseA: Value(synchroniseA),
    );
  }

  factory ProfilsFoyerData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfilsFoyerData(
      id: serializer.fromJson<String>(json['id']),
      identifiantImmuable: serializer.fromJson<String>(
        json['identifiantImmuable'],
      ),
      prenom: serializer.fromJson<String>(json['prenom']),
      modeInterface: serializer.fromJson<String>(json['modeInterface']),
      politiqueCamera: serializer.fromJson<String>(json['politiqueCamera']),
      cleAvatarCache: serializer.fromJson<String?>(json['cleAvatarCache']),
      synchroniseA: serializer.fromJson<DateTime>(json['synchroniseA']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'identifiantImmuable': serializer.toJson<String>(identifiantImmuable),
      'prenom': serializer.toJson<String>(prenom),
      'modeInterface': serializer.toJson<String>(modeInterface),
      'politiqueCamera': serializer.toJson<String>(politiqueCamera),
      'cleAvatarCache': serializer.toJson<String?>(cleAvatarCache),
      'synchroniseA': serializer.toJson<DateTime>(synchroniseA),
    };
  }

  ProfilsFoyerData copyWith({
    String? id,
    String? identifiantImmuable,
    String? prenom,
    String? modeInterface,
    String? politiqueCamera,
    Value<String?> cleAvatarCache = const Value.absent(),
    DateTime? synchroniseA,
  }) => ProfilsFoyerData(
    id: id ?? this.id,
    identifiantImmuable: identifiantImmuable ?? this.identifiantImmuable,
    prenom: prenom ?? this.prenom,
    modeInterface: modeInterface ?? this.modeInterface,
    politiqueCamera: politiqueCamera ?? this.politiqueCamera,
    cleAvatarCache: cleAvatarCache.present
        ? cleAvatarCache.value
        : this.cleAvatarCache,
    synchroniseA: synchroniseA ?? this.synchroniseA,
  );
  ProfilsFoyerData copyWithCompanion(ProfilsFoyerCompanion data) {
    return ProfilsFoyerData(
      id: data.id.present ? data.id.value : this.id,
      identifiantImmuable: data.identifiantImmuable.present
          ? data.identifiantImmuable.value
          : this.identifiantImmuable,
      prenom: data.prenom.present ? data.prenom.value : this.prenom,
      modeInterface: data.modeInterface.present
          ? data.modeInterface.value
          : this.modeInterface,
      politiqueCamera: data.politiqueCamera.present
          ? data.politiqueCamera.value
          : this.politiqueCamera,
      cleAvatarCache: data.cleAvatarCache.present
          ? data.cleAvatarCache.value
          : this.cleAvatarCache,
      synchroniseA: data.synchroniseA.present
          ? data.synchroniseA.value
          : this.synchroniseA,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfilsFoyerData(')
          ..write('id: $id, ')
          ..write('identifiantImmuable: $identifiantImmuable, ')
          ..write('prenom: $prenom, ')
          ..write('modeInterface: $modeInterface, ')
          ..write('politiqueCamera: $politiqueCamera, ')
          ..write('cleAvatarCache: $cleAvatarCache, ')
          ..write('synchroniseA: $synchroniseA')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    identifiantImmuable,
    prenom,
    modeInterface,
    politiqueCamera,
    cleAvatarCache,
    synchroniseA,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfilsFoyerData &&
          other.id == this.id &&
          other.identifiantImmuable == this.identifiantImmuable &&
          other.prenom == this.prenom &&
          other.modeInterface == this.modeInterface &&
          other.politiqueCamera == this.politiqueCamera &&
          other.cleAvatarCache == this.cleAvatarCache &&
          other.synchroniseA == this.synchroniseA);
}

class ProfilsFoyerCompanion extends UpdateCompanion<ProfilsFoyerData> {
  final Value<String> id;
  final Value<String> identifiantImmuable;
  final Value<String> prenom;
  final Value<String> modeInterface;
  final Value<String> politiqueCamera;
  final Value<String?> cleAvatarCache;
  final Value<DateTime> synchroniseA;
  final Value<int> rowid;
  const ProfilsFoyerCompanion({
    this.id = const Value.absent(),
    this.identifiantImmuable = const Value.absent(),
    this.prenom = const Value.absent(),
    this.modeInterface = const Value.absent(),
    this.politiqueCamera = const Value.absent(),
    this.cleAvatarCache = const Value.absent(),
    this.synchroniseA = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilsFoyerCompanion.insert({
    required String id,
    required String identifiantImmuable,
    required String prenom,
    this.modeInterface = const Value.absent(),
    this.politiqueCamera = const Value.absent(),
    this.cleAvatarCache = const Value.absent(),
    required DateTime synchroniseA,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       identifiantImmuable = Value(identifiantImmuable),
       prenom = Value(prenom),
       synchroniseA = Value(synchroniseA);
  static Insertable<ProfilsFoyerData> custom({
    Expression<String>? id,
    Expression<String>? identifiantImmuable,
    Expression<String>? prenom,
    Expression<String>? modeInterface,
    Expression<String>? politiqueCamera,
    Expression<String>? cleAvatarCache,
    Expression<DateTime>? synchroniseA,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (identifiantImmuable != null)
        'identifiant_immuable': identifiantImmuable,
      if (prenom != null) 'prenom': prenom,
      if (modeInterface != null) 'mode_interface': modeInterface,
      if (politiqueCamera != null) 'politique_camera': politiqueCamera,
      if (cleAvatarCache != null) 'cle_avatar_cache': cleAvatarCache,
      if (synchroniseA != null) 'synchronise_a': synchroniseA,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilsFoyerCompanion copyWith({
    Value<String>? id,
    Value<String>? identifiantImmuable,
    Value<String>? prenom,
    Value<String>? modeInterface,
    Value<String>? politiqueCamera,
    Value<String?>? cleAvatarCache,
    Value<DateTime>? synchroniseA,
    Value<int>? rowid,
  }) {
    return ProfilsFoyerCompanion(
      id: id ?? this.id,
      identifiantImmuable: identifiantImmuable ?? this.identifiantImmuable,
      prenom: prenom ?? this.prenom,
      modeInterface: modeInterface ?? this.modeInterface,
      politiqueCamera: politiqueCamera ?? this.politiqueCamera,
      cleAvatarCache: cleAvatarCache ?? this.cleAvatarCache,
      synchroniseA: synchroniseA ?? this.synchroniseA,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (identifiantImmuable.present) {
      map['identifiant_immuable'] = Variable<String>(identifiantImmuable.value);
    }
    if (prenom.present) {
      map['prenom'] = Variable<String>(prenom.value);
    }
    if (modeInterface.present) {
      map['mode_interface'] = Variable<String>(modeInterface.value);
    }
    if (politiqueCamera.present) {
      map['politique_camera'] = Variable<String>(politiqueCamera.value);
    }
    if (cleAvatarCache.present) {
      map['cle_avatar_cache'] = Variable<String>(cleAvatarCache.value);
    }
    if (synchroniseA.present) {
      map['synchronise_a'] = Variable<DateTime>(synchroniseA.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilsFoyerCompanion(')
          ..write('id: $id, ')
          ..write('identifiantImmuable: $identifiantImmuable, ')
          ..write('prenom: $prenom, ')
          ..write('modeInterface: $modeInterface, ')
          ..write('politiqueCamera: $politiqueCamera, ')
          ..write('cleAvatarCache: $cleAvatarCache, ')
          ..write('synchroniseA: $synchroniseA, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsAVenirTable extends SessionsAVenir
    with TableInfo<$SessionsAVenirTable, SessionsAVenirData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsAVenirTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debutUtcMeta = const VerificationMeta(
    'debutUtc',
  );
  @override
  late final GeneratedColumn<DateTime> debutUtc = GeneratedColumn<DateTime>(
    'debut_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finUtcMeta = const VerificationMeta('finUtc');
  @override
  late final GeneratedColumn<DateTime> finUtc = GeneratedColumn<DateTime>(
    'fin_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profilIdMeta = const VerificationMeta(
    'profilId',
  );
  @override
  late final GeneratedColumn<String> profilId = GeneratedColumn<String>(
    'profil_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prenomEnseignantMeta = const VerificationMeta(
    'prenomEnseignant',
  );
  @override
  late final GeneratedColumn<String> prenomEnseignant = GeneratedColumn<String>(
    'prenom_enseignant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _synchroniseAMeta = const VerificationMeta(
    'synchroniseA',
  );
  @override
  late final GeneratedColumn<DateTime> synchroniseA = GeneratedColumn<DateTime>(
    'synchronise_a',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    debutUtc,
    finUtc,
    statut,
    profilId,
    prenomEnseignant,
    synchroniseA,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions_a_venir';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionsAVenirData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('debut_utc')) {
      context.handle(
        _debutUtcMeta,
        debutUtc.isAcceptableOrUnknown(data['debut_utc']!, _debutUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_debutUtcMeta);
    }
    if (data.containsKey('fin_utc')) {
      context.handle(
        _finUtcMeta,
        finUtc.isAcceptableOrUnknown(data['fin_utc']!, _finUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_finUtcMeta);
    }
    if (data.containsKey('statut')) {
      context.handle(
        _statutMeta,
        statut.isAcceptableOrUnknown(data['statut']!, _statutMeta),
      );
    } else if (isInserting) {
      context.missing(_statutMeta);
    }
    if (data.containsKey('profil_id')) {
      context.handle(
        _profilIdMeta,
        profilId.isAcceptableOrUnknown(data['profil_id']!, _profilIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profilIdMeta);
    }
    if (data.containsKey('prenom_enseignant')) {
      context.handle(
        _prenomEnseignantMeta,
        prenomEnseignant.isAcceptableOrUnknown(
          data['prenom_enseignant']!,
          _prenomEnseignantMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prenomEnseignantMeta);
    }
    if (data.containsKey('synchronise_a')) {
      context.handle(
        _synchroniseAMeta,
        synchroniseA.isAcceptableOrUnknown(
          data['synchronise_a']!,
          _synchroniseAMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_synchroniseAMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionsAVenirData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionsAVenirData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      debutUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}debut_utc'],
      )!,
      finUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fin_utc'],
      )!,
      statut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut'],
      )!,
      profilId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profil_id'],
      )!,
      prenomEnseignant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prenom_enseignant'],
      )!,
      synchroniseA: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synchronise_a'],
      )!,
    );
  }

  @override
  $SessionsAVenirTable createAlias(String alias) {
    return $SessionsAVenirTable(attachedDatabase, alias);
  }
}

class SessionsAVenirData extends DataClass
    implements Insertable<SessionsAVenirData> {
  /// Identifiant de la seance.
  final String id;

  /// Debut, en UTC. Le fuseau est une donnee d'affichage.
  final DateTime debutUtc;

  /// Fin, en UTC.
  final DateTime finUtc;

  /// Statut, valeur SQL de `public.session_status`.
  final String statut;

  /// Profil du foyer concerne.
  final String profilId;

  /// Prenom de l'enseignant. Prenom seul, jamais le nom complet.
  final String prenomEnseignant;

  /// Derniere synchronisation.
  final DateTime synchroniseA;
  const SessionsAVenirData({
    required this.id,
    required this.debutUtc,
    required this.finUtc,
    required this.statut,
    required this.profilId,
    required this.prenomEnseignant,
    required this.synchroniseA,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['debut_utc'] = Variable<DateTime>(debutUtc);
    map['fin_utc'] = Variable<DateTime>(finUtc);
    map['statut'] = Variable<String>(statut);
    map['profil_id'] = Variable<String>(profilId);
    map['prenom_enseignant'] = Variable<String>(prenomEnseignant);
    map['synchronise_a'] = Variable<DateTime>(synchroniseA);
    return map;
  }

  SessionsAVenirCompanion toCompanion(bool nullToAbsent) {
    return SessionsAVenirCompanion(
      id: Value(id),
      debutUtc: Value(debutUtc),
      finUtc: Value(finUtc),
      statut: Value(statut),
      profilId: Value(profilId),
      prenomEnseignant: Value(prenomEnseignant),
      synchroniseA: Value(synchroniseA),
    );
  }

  factory SessionsAVenirData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionsAVenirData(
      id: serializer.fromJson<String>(json['id']),
      debutUtc: serializer.fromJson<DateTime>(json['debutUtc']),
      finUtc: serializer.fromJson<DateTime>(json['finUtc']),
      statut: serializer.fromJson<String>(json['statut']),
      profilId: serializer.fromJson<String>(json['profilId']),
      prenomEnseignant: serializer.fromJson<String>(json['prenomEnseignant']),
      synchroniseA: serializer.fromJson<DateTime>(json['synchroniseA']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'debutUtc': serializer.toJson<DateTime>(debutUtc),
      'finUtc': serializer.toJson<DateTime>(finUtc),
      'statut': serializer.toJson<String>(statut),
      'profilId': serializer.toJson<String>(profilId),
      'prenomEnseignant': serializer.toJson<String>(prenomEnseignant),
      'synchroniseA': serializer.toJson<DateTime>(synchroniseA),
    };
  }

  SessionsAVenirData copyWith({
    String? id,
    DateTime? debutUtc,
    DateTime? finUtc,
    String? statut,
    String? profilId,
    String? prenomEnseignant,
    DateTime? synchroniseA,
  }) => SessionsAVenirData(
    id: id ?? this.id,
    debutUtc: debutUtc ?? this.debutUtc,
    finUtc: finUtc ?? this.finUtc,
    statut: statut ?? this.statut,
    profilId: profilId ?? this.profilId,
    prenomEnseignant: prenomEnseignant ?? this.prenomEnseignant,
    synchroniseA: synchroniseA ?? this.synchroniseA,
  );
  SessionsAVenirData copyWithCompanion(SessionsAVenirCompanion data) {
    return SessionsAVenirData(
      id: data.id.present ? data.id.value : this.id,
      debutUtc: data.debutUtc.present ? data.debutUtc.value : this.debutUtc,
      finUtc: data.finUtc.present ? data.finUtc.value : this.finUtc,
      statut: data.statut.present ? data.statut.value : this.statut,
      profilId: data.profilId.present ? data.profilId.value : this.profilId,
      prenomEnseignant: data.prenomEnseignant.present
          ? data.prenomEnseignant.value
          : this.prenomEnseignant,
      synchroniseA: data.synchroniseA.present
          ? data.synchroniseA.value
          : this.synchroniseA,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionsAVenirData(')
          ..write('id: $id, ')
          ..write('debutUtc: $debutUtc, ')
          ..write('finUtc: $finUtc, ')
          ..write('statut: $statut, ')
          ..write('profilId: $profilId, ')
          ..write('prenomEnseignant: $prenomEnseignant, ')
          ..write('synchroniseA: $synchroniseA')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    debutUtc,
    finUtc,
    statut,
    profilId,
    prenomEnseignant,
    synchroniseA,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionsAVenirData &&
          other.id == this.id &&
          other.debutUtc == this.debutUtc &&
          other.finUtc == this.finUtc &&
          other.statut == this.statut &&
          other.profilId == this.profilId &&
          other.prenomEnseignant == this.prenomEnseignant &&
          other.synchroniseA == this.synchroniseA);
}

class SessionsAVenirCompanion extends UpdateCompanion<SessionsAVenirData> {
  final Value<String> id;
  final Value<DateTime> debutUtc;
  final Value<DateTime> finUtc;
  final Value<String> statut;
  final Value<String> profilId;
  final Value<String> prenomEnseignant;
  final Value<DateTime> synchroniseA;
  final Value<int> rowid;
  const SessionsAVenirCompanion({
    this.id = const Value.absent(),
    this.debutUtc = const Value.absent(),
    this.finUtc = const Value.absent(),
    this.statut = const Value.absent(),
    this.profilId = const Value.absent(),
    this.prenomEnseignant = const Value.absent(),
    this.synchroniseA = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsAVenirCompanion.insert({
    required String id,
    required DateTime debutUtc,
    required DateTime finUtc,
    required String statut,
    required String profilId,
    required String prenomEnseignant,
    required DateTime synchroniseA,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       debutUtc = Value(debutUtc),
       finUtc = Value(finUtc),
       statut = Value(statut),
       profilId = Value(profilId),
       prenomEnseignant = Value(prenomEnseignant),
       synchroniseA = Value(synchroniseA);
  static Insertable<SessionsAVenirData> custom({
    Expression<String>? id,
    Expression<DateTime>? debutUtc,
    Expression<DateTime>? finUtc,
    Expression<String>? statut,
    Expression<String>? profilId,
    Expression<String>? prenomEnseignant,
    Expression<DateTime>? synchroniseA,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (debutUtc != null) 'debut_utc': debutUtc,
      if (finUtc != null) 'fin_utc': finUtc,
      if (statut != null) 'statut': statut,
      if (profilId != null) 'profil_id': profilId,
      if (prenomEnseignant != null) 'prenom_enseignant': prenomEnseignant,
      if (synchroniseA != null) 'synchronise_a': synchroniseA,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsAVenirCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? debutUtc,
    Value<DateTime>? finUtc,
    Value<String>? statut,
    Value<String>? profilId,
    Value<String>? prenomEnseignant,
    Value<DateTime>? synchroniseA,
    Value<int>? rowid,
  }) {
    return SessionsAVenirCompanion(
      id: id ?? this.id,
      debutUtc: debutUtc ?? this.debutUtc,
      finUtc: finUtc ?? this.finUtc,
      statut: statut ?? this.statut,
      profilId: profilId ?? this.profilId,
      prenomEnseignant: prenomEnseignant ?? this.prenomEnseignant,
      synchroniseA: synchroniseA ?? this.synchroniseA,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (debutUtc.present) {
      map['debut_utc'] = Variable<DateTime>(debutUtc.value);
    }
    if (finUtc.present) {
      map['fin_utc'] = Variable<DateTime>(finUtc.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (profilId.present) {
      map['profil_id'] = Variable<String>(profilId.value);
    }
    if (prenomEnseignant.present) {
      map['prenom_enseignant'] = Variable<String>(prenomEnseignant.value);
    }
    if (synchroniseA.present) {
      map['synchronise_a'] = Variable<DateTime>(synchroniseA.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsAVenirCompanion(')
          ..write('id: $id, ')
          ..write('debutUtc: $debutUtc, ')
          ..write('finUtc: $finUtc, ')
          ..write('statut: $statut, ')
          ..write('profilId: $profilId, ')
          ..write('prenomEnseignant: $prenomEnseignant, ')
          ..write('synchroniseA: $synchroniseA, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RessourcesHorsLigneTable extends RessourcesHorsLigne
    with TableInfo<$RessourcesHorsLigneTable, RessourcesHorsLigneData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RessourcesHorsLigneTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
    'resource_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionIdMeta = const VerificationMeta(
    'versionId',
  );
  @override
  late final GeneratedColumn<String> versionId = GeneratedColumn<String>(
    'version_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cleCacheMeta = const VerificationMeta(
    'cleCache',
  );
  @override
  late final GeneratedColumn<String> cleCache = GeneratedColumn<String>(
    'cle_cache',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _epingleeMeta = const VerificationMeta(
    'epinglee',
  );
  @override
  late final GeneratedColumn<bool> epinglee = GeneratedColumn<bool>(
    'epinglee',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("epinglee" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deposeeAMeta = const VerificationMeta(
    'deposeeA',
  );
  @override
  late final GeneratedColumn<DateTime> deposeeA = GeneratedColumn<DateTime>(
    'deposee_a',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    resourceId,
    versionId,
    cleCache,
    epinglee,
    deposeeA,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ressources_hors_ligne';
  @override
  VerificationContext validateIntegrity(
    Insertable<RessourcesHorsLigneData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('version_id')) {
      context.handle(
        _versionIdMeta,
        versionId.isAcceptableOrUnknown(data['version_id']!, _versionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_versionIdMeta);
    }
    if (data.containsKey('cle_cache')) {
      context.handle(
        _cleCacheMeta,
        cleCache.isAcceptableOrUnknown(data['cle_cache']!, _cleCacheMeta),
      );
    } else if (isInserting) {
      context.missing(_cleCacheMeta);
    }
    if (data.containsKey('epinglee')) {
      context.handle(
        _epingleeMeta,
        epinglee.isAcceptableOrUnknown(data['epinglee']!, _epingleeMeta),
      );
    }
    if (data.containsKey('deposee_a')) {
      context.handle(
        _deposeeAMeta,
        deposeeA.isAcceptableOrUnknown(data['deposee_a']!, _deposeeAMeta),
      );
    } else if (isInserting) {
      context.missing(_deposeeAMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId};
  @override
  RessourcesHorsLigneData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RessourcesHorsLigneData(
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_id'],
      )!,
      versionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_id'],
      )!,
      cleCache: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cle_cache'],
      )!,
      epinglee: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}epinglee'],
      )!,
      deposeeA: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deposee_a'],
      )!,
    );
  }

  @override
  $RessourcesHorsLigneTable createAlias(String alias) {
    return $RessourcesHorsLigneTable(attachedDatabase, alias);
  }
}

class RessourcesHorsLigneData extends DataClass
    implements Insertable<RessourcesHorsLigneData> {
  /// Identifiant de la ressource (`library_resource.id`).
  final String resourceId;

  /// Version telechargee (`resource_version.id`).
  final String versionId;

  /// Cle du fichier dans le cache media.
  final String cleCache;

  /// Epinglee : ne participe pas a la purge automatique.
  final bool epinglee;

  /// Date de depot local.
  final DateTime deposeeA;
  const RessourcesHorsLigneData({
    required this.resourceId,
    required this.versionId,
    required this.cleCache,
    required this.epinglee,
    required this.deposeeA,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['version_id'] = Variable<String>(versionId);
    map['cle_cache'] = Variable<String>(cleCache);
    map['epinglee'] = Variable<bool>(epinglee);
    map['deposee_a'] = Variable<DateTime>(deposeeA);
    return map;
  }

  RessourcesHorsLigneCompanion toCompanion(bool nullToAbsent) {
    return RessourcesHorsLigneCompanion(
      resourceId: Value(resourceId),
      versionId: Value(versionId),
      cleCache: Value(cleCache),
      epinglee: Value(epinglee),
      deposeeA: Value(deposeeA),
    );
  }

  factory RessourcesHorsLigneData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RessourcesHorsLigneData(
      resourceId: serializer.fromJson<String>(json['resourceId']),
      versionId: serializer.fromJson<String>(json['versionId']),
      cleCache: serializer.fromJson<String>(json['cleCache']),
      epinglee: serializer.fromJson<bool>(json['epinglee']),
      deposeeA: serializer.fromJson<DateTime>(json['deposeeA']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceId': serializer.toJson<String>(resourceId),
      'versionId': serializer.toJson<String>(versionId),
      'cleCache': serializer.toJson<String>(cleCache),
      'epinglee': serializer.toJson<bool>(epinglee),
      'deposeeA': serializer.toJson<DateTime>(deposeeA),
    };
  }

  RessourcesHorsLigneData copyWith({
    String? resourceId,
    String? versionId,
    String? cleCache,
    bool? epinglee,
    DateTime? deposeeA,
  }) => RessourcesHorsLigneData(
    resourceId: resourceId ?? this.resourceId,
    versionId: versionId ?? this.versionId,
    cleCache: cleCache ?? this.cleCache,
    epinglee: epinglee ?? this.epinglee,
    deposeeA: deposeeA ?? this.deposeeA,
  );
  RessourcesHorsLigneData copyWithCompanion(RessourcesHorsLigneCompanion data) {
    return RessourcesHorsLigneData(
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
      versionId: data.versionId.present ? data.versionId.value : this.versionId,
      cleCache: data.cleCache.present ? data.cleCache.value : this.cleCache,
      epinglee: data.epinglee.present ? data.epinglee.value : this.epinglee,
      deposeeA: data.deposeeA.present ? data.deposeeA.value : this.deposeeA,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RessourcesHorsLigneData(')
          ..write('resourceId: $resourceId, ')
          ..write('versionId: $versionId, ')
          ..write('cleCache: $cleCache, ')
          ..write('epinglee: $epinglee, ')
          ..write('deposeeA: $deposeeA')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(resourceId, versionId, cleCache, epinglee, deposeeA);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RessourcesHorsLigneData &&
          other.resourceId == this.resourceId &&
          other.versionId == this.versionId &&
          other.cleCache == this.cleCache &&
          other.epinglee == this.epinglee &&
          other.deposeeA == this.deposeeA);
}

class RessourcesHorsLigneCompanion
    extends UpdateCompanion<RessourcesHorsLigneData> {
  final Value<String> resourceId;
  final Value<String> versionId;
  final Value<String> cleCache;
  final Value<bool> epinglee;
  final Value<DateTime> deposeeA;
  final Value<int> rowid;
  const RessourcesHorsLigneCompanion({
    this.resourceId = const Value.absent(),
    this.versionId = const Value.absent(),
    this.cleCache = const Value.absent(),
    this.epinglee = const Value.absent(),
    this.deposeeA = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RessourcesHorsLigneCompanion.insert({
    required String resourceId,
    required String versionId,
    required String cleCache,
    this.epinglee = const Value.absent(),
    required DateTime deposeeA,
    this.rowid = const Value.absent(),
  }) : resourceId = Value(resourceId),
       versionId = Value(versionId),
       cleCache = Value(cleCache),
       deposeeA = Value(deposeeA);
  static Insertable<RessourcesHorsLigneData> custom({
    Expression<String>? resourceId,
    Expression<String>? versionId,
    Expression<String>? cleCache,
    Expression<bool>? epinglee,
    Expression<DateTime>? deposeeA,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (versionId != null) 'version_id': versionId,
      if (cleCache != null) 'cle_cache': cleCache,
      if (epinglee != null) 'epinglee': epinglee,
      if (deposeeA != null) 'deposee_a': deposeeA,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RessourcesHorsLigneCompanion copyWith({
    Value<String>? resourceId,
    Value<String>? versionId,
    Value<String>? cleCache,
    Value<bool>? epinglee,
    Value<DateTime>? deposeeA,
    Value<int>? rowid,
  }) {
    return RessourcesHorsLigneCompanion(
      resourceId: resourceId ?? this.resourceId,
      versionId: versionId ?? this.versionId,
      cleCache: cleCache ?? this.cleCache,
      epinglee: epinglee ?? this.epinglee,
      deposeeA: deposeeA ?? this.deposeeA,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (versionId.present) {
      map['version_id'] = Variable<String>(versionId.value);
    }
    if (cleCache.present) {
      map['cle_cache'] = Variable<String>(cleCache.value);
    }
    if (epinglee.present) {
      map['epinglee'] = Variable<bool>(epinglee.value);
    }
    if (deposeeA.present) {
      map['deposee_a'] = Variable<DateTime>(deposeeA.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RessourcesHorsLigneCompanion(')
          ..write('resourceId: $resourceId, ')
          ..write('versionId: $versionId, ')
          ..write('cleCache: $cleCache, ')
          ..write('epinglee: $epinglee, ')
          ..write('deposeeA: $deposeeA, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferenceLocaleTable extends PreferenceLocale
    with TableInfo<$PreferenceLocaleTable, PreferenceLocaleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferenceLocaleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clefMeta = const VerificationMeta('clef');
  @override
  late final GeneratedColumn<String> clef = GeneratedColumn<String>(
    'clef',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valeurMeta = const VerificationMeta('valeur');
  @override
  late final GeneratedColumn<String> valeur = GeneratedColumn<String>(
    'valeur',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [clef, valeur];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preference_locale';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferenceLocaleData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('clef')) {
      context.handle(
        _clefMeta,
        clef.isAcceptableOrUnknown(data['clef']!, _clefMeta),
      );
    } else if (isInserting) {
      context.missing(_clefMeta);
    }
    if (data.containsKey('valeur')) {
      context.handle(
        _valeurMeta,
        valeur.isAcceptableOrUnknown(data['valeur']!, _valeurMeta),
      );
    } else if (isInserting) {
      context.missing(_valeurMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clef};
  @override
  PreferenceLocaleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferenceLocaleData(
      clef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clef'],
      )!,
      valeur: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valeur'],
      )!,
    );
  }

  @override
  $PreferenceLocaleTable createAlias(String alias) {
    return $PreferenceLocaleTable(attachedDatabase, alias);
  }
}

class PreferenceLocaleData extends DataClass
    implements Insertable<PreferenceLocaleData> {
  /// La clef, par exemple `dock.position`.
  final String clef;

  /// La valeur, en texte brut.
  final String valeur;
  const PreferenceLocaleData({required this.clef, required this.valeur});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['clef'] = Variable<String>(clef);
    map['valeur'] = Variable<String>(valeur);
    return map;
  }

  PreferenceLocaleCompanion toCompanion(bool nullToAbsent) {
    return PreferenceLocaleCompanion(clef: Value(clef), valeur: Value(valeur));
  }

  factory PreferenceLocaleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferenceLocaleData(
      clef: serializer.fromJson<String>(json['clef']),
      valeur: serializer.fromJson<String>(json['valeur']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clef': serializer.toJson<String>(clef),
      'valeur': serializer.toJson<String>(valeur),
    };
  }

  PreferenceLocaleData copyWith({String? clef, String? valeur}) =>
      PreferenceLocaleData(
        clef: clef ?? this.clef,
        valeur: valeur ?? this.valeur,
      );
  PreferenceLocaleData copyWithCompanion(PreferenceLocaleCompanion data) {
    return PreferenceLocaleData(
      clef: data.clef.present ? data.clef.value : this.clef,
      valeur: data.valeur.present ? data.valeur.value : this.valeur,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceLocaleData(')
          ..write('clef: $clef, ')
          ..write('valeur: $valeur')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clef, valeur);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferenceLocaleData &&
          other.clef == this.clef &&
          other.valeur == this.valeur);
}

class PreferenceLocaleCompanion extends UpdateCompanion<PreferenceLocaleData> {
  final Value<String> clef;
  final Value<String> valeur;
  final Value<int> rowid;
  const PreferenceLocaleCompanion({
    this.clef = const Value.absent(),
    this.valeur = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferenceLocaleCompanion.insert({
    required String clef,
    required String valeur,
    this.rowid = const Value.absent(),
  }) : clef = Value(clef),
       valeur = Value(valeur);
  static Insertable<PreferenceLocaleData> custom({
    Expression<String>? clef,
    Expression<String>? valeur,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clef != null) 'clef': clef,
      if (valeur != null) 'valeur': valeur,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferenceLocaleCompanion copyWith({
    Value<String>? clef,
    Value<String>? valeur,
    Value<int>? rowid,
  }) {
    return PreferenceLocaleCompanion(
      clef: clef ?? this.clef,
      valeur: valeur ?? this.valeur,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clef.present) {
      map['clef'] = Variable<String>(clef.value);
    }
    if (valeur.present) {
      map['valeur'] = Variable<String>(valeur.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceLocaleCompanion(')
          ..write('clef: $clef, ')
          ..write('valeur: $valeur, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RapportsEnAttenteTable extends RapportsEnAttente
    with TableInfo<$RapportsEnAttenteTable, RapportsEnAttenteData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RapportsEnAttenteTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cleIdempotenceMeta = const VerificationMeta(
    'cleIdempotence',
  );
  @override
  late final GeneratedColumn<String> cleIdempotence = GeneratedColumn<String>(
    'cle_idempotence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contenuJsonMeta = const VerificationMeta(
    'contenuJson',
  );
  @override
  late final GeneratedColumn<String> contenuJson = GeneratedColumn<String>(
    'contenu_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en_attente'),
  );
  static const VerificationMeta _redigeAMeta = const VerificationMeta(
    'redigeA',
  );
  @override
  late final GeneratedColumn<DateTime> redigeA = GeneratedColumn<DateTime>(
    'redige_a',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tentativesMeta = const VerificationMeta(
    'tentatives',
  );
  @override
  late final GeneratedColumn<int> tentatives = GeneratedColumn<int>(
    'tentatives',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    cleIdempotence,
    sessionId,
    contenuJson,
    statut,
    redigeA,
    tentatives,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rapports_en_attente';
  @override
  VerificationContext validateIntegrity(
    Insertable<RapportsEnAttenteData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cle_idempotence')) {
      context.handle(
        _cleIdempotenceMeta,
        cleIdempotence.isAcceptableOrUnknown(
          data['cle_idempotence']!,
          _cleIdempotenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cleIdempotenceMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('contenu_json')) {
      context.handle(
        _contenuJsonMeta,
        contenuJson.isAcceptableOrUnknown(
          data['contenu_json']!,
          _contenuJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contenuJsonMeta);
    }
    if (data.containsKey('statut')) {
      context.handle(
        _statutMeta,
        statut.isAcceptableOrUnknown(data['statut']!, _statutMeta),
      );
    }
    if (data.containsKey('redige_a')) {
      context.handle(
        _redigeAMeta,
        redigeA.isAcceptableOrUnknown(data['redige_a']!, _redigeAMeta),
      );
    } else if (isInserting) {
      context.missing(_redigeAMeta);
    }
    if (data.containsKey('tentatives')) {
      context.handle(
        _tentativesMeta,
        tentatives.isAcceptableOrUnknown(data['tentatives']!, _tentativesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cleIdempotence};
  @override
  RapportsEnAttenteData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RapportsEnAttenteData(
      cleIdempotence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cle_idempotence'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      contenuJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contenu_json'],
      )!,
      statut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut'],
      )!,
      redigeA: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}redige_a'],
      )!,
      tentatives: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tentatives'],
      )!,
    );
  }

  @override
  $RapportsEnAttenteTable createAlias(String alias) {
    return $RapportsEnAttenteTable(attachedDatabase, alias);
  }
}

class RapportsEnAttenteData extends DataClass
    implements Insertable<RapportsEnAttenteData> {
  /// Cle d'idempotence, generee localement, jamais reattribuee.
  final String cleIdempotence;

  /// Seance concernee.
  final String sessionId;

  /// Contenu du rapport, tel qu'il sera envoye.
  final String contenuJson;

  /// Statut local : `en_attente`, `envoi`, `envoye`.
  final String statut;

  /// Date de redaction.
  final DateTime redigeA;

  /// Nombre de tentatives d'envoi.
  final int tentatives;
  const RapportsEnAttenteData({
    required this.cleIdempotence,
    required this.sessionId,
    required this.contenuJson,
    required this.statut,
    required this.redigeA,
    required this.tentatives,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cle_idempotence'] = Variable<String>(cleIdempotence);
    map['session_id'] = Variable<String>(sessionId);
    map['contenu_json'] = Variable<String>(contenuJson);
    map['statut'] = Variable<String>(statut);
    map['redige_a'] = Variable<DateTime>(redigeA);
    map['tentatives'] = Variable<int>(tentatives);
    return map;
  }

  RapportsEnAttenteCompanion toCompanion(bool nullToAbsent) {
    return RapportsEnAttenteCompanion(
      cleIdempotence: Value(cleIdempotence),
      sessionId: Value(sessionId),
      contenuJson: Value(contenuJson),
      statut: Value(statut),
      redigeA: Value(redigeA),
      tentatives: Value(tentatives),
    );
  }

  factory RapportsEnAttenteData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RapportsEnAttenteData(
      cleIdempotence: serializer.fromJson<String>(json['cleIdempotence']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      contenuJson: serializer.fromJson<String>(json['contenuJson']),
      statut: serializer.fromJson<String>(json['statut']),
      redigeA: serializer.fromJson<DateTime>(json['redigeA']),
      tentatives: serializer.fromJson<int>(json['tentatives']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cleIdempotence': serializer.toJson<String>(cleIdempotence),
      'sessionId': serializer.toJson<String>(sessionId),
      'contenuJson': serializer.toJson<String>(contenuJson),
      'statut': serializer.toJson<String>(statut),
      'redigeA': serializer.toJson<DateTime>(redigeA),
      'tentatives': serializer.toJson<int>(tentatives),
    };
  }

  RapportsEnAttenteData copyWith({
    String? cleIdempotence,
    String? sessionId,
    String? contenuJson,
    String? statut,
    DateTime? redigeA,
    int? tentatives,
  }) => RapportsEnAttenteData(
    cleIdempotence: cleIdempotence ?? this.cleIdempotence,
    sessionId: sessionId ?? this.sessionId,
    contenuJson: contenuJson ?? this.contenuJson,
    statut: statut ?? this.statut,
    redigeA: redigeA ?? this.redigeA,
    tentatives: tentatives ?? this.tentatives,
  );
  RapportsEnAttenteData copyWithCompanion(RapportsEnAttenteCompanion data) {
    return RapportsEnAttenteData(
      cleIdempotence: data.cleIdempotence.present
          ? data.cleIdempotence.value
          : this.cleIdempotence,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      contenuJson: data.contenuJson.present
          ? data.contenuJson.value
          : this.contenuJson,
      statut: data.statut.present ? data.statut.value : this.statut,
      redigeA: data.redigeA.present ? data.redigeA.value : this.redigeA,
      tentatives: data.tentatives.present
          ? data.tentatives.value
          : this.tentatives,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RapportsEnAttenteData(')
          ..write('cleIdempotence: $cleIdempotence, ')
          ..write('sessionId: $sessionId, ')
          ..write('contenuJson: $contenuJson, ')
          ..write('statut: $statut, ')
          ..write('redigeA: $redigeA, ')
          ..write('tentatives: $tentatives')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cleIdempotence,
    sessionId,
    contenuJson,
    statut,
    redigeA,
    tentatives,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RapportsEnAttenteData &&
          other.cleIdempotence == this.cleIdempotence &&
          other.sessionId == this.sessionId &&
          other.contenuJson == this.contenuJson &&
          other.statut == this.statut &&
          other.redigeA == this.redigeA &&
          other.tentatives == this.tentatives);
}

class RapportsEnAttenteCompanion
    extends UpdateCompanion<RapportsEnAttenteData> {
  final Value<String> cleIdempotence;
  final Value<String> sessionId;
  final Value<String> contenuJson;
  final Value<String> statut;
  final Value<DateTime> redigeA;
  final Value<int> tentatives;
  final Value<int> rowid;
  const RapportsEnAttenteCompanion({
    this.cleIdempotence = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.contenuJson = const Value.absent(),
    this.statut = const Value.absent(),
    this.redigeA = const Value.absent(),
    this.tentatives = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RapportsEnAttenteCompanion.insert({
    required String cleIdempotence,
    required String sessionId,
    required String contenuJson,
    this.statut = const Value.absent(),
    required DateTime redigeA,
    this.tentatives = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cleIdempotence = Value(cleIdempotence),
       sessionId = Value(sessionId),
       contenuJson = Value(contenuJson),
       redigeA = Value(redigeA);
  static Insertable<RapportsEnAttenteData> custom({
    Expression<String>? cleIdempotence,
    Expression<String>? sessionId,
    Expression<String>? contenuJson,
    Expression<String>? statut,
    Expression<DateTime>? redigeA,
    Expression<int>? tentatives,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cleIdempotence != null) 'cle_idempotence': cleIdempotence,
      if (sessionId != null) 'session_id': sessionId,
      if (contenuJson != null) 'contenu_json': contenuJson,
      if (statut != null) 'statut': statut,
      if (redigeA != null) 'redige_a': redigeA,
      if (tentatives != null) 'tentatives': tentatives,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RapportsEnAttenteCompanion copyWith({
    Value<String>? cleIdempotence,
    Value<String>? sessionId,
    Value<String>? contenuJson,
    Value<String>? statut,
    Value<DateTime>? redigeA,
    Value<int>? tentatives,
    Value<int>? rowid,
  }) {
    return RapportsEnAttenteCompanion(
      cleIdempotence: cleIdempotence ?? this.cleIdempotence,
      sessionId: sessionId ?? this.sessionId,
      contenuJson: contenuJson ?? this.contenuJson,
      statut: statut ?? this.statut,
      redigeA: redigeA ?? this.redigeA,
      tentatives: tentatives ?? this.tentatives,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cleIdempotence.present) {
      map['cle_idempotence'] = Variable<String>(cleIdempotence.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (contenuJson.present) {
      map['contenu_json'] = Variable<String>(contenuJson.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (redigeA.present) {
      map['redige_a'] = Variable<DateTime>(redigeA.value);
    }
    if (tentatives.present) {
      map['tentatives'] = Variable<int>(tentatives.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RapportsEnAttenteCompanion(')
          ..write('cleIdempotence: $cleIdempotence, ')
          ..write('sessionId: $sessionId, ')
          ..write('contenuJson: $contenuJson, ')
          ..write('statut: $statut, ')
          ..write('redigeA: $redigeA, ')
          ..write('tentatives: $tentatives, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilsFoyerTable profilsFoyer = $ProfilsFoyerTable(this);
  late final $SessionsAVenirTable sessionsAVenir = $SessionsAVenirTable(this);
  late final $RessourcesHorsLigneTable ressourcesHorsLigne =
      $RessourcesHorsLigneTable(this);
  late final $PreferenceLocaleTable preferenceLocale = $PreferenceLocaleTable(
    this,
  );
  late final $RapportsEnAttenteTable rapportsEnAttente =
      $RapportsEnAttenteTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profilsFoyer,
    sessionsAVenir,
    ressourcesHorsLigne,
    preferenceLocale,
    rapportsEnAttente,
  ];
}

typedef $$ProfilsFoyerTableCreateCompanionBuilder =
    ProfilsFoyerCompanion Function({
      required String id,
      required String identifiantImmuable,
      required String prenom,
      Value<String> modeInterface,
      Value<String> politiqueCamera,
      Value<String?> cleAvatarCache,
      required DateTime synchroniseA,
      Value<int> rowid,
    });
typedef $$ProfilsFoyerTableUpdateCompanionBuilder =
    ProfilsFoyerCompanion Function({
      Value<String> id,
      Value<String> identifiantImmuable,
      Value<String> prenom,
      Value<String> modeInterface,
      Value<String> politiqueCamera,
      Value<String?> cleAvatarCache,
      Value<DateTime> synchroniseA,
      Value<int> rowid,
    });

class $$ProfilsFoyerTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilsFoyerTable> {
  $$ProfilsFoyerTableFilterComposer({
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

  ColumnFilters<String> get identifiantImmuable => $composableBuilder(
    column: $table.identifiantImmuable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prenom => $composableBuilder(
    column: $table.prenom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modeInterface => $composableBuilder(
    column: $table.modeInterface,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get politiqueCamera => $composableBuilder(
    column: $table.politiqueCamera,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cleAvatarCache => $composableBuilder(
    column: $table.cleAvatarCache,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get synchroniseA => $composableBuilder(
    column: $table.synchroniseA,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilsFoyerTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilsFoyerTable> {
  $$ProfilsFoyerTableOrderingComposer({
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

  ColumnOrderings<String> get identifiantImmuable => $composableBuilder(
    column: $table.identifiantImmuable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prenom => $composableBuilder(
    column: $table.prenom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modeInterface => $composableBuilder(
    column: $table.modeInterface,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get politiqueCamera => $composableBuilder(
    column: $table.politiqueCamera,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cleAvatarCache => $composableBuilder(
    column: $table.cleAvatarCache,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get synchroniseA => $composableBuilder(
    column: $table.synchroniseA,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilsFoyerTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilsFoyerTable> {
  $$ProfilsFoyerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get identifiantImmuable => $composableBuilder(
    column: $table.identifiantImmuable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prenom =>
      $composableBuilder(column: $table.prenom, builder: (column) => column);

  GeneratedColumn<String> get modeInterface => $composableBuilder(
    column: $table.modeInterface,
    builder: (column) => column,
  );

  GeneratedColumn<String> get politiqueCamera => $composableBuilder(
    column: $table.politiqueCamera,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cleAvatarCache => $composableBuilder(
    column: $table.cleAvatarCache,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get synchroniseA => $composableBuilder(
    column: $table.synchroniseA,
    builder: (column) => column,
  );
}

class $$ProfilsFoyerTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilsFoyerTable,
          ProfilsFoyerData,
          $$ProfilsFoyerTableFilterComposer,
          $$ProfilsFoyerTableOrderingComposer,
          $$ProfilsFoyerTableAnnotationComposer,
          $$ProfilsFoyerTableCreateCompanionBuilder,
          $$ProfilsFoyerTableUpdateCompanionBuilder,
          (
            ProfilsFoyerData,
            BaseReferences<_$AppDatabase, $ProfilsFoyerTable, ProfilsFoyerData>,
          ),
          ProfilsFoyerData,
          PrefetchHooks Function()
        > {
  $$ProfilsFoyerTableTableManager(_$AppDatabase db, $ProfilsFoyerTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilsFoyerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilsFoyerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilsFoyerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> identifiantImmuable = const Value.absent(),
                Value<String> prenom = const Value.absent(),
                Value<String> modeInterface = const Value.absent(),
                Value<String> politiqueCamera = const Value.absent(),
                Value<String?> cleAvatarCache = const Value.absent(),
                Value<DateTime> synchroniseA = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilsFoyerCompanion(
                id: id,
                identifiantImmuable: identifiantImmuable,
                prenom: prenom,
                modeInterface: modeInterface,
                politiqueCamera: politiqueCamera,
                cleAvatarCache: cleAvatarCache,
                synchroniseA: synchroniseA,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String identifiantImmuable,
                required String prenom,
                Value<String> modeInterface = const Value.absent(),
                Value<String> politiqueCamera = const Value.absent(),
                Value<String?> cleAvatarCache = const Value.absent(),
                required DateTime synchroniseA,
                Value<int> rowid = const Value.absent(),
              }) => ProfilsFoyerCompanion.insert(
                id: id,
                identifiantImmuable: identifiantImmuable,
                prenom: prenom,
                modeInterface: modeInterface,
                politiqueCamera: politiqueCamera,
                cleAvatarCache: cleAvatarCache,
                synchroniseA: synchroniseA,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilsFoyerTable, ProfilsFoyerData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProfilsFoyerTable,
                    ProfilsFoyerData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilsFoyerTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilsFoyerTable,
      ProfilsFoyerData,
      $$ProfilsFoyerTableFilterComposer,
      $$ProfilsFoyerTableOrderingComposer,
      $$ProfilsFoyerTableAnnotationComposer,
      $$ProfilsFoyerTableCreateCompanionBuilder,
      $$ProfilsFoyerTableUpdateCompanionBuilder,
      (
        ProfilsFoyerData,
        BaseReferences<_$AppDatabase, $ProfilsFoyerTable, ProfilsFoyerData>,
      ),
      ProfilsFoyerData,
      PrefetchHooks Function()
    >;
typedef $$SessionsAVenirTableCreateCompanionBuilder =
    SessionsAVenirCompanion Function({
      required String id,
      required DateTime debutUtc,
      required DateTime finUtc,
      required String statut,
      required String profilId,
      required String prenomEnseignant,
      required DateTime synchroniseA,
      Value<int> rowid,
    });
typedef $$SessionsAVenirTableUpdateCompanionBuilder =
    SessionsAVenirCompanion Function({
      Value<String> id,
      Value<DateTime> debutUtc,
      Value<DateTime> finUtc,
      Value<String> statut,
      Value<String> profilId,
      Value<String> prenomEnseignant,
      Value<DateTime> synchroniseA,
      Value<int> rowid,
    });

class $$SessionsAVenirTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsAVenirTable> {
  $$SessionsAVenirTableFilterComposer({
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

  ColumnFilters<DateTime> get debutUtc => $composableBuilder(
    column: $table.debutUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finUtc => $composableBuilder(
    column: $table.finUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profilId => $composableBuilder(
    column: $table.profilId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prenomEnseignant => $composableBuilder(
    column: $table.prenomEnseignant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get synchroniseA => $composableBuilder(
    column: $table.synchroniseA,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsAVenirTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsAVenirTable> {
  $$SessionsAVenirTableOrderingComposer({
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

  ColumnOrderings<DateTime> get debutUtc => $composableBuilder(
    column: $table.debutUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finUtc => $composableBuilder(
    column: $table.finUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profilId => $composableBuilder(
    column: $table.profilId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prenomEnseignant => $composableBuilder(
    column: $table.prenomEnseignant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get synchroniseA => $composableBuilder(
    column: $table.synchroniseA,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsAVenirTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsAVenirTable> {
  $$SessionsAVenirTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get debutUtc =>
      $composableBuilder(column: $table.debutUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get finUtc =>
      $composableBuilder(column: $table.finUtc, builder: (column) => column);

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<String> get profilId =>
      $composableBuilder(column: $table.profilId, builder: (column) => column);

  GeneratedColumn<String> get prenomEnseignant => $composableBuilder(
    column: $table.prenomEnseignant,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get synchroniseA => $composableBuilder(
    column: $table.synchroniseA,
    builder: (column) => column,
  );
}

class $$SessionsAVenirTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsAVenirTable,
          SessionsAVenirData,
          $$SessionsAVenirTableFilterComposer,
          $$SessionsAVenirTableOrderingComposer,
          $$SessionsAVenirTableAnnotationComposer,
          $$SessionsAVenirTableCreateCompanionBuilder,
          $$SessionsAVenirTableUpdateCompanionBuilder,
          (
            SessionsAVenirData,
            BaseReferences<
              _$AppDatabase,
              $SessionsAVenirTable,
              SessionsAVenirData
            >,
          ),
          SessionsAVenirData,
          PrefetchHooks Function()
        > {
  $$SessionsAVenirTableTableManager(
    _$AppDatabase db,
    $SessionsAVenirTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsAVenirTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsAVenirTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsAVenirTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> debutUtc = const Value.absent(),
                Value<DateTime> finUtc = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<String> profilId = const Value.absent(),
                Value<String> prenomEnseignant = const Value.absent(),
                Value<DateTime> synchroniseA = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsAVenirCompanion(
                id: id,
                debutUtc: debutUtc,
                finUtc: finUtc,
                statut: statut,
                profilId: profilId,
                prenomEnseignant: prenomEnseignant,
                synchroniseA: synchroniseA,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime debutUtc,
                required DateTime finUtc,
                required String statut,
                required String profilId,
                required String prenomEnseignant,
                required DateTime synchroniseA,
                Value<int> rowid = const Value.absent(),
              }) => SessionsAVenirCompanion.insert(
                id: id,
                debutUtc: debutUtc,
                finUtc: finUtc,
                statut: statut,
                profilId: profilId,
                prenomEnseignant: prenomEnseignant,
                synchroniseA: synchroniseA,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsAVenirTable, SessionsAVenirData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SessionsAVenirTable,
                    SessionsAVenirData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsAVenirTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsAVenirTable,
      SessionsAVenirData,
      $$SessionsAVenirTableFilterComposer,
      $$SessionsAVenirTableOrderingComposer,
      $$SessionsAVenirTableAnnotationComposer,
      $$SessionsAVenirTableCreateCompanionBuilder,
      $$SessionsAVenirTableUpdateCompanionBuilder,
      (
        SessionsAVenirData,
        BaseReferences<_$AppDatabase, $SessionsAVenirTable, SessionsAVenirData>,
      ),
      SessionsAVenirData,
      PrefetchHooks Function()
    >;
typedef $$RessourcesHorsLigneTableCreateCompanionBuilder =
    RessourcesHorsLigneCompanion Function({
      required String resourceId,
      required String versionId,
      required String cleCache,
      Value<bool> epinglee,
      required DateTime deposeeA,
      Value<int> rowid,
    });
typedef $$RessourcesHorsLigneTableUpdateCompanionBuilder =
    RessourcesHorsLigneCompanion Function({
      Value<String> resourceId,
      Value<String> versionId,
      Value<String> cleCache,
      Value<bool> epinglee,
      Value<DateTime> deposeeA,
      Value<int> rowid,
    });

class $$RessourcesHorsLigneTableFilterComposer
    extends Composer<_$AppDatabase, $RessourcesHorsLigneTable> {
  $$RessourcesHorsLigneTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versionId => $composableBuilder(
    column: $table.versionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cleCache => $composableBuilder(
    column: $table.cleCache,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get epinglee => $composableBuilder(
    column: $table.epinglee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deposeeA => $composableBuilder(
    column: $table.deposeeA,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RessourcesHorsLigneTableOrderingComposer
    extends Composer<_$AppDatabase, $RessourcesHorsLigneTable> {
  $$RessourcesHorsLigneTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versionId => $composableBuilder(
    column: $table.versionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cleCache => $composableBuilder(
    column: $table.cleCache,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get epinglee => $composableBuilder(
    column: $table.epinglee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deposeeA => $composableBuilder(
    column: $table.deposeeA,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RessourcesHorsLigneTableAnnotationComposer
    extends Composer<_$AppDatabase, $RessourcesHorsLigneTable> {
  $$RessourcesHorsLigneTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get versionId =>
      $composableBuilder(column: $table.versionId, builder: (column) => column);

  GeneratedColumn<String> get cleCache =>
      $composableBuilder(column: $table.cleCache, builder: (column) => column);

  GeneratedColumn<bool> get epinglee =>
      $composableBuilder(column: $table.epinglee, builder: (column) => column);

  GeneratedColumn<DateTime> get deposeeA =>
      $composableBuilder(column: $table.deposeeA, builder: (column) => column);
}

class $$RessourcesHorsLigneTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RessourcesHorsLigneTable,
          RessourcesHorsLigneData,
          $$RessourcesHorsLigneTableFilterComposer,
          $$RessourcesHorsLigneTableOrderingComposer,
          $$RessourcesHorsLigneTableAnnotationComposer,
          $$RessourcesHorsLigneTableCreateCompanionBuilder,
          $$RessourcesHorsLigneTableUpdateCompanionBuilder,
          (
            RessourcesHorsLigneData,
            BaseReferences<
              _$AppDatabase,
              $RessourcesHorsLigneTable,
              RessourcesHorsLigneData
            >,
          ),
          RessourcesHorsLigneData,
          PrefetchHooks Function()
        > {
  $$RessourcesHorsLigneTableTableManager(
    _$AppDatabase db,
    $RessourcesHorsLigneTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RessourcesHorsLigneTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RessourcesHorsLigneTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RessourcesHorsLigneTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> resourceId = const Value.absent(),
                Value<String> versionId = const Value.absent(),
                Value<String> cleCache = const Value.absent(),
                Value<bool> epinglee = const Value.absent(),
                Value<DateTime> deposeeA = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RessourcesHorsLigneCompanion(
                resourceId: resourceId,
                versionId: versionId,
                cleCache: cleCache,
                epinglee: epinglee,
                deposeeA: deposeeA,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String resourceId,
                required String versionId,
                required String cleCache,
                Value<bool> epinglee = const Value.absent(),
                required DateTime deposeeA,
                Value<int> rowid = const Value.absent(),
              }) => RessourcesHorsLigneCompanion.insert(
                resourceId: resourceId,
                versionId: versionId,
                cleCache: cleCache,
                epinglee: epinglee,
                deposeeA: deposeeA,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $RessourcesHorsLigneTable,
                    RessourcesHorsLigneData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RessourcesHorsLigneTable,
                    RessourcesHorsLigneData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RessourcesHorsLigneTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RessourcesHorsLigneTable,
      RessourcesHorsLigneData,
      $$RessourcesHorsLigneTableFilterComposer,
      $$RessourcesHorsLigneTableOrderingComposer,
      $$RessourcesHorsLigneTableAnnotationComposer,
      $$RessourcesHorsLigneTableCreateCompanionBuilder,
      $$RessourcesHorsLigneTableUpdateCompanionBuilder,
      (
        RessourcesHorsLigneData,
        BaseReferences<
          _$AppDatabase,
          $RessourcesHorsLigneTable,
          RessourcesHorsLigneData
        >,
      ),
      RessourcesHorsLigneData,
      PrefetchHooks Function()
    >;
typedef $$PreferenceLocaleTableCreateCompanionBuilder =
    PreferenceLocaleCompanion Function({
      required String clef,
      required String valeur,
      Value<int> rowid,
    });
typedef $$PreferenceLocaleTableUpdateCompanionBuilder =
    PreferenceLocaleCompanion Function({
      Value<String> clef,
      Value<String> valeur,
      Value<int> rowid,
    });

class $$PreferenceLocaleTableFilterComposer
    extends Composer<_$AppDatabase, $PreferenceLocaleTable> {
  $$PreferenceLocaleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clef => $composableBuilder(
    column: $table.clef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valeur => $composableBuilder(
    column: $table.valeur,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferenceLocaleTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferenceLocaleTable> {
  $$PreferenceLocaleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clef => $composableBuilder(
    column: $table.clef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valeur => $composableBuilder(
    column: $table.valeur,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferenceLocaleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferenceLocaleTable> {
  $$PreferenceLocaleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clef =>
      $composableBuilder(column: $table.clef, builder: (column) => column);

  GeneratedColumn<String> get valeur =>
      $composableBuilder(column: $table.valeur, builder: (column) => column);
}

class $$PreferenceLocaleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferenceLocaleTable,
          PreferenceLocaleData,
          $$PreferenceLocaleTableFilterComposer,
          $$PreferenceLocaleTableOrderingComposer,
          $$PreferenceLocaleTableAnnotationComposer,
          $$PreferenceLocaleTableCreateCompanionBuilder,
          $$PreferenceLocaleTableUpdateCompanionBuilder,
          (
            PreferenceLocaleData,
            BaseReferences<
              _$AppDatabase,
              $PreferenceLocaleTable,
              PreferenceLocaleData
            >,
          ),
          PreferenceLocaleData,
          PrefetchHooks Function()
        > {
  $$PreferenceLocaleTableTableManager(
    _$AppDatabase db,
    $PreferenceLocaleTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferenceLocaleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferenceLocaleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferenceLocaleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clef = const Value.absent(),
                Value<String> valeur = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferenceLocaleCompanion(
                clef: clef,
                valeur: valeur,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clef,
                required String valeur,
                Value<int> rowid = const Value.absent(),
              }) => PreferenceLocaleCompanion.insert(
                clef: clef,
                valeur: valeur,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferenceLocaleTable, PreferenceLocaleData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PreferenceLocaleTable,
                    PreferenceLocaleData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferenceLocaleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferenceLocaleTable,
      PreferenceLocaleData,
      $$PreferenceLocaleTableFilterComposer,
      $$PreferenceLocaleTableOrderingComposer,
      $$PreferenceLocaleTableAnnotationComposer,
      $$PreferenceLocaleTableCreateCompanionBuilder,
      $$PreferenceLocaleTableUpdateCompanionBuilder,
      (
        PreferenceLocaleData,
        BaseReferences<
          _$AppDatabase,
          $PreferenceLocaleTable,
          PreferenceLocaleData
        >,
      ),
      PreferenceLocaleData,
      PrefetchHooks Function()
    >;
typedef $$RapportsEnAttenteTableCreateCompanionBuilder =
    RapportsEnAttenteCompanion Function({
      required String cleIdempotence,
      required String sessionId,
      required String contenuJson,
      Value<String> statut,
      required DateTime redigeA,
      Value<int> tentatives,
      Value<int> rowid,
    });
typedef $$RapportsEnAttenteTableUpdateCompanionBuilder =
    RapportsEnAttenteCompanion Function({
      Value<String> cleIdempotence,
      Value<String> sessionId,
      Value<String> contenuJson,
      Value<String> statut,
      Value<DateTime> redigeA,
      Value<int> tentatives,
      Value<int> rowid,
    });

class $$RapportsEnAttenteTableFilterComposer
    extends Composer<_$AppDatabase, $RapportsEnAttenteTable> {
  $$RapportsEnAttenteTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cleIdempotence => $composableBuilder(
    column: $table.cleIdempotence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contenuJson => $composableBuilder(
    column: $table.contenuJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get redigeA => $composableBuilder(
    column: $table.redigeA,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tentatives => $composableBuilder(
    column: $table.tentatives,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RapportsEnAttenteTableOrderingComposer
    extends Composer<_$AppDatabase, $RapportsEnAttenteTable> {
  $$RapportsEnAttenteTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cleIdempotence => $composableBuilder(
    column: $table.cleIdempotence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contenuJson => $composableBuilder(
    column: $table.contenuJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get redigeA => $composableBuilder(
    column: $table.redigeA,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tentatives => $composableBuilder(
    column: $table.tentatives,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RapportsEnAttenteTableAnnotationComposer
    extends Composer<_$AppDatabase, $RapportsEnAttenteTable> {
  $$RapportsEnAttenteTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cleIdempotence => $composableBuilder(
    column: $table.cleIdempotence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get contenuJson => $composableBuilder(
    column: $table.contenuJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<DateTime> get redigeA =>
      $composableBuilder(column: $table.redigeA, builder: (column) => column);

  GeneratedColumn<int> get tentatives => $composableBuilder(
    column: $table.tentatives,
    builder: (column) => column,
  );
}

class $$RapportsEnAttenteTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RapportsEnAttenteTable,
          RapportsEnAttenteData,
          $$RapportsEnAttenteTableFilterComposer,
          $$RapportsEnAttenteTableOrderingComposer,
          $$RapportsEnAttenteTableAnnotationComposer,
          $$RapportsEnAttenteTableCreateCompanionBuilder,
          $$RapportsEnAttenteTableUpdateCompanionBuilder,
          (
            RapportsEnAttenteData,
            BaseReferences<
              _$AppDatabase,
              $RapportsEnAttenteTable,
              RapportsEnAttenteData
            >,
          ),
          RapportsEnAttenteData,
          PrefetchHooks Function()
        > {
  $$RapportsEnAttenteTableTableManager(
    _$AppDatabase db,
    $RapportsEnAttenteTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RapportsEnAttenteTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RapportsEnAttenteTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RapportsEnAttenteTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cleIdempotence = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> contenuJson = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<DateTime> redigeA = const Value.absent(),
                Value<int> tentatives = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RapportsEnAttenteCompanion(
                cleIdempotence: cleIdempotence,
                sessionId: sessionId,
                contenuJson: contenuJson,
                statut: statut,
                redigeA: redigeA,
                tentatives: tentatives,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cleIdempotence,
                required String sessionId,
                required String contenuJson,
                Value<String> statut = const Value.absent(),
                required DateTime redigeA,
                Value<int> tentatives = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RapportsEnAttenteCompanion.insert(
                cleIdempotence: cleIdempotence,
                sessionId: sessionId,
                contenuJson: contenuJson,
                statut: statut,
                redigeA: redigeA,
                tentatives: tentatives,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RapportsEnAttenteTable, RapportsEnAttenteData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $RapportsEnAttenteTable,
                    RapportsEnAttenteData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RapportsEnAttenteTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RapportsEnAttenteTable,
      RapportsEnAttenteData,
      $$RapportsEnAttenteTableFilterComposer,
      $$RapportsEnAttenteTableOrderingComposer,
      $$RapportsEnAttenteTableAnnotationComposer,
      $$RapportsEnAttenteTableCreateCompanionBuilder,
      $$RapportsEnAttenteTableUpdateCompanionBuilder,
      (
        RapportsEnAttenteData,
        BaseReferences<
          _$AppDatabase,
          $RapportsEnAttenteTable,
          RapportsEnAttenteData
        >,
      ),
      RapportsEnAttenteData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilsFoyerTableTableManager get profilsFoyer =>
      $$ProfilsFoyerTableTableManager(_db, _db.profilsFoyer);
  $$SessionsAVenirTableTableManager get sessionsAVenir =>
      $$SessionsAVenirTableTableManager(_db, _db.sessionsAVenir);
  $$RessourcesHorsLigneTableTableManager get ressourcesHorsLigne =>
      $$RessourcesHorsLigneTableTableManager(_db, _db.ressourcesHorsLigne);
  $$PreferenceLocaleTableTableManager get preferenceLocale =>
      $$PreferenceLocaleTableTableManager(_db, _db.preferenceLocale);
  $$RapportsEnAttenteTableTableManager get rapportsEnAttente =>
      $$RapportsEnAttenteTableTableManager(_db, _db.rapportsEnAttente);
}
