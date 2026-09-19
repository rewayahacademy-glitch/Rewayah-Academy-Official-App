import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../icons/app_icons.dart';
import '../theme/app_spacing.dart';
import '../widgets/action_principale.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/setting_row.dart';
import 'service_configuration.dart';

/// Une ligne Configuration qui edite un entier de `app_config` par une
/// feuille de saisie -- meme mecanique que `_FeuilleTraitement` de
/// `admin_pedagogie_qualite/qualite_page.dart`, generalisee parce que les
/// trois ecrans Configuration (Regles, Fonctionnalites, Conservation des
/// donnees) en ont chacun plusieurs. Les libelles traduits viennent de
/// l'appelant : ce widget, comme [SettingRow], ne connait aucune cle `t.*`.
class ConfigLigneEntiere extends ConsumerWidget {
  /// Cree la ligne.
  const ConfigLigneEntiere({
    required this.titre,
    required this.description,
    required this.cle,
    required this.valeur,
    required this.affichage,
    required this.champValeur,
    required this.envoyer,
    required this.valeurInvalide,
    required this.erreurEcriture,
    required this.onEcrit,
    super.key,
    this.icone = AppIcons.reglages,
  });

  /// Le titre de la ligne.
  final String titre;

  /// La description sous le titre.
  final String description;

  /// La cle `app_config` a lire et ecrire.
  final String cle;

  /// La valeur courante.
  final int valeur;

  /// Formate la valeur pour l'affichage (unite comprise).
  final String Function(int valeur) affichage;

  /// Le libelle du champ de saisie.
  final String champValeur;

  /// Le libelle du bouton d'envoi.
  final String envoyer;

  /// Le message affiche quand la saisie n'est pas un entier valide.
  final String valeurInvalide;

  /// Le message d'erreur d'ecriture, le detail technique en parametre.
  final String Function(String message) erreurEcriture;

  /// Appele apres une ecriture reussie -- invalide le provider de lecture.
  final VoidCallback onEcrit;

  /// L'icone de la ligne.
  final AppIcon icone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingRow(
      title: titre,
      description: description,
      value: affichage(valeur),
      icon: icone,
      onPress: () => _ouvrir(context, ref),
    );
  }

  void _ouvrir(BuildContext context, WidgetRef ref) {
    AppBottomSheet.ouvrir<void>(
      context,
      titre: titre,
      constructeur: (BuildContext _) => _FeuilleEntiere(
        valeurInitiale: valeur,
        champValeur: champValeur,
        envoyer: envoyer,
        valeurInvalide: valeurInvalide,
        onEnvoyer: (int v) =>
            ref.read(serviceConfigurationProvider).ecrire(cle, v),
        erreurEcriture: erreurEcriture,
        onSucces: onEcrit,
      ),
    );
  }
}

class _FeuilleEntiere extends StatefulWidget {
  const _FeuilleEntiere({
    required this.valeurInitiale,
    required this.champValeur,
    required this.envoyer,
    required this.valeurInvalide,
    required this.erreurEcriture,
    required this.onEnvoyer,
    required this.onSucces,
  });

  final int valeurInitiale;
  final String champValeur;
  final String envoyer;
  final String valeurInvalide;
  final String Function(String message) erreurEcriture;
  final Future<void> Function(int valeur) onEnvoyer;
  final VoidCallback onSucces;

  @override
  State<_FeuilleEntiere> createState() => _FeuilleEntiereEtat();
}

class _FeuilleEntiereEtat extends State<_FeuilleEntiere> {
  late final TextEditingController _champ = TextEditingController(
    text: '${widget.valeurInitiale}',
  );
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _champ.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final int? v = int.tryParse(_champ.text.trim());
    if (v == null || v < 0) {
      setState(() => _erreur = widget.valeurInvalide);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.onEnvoyer(v);
      widget.onSucces();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      setState(() => _erreur = widget.erreurEcriture(_message(erreur)));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: _champ,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(labelText: widget.champValeur),
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          libelle: widget.envoyer,
          enCours: _envoi,
          onPress: _envoyer,
        ),
      ],
    );
  }
}

/// Une ligne Configuration qui bascule un booleen de `app_config`
/// immediatement -- pas de feuille, comme les interrupteurs de
/// `features/compte/compte_page.dart`, mais avec une ecriture serveur et son
/// erreur eventuelle affichee sous la ligne plutot que silencieuse.
class ConfigLigneBooleenne extends ConsumerStatefulWidget {
  /// Cree la ligne.
  const ConfigLigneBooleenne({
    required this.titre,
    required this.description,
    required this.cle,
    required this.valeur,
    required this.erreurEcriture,
    required this.onEcrit,
    super.key,
    this.icone = AppIcons.reglages,
  });

  /// Le titre de la ligne.
  final String titre;

  /// La description sous le titre.
  final String description;

  /// La cle `app_config` a ecrire.
  final String cle;

  /// La valeur courante.
  final bool valeur;

  /// Le message d'erreur d'ecriture, le detail technique en parametre.
  final String Function(String message) erreurEcriture;

  /// Appele apres une ecriture reussie -- invalide le provider de lecture.
  final VoidCallback onEcrit;

  /// L'icone de la ligne.
  final AppIcon icone;

  @override
  ConsumerState<ConfigLigneBooleenne> createState() =>
      _ConfigLigneBooleenneEtat();
}

class _ConfigLigneBooleenneEtat extends ConsumerState<ConfigLigneBooleenne> {
  String? _erreur;

  Future<void> _basculer(bool v) async {
    setState(() => _erreur = null);
    try {
      await ref.read(serviceConfigurationProvider).ecrire(widget.cle, v);
      widget.onEcrit();
    } catch (erreur) {
      if (mounted) {
        setState(() => _erreur = widget.erreurEcriture(_message(erreur)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingRow(
          title: widget.titre,
          description: widget.description,
          icon: widget.icone,
          controle: Switch.adaptive(value: widget.valeur, onChanged: _basculer),
        ),
        if (_erreur != null) ...<Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              top: AppSpacing.xs,
            ),
            child: Text(
              _erreur!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }
}

String _message(Object erreur) {
  final String brut = erreur.toString();
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}
