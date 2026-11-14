import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_classe/garde_hors_application.dart';
import 'package:rewayah_academy/core/tc_classe/port_session_persistante.dart';
import 'package:rewayah_academy/core/tc_classe/session_persistante.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/video/ecran_eveille.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

import '../../teaching_core/e/faux/faux_classe.dart';

/// HORS-SALLE-1 (directeur, 12/11/2026 au soir) : « l'enseignant ne doit pas
/// etre prisonnier de sa salle ; [...] l'eleve, qui peut lui sortir de la
/// salle sans que ca coupe, mais quand il sort de l'app, la le systeme doit
/// lui donner un moment sans couper ».
void main() {
  group('la regle, lue sur les capacites (jamais un role)', () {
    test('qui modere n est jamais coupe', () {
      expect(
        regleHorsApplication(
          appelTenu: true,
          peutModerer: true,
          peutPublier: true,
          publicationDifferee: false,
          invisible: false,
        ),
        RegleHorsApplication.jamaisCoupe,
      );
    });

    test('qui suit le cours sort apres le delai, voix attendue comprise', () {
      for (final (bool publier, bool differee) in <(bool, bool)>[
        (true, false),
        (false, true),
      ]) {
        expect(
          regleHorsApplication(
            appelTenu: true,
            peutModerer: false,
            peutPublier: publier,
            publicationDifferee: differee,
            invisible: false,
          ),
          RegleHorsApplication.sortieApresDelai,
        );
      }
    });

    test('un observateur (tuteur temoin, controleur invisible) et un appel '
        'non tenu ne sont pas concernes', () {
      expect(
        regleHorsApplication(
          appelTenu: true,
          peutModerer: false,
          peutPublier: false,
          publicationDifferee: false,
          invisible: false,
        ),
        RegleHorsApplication.horsRegle,
      );
      expect(
        regleHorsApplication(
          appelTenu: true,
          peutModerer: false,
          peutPublier: true,
          publicationDifferee: false,
          invisible: true,
        ),
        RegleHorsApplication.horsRegle,
      );
      expect(
        regleHorsApplication(
          appelTenu: false,
          peutModerer: false,
          peutPublier: true,
          publicationDifferee: false,
          invisible: false,
        ),
        RegleHorsApplication.horsRegle,
      );
    });

    test('le delai : 30 secondes, a un seul endroit, lu par un provider', () {
      expect(AppDelais.horsApplicationEleve, const Duration(seconds: 30));
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(delaiHorsApplicationProvider), const Duration(seconds: 30));
      expect(c.read(coupureSuspendueProvider), isFalse);
    });
  });

  group('l eleve hors de l application', () {
    test(
      'cache 29 s puis revenu : rien ne se passe, rien ne s affiche',
      () async {
        final _Banc b = _Banc.eleve();
        b.cacher();
        b.avancer(const Duration(seconds: 29));
        await b.montrer();
        expect(b.video.sorties, isEmpty);
        expect(b.moteur.departs, 0);
        expect(b.controleur.etatCourant.cours, isNotNull);
        expect(b.controleur.etatCourant.sortieHorsApplication, isNull);
        expect(b.minuterie.actives, isEmpty, reason: 'minuterie annulee');
      },
    );

    test('cache 31 s : sorti par le chemin de « Quitter », ecran du retour '
        'pose', () async {
      final _Banc b = _Banc.eleve();
      b.cacher();
      b.avancer(const Duration(seconds: 31));
      await _vider();
      // Pendant l'absence, la minuterie a sonne.
      expect(b.journal, <String>['annonce', 'deconnexion']);
      expect(b.controleur.etatCourant.cours, isNull);
      expect(b.controleur.etatCourant.sortieHorsApplication?.sessionId, 's1');
      await b.montrer();
      expect(b.video.sorties, <String>['s1'], reason: 'une seule sortie');
      expect(b.moteur.departs, 1);
    });

    test('minuterie gelee par le navigateur, retour apres 5 min : l horloge '
        'tranche, sorti', () async {
      final _Banc b = _Banc.eleve();
      b.cacher();
      // L'horloge avance, la minuterie ne sonne pas (page gelee).
      b.horloge = b.horloge.add(const Duration(minutes: 5));
      expect(b.video.sorties, isEmpty);
      await b.montrer();
      expect(b.journal, <String>['annonce', 'deconnexion']);
      expect(b.controleur.etatCourant.sortieHorsApplication?.sessionId, 's1');
      expect(b.minuterie.actives, isEmpty);
    });

    test('retrait annonce (coupure suspendue) : jamais sorti', () async {
      final _Banc b = _Banc.eleve(suspendue: true);
      b.cacher();
      b.avancer(const Duration(minutes: 10));
      await b.montrer();
      expect(b.video.sorties, isEmpty);
      expect(b.moteur.departs, 0);
      expect(b.controleur.etatCourant.sortieHorsApplication, isNull);
    });

    test('page cachee sans appel tenu : rien', () async {
      final _Banc b = _Banc.eleve(adopter: false);
      b.cacher();
      expect(b.minuterie.actives, isEmpty);
      b.horloge = b.horloge.add(const Duration(minutes: 5));
      await b.montrer();
      expect(b.video.sorties, isEmpty);
      expect(b.moteur.departs, 0);
      expect(b.controleur.etatCourant.sortieHorsApplication, isNull);
    });

    test('sortie volontaire pendant le delai : une seule sortie, aucun ecran '
        'du retour', () async {
      final _Banc b = _Banc.eleve();
      b.cacher();
      b.avancer(const Duration(seconds: 10));
      await b.controleur.quitter();
      b.avancer(const Duration(seconds: 40));
      b.horloge = b.horloge.add(const Duration(minutes: 5));
      await b.montrer();
      expect(b.video.sorties, <String>['s1']);
      expect(b.moteur.departs, 1);
      expect(b.controleur.etatCourant.sortieHorsApplication, isNull);
    });

    test(
      'le delai se lit a chaque absence (reglage de la direction)',
      () async {
        Duration delai = const Duration(seconds: 30);
        final _Banc b = _Banc.eleve(delai: () => delai);
        delai = const Duration(seconds: 60);
        b.cacher();
        b.avancer(const Duration(seconds: 45));
        await b.montrer();
        expect(b.video.sorties, isEmpty);
      },
    );

    test('la salle lit l ecran du retour, puis il retombe', () async {
      final _Banc b = _Banc.eleve();
      b.cacher();
      b.avancer(const Duration(seconds: 31));
      await _vider();
      b.controleur.oublierSortieHorsApplication();
      expect(b.controleur.etatCourant.sortieHorsApplication, isNull);
    });
  });

  // HORS-SALLE-2 (directeur, 12/11/2026 au soir) : « Toutes ses sorties de
  // l'app doivent etre consignees sur le rapport. »
  group('le journal des sorties, au retour de l eleve', () {
    test('cache 20 s puis revenu : la sortie part au journal, sans '
        'sortie de la salle, avec l eleve de l appareil du tuteur', () async {
      final _Banc b = _Banc.eleve();
      b.cacher();
      b.avancer(const Duration(seconds: 20));
      await b.montrer();
      expect(b.notes, <(String, int, bool, String?)>[('s1', 20, false, 'e1')]);
    });

    test('cache 31 s : sorti de la salle, la sortie part au retour avec le '
        'drapeau', () async {
      final _Banc b = _Banc.eleve();
      b.cacher();
      b.avancer(const Duration(seconds: 31));
      await _vider();
      expect(b.notes, isEmpty, reason: 'rien tant qu il n est pas revenu');
      await b.montrer();
      expect(b.notes, <(String, int, bool, String?)>[('s1', 31, true, 'e1')]);
    });

    test('serveur ancien ou sans accord (rien note) : rien ne change pour '
        'l eleve', () async {
      final _Banc b = _Banc.eleve(noteAcceptee: false);
      b.cacher();
      b.avancer(const Duration(seconds: 10));
      await b.montrer();
      expect(b.notes, hasLength(1));
      expect(b.controleur.etatCourant.cours, isNotNull);
      expect(b.controleur.etatCourant.sortieHorsApplication, isNull);
    });

    test('rien pour qui modere, rien sans appel tenu', () async {
      final _Banc prof = _Banc.enseignant(
        traces: <(String, Map<String, Object?>)>[],
      );
      prof.cacher();
      prof.avancer(const Duration(minutes: 3));
      await prof.montrer();
      expect(prof.notes, isEmpty);
      final _Banc libre = _Banc.eleve(adopter: false);
      libre.cacher();
      libre.horloge = libre.horloge.add(const Duration(minutes: 2));
      await libre.montrer();
      expect(libre.notes, isEmpty);
    });

    test('une sortie voulue pendant l absence : rien n est note', () async {
      final _Banc b = _Banc.eleve();
      b.cacher();
      b.avancer(const Duration(seconds: 10));
      await b.controleur.quitter();
      await b.montrer();
      expect(b.notes, isEmpty);
    });
  });

  group('qui modere la seance (l enseignant)', () {
    test('cache 10 min : jamais sorti ; deux traces sans identite', () async {
      final List<(String, Map<String, Object?>)> traces =
          <(String, Map<String, Object?>)>[];
      final _Banc b = _Banc.enseignant(traces: traces);
      b.cacher();
      b.moteur.poser(EtatSalle.reconnexion);
      await _vider();
      b.moteur.poser(EtatSalle.retabli);
      await _vider();
      b.avancer(const Duration(minutes: 10));
      await b.montrer();
      expect(b.video.sorties, isEmpty);
      expect(b.moteur.departs, 0);
      expect(b.controleur.etatCourant.cours, isNotNull);
      expect(traces.map(((String, Map<String, Object?>) t) => t.$1), <String>[
        'page_cachee',
        'page_revenue',
      ]);
      final Map<String, Object?> retour = traces.last.$2;
      expect(retour['secondes'], 600);
      expect(retour['reprises'], 1);
      expect(retour['connexion'], 'retabli');
      expect(retour['son_bloque'], isFalse);
      // Jamais une identite : ni seance, ni eleve, ni profil.
      for (final (String _, Map<String, Object?> d) in traces) {
        expect(d.values, isNot(contains('s1')));
        expect(d.values, isNot(contains('e1')));
      }
    });

    test('aucune trace de ce genre pour un eleve', () async {
      final List<(String, Map<String, Object?>)> traces =
          <(String, Map<String, Object?>)>[];
      final GardeHorsApplication garde = GardeHorsApplication(
        regle: () => RegleHorsApplication.sortieApresDelai,
        sortir: () async {},
        delai: () => const Duration(seconds: 30),
        signaler: (String e, Map<String, Object?> d) => traces.add((e, d)),
        minuterie: _FausseMinuterie().creer,
      );
      garde.cachee();
      await garde.revenue();
      expect(traces, isEmpty);
    });
  });
}

Future<void> _vider() => Future<void>.delayed(Duration.zero);

const SessionEnCours _cours = SessionEnCours(
  sessionId: 's1',
  groupeId: 'g1',
  libelleGroupe: 'Classe Al-Fatiha',
  eleveId: 'e1',
);

AccesSalle _accesEnseignant() {
  final AccesSalle base = accesDe('teacher');
  return AccesSalle(
    urlServeur: base.urlServeur,
    jeton: base.jeton,
    nomSalle: base.nomSalle,
    fournisseur: base.fournisseur,
    role: base.role,
    capacites: const CapacitesSalle(
      peutPublier: true,
      peutPublierVideo: true,
      peutPublierDonnees: true,
      peutRecevoir: true,
      invisible: false,
      peutModerer: true,
    ),
    expireLe: base.expireLe,
  );
}

/// Le controleur de session reel, avec une horloge et une minuterie a la
/// main, branche sur le faux moteur de la Classe.
class _Banc {
  _Banc._(
    AccesSalle acces, {
    bool adopter = true,
    bool suspendue = false,
    Duration Function()? delai,
    List<(String, Map<String, Object?>)>? traces,
    bool noteAcceptee = true,
  }) {
    moteur = FauxMoteurClasse(journal: journal);
    video = FauxServiceVideoClasse(
      acces0: accesDe('student'),
      journal: journal,
    );
    controleur = ControleurSessionPersistante(
      moteur,
      video,
      observeLeCycleDeVie: false,
      ecranEveille: EcranEveille(const _SansNavigateur()),
      delaiHorsApplication: delai ?? () => const Duration(seconds: 30),
      coupureSuspendue: () => suspendue,
      maintenant: () => horloge,
      minuterie: minuterie.creer,
      signalerAbsence: (String e, Map<String, Object?> d) =>
          traces?.add((e, d)),
      noterSortieApp:
          ({
            required String seanceId,
            required int secondes,
            required bool sortieSalle,
            String? eleveId,
          }) async {
            notes.add((seanceId, secondes, sortieSalle, eleveId));
            return noteAcceptee;
          },
    );
    addTearDown(controleur.liberer);
    if (adopter) controleur.adopter(cours: _cours, acces: acces);
  }

  factory _Banc.eleve({
    bool adopter = true,
    bool suspendue = false,
    Duration Function()? delai,
    bool noteAcceptee = true,
  }) => _Banc._(
    accesDe('student'),
    adopter: adopter,
    suspendue: suspendue,
    delai: delai,
    noteAcceptee: noteAcceptee,
  );

  factory _Banc.enseignant({
    required List<(String, Map<String, Object?>)> traces,
  }) => _Banc._(_accesEnseignant(), traces: traces);

  final List<String> journal = <String>[];

  /// HORS-SALLE-2 : les sorties envoyees au journal.
  final List<(String, int, bool, String?)> notes =
      <(String, int, bool, String?)>[];
  late final FauxMoteurClasse moteur;
  late final FauxServiceVideoClasse video;
  late final ControleurSessionPersistante controleur;
  final _FausseMinuterie minuterie = _FausseMinuterie();
  DateTime horloge = DateTime.utc(2026, 11, 12, 21);

  void cacher() {
    controleur
      ..didChangeAppLifecycleState(AppLifecycleState.inactive)
      ..didChangeAppLifecycleState(AppLifecycleState.hidden);
  }

  Future<void> montrer() async {
    controleur
      ..didChangeAppLifecycleState(AppLifecycleState.inactive)
      ..didChangeAppLifecycleState(AppLifecycleState.resumed);
    await _vider();
    await _vider();
  }

  void avancer(Duration d) {
    horloge = horloge.add(d);
    minuterie.avancer(d);
  }
}

class _SansNavigateur implements VerrouEcranNavigateur {
  const _SansNavigateur();

  @override
  bool get disponible => false;

  @override
  bool get visible => true;

  @override
  Stream<void> get changementsDeVisibilite => const Stream<void>.empty();

  @override
  Future<Object> demander() => throw UnsupportedError('sans navigateur');

  @override
  bool estRelache(Object verrou) => true;

  @override
  Future<void> relacher(Object verrou) async {}
}

/// Une minuterie qu'on avance a la main.
class _FausseMinuterie {
  final List<_Fausse> actives = <_Fausse>[];
  Duration _temps = Duration.zero;

  Timer creer(Duration d, void Function() rappel) {
    final _Fausse f = _Fausse(this, _temps + d, rappel);
    actives.add(f);
    return f;
  }

  void avancer(Duration d) {
    _temps += d;
    for (final _Fausse f in List<_Fausse>.of(actives)) {
      if (f.echeance <= _temps) {
        actives.remove(f);
        f.rappel();
      }
    }
  }
}

class _Fausse implements Timer {
  _Fausse(this._parent, this.echeance, this.rappel);

  final _FausseMinuterie _parent;
  final Duration echeance;
  final void Function() rappel;

  @override
  void cancel() => _parent.actives.remove(this);

  @override
  bool get isActive => _parent.actives.contains(this);

  @override
  int get tick => 0;
}
