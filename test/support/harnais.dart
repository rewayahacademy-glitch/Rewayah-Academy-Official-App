import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, alors que `ProviderScope.overrides` en attend une liste.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
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

  /// Les pieces deposees, avec le genre transmis.
  final List<({PieceAEnvoyer piece, Genre genre})> depots =
      <({PieceAEnvoyer piece, Genre genre})>[];

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
  Future<void> deposerPiece(PieceAEnvoyer piece, Genre genre) async {
    _peutEchouer();
    depots.add((piece: piece, genre: genre));
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

/// Un selecteur de fichier qui rend toujours la meme piece.
class FauxSelecteurFichier implements SelecteurFichier {
  /// Cree le selecteur.
  FauxSelecteurFichier(this.reponse);

  /// Ce que le selecteur rendra. `null` simule un abandon.
  PieceAEnvoyer? reponse;

  @override
  Future<PieceAEnvoyer?> choisirPiece(TypePiece type) async => reponse;
}
