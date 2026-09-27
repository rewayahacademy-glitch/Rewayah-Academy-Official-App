// La coquille controleur en demonstration : /demo/controleur (hors
// production, CT-1b).
//
// Sans parametre : les liens ecran x situation. Avec `ecran` (controle,
// historique, echanges, compte) et `etat` (aucune, pasEncoreEnDirect,
// enDirect, indisponible) : la VRAIE coquille (`NavShell`, destinations de
// `destinationsPour(AppRole.controller)`, C13) et la VRAIE page de la
// destination, ses providers surcharges par un ProviderScope (K-35). Les
// fournisseurs reels restent en place, aucun port reseau n'est modifie :
// aucun appel serveur (K-28).
//
// Controle montre encore le planning global, vide ici, jusqu'a sa refonte
// en CT-2, qui lira `DonneesControleurDemo.mission(etat)`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/controle/service_controle.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart' show Seance;
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import '../compte/compte_page.dart';
import '../controleur/echanges_controleur_page.dart';
import '../controleur/historique_controleur_page.dart';
import '../controleur/planning_page.dart';
import 'controleur_demo.dart';
import 'mode_demonstration.dart';
import 'repere_demonstration.dart';

/// Les routes de la demonstration controleur : AUCUNE en production.
List<RouteBase> routesDemoControleur(String environnement) {
  if (!environnementAutoriseDemo(environnement)) return const <RouteBase>[];
  return <RouteBase>[
    GoRoute(
      path: Routes.demoControleur,
      builder: (BuildContext _, GoRouterState etat) => DemoControleurPage(
        ecran: _lire(
          EcranDemoControleur.values,
          etat.uri.queryParameters['ecran'],
        ),
        etat:
            _lire(
              EtatDemoControleur.values,
              etat.uri.queryParameters['etat'],
            ) ??
            EtatDemoControleur.enDirect,
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

/// L'adresse d'un ecran de la demonstration.
String adresseDemoControleur(
  EcranDemoControleur ecran, {
  EtatDemoControleur etat = EtatDemoControleur.enDirect,
}) => Uri(
  path: Routes.demoControleur,
  queryParameters: <String, String>{'ecran': ecran.name, 'etat': etat.name},
).toString();

/// Le libelle d'un ecran : celui de sa destination dans la barre.
String libelleEcranDemoControleur(EcranDemoControleur ecran) =>
    switch (ecran) {
      EcranDemoControleur.controle => t.nav.controleur.controle,
      EcranDemoControleur.historique => t.nav.controleur.historique,
      EcranDemoControleur.echanges => t.nav.controleur.echanges,
      EcranDemoControleur.compte => t.nav.controleur.compte,
    };

/// Le libelle d'une situation.
String libelleEtatDemoControleur(EtatDemoControleur etat) => switch (etat) {
  EtatDemoControleur.aucune => t.controleur.demo.etatAucune,
  EtatDemoControleur.pasEncoreEnDirect =>
    t.controleur.demo.etatPasEncoreEnDirect,
  EtatDemoControleur.enDirect => t.controleur.demo.etatEnDirect,
  EtatDemoControleur.indisponible => t.controleur.demo.etatIndisponible,
};

/// La session de demonstration : un controleur resolu, sans source serveur.
class _SessionControleurDemo extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.controller,
    profileId: DonneesControleurDemo.controleurId,
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

/// Les surcharges de la coquille controleur : seuls les providers lus par
/// les pages sont remplaces, aucun port reseau.
List<Override> surchargesCoquilleControleurDemo(EtatDemoControleur etat) =>
    <Override>[
      sessionProvider.overrideWith(_SessionControleurDemo.new),
      horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
      // Le planning global, vide : il est remplace par la mission en CT-2
      // (C1, C3). Aucune lecture de `mes_seances_v`.
      planningGlobalProvider.overrideWith((Ref _) async => const <Seance>[]),
    ];

/// La page : la liste des ecrans, ou la coquille sur l'ecran choisi.
class DemoControleurPage extends StatelessWidget {
  /// Cree la page.
  const DemoControleurPage({
    this.ecran,
    this.etat = EtatDemoControleur.enDirect,
    super.key,
  });

  /// L'ecran choisi, ou nul pour la liste.
  final EcranDemoControleur? ecran;

  /// La situation de mission.
  final EtatDemoControleur etat;

  @override
  Widget build(BuildContext context) {
    final EcranDemoControleur? e = ecran;
    if (e != null) return CoquilleControleurDemo(ecran: e, etat: etat);

    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    Text texte(String valeur, {bool fort = false}) => Text(
      valeur,
      style: (fort ? palette.inkStrong : palette.inkMuted).applyTo(
        (fort ? textes.titleMedium : textes.bodyMedium) ?? const TextStyle(),
      ),
    );
    return PageShell(
      titre: t.controleur.demo.titre,
      sousTitre: t.controleur.demo.mention,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          texte(t.controleur.demo.intro),
          for (final EcranDemoControleur ecran
              in EcranDemoControleur.values) ...<Widget>[
            Ecart.vXxl,
            Semantics(
              header: true,
              child: texte(libelleEcranDemoControleur(ecran), fort: true),
            ),
            Ecart.vMd,
            for (final EtatDemoControleur etat in EtatDemoControleur.values)
              LienFleche(
                key: ValueKey<String>('lien-${ecran.name}-${etat.name}'),
                libelle: libelleEtatDemoControleur(etat),
                onPress: () =>
                    context.go(adresseDemoControleur(ecran, etat: etat)),
              ),
          ],
        ],
      ),
    );
  }
}

/// La VRAIE coquille controleur, sur la VRAIE page de [ecran], ses providers
/// surcharges par les donnees de demonstration.
class CoquilleControleurDemo extends StatelessWidget {
  /// Cree la coquille.
  const CoquilleControleurDemo({
    required this.ecran,
    this.etat = EtatDemoControleur.enDirect,
    super.key,
  });

  /// L'ecran affiche, donc la destination active.
  final EcranDemoControleur ecran;

  /// La situation de mission.
  final EtatDemoControleur etat;

  @override
  Widget build(BuildContext context) {
    final List<Destination> destinations = destinationsPour(
      role: AppRole.controller,
      mode: InterfaceMode.standard,
    );
    return ProviderScope(
      key: ValueKey<EtatDemoControleur>(etat),
      overrides: surchargesCoquilleControleurDemo(etat),
      child: RepereDemonstration(
        child: NavShell(
          destinations: destinations,
          indexActif: ecran.index,
          libellesDansLeRail: true,
          onAller: (String chemin) {
            final int i = destinations.indexWhere(
              (Destination d) => d.chemin == chemin,
            );
            if (i == -1) return;
            context.go(
              adresseDemoControleur(EcranDemoControleur.values[i], etat: etat),
            );
          },
          child: switch (ecran) {
            EcranDemoControleur.controle => const PlanningControleurPage(),
            EcranDemoControleur.historique => const HistoriqueControleurPage(),
            EcranDemoControleur.echanges => const EchangesControleurPage(),
            EcranDemoControleur.compte => const ComptePage(),
          },
        ),
      ),
    );
  }
}
