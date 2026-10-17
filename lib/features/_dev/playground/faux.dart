/// Les services fictifs du Playground.
///
/// Copie de `test/support/harnais.dart` : les memes doubles vivent deja dans la
/// suite de tests, et le Playground sert exactement ce qu'ils servent a un
/// test de widget - monter la vraie application sans reseau ni backend.
///
/// **Une seule source de comportement.** Si le comportement d'une operation
/// change, il se corrige ici et dans le harnais, jamais en etendant ce fichier
/// sur un cas qui n'existait pas. La regle de la bench (`07-catalogue-*`) vaut
/// pour les fausses donnees : ce fichier ne porte ni style ni interface, il
/// porte les memes services que l'application reelle, remplis de memoire.
library;

import 'dart:async';

import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/appairage/service_enfant.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/cache/secure/stockage_securise.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/reglages_priere.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';

/// Un service de dossier en memoire.
class FauxServiceDossier implements ServiceDossier {
  /// Ce que [etat] renverra.
  EtatDossier etatRendu = const EtatDossier.sansProfil();

  /// Ce que la prochaine operation doit jeter, quand on simule un echec.
  Object? erreurAJeter;

  /// Les profils demandes.
  final List<({AppRole role, String prenom, String nom, Genre? genre})>
  profilsCrees = <({AppRole role, String prenom, String nom, Genre? genre})>[];

  /// Le terrain de jeu n'est pas la demonstration : il suit la regle des
  /// vrais comptes pour la version du contrat enseignant.
  @override
  bool get demonstration => false;

  /// Les contrats acceptes.
  final List<SorteContrat> contratsAcceptes = <SorteContrat>[];

  /// Les pieces deposees.
  final List<PieceAEnvoyer> depots = <PieceAEnvoyer>[];

  void _peutEchouer() {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // Volontairement un Object : le vrai client jette aussi bien une
      // PostgrestException qu'une erreur de plateforme, et l'ecran doit se
      // comporter pareil dans les deux cas.
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
    String? codeInvitation,
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

  /// Le nombre de rafraichissements demandes.
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

  /// Les adresses ayant tente une connexion par mot de passe.
  final List<String> motsDePasseTentes = <String>[];

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
      // ignore: only_throw_errors
      throw erreur;
    }
    liensEnvoyes.add(courriel.trim());
  }

  @override
  Future<void> connexionMotDePasse(String courriel, String motDePasse) async {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    motsDePasseTentes.add(courriel.trim());
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
  Future<List<Seance>> seances({String? eleveId}) async => seancesRendues;

  @override
  Future<List<Affectation>> affectations() async => affectationsRendues;
}

/// Un service de matching en memoire.
class FauxServiceMatching implements ServiceMatching {
  /// Les demandes deposees.
  final List<({SorteDemande sorte, String sujetId, String motif, int? valeur})>
  demandes =
      <({SorteDemande sorte, String sujetId, String motif, int? valeur})>[];

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
class FauxServiceAdmin implements ServiceAdmin {
  /// Les six compteurs rendus. Tous a zero par defaut.
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
  Future<void> enregistrerJetonAppareil(
    String profilId,
    String jeton,
  ) async {
    jetons[profilId] = jeton;
  }

  @override
  Future<void> oublierAppareil(String profilId) async {
    jetons.remove(profilId);
  }

  @override
  Future<String?> empreintePin(String profilId) async =>
      empreintes[profilId];

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