// `FinanceDelegationPolicyPanel` (spec §37, §21.2 ; CPT-DIR-1) : ce que le
// Comptable peut executer seul, regle une fois par la Direction. Pouvoirs
// (paiements standards, remboursement, alimentation de la Reserve), plafonds
// par transaction, par lot et par periode, secondes validations (retrait de
// la Reserve, premier paiement, coordonnees recentes) et, en lecture seule,
// les trois regles que rien ne leve (auto-payout, montant manuel, politique
// tarifaire).
//
// **Aucun plafond code** : un plafond vide n'en fixe aucun ; 10 USD comme
// 1 000 000 USD s'enregistrent pareil. Le panneau ne lit rien : il recoit la
// politique et rend le brouillon a [FinanceDelegationPolicyPanel.onEnregistrer].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/port_delegation_finance.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import '../../../core/widgets/setting_row.dart';
import '../../../core/widgets/status_pill.dart';
import 'composants_politique.dart';
import 'politiques_direction.dart';
import 'saisie_politique.dart';

/// La lecture et l'enregistrement du panneau : la delegation et son
/// historique. L'enregistrement relit les deux.
class FinanceDelegationPolicyPanelBloc extends ConsumerWidget {
  /// Cree le bloc.
  const FinanceDelegationPolicyPanelBloc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocPolitique<PolitiqueDelegationFinance>(
      fournisseur: politiqueDelegationProvider,
      construire: (PolitiqueDelegationFinance politique) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FinanceDelegationPolicyPanel(
            politique: politique,
            onEnregistrer:
                (BrouillonDelegationFinance brouillon, String cle) async {
                  await ref
                      .read(portDelegationFinanceProvider)
                      .enregistrer(brouillon: brouillon, cleIdempotence: cle);
                  ref
                    ..invalidate(politiqueDelegationProvider)
                    ..invalidate(journalDelegationProvider);
                },
          ),
          Ecart.vXxl,
          HistoriqueVersions(fournisseur: journalDelegationProvider),
        ],
      ),
    );
  }
}

/// Le panneau de delegation financiere.
class FinanceDelegationPolicyPanel extends StatefulWidget {
  /// Cree le panneau pour [politique].
  const FinanceDelegationPolicyPanel({
    required this.politique,
    required this.onEnregistrer,
    super.key,
  });

  /// La politique en vigueur.
  final PolitiqueDelegationFinance politique;

  /// Enregistre [BrouillonDelegationFinance] sous la cle d'idempotence donnee.
  /// Echoue avec l'erreur de la source.
  final Future<void> Function(BrouillonDelegationFinance brouillon, String cle)
  onEnregistrer;

  /// La cle du bouton d'enregistrement (tests).
  static const Key enregistrerKey = ValueKey<String>(
    'cpt-dir-delegation-enregistrer',
  );

  @override
  State<FinanceDelegationPolicyPanel> createState() =>
      _FinanceDelegationPolicyPanelState();
}

class _FinanceDelegationPolicyPanelState
    extends State<FinanceDelegationPolicyPanel> {
  late bool _paiements;
  late bool _remboursement;
  late bool _alimentation;
  late bool _retrait;
  late bool _premier;
  late bool _coordonnees;
  final TextEditingController _transaction = TextEditingController();
  final TextEditingController _lot = TextEditingController();
  final TextEditingController _periode = TextEditingController();
  final TextEditingController _jours = TextEditingController();

  bool _tente = false;
  bool _enCours = false;
  String? _message;
  bool _messageEstErreur = false;
  String? _cle;

  String get _devise =>
      widget.politique.plafondParTransaction?.devise ??
      widget.politique.plafondParLot?.devise ??
      widget.politique.plafondParPeriode?.devise ??
      deviseDeLancement;

  @override
  void initState() {
    super.initState();
    _charger(widget.politique);
  }

  @override
  void didUpdateWidget(FinanceDelegationPolicyPanel ancien) {
    super.didUpdateWidget(ancien);
    if (widget.politique.version != ancien.politique.version) {
      _charger(widget.politique);
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _transaction,
      _lot,
      _periode,
      _jours,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _charger(PolitiqueDelegationFinance p) {
    _paiements = p.paiementsStandardsAutorises;
    _remboursement = p.remboursementStandardAutorise;
    _alimentation = p.alimentationReserveAutorisee;
    _retrait = p.retraitReserveInterdit;
    _premier = p.premierPaiementSecondeValidation;
    _coordonnees = p.coordonneesRecentesSecondeValidation;
    _transaction.text = texteMontant(p.plafondParTransaction);
    _lot.text = texteMontant(p.plafondParLot);
    _periode.text = texteMontant(p.plafondParPeriode);
    _jours.text = texteEntier(p.joursCoordonneesRecentes);
    _tente = false;
    _cle = null;
  }

  bool get _modifie {
    final PolitiqueDelegationFinance p = widget.politique;
    return _paiements != p.paiementsStandardsAutorises ||
        _remboursement != p.remboursementStandardAutorise ||
        _alimentation != p.alimentationReserveAutorisee ||
        _retrait != p.retraitReserveInterdit ||
        _premier != p.premierPaiementSecondeValidation ||
        _coordonnees != p.coordonneesRecentesSecondeValidation ||
        _transaction.text != texteMontant(p.plafondParTransaction) ||
        _lot.text != texteMontant(p.plafondParLot) ||
        _periode.text != texteMontant(p.plafondParPeriode) ||
        (_coordonnees &&
            _jours.text != texteEntier(p.joursCoordonneesRecentes));
  }

  /// Un plafond vide n'en fixe aucun ; rempli, il doit etre lisible.
  bool _plafondValide(TextEditingController c) =>
      c.text.trim().isEmpty || lireMontant(c.text, _devise) != null;

  Montant? _plafond(TextEditingController c) =>
      c.text.trim().isEmpty ? null : lireMontant(c.text, _devise);

  String? _erreurPlafond(TextEditingController c) =>
      _tente && !_plafondValide(c) ? t.comptable.direction.erreurMontant : null;

  BrouillonDelegationFinance? _brouillon() {
    final int? jours = _coordonnees ? lireEntier(_jours.text) : null;
    if (!_plafondValide(_transaction) ||
        !_plafondValide(_lot) ||
        !_plafondValide(_periode) ||
        (_coordonnees && jours == null)) {
      return null;
    }
    return BrouillonDelegationFinance(
      paiementsStandardsAutorises: _paiements,
      remboursementStandardAutorise: _remboursement,
      alimentationReserveAutorisee: _alimentation,
      retraitReserveInterdit: _retrait,
      premierPaiementSecondeValidation: _premier,
      coordonneesRecentesSecondeValidation: _coordonnees,
      plafondParTransaction: _plafond(_transaction),
      plafondParLot: _plafond(_lot),
      plafondParPeriode: _plafond(_periode),
      joursCoordonneesRecentes: jours,
    );
  }

  void _edite(VoidCallback changement) => setState(() {
    changement();
    _cle = null;
    _message = null;
  });

  Future<void> _enregistrer() async {
    final BrouillonDelegationFinance? brouillon = _brouillon();
    if (brouillon == null) {
      setState(() {
        _tente = true;
        _message = t.comptable.direction.corrigezChamps;
        _messageEstErreur = true;
      });
      return;
    }
    final String cle = _cle ??= nouvelleCleIdempotence('delegation');
    setState(() {
      _enCours = true;
      _message = null;
    });
    try {
      await widget.onEnregistrer(brouillon, cle);
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _cle = null;
        _tente = false;
        _message = t.comptable.direction.enregistree;
        _messageEstErreur = false;
      });
    } catch (erreur) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _message = phraseEchecEnregistrement(erreur);
        _messageEstErreur = true;
      });
    }
  }

  SettingRow _interrupteur({
    required String titre,
    required String detail,
    required AppIcon icone,
    required bool valeur,
    required ValueChanged<bool> onChange,
  }) => SettingRow(
    title: titre,
    description: detail,
    icon: icone,
    controle: Switch.adaptive(
      value: valeur,
      onChanged: _enCours ? null : (bool v) => _edite(() => onChange(v)),
    ),
  );

  ChampPolitique _champPlafond({
    required String libelle,
    required String detail,
    required TextEditingController controleur,
  }) => ChampPolitique(
    libelle: libelle,
    consequence: detail,
    suffixe: symboleDe(_devise),
    indice: t.comptable.direction.delegationPanneau.plafondIndice,
    controleur: controleur,
    erreur: _erreurPlafond(controleur),
    actif: !_enCours,
    onChange: () => _edite(() {}),
  );

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.direction;
    final d = c.delegationPanneau;
    final PolitiqueDelegationFinance p = widget.politique;
    final DateTime? dateEffet = p.dateEffet;
    final String? auteur = p.auteur;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            StatusPill(
              libelle: dateEffet == null
                  ? c.versionSansDate(version: p.version)
                  : c.versionDepuis(
                      version: p.version,
                      date: dateComptable(dateEffet),
                    ),
              ton: TonEtat.succes,
            ),
            if (auteur != null) Text(c.auteur(auteur: auteur)),
          ],
        ),
        Ecart.vSm,
        Text(d.intro),
        Ecart.vXxl,
        GroupePolitique(
          titre: d.pouvoirsTitre,
          enfants: <Widget>[
            _interrupteur(
              titre: d.paiementsStandards,
              detail: d.paiementsStandardsDetail,
              icone: AppIcons.paiements,
              valeur: _paiements,
              onChange: (bool v) => _paiements = v,
            ),
            _interrupteur(
              titre: d.remboursement,
              detail: d.remboursementDetail,
              icone: AppIcons.sortieArgent,
              valeur: _remboursement,
              onChange: (bool v) => _remboursement = v,
            ),
            _interrupteur(
              titre: d.alimentationReserve,
              detail: d.alimentationReserveDetail,
              icone: AppIcons.reserve,
              valeur: _alimentation,
              onChange: (bool v) => _alimentation = v,
            ),
          ],
        ),
        Ecart.vXxl,
        GroupePolitique(
          titre: d.plafondsTitre,
          detail: d.plafondsDetail,
          enfants: <Widget>[
            _champPlafond(
              libelle: d.plafondTransaction,
              detail: d.plafondTransactionDetail,
              controleur: _transaction,
            ),
            _champPlafond(
              libelle: d.plafondLot,
              detail: d.plafondLotDetail,
              controleur: _lot,
            ),
            _champPlafond(
              libelle: d.plafondPeriode,
              detail: d.plafondPeriodeDetail,
              controleur: _periode,
            ),
          ],
        ),
        Ecart.vXxl,
        GroupePolitique(
          titre: d.validationsTitre,
          enfants: <Widget>[
            _interrupteur(
              titre: d.retraitReserve,
              detail: d.retraitReserveDetail,
              icone: AppIcons.verrou,
              valeur: _retrait,
              onChange: (bool v) => _retrait = v,
            ),
            _interrupteur(
              titre: d.premierPaiement,
              detail: d.premierPaiementDetail,
              icone: AppIcons.beneficiaire,
              valeur: _premier,
              onChange: (bool v) => _premier = v,
            ),
            _interrupteur(
              titre: d.coordonnees,
              detail: d.coordonneesDetail,
              icone: AppIcons.historique,
              valeur: _coordonnees,
              onChange: (bool v) => _coordonnees = v,
            ),
            if (_coordonnees)
              ChampPolitique(
                libelle: d.joursRecents,
                consequence: d.joursRecentsDetail,
                suffixe: c.suffixeJours,
                controleur: _jours,
                erreur: _tente && lireEntier(_jours.text) == null
                    ? c.erreurNombre
                    : null,
                actif: !_enCours,
                onChange: () => _edite(() {}),
              ),
          ],
        ),
        Ecart.vXxl,
        GroupePolitique(
          titre: d.toujoursTitre,
          detail: d.toujoursDetail,
          enfants: <Widget>[
            _Interdit(titre: d.autoPayout, detail: d.autoPayoutDetail),
            _Interdit(titre: d.montantManuel, detail: d.montantManuelDetail),
            _Interdit(
              titre: d.politiqueTarifaire,
              detail: d.politiqueTarifaireDetail,
            ),
          ],
        ),
        Ecart.vXxl,
        // Spec §21.4 : ce qui est sensible quoi qu'on regle plus haut. Une
        // ligne en lecture seule par cas, rien ne se regle ici (COMPTA-RECON-1
        // §3.2 ; l'echelle des exceptions attend une decision du directeur).
        GroupePolitique(
          titre: d.sensiblesTitre,
          detail: d.sensiblesDetail,
          enfants: <Widget>[
            _Interdit(
              titre: d.sensibleHorsSeuil,
              detail: d.sensibleHorsSeuilDetail,
            ),
            _Interdit(
              titre: d.sensibleHorsCycle,
              detail: d.sensibleHorsCycleDetail,
            ),
            _Interdit(
              titre: d.sensibleLieOperateur,
              detail: d.sensibleLieOperateurDetail,
            ),
            _Interdit(
              titre: d.sensibleFournisseur,
              detail: d.sensibleFournisseurDetail,
            ),
            _Interdit(
              titre: d.sensibleManuelle,
              detail: d.sensibleManuelleDetail,
            ),
          ],
        ),
        Ecart.vXxl,
        PiedEnregistrement(
          key: FinanceDelegationPolicyPanel.enregistrerKey,
          modifie: _modifie,
          enCours: _enCours,
          onEnregistrer: _enregistrer,
          message: _message,
          messageEstErreur: _messageEstErreur,
        ),
      ],
    );
  }
}

/// Une regle que rien ne leve : une ligne en lecture seule, sans interrupteur
/// (le titre du groupe dit « Toujours interdit »).
class _Interdit extends StatelessWidget {
  const _Interdit({required this.titre, required this.detail});

  final String titre;
  final String detail;

  @override
  Widget build(BuildContext context) =>
      SettingRow(title: titre, description: detail, icon: AppIcons.interdit);
}
