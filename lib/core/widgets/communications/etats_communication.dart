// Les etats generiques des communications (spec section 22 « Etats
// generiques », section 25 « Etats par ecran »).
//
// Aucun nouvel ecran d'etat : tout passe par `EtatSysteme` (bloc ou page),
// `Skeleton`, `BlocAsynchrone` et `OfflineBanner`, avec les textes de la spec
// (`com.socle.composants.etats.*`). Un ecran de communication ne recompose
// donc ni son vide, ni son erreur, ni son hors ligne.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capacites/capacite_indisponible.dart';
import '../../i18n/strings.g.dart';
import '../../reseau/service_reseau.dart';
import '../bloc_asynchrone.dart';
import '../etat_systeme.dart';
import '../offline_banner.dart';
import '../skeleton.dart';

/// Les etats qu'un ecran de communication rend hors de son contenu.
enum EtatCommunication {
  /// La lecture est en cours.
  chargement,

  /// La lecture a abouti, il n'y a rien.
  vide,

  /// La lecture a echoue : « Reessayer » si l'ecran sait relancer.
  erreur,

  /// L'appareil est hors ligne et rien n'est en cache.
  horsLigne,

  /// La capacite n'existe pas encore (port neutre) : ni un echec, ni un vide,
  /// elle ne se reessaie pas.
  indisponible,

  /// Le serveur refuse ce contenu a la personne qui lit.
  permissionRefusee,
}

/// La vue d'un [EtatCommunication], sur `EtatSysteme` et `Skeleton`.
///
/// [titreVide] et [phraseVide] disent le vide propre a l'ecran (« Aucune
/// conversation pour le moment. ») ; sans eux, le vide generique. [dependance]
/// nomme ce qui manque, pour la trace et les tests seulement : il n'est jamais
/// affiche.
class VueEtatCommunication extends StatelessWidget {
  /// Cree la vue.
  const VueEtatCommunication({
    required this.etat,
    super.key,
    this.titreVide,
    this.phraseVide,
    this.onReessayer,
    this.portee = PorteeEtat.bloc,
    this.dependance,
  });

  /// L'etat a rendre.
  final EtatCommunication etat;

  /// Le titre du vide propre a l'ecran.
  final String? titreVide;

  /// La phrase du vide propre a l'ecran.
  final String? phraseVide;

  /// Relance la lecture ; sans lui, aucun « Reessayer » n'est rendu.
  final VoidCallback? onReessayer;

  /// Bloc ou page.
  final PorteeEtat portee;

  /// Ce qui manque (`COM-BR-nn`), jamais affiche.
  final String? dependance;

  /// L'etat qui correspond a une erreur de lecture : une capacite absente
  /// n'est pas un echec.
  static EtatCommunication depuisErreur(Object erreur) =>
      erreur is CapaciteIndisponible
      ? EtatCommunication.indisponible
      : EtatCommunication.erreur;

  /// La cle du squelette de chargement, pour les tests.
  static const ValueKey<String> cleChargement = ValueKey<String>(
    'com-etat-chargement',
  );

  @override
  Widget build(BuildContext context) {
    final e = t.com.socle.composants.etats;
    return switch (etat) {
      EtatCommunication.chargement => Semantics(
        key: cleChargement,
        label: e.chargement,
        liveRegion: true,
        child: const ExcludeSemantics(child: Skeleton.liste()),
      ),
      EtatCommunication.vide => EtatSysteme(
        nature: NatureEtat.aucunResultat,
        portee: portee,
        titre: titreVide ?? e.videTitre,
        phrase: phraseVide ?? '',
      ),
      EtatCommunication.erreur => EtatSysteme(
        nature: NatureEtat.echecServeur,
        portee: portee,
        titre: e.erreurTitre,
        phrase: e.erreur,
        libelleAction: e.reessayer,
        onAction: onReessayer,
        dependance: dependance,
      ),
      EtatCommunication.horsLigne => EtatSysteme(
        nature: NatureEtat.horsLigne,
        portee: portee,
        phrase: e.horsLigne,
        libelleAction: e.reessayer,
        onAction: onReessayer,
      ),
      EtatCommunication.indisponible => EtatSysteme(
        nature: NatureEtat.indisponible,
        portee: portee,
        titre: e.indisponibleTitre,
        phrase: e.indisponible,
        dependance: dependance,
      ),
      EtatCommunication.permissionRefusee => EtatSysteme(
        nature: NatureEtat.accesRefuse,
        portee: portee,
        phrase: e.permissionRefusee,
        dependance: dependance,
      ),
    };
  }
}

/// Le bandeau hors ligne des communications : `OfflineBanner`, avec la
/// phrase de la spec (« Les nouveaux messages ne peuvent pas etre
/// actualises »), rendu seulement quand l'appareil est hors ligne. Le contenu
/// deja lu reste affiche dessous.
class BandeauHorsLigneCommunication extends ConsumerWidget {
  /// Cree le bandeau.
  const BandeauHorsLigneCommunication({super.key, this.encadre = false});

  /// Vrai : le bandeau suit les marges de la page.
  final bool encadre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tant que la reponse n'est pas la, l'appareil est repute en ligne, comme
    // `OfflineBanner` : pas de bandeau qui clignote a la premiere image.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    if (!horsLigne) return const SizedBox.shrink();
    return OfflineBanner.message(
      message: t.com.socle.composants.etats.horsLigne,
      encadre: encadre,
    );
  }
}

/// Un bloc de communication qui lit une valeur asynchrone : `BlocAsynchrone`
/// (squelette, chargement prolonge, perte, « Reessayer » borne, capacite
/// indisponible sans « Reessayer »), avec le vide et l'erreur des
/// communications.
class BlocCommunication<T> extends StatelessWidget {
  /// Cree le bloc.
  const BlocCommunication({
    required this.valeur,
    required this.construire,
    super.key,
    this.onReessayer,
    this.titreVide,
    this.phraseVide,
    this.estVide,
    this.squelette = const Skeleton.liste(),
  });

  /// La valeur lue.
  final AsyncValue<T> valeur;

  /// Le contenu.
  final Widget Function(T valeur) construire;

  /// Relance la lecture.
  final VoidCallback? onReessayer;

  /// Le titre du vide propre a l'ecran.
  final String? titreVide;

  /// La phrase du vide propre a l'ecran.
  final String? phraseVide;

  /// Dit si une valeur est vide (par defaut : nulle ou collection vide).
  final bool Function(T valeur)? estVide;

  /// La forme du contenu pendant le chargement.
  final Widget squelette;

  @override
  Widget build(BuildContext context) => BlocAsynchrone<T>(
    valeur: valeur,
    squelette: squelette,
    construire: construire,
    onReessayer: onReessayer,
    estVide: estVide,
    titreEchec: t.com.socle.composants.etats.erreurTitre,
    vide: VueEtatCommunication(
      etat: EtatCommunication.vide,
      titreVide: titreVide,
      phraseVide: phraseVide,
    ),
    // Une capacite absente garde le traitement de BlocAsynchrone (indisponible,
    // sans « Reessayer ») ; un echec prend la phrase des communications.
    erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
        erreur is CapaciteIndisponible
        ? VueEtatCommunication(
            etat: EtatCommunication.indisponible,
            dependance: erreur.dependance,
          )
        : VueEtatCommunication(
            etat: EtatCommunication.erreur,
            onReessayer: reessayer,
          ),
  );
}
