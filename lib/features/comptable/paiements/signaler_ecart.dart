// « Signaler un ecart » (spec §13.4, R-FIN-17 ; CPT-PAY-1) : le Comptable
// dit quelle ligne et ce qui ne va pas, **sans aucun champ de montant ni de
// saisie libre** ; la correction se fait a la source, puis le moteur
// recalcule (R-FIN-18).
//
// Formulaire semi-automatique (K-57) : la ligne et le motif sont choisis
// dans des listes fermees, preremplies avec la premiere ligne et le motif le
// plus courant, tous deux modifiables. La cle d'idempotence est tiree une
// fois par feuille : un double appui ou une reponse perdue puis rejouee ne
// creent qu'un signalement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/capacites/port_obligations_payables.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/status_pill.dart';

/// Les motifs proposes, dans l'ordre (le premier est preselectionne).
enum MotifEcart {
  /// Le montant d'une ligne ne correspond pas.
  montantLigne,

  /// Une ligne manque.
  ligneManquante,

  /// Une ligne est en trop.
  ligneEnTrop,

  /// La source citee n'est pas la bonne.
  sourceErronee;

  /// Le libelle lisible, qui part aussi a la source comme motif.
  String get libelle {
    final m = t.comptable.paiements.ecart.motifs;
    return switch (this) {
      MotifEcart.montantLigne => m.montantLigne,
      MotifEcart.ligneManquante => m.ligneManquante,
      MotifEcart.ligneEnTrop => m.ligneEnTrop,
      MotifEcart.sourceErronee => m.sourceErronee,
    };
  }
}

/// Ouvre la feuille et rend le signalement depose, ou `null` si la feuille
/// est fermee sans envoi.
Future<SignalementEcart?> ouvrirSignalerEcart(
  BuildContext context,
  ObligationPayable obligation,
) => AppBottomSheet.ouvrir<SignalementEcart>(
  context,
  titre: t.comptable.paiements.ecart.titre,
  constructeur: (BuildContext _) =>
      FeuilleSignalerEcart(obligation: obligation),
);

/// Le contenu de la feuille « Signaler un ecart ».
class FeuilleSignalerEcart extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleSignalerEcart({required this.obligation, super.key});

  /// L'obligation visee.
  final ObligationPayable obligation;

  /// La cle du bouton d'envoi.
  static const Key cleEnvoyer = ValueKey<String>('ecart-envoyer');

  @override
  ConsumerState<FeuilleSignalerEcart> createState() =>
      _FeuilleSignalerEcartState();
}

class _FeuilleSignalerEcartState extends ConsumerState<FeuilleSignalerEcart> {
  /// Tiree une fois par feuille, rejouee telle quelle a chaque nouvel essai.
  final String _cle = const Uuid().v4();

  late String? _ligneId = widget.obligation.lignes.isEmpty
      ? null
      : widget.obligation.lignes.first.id;
  MotifEcart _motif = MotifEcart.montantLigne;
  bool _envoi = false;
  bool _echec = false;

  Future<void> _envoyer() async {
    final String? ligneId = _ligneId;
    if (ligneId == null || _envoi) return;
    setState(() {
      _envoi = true;
      _echec = false;
    });
    try {
      final SignalementEcart depose = await ref
          .read(portObligationsPayablesProvider)
          .signalerEcart(
            obligationId: widget.obligation.id,
            ligneId: ligneId,
            motif: _motif.libelle,
            cleIdempotence: _cle,
          );
      if (mounted) Navigator.of(context).pop(depose);
    } on Object {
      if (mounted) {
        setState(() {
          _envoi = false;
          _echec = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final e = t.comptable.paiements.ecart;
    final TextStyle titre = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          e.phrase,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,
        Semantics(header: true, child: Text(e.ligne, style: titre)),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: _ligneId == null
              ? null
              : ReponseChoix(valeurs: <String>{_ligneId!}),
          options: <OptionChoix>[
            for (final LigneCalcul l in widget.obligation.lignes)
              OptionChoix(
                cle: ValueKey<String>('ecart-ligne-${l.id}'),
                valeur: l.id,
                libelle: l.libelle,
                description: t.comptable.paiements.detail.source(
                  source: l.source,
                ),
              ),
          ],
          onChange: (ReponseChoix r) => setState(
            () => _ligneId = r.valeurs.isEmpty ? null : r.valeurs.first,
          ),
        ),
        Ecart.vLg,
        Semantics(header: true, child: Text(e.motif, style: titre)),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{_motif.name}),
          options: <OptionChoix>[
            for (final MotifEcart m in MotifEcart.values)
              OptionChoix(
                cle: ValueKey<String>('ecart-motif-${m.name}'),
                valeur: m.name,
                libelle: m.libelle,
              ),
          ],
          onChange: (ReponseChoix r) {
            if (r.valeurs.isEmpty) return;
            setState(() => _motif = MotifEcart.values.byName(r.valeurs.first));
          },
        ),
        if (_echec) ...<Widget>[
          Ecart.vLg,
          BandeauAttention(
            titre: e.titre,
            message: e.erreurEnvoi,
            ton: TonEtat.alerte,
          ),
        ],
        Ecart.vXl,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          children: <Widget>[
            ActionPrincipale(
              libelle: e.annuler,
              niveau: NiveauAction.tertiaire,
              onPress: () => Navigator.of(context).pop(),
            ),
            if (_ligneId != null)
              ActionPrincipale(
                key: FeuilleSignalerEcart.cleEnvoyer,
                libelle: e.envoyer,
                enCours: _envoi,
                onPress: _envoyer,
              ),
          ],
        ),
      ],
    );
  }
}
