/// SUIVI-ATTENTE (directeur, 12/11/2026 ; S1 a S9) : l'ecran du suivi de
/// l'attente de la classe, « comme une livraison ».
///
/// **Un seul ecran de suivi** (S6) : la carte compacte des accueils et les
/// notifications y menent, ils ne le dupliquent pas. Il sert le tuteur (un
/// suivi par enfant), l'eleve adulte et l'eleve de moins de 10 ans dans son
/// espace (version simple : tutoiement, aucun delai chiffre, rien sur
/// l'argent).
///
/// Il lit une seule source ([suivisAttenteProvider]) et ne decide rien : les
/// cinq etapes, leurs dates, le delai, le cas particulier et la carte de
/// l'enseignant viennent du serveur. Etats : chargement (`Skeleton`), contenu,
/// vide (« Vous n'avez pas encore choisi de classe » et le geste d'en choisir
/// une), erreur (« Reessayer »), hors ligne (bandeau de `PageShell` ; un bloc
/// `EtatSansDonnees` quand rien n'a pu etre lu).
///
/// La page defile, jamais un cadre (DECISION-DEFILEMENT-2026-11-01). Un seul
/// bouton plein : « Choisir un autre creneau », quand une demande est close et
/// que le serveur l'autorise (capacite lue, jamais un role).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/attente_classe/modele_attente.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../suivi_demandes/libelles_suivi_demandes.dart'
    show deFuseau, joursEtHeuresDemande;
import 'carte_enseignant_attente.dart';
import 'frise_attente.dart';
import 'libelles_attente.dart';

/// Ou menent les liens du suivi : le meme ecran sert le tuteur, l'eleve adulte
/// et l'eleve de moins de 10 ans, sur leurs propres routes.
class CheminsAttente {
  /// Cree les chemins.
  const CheminsAttente({
    required this.detail,
    required this.accueil,
    this.choisir,
    this.choisirPour,
  });

  /// Le detail d'une demande.
  final String Function(String demandeId) detail;

  /// Le repli du retour.
  final String accueil;

  /// Ou choisir une classe quand rien n'a ete demande ; nul quand ce profil
  /// n'a aucun parcours (l'enfant).
  final String? choisir;

  /// Ou choisir un autre creneau pour un eleve ; nul quand aucun parcours
  /// n'existe pour ce profil.
  final String Function(String eleveId)? choisirPour;

  /// La famille (tuteur).
  static const CheminsAttente tuteur = CheminsAttente(
    detail: Routes.tuteurAttenteDemande,
    accueil: Routes.tuteurAccueil,
    choisir: Routes.tuteurAccueil,
    choisirPour: Routes.parcoursPour,
  );

  /// L'eleve adulte autonome.
  static const CheminsAttente adulte = CheminsAttente(
    detail: Routes.eleveAdulteAttenteDemande,
    accueil: Routes.eleveAdulte,
  );

  /// L'eleve de moins de 10 ans, dans son espace.
  static const CheminsAttente enfant = CheminsAttente(
    detail: Routes.eleveAttenteDemande,
    accueil: Routes.eleve,
  );
}

/// L'ecran du suivi d'une demande.
class SuiviAttentePage extends ConsumerWidget {
  /// Cree l'ecran de la demande [demandeId].
  const SuiviAttentePage({
    required this.demandeId,
    required this.chemins,
    super.key,
  });

  /// La demande suivie.
  final String demandeId;

  /// Les destinations des liens.
  final CheminsAttente chemins;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    SuiviAttente? suivi;
    for (final SuiviAttente s
        in ref.watch(suivisAttenteProvider).value ?? const <SuiviAttente>[]) {
      if (s.demandeId == demandeId) suivi = s;
    }
    final bool simple = suivi?.versionSimple ?? false;
    void relire() => ref.invalidate(suivisAttenteProvider);

    return PageShell(
      titre: simple ? t.suiviAttente.titreSimple : t.suiviAttente.titre,
      sousTitre: simple
          ? t.suiviAttente.contexteSimple
          : t.suiviAttente.contexte,
      onRetour: () {
        final GoRouter? routeur = GoRouter.maybeOf(context);
        if (routeur == null) return;
        if (routeur.canPop()) {
          routeur.pop();
        } else {
          routeur.go(chemins.accueil);
        }
      },
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: BlocAsynchrone<List<SuiviAttente>>(
            key: const ValueKey<String>('attente-bloc'),
            valeur: ref.watch(suivisAttenteProvider),
            squelette: const Skeleton.liste(lignes: 4),
            onReessayer: relire,
            vide: _Vide(chemins: chemins),
            erreurVersEtat: (Object _, VoidCallback? reessayer) => horsLigne
                ? EtatSansDonnees(
                    key: const ValueKey<String>('attente-sans-donnees'),
                    quoi: t.suiviAttente.sansDonnees,
                    onAction: reessayer,
                  )
                : EtatSysteme(
                    key: const ValueKey<String>('attente-erreur'),
                    nature: NatureEtat.echecServeur,
                    phrase: t.suiviAttente.erreur,
                    onAction: reessayer,
                  ),
            construire: (List<SuiviAttente> lues) {
              final Iterable<SuiviAttente> trouvees = lues.where(
                (SuiviAttente s) => s.demandeId == demandeId,
              );
              return trouvees.isEmpty
                  ? _Introuvable(chemins: chemins)
                  : _Suivi(suivi: trouvees.first, chemins: chemins);
            },
          ),
        ),
      ),
    );
  }
}

/// Rien n'a ete demande : l'etat vide est juste (S9).
class _Vide extends StatelessWidget {
  const _Vide({required this.chemins});

  final CheminsAttente chemins;

  @override
  Widget build(BuildContext context) {
    final String? choisir = chemins.choisir;
    final bool enfant = choisir == null;
    return EmptyState(
      key: const ValueKey<String>('attente-vide'),
      message: enfant
          ? t.suiviAttente.vide.messageSimple
          : t.suiviAttente.vide.message,
      invitation: enfant
          ? t.suiviAttente.vide.invitationSimple
          : t.suiviAttente.vide.invitation,
      icone: AppIcons.creneaux,
      // Un vide « subi » ne propose rien : le geste de choisir une classe
      // n'existe que pour qui peut le faire (pas l'enfant).
      registre: enfant ? RegistreVide.subi : RegistreVide.actionnable,
      libelleAction: enfant ? null : t.suiviAttente.vide.action,
      onAction: enfant ? null : () => GoRouter.maybeOf(context)?.go(choisir),
    );
  }
}

class _Introuvable extends StatelessWidget {
  const _Introuvable({required this.chemins});

  final CheminsAttente chemins;

  @override
  Widget build(BuildContext context) => EmptyState(
    key: const ValueKey<String>('attente-introuvable'),
    message: t.suiviAttente.introuvable,
    icone: AppIcons.creneaux,
    registre: RegistreVide.actionnable,
    libelleAction: t.suiviAttente.retour,
    onAction: () => GoRouter.maybeOf(context)?.go(chemins.accueil),
  );
}

class _Suivi extends StatelessWidget {
  const _Suivi({required this.suivi, required this.chemins});

  final SuiviAttente suivi;
  final CheminsAttente chemins;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppInkColor secondaire = palette.encreSecondaireSur(
      palette.surfaceCanvas,
    );
    final TextStyle detail = secondaire.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final CarteEnseignantAttente? enseignant = suivi.enseignant;
    final CreneauDemande? creneau = suivi.creneau;
    final String Function(String)? choisirPour = chemins.choisirPour;

    return Column(
      key: ValueKey<String>('attente-contenu-${suivi.demandeId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            t.suiviAttente.pour(prenom: suivi.prenom),
            key: const ValueKey<String>('attente-pour'),
            style: palette.inkStrong.applyTo(
              textes.titleLarge ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vLg,
        if (suivi.close) ...<Widget>[_Cloture(suivi: suivi), Ecart.vLg],
        FriseAttente(
          suivi: suivi,
          apres: (int numero) => numero == 4 && enseignant != null
              ? CarteEnseignantAttenteVue(
                  enseignant: enseignant,
                  simple: suivi.versionSimple,
                  peutSePresenter: !suivi.versionSimple,
                )
              : null,
        ),
        if (creneau != null) ...<Widget>[
          Ecart.vLg,
          Text(
            joursEtHeuresDemande(creneau),
            key: const ValueKey<String>('attente-creneau'),
            style: detail,
          ),
        ],
        Ecart.vSm,
        Text(
          t.suiviDemandes.fuseauValeur(
            deVille: deFuseau(
              suivi.fuseauIana,
              cle: 'suiviDemandes.fuseauValeur',
            ),
          ),
          key: const ValueKey<String>('attente-fuseau'),
          style: detail,
        ),
        if (suivi.close &&
            suivi.peutChoisirAutreCreneau &&
            choisirPour != null &&
            !suivi.versionSimple) ...<Widget>[
          Ecart.vLg,
          ActionPrincipale(
            key: const ValueKey<String>('attente-autre-creneau'),
            libelle: t.suiviAttente.cloture.autreCreneau,
            pleineLargeur: false,
            onPress: () =>
                GoRouter.maybeOf(context)?.go(choisirPour(suivi.eleveId)),
          ),
        ],
      ],
    );
  }
}

/// La cloture : son motif en clair, et ce qui reste possible (S3).
class _Cloture extends StatelessWidget {
  const _Cloture({required this.suivi});

  final SuiviAttente suivi;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool refus = suivi.cas == CasAttente.refusee;
    final bool suite = suivi.peutChoisirAutreCreneau && !suivi.versionSimple;
    return PileCartes(
      children: <Widget>[
        AppCard(
          key: const ValueKey<String>('attente-cloture'),
          surface: refus ? palette.washWarning : palette.washAccent,
          entete: Semantics(
            header: true,
            child: TexteSansCoupure(
              titreCloture(suivi),
              style: textes.titleMedium ?? const TextStyle(),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TexteSansCoupure(
                motifCloture(suivi),
                key: const ValueKey<String>('attente-cloture-motif'),
                style: palette.inkStrong.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
              if (suite) ...<Widget>[
                Ecart.vSm,
                TexteSansCoupure(
                  t.suiviAttente.cloture.suite,
                  key: const ValueKey<String>('attente-cloture-suite'),
                  style: palette.inkStrong.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
