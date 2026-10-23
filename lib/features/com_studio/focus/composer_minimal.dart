// Le Studio, Mode focus : le champ minimal (`MinimalComposer`, COM-STU-3 ;
// spec section 10.1, section 10.4, section 10.6, section 23 « Focus »).
//
// Il n'y a PAS de second champ : c'est celui du fil (`FilDiscussion`, socle),
// le meme controleur, le meme brouillon, les memes envois en attente. Un
// second champ en Focus obligerait a recopier le texte a l'entree et a la
// sortie, et un envoi parti de l'un ne serait pas suivi par l'autre. Le
// champ minimal est donc une REGLE sur ce que le champ du canal garde autour
// de lui :
//
// - toujours le champ et « Envoyer », des que la personne peut ecrire
//   (section 10.6 : le Focus ne supprime jamais le champ) ; un canal en
//   lecture seule garde sa phrase qui dit la limite ;
// - le vocal du fil (section 10.4 : « documents et vocaux du fil » restent) ;
// - les pieces deja jointes au message en preparation (jamais perdues) ;
// - mais pas l'entree « Joindre un fichier » ni les autres outils de
//   redaction, qui reviennent a la sortie du Focus.
//
// Depuis COM-FUS, le canal pose le composer vocal (`ComposerVocal`) quand la
// capacite `envoyerVocal` est ouverte : il reste en Focus. Il ne pose pas
// encore de piece jointe (aucun contrat d'envoi, COM-BR-04). La regle ne
// change pas la forme de l'arbre du fil (le champ garde son texte d'une
// disposition a l'autre).

import 'package:flutter/widgets.dart';

import '../../../core/theme/app_spacing.dart';

/// Ce que le champ d'un canal porte autour de lui, hors Focus et en Focus
/// (`MinimalComposer`).
@immutable
class ComposerMinimal {
  /// Cree la regle avec les emplacements que le canal sait poser.
  const ComposerMinimal({
    this.piecesEnPreparation,
    this.entreeJoindre,
    this.vocal,
  });

  /// Les cartes des pieces deja jointes au message en preparation, ou nul.
  final Widget? piecesEnPreparation;

  /// L'entree « Joindre un fichier », ou nul.
  final Widget? entreeJoindre;

  /// Le message vocal du champ, ou nul.
  final Widget? vocal;

  /// L'emplacement pose au-dessus du champ (`emplacementPieceJointe` du
  /// fil) : en Focus, seulement les pieces deja jointes ; sinon, les pieces
  /// puis l'entree « Joindre ». Nul s'il n'y a rien a poser : aucune place
  /// n'est reservee.
  Widget? emplacementPieceJointe({required bool focus}) {
    final Widget? pieces = piecesEnPreparation;
    final Widget? joindre = focus ? null : entreeJoindre;
    if (pieces == null) return joindre;
    if (joindre == null) return pieces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[pieces, Ecart.vSm, joindre],
    );
  }

  /// L'emplacement du vocal (`emplacementVocal` du fil) : le meme en Focus
  /// et hors Focus.
  Widget? emplacementVocal({required bool focus}) => vocal;
}
