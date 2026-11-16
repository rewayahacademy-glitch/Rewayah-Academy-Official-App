// RECRUTEMENT-SANS-SORTIE (directeur, 14/11/2026) : « Ecrire a {nom} » dans
// le dossier d'un candidat ne fait plus quitter le dossier.
//
// Ce que le test prouve :
// - sur ordinateur (1440), la conversation s'ouvre dans un volet a droite du
//   dossier ; l'adresse reste celle du dossier ; on ecrit (le message part
//   par le port des Messages, le meme que la page Messages) ; la croix replie
//   le volet et le dossier est toujours la ;
// - au telephone (390), la conversation monte en surface plein ecran ; le
//   disque « Replier la conversation » ramene au dossier, a la meme adresse ;
// - « Ouvrir dans Messages » reste en lien secondaire et empile la page
//   Messages (son retour ramene au dossier).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/admin_candidature/candidature_page.dart';
import 'package:rewayah_academy/features/admin_candidature/volet_conversation.dart';
import 'package:rewayah_academy/features/com_messages/fil_en_place.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/envoi_fil.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';
import '../com_messages/support_messages.dart';
import 'hote_candidature.dart';

const Participant _candidat = Participant(
  id: 'p-amina',
  nomAffiche: 'Amina Diallo',
  fonction: 'Candidate',
);

ConversationPossible get _conversation => ConversationPossible(
  interlocuteur: _candidat,
  nature: NatureInterlocuteur.personne,
  objet: ObjetLie(
    type: TypeObjetLie.candidature,
    id: 'c1',
    libelle: 'Candidature',
  ),
  filId: 'fil-cand',
);

FauxMessagesMetier _messages() => FauxMessagesMetier(
  fils: <FilMetier>[
    filAvec(
      id: 'fil-cand',
      autre: _candidat,
      objets: <ObjetLie>[
        ObjetLie(
          type: TypeObjetLie.candidature,
          id: 'c1',
          libelle: 'Candidature',
        ),
      ],
      texte: 'Bonjour, ma pièce est prête.',
    ),
  ],
  conversations: <String, List<ConversationPossible>>{
    cleObjet(TypeObjetLie.candidature, 'c1'): <ConversationPossible>[
      _conversation,
    ],
  },
);

Future<GoRouter> _monter(
  WidgetTester tester,
  FauxMessagesMetier messages, {
  required double largeur,
  double hauteur = 3000,
  TextDirection? direction,
}) async {
  final PortCandidaturesDirection port = FauxCandidaturesDirection(
    capacitesRendues: capacitesGestes,
    details: <DetailCandidature>[detailTest()],
  );
  await monterRecrutement(
    tester,
    chemin: Routes.adminPersonnesCandidature,
    depart: Routes.adminPersonnesCandidaturePour(referenceTest),
    ecran: (_) => const CandidatureDirectionPage(
      reference: referenceTest,
      identifiant: 'c1',
    ),
    autres: <String>[
      Routes.adminPersonnesCandidatures,
      '${Routes.adminCommunicationsMessages}/:fil',
    ],
    surcharges: [
      portCandidaturesDirectionProvider.overrideWithValue(port),
      portMessagesMetierProvider.overrideWithValue(messages),
      capaciteEcrireOuverteTest,
    ],
    largeur: largeur,
    hauteur: hauteur,
    direction: direction,
  );
  // BE-DOSSIER : les messages vivent sous leur rubrique, ouverte ici.
  await ouvrirToutesLesRubriques(tester);
  return GoRouter.of(
    tester.element(find.byKey(CandidatureDirectionPage.clePage)),
  );
}

Finder get _ecrire =>
    find.text(t.com.messages.entree.ecrireA(nom: _candidat.nomAffiche));

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await laisser(tester, fois: 2);
  await tester.tap(f, warnIfMissed: false);
  await laisser(tester);
}

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  testWidgets('ordinateur : la conversation s\'ouvre a cote du dossier', (
    WidgetTester tester,
  ) async {
    final FauxMessagesMetier messages = _messages();
    final GoRouter routeur = await _monter(tester, messages, largeur: 1440);
    final String adresse = cheminCourant(routeur);
    expect(_ecrire, findsOneWidget);

    await _toucher(tester, _ecrire);

    // Le volet est la, a droite du dossier, et l'adresse n'a pas bouge.
    expect(find.byKey(VoletConversation.cle), findsOneWidget);
    expect(find.byKey(FilEnPlace.cle), findsOneWidget);
    expect(cheminCourant(routeur), adresse);
    expect(find.byKey(CandidatureDirectionPage.clePage), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(VoletConversation.cle)).dx,
      greaterThan(
        tester.getTopLeft(find.byKey(CandidatureDirectionPage.clePage)).dx,
      ),
    );
    expect(find.text('Bonjour, ma pièce est prête.'), findsOneWidget);

    // On ecrit, dans le dossier.
    await tester.enterText(
      find.byKey(FilDiscussion.champKey),
      'Merci, déposez-la depuis votre portail.',
    );
    await laisser(tester, fois: 2);
    await tester.tap(envoiDuFil());
    await laisser(tester);
    expect(messages.envois, hasLength(1));
    expect(messages.envois.single.$1, 'fil-cand');
    verifierUnSeulBoutonPlein(tester);

    // On replie : le dossier reste, a la meme adresse.
    await _toucher(tester, find.byKey(VoletConversation.cleReplier));
    expect(find.byKey(VoletConversation.cle), findsNothing);
    expect(find.byKey(CandidatureDirectionPage.clePage), findsOneWidget);
    expect(cheminCourant(routeur), adresse);
  });

  testWidgets('ordinateur : « Ouvrir dans Messages » reste un lien '
      'secondaire, et le retour ramene au dossier', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(tester, _messages(), largeur: 1440);
    final String adresse = cheminCourant(routeur);
    await _toucher(tester, _ecrire);
    await _toucher(tester, find.byKey(VoletConversation.cleMessages));
    expect(
      find.text('temoin:${Routes.adminCommunicationsMessages}/:fil'),
      findsOneWidget,
    );
    routeur.pop();
    await laisser(tester);
    expect(cheminCourant(routeur), adresse);
    expect(find.byKey(CandidatureDirectionPage.clePage), findsOneWidget);
  });

  testWidgets('telephone : la conversation monte en feuille et se replie '
      'sur le dossier', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(tester, _messages(), largeur: 390);
    final String adresse = cheminCourant(routeur);
    await _toucher(tester, _ecrire);

    expect(find.byKey(VoletConversation.cle), findsOneWidget);
    expect(find.byKey(FilEnPlace.cle), findsOneWidget);
    expect(find.text('Bonjour, ma pièce est prête.'), findsOneWidget);
    expect(cheminCourant(routeur), adresse);

    await _toucher(
      tester,
      find.bySemanticsLabel(t.com.messages.entree.replier).first,
    );
    expect(find.byKey(VoletConversation.cle), findsNothing);
    expect(find.byKey(CandidatureDirectionPage.clePage), findsOneWidget);
    expect(cheminCourant(routeur), adresse);
  });

  // Captures R3 (sautees sans CAPTURE_DIR) : 1440 et 390, francais et arabe,
  // theme clair ; la conversation ouverte dans le dossier.
  group('captures recrutement sans sortie', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(1440, 900),
        const Size(390, 844),
      ]) {
        testWidgets('conversation-dossier-${taille.width.toInt()}-'
            '${langue.languageCode}', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            _messages(),
            largeur: taille.width,
            hauteur: taille.height,
            direction: langue == AppLocale.ar
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
          final Finder ecrire = find.text(
            t.com.messages.entree.ecrireA(nom: _candidat.nomAffiche),
          );
          await _toucher(tester, ecrire);
          await stabiliser(tester);
          await capturerVue(
            tester,
            'recrutement-sans-sortie/conversation-dossier-'
            '${taille.width.toInt()}-${langue.languageCode}',
          );
        });
      }
    }
  }, skip: sautSansCapture);
}
