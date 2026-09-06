import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, alors que `ProviderScope.overrides` en attend une liste.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
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
    child: MaterialApp(theme: AppTheme.pour(mode), home: enfant),
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
      theme: AppTheme.pour(mode),
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
  Future<String> apercu(String cleObjet) async => 'https://exemple.test/$cleObjet';

  @override
  Future<void> decider({
    required String documentId,
    required bool approuve,
    String? motif,
  }) async {
    verdicts.add((documentId: documentId, approuve: approuve, motif: motif));
  }
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
