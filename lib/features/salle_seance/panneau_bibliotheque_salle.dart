// Plan de composition du 26/10/2026 (docs/current/maquettes/salle/
// PLAN-SALLE-COMPOSITION-2026-10-26.md §2) : la Bibliotheque de la salle de
// l'enseignant, panneau de droite sur ordinateur, onglet « Support » du
// tiroir au telephone.
//
// Lot SUPPORTS-ETAGERE (directeur, 11/11/2026 ; CAHIER-SALLE §7) : le
// contenu est l'etagere des supports ([EtagereSupports], dans
// `salle_enseignant/etagere_supports.dart`, reutilisable dans « Ma classe ») ;
// ce fichier ne garde que le point d'insertion de la salle, inchange.

import 'package:flutter/material.dart';

import '../salle_enseignant/etagere_supports.dart';

export '../salle_enseignant/etagere_supports.dart'
    show EtatEtagere, FiltreBibliotheque, LecteurSupport, SupportBibliotheque;

/// La Bibliotheque de la salle, dans son panneau.
class PanneauBibliothequeSalle extends StatelessWidget {
  const PanneauBibliothequeSalle({
    required this.supports,
    this.onFermer,
    this.entete = const <Widget>[],
    this.etat = EtatEtagere.pret,
    this.onReessayer,
    super.key,
  });

  final List<SupportBibliotheque> supports;

  /// Ce qui se pose en tete de la liste et defile avec elle (le tiroir du
  /// telephone : le Tableau et « Ranger le support », fiche 1, ligne 9).
  final List<Widget> entete;

  /// La croix « Fermer » et la languette du titre ; `null` : ni l'une ni
  /// l'autre (le tiroir du telephone porte deja son titre et « Reduire »).
  final VoidCallback? onFermer;

  /// L'etat de la lecture des supports.
  final EtatEtagere etat;

  /// Relit les supports apres une erreur.
  final VoidCallback? onReessayer;

  /// La cle du panneau (tests, captures).
  static const Key cle = ValueKey<String>('salle-panneau-bibliotheque');

  @override
  Widget build(BuildContext context) => EtagereSupports(
    cle: cle,
    supports: supports,
    etat: etat,
    onReessayer: onReessayer,
    onFermer: onFermer,
    entete: entete,
  );
}
