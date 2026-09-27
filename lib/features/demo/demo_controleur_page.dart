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
// Controle (CT-2) lit `DonneesControleurDemo.mission(etat)` : une seule
// carte de mission, jamais un planning (C1).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/presence/service_presence.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/pre_vol.dart';
import '../../core/video/service_video.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import '../compte/compte_page.dart';
import '../controleur/compte_rendu_controle.dart';
import '../controleur/compte_rendu_controle_page.dart';
import '../controleur/controle_page.dart';
import '../controleur/echanges_controleur_page.dart';
import '../controleur/historique_controleur_page.dart';
import '../controleur/mission_controle.dart';
import '../salle/salle_page.dart';
import 'controleur_demo.dart';
import 'mode_demonstration.dart';
import 'repere_demonstration.dart';
import 'salle_controleur_demo.dart';

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
    // CTR-02 (CT-3) : la VRAIE salle, en role controleur, sans serveur.
    GoRoute(
      path: cheminDemoSalleControleur,
      builder: (BuildContext _, GoRouterState etat) => SalleControleurDemo(
        seanceId: etat.extra is BilletSalle
            ? (etat.extra! as BilletSalle).sessionId
            : 'demo-controle',
      ),
    ),
    // CTR-03 (CT-4) : la sortie de la salle, faits et envoi de
    // demonstration, aucun serveur.
    GoRoute(
      path: cheminDemoCompteRenduControleur,
      builder: (BuildContext contexte, GoRouterState _) => ProviderScope(
        overrides: <Override>[
          ...surchargesCoquilleControleurDemo(EtatDemoControleur.enDirect),
          faitsVisiteProvider.overrideWith(
            (Ref _) async => faitsVisiteDemoControleur(),
          ),
          envoiCompteRenduProvider.overrideWithValue(
            const EnvoiCompteRenduDemo(),
          ),
        ],
        child: RepereDemonstration(
          child: CompteRenduControlePage(
            onRevenir: () => contexte.go(
              adresseDemoControleur(EcranDemoControleur.controle),
            ),
            onObservation: (ChoixCompteRendu _) =>
                contexte.go(cheminDemoObservationControleur),
            onEcrireAdmin: () => contexte.go(
              adresseDemoControleur(EcranDemoControleur.echanges),
            ),
          ),
        ),
      ),
    ),
    // CTR-03A provisoire (CT-5 le construit).
    GoRoute(
      path: cheminDemoObservationControleur,
      builder: (BuildContext contexte, GoRouterState _) => RepereDemonstration(
        child: ObservationControlePage(
          onRetour: () => contexte.go(cheminDemoCompteRenduControleur),
        ),
      ),
    ),
  ];
}

/// L'observation provisoire en demonstration.
const String cheminDemoObservationControleur =
    '${Routes.demoControleur}/compte-rendu/observation';

/// Les faits de la seance en direct, dans le modele de CTR-03.
FaitsVisite faitsVisiteDemoControleur() {
  final FaitsAutomatiquesDemo f = DonneesControleurDemo.faitsEnDirect;
  return FaitsVisite(
    debutPrevu: f.debutPrevu,
    finPrevue: f.debutPrevu.add(f.dureePrevue),
    debutReel: f.debutReel,
    finReelle: f.finReelle,
    participantsAttendus: f.participantsAttendus,
    participantsPresents: f.participantsPresents,
    reconnexions: f.reconnexions,
  );
}

/// L'envoi de demonstration : rien ne part ; la reponse arrive apres un court
/// delai, comme celle d'un serveur (K-28).
class EnvoiCompteRenduDemo implements EnvoiCompteRendu {
  /// Cree le port.
  const EnvoiCompteRenduDemo();

  @override
  Future<void> envoyer(ChoixCompteRendu choix) =>
      Future<void>.delayed(const Duration(milliseconds: 400));
}

/// La salle du controleur en demonstration.
const String cheminDemoSalleControleur = '${Routes.demoControleur}/salle';

/// Le compte rendu provisoire en demonstration.
const String cheminDemoCompteRenduControleur =
    '${Routes.demoControleur}/compte-rendu';

/// La VRAIE salle (`SallePage`) en role controleur : ses ports remplaces
/// par les doubles de `salle_controleur_demo.dart`, aucun appel serveur.
class SalleControleurDemo extends StatelessWidget {
  /// Cree la salle.
  const SalleControleurDemo({required this.seanceId, super.key});

  /// La seance de la mission.
  final String seanceId;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: <Override>[
      ...surchargesCoquilleControleurDemo(EtatDemoControleur.enDirect),
      moteurSalleProvider.overrideWith(
        (Ref _) => MoteurSalleControleurDemo(),
      ),
      serviceVideoProvider.overrideWithValue(
        const ServiceVideoControleurDemo(),
      ),
      servicePreVolProvider.overrideWithValue(const PreVolControleurDemo()),
      // Les lecteurs derives sont surcharges aussi : sans declaration de
      // dependances, ils vivraient dans le conteneur racine et liraient les
      // vrais ports (Riverpod, portee imbriquee).
      preVolProvider.overrideWith(
        (Ref _) => const PreVolControleurDemo().verifier(),
      ),
      presenceSeanceProvider.overrideWith(
        (Ref _, String _) => Stream<List<PresenceParticipant>?>.value(null),
      ),
      servicePresenceProvider.overrideWithValue(
        const PresenceControleurDemo(),
      ),
    ],
    child: RepereDemonstration(
      child: SallePage(
        seanceId: seanceId,
        cheminCompteRenduControle: cheminDemoCompteRenduControleur,
      ),
    ),
  );
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
      // La mission de la situation (CT-2) : une seule, jamais un planning
      // (C1, C3). Aucune lecture serveur.
      missionControleProvider.overrideWith(
        (Ref _) async => missionDemoControleur(etat),
      ),
    ];

/// La mission de demonstration de [etat], dans le modele de CTR-01.
MissionControle? missionDemoControleur(EtatDemoControleur etat) {
  final MissionControleurDemo? m = DonneesControleurDemo.mission(etat);
  if (m == null) return null;
  final String titre = switch (m.titreEnseignant) {
    TitreEnseignant.sayyid => LibellesGroupe.sayyid,
    TitreEnseignant.sayyida => LibellesGroupe.sayyida,
  };
  return MissionControle(
    seanceId: m.seanceId,
    classe: m.classe,
    enseignant: '$titre ${m.enseignant}',
    nombreEleves: m.nombreEleves,
    debut: m.debut,
    finPrevue: m.finPrevue,
    etat: switch (m.etat) {
      EtatMissionDemo.prevue => EtatMissionControle.prevue,
      EtatMissionDemo.enDirect => EtatMissionControle.enDirect,
      EtatMissionDemo.indisponible => EtatMissionControle.indisponible,
    },
  );
}

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
            EcranDemoControleur.controle => ControleControleurPage(
              onCommencer: (MissionControle m) => context.go(
                cheminDemoSalleControleur,
                extra: BilletSalle(sessionId: m.seanceId, emisA: DateTime.now()),
              ),
              onReprendreCompteRendu: () =>
                  context.go(cheminDemoCompteRenduControleur),
            ),
            EcranDemoControleur.historique => const HistoriqueControleurPage(),
            EcranDemoControleur.echanges => const EchangesControleurPage(),
            EcranDemoControleur.compte => const ComptePage(),
          },
        ),
      ),
    );
  }
}
