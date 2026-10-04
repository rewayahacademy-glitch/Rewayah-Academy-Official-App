// Les remboursements et avoirs vus par le Comptable (spec §26, §48 ;
// CPT-BR-15, 17) : demande, beneficiaire, motif, montant, source, etat,
// approbation requise ou non, et le journal de chacun.
//
// Les regles commerciales appartiennent a la politique Finance : aucun champ
// ne les modifie ici. « Executer le remboursement » ne se montre que si la
// source permet `rembourser` ; sinon la raison rendue (DR-19). L'etat
// affiche apres l'execution est celui que la source rend (§5.3) ; la cle
// d'idempotence est gardee jusqu'a la reponse.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/capacites/port_encaissements.dart';
import '../../../../core/comptable/statuts_comptable.dart';
import '../../../../core/i18n/strings.g.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/action_principale.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/bandeau_attention.dart';
import '../../../../core/widgets/comptable/ligne_activite.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/ligne_cle_valeur.dart';
import '../../../../core/widgets/pastilles_comptable.dart';
import '../../../../core/widgets/status_pill.dart';
import '../commun_encaissements.dart';
import '../contenu_encaissement.dart';
import '../donnees_encaissements.dart';
import 'donnees_rapprochement.dart';
import 'feuille_remboursement.dart';

/// La liste des remboursements et avoirs.
class RemboursementsAvoirs extends ConsumerWidget {
  /// Cree la liste.
  const RemboursementsAvoirs({required this.remboursements, super.key});

  /// Les remboursements rendus par la source.
  final List<Remboursement> remboursements;

  /// La cle de la carte d'un remboursement.
  static Key carteKey(String id) => ValueKey<String>('remb-$id');

  /// La cle du bouton « Executer le remboursement ».
  static Key executerKey(String id) => ValueKey<String>('remb-executer-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.comptable.encaissements.rap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        NoteAttenuee(r.politiqueNote),
        Ecart.vLg,
        if (remboursements.isEmpty)
          EmptyState(
            message: r.remboursementsVideTitre,
            invitation: r.remboursementsVidePhrase,
          )
        else
          for (int i = 0; i < remboursements.length; i++) ...<Widget>[
            if (i > 0) Ecart.vLg,
            _CarteRemboursement(
              key: carteKey(remboursements[i].id),
              remboursement: remboursements[i],
            ),
          ],
      ],
    );
  }
}

class _CarteRemboursement extends ConsumerStatefulWidget {
  const _CarteRemboursement({required this.remboursement, super.key});

  final Remboursement remboursement;

  @override
  ConsumerState<_CarteRemboursement> createState() =>
      _CarteRemboursementState();
}

class _CarteRemboursementState extends ConsumerState<_CarteRemboursement> {
  String? _cle;
  String? _resultat;
  bool _echec = false;
  bool _envoi = false;

  Future<void> _executer() async {
    if (_envoi) return;
    final Remboursement rb = widget.remboursement;
    final bool ok = await confirmerRemboursement(context, rb);
    if (!ok || !mounted) return;
    final String cle = _cle ??= const Uuid().v4();
    setState(() {
      _envoi = true;
      _echec = false;
      _resultat = null;
    });
    try {
      final Remboursement reponse = await ref
          .read(portEncaissementsProvider)
          .executerRemboursement(remboursementId: rb.id, cleIdempotence: cle);
      _cle = null;
      if (!mounted) return;
      setState(() {
        _resultat = t.comptable.encaissements.rap.resultat(
          etat: libelleRemboursement(reponse.etat),
        );
      });
      ref
        ..invalidate(remboursementsProvider)
        ..invalidate(journalEncaissementProvider(rb.id));
    } on Object {
      if (mounted) setState(() => _echec = true);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _actualiser() {
    setState(() => _echec = false);
    ref
      ..invalidate(remboursementsProvider)
      ..invalidate(journalEncaissementProvider(widget.remboursement.id));
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.comptable.encaissements.rap;
    final Remboursement rb = widget.remboursement;
    final bool peut = rb.permissions.permet(ActionFinance.rembourser);
    final RaisonBlocage? raison = rb.permissions.raisonDe(
      ActionFinance.rembourser,
    );
    final String? resultat = _resultat;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              rb.beneficiaire,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXs,
          NoteAttenuee(r.demandeLe(date: dateComptable(rb.date))),
          Ecart.vSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[PastilleRemboursement(rb.etat)],
          ),
          Ecart.vSm,
          NoteAttenuee(
            rb.approbationRequise ? r.approbationRequise : r.approbationNon,
          ),
          Ecart.vMd,
          LigneCleValeur(cle: r.motif, valeur: rb.motif),
          LigneCleValeur(cle: r.source, valeur: rb.source),
          LigneMontant(libelle: r.montant, montant: rb.montant, fort: true),
          if (resultat != null) ...<Widget>[
            Ecart.vSm,
            Semantics(
              liveRegion: true,
              child: Text(
                resultat,
                style: palette.inkStrong.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
          if (_echec) ...<Widget>[
            Ecart.vMd,
            BandeauAttention(
              titre: r.erreurEnvoiTitre,
              message: r.erreurEnvoi,
              ton: TonEtat.avertissement,
              action: ActionPrincipale(
                libelle: r.actualiser,
                niveau: NiveauAction.tertiaire,
                onPress: _actualiser,
              ),
            ),
          ],
          if (peut) ...<Widget>[
            Ecart.vMd,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                label: r.executerLecteur(beneficiaire: rb.beneficiaire),
                excludeSemantics: true,
                button: true,
                child: ActionPrincipale(
                  key: RemboursementsAvoirs.executerKey(rb.id),
                  libelle: r.executer,
                  niveau: NiveauAction.secondaire,
                  enCours: _envoi,
                  onPress: _executer,
                ),
              ),
            ),
          ] else if (raison != null) ...<Widget>[
            Ecart.vMd,
            NoteAttenuee(libelleRaisonBlocage(raison)),
          ],
          Ecart.vLg,
          TitreZone(r.journalRemboursement),
          JournalOperationSansCarte(
            objetId: rb.id,
            vide: r.journalRemboursementVide,
          ),
        ],
      ),
    );
  }
}

/// Le journal d'un remboursement, pose dans sa carte (pas de carte dans la
/// carte).
class JournalOperationSansCarte extends ConsumerWidget {
  /// Cree le journal.
  const JournalOperationSansCarte({
    required this.objetId,
    required this.vide,
    super.key,
  });

  /// L'objet.
  final String objetId;

  /// La phrase quand le journal est vide.
  final String vide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocEncaissements<List<EntreeJournal>>(
      valeur: ref.watch(journalEncaissementProvider(objetId)),
      onReessayer: () => ref.invalidate(journalEncaissementProvider(objetId)),
      vide: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: NoteAttenuee(vide),
      ),
      construire: (List<EntreeJournal> entrees) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final EntreeJournal j in entrees) LigneActivite(j),
        ],
      ),
    );
  }
}
