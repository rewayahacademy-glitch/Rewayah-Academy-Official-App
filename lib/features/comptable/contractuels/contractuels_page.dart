// Contractuels et obligations (FIN-CPT-W06 ; spec §22, §23, §34). **Propriete
// de la voie CPT-CTR** (`20_comptable/02_DECOUPAGE.md`) : elle ecrit dans
// `lib/features/comptable/contractuels/**` seulement.
//
// Quatre zones (Obligations, A approuver, A payer, Historique) ; le montant
// manuel n'existe qu'a la creation, fige apres approbation ; « Nouvelle
// obligation » seulement quand la source rend la capacite `creerObligation` ;
// « Payer » ouvre le W03 de l'obligation payable, aucun composant de paiement
// ici (DR-12). Un contractuel est un beneficiaire externe, jamais un role
// (DR-16). Lit `portObligationsContractuelsProvider` (CPT-BR-08).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_obligations_contractuels.dart';
import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import '../../../core/widgets/data_collection.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import '../../../core/widgets/status_pill.dart';
import 'contractuels_commun.dart';

/// Les obligations de contractuels, onglet « Contractuels » de Paiements.
class ContractuelsPage extends ConsumerStatefulWidget {
  /// Cree la page. [onglet] est la zone interne demandee par l'adresse
  /// (`?onglet=`), brute.
  const ContractuelsPage({super.key, this.onglet});

  /// La zone interne, brute.
  final String? onglet;

  @override
  ConsumerState<ContractuelsPage> createState() => _ContractuelsPageState();
}

class _ContractuelsPageState extends ConsumerState<ContractuelsPage> {
  late OngletContractuels _onglet = OngletContractuels.depuis(widget.onglet);

  @override
  void didUpdateWidget(ContractuelsPage ancienne) {
    super.didUpdateWidget(ancienne);
    if (ancienne.onglet != widget.onglet) {
      _onglet = OngletContractuels.depuis(widget.onglet);
    }
  }

  void _relire() {
    ref.invalidate(obligationsContractuelsProvider);
    ref.invalidate(contexteCreationObligationProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    final AsyncValue<List<ObligationContractuel>> liste = ref.watch(
      obligationsContractuelsProvider,
    );
    final ContexteCreationObligation? contexte = ref
        .watch(contexteCreationObligationProvider)
        .value;
    // Sans reseau, un echec se dit « hors ligne » ; une capacite absente
    // reste dite indisponible.
    final Object? erreur = liste.hasError ? liste.error : null;
    final bool echecHorsLigne =
        erreur != null &&
        erreur is! CapaciteIndisponible &&
        (ref.watch(horsLigneProvider).value ?? false);
    final RaisonBlocage? raison = contexte?.permissions.raisonDe(
      ActionFinance.creerObligation,
    );
    final List<ObligationContractuel> toutes =
        liste.value ?? const <ObligationContractuel>[];
    // Sur bureau, un tableau qui defile seul ; sinon la page entiere defile
    // et chaque obligation est une carte (la tete des onglets est haute).
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;

    return PageShell(
      titre: c.titre,
      sousTitre: c.sousTitre,
      defilante: !bureau,
      entete: _entete(context, contexte, raison, toutes, liste.hasValue),
      actionsEntete: <Widget>[
        const BasculeMontants(),
        // Sur bureau, en haut a droite (H08 W06) ; sur telephone l'en-tete
        // est deja plein, le bouton passe sous les onglets.
        if (contexte != null && contexte.peutCreer && bureau)
          _boutonNouvelle(context),
      ],
      child: echecHorsLigne
          ? EtatSysteme(nature: NatureEtat.horsLigne, onAction: _relire)
          : BlocAsynchrone<List<ObligationContractuel>>(
              valeur: liste,
              squelette: const Skeleton.liste(lignes: 5),
              onReessayer: _relire,
              estVide: (List<ObligationContractuel> l) =>
                  l.where(_onglet.contient).isEmpty,
              vide: _Vide(onglet: _onglet),
              construire: (List<ObligationContractuel> l) {
                final List<ObligationContractuel> vues = l
                    .where(_onglet.contient)
                    .toList();
                return bureau
                    ? _Tableau(obligations: vues)
                    : _Cartes(obligations: vues);
              },
            ),
    );
  }

  Widget _boutonNouvelle(BuildContext context) => ActionPrincipale(
    key: const ValueKey<String>('nouvelle-obligation'),
    libelle: t.comptable.contractuels.nouvelle,
    compacte: true,
    pleineLargeur: false,
    prefixe: Icon(AppIcons.ajouter.repos),
    onPress: () => context.push(Routes.comptableContractuelsNouvelle),
  );

  /// L'en-tete qui ne defile pas (sauf a texte agrandi, par le gabarit) : les
  /// onglets de Paiements, la phrase d'une creation indisponible, les quatre
  /// zones.
  Widget _entete(
    BuildContext context,
    ContexteCreationObligation? contexte,
    RaisonBlocage? raison,
    List<ObligationContractuel> toutes,
    bool charge,
  ) {
    final c = t.comptable.contractuels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SousNavigationDomaine(
          onglets: ongletsPaiementsComptable(),
          indexActif: 1,
        ),
        Ecart.vLg,
        if (contexte != null &&
            contexte.peutCreer &&
            AppGabarit.de(context) != Gabarit.desktop) ...<Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _boutonNouvelle(context),
          ),
          Ecart.vMd,
        ],
        if (contexte != null &&
            !contexte.peutCreer &&
            raison != null) ...<Widget>[
          Text(
            c.creationBloquee(raison: libelleRaisonBlocage(raison)),
            style: AppPalette.of(context).inkMuted.applyTo(
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
        ],
        Semantics(
          container: true,
          label: c.ongletsLecteur,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final OngletContractuels o in OngletContractuels.values)
                FilterPill(
                  key: ValueKey<String>('onglet-${o.parametre}'),
                  libelle: _libelleOnglet(o),
                  retenue: o == _onglet,
                  compteur: charge ? toutes.where(o.contient).length : null,
                  onPress: () => setState(() => _onglet = o),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _libelleOnglet(OngletContractuels o) {
  final c = t.comptable.contractuels;
  return switch (o) {
    OngletContractuels.obligations => c.ongletObligations,
    OngletContractuels.aApprouver => c.ongletAApprouver,
    OngletContractuels.aPayer => c.ongletAPayer,
    OngletContractuels.historique => c.ongletHistorique,
  };
}

/// Le mot du type d'une obligation (§22.1).
String libelleTypeObligation(TypeObligationContractuel type) {
  final c = t.comptable.contractuels;
  return switch (type) {
    TypeObligationContractuel.recurrente => c.typeRecurrente,
    TypeObligationContractuel.ponctuelle => c.typePonctuelle,
  };
}

/// L'etat vide d'une zone : une phrase, aucune action (un vide subi).
class _Vide extends StatelessWidget {
  const _Vide({required this.onglet});

  final OngletContractuels onglet;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    final (String message, String detail) = switch (onglet) {
      OngletContractuels.obligations => (
        c.videObligations,
        c.videObligationsDetail,
      ),
      OngletContractuels.aApprouver => (
        c.videAApprouver,
        c.videAApprouverDetail,
      ),
      OngletContractuels.aPayer => (c.videAPayer, c.videAPayerDetail),
      OngletContractuels.historique => (
        c.videHistorique,
        c.videHistoriqueDetail,
      ),
    };
    return EmptyState(
      message: message,
      invitation: detail,
      icone: AppIcons.finance,
      registre: RegistreVide.subi,
    );
  }
}

/// Les obligations en cartes (telephone et tablette), dans la page qui
/// defile : le beneficiaire, l'objet, l'echeance, le montant masque, le
/// statut, et « Payer » quand la source le permet.
class _Cartes extends StatelessWidget {
  const _Cartes({required this.obligations});

  final List<ObligationContractuel> obligations;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < obligations.length; i++) ...<Widget>[
          if (i > 0) Ecart.vMd,
          _carte(context, obligations[i], palette, textes, attenue),
        ],
      ],
    );
  }

  Widget _carte(
    BuildContext context,
    ObligationContractuel o,
    AppPalette palette,
    TextTheme textes,
    TextStyle attenue,
  ) {
    final String? payable = o.obligationPayableId;
    final bool payer =
        o.etat == EtatObligationContractuel.approuvee &&
        o.permissions.permet(ActionFinance.payer) &&
        payable != null;
    return AppCard(
      key: ValueKey<String>('obligation-${o.id}'),
      onPress: () =>
          context.push(Routes.comptableContractuelObligationPour(o.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            o.beneficiaire.nom,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(
            '${o.objet} · ${libelleTypeObligation(o.type)}',
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Text(
            t.comptable.contractuels.echeanceLe(
              date: dateComptable(o.echeance),
            ),
            style: attenue,
          ),
          Ecart.vMd,
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              MontantSensible(o.montant),
              StatusPill(
                libelle: libelleObligationContractuel(o.etat),
                ton: tonObligationContractuel(o.etat),
              ),
            ],
          ),
          if (payer) ...<Widget>[
            Ecart.vMd,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionPrincipale(
                key: ValueKey<String>('payer-${o.id}'),
                libelle: t.comptable.contractuels.payer,
                niveau: NiveauAction.secondaire,
                compacte: true,
                pleineLargeur: false,
                onPress: () => context.push(
                  Routes.comptablePaiementObligationPour(payable),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// La table des obligations, sur bureau.
class _Tableau extends StatelessWidget {
  const _Tableau({required this.obligations});

  final List<ObligationContractuel> obligations;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    return DataCollection<ObligationContractuel>(
      lignes: obligations,
      cle: (ObligationContractuel o) => ValueKey<String>('obligation-${o.id}'),
      onSelectionner: (ObligationContractuel o) =>
          context.push(Routes.comptableContractuelObligationPour(o.id)),
      colonnes: <ColonneDonnees<ObligationContractuel>>[
        ColonneDonnees<ObligationContractuel>(
          titre: c.colonneBeneficiaire,
          role: RoleColonne.identifiante,
          flex: 2,
          texte: (ObligationContractuel o) => o.beneficiaire.nom,
        ),
        ColonneDonnees<ObligationContractuel>(
          titre: c.colonneObjet,
          flex: 3,
          texte: (ObligationContractuel o) =>
              '${o.objet} · ${libelleTypeObligation(o.type)}',
        ),
        ColonneDonnees<ObligationContractuel>(
          titre: c.colonneEcheance,
          texte: (ObligationContractuel o) =>
              c.echeanceLe(date: dateComptable(o.echeance)),
        ),
        // Un montant ne se dit jamais en texte : il passe par
        // `MontantSensible`, masque par defaut (R-FIN-01).
        ColonneDonnees<ObligationContractuel>(
          titre: c.colonneMontant,
          role: RoleColonne.aPart,
          tabulaire: true,
          texte: (ObligationContractuel _) => '',
          rendreMemeSiTexteVide: true,
          rendu: (BuildContext _, ObligationContractuel o) =>
              MontantSensible(o.montant),
        ),
        ColonneDonnees<ObligationContractuel>(
          titre: c.colonneStatut,
          role: RoleColonne.aPart,
          texte: (ObligationContractuel o) =>
              libelleObligationContractuel(o.etat),
          rendu: (BuildContext _, ObligationContractuel o) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusPill(
              libelle: libelleObligationContractuel(o.etat),
              ton: tonObligationContractuel(o.etat),
            ),
          ),
        ),
        ColonneDonnees<ObligationContractuel>(
          titre: '',
          role: RoleColonne.aPart,
          texte: (ObligationContractuel _) => '',
          rendreMemeSiTexteVide: true,
          rendu: (BuildContext contexte, ObligationContractuel o) {
            final String? payable = o.obligationPayableId;
            // « Payer » n'existe que si la source le permet et que
            // l'obligation payable existe : il ouvre W03 (DR-12).
            if (o.etat != EtatObligationContractuel.approuvee ||
                !o.permissions.permet(ActionFinance.payer) ||
                payable == null) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionPrincipale(
                key: ValueKey<String>('payer-${o.id}'),
                libelle: c.payer,
                niveau: NiveauAction.secondaire,
                compacte: true,
                pleineLargeur: false,
                onPress: () => contexte.push(
                  Routes.comptablePaiementObligationPour(payable),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
