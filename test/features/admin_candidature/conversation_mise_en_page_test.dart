// CONVERSATIONS-PARTOUT (directeur, 16/11/2026) : la conversation ouverte
// depuis le dossier d'un candidat a la mise en page de la messagerie refaite,
// ouverte dans un volet (ordinateur) ou une page plein ecran (telephone) :
// - une seule barre compacte d'une rangee (avatar a cote du nom), jamais un
//   gros titre « Conversation avec ... », un lien d'en-tete ou un second bloc
//   d'identite empiles au-dessus du fil ;
// - aucune phrase d'aide sous le champ ;
// - une marge entre la bulle et le bord du cadre ;
// - aucune exception, a toutes les tailles, en francais et en arabe, a texte
//   agrandi, clavier ouvert.

import 'package:flutter/material.dart' show Brightness, ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/tete_panneau.dart';
import 'package:rewayah_academy/features/admin_candidature/candidature_page.dart';
import 'package:rewayah_academy/features/admin_candidature/volet_conversation.dart';
import 'package:rewayah_academy/features/com_messages/barre_conversation.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/candidature/faux_candidatures_direction.dart';
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

/// Un fil de quarante messages : assez long pour remonter vers les anciens.
FauxMessagesMetier _messagesLongs() {
  const Participant soi = Participant(
    id: 'soi',
    nomAffiche: 'Vous',
    estSoi: true,
  );
  final ObjetLie objet = ObjetLie(
    type: TypeObjetLie.candidature,
    id: 'c1',
    libelle: 'Candidature',
  );
  return FauxMessagesMetier(
    fils: <FilMetier>[
      FilMetier(
        id: 'fil-cand',
        contexte: <ElementContexteFil>[
          ElementContexteFil(objet: objet, accessible: true),
        ],
        participants: const <Participant>[soi, _candidat],
        messages: <MessageCommunication>[
          for (int i = 0; i < 40; i++)
            MessageCommunication(
              id: 'fil-cand-m$i',
              auteur: i.isEven ? _candidat : soi,
              texte: 'Message numero $i de la conversation du dossier.',
              envoyeLe: maintenantTest.subtract(Duration(hours: 100 - i)),
            ),
        ],
        attention: IndicateurAttention.aucun,
        capacites: const <CapaciteFil>{CapaciteFil.ecrire},
      ),
    ],
    conversations: <String, List<ConversationPossible>>{
      cleObjet(TypeObjetLie.candidature, 'c1'): <ConversationPossible>[
        _conversation,
      ],
    },
  );
}

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
  double echelle = 1,
  ThemeMode themeMode = ThemeMode.light,
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
    echelle: echelle,
    themeMode: themeMode,
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

  final List<(String, Size, double, bool)> tailles =
      <(String, Size, double, bool)>[
        ('1440', const Size(1440, 900), 1, false),
        ('390', const Size(390, 844), 1, false),
        ('390 court', const Size(390, 600), 1, false),
        ('390 texte x2', const Size(390, 844), 2, false),
        ('390 clavier', const Size(390, 700), 1, true),
        ('320 texte x2 clavier', const Size(320, 640), 2, true),
        ('768', const Size(768, 1024), 1, false),
      ];
  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    for (final (String nom, Size taille, double echelle, bool clavier)
        in tailles) {
      testWidgets('${langue.languageCode} $nom : barre compacte, rien de '
          'l\'ancien en-tete, aucune exception', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        final bool rtl = langue == AppLocale.ar;
        await _monter(
          tester,
          _messages(),
          largeur: taille.width,
          hauteur: taille.height,
          echelle: echelle,
          direction: rtl ? TextDirection.rtl : TextDirection.ltr,
        );
        await _toucher(tester, _ecrire);
        await laisser(tester, fois: 3);
        if (clavier) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          addTearDown(tester.view.resetViewInsets);
          await tester.tap(
            find.byKey(FilDiscussion.champKey),
            warnIfMissed: false,
          );
          await laisser(tester, fois: 3);
        }

        final Finder volet = find.byKey(VoletConversation.cle);
        expect(volet, findsOneWidget);
        // Une seule barre, celle de la messagerie refaite.
        expect(
          find.descendant(
            of: volet,
            matching: find.byKey(BarreConversation.cle),
          ),
          findsOneWidget,
        );
        // L'ancien en-tete est parti : ni titre de panneau, ni lien, ni bloc
        // d'identite empile.
        expect(
          find.descendant(of: volet, matching: find.byType(TetePanneau)),
          findsNothing,
        );
        expect(
          find.descendant(of: volet, matching: find.byType(LienFleche)),
          findsNothing,
        );
        expect(
          find.descendant(of: volet, matching: find.byType(EnteteFilContexte)),
          findsNothing,
        );
        // Avatar a cote du nom, dans la barre.
        if (!clavier) {
          expect(
            find.descendant(
              of: find.byKey(BarreConversation.cle),
              matching: find.byType(AvatarNom),
            ),
            findsOneWidget,
          );
        }
        // Le nom n'est ecrit qu'une fois dans la conversation (pas de second
        // bloc d'identite).
        expect(
          find.descendant(of: volet, matching: find.text(_candidat.nomAffiche)),
          findsOneWidget,
        );
        // Aucune phrase d'aide sous le champ.
        expect(
          find.text(t.com.socle.composants.composer.champVide),
          findsNothing,
        );
        // Une marge entre la bulle et le bord du cadre.
        final Rect cadre = tester.getRect(volet);
        final Rect bulle = tester.getRect(
          find.text('Bonjour, ma pièce est prête.'),
        );
        final double ecart = rtl
            ? cadre.right - bulle.right
            : bulle.left - cadre.left;
        expect(ecart, greaterThanOrEqualTo(AppSpacing.lg));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('ordinateur : la croix de la barre replie, « Ouvrir dans '
      'Messages » est un bouton d\'icone de la barre', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _messages(), largeur: 1440);
    await _toucher(tester, _ecrire);
    expect(
      find.descendant(
        of: find.byKey(BarreConversation.cle),
        matching: find.byKey(VoletConversation.cleMessages),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(BarreConversation.cle),
        matching: find.byKey(VoletConversation.cleReplier),
      ),
      findsOneWidget,
    );
  });

  // MESSAGERIE-COULEURS (pilote, 16/11/2026, regression de #540 : « sur
  // ordinateur, la croix a disparu, le volet ne peut plus etre ferme »). La
  // croix « Fermer la conversation » est au bord de FIN de la barre, la barre
  // d'un volet ne se replie jamais quand on remonte un long fil, et Echap
  // ferme le volet. Echoue sur main : pas de croix au bord de fin, barre
  // repliee au defilement, Echap sans effet.
  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    for (final double largeur in <double>[1024, 1440]) {
      final String cas = '${langue.languageCode} ${largeur.toInt()}';
      testWidgets('volet, $cas : croix au bord de fin, toujours atteignable, '
          'ferme par la croix et par Echap', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        final bool rtl = langue == AppLocale.ar;
        await _monter(
          tester,
          _messagesLongs(),
          largeur: largeur,
          hauteur: 900,
          direction: rtl ? TextDirection.rtl : TextDirection.ltr,
        );
        final Finder croix = find.descendant(
          of: find.byKey(BarreConversation.cle),
          matching: find.byKey(VoletConversation.cleReplier),
        );

        // 1. La croix est le controle du bord de FIN de la barre.
        await _toucher(tester, _ecrire);
        await laisser(tester, fois: 3);
        expect(find.byKey(VoletConversation.cle), findsOneWidget);
        expect(croix, findsOneWidget);
        final Rect barre = tester.getRect(find.byKey(BarreConversation.cle));
        final Rect c = tester.getRect(croix);
        if (rtl) {
          expect(c.center.dx, lessThan(barre.center.dx));
          expect(c.left - barre.left, lessThan(24));
        } else {
          expect(c.center.dx, greaterThan(barre.center.dx));
          expect(barre.right - c.right, lessThan(24));
        }

        // 2. Elle reste atteignable quand on remonte vers les anciens messages.
        await tester.drag(
          find.byKey(FilDiscussion.cleMessages),
          const Offset(0, 600),
          warnIfMissed: false,
        );
        await laisser(tester, fois: 3);
        expect(croix.hitTestable(), findsOneWidget);
        expect(
          tester.getSize(find.byKey(BarreConversation.cle)).height,
          greaterThan(0),
        );

        // 3. La croix ferme le volet.
        await tester.tap(croix);
        await laisser(tester, fois: 3);
        expect(find.byKey(VoletConversation.cle), findsNothing);

        // 4. Echap ferme le volet, focus dans le champ comme ailleurs.
        await _toucher(tester, _ecrire);
        await laisser(tester, fois: 3);
        expect(find.byKey(VoletConversation.cle), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await laisser(tester, fois: 3);
        expect(find.byKey(VoletConversation.cle), findsNothing);
      });
    }
  }

  // MESSAGERIE-COULEURS (pilote, 16/11/2026) : a l'ouverture, au bout du fil,
  // le dernier message et son heure restent entierement au-dessus du champ.
  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    testWidgets('volet, ${langue.languageCode} : le dernier message et son '
        'heure ne passent pas sous le champ', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(langue));
      await _monter(
        tester,
        _messagesLongs(),
        largeur: 1440,
        hauteur: 900,
        direction: langue == AppLocale.ar
            ? TextDirection.rtl
            : TextDirection.ltr,
      );
      await _toucher(tester, _ecrire);
      await laisser(tester, fois: 5);
      final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
      final Finder dernier = find.textContaining('Message numero 39');
      expect(dernier, findsOneWidget);
      expect(tester.getRect(dernier).bottom, lessThanOrEqualTo(champ.top));
      // L'heure du dernier message (a sa suite) est visible, hors du champ.
      final Finder heures = find.descendant(
        of: find.byKey(FilDiscussion.cleMessages),
        matching: find.textContaining(RegExp(r'^\d{2}:\d{2}$')),
      );
      final double basHeure = heures
          .evaluate()
          .map((e) => tester.getRect(find.byWidget(e.widget)).bottom)
          .reduce((double a, double b) => a > b ? a : b);
      expect(basHeure, lessThanOrEqualTo(champ.top));
    });
  }

  // MESSAGERIE-COULEURS : captures R3 du volet de conversation sur ordinateur
  // (1440 x 900), fil remonte vers les anciens messages, croix visible.
  // Sautees sans CAPTURE_DIR.
  group('captures volet', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Brightness lum in <Brightness>[
        Brightness.light,
        Brightness.dark,
      ]) {
        final String nom =
            'volet-1440-${langue.languageCode}-'
            '${lum == Brightness.dark ? 'sombre' : 'clair'}';
        testWidgets(nom, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            _messagesLongs(),
            largeur: 1440,
            hauteur: 900,
            direction: langue == AppLocale.ar
                ? TextDirection.rtl
                : TextDirection.ltr,
            themeMode: lum == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
          );
          await _toucher(tester, _ecrire);
          await laisser(tester, fois: 3);
          await tester.drag(
            find.byKey(FilDiscussion.cleMessages),
            const Offset(0, 600),
            warnIfMissed: false,
          );
          await laisser(tester, fois: 3);
          expect(
            find
                .descendant(
                  of: find.byKey(BarreConversation.cle),
                  matching: find.byKey(VoletConversation.cleReplier),
                )
                .hitTestable(),
            findsOneWidget,
          );
          await capturerVue(tester, 'MESSAGERIE-COULEURS/$nom');
        });
      }
    }
  }, skip: sautSansCapture);
}
