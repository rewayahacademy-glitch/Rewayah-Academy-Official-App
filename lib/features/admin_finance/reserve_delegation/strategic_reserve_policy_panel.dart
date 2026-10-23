// `StrategicReservePolicyPanel` (spec §37, §9.2 a §9.6 ; CPT-DIR-1) : la
// politique de la Reserve strategique, reglee par la Direction. Le titre
// reste « Reserve strategique » (§9.1) ; le Comptable lit la politique et
// l'execute (§9.6).
//
// Objectif : montant fixe ou couverture en mois. Alimentation : desactivee,
// montant fixe, pourcentage, jusqu'a l'objectif, proposee. Cadence (§9.4).
// Seuil d'alerte. Retrait soumis a validation. **Aucune borne commerciale
// codee** : 10 USD et 1 000 000 USD s'enregistrent pareil (R-FIN-08, 09) ;
// seule la validation serveur decidera des limites reelles.
//
// Le panneau ne lit rien : il recoit la politique et rend le brouillon a
// [StrategicReservePolicyPanel.onEnregistrer]. Il ne calcule rien.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/port_politique_reserve.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/comptable/carte_reserve_strategique.dart';
import '../../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import '../../../core/widgets/controle_segmente.dart';
import '../../../core/widgets/setting_row.dart';
import '../../../core/widgets/status_pill.dart';
import 'composants_politique.dart';
import 'politiques_direction.dart';
import 'saisie_politique.dart';

/// La lecture et l'enregistrement du panneau : la politique, son etat actuel,
/// son historique. L'enregistrement relit la politique et l'historique.
class StrategicReservePolicyPanelBloc extends ConsumerWidget {
  /// Cree le bloc.
  const StrategicReservePolicyPanelBloc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocPolitique<PolitiqueReserve>(
      fournisseur: politiqueReserveProvider,
      construire: (PolitiqueReserve politique) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _EtatActuel(),
          StrategicReservePolicyPanel(
            politique: politique,
            onEnregistrer:
                (BrouillonPolitiqueReserve brouillon, String cle) async {
                  await ref
                      .read(portPolitiqueReserveProvider)
                      .enregistrer(brouillon: brouillon, cleIdempotence: cle);
                  ref
                    ..invalidate(politiqueReserveProvider)
                    ..invalidate(indicateursReserveDirectionProvider)
                    ..invalidate(journalReserveProvider);
                },
          ),
          Ecart.vXxl,
          HistoriqueVersions(fournisseur: journalReserveProvider),
        ],
      ),
    );
  }
}

/// L'etat actuel de la Reserve (§9.7), en lecture : il ne s'affiche pas si
/// la source ne le rend pas.
class _EtatActuel extends ConsumerWidget {
  const _EtatActuel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final IndicateursReserve? indicateurs = ref
        .watch(indicateursReserveDirectionProvider)
        .value;
    if (indicateurs == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: GroupePolitique(
        titre: t.comptable.direction.etatActuel,
        enCarte: false,
        enfants: <Widget>[CarteReserveStrategique(indicateurs)],
      ),
    );
  }
}

/// Le panneau de politique de la Reserve strategique.
class StrategicReservePolicyPanel extends StatefulWidget {
  /// Cree le panneau pour [politique].
  const StrategicReservePolicyPanel({
    required this.politique,
    required this.onEnregistrer,
    super.key,
  });

  /// La politique en vigueur.
  final PolitiqueReserve politique;

  /// Enregistre [BrouillonPolitiqueReserve] sous la cle d'idempotence donnee.
  /// Echoue avec l'erreur de la source.
  final Future<void> Function(BrouillonPolitiqueReserve brouillon, String cle)
  onEnregistrer;

  /// La cle du bouton d'enregistrement (tests).
  static const Key enregistrerKey = ValueKey<String>(
    'cpt-dir-reserve-enregistrer',
  );

  @override
  State<StrategicReservePolicyPanel> createState() =>
      _StrategicReservePolicyPanelState();
}

class _StrategicReservePolicyPanelState
    extends State<StrategicReservePolicyPanel> {
  late ModeObjectifReserve _mode;
  late RegleAlimentation _regle;
  late CadenceAlimentation _cadence;
  late bool _retrait;
  final TextEditingController _cible = TextEditingController();
  final TextEditingController _mois = TextEditingController();
  final TextEditingController _auto = TextEditingController();
  final TextEditingController _pourcentage = TextEditingController();
  final TextEditingController _seuil = TextEditingController();

  bool _tente = false;
  bool _enCours = false;
  String? _message;
  bool _messageEstErreur = false;
  String? _cle;

  String get _devise =>
      widget.politique.montantCible?.devise ??
      widget.politique.montantAuto?.devise ??
      deviseDeLancement;

  @override
  void initState() {
    super.initState();
    _charger(widget.politique);
  }

  @override
  void didUpdateWidget(StrategicReservePolicyPanel ancien) {
    super.didUpdateWidget(ancien);
    if (widget.politique.version != ancien.politique.version) {
      _charger(widget.politique);
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _cible,
      _mois,
      _auto,
      _pourcentage,
      _seuil,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _charger(PolitiqueReserve p) {
    _mode = p.modeObjectif;
    _regle = p.regleAlimentation;
    _cadence = p.cadence;
    _retrait = p.retraitSoumisValidation;
    _cible.text = texteMontant(p.montantCible);
    _mois.text = texteEntier(p.nombreMois);
    _auto.text = texteMontant(p.montantAuto);
    _pourcentage.text = textePourMille(p.pourcentageAutoPourMille);
    _seuil.text = textePourMille(p.seuilAlertePourMille);
    _tente = false;
    _cle = null;
  }

  /// Vrai quand le brouillon differe de la version en vigueur (seuls les
  /// champs que le mode et la regle rendent utiles comptent).
  bool get _modifie {
    final PolitiqueReserve p = widget.politique;
    if (_mode != p.modeObjectif ||
        _regle != p.regleAlimentation ||
        _retrait != p.retraitSoumisValidation ||
        _seuil.text != textePourMille(p.seuilAlertePourMille)) {
      return true;
    }
    if (_mode == ModeObjectifReserve.montantFixe &&
        _cible.text != texteMontant(p.montantCible)) {
      return true;
    }
    if (_mode == ModeObjectifReserve.couvertureMois &&
        _mois.text != texteEntier(p.nombreMois)) {
      return true;
    }
    if (_regle != RegleAlimentation.desactivee && _cadence != p.cadence) {
      return true;
    }
    if (_regle == RegleAlimentation.montantFixe &&
        _auto.text != texteMontant(p.montantAuto)) {
      return true;
    }
    return _regle == RegleAlimentation.pourcentage &&
        _pourcentage.text != textePourMille(p.pourcentageAutoPourMille);
  }

  bool get _seuilVide => _seuil.text.trim().isEmpty;

  String? _erreurMontant(TextEditingController c) =>
      _tente && lireMontant(c.text, _devise) == null
      ? t.comptable.direction.erreurMontant
      : null;

  /// Le brouillon, ou `null` quand un champ utile est illisible.
  BrouillonPolitiqueReserve? _brouillon() {
    final bool fixe = _mode == ModeObjectifReserve.montantFixe;
    final Montant? cible = fixe ? lireMontant(_cible.text, _devise) : null;
    final int? mois = fixe ? null : lireEntier(_mois.text);
    final Montant? montantAuto = _regle == RegleAlimentation.montantFixe
        ? lireMontant(_auto.text, _devise)
        : null;
    final int? pct = _regle == RegleAlimentation.pourcentage
        ? lirePourMille(_pourcentage.text)
        : null;
    final int? seuil = _seuilVide ? null : lirePourMille(_seuil.text);
    if ((fixe && cible == null) ||
        (!fixe && mois == null) ||
        (_regle == RegleAlimentation.montantFixe && montantAuto == null) ||
        (_regle == RegleAlimentation.pourcentage && pct == null) ||
        (!_seuilVide && seuil == null)) {
      return null;
    }
    return BrouillonPolitiqueReserve(
      modeObjectif: _mode,
      montantCible: cible,
      nombreMois: mois,
      regleAlimentation: _regle,
      montantAuto: montantAuto,
      pourcentageAutoPourMille: pct,
      cadence: _cadence,
      seuilAlertePourMille: seuil,
      retraitSoumisValidation: _retrait,
    );
  }

  void _edite(VoidCallback changement) => setState(() {
    changement();
    _cle = null;
    _message = null;
  });

  Future<void> _enregistrer() async {
    final BrouillonPolitiqueReserve? brouillon = _brouillon();
    if (brouillon == null) {
      setState(() {
        _tente = true;
        _message = t.comptable.direction.corrigezChamps;
        _messageEstErreur = true;
      });
      return;
    }
    final String cle = _cle ??= nouvelleCleIdempotence('reserve');
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

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.direction;
    final r = c.reservePanneau;
    final PolitiqueReserve p = widget.politique;
    final bool fixe = _mode == ModeObjectifReserve.montantFixe;
    final String symbole = symboleDe(_devise);
    final DateTime? dateEffet = p.dateEffet;
    final String? auteur = p.auteur;
    final bool automatique = _regle != RegleAlimentation.desactivee;
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
        Text(r.intro),
        Ecart.vXxl,
        GroupePolitique(
          titre: r.objectifTitre,
          detail: r.objectifDetail,
          enfants: <Widget>[
            ControleSegmente<ModeObjectifReserve>(
              segments: <Segment<ModeObjectifReserve>>[
                Segment<ModeObjectifReserve>(
                  valeur: ModeObjectifReserve.montantFixe,
                  libelle: r.modeFixe,
                ),
                Segment<ModeObjectifReserve>(
                  valeur: ModeObjectifReserve.couvertureMois,
                  libelle: r.modeMois,
                ),
              ],
              valeur: _mode,
              onChange: (ModeObjectifReserve m) => _edite(() => _mode = m),
            ),
            if (fixe)
              ChampPolitique(
                libelle: r.montantCible,
                consequence: r.montantCibleDetail,
                suffixe: symbole,
                controleur: _cible,
                erreur: _erreurMontant(_cible),
                actif: !_enCours,
                onChange: () => _edite(() {}),
              )
            else
              ChampPolitique(
                libelle: r.nombreMois,
                consequence: r.nombreMoisDetail,
                suffixe: c.suffixeMois,
                controleur: _mois,
                erreur: _tente && lireEntier(_mois.text) == null
                    ? c.erreurNombre
                    : null,
                actif: !_enCours,
                onChange: () => _edite(() {}),
              ),
          ],
        ),
        Ecart.vXxl,
        GroupePolitique(
          titre: r.alimentationTitre,
          detail: r.alimentationDetail,
          enCarte: false,
          enfants: <Widget>[
            ChoiceCardGroup(
              key: ValueKey<String>('regle-${p.version}'),
              autoriserSaisieLibre: false,
              valeurInitiale: ReponseChoix(valeurs: <String>{_regle.name}),
              options: <OptionChoix>[
                OptionChoix(
                  valeur: RegleAlimentation.desactivee.name,
                  libelle: r.regle.desactivee,
                  description: r.regle.desactiveeDetail,
                ),
                OptionChoix(
                  valeur: RegleAlimentation.montantFixe.name,
                  libelle: r.regle.montantFixe,
                  description: r.regle.montantFixeDetail,
                ),
                OptionChoix(
                  valeur: RegleAlimentation.pourcentage.name,
                  libelle: r.regle.pourcentage,
                  description: r.regle.pourcentageDetail,
                ),
                OptionChoix(
                  valeur: RegleAlimentation.jusquAObjectif.name,
                  libelle: r.regle.jusquAObjectif,
                  description: r.regle.jusquAObjectifDetail,
                ),
                OptionChoix(
                  valeur: RegleAlimentation.proposee.name,
                  libelle: r.regle.proposee,
                  description: r.regle.proposeeDetail,
                ),
              ],
              onChange: (ReponseChoix rep) => _edite(
                () => _regle = RegleAlimentation.values.byName(
                  rep.valeurs.single,
                ),
              ),
            ),
            if (_regle == RegleAlimentation.montantFixe)
              ChampPolitique(
                libelle: r.montantAuto,
                consequence: r.montantAutoDetail,
                suffixe: symbole,
                controleur: _auto,
                erreur: _erreurMontant(_auto),
                actif: !_enCours,
                onChange: () => _edite(() {}),
              ),
            if (_regle == RegleAlimentation.pourcentage)
              ChampPolitique(
                libelle: r.pourcentageAuto,
                consequence: r.pourcentageAutoDetail,
                suffixe: c.suffixePourcent,
                controleur: _pourcentage,
                erreur: _tente && lirePourMille(_pourcentage.text) == null
                    ? c.erreurPourcentage
                    : null,
                actif: !_enCours,
                onChange: () => _edite(() {}),
              ),
          ],
        ),
        if (automatique) ...<Widget>[
          Ecart.vXxl,
          GroupePolitique(
            titre: r.cadenceTitre,
            detail: r.cadenceDetail,
            enCarte: false,
            enfants: <Widget>[
              ChoiceCardGroup(
                key: ValueKey<String>('cadence-${p.version}'),
                autoriserSaisieLibre: false,
                valeurInitiale: ReponseChoix(valeurs: <String>{_cadence.name}),
                options: <OptionChoix>[
                  OptionChoix(
                    valeur: CadenceAlimentation.clotureCycle.name,
                    libelle: r.cadence.clotureCycle,
                  ),
                  OptionChoix(
                    valeur: CadenceAlimentation.hebdomadaire.name,
                    libelle: r.cadence.hebdomadaire,
                  ),
                  OptionChoix(
                    valeur: CadenceAlimentation.mensuelle.name,
                    libelle: r.cadence.mensuelle,
                  ),
                  OptionChoix(
                    valeur: CadenceAlimentation.apresEncaissementConsolide.name,
                    libelle: r.cadence.apresEncaissementConsolide,
                  ),
                  OptionChoix(
                    valeur: CadenceAlimentation.manuelle.name,
                    libelle: r.cadence.manuelle,
                  ),
                ],
                onChange: (ReponseChoix rep) => _edite(
                  () => _cadence = CadenceAlimentation.values.byName(
                    rep.valeurs.single,
                  ),
                ),
              ),
            ],
          ),
        ],
        Ecart.vXxl,
        GroupePolitique(
          titre: r.seuilTitre,
          enfants: <Widget>[
            ChampPolitique(
              libelle: r.seuil,
              consequence: r.seuilDetail,
              suffixe: c.suffixePourcent,
              indice: r.seuilIndice,
              controleur: _seuil,
              erreur:
                  _tente && !_seuilVide && lirePourMille(_seuil.text) == null
                  ? c.erreurPourcentage
                  : null,
              actif: !_enCours,
              onChange: () => _edite(() {}),
            ),
          ],
        ),
        Ecart.vXxl,
        GroupePolitique(
          titre: r.retraitTitre,
          enfants: <Widget>[
            SettingRow(
              title: r.retraitSwitch,
              description: r.retraitSwitchDetail,
              icon: AppIcons.verrou,
              controle: Switch.adaptive(
                value: _retrait,
                onChanged: _enCours
                    ? null
                    : (bool v) => _edite(() => _retrait = v),
              ),
            ),
          ],
        ),
        Ecart.vXxl,
        PiedEnregistrement(
          key: StrategicReservePolicyPanel.enregistrerKey,
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
