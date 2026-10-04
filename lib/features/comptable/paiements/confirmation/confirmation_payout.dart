// `PayoutConfirmationSheet` (spec §7.5, §20, §21, §40, §41, §47 ; CPT-PAY-2).
//
// La seule surface ou un montant s'affiche malgre le masque : le montant
// exact, par `MontantArgent`, jamais `MontantSensible` (R-FIN-04, DR-05), et
// le bouton dit ce montant (« Confirmer le paiement de 212 USD »).
//
// Deroule, toujours dans cet ordre et jamais autrement :
// 1. preflight obligatoire de la selection (par identifiant **et** version) :
//    la source rend les prets, les exclus avec leur raison, les totaux par
//    devise, les prestataires, les plafonds restants ; l'ecran n'additionne
//    rien (§41) ;
// 2. confirmation explicite des seuls prets (R-FIN-22, 23), ou « Demander
//    validation » pour un paiement sensible (§21.4, §40) ;
// 3. soumission une fois, avec une cle d'idempotence tiree par preflight et
//    rejouee telle quelle a chaque nouvel essai : un double appui ou une
//    reponse perdue n'envoient qu'une fois (DR-13) ; le bouton est en cours
//    des l'appui ;
// 4. suivi rendu par le prestataire : jamais « Reussi » sur simple appui
//    (§5.3), un paiement envoye n'est pas un paiement confirme (§47).
//
// Etats d'echec honnetes : un refus de la source dit que rien n'est parti et
// pourquoi (version changee : « Le montant a ete recalcule », R-FIN-18) ; une
// erreur sans reponse dit que l'issue est inconnue et que reessayer renvoie
// la meme demande. Hors ligne, aucun bouton d'envoi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/capacites/port_obligations_payables.dart';
import '../../../../core/capacites/port_payout.dart';
import '../../../../core/comptable/modeles_comptable.dart';
import '../../../../core/comptable/statuts_comptable.dart';
import '../../../../core/finance/format_montant.dart';
import '../../../../core/finance/montant.dart';
import '../../../../core/i18n/strings.g.dart';
import '../../../../core/reseau/service_reseau.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/action_principale.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/bandeau_attention.dart';
import '../../../../core/widgets/comptable/ligne_activite.dart';
import '../../../../core/widgets/ligne_cle_valeur.dart';
import '../../../../core/widgets/ligne_destination.dart';
import '../../../../core/widgets/montant_argent.dart';
import '../../../../core/widgets/pastilles_comptable.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_pill.dart';
import '../paiements_donnees.dart';

/// Ouvre la confirmation pour [selection] (une obligation depuis une ligne
/// ou le detail, plusieurs depuis la barre de selection). Rend `true` quand
/// quelque chose a pu changer a la source (envoi, demande de validation,
/// recalcul) : la page relit alors sa liste.
Future<bool> ouvrirConfirmationPayout(
  BuildContext context,
  List<ObligationPayable> selection,
) async {
  // La feuille s'ouvre au-dessus de l'application : elle lit les ports de
  // la portee de la page qui l'ouvre (une demonstration les y surcharge).
  final ProviderContainer portee = ProviderScope.containerOf(
    context,
    listen: false,
  );
  final bool? change = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: titreConfirmation(selection),
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: portee,
      child: PayoutConfirmationSheet(selection: selection),
    ),
  );
  return change ?? true;
}

/// Le titre de la feuille, connu avant le preflight.
String titreConfirmation(List<ObligationPayable> selection) {
  final c = t.comptable.paiements.confirmation;
  if (selection.length != 1) return c.titreLot;
  return actionDe(selection.single) == ActionLigne.demanderValidation
      ? c.titreValidation
      : c.titreUn;
}

/// Les etats de paiement ou le suivi n'avancera plus.
const Set<EtatPaiementSortant> etatsTermines = <EtatPaiementSortant>{
  EtatPaiementSortant.reussi,
  EtatPaiementSortant.echoue,
  EtatPaiementSortant.annule,
  EtatPaiementSortant.retourne,
};

enum _Phase {
  controle,
  controleEchoue,
  pret,
  envoi,
  soumis,
  refuse,
  issueInconnue,
  validationDemandee,
  validationEchouee,
}

/// Le contenu de la feuille de confirmation d'un payout.
class PayoutConfirmationSheet extends ConsumerStatefulWidget {
  /// Cree la feuille pour [selection].
  const PayoutConfirmationSheet({required this.selection, super.key});

  /// Les obligations choisies, telles que vues par le Comptable.
  final List<ObligationPayable> selection;

  /// La cle du bouton de confirmation (« Confirmer le paiement de ... »).
  static const Key cleConfirmer = ValueKey<String>('payout-confirmer');

  /// La cle du bouton « Demander validation ».
  static const Key cleDemander = ValueKey<String>('payout-demander');

  /// La cle du bouton qui relance le preflight.
  static const Key cleRelancer = ValueKey<String>('payout-relancer');

  /// La cle du bouton « Reessayer » apres une issue inconnue.
  static const Key cleReessayer = ValueKey<String>('payout-reessayer');

  /// La cle du bouton « Actualiser le suivi ».
  static const Key cleActualiser = ValueKey<String>('payout-actualiser');

  @override
  ConsumerState<PayoutConfirmationSheet> createState() =>
      _PayoutConfirmationSheetState();
}

class _PayoutConfirmationSheetState
    extends ConsumerState<PayoutConfirmationSheet> {
  _Phase _phase = _Phase.controle;
  PreflightLot? _lot;

  /// Les obligations telles que relues apres un recalcul (R-FIN-18).
  late final Map<String, ObligationPayable> _obligations =
      <String, ObligationPayable>{
        for (final ObligationPayable o in widget.selection) o.id: o,
      };

  /// Tiree une fois par preflight, rejouee telle quelle a chaque essai.
  String _cle = const Uuid().v4();

  RefusPayout? _refus;
  bool _recalcul = false;
  List<SuiviPayout> _suivis = const <SuiviPayout>[];
  bool _actualisation = false;
  bool _suiviEchoue = false;
  bool _change = false;

  @override
  void initState() {
    super.initState();
    _controler();
  }

  Future<void> _controler() async {
    setState(() {
      _phase = _Phase.controle;
      _refus = null;
    });
    try {
      final PreflightLot lot = await ref.read(portPayoutProvider).preflight(
        <ObligationChoisie>[
          for (final ObligationPayable o in _obligations.values)
            ObligationChoisie(obligationId: o.id, version: o.version),
        ],
      );
      if (!mounted) return;
      setState(() {
        _lot = lot;
        _cle = const Uuid().v4();
        _phase = _Phase.pret;
      });
    } on Object {
      if (mounted) setState(() => _phase = _Phase.controleEchoue);
    }
  }

  Future<void> _soumettre() async {
    final PreflightLot? lot = _lot;
    if (lot == null || _phase == _Phase.envoi) return;
    setState(() => _phase = _Phase.envoi);
    try {
      final List<SuiviPayout> suivis = await ref
          .read(portPayoutProvider)
          .soumettre(preflightId: lot.id, cleIdempotence: _cle);
      if (!mounted) return;
      setState(() {
        _change = true;
        _suivis = suivis;
        _phase = _Phase.soumis;
      });
    } on RefusPayout catch (refus) {
      if (!mounted) return;
      if (refus.motif == MotifRefusPayout.versionChangee) {
        await _relireRecalculees(refus.obligationIds);
      }
      if (!mounted) return;
      setState(() {
        _change = true;
        _refus = refus;
        _recalcul = refus.motif == MotifRefusPayout.versionChangee;
        _phase = _Phase.refuse;
      });
    } on Object {
      // Aucune reponse : le paiement a pu partir. La meme cle sera
      // rejouee : la source rendra le suivi existant, sans second envoi.
      if (mounted) {
        setState(() {
          _change = true;
          _phase = _Phase.issueInconnue;
        });
      }
    }
  }

  /// Relit le detail des obligations recalculees : le prochain preflight
  /// porte leur nouvelle version et la feuille montre le nouveau montant.
  Future<void> _relireRecalculees(List<String> ids) async {
    final PortObligationsPayables port = ref.read(
      portObligationsPayablesProvider,
    );
    for (final String id in ids) {
      try {
        _obligations[id] = await port.detail(id);
      } on Object {
        // La relecture echouee laisse l'ancienne version : le preflight
        // suivant la refusera de nouveau, sans rien envoyer.
      }
    }
  }

  Future<void> _demanderValidation() async {
    if (_phase == _Phase.envoi) return;
    final ObligationPayable o = _obligations.values.first;
    setState(() => _phase = _Phase.envoi);
    try {
      await ref
          .read(portPayoutProvider)
          .demanderValidation(
            obligationId: o.id,
            motif: libelleRaisonBlocage(RaisonBlocage.validationRequise),
            cleIdempotence: _cle,
          );
      if (!mounted) return;
      setState(() {
        _change = true;
        _phase = _Phase.validationDemandee;
      });
    } on Object {
      if (mounted) setState(() => _phase = _Phase.validationEchouee);
    }
  }

  Future<void> _actualiser() async {
    if (_actualisation) return;
    setState(() {
      _actualisation = true;
      _suiviEchoue = false;
    });
    final PortPayout port = ref.read(portPayoutProvider);
    final List<SuiviPayout> lus = <SuiviPayout>[];
    bool echec = false;
    for (final SuiviPayout s in _suivis) {
      if (etatsTermines.contains(s.etat)) {
        lus.add(s);
        continue;
      }
      try {
        lus.add(await port.suivre(s.payoutId));
      } on Object {
        echec = true;
        lus.add(s);
      }
    }
    if (!mounted) return;
    setState(() {
      _suivis = lus;
      _actualisation = false;
      _suiviEchoue = echec;
    });
  }

  void _fermer() => Navigator.of(context).pop(_change);

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final PreflightLot? lot = _lot;
    final List<Widget> corps = switch (_phase) {
      _Phase.controle => <Widget>[const Skeleton.texte(lignes: 6)],
      _Phase.controleEchoue => <Widget>[
        _Bandeau(
          titre: t.comptable.paiements.confirmation.controleEchoueTitre,
          message: t.comptable.paiements.confirmation.controleEchoue,
          ton: TonEtat.alerte,
        ),
      ],
      _Phase.pret ||
      _Phase.envoi ||
      _Phase.validationEchouee => <Widget>[if (lot != null) ..._resume(lot)],
      _Phase.refuse => _refuse(),
      _Phase.issueInconnue => <Widget>[
        _Bandeau(
          titre: t.comptable.paiements.confirmation.inconnuTitre,
          message: t.comptable.paiements.confirmation.inconnuPhrase,
          ton: TonEtat.alerte,
        ),
      ],
      _Phase.soumis => _soumis(),
      _Phase.validationDemandee => <Widget>[
        _Bandeau(
          titre: t.comptable.paiements.confirmation.validationDemandeeTitre,
          message: t.comptable.paiements.confirmation.validationDemandeePhrase,
          ton: TonEtat.accent,
        ),
      ],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...corps,
        if (_phase == _Phase.validationEchouee) ...<Widget>[
          Ecart.vLg,
          _Bandeau(
            titre: t.comptable.paiements.confirmation.titreValidation,
            message: t.comptable.paiements.confirmation.validationEchouee,
            ton: TonEtat.alerte,
          ),
        ],
        if (horsLigne && _envoiPossible) ...<Widget>[
          Ecart.vLg,
          _Bandeau(
            titre: t.comptable.paiements.horsLigneCourt,
            message: t.comptable.paiements.horsLigne,
            ton: TonEtat.avertissement,
          ),
        ],
        Ecart.vXl,
        _actions(horsLigne),
      ],
    );
  }

  /// Vrai dans les phases ou un bouton d'envoi peut se poser.
  bool get _envoiPossible =>
      _phase == _Phase.pret ||
      _phase == _Phase.envoi ||
      _phase == _Phase.validationEchouee ||
      _phase == _Phase.issueInconnue;

  Widget _actions(bool horsLigne) {
    final c = t.comptable.paiements.confirmation;
    final bool termine =
        _phase == _Phase.soumis || _phase == _Phase.validationDemandee;
    final List<Widget> boutons = <Widget>[
      ActionPrincipale(
        libelle: termine ? c.fermer : c.annuler,
        niveau: NiveauAction.tertiaire,
        onPress: _phase == _Phase.envoi ? null : _fermer,
      ),
    ];
    final _Bouton? plein = _boutonPlein(horsLigne);
    if (_phase == _Phase.soumis &&
        _suivis.any((SuiviPayout s) => !etatsTermines.contains(s.etat))) {
      boutons.add(
        ActionPrincipale(
          key: PayoutConfirmationSheet.cleActualiser,
          libelle: c.actualiser,
          niveau: NiveauAction.secondaire,
          enCours: _actualisation,
          onPress: _actualiser,
        ),
      );
    }
    if (plein != null) {
      boutons.add(
        ActionPrincipale(
          key: plein.cle,
          libelle: plein.libelle,
          enCours: plein.enCours,
          onPress: plein.action,
        ),
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.end,
      children: boutons,
    );
  }

  /// L'unique bouton plein de la phase, ou `null` : relancer le controle,
  /// confirmer les prets, demander la validation, ou reessayer la meme
  /// demande. Hors ligne, aucun bouton d'envoi.
  _Bouton? _boutonPlein(bool horsLigne) {
    final c = t.comptable.paiements.confirmation;
    final PreflightLot? lot = _lot;
    switch (_phase) {
      case _Phase.controleEchoue:
      case _Phase.refuse:
        if (_refus?.motif == MotifRefusPayout.dejaSoumis) return null;
        return _Bouton(
          PayoutConfirmationSheet.cleRelancer,
          c.relancerControle,
          _controler,
        );
      case _Phase.pret:
      case _Phase.envoi:
      case _Phase.validationEchouee:
        if (lot == null || lot.prets.isEmpty || horsLigne) return null;
        final bool envoi = _phase == _Phase.envoi;
        return lot.sensible
            ? _Bouton(
                PayoutConfirmationSheet.cleDemander,
                c.demanderValidation,
                _demanderValidation,
                enCours: envoi,
              )
            : _Bouton(
                PayoutConfirmationSheet.cleConfirmer,
                libelleConfirmer(lot),
                _soumettre,
                enCours: envoi,
              );
      case _Phase.issueInconnue:
        if (horsLigne) return null;
        return _Bouton(
          PayoutConfirmationSheet.cleReessayer,
          c.reessayer,
          _soumettre,
        );
      case _Phase.controle:
      case _Phase.soumis:
      case _Phase.validationDemandee:
        return null;
    }
  }

  List<Widget> _resume(PreflightLot lot) {
    final c = t.comptable.paiements.confirmation;
    final bool seul = widget.selection.length == 1;
    final ObligationPayable? unique = lot.prets.length == 1
        ? _obligations[lot.prets.single.obligationId]
        : null;
    return <Widget>[
      if (seul && unique != null)
        _DetailUnique(obligation: unique, lot: lot)
      else
        _ResumeLot(lot: lot),
      if (lot.exclus.isNotEmpty) ...<Widget>[
        Ecart.vLg,
        _Exclus(exclus: lot.exclus),
      ],
      if (lot.prets.isEmpty) ...<Widget>[
        Ecart.vLg,
        _Bandeau(
          titre: c.aucunPretTitre,
          message: c.aucunPret,
          ton: TonEtat.neutre,
        ),
      ],
      if (lot.erreurs.isNotEmpty) ...<Widget>[
        Ecart.vLg,
        _Bandeau(
          titre: c.erreursTitre,
          message: lot.erreurs.join('\n'),
          ton: TonEtat.alerte,
        ),
      ],
      Ecart.vLg,
      if (lot.sensible)
        _Bandeau(
          titre: libelleRaisonBlocage(RaisonBlocage.validationRequise),
          message: c.sensiblePhrase,
        )
      else if (lot.prets.isNotEmpty)
        _Bandeau(
          titre: c.controlesTitre,
          message: c.controlesPhrase,
          ton: TonEtat.neutre,
        ),
    ];
  }

  List<Widget> _refuse() {
    final c = t.comptable.paiements.confirmation;
    final RefusPayout? refus = _refus;
    final String message = switch (refus?.motif) {
      MotifRefusPayout.versionChangee => c.recalculePhrase,
      MotifRefusPayout.dejaSoumis => c.refusDejaSoumis,
      MotifRefusPayout.horsDelegation => c.refusHorsDelegation,
      MotifRefusPayout.fournisseurIndisponible => c.refusFournisseur,
      MotifRefusPayout.preflightPerime || null => c.refusPerime,
    };
    return <Widget>[
      _Bandeau(
        titre: _recalcul ? c.recalculeTitre : c.refusTitre,
        message: message,
        ton: TonEtat.alerte,
      ),
      if (_recalcul && refus != null)
        for (final String id in refus.obligationIds)
          if (_obligations[id] case final ObligationPayable o) ...<Widget>[
            Ecart.vLg,
            _NouveauMontant(obligation: o),
          ],
    ];
  }

  List<Widget> _soumis() {
    final c = t.comptable.paiements.confirmation;
    return <Widget>[
      _Bandeau(
        titre: c.soumisTitre,
        message: c.soumisPhrase,
        ton: TonEtat.neutre,
      ),
      Ecart.vLg,
      for (final SuiviPayout s in _suivis) ...<Widget>[
        _LigneSuivi(
          suivi: s,
          nom: _obligations[s.obligationId]?.beneficiaire.nom ?? s.obligationId,
        ),
        Ecart.vSm,
      ],
      if (_suiviEchoue) ...<Widget>[
        Ecart.vSm,
        _Bandeau(
          titre: c.actualiser,
          message: c.suiviEchoue,
          ton: TonEtat.avertissement,
        ),
      ],
    ];
  }
}

/// Le libelle du bouton de confirmation : il dit toujours le montant exact
/// rendu par la source (DR-05), jamais un montant masque.
String libelleConfirmer(PreflightLot lot) {
  final c = t.comptable.paiements.confirmation;
  final String montants = lot.totauxParDevise.map(formaterMontant).join(' + ');
  if (lot.prets.length == 1) return c.confirmerUn(montant: montants);
  return c.confirmerLot(n: lot.prets.length, montants: montants);
}

/// La confirmation d'un paiement seul (§7.5, §40).
class _DetailUnique extends StatelessWidget {
  const _DetailUnique({required this.obligation, required this.lot});

  final ObligationPayable obligation;
  final PreflightLot lot;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.paiements.confirmation;
    final ObligationPayable o = obligation;
    final FraisEtChange? f = lot.fraisEtChange;
    final Montant montant = lot.totauxParDevise.length == 1
        ? lot.totauxParDevise.single
        : o.montant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Titre(c.montant),
        Ecart.vXs,
        MontantArgent(montant, taille: TailleMontant.grand),
        Ecart.vLg,
        LigneCleValeur(cle: c.beneficiaire, valeur: o.beneficiaire.nom),
        LigneCleValeur(cle: c.devise, valeur: montant.devise),
        LigneDestinationMasquee(destination: o.destination),
        LigneCleValeur(
          cle: c.type,
          valeur: libelleTypeBeneficiaire(o.beneficiaire.type),
        ),
        LigneCleValeur(cle: c.periode, valeur: o.periode),
        LigneCleValeur(
          cle: c.prestataire,
          valeur: o.prestatairePrevu ?? c.prestataireAucun,
        ),
        if (f != null) ..._frais(f),
      ],
    );
  }

  List<Widget> _frais(FraisEtChange f) {
    final c = t.comptable.paiements.confirmation;
    final String? taux = f.tauxRendu;
    final DateTime? date = f.dateTaux;
    return <Widget>[
      if (taux != null)
        LigneCleValeur(
          cle: c.taux,
          valeur: date == null
              ? taux
              : c.tauxDate(taux: taux, date: dateComptable(date)),
          chiffres: true,
        ),
      if (f.fraisPrestataire case final Montant m)
        LigneCleValeur(
          cle: c.frais,
          valeur: formaterMontant(m),
          chiffres: true,
        ),
      if (f.coutChange case final Montant m)
        LigneCleValeur(
          cle: c.change,
          valeur: formaterMontant(m),
          chiffres: true,
        ),
      if (f.montantEnvoye case final Montant m)
        LigneCleValeur(
          cle: c.montantEnvoye,
          valeur: formaterMontant(m),
          chiffres: true,
          valeurForte: true,
        ),
      if (f.montantRecuAttendu case final Montant m)
        LigneCleValeur(
          cle: c.montantRecu,
          valeur: formaterMontant(m),
          chiffres: true,
        ),
    ];
  }
}

/// Le resume du preflight d'un lot (§41) : « 18 prets / 3 exclus ».
class _ResumeLot extends StatelessWidget {
  const _ResumeLot({required this.lot});

  final PreflightLot lot;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.paiements.confirmation;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            '${c.prets(n: lot.prets.length)} / ${c.exclus(n: lot.exclus.length)}',
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vLg,
        _Titre(c.total),
        Ecart.vXs,
        for (final Montant m in lot.totauxParDevise)
          MontantArgent(m, taille: TailleMontant.grand),
        Ecart.vLg,
        LigneCleValeur(
          cle: c.beneficiairesCle,
          valeur: c.beneficiaires(n: lot.nombreBeneficiaires),
        ),
        LigneCleValeur(
          cle: c.devises,
          valeur: <String>{
            for (final Montant m in lot.totauxParDevise) m.devise,
          }.join(', '),
        ),
        LigneCleValeur(
          cle: c.prestataires,
          valeur: lot.prestataires.isEmpty
              ? c.prestataireAucun
              : lot.prestataires
                    .map((PrestataireFinance p) => p.nom)
                    .join(', '),
        ),
        for (final Montant m in lot.plafondsRestants)
          LigneCleValeur(
            cle: c.plafond,
            valeur: formaterMontant(m),
            chiffres: true,
          ),
      ],
    );
  }
}

/// Les exclus du lot, chacun avec sa raison rendue (R-FIN-22).
class _Exclus extends StatelessWidget {
  const _Exclus({required this.exclus});

  final List<ExclusionLot> exclus;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.paiements.confirmation;
    return Column(
      key: const ValueKey<String>('payout-exclus'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Titre(c.exclusTitre),
        Ecart.vXs,
        for (final ExclusionLot e in exclus)
          LigneCleValeur(
            cle: e.beneficiaire.nom,
            valeur: libelleRaisonBlocage(e.raison),
          ),
      ],
    );
  }
}

/// Le nouveau montant d'une obligation recalculee (R-FIN-18), exact.
class _NouveauMontant extends StatelessWidget {
  const _NouveauMontant({required this.obligation});

  final ObligationPayable obligation;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.paiements.confirmation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Titre(c.nouveauMontant(nom: obligation.beneficiaire.nom)),
        Ecart.vXs,
        MontantArgent(obligation.montant, taille: TailleMontant.grand),
      ],
    );
  }
}

/// Une ligne de suivi : l'etat est celui que rend le prestataire.
class _LigneSuivi extends StatelessWidget {
  const _LigneSuivi({required this.suivi, required this.nom});

  final SuiviPayout suivi;
  final String nom;

  @override
  Widget build(BuildContext context) {
    final String? reference = suivi.reference;
    return Column(
      key: ValueKey<String>('payout-suivi-${suivi.obligationId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LigneCleValeur(
          cle: nom,
          valeur: formaterMontant(suivi.montant),
          chiffres: true,
          complement: PastillePaiementSortant(suivi.etat),
        ),
        if (reference != null)
          LigneCleValeur(
            cle: t.comptable.paiements.confirmation.referenceCle,
            valeur: reference,
          ),
      ],
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      texte,
      style: AppPalette.of(context).inkMuted
          .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
    ),
  );
}

/// Un bouton plein, decrit avant d'etre pose.
class _Bouton {
  const _Bouton(this.cle, this.libelle, this.action, {this.enCours = false});

  final Key cle;
  final String libelle;
  final VoidCallback action;
  final bool enCours;
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({
    required this.titre,
    required this.message,
    this.ton = TonEtat.avertissement,
  });

  final String titre;
  final String message;
  final TonEtat ton;

  @override
  Widget build(BuildContext context) =>
      BandeauAttention(titre: titre, message: message, ton: ton);
}
