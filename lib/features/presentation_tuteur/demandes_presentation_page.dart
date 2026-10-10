/// BACK-FRONT-AGE-1 (MA-9) : le tuteur repond aux demandes de presentation
/// standard de ses enfants (`port_reponse_presentation.dart`).
///
/// Une carte par demande : qui, quand, « Accepter » et « Refuser ». Aucun
/// bouton plein (deux gestes de meme poids : secondaire et tertiaire). Une
/// reponse non confirmee laisse la demande en attente et le dit. Aucun age,
/// aucune date de naissance.
///
/// Etats : chargement, contenu, vide, erreur, hors ligne. [CarteDemandePresentation]
/// est le point d'entree de l'accueil famille : silencieuse sans demande.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/port_reponse_presentation.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../suivi_demandes/libelles_suivi_demandes.dart' show hhmmDemande;

/// « Lundi 12 octobre » : le jour de la demande, heure murale du foyer.
String _jour(DateTime d) => t.commun.dates.jourDate(
  jour: t.commun.dates.jours[d.weekday - 1],
  numero: d.day,
  mois: t.commun.dates.mois[d.month - 1],
);

/// Le titre de la notification `demande_presentation` : qui demande quoi.
String titreNotificationPresentation(DemandePresentation d) =>
    t.presentationTuteur.notification(prenom: d.prenom);

/// L'ecran des demandes de presentation.
class DemandesPresentationPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const DemandesPresentationPage({super.key});

  @override
  ConsumerState<DemandesPresentationPage> createState() =>
      _DemandesPresentationPageState();
}

class _DemandesPresentationPageState
    extends ConsumerState<DemandesPresentationPage> {
  String? _enCours;
  String? _retour;
  bool _echec = false;

  Future<void> _repondre(
    DemandePresentation d, {
    required bool accepter,
  }) async {
    final PortReponsePresentation? port = ref.read(
      portReponsePresentationProvider,
    );
    if (port == null || _enCours != null) {
      return;
    }
    setState(() {
      _enCours = d.id;
      _echec = false;
    });
    try {
      if (accepter) {
        await port.accepter(d.id);
      } else {
        await port.refuser(d.id);
      }
      if (!mounted) return;
      ref.invalidate(demandesPresentationProvider);
      setState(() {
        _retour = accepter
            ? t.presentationTuteur.acceptee(prenom: d.prenom)
            : t.presentationTuteur.refusee(prenom: d.prenom);
      });
    } on Object {
      if (!mounted) return;
      setState(() => _echec = true);
    } finally {
      if (mounted) setState(() => _enCours = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<List<DemandePresentation>> demandes = ref.watch(
      demandesPresentationProvider,
    );
    void relire() => ref.invalidate(demandesPresentationProvider);
    return PageShell(
      titre: t.presentationTuteur.titre,
      sousTitre: t.presentationTuteur.contexte,
      onRetour: () {
        final GoRouter? routeur = GoRouter.maybeOf(context);
        if (routeur == null) return;
        if (routeur.canPop()) {
          routeur.pop();
        } else {
          routeur.go(Routes.tuteurAccueil);
        }
      },
      entete: LocalFeedback(message: _retour),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: BlocAsynchrone<List<DemandePresentation>>(
            key: const ValueKey<String>('presentation-bloc'),
            valeur: demandes,
            squelette: const Skeleton.liste(lignes: 2),
            onReessayer: relire,
            vide: EmptyState(
              key: const ValueKey<String>('presentation-vide'),
              message: t.presentationTuteur.vide,
              icone: AppIcons.info,
              registre: RegistreVide.subi,
            ),
            erreurVersEtat: (Object _, VoidCallback? reessayer) => horsLigne
                ? EtatSansDonnees(
                    key: const ValueKey<String>('presentation-sans-donnees'),
                    quoi: t.presentationTuteur.sansDonnees,
                    onAction: reessayer,
                  )
                : EtatSysteme(
                    key: const ValueKey<String>('presentation-erreur'),
                    nature: NatureEtat.echecServeur,
                    phrase: t.presentationTuteur.erreur,
                    onAction: reessayer,
                  ),
            construire: (List<DemandePresentation> lues) => PileCartes(
              key: const ValueKey<String>('presentation-contenu'),
              children: <Widget>[
                if (_echec)
                  Text(
                    t.presentationTuteur.echecReponse,
                    key: const ValueKey<String>('presentation-echec'),
                    style: AppPalette.of(context).inkAlert.applyTo(
                      Theme.of(context).textTheme.bodyMedium ??
                          const TextStyle(),
                    ),
                  ),
                for (final DemandePresentation d in lues)
                  _CarteDemande(
                    demande: d,
                    enCours: _enCours == d.id,
                    occupe: _enCours != null,
                    onAccepter: () => unawaited(_repondre(d, accepter: true)),
                    onRefuser: () => unawaited(_repondre(d, accepter: false)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CarteDemande extends StatelessWidget {
  const _CarteDemande({
    required this.demande,
    required this.enCours,
    required this.occupe,
    required this.onAccepter,
    required this.onRefuser,
  });

  final DemandePresentation demande;
  final bool enCours;
  final bool occupe;
  final VoidCallback onAccepter;
  final VoidCallback onRefuser;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final DemandePresentation d = demande;
    return AppCard(
      key: ValueKey<String>('presentation-${d.id}'),
      entete: Semantics(
        header: true,
        child: TexteSansCoupure(
          t.presentationTuteur.ligne(prenom: d.prenom),
          style: textes.titleMedium ?? const TextStyle(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            t.presentationTuteur.demandeeLe(
              date: _jour(d.demandeeLe),
              heure: hhmmDemande(d.demandeeLe.hour, d.demandeeLe.minute),
            ),
            style: palette
                .encreSecondaireSur(palette.surfaceRaised)
                .applyTo(textes.bodySmall ?? const TextStyle()),
          ),
          Ecart.vLg,
          // Pendant l'enregistrement d'une reponse, les autres gestes ne
          // sont pas rendus (jamais grises).
          if (enCours || !occupe) ...<Widget>[
            ActionPrincipale(
              key: ValueKey<String>('presentation-accepter-${d.id}'),
              libelle: t.presentationTuteur.accepter,
              niveau: NiveauAction.secondaire,
              enCours: enCours,
              onPress: enCours ? null : onAccepter,
            ),
            if (!enCours) ...<Widget>[
              Ecart.vSm,
              ActionPrincipale(
                key: ValueKey<String>('presentation-refuser-${d.id}'),
                libelle: t.presentationTuteur.refuser,
                niveau: NiveauAction.tertiaire,
                onPress: onRefuser,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// L'entree de l'accueil famille : silencieuse sans port, en chargement, en
/// echec et sans demande (l'ecran porte alors ses propres etats).
class CarteDemandePresentation extends ConsumerWidget {
  /// Cree la carte.
  const CarteDemandePresentation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DemandePresentation> lues =
        ref.watch(demandesPresentationProvider).value ??
        const <DemandePresentation>[];
    if (lues.isEmpty) {
      return const SizedBox.shrink();
    }
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppCard(
          key: const ValueKey<String>('carte-demande-presentation'),
          entete: Semantics(
            header: true,
            child: TexteSansCoupure(
              t.presentationTuteur.accueil.titre,
              style: textes.titleMedium ?? const TextStyle(),
            ),
          ),
          actions: LienFleche(
            key: const ValueKey<String>('carte-demande-presentation-voir'),
            libelle: t.presentationTuteur.accueil.voir,
            alignerEnFin: true,
            onPress: () =>
                GoRouter.maybeOf(context)?.go(Routes.tuteurPresentation),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final DemandePresentation d in lues)
                Text(
                  t.presentationTuteur.ligne(prenom: d.prenom),
                  style: palette.inkStrong.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
            ],
          ),
        ),
        Ecart.vXl,
      ],
    );
  }
}
