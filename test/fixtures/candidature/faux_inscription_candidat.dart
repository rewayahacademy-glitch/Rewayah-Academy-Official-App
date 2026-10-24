// Le double du port de l'inscription du candidat, oracle des tests de widget
// de CAND-04 (« Inscription sans code »). Importe par aucune ligne de
// production (`CONTRAT_PORTS_CANDIDATURES.md`, section 6).
//
// Il rejoue, dans le meme ordre, ce que fait `inscrire_candidat`
// (`20261022000600_cand_l3_inscription_import_rapprochement.sql`) : session sans
// profil (sinon `PermissionInsuffisante`, le 42501 du serveur), courriel
// confirme, la porte (cle de mise en ligne pour le lien public, code lie a
// l'adresse pour l'invitation), les champs obligatoires, l'accord de
// confidentialite a la version attendue, puis le plafond horaire du lien public
// **dont la reponse est celle du succes sans rien creer**. Aucune regle de plus :
// un test qui veut une panne la programme.

import 'package:rewayah_academy/core/candidature/port_inscription_candidat.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart'
    show HorsLigneCandidature;
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';

/// Un appel a `inscrire`, tel que le port l'a recu.
class AppelInscriptionCandidat {
  /// Garde un appel.
  const AppelInscriptionCandidat({
    required this.code,
    required this.prenom,
    required this.nom,
    required this.genre,
    required this.telephone,
    required this.langue,
    required this.versionConfidentialite,
  });

  /// Le code d'invitation, nul pour le lien public.
  final String? code;

  /// Le prenom.
  final String prenom;

  /// Le nom.
  final String nom;

  /// `male` ou `female`.
  final String genre;

  /// Le telephone international.
  final String telephone;

  /// `fr` ou `ar`.
  final String langue;

  /// La version de confidentialite acceptee.
  final String versionConfidentialite;
}

/// L'inscription du candidat en memoire.
class FauxInscriptionCandidat implements PortInscriptionCandidat {
  /// Cree le double ; [cleOuverte] est la cle de mise en ligne.
  FauxInscriptionCandidat({
    this.cleOuverte = true,
    this.versionAttendue = '2026-10-v1',
    this.codesValides = const <String>{},
    this.codesUtilises = const <String>{},
    this.codesExpires = const <String>{},
    this.plafond = 60,
  });

  /// La cle de mise en ligne de l'inscription sans code.
  bool cleOuverte;

  /// La version de confidentialite que le serveur attend.
  String? versionAttendue;

  /// Les codes d'invitation valides pour l'adresse de la session.
  final Set<String> codesValides;

  /// Les codes qui ont deja servi.
  final Set<String> codesUtilises;

  /// Les codes qui ont expire.
  final Set<String> codesExpires;

  /// Le nombre d'inscriptions publiques acceptees par heure.
  int plafond;

  /// Le nombre d'inscriptions publiques deja faites dans l'heure.
  int dejaInscrits = 0;

  /// Vrai quand la session a deja un profil (le serveur rend 42501).
  bool profilExiste = false;

  /// Faux quand le courriel n'est pas encore confirme.
  bool courrielConfirme = true;

  /// Ce que `ouverte()` doit jeter, ou `null`.
  Object? panneLecture;

  /// Ce que `inscrire()` doit jeter, ou `null`.
  Object? panneInscription;

  /// Une reponse imposee a `inscrire()` (un refus que le test veut voir).
  ResultatInscriptionCandidat? reponseImposee;

  /// Tous les appels a `inscrire`, y compris ceux qui n'ont rien cree.
  final List<AppelInscriptionCandidat> appels = <AppelInscriptionCandidat>[];

  /// Les comptes et candidatures effectivement crees.
  final List<AppelInscriptionCandidat> creations = <AppelInscriptionCandidat>[];

  /// Le nombre de lectures de `ouverte()`.
  int lectures = 0;

  @override
  Future<OuvertureInscriptionCandidat> ouverte() async {
    lectures++;
    final Object? panne = panneLecture;
    if (panne != null) {
      // Le double rejette ce que le test a programme, Exception ou non.
      // ignore: only_throw_errors
      throw panne;
    }
    return OuvertureInscriptionCandidat(
      ouverte: cleOuverte,
      versionConfidentialite: versionAttendue,
    );
  }

  @override
  Future<ResultatInscriptionCandidat> inscrire({
    required String prenom,
    required String nom,
    required String genre,
    required String telephone,
    required String langue,
    required String versionConfidentialite,
    String? code,
  }) async {
    final AppelInscriptionCandidat appel = AppelInscriptionCandidat(
      code: code,
      prenom: prenom,
      nom: nom,
      genre: genre,
      telephone: telephone,
      langue: langue,
      versionConfidentialite: versionConfidentialite,
    );
    appels.add(appel);
    final Object? panne = panneInscription;
    if (panne != null) {
      // Le double rejette ce que le test a programme, Exception ou non.
      // ignore: only_throw_errors
      throw panne;
    }
    if (profilExiste) {
      throw const PermissionInsuffisante('inscrire_candidat');
    }
    if (!courrielConfirme) {
      return const InscriptionCourrielNonConfirme();
    }
    final ResultatInscriptionCandidat? imposee = reponseImposee;
    if (imposee != null) {
      return imposee;
    }
    final String? c = code?.trim().isEmpty ?? true ? null : code!.trim();
    if (c == null) {
      if (!cleOuverte) {
        return const InscriptionFermee();
      }
    } else if (codesUtilises.contains(c)) {
      return const InscriptionCodeDejaUtilise();
    } else if (codesExpires.contains(c)) {
      return const InscriptionCodeExpire();
    } else if (!codesValides.contains(c)) {
      return const InscriptionCodeInconnu();
    }
    final List<String> invalides = <String>[
      if (prenom.trim().isEmpty) 'prenom',
      if (nom.trim().isEmpty) 'nom',
      if (genre != 'male' && genre != 'female') 'genre',
      if (langue != 'fr' && langue != 'ar') 'langue',
      if (!RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(telephone)) 'telephone',
    ];
    if (invalides.isNotEmpty) {
      return InscriptionInvalide(invalides);
    }
    final String? attendue = versionAttendue;
    if (attendue == null) {
      return const InscriptionConfidentialiteIndisponible();
    }
    if (versionConfidentialite != attendue) {
      return InscriptionConfidentialitePerimee(versionCourante: attendue);
    }
    // Le plafond (lien public seulement) : au-dela, la reponse est exactement
    // celle du succes, sans rien creer (CAND-F03).
    if (c == null) {
      if (dejaInscrits >= plafond) {
        return const InscriptionAcceptee();
      }
      dejaInscrits++;
    }
    creations.add(appel);
    return const InscriptionAcceptee();
  }
}

/// Une panne de reseau, comme le client la voit.
const Object panneReseau = HorsLigneCandidature();

/// Un lot serveur absent.
const Object panneLotAbsent = CapaciteIndisponible(
  dependanceInscriptionCandidat,
);
