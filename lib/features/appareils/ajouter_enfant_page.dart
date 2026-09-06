import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/inscription/page_parcours.dart';

/// L'ajout d'un enfant au foyer.
///
/// Une seule page, parce qu'il n'y a qu'une question reelle : l'age. C'est lui
/// qui fixe le mode d'interface et la politique camera initiale (ADR-009), et
/// les deux valeurs sont derivees **en base**, depuis `app_config`, jamais ici :
/// le seuil est un reglage d'academie, pas une constante d'application.
class AjouterEnfantPage extends ConsumerStatefulWidget {
  /// Cree l'ecran d'ajout.
  const AjouterEnfantPage({super.key});

  @override
  ConsumerState<AjouterEnfantPage> createState() => _AjouterEnfantPageState();
}

class _AjouterEnfantPageState extends ConsumerState<AjouterEnfantPage> {
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _age = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _age.dispose();
    super.dispose();
  }

  int? get _ageLu {
    final int? valeur = int.tryParse(_age.text.trim());
    if (valeur == null || valeur < 3 || valeur > 18) {
      return null;
    }
    return valeur;
  }

  bool get _complet =>
      _prenom.text.trim().isNotEmpty &&
      _nom.text.trim().isNotEmpty &&
      _ageLu != null;

  Future<void> _creer() async {
    final int? age = _ageLu;
    if (age == null) {
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceAppairageProvider)
          .creerEnfant(
            prenom: _prenom.text.trim(),
            nom: _nom.text.trim(),
            age: age,
          );
      ref.invalidate(elevesDuFoyerProvider);
      if (mounted) {
        GoRouter.of(context).go(Routes.tuteurFoyer);
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.enfant.erreur);
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageParcours(
      numero: 1,
      total: 1,
      question: t.enfant.titre,
      explication: t.enfant.ageRaison,
      libelleAction: t.enfant.creer,
      onAction: _complet ? () => unawaited(_creer()) : null,
      onRetour: () => GoRouter.of(context).go(Routes.tuteurFoyer),
      enCours: _envoi,
      souscription: _erreur == null
          ? null
          : Semantics(
              liveRegion: true,
              child: Text(
                _erreur!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _prenom,
            onChanged: (String _) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: t.enfant.prenom),
          ),
          Ecart.vLg,
          TextField(
            controller: _nom,
            onChanged: (String _) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: t.enfant.nom),
          ),
          Ecart.vLg,
          TextField(
            controller: _age,
            onChanged: (String _) => setState(() {}),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t.enfant.age,
              errorText: _age.text.trim().isEmpty || _ageLu != null
                  ? null
                  : t.enfant.ageInvalide,
            ),
          ),
        ],
      ),
    );
  }
}
