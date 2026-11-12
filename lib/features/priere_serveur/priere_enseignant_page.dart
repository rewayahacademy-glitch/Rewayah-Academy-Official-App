import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/priere/libelle_priere.dart';
import '../../core/priere/lieu_priere.dart';
import '../../core/priere/service_priere.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/choix_nombre.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';

/// « Mes heures de priere » : l'enseignant lit les cinq heures de son jour et
/// ajuste chacune de 30 minutes au plus (PRIERE-1, P3).
///
/// **Rien n'est calcule ici** : les heures viennent de `priere_horaires_jour`,
/// le meme calcul serveur que celui qui place la pause de ses seances. Le lieu
/// est pose par la direction ; l'enseignant ne le modifie pas.
///
/// Cinq etats : chargement (squelette), contenu (cinq lignes), vide (aucun lieu
/// pose), erreur (relire), hors ligne (le bandeau de la page ; la lecture en
/// echec dit que la demande n'est peut-etre pas partie).
class PriereEnseignantPage extends ConsumerWidget {
  /// Cree la page.
  const PriereEnseignantPage({super.key});

  /// La cle de la ligne d'une priere.
  static Key cleLigne(Priere priere) =>
      ValueKey<String>('priere-ligne-${priere.valeurSql}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LieuPriere?> lieu = ref.watch(monLieuPriereProvider);
    final AsyncValue<List<HeurePriere>> heures = ref.watch(
      mesHorairesPriereProvider,
    );
    final TextTheme textes = Theme.of(context).textTheme;

    void relire() => ref
      ..invalidate(monLieuPriereProvider)
      ..invalidate(mesHorairesPriereProvider);

    final Widget corps;
    if (lieu.hasError || heures.hasError) {
      corps = EmptyState(
        message: t.priere.enseignant.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: relire,
      );
    } else if (!lieu.hasValue || !heures.hasValue) {
      corps = const Skeleton.liste(lignes: 5);
    } else if (lieu.requireValue == null) {
      corps = EmptyState(
        message: t.priere.enseignant.vide,
        icone: AppIcons.priere,
      );
    } else {
      corps = _Heures(
        lieu: lieu.requireValue!,
        heures: heures.requireValue,
        onAjuste: relire,
      );
    }

    return PageShell(
      titre: t.priere.enseignant.titre,
      // Ouverte depuis le Compte : le retour ramene au Compte.
      onRetour: () {
        final GoRouter? routeur = GoRouter.maybeOf(context);
        if (routeur == null) return;
        if (routeur.canPop()) {
          routeur.pop();
        } else {
          routeur.go(Routes.enseignantProfil);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.priere.enseignant.intro, style: textes.bodyMedium),
          Ecart.vXl,
          corps,
        ],
      ),
    );
  }
}

class _Heures extends ConsumerWidget {
  const _Heures({
    required this.lieu,
    required this.heures,
    required this.onAjuste,
  });

  final LieuPriere lieu;
  final List<HeurePriere> heures;
  final VoidCallback onAjuste;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final Map<Priere, HeurePriere> parPriere = <Priere, HeurePriere>{
      for (final HeurePriere h in heures) h.priere: h,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.priere.lieu(lieu: lieu.lieu), style: textes.titleMedium),
        Ecart.vMd,
        CarteLignes(
          lignes: <Widget>[
            for (final Priere priere in Priere.values)
              if (parPriere[priere] case final HeurePriere heure)
                SettingRow(
                  key: PriereEnseignantPage.cleLigne(priere),
                  title: libellePriere(priere),
                  value: heureChezMoi(heure.instant),
                  description: <String>[
                    _ajustement(lieu.ajustement(priere)),
                    if (heure.approximee) t.priere.approchee,
                  ].join('\n'),
                  icon: AppIcons.priere,
                  onPress: () => _ouvrir(context, ref, priere),
                ),
          ],
        ),
      ],
    );
  }

  void _ouvrir(BuildContext context, WidgetRef ref, Priere priere) {
    unawaited(
      AppBottomSheet.ouvrir<void>(
        context,
        titre: libellePriere(priere),
        constructeur: (BuildContext _) => _FeuilleAjustement(
          priere: priere,
          valeurInitiale: lieu.ajustement(priere),
          onEnregistre: () {
            ref.invalidate(pausePrevueProvider);
            onAjuste();
          },
        ),
      ),
    );
  }
}

/// « 3 min en plus », « 2 min en moins », ou « Aucun ajustement ».
String _ajustement(int minutes) => switch (minutes) {
  0 => t.priere.enseignant.aucunAjustement,
  > 0 => t.priere.enseignant.plus(minutes: '$minutes'),
  _ => t.priere.enseignant.moins(minutes: '${-minutes}'),
};

/// L'ajustement en minutes, signe, ancre pour s'afficher seul.
String _minutes(int n) => LibellesGroupe.valeurSeule(
  t.priere.enseignant.unite(n: n > 0 ? '+$n' : '$n'),
);

class _FeuilleAjustement extends ConsumerStatefulWidget {
  const _FeuilleAjustement({
    required this.priere,
    required this.valeurInitiale,
    required this.onEnregistre,
  });

  final Priere priere;
  final int valeurInitiale;
  final VoidCallback onEnregistre;

  @override
  ConsumerState<_FeuilleAjustement> createState() => _FeuilleAjustementEtat();
}

class _FeuilleAjustementEtat extends ConsumerState<_FeuilleAjustement> {
  late int _valeur = widget.valeurInitiale;
  bool _envoi = false;
  String? _erreur;

  Future<void> _enregistrer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref.read(servicePriereProvider).ajuster(widget.priere, _valeur);
      widget.onEnregistre();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _erreur = t.priere.enseignant.erreurEnregistrement);
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.priere.enseignant.feuilleAide,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Ecart.vMd,
        ChoixNombre(
          libelle: t.priere.enseignant.champ,
          valeur: _valeur,
          min: -30,
          max: 30,
          affichage: _minutes,
          libelleMoins: t.choix.diminuer,
          libellePlus: t.choix.augmenter,
          onChange: (int v) => setState(() {
            _valeur = v;
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
          libelle: t.priere.enseignant.enregistrer,
          enCours: _envoi,
          onPress: _enregistrer,
        ),
      ],
    );
  }
}
