import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Les profils du foyer, consultables hors ligne.
///
/// Miroir **partiel** de `profiles` et `student_profiles`. Aucune colonne
/// sensible n'est recopiee : ni nom de famille expose a un tiers, ni courriel,
/// ni telephone. Le cache local ne peut pas fuiter ce qu'il ne contient pas.
class ProfilsFoyer extends Table {
  /// Identifiant du profil, identique a celui de la base.
  TextColumn get id => text()();

  /// Identifiant immuable, celui qu'un enseignant voit.
  TextColumn get identifiantImmuable => text()();

  /// Prenom.
  TextColumn get prenom => text()();

  /// Mode d'interface, valeur SQL (`child` ou `standard`).
  TextColumn get modeInterface =>
      text().withDefault(const Constant('standard'))();

  /// Politique camera, valeur SQL (`allowed` ou `forbidden`).
  TextColumn get politiqueCamera =>
      text().withDefault(const Constant('forbidden'))();

  /// Cle du fichier avatar dans le cache media. Jamais l'URL signee, qui
  /// expire, ni l'original, qui n'est jamais transporte (ADR-012).
  TextColumn get cleAvatarCache => text().nullable()();

  /// Derniere synchronisation.
  DateTimeColumn get synchroniseA => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Les seances a venir sur sept jours glissants.
///
/// Sept jours, pas l'historique complet : le cache local sert a consulter son
/// planning sans reseau, pas a dupliquer la base.
class SessionsAVenir extends Table {
  /// Identifiant de la seance.
  TextColumn get id => text()();

  /// Debut, en UTC. Le fuseau est une donnee d'affichage.
  DateTimeColumn get debutUtc => dateTime()();

  /// Fin, en UTC.
  DateTimeColumn get finUtc => dateTime()();

  /// Statut, valeur SQL de `public.session_status`.
  TextColumn get statut => text()();

  /// Profil du foyer concerne.
  TextColumn get profilId => text()();

  /// Prenom de l'enseignant. Prenom seul, jamais le nom complet.
  TextColumn get prenomEnseignant => text()();

  /// Derniere synchronisation.
  DateTimeColumn get synchroniseA => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Index des pages du mushaf deja consultees.
///
/// L'index seulement : les octets de la page vivent dans le cache media, pas
/// en base locale.
class PagesMushafConsultees extends Table {
  /// Numero de page du mushaf.
  IntColumn get numeroPage => integer()();

  /// Cle du fichier dans le cache media.
  TextColumn get cleCache => text()();

  /// Derniere consultation. Sert a la purge par anciennete.
  DateTimeColumn get consulteeA => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{numeroPage};
}

/// File d'attente des cahiers de transmission non encore synchronises.
///
/// Seul besoin d'ecriture hors ligne reel du produit. Chaque rapport recoit une
/// cle d'idempotence generee **localement**, ecrite ici avec le statut
/// `en_attente`, puis rejouee au retour du reseau. La contrainte d'unicite C9
/// de l'etape 1 tranche en base si la synchronisation part deux fois.
class RapportsEnAttente extends Table {
  /// Cle d'idempotence, generee localement, jamais reattribuee.
  TextColumn get cleIdempotence => text()();

  /// Seance concernee.
  TextColumn get sessionId => text()();

  /// Contenu du rapport, tel qu'il sera envoye.
  TextColumn get contenuJson => text()();

  /// Statut local : `en_attente`, `envoi`, `envoye`.
  TextColumn get statut => text().withDefault(const Constant('en_attente'))();

  /// Date de redaction.
  DateTimeColumn get redigeA => dateTime()();

  /// Nombre de tentatives d'envoi.
  IntColumn get tentatives => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{cleIdempotence};
}

/// La base locale.
///
/// **Exactement quatre tables, ni plus ni moins**
/// (`docs/architecture/etape-2-core-flutter.md` section 4). Toute table
/// supplementaire doit d'abord etre justifiee dans la specification : un cache
/// qui grossit sans regle finit par recopier la base et par en heriter les
/// obligations de protection.
@DriftDatabase(
  tables: <Type>[
    ProfilsFoyer,
    SessionsAVenir,
    PagesMushafConsultees,
    RapportsEnAttente,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Ouvre la base locale de l'appareil.
  AppDatabase() : super(driftDatabase(name: 'rewayah_local'));

  /// Ouvre une base sur un executeur fourni. Reserve aux tests.
  AppDatabase.surExecuteur(super.executeur);

  @override
  int get schemaVersion => 1;
}
