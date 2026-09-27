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
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import '../accueil_eleve/accueil_accessibilite.dart';
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
///
/// MA-2 : hors de la salle, l'ecran est pose dans la VRAIE coquille
/// (`NavShell`, destinations de `destinationsPour` pour l'eleve), sur Ma
/// classe. Les autres destinations restent dans la demonstration (aucune
/// route reelle, aucun serveur). MA-3 : l'Accueil du mode
/// (`AccueilAccessibilite`) ; le Coran et Mon espace arrivent en MA-7 et
/// MA-8. Pendant la seance, aucune
/// navigation d'app (MA17, MA20).
class EcranAccessibiliteDemo extends StatefulWidget {
  /// Cree l'ecran.
  const EcranAccessibiliteDemo({
    required this.eleve,
    this.moment = MomentDemoAccessibilite.avant,
    this.destinationInitiale = indexMaClasse,
    super.key,
  });

  /// L'eleve.
  final EleveDemoAccessibilite eleve;

  /// Le moment de la seance.
  final MomentDemoAccessibilite moment;

  /// La destination ouverte a l'arrivee (captures de MA-3 : l'Accueil).
  final int destinationInitiale;

  /// L'index de Ma classe dans les destinations de l'eleve.
  static const int indexMaClasse = 1;

  /// L'index de l'Accueil (MA-3).
  static const int indexAccueil = 0;

  /// L'index du Coran.
  static const int indexCoran = 2;

  /// L'index de Mon espace.
  static const int indexMonEspace = 3;

  @override
  State<EcranAccessibiliteDemo> createState() => _EcranAccessibiliteDemoEtat();
}

class _EcranAccessibiliteDemoEtat extends State<EcranAccessibiliteDemo> {
  late int _index = widget.destinationInitiale;

  void _aller(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final Widget classe = EcranEleveDemo(
      etat: DonneesAccessibiliteDemo.etatClasse(widget.moment),
      titre: DonneesAccessibiliteDemo.titre,
    );
    final List<Destination> destinations = destinationsPour(
      role: AppRole.student,
      mode: DonneesAccessibiliteDemo.presentation,
    );
    final Widget contenu = widget.moment == MomentDemoAccessibilite.pendant
        ? classe
        : NavShell(
            destinations: destinations,
            indexActif: _index,
            libellesDansLeRail: true,
            onAller: (String chemin) {
              final int i = destinations.indexWhere(
                (Destination d) => d.chemin == chemin,
              );
              if (i != -1) setState(() => _index = i);
            },
            child: _index == EcranAccessibiliteDemo.indexMaClasse
                ? classe
                : _index == EcranAccessibiliteDemo.indexAccueil
                ? AccueilAccessibilite(
                    key: const ValueKey<String>('demo-accueil'),
                    prenom: DonneesAccessibiliteDemo.prenom(widget.eleve),
                    espace: DonneesAccessibiliteDemo.espaceAccueil(
                      widget.moment,
                    ),
                    onVoirClasse: () =>
                        _aller(EcranAccessibiliteDemo.indexMaClasse),
                    onTache: () => _aller(EcranAccessibiliteDemo.indexMaClasse),
                    onCoran: () => _aller(EcranAccessibiliteDemo.indexCoran),
                    // L'aide vit dans Mon espace en demonstration (MA14,
                    // MA-8) : aucune route reelle hors de la demonstration.
                    onAide: () => _aller(EcranAccessibiliteDemo.indexMonEspace),
                  )
                : PageShell(
                    key: ValueKey<String>('demo-destination-$_index'),
                    titre: destinations[_index].libelle,
                    sousTitre: t.accessibilite.demo.mention,
                    child: const SizedBox.shrink(),
                  ),
          );
    // Sous la racine, le theme suit la session (standard en demonstration) :
    // la presentation du Mode Accessibilite y est reprise telle quelle,
    // `AppTheme.pour` existant, sans aucune couleur nouvelle (K-37).
    return ProviderScope(
      key: ValueKey<String>('${widget.eleve.name}-${widget.moment.name}'),
      overrides: surchargesAccessibiliteDemo(),
      child: Theme(
        data: AppTheme.pour(
          DonneesAccessibiliteDemo.presentation,
          Theme.of(context).brightness,
        ),
        child: contenu,
      ),
    );
  }
}
