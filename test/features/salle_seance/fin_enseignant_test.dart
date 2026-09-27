// T7 : fin de seance enseignant (CLV-10) et adaptateur `/salle`.
//
// CLV-10 : textes exacts, recapitulatif derive de la MEME liste que le
// compteur (I-6), aucune mention d'enregistrement, jamais « absent » ;
// jamais rendu pour l'eleve ni la guidee. `DepuisSalle` : role sans salle de
// seance = null (controleur invisible), annonce d'observation a l'enseignant.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_salle.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

void _rien() {}
void _aller(String _) {}

const ActionsSeance _actions = ActionsSeance(
  onRetour: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
  onNaviguer: _aller,
);

const Map<String, Size> _tailles = <String, Size>{
  'mobile': Size(390, 844),
  'web etroit': Size(640, 1000),
  'desktop': Size(1440, 900),
};

const Key _recap = ValueKey<String>('fin-recapitulatif');

Future<void> _monterFin(
  WidgetTester tester,
  Size taille, {
  VueSeance? vue,
  bool indisponible = false,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      FinSeanceEnseignant(
        vue:
            vue ??
            DonneesSeanceDemo.vue(RoleSeance.enseignant, EtatDemoSalle.fin),
        actions: _actions,
        onOuvrirCahier: _rien,
        onRevenirJournee: _rien,
        cahierIndisponible: indisponible,
      ),
      themeMode: mode,
    ),
  );
  await tester.pumpAndSettle();
}

AccesSalle _acces(String role) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: role == 'teacher' || role == 'student',
    peutPublierVideo: role == 'teacher',
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: role == 'masked_controller',
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

VueSalle _salle(String role) => VueSalle.depuis(
  materielPret: true,
  acces: _acces(role),
  etatMoteur: EtatSalle.connecte,
  participants: const <ParticipantSalle>[],
  qualite: QualiteLien.bonne,
);

PresenceParticipant _ligne(
  String prenom,
  String role,
  EtatPresence etat, {
  DateTime? entre,
}) => PresenceParticipant(
  profilId: 'p-$prenom',
  role: role,
  prenom: prenom,
  identifiantImmuable: 'i-$prenom',
  etat: etat,
  consolide: false,
  entreLe: entre,
);

void main() {
  group('CLV-10 : retours de relecture T7', () {
    test('0 et 1 au singulier, puis pluriel', () {
      expect(libelleConnectes(0), '0 élève connecté');
      expect(libelleConnectes(1), '1 élève connecté');
      expect(libelleConnectes(2), '2 élèves connectés');
      expect(libelleInscrits(0), 'sur 0 inscrit');
      expect(libelleInscrits(3), 'sur 3 inscrits');
    });

    test('le cahier ne s ouvre que vers une route existante', () {
      final GoRouter sansCahier = GoRouter(
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        ],
      );
      final GoRouter avecCahier = GoRouter(
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(
            path: '${Routes.enseignantSeance}/:seanceId/cahier',
            builder: (_, _) => const SizedBox(),
          ),
        ],
      );
      expect(cheminCahierOuvrable(sansCahier.configuration, 's1'), isNull);
      expect(cheminCahierOuvrable(avecCahier.configuration, ''), isNull);
      expect(
        cheminCahierOuvrable(avecCahier.configuration, 's1'),
        Routes.cahierPour('s1'),
      );
    });
  });

  group('CLV-10 : fin de seance enseignant', () {
    for (final MapEntry<String, Size> taille in _tailles.entries) {
      testWidgets('textes exacts, sans mention ni absent (${taille.key})', (
        WidgetTester tester,
      ) async {
        await _monterFin(tester, taille.value);
        expect(tester.takeException(), isNull);
        for (final String texte in <String>[
          'Séance terminée',
          'Le cahier est prêt avec les informations de la séance.',
          'Sayyid Ibrahim',
          'Fin',
          '15:16',
          '2 élèves connectés',
          'sur 3 inscrits',
          'Cahier de séance',
          'Cahier à compléter',
          'Ouvrir le cahier',
          'Revenir à ma journée',
        ]) {
          expect(find.text(texte), findsWidgets, reason: texte);
        }
        expect(find.text('Classe An-Nour'), findsWidgets);
        expect(find.byKey(_recap), findsOneWidget);
        // Aucune mention d'enregistrement, aucune presence au sens J3.
        expect(find.text(t.salle.bandeauPermanent), findsNothing);
        expect(find.textContaining('bsent'), findsNothing);
        expect(find.textContaining('résent'), findsNothing);
        expect(find.textContaining('Foyer'), findsNothing);
        final bool desktop = taille.key == 'desktop';
        // En-tete « Terminee » et rail : desktop seulement (images).
        expect(find.text('Terminée'), desktop ? findsOneWidget : findsNothing);
        expect(
          find.byKey(const ValueKey<String>('rail-seance')),
          desktop ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('sombre, sans debordement', (WidgetTester tester) async {
      await _monterFin(tester, const Size(390, 844), mode: ThemeMode.dark);
      expect(tester.takeException(), isNull);
    });

    testWidgets('etat d erreur : message et Reessayer', (
      WidgetTester tester,
    ) async {
      await _monterFin(tester, const Size(1440, 900), indisponible: true);
      expect(
        find.text('Le cahier ne peut pas être ouvert pour le moment.'),
        findsOneWidget,
      );
      expect(find.text(t.commun.reessayer), findsOneWidget);
      expect(find.text('Ouvrir le cahier'), findsNothing);
    });

    testWidgets('le recapitulatif lit la liste du compteur (I-6)', (
      WidgetTester tester,
    ) async {
      final VueSeance base = DonneesSeanceDemo.vue(
        RoleSeance.enseignant,
        EtatDemoSalle.fin,
      );
      final VueSeance vue = base.copyWith(
        eleves: const <EleveSeance>[
          EleveSeance(prenom: 'A', statut: StatutEleveSeance.connecte),
          EleveSeance(prenom: 'B', statut: StatutEleveSeance.pasEncoreConnecte),
          EleveSeance(prenom: 'C', statut: StatutEleveSeance.pasEncoreConnecte),
          EleveSeance(prenom: 'D', statut: StatutEleveSeance.pasEncoreConnecte),
        ],
      );
      await _monterFin(tester, const Size(1440, 900), vue: vue);
      expect(find.text('1 élève connecté'), findsOneWidget);
      expect(find.text('sur 4 inscrits'), findsOneWidget);
      expect(vue.connectesAuMoinsUneFois, 1);
      expect(vue.inscrits, vue.eleves.length);
    });

    testWidgets('jamais rendu pour l eleve ni la guidee', (
      WidgetTester tester,
    ) async {
      for (final RoleSeance role in <RoleSeance>[
        RoleSeance.eleve,
        RoleSeance.guidee,
      ]) {
        final VueSeance vue = DonneesSeanceDemo.vue(role, EtatDemoSalle.fin);
        expect(vue.voitRecapitulatifFin, isFalse);
        await _monterFin(tester, const Size(1440, 900), vue: vue);
        expect(find.byKey(_recap), findsNothing);
        expect(find.text('Ouvrir le cahier'), findsNothing);
      }
      // La demonstration : fin eleve = CLV-09, sans recapitulatif.
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await tester.pumpWidget(
        hoteCapture(
          const SalleDemo(
            role: RoleSeance.eleve,
            etat: EtatDemoSalle.fin,
            onSortir: _rien,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ResultatSeance), findsOneWidget);
      expect(find.byKey(_recap), findsNothing);
      expect(find.textContaining('connecté'), findsNothing);
    });
  });

  group('DepuisSalle : /salle -> VueSeance', () {
    test(
      'controleur, observateur, administration : pas de salle de seance',
      () {
        for (final String role in <String>[
          'masked_controller',
          'guardian_observer',
          'admin_masked',
          'admin_visible',
        ]) {
          expect(
            DepuisSalle.vue(salle: _salle(role), mode: InterfaceMode.standard),
            isNull,
            reason: role,
          );
        }
      },
    );

    test('eleve en mode enfant : guidee', () {
      final VueSeance? vue = DepuisSalle.vue(
        salle: _salle('student'),
        mode: InterfaceMode.enfant,
      );
      expect(vue?.role, RoleSeance.guidee);
    });

    test('l enseignant apprend qu un parent regarde', () {
      final VueSeance? vue = DepuisSalle.vue(
        salle: _salle('teacher'),
        mode: InterfaceMode.standard,
        annonces: const <AnnonceObservation>[
          AnnonceObservation(libelle: 'x', prenomEnfant: 'Mariam'),
        ],
      );
      expect(
        vue?.texteNotice,
        t.salle.seance.tuteurDeObserve(prenom: 'Mariam'),
      );
    });

    test('l eleve non observe ne lit rien', () {
      final VueSeance? vue = DepuisSalle.vue(
        salle: _salle('student'),
        mode: InterfaceMode.standard,
      );
      expect(vue?.visite, isNull);
      expect(vue?.texteNotice, isNull);
    });

    test('presence : jamais absent, et le compteur suit la liste', () {
      final VueSeance? vue = DepuisSalle.vue(
        salle: _salle('teacher'),
        mode: InterfaceMode.standard,
        presence: <PresenceParticipant>[
          _ligne('Amina', 'teacher', EtatPresence.presente),
          _ligne('Mariam', 'student', EtatPresence.presente),
          _ligne('Yusuf', 'student', EtatPresence.absente),
          _ligne(
            'Aicha',
            'student',
            EtatPresence.deconnectee,
            entre: DateTime.utc(2026, 9, 26, 14),
          ),
        ],
      );
      expect(vue, isNotNull);
      expect(vue!.nomEnseignant, 'Amina');
      expect(
        vue.eleves.map((EleveSeance e) => e.statut).toList(),
        <StatutEleveSeance>[
          StatutEleveSeance.connecte,
          StatutEleveSeance.pasEncoreConnecte,
          StatutEleveSeance.connexionInterrompue,
        ],
      );
      expect(
        vue.compteurEleves,
        t.salle.seance.compteurEleves(connectes: 1, inscrits: 3),
      );
      expect(vue.connectesAuMoinsUneFois, 2);
      // Rien d'autre que ce que BR-1 cablera : pas de support partage.
      expect(vue.support, isNull);
    });

    test('heure de fin au format 15:16', () {
      expect(DepuisSalle.heure(DateTime(2026, 9, 26, 15, 16)), '15:16');
      expect(DepuisSalle.initiales('Sayyida Amina'), 'SA');
    });
  });
}
