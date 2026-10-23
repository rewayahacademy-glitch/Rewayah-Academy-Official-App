// Les dernieres transactions du Foyer, sur ordinateur (FI-5b, guide Finance
// V4 §5.1 « Desktop », maquette 05) : les trois derniers mouvements du foyer,
// tels que la source les rend (`PortPaiementsFoyer.derniersMouvements`),
// puis « Voir tout » vers l'historique des paiements du foyer (X-12, FI-Q4 (a)
// decide par delegation le 05/10 ;
// `PaiementsComptePage` sans soldes ; revue FI-VAGUE-R R1-07).
//
// Aucun tri ni agregat ici (FI6) : la liste arrive arretee. En production le
// port rend `CapaciteIndisponible` : aucun bloc, jamais une transaction
// inventee. Pour le titulaire seulement (lecon 15).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/finance/mouvements_profil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_transaction.dart';
import '../../core/widgets/skeleton.dart';
import 'fiche/mouvements_page.dart' show libelleMouvement;
import 'ligne_membre.dart' show dateEcheance;

/// Le nombre de transactions montrees (maquette 05).
const int nombreDernieresTransactions = 3;

/// Les derniers mouvements du foyer, relus a chaque ouverture du Foyer.
final FutureProvider<List<MouvementFoyer>> derniersMouvementsFoyerProvider =
    FutureProvider<List<MouvementFoyer>>((Ref ref) {
      surveillerPersonneConnectee(ref);
      return ref
          .watch(portPaiementsFoyerProvider)
          .derniersMouvements(limite: nombreDernieresTransactions);
    });

/// Vrai quand la source des transactions existe : faux en production
/// (`CapaciteIndisponible`), ou la page garde sa composition sans ce bloc.
bool transactionsDisponibles(AsyncValue<List<MouvementFoyer>> lecture) =>
    !(lecture.hasError && lecture.error is CapaciteIndisponible);

/// « Dernieres transactions » : chargement, contenu, vide, erreur, hors
/// ligne ; rien du tout sans source (production).
class DernieresTransactionsFoyer extends ConsumerWidget {
  /// Cree le bloc.
  const DernieresTransactionsFoyer({
    required this.aller,
    super.key,
    this.onVoirTout,
  });

  /// Ouvre un chemin (le routeur, ou la coquille de la demonstration).
  final void Function(String chemin) aller;

  /// Ouvre l'historique du foyer ; par defaut, Compte > Paiements du tuteur
  /// (`PaiementsComptePage` sans soldes). Le titulaire adulte y passe sa
  /// page « Paiements du foyer ».
  final VoidCallback? onVoirTout;

  /// Le bloc.
  static const Key cle = Key('foyer.transactions');

  /// Le lien « Voir tout ».
  static const Key voirToutKey = Key('foyer.transactions.voirTout');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MouvementFoyer>> lecture = ref.watch(
      derniersMouvementsFoyerProvider,
    );
    if (!transactionsDisponibles(lecture)) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final Object? erreur = lecture.hasError ? lecture.error : null;
    void relire() => ref.invalidate(derniersMouvementsFoyerProvider);
    final List<MouvementFoyer> mouvements = erreur == null && lecture.hasValue
        ? lecture.requireValue
        : const <MouvementFoyer>[];
    final MouvementFoyer? premier = mouvements.firstOrNull;

    final Widget corps;
    if (erreur != null) {
      corps = (ref.watch(horsLigneProvider).value ?? false)
          ? EtatSansDonnees(
              quoi: t.foyer.transactions.sansDonnees,
              onAction: relire,
            )
          : EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: t.foyer.transactions.erreurTitre,
              onAction: relire,
            );
    } else if (!lecture.hasValue) {
      corps = const Skeleton.liste(lignes: nombreDernieresTransactions);
    } else if (premier == null) {
      corps = EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.foyer.transactions.videTitre,
        phrase: t.foyer.transactions.videPhrase,
      );
    } else {
      // Une seule carte a lignes fines : des contenus lies (K-55).
      corps = CarteGroupee(
        sections: <Widget>[
          for (final MouvementFoyer m in mouvements)
            LigneTransaction(
              libelle: t.foyer.transactions.ligne(
                libelle: libelleMouvement(m.mouvement),
                prenom: m.prenom,
              ),
              date: dateEcheance(m.mouvement.date),
              montant: m.mouvement.montant,
            ),
        ],
      );
    }
    return KeyedSubtree(
      key: cle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Le titre au debut, « Voir tout » au bord de fin ; a texte
          // agrandi, le lien passe sous le titre plutot que de le couper.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.lg,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  t.foyer.transactions.titre,
                  style: palette.inkStrong.applyTo(
                    Theme.of(context).textTheme.titleMedium ??
                        const TextStyle(),
                  ),
                ),
              ),
              // « Voir tout » mene a l'historique du foyer entier, jamais aux
              // mouvements d'un seul enfant (X-12) ; son nom lu commence par
              // le libelle visible (WCAG 2.5.3, R1-12).
              if (premier != null)
                LienFleche(
                  key: voirToutKey,
                  libelle: t.foyer.transactions.voirTout,
                  libelleSemantique: t.foyer.transactions.voirToutSemantique,
                  onPress:
                      onVoirTout ??
                      () => aller(Routes.compteTuteurSousPage('paiements')),
                ),
            ],
          ),
          Ecart.vSm,
          corps,
        ],
      ),
    );
  }
}
