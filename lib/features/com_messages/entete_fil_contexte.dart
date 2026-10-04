// L'en-tete contextuel d'un fil metier (`ContextThreadHeader`, spec
// section 19, section 20 ; COM-M01 « header contextuel, identite autorisee,
// contexte Classe/eleve »).
//
// Il recoit un modele DEJA NETTOYE par le port (spec section 20) : les
// interlocuteurs autorises, les objets du fil (Classe, eleve, dossier,
// mission, autre objet autorise) et l'indicateur d'attention. Il ne lit aucun
// role et n'affiche aucune coordonnee : le `Participant` du socle n'en porte
// pas. Les mises en mots partagees par la liste, le panneau et le fil
// (noms, objets, nature d'objet) vivent ici, une seule fois.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/communications/badge_non_lu.dart';
import 'port_messages_metier.dart';

/// Le nom d'un participant, avec sa fonction quand le port la donne :
/// « Mme Mariam, Enseignante de la Classe ».
String nomParticipant(Participant p) {
  final String? fonction = p.fonction;
  return fonction == null || fonction.isEmpty
      ? p.nomAffiche
      : t.com.messages.noms.avecFonction(nom: p.nomAffiche, fonction: fonction);
}

/// Les interlocuteurs d'un fil, en une ligne : un seul avec sa fonction ;
/// deux par leurs noms ; au-dela, le premier et le nombre des autres.
String nomsInterlocuteurs(List<Participant> interlocuteurs) {
  final n = t.com.messages.noms;
  return switch (interlocuteurs) {
    <Participant>[] => '',
    <Participant>[final Participant seul] => nomParticipant(seul),
    <Participant>[final Participant a, final Participant b] => n.deux(
      premier: a.nomAffiche,
      second: b.nomAffiche,
    ),
    <Participant>[final Participant a, ...] => n.plusieurs(
      premier: a.nomAffiche,
      nombre: interlocuteurs.length - 1,
    ),
  };
}

/// Les objets d'un fil, en une ligne : « Classe An-Nour · Adam ».
String libelleObjets(List<ObjetLie> objets) {
  if (objets.isEmpty) return '';
  return objets
      .skip(1)
      .fold(
        objets.first.libelle,
        (String acc, ObjetLie o) =>
            t.com.messages.entete.deuxObjets(premier: acc, second: o.libelle),
      );
}

/// Le nom de la nature d'un objet : « Classe », « Mission de controle ».
String libelleTypeObjet(TypeObjetLie type) {
  final x = t.com.messages.types;
  return switch (type) {
    TypeObjetLie.classe => x.classe,
    TypeObjetLie.eleve => x.eleve,
    TypeObjetLie.dossier => x.dossier,
    TypeObjetLie.mission => x.mission,
    TypeObjetLie.remplacement => x.remplacement,
    TypeObjetLie.publication ||
    TypeObjetLie.canal ||
    TypeObjetLie.message ||
    TypeObjetLie.annonce ||
    TypeObjetLie.autre => x.autre,
  };
}

/// L'icone de la nature d'un objet.
AppIcon iconeTypeObjet(TypeObjetLie type) => switch (type) {
  TypeObjetLie.classe => AppIcons.classes,
  TypeObjetLie.eleve => AppIcons.eleves,
  TypeObjetLie.dossier => AppIcons.dossiers,
  TypeObjetLie.mission => AppIcons.controleQualite,
  TypeObjetLie.remplacement => AppIcons.reaffectation,
  TypeObjetLie.publication ||
  TypeObjetLie.canal ||
  TypeObjetLie.message ||
  TypeObjetLie.annonce ||
  TypeObjetLie.autre => AppIcons.discussion,
};

/// L'en-tete contextuel d'un fil (`ContextThreadHeader`).
///
/// Une rangee : le cercle du premier interlocuteur, ses noms (identite
/// autorisee), la ligne des objets du fil, et le badge d'attention s'il a
/// quelque chose a dire. Le lecteur d'ecran l'entend d'un bloc, comme un
/// titre : « Conversation avec Ahmed, parent d'Adam, a propos de Classe
/// An-Nour · Adam ».
class EnteteFilContexte extends StatelessWidget {
  /// Cree l'en-tete.
  const EnteteFilContexte({
    required this.interlocuteurs,
    required this.objets,
    super.key,
    this.attention = IndicateurAttention.aucun,
  });

  /// Construit l'en-tete d'un fil ouvert.
  EnteteFilContexte.duFil(FilMetier fil, {Key? key})
    : this(
        key: key,
        interlocuteurs: fil.interlocuteurs,
        objets: <ObjetLie>[
          for (final ElementContexteFil e in fil.contexte) e.objet,
        ],
        attention: fil.attention,
      );

  /// Les autres personnes du fil, deja autorisees.
  final List<Participant> interlocuteurs;

  /// Les objets du fil, le principal d'abord.
  final List<ObjetLie> objets;

  /// Ce que le badge doit dire.
  final IndicateurAttention attention;

  /// La cle de l'en-tete, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('entete-fil-contexte');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String noms = nomsInterlocuteurs(interlocuteurs);
    final String ligneObjets = libelleObjets(objets);
    final String prenom = interlocuteurs.isEmpty
        ? ligneObjets
        : interlocuteurs.first.nomAffiche;
    // Le fil ouvert est en train d'etre lu : l'en-tete ne recompte pas ses
    // non-lus, il garde ce qui demande encore quelque chose (action requise,
    // urgence, mention).
    final IndicateurAttention reste = IndicateurAttention(
      niveau: attention.niveau.estAuMoins(NiveauAttention.actionRequise)
          ? attention.niveau
          : NiveauAttention.information,
      mention: attention.mention,
    );
    final String? phraseAttention = BadgeNonLu.phraseSemantique(reste);
    final String phrase = t.com.messages.entete.semantique(
      noms: noms,
      objets: ligneObjets,
    );
    return Semantics(
      key: cle,
      container: true,
      header: true,
      // Le badge est lu avec l'en-tete : un seul bloc pour le lecteur d'ecran.
      label: phraseAttention == null
          ? phrase
          : t.com.messages.entete.avecAttention(
              entete: phrase,
              attention: phraseAttention,
            ),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AvatarNom.enLigne(
              prenom: prenom,
              nom: noms,
              role: ligneObjets,
              styleNom: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
            // Sous l'identite, jamais a cote : a texte agrandi, le badge ne
            // reduit pas la colonne des noms a un mot par ligne.
            if (reste.estVisible) ...<Widget>[
              Ecart.vSm,
              BadgeNonLu(indicateur: reste),
            ],
          ],
        ),
      ),
    );
  }
}
