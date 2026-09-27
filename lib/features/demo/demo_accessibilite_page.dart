// Le Mode Accessibilite en demonstration : /demo/accessibilite (hors
// production, MA-1b).
//
// Sans parametre : les liens eleve x moment de la seance. Avec `eleve`
// (mariam, idriss) et `moment` (avant, pendant, apres) : la presentation est
// surchargee en Mode Accessibilite (`surchargePresentationProvider`) autour
// du VRAI Espace Classe eleve de la demonstration de Classe (CL-4). Les
// ecrans propres au mode arrivent de MA-2 a MA-8. Aucun port reseau n'est
// modifie : aucun appel serveur (K-28).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/mode_accessibilite.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import 'accessibilite_demo.dart';
import 'demo_classe_page.dart' show EcranEleveDemo;
import 'mode_demonstration.dart';

/// Les routes de la demonstration du Mode Accessibilite : AUCUNE en
/// production.
List<RouteBase> routesDemoAccessibilite(String environnement) {
  if (!environnementAutoriseDemo(environnement)) return const <RouteBase>[];
  return <RouteBase>[
    GoRoute(
      path: Routes.demoAccessibilite,
      builder: (BuildContext _, GoRouterState etat) => DemoAccessibilitePage(
        eleve: _lire(
          EleveDemoAccessibilite.values,
          etat.uri.queryParameters['eleve'],
        ),
        moment:
            _lire(
              MomentDemoAccessibilite.values,
              etat.uri.queryParameters['moment'],
            ) ??
            MomentDemoAccessibilite.avant,
      ),
    ),
  ];
}

T? _lire<T extends Enum>(List<T> valeurs, String? nom) {
  for (final T v in valeurs) {
    if (v.name == nom) return v;
  }
  return null;
}

/// L'adresse d'une situation de la demonstration.
String adresseDemoAccessibilite(
  EleveDemoAccessibilite eleve, {
  MomentDemoAccessibilite moment = MomentDemoAccessibilite.avant,
}) => Uri(
  path: Routes.demoAccessibilite,
  queryParameters: <String, String>{'eleve': eleve.name, 'moment': moment.name},
).toString();

/// Le libelle d'un eleve de la demonstration.
String libelleEleveDemoAccessibilite(EleveDemoAccessibilite eleve) =>
    switch (eleve) {
      EleveDemoAccessibilite.mariam => t.accessibilite.demo.eleveMineure,
      EleveDemoAccessibilite.idriss => t.accessibilite.demo.eleveAdulte,
    };

/// Le libelle d'un moment de la seance.
String libelleMomentDemoAccessibilite(MomentDemoAccessibilite moment) =>
    switch (moment) {
      MomentDemoAccessibilite.avant => t.accessibilite.demo.etatAvant,
      MomentDemoAccessibilite.pendant => t.accessibilite.demo.etatPendant,
      MomentDemoAccessibilite.apres => t.accessibilite.demo.etatApres,
    };

/// Les surcharges du Mode Accessibilite en demonstration.
List<Override> surchargesAccessibiliteDemo() => <Override>[
  surchargePresentationProvider.overrideWithValue(
    DonneesAccessibiliteDemo.presentation,
  ),
];

/// La page : la liste des situations, ou l'ecran de la situation choisie.
class DemoAccessibilitePage extends StatelessWidget {
  /// Cree la page.
  const DemoAccessibilitePage({
    this.eleve,
    this.moment = MomentDemoAccessibilite.avant,
    super.key,
  });

  /// L'eleve choisi, ou nul pour la liste.
  final EleveDemoAccessibilite? eleve;

  /// Le moment de la seance.
  final MomentDemoAccessibilite moment;

  @override
  Widget build(BuildContext context) {
    final EleveDemoAccessibilite? e = eleve;
    if (e != null) return EcranAccessibiliteDemo(eleve: e, moment: moment);

    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    Text texte(String valeur, {bool fort = false}) => Text(
      valeur,
      style: (fort ? palette.inkStrong : palette.inkMuted).applyTo(
        (fort ? textes.titleMedium : textes.bodyMedium) ?? const TextStyle(),
      ),
    );
    return PageShell(
      titre: t.accessibilite.demo.titre,
      sousTitre: t.accessibilite.demo.mention,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          texte(t.accessibilite.demo.intro),
          for (final EleveDemoAccessibilite eleve
              in EleveDemoAccessibilite.values) ...<Widget>[
            Ecart.vXxl,
            Semantics(
              header: true,
              child: texte(libelleEleveDemoAccessibilite(eleve), fort: true),
            ),
            Ecart.vMd,
            for (final MomentDemoAccessibilite moment
                in MomentDemoAccessibilite.values)
              LienFleche(
                key: ValueKey<String>('lien-${eleve.name}-${moment.name}'),
                libelle: libelleMomentDemoAccessibilite(moment),
                onPress: () =>
                    context.go(adresseDemoAccessibilite(eleve, moment: moment)),
              ),
          ],
        ],
      ),
    );
  }
}

/// L'ecran d'une situation, en Mode Accessibilite.
class EcranAccessibiliteDemo extends StatelessWidget {
  /// Cree l'ecran.
  const EcranAccessibiliteDemo({
    required this.eleve,
    this.moment = MomentDemoAccessibilite.avant,
    super.key,
  });

  /// L'eleve.
  final EleveDemoAccessibilite eleve;

  /// Le moment de la seance.
  final MomentDemoAccessibilite moment;

  @override
  Widget build(BuildContext context) {
    // Sous la racine, le theme suit la session (standard en demonstration) :
    // la presentation du Mode Accessibilite y est reprise telle quelle,
    // `AppTheme.pour` existant, sans aucune couleur nouvelle (K-37).
    return ProviderScope(
      key: ValueKey<String>('${eleve.name}-${moment.name}'),
      overrides: surchargesAccessibiliteDemo(),
      child: Theme(
        data: AppTheme.pour(
          DonneesAccessibiliteDemo.presentation,
          Theme.of(context).brightness,
        ),
        child: EcranEleveDemo(
          etat: DonneesAccessibiliteDemo.etatClasse(moment),
          titre: DonneesAccessibiliteDemo.titre,
        ),
      ),
    );
  }
}
