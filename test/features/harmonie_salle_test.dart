// HARMONIE-SALLE (13/11/2026, directeur, point 13 du plan des retours ;
// retour du pilote le meme jour : « l'etat de repos compte plus que l'instant
// du depli ») : sur ordinateur, la tete de la colonne suit son contenu.
//
// Vraie page `/salle` de l'enseignant a 1024 x 768, 1280 x 800 et
// 1440 x 900 :
// (a) au repos, aucun vide en tete de colonne : les tuiles commencent juste
//     sous la Dynamique chrono et sa ligne d'etat, a l'ecart de l'echelle ;
// (b) au repos, les noms des tuiles sont la quand ils tiennent (mesure du
//     13/11 : ils tiennent aux trois tailles, la pause de priere annoncee) ;
// (c) un depli puis un repli rendent exactement la forme de repos ; pendant
//     le depli, rien ne chevauche (la colonne se tasse : noms, puis icones).
//
// Avec CAPTURE_DIR, chaque etat est capture (R3, captures de test).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
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

/// Le bas de ce qui se voit dans la tete : la barre et, au repos, la ligne
/// d'etat quand elle y est.
double _basDuContenuDeLaTete(WidgetTester tester) {
  final Finder tete = find.byKey(SalleOrdinateur.cleTete);
  double bas = tester.getRect(find.byKey(DynamiqueChrono.cleDeplier)).bottom;
  final Finder ligne = find.descendant(
    of: tete,
    matching: find.byKey(LigneEtatSalle.cle),
  );
  if (ligne.evaluate().isNotEmpty) {
    final double b = tester.getRect(ligne).bottom;
    if (b > bas) bas = b;
  }
  return bas;
}

/// (a) : aucun vide sous la tete, et les tuiles a l'ecart de l'echelle.
void _sansVide(WidgetTester tester, String cas) {
  final Rect tete = tester.getRect(find.byKey(SalleOrdinateur.cleTete));
  final Rect commandes = tester.getRect(_commandes);
  expect(
    tete.bottom - _basDuContenuDeLaTete(tester),
    lessThan(0.5),
    reason: '$cas : vide sous la barre, tete $tete',
  );
  expect(
    commandes.top - tete.bottom,
    closeTo(AppSpacing.sm, 0.5),
    reason: '$cas : ecart entre la tete et les tuiles',
  );
}

/// Rien ne chevauche : la tete au-dessus des tuiles, les tuiles dans
/// l'ecran.
void _sansChevauchement(WidgetTester tester, Size taille, String cas) {
  final Rect tete = tester.getRect(find.byKey(SalleOrdinateur.cleTete));
  final Rect commandes = tester.getRect(_commandes);
  expect(tete.bottom, lessThanOrEqualTo(commandes.top + 0.5), reason: cas);
  expect(commandes.bottom, lessThanOrEqualTo(taille.height + 0.5), reason: cas);
  for (int i = 0; i < _tuiles.evaluate().length; i++) {
    final Rect r = tester.getRect(_tuiles.at(i));
    expect(r.top, greaterThanOrEqualTo(commandes.top - 0.5), reason: cas);
    expect(r.bottom, lessThanOrEqualTo(commandes.bottom + 0.5), reason: cas);
  }
}

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

  for (final (Size taille, bool nomsAuRepos) in <(Size, bool)>[
    (const Size(1024, 768), true),
    (const Size(1280, 800), true),
    (const Size(1440, 900), true),
  ]) {
    final String nom =
        'ordinateur ${taille.width.toInt()}x${taille.height.toInt()}';
    testWidgets('$nom : au repos, pas de vide en tete et les noms quand ils '
        'tiennent ; apres un depli, la forme de repos revient', (
      WidgetTester tester,
    ) async {
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
      _sansVide(tester, '$nom, au repos');
      _sansChevauchement(tester, taille, '$nom, au repos');
      expect(repliee.rects, hasLength(9), reason: nom);
      expect(
        repliee.noms.isNotEmpty,
        nomsAuRepos,
        reason: '$nom : noms des tuiles au repos ${repliee.noms}',
      );
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
      _sansChevauchement(tester, taille, '$nom, depliee d un toucher');
      await _capture(
        tester,
        'ordinateur_${taille.width.toInt()}x${taille.height.toInt()}_depliee',
      );
      await tester.pump(AppMouvement.dynamiqueChronoDepliee);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(DynamiqueChrono.cleDepliee), findsNothing);
      _memes(repliee, _releve(tester), '$nom, repliee de nouveau');
      _sansVide(tester, '$nom, repliee de nouveau');

      // Une arrivee.
      moteur.publier(<ParticipantSalle>[
        _personne('t1', 'teacher', local: true),
        _personne('e1', 'student'),
        _personne('e2', 'student', nom: 'Aicha'),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      _sansChevauchement(tester, taille, '$nom, arrivee');
      expect(tester.takeException(), isNull, reason: nom);
      // L'alerte passee, la forme de repos revient.
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(DynamiqueChrono.cleDepliee), findsNothing);
      _memes(repliee, _releve(tester), '$nom, apres l arrivee');
      _sansVide(tester, '$nom, apres l arrivee');
    });
  }
}
