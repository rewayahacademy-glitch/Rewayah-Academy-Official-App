// Une candidature dans la file (`ADM-20`) : une ligne du tableau dense au
// bureau, une carte ailleurs. Les deux lisent les memes champs de la meme
// ligne ; aucun n'en recalcule un.
//
// **Jamais dans une ligne** : courriel, telephone, genre, piece, motif interne,
// compte rendu, constat, reponse libre (`CONS` 8.3). `LigneCandidature` n'a pas
// de champ pour les recevoir ; du contact, seules deux marques voyagent, en un
// **repere compact** (une icone, et un texte pour le lecteur d'ecran) dans le
// tableau, en pastilles sur la carte.
//
// **Trois cibles par ligne** (LISTES-1) : la case (retenir la candidature), la
// ligne (ouvrir le dossier) et le menu « ... » (ses gestes), posees l'une a cote
// de l'autre, jamais l'une dans l'autre. La ligne ne coche plus : il n'y a plus
// de « mode selection » a quitter. Le lien d'entretien de la ligne viendra avec
// le lot des entretiens (L4), qui rend la date et la personne qui mene.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/case_a_cocher.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/pays_enseignant.dart';
import '../../core/widgets/status_pill.dart';
import 'libelles_candidatures.dart';

/// Ce que la page sait d'une ligne : retenue ou non, ce que fait le toucher, et
/// son menu.
@immutable
class GestesLigne {
  /// Cree les gestes.
  const GestesLigne({
    required this.retenues,
    this.basculer,
    this.ouvrir,
    this.menu,
  });

  /// Les identifiants retenus.
  final Set<String> retenues;

  /// Retient ou relache la ligne, ou `null` : la selection n'est pas offerte
  /// (le serveur n'ouvre pas le traitement groupe) et aucune case n'est rendue.
  final void Function(LigneCandidature ligne)? basculer;

  /// Ouvre la candidature (`ADM-21`), ou `null` tant qu'il n'y a pas de
  /// destination : la ligne n'est alors pas pressable.
  final void Function(LigneCandidature ligne)? ouvrir;

  /// Le menu d'actions de la ligne, ou `null` : aucune action n'est offerte
  /// (hors ligne, sans le droit de decider). Un menu sans entree n'est pas rendu.
  final Widget Function(BuildContext context, LigneCandidature ligne)? menu;

  /// La selection est offerte.
  bool get selectionPossible => basculer != null;

  /// La ligne est-elle retenue ?
  bool estRetenue(LigneCandidature ligne) => retenues.contains(ligne.id);
}

/// La cle de la ligne ou de la carte d'une candidature, pour les tests.
Key cleCandidature(String id) => ValueKey<String>('candidature-$id');

/// La cle de la case d'une carte de candidature.
Key cleCase(String id) => ValueKey<String>('candidature-case-$id');

/// Le texte d'un instant, en date et heure, dans le fuseau de la personne qui
/// lit : « 22 oct. 2026 » et « 10:24 ».
({String date, String heure}) dateEtHeure(DateTime instant) {
  final DateTime local = instant.toLocal();
  return (
    date: dateCourteCandidature(local),
    heure:
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}',
  );
}

/// L'instant que la colonne de date montre selon le tri : la reception quand le
/// tri est « Date de reception », la derniere activite sinon. Un instant que le
/// serveur n'a pas rendu reste absent, jamais invente.
DateTime? instantDeLaColonne(LigneCandidature ligne, TriCandidatures tri) =>
    tri == TriCandidatures.recente ? ligne.recueLe : ligne.derniereActivite;

/// Les colonnes du tableau dense (bureau), dans l'ordre : nom (avec sa
/// reference), salle, etat, pays de residence, versement, puis derniere
/// activite ou date de reception selon le tri.
///
/// Les en-tetes triables sont ceux des tris que le serveur sert : le nom, et la
/// date (derniere activite ou reception). Aucun tri n'est invente sur une
/// autre colonne.
List<ColonneDonnees<LigneCandidature>> colonnesCandidatures({
  required TriCandidatures tri,
  required ValueChanged<TriCandidatures> onTri,
}) {
  final c = t.admin.candidatures.colonnes;
  final bool parDate = tri != TriCandidatures.nom;
  final TriCandidatures autreDate = tri == TriCandidatures.activite
      ? TriCandidatures.recente
      : TriCandidatures.activite;
  return <ColonneDonnees<LigneCandidature>>[
    ColonneDonnees<LigneCandidature>(
      titre: c.nom,
      texte: nomAffiche,
      role: RoleColonne.identifiante,
      flex: 5,
      rendu: (BuildContext _, LigneCandidature l) => _CelluleNom(ligne: l),
      tri: TriColonne(
        sens: tri == TriCandidatures.nom ? SensTri.croissant : null,
        onTrier: () => onTri(TriCandidatures.nom),
      ),
    ),
    ColonneDonnees<LigneCandidature>(
      titre: t.admin.candidatures.liste.salle,
      texte: (LigneCandidature l) => libelleSalle(l.etape) ?? '',
      flex: 3,
    ),
    ColonneDonnees<LigneCandidature>(
      titre: c.etat,
      texte: (LigneCandidature l) => etatAffiche(l)?.libelle ?? '',
      flex: 3,
      rendu: (BuildContext _, LigneCandidature l) => _PastilleEtat(ligne: l),
    ),
    ColonneDonnees<LigneCandidature>(
      titre: t.admin.candidatures.liste.colonnePays,
      texte: (LigneCandidature l) => libellePays(l.paysResidence) ?? '',
      flex: 2,
      rendu: (BuildContext _, LigneCandidature l) =>
          PaysEnseignant.parCode(codeIso: l.paysResidence),
    ),
    ColonneDonnees<LigneCandidature>(
      titre: c.versement,
      texte: (LigneCandidature l) => libelleVersement(l.paiement),
      flex: 2,
      rendu: (BuildContext _, LigneCandidature l) =>
          _CelluleVersement(ligne: l),
    ),
    ColonneDonnees<LigneCandidature>(
      titre: tri == TriCandidatures.recente
          ? t.admin.candidatures.tri.reception
          : t.admin.candidatures.tri.activite,
      texte: (LigneCandidature l) {
        final DateTime? i = instantDeLaColonne(l, tri);
        if (i == null) return '';
        final ({String date, String heure}) x = dateEtHeure(i);
        return '${x.date} ${x.heure}';
      },
      flex: 2,
      tabulaire: true,
      rendu: (BuildContext _, LigneCandidature l) =>
          _CelluleDate(instant: instantDeLaColonne(l, tri)),
      tri: TriColonne(
        sens: parDate ? SensTri.decroissant : null,
        // Le serveur sert deux ordres de date : un toucher passe de l'un a
        // l'autre ; depuis le tri par nom, il revient a la derniere activite.
        onTrier: () => onTri(parDate ? autreDate : TriCandidatures.activite),
      ),
    ),
  ];
}

/// La seconde ligne du nom : le nom d'origine, garde tel quel (isole pour son
/// sens), puis la reference. Le nom d'origine est en petit : c'est le nom
/// latin qui fait reference (decision du directeur du 23/10/2026).
String secondeLigneNom(LigneCandidature ligne) {
  final String? origine = nomOrigineAffiche(ligne);
  return origine == null
      ? referenceAffichee(ligne)
      : '${isolerSens(origine)} · ${referenceAffichee(ligne)}';
}

/// Le nom de reference d'une ligne (en lettres latines) et, quand il n'est
/// qu'une proposition, la marque « a confirmer » : un mot, jamais la couleur
/// seule.
class NomDeLigne extends StatelessWidget {
  /// Cree le nom.
  const NomDeLigne({required this.ligne, required this.style, super.key});

  /// La ligne.
  final LigneCandidature ligne;

  /// Le style du nom.
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final Widget nom = TexteSansCoupure(nomAffiche(ligne), style: style);
    if (!nomAConfirmer(ligne)) {
      return nom;
    }
    final AppPalette palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(child: nom),
        Ecart.hSm,
        Semantics(
          label: t.admin.candidatures.liste.nomAConfirmerSemantique,
          excludeSemantics: true,
          child: Text(
            t.admin.candidatures.liste.nomAConfirmer,
            style: palette.inkWarning.applyTo(
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}

/// La cellule du nom : le nom, la reference dessous, et le repere des
/// informations manquantes quand il y en a.
class _CelluleNom extends StatelessWidget {
  const _CelluleNom({required this.ligne});

  final LigneCandidature ligne;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final List<String> marques = marquesDeLigne(ligne);
    return Row(
      children: <Widget>[
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              NomDeLigne(
                ligne: ligne,
                style: palette.inkStrong.applyTo(
                  textes.titleSmall ?? const TextStyle(),
                ),
              ),
              TexteSansCoupure(
                secondeLigneNom(ligne),
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ],
          ),
        ),
        if (marques.isNotEmpty) ...<Widget>[
          Ecart.hSm,
          RepereManques(marques: marques),
        ],
      ],
    );
  }
}

/// Le repere compact des informations manquantes d'une ligne : l'icone des
/// « informations manquantes » de la synthese (la meme, pour que la ligne et le
/// compteur se relient), et **ce qui manque, dit en toutes lettres** : au
/// survol et au focus (infobulle), et au lecteur d'ecran (« Informations
/// manquantes : Courriel a obtenir, Indicatif a confirmer »). Il remplace les
/// pastilles empilees, qui doublaient la hauteur de la ligne ; sans l'infobulle,
/// une personne qui voit l'ecran ne savait pas ce qui manquait (relecture du
/// code R-2, relecture visuelle C-06).
class RepereManques extends StatelessWidget {
  /// Cree le repere.
  const RepereManques({required this.marques, super.key});

  /// Ce qui manque, en mots.
  final List<String> marques;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String texte = t.admin.candidatures.liste.repereManques(
      marques: marques.join(t.admin.candidatures.liste.separateurMarques),
    );
    return Tooltip(
      message: texte,
      excludeFromSemantics: true,
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
        label: texte,
        excludeSemantics: true,
        child: Icon(
          AppIcons.info.actif,
          size: AppSpacing.xl,
          color: palette.inkWarning.asIconTheme().color,
        ),
      ),
    );
  }
}

/// L'etat de la ligne, en pastille (mot et point), ou rien.
class _PastilleEtat extends StatelessWidget {
  const _PastilleEtat({required this.ligne});

  final LigneCandidature ligne;

  @override
  Widget build(BuildContext context) {
    final EtatAffiche? etat = etatAffiche(ligne);
    if (etat == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: StatusPill(libelle: etat.libelle, ton: etat.ton),
    );
  }
}

/// Le versement : une icone et son mot (jamais l'icone seule).
class _CelluleVersement extends StatelessWidget {
  const _CelluleVersement({required this.ligne});

  final LigneCandidature ligne;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final (AppIcon icone, Color? couleur) = switch (ligne.paiement) {
      EtatVersement.compatible => (
        AppIcons.succes,
        palette.inkSuccess.asIconTheme().color,
      ),
      EtatVersement.aVerifier => (
        AppIcons.horloge,
        palette.inkMuted.asIconTheme().color,
      ),
      EtatVersement.incompatible => (
        AppIcons.interdit,
        palette.inkAlert.asIconTheme().color,
      ),
      EtatVersement.inconnu => (
        AppIcons.moins,
        palette.inkFaint.asIconTheme().color,
      ),
    };
    return Semantics(
      label:
          '${t.admin.candidatures.colonnes.versement} : '
          '${libelleVersement(ligne.paiement)}',
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          Icon(icone.actif, size: AppSpacing.lg, color: couleur),
          Ecart.hXs,
          Expanded(
            child: TexteSansCoupure(
              libelleVersement(ligne.paiement),
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La date et l'heure d'un instant, sur deux lignes, chiffres tabulaires.
class _CelluleDate extends StatelessWidget {
  const _CelluleDate({required this.instant});

  final DateTime? instant;

  @override
  Widget build(BuildContext context) {
    final DateTime? i = instant;
    if (i == null) {
      return const SizedBox.shrink();
    }
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final ({String date, String heure}) x = dateEtHeure(i);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          x.date,
          style: palette.inkStrong.applyTo(AppTypography.tabulaire(base)),
        ),
        TexteSansCoupure(
          isolerSens(x.heure),
          style: palette.inkMuted.applyTo(AppTypography.tabulaire(base)),
        ),
      ],
    );
  }
}

/// La carte d'une candidature, sur telephone et tablette : le nom et la
/// reference, la salle et l'etat, puis les valeurs avec leur mot (pays,
/// versement, activite ou reception), puis les marques. Tout se replie a 320 de
/// large et a texte double. La case vient avant la carte et le menu apres, hors
/// de la cible de la carte (jamais un bouton dans un bouton).
class CarteCandidature extends StatelessWidget {
  /// Cree la carte.
  const CarteCandidature({
    required this.ligne,
    required this.gestes,
    this.tri = TriCandidatures.activite,
    super.key,
  });

  /// La ligne.
  final LigneCandidature ligne;

  /// Les gestes de la page.
  final GestesLigne gestes;

  /// Le tri : il dit si la carte montre la derniere activite ou la reception.
  final TriCandidatures tri;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final l = t.admin.candidatures.ligne;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final bool retenue = gestes.estRetenue(ligne);
    final String? salle = libelleSalle(ligne.etape);
    final EtatAffiche? etat = etatAffiche(ligne);
    final String? pays = libellePays(ligne.paysResidence);
    final String? detail = detailDate(ligne);
    final List<String> marques = marquesDeLigne(ligne);
    final void Function(LigneCandidature)? ouvrir = gestes.ouvrir;
    // Une carte sans destination n'est pas pressable : ce n'est pas un bouton
    // grise, c'est une carte de lecture.
    final VoidCallback? appui = ouvrir == null ? null : () => ouvrir(ligne);
    final DateTime? instant = instantDeLaColonne(ligne, tri);
    final String? quand = instant == null
        ? null
        : tri == TriCandidatures.recente
        ? t.admin.candidatures.detail.recue(
            date: dateCourteCandidature(instant),
          )
        : l.activite(date: dateCourteCandidature(instant));

    final String semantique = <String>[
      nomAffiche(ligne),
      if (nomAConfirmer(ligne))
        t.admin.candidatures.liste.nomAConfirmerSemantique,
      referenceAffichee(ligne),
      ?salle,
      ?etat?.libelle,
    ].join(', ');

    final double cible = AppMetriques.of(context).cibleTactile;
    final bool aCase = gestes.selectionPossible;
    final Widget? menu = gestes.menu?.call(context, ligne);
    // Les valeurs d'une ligne de texte (pays, versement, activite, date de
    // pause), au lieu d'une ligne par valeur : la carte tenait sur cinq lignes
    // et 235 points, une seule candidature se lisait sur un telephone.
    final String valeurs = enchainer(<String>[
      if (pays != null) l.pays(pays: pays),
      l.versement(etat: libelleVersement(ligne.paiement)),
      ?quand,
      ?detail,
    ], ' · ');

    final Widget carte = AppCard(
      key: cleCandidature(ligne.id),
      onPress: appui,
      libelleSemantique: semantique,
      selectionnee: retenue,
      // La case et le menu sont **dans** la carte (ils pendaient a ses bords et
      // la reduisaient a 262 de large sur 390) : la marge est plus serree, et
      // la rangee du nom leur garde leur place.
      marge: _margeCarte,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: cible),
            child: Row(
              children: <Widget>[
                if (aCase) SizedBox(width: cible),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      NomDeLigne(
                        ligne: ligne,
                        style: palette.inkStrong.applyTo(
                          textes.titleMedium ?? const TextStyle(),
                        ),
                      ),
                      TexteSansCoupure(secondeLigneNom(ligne), style: attenue),
                    ],
                  ),
                ),
                if (menu != null) SizedBox(width: cible),
              ],
            ),
          ),
          if (salle != null || etat != null) ...<Widget>[
            Ecart.vSm,
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (salle != null)
                  TexteSansCoupure(
                    salle,
                    style: palette.inkStrong.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                if (etat != null)
                  StatusPill(libelle: etat.libelle, ton: etat.ton),
              ],
            ),
          ],
          Ecart.vSm,
          TexteSansCoupure(valeurs, style: attenue),
          if (marques.isNotEmpty) ...<Widget>[
            Ecart.vSm,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  AppIcons.info.actif,
                  size: AppSpacing.lg,
                  color: palette.inkWarning.asIconTheme().color,
                ),
                Ecart.hXs,
                Expanded(
                  child: TexteSansCoupure(
                    marques.join(t.admin.candidatures.liste.separateurMarques),
                    style: palette.inkWarning.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (!aCase && menu == null) return carte;
    // Superposees a la carte, **hors de sa cible** : la case et le menu sont
    // deux arrets de tabulation, jamais un bouton dans un bouton.
    const double decalage = _margeCarte + 1;
    return Stack(
      children: <Widget>[
        carte,
        if (aCase)
          PositionedDirectional(
            start: decalage,
            top: decalage,
            child: CaseACocher(
              key: cleCase(ligne.id),
              valeur: retenue,
              libelle: t.commun.listes.cocherLigne(objet: nomAffiche(ligne)),
              onChange: (bool _) => gestes.basculer!(ligne),
            ),
          ),
        if (menu != null)
          PositionedDirectional(end: decalage, top: decalage, child: menu),
      ],
    );
  }

  /// La marge d'une carte de la file : serree, la liste est le contenu.
  static const double _margeCarte = AppSpacing.md;
}
