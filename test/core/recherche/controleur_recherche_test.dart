// RECH-1 : la machine d'etats de la recherche, sur le port de demonstration
// (spec RECH-03 §5, §6, §8.3 ; SEC-R05, R07, R08, R09, R18, R21).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/recherche/budgets_recherche.dart';
import 'package:rewayah_academy/core/recherche/controleur_recherche.dart';
import 'package:rewayah_academy/core/recherche/corpus_demo_recherche.dart';
import 'package:rewayah_academy/core/recherche/etat_recherche.dart';
import 'package:rewayah_academy/core/recherche/modeles_recherche.dart';
import 'package:rewayah_academy/core/recherche/moteur_recherche_demo.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';

import '../../support/harnais.dart';

const ContexteRecherche _famille = ContexteRecherche(
  espace: EspaceRecherche.famille,
);

const Set<EspaceRecherche> _tous = <EspaceRecherche>{
  EspaceRecherche.famille,
  EspaceRecherche.eleve,
  EspaceRecherche.enseignant,
};

SessionState _session({
  String profil = 'p1',
  AppRole role = AppRole.guardian,
}) => SessionState(
  resolue: true,
  profileId: profil,
  householdId: 'h1',
  role: role,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

class _ServiceReseauHorsLigne implements ServiceReseau {
  @override
  Stream<bool> horsLigne() => Stream<bool>.value(true);
}

MoteurRechercheDemo _moteur(
  DomaineRecherche domaine, {
  List<EntreeCorpusDemo>? corpus,
  Set<EspaceRecherche> espaces = _tous,
  ComportementDemo comportement = ComportementDemo.normal,
  Duration latence = Duration.zero,
}) => MoteurRechercheDemo(
  domaine: domaine,
  corpus: corpus ?? corpusClassesDemo(nombre: 400),
  espaces: espaces,
  comportement: comportement,
  latence: latence,
);

ProviderContainer _ouvrir(
  List<MoteurRechercheDomaine> moteurs, {
  FausseSourceSession? source,
  bool horsLigne = false,
  ContexteRecherche contexte = _famille,
}) {
  final ProviderContainer c = ProviderContainer(
    overrides: [
      moteursRechercheProvider.overrideWithValue(moteurs),
      sourceSessionProvider.overrideWithValue(
        source ?? FausseSourceSession(_session()),
      ),
      portCapaciteEleveProvider.overrideWithValue(
        const PortCapaciteEleveInconnu(),
      ),
      if (horsLigne)
        serviceReseauProvider.overrideWithValue(_ServiceReseauHorsLigne()),
    ],
  );
  addTearDown(c.dispose);
  c.listen(sessionProvider, (_, _) {});
  c.listen(rechercheControleurProvider(contexte), (_, _) {});
  return c;
}

EtatRecherche _etat(ProviderContainer c, [ContexteRecherche x = _famille]) =>
    c.read(rechercheControleurProvider(x));

RechercheControleur _ctl(
  ProviderContainer c, [
  ContexteRecherche x = _famille,
]) => c.read(rechercheControleurProvider(x).notifier);

Future<void> _attendre(WidgetTester t, Duration d) async {
  await t.pump(d);
  await t.pump(Duration.zero);
}

const Duration _apresSaisie = Duration(milliseconds: 260);

void main() {
  group('bornes avant tout appel', () {
    testWidgets('un champ vide n\'interroge rien', (WidgetTester t) async {
      final MoteurRechercheDemo m = _moteur(DomaineRecherche.classes);
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[m]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('');
      await _attendre(t, _apresSaisie);
      expect(m.appels, 0);
      expect(_etat(c).phase, PhaseRecherche.inactif);
    });

    testWidgets('moins de 3 caracteres : « saisie », aucun appel', (
      WidgetTester t,
    ) async {
      final MoteurRechercheDemo m = _moteur(DomaineRecherche.classes);
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[m]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('al');
      await _attendre(t, const Duration(seconds: 1));
      expect(m.appels, 0);
      expect(_etat(c).phase, PhaseRecherche.saisie);
    });

    testWidgets('le delai de saisie regroupe les frappes en une recherche', (
      WidgetTester t,
    ) async {
      final MoteurRechercheDemo m = _moteur(DomaineRecherche.classes);
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[m]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fat');
      await t.pump(const Duration(milliseconds: 100));
      _ctl(c).ecrire('fati');
      await t.pump(const Duration(milliseconds: 100));
      _ctl(c).ecrire('fatih');
      expect(_etat(c).phase, PhaseRecherche.attente);
      expect(m.appels, 0);
      await _attendre(t, _apresSaisie);
      expect(m.appels, 1);
      expect(_etat(c).texte, 'fatih');
    });

    testWidgets('Entree lance sans attendre le delai', (WidgetTester t) async {
      final MoteurRechercheDemo m = _moteur(DomaineRecherche.classes);
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[m]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      _ctl(c).valider();
      await t.pump(Duration.zero);
      expect(m.appels, 1);
    });
  });

  group('resultats', () {
    testWidgets('au plus 5 elements par domaine dans la fenetre commune, '
        'sans aucun total', (WidgetTester t) async {
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        _moteur(DomaineRecherche.classes, corpus: corpusClassesDemo()),
        _moteur(DomaineRecherche.supports, corpus: corpusSupportsDemo()),
      ]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      final EtatRecherche e = _etat(c);
      expect(e.phase, PhaseRecherche.resultats);
      expect(e.domaines.map((EtatDomaine d) => d.domaine), <DomaineRecherche>[
        DomaineRecherche.classes,
        DomaineRecherche.supports,
      ]);
      for (final EtatDomaine d in e.domaines) {
        expect(d.elements.length, BudgetsRecherche.limiteCommune);
        expect(d.aPlus, isTrue);
        expect(d.curseur, isNotNull);
      }
    });

    testWidgets('le vide n\'est confirme que par ok et aucun element', (
      WidgetTester t,
    ) async {
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        _moteur(DomaineRecherche.classes),
        _moteur(DomaineRecherche.supports),
      ]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('zzzzzz');
      await _attendre(t, _apresSaisie);
      expect(_etat(c).phase, PhaseRecherche.vide);
      expect(
        _etat(c).domaines.every((EtatDomaine d) => d.videConfirme),
        isTrue,
      );
    });

    testWidgets('des domaines en panne ne sont jamais un « aucun resultat »', (
      WidgetTester t,
    ) async {
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        _moteur(
          DomaineRecherche.classes,
          comportement: ComportementDemo.indisponible,
        ),
        _moteur(
          DomaineRecherche.supports,
          comportement: ComportementDemo.limite,
        ),
      ]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      expect(_etat(c).phase, PhaseRecherche.erreur);
      expect(_etat(c).domaines.any((EtatDomaine d) => d.videConfirme), isFalse);
    });

    testWidgets('un domaine en panne parmi des domaines vides : partiel, '
        'jamais un vide', (WidgetTester t) async {
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        _moteur(DomaineRecherche.classes),
        _moteur(
          DomaineRecherche.supports,
          comportement: ComportementDemo.indisponible,
        ),
      ]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('zzzzzz');
      await _attendre(t, _apresSaisie);
      expect(_etat(c).phase, PhaseRecherche.partiels);
    });
  });

  group('retours partiels et delais', () {
    testWidgets('un domaine silencieux ne retient pas les autres', (
      WidgetTester t,
    ) async {
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        _moteur(DomaineRecherche.classes),
        _moteur(
          DomaineRecherche.supports,
          comportement: ComportementDemo.silencieux,
        ),
      ]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      // Les classes sont deja la ; les supports sont encore attendus.
      expect(_etat(c).phase, PhaseRecherche.partiels);
      expect(_etat(c).domaines.first.avancement, AvancementDomaine.termine);
      expect(_etat(c).domaines.last.avancement, AvancementDomaine.enCours);
      // A 2 s, la lenteur se dit sans rien retirer.
      await _attendre(t, const Duration(seconds: 2));
      expect(_etat(c).lent, isTrue);
      expect(_etat(c).domaines.first.elements, isNotEmpty);
      // A 3 s, le domaine est coupe : delai, et lui seul.
      await _attendre(t, const Duration(seconds: 2));
      final EtatDomaine supports = _etat(c).domaines.last;
      expect(supports.avancement, AvancementDomaine.enEchec);
      expect(supports.echec, StatutRecherche.delai);
      expect(_etat(c).phase, PhaseRecherche.partiels);
      expect(_etat(c).lent, isFalse);
    });

    testWidgets('tous silencieux : delai, jamais un spinner sans fin', (
      WidgetTester t,
    ) async {
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        _moteur(
          DomaineRecherche.classes,
          comportement: ComportementDemo.silencieux,
        ),
      ]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, const Duration(seconds: 5));
      expect(_etat(c).phase, PhaseRecherche.delai);
    });

    testWidgets('« Reessayer ce domaine » ne relance que lui', (
      WidgetTester t,
    ) async {
      final MoteurRechercheDemo classes = _moteur(DomaineRecherche.classes);
      final MoteurRechercheDemo supports = _moteur(
        DomaineRecherche.supports,
        comportement: ComportementDemo.indisponible,
      );
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        classes,
        supports,
      ]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      expect(classes.appels, 1);
      supports.comportement = ComportementDemo.normal;
      _ctl(c).reessayerDomaine(DomaineRecherche.supports);
      await t.pump(Duration.zero);
      expect(classes.appels, 1);
      expect(supports.appels, 2);
    });

    testWidgets('trois domaines au plus en meme temps', (WidgetTester t) async {
      int enCours = 0;
      int maximum = 0;
      final List<MoteurRechercheDomaine> moteurs = <MoteurRechercheDomaine>[
        for (final DomaineRecherche d in <DomaineRecherche>[
          DomaineRecherche.classes,
          DomaineRecherche.supports,
          DomaineRecherche.personnes,
          DomaineRecherche.enseignants,
          DomaineRecherche.pedagogie,
        ])
          _MoteurCompteur(d, () {
            enCours++;
            if (enCours > maximum) maximum = enCours;
          }, () => enCours--),
      ];
      final ProviderContainer c = _ouvrir(moteurs);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      await _attendre(t, const Duration(seconds: 1));
      expect(maximum, BudgetsRecherche.domainesSimultanes);
      expect(_etat(c).phase, PhaseRecherche.resultats);
    });

    testWidgets('le domaine d\'ouverture borne la recherche a lui seul, '
        'pages de 20', (WidgetTester t) async {
      const ContexteRecherche borne = ContexteRecherche(
        espace: EspaceRecherche.famille,
        domaineCible: DomaineRecherche.supports,
      );
      final MoteurRechercheDemo classes = _moteur(
        DomaineRecherche.classes,
        corpus: corpusClassesDemo(),
      );
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        classes,
        _moteur(DomaineRecherche.supports, corpus: corpusSupportsDemo()),
      ], contexte: borne);
      await t.pump(Duration.zero);
      _ctl(c, borne).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      final List<EtatDomaine> domaines = _etat(c, borne).domaines;
      expect(domaines.length, 1);
      expect(domaines.single.domaine, DomaineRecherche.supports);
      expect(domaines.single.elements.length, BudgetsRecherche.limitePage);
      // Aucune demande n'est partie vers les autres domaines (§6.1 point 4).
      expect(classes.appels, 0);
    });
  });

  group('reponses tardives (SEC-R05)', () {
    testWidgets('une ancienne reponse n\'est jamais montree comme celle de la '
        'saisie courante', (WidgetTester t) async {
      final MoteurRechercheDemo m = _moteur(
        DomaineRecherche.classes,
        latence: const Duration(seconds: 1),
      );
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[m]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      expect(m.appels, 1);
      // Nouvelle saisie avant la reponse de la premiere.
      _ctl(c).ecrire('baqara');
      await _attendre(t, _apresSaisie);
      expect(m.appels, 2);
      await _attendre(t, const Duration(seconds: 2));
      final EtatRecherche e = _etat(c);
      expect(e.texte, 'baqara');
      for (final ResultatRecherche r in e.domaines.single.elements) {
        expect(r.titre.toLowerCase(), contains('baqara'));
      }
    });

    testWidgets('effacer annule la recherche en cours', (WidgetTester t) async {
      final MoteurRechercheDemo m = _moteur(
        DomaineRecherche.classes,
        latence: const Duration(seconds: 1),
      );
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[m]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      _ctl(c).effacer();
      await _attendre(t, const Duration(seconds: 2));
      expect(_etat(c).phase, PhaseRecherche.inactif);
      expect(_etat(c).domaines, isEmpty);
    });
  });

  group('pagination par curseur', () {
    testWidgets('« Voir davantage » ajoute sans doublon, jamais de total', (
      WidgetTester t,
    ) async {
      const ContexteRecherche borne = ContexteRecherche(
        espace: EspaceRecherche.famille,
        domaineCible: DomaineRecherche.classes,
      );
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        _moteur(DomaineRecherche.classes, corpus: corpusClassesDemo()),
      ], contexte: borne);
      await t.pump(Duration.zero);
      _ctl(c, borne).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      expect(_etat(c, borne).domaines.single.elements.length, 20);
      _ctl(c, borne).plusDeResultats(DomaineRecherche.classes);
      expect(_etat(c, borne).domaines.single.pageEnCours, isTrue);
      await t.pump(Duration.zero);
      final EtatDomaine d = _etat(c, borne).domaines.single;
      expect(d.elements.length, 40);
      expect(
        d.elements.map((ResultatRecherche r) => r.reference).toSet().length,
        40,
      );
    });

    testWidgets('un curseur d\'une autre requete est refuse', (
      WidgetTester t,
    ) async {
      final MoteurRechercheDemo m = _moteur(
        DomaineRecherche.classes,
        corpus: corpusClassesDemo(),
      );
      final ReponseDomaine premiere = await m.rechercher(
        requete: 'fatiha',
        contexte: _famille,
        limite: 5,
      );
      final String curseur = (premiere as ReponseOk).curseurSuivant!;
      final ReponseDomaine autre = await m.rechercher(
        requete: 'baqara',
        contexte: _famille,
        curseur: curseur,
      );
      expect(autre, isA<ReponseEchec>());
      expect((autre as ReponseEchec).statut, StatutRecherche.curseurPerime);
      final ReponseDomaine autreEspace = await m.rechercher(
        requete: 'fatiha',
        contexte: const ContexteRecherche(espace: EspaceRecherche.enseignant),
        curseur: curseur,
      );
      expect(
        (autreEspace as ReponseEchec).statut,
        StatutRecherche.curseurPerime,
      );
    });

    testWidgets('une page en echec garde les lignes deja recues', (
      WidgetTester t,
    ) async {
      const ContexteRecherche borne = ContexteRecherche(
        espace: EspaceRecherche.famille,
        domaineCible: DomaineRecherche.classes,
      );
      final MoteurRechercheDemo m = _moteur(
        DomaineRecherche.classes,
        corpus: corpusClassesDemo(),
      );
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        m,
      ], contexte: borne);
      await t.pump(Duration.zero);
      _ctl(c, borne).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      m.comportement = ComportementDemo.indisponible;
      _ctl(c, borne).plusDeResultats(DomaineRecherche.classes);
      await t.pump(Duration.zero);
      final EtatDomaine d = _etat(c, borne).domaines.single;
      expect(d.elements.length, 20);
      expect(d.pageEnEchec, isTrue);
      expect(d.avancement, AvancementDomaine.termine);
    });
  });

  group('hors ligne, droits retires, session', () {
    testWidgets('hors ligne : aucune requete ne part (SEC-R18)', (
      WidgetTester t,
    ) async {
      final MoteurRechercheDemo m = _moteur(DomaineRecherche.classes);
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        m,
      ], horsLigne: true);
      await t.pump(Duration.zero);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      expect(m.appels, 0);
      expect(_etat(c).phase, PhaseRecherche.horsLigne);
    });

    testWidgets('aucun moteur raccorde : non autorise, rien d\'invente', (
      WidgetTester t,
    ) async {
      final ProviderContainer c = _ouvrir(const <MoteurRechercheDomaine>[]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      expect(_etat(c).phase, PhaseRecherche.nonAutorise);
      expect(_etat(c).domaines, isEmpty);
    });

    testWidgets('un domaine interdit a l\'espace est absent, pas desactive', (
      WidgetTester t,
    ) async {
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        _moteur(DomaineRecherche.classes),
        _moteur(
          DomaineRecherche.pedagogie,
          espaces: const <EspaceRecherche>{EspaceRecherche.enseignant},
        ),
      ]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      expect(
        _etat(c).domaines.map((EtatDomaine d) => d.domaine),
        <DomaineRecherche>[DomaineRecherche.classes],
      );
    });

    testWidgets('droit retire en cours de route : rien n\'est montre', (
      WidgetTester t,
    ) async {
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        _moteur(
          DomaineRecherche.classes,
          comportement: ComportementDemo.contexteRevoque,
        ),
      ]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      expect(_etat(c).phase, PhaseRecherche.nonAutorise);
    });

    testWidgets('session expiree : sa propre phase', (WidgetTester t) async {
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        _moteur(
          DomaineRecherche.classes,
          comportement: ComportementDemo.sessionExpiree,
        ),
      ]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      expect(_etat(c).phase, PhaseRecherche.sessionExpiree);
    });

    testWidgets('changement de compte : requete, resultats et curseurs '
        'sont purges (SEC-R07)', (WidgetTester t) async {
      final FausseSourceSession source = FausseSourceSession(
        _session(profil: 'A'),
      );
      final StreamController<SessionState> flux =
          StreamController<SessionState>();
      addTearDown(flux.close);
      final ProviderContainer c = ProviderContainer(
        overrides: [
          moteursRechercheProvider.overrideWithValue(<MoteurRechercheDomaine>[
            _moteur(DomaineRecherche.classes, corpus: corpusClassesDemo()),
          ]),
          sourceSessionProvider.overrideWithValue(_SourceFlux(flux.stream)),
          portCapaciteEleveProvider.overrideWithValue(
            const PortCapaciteEleveInconnu(),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(sessionProvider, (_, _) {});
      c.listen(rechercheControleurProvider(_famille), (_, _) {});
      flux.add(_session(profil: 'A'));
      await t.pump(Duration.zero);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('fatiha');
      await _attendre(t, _apresSaisie);
      expect(_etat(c).domaines, isNotEmpty);
      // Autre compte sur le meme appareil.
      flux.add(_session(profil: 'B'));
      await t.pump(Duration.zero);
      await t.pump(Duration.zero);
      expect(_etat(c).texte, isEmpty);
      expect(_etat(c).domaines, isEmpty);
      expect(_etat(c).phase, PhaseRecherche.inactif);
      expect(source.etat.profileId, 'A');
    });
  });

  group('volume (spec §10.2, demonstration)', () {
    testWidgets('plusieurs milliers d\'elements par domaine, 3 domaines', (
      WidgetTester t,
    ) async {
      final ProviderContainer c = _ouvrir(<MoteurRechercheDomaine>[
        _moteur(
          DomaineRecherche.classes,
          corpus: corpusClassesDemo(nombre: 8000),
        ),
        _moteur(
          DomaineRecherche.supports,
          corpus: corpusSupportsDemo(nombre: 8000),
        ),
        _moteur(
          DomaineRecherche.pedagogie,
          corpus: corpusElevesClasseDemo(nombre: 8000),
          espaces: const <EspaceRecherche>{EspaceRecherche.famille},
        ),
      ]);
      await t.pump(Duration.zero);
      _ctl(c).ecrire('mariam');
      await _attendre(t, _apresSaisie);
      final EtatRecherche e = _etat(c);
      expect(e.domaines.length, 3);
      expect(e.domaines.last.elements.length, BudgetsRecherche.limiteCommune);
      expect(e.domaines.last.aPlus, isTrue);
    });
  });

  group('espace de recherche d\'une session', () {
    SessionState s(
      AppRole role, {
      bool autonome = false,
      InterfaceMode? mode,
    }) => SessionState(
      resolue: true,
      role: role,
      eleveAutonome: autonome,
      interfaceMode: mode ?? InterfaceMode.standard,
    );

    test('un role, un espace', () {
      expect(
        espaceRecherchePour(s(AppRole.admin)),
        EspaceRecherche.administration,
      );
      expect(
        espaceRecherchePour(s(AppRole.accountant)),
        EspaceRecherche.comptable,
      );
      expect(
        espaceRecherchePour(s(AppRole.controller)),
        EspaceRecherche.controleur,
      );
      expect(
        espaceRecherchePour(s(AppRole.teacher)),
        EspaceRecherche.enseignant,
      );
      expect(espaceRecherchePour(s(AppRole.student)), EspaceRecherche.eleve);
      expect(
        espaceRecherchePour(s(AppRole.student, mode: InterfaceMode.enfant)),
        EspaceRecherche.eleveGuide,
      );
      expect(espaceRecherchePour(const SessionState.deconnecte()), isNull);
    });

    test('l\'espace d\'eleve d\'un tuteur n\'existe que par la capacite', () {
      expect(
        espaceRecherchePour(
          s(AppRole.guardian),
          demande: EspaceRecherche.eleve,
        ),
        EspaceRecherche.famille,
      );
      expect(
        espaceRecherchePour(
          s(AppRole.guardian, autonome: true),
          demande: EspaceRecherche.eleve,
        ),
        EspaceRecherche.eleve,
      );
      expect(
        espaceRecherchePour(s(AppRole.guardian, autonome: true)),
        EspaceRecherche.famille,
      );
    });

    test('un espace demande ne donne jamais plus que le role', () {
      expect(
        espaceRecherchePour(
          s(AppRole.student),
          demande: EspaceRecherche.administration,
        ),
        EspaceRecherche.eleve,
      );
      expect(
        espaceRecherchePour(
          s(AppRole.teacher),
          demande: EspaceRecherche.comptable,
        ),
        EspaceRecherche.enseignant,
      );
    });
  });

  group('port', () {
    test('un moteur qui leve est indisponible, pas un vide', () async {
      final PortRecherche port = PortRechercheParMoteurs(
        <MoteurRechercheDomaine>[_MoteurQuiLeve()],
      );
      final ReponseDomaine r = await port.rechercher(
        domaine: DomaineRecherche.classes,
        requete: 'fatiha',
        contexte: _famille,
      );
      expect(r, isA<ReponseEchec>());
      expect((r as ReponseEchec).statut, StatutRecherche.indisponible);
    });

    test('un domaine non raccorde est indisponible', () async {
      const PortRecherche port = PortRechercheParMoteurs(
        <MoteurRechercheDomaine>[],
      );
      final ReponseDomaine r = await port.rechercher(
        domaine: DomaineRecherche.finances,
        requete: 'fac-2026',
        contexte: _famille,
      );
      expect((r as ReponseEchec).statut, StatutRecherche.indisponible);
      expect(await port.portees(_famille), isEmpty);
    });

    test('un moteur dont le droit ne se lit pas est ferme', () async {
      final PortRecherche port = PortRechercheParMoteurs(
        <MoteurRechercheDomaine>[_MoteurQuiLeve()],
      );
      expect(await port.portees(_famille), isEmpty);
    });

    test('la page demandee est plafonnee a 50', () async {
      final _MoteurEspion espion = _MoteurEspion();
      final PortRecherche port = PortRechercheParMoteurs(
        <MoteurRechercheDomaine>[espion],
      );
      await port.rechercher(
        domaine: DomaineRecherche.classes,
        requete: 'fatiha',
        contexte: _famille,
        limite: 5000,
      );
      expect(espion.limiteRecue, BudgetsRecherche.plafondPage);
    });

    test('le port de production est neutre : aucun domaine', () async {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      expect(await c.read(portRechercheProvider).portees(_famille), isEmpty);
    });

    test(
      'l\'interdit : un resultat ne porte aucun champ hors liste blanche',
      () {
        const ResultatRecherche r = ResultatRecherche(
          type: TypeResultat.support,
          reference: 'r1',
          titre: '<b>Lecon</b>',
          cible: CibleRecherche(kind: KindCible.support, reference: 'r1'),
        );
        // Le titre reste du texte pur : aucun balisage n'est interprete.
        expect(r.titre, '<b>Lecon</b>');
        expect(r.cible.kind, KindCible.support);
      },
    );
  });
}

class _SourceFlux implements SourceSession {
  _SourceFlux(this._flux);
  final Stream<SessionState> _flux;
  @override
  Stream<SessionState> etats() => _flux;
  @override
  Future<void> rafraichir() async {}
}

class _MoteurCompteur implements MoteurRechercheDomaine {
  _MoteurCompteur(this.domaine, this.entree, this.sortie);
  @override
  final DomaineRecherche domaine;
  final void Function() entree;
  final void Function() sortie;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) async => true;

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = 5,
  }) async {
    entree();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    sortie();
    return ReponseOk(
      domaine,
      elements: const <ResultatRecherche>[
        ResultatRecherche(
          type: TypeResultat.classe,
          reference: 'x',
          titre: 'Al-Fatiha',
          cible: CibleRecherche(kind: KindCible.classe, reference: 'x'),
        ),
      ],
    );
  }
}

class _MoteurQuiLeve implements MoteurRechercheDomaine {
  @override
  DomaineRecherche get domaine => DomaineRecherche.classes;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) =>
      Future<bool>.error(StateError('serveur'));

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = 5,
  }) => Future<ReponseDomaine>.error(StateError('serveur'));
}

class _MoteurEspion implements MoteurRechercheDomaine {
  int? limiteRecue;

  @override
  DomaineRecherche get domaine => DomaineRecherche.classes;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) async => true;

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = 5,
  }) async {
    limiteRecue = limite;
    return ReponseOk(domaine, elements: const <ResultatRecherche>[]);
  }
}
