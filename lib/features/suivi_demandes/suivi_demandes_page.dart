/// OFFRES-FAM-1 : le suivi des demandes de creneau, cote famille.
///
/// Decision du directeur du 09/10/2026 (`DECISION-OFFRES-GROUPES-2026-10-09`,
/// §2 et §4) : une carte par eleve concerne, qui dit ou en est sa demande et
/// ce qui vient ensuite :
///
/// 1. Demande envoyee : « Votre demande est arrivee a l'administration »,
///    prochaine etape : constitution de la classe ;
/// 2. Classe validee : « Votre classe a ete validee », prochaine etape :
///    affectation de l'enseignant ;
/// 3. Enseignant affecte : « Classe validee · enseignant affecte », prochaine
///    echeance : debut des cours, date et heure dans le fuseau du foyer ;
/// 4. Refus ou retrait : le motif en clair, et ce que la famille peut faire.
///
/// Chaque carte rappelle les jours et l'heure choisis. Un creneau
/// personnalise encore a l'etape 1 porte la notice : il ne s'ouvrira que si
/// d'autres eleves le choisissent et remplissent la classe.
///
/// **Jamais d'information sur les autres demandeurs**, ni nombre, ni
/// identite : le contrat n'en porte pas. **Aucun nom d'enseignant avant
/// l'etape 3** : le modele l'efface avant.
///
/// L'ecran lit des capacites, jamais un role : le lien « Choisir un autre
/// creneau » n'existe que si le serveur dit `peutChoisirAutreCreneau`.
///
/// Etats : chargement (`Skeleton` dans `BlocAsynchrone`), contenu, vide
/// (`EmptyState`), erreur (`EtatSysteme`, « Reessayer »), hors ligne (le
/// bandeau de `PageShell` ; un bloc `EtatSansDonnees` seulement si rien n'a
/// pu etre lu, EA-HL-DOUBLE-1).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/port_suivi_demandes.dart';
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
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'libelles_suivi_demandes.dart';

/// Les demandes en cours d'abord, les demandes closes ensuite ; l'ordre du
/// serveur est garde a l'interieur de chaque groupe.
List<SuiviDemande> trierDemandes(List<SuiviDemande> demandes) => <SuiviDemande>[
  ...demandes.where((SuiviDemande d) => d.etape != EtapeDemande.close),
  ...demandes.where((SuiviDemande d) => d.etape == EtapeDemande.close),
];

/// L'ecran « Suivi des demandes de creneau ».
class SuiviDemandesPage extends ConsumerWidget {
  /// Cree l'ecran.
  const SuiviDemandesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SuiviDemande>> demandes = ref.watch(
      suiviDemandesProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    void relire() => ref.invalidate(suiviDemandesProvider);

    return PageShell(
      titre: t.suiviDemandes.titre,
      sousTitre: t.suiviDemandes.contexte,
      onRetour: () {
        final GoRouter? routeur = GoRouter.maybeOf(context);
        if (routeur == null) return;
        if (routeur.canPop()) {
          routeur.pop();
        } else {
          routeur.go(Routes.tuteurAccueil);
        }
      },
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: BlocAsynchrone<List<SuiviDemande>>(
            key: const ValueKey<String>('suivi-demandes-bloc'),
            valeur: demandes,
            squelette: const Skeleton.liste(lignes: 3),
            onReessayer: relire,
            vide: EmptyState(
              key: const ValueKey<String>('suivi-demandes-vide'),
              message: t.suiviDemandes.vide,
              icone: AppIcons.creneaux,
              registre: RegistreVide.subi,
            ),
            erreurVersEtat: (Object _, VoidCallback? reessayer) => horsLigne
                ? EtatSansDonnees(
                    key: const ValueKey<String>('suivi-demandes-sans-donnees'),
                    quoi: t.suiviDemandes.sansDonnees,
                    onAction: reessayer,
                  )
                : EtatSysteme(
                    key: const ValueKey<String>('suivi-demandes-erreur'),
                    nature: NatureEtat.echecServeur,
                    phrase: t.suiviDemandes.erreur,
                    onAction: reessayer,
                  ),
            construire: (List<SuiviDemande> lues) => PileCartes(
              key: const ValueKey<String>('suivi-demandes-contenu'),
              children: <Widget>[
                for (final SuiviDemande d in trierDemandes(lues))
                  CarteDemande(demande: d),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La carte d'une demande : ou elle en est, ce qui vient, ce qui a ete choisi.
class CarteDemande extends StatelessWidget {
  /// Cree la carte.
  const CarteDemande({required this.demande, super.key});

  /// La demande.
  final SuiviDemande demande;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final SuiviDemande d = demande;
    final bool close = d.etape == EtapeDemande.close;
    final TextStyle fort = palette.inkStrong.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    final List<Widget> blocs = <Widget>[
      if (close) ...<Widget>[
        Text(
          motifDemande(d.motif!),
          key: ValueKey<String>('demande-motif-${d.demandeId}'),
          style: fort,
        ),
        Ecart.vSm,
        Text(
          d.peutChoisirAutreCreneau
              ? t.suiviDemandes.close.suite
              : t.suiviDemandes.close.suiteSansChoix,
          style: corps,
        ),
      ] else ...<Widget>[
        Text(
          situationDemande(d.etape)!,
          key: ValueKey<String>('demande-situation-${d.demandeId}'),
          style: fort,
        ),
        Ecart.vLg,
        _FriseEtapes(etape: d.etape),
        Ecart.vLg,
        ..._prochaine(d, corps),
      ],
      Ecart.vLg,
      // C-10 bis : une heure commune se dit une fois ; sinon chaque jour
      // avec la sienne, et le fuseau sur sa propre ligne.
      if (heureDemande(d) case final String heure) ...<Widget>[
        LigneCleValeur(
          cle: t.suiviDemandes.joursChoisis,
          valeur: joursDemande(d.creneau.joursIso),
        ),
        Ecart.vSm,
        LigneCleValeur(cle: t.suiviDemandes.heureChoisie, valeur: heure),
      ] else ...<Widget>[
        LigneCleValeur(
          key: ValueKey<String>('demande-jours-heures-${d.demandeId}'),
          cle: t.suiviDemandes.creneauxChoisis,
          valeur: joursEtHeuresDemande(d.creneau),
        ),
        Ecart.vSm,
        LigneCleValeur(
          cle: t.suiviDemandes.fuseauChoisi,
          valeur: fuseauDemande(d),
        ),
      ],
      if (d.personnalise && d.etape == EtapeDemande.envoyee) ...<Widget>[
        Ecart.vLg,
        _NoticePersonnalise(
          key: ValueKey<String>('demande-notice-${d.demandeId}'),
        ),
      ],
    ];

    final Widget titre = Semantics(
      header: true,
      child: TexteSansCoupure(
        t.suiviDemandes.carteTitre(
          dePrenom: deDevant(d.prenom, cle: 'suiviDemandes.carteTitre'),
        ),
        style: textes.titleMedium ?? const TextStyle(),
      ),
    );

    return AppCard(
      key: ValueKey<String>('demande-${d.demandeId}'),
      entete: close
          ? OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowAlignment: OverflowBarAlignment.start,
              spacing: AppSpacing.sm,
              overflowSpacing: AppSpacing.sm,
              children: <Widget>[
                titre,
                StatusPill(
                  libelle: etatCourtDemande(d),
                  ton: TonEtat.avertissement,
                ),
              ],
            )
          : titre,
      // Capacite rendue par le serveur : sans elle, pas de lien (jamais
      // grise) ; la phrase de suite dit ce qui reste possible.
      actions: close && d.peutChoisirAutreCreneau
          ? LienFleche(
              key: ValueKey<String>('demande-rechoisir-${d.demandeId}'),
              libelle: t.suiviDemandes.close.choisirAutre(prenom: d.prenom),
              alignerEnFin: true,
              onPress: () =>
                  GoRouter.maybeOf(context)?.go(Routes.parcoursPour(d.eleveId)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: blocs,
      ),
    );
  }

  /// Ce qui vient ensuite, pour une demande en cours.
  List<Widget> _prochaine(SuiviDemande d, TextStyle corps) {
    switch (d.etape) {
      case EtapeDemande.envoyee:
        return <Widget>[Text(t.suiviDemandes.prochaine.envoyee, style: corps)];
      case EtapeDemande.classeValidee:
        return <Widget>[
          Text(t.suiviDemandes.prochaine.classeValidee, style: corps),
        ];
      case EtapeDemande.enseignantAffecte:
        final String? debut = debutCoursDemande(d);
        final String? enseignant = d.enseignant;
        return <Widget>[
          if (debut == null)
            Text(t.suiviDemandes.debutAFixer, style: corps)
          else
            LigneCleValeur(
              key: ValueKey<String>('demande-debut-${d.demandeId}'),
              cle: t.suiviDemandes.debutCours,
              valeur: debut,
            ),
          if (enseignant != null && enseignant.isNotEmpty) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(
              key: ValueKey<String>('demande-enseignant-${d.demandeId}'),
              cle: t.suiviDemandes.enseignant,
              valeur: enseignant,
            ),
          ],
        ];
      case EtapeDemande.close:
        return const <Widget>[];
    }
  }
}

/// Ou en est une etape de la frise.
enum _EtatEtape { fait, prochaine, aVenir }

/// Les trois etapes d'une demande en cours, du haut vers le bas.
///
/// Chaque etape dit son etat par trois signaux, jamais la couleur seule :
/// l'icone (coche pleine, horloge, sablier), le mot (« Fait », « Prochaine
/// etape », « A venir ») et l'encre.
class _FriseEtapes extends StatelessWidget {
  const _FriseEtapes({required this.etape});

  final EtapeDemande etape;

  @override
  Widget build(BuildContext context) {
    final int atteintes = switch (etape) {
      EtapeDemande.envoyee => 1,
      EtapeDemande.classeValidee => 2,
      EtapeDemande.enseignantAffecte => 3,
      EtapeDemande.close => 0,
    };
    final List<String> libelles = <String>[
      t.suiviDemandes.etapes.envoyee,
      t.suiviDemandes.etapes.classeValidee,
      t.suiviDemandes.etapes.enseignantAffecte,
    ];
    return Column(
      key: const ValueKey<String>('demande-frise'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < libelles.length; i++) ...<Widget>[
          if (i > 0) Ecart.vSm,
          _LigneEtape(
            libelle: libelles[i],
            etat: i < atteintes
                ? _EtatEtape.fait
                : i == atteintes
                ? _EtatEtape.prochaine
                : _EtatEtape.aVenir,
          ),
        ],
      ],
    );
  }
}

class _LigneEtape extends StatelessWidget {
  const _LigneEtape({required this.libelle, required this.etat});

  final String libelle;
  final _EtatEtape etat;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppInkColor secondaire = palette.encreSecondaireSur(
      palette.surfaceRaised,
    );
    final (
      AppIcon icone,
      bool plein,
      AppInkColor encre,
      String mot,
    ) = switch (etat) {
      _EtatEtape.fait => (
        AppIcons.succes,
        true,
        palette.inkSuccess,
        t.suiviDemandes.etats.fait,
      ),
      _EtatEtape.prochaine => (
        AppIcons.horloge,
        false,
        palette.inkAccent,
        t.suiviDemandes.etats.prochaine,
      ),
      _EtatEtape.aVenir => (
        AppIcons.attente,
        false,
        secondaire,
        t.suiviDemandes.etats.aVenir,
      ),
    };
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconTheme(
            data: encre.asIconTheme(size: AppSpacing.xxl),
            child: ExcludeSemantics(
              child: Icon(icone.resoudre(selectionne: plein)),
            ),
          ),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  libelle,
                  style: palette.inkStrong.applyTo(
                    textes.titleSmall ?? const TextStyle(),
                  ),
                ),
                Text(
                  mot,
                  style: secondaire.applyTo(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La notice d'un creneau personnalise en attente (decision du 09/10, §2).
class _NoticePersonnalise extends StatelessWidget {
  const _NoticePersonnalise({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IconTheme(
          data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
          child: ExcludeSemantics(child: Icon(AppIcons.info.repos)),
        ),
        Ecart.hMd,
        Expanded(
          child: Text(
            t.suiviDemandes.personnaliseNotice,
            style: palette.inkStrong.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}
