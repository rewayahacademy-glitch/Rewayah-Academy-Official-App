// VISION-RECRUTEMENT (directeur, 14/11/2026) : « Qui attend quoi », au-dessus
// de la file des candidatures.
//
// Trois attentes, rangees selon qui doit agir : l'academie (examen, piece,
// entretien, decision), la personne (candidature a completer), un moyen de
// versement (decision de la direction attendue, CAND-Q05). Chaque ligne dit le
// nombre et depuis quand attend la plus ancienne ; toucher une ligne pose le
// filtre d'etat que `lister_candidatures` connait deja, donc la liste compte
// exactement ce que la ligne annonce. La piece n'a pas de filtre serveur : sa
// ligne ne se touche pas et dit ou la valider.
//
// Ordinateur (840 points et plus) : trois cartes cote a cote, denses, sous le
// titre de section (Material 3, mise en page « supporting pane » ; Nielsen n° 1,
// visibilite de l'etat). En dessous : les memes cartes empilees (K-55, 16).
// Une ligne a zero n'est pas affichee ; une carte sans ligne non plus. Rien
// a attendre : une phrase.
//
// Tout vient du serveur (`attentes_recrutement()`), rien n'est recalcule. Sans
// la migration, la carte ne s'affiche pas (la page garde « A traiter »).
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/attentes_recrutement.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';

/// La phrase « depuis quand » d'une attente, ou `null` sans date.
String? depuisQuand(DateTime? plusAncien, DateTime maintenant) {
  if (plusAncien == null) return null;
  final Duration d = maintenant.difference(plusAncien);
  final a = t.admin.candidatures.attentes;
  // DUREE-INSECABLE : le nombre et son unite ne se separent jamais.
  if (d.inDays >= 1) {
    return LibellesGroupe.insecable(a.depuisJours(n: d.inDays));
  }
  if (d.inHours >= 1) {
    return LibellesGroupe.insecable(a.depuisHeures(n: d.inHours));
  }
  return LibellesGroupe.insecable(
    a.depuisMinutes(n: d.inMinutes < 1 ? 1 : d.inMinutes),
  );
}

String? _lignes(List<String?> morceaux) {
  final List<String> l = <String>[
    for (final String? m in morceaux)
      if (m != null && m.isNotEmpty) m,
  ];
  return l.isEmpty ? null : l.join('\n');
}

/// La carte « Qui attend quoi ».
class CarteAttentes extends StatelessWidget {
  /// Cree la carte.
  const CarteAttentes({
    required this.attentes,
    required this.onFiltrer,
    required this.maintenant,
    this.onFiltrerPause,
    super.key,
  });

  /// Ce que le serveur rend.
  final AttentesRecrutement attentes;

  /// Pose le filtre de l'etat touche.
  final ValueChanged<EtatCandidature> onFiltrer;

  /// Pose le filtre « en pause », ou `null` pour ne pas l'offrir.
  final VoidCallback? onFiltrerPause;

  /// L'instant de reference des durees (injecte pour les tests).
  final DateTime maintenant;

  /// La cle de la section.
  static const Key cleSection = ValueKey<String>('candidatures-attentes');

  /// La cle de la ligne d'un etat.
  static Key cleLigne(EtatCandidature e) =>
      ValueKey<String>('candidatures-attente-${e.valeurSql}');

  /// La cle de la ligne de la piece.
  static const Key clePiece = ValueKey<String>('candidatures-attente-piece');

  /// La cle de la ligne de la pause.
  static const Key clePause = ValueKey<String>('candidatures-attente-pause');

  /// La cle de la phrase « Personne n'attend. ».
  static const Key cleRien = ValueKey<String>('candidatures-attentes-rien');

  @override
  Widget build(BuildContext context) {
    final a = t.admin.candidatures.attentes;
    final e = t.admin.candidatures.etats;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    Widget? ligneEtat(EtatCandidature etat, String titre, {String? aide}) {
      final Attente at = attentes.etat(etat);
      if (at.nombre == 0) return null;
      final String? depuis = depuisQuand(at.plusAncien, maintenant);
      return SettingRow(
        key: cleLigne(etat),
        title: titre,
        value: '${at.nombre}',
        description: _lignes(<String?>[depuis, aide]),
        libelleSemantique: a.filtrer(etat: titre, n: at.nombre),
        onPress: () => onFiltrer(etat),
      );
    }

    final int creneaux = attentes.creneauxOuverts;
    final List<Widget> academie = <Widget>[
      ?ligneEtat(EtatCandidature.enExamen, e.enExamen),
      if (attentes.pieceAValider.nombre > 0)
        SettingRow(
          key: clePiece,
          title: a.pieceAValider,
          value: '${attentes.pieceAValider.nombre}',
          description: _lignes(<String?>[
            depuisQuand(attentes.pieceAValider.plusAncien, maintenant),
            a.pieceAide,
          ]),
        ),
      ?ligneEtat(
        EtatCandidature.entretienAPlanifier,
        e.entretienAPlanifier,
        aide: creneaux == 0 ? a.aucunCreneau : a.creneauxOuverts(n: creneaux),
      ),
      ?ligneEtat(EtatCandidature.entretienPlanifie, e.entretienPlanifie),
      ?ligneEtat(EtatCandidature.decisionEnAttente, e.decisionEnAttente),
    ];
    final List<Widget> personne = <Widget>[
      ?ligneEtat(EtatCandidature.aCompleter, e.aCompleter),
      if (attentes.enPause > 0)
        SettingRow(
          key: clePause,
          title: e.enPause,
          value: '${attentes.enPause}',
          onPress: onFiltrerPause,
        ),
    ];
    final List<Widget> versement = <Widget>[
      ?ligneEtat(
        EtatCandidature.paiementNonDisponible,
        e.versementImpossible,
        aide: a.versementAide,
      ),
    ];

    final List<Widget> cartes = <Widget>[
      if (academie.isNotEmpty) _Groupe(titre: a.academie, lignes: academie),
      if (personne.isNotEmpty) _Groupe(titre: a.personne, lignes: personne),
      if (versement.isNotEmpty) _Groupe(titre: a.versement, lignes: versement),
    ];

    return Column(
      key: cleSection,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(header: true, child: SectionHeader(titre: a.titre)),
        Ecart.vXs,
        TexteSansCoupure(
          attentes.deuxCotes ? '${a.aide} ${a.deuxCotes}' : a.aide,
          style: attenue,
        ),
        Ecart.vMd,
        if (cartes.isEmpty)
          AppCard(
            child: TexteSansCoupure(a.rien, key: cleRien, style: attenue),
          )
        else
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              if (c.maxWidth < 840) {
                return PileCartes(children: cartes);
              }
              return PileCartes(
                axe: Axis.horizontal,
                alignement: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final Widget carte in cartes) Expanded(child: carte),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// Une attente : son titre et ses lignes, dans une seule carte.
class _Groupe extends StatelessWidget {
  const _Groupe({required this.titre, required this.lignes});

  final String titre;
  final List<Widget> lignes;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: TexteSansCoupure(
            titre,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        CarteLignes(lignes: lignes),
      ],
    );
  }
}
