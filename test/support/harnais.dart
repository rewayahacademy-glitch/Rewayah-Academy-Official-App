import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, alors que `ProviderScope.overrides` en attend une liste.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/reglages_priere.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

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

  @override
  Future<String> apercu(String cleObjet) async =>
      'https://exemple.test/$cleObjet';

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
