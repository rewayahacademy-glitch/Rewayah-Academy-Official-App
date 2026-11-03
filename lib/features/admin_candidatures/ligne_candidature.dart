// Une candidature dans la file (`ADM-20`) : une ligne du tableau dense au
// bureau, une carte ailleurs. Les deux lisent les memes champs de la meme
// ligne ; aucun n'en recalcule un.
//
// **Jamais dans une ligne** : courriel, telephone, genre, piece, motif interne,
// compte rendu, constat, reponse libre (`CONS` 8.3). `LigneCandidature` n'a pas
// de champ pour les recevoir ; du contact, seules deux marques s'affichent
// (« Courriel a obtenir », « Indicatif a confirmer »).
//
// **Une cible par ligne aujourd'hui** : hors selection, la ligne entiere ouvre
// la candidature quand une destination existe (`ADM-21`), sinon elle ne se
// touche pas ; en selection, elle coche sa case. La case est un indicateur
// d'etat de la ligne (clavier et lecteur d'ecran passent par la ligne), jamais
// une seconde cible imbriquee. Le lien d'entretien de la ligne viendra avec le
// lot des entretiens (L4), qui rend la date et la personne qui mene.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/status_pill.dart';
import 'libelles_candidatures.dart';

/// Ce que la page sait d'une ligne : retenue ou non, et en mode selection.
@immutable
class GestesLigne {
  /// Cree les gestes.
  const GestesLigne({
    required this.enSelection,
    required this.retenues,
    required this.basculer,
    this.ouvrir,
  });

  /// La page est en mode selection : la ligne coche sa case au lieu d'ouvrir.
  final bool enSelection;

  /// Les identifiants retenus.
  final Set<String> retenues;

  /// Retient ou relache la ligne.
  final void Function(LigneCandidature ligne) basculer;

  /// Ouvre la candidature (`ADM-21`), ou `null` tant qu'il n'y a pas de
  /// destination : la ligne n'est alors pas pressable hors selection.
  final void Function(LigneCandidature ligne)? ouvrir;

  /// La ligne est-elle retenue ?
  bool estRetenue(LigneCandidature ligne) => retenues.contains(ligne.id);

  /// Ce que fait le toucher de la ligne, ou `null` : rien a faire.
  void Function(LigneCandidature ligne)? get auToucher =>
      enSelection ? basculer : ouvrir;
}

/// La cle de la ligne ou de la carte d'une candidature, pour les tests.
Key cleCandidature(String id) => ValueKey<String>('candidature-$id');

/// La cle de l'indicateur de case d'une candidature.
Key cleCase(String id) => ValueKey<String>('candidature-case-$id');

/// Les colonnes du tableau dense (bureau), dans l'ordre : case en mode
/// selection, nom, salle, etat, pays de residence, versement, derniere
/// activite.
List<ColonneDonnees<LigneCandidature>> colonnesCandidatures(
  GestesLigne gestes,
) {
  final c = t.admin.candidatures.colonnes;
  return <ColonneDonnees<LigneCandidature>>[
    if (gestes.enSelection)
      ColonneDonnees<LigneCandidature>(
        titre: '',
        texte: (LigneCandidature l) => '',
        flex: 1,
        rendu: (BuildContext _, LigneCandidature l) =>
            IndicateurCase(ligne: l, retenue: gestes.estRetenue(l)),
      ),
    ColonneDonnees<LigneCandidature>(
      titre: c.nom,
      texte: nomAffiche,
      role: RoleColonne.identifiante,
      flex: 5,
      rendu: (BuildContext _, LigneCandidature l) => _CelluleNom(ligne: l),
    ),
    ColonneDonnees<LigneCandidature>(
      titre: c.salle,
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
      titre: c.pays,
      texte: (LigneCandidature l) => libellePays(l.paysResidence) ?? '',
      flex: 2,
    ),
    ColonneDonnees<LigneCandidature>(
      titre: c.versement,
      texte: (LigneCandidature l) => libelleVersement(l.paiement),
      flex: 2,
    ),
    ColonneDonnees<LigneCandidature>(
      titre: c.activite,
      texte: activiteAffichee,
      flex: 2,
      tabulaire: true,
    ),
  ];
}

/// L'indicateur de case d'une ligne en selection : montre l'etat, ne se touche
/// pas (la ligne entiere est la cible), muet pour le lecteur d'ecran qui lit
/// l'etat sur la ligne.
class IndicateurCase extends StatelessWidget {
  /// Cree l'indicateur.
  const IndicateurCase({
    required this.ligne,
    required this.retenue,
    super.key,
  });

  /// La ligne.
  final LigneCandidature ligne;

  /// Vrai quand la ligne est retenue.
  final bool retenue;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ExcludeFocus(
      child: IgnorePointer(
        child: Checkbox(
          key: cleCase(ligne.id),
          value: retenue,
          onChanged: (bool? _) {},
        ),
      ),
    ),
  );
}

/// La cellule du nom : le nom, la reference, puis les marques.
class _CelluleNom extends StatelessWidget {
  const _CelluleNom({required this.ligne});

  final LigneCandidature ligne;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final List<String> marques = marquesDeLigne(ligne);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          nomAffiche(ligne),
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        TexteSansCoupure(
          referenceAffichee(ligne),
          style: palette.inkMuted.applyTo(textes.bodySmall ?? const TextStyle()),
        ),
        if (marques.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final String m in marques)
                StatusPill(libelle: m, ton: TonEtat.avertissement),
            ],
          ),
        ],
      ],
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

/// La carte d'une candidature, sur telephone et tablette : le nom et la
/// reference, la salle et l'etat, puis les valeurs avec leur mot (pays,
/// versement, activite), puis les marques. Tout se replie a 320 de large et a
/// texte double.
class CarteCandidature extends StatelessWidget {
  /// Cree la carte.
  const CarteCandidature({required this.ligne, required this.gestes, super.key});

  /// La ligne.
  final LigneCandidature ligne;

  /// Les gestes de la page.
  final GestesLigne gestes;

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
    final void Function(LigneCandidature)? toucher = gestes.auToucher;
    // Une carte sans destination n'est pas pressable : ce n'est pas un bouton
    // grise, c'est une carte de lecture.
    final VoidCallback? appui = toucher == null ? null : () => toucher(ligne);

    final String semantique = <String>[
      nomAffiche(ligne),
      referenceAffichee(ligne),
      ?salle,
      ?etat?.libelle,
    ].join(', ');

    return AppCard(
      key: cleCandidature(ligne.id),
      onPress: appui,
      libelleSemantique: semantique,
      selectionnee: gestes.enSelection && retenue,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (gestes.enSelection) ...<Widget>[
            IndicateurCase(ligne: ligne, retenue: retenue),
            Ecart.hSm,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TexteSansCoupure(
                  nomAffiche(ligne),
                  style: palette.inkStrong.applyTo(
                    textes.titleMedium ?? const TextStyle(),
                  ),
                ),
                Ecart.vXs,
                TexteSansCoupure(referenceAffichee(ligne), style: attenue),
                if (salle != null || etat != null) ...<Widget>[
                  Ecart.vSm,
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
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
                if (pays != null)
                  TexteSansCoupure(l.pays(pays: pays), style: attenue),
                TexteSansCoupure(
                  l.versement(etat: libelleVersement(ligne.paiement)),
                  style: attenue,
                ),
                TexteSansCoupure(
                  l.activite(date: activiteAffichee(ligne)),
                  style: attenue,
                ),
                if (detail != null) TexteSansCoupure(detail, style: attenue),
                if (marques.isNotEmpty) ...<Widget>[
                  Ecart.vSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final String m in marques)
                        StatusPill(libelle: m, ton: TonEtat.avertissement),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
