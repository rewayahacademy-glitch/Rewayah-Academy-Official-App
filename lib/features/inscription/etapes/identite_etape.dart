import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../brouillon_inscription.dart';
import '../inscription_page.dart';

/// `/inscription/identite` : prenom et nom, erreurs sous les champs.
class IdentiteEtape extends ConsumerStatefulWidget {
  /// Cree l'etape.
  const IdentiteEtape({super.key});

  @override
  ConsumerState<IdentiteEtape> createState() => _IdentiteEtapeState();
}

class _IdentiteEtapeState extends ConsumerState<IdentiteEtape> {
  static const String _route = Routes.inscriptionIdentite;

  late final TextEditingController _prenom;
  late final TextEditingController _nom;

  /// Les erreurs ne s'affichent qu'apres une premiere tentative.
  bool _tente = false;

  @override
  void initState() {
    super.initState();
    final BrouillonInscription brouillon = ref.read(
      brouillonInscriptionProvider,
    );
    _prenom = TextEditingController(text: brouillon.prenom);
    _nom = TextEditingController(text: brouillon.nom);
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    super.dispose();
  }

  String? _erreur(TextEditingController champ) =>
      _tente && champ.text.trim().isEmpty ? t.inscription.champRequis : null;

  void _continuer() {
    if (_prenom.text.trim().isEmpty || _nom.text.trim().isEmpty) {
      setState(() => _tente = true);
      return;
    }
    ref
        .read(brouillonInscriptionProvider.notifier)
        .saisirIdentite(prenom: _prenom.text, nom: _nom.text);
    avancerDepuis(context, _route);
  }

  @override
  Widget build(BuildContext context) {
    exigerEtapesPrecedentes(
      context,
      ref.watch(brouillonInscriptionProvider),
      _route,
    );
    return CoquilleEtape(
      route: _route,
      question: t.inscription.identiteQuestion,
      explication: t.inscription.identiteRaison,
      libelleAction: t.commun.continuer,
      onAction: _continuer,
      onRetour: () => reculerDepuis(context, _route),
      enfant: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const Key('inscription-prenom'),
              controller: _prenom,
              onChanged: (String _) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.givenName],
              decoration: InputDecoration(
                labelText: t.inscription.prenom,
                errorText: _erreur(_prenom),
              ),
            ),
            Ecart.vLg,
            TextField(
              key: const Key('inscription-nom'),
              controller: _nom,
              onChanged: (String _) => setState(() {}),
              onSubmitted: (String _) => _continuer(),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.familyName],
              decoration: InputDecoration(
                labelText: t.inscription.nom,
                errorText: _erreur(_nom),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
