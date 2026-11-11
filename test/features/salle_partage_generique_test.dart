// Lot PARTAGE-GENERIQUE (directeur, 11/11/2026 ; CAHIER-SALLE §7) : le
// partage en direct est commun a tout support.
//
// 1. Le message de presentation : compatibilite dans les deux sens (une
//    application ancienne lit un message nouveau, une application nouvelle
//    lit un message ancien), paquet abime.
// 2. Le support presente : Coran, support connu, support inconnu.
// 3. De bout en bout, dans la vraie `SallePage` : l'enseignant partage le
//    support de demonstration, l'eleve le voit, tourner la page suit, le
//    pointeur s'y pose au meme endroit de la page.
// 4. La reprise : par Classe et par support, jamais dans la memoire du
//    Coran ; sans la migration, une phrase, pas une erreur.
// 5. Le lecteur simple de pages d'images.
//
// Captures (docs/current/captures/E2E/partage-generique/) seulement avec
// CAPTURE_DIR.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/tc_realtime/codec_message_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/types_message.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/position_reprise.dart';
import 'package:rewayah_academy/features/salle/reprise_support.dart';
import 'package:rewayah_academy/features/salle/reprise_support_supabase.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle/synchro_salle.dart';
import 'package:rewayah_academy/features/salle_enseignant/page_coran_salle.dart';
import 'package:rewayah_academy/features/salle_seance/lecteur_support.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart';

import '../capture/outil_capture.dart';
import '../support/harnais.dart';
import '../support/mushaf_15l.dart'
    show chargerPoliceMadina15, surchargesMadina15;
import '../teaching_core/e/faux/faux_classe.dart';

/// Le decodeur d'AVANT ce lot, recopie tel quel : ce que fait une application
/// d'eleve pas encore mise a jour d'un paquet recu.
({int page, int sourate, int verset}) _ancienneApplication(
  Map<String, dynamic> json,
) => (
  page: json['p'] as int? ?? 1,
  sourate: json['s'] as int? ?? 1,
  verset: json['v'] as int? ?? 1,
);

/// Le paquet tel qu'il arrive : encode puis decode, comme sur le reseau.
Map<String, dynamic> _parLeReseau(ContenuPresente contenu) =>
    jsonDecode(jsonEncode(contenu.versJson())) as Map<String, dynamic>;

AccesSalle _acces(String role) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: role == 'teacher',
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

ParticipantSalle _personne(String id, String role, bool local) =>
    ParticipantSalle(
      identite: id,
      nom: '',
      role: role,
      estLocal: local,
      micro: false,
      camera: role == 'teacher',
      parle: false,
      qualite: QualiteLien.bonne,
    );

PresenceParticipant _ligne(String id, String prenom, String role) =>
    PresenceParticipant(
      seanceId: 's1',
      profilId: id,
      role: role,
      prenom: prenom,
      identifiantImmuable: 'RA-26-$id',
      etat: EtatPresence.presente,
      consolide: false,
      entreLe: DateTime.now(),
    );

/// La position du Coran, espionnee : rien ne doit y arriver d'un autre
/// support.
class _CoranEspion extends PositionRepriseAbsente {
  final List<int> pages = <int>[];

  @override
  Future<void> enregistrer({
    required String sessionId,
    required int page,
  }) async => pages.add(page);
}

/// La reprise des supports, espionnee. [retient] : le serveur sait retenir
/// (migration installee) ou non.
class _RepriseEspion implements PortRepriseSupport {
  _RepriseEspion({required this.retient, this.connues = const <String, int>{}});

  final bool retient;
  final Map<String, int> connues;
  final List<({String support, String version, int page, int pages})> ecrites =
      <({String support, String version, int page, int pages})>[];

  @override
  Future<Map<String, int>> pagesDeLaSeance(String sessionId) async => connues;

  @override
  Future<bool> enregistrer({
    required String sessionId,
    required String support,
    required String version,
    required int page,
    required int pages,
  }) async {
    ecrites.add((support: support, version: version, page: page, pages: pages));
    return retient;
  }
}

List<Override> _surcharges(
  FauxMoteurSalle moteur, {
  required String role,
  List<SupportDeSalle>? supports,
  PortRepriseSupport? reprise,
  PortPositionReprise? coran,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      SessionState(
        resolue: true,
        role: role == 'teacher' ? AppRole.teacher : AppRole.student,
        profileId: role == 'teacher' ? 't1' : 'e1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  serviceVideoProvider.overrideWithValue(
    FauxServiceVideo(acces0: _acces(role)),
  ),
  moteurSalleProvider.overrideWithValue(moteur),
  servicePresenceProvider.overrideWithValue(
    FauxServicePresence(
      lignes: <PresenceParticipant>[
        _ligne('t1', 'Amina', 'teacher'),
        _ligne('e1', 'Yasmine', 'student'),
      ],
    ),
  ),
  portAnnonceObservationEnfantProvider.overrideWithValue(
    FauxAnnonceObservationEnfant(observe: false),
  ),
  portAnnonceObservationProvider.overrideWithValue(
    FauxAnnonceObservation(lignes: const <AnnonceObservation>[]),
  ),
  ...surchargesMadina15(page: 42),
  pageCoranProvider.overrideWith(
    (Ref _, int n) async => PageCoran(
      numero: n,
      versets: <VersetCoran>[
        VersetCoran(
          sourateNumero: 2,
          numero: 255,
          texte: 'verset',
          pageNumero: n,
        ),
      ],
    ),
  ),
  // Le support de demonstration n'existe que sous PLAYGROUND et ici.
  if (supports != null) supportsDeSalleProvider.overrideWithValue(supports),
  if (reprise != null) portRepriseSupportProvider.overrideWithValue(reprise),
  if (coran != null) portPositionRepriseProvider.overrideWithValue(coran),
];

Future<FauxMoteurSalle> _monter(
  WidgetTester tester, {
  required String role,
  required Size taille,
  List<SupportDeSalle>? supports,
  PortRepriseSupport? reprise,
  PortPositionReprise? coran,
  ThemeMode theme = ThemeMode.light,
}) async {
  // Une salle neuve a chaque montage : l'ancienne (un autre appareil) est
  // demontee d'abord.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  fixerVueCapture(tester, taille, 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      SallePage(key: ValueKey<String>('salle-$role'), seanceId: 's1'),
      surcharges: _surcharges(
        moteur,
        role: role,
        supports: supports,
        reprise: reprise,
        coran: coran,
      ),
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    _personne('t1', 'teacher', role == 'teacher'),
    _personne('e1', 'student', role != 'teacher'),
  ]);
  moteur.publierQualite(QualiteLien.bonne);
  await tester.pumpAndSettle();
  return moteur;
}

Future<void> _toucherCle(WidgetTester tester, String cle) async {
  final Finder f = find.byKey(ValueKey<String>(cle));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// La capture, seulement avec CAPTURE_DIR.
Future<void> _capture(WidgetTester tester, String nom) async {
  if (dossierCapture == null) return;
  await capturerVue(tester, nom);
}

Finder _pageDemo(int numero) =>
    find.byKey(ValueKey<String>('page-demonstration-$numero'));

/// Un PNG d'un point, valide.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await chargerPoliceMadina15();
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  final DateTime instant = DateTime.utc(2026, 11, 11, 10);

  group('PARTAGE-GENERIQUE : le message de presentation', () {
    test('un message ancien (sans identifiant de support) se lit comme le '
        'Coran', () {
      final ContenuPresente lu = ContenuPresente.depuisJson(<String, dynamic>{
        'p': 42,
        's': 2,
        'v': 255,
        'q': 't1',
        't': instant.millisecondsSinceEpoch,
      });
      expect(lu.estCoran, isTrue);
      expect(lu.support, ContenuPresente.supportCoran);
      expect(lu.page, 42);
      expect(lu.reference, '2:255');
      expect(lu.estRetire, isFalse);
    });

    test('le message du Coran ne change pas d un octet : une application '
        'ancienne y lit la meme page qu avant', () {
      final Map<String, dynamic> paquet = _parLeReseau(
        ContenuPresente(
          page: 42,
          sourate: 2,
          verset: 255,
          presentePar: 't1',
          emisLe: instant,
        ),
      );
      // Les cles d'avant ce lot, et elles seules.
      expect(paquet.keys.toSet(), <String>{'p', 's', 'v', 'q', 't'});
      final ({int page, int sourate, int verset}) ancienne =
          _ancienneApplication(paquet);
      expect(ancienne.page, 42);
      expect(ancienne.sourate, 2);
      expect(ancienne.verset, 255);
      // Et l'application nouvelle le relit a l'identique.
      final ContenuPresente lu = ContenuPresente.depuisJson(paquet);
      expect(lu.estCoran, isTrue);
      expect(lu.page, 42);
      expect(lu.reference, '2:255');
    });

    test('un autre support : une application ancienne lit « rien n est '
        'presente » (page 0), jamais la page du Coran de meme numero', () {
      final Map<String, dynamic> paquet = _parLeReseau(
        ContenuPresente.deSupport(
          support: 'lettres',
          version: '3',
          page: 2,
          total: 40,
          presentePar: 't1',
          emisLe: instant,
        ),
      );
      // Une adresse, jamais un contenu (invariant J6) : identifiant, version,
      // page, nombre de pages.
      expect(paquet.keys.toSet(), <String>{
        'p',
        's',
        'v',
        'q',
        't',
        'd',
        'e',
        'g',
        'n',
      });
      final ({int page, int sourate, int verset}) ancienne =
          _ancienneApplication(paquet);
      expect(ancienne.page, ContenuPresente.pageRetiree);
      // L'application nouvelle lit le support, sa version, sa page, son
      // nombre de pages.
      final ContenuPresente lu = ContenuPresente.depuisJson(paquet);
      expect(lu.estCoran, isFalse);
      expect(lu.estRetire, isFalse);
      expect(lu.support, 'lettres');
      expect(lu.version, '3');
      expect(lu.page, 2);
      expect(lu.total, 40);
      expect(lu.presentePar, 't1');
      expect(lu.emisLe.toUtc(), instant);
    });

    test('« rien n est presente » reste lu par les deux applications', () {
      final Map<String, dynamic> paquet = _parLeReseau(
        ContenuPresente.retire(presentePar: 't1', emisLe: instant),
      );
      expect(_ancienneApplication(paquet).page, ContenuPresente.pageRetiree);
      expect(ContenuPresente.depuisJson(paquet).estRetire, isTrue);
    });

    test('un paquet abime ne leve jamais : des defauts surs', () {
      for (final Map<String, dynamic> abime in <Map<String, dynamic>>[
        <String, dynamic>{},
        <String, dynamic>{'d': 42, 'p': 'x', 't': 'hier', 'q': 7},
        <String, dynamic>{'d': 'lettres'},
        <String, dynamic>{'d': 'lettres', 'g': -3, 'n': 0, 'e': 9},
        <String, dynamic>{'d': '', 'p': 3.0},
      ]) {
        final ContenuPresente lu = ContenuPresente.depuisJson(abime);
        expect(lu.page, greaterThanOrEqualTo(1), reason: '$abime');
        expect(lu.estRetire, isFalse, reason: '$abime');
      }
      // Un identifiant vide ou d'un type inattendu : le Coran.
      expect(
        ContenuPresente.depuisJson(const <String, dynamic>{'d': 42}).estCoran,
        isTrue,
      );
      // Une page ou un nombre de pages absurdes : page 1, total inconnu.
      final ContenuPresente lu = ContenuPresente.depuisJson(
        const <String, dynamic>{'d': 'lettres', 'g': -3, 'n': 0},
      );
      expect(lu.page, 1);
      expect(lu.total, isNull);
    });
  });

  group('PARTAGE-GENERIQUE : le support presente', () {
    test('le Coran garde sa page ; un support connu rend la sienne ; un '
        'support inconnu, ou d une autre version, garde une page pour dire '
        'qu il ne s affiche pas', () {
      final SupportDeSalle demo = supportDemonstration();
      final List<SupportDeSalle> connus = <SupportDeSalle>[demo];

      final coran = supportPresenteDe(
        ContenuPresente(
          page: 42,
          sourate: 2,
          verset: 255,
          presentePar: 't1',
          emisLe: instant,
        ),
        connus,
      );
      expect(coran.id, ContenuPresente.supportCoran);
      expect(coran.total, pagesMushafMedine);
      expect(coran.ratioFixe, isFalse);

      final connu = supportPresenteDe(
        demo.contenu(numero: 3, presentePar: 't1', emisLe: instant),
        connus,
      );
      expect(connu.id, idSupportDemonstration);
      expect(connu.page, 3);
      expect(connu.total, pagesSupportDemonstration);
      expect(connu.ratioFixe, isTrue);

      // Une page au-dela du support : ramenee a la derniere, jamais une
      // assertion.
      expect(
        supportPresenteDe(
          ContenuPresente.deSupport(
            support: demo.id,
            version: demo.version,
            page: 99,
            total: 99,
            presentePar: 't1',
            emisLe: instant,
          ),
          connus,
        ).page,
        pagesSupportDemonstration,
      );

      for (final ContenuPresente inconnu in <ContenuPresente>[
        ContenuPresente.deSupport(
          support: 'jamais-vu',
          version: '1',
          page: 7,
          total: 5,
          presentePar: 't1',
          emisLe: instant,
        ),
        ContenuPresente.deSupport(
          support: demo.id,
          version: 'autre-version',
          page: 2,
          total: 4,
          presentePar: 't1',
          emisLe: instant,
        ),
      ]) {
        expect(supportDeSalleDe(inconnu, connus), isNull);
        final page = supportPresenteDe(inconnu, connus);
        expect(page.id, inconnu.support);
        expect(page.page, inconnu.page);
        expect(page.total, greaterThanOrEqualTo(page.page));
      }
    });

    test('en production, aucun support de demonstration', () {
      expect(supportsDeSalleSelon(demo: false), isEmpty);
      final List<SupportDeSalle> demo = supportsDeSalleSelon(demo: true);
      expect(demo.single.id, idSupportDemonstration);
      expect(demo.single.aValider, isTrue);
    });
  });

  group('PARTAGE-GENERIQUE : de bout en bout dans la salle', () {
    testWidgets('l enseignant partage le support de demonstration, l eleve le '
        'voit, tourner la page suit, le pointeur se pose au meme endroit de '
        'la page', (WidgetTester tester) async {
      final SupportDeSalle demo = supportDemonstration();
      final _CoranEspion coran = _CoranEspion();
      final _RepriseEspion reprise = _RepriseEspion(retient: true);

      // 1. L'enseignant, sur ordinateur : la Bibliotheque, « Partager ».
      final FauxMoteurSalle moteurEnseignant = await _monter(
        tester,
        role: 'teacher',
        taille: const Size(1440, 900),
        supports: <SupportDeSalle>[demo],
        reprise: reprise,
        coran: coran,
      );
      await _toucherCle(tester, 'bibliotheque-deplier-${demo.id}');
      await _capture(tester, 'partage_1440_enseignant_fiche_light');
      await _toucherCle(tester, 'bibliotheque-presenter-${demo.id}');
      final ContenuPresente partage =
          moteurEnseignant.contenusPresentesDemandes.last;
      expect(partage.support, demo.id);
      expect(partage.page, 1);
      // L'enseignant voit sa page (le meme chemin que la classe).
      expect(_pageDemo(1), findsOneWidget);
      expect(find.byType(PageCoranSalle), findsNothing);
      await _capture(tester, 'partage_1440_enseignant_partage_light');

      // Tourner la page : la fleche de la salle, sans rien savoir du support.
      await tester.tap(find.bySemanticsLabel(t.salle.seance.pageSuivante).last);
      await tester.pumpAndSettle();
      final ContenuPresente page2 =
          moteurEnseignant.contenusPresentesDemandes.last;
      expect(page2.support, demo.id);
      expect(page2.page, 2);
      expect(_pageDemo(2), findsOneWidget);

      // La reprise : dans la memoire des supports, jamais dans celle du
      // Coran.
      expect(coran.pages, isEmpty);
      expect(reprise.ecrites.map((e) => (e.support, e.page)), <(String, int)>[
        (demo.id, 1),
        (demo.id, 2),
      ]);

      // Le pointeur de l'enseignant, tel que `SynchroSalle` le pose sur le
      // canal ephemere : un point de 0 a 1 sur la page, rien du support.
      final PaquetDonnees pointeur = PaquetDonnees(
        sujet: sujetProtocolePedagogique,
        charge: messageVersOctets(
          MessagePedagogique(
            type: typePointeurSalle,
            sessionId: 's1',
            emetteurProfilId: 't1',
            charge: const <String, dynamic>{'x': 0.5, 'y': 0.25},
            emisLeUtc: DateTime.now().toUtc(),
          ),
        ),
        fiable: false,
      );

      // 2. L'eleve, au telephone : il recoit les memes paquets.
      final FauxMoteurSalle moteurEleve = await _monter(
        tester,
        role: 'student',
        taille: const Size(390, 844),
        supports: <SupportDeSalle>[demo],
      );
      expect(_pageDemo(1), findsNothing);
      moteurEleve.publierContenu(
        ContenuPresente.depuisJson(_parLeReseau(partage)),
      );
      await tester.pumpAndSettle();
      expect(_pageDemo(1), findsOneWidget);
      expect(find.byType(PageCoranSalle), findsNothing);
      expect(find.byKey(SupportIllisibleIci.cle), findsNothing);
      await _capture(tester, 'partage_390_eleve_page1_light');

      // La page tournee par l'enseignant arrive : l'eleve suit.
      moteurEleve.publierContenu(
        ContenuPresente.depuisJson(_parLeReseau(page2)),
      );
      await tester.pumpAndSettle();
      expect(_pageDemo(2), findsOneWidget);
      expect(_pageDemo(1), findsNothing);

      // La page garde ses proportions (jamais etiree) et tient dans l'ecran.
      final Rect page = tester.getRect(find.byType(PageDemonstration));
      expect(
        page.width / page.height,
        closeTo(PageDemonstration.largeur / PageDemonstration.hauteur, 0.01),
      );
      expect(page.width, lessThanOrEqualTo(390 + 0.5));

      // Le pointeur arrive : il se pose au point (0,5 ; 0,25) DE LA PAGE.
      moteurEleve.recevoirDonnees(
        paquetDepuisLeReseau(
          sujetRecu: sujetSurLeReseau(pointeur.sujet, fiable: pointeur.fiable),
          charge: pointeur.charge,
          emetteurIdentite: 't1',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final Finder point = find.byKey(SurfacePageFixe.clePointeurDistant);
      expect(point, findsOneWidget);
      final Offset centre = tester.getCenter(point);
      expect(centre.dx, closeTo(page.left + 0.5 * page.width, 1.5));
      expect(centre.dy, closeTo(page.top + 0.25 * page.height, 1.5));
      await _capture(tester, 'partage_390_eleve_page2_pointeur_light');
      expect(tester.takeException(), isNull);

      // Le pointeur s'efface seul : aucun minuteur ne reste.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('un eleve dont l application ne connait pas le support voit '
        'une phrase claire, jamais un ecran vide ni une page du Coran', (
      WidgetTester tester,
    ) async {
      // Aucun support connu : comme une application pas encore mise a jour
      // qui lit deja le nouveau message.
      final FauxMoteurSalle moteur = await _monter(
        tester,
        role: 'student',
        taille: const Size(390, 844),
      );
      moteur.publierContenu(
        ContenuPresente.depuisJson(
          _parLeReseau(
            ContenuPresente.deSupport(
              support: 'jamais-vu',
              version: '1',
              page: 2,
              total: 12,
              presentePar: 't1',
              emisLe: DateTime.now(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(SupportIllisibleIci.cle), findsOneWidget);
      expect(find.text(t.salle.support.inconnuTitre), findsOneWidget);
      expect(find.text(t.salle.support.inconnuDetail), findsOneWidget);
      expect(find.byType(PageCoranSalle), findsNothing);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'partage_390_eleve_inconnu_light');

      // Le Coran revient : son lecteur reprend, comme avant.
      moteur.publierContenu(
        ContenuPresente(
          page: 42,
          sourate: 2,
          verset: 255,
          presentePar: 't1',
          emisLe: DateTime.now(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(SupportIllisibleIci.cle), findsNothing);
      expect(find.byType(PageCoranSalle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('l eleve ne partage rien : le moteur refuse sans le droit du '
        'jeton', (WidgetTester tester) async {
      final SupportDeSalle demo = supportDemonstration();
      final FauxMoteurSalle moteur = await _monter(
        tester,
        role: 'student',
        taille: const Size(390, 844),
        supports: <SupportDeSalle>[demo],
      );
      // Aucune etagere chez l'eleve.
      expect(
        find.byKey(ValueKey<String>('bibliotheque-deplier-${demo.id}')),
        findsNothing,
      );
      await moteur.presenterContenu(
        demo.contenu(numero: 1, presentePar: 'e1', emisLe: DateTime.now()),
      );
      await tester.pumpAndSettle();
      expect(moteur.dernierContenuPresente, isNull);
      expect(_pageDemo(1), findsNothing);
    });
  });

  group('PARTAGE-GENERIQUE : la reprise', () {
    testWidgets('sans la migration, la page n est pas retenue au serveur : '
        'une phrase sur la fiche, pas une erreur ; le partage marche', (
      WidgetTester tester,
    ) async {
      final SupportDeSalle demo = supportDemonstration();
      final _RepriseEspion reprise = _RepriseEspion(retient: false);
      final FauxMoteurSalle moteur = await _monter(
        tester,
        role: 'teacher',
        taille: const Size(1440, 900),
        supports: <SupportDeSalle>[demo],
        reprise: reprise,
      );
      await _toucherCle(tester, 'bibliotheque-deplier-${demo.id}');
      final Finder note = find.byKey(
        ValueKey<String>('bibliotheque-note-${demo.id}'),
      );
      expect(note, findsNothing);
      await _toucherCle(tester, 'bibliotheque-presenter-${demo.id}');
      expect(moteur.contenusPresentesDemandes.last.support, demo.id);
      expect(_pageDemo(1), findsOneWidget);
      await tester.pumpAndSettle();
      expect(reprise.ecrites, hasLength(1));
      expect(note, findsOneWidget);
      expect(find.text(t.salle.support.repriseNonRetenue), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'partage_1440_enseignant_non_retenue_light');
    });

    testWidgets('avec la migration, la page retenue au serveur se propose : '
        '« Partager page 3 »', (WidgetTester tester) async {
      final SupportDeSalle demo = supportDemonstration();
      final FauxMoteurSalle moteur = await _monter(
        tester,
        role: 'teacher',
        taille: const Size(1440, 900),
        supports: <SupportDeSalle>[demo],
        reprise: _RepriseEspion(
          retient: true,
          connues: <String, int>{demo.id: 3},
        ),
      );
      await _toucherCle(tester, 'bibliotheque-deplier-${demo.id}');
      expect(find.text(t.salle.etagere.partagerPage(page: 3)), findsOneWidget);
      await _toucherCle(tester, 'bibliotheque-reprendre-${demo.id}');
      expect(moteur.contenusPresentesDemandes.last.page, 3);
      expect(_pageDemo(3), findsOneWidget);
    });

    test('la memoire : une page par Classe et par support ; la meme page ne '
        'repart pas ; une page hors du support est ignoree', () async {
      final _RepriseEspion port = _RepriseEspion(retient: true);
      final List<bool> signaux = <bool>[];
      final MemoireRepriseSupport memoire = MemoireRepriseSupport(
        port,
        surNonRetenue: signaux.add,
      );
      void ecrire(String support, int page) => memoire.ecrire(
        'g1',
        support: support,
        version: '1',
        page: page,
        pages: 10,
        sessionId: 's1',
      );
      ecrire('lettres', 2);
      ecrire('voyelles', 5);
      await pumpEventQueue();
      ecrire('lettres', 2);
      ecrire('lettres', 11);
      ecrire('lettres', 0);
      await pumpEventQueue();
      expect(memoire.lire('g1', 'lettres'), 2);
      expect(memoire.lire('g1', 'voyelles'), 5);
      expect(memoire.lire('g2', 'lettres'), isNull);
      expect(port.ecrites.map((e) => (e.support, e.page)), <(String, int)>[
        ('lettres', 2),
        ('voyelles', 5),
      ]);
      expect(signaux, <bool>[false, false]);
    });

    test('l adaptateur : fonction absente du serveur, reponses lues', () {
      expect(fonctionAbsente('PGRST202'), isTrue);
      expect(fonctionAbsente('42883'), isTrue);
      expect(fonctionAbsente('42501'), isFalse);
      expect(fonctionAbsente(null), isFalse);
      expect(
        pagesDepuisReponse(<Object?>[
          <String, Object?>{'support': 'lettres', 'page': 4, 'pages': 40},
          <String, Object?>{'support': 'voyelles', 'page': 50, 'pages': 40},
          <String, Object?>{'support': '', 'page': 2, 'pages': 40},
          <String, Object?>{'support': 'priere', 'page': 0, 'pages': 4},
          'bruit',
        ]),
        <String, int>{'lettres': 4},
      );
      expect(pagesDepuisReponse(null), isEmpty);
    });
  });

  group('PARTAGE-GENERIQUE : le lecteur simple de pages d images', () {
    Widget hote(Widget page) => hoteCapture(
      Center(child: SizedBox(width: 300, height: 424, child: page)),
    );

    testWidgets('la page chargee s affiche entiere', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(PageImageSupport(numero: 1, charger: (int _) async => _png)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('page-image-contenu')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fichier absent : une phrase et « Reessayer », qui relit', (
      WidgetTester tester,
    ) async {
      int lectures = 0;
      await tester.pumpWidget(
        hote(
          PageImageSupport(
            numero: 2,
            charger: (int _) async => ++lectures == 1 ? null : _png,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.salle.support.pageIllisible), findsOneWidget);
      expect(find.text(t.salle.support.pageIllisibleDetail), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('page-image-reessayer')),
      );
      await tester.pumpAndSettle();
      expect(lectures, 2);
      expect(
        find.byKey(const ValueKey<String>('page-image-contenu')),
        findsOneWidget,
      );
    });

    testWidgets('une lecture qui echoue ne leve pas : le meme etat', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          PageImageSupport(
            numero: 3,
            charger: (int _) async => throw StateError('reseau'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('page-image-erreur')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('PARTAGE-GENERIQUE : captures', skip: sautSansCapture, () {
    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      for (final (Size taille, String largeur) in const <(Size, String)>[
        (Size(390, 844), '390'),
        (Size(1440, 900), '1440'),
      ]) {
        testWidgets('l eleve voit le support partage, $largeur, '
            '${theme.name}', (WidgetTester tester) async {
          final SupportDeSalle demo = supportDemonstration();
          final FauxMoteurSalle moteur = await _monter(
            tester,
            role: 'student',
            taille: taille,
            supports: <SupportDeSalle>[demo],
            theme: theme,
          );
          moteur.publierContenu(
            demo.contenu(numero: 2, presentePar: 't1', emisLe: DateTime.now()),
          );
          await tester.pumpAndSettle();
          await _capture(tester, 'partage_${largeur}_eleve_voit_${theme.name}');
          expect(tester.takeException(), isNull);
        });

        testWidgets('l enseignant partage, $largeur, ${theme.name}', (
          WidgetTester tester,
        ) async {
          final SupportDeSalle demo = supportDemonstration();
          final FauxMoteurSalle moteur = await _monter(
            tester,
            role: 'teacher',
            taille: taille,
            supports: <SupportDeSalle>[demo],
            theme: theme,
          );
          await moteur.presenterContenu(
            demo.contenu(numero: 1, presentePar: 't1', emisLe: DateTime.now()),
          );
          await tester.pumpAndSettle();
          if (taille.width < 840) {
            // Le tiroir des Commandes, onglet de la Bibliotheque.
            await tester.tapAt(const Offset(10, 10));
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(TelephonePleinEcran.cleCommandesToucher),
            );
            await tester.pumpAndSettle();
          }
          await _capture(
            tester,
            'partage_${largeur}_enseignant_partage_${theme.name}',
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('arabe : l eleve au telephone, l enseignant sur ordinateur', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      final SupportDeSalle demo = supportDemonstration();
      final FauxMoteurSalle eleve = await _monter(
        tester,
        role: 'student',
        taille: const Size(390, 844),
        supports: <SupportDeSalle>[demo],
      );
      eleve.publierContenu(
        demo.contenu(numero: 2, presentePar: 't1', emisLe: DateTime.now()),
      );
      await tester.pumpAndSettle();
      await _capture(tester, 'partage_390_eleve_voit_ar');
      final FauxMoteurSalle enseignant = await _monter(
        tester,
        role: 'teacher',
        taille: const Size(1440, 900),
        supports: <SupportDeSalle>[demo],
      );
      await enseignant.presenterContenu(
        demo.contenu(numero: 1, presentePar: 't1', emisLe: DateTime.now()),
      );
      await tester.pumpAndSettle();
      await _capture(tester, 'partage_1440_enseignant_partage_ar');
      expect(tester.takeException(), isNull);
    });
  });
}
