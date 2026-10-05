// Le port du garde anti-promotion de la Communaute enseignants (COM-COMU-2,
// spec section 5 ; contrat serveur COM-BR-07).
//
// Le garde (`CommunityPromotionGuard`, `garde_promotion.dart`) ne detecte
// RIEN lui-meme : il affiche le verdict que ce port lui rend. Aucun moteur
// artisanal de detection cote client (spec section 20), et jamais
// « Verifie » sur la seule base du client (spec section 5.4). La detection
// reelle (liens affilies, vente) est un contrat serveur, COM-BR-07.
//
// Production : `GardePromotionIndisponible`, chaque appel echoue avec
// `CapaciteIndisponible('COM-BR-07')`. Le composer le dit honnetement : il
// ne pretend pas avoir relu la publication, il la transmet au serveur, qui
// reste seul juge (COM-BR-05, COM-BR-07). `GardePromotionFixtures` est un
// double de demonstration et de test : une TABLE de contenus marques
// d'avance (spec section 26), jamais une analyse du texte.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/moderation.dart';
import 'etat_lien.dart';
import 'port_communaute.dart';

/// Le verdict du serveur sur un brouillon (spec section 5.2).
enum VerdictPromotion {
  /// Rien a signaler : la publication part.
  normal,

  /// Potentiellement commercial : la publication est retenue, la personne
  /// retire le lien, le code ou l'offre.
  avertissement,

  /// Lien affilie : blocage.
  lienAffilie,

  /// Vente de produits ou de services : blocage.
  vente;

  /// Vrai si le contenu enfreint clairement la regle (blocage).
  bool get bloque =>
      this == VerdictPromotion.lienAffilie || this == VerdictPromotion.vente;

  /// Vrai si la publication ne part pas en l'etat.
  bool get retient => this != VerdictPromotion.normal;
}

/// Ce que le serveur rend pour un brouillon : le verdict, le motif de la
/// politique (un des huit motifs du socle, spec section 5.5) et l'etat de
/// chaque lien qu'il a lu dans le brouillon (spec section 5.4).
@immutable
class VerificationPromotion {
  /// Cree la verification.
  const VerificationPromotion({
    required this.verdict,
    this.motif,
    this.liens = const <LienAnalyse>[],
  });

  /// Le brouillon ne pose aucun probleme.
  static const VerificationPromotion normale = VerificationPromotion(
    verdict: VerdictPromotion.normal,
  );

  /// Le verdict.
  final VerdictPromotion verdict;

  /// Le motif nomme par le serveur, s'il y en a un.
  final MotifSignalement? motif;

  /// Les liens du brouillon et leur etat, dans l'ordre du texte.
  final List<LienAnalyse> liens;
}

/// Le garde anti-promotion (COM-BR-07).
abstract interface class PortGardePromotion {
  /// Le verdict du serveur sur [brouillon], avant sa publication.
  Future<VerificationPromotion> verifier(BrouillonPublication brouillon);

  /// L'etat d'un lien isole ; [EtatLien.nonVerifie] si le serveur ne le
  /// qualifie pas.
  Future<EtatLien> etatLien(String adresse);
}

/// Le garde tant qu'aucun contrat n'existe (COM-BR-07) : chaque appel
/// echoue avec [CapaciteIndisponible], jamais un verdict invente.
class GardePromotionIndisponible implements PortGardePromotion {
  /// Cree l'implementation.
  const GardePromotionIndisponible();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('COM-BR-07');

  @override
  Future<VerificationPromotion> verifier(BrouillonPublication brouillon) =>
      Future<VerificationPromotion>.error(_manque);

  @override
  Future<EtatLien> etatLien(String adresse) => Future<EtatLien>.error(_manque);
}

/// Le contenu d'un brouillon, cle des fixtures : titre et texte, sans les
/// blancs du debut et de la fin.
typedef ContenuMarque = ({String titre, String texte});

/// Le garde des fixtures : **double de demonstration et de test**, jamais
/// branche en production.
///
/// Un brouillon dont le titre ET le texte sont exactement ceux d'une fixture
/// recoit son verdict ; tout autre brouillon est normal. C'est une table de
/// contenus marques d'avance, pas une detection : modifier un seul mot rend
/// le brouillon normal. [echec] fait echouer chaque appel comme un reseau
/// coupe.
class GardePromotionFixtures implements PortGardePromotion {
  /// Cree le garde sur ses fixtures.
  GardePromotionFixtures({
    Map<ContenuMarque, VerificationPromotion> verdicts =
        const <ContenuMarque, VerificationPromotion>{},
    Map<String, EtatLien> liens = const <String, EtatLien>{},
    this.echec = false,
    this.attente = Duration.zero,
  }) : _verdicts = <ContenuMarque, VerificationPromotion>{
         for (final MapEntry<ContenuMarque, VerificationPromotion> e
             in verdicts.entries)
           (titre: e.key.titre.trim(), texte: e.key.texte.trim()): e.value,
       },
       _liens = Map<String, EtatLien>.of(liens);

  final Map<ContenuMarque, VerificationPromotion> _verdicts;
  final Map<String, EtatLien> _liens;

  /// Vrai : chaque appel echoue (reseau coupe).
  bool echec;

  /// La latence simulee.
  final Duration attente;

  /// Les brouillons verifies (tests).
  final List<BrouillonPublication> verifies = <BrouillonPublication>[];

  Future<void> _attendre() async {
    if (attente > Duration.zero) await Future<void>.delayed(attente);
    if (echec) throw StateError('garde anti-promotion injoignable');
  }

  @override
  Future<VerificationPromotion> verifier(BrouillonPublication brouillon) async {
    await _attendre();
    verifies.add(brouillon);
    return _verdicts[(
          titre: brouillon.titre.trim(),
          texte: brouillon.texte.trim(),
        )] ??
        VerificationPromotion.normale;
  }

  @override
  Future<EtatLien> etatLien(String adresse) async {
    await _attendre();
    return _liens[adresse.trim()] ?? EtatLien.nonVerifie;
  }
}

/// Le garde employe par l'application.
final Provider<PortGardePromotion> portGardePromotionProvider =
    Provider<PortGardePromotion>(
      (Ref ref) => const GardePromotionIndisponible(),
      // Surchargeable dans un ProviderScope imbrique (demonstration).
      dependencies: const <ProviderOrFamily>[],
    );
