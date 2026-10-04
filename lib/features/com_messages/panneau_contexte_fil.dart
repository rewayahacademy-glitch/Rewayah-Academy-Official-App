// Le panneau de contexte d'un fil metier (`ThreadContextPanel`, spec
// section 19 « objet, participants, raccourcis » ; COM-W01, colonne de
// droite ; spec section 25 « objet lie inaccessible », « piece jointe
// indisponible »).
//
// Trois blocs, rendus seulement s'ils ont quelque chose a dire (aucune
// section vide decorative) :
//
// - les objets lies : chacun ouvre son module canonique (le raccourci du
//   fil, spec section 14), et seulement s'il a une destination et qu'il est
//   encore accessible ; sinon il est nomme sans chevron, avec la raison ;
// - les participants : nom et fonction deja rediges, jamais une coordonnee
//   (spec section 3.1) ;
// - les fichiers partages du fil : cartes du socle, sans URL ni chemin.
//
// Ce qu'on ne reprend pas de la maquette : « Parametres de la conversation »
// (Suivi, Mode silencieux), « Voir tout », la presence en ligne et les menus
// de participant n'ont aucun contrat (UX_REVIEW L0, ecart 13).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/communications/carte_piece_jointe.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/pile_cartes.dart';
import 'entete_fil_contexte.dart';
import 'port_messages_metier.dart';

/// Le panneau de contexte d'un fil (`ThreadContextPanel`).
///
/// Un contenu a hauteur naturelle : l'espace de travail le fait defiler, en
/// colonne comme en feuille.
class PanneauContexteFil extends StatelessWidget {
  /// Cree le panneau du fil [fil].
  const PanneauContexteFil({required this.fil, super.key, this.onOuvrirObjet});

  /// Le fil ouvert.
  final FilMetier fil;

  /// Ouvre un objet lie a son chemin interne ; par defaut, le routeur.
  final ValueChanged<String>? onOuvrirObjet;

  /// La cle du bloc des objets lies, pour les tests.
  static const ValueKey<String> cleObjets = ValueKey<String>('panneau-objets');

  /// La cle du bloc des participants, pour les tests.
  static const ValueKey<String> cleParticipants = ValueKey<String>(
    'panneau-participants',
  );

  /// La cle du bloc des fichiers, pour les tests.
  static const ValueKey<String> cleFichiers = ValueKey<String>(
    'panneau-fichiers',
  );

  void _ouvrir(BuildContext context, String chemin) {
    final ValueChanged<String>? ouvrir = onOuvrirObjet;
    if (ouvrir != null) {
      ouvrir(chemin);
    } else {
      GoRouter.of(context).go(chemin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = t.com.messages.panneau;
    final List<PieceJointe> pieces = fil.piecesJointes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GroupeReglages(
          key: cleObjets,
          titre: p.objets,
          lignes: <LigneRubrique>[
            for (final ElementContexteFil e in fil.contexte)
              _ligneObjet(context, e),
          ],
        ),
        Ecart.vXl,
        GroupeReglages(
          key: cleParticipants,
          titre: p.participants,
          lignes: <LigneRubrique>[
            for (final Participant q in fil.participants)
              LigneRubrique(
                meneur: AvatarTile(
                  prenom: q.nomAffiche,
                  diametre: AppAvatar.petit,
                ),
                libelle: q.nomAffiche,
                legende: q.estSoi ? p.vous : q.fonction,
              ),
          ],
        ),
        if (pieces.isNotEmpty) ...<Widget>[
          Ecart.vXl,
          Semantics(
            header: true,
            child: Text(
              p.fichiers,
              style: AppPalette.of(context).inkStrong.applyTo(
                Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
          PileCartes(
            key: cleFichiers,
            children: <Widget>[
              // L'ouverture passera par un jeton ephemere (COM-BR-04) : tant
              // qu'il n'existe pas, « Ouvrir » n'est pas rendu.
              for (final PieceJointe piece in pieces)
                CartePieceJointe(piece: piece),
            ],
          ),
        ],
      ],
    );
  }

  LigneRubrique _ligneObjet(BuildContext context, ElementContexteFil e) {
    final p = t.com.messages.panneau;
    final AppIcon icone = iconeTypeObjet(e.objet.type);
    final String legende = e.accessible
        ? libelleTypeObjet(e.objet.type)
        : p.inaccessible;
    final String? chemin = e.destination;
    // Sans destination (ou objet devenu inaccessible), la ligne nomme l'objet
    // sans chevron ni geste : rien n'est grise (R-COM-11).
    if (chemin == null) {
      return LigneRubrique(
        icone: icone,
        libelle: e.objet.libelle,
        legende: legende,
      );
    }
    return LigneRubrique(
      icone: icone,
      libelle: e.objet.libelle,
      legende: legende,
      libelleSemantique: p.ouvrir(objet: e.objet.libelle),
      onPress: () => _ouvrir(context, chemin),
    );
  }
}
