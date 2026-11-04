import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../i18n/isolat_bidi.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_spacing.dart';
import '../widgets/action_principale.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/choix_nombre.dart';
import '../widgets/selecteur_motif.dart';
import '../widgets/setting_row.dart';
import 'service_configuration.dart';

/// Les valeurs proposees d'un reglage entier (FORM-L13).
///
/// **Les puces ne sont que des raccourcis** : une valeur saisie par « Autre »
/// est acceptee des qu'elle est un entier positif ou nul, comme avant FORM-L13
/// (decide par delegation le 08/10). Seule exception : un plafond [max] qui a
/// une source ecrite (migration ou `docs/current`), citee en commentaire.
@immutable
class ReglageEntierPropose {
  /// Cree une proposition.
  const ReglageEntierPropose({required this.proposees, this.max});

  /// Les valeurs proposees en puces.
  final List<int> proposees;

  /// Le plafond de la saisie libre, seulement s'il a une source ecrite ; nul
  /// sinon (toute valeur >= 0 est acceptee).
  final int? max;
}

/// Les propositions des treize reglages entiers de Configuration, par cle
/// `app_config` (FORM-L13, decide par delegation le 05/10).
///
/// **Aucune regle metier n'est inventee ici** : chaque valeur proposee vient
/// d'un defaut de migration, d'une valeur deja proposee ailleurs dans le code
/// ou de `docs/current`. La source de chaque ligne est dans
/// `docs/current/FORM-L1-7-13_MOTIFS.md` (section L13). Le serveur n'impose
/// aucune borne ; l'ecran n'en ajoute aucune sans source ecrite (08/10).
const Map<String, ReglageEntierPropose>
reglagesEntiersProposes = <String, ReglageEntierPropose>{
  // Defaut 5 (0001_fondations).
  'absence_threshold_minutes': ReglageEntierPropose(
    proposees: <int>[5, 10, 15],
  ),
  // Defaut 60 (0005) ; 45 et 90 : doc 07 ; liste de `FeuilleRegle`.
  'session_duration_minutes': ReglageEntierPropose(
    proposees: <int>[30, 45, 60, 90],
  ),
  // Defaut 45 (0005) ; liste de `FeuilleRegle`.
  'session_paid_minimum_minutes': ReglageEntierPropose(
    proposees: <int>[30, 45, 60],
  ),
  // Defaut 30 (0005) ; liste de `FeuilleRegle`.
  'break_minutes_between_sessions': ReglageEntierPropose(
    proposees: <int>[15, 30, 45],
  ),
  // Defaut 5 (0005) ; liste de `FeuilleRegle` ; 6 : doc 07 (adultes).
  'max_students_per_teacher': ReglageEntierPropose(
    proposees: <int>[3, 4, 5, 6],
  ),
  // Defaut 4 (0005, 0033).
  'matching_horizon_weeks': ReglageEntierPropose(proposees: <int>[2, 4, 8]),
  // Defaut 11 (0001) ; 15 et 18 : bornes des tranches d'age (0043).
  'camera_auto_allow_min_age': ReglageEntierPropose(
    proposees: <int>[11, 15, 18],
  ),
  // Defaut 8 (0001) ; 7 et 10 : bornes des tranches d'age (0043).
  'child_ui_mode_max_age': ReglageEntierPropose(proposees: <int>[7, 8, 10]),
  // Defaut 2. Plafond 2 : source ecrite, regle C11 de
  // `supabase/migrations/0001_fondations.sql` (« deux appareils actifs
  // max par eleve », garde `guard_devices_max`).
  'max_devices_per_student': ReglageEntierPropose(
    proposees: <int>[1, 2],
    max: 2,
  ),
  // Defaut 1 (0001).
  'max_concurrent_sessions_per_profile': ReglageEntierPropose(
    proposees: <int>[1, 2],
  ),
  // Defaut 3 (decision du directeur du 22/10/2026). Plafond 80 : source
  // ecrite, le declencheur `app_config_classes_max` refuse au-dela
  // (`20261022000200_classes_plafond_par_enseignant.sql`).
  'enseignant.classes_max': ReglageEntierPropose(
    proposees: <int>[1, 2, 3, 4, 5, 6],
    max: 80,
  ),
  // Defaut 2 (0001), 7 (0017) ; 5 et 6 : doc 07 (capacites + enseignant).
  'max_participants_per_session': ReglageEntierPropose(
    proposees: <int>[2, 5, 6, 7],
  ),
  // Defaut 30 (0001, doc 06).
  'recording_retention_days': ReglageEntierPropose(proposees: <int>[7, 15, 30]),
  // Defaut 90 (0004).
  'kyc_retention_days': ReglageEntierPropose(proposees: <int>[30, 60, 90]),
  // Defaut 14 (20261018150000) : delai de reflexion avant qu'une demande de
  // suppression de compte puisse etre traitee.
  'compte.suppression_delai_jours': ReglageEntierPropose(
    proposees: <int>[7, 14, 30],
  ),
};

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
    this.min,
    this.max,
    this.aideBornes,
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

  /// La plus petite valeur admise, quand elle depend d'un autre reglage (les
  /// delais A3 se suivent) ; nul : 0.
  final int? min;

  /// La plus grande valeur admise, quand elle depend d'un autre reglage ; nul :
  /// le plafond a source ecrite de [reglagesEntiersProposes], s'il existe.
  final int? max;

  /// La phrase sous le titre de la feuille qui dit pourquoi ces bornes.
  final String? aideBornes;

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
        proposition: reglagesEntiersProposes[cle],
        min: min,
        max: max,
        aideBornes: aideBornes,
        affichage: affichage,
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
    required this.proposition,
    required this.affichage,
    required this.champValeur,
    required this.envoyer,
    required this.valeurInvalide,
    required this.erreurEcriture,
    required this.onEnvoyer,
    required this.onSucces,
    this.min,
    this.max,
    this.aideBornes,
  });

  final int valeurInitiale;
  final int? min;
  final int? max;
  final String? aideBornes;

  /// Les valeurs proposees ; nul pour une cle sans proposition (champ seul).
  final ReglageEntierPropose? proposition;
  final String Function(int valeur) affichage;
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
  late int? _choisie = widget.valeurInitiale;
  bool _envoi = false;
  String? _erreur;

  Future<void> _envoyer() async {
    final int? v = _choisie;
    final int min = widget.min ?? 0;
    if (v == null || v < 0) {
      setState(() => _erreur = widget.valeurInvalide);
      return;
    }
    // Seul un plafond a source ecrite refuse une valeur (08/10), ou une borne
    // tiree d'un autre reglage (delais A3).
    final int? max = _max;
    if (v < min || (max != null && v > max)) {
      setState(
        // DUREE-FOND-1 : une valeur ancree pour s'afficher seule
        // (« 30 jours », marque U+200E en tete) perd son ancre au milieu de
        // la phrase.
        () => _erreur = max == null
            ? widget.aideBornes ?? widget.valeurInvalide
            : t.formulaire.entier.horsBornes(
                min: sansAncre(widget.affichage(min)),
                max: sansAncre(widget.affichage(max)),
              ),
      );
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

  /// Le plafond en vigueur : celui de la ligne, sinon celui a source ecrite.
  int? get _max => widget.max ?? widget.proposition?.max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.aideBornes case final String aide) ...<Widget>[
          Text(aide, style: Theme.of(context).textTheme.bodyMedium),
          Ecart.vMd,
        ],
        if (widget.proposition case final ReglageEntierPropose p)
          SelecteurEntier(
            proposees: p.proposees,
            max: p.max,
            affichage: widget.affichage,
            valeurInitiale: widget.valeurInitiale,
            libelleChamp: widget.champValeur,
            onChange: (int? v) => setState(() {
              _choisie = v;
              _erreur = null;
            }),
          )
        else
          // Sans proposition, la valeur se choisit au pas a pas, jamais au
          // clavier (decision du 17/10).
          ChoixNombre(
            libelle: widget.champValeur,
            valeur: _choisie ?? widget.valeurInitiale,
            min: widget.min ?? 0,
            max: _max,
            affichage: widget.affichage,
            libelleMoins: t.choix.diminuer,
            libellePlus: t.choix.augmenter,
            onChange: (int v) => setState(() {
              _choisie = v;
              _erreur = null;
            }),
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
  // Un refus du serveur : son seul message, jamais « code: …, details: Bad
  // Request, hint: null » (capture R3 de la PR 128, 01/11/2026).
  if (erreur case PostgrestException(:final String message)) {
    return message;
  }
  final String brut = erreur.toString();
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}
