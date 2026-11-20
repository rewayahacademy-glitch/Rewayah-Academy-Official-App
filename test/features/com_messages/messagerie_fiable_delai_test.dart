// PE-D1 MESSAGERIE-FIABLE, relecture adverse 3 de la PR 657 (20/11/2026) :
// - une lecture de page qui ne repond jamais ne fige plus le fil : au-dela de
//   `AppDelais.requeteMax`, le comblement repart des plus recents et les
//   relectures suivantes s'affichent ; la rangee « chargement » des messages
//   precedents finit en echec, jamais sans fin ;
// - une image envoyee sans session dit sa cause (« Reconnectez-vous »), comme
//   le texte.
// Donnees fictives seulement.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/communications/veille_messages.dart';
import 'package:rewayah_academy/core/fichiers/selecteur_image.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/memoire_pages_fil.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../../support/demo/communications/demo_communications_page.dart';
import '../../support/echec_bulle.dart';
import '../../support/hote_theme.dart';
import '../../support/image_png.dart';
import '../../support/plugin_compression.dart';
import 'support_messages.dart';
import 'support_serveur_fiable.dart';

MessageCommunication _m(int i) => MessageCommunication(
  id: 'm$i',
  auteur: const Participant(id: 'p', nomAffiche: 'P'),
  texte: 't$i',
  envoyeLe: DateTime.utc(2026, 11, 20).add(Duration(minutes: i)),
);

FilMetier _fil(int premier, int dernier, {required bool plus}) => FilMetier(
  id: 'f',
  contexte: <ElementContexteFil>[
    ElementContexteFil(
      objet: ObjetLie(type: TypeObjetLie.classe, id: 'c', libelle: 'C'),
    ),
  ],
  participants: const <Participant>[],
  messages: <MessageCommunication>[
    for (int i = premier; i <= dernier; i++) _m(i),
  ],
  plusAnciens: plus,
);

List<String> _ids(MemoirePagesFil m) => <String>[
  for (final MessageCommunication x in m.messages) x.id,
];

List<String> _de(int a, int b) => <String>[for (int i = a; i <= b; i++) 'm$i'];

void main() {
  group('lecture de page sans reponse (memoire)', () {
    testWidgets('comblement : apres la limite, on repart des plus recents et '
        'les relectures suivantes s\'affichent', (WidgetTester tester) async {
      final Completer<PageMessagesFil> jamais = Completer<PageMessagesFil>();
      final MemoirePagesFil m = MemoirePagesFil(lire: (_) => jamais.future);
      addTearDown(m.dispose);
      m.recevoir(_fil(1, 30, plus: false));
      m.recevoir(_fil(41, 90, plus: true));
      await tester.pump();
      // Pendant la lecture, l'ecran garde ce qu'il montrait.
      m.recevoir(_fil(45, 94, plus: true));
      await tester.pump(const Duration(seconds: 1));
      expect(_ids(m), _de(1, 30));
      expect(m.enCours, isTrue);
      // La limite passee : plus d'ecran fige.
      await tester.pump(AppDelais.requeteMax);
      // La page attendue (m41..m90), puis la relecture arrivee pendant
      // la lecture (jusqu'a m94) : contigu, sans trou.
      expect(_ids(m), _de(41, 94));
      expect(m.enCours, isFalse);
      expect(m.plusAnciens, isTrue);
      expect(m.recalages, 1);
      // Une relecture suivante s'affiche aussitot.
      m.recevoir(_fil(50, 99, plus: true));
      expect(_ids(m), _de(41, 99));
    });

    testWidgets('page precedente sans reponse : echec apres la limite, la '
        'rangee ne tourne pas sans fin', (WidgetTester tester) async {
      final Completer<PageMessagesFil> jamais = Completer<PageMessagesFil>();
      final MemoirePagesFil m = MemoirePagesFil(lire: (_) => jamais.future);
      addTearDown(m.dispose);
      m.recevoir(_fil(51, 100, plus: true));
      Object? erreur;
      unawaited(m.chargerAnciens().catchError((Object e) => erreur = e));
      await tester.pump(const Duration(seconds: 1));
      expect(m.enCours, isTrue);
      await tester.pump(AppDelais.requeteMax);
      expect(erreur, isA<TimeoutException>());
      expect(m.enCours, isFalse);
      expect(_ids(m), _de(51, 100));
      expect(m.plusAnciens, isTrue, reason: '« Reessayer » reste possible');
    });
  });

  testWidgets('telephone : page du trou sans reponse, puis des arrivees : '
      'apres la limite, les nouveaux messages s\'affichent', (
    WidgetTester tester,
  ) async {
    final ServeurFiable s = ServeurFiable(
      portDemo(RoleDemoCommunications.enseignant),
    );
    await s.preparer(anciens: 30);
    await monterFilPleinEcran(tester, port: s);
    EtatVeilleMessagesControleur veille() =>
        ProviderScope.containerOf(tester.element(find.byType(FilDiscussion)))
            .read(etatVeilleMessagesProvider.notifier);
    void arrive(String id) => s.messages.add(
      MessageCommunication(
        id: id,
        auteur: s.autre,
        texte: 'Texte $id',
        envoyeLe: maintenantTest.add(Duration(seconds: s.messages.length)),
      ),
    );
    for (int i = 0; i < 60; i++) {
      arrive('rafale-$i');
    }
    s.pageSuspendue = Completer<void>(); // ne repond jamais
    veille().relire();
    await tester.pump();
    for (int k = 0; k < 3; k++) {
      arrive('plus-tard-$k');
      veille().relire();
      await tester.pump(const Duration(seconds: 2));
    }
    expect(find.text('Texte plus-tard-2'), findsNothing);
    await tester.pump(AppDelais.requeteMax);
    await tester.pumpAndSettle();
    expect(find.text('Texte plus-tard-2'), findsOneWidget);
    arrive('encore');
    veille().relire();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Texte encore'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('image sans session : la bulle dit « Reconnectez-vous », '
      'garde « Reessayer », sans essai automatique', (
    WidgetTester tester,
  ) async {
    simulerPluginCompression();
    fixerVue(tester, const Size(390, 844));
    late Uint8List png;
    await tester.runAsync(() async => png = await fabriquerPng(160, 100));
    int appels = 0;
    await tester.pumpWidget(
      hoteTheme(
        FilDiscussion(
          messages: const <MessageFil>[],
          textes: textesFilCommunication(),
          onEnvoyerMessage: (String _, String _) async {},
          onEnvoyerImage:
              (String _, String _, ImagePrete _, ProgressionImage _) async {
                appels++;
                throw EnvoiNonConfirme(t.commun.etats.sessionExpiree.phrase);
              },
          choisirImage: (SourceImage _) async => png,
          deuxChoixPhoto: false,
        ),
        defilant: false,
      ),
    );
    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Ma page 4');
    await tester.pump();
    await tester.tap(find.byKey(FilDiscussion.cleImage));
    for (int i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(appels, 1);
    expect(find.text(ligneEchec), findsOneWidget);
    expect(find.text(t.com.messages.fil.refusFerme), findsNothing);
    expect(
      find.bySemanticsLabel(
        RegExp(RegExp.escape(t.commun.etats.sessionExpiree.phrase)),
      ),
      findsOneWidget,
    );
  });
}
