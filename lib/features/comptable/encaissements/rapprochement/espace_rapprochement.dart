// `ReconciliationWorkspace` (spec §25, §26, §47, §48 ; CPT-BR-14, 15, 17 ;
// UX_REVIEW §4 : a creer par CPT-ENC-2).
//
// Deux vues dans le meme onglet, choisies par deux pilules a compteur :
// - « A rapprocher » : les filtres des six etats §25 (Tous, Automatique, A
//   verifier, Rapproche, Conflit, Sans correspondance, Doublon potentiel),
//   la liste des transactions, et leur detail : panneau a droite a 1440,
//   feuille sous 1200 (meme contenu, `PanneauRapprochement`) ;
// - « Remboursements et avoirs » (§26) : vus et executes selon la politique,
//   jamais reecrite.
//
// Un doublon potentiel n'est jamais silencieux (§47) : sa ligne porte sa
// pastille, son detail un bandeau. Les compteurs comptent des lignes, jamais
// un montant (FI6).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/capacites/port_encaissements.dart';
import '../../../../core/capacites/port_rapprochement.dart';
import '../../../../core/comptable/statuts_comptable.dart';
import '../../../../core/i18n/strings.g.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/comptable/ligne_activite.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/filter_pill.dart';
import '../../../../core/widgets/montant_sensible.dart';
import '../../../../core/widgets/pastilles_comptable.dart';
import '../commun_encaissements.dart';
import 'donnees_rapprochement.dart';
import 'panneau_rapprochement.dart';
import 'remboursements_avoirs.dart';

/// Les deux vues de l'espace.
enum VueRapprochement {
  /// Les transactions a rapprocher (§25).
  transactions,

  /// Les remboursements et avoirs (§26).
  remboursements,
}

/// L'espace de rapprochement.
class ReconciliationWorkspace extends ConsumerStatefulWidget {
  /// Cree l'espace.
  const ReconciliationWorkspace({
    required this.elements,
    required this.panneau,
    super.key,
  });

  /// Les elements rendus par la source.
  final List<ElementRapprochement> elements;

  /// Vrai a 1440 (bureau, texte normal) : le detail en panneau.
  final bool panneau;

  /// La cle de la pilule d'une vue.
  static Key vueKey(VueRapprochement v) =>
      ValueKey<String>('rap-vue-${v.name}');

  /// La cle de la pilule d'un filtre d'etat (`null` : Tous).
  static Key filtreKey(EtatRapprochement? e) =>
      ValueKey<String>('rap-filtre-${e?.name ?? 'tous'}');

  /// La cle de la ligne d'un element.
  static Key ligneKey(String id) => ValueKey<String>('rap-ligne-$id');

  /// La cle du panneau detail.
  static const Key panneauKey = ValueKey<String>('rap-panneau');

  @override
  ConsumerState<ReconciliationWorkspace> createState() =>
      _ReconciliationWorkspaceState();
}

class _ReconciliationWorkspaceState
    extends ConsumerState<ReconciliationWorkspace> {
  VueRapprochement _vue = VueRapprochement.transactions;
  EtatRapprochement? _etat;
  String? _selection;

  Future<void> _ouvrir(ElementRapprochement e) async {
    if (widget.panneau) {
      setState(() => _selection = e.id);
      return;
    }
    // La feuille vit sur la route modale : elle reprend le conteneur de la
    // page (memes surcharges, meme visibilite des montants).
    final ProviderContainer conteneur = ProviderScope.containerOf(context);
    await AppBottomSheet.ouvrir<void>(
      context,
      titre: t.comptable.encaissements.rapprochementTitre,
      constructeur: (BuildContext _) => UncontrolledProviderScope(
        container: conteneur,
        child: PanneauRapprochement(elementId: e.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = t.comptable.encaissements.rap;
    final AsyncValue<List<Remboursement>> remboursements = ref.watch(
      remboursementsProvider,
    );
    final List<Widget> vues = <Widget>[
      FilterPill(
        key: ReconciliationWorkspace.vueKey(VueRapprochement.transactions),
        libelle: r.vueTransactions,
        retenue: _vue == VueRapprochement.transactions,
        compteur: widget.elements
            .where((ElementRapprochement e) => !estRelie(e.etat))
            .length,
        onPress: () => setState(() => _vue = VueRapprochement.transactions),
      ),
      FilterPill(
        key: ReconciliationWorkspace.vueKey(VueRapprochement.remboursements),
        libelle: r.vueRemboursements,
        retenue: _vue == VueRapprochement.remboursements,
        compteur: remboursements.value?.length,
        onPress: () => setState(() => _vue = VueRapprochement.remboursements),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: vues),
        Ecart.vXxl,
        switch (_vue) {
          VueRapprochement.transactions => _transactions(context),
          VueRapprochement.remboursements =>
            BlocEncaissements<List<Remboursement>>(
              valeur: remboursements,
              onReessayer: () => ref.invalidate(remboursementsProvider),
              construire: (List<Remboursement> liste) =>
                  RemboursementsAvoirs(remboursements: liste),
            ),
        },
      ],
    );
  }

  Widget _transactions(BuildContext context) {
    final r = t.comptable.encaissements.rap;
    final List<ElementRapprochement> tous = widget.elements;
    final List<ElementRapprochement> lignes = <ElementRapprochement>[
      for (final ElementRapprochement e in tous)
        if (_etat == null || e.etat == _etat) e,
    ];
    final Widget filtres = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final EtatRapprochement? etat in <EtatRapprochement?>[
          null,
          ...EtatRapprochement.values,
        ])
          FilterPill(
            key: ReconciliationWorkspace.filtreKey(etat),
            libelle: etat == null
                ? t.comptable.encaissements.filtreTous
                : libelleRapprochement(etat),
            retenue: etat == _etat,
            compteur: etat == null
                ? tous.length
                : tous.where((ElementRapprochement e) => e.etat == etat).length,
            onPress: () => setState(() {
              _etat = etat;
              _selection = null;
            }),
          ),
      ],
    );
    final Widget liste = lignes.isEmpty
        ? EmptyState(
            message: tous.isEmpty ? r.videTitre : r.videFiltreTitre,
            invitation: tous.isEmpty ? r.videPhrase : r.videFiltrePhrase,
            libelleAction: tous.isEmpty ? null : r.voirToutes,
            onAction: tous.isEmpty
                ? null
                : () => setState(() {
                    _etat = null;
                    _selection = null;
                  }),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < lignes.length; i++) ...<Widget>[
                if (i > 0) Ecart.vLg,
                _LigneElement(
                  key: ReconciliationWorkspace.ligneKey(lignes[i].id),
                  element: lignes[i],
                  choisie: lignes[i].id == _selection,
                  onPress: () => _ouvrir(lignes[i]),
                ),
              ],
            ],
          );
    final String? choisi =
        widget.panneau &&
            lignes.any((ElementRapprochement e) => e.id == _selection)
        ? _selection
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        filtres,
        Ecart.vLg,
        if (!widget.panneau)
          liste
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 3, child: liste),
              Ecart.hXxl,
              Expanded(
                flex: 2,
                child: choisi == null
                    ? EmptyState(
                        message: r.choisirTitre,
                        invitation: r.choisirPhrase,
                      )
                    : PanneauRapprochement(
                        key: ReconciliationWorkspace.panneauKey,
                        elementId: choisi,
                      ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Une transaction dans la liste : libelle, nature et date, reference, le
/// montant masquable, l'etat §25.
class _LigneElement extends StatelessWidget {
  const _LigneElement({
    required this.element,
    required this.choisie,
    required this.onPress,
    super.key,
  });

  final ElementRapprochement element;
  final bool choisie;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.comptable.encaissements.rap;
    final ElementRapprochement e = element;
    final String? reference = e.reference;
    final Widget texte = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          e.libelle,
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        NoteAttenuee(
          r.natureDate(
            nature: libelleNatureRapprochement(e.nature),
            date: dateComptable(e.date),
          ),
        ),
        if (reference != null)
          NoteAttenuee(
            t.comptable.commun.activiteReference(reference: reference),
          ),
      ],
    );
    final Widget montant = MontantSensible(e.montant);
    return AppCard(
      onPress: onPress,
      selectionnee: choisie,
      libelleSemantique: r.ouvrirLecteur(libelle: e.libelle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (texteAgrandi(context)) ...<Widget>[texte, Ecart.vSm, montant] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: texte),
                Ecart.hLg,
                montant,
              ],
            ),
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PastilleRapprochement(e.etat),
          ),
        ],
      ),
    );
  }
}
