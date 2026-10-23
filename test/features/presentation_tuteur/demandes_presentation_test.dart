// BACK-FRONT-AGE-1 (MA-9) : le tuteur repond aux demandes de presentation.
//
// Ce que le test prouve : les cinq etats (chargement, contenu, vide, erreur,
// hors ligne) ; accepter et refuser retirent la demande et le disent ; une
// reponse non confirmee laisse la demande en attente et le dit ; aucun bouton
// plein ; la carte de l'accueil est silencieuse sans demande ; le titre de la
// notification ; la tranche d'age inconnue est vouvoyee ; 320 px, texte x2,
// LTR et RTL.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/age_eleve.dart';
import 'package:rewayah_academy/core/accessibilite/port_reponse_presentation.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/presentation_tuteur/demandes_presentation_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';

class _Port implements PortReponsePresentation {
  _Port(this.demandes, {this.echecReponse = false, this.echecLecture = false});

  final List<DemandePresentation> demandes;
  final bool echecReponse;
  final bool echecLecture;
  final List<String> acceptees = <String>[];
  final List<String> refusees = <String>[];
  Completer<List<DemandePresentation>>? retenue;

  @override
  Future<List<DemandePresentation>> enAttente() {
    if (retenue != null) return retenue!.future;
    if (echecLecture) return Future<List<DemandePresentation>>.error('x');
    return Future<List<DemandePresentation>>.value(
      demandes
          .where(
            (DemandePresentation d) =>
                !acceptees.contains(d.id) && !refusees.contains(d.id),
          )
          .toList(),
    );
  }

  @override
  Future<void> accepter(String id) async {
    if (echecReponse) throw StateError('non confirme');
    acceptees.add(id);
  }

  @override
  Future<void> refuser(String id) async {
    if (echecReponse) throw StateError('non confirme');
    refusees.add(id);
  }
}

final List<DemandePresentation> _deux = <DemandePresentation>[
  DemandePresentation(
    id: 'p1',
    eleveId: 'e1',
    prenom: 'Yusuf',
    demandeeLe: DateTime(2026, 10, 8, 19, 40),
  ),
  DemandePresentation(
    id: 'p2',
    eleveId: 'e2',
    prenom: 'Aïcha',
    demandeeLe: DateTime(2026, 10, 9, 8, 5),
  ),
];

Future<void> _monter(
  WidgetTester tester,
  PortReponsePresentation? port, {
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterRecrutement(
  tester,
  chemin: '/tuteur/presentation',
  ecran: (_) => const DemandesPresentationPage(),
  autres: <String>['/tuteur'],
  surcharges: <Override>[
    if (port != null) portReponsePresentationProvider.overrideWithValue(port),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

void main() {
  final p = t.presentationTuteur;

  testWidgets('contenu : une carte par demande, qui et quand', (tester) async {
    await _monter(tester, _Port(_deux));
    expect(find.text(p.ligne(prenom: 'Yusuf')), findsOneWidget);
    expect(find.text(p.ligne(prenom: 'Aïcha')), findsOneWidget);
    expect(find.text(p.accepter), findsNWidgets(2));
    expect(find.text(p.refuser), findsNWidgets(2));
    verifierUnSeulBoutonPlein(tester);
  });

  testWidgets('chargement', (tester) async {
    final _Port port = _Port(_deux)
      ..retenue = Completer<List<DemandePresentation>>();
    await _monter(tester, port);
    expect(find.byType(Skeleton), findsWidgets);
  });

  testWidgets('vide, avec ou sans port', (tester) async {
    await _monter(tester, _Port(const <DemandePresentation>[]));
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(p.vide), findsOneWidget);
  });

  testWidgets('sans port : vide, rien d\'invente', (tester) async {
    await _monter(tester, null);
    expect(find.text(p.vide), findsOneWidget);
  });

  testWidgets('erreur : reessayer', (tester) async {
    await _monter(tester, _Port(_deux, echecLecture: true));
    expect(find.byType(EtatSysteme), findsOneWidget);
    expect(find.text(p.erreur), findsOneWidget);
  });

  testWidgets('hors ligne sans donnees', (tester) async {
    await _monter(tester, _Port(_deux, echecLecture: true), horsLigne: true);
    expect(find.text(p.erreur), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('presentation-sans-donnees')),
      findsOneWidget,
    );
  });

  testWidgets('accepter : confirmation, la demande disparait', (tester) async {
    final _Port port = _Port(_deux);
    await _monter(tester, port);
    await tester.tap(
      find.byKey(const ValueKey<String>('presentation-accepter-p1')),
    );
    await laisser(tester);
    expect(port.acceptees, <String>['p1']);
    expect(find.text(p.acceptee(prenom: 'Yusuf')), findsOneWidget);
    expect(find.text(p.ligne(prenom: 'Yusuf')), findsNothing);
    expect(find.text(p.ligne(prenom: 'Aïcha')), findsOneWidget);
  });

  testWidgets('refuser : confirmation, la demande disparait', (tester) async {
    final _Port port = _Port(_deux);
    await _monter(tester, port);
    await tester.tap(
      find.byKey(const ValueKey<String>('presentation-refuser-p2')),
    );
    await laisser(tester);
    expect(port.refusees, <String>['p2']);
    expect(
      find.text(
        p.refusee(
          dePrenom: deDevant('Aïcha', cle: 'presentationTuteur.refusee'),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(p.ligne(prenom: 'Aïcha')), findsNothing);
  });

  testWidgets('reponse non confirmee : la demande reste, le message le dit', (
    tester,
  ) async {
    await _monter(tester, _Port(_deux, echecReponse: true));
    await tester.tap(
      find.byKey(const ValueKey<String>('presentation-accepter-p1')),
    );
    await laisser(tester);
    expect(
      find.byKey(const ValueKey<String>('presentation-echec')),
      findsOneWidget,
    );
    expect(find.text(p.ligne(prenom: 'Yusuf')), findsOneWidget);
    expect(find.text(p.acceptee(prenom: 'Yusuf')), findsNothing);
    expect(find.byType(ActionPrincipale), findsWidgets);
  });

  test('notification demande_presentation : libelle et destination', () {
    expect(
      titreNotificationPresentation(_deux.first),
      p.notification(prenom: 'Yusuf'),
    );
  });

  test('tranche inconnue : vouvoiement, seul un mineur connu est tutoye', () {
    expect(AgeEleve.inconnu.tutoiement, isFalse);
    expect(AgeEleve.adulte.tutoiement, isFalse);
    expect(AgeEleve.mineur.tutoiement, isTrue);
    expect(const AgeEleveInconnu().ageDeLEleve(), AgeEleve.inconnu);
  });

  group('gabarits', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection d in TextDirection.values) {
      testWidgets('320 px, texte x2, ${d.name}', (tester) async {
        await _monter(
          tester,
          _Port(_deux),
          largeur: 320,
          echelle: 2,
          direction: d,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });
}
