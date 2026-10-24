// La troisieme etape de « Vos autres talents » (`CAND-07`) : le niveau, competence
// par competence.
//
// Trois niveaux, dans les mots de la personne : « Je debute », « J'ai de
// l'experience », « C'est mon metier ». Une legende dit une fois ce que chacun
// veut dire (K-58) ; ensuite, un controle segmente par competence, dans UNE
// grande carte a lignes fines (des contenus lies, K-55). Aucun niveau n'est
// choisi d'avance : rien n'est presume (K-57), et « Continuer » dit lequel
// manque.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/choice_card_group.dart' show RadioChoix;
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/pressable.dart';
import 'controleur_talents.dart';
import 'libelles_talents.dart';

/// Le corps de l'etape des niveaux.
class EtapeNiveaux extends StatelessWidget {
  /// Cree le corps.
  const EtapeNiveaux({required this.controleur, super.key});

  /// Le parcours.
  final ControleurTalents controleur;

  /// La cle de la legende des trois niveaux.
  static const Key legendeKey = ValueKey<String>('talents-legende');

  /// La cle de la carte qui porte une ligne par competence.
  static const Key listeKey = ValueKey<String>('talents-niveaux');

  /// La cle de la ligne d'une competence.
  static Key ligneKey(String code) => ValueKey<String>('talents-niveau-$code');

  @override
  Widget build(BuildContext context) => PileCartes(
    children: <Widget>[
      const _Legende(key: legendeKey),
      CarteGroupee(
        key: listeKey,
        sections: <Widget>[
          for (final EntreeCatalogue e in controleur.competencesChoisies)
            _Ligne(
              key: ligneKey(e.code),
              entree: e,
              niveau: controleur.niveau(e.code),
              onChoix: (NiveauCompetence n) =>
                  controleur.definirNiveau(e.code, n),
            ),
        ],
      ),
    ],
  );
}

/// Ce que veut dire chaque niveau.
class _Legende extends StatelessWidget {
  const _Legende({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(
              t.recrutement.talents.niveaux.legende,
              style: textes.titleMedium,
            ),
          ),
          Ecart.vMd,
          // Cote a cote quand la place le permet (les trois niveaux d'un coup
          // d'oeil), empiles sinon.
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final bool cote =
                  c.maxWidth >= 560 &&
                  MediaQuery.textScalerOf(context).scale(16) / 16 <= 1.3;
              final List<Widget> niveaux = <Widget>[
                for (final NiveauCompetence n in NiveauCompetence.values)
                  _Niveau(niveau: n),
              ];
              if (cote) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final (int i, Widget w)
                        in niveaux.indexed) ...<Widget>[
                      if (i > 0) Ecart.hXl,
                      Expanded(child: w),
                    ],
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final (int i, Widget w) in niveaux.indexed) ...<Widget>[
                    if (i > 0) Ecart.vMd,
                    w,
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Un niveau et ce qu'il veut dire.
class _Niveau extends StatelessWidget {
  const _Niveau({required this.niveau});

  final NiveauCompetence niveau;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TexteSansCoupure(
            libelleNiveau(niveau),
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          TexteSansCoupure(
            descriptionNiveau(niveau),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une competence et son controle de niveau : cote a cote quand la place le
/// permet, empiles sinon (telephone, texte agrandi).
///
/// Le controle lui-meme suit la place : trois segments quand le mot le plus
/// long de leurs libelles tient dans un segment, sans etre coupe ni reduit ;
/// sinon trois lignes a choix unique, l'une sous l'autre (320 px, texte x2,
/// arabe). Jamais un mot coupe pour garder les segments (K-54).
class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.entree,
    required this.niveau,
    required this.onChoix,
    super.key,
  });

  final EntreeCatalogue entree;
  final NiveauCompetence? niveau;
  final ValueChanged<NiveauCompetence> onChoix;

  /// Vrai quand les trois libelles tiennent chacun dans un segment de
  /// [largeur] / 3, a l'echelle du texte de l'appareil : la place d'un
  /// segment est sa part, moins la marge de la piste (4 de chaque cote) et
  /// le retrait de son libelle (8 de chaque cote).
  static bool _tientEnSegments(BuildContext context, double largeur) {
    final TextStyle? style = Theme.of(context).textTheme.labelLarge;
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final double place =
        largeur / NiveauCompetence.values.length -
        2 * (AppSpacing.xs + AppSpacing.sm) -
        2;
    for (final NiveauCompetence n in NiveauCompetence.values) {
      if (largeurMotLePlusLong(context, libelleNiveau(n), style, echelle) >
          place) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle titre =
        Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    final String nom = textesCompetence(entree).libelle;
    void choisir(NiveauCompetence? n) {
      if (n != null) {
        onChoix(n);
      }
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool cote =
            c.maxWidth >= 560 &&
            MediaQuery.textScalerOf(context).scale(16) / 16 <= seuilTexteEmpile;
        // La largeur du controle : trois cinquiemes de la ligne quand le nom
        // est a sa gauche (apres l'ecart), toute la ligne sinon.
        final double largeurControle = cote
            ? (c.maxWidth - AppSpacing.xl) * 3 / 5
            : c.maxWidth;
        final Widget controle = Semantics(
          container: true,
          label: t.recrutement.talents.niveaux.niveauDe(competence: nom),
          child: _tientEnSegments(context, largeurControle)
              ? ControleSegmente<NiveauCompetence?>(
                  segments: <Segment<NiveauCompetence?>>[
                    for (final NiveauCompetence n in NiveauCompetence.values)
                      Segment<NiveauCompetence?>(
                        valeur: n,
                        libelle: libelleNiveau(n),
                      ),
                  ],
                  valeur: niveau,
                  onChange: choisir,
                )
              : _ChoixEmpile(niveau: niveau, onChoix: onChoix),
        );
        if (cote) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(flex: 2, child: TexteSansCoupure(nom, style: titre)),
              Ecart.hXl,
              Expanded(flex: 3, child: controle),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TexteSansCoupure(nom, style: titre),
            Ecart.vMd,
            controle,
          ],
        );
      },
    );
  }
}

/// Les trois niveaux en lignes a choix unique, l'une sous l'autre : le repli
/// du controle segmente quand un libelle n'y tient pas. Un radio et le libelle
/// entier ; la ligne retenue prend le fond doux et le filet d'accent (la
/// selection ne repose jamais sur la seule couleur : le radio se remplit).
class _ChoixEmpile extends StatelessWidget {
  const _ChoixEmpile({required this.niveau, required this.onChoix});

  final NiveauCompetence? niveau;
  final ValueChanged<NiveauCompetence> onChoix;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final (int i, NiveauCompetence n)
          in NiveauCompetence.values.indexed) ...<Widget>[
        if (i > 0) Ecart.vXs,
        _OptionNiveau(niveau: n, retenue: n == niveau, onChoix: onChoix),
      ],
    ],
  );
}

class _OptionNiveau extends StatelessWidget {
  const _OptionNiveau({
    required this.niveau,
    required this.retenue,
    required this.onChoix,
  });

  final NiveauCompetence niveau;
  final bool retenue;
  final ValueChanged<NiveauCompetence> onChoix;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    final String libelle = libelleNiveau(niveau);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      child: Pressable.selon(
        // La ligne deja retenue reste un bouton actif (sinon elle serait
        // annoncee « desactivee ») ; la presser ne fait rien.
        onPress: () {
          if (!retenue) {
            onChoix(niveau);
          }
        },
        selectionne: retenue,
        libelleSemantique: libelle,
        arrondiFocus: AppRadius.arrondiMd,
        constructeur: (BuildContext contexte, EtatPression etat) =>
            DecoratedBox(
              decoration: retenue
                  ? palette.washAccent.decoration(
                      borderRadius: AppRadius.arrondiMd,
                      side: palette.inkAccent.asBorderSide(),
                    )
                  : BoxDecoration(
                      borderRadius: AppRadius.arrondiMd,
                      color: etat.survole || etat.presse
                          ? palette.calqueInteraction(presse: etat.presse)
                          : null,
                    ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    RadioChoix(retenue: retenue),
                    Ecart.hMd,
                    Expanded(
                      child: TexteSansCoupure(
                        libelle,
                        style: retenue
                            ? palette.washAccent.applyTo(base)
                            : palette.inkStrong.applyTo(base),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
