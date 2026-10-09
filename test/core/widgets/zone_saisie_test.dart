// SUPERPOS-1 (05/10/2026, decision prise par delegation) : la zone de
// saisie partagee et le fil de discussion qui l'emploie.
//
// Mesures par rectangles a 320 en texte double (LTR et RTL), 390 et 1440,
// clavier ferme et ouvert :
// - le bouton d'envoi est DANS le rectangle du champ, a son bord de fin, et
//   centre en hauteur, quelle que soit la hauteur du champ ;
// - le champ vide n'a aucun bouton grise : le bouton n'est pas rendu, sa
//   place est gardee, la raison est ecrite sous le champ ;
// - le champ grandit avec le texte, sans depasser les deux cinquiemes de la
//   hauteur visible ;
// - l'etiquette est au-dessus du champ, sans le recouvrir, sans mot coupe ;
// - le fil ne deborde pas, clavier ouvert a 320 en texte double.
//
// Contre-epreuve faite sur l'ancien `FilDiscussion` (bouton « Envoyer » a
// cote du champ, inerte quand le champ est vide, `Column` simple) : les
// tests du groupe « fil de discussion » echouent tous (bouton hors du champ,
// `ActionPrincipale` inerte rendue, debordement de 134 px).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/zone_saisie.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

const Key _champ = ValueKey<String>('champ');
const Key _envoi = ValueKey<String>('envoi');

/// Taille de vue, echelle du texte, sens, clavier.
typedef _Vue = (Size, double, TextDirection, double);

const List<_Vue> _vues = <_Vue>[
  (Size(320, 640), 2, TextDirection.ltr, 0),
  (Size(320, 640), 2, TextDirection.rtl, 0),
  (Size(320, 640), 2, TextDirection.ltr, 300),
  (Size(390, 844), 1, TextDirection.ltr, 0),
  (Size(390, 844), 1, TextDirection.rtl, 300),
  (Size(1440, 900), 1, TextDirection.ltr, 0),
];

String _nom(_Vue v) =>
    '${v.$1.width.toInt()} x${v.$2.toInt()} ${v.$3.name}'
    '${v.$4 > 0 ? ' clavier' : ''}';

void _fixer(WidgetTester tester, _Vue v) {
  tester.view.physicalSize = v.$1;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: v.$4);
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = v.$2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Widget _sens(_Vue v, Widget enfant) =>
    Directionality(textDirection: v.$3, child: enfant);

/// Le bouton d'envoi est dans le champ, a son bord de fin, centre en hauteur.
void _verifierEnvoiIntegre(
  WidgetTester tester,
  Finder champ,
  Finder envoi,
  TextDirection sens,
) {
  final Rect c = tester.getRect(champ);
  final Rect b = tester.getRect(envoi);
  expect(
    c.contains(b.topLeft) && c.contains(b.bottomRight - const Offset(1, 1)),
    isTrue,
    reason: 'le bouton d envoi $b sort du champ $c',
  );
  expect(
    (b.center.dy - c.center.dy).abs(),
    lessThanOrEqualTo(toleranceGarde),
    reason: 'le bouton d envoi n est pas centre en hauteur : $b dans $c',
  );
  // Au bord de fin : plus pres de la fin que du debut.
  final double fin = sens == TextDirection.ltr
      ? c.right - b.right
      : b.left - c.left;
  final double debut = sens == TextDirection.ltr
      ? b.left - c.left
      : c.right - b.right;
  expect(fin, lessThan(debut), reason: 'le bouton n est pas au bord de fin');
}

void main() {
  // Les vraies polices : un mot se mesure a sa vraie largeur, pas a celle
  // des carres de la police de test.
  setUpAll(chargerPolicesDuDepot);

  group('ZoneSaisie', () {
    // SUPERPOS-1, reprise : l'aide du champ vide (« Repondre a
    // l'administration… », celle du fil du controleur) se coupait dans un mot
    // a 320 en texte double (« administratio / n… »). Contre-epreuve faite :
    // echoue sur l'ancien code (aide rendue par `hintText`).
    for (final _Vue v in _vues) {
      testWidgets('${_nom(v)} : l aide du champ vide garde ses mots '
          'entiers', (WidgetTester tester) async {
        _fixer(tester, v);
        final TextEditingController texte = TextEditingController();
        addTearDown(texte.dispose);
        await tester.pumpWidget(
          hote(
            _sens(
              v,
              Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ZoneSaisie(
                      controleur: texte,
                      cleChamp: _champ,
                      libelle: 'Répondre à l administration',
                      aide: 'Répondre à l\'administration…',
                      explication:
                          'Écrivez un message pour pouvoir '
                          'l\'envoyer.',
                      envoi: EnvoiZoneSaisie(
                        cle: _envoi,
                        libelle: 'Envoyer',
                        onEnvoyer: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Répondre à l\'administration…'), findsOneWidget);
        verifierAucunMotCoupe(tester, find.byType(ZoneSaisie));
      });
    }

    for (final _Vue v in _vues) {
      testWidgets('${_nom(v)} : envoi integre et centre, a une ligne et a '
          'plusieurs', (WidgetTester tester) async {
        _fixer(tester, v);
        final TextEditingController texte = TextEditingController();
        addTearDown(texte.dispose);
        await tester.pumpWidget(
          hote(
            _sens(
              v,
              Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ZoneSaisie(
                      controleur: texte,
                      cleChamp: _champ,
                      libelle: 'Répondre à l administration',
                      aide: 'Message',
                      envoi: EnvoiZoneSaisie(
                        cle: _envoi,
                        libelle: 'Envoyer',
                        onEnvoyer: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        // Vide : rien de grise, la place est gardee.
        expect(find.byKey(_envoi), findsNothing);
        expect(find.byKey(ZoneSaisie.placeEnvoiKey), findsOneWidget);
        _verifierEnvoiIntegre(
          tester,
          find.byKey(_champ),
          find.byKey(ZoneSaisie.placeEnvoiKey),
          v.$3,
        );

        await tester.enterText(find.byKey(_champ), 'Bonjour.');
        await tester.pump();
        expect(find.byType(BoutonIcone), findsOneWidget);
        _verifierEnvoiIntegre(
          tester,
          find.byKey(_champ),
          find.byKey(_envoi),
          v.$3,
        );
        final double uneLigne = tester.getSize(find.byKey(_champ)).height;

        await tester.enterText(find.byKey(_champ), 'Un\ndeux\ntrois\nquatre');
        await tester.pump();
        final double plusieurs = tester.getSize(find.byKey(_champ)).height;
        _verifierEnvoiIntegre(
          tester,
          find.byKey(_champ),
          find.byKey(_envoi),
          v.$3,
        );
        // La hauteur grandit avec le texte...
        expect(plusieurs, greaterThan(uneLigne));
        // ... sans depasser les deux cinquiemes de la vue visible (plus
        // les marges internes du champ).
        final double visible = v.$1.height - v.$4;
        expect(
          plusieurs,
          lessThanOrEqualTo(visible * ZoneSaisie.partMaxVue + toleranceGarde),
        );
      });

      testWidgets('${_nom(v)} : etiquette au-dessus, sans recouvrement ni '
          'mot coupe, aide et erreur entieres', (WidgetTester tester) async {
        _fixer(tester, v);
        final TextEditingController texte = TextEditingController();
        addTearDown(texte.dispose);
        await tester.pumpWidget(
          hote(
            _sens(
              v,
              Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ZoneSaisie(
                    controleur: texte,
                    cleChamp: _champ,
                    libelle: 'Observation de la séance, en quelques phrases',
                    explication:
                        'Décrivez ce que vous avez vu, sans nom de famille.',
                    erreur: 'Écrivez votre observation avant de continuer.',
                    minLignes: 4,
                    maxLignes: 8,
                  ),
                ),
              ),
            ),
          ),
        );
        verifierSansChevauchement(tester, <Finder>[
          find.text('Observation de la séance, en quelques phrases'),
          find.byType(InputDecorator),
        ]);
        expect(
          tester
              .getRect(
                find.text('Observation de la séance, en quelques phrases'),
              )
              .bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(InputDecorator)).top),
        );
        expect(motsCoupes(tester, find.byType(Scaffold)), isEmpty);
      });
    }
  });

  group('fil de discussion (SUPERPOS-1)', () {
    Future<void> monter(WidgetTester tester, _Vue v) async {
      _fixer(tester, v);
      await tester.pumpWidget(
        hote(
          _sens(
            v,
            PageShell(
              titre: 'Classe Al-Badr',
              defilante: false,
              child: FilDiscussion(
                messages: const <MessageFil>[
                  MessageFil(
                    id: '1',
                    auteur: 'Administration',
                    texte: 'Merci, c est noté.',
                    horodatage: 'Vendredi 25 septembre, 09:30',
                    deSoi: false,
                  ),
                ],
                textes: TextesFilDiscussion(
                  aideChamp: 'Répondre à l administration…',
                  libelleChamp: 'Répondre à l administration',
                  envoyer: 'Envoyer',
                  champVide: 'Écrivez un message pour pouvoir l envoyer.',
                  enCours: 'Envoi en cours.',
                  envoye: 'Envoyé.',
                  echec: 'L envoi n est pas confirmé.',
                  reessayer: 'Réessayer',
                  auteurSoi: 'Vous',
                  annonce: (String a, String t) => '$a : $t',
                ),
                onEnvoyer: (String _) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final _Vue v in _vues) {
      testWidgets('${_nom(v)} : aucun bouton grise quand le champ est vide', (
        WidgetTester tester,
      ) async {
        await monter(tester, v);
        expect(tester.takeException(), isNull);
        expect(find.byType(ActionPrincipale), findsNothing);
        expect(find.byKey(FilDiscussion.envoyerKey), findsNothing);
        expect(
          find.text('Écrivez un message pour pouvoir l envoyer.'),
          findsOneWidget,
        );
      });

      testWidgets('${_nom(v)} : envoi dans le champ, centre ; aucun '
          'debordement, aucun recouvrement', (WidgetTester tester) async {
        await monter(tester, v);
        await tester.enterText(
          find.byKey(FilDiscussion.champKey),
          'Merci pour votre retour.\nJe joins le complément.\nBonne journée.',
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byKey(FilDiscussion.champKey));
        await tester.pumpAndSettle();
        _verifierEnvoiIntegre(
          tester,
          find.byKey(FilDiscussion.champKey),
          find.byKey(FilDiscussion.envoyerKey),
          v.$3,
        );
        // Le champ ne passe pas sous la bulle, ni la bulle sous le champ :
        // la part VISIBLE de la bulle (coupee par la liste qui defile) ne
        // touche pas le champ.
        final Rect bulle = tester
            .getRect(find.byKey(const ValueKey<String>('message-1')))
            .intersect(tester.getRect(find.byType(ListView)));
        final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
        final Rect commun = bulle.intersect(champ);
        expect(
          bulle.isEmpty ||
              commun.width <= toleranceGarde ||
              commun.height <= toleranceGarde,
          isTrue,
          reason: 'la bulle visible $bulle recouvre le champ $champ',
        );
        // Le champ et son bouton restent dans la largeur de l'ecran.
        final Rect c = tester.getRect(find.byKey(FilDiscussion.champKey));
        expect(c.left, greaterThanOrEqualTo(0));
        expect(c.right, lessThanOrEqualTo(v.$1.width));
      });
    }
  });
}
