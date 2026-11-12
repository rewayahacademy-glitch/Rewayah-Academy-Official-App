import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/config_edition.dart';
import '../../core/admin/service_configuration.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/priere/libelle_priere.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/setting_row.dart';

/// La section « La priere » de Configuration > Regles (PRIERE-1, P3, P5, P6) :
/// les reglages de la priere de toute l'ecole.
///
/// La methode et l'ecole d'Asr relevent du fiqh : la ligne le dit
/// (« valeur par defaut en vigueur, a valider par le directeur et ses
/// associes »). Un serveur d'avant ce lot ne rend pas les cles : la section
/// n'est alors pas montree, plutot qu'un « 0 min » que rien n'ecrirait.
List<Widget> sectionReglesPriere({
  required List<ValeurConfig> valeurs,
  required TextTheme textes,
  required VoidCallback onEcrit,
  required String Function(String message) erreurEcriture,
}) {
  ValeurConfig? v(String cle) {
    for (final ValeurConfig c in valeurs) {
      if (c.cle == cle) return c;
    }
    return null;
  }

  if (clesPriere.any((String c) => v(c)?.valeur == null)) {
    return const <Widget>[];
  }
  final r = t.priere.regles;
  String enMinutes(int n) => LibellesGroupe.valeurSeule(r.unite(n: '$n'));
  String enJours(int n) => LibellesGroupe.valeurSeule(r.uniteJours(n: '$n'));
  String refus(String message) => r.erreurEcriture(message: message);

  ConfigLigneEntiere ligne({
    required String titre,
    required String description,
    required String cle,
    required int min,
    required int max,
    required List<int> proposees,
    required String Function(int) affichage,
  }) => ConfigLigneEntiere(
    key: ValueKey<String>('regles-$cle'),
    titre: titre,
    description: description,
    cle: cle,
    valeur: v(cle)!.versEntier,
    min: min,
    max: max,
    proposition: ReglageEntierPropose(proposees: proposees, max: max),
    affichage: affichage,
    champValeur: t.admin.regles.champValeur,
    envoyer: t.admin.regles.envoyer,
    valeurInvalide: t.admin.regles.valeurInvalide,
    erreurEcriture: refus,
    onEcrit: onEcrit,
  );

  final MethodeCalcul? methode = MethodeCalcul.depuisSql(
    v(clePriereMethode)!.valeur as String?,
  );
  final Madhab? ecole = Madhab.depuisSql(
    v(clePriereEcoleAsr)!.valeur as String?,
  );

  return <Widget>[
    Ecart.vXl,
    Text(
      r.section,
      key: const ValueKey<String>('regles-priere'),
      style: textes.titleMedium,
    ),
    Ecart.vSm,
    Text(r.intro, style: textes.bodyMedium),
    Ecart.vMd,
    CarteLignes(
      lignes: <Widget>[
        // Le lieu de chaque enseignant : une page de la direction, ouverte d'ici.
        Builder(
          builder: (BuildContext context) => SettingRow(
            key: const ValueKey<String>('regles-priere-lieux'),
            title: r.lieux,
            description: r.lieuxDetail,
            icon: AppIcons.priere,
            lien: true,
            onPress: () => unawaited(
              GoRouter.of(context).push(Routes.adminConfigurationPriere),
            ),
          ),
        ),
        _LigneChoixTexte(
          cle: clePriereMethode,
          titre: r.methode,
          description: '${r.methodeDetail} ${t.priere.aValider}',
          valeur: methode == null ? '' : libelleMethode(methode),
          choix: <(String, String)>[
            for (final MethodeCalcul m in MethodeCalcul.values)
              (m.valeurSql, libelleMethode(m)),
          ],
          courante: methode?.valeurSql,
          erreurEcriture: refus,
          onEcrit: onEcrit,
        ),
        _LigneChoixTexte(
          cle: clePriereEcoleAsr,
          titre: r.ecole,
          description: '${r.ecoleDetail} ${t.priere.aValider}',
          valeur: ecole == null ? '' : libelleEcoleAsr(ecole),
          choix: <(String, String)>[
            for (final Madhab m in Madhab.values)
              (m.valeurSql, libelleEcoleAsr(m)),
          ],
          courante: ecole?.valeurSql,
          erreurEcriture: refus,
          onEcrit: onEcrit,
        ),
        ligne(
          titre: r.pause,
          description: r.pauseDetail,
          cle: clePrierePause,
          min: 5,
          max: 20,
          proposees: <int>[5, 10, 15, 20],
          affichage: enMinutes,
        ),
        ligne(
          titre: r.pauseRamadan,
          description: r.pauseRamadanDetail,
          cle: clePrierePauseRamadan,
          min: 5,
          max: 20,
          proposees: <int>[5, 10, 15, 20],
          affichage: enMinutes,
        ),
        ConfigLigneBooleenne(
          key: const ValueKey<String>('regles-priere-ramadan'),
          titre: r.ramadan,
          description: r.ramadanDetail,
          cle: clePriereRamadan,
          valeur: v(clePriereRamadan)!.versBooleen,
          erreurEcriture: refus,
          onEcrit: onEcrit,
        ),
        ligne(
          titre: r.margeDebut,
          description: r.margeDebutDetail,
          cle: clePriereMargeDebut,
          min: 0,
          max: 15,
          proposees: <int>[0, 5, 10, 15],
          affichage: enMinutes,
        ),
        ligne(
          titre: r.margeFin,
          description: r.margeFinDetail,
          cle: clePriereMargeFin,
          min: 5,
          max: 30,
          proposees: <int>[10, 15, 20, 30],
          affichage: enMinutes,
        ),
        ligne(
          titre: r.horizon,
          description: r.horizonDetail,
          cle: clePriereHorizon,
          min: 7,
          max: 30,
          proposees: <int>[7, 14, 21, 30],
          affichage: enJours,
        ),
      ],
    ),
  ];
}

/// Une ligne qui edite un texte de `app_config` parmi un choix ferme : la
/// feuille montre toutes les options, la carte choisie se voit en entier.
class _LigneChoixTexte extends ConsumerWidget {
  const _LigneChoixTexte({
    required this.cle,
    required this.titre,
    required this.description,
    required this.valeur,
    required this.choix,
    required this.courante,
    required this.erreurEcriture,
    required this.onEcrit,
  });

  final String cle;
  final String titre;
  final String description;
  final String valeur;
  final List<(String, String)> choix;
  final String? courante;
  final String Function(String message) erreurEcriture;
  final VoidCallback onEcrit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingRow(
      key: ValueKey<String>('regles-$cle'),
      title: titre,
      description: description,
      value: valeur,
      icon: AppIcons.priere,
      onPress: () => unawaited(
        AppBottomSheet.ouvrir<void>(
          context,
          titre: titre,
          constructeur: (BuildContext contexte) => _Feuille(
            cle: cle,
            choix: choix,
            courante: courante,
            erreurEcriture: erreurEcriture,
            onEcrit: onEcrit,
          ),
        ),
      ),
    );
  }
}

class _Feuille extends ConsumerStatefulWidget {
  const _Feuille({
    required this.cle,
    required this.choix,
    required this.courante,
    required this.erreurEcriture,
    required this.onEcrit,
  });

  final String cle;
  final List<(String, String)> choix;
  final String? courante;
  final String Function(String message) erreurEcriture;
  final VoidCallback onEcrit;

  @override
  ConsumerState<_Feuille> createState() => _FeuilleEtat();
}

class _FeuilleEtat extends ConsumerState<_Feuille> {
  String? _erreur;

  Future<void> _choisir(String valeur) async {
    if (valeur == widget.courante) {
      Navigator.of(context).pop();
      return;
    }
    try {
      await ref.read(serviceConfigurationProvider).ecrire(widget.cle, valeur);
      widget.onEcrit();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      if (mounted) {
        setState(() => _erreur = widget.erreurEcriture('$erreur'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.priere.aValider, style: Theme.of(context).textTheme.bodyMedium),
        Ecart.vMd,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: widget.courante == null
              ? null
              : ReponseChoix(valeurs: <String>{widget.courante!}),
          options: <OptionChoix>[
            for (final (String valeur, String libelle) in widget.choix)
              OptionChoix(valeur: valeur, libelle: libelle),
          ],
          onChange: (ReponseChoix r) {
            if (r.valeurs.isNotEmpty) {
              unawaited(_choisir(r.valeurs.first));
            }
          },
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
