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

/// Index local des ressources conservees hors ligne (Teaching Core, Agent B).
///
/// Persiste ce que `CacheMediaFichiers` ne pouvait garder qu'en memoire : sans
/// cette table, une ressource "Telechargee" repassait a "A telecharger" au
/// lancement suivant, parce qu'aucune cle ne survivait au redemarrage.
class RessourcesHorsLigne extends Table {
  /// Identifiant de la ressource (`library_resource.id`).
  TextColumn get resourceId => text()();

  /// Version telechargee (`resource_version.id`).
  TextColumn get versionId => text()();

  /// Cle du fichier dans le cache media.
  TextColumn get cleCache => text()();

  /// Epinglee : ne participe pas a la purge automatique.
  BoolColumn get epinglee => boolean().withDefault(const Constant(false))();

  /// Date de depot local.
  DateTimeColumn get deposeeA => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{resourceId};
}

/// Preferences locales durables, en clef/valeur (Teaching Core, Agent D).
///
/// Remplace la discussion "table dediee ou `shared_preferences`" : D n'a pas
/// demande la dependance, et ce mecanisme existe deja. Premier usage : la
/// position du dock d'outils (bas/gauche/droite) ; ouvert a tout autre
/// agent qui a besoin d'une preference d'affichage durable et non sensible.
class PreferenceLocale extends Table {
  /// La clef, par exemple `dock.position`.
  TextColumn get clef => text()();

  /// La valeur, en texte brut.
  TextColumn get valeur => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{clef};
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
/// Cinq tables (`docs/archive/2026-09-pre-remise-a-plat/architecture/etape-2-core-flutter.md` section 4, mis a
/// jour au schema 2). Toute table supplementaire doit d'abord etre justifiee
/// dans la specification : un cache qui grossit sans regle finit par recopier
/// la base et par en heriter les obligations de protection.
///
/// Schema 2 (Teaching Core) : `PagesMushafConsultees` est supprimee -- table
/// generee mais jamais lue ni ecrite depuis sa creation, et son modele
/// page-image est de toute facon incompatible avec le rendu texte structure
/// retenu pour le Coran (arbitrage produit du 20/09, aucune police QCF).
/// `RessourcesHorsLigne` (Agent B) et `PreferenceLocale` (Agent D) la
/// remplacent dans le schema, sans rapport l'une a l'autre.
@DriftDatabase(
  tables: <Type>[
    ProfilsFoyer,
    SessionsAVenir,
    RessourcesHorsLigne,
    PreferenceLocale,
    RapportsEnAttente,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Ouvre la base locale de l'appareil.
  AppDatabase() : super(driftDatabase(name: 'rewayah_local'));

  /// Ouvre une base sur un executeur fourni. Reserve aux tests.
  AppDatabase.surExecuteur(super.executeur);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.deleteTable('pages_mushaf_consultees');
        await m.createTable(ressourcesHorsLigne);
        await m.createTable(preferenceLocale);
      }
    },
  );
}
