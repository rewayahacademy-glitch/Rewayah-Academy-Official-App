// NAV-REFONTE, etape 2a (decisions du directeur du 09/11/2026) : le halo du
// cercle Compte (urgent, a lire), sa source unique (la liste de la cloche),
// la feuille « En ce moment », le mouvement reduit et la tuile du Mode
// Accessibilite.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/halo_compte.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/notifications/non_lues.dart';

import '../support/harnais.dart';

NotificationTuteur _notif(
  String id, {
  NiveauAttention niveau = NiveauAttention.information,
  bool lue = false,
  bool geste = false,
  String? destination,
}) => NotificationTuteur(
  id: id,
  titre: 'Titre $id',
  date: DateTime.utc(2026, 11, 9),
  niveau: niveau,
  lue: lue,
  gesteEnAttente: geste,
  destination: destination,
  texte: 'Texte $id',
);

EtatHaloCompte? _halo(List<NotificationTuteur>? liste, {String? cloche}) =>
    haloDepuisNotifications(
      liste == null
          ? const AsyncLoading<List<NotificationTuteur>>()
          : AsyncData<List<NotificationTuteur>>(liste),
      cheminNotifications: cloche ?? Routes.tuteurNotifications,
    );

Widget _barre({
  required EtatHaloCompte? halo,
  void Function(String chemin)? onAller,
  void Function(EtatHaloCompte halo)? onHaloTouche,
  InterfaceMode mode = InterfaceMode.standard,
  bool reduit = false,
  int indexActif = 0,
}) => hote(
  Builder(
    builder: (BuildContext contexte) => MediaQuery(
      data: MediaQuery.of(contexte).copyWith(disableAnimations: reduit),
      child: NavShell(
        destinations: destinationsPour(role: AppRole.guardian, mode: mode),
        indexActif: indexActif,
        onAller: onAller ?? (_) {},
        halo: halo,
        onHaloTouche: onHaloTouche,
        child: const PageShell(child: SizedBox(key: Key('contenu'))),
      ),
    ),
  ),
  surcharges: <Override>[sansPersonneConnectee()],
  mode: mode,
);

void _vue(WidgetTester tester, Size taille, {double texte = 1}) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = texte;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  group('haloDepuisNotifications : la meme liste que la cloche', () {
    test('aucune liste connue, ou aucun centre : aucun halo', () {
      expect(_halo(null), isNull);
      expect(
        haloDepuisNotifications(
          AsyncData<List<NotificationTuteur>>(<NotificationTuteur>[
            _notif('a'),
          ]),
          cheminNotifications: null,
        ),
        isNull,
      );
      expect(_halo(<NotificationTuteur>[]), isNull);
      expect(_halo(<NotificationTuteur>[_notif('a', lue: true)]), isNull);
    });

    test('des non-lus : Nouveau, qui ouvre les notifications', () {
      final EtatHaloCompte? h = _halo(<NotificationTuteur>[
        _notif('a'),
        _notif('b'),
        _notif('c', lue: true),
      ]);
      expect(h?.nature, NatureHalo.nouveau);
      expect(h?.nombre, 2);
      expect(h?.chemin, Routes.tuteurNotifications);
      expect(h?.titre, t.nav.halo.nouveauTitre(n: 2, nombre: 2));
    });

    test('une urgence non lue l emporte, et ouvre sa destination', () {
      final EtatHaloCompte? h = _halo(<NotificationTuteur>[
        _notif('a'),
        _notif(
          'u',
          niveau: NiveauAttention.urgent,
          destination: Routes.tuteurFoyer,
        ),
      ]);
      expect(h?.nature, NatureHalo.urgent);
      expect(h?.titre, 'Titre u');
      expect(h?.detail, 'Texte u');
      expect(h?.chemin, Routes.tuteurFoyer);
    });

    test('une urgence lue reste tant que son geste attend ; sans geste, '
        'elle s efface', () {
      expect(
        _halo(<NotificationTuteur>[
          _notif('u', niveau: NiveauAttention.urgent, lue: true, geste: true),
        ])?.nature,
        NatureHalo.urgent,
      );
      expect(
        _halo(<NotificationTuteur>[
          _notif('u', niveau: NiveauAttention.urgent, lue: true),
        ]),
        isNull,
      );
    });

    test('« Nouveau » vu s eteint ; une nouvelle notification le rallume', () {
      final List<NotificationTuteur> deux = <NotificationTuteur>[
        _notif('a'),
        _notif('b'),
      ];
      final EtatHaloCompte? avant = _halo(deux);
      expect(avant?.idsNonLus, <String>{'a', 'b'});
      EtatHaloCompte? vu(List<NotificationTuteur> l) => haloDepuisNotifications(
        AsyncData<List<NotificationTuteur>>(l),
        cheminNotifications: Routes.tuteurNotifications,
        vues: avant!.idsNonLus,
      );
      expect(vu(deux), isNull);
      expect(vu(<NotificationTuteur>[...deux, _notif('c')])?.nombre, 3);
      // Urgent ne s'eteint jamais pour avoir ete vu.
      expect(
        haloDepuisNotifications(
          AsyncData<List<NotificationTuteur>>(<NotificationTuteur>[
            _notif('u', niveau: NiveauAttention.urgent),
          ]),
          cheminNotifications: Routes.tuteurNotifications,
          vues: <String>{'u'},
        )?.nature,
        NatureHalo.urgent,
      );
    });

    test('une urgence sans destination ouvre le centre de notifications', () {
      expect(
        _halo(<NotificationTuteur>[_notif('u', niveau: NiveauAttention.urgent)])
            ?.chemin,
        Routes.tuteurNotifications,
      );
    });
  });

  group('le cercle Compte avec un halo', () {
    final EtatHaloCompte nouveau = EtatHaloCompte.nouveau(
      nombre: 2,
      chemin: Routes.tuteurNotifications,
    );
    final EtatHaloCompte urgent = EtatHaloCompte.urgent(
      titre: 'Remplacement a confirmer',
      detail: 'Classe de tajwid, 18 h',
      chemin: Routes.tuteurFoyer,
    );

    testWidgets('le nom lu dit l etat ; la lumiere tourne puis reste en '
        'lueur fixe, pastille posee', (WidgetTester tester) async {
      _vue(tester, const Size(390, 844));
      await tester.pumpWidget(_barre(halo: urgent));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.bySemanticsLabel(
          t.nav.halo.urgentNom(compte: t.nav.tuteur.compte),
        ),
        findsOneWidget,
      );
      expect(find.byKey(HaloCompte.lumiereKey), findsOneWidget);
      expect(find.byKey(HaloCompte.pastilleKey), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(HaloCompte.lumiereKey), findsNothing);
      expect(find.byKey(HaloCompte.lueurKey), findsOneWidget);
      expect(find.byKey(HaloCompte.pastilleKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mouvement reduit : la lueur fixe d emblee, aucune rotation', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      await tester.pumpWidget(_barre(halo: nouveau, reduit: true));
      await tester.pump();
      expect(find.byKey(HaloCompte.lumiereKey), findsNothing);
      expect(find.byKey(HaloCompte.lueurKey), findsOneWidget);
      expect(find.byKey(HaloCompte.pastilleKey), findsOneWidget);
    });

    testWidgets('au toucher : la feuille « En ce moment », l action mene a '
        'son chemin', (WidgetTester tester) async {
      _vue(tester, const Size(390, 844));
      String? alle;
      await tester.pumpWidget(
        _barre(halo: nouveau, onAller: (String c) => alle = c),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel(
          t.nav.halo.nouveauNom(n: 2, compte: t.nav.tuteur.compte, nombre: 2),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.nav.halo.enCeMoment), findsOneWidget);
      expect(find.text(nouveau.titre), findsOneWidget);
      expect(find.text(t.nav.halo.lire), findsOneWidget);
      expect(find.text(t.nav.halo.monCompte), findsOneWidget);
      expect(alle, isNull);
      await tester.tap(find.text(t.nav.halo.lire));
      await tester.pumpAndSettle();
      expect(alle, Routes.tuteurNotifications);
      expect(find.text(t.nav.halo.enCeMoment), findsNothing);
    });

    testWidgets('« Mon compte » mene au Compte', (WidgetTester tester) async {
      _vue(tester, const Size(390, 844));
      String? alle;
      await tester.pumpWidget(
        _barre(halo: urgent, onAller: (String c) => alle = c),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel(
          t.nav.halo.urgentNom(compte: t.nav.tuteur.compte),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Classe de tajwid, 18 h'), findsOneWidget);
      await tester.tap(find.text(t.nav.halo.monCompte));
      await tester.pumpAndSettle();
      expect(alle, Routes.tuteurCompte);
    });

    testWidgets('sans halo : le toucher ouvre directement le Compte', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      String? alle;
      await tester.pumpWidget(
        _barre(halo: null, onAller: (String c) => alle = c),
      );
      await tester.pump();
      expect(find.byKey(HaloCompte.pastilleKey), findsNothing);
      await tester.tap(find.bySemanticsLabel(t.nav.tuteur.compte));
      await tester.pumpAndSettle();
      expect(alle, Routes.tuteurCompte);
      expect(find.text(t.nav.halo.enCeMoment), findsNothing);
    });

    for (final double texte in <double>[1, 2]) {
      testWidgets('Mode Accessibilite, 320, texte x$texte : la tuile porte '
          'la pastille et le mot d etat, rien ne deborde', (
        WidgetTester tester,
      ) async {
        _vue(tester, const Size(320, 700), texte: texte);
        await tester.pumpWidget(
          _barre(halo: nouveau, mode: InterfaceMode.enfant),
        );
        await tester.pumpAndSettle();
        expect(find.text(t.nav.halo.nouveauMot), findsOneWidget);
        expect(find.byKey(HaloCompte.pastilleKey), findsOneWidget);
        // La tuile n'est pas un cercle : aucune lumiere qui tourne.
        expect(find.byKey(HaloCompte.lumiereKey), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('persistance (arbitrage du garde-cap du 09/11/2026)', () {
    final EtatHaloCompte urgent = EtatHaloCompte.urgent(
      titre: 'Alerte',
      chemin: Routes.tuteurFoyer,
    );

    testWidgets('la lueur reste ; la rotation se rejoue quand un autre ecran '
        'apparait', (WidgetTester tester) async {
      _vue(tester, const Size(390, 844));
      await tester.pumpWidget(_barre(halo: urgent));
      await tester.pumpAndSettle();
      expect(find.byKey(HaloCompte.lueurKey), findsOneWidget);
      await tester.pumpWidget(_barre(halo: urgent, indexActif: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(HaloCompte.lumiereKey), findsOneWidget);
      // Jamais infinie : elle s'arrete, la lueur reste.
      await tester.pumpAndSettle();
      expect(find.byKey(HaloCompte.lumiereKey), findsNothing);
      expect(find.byKey(HaloCompte.lueurKey), findsOneWidget);
    });

    testWidgets('retour au premier plan : la rotation se rejoue', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      await tester.pumpWidget(_barre(halo: urgent));
      await tester.pumpAndSettle();
      expect(find.byKey(HaloCompte.lumiereKey), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(HaloCompte.lumiereKey), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('mouvement reduit : aucune rotation, meme au changement '
        'd ecran', (WidgetTester tester) async {
      _vue(tester, const Size(390, 844));
      await tester.pumpWidget(_barre(halo: urgent, reduit: true));
      await tester.pump();
      await tester.pumpWidget(
        _barre(halo: urgent, reduit: true, indexActif: 1),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(HaloCompte.lumiereKey), findsNothing);
      expect(find.byKey(HaloCompte.lueurKey), findsOneWidget);
    });

    testWidgets('toucher le cercle signale le halo a la coquille', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      EtatHaloCompte? touche;
      final EtatHaloCompte nouveau = EtatHaloCompte.nouveau(
        nombre: 1,
        chemin: Routes.tuteurNotifications,
        idsNonLus: const <String>{'a'},
      );
      await tester.pumpWidget(
        _barre(halo: nouveau, onHaloTouche: (EtatHaloCompte h) => touche = h),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel(
          t.nav.halo.nouveauNom(n: 1, compte: t.nav.tuteur.compte, nombre: 1),
        ),
      );
      await tester.pumpAndSettle();
      expect(touche?.idsNonLus, <String>{'a'});
    });
  });
}
