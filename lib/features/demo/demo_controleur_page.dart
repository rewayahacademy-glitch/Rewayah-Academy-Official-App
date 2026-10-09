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
import '../../core/reseau/service_reseau.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import '../compte/compte_page.dart';
import '../compte/espaces_compte.dart';
import '../controleur/compte_rendu_controle.dart';
import '../controleur/compte_rendu_controle_page.dart';
import '../controleur/controle_page.dart';
import '../controleur/echanges_controleur.dart';
import '../controleur/echanges_controleur_page.dart';
import '../controleur/garde_controle.dart';
import '../controleur/historique_controleur.dart';
import '../controleur/historique_controleur_page.dart';
import '../controleur/mission_controle.dart';
import '../controleur/observation_controle.dart';
import '../controleur/observation_controle_page.dart';
import 'controleur_demo.dart';
import 'espaces_controleur_demo.dart';
import 'historique_controleur_demo.dart';
import 'mode_demonstration.dart';
import 'repere_demonstration.dart';
import 'salle_observateur_demo.dart';

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
        fil: etat.uri.queryParameters['fil'],
        espaces: SituationEspacesDemo.lire(etat.uri.queryParameters),
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
      builder: (BuildContext contexte, GoRouterState etat) {
        // CT-9 : `etat=indisponible` montre la mission retiree pendant le
        // compte rendu (P-CTR-08) ; la mission est en cours (§4.2) et le
        // retour garde le profil de demonstration.
        final SituationEspacesDemo espaces = SituationEspacesDemo.lire(
          etat.uri.queryParameters,
        );
        return ProviderScope(
          overrides: <Override>[
            ...surchargesCoquilleControleurDemo(
              _lire(
                    EtatDemoControleur.values,
                    etat.uri.queryParameters['etat'],
                  ) ??
                  EtatDemoControleur.enDirect,
              profil: espaces.controleur,
            ),
            ...surchargesEspacesDemo(espaces.enMission()),
            faitsVisiteProvider.overrideWith(
              (Ref _) async => faitsVisiteDemoControleur(),
            ),
            ..._visitesDemo(),
          ],
          child: RepereDemonstration(
            child: GardeControle(
              child: CompteRenduControlePage(
                seanceId: _seanceDemo(etat),
                onRevenir: () => contexte.go(
                  adresseDemoControleur(
                    EcranDemoControleur.controle,
                    espaces: espaces.vers(principal: false),
                  ),
                ),
                onObservation: (ChoixCompteRendu choix, String seance) =>
                    contexte.go(
                      adresseObservation(
                        cheminDemoObservationControleur,
                        choix,
                        seanceId: seance,
                      ),
                    ),
                onEcrireAdmin: (String? _) =>
                    contexte.go(adresseFilMissionDemoControleur()),
              ),
            ),
          ),
        );
      },
    ),
    // CTR-03A (CT-5) : l'observation structuree, roster de demonstration
    // (prenoms seuls, C8), envoi simule, aucun serveur.
    GoRoute(
      path: cheminDemoObservationControleur,
      builder: (BuildContext contexte, GoRouterState etat) => ProviderScope(
        overrides: <Override>[
          ...surchargesCoquilleControleurDemo(EtatDemoControleur.enDirect),
          rosterControleProvider.overrideWith(
            (Ref _) async => rosterDemoControleur(),
          ),
          ..._visitesDemo(),
        ],
        child: RepereDemonstration(
          child: ObservationControlePage(
            seanceId: _seanceDemo(etat),
            choix: choixObservationDepuis(etat.uri.queryParameters, etat.extra),
            onRetour: () => contexte.go(
              adresseCompteRendu(
                cheminDemoCompteRenduControleur,
                _seanceDemo(etat),
              ),
            ),
            onRevenir: () => contexte.go(
              adresseDemoControleur(EcranDemoControleur.controle),
            ),
            onEcrireAdmin: (String? _) =>
                contexte.go(adresseFilMissionDemoControleur()),
          ),
        ),
      ),
    ),
  ];
}

/// La visite de demonstration : la mission en direct, copiee a l'entree en
/// salle (revue CT-R B1).
CompteRenduEnSuspens visiteDemoControleur() => CompteRenduEnSuspens.deMission(
  missionDemoControleur(EtatDemoControleur.enDirect)!,
);

/// La seance de l'adresse, sinon celle de la visite de demonstration (liens
/// directs de la liste de demonstration).
String _seanceDemo(GoRouterState etat) =>
    etat.uri.queryParameters['seance'] ?? visiteDemoControleur().seanceId;

/// La visite de demonstration, toujours connue des ecrans du compte rendu.
List<Override> _visitesDemo() {
  final CompteRenduEnSuspens v = visiteDemoControleur();
  return <Override>[
    visitesObserveesProvider.overrideWith(
      () => VisitesObservees(<String, CompteRenduEnSuspens>{v.seanceId: v}),
    ),
  ];
}

/// Le roster autorise de demonstration : prenom seul (C8), identifiant
/// pedagogique fictif.
List<EleveRoster> rosterDemoControleur() => <EleveRoster>[
  for (final (int i, String prenom) in DonneesControleurDemo.roster.indexed)
    EleveRoster(id: 'demo-eleve-$i', prenom: prenom),
];

/// L'observation structuree (CTR-03A) en demonstration.
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
  Future<void> transmettreVisite(String seanceId) =>
      Future<void>.delayed(const Duration(milliseconds: 400));

  @override
  Future<void> envoyer(String seanceId, ChoixCompteRendu choix) =>
      Future<void>.delayed(const Duration(milliseconds: 400));

  @override
  Future<void> envoyerObservation(
    String seanceId,
    ObservationControle observation,
  ) => Future<void>.delayed(const Duration(milliseconds: 400));
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

  // TB-11a : une seule salle d'observateur en demonstration
  // (`SalleObservateurDemo`), ici en role controleur, sans presentation.
  @override
  Widget build(BuildContext context) => SalleObservateurDemo(
    observateur: ObservateurDemo.controleur,
    seanceId: seanceId,
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
  String? fil,
  SituationEspacesDemo espaces = const SituationEspacesDemo(),
}) => Uri(
  path: Routes.demoControleur,
  queryParameters: <String, String>{
    'ecran': ecran.name,
    'etat': etat.name,
    'fil': ?fil,
    ...espaces.parametres,
  },
).toString();

/// « Ecrire a l'administration » (P-CTR-06) : le fil de la mission en direct
/// de la demonstration, dans Echanges.
String adresseFilMissionDemoControleur() => adresseDemoControleur(
  EcranDemoControleur.echanges,
  fil: DonneesControleurDemo.mission(EtatDemoControleur.enDirect)!.id,
);

/// Les echanges de demonstration (CT-6) : les fils de
/// [DonneesControleurDemo.fils], en memoire ; l'envoi repond apres un court
/// delai, rien ne part (K-28). Le fil d'une mission sans fil nait vide,
/// comme le fil canonique cree par le serveur (P-CTR-06).
class EchangesDemo implements PortEchanges {
  /// Cree le port, sur les fils de demonstration.
  EchangesDemo()
    : _fils = <FilEchange>[
        for (final FilAdminDemo f in DonneesControleurDemo.fils)
          FilEchange(
            id: f.id,
            missionId: f.missionId,
            classe: f.classe,
            debutMission: f.debutMission,
            etat: switch (f.etat) {
              EtatFilDemo.reponseRecue => EtatFilEchange.reponseRecue,
              EtatFilDemo.enAttente => EtatFilEchange.enAttente,
            },
            messages: <MessageEchange>[
              for (final (int i, MessageFilDemo m) in f.messages.indexed)
                MessageEchange(
                  id: '${f.id}-$i',
                  auteur: switch (m.auteur) {
                    AuteurMessageDemo.controleur => AuteurEchange.controleur,
                    AuteurMessageDemo.administration =>
                      AuteurEchange.administration,
                  },
                  texte: m.texte,
                  date: m.date,
                ),
            ],
          ),
      ];

  final List<FilEchange> _fils;

  static const Duration _delai = Duration(milliseconds: 400);

  @override
  Future<List<FilEchange>> fils() async {
    await Future<void>.delayed(_delai);
    return <FilEchange>[
      for (final FilEchange f in _fils)
        if (f.messages.isNotEmpty) f,
    ]..sort(
      (FilEchange a, FilEchange b) =>
          b.derniereActivite.compareTo(a.derniereActivite),
    );
  }

  @override
  Future<FilEchange> filDeMission(String missionId) async {
    await Future<void>.delayed(_delai);
    for (final FilEchange f in _fils) {
      if (f.missionId == missionId) return f;
    }
    final MissionControleurDemo? m = DonneesControleurDemo.mission(
      EtatDemoControleur.enDirect,
    );
    // Une mission passee de l'Historique (CT-7) a aussi son fil canonique.
    final RapportControleurDemo? r = DonneesControleurDemo.rapports
        .where((RapportControleurDemo r) => r.missionId == missionId)
        .firstOrNull;
    final (String classe, DateTime debut) = switch ((m, r)) {
      (final MissionControleurDemo m, _) when m.id == missionId => (
        m.classe,
        m.debut,
      ),
      (_, final RapportControleurDemo r) => (r.classe, r.date),
      _ => throw StateError('Mission inconnue de la demonstration.'),
    };
    final FilEchange nouveau = FilEchange(
      id: 'demo-fil-$missionId',
      missionId: missionId,
      classe: classe,
      debutMission: debut,
      etat: EtatFilEchange.enAttente,
      messages: const <MessageEchange>[],
    );
    _fils.add(nouveau);
    return nouveau;
  }

  @override
  Future<void> envoyer(String filId, String texte) async {
    await Future<void>.delayed(_delai);
    final int i = _fils.indexWhere((FilEchange f) => f.id == filId);
    if (i == -1) throw StateError('Fil inconnu de la demonstration.');
    final FilEchange f = _fils[i];
    _fils[i] = FilEchange(
      id: f.id,
      missionId: f.missionId,
      classe: f.classe,
      debutMission: f.debutMission,
      etat: EtatFilEchange.enAttente,
      messages: <MessageEchange>[
        ...f.messages,
        MessageEchange(
          id: '${f.id}-${f.messages.length}',
          auteur: AuteurEchange.controleur,
          texte: texte,
          date: DateTime.now(),
        ),
      ],
    );
  }
}

/// Le libelle d'un ecran : celui de sa destination dans la barre.
String libelleEcranDemoControleur(EcranDemoControleur ecran) => switch (ecran) {
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
  EtatDemoControleur.dejaControlee => t.controleur.demo.etatDejaControlee,
  EtatDemoControleur.indisponible => t.controleur.demo.etatIndisponible,
};

/// La session de demonstration : un controleur resolu, sans source serveur.
class _SessionControleurDemo extends SessionControleur {
  _SessionControleurDemo([this._id = DonneesControleurDemo.controleurId]);

  final String _id;

  @override
  SessionState build() => SessionState(
    resolue: true,
    role: AppRole.controller,
    profileId: _id,
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

/// Les surcharges de la coquille controleur : seuls les providers lus par
/// les pages sont remplaces, aucun port reseau.
///
/// [profil] (CT-9) : le compte de la session ; la mission est celle que le
/// serveur lui attribuerait, jamais sa propre Classe.
List<Override> surchargesCoquilleControleurDemo(
  EtatDemoControleur etat, {
  ControleurDemo? profil,
}) => <Override>[
  sessionProvider.overrideWith(
    () => profil == null
        ? _SessionControleurDemo()
        : _SessionControleurDemo(profil.id),
  ),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
  // La mission de la situation (CT-2) : une seule, jamais un planning
  // (C1, C3). Aucune lecture serveur.
  missionControleProvider.overrideWith(
    (Ref _) async => profil == null
        ? missionDemoControleur(etat)
        : missionAttribueeDemo(etat, profil),
  ),
  // Transmission et envoi simules (CT-4) : rien ne part, la reponse
  // arrive apres un court delai. Lu aussi par « Reessayer » du Controle.
  envoiCompteRenduProvider.overrideWithValue(const EnvoiCompteRenduDemo()),
  // Echanges simules (CT-6) : fils en memoire, envoi sans serveur.
  portEchangesProvider.overrideWith((Ref _) => EchangesDemo()),
  // Historique simule (CT-7) : rapports en memoire, aucun serveur.
  portHistoriqueProvider.overrideWithValue(const HistoriqueDemo()),
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
    id: m.id,
    seanceId: m.seanceId,
    classe: m.classe,
    enseignant: '$titre ${m.enseignant}',
    nombreEleves: m.nombreEleves,
    debut: m.debut,
    finPrevue: m.finPrevue,
    etat: switch (m.etat) {
      EtatMissionDemo.prevue => EtatMissionControle.prevue,
      EtatMissionDemo.enDirect => EtatMissionControle.enDirect,
      EtatMissionDemo.dejaControlee => EtatMissionControle.dejaControlee,
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
    this.fil,
    this.espaces = const SituationEspacesDemo(),
    super.key,
  });

  /// Le profil et l'espace (CT-9).
  final SituationEspacesDemo espaces;

  /// La mission dont le fil d'Echanges s'ouvre, ou nulle.
  final String? fil;

  /// L'ecran choisi, ou nul pour la liste.
  final EcranDemoControleur? ecran;

  /// La situation de mission.
  final EtatDemoControleur etat;

  @override
  Widget build(BuildContext context) {
    final EcranDemoControleur? e = ecran;
    // L'espace principal de l'Enseignant-Controleur ou de l'Admin-Controleur
    // (CT-9) : sa coquille, autour de Compte.
    if (e != null &&
        espaces.espacePrincipal &&
        espaces.profil != ProfilDemoControleur.externe) {
      return EspacePrincipalDemo(situation: espaces);
    }
    if (e != null) {
      return CoquilleControleurDemo(
        ecran: e,
        etat: etat,
        fil: fil,
        espaces: espaces,
      );
    }

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
          // CT-9 : commutation d'espaces et etats transverses.
          Ecart.vXxl,
          Semantics(
            header: true,
            child: texte(t.controleur.demo.espaces, fort: true),
          ),
          Ecart.vSm,
          texte(t.controleur.demo.espacesIntro),
          Ecart.vMd,
          for (final (String cle, String libelle, String adresse)
              in _liensEspaces())
            LienFleche(
              key: ValueKey<String>('lien-espaces-$cle'),
              libelle: libelle,
              onPress: () => context.go(adresse),
            ),
        ],
      ),
    );
  }
}

/// Les liens de la section « Espaces et acces » (CT-9).
List<(String, String, String)> _liensEspaces() {
  const SituationEspacesDemo enseignant = SituationEspacesDemo(
    profil: ProfilDemoControleur.enseignant,
  );
  const SituationEspacesDemo admin = SituationEspacesDemo(
    profil: ProfilDemoControleur.admin,
  );
  final d = t.controleur.demo;
  return <(String, String, String)>[
    (
      'enseignant-controle',
      d.enseignantControle,
      adresseDemoControleur(EcranDemoControleur.controle, espaces: enseignant),
    ),
    (
      'enseignant-principal',
      d.enseignantPrincipal,
      adresseDemoControleur(
        EcranDemoControleur.compte,
        espaces: enseignant.vers(principal: true),
      ),
    ),
    (
      'admin-controle',
      d.adminControle,
      adresseDemoControleur(EcranDemoControleur.controle, espaces: admin),
    ),
    (
      'admin-principal',
      d.adminPrincipal,
      adresseDemoControleur(
        EcranDemoControleur.compte,
        espaces: admin.vers(principal: true),
      ),
    ),
    (
      'mission-en-cours',
      d.missionEnCours,
      adresseDemoControleur(
        EcranDemoControleur.compte,
        espaces: enseignant.enMission(),
      ),
    ),
    (
      'acces-revoque',
      d.accesRevoque,
      adresseDemoControleur(
        EcranDemoControleur.historique,
        espaces: const SituationEspacesDemo(
          profil: ProfilDemoControleur.enseignant,
          acces: AccesDemoControleur.revoque,
        ),
      ),
    ),
    (
      'sans-capacite',
      d.sansCapacite,
      adresseDemoControleur(
        EcranDemoControleur.controle,
        espaces: const SituationEspacesDemo(
          profil: ProfilDemoControleur.enseignant,
          acces: AccesDemoControleur.sansCapacite,
        ),
      ),
    ),
    (
      'compte-rendu-indisponible',
      d.compteRenduIndisponible,
      Uri(
        path: cheminDemoCompteRenduControleur,
        queryParameters: <String, String>{
          'etat': EtatDemoControleur.indisponible.name,
        },
      ).toString(),
    ),
  ];
}

/// La VRAIE coquille controleur, sur la VRAIE page de [ecran], ses providers
/// surcharges par les donnees de demonstration.
class CoquilleControleurDemo extends StatelessWidget {
  /// Cree la coquille.
  const CoquilleControleurDemo({
    required this.ecran,
    this.etat = EtatDemoControleur.enDirect,
    this.fil,
    this.espaces = const SituationEspacesDemo(),
    super.key,
  });

  /// Le profil, la mission en cours et l'acces (CT-9).
  final SituationEspacesDemo espaces;

  /// La mission dont le fil d'Echanges s'ouvre, ou nulle pour la liste.
  final String? fil;

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
      key: ValueKey<String>('${etat.name}-${espaces.parametres}'),
      overrides: <Override>[
        ...surchargesCoquilleControleurDemo(etat, profil: espaces.controleur),
        ...surchargesEspacesDemo(espaces),
      ],
      child: RepereDemonstration(
        // CT-9 : l'espace Controle est garde (C7) ; le raccourci d'en-tete
        // ouvre `Compte > Espaces` quand le compte en a plusieurs (C6).
        child: GardeControle(
          child: EnteteEspaces(
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
                  adresseDemoControleur(
                    EcranDemoControleur.values[i],
                    etat: etat,
                    espaces: espaces,
                  ),
                );
              },
              child: switch (ecran) {
                EcranDemoControleur.controle => ControleControleurPage(
                  onCommencer: (MissionControle m) => context.go(
                    cheminDemoSalleControleur,
                    extra: BilletSalle(
                      sessionId: m.seanceId,
                      emisA: DateTime.now(),
                    ),
                  ),
                  onReprendreCompteRendu: (String seance) => context.go(
                    adresseCompteRendu(
                      cheminDemoCompteRenduControleur,
                      seance,
                      autres: espaces.parametres,
                    ),
                  ),
                ),
                EcranDemoControleur.historique => HistoriqueControleurPage(
                  maintenant: DonneesControleurDemo.maintenant,
                  onReprendreCompteRendu: (String seance) => context.go(
                    adresseCompteRendu(
                      cheminDemoCompteRenduControleur,
                      seance,
                      autres: espaces.parametres,
                    ),
                  ),
                  onEcrireAdmin: (String mission) => context.go(
                    adresseDemoControleur(
                      EcranDemoControleur.echanges,
                      etat: etat,
                      fil: mission,
                      espaces: espaces,
                    ),
                  ),
                ),
                EcranDemoControleur.echanges => EchangesControleurPage(
                  key: ValueKey<String?>(fil),
                  missionOuverte: fil,
                ),
                EcranDemoControleur.compte => const ComptePage(),
              },
            ),
          ),
        ),
      ),
    );
  }
}
