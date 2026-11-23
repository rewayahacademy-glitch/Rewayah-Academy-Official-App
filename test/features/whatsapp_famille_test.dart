// WHATSAPP-FAMILLE (directeur, 23/11/2026) : le numero WhatsApp de la famille.
//
// Ce que le test prouve : la direction lit le numero (demande, fiche) avec
// « Ouvrir WhatsApp » vers `https://wa.me/<numero sans +>`, et ses quatre
// etats (lecture, numero, aucun numero, echec) ; la ligne de l'accueil de la
// famille n'existe que pour un compte qui peut donner un numero et n'en a pas,
// et l'enregistre au format international ; le pays se propose d'apres l'appareil
// ou le fuseau, jamais au hasard. 320 et 1440 px, texte x2.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/whatsapp_direction.dart';
import 'package:rewayah_academy/core/dossier/whatsapp_famille.dart';
import 'package:rewayah_academy/core/fichiers/ouvrir_onglet.dart';
import 'package:rewayah_academy/core/i18n/pays_du_fuseau.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/accueil_famille/ligne_whatsapp_famille.dart';
import 'package:rewayah_academy/features/admin_admissions/ligne_whatsapp_direction.dart';

import '../capture/outil_capture.dart';
import '../support/hote_theme.dart';

class _PortDirection implements PortWhatsappDirection {
  _PortDirection(this.reponse);

  final Future<String?> Function() reponse;
  final List<CibleWhatsapp> lues = <CibleWhatsapp>[];

  @override
  Future<String?> lire(CibleWhatsapp cible) {
    lues.add(cible);
    return reponse();
  }
}

class _PortFamille implements PortWhatsappFamille {
  _PortFamille(this.etat);

  EtatWhatsapp etat;
  final List<String> definis = <String>[];
  bool echec = false;

  @override
  Future<EtatWhatsapp> lire() async => etat;

  @override
  Future<void> definir(String numero) async {
    if (echec) {
      throw StateError('refus');
    }
    definis.add(numero);
    etat = (possible: true, numero: numero);
  }
}

const CibleWhatsapp _cible = (candidatureId: 'c1', profilId: null);

void main() {
  group('la direction lit le numero', () {
    testWidgets('numero, lien wa.me sans le plus, 320 et 1440 px', (
      WidgetTester tester,
    ) async {
      for (final Size vue in <Size>[const Size(320, 700), vueBureau]) {
        fixerVue(tester, vue);
        final _PortDirection port = _PortDirection(() async => '+33612345678');
        final List<Uri> ouverts = <Uri>[];
        await tester.pumpWidget(
          hoteTheme(
            const LigneWhatsappDirection(cible: _cible),
            echelleTexte: 2,
            surcharges: <Override>[
              portWhatsappDirectionProvider.overrideWithValue(port),
              ouvreurOngletProvider.overrideWithValue((Uri lien) async {
                ouverts.add(lien);
                return true;
              }),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(t.whatsapp.direction), findsOneWidget);
        expect(find.textContaining('33612345678'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(LigneWhatsappDirection.cleOuvrir));
        await tester.pumpAndSettle();
        expect(ouverts.single.toString(), 'https://wa.me/33612345678');
        expect(port.lues.single, _cible);
      }
    });

    testWidgets('aucun numero : une phrase, pas de lien', (tester) async {
      fixerVue(tester, vueBureau);
      await tester.pumpWidget(
        hoteTheme(
          const LigneWhatsappDirection(cible: _cible),
          surcharges: <Override>[
            portWhatsappDirectionProvider.overrideWithValue(
              _PortDirection(() async => null),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.whatsapp.absent), findsOneWidget);
      expect(find.byKey(LigneWhatsappDirection.cleOuvrir), findsNothing);
    });

    testWidgets('lecture impossible : la phrase le dit', (tester) async {
      fixerVue(tester, vueBureau);
      await tester.pumpWidget(
        hoteTheme(
          const LigneWhatsappDirection(cible: _cible),
          surcharges: <Override>[
            portWhatsappDirectionProvider.overrideWithValue(
              _PortDirection(() async => throw StateError('refus')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.whatsapp.illisible), findsOneWidget);
      expect(find.byKey(LigneWhatsappDirection.cleOuvrir), findsNothing);
    });

    test('le lien wa.me ignore tout ce qui n est pas un chiffre', () {
      expect(
        lienWhatsapp('+44 7700 900123').toString(),
        'https://wa.me/447700900123',
      );
    });
  });

  group('l accueil de la famille', () {
    Future<_PortFamille> monter(WidgetTester tester, EtatWhatsapp etat) async {
      fixerVue(tester, const Size(390, 800));
      final _PortFamille port = _PortFamille(etat);
      await tester.pumpWidget(
        hoteTheme(
          const LigneWhatsappFamille(),
          surcharges: <Override>[
            portWhatsappFamilleProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return port;
    }

    testWidgets('pas de numero : la ligne est la, et enregistre', (
      tester,
    ) async {
      final _PortFamille port = await monter(tester, (
        possible: true,
        numero: null,
      ));
      expect(find.text(t.whatsapp.accueilLigne), findsOneWidget);
      await tester.tap(find.text(t.whatsapp.accueilLigne));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('whatsapp-numero')),
        '2025550123',
      );
      await tester.tap(find.byKey(LigneWhatsappFamille.cleEnregistrer));
      await tester.pumpAndSettle();
      expect(port.definis.single, '+12025550123');
      // Le numero existe : la ligne disparait.
      expect(find.byKey(LigneWhatsappFamille.cleLigne), findsNothing);
    });

    testWidgets(
      'un numero illisible : rien ne part, la phrase dit quoi faire',
      (tester) async {
        final _PortFamille port = await monter(tester, (
          possible: true,
          numero: null,
        ));
        await tester.tap(find.text(t.whatsapp.accueilLigne));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey<String>('whatsapp-numero')),
          'abc',
        );
        await tester.tap(find.byKey(LigneWhatsappFamille.cleEnregistrer));
        await tester.pumpAndSettle();
        expect(port.definis, isEmpty);
        expect(
          find.text(t.inscription.telephone.numeroInvalide),
          findsOneWidget,
        );
      },
    );

    testWidgets('un refus du serveur se dit, rien n est perdu', (tester) async {
      final _PortFamille port =
          await monter(tester, (possible: true, numero: null))
            ..echec = true;
      await tester.tap(find.text(t.whatsapp.accueilLigne));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('whatsapp-numero')),
        '2025550123',
      );
      await tester.tap(find.byKey(LigneWhatsappFamille.cleEnregistrer));
      await tester.pumpAndSettle();
      expect(find.text(t.whatsapp.echec), findsOneWidget);
      expect(port.definis, isEmpty);
    });

    testWidgets('numero deja donne : aucune ligne', (tester) async {
      await monter(tester, (possible: true, numero: '+33612345678'));
      expect(find.byKey(LigneWhatsappFamille.cleLigne), findsNothing);
    });

    testWidgets('compte sans demande : aucune ligne', (tester) async {
      await monter(tester, (possible: false, numero: null));
      expect(find.byKey(LigneWhatsappFamille.cleLigne), findsNothing);
    });
  });

  group('le pays propose', () {
    test('la langue de l appareil d abord, sinon le fuseau, sinon rien', () {
      expect(
        paysPourIndicatif(
          locale: const Locale('fr', 'BE'),
          fuseau: 'Europe/Paris',
        ),
        'BE',
      );
      expect(
        paysPourIndicatif(
          locale: const Locale('fr'),
          fuseau: 'Africa/Casablanca',
        ),
        'MA',
      );
      expect(
        paysPourIndicatif(locale: const Locale('fr'), fuseau: 'Pacific/Fiji'),
        isNull,
      );
      expect(paysPourIndicatif(locale: const Locale('fr')), isNull);
    });
  });

  // Captures R3 : jamais sans `CAPTURE_DIR`.
  group(
    'Capture : WHATSAPP-FAMILLE direction et accueil',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      testWidgets('direction_whatsapp_fr_1440', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(1440, 260), 1);
        await tester.pumpWidget(
          hoteCapture(
            Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: const LigneWhatsappDirection(cible: _cible),
                ),
              ),
            ),
            surcharges: <Override>[
              portWhatsappDirectionProvider.overrideWithValue(
                _PortDirection(() async => '+33612345678'),
              ),
            ],
          ),
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'direction_whatsapp_fr_1440')}',
        );
      });

      testWidgets('accueil_whatsapp_fr_390', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 220), 1);
        await tester.pumpWidget(
          hoteCapture(
            const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: LigneWhatsappFamille(),
              ),
            ),
            surcharges: <Override>[
              portWhatsappFamilleProvider.overrideWithValue(
                _PortFamille((possible: true, numero: null)),
              ),
            ],
          ),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, 'accueil_whatsapp_fr_390')}');
      });
    },
  );
}
