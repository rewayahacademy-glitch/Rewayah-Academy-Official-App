import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import 'domaine/erreur_domaine.dart';

/// La feuille qui dispense un compte du KYC, ou retablit l'exigence.
///
/// Les garanties du contrat (section 5.3) sont **serveur** : autorisation,
/// idempotence, audit, jamais accessible au demandeur lui-meme. Cette feuille
/// tient ce qui revient a l'ecran : une confirmation courte, la consequence en
/// langage humain, un motif obligatoire, et un retour qui ne montre jamais une
/// erreur brute.
class FeuilleDispenseKyc extends StatefulWidget {
  /// Cree la feuille.
  const FeuilleDispenseKyc({
    required this.libelleCompte,
    required this.requiseActuellement,
    required this.onEnvoyer,
    required this.onSucces,
    super.key,
  });

  /// Ce qui s'affiche pour nommer la personne.
  final String libelleCompte;

  /// Vrai quand le KYC est requis aujourd'hui : la feuille propose alors de
  /// dispenser ; faux, elle propose de retablir.
  final bool requiseActuellement;

  /// L'ecriture, avec le motif. Leve en cas d'echec.
  final Future<void> Function(String motif) onEnvoyer;

  /// Appele apres une ecriture reussie, avant la fermeture.
  final VoidCallback onSucces;

  /// Ouvre la feuille.
  static Future<void> ouvrir(
    BuildContext context, {
    required String libelleCompte,
    required bool requiseActuellement,
    required Future<void> Function(String motif) onEnvoyer,
    required VoidCallback onSucces,
  }) => AppBottomSheet.ouvrir<void>(
    context,
    titre: requiseActuellement
        ? t.classes.conformite.dispenserTitre(libelle: libelleCompte)
        : t.classes.conformite.retablirTitre(libelle: libelleCompte),
    constructeur: (BuildContext _) => FeuilleDispenseKyc(
      libelleCompte: libelleCompte,
      requiseActuellement: requiseActuellement,
      onEnvoyer: onEnvoyer,
      onSucces: onSucces,
    ),
  );

  @override
  State<FeuilleDispenseKyc> createState() => _FeuilleDispenseKycEtat();
}

class _FeuilleDispenseKycEtat extends State<FeuilleDispenseKyc> {
  final TextEditingController _motif = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.onEnvoyer(_motif.text.trim());
      widget.onSucces();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(
          () => _erreur = t.classes.conformite.echec(
            message: messageHumain(erreur),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool dispenser = widget.requiseActuellement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          dispenser
              ? t.classes.conformite.dispenserConsequence(
                  libelle: widget.libelleCompte,
                )
              : t.classes.conformite.retablirConsequence(
                  libelle: widget.libelleCompte,
                ),
          style: textes.bodyMedium,
        ),
        Ecart.vLg,
        Text(t.classes.conformite.motifRequis, style: textes.bodySmall),
        Ecart.vSm,
        TextField(
          controller: _motif,
          maxLines: 2,
          onChanged: (String _) => setState(() {}),
          decoration: InputDecoration(labelText: t.classes.conformite.motif),
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              _erreur!,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          libelle: dispenser
              ? t.classes.conformite.dispenserEnvoyer
              : t.classes.conformite.retablirEnvoyer,
          enCours: _envoi,
          onPress: _motif.text.trim().isEmpty ? null : () => unawaited(_envoyer()),
        ),
      ],
    );
  }
}
