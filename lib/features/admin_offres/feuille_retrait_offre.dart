/// L2-05 : la feuille « Retirer cette offre » (motif obligatoire).
///
/// Le serveur refuse un retrait sans motif (`retirer_offre_horaire`) : la
/// feuille le dit avant l'envoi, sans griser le bouton. Les demandes deja
/// posees sur l'offre ne sont pas effacees (la phrase le dit) : l'administration
/// doit les traiter. Echec honnete (K-59) : « non confirme », la saisie reste.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/port_offres_admin.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/zone_saisie.dart';
import '../admin_groupes/bas_de_feuille.dart';
import 'offres_libelles.dart';

/// La feuille de retrait d'une offre. Se ferme sur `true` si l'offre est
/// retiree.
class FeuilleRetraitOffre extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleRetraitOffre({required this.offre, super.key});

  /// L'offre a retirer.
  final OffreAdmin offre;

  @override
  ConsumerState<FeuilleRetraitOffre> createState() =>
      _FeuilleRetraitOffreEtat();
}

class _FeuilleRetraitOffreEtat extends ConsumerState<FeuilleRetraitOffre> {
  final TextEditingController _motif = TextEditingController();
  bool _envoi = false;
  String? _message;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _retirer() async {
    if (_envoi) return;
    final String motif = _motif.text.trim();
    if (motif.isEmpty) {
      setState(() => _message = t.admin.offres.motifManque);
      return;
    }
    setState(() {
      _envoi = true;
      _message = null;
    });
    String? echec;
    try {
      await ref
          .read(portOffresAdminProvider)
          .retirer(widget.offre.id, motif: motif);
    } on OffreAdminRefusee catch (e) {
      echec = t.admin.offres.refusee(motif: e.message);
    } on Object {
      echec = t.admin.offres.nonConfirmee;
    }
    if (!mounted) return;
    if (echec != null) {
      setState(() {
        _envoi = false;
        _message = echec;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final o = t.admin.offres;
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          resumeOffre(widget.offre),
          key: const ValueKey<String>('retrait-resume'),
          style: textes.titleMedium,
        ),
        Ecart.vXs,
        TexteSansCoupure(o.retraitExplication, style: textes.bodySmall),
        Ecart.vLg,
        ZoneSaisie(
          cleChamp: const ValueKey<String>('retrait-motif'),
          controleur: _motif,
          libelle: o.motifLibelle,
          minLignes: 2,
          onChanged: (String _) {
            if (_message != null) setState(() => _message = null);
          },
        ),
        if (_message != null) ...<Widget>[
          Ecart.vMd,
          KeyedSubtree(
            key: const ValueKey<String>('retrait-message'),
            child: MessageAlerte(_message!),
          ),
        ],
        Ecart.vLg,
        BasDeFeuille(
          libelle: o.retirer,
          enCours: _envoi,
          horsLigne: o.retraitHorsLigne,
          onPress: () => unawaited(_retirer()),
        ),
      ],
    );
  }
}
