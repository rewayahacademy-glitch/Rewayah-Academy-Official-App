// Paiements a effectuer (FIN-CPT-W02, M01 ecran 2 ; spec §13, §14, §15, §30).
// Posee « en preparation » par CPT-F avec son constructeur definitif ;
// **propriete de la voie CPT-PAY**, qui ecrit dans
// `lib/features/comptable/paiements/**` seulement
// (`20_comptable/02_DECOUPAGE.md`).
//
// Composition (planches H04 et H08 W02, layout seulement, K-63) : les
// filtres, le compteur et « Selectionner tous les paiements prets », le
// tableau de §30 au bureau, des cartes sur telephone et tablette (§45), la
// barre de selection collee en bas.
//
// Montant en lecture seule, jamais un champ de saisie (R-FIN-16) ;
// consolidation par beneficiaire (une ligne par obligation consolidee), la
// Classe reste un filtre (§14.4, 14.5) ; chaque action vient des permissions
// rendues par la source, jamais d'un role (DR-19). Cinq etats : squelette,
// contenu, vide (avec ou sans filtre), erreur (« Reessayer »), hors ligne
// (bandeau de `PageShell`, etat hors ligne et paiements retires). Sans
// source serveur (production d'aujourd'hui), la page dit honnetement « en
// preparation ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_export_rapports.dart';
import '../../../core/capacites/port_obligations_payables.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/barre_selection.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/data_collection.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/menu_filtre.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/pile_cartes.dart';
import '../../../core/widgets/rangee_filtres.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import '../graphiques/action_export.dart';
import 'confirmation/confirmation_payout.dart';
import 'espace_paiements.dart';
import 'ligne_obligation.dart';
import 'paiements_donnees.dart';

/// La liste des paiements a effectuer, onglet « A effectuer » de Paiements.
class PaiementsAEffectuerPage extends ConsumerStatefulWidget {
  /// Cree la page. Les trois filtres viennent de l'adresse, bruts
  /// (`?filtre=prets|infos|verification|validation|retard`,
  /// `?type=enseignant|contractuel`, `?classe=`) : les liens d'Aujourd'hui
  /// ouvrent la liste deja filtree (§5.1).
  const PaiementsAEffectuerPage({
    super.key,
    this.filtre,
    this.type,
    this.classe,
    this.espace,
  });

  /// L'espace de la page : celui du Comptable par defaut, ou la Finance de
  /// la direction (« Paie des enseignants », directeur, 31/10/2026). Il
  /// donne les onglets, le titre et les adresses des liens.
  final EspacePaiements? espace;

  /// Le filtre d'etat, brut.
  final String? filtre;

  /// Le type de beneficiaire, brut.
  final String? type;

  /// La Classe, brute.
  final String? classe;

  /// La cle du lien « Selectionner tous les paiements prets ».
  static const Key cleSelectionnerPrets = ValueKey<String>(
    'paiements-selectionner-prets',
  );

  @override
  ConsumerState<PaiementsAEffectuerPage> createState() =>
      _PaiementsAEffectuerPageState();
}

class _PaiementsAEffectuerPageState
    extends ConsumerState<PaiementsAEffectuerPage> {
  FiltrePaiements? _filtre;
  TypeBeneficiaire? _type;
  String? _classe;
  String? _periode;

  /// Les obligations retenues, par identifiant. Videe a chaque changement
  /// de filtre : ce qui est retenu reste toujours visible.
  final Set<String> _selection = <String>{};

  @override
  void initState() {
    super.initState();
    _lireAdresse();
  }

  @override
  void didUpdateWidget(PaiementsAEffectuerPage ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.filtre != widget.filtre ||
        ancien.type != widget.type ||
        ancien.classe != widget.classe) {
      setState(() {
        _lireAdresse();
        _selection.clear();
      });
    }
  }

  void _lireAdresse() {
    _filtre = filtrePaiementsDe(widget.filtre);
    _type = typeBeneficiaireDe(widget.type);
    _classe = classeDe(widget.classe);
    _periode = null;
  }

  FiltreObligations get _filtreSource =>
      filtreDe(filtre: _filtre, type: _type, classe: _classe);

  bool get _filtrePose =>
      _filtre != null || _type != null || _classe != null || _periode != null;

  void _changer(VoidCallback changement) => setState(() {
    changement();
    _selection.clear();
  });

  void _effacer() => _changer(() {
    _filtre = null;
    _type = null;
    _classe = null;
    _periode = null;
  });

  EspacePaiements get _espace => widget.espace ?? EspacePaiements.comptable();

  void _ouvrir(ObligationPayable o) => context.push(_espace.detail(o.id));

  /// Le profil du beneficiaire quand l'espace en a un ; sinon le detail, qui
  /// dit ce qui manque (la direction n'a pas les pages du Comptable).
  void _relancer(ObligationPayable o) {
    final String Function(String)? beneficiaire = _espace.beneficiaire;
    context.push(
      beneficiaire == null
          ? _espace.detail(o.id)
          : beneficiaire(o.beneficiaire.id),
    );
  }

  void _basculer(ObligationPayable o, bool retenue) => setState(() {
    if (retenue) {
      _selection.add(o.id);
    } else {
      _selection.remove(o.id);
    }
  });

  /// Ouvre la confirmation (CPT-PAY-2) pour [choisies] : preflight, puis
  /// confirmation explicite des seuls prets. Au retour, la selection est
  /// relachee et la liste relue : les etats viennent de la source.
  Future<void> _payer(List<ObligationPayable> choisies) async {
    if (choisies.isEmpty) return;
    final bool change = await ouvrirConfirmationPayout(context, choisies);
    if (!mounted) return;
    if (change) {
      setState(_selection.clear);
      _relire();
    }
  }

  void _selectionnerPrets(List<ObligationPayable> visibles) => setState(() {
    _selection
      ..clear()
      ..addAll(<String>[
        for (final ObligationPayable o in visibles)
          if (estPrete(o)) o.id,
      ]);
  });

  void _relire() {
    ref
      ..invalidate(obligationsPayablesProvider(_filtreSource))
      ..invalidate(obligationsPayablesProvider(FiltreObligations.tout));
  }

  @override
  Widget build(BuildContext context) {
    final p = t.comptable.paiements;
    final EspacePaiements espace = _espace;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    final AsyncValue<List<ObligationPayable>> valeur = ref.watch(
      obligationsPayablesProvider(_filtreSource),
    );
    // Les Classes et les periodes proposees aux filtres viennent de la liste
    // complete : filtrer par une Classe ne fait pas disparaitre les autres
    // du menu.
    final AsyncValue<List<ObligationPayable>> toutes = ref.watch(
      obligationsPayablesProvider(FiltreObligations.tout),
    );
    final List<ObligationPayable> connues = toutes.hasValue
        ? toutes.requireValue
        : const <ObligationPayable>[];
    final GestesObligation gestes = GestesObligation(
      selection: _selection,
      ouvrir: _ouvrir,
      basculer: _basculer,
      relancer: _relancer,
      payer: (ObligationPayable o) => _payer(<ObligationPayable>[o]),
      demanderValidation: (ObligationPayable o) =>
          _payer(<ObligationPayable>[o]),
      horsLigne: horsLigne,
    );
    // Les obligations retenues, dans l'ordre de la liste lue.
    final List<ObligationPayable> retenues = <ObligationPayable>[
      if (valeur.hasValue)
        for (final ObligationPayable o in valeur.requireValue)
          if (_selection.contains(o.id)) o,
    ];

    final Widget bloc = BlocAsynchrone<List<ObligationPayable>>(
      valeur: valeur,
      squelette: const Skeleton.liste(lignes: 6),
      onReessayer: _relire,
      erreurVersEtat: (Object erreur, VoidCallback? _) =>
          _etatErreur(erreur, horsLigne),
      vide: _vide(),
      construire: (List<ObligationPayable> liste) {
        final List<ObligationPayable> visibles = <ObligationPayable>[
          for (final ObligationPayable o in liste)
            if (_periode == null || o.periode == _periode) o,
        ];
        if (visibles.isEmpty) return _vide();
        return _Liste(
          obligations: visibles,
          gestes: gestes,
          bureau: bureau,
          onSelectionnerPrets: () => _selectionnerPrets(visibles),
        );
      },
    );

    final Widget filtres = _Filtres(
      filtre: _filtre,
      type: _type,
      classe: _classe,
      periode: _periode,
      classes: <String>{
        ?_classe,
        for (final ObligationPayable o in connues) ...o.classes,
      }.toList(),
      periodes: <String>{
        ?_periode,
        for (final ObligationPayable o in connues) o.periode,
      }.toList(),
      filtrePose: _filtrePose,
      onFiltre: (FiltrePaiements? f) => _changer(() => _filtre = f),
      onType: (TypeBeneficiaire? v) => _changer(() => _type = v),
      onClasse: (String? c) => _changer(() => _classe = c),
      onPeriode: (String? v) => _changer(() => _periode = v),
      onEffacer: _effacer,
    );

    return PageShell(
      titre: espace.titre,
      sousTitre: p.sousTitre,
      entete: SousNavigationDomaine(
        onglets: espace.onglets,
        indexActif: espace.indexOnglet,
      ),
      actionsEntete: const <Widget>[BasculeMontants(avecEtat: true)],
      // Au bureau, le tableau defile lui-meme sous son en-tete de colonnes ;
      // ailleurs, la page defile et porte les cartes.
      defilante: !bureau,
      actions: _selection.isEmpty
          ? null
          : BarreSelection(
              titre: p.selection(n: _selection.length),
              phrase: horsLigne ? p.horsLigne : p.selectionPhrase,
              libelleRelacher: p.actions.viderSelection,
              onRelacher: () => setState(_selection.clear),
              // COMPTA-GRAPH-1 : l'export de la selection, par un port ; sans
              // capacite, une phrase le dit a la place de l'action.
              avantActions: ActionExport(
                perimetre: PerimetreExport.selection,
                identifiants: _selection.toList(),
              ),
              // Hors ligne, ou sans obligation retenue : l'action n'est pas
              // rendue, la phrase dit pourquoi.
              libelleAction: p.actions.payerSelection,
              onAction: retenues.isEmpty || horsLigne
                  ? null
                  : () => _payer(retenues),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          filtres,
          Ecart.vLg,
          if (bureau) Expanded(child: bloc) else bloc,
        ],
      ),
    );
  }

  Widget _vide() {
    final p = t.comptable.paiements.vide;
    if (_filtrePose) {
      return EmptyState(
        message: p.filtreMessage,
        invitation: p.filtreInvitation,
        libelleAction: t.comptable.paiements.filtres.effacer,
        onAction: _effacer,
      );
    }
    return EmptyState(
      message: p.message,
      invitation: p.invitation,
      registre: RegistreVide.bonneNouvelle,
    );
  }

  /// Sans source (production d'aujourd'hui) : « en preparation », honnete
  /// et sans chiffre. Hors ligne : l'etat hors ligne. Sinon : l'echec de
  /// bloc de `BlocAsynchrone`, avec « Reessayer ».
  Widget? _etatErreur(Object erreur, bool horsLigne) {
    if (erreur is CapaciteIndisponible) {
      return EmptyState(
        message: t.comptable.commun.enPreparationTitre,
        invitation: t.comptable.commun.enPreparationPhrase,
        registre: RegistreVide.subi,
      );
    }
    if (horsLigne) {
      return EtatSysteme.sansDonnees(
        quoi: t.sansDonnees.paiementsAEffectuer,
        onAction: _relire,
      );
    }
    return null;
  }
}

/// Les filtres de §30 : type en pilules (Tous, Enseignants, Contractuels),
/// statut, Classe et periode en menus. Tout se replie en lignes a 320.
class _Filtres extends StatelessWidget {
  const _Filtres({
    required this.filtre,
    required this.type,
    required this.classe,
    required this.periode,
    required this.classes,
    required this.periodes,
    required this.filtrePose,
    required this.onFiltre,
    required this.onType,
    required this.onClasse,
    required this.onPeriode,
    required this.onEffacer,
  });

  final FiltrePaiements? filtre;
  final TypeBeneficiaire? type;
  final String? classe;
  final String? periode;
  final List<String> classes;
  final List<String> periodes;
  final bool filtrePose;
  final ValueChanged<FiltrePaiements?> onFiltre;
  final ValueChanged<TypeBeneficiaire?> onType;
  final ValueChanged<String?> onClasse;
  final ValueChanged<String?> onPeriode;
  final VoidCallback onEffacer;

  @override
  Widget build(BuildContext context) {
    final f = t.comptable.paiements.filtres;
    return RangeeFiltres(
      filtres: <Widget>[
        FilterPill(
          libelle: f.tous,
          retenue: type == null,
          onPress: () => onType(null),
        ),
        FilterPill(
          libelle: f.enseignants,
          retenue: type == TypeBeneficiaire.enseignant,
          onPress: () => onType(TypeBeneficiaire.enseignant),
        ),
        FilterPill(
          libelle: f.contractuels,
          retenue: type == TypeBeneficiaire.contractuel,
          onPress: () => onType(TypeBeneficiaire.contractuel),
        ),
        MenuFiltre<FiltrePaiements>(
          libelle: f.statut,
          valeur: filtre,
          entrees: <EntreeFiltre<FiltrePaiements>>[
            EntreeFiltre<FiltrePaiements>(valeur: null, libelle: f.tousStatuts),
            for (final FiltrePaiements v in FiltrePaiements.values)
              EntreeFiltre<FiltrePaiements>(
                valeur: v,
                libelle: libelleFiltrePaiements(v),
              ),
          ],
          onChoix: onFiltre,
        ),
        if (classes.isNotEmpty)
          MenuFiltre<String>(
            libelle: f.classe,
            valeur: classe,
            entrees: <EntreeFiltre<String>>[
              EntreeFiltre<String>(valeur: null, libelle: f.toutesClasses),
              for (final String c in classes)
                EntreeFiltre<String>(valeur: c, libelle: c),
            ],
            onChoix: onClasse,
          ),
        if (periodes.length > 1 || periode != null)
          MenuFiltre<String>(
            libelle: f.periode,
            valeur: periode,
            entrees: <EntreeFiltre<String>>[
              EntreeFiltre<String>(valeur: null, libelle: f.toutesPeriodes),
              for (final String v in periodes)
                EntreeFiltre<String>(valeur: v, libelle: v),
            ],
            onChoix: onPeriode,
          ),
        if (filtrePose)
          LienFleche(
            libelle: f.effacer,
            legende: true,
            fleche: false,
            onPress: onEffacer,
          ),
      ],
    );
  }
}

/// Le compteur, « Selectionner tous les paiements prets », puis le tableau
/// au bureau ou les cartes ailleurs.
class _Liste extends StatelessWidget {
  const _Liste({
    required this.obligations,
    required this.gestes,
    required this.bureau,
    required this.onSelectionnerPrets,
  });

  final List<ObligationPayable> obligations;
  final GestesObligation gestes;
  final bool bureau;
  final VoidCallback onSelectionnerPrets;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool desPrets = obligations.any(estPrete);
    final Widget tete = Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            t.comptable.paiements.compteur(n: obligations.length),
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        if (desPrets)
          LienFleche(
            key: PaiementsAEffectuerPage.cleSelectionnerPrets,
            libelle: t.comptable.paiements.actions.selectionnerPrets,
            legende: true,
            fleche: false,
            onPress: onSelectionnerPrets,
          ),
      ],
    );
    if (bureau) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          tete,
          Ecart.vMd,
          Expanded(
            child: DataCollection<ObligationPayable>(
              colonnes: colonnesObligations(gestes),
              lignes: obligations,
              cle: (ObligationPayable o) =>
                  ValueKey<String>('obligation-${o.id}'),
              onSelectionner: gestes.ouvrir,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        tete,
        Ecart.vMd,
        PileCartes(
          children: <Widget>[
            for (final ObligationPayable o in obligations)
              CarteObligation(
                key: ValueKey<String>('obligation-${o.id}'),
                obligation: o,
                gestes: gestes,
              ),
          ],
        ),
      ],
    );
  }
}
