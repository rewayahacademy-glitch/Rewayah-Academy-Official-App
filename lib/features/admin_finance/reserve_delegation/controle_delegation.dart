// DELEG-FIN-1 : le controle de la Direction sur les delegations du Comptable.
//
// - **Suspendre toutes les delegations** : effet immediat cote serveur, par
//   `ConfirmDestructive` (l'effet se dit avant le choix), une cle
//   d'idempotence par demande. Suspendues, la bande le dit ; l'ecran ne
//   decide rien : l'etat est celui que la source rend.
// - **Expiration** : chaque delegation expire (90 jours par defaut cote
//   source), renouvelable. L'etat (active, suspendue, expiree) vient de la
//   source, jamais d'une comparaison de dates faite ici.
//
// Aucun succes n'est annonce avant la reponse : « non confirme », jamais
// « non envoye » (K-59, D5).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/port_delegation_finance.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import '../../../core/widgets/confirm_destructive.dart';
import '../../../core/widgets/setting_row.dart';
import '../../../core/widgets/status_pill.dart';
import 'composants_politique.dart';
import 'politiques_direction.dart';

/// Le mot de l'etat d'une delegation.
String libelleEtatDelegation(EtatDelegation etat) {
  final d = t.comptable.direction.delegationPanneau;
  return switch (etat) {
    EtatDelegation.active => d.etatActive,
    EtatDelegation.suspendue => d.etatSuspendue,
    EtatDelegation.expiree => d.etatExpiree,
  };
}

/// Le ton d'une pastille d'etat : jamais la couleur seule, le mot la porte.
TonEtat tonEtatDelegation(EtatDelegation etat) => switch (etat) {
  EtatDelegation.active => TonEtat.succes,
  EtatDelegation.suspendue => TonEtat.alerte,
  EtatDelegation.expiree => TonEtat.avertissement,
};

/// La suspension et l'expiration d'une [politique].
class ControleDelegation extends ConsumerStatefulWidget {
  /// Cree le controle.
  const ControleDelegation({required this.politique, super.key});

  /// La politique en vigueur, etat compris.
  final PolitiqueDelegationFinance politique;

  /// La cle du bouton « Suspendre toutes les delegations ».
  static const Key cleSuspendre = ValueKey<String>('deleg-suspendre');

  /// La cle du bouton « Renouveler la delegation ».
  static const Key cleRenouveler = ValueKey<String>('deleg-renouveler');

  /// La cle de la bande « Delegations suspendues ».
  static const Key cleBandeSuspendue = ValueKey<String>('deleg-suspendue');

  /// La cle du message de retour (succes ou echec).
  static const Key cleRetour = ValueKey<String>('deleg-retour');

  @override
  ConsumerState<ControleDelegation> createState() => _ControleDelegationEtat();
}

class _ControleDelegationEtat extends ConsumerState<ControleDelegation> {
  bool _suspension = false;
  bool _renouvellement = false;
  String? _retour;
  bool _retourEchec = false;

  /// Une cle par demande : un second appui, ou un appui apres une reponse
  /// perdue, reprend la meme demande cote serveur.
  String? _cleSuspension;
  String? _cleRenouvellement;

  void _relire() => ref
    ..invalidate(politiqueDelegationProvider)
    ..invalidate(journalDelegationProvider);

  Future<void> _suspendre() async {
    if (_suspension) return;
    final d = t.comptable.direction.delegationPanneau;
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: d.suspendreConfirmerTitre,
      consequence: d.suspendreConfirmerPhrase,
      libelleConfirmer: d.suspendreConfirmer,
      libelleAnnuler: d.suspendreGarder,
    );
    if (!oui || !mounted) return;
    final String cle = _cleSuspension ??= nouvelleCleIdempotence('suspension');
    setState(() {
      _suspension = true;
      _retour = null;
    });
    try {
      await ref
          .read(portControleDelegationProvider)
          .suspendreToutes(cleIdempotence: cle);
      if (!mounted) return;
      _cleSuspension = null;
      _relire();
      setState(() {
        _suspension = false;
        _retour = d.etatSuspendue;
        _retourEchec = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _suspension = false;
        _retour = d.suspendueEchec;
        _retourEchec = true;
      });
    }
  }

  Future<void> _renouveler() async {
    if (_renouvellement) return;
    final d = t.comptable.direction.delegationPanneau;
    final String cle = _cleRenouvellement ??= nouvelleCleIdempotence(
      'renouvellement',
    );
    setState(() {
      _renouvellement = true;
      _retour = null;
    });
    try {
      await ref
          .read(portControleDelegationProvider)
          .renouveler(cleIdempotence: cle);
      if (!mounted) return;
      _cleRenouvellement = null;
      _relire();
      setState(() {
        _renouvellement = false;
        _retour = d.renouvelee;
        _retourEchec = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _renouvellement = false;
        _retour = d.renouvelerEchec;
        _retourEchec = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = t.comptable.direction.delegationPanneau;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final PolitiqueDelegationFinance p = widget.politique;
    final bool suspendue = p.etat == EtatDelegation.suspendue;
    final DateTime? expire = p.expireLe;
    final DateTime? depuis = p.suspendueLe;
    final String? retour = _retour;
    final String detailExpiration = <String>[
      if (p.dureeJours != null) d.renouvelablePour(jours: p.dureeJours!),
      if (p.delaiSortieHeures != null)
        d.sortiesDelai(heures: p.delaiSortieHeures!),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (suspendue) ...<Widget>[
          BandeauAttention(
            key: ControleDelegation.cleBandeSuspendue,
            titre: d.suspendueTitre,
            message: depuis == null
                ? d.suspendueSansDate
                : d.suspendueDepuis(date: dateComptable(depuis)),
            ton: TonEtat.alerte,
          ),
          Ecart.vXxl,
        ],
        GroupePolitique(
          titre: d.expirationTitre,
          detail: d.expirationDetail,
          enfants: <Widget>[
            SettingRow(
              title: expire == null
                  ? d.expirationInconnue
                  : d.expireLe(date: dateComptable(expire)),
              description: detailExpiration.isEmpty ? null : detailExpiration,
              icon: AppIcons.attente,
              controle: StatusPill(
                libelle: libelleEtatDelegation(p.etat),
                ton: tonEtatDelegation(p.etat),
              ),
            ),
          ],
        ),
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionPrincipale(
            key: ControleDelegation.cleRenouveler,
            libelle: d.renouveler,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            enCours: _renouvellement,
            onPress: _renouveler,
          ),
        ),
        if (!suspendue) ...<Widget>[
          Ecart.vXxl,
          GroupePolitique(
            titre: d.suspendreTitre,
            detail: d.suspendreDetail,
            enfants: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ActionPrincipale(
                    key: ControleDelegation.cleSuspendre,
                    libelle: d.suspendreAction,
                    niveau: NiveauAction.destructive,
                    pleineLargeur: false,
                    enCours: _suspension,
                    onPress: _suspendre,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (retour != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              retour,
              key: ControleDelegation.cleRetour,
              style: (_retourEchec ? palette.inkAlert : palette.inkStrong)
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ),
        ],
      ],
    );
  }
}
