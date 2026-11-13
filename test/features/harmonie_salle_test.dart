// HARMONIE-SALLE (13/11/2026, directeur, point 13 du plan des retours :
// « comme un seul ingenieur et architecte ») : sur ordinateur, plier ou
// deplier la Dynamique chrono en tete de la colonne ne change JAMAIS les
// tuiles (ni leur place, ni leurs noms). La colonne decide « noms ou icones
// seules » une fois, sur le cas le plus haut, pour une taille d'ecran donnee.
//
// - composant : pour chaque alerte de qui conduit la seance (vrais textes,
//   prenom long, deux actions), la barre depliee a sa place ne depasse pas la
//   hauteur reservee (`allongementAlerteEnPlace`), texte x1 et x2 ;
// - vraie page `/salle` de l'enseignant a 1024 x 768, 1280 x 800 et
//   1440 x 900 : les rectangles des tuiles et leurs noms sont identiques barre
//   repliee, depliee d'un toucher, et depliee par une alerte (la pause de
//   priere, deux actions ; une arrivee).
//
// Avec CAPTURE_DIR, chaque etat est capture (R3, captures de test).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/commande_salle.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/marque_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/pilote_dynamique.dart'
    show titreRecitation;
import 'package:rewayah_academy/features/salle_seance/salle_ordinateur.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../capture/outil_capture.dart';
import '../support/demo/seance_demo.dart';
import '../support/harnais.dart' show FauxMoteurSalle;
import '../support/salle_chrono.dart';

/// L'horloge du serveur, que le test avance.
class _Horloge {
  _Horloge(this.maintenant);
  DateTime maintenant;
  DateTime call() => maintenant;
}

/// Le port de la pause : rend l'etat donne, compte les appels.
class _Port implements PortPauseSeance {
  _Port(this.etatCourant);
  PauseSeance etatCourant;

  @override
  Future<PauseSeance> demarrer({
    required String seanceId,
    required String cleIdempotence,
  }) async => etatCourant;

  @override
  Future<PauseSeance> terminer({
    required String seanceId,
    required String cleIdempotence,
  }) async => etatCourant;

  @override
  Future<PauseSeance> refuser({
    required String seanceId,
    required String cleIdempotence,
  }) async => etatCourant;

  @override
  Future<PauseSeance> etat(String seanceId) async => etatCourant;

  @override
  Future<ReglagePause> reglage(String groupeId) => throw UnimplementedError();

  @override
  Future<ReglagePause> enregistrerReglage({
    required String groupeId,
    required bool actif,
    required int apresMinutes,
    required int dureeMinutes,
    required String versionAttendue,
    required String cleIdempotence,
  }) => throw UnimplementedError();
}

final Finder _commandes = find.byKey(SalleOrdinateur.cleCommandes);
final Finder _tuiles = find.descendant(
  of: _commandes,
  matching: find.byType(TuileCommandeSalle),
);

/// Ce qui se voit des tuiles : chaque rectangle, et les textes poses dans la
/// colonne (les noms).
({List<Rect> rects, List<String> noms}) _releve(WidgetTester tester) => (
  rects: <Rect>[
    for (int i = 0; i < _tuiles.evaluate().length; i++)
      tester.getRect(_tuiles.at(i)),
  ],
  noms: tester
      .widgetList<Text>(
        find.descendant(of: _commandes, matching: find.byType(Text)),
      )
      .map((Text e) => e.data ?? '')
      .toList(),
);

void _memes(
  ({List<Rect> rects, List<String> noms}) avant,
  ({List<Rect> rects, List<String> noms}) apres,
  String cas,
) {
  expect(apres.rects.length, avant.rects.length, reason: cas);
  expect(avant.rects, isNotEmpty, reason: cas);
  for (int i = 0; i < avant.rects.length; i++) {
    final Rect a = avant.rects[i];
    final Rect b = apres.rects[i];
    expect(
      (a.left - b.left).abs() < 0.5 &&
          (a.top - b.top).abs() < 0.5 &&
          (a.width - b.width).abs() < 0.5 &&
          (a.height - b.height).abs() < 0.5,
      isTrue,
      reason: '$cas : tuile $i $a devient $b',
    );
  }
  expect(apres.noms, avant.noms, reason: '$cas : les noms changent');
}

Future<void> _capture(WidgetTester tester, String nom) async {
  if (dossierCapture == null) return;
  await capturer(tester, nom);
}

Future<void> _battre(WidgetTester tester, [int fois = 1]) async {
  for (int i = 0; i < fois; i++) {
    await tester.pump(AppMouvement.battementDynamique);
  }
  await tester.pump(const Duration(milliseconds: 600));
}

ParticipantSalle _personne(
  String id,
  String role, {
  bool local = false,
  String nom = '',
}) => ParticipantSalle(
  identite: id,
  nom: nom,
  role: role,
  estLocal: local,
  micro: false,
  camera: false,
  parle: false,
  qualite: QualiteLien.bonne,
);

final DateTime _t0 = DateTime.utc(2026, 11, 11, 17);

/// Le composant seul, a sa place (tete d'une colonne de [largeur]).
Future<double> _hauteurBarre(
  WidgetTester tester, {
  required double largeur,
  required double echelle,
  AlerteChrono? alerte,
}) async {
  const Size taille = Size(1280, 800);
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final VueSeance vue =
      DonneesSeanceDemo.vue(
        RoleSeance.enseignant,
        EtatDemoSalle.repos,
      ).copyWith(
        chrono: BornesChrono(
          debutUtc: _t0,
          finPrevueUtc: _t0.add(const Duration(minutes: 90)),
        ),
      );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        horlogeChronoProvider.overrideWithValue(
          () => _t0.add(const Duration(minutes: 20)),
        ),
      ],
      child: TranslationProvider(
        child: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
          ),
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            home: Material(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: largeur,
                  child: DynamiqueChrono(
                    vue: vue,
                    avecChrono: true,
                    largeurMax: largeur,
                    enPlace: true,
                    alerte: alerte,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  return tester
      .getSize(find.byKey(const ValueKey<String>('pilule-etat-salle')))
      .height;
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('la hauteur reservee couvre chaque alerte de qui conduit', () {
    const String prenom = 'Abdourrahmane';
    final List<AlerteChrono> alertes = <AlerteChrono>[
      AlerteChrono(
        id: 'recitation',
        titre: titreRecitation(prenom),
        detail: t.salle.gestes.recitationOuverte(prenom: prenom),
      ),
      AlerteChrono(
        id: 'fin-seule',
        titre: t.salle.gestes.finRecitationTitre,
        detail: t.salle.gestes.recitationFinieSeule(prenom: prenom),
      ),
      AlerteChrono(
        id: 'appel',
        titre: t.salle.gestes.appelEnvoyeTitre(prenom: prenom),
        detail: t.salle.gestes.appelEnvoye,
      ),
      AlerteChrono(
        id: 'question',
        titre: LibellesGroupe.insecable(
          t.salle.dynamique.pauseQuestion(minutes: 10),
        ),
        actions: <ActionAlerteChrono>[
          ActionAlerteChrono(
            libelle: t.salle.dynamique.oui,
            principale: true,
            onPress: () {},
          ),
          ActionAlerteChrono(libelle: t.salle.dynamique.non, onPress: () {}),
        ],
      ),
      AlerteChrono(
        id: 'priere',
        titre: LibellesGroupe.insecable(
          t.salle.dynamique.priereDans(minutes: 3),
        ),
        actions: <ActionAlerteChrono>[
          ActionAlerteChrono(
            libelle: t.salle.dynamique.commencerMaintenant,
            principale: true,
            onPress: () {},
          ),
          ActionAlerteChrono(
            libelle: LibellesGroupe.insecable(
              t.salle.dynamique.decaler(minutes: 5),
            ),
            onPress: () {},
          ),
        ],
      ),
      AlerteChrono(
        id: 'debut',
        titre: LibellesGroupe.insecable(
          t.salle.dynamique.pauseDebut(minutes: 10, heure: '20:45'),
        ),
      ),
    ];
    for (final double echelle in <double>[1, 2]) {
      for (final double largeur in <double>[176, 220, 280]) {
        testWidgets('largeur $largeur, texte x$echelle', (
          WidgetTester tester,
        ) async {
          final double repliee = await _hauteurBarre(
            tester,
            largeur: largeur,
            echelle: echelle,
          );
          final double reserve = allongementAlerteEnPlace(
            tester.element(find.byType(DynamiqueChrono)),
            largeur,
          );
          for (final AlerteChrono a in alertes) {
            final double depliee = await _hauteurBarre(
              tester,
              largeur: largeur,
              echelle: echelle,
              alerte: a,
            );
            expect(tester.takeException(), isNull, reason: a.id);
            expect(
              find.byKey(DynamiqueChrono.cleAlerte),
              findsOneWidget,
              reason: a.id,
            );
            expect(
              depliee - repliee <= reserve + 0.5,
              isTrue,
              reason:
                  '${a.id} : la barre depliee ajoute ${depliee - repliee}, '
                  'la colonne reserve $reserve',
            );
          }
        });
      }
    }
  });

  for (final Size taille in <Size>[
    const Size(1024, 768),
    const Size(1280, 800),
    const Size(1440, 900),
  ]) {
    final String nom =
        'ordinateur ${taille.width.toInt()}x${taille.height.toInt()}';
    testWidgets('$nom : plier, deplier ou recevoir une alerte ne change ni la '
        'place ni les noms des tuiles', (WidgetTester tester) async {
      final _Horloge h = _Horloge(DateTime.now().toUtc());
      final DateTime heure = h.maintenant.add(const Duration(minutes: 10));
      final _Port port = _Port(
        PauseSeance(
          statut: StatutPause.programmee,
          dureePrevueMinutes: 10,
          debutPrevuUtc: heure,
          proposerAUtc: heure,
          peutPiloter: true,
          motif: MotifPause.priere,
        ),
      );
      final FauxMoteurSalle moteur = await monterSalleChrono(
        tester,
        role: 'teacher',
        taille: taille,
        horloge: h.call,
        portPause: port,
        pause: () => port.etatCourant,
        maintenant: h.maintenant,
        moderer: true,
      );
      expect(tester.takeException(), isNull, reason: nom);
      final ({List<Rect> rects, List<String> noms}) repliee = _releve(tester);
      await _capture(
        tester,
        'ordinateur_${taille.width.toInt()}x${taille.height.toInt()}_repliee',
      );

      // Un toucher deplie la barre (la pause en clair, sa commande).
      await tester.tap(find.byKey(DynamiqueChrono.cleDeplier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(DynamiqueChrono.cleDepliee), findsOneWidget);
      expect(find.byKey(ChronoSalle.cleCommandePause), findsOneWidget);
      expect(tester.takeException(), isNull, reason: nom);
      _memes(repliee, _releve(tester), '$nom, depliee d un toucher');
      await _capture(
        tester,
        'ordinateur_${taille.width.toInt()}x${taille.height.toInt()}_depliee',
      );
      await tester.pump(AppMouvement.dynamiqueChronoDepliee);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(DynamiqueChrono.cleDepliee), findsNothing);
      _memes(repliee, _releve(tester), '$nom, repliee de nouveau');

      // La pause de priere annoncee : titre et deux actions.
      h.maintenant = heure.subtract(const Duration(minutes: 3));
      await _battre(tester);
      expect(find.byKey(DynamiqueChrono.cleAlerte), findsOneWidget);
      expect(find.text(t.salle.dynamique.commencerMaintenant), findsOneWidget);
      expect(tester.takeException(), isNull, reason: nom);
      _memes(repliee, _releve(tester), '$nom, alerte a deux actions');
      await _capture(
        tester,
        'ordinateur_${taille.width.toInt()}x${taille.height.toInt()}_alerte',
      );
      // Toucher la barre replie l'alerte (sa marque reste).
      await tester.tap(find.byKey(DynamiqueChrono.cleDeplier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      _memes(repliee, _releve(tester), '$nom, alerte repliee');

      // Une arrivee.
      moteur.publier(<ParticipantSalle>[
        _personne('t1', 'teacher', local: true),
        _personne('e1', 'student'),
        _personne('e2', 'student', nom: 'Aicha'),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      _memes(repliee, _releve(tester), '$nom, arrivee');
      expect(tester.takeException(), isNull, reason: nom);
    });
  }
}
