/// SUIVI-FAMILLE (R20, directeur, 10/10/2026) : le suivi des demandes, « comme
/// une livraison », cote famille.
///
/// Deux ecrans sur le meme port ([PortFriseDemandes]) :
/// - la **liste** : une carte par demande et par enfant, avec son etape
///   courante, qui ouvre le detail ;
/// - le **detail** : la frise des etapes (fait, en cours, a venir), chacune
///   avec son horodatage, l'intervalle depuis l'etape precedente et, a
///   l'attente, son motif. Pas de rang, pas d'autres familles (R11).
///
/// L'ecran lit des donnees du serveur, jamais un role. Etats : chargement,
/// contenu, vide (bouton vers la demande), erreur, hors ligne.
///
/// [SuiviDemandesEntree] choisit la liste : sans port de frise (production
/// avant branchement) l'ecran d'OFFRES-FAM-1 reste en place, inchange.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/port_frise_demande.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../suivi_demandes/libelles_suivi_demandes.dart';
import '../suivi_demandes/suivi_demandes_page.dart';
import 'libelles_suivi_famille.dart';

/// L'entree de la route des demandes : la liste a frise quand le port existe,
/// sinon l'ecran de suivi existant.
class SuiviDemandesEntree extends ConsumerWidget {
  /// Cree l'entree.
  const SuiviDemandesEntree({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(portFriseDemandesProvider) == null
      ? const SuiviDemandesPage()
      : const SuiviFamillePage();
}

void _retour(BuildContext context, String repli) {
  final GoRouter? routeur = GoRouter.maybeOf(context);
  if (routeur == null) return;
  if (routeur.canPop()) {
    routeur.pop();
  } else {
    routeur.go(repli);
  }
}

/// Le bloc asynchrone commun a la liste et au detail.
Widget _bloc({
  required WidgetRef ref,
  required bool horsLigne,
  required String prefixe,
  required Widget vide,
  required Widget Function(List<FriseDemande>) construire,
}) {
  void relire() => ref.invalidate(frisesDemandesProvider);
  return BlocAsynchrone<List<FriseDemande>>(
    key: ValueKey<String>('$prefixe-bloc'),
    valeur: ref.watch(frisesDemandesProvider),
    squelette: const Skeleton.liste(lignes: 3),
    onReessayer: relire,
    vide: vide,
    erreurVersEtat: (Object _, VoidCallback? reessayer) => horsLigne
        ? EtatSansDonnees(
            key: ValueKey<String>('$prefixe-sans-donnees'),
            quoi: t.suiviFamille.sansDonnees,
            onAction: reessayer,
          )
        : EtatSysteme(
            key: ValueKey<String>('$prefixe-erreur'),
            nature: NatureEtat.echecServeur,
            phrase: t.suiviFamille.erreur,
            onAction: reessayer,
          ),
    construire: construire,
  );
}

/// La liste des demandes, avec l'etape courante de chacune.
class SuiviFamillePage extends ConsumerWidget {
  /// Cree l'ecran.
  const SuiviFamillePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return PageShell(
      titre: t.suiviFamille.titre,
      sousTitre: t.suiviFamille.contexte,
      onRetour: () => _retour(context, Routes.tuteurAccueil),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: _bloc(
            ref: ref,
            horsLigne: horsLigne,
            prefixe: 'suivi-famille',
            vide: EmptyState(
              key: const ValueKey<String>('suivi-famille-vide'),
              message: t.suiviFamille.vide,
              icone: AppIcons.creneaux,
              libelleAction: t.suiviFamille.faireDemande,
              onAction: () =>
                  GoRouter.maybeOf(context)?.go(Routes.tuteurClassesCatalogue),
            ),
            construire: (List<FriseDemande> lues) => PileCartes(
              key: const ValueKey<String>('suivi-famille-contenu'),
              children: <Widget>[
                for (final FriseDemande f in lues) _CarteFrise(frise: f),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CarteFrise extends StatelessWidget {
  const _CarteFrise({required this.frise});

  final FriseDemande frise;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TypeEtapeFrise? courante = frise.courante;
    final String phrase = courante == null
        ? t.suiviFamille.toutFait
        : t.suiviFamille.etapeCourante(etape: libelleEtape(courante));
    return AppCard(
      key: ValueKey<String>('frise-${frise.demandeId}'),
      entete: Semantics(
        header: true,
        child: TexteSansCoupure(
          t.suiviFamille.carteTitre(
            dePrenom: deDevant(frise.prenom, cle: 'suiviFamille.carteTitre'),
          ),
          style: textes.titleMedium ?? const TextStyle(),
        ),
      ),
      actions: LienFleche(
        key: ValueKey<String>('frise-voir-${frise.demandeId}'),
        libelle: t.suiviFamille.voirSuivi,
        alignerEnFin: true,
        onPress: () =>
            GoRouter.maybeOf(context)
                ?.go(Routes.tuteurDemande(frise.demandeId)),
      ),
      child: Text(
        phrase,
        key: ValueKey<String>('frise-courante-${frise.demandeId}'),
        style: palette.inkStrong.applyTo(textes.bodyLarge ?? const TextStyle()),
      ),
    );
  }
}

/// Le detail d'une demande : la frise de ses etapes.
class FriseDemandePage extends ConsumerWidget {
  /// Cree le detail de [demandeId].
  const FriseDemandePage({required this.demandeId, super.key});

  /// La demande ouverte.
  final String demandeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    FriseDemande? frise;
    for (final FriseDemande f
        in ref.watch(frisesDemandesProvider).value ?? const <FriseDemande>[]) {
      if (f.demandeId == demandeId) frise = f;
    }
    return PageShell(
      titre: frise == null
          ? t.suiviFamille.titre
          : t.suiviFamille.detailTitre(
              dePrenom: deDevant(frise.prenom, cle: 'suiviFamille.detailTitre'),
            ),
      onRetour: () => _retour(context, Routes.tuteurDemandes),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: _bloc(
            ref: ref,
            horsLigne: horsLigne,
            prefixe: 'frise-detail',
            vide: _Introuvable(),
            construire: (List<FriseDemande> lues) {
              final Iterable<FriseDemande> trouvees = lues.where(
                (FriseDemande f) => f.demandeId == demandeId,
              );
              return trouvees.isEmpty
                  ? _Introuvable()
                  : _Frise(frise: trouvees.first);
            },
          ),
        ),
      ),
    );
  }
}

class _Introuvable extends StatelessWidget {
  @override
  Widget build(BuildContext context) => EmptyState(
    key: const ValueKey<String>('frise-introuvable'),
    message: t.suiviFamille.introuvable,
    icone: AppIcons.creneaux,
    registre: RegistreVide.subi,
    libelleAction: t.suiviFamille.retour,
    onAction: () => GoRouter.maybeOf(context)?.go(Routes.tuteurDemandes),
  );
}

class _Frise extends StatelessWidget {
  const _Frise({required this.frise});

  final FriseDemande frise;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final List<EtapeFrise> etapes = frise.etapes;
    DateTime? precedente;
    final List<Widget> lignes = <Widget>[];
    for (final (int i, EtapeFrise e) in etapes.indexed) {
      final EtatEtapeFrise etat = frise.etatDe(e.type);
      final DateTime? quand = e.quand;
      // L'intervalle ne se dit qu'entre deux instants franchis.
      final String? depuis =
          etat != EtatEtapeFrise.aVenir && quand != null && precedente != null
          ? intervalleEntre(precedente, quand)
          : null;
      if (etat != EtatEtapeFrise.aVenir && quand != null) precedente = quand;
      lignes.add(
        _LigneFrise(
          key: ValueKey<String>('frise-etape-${e.type.name}'),
          etape: e,
          etat: etat,
          depuis: depuis,
          motif:
              e.type == TypeEtapeFrise.enAttente &&
                  etat == EtatEtapeFrise.enCours
              ? libelleMotifAttente(frise.motifAttente!)
              : null,
          derniere: i == etapes.length - 1,
          rang: i + 1,
          total: etapes.length,
        ),
      );
    }
    return Column(
      key: const ValueKey<String>('frise-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...lignes,
        Ecart.vLg,
        Text(
          t.suiviFamille.fuseau(
            deVille: deFuseau(frise.fuseauIana, cle: 'suiviFamille.fuseau'),
          ),
          key: const ValueKey<String>('frise-fuseau'),
          style: palette
              .encreSecondaireSur(palette.surfaceCanvas)
              .applyTo(textes.bodySmall ?? const TextStyle()),
        ),
      ],
    );
  }
}

class _LigneFrise extends StatelessWidget {
  const _LigneFrise({
    required this.etape,
    required this.etat,
    required this.derniere,
    required this.rang,
    required this.total,
    this.depuis,
    this.motif,
    super.key,
  });

  final EtapeFrise etape;
  final EtatEtapeFrise etat;
  final bool derniere;
  final int rang;
  final int total;
  final String? depuis;
  final String? motif;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppInkColor secondaire = palette.encreSecondaireSur(
      palette.surfaceCanvas,
    );
    final (AppIcon icone, bool plein, AppInkColor encre) = switch (etat) {
      EtatEtapeFrise.fait => (AppIcons.succes, true, palette.inkSuccess),
      EtatEtapeFrise.enCours => (AppIcons.horloge, true, palette.inkAccent),
      EtatEtapeFrise.aVenir => (AppIcons.attente, false, secondaire),
    };
    final DateTime? quand = etape.quand;
    final String? instant = quand == null
        ? null
        : etat == EtatEtapeFrise.fait
        ? horodatage(quand)
        : datePrevue(quand);
    final String nom = libelleEtape(etape.type);
    final TextStyle titre =
        (etat == EtatEtapeFrise.enCours ? palette.inkAccent : palette.inkStrong)
            .applyTo(
              (etat == EtatEtapeFrise.enCours
                      ? textes.titleMedium
                      : textes.titleSmall) ??
                  const TextStyle(),
            );
    final TextStyle detail = secondaire.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final String etiquette = <String>[
      t.suiviFamille.etapeSurTotal(n: rang, total: total, etape: nom),
      libelleEtat(etat),
      ?instant,
      ?depuis,
      ?motif,
    ].join(', ');
    return Semantics(
      label: etiquette,
      container: true,
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: AppSpacing.xxl,
              child: Column(
                children: <Widget>[
                  IconTheme(
                    data: encre.asIconTheme(size: AppSpacing.xxl),
                    child: ExcludeSemantics(
                      child: Icon(icone.resoudre(selectionne: plein)),
                    ),
                  ),
                  if (!derniere)
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: BorderDirectional(
                            start: palette.borderStrong.asBorderSide(),
                          ),
                        ),
                        child: const SizedBox(width: 0),
                      ),
                    ),
                ],
              ),
            ),
            Ecart.hMd,
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: derniere ? 0 : AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(nom, style: titre),
                    Text(libelleEtat(etat), style: detail),
                    if (instant != null)
                      Text(
                        instant,
                        key: ValueKey<String>('frise-quand-${etape.type.name}'),
                        style: detail,
                      ),
                    if (depuis != null)
                      Text(
                        depuis!,
                        key: ValueKey<String>(
                          'frise-depuis-${etape.type.name}',
                        ),
                        style: detail,
                      ),
                    if (motif != null) ...<Widget>[
                      Ecart.vXs,
                      Text(
                        motif!,
                        key: const ValueKey<String>('frise-motif'),
                        style: palette.inkStrong.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
