// La coquille enseignant en demonstration : /demo/enseignant (hors production,
// EN-1b).
//
// Sans parametre : les liens ecran x situation. Avec `ecran` (aujourdhui,
// classes, disponibilites, profil) et `etat` (nominal, vide, horsLigne) : la
// VRAIE coquille (`NavShell`, destinations de `destinationsPour`) et la VRAIE
// page de la destination, ses providers surcharges par un ProviderScope sur
// les donnees d'enseignant_demo.dart (K-35). Les fournisseurs reels restent en
// place, aucun port reseau n'est modifie : aucun appel serveur (K-28).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/matching/service_matching.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/priere/service_priere.dart';
import '../../core/profil/service_acceptations.dart';
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/regles/service_regles.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/pre_vol.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import '../creneaux/creneaux_page.dart';
import '../enseignant_classes/mes_classes_page.dart';
import '../journee/journee_page.dart';
import '../profil_enseignant/profil_enseignant_page.dart';
import 'enseignant_demo.dart';
import 'mode_demonstration.dart';
import 'repere_demonstration.dart';

/// Les routes de la demonstration enseignant : AUCUNE en production.
List<RouteBase> routesDemoEnseignant(String environnement) {
  if (!environnementAutoriseDemo(environnement)) return const <RouteBase>[];
  return <RouteBase>[
    GoRoute(
      path: Routes.demoEnseignant,
      builder: (BuildContext _, GoRouterState etat) => DemoEnseignantPage(
        ecran: _lire(
          EcranDemoEnseignant.values,
          etat.uri.queryParameters['ecran'],
        ),
        etat:
            _lire(
              EtatDemoEnseignant.values,
              etat.uri.queryParameters['etat'],
            ) ??
            EtatDemoEnseignant.nominal,
        titre: etat.uri.queryParameters['titre'] == 'sayyida'
            ? TitreEnseignant.sayyida
            : TitreEnseignant.sayyid,
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
String adresseDemoEnseignant(
  EcranDemoEnseignant ecran, {
  EtatDemoEnseignant etat = EtatDemoEnseignant.nominal,
}) => Uri(
  path: Routes.demoEnseignant,
  queryParameters: <String, String>{'ecran': ecran.name, 'etat': etat.name},
).toString();

/// Le libelle d'un ecran : celui de sa destination dans la barre.
String libelleEcranDemoEnseignant(EcranDemoEnseignant ecran) => switch (ecran) {
  EcranDemoEnseignant.aujourdhui => t.nav.enseignant.journee,
  EcranDemoEnseignant.classes => t.nav.enseignant.classes,
  EcranDemoEnseignant.disponibilites => t.nav.enseignant.creneaux,
  EcranDemoEnseignant.profil => t.nav.enseignant.profil,
};

/// Le libelle d'une situation.
String libelleEtatDemoEnseignant(EtatDemoEnseignant etat) => switch (etat) {
  EtatDemoEnseignant.nominal => t.enseignant.demo.etatNominal,
  EtatDemoEnseignant.vide => t.enseignant.demo.etatVide,
  EtatDemoEnseignant.horsLigne => t.enseignant.demo.etatHorsLigne,
};

/// La session de demonstration : un enseignant resolu, sans source serveur.
class _SessionEnseignantDemo extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.teacher,
    profileId: DonneesEnseignantDemo.enseignantId,
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

/// Les surcharges de la coquille enseignant pour une situation : seuls les
/// providers lus par les pages sont remplaces, aucun port reseau.
///
/// Les familles sont surchargees a leur argument exact : sous un ProviderScope
/// imbrique, une famille non surchargee se resoudrait dans le conteneur
/// racine, ou la session n'a pas d'enseignant.
List<Override> surchargesCoquilleEnseignantDemo(EtatDemoEnseignant etat) {
  const String id = DonneesEnseignantDemo.enseignantId;
  final bool vide = etat == EtatDemoEnseignant.vide;
  final List<SeanceEnseignant> seances = DonneesEnseignantDemo.seances(etat);
  return <Override>[
    sessionProvider.overrideWith(_SessionEnseignantDemo.new),
    horsLigneProvider.overrideWith(
      (Ref _) => Stream<bool>.value(etat == EtatDemoEnseignant.horsLigne),
    ),
    // Aujourd'hui (ENS-02).
    seancesEnseignantProvider.overrideWith((Ref _) async => seances),
    cahiersEnRetardProvider.overrideWith(
      (Ref _) async => DonneesEnseignantDemo.cahiersEnRetard(etat),
    ),
    elevesEnAttenteProvider.overrideWith(
      (Ref _) async => const <EleveEnAttente>[],
    ),
    reglagesPriereProvider(id).overrideWith((Ref _) async => null),
    valeurRegleProvider((profilId: id, cle: CleRegle.pauseEntreCours))
        .overrideWith((Ref _) async => 10),
    preVolProvider.overrideWith(
      (Ref _) async => const ResultatPreVol(
        microDisponible: true,
        cameraDisponible: true,
        sortieAudioDisponible: true,
        permissionRefusee: false,
      ),
    ),
    for (final SeanceEnseignant s in seances)
      presenceSeanceProvider(
        s.id,
      ).overrideWith((Ref _) => Stream<List<PresenceParticipant>?>.value(null)),
    // Disponibilites (ENS-06), hebdomadaires et sans date (E15).
    monFuseauProvider.overrideWith(
      (Ref _) async => DonneesEnseignantDemo.fuseau,
    ),
    disponibilitesProvider(id).overrideWith(
      (Ref _) async =>
          vide ? const <Creneau>[] : DonneesEnseignantDemo.disponibilites,
    ),
    affectationsProvider.overrideWith((Ref _) async => const <Affectation>[]),
    // Profil (ENS-05).
    profilEnseignantProvider.overrideWith(
      (Ref _) async => DonneesEnseignantDemo.profil,
    ),
    acceptationsProvider.overrideWith((Ref _) async => const <Acceptation>[]),
  ];
}

/// La page : la liste des ecrans, ou la coquille sur l'ecran choisi.
class DemoEnseignantPage extends StatelessWidget {
  /// Cree la page.
  const DemoEnseignantPage({
    this.ecran,
    this.etat = EtatDemoEnseignant.nominal,
    this.titre = TitreEnseignant.sayyid,
    super.key,
  });

  /// L'ecran choisi, ou nul pour la liste.
  final EcranDemoEnseignant? ecran;

  /// La situation.
  final EtatDemoEnseignant etat;

  /// Le titre de l'enseignant : Sayyid par defaut, Sayyida en variante.
  final TitreEnseignant titre;

  @override
  Widget build(BuildContext context) {
    final EcranDemoEnseignant? e = ecran;
    if (e != null) return CoquilleEnseignantDemo(ecran: e, etat: etat);

    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    Text texte(String valeur, {bool fort = false}) => Text(
      valeur,
      style: (fort ? palette.inkStrong : palette.inkMuted).applyTo(
        (fort ? textes.titleMedium : textes.bodyMedium) ?? const TextStyle(),
      ),
    );
    return PageShell(
      titre: t.enseignant.demo.titre,
      sousTitre: t.enseignant.demo.mention,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          texte(t.enseignant.demo.intro),
          for (final EcranDemoEnseignant ecran
              in EcranDemoEnseignant.values) ...<Widget>[
            Ecart.vXxl,
            Semantics(
              header: true,
              child: texte(libelleEcranDemoEnseignant(ecran), fort: true),
            ),
            Ecart.vMd,
            for (final EtatDemoEnseignant etat in EtatDemoEnseignant.values)
              LienFleche(
                key: ValueKey<String>('lien-${ecran.name}-${etat.name}'),
                libelle: libelleEtatDemoEnseignant(etat),
                onPress: () =>
                    context.go(adresseDemoEnseignant(ecran, etat: etat)),
              ),
          ],
        ],
      ),
    );
  }
}

/// La VRAIE coquille enseignant, sur la VRAIE page de [ecran], ses providers
/// surcharges par les donnees de demonstration.
class CoquilleEnseignantDemo extends StatelessWidget {
  /// Cree la coquille.
  const CoquilleEnseignantDemo({
    required this.ecran,
    this.etat = EtatDemoEnseignant.nominal,
    super.key,
  });

  /// L'ecran affiche, donc la destination active.
  final EcranDemoEnseignant ecran;

  /// La situation.
  final EtatDemoEnseignant etat;

  @override
  Widget build(BuildContext context) {
    final List<Destination> destinations = destinationsPour(
      role: AppRole.teacher,
      mode: InterfaceMode.standard,
    );
    return ProviderScope(
      key: ValueKey<EtatDemoEnseignant>(etat),
      overrides: surchargesCoquilleEnseignantDemo(etat),
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
              adresseDemoEnseignant(EcranDemoEnseignant.values[i], etat: etat),
            );
          },
          child: switch (ecran) {
            EcranDemoEnseignant.aujourdhui => const JourneePage(),
            EcranDemoEnseignant.classes => const MesClassesPage(),
            EcranDemoEnseignant.disponibilites => const CreneauxPage(),
            EcranDemoEnseignant.profil => const ProfilEnseignantPage(),
          },
        ),
      ),
    );
  }
}
