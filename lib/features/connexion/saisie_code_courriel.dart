// ONBOARDING-BOUCLE (directeur, 14/11/2026, demande repetee plus de dix fois) :
// « ou saisissez le code recu ».
//
// Le lien du courriel de connexion s'ouvre souvent dans un autre navigateur
// (l'appli de messagerie) que celui ou il a ete demande : l'echange PKCE y
// echoue et les reponses du questionnaire, gardees dans l'appareil, n'y sont
// pas ; la personne repartait du debut. Le courriel porte aussi un code a 6
// chiffres : saisi ici, dans le MEME navigateur, il ouvre la session sans
// passer par un autre. La session ouverte, le routeur fait le reste (aucun
// retour a l'ecran d'avant).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/auth/service_auth.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import 'coquille_entree.dart';

/// Le nombre de chiffres du code du courriel de connexion.
const int longueurCodeCourriel = 6;

/// Ne garde que les chiffres, au plus [longueurCodeCourriel] : un code colle
/// avec des espaces ou un tiret (« 123 456 ») reste utilisable. Pure.
String chiffresDuCode(String saisie) {
  final String chiffres = saisie.replaceAll(RegExp(r'[^0-9]'), '');
  return chiffres.length <= longueurCodeCourriel
      ? chiffres
      : chiffres.substring(0, longueurCodeCourriel);
}

/// Le champ « code recu » et son bouton, sous l'ecran « lien envoye ».
class SaisieCodeCourriel extends ConsumerStatefulWidget {
  /// Cree le bloc pour l'adresse a laquelle le lien est parti.
  const SaisieCodeCourriel({required this.courriel, super.key});

  /// L'adresse a laquelle le courriel est parti.
  final String courriel;

  /// La cle du champ du code (tests).
  static const Key cleChamp = ValueKey<String>('connexion-code-champ');

  /// La cle du bouton de validation (tests).
  static const Key cleBouton = ValueKey<String>('connexion-code-valider');

  @override
  ConsumerState<SaisieCodeCourriel> createState() => _SaisieCodeState();
}

class _SaisieCodeState extends ConsumerState<SaisieCodeCourriel> {
  final TextEditingController _code = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _surSaisie() {
    final String propre = chiffresDuCode(_code.text);
    if (propre != _code.text) {
      _code.value = TextEditingValue(
        text: propre,
        selection: TextSelection.collapsed(offset: propre.length),
      );
    }
    if (_erreur != null) {
      setState(() => _erreur = null);
    }
  }

  Future<void> _valider() async {
    if (_enCours) {
      return;
    }
    final String code = chiffresDuCode(_code.text);
    if (code.length != longueurCodeCourriel) {
      setState(() => _erreur = t.connexion.code.erreurLongueur);
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceAuthProvider)
          .verifierCodeCourriel(widget.courriel, code);
      // Session ouverte : le routeur emmene la personne la ou elle allait.
    } on AuthException {
      if (mounted) {
        setState(() => _erreur = t.connexion.code.erreurCode);
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.connexion.code.erreurReseau);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(t.connexion.code.titre, style: textes.titleMedium),
        ),
        Ecart.vSm,
        Text(
          t.connexion.code.aide,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,
        ChampEntree(
          cle: 'connexion-code-champ',
          etiquette: t.connexion.code.etiquette,
          indice: t.connexion.code.indice,
          controleur: _code,
          erreur: _erreur,
          onChanged: _surSaisie,
          onSoumettre: () => unawaited(_valider()),
          clavier: TextInputType.number,
          autofill: const <String>[AutofillHints.oneTimeCode],
        ),
        Ecart.vLg,
        ActionPrincipale(
          key: SaisieCodeCourriel.cleBouton,
          libelle: t.connexion.code.valider,
          onPress: () => unawaited(_valider()),
          enCours: _enCours,
          pleineLargeur: true,
        ),
      ],
    );
  }
}
