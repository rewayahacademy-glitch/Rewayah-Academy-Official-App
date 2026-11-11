// Captures de recette SUPPORTS-ETAGERE (directeur, 11/11/2026 ; CAHIER-SALLE
// §7) : l'etagere des supports dans la vraie salle de l'enseignant
// (`SallePage`, moteur de visio simule), a 1440 (panneau de droite) et a 390
// (onglet « Support » du tiroir des Commandes), clair, sombre et arabe ; la
// fiche du Coran avec « Partager » et « Afficher » ; la lecture seule. Plus
// l'etagere seule avec les supports de demonstration « a valider ».
// Saute sans CAPTURE_DIR. Captures de test, pas de la vraie application.

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
import 'package:rewayah_academy/core/tc_bibliotheque/couverture_ressource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_enseignant/etagere_supports.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart';

import '../support/harnais.dart';
import '../support/mushaf_15l.dart'
    show chargerPoliceMadina15, surchargesMadina15;
import '../teaching_core/e/faux/faux_classe.dart';
import 'outil_capture.dart';

AccesSalle _acces() => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: 'teacher',
  capacites: const CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: true,
    peutPublierDonnees: true,
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
      camera: false,
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

List<Override> _surcharges(FauxMoteurSalle moteur) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      const SessionState(
        resolue: true,
        role: AppRole.teacher,
        profileId: 't1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  serviceVideoProvider.overrideWithValue(FauxServiceVideo(acces0: _acces())),
  moteurSalleProvider.overrideWithValue(moteur),
  servicePresenceProvider.overrideWithValue(
    FauxServicePresence(
      lignes: <PresenceParticipant>[
        _ligne('t1', 'Amina', 'teacher'),
        _ligne('e1', 'Yasmine', 'student'),
        _ligne('e2', 'Ilyes', 'student'),
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
];

Future<void> _monterSalle(
  WidgetTester tester,
  Size taille,
  ThemeMode theme,
) async {
  fixerVueCapture(tester, taille, 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: _surcharges(moteur),
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(<ParticipantSalle>[
    _personne('t1', 'teacher', true),
    _personne('e1', 'student', false),
    _personne('e2', 'student', false),
  ]);
  moteur.publierQualite(QualiteLien.bonne);
  await tester.pumpAndSettle();
  await moteur.presenterContenu(
    ContenuPresente(
      page: 42,
      sourate: 2,
      verset: 255,
      presentePar: 't1',
      emisLe: DateTime.now(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _toucherCle(WidgetTester tester, String cle) async {
  final Finder f = find.byKey(ValueKey<String>(cle));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _ouvrirTiroir(WidgetTester tester) async {
  await tester.tapAt(const Offset(10, 10));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(TelephonePleinEcran.cleCommandesToucher));
  await tester.pumpAndSettle();
}

/// Les supports de demonstration « a valider » (CAHIER-SALLE §7) : titres
/// tires du programme, aucun contenu ; ils ne vivent que dans les tests et
/// la galerie.
List<SupportBibliotheque> _demo() => <SupportBibliotheque>[
  SupportBibliotheque(
    id: 'coran',
    titre: t.salle.supports.coran,
    detail: t.cahierC1.onReprendPage(page: 42),
    couverture: CouvertureRessource.coran(t.salle.supports.coran),
    onPresenter: () {},
    pageReprise: 42,
    onReprendre: () {},
  ),
  for (final (String id, String titre, String detail, int teinte)
      in <(String, String, String, int)>[
        (
          'lettres',
          t.salle.etagere.demo.lettres,
          t.salle.etagere.demo.lettresDetail,
          3,
        ),
        (
          'voyelles',
          t.salle.etagere.demo.voyelles,
          t.salle.etagere.demo.voyellesDetail,
          9,
        ),
        (
          'priere',
          t.salle.etagere.demo.priere,
          t.salle.etagere.demo.priereDetail,
          14,
        ),
      ])
    SupportBibliotheque(
      id: id,
      titre: titre,
      detail: detail,
      couverture: CouvertureRessource(
        indexTeinte: teinte,
        motif: MotifCouverture.lignes,
        monogramme: titre.substring(0, 1),
        type: TypeRessource.texteStructure,
      ),
      aValider: true,
    ),
];

void main() {
  group('Capture : SUPPORTS-ETAGERE', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await chargerPoliceMadina15();
    });
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('ordinateur 1440, ${theme.name} : etagere, fiche, lecture', (
        WidgetTester tester,
      ) async {
        await _monterSalle(tester, const Size(1440, 900), theme);
        await capturerVue(tester, 'supports_1440_etagere_${theme.name}');
        await _toucherCle(tester, 'bibliotheque-deplier-coran');
        await capturerVue(tester, 'supports_1440_fiche_${theme.name}');
        await _toucherCle(tester, 'bibliotheque-afficher-coran');
        await capturerVue(tester, 'supports_1440_afficher_${theme.name}');
        expect(tester.takeException(), isNull);
      });

      testWidgets('telephone 390, ${theme.name} : onglet Support, fiche', (
        WidgetTester tester,
      ) async {
        await _monterSalle(tester, const Size(390, 844), theme);
        await _ouvrirTiroir(tester);
        await capturerVue(tester, 'supports_390_etagere_${theme.name}');
        await _toucherCle(tester, 'bibliotheque-deplier-coran');
        await capturerVue(tester, 'supports_390_fiche_${theme.name}');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('arabe : ordinateur 1440 et telephone 390', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monterSalle(tester, const Size(1440, 900), ThemeMode.light);
      await capturerVue(tester, 'supports_1440_etagere_light_ar');
      await _toucherCle(tester, 'bibliotheque-deplier-coran');
      await capturerVue(tester, 'supports_1440_fiche_light_ar');
      await _monterSalle(tester, const Size(390, 844), ThemeMode.light);
      await _ouvrirTiroir(tester);
      await capturerVue(tester, 'supports_390_etagere_light_ar');
      expect(tester.takeException(), isNull);
    });

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('etagere seule, supports de demonstration a valider, '
          '${theme.name}', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(392, 900), 1);
        await tester.pumpWidget(
          hoteCapture(
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: EtagereSupports(supports: _demo(), onFermer: () {}),
              ),
            ),
            themeMode: theme,
          ),
        );
        await tester.pumpAndSettle();
        await capturerVue(tester, 'supports_demo_a-valider_${theme.name}');
        await _toucherCle(tester, 'bibliotheque-deplier-lettres');
        await capturerVue(
          tester,
          'supports_demo_a-valider_fiche_${theme.name}',
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
