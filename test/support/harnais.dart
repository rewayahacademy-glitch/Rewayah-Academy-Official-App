import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, alors que `ProviderScope.overrides` en attend une liste.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/appairage/service_enfant.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/cache/secure/stockage_securise.dart';
import 'package:rewayah_academy/core/cache/sync/file_rapports.dart';
import 'package:rewayah_academy/core/capacites/port_consentements.dart';
import 'package:rewayah_academy/core/controle/service_controle.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/journal/service_journal.dart';
import 'package:rewayah_academy/core/matching/service_attribution.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/reglages_priere.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

/// L'hote minimal d'un ecran sous test.
///
/// Le theme est indispensable : `AppPalette.of` et `AppMetriques.of` lisent des
/// extensions de theme, et un ecran monte sans elles echoue avant d'avoir rendu
/// quoi que ce soit.
Widget hote(
  Widget enfant, {
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(mode, Brightness.light),
      home: enfant,
    ),
  ),
);

/// L'hote d'un ecran qui navigue.
///
/// Certains ecrans de l'etape 3 se terminent par un `go` vers le portail : sans
/// routeur, ils echouent au moment ou l'on teste justement ce qu'ils font de
/// reussi. Le routeur du test reste minimal, il ne rejoue pas celui de
/// l'application.
Widget hoteRoutant({
  required String depart,
  required List<RouteBase> routes,
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp.router(
      theme: AppTheme.pour(mode, Brightness.light),
      routerConfig: GoRouter(initialLocation: depart, routes: routes),
    ),
  ),
);

/// Un service de dossier en memoire.
class FauxServiceDossier implements ServiceDossier {
  /// Ce que [etat] renverra.
  EtatDossier etatRendu = const EtatDossier.sansProfil();

  /// Ce que la prochaine operation doit jeter, quand on teste un echec.
  Object? erreurAJeter;

  /// Les profils demandes.
  final List<({AppRole role, String prenom, String nom, Genre? genre})>
  profilsCrees = <({AppRole role, String prenom, String nom, Genre? genre})>[];

  /// Les contrats acceptes.
  final List<SorteContrat> contratsAcceptes = <SorteContrat>[];

  /// Les pieces deposees.
  final List<PieceAEnvoyer> depots = <PieceAEnvoyer>[];

  void _peutEchouer() {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // Volontairement un Object : le vrai client jette aussi bien une
      // PostgrestException qu'une erreur de plateforme, et l'ecran doit se
      // comporter pareil dans les deux cas. Restreindre ce type ici testerait
      // moins que ce qui arrive en production.
      // ignore: only_throw_errors
      throw erreur;
    }
  }

  @override
  Future<void> creerProfil({
    required AppRole role,
    required String prenom,
    required String nom,
    Genre? genre,
  }) async {
    _peutEchouer();
    profilsCrees.add((role: role, prenom: prenom, nom: nom, genre: genre));
  }

  @override
  Future<EtatDossier> etat() async {
    _peutEchouer();
    return etatRendu;
  }

  @override
  Future<void> accepterContrat(SorteContrat sorte, String version) async {
    _peutEchouer();
    contratsAcceptes.add(sorte);
  }

  @override
  Future<void> deposerPiece(PieceAEnvoyer piece) async {
    _peutEchouer();
    depots.add(piece);
  }
}

/// Une source de session figee.
class FausseSourceSession implements SourceSession {
  /// Cree la source sur un etat donne.
  FausseSourceSession([this.etat = const SessionState.deconnecte()]);

  /// L'etat rendu.
  SessionState etat;

  /// Le nombre de rafraichissements demandes. C'est ce qui prouve que le jeton
  /// est bien redemande apres la creation du profil.
  int rafraichissements = 0;

  @override
  Stream<SessionState> etats() => Stream<SessionState>.value(etat);

  @override
  Future<void> rafraichir() async {
    rafraichissements++;
  }
}

/// Un service d'authentification en memoire.
class FauxServiceAuth implements ServiceAuth {
  /// Les adresses auxquelles un lien a ete demande.
  final List<String> liensEnvoyes = <String>[];

  /// Le nombre d'ouvertures du parcours Google.
  int google = 0;

  /// Les identifiants utilises pour une connexion de demonstration.
  final List<({String courriel, String motDePasse})> connexionsMotDePasse =
      <({String courriel, String motDePasse})>[];

  /// Le nombre de deconnexions.
  int deconnexions = 0;

  /// Ce que la prochaine operation doit jeter.
  Object? erreurAJeter;

  @override
  Future<void> envoyerLienCourriel(String courriel) async {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // Volontairement un Object : le vrai client jette aussi bien une
      // PostgrestException qu'une erreur de plateforme, et l'ecran doit se
      // comporter pareil dans les deux cas. Restreindre ce type ici testerait
      // moins que ce qui arrive en production.
      // ignore: only_throw_errors
      throw erreur;
    }
    liensEnvoyes.add(courriel.trim());
  }

  @override
  Future<void> connexionGoogle() async {
    google++;
  }

  @override
  Future<void> connexionMotDePasse(String courriel, String motDePasse) async {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    connexionsMotDePasse.add((
      courriel: courriel.trim(),
      motDePasse: motDePasse,
    ));
  }

  @override
  Future<void> deconnexion() async {
    deconnexions++;
  }
}

/// Un service d'appairage en memoire.
class FauxServiceAppairage implements ServiceAppairage {
  /// Les eleves rendus.
  List<EleveDuFoyer> elevesRendus = const <EleveDuFoyer>[];

  /// Les appareils rendus.
  List<AppareilAppaire> appareilsRendus = const <AppareilAppaire>[];

  /// Les codes demandes, par eleve.
  final List<String> codesDemandes = <String>[];

  /// Les appareils revoques.
  final List<String> revocations = <String>[];

  /// Les enfants crees.
  final List<({String prenom, String nom, int age})> enfantsCrees =
      <({String prenom, String nom, int age})>[];

  /// Les reglages ecrits, dans l'ordre.
  ///
  /// C'est ce qui permet de mesurer l'invariant I6 cote ecran : `TUT-05`
  /// n'envoie que ce qui change, et jamais une colonne pedagogique.
  final List<
    ({
      String eleveId,
      InterfaceMode? mode,
      CameraPolicy? camera,
      String? cleAvatar,
    })
  >
  reglagesEcrits =
      <
        ({
          String eleveId,
          InterfaceMode? mode,
          CameraPolicy? camera,
          String? cleAvatar,
        })
      >[];

  /// Ce que la prochaine operation doit jeter.
  Object? erreurAJeter;

  /// Le code rendu par [creerCode].
  CodeAppairage code = CodeAppairage(
    code: 'AB23CD',
    expireA: DateTime.now().add(const Duration(minutes: 10)),
  );

  void _peutEchouer() {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
  }

  @override
  Future<List<EleveDuFoyer>> eleves() async => elevesRendus;

  @override
  Future<List<AppareilAppaire>> appareils() async => appareilsRendus;

  @override
  Future<CodeAppairage> creerCode(String eleveId) async {
    _peutEchouer();
    codesDemandes.add(eleveId);
    return code;
  }

  @override
  Future<void> revoquer(String appareilId) async {
    _peutEchouer();
    revocations.add(appareilId);
  }

  @override
  Future<void> creerEnfant({
    required String prenom,
    required String nom,
    required int age,
    String? niveau,
  }) async {
    _peutEchouer();
    enfantsCrees.add((prenom: prenom, nom: nom, age: age));
  }

  @override
  Future<void> majReglages({
    required String eleveId,
    InterfaceMode? mode,
    CameraPolicy? camera,
    String? cleAvatar,
  }) async {
    _peutEchouer();
    reglagesEcrits.add((
      eleveId: eleveId,
      mode: mode,
      camera: camera,
      cleAvatar: cleAvatar,
    ));
    // Le faux relit ce qu'il a ecrit, comme la base : l'ecran n'a aucun etat
    // local, il reaffiche ce que la lecture rend.
    elevesRendus = <EleveDuFoyer>[
      for (final EleveDuFoyer eleve in elevesRendus)
        if (eleve.id != eleveId)
          eleve
        else
          EleveDuFoyer(
            id: eleve.id,
            prenom: eleve.prenom,
            identifiantImmuable: eleve.identifiantImmuable,
            mode: mode ?? eleve.mode,
            camera: camera ?? eleve.camera,
            cleAvatar: cleAvatar ?? eleve.cleAvatar,
            finAcces: eleve.finAcces,
          ),
    ];
  }
}

/// Un service de photos en memoire.
///
/// Aucun test ne peut deposer un fichier dans un seau de stockage : sans ce
/// faux, le premier des trois reglages de `TUT-05` ne serait pas mesurable.
class FauxServiceAvatar implements ServiceAvatar {
  /// Les photos deposees, dans l'ordre.
  final List<({String eleveId, PhotoEnfant photo})> depots =
      <({String eleveId, PhotoEnfant photo})>[];

  /// Ce que le depot doit jeter.
  Object? erreurAJeter;

  @override
  Future<String> televerser({
    required String eleveId,
    required PhotoEnfant photo,
  }) async {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    depots.add((eleveId: eleveId, photo: photo));
    return '$eleveId/${depots.length}.${photo.extension}';
  }

  @override
  Future<String> urlSignee(String cleAvatar) async =>
      'https://exemple.test/$cleAvatar';
}

/// Un selecteur de photo qui rend toujours la meme image.
class FauxSelecteurPhoto implements SelecteurPhoto {
  /// Cree le selecteur.
  FauxSelecteurPhoto(this.reponse);

  /// Ce que le selecteur rendra. `null` simule un abandon.
  PhotoEnfant? reponse;

  @override
  Future<PhotoEnfant?> choisirPhoto() async => reponse;
}

/// Un service de validation en memoire.
class FauxServiceValidation implements ServiceValidation {
  /// La file rendue.
  List<DossierAValider> file = const <DossierAValider>[];

  /// Ce que la lecture de la file doit jeter.
  Object? erreurFile;

  /// Les verdicts rendus.
  final List<({String documentId, bool approuve, String? motif})> verdicts =
      <({String documentId, bool approuve, String? motif})>[];

  @override
  Future<List<DossierAValider>> enAttente() async {
    final Object? erreur = erreurFile;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return file;
  }

  /// Les cles signees, dans l'ordre (AD-7).
  final List<String> apercus = <String>[];

  /// Ce que la signature doit jeter (AD-7 : StorageException 404...).
  Object? erreurApercu;

  @override
  Future<String> apercu(String cleObjet) async {
    apercus.add(cleObjet);
    final Object? erreur = erreurApercu;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return 'https://exemple.test/$cleObjet';
  }

  @override
  Future<void> decider({
    required String documentId,
    required bool approuve,
    String? motif,
  }) async {
    verdicts.add((documentId: documentId, approuve: approuve, motif: motif));
  }
}

/// Un service de planning en memoire.
class FauxServicePlanning implements ServicePlanning {
  /// Les creneaux rendus, par profil.
  final Map<String, List<Creneau>> creneaux = <String, List<Creneau>>{};

  /// Les seances rendues.
  List<Seance> seancesRendues = const <Seance>[];

  /// Les affectations rendues.
  List<Affectation> affectationsRendues = const <Affectation>[];

  /// Le fuseau rendu.
  String fuseau = 'Europe/Paris';

  /// Les creneaux poses, dans l'ordre.
  final List<({String profilId, Creneau creneau})> poses =
      <({String profilId, Creneau creneau})>[];

  /// Les creneaux retires, dans l'ordre.
  final List<({String profilId, Creneau creneau})> retires =
      <({String profilId, Creneau creneau})>[];

  /// Ce que la prochaine ecriture doit jeter.
  Object? erreurAJeter;

  void _peutEchouer() {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
  }

  @override
  Future<String> monFuseau() async => fuseau;

  @override
  Future<List<Creneau>> disponibilites(String profilId) async =>
      creneaux[profilId] ?? const <Creneau>[];

  @override
  Future<void> poser({
    required String profilId,
    required Creneau creneau,
  }) async {
    _peutEchouer();
    poses.add((profilId: profilId, creneau: creneau));
    creneaux.putIfAbsent(profilId, () => <Creneau>[]).add(creneau);
  }

  @override
  Future<void> retirer({
    required String profilId,
    required Creneau creneau,
  }) async {
    _peutEchouer();
    retires.add((profilId: profilId, creneau: creneau));
    creneaux[profilId]?.removeWhere(
      (Creneau c) => c.jour == creneau.jour && c.heure == creneau.heure,
    );
  }

  @override
  Future<List<Seance>> seances() async => seancesRendues;

  @override
  Future<List<Affectation>> affectations() async => affectationsRendues;
}

/// Un service de matching en memoire.
class FauxServiceMatching implements ServiceMatching {
  /// Le feed rendu.
  List<EleveEnAttente> feed = const <EleveEnAttente>[];

  /// Les prises demandees.
  final List<({String eleveId, Creneau creneau})> prises =
      <({String eleveId, Creneau creneau})>[];

  /// Les demandes deposees.
  final List<({SorteDemande sorte, String sujetId, String motif, int? valeur})>
  demandes =
      <({SorteDemande sorte, String sujetId, String motif, int? valeur})>[];

  /// Ce que la prochaine prise doit jeter.
  Object? erreurPrise;

  @override
  Future<List<EleveEnAttente>> elevesEnAttente() async => feed;

  @override
  Future<void> prendre({
    required String eleveId,
    required Creneau creneau,
  }) async {
    final Object? erreur = erreurPrise;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    prises.add((eleveId: eleveId, creneau: creneau));
  }

  @override
  Future<void> demander({
    required SorteDemande sorte,
    required String sujetId,
    required String motif,
    CleRegle? cle,
    int? valeur,
  }) async {
    demandes.add((
      sorte: sorte,
      sujetId: sujetId,
      motif: motif,
      valeur: valeur,
    ));
  }
}

/// Un service d'administration en memoire.
///
/// Le dernier des sept services a en recevoir un : personne n'en avait eu
/// besoin avant `ADM-01`, dont le scenario 11 se mesure precisement par un test
/// de widget.
class FauxServiceAdmin implements ServiceAdmin {
  /// Les six compteurs rendus. **Tous a zero par defaut**, parce que c'est
  /// l'etat que l'invariant I9 demande de savoir afficher.
  IndicateursAdmin indicateursRendus = const IndicateursAdmin(
    dossiersEnAttente: 0,
    foyersSansEnseignant: 0,
    rapportsManquants: 0,
    incidents24h: 0,
    comptesEchus: 0,
    demandesEnAttente: 0,
  );

  /// La file rendue.
  List<Demande> file = const <Demande>[];

  /// Ce que la lecture des compteurs doit jeter.
  Object? erreurIndicateurs;

  /// Ce que la lecture de la file doit jeter.
  Object? erreurFile;

  /// Les verdicts rendus, dans l'ordre.
  final List<({String demandeId, bool accepte, String? motif})> verdicts =
      <({String demandeId, bool accepte, String? motif})>[];

  @override
  Future<IndicateursAdmin> indicateurs() async {
    final Object? erreur = erreurIndicateurs;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return indicateursRendus;
  }

  @override
  Future<List<Demande>> demandesEnAttente() async {
    final Object? erreur = erreurFile;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return file;
  }

  @override
  Future<void> decider({
    required String demandeId,
    required bool accepte,
    String? motif,
  }) async {
    verdicts.add((demandeId: demandeId, accepte: accepte, motif: motif));
  }
}

/// Un service d'attribution en memoire.
///
/// `ADM-05` est le seul ecran du produit dont les deux listes viennent de deux
/// lectures distinctes : sans ce faux, on ne pourrait mesurer ni l'ordre de la
/// file, ni le motif exige hors disponibilite.
class FauxServiceAttribution implements ServiceAttribution {
  /// La colonne de gauche.
  List<FoyerEnAttente> foyers = const <FoyerEnAttente>[];

  /// La colonne de droite, par eleve.
  final Map<String, List<EnseignantCandidat>> enseignants =
      <String, List<EnseignantCandidat>>{};

  /// Les attributions demandees, dans l'ordre.
  final List<
    ({String eleveId, String enseignantId, Creneau creneau, String? motif})
  >
  attributions =
      <
        ({String eleveId, String enseignantId, Creneau creneau, String? motif})
      >[];

  /// Ce que la lecture de la file doit jeter.
  Object? erreurFoyers;

  /// Ce que la lecture des enseignants doit jeter.
  Object? erreurEnseignants;

  /// Ce que la prochaine attribution doit jeter.
  Object? erreurAttribution;

  /// Le temps que prend une lecture.
  ///
  /// Sans lui, aucun test ne peut regarder l'ecran **pendant** le chargement :
  /// un faux qui rend tout de suite resout son futur dans la micro-tache que le
  /// premier `pump` vide, et l'etat d'attente n'existe jamais.
  Duration delai = Duration.zero;

  Future<void> _attendre() async {
    if (delai > Duration.zero) {
      await Future<void>.delayed(delai);
    }
  }

  @override
  Future<List<FoyerEnAttente>> foyersEnAttente() async {
    await _attendre();
    final Object? erreur = erreurFoyers;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return foyers;
  }

  @override
  Future<List<EnseignantCandidat>> enseignantsPour(String eleveId) async {
    await _attendre();
    final Object? erreur = erreurEnseignants;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return enseignants[eleveId] ?? const <EnseignantCandidat>[];
  }

  @override
  Future<void> attribuer({
    required String eleveId,
    required String enseignantId,
    required Creneau creneau,
    String? motif,
  }) async {
    final Object? erreur = erreurAttribution;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    attributions.add((
      eleveId: eleveId,
      enseignantId: enseignantId,
      creneau: creneau,
      motif: motif,
    ));
    // Le faux relit ce qu'il a ecrit, comme la base : l'eleve attribue quitte
    // la file, et c'est ce que l'ecran doit refleter sans etat local.
    foyers = foyers.where((FoyerEnAttente f) => f.eleveId != eleveId).toList();
  }
}

/// Un journal d'audit en memoire.
///
/// Il **pagine pour de vrai** plutot que de rendre tout d'un coup : `ADM-04`
/// est le premier ecran du produit dont la liste n'a pas de fin, et un faux qui
/// ignorerait le curseur laisserait le bouton « charger la suite » non mesure.
class FauxServiceJournal implements ServiceJournal {
  /// Le journal, le plus recent d'abord. L'ordre est celui de la base.
  List<EntreeJournal> entreesEnBase = const <EntreeJournal>[];

  /// Ce que les filtres proposent.
  FiltresJournal filtres0 = const FiltresJournal(
    actions: <ValeurFiltre>[],
    acteurs: <ValeurFiltre>[],
    total: 0,
  );

  /// Le verdict de la chaine.
  EtatChaine chaine = const EtatChaine(verifiees: 0, rompues: 0);

  /// Les lectures demandees, dans l'ordre. C'est par elles qu'un test verifie
  /// qu'un changement de filtre a bien relu depuis le debut.
  final List<
    ({String? acteur, String? type, DateTime? depuis, CurseurJournal? curseur})
  >
  lectures =
      <
        ({
          String? acteur,
          String? type,
          DateTime? depuis,
          CurseurJournal? curseur,
        })
      >[];

  /// Ce que la lecture doit jeter.
  Object? erreurEntrees;

  /// Ce que la verification de chaine doit jeter.
  Object? erreurChaine;

  /// Le temps que prend une lecture.
  Duration delai = Duration.zero;

  @override
  Future<List<EntreeJournal>> entrees({
    String? acteur,
    String? typeEvenement,
    DateTime? depuis,
    int limite = 50,
    CurseurJournal? curseur,
  }) async {
    lectures.add((
      acteur: acteur,
      type: typeEvenement,
      depuis: depuis,
      curseur: curseur,
    ));
    if (delai > Duration.zero) {
      await Future<void>.delayed(delai);
    }
    final Object? erreur = erreurEntrees;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }

    Iterable<EntreeJournal> retenues = entreesEnBase;
    if (acteur != null) {
      retenues = retenues.where((EntreeJournal e) => e.acteur == acteur);
    }
    if (typeEvenement != null) {
      retenues = retenues.where(
        (EntreeJournal e) => e.typeEvenement == typeEvenement,
      );
    }
    if (depuis != null) {
      retenues = retenues.where(
        (EntreeJournal e) => !e.survenuLe.isBefore(depuis),
      );
    }
    if (curseur != null) {
      // Le meme keyset que la base : strictement avant le couple donne.
      retenues = retenues.where(
        (EntreeJournal e) =>
            e.survenuLe.isBefore(curseur.avantDate) ||
            (e.survenuLe.isAtSameMomentAs(curseur.avantDate) &&
                e.id < curseur.avantId),
      );
    }
    return retenues.take(limite).toList();
  }

  @override
  Future<FiltresJournal> filtres() async {
    if (delai > Duration.zero) {
      await Future<void>.delayed(delai);
    }
    return filtres0;
  }

  @override
  Future<EtatChaine> verifierChaine({int limite = 200}) async {
    if (delai > Duration.zero) {
      await Future<void>.delayed(delai);
    }
    final Object? erreur = erreurChaine;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return chaine;
  }
}

/// Un service de regles en memoire.
class FauxServiceRegles implements ServiceRegles {
  /// Les regles rendues, par profil.
  final Map<String, List<RegleProfil>> parProfil =
      <String, List<RegleProfil>>{};

  /// Les surcharges closes rendues, par profil.
  final Map<String, List<SurchargeClose>> historiqueParProfil =
      <String, List<SurchargeClose>>{};

  /// Les regles posees.
  final List<({String profilId, CleRegle cle, int valeur, String motif})>
  posees = <({String profilId, CleRegle cle, int valeur, String motif})>[];

  /// Les surcharges closes.
  final List<String> closes = <String>[];

  @override
  Future<int> valeur(String profilId, CleRegle cle) async =>
      (parProfil[profilId] ?? const <RegleProfil>[])
          .firstWhere(
            (RegleProfil r) => r.cle == cle,
            orElse: () => const RegleProfil(
              cle: null,
              valeurEffective: 0,
              valeurPlateforme: 0,
            ),
          )
          .valeurEffective;

  @override
  Future<List<RegleProfil>> regles(String profilId) async =>
      parProfil[profilId] ?? const <RegleProfil>[];

  @override
  Future<List<SurchargeClose>> historique(String profilId) async =>
      historiqueParProfil[profilId] ?? const <SurchargeClose>[];

  @override
  Future<void> poser({
    required String profilId,
    required CleRegle cle,
    required int valeur,
    required String motif,
  }) async {
    posees.add((profilId: profilId, cle: cle, valeur: valeur, motif: motif));
  }

  @override
  Future<void> clore({
    required String surchargeId,
    required String motif,
  }) async {
    closes.add(surchargeId);
  }
}

/// Un service de prieres en memoire.
class FauxServicePriere implements ServicePriere {
  /// Les reglages rendus, par enseignant.
  final Map<String, ReglagesPriere> parEnseignant = <String, ReglagesPriere>{};

  /// Les reglages enregistres, dans l'ordre.
  final List<ReglagesPriere> enregistres = <ReglagesPriere>[];

  @override
  Future<ReglagesPriere?> reglages(String enseignantId) async =>
      parEnseignant[enseignantId];

  @override
  Future<void> enregistrer(ReglagesPriere reglages) async {
    enregistres.add(reglages);
    parEnseignant[reglages.enseignantId] = reglages;
  }
}

/// Un etat de reseau fige.
///
/// Aucun test ne peut couper le reseau de la machine qui l'execute : sans ce
/// faux, le sixieme etat de `ELV-02`, le hors ligne, ne serait pas mesurable.
class FauxServiceReseau implements ServiceReseau {
  /// Cree la source sur un etat donne.
  FauxServiceReseau({this.horsLigneRendu = false});

  /// Vrai pour simuler l'absence de reseau.
  bool horsLigneRendu;

  @override
  Stream<bool> horsLigne() => Stream<bool>.value(horsLigneRendu);
}

/// Un selecteur de fichier qui rend toujours la meme piece.
class FauxSelecteurFichier implements SelecteurFichier {
  /// Cree le selecteur.
  FauxSelecteurFichier(this.reponse);

  /// Ce que le selecteur rendra. `null` simule un abandon.
  PieceAEnvoyer? reponse;

  @override
  Future<PieceAEnvoyer?> choisirPiece(TypePiece type) async => reponse;
}

/// Les profils locaux d'un appareil, en memoire.
///
/// `ELV-01` n'avait aucun test de widget avant le lot A1 : la connexion de
/// l'eleve ne passe par aucun provider Riverpod « service », mais par trois
/// depots locaux (profils, coffre, appairage). Sans ces trois faux, l'ecran ne
/// peut pas se monter en test, faute de plateforme pour `flutter_secure_storage`
/// et de base Drift reelle.
class FauxProfilsLocaux implements ProfilsLocaux {
  /// Les profils connus de cet appareil.
  List<ProfilLocal> profils = const <ProfilLocal>[];

  @override
  Future<List<ProfilLocal>> lister() async => profils;

  @override
  Future<void> enregistrer(ProfilLocal profil) async {
    profils = <ProfilLocal>[
      for (final ProfilLocal p in profils)
        if (p.id != profil.id) p,
      profil,
    ];
  }

  @override
  Future<void> oublier(String profilId) async {
    profils = profils.where((ProfilLocal p) => p.id != profilId).toList();
  }
}

/// Le coffre securise de l'appareil, en memoire.
class FauxStockageSecurise implements StockageSecurise {
  /// Jetons d'appareil, par profil.
  final Map<String, String> jetons = <String, String>{};

  /// Empreintes de code personnel, par profil.
  final Map<String, String> empreintes = <String, String>{};

  @override
  Future<String?> jetonAppareil(String profilId) async => jetons[profilId];

  @override
  Future<void> enregistrerJetonAppareil(String profilId, String jeton) async {
    jetons[profilId] = jeton;
  }

  @override
  Future<void> oublierAppareil(String profilId) async {
    jetons.remove(profilId);
  }

  @override
  Future<String?> empreintePin(String profilId) async => empreintes[profilId];

  @override
  Future<void> enregistrerEmpreintePin(
    String profilId,
    String empreinte,
  ) async {
    empreintes[profilId] = empreinte;
  }

  @override
  Future<void> effacerEmpreintePin(String profilId) async {
    empreintes.remove(profilId);
  }

  @override
  Future<String> empreinteAppareil() async => 'appareil-test';
}

/// Un pre-vol en memoire.
///
/// Aucun test ne peut enumerer les micros de la machine qui l'execute : sans ce
/// faux, la premiere phase de la salle -- celle qui refuse d'entrer sans micro
/// -- ne serait pas mesurable.
class FauxServicePreVol implements ServicePreVol {
  /// Cree le faux, avec un materiel complet par defaut.
  FauxServicePreVol({
    this.microDisponible = true,
    this.cameraDisponible = true,
    this.permissionRefusee = false,
  });

  /// Vrai quand une entree audio est utilisable.
  bool microDisponible;

  /// Vrai quand une camera est utilisable.
  bool cameraDisponible;

  /// Vrai pour simuler un refus de permission du navigateur.
  bool permissionRefusee;

  /// Le nombre d'inspections demandees. C'est par lui qu'un test verifie qu'un
  /// « Reessayer » relance vraiment le pre-vol.
  int verifications = 0;

  @override
  Future<ResultatPreVol> verifier() async {
    verifications++;
    return ResultatPreVol(
      microDisponible: microDisponible,
      cameraDisponible: cameraDisponible,
      sortieAudioDisponible: true,
      permissionRefusee: permissionRefusee,
    );
  }
}

/// Un service d'acces a la salle en memoire.
class FauxServiceVideo implements ServiceVideo {
  /// Cree le faux.
  FauxServiceVideo({this.acces0, this.motifARefuser});

  /// L'acces rendu. Nul et sans motif signifie « rien ne repond ».
  AccesSalle? acces0;

  /// Le refus a lever, s'il y en a un.
  MotifRefusSalle? motifARefuser;

  /// Les seances pour lesquelles un acces a ete demande.
  final List<String> demandes = <String>[];

  /// Les sorties volontaires annoncees, dans l'ordre. C'est la seule ecriture
  /// de presence confiee au client, et c'est elle qui distingue `sortie` de
  /// `deconnectee` : un test doit pouvoir constater qu'elle a bien eu lieu.
  final List<String> sorties = <String>[];

  /// Les seances ou une visite de controle a ete inscrite, dans l'ordre.
  final List<String> observations = <String>[];

  /// Les seances ou un tuteur s'est inscrit comme temoin, dans l'ordre.
  final List<String> assistances = <String>[];

  /// Ce que la prochaine inscription doit jeter, s'il y a lieu.
  ///
  /// Sans lui, le refus de la porte ne serait pas mesurable : il vient de la
  /// base -- seance close, role insuffisant, deja partie prenante -- et aucun
  /// test ne peut le produire autrement.
  Object? refusInscription;

  @override
  Future<void> observerEnControle(String seanceId) async {
    final Object? refus = refusInscription;
    if (refus != null) {
      // ignore: only_throw_errors
      throw refus;
    }
    observations.add(seanceId);
  }

  @override
  Future<void> assisterEnTuteur(String seanceId) async {
    final Object? refus = refusInscription;
    if (refus != null) {
      // ignore: only_throw_errors
      throw refus;
    }
    assistances.add(seanceId);
  }

  @override
  Future<AccesSalle> acces(String seanceId) async {
    demandes.add(seanceId);
    final MotifRefusSalle? motif = motifARefuser;
    if (motif != null) {
      throw EchecSalle(motif);
    }
    final AccesSalle? rendu = acces0;
    if (rendu == null) {
      throw const EchecSalle(MotifRefusSalle.reseau);
    }
    return rendu;
  }

  @override
  Future<void> annoncerSortie(String seanceId) async {
    sorties.add(seanceId);
  }
}

/// La presence d'une seance, en memoire.
///
/// **Le `null` est le cas le plus important a pouvoir jouer**, pas le cas
/// degrade : c'est lui qui exerce l'invariant J3 -- une presence indisponible
/// s'affiche « inconnu », jamais « absent ». Sans ce faux, la seule facon de
/// l'obtenir serait de couper le reseau de la machine qui execute les tests.
class FauxServicePresence implements ServicePresence {
  /// Cree le faux.
  FauxServicePresence({this.lignes});

  /// Ce que la lecture rend. `null` signifie « indisponible ».
  List<PresenceParticipant>? lignes;

  /// Les seances dont la presence a ete demandee.
  final List<String> demandes = <String>[];

  @override
  Future<List<PresenceParticipant>?> presence(String seanceId) async {
    demandes.add(seanceId);
    return lignes;
  }
}

/// Un moteur de salle en memoire.
///
/// Il ne simule pas WebRTC : il rejoue ce que le vrai moteur **publie**, c'est
/// a dire trois flux et une liste. C'est tout ce dont la salle depend, et c'est
/// pourquoi elle se verifie sans SDK, sans reseau et sans compte LiveKit --
/// lequel n'existe pas encore.
class FauxMoteurSalle implements VideoSessionProvider {
  final StreamController<EtatSalle> _etats =
      StreamController<EtatSalle>.broadcast();
  final StreamController<List<ParticipantSalle>> _participants =
      StreamController<List<ParticipantSalle>>.broadcast();
  final StreamController<QualiteLien> _qualite =
      StreamController<QualiteLien>.broadcast();
  final StreamController<ContenuPresente> _contenus =
      StreamController<ContenuPresente>.broadcast();
  final StreamController<PaquetDonnees> _donnees =
      StreamController<PaquetDonnees>.broadcast();

  EtatSalle _etat = EtatSalle.absent;
  ContenuPresente? _dernierContenu;

  /// Les paquets que l'ecran a demande de publier, dans l'ordre.
  final List<PaquetDonnees> donneesPubliees = <PaquetDonnees>[];

  /// Les acces avec lesquels on a rejoint, dans l'ordre.
  final List<AccesSalle> entrees = <AccesSalle>[];

  /// Les contenus que l'ecran a demande a presenter, dans l'ordre.
  ///
  /// **Tout est enregistre, y compris ce que le faux refuse ensuite de
  /// publier** : c'est ce qui permet de mesurer les deux faits separement --
  /// l'ecran a bien appele, et le moteur a bien refuse.
  final List<ContenuPresente> contenusPresentesDemandes = <ContenuPresente>[];

  /// Le nombre de sorties du moteur.
  int departs = 0;

  /// Les reglages de micro demandes, dans l'ordre.
  final List<bool> microDemande = <bool>[];

  /// Les reglages de camera demandes, dans l'ordre.
  final List<bool> cameraDemandee = <bool>[];

  /// Ce que `rejoindre` doit lever, quand on teste un echec de connexion.
  Object? erreurEntree;

  /// Les identites pour lesquelles une image existe.
  final Set<String> avecImage = <String>{};

  /// Pose un etat et le publie, comme le vrai moteur.
  void poser(EtatSalle etat) {
    _etat = etat;
    _etats.add(etat);
  }

  /// Publie une liste de participants.
  void publier(List<ParticipantSalle> liste) => _participants.add(liste);

  /// Publie une qualite de lien.
  void publierQualite(QualiteLien lien) => _qualite.add(lien);

  /// Le dernier contenu connu du moteur, emis ou recu.
  ///
  /// Il se lit sans s'abonner, et ce n'est pas une commodite : **un
  /// `addTearDown(abonnement.cancel)` dans un `testWidgets` ne se termine
  /// jamais**. Le `cancel` est attendu apres la sortie de la zone de temps
  /// simule, et la micro-tache qui le resoudrait n'est plus drainee par
  /// personne : le test se bloque sans message, hors de son propre delai. Lu
  /// une fois, le 20 septembre 2026, contre un abonnement de trois lignes.
  ContenuPresente? get dernierContenuPresente => _dernierContenu;

  /// Fait arriver un contenu presente, comme s'il venait du canal de donnees.
  ///
  /// C'est par elle qu'un ecran de RECEPTEUR se teste : un eleve ne presente
  /// rien, il recoit -- et sans ce point d'entree il faudrait un serveur
  /// LiveKit pour mesurer ce que son ecran fait de la page qu'on lui pousse.
  void publierContenu(ContenuPresente contenu) {
    _dernierContenu = contenu;
    _contenus.add(contenu);
  }

  /// Fait arriver un paquet de donnees applicatif, comme un vrai recepteur.
  void recevoirDonnees(PaquetDonnees paquet) {
    if (!_donnees.isClosed) {
      _donnees.add(paquet);
    }
  }

  @override
  Stream<PaquetDonnees> get donneesRecues => _donnees.stream;

  @override
  AccesSalle? get accesCourant => entrees.isEmpty ? null : entrees.last;

  @override
  Future<void> publierDonnees({
    required String sujet,
    required List<int> charge,
    required bool fiable,
    List<String> destinataires = const <String>[],
  }) async {
    final AccesSalle? acces = accesCourant;
    if (acces == null) {
      throw const EchecPublicationDonnees(MotifEchecPublication.horsSalle);
    }
    if (!acces.capacites.peutPublierDonnees) {
      throw const EchecPublicationDonnees(MotifEchecPublication.droitRefuse);
    }
    donneesPubliees.add(
      PaquetDonnees(sujet: sujet, charge: charge, fiable: fiable),
    );
  }

  @override
  EtatSalle get etatCourant => _etat;

  @override
  Stream<EtatSalle> get etats => _etats.stream;

  @override
  Stream<List<ParticipantSalle>> get participants => _participants.stream;

  @override
  Stream<QualiteLien> get qualite => _qualite.stream;

  @override
  Stream<ContenuPresente> get contenusPresentes async* {
    // Le meme contrat que le vrai moteur, et c'est la raison d'etre du faux :
    // le dernier contenu connu d'abord, le flux ensuite. Un ecran qui s'abonne
    // apres le tour de page doit retrouver la page ouverte.
    final ContenuPresente? dernier = _dernierContenu;
    if (dernier != null) {
      yield dernier;
    }
    yield* _contenus.stream;
  }

  @override
  Future<void> presenterContenu(ContenuPresente contenu) async {
    contenusPresentesDemandes.add(contenu);
    // **Le meme refus silencieux que le vrai moteur**, lu au meme endroit : les
    // capacites du jeton avec lequel on est entre. Un faux plus permissif
    // laisserait passer un ecran d'eleve qui presente, et le defaut ne se
    // verrait qu'en production, contre un serveur qui, lui, refuserait.
    final AccesSalle? acces = entrees.isEmpty ? null : entrees.last;
    if (acces == null || !acces.capacites.peutPublierDonnees) {
      return;
    }
    publierContenu(contenu);
  }

  @override
  Future<void> rejoindre(AccesSalle acces) async {
    final Object? erreur = erreurEntree;
    if (erreur != null) {
      poser(EtatSalle.echec);
      // ignore: only_throw_errors
      throw erreur;
    }
    entrees.add(acces);
    poser(EtatSalle.connecte);
  }

  @override
  Future<void> quitter() async {
    departs++;
    // Comme le vrai moteur : quitter efface l'etat pedagogique, une coupure ne
    // l'efface pas.
    _dernierContenu = null;
    poser(EtatSalle.absent);
  }

  @override
  Future<void> reglerMicro({required bool actif}) async {
    microDemande.add(actif);
  }

  @override
  Future<void> reglerCamera({required bool actif}) async {
    cameraDemandee.add(actif);
  }

  @override
  Future<void> reglerAudioSeul({required bool actif}) async {}

  @override
  Widget? renduVideo(String identite) => avecImage.contains(identite)
      ? const SizedBox.expand(key: Key('image-video'))
      : null;

  @override
  Future<void> liberer() async {
    await _etats.close();
    await _participants.close();
    await _qualite.close();
    await _contenus.close();
    await _donnees.close();
  }
}

/// Le service d'appairage de l'enfant, en memoire.
class FauxServiceEnfant implements ServiceEnfant {
  /// Ce que le prochain appairage rendra.
  AppairageReussi reponse = const AppairageReussi(
    profilId: 'e1',
    prenom: 'Khadija',
    jetonAppareil: 'jeton-test',
  );

  /// Le nombre d'ouvertures de session reussies.
  int sessionsOuvertes = 0;

  @override
  Future<AppairageReussi> appairer({
    required String code,
    required String empreinteAppareil,
    required String plateforme,
  }) async => reponse;

  @override
  Future<void> ouvrirSession(String jetonAppareil) async {
    sessionsOuvertes++;
  }
}

/// Le planning global du controle qualite, en memoire.
///
/// Il rend des `Seance`, le meme modele que le planning des trois autres roles :
/// `CTR-01` lit `mes_seances_v` comme eux, et un faux qui rendrait un autre
/// modele laisserait croire a une vue jumelle qui n'existe pas.
class FauxServiceControle implements ServiceControle {
  /// Cree le faux.
  FauxServiceControle({this.seancesRendues = const <Seance>[]});

  /// Ce que la lecture rend.
  List<Seance> seancesRendues;

  /// Ce que la prochaine lecture doit jeter, s'il y a lieu.
  Object? erreurAJeter;

  /// Combien de temps la lecture met a repondre.
  ///
  /// Nul par defaut : un faux qui repond dans la micro-tache suivante ne laisse
  /// **aucune frame** pendant laquelle l'ecran est en chargement, et l'etat
  /// squelette serait alors impossible a mesurer -- non parce qu'il manque, mais
  /// parce que le faux est trop rapide pour lui.
  Duration? delai;

  /// Combien de fois le planning a ete relu. C'est ce qui permet de constater
  /// qu'une minute ecoulee relit, plutot que de recalculer sur des donnees
  /// vieillies.
  int lectures = 0;

  @override
  Future<List<Seance>> planning() async {
    lectures++;
    final Duration? attente = delai;
    if (attente != null) {
      await Future<void>.delayed(attente);
    }
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return seancesRendues;
  }
}

/// Le suivi du foyer, en memoire.
///
/// **Ses deux lectures echouent separement, et c'est tout l'interet du faux.**
/// `TUT-06` lit les cours d'un cote et la presence de l'autre : une presence
/// indisponible doit laisser l'historique lisible, avec des etats « inconnu »,
/// la ou une lecture de cours impossible vide l'ecran. Un faux qui ne saurait
/// echouer qu'en bloc ne permettrait pas de distinguer les deux.
class FauxServiceSuivi implements ServiceSuivi {
  /// Cree le faux.
  FauxServiceSuivi({
    this.seancesRendues = const <Seance>[],
    this.presencesRendues = const <PresenceParticipant>[],
  });

  /// Les cours que la lecture rend.
  List<Seance> seancesRendues;

  /// Les lignes de presence rendues. `null` signifie « indisponible ».
  List<PresenceParticipant>? presencesRendues;

  /// Ce que la prochaine lecture de cours doit jeter, s'il y a lieu.
  Object? erreurAJeter;

  /// Combien de temps la lecture des cours met a repondre.
  ///
  /// Nul par defaut, pour la meme raison qu'a [FauxServiceControle] : sans
  /// delai, l'ecran n'est en chargement pendant aucune frame et l'etat
  /// squelette serait impossible a mesurer.
  Duration? delai;

  /// Combien de fois les cours ont ete lus.
  int lectures = 0;

  @override
  Future<List<Seance>> seances() async {
    lectures++;
    final Duration? attente = delai;
    if (attente != null) {
      await Future<void>.delayed(attente);
    }
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return seancesRendues;
  }

  @override
  Future<List<PresenceParticipant>?> presences() async => presencesRendues;
}

/// Le service du role Enseignant, en memoire.
///
/// Le huitieme service a recevoir un faux, et il en fallait un : le lot
/// « role Enseignant » construit cinq ecrans sur ce seul contrat, et aucun
/// d'entre eux ne peut se monter en test contre Supabase.
///
/// **Aucun agent metier ne modifie ce faux.** Un besoin non couvert se demande
/// par `CONTRACT_REQUEST_<AGENT>.md`
/// (`docs/archive/2026-09-pre-remise-a-plat/architecture/TEACHER_FILE_OWNERSHIP.md`).
class FauxServiceEnseignant implements ServiceEnseignant {
  /// Les seances rendues.
  List<SeanceEnseignant> seancesRendues = const <SeanceEnseignant>[];

  /// Les rosters rendus, par identifiant de seance.
  Map<String, List<MembreSeance>> rostersRendus =
      const <String, List<MembreSeance>>{};

  /// Les groupes rendus.
  List<GroupeEnseignant> groupesRendus = const <GroupeEnseignant>[];

  /// Les membres rendus, par identifiant de groupe.
  Map<String, List<MembreSeance>> membresRendus =
      const <String, List<MembreSeance>>{};

  /// Les cahiers en retard rendus.
  List<CahierEnRetard> retardsRendus = const <CahierEnRetard>[];

  /// Le brouillon rendu. Nul pour jouer une seance introuvable.
  BrouillonCahier? brouillonRendu;

  /// Les cahiers deposes, dans l'ordre. C'est par eux qu'un test verifie
  /// **qu'une seule** ecriture part pour une cle donnee.
  final List<({String cle, String seanceId, Map<String, dynamic> contenu})>
  cahiersDeposes =
      <({String cle, String seanceId, Map<String, dynamic> contenu})>[];

  /// Ce que la prochaine lecture doit jeter.
  Object? erreurLecture;

  /// Ce que le prochain depot doit jeter.
  Object? erreurDepot;

  /// Combien de temps une lecture met a repondre.
  ///
  /// Nul par defaut. Sans delai, un faux resout son futur dans la micro-tache
  /// que le premier `pump` vide, et l'etat de chargement n'existe jamais : c'est
  /// la meme raison qu'a [FauxServiceAttribution].
  Duration? delai;

  /// Combien de fois les seances ont ete lues.
  int lecturesSeances = 0;

  Future<void> _preparer() async {
    final Duration? attente = delai;
    if (attente != null) {
      await Future<void>.delayed(attente);
    }
    final Object? erreur = erreurLecture;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
  }

  @override
  Future<List<SeanceEnseignant>> seances() async {
    lecturesSeances++;
    await _preparer();
    return seancesRendues;
  }

  @override
  Future<List<MembreSeance>> rosterDeSeance(String seanceId) async {
    await _preparer();
    return rostersRendus[seanceId] ?? const <MembreSeance>[];
  }

  @override
  Future<List<GroupeEnseignant>> groupes() async {
    await _preparer();
    return groupesRendus;
  }

  @override
  Future<List<MembreSeance>> membresDuGroupe(String groupeId) async {
    await _preparer();
    return membresRendus[groupeId] ?? const <MembreSeance>[];
  }

  @override
  Future<List<CahierEnRetard>> cahiersEnRetard() async {
    await _preparer();
    return retardsRendus;
  }

  @override
  Future<BrouillonCahier?> brouillon(String seanceId) async {
    await _preparer();
    return brouillonRendu;
  }

  @override
  Future<void> deposerCahier({
    required String cleIdempotence,
    required Map<String, dynamic> contenu,
    required String seanceId,
  }) async {
    final Object? erreur = erreurDepot;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    cahiersDeposes.add((
      cle: cleIdempotence,
      seanceId: seanceId,
      contenu: contenu,
    ));
  }
}

/// La file locale des cahiers en attente, en memoire.
///
/// Elle **respecte l'idempotence pour de vrai** plutot que d'empiler : un
/// cahier redepose sous la meme cle ne cree pas de seconde ligne. Un faux qui
/// ignorerait la cle laisserait le rejeu hors ligne non mesure, alors que c'est
/// precisement la garantie que le protocole exige.
class FauxDepotRapports implements DepotRapports {
  final Map<String, RapportEnAttente> _lignes = <String, RapportEnAttente>{};

  /// Ce que la prochaine ecriture doit jeter.
  Object? erreurAJeter;

  /// Les cles presentes, du plus ancien au plus recent.
  List<String> get cles =>
      (_lignes.values.toList()..sort(
            (RapportEnAttente a, RapportEnAttente b) =>
                a.redigeA.compareTo(b.redigeA),
          ))
          .map((RapportEnAttente r) => r.cleIdempotence)
          .toList(growable: false);

  @override
  Future<List<RapportEnAttente>> enAttente() async =>
      _lignes.values.toList(growable: false)..sort(
        (RapportEnAttente a, RapportEnAttente b) =>
            a.redigeA.compareTo(b.redigeA),
      );

  @override
  Future<void> deposer(RapportEnAttente rapport) async {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    _lignes.putIfAbsent(rapport.cleIdempotence, () => rapport);
  }

  @override
  Future<void> retirer(String cleIdempotence) async {
    _lignes.remove(cleIdempotence);
  }

  @override
  Future<void> majApresEchec(RapportEnAttente rapport) async {
    _lignes[rapport.cleIdempotence] = rapport;
  }
}

/// Une seance d'enseignant prete a l'emploi dans un test.
///
/// Le modele porte douze champs, dont neuf ont un defaut sensé : les ecrire a
/// chaque cas de test noierait ce que le test mesure vraiment.
SeanceEnseignant seanceDeTest({
  String id = 's1',
  required DateTime debut,
  Duration duree = const Duration(minutes: 45),
  StatutSeance? statut = StatutSeance.planifiee,
  int nbParticipants = 1,
  bool cahierDepose = false,
  String? groupeId,
  String? groupeLibelle,
  int? seuilMax,
  int minutesInterruption = 0,
}) => SeanceEnseignant(
  id: id,
  debut: debut,
  fin: debut.add(duree),
  statut: statut,
  nbParticipants: nbParticipants,
  cahierDepose: cahierDepose,
  groupeId: groupeId,
  groupeLibelle: groupeLibelle,
  seuilMax: seuilMax,
  minutesInterruption: minutesInterruption,
);

/// Un port de consentements en memoire (contrat K6).
class FauxPortConsentements implements PortConsentements {
  /// Ce que [signees] renvoie.
  List<Acceptation> signeesRendues = <Acceptation>[];

  /// Ce que [aRenouveler] renvoie.
  List<ConsentementRequis> aRenouvelerRendu = <ConsentementRequis>[];

  /// Ce que la prochaine lecture ou ecriture doit jeter.
  Object? erreurAJeter;

  /// Les acceptations enregistrees par [accepter].
  final List<({SorteContrat sorte, String version})> accepteEnregistre =
      <({SorteContrat sorte, String version})>[];

  @override
  Future<List<Acceptation>> signees() async {
    if (erreurAJeter case final Object e) {
      // ignore: only_throw_errors
      throw e;
    }
    return signeesRendues;
  }

  @override
  Future<List<ConsentementRequis>> aRenouveler() async {
    if (erreurAJeter case final Object e) {
      // ignore: only_throw_errors
      throw e;
    }
    return aRenouvelerRendu;
  }

  @override
  Future<void> accepter({
    required SorteContrat sorte,
    required String version,
  }) async {
    if (erreurAJeter case final Object e) {
      // ignore: only_throw_errors
      throw e;
    }
    accepteEnregistre.add((sorte: sorte, version: version));
  }
}

/// Un eleve pret a l'emploi dans un test.
MembreSeance membreDeTest({
  String studentId = 'e1',
  String identifiant = 'RA-0001',
  String? prenom = 'Khadija',
  String? niveau,
  String? riwaya,
}) => MembreSeance(
  studentId: studentId,
  identifiantImmuable: identifiant,
  prenom: prenom,
  niveau: niveau,
  riwaya: riwaya,
);

/// Une image PNG synthetique de 1 x 1 (transparente) : jamais une vraie piece.
final Uint8List pngSynthetique = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
