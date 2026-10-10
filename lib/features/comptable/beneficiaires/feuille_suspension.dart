// La feuille « Suspendre les paiements de... » (W07, spec §16.2 ; CPT-BEN-1).
//
// Ce qui arrive est dit avant le geste (K-58) : aucun versement ne part tant
// que les paiements ne sont pas repris, les coordonnees ne changent pas. Le
// motif se **choisit** (K-57 : trois motifs courants, chacun explique, et
// « Autre » en saisie libre pour ce que l'app ne peut pas connaitre) ; il
// part au journal du profil par le port (`suspendre(motif:)`). Le bouton
// nomme l'acte et la personne, au niveau destructif (jamais un aplat plein,
// la page porte deja son bouton plein « Relancer »).

import 'package:flutter/material.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/choice_card_group.dart';

/// Ouvre la feuille et rend le motif choisi, ou `null` si la personne
/// renonce (glissement, `Echap`, voile).
Future<String?> demanderMotifSuspension(
  BuildContext context, {
  required String nom,
}) => AppBottomSheet.ouvrir<String>(
  context,
  titre: t.comptable.beneficiaires.profil.suspensionTitre(nom: nom),
  constructeur: (BuildContext contexte) => CorpsSuspension(
    nom: nom,
    onConfirmer: (String motif) => Navigator.of(contexte).pop(motif),
  ),
);

/// Le corps de la feuille, rendu seul dans les tests.
class CorpsSuspension extends StatefulWidget {
  /// Cree le corps.
  const CorpsSuspension({
    required this.nom,
    required this.onConfirmer,
    super.key,
  });

  /// Le nom du beneficiaire.
  final String nom;

  /// Recoit le motif retenu.
  final ValueChanged<String> onConfirmer;

  /// La cle du bouton de confirmation.
  static const Key confirmerKey = ValueKey<String>('cpt-ben-suspendre-ok');

  @override
  State<CorpsSuspension> createState() => _CorpsSuspensionEtat();
}

class _CorpsSuspensionEtat extends State<CorpsSuspension> {
  ReponseChoix _reponse = const ReponseChoix(valeurs: <String>{});
  bool _tente = false;

  String? get _motif {
    final String? libre = _reponse.saisieLibre?.trim();
    if (_reponse.valeurs.contains(ChoiceCardGroup.valeurAutre)) {
      return (libre == null || libre.isEmpty) ? null : libre;
    }
    if (_reponse.valeurs.isNotEmpty) return _reponse.valeurs.first;
    return (libre == null || libre.isEmpty) ? null : libre;
  }

  @override
  Widget build(BuildContext context) {
    final p = t.comptable.beneficiaires.profil;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          p.suspensionContexte,
          style: palette.surfaceRaised.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,
        ChoiceCardGroup(
          options: <OptionChoix>[
            OptionChoix(
              valeur: p.motifVerifier,
              libelle: p.motifVerifier,
              description: p.motifVerifierDetail,
              cle: const ValueKey<String>('cpt-ben-motif-verifier'),
            ),
            OptionChoix(
              valeur: p.motifAnomalie,
              libelle: p.motifAnomalie,
              description: p.motifAnomalieDetail,
              cle: const ValueKey<String>('cpt-ben-motif-anomalie'),
            ),
            OptionChoix(
              valeur: p.motifDemande,
              libelle: p.motifDemande,
              description: p.motifDemandeDetail,
              cle: const ValueKey<String>('cpt-ben-motif-demande'),
            ),
          ],
          onChange: (ReponseChoix r) => setState(() => _reponse = r),
        ),
        if (_tente && _motif == null) ...<Widget>[
          Ecart.vMd,
          Text(
            p.motifRequis,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vXl,
        ActionPrincipale(
          key: CorpsSuspension.confirmerKey,
          libelle: p.suspendre(nom: widget.nom),
          niveau: NiveauAction.destructive,
          onPress: () {
            final String? motif = _motif;
            if (motif == null) {
              setState(() => _tente = true);
              return;
            }
            widget.onConfirmer(motif);
          },
        ),
      ],
    );
  }
}
