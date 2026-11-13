// HARMONIE-SALLE (13/11/2026, directeur, point 13 du plan des retours :
// « comme un seul ingenieur et architecte ») : sur ordinateur, plier ou
// deplier la Dynamique chrono en tete de la colonne ne change JAMAIS les
// tuiles (ni leur place, ni leurs noms). La colonne decide « noms ou icones
// seules » une fois, sur le cas le plus haut, pour une taille d'ecran donnee.
//
// - vraie page `/salle` de l'enseignant a 1024 x 768, 1280 x 800 et
//   1440 x 900 : les rectangles des tuiles et leurs noms sont identiques barre
//   repliee, depliee d'un toucher (la pause en clair et sa commande), et
//   depliee par une alerte courte (une arrivee).
//
// Limite (relevé HARMONIE-2026-11-13, point 2) : une alerte haute (detail de
// la recitation, deux actions de la pause de priere) ne tient pas dans la
// reserve d'un ecran bas ; elle n'est pas couverte ici.
//
// Avec CAPTURE_DIR, chaque etat est capture (R3, captures de test).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/video/gestes_salle.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/commande_salle.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/salle_ordinateur.dart';

import '../capture/outil_capture.dart';
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

/// Les gestes de l'enseignant, sans reseau.
class _Gestes implements PortGestesSalle {
  @override
  Future<void> appliquer(
    String seanceId,
    String eleveId,
    GesteSalle geste,
  ) async {}

  @override
  Future<IssueRecitation> faireReciter(String seanceId, String eleveId) async =>
      IssueRecitation.ouverte;

  @override
  Future<void> terminerRecitation(String seanceId, {String? eleveId}) async {}

  @override
  Future<void> readmettre(String seanceId, String eleveId) async {}

  @override
  Future<List<EleveSorti>> sortis(String seanceId) async =>
      const <EleveSorti>[];
}

final Override _sansReseau = portGestesSalleProvider.overrideWithValue(
  _Gestes(),
);

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

void main() {
  setUpAll(chargerPolicesDuDepot);

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
        autres: <Override>[_sansReseau],
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
