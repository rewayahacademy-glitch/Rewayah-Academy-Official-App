// Mes revenus de l'enseignant (FI-10, guide Finance V4 §1.4, §4, §5.5 et §8
// F6 ; maquette 17_finance/V/08).
//
// **Une estimation, jamais une paie definitive** : le mot est ecrit en tete,
// et la mention de bas de page dit que le releve de l'academie fait foi.
// Par Classe : heures assurees, capacite, sieges eligibles, taux horaire
// effectif, montant estime ; puis l'explication simple (base garantie,
// composante d'occupation, plafond) et l'aide Internet, a part.
//
// Tout chiffre d'argent vient du port (`PortRevenusEnseignant`) : l'ecran ne
// calcule ni taux ni montant (FI6). Aucune donnee de famille : ni prenom
// d'eleve, ni solde, ni montant paye par un eleve (guide §5.5).
//
// Hors de la maquette, et pour cause : l'historique des paiements et les
// variations « vs mois precedent » n'existent dans aucun contrat (FI-BR-11) ;
// ils ne sont pas inventes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_revenus_enseignant.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/ligne_finance.dart';
import '../../core/widgets/montant_argent.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

/// Les revenus estimes du mois en cours, lus par le port (FI-BR-11). Aucune
/// relance automatique : une capacite absente ne revient pas en insistant,
/// et « Reessayer » reste un geste de la personne (`BlocAsynchrone`).
final FutureProvider<RevenusEnseignant> revenusEnseignantProvider =
    FutureProvider<RevenusEnseignant>(
      (Ref ref) => ref.watch(portRevenusEnseignantProvider).moisEnCours(),
      retry: (int retryCount, Object error) => null,
    );

/// `/enseignant/revenus` : l'estimation du mois, atteinte depuis le Profil.
class RevenusEnseignantPage extends ConsumerWidget {
  /// Cree l'ecran.
  const RevenusEnseignantPage({super.key, this.onRetour});

  /// Le retour au Profil. Nul : la pile du routeur, sinon `/enseignant/profil`.
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageShell(
      titre: t.enseignant.revenus.titre,
      entete: Text(t.enseignant.revenus.intro),
      onRetour: onRetour ?? () => _retour(context),
      child: BlocAsynchrone<RevenusEnseignant>(
        valeur: ref.watch(revenusEnseignantProvider),
        squelette: const Skeleton.liste(lignes: 6),
        onReessayer: () => ref.invalidate(revenusEnseignantProvider),
        estVide: (RevenusEnseignant r) => r.classes.isEmpty,
        vide: EmptyState(
          message: t.enseignant.revenus.vide,
          invitation: t.enseignant.revenus.videDetail,
          icone: AppIcons.finance,
          registre: RegistreVide.subi,
        ),
        construire: (RevenusEnseignant r) => _Corps(revenus: r),
      ),
    );
  }

  static void _retour(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.enseignantProfil);
    }
  }
}

/// Le corps : une colonne sur telephone, deux sur bureau.
class _Corps extends StatelessWidget {
  const _Corps({required this.revenus});

  final RevenusEnseignant revenus;

  @override
  Widget build(BuildContext context) {
    final Widget principal = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Resume(revenus: revenus),
        Ecart.vSection,
        SectionHeader(titre: t.enseignant.revenus.detailSection),
        _DetailClasses(classes: revenus.classes),
      ],
    );
    final Widget annexe = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.enseignant.revenus.calculSection),
        _Calcul(revenus: revenus),
        Ecart.vSection,
        SectionHeader(titre: t.enseignant.revenus.internetSection),
        _Internet(allocation: revenus.allocationInternet),
      ],
    );
    // [RESPONSIVE] Le gabarit decide, jamais une largeur comparee a un nombre.
    if (AppGabarit.de(context) == Gabarit.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 3, child: principal),
          const SizedBox(width: AppSpacing.section),
          Expanded(flex: 2, child: annexe),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[principal, Ecart.vSection, annexe],
    );
  }
}

/// Une duree en minutes, en heures lisibles : « 8 h », « 7 h 30 ».
String _duree(int minutes) {
  final int heures = minutes ~/ 60;
  final int reste = minutes % 60;
  return reste == 0
      ? t.enseignant.revenus.heures(heures: heures)
      : t.enseignant.revenus.heuresMinutes(
          heures: heures,
          minutes: reste.toString().padLeft(2, '0'),
        );
}

/// Le resume : « Estimation », la periode, le total estime, les heures
/// assurees et le nombre de Classes, puis la mention qui dit que le releve
/// de l'academie fait foi.
class _Resume extends StatelessWidget {
  const _Resume({required this.revenus});

  final RevenusEnseignant revenus;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    // Une somme de durees, jamais d'argent : le total estime vient du port.
    final int minutes = revenus.classes.fold<int>(
      0,
      (int s, RevenusClasse c) => s + c.minutesAssurees,
    );
    return AppCard(
      dominante: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              StatusPill(
                libelle: t.enseignant.revenus.estimation,
                ton: TonEtat.accent,
              ),
              Text(
                t.enseignant.revenus.periode(
                  mois: t.commun.dates.mois[revenus.debut.month - 1],
                  annee: revenus.debut.year,
                ),
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ],
          ),
          Ecart.vMd,
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  t.enseignant.revenus.totalEstime,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
                MontantArgent(revenus.totalEstime, taille: TailleMontant.grand),
                Text(t.enseignant.revenus.totalDetail, style: attenue),
              ],
            ),
          ),
          Ecart.vMd,
          LigneCleValeur(
            cle: t.enseignant.revenus.heuresAssurees,
            valeur: _duree(minutes),
            chiffres: true,
          ),
          LigneCleValeur(
            cle: t.enseignant.revenus.classesActives,
            valeur: '${revenus.classes.length}',
            chiffres: true,
          ),
          Ecart.vMd,
          Text(t.enseignant.revenus.mention, style: attenue),
        ],
      ),
    );
  }
}

/// Le detail par Classe, une section par Classe dans une seule carte : les
/// lignes sont liees (une meme estimation), jamais des cartes collees (K-55).
class _DetailClasses extends StatelessWidget {
  const _DetailClasses({required this.classes});

  final List<RevenusClasse> classes;

  @override
  Widget build(BuildContext context) => CarteGroupee(
    sections: <Widget>[
      for (final RevenusClasse c in classes) _SectionClasse(classe: c),
    ],
  );
}

class _SectionClasse extends StatelessWidget {
  const _SectionClasse({required this.classe});

  final RevenusClasse classe;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      key: ValueKey<String>('revenus-classe-${classe.classeId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.enseignant.revenus.classe(nom: classe.classe),
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        LigneCleValeur(
          cle: t.enseignant.revenus.heuresAssurees,
          valeur: _duree(classe.minutesAssurees),
          chiffres: true,
        ),
        LigneCleValeur(
          cle: t.enseignant.revenus.capacite,
          valeur: t.enseignant.revenus.capaciteValeur(nombre: classe.capacite),
          chiffres: true,
        ),
        LigneCleValeur(
          cle: t.enseignant.revenus.sieges,
          detailCle: t.enseignant.revenus.siegesDetail,
          valeur: t.enseignant.revenus.siegesValeur(
            nombre: classe.siegesEligibles,
            capacite: classe.capacite,
          ),
          chiffres: true,
        ),
        LigneCleValeur(
          cle: t.enseignant.revenus.taux,
          valeur: t.enseignant.revenus.tauxValeur(
            montant: formaterMontant(classe.tauxHoraireEffectif),
          ),
          chiffres: true,
        ),
        LigneFinance(
          libelle: t.enseignant.revenus.montantClasse,
          montant: classe.montantEstime,
          total: true,
        ),
      ],
    );
  }
}

/// L'explication simple du guide §5.5 : base garantie, composante
/// d'occupation, plafond horaire. Les deux valeurs viennent de la politique
/// appliquee, rendue par le port.
class _Calcul extends StatelessWidget {
  const _Calcul({required this.revenus});

  final RevenusEnseignant revenus;

  @override
  Widget build(BuildContext context) {
    final String base = formaterMontant(revenus.baseHoraire);
    final String plafond = formaterMontant(revenus.plafondHoraire);
    return CarteGroupee(
      sections: <Widget>[
        _Etape(
          titre: t.enseignant.revenus.base,
          detail: t.enseignant.revenus.baseDetail(base: base),
        ),
        _Etape(
          titre: t.enseignant.revenus.occupation,
          detail: t.enseignant.revenus.occupationDetail,
        ),
        _Etape(
          titre: t.enseignant.revenus.plafond,
          detail: t.enseignant.revenus.plafondDetail(plafond: plafond),
        ),
      ],
    );
  }
}

class _Etape extends StatelessWidget {
  const _Etape({required this.titre, required this.detail});

  final String titre;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            titre,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(
            detail,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// L'aide Internet, a part de la remuneration pedagogique (guide §1.4) : une
/// seule par enseignant eligible, jamais multipliee par Classe.
class _Internet extends StatelessWidget {
  const _Internet({required this.allocation});

  final Montant? allocation;

  @override
  Widget build(BuildContext context) {
    final Montant? montant = allocation;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return AppCard(
      child: montant == null
          ? Text(
              t.enseignant.revenus.internetNon,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            )
          : LigneFinance(
              libelle: t.enseignant.revenus.internet,
              detail: t.enseignant.revenus.internetDetail,
              montant: montant,
            ),
    );
  }
}
