// PAIEMENTS-TUTEUR (garde-cap, 12/11/2026) : la famille voit ce qu'elle a
// paye. Une ligne « Paiements » au Compte (capacite, pas role : absente sans
// source) ; la page dit, pour chaque paiement, le montant rendu par le
// serveur (formate, aucun calcul), son statut en mots et son jour au fuseau
// du profil ; jamais un recu qui n'existe pas ; le refus du serveur (42501,
// second adulte) se dit en clair, sans « Reessayer ».

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/features/compte/compte_tuteur_page.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../capture/outil_capture.dart'
    show
        capturerVue,
        chargerPolicesDuDepot,
        masquerRubanDebug,
        sautSansCapture,
        stabiliser;
import '../../fixtures/tuteur/faux_capacites.dart';
import 'support_compte.dart';

final List<PaiementFoyer> _deux = <PaiementFoyer>[
  // 20:00 UTC le 12/11 : deja le 13/11 au fuseau du profil (+05:30).
  PaiementFoyer(
    id: '2',
    montantMineur: 5500,
    devise: 'USD',
    statutServeur: 'en_confirmation',
    date: DateTime.utc(2026, 11, 12, 20),
    justificatifDisponible: false,
  ),
  PaiementFoyer(
    id: '1',
    montantMineur: 11000,
    devise: 'USD',
    statutServeur: 'confirme',
    date: DateTime.utc(2026, 10, 3, 9),
    justificatifDisponible: false,
  ),
];

class _Refus extends FauxPaiementsFoyer {
  @override
  Future<List<PaiementFoyer>> historique() => Future<List<PaiementFoyer>>.error(
    const PostgrestException(message: 'refus', code: '42501'),
  );
}

final MonHorloge _kolkata = MonHorloge.lire(const <String, Object?>{
  'maintenant': '2026-11-12T12:00:00Z',
  'moi': <String, Object?>{
    'fuseau': 'Asia/Kolkata',
    'decalage_secondes': 19800,
  },
});

/// Le port et l'horloge du profil : monHorlogeProvider, ecoute par la page,
/// pose la lecture (sans surcharge, il la remettrait a vide hors Supabase).
List<Override> _avec(PortPaiementsFoyer port) => <Override>[
  portPaiementsFoyerProvider.overrideWithValue(port),
  monHorlogeProvider.overrideWith((Ref _) async {
    poserMonHorlogePourTest(_kolkata);
    return _kolkata;
  }),
];

Finder _texte(String s) => find.text(s, findRichText: true);

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    poserMonHorlogePourTest(_kolkata);
  });
  tearDown(() => poserMonHorlogePourTest(null));

  group('la ligne du Compte', () {
    testWidgets('sans source : aucune ligne « Paiements » (absente, jamais '
        'grisee)', (WidgetTester tester) async {
      await monterCompte(tester, taille: const Size(390, 2400));
      expect(find.byKey(CompteTuteurPage.paiementsKey), findsNothing);
    });

    testWidgets('avec une source : « Paiements » ouvre la page des paiements', (
      WidgetTester tester,
    ) async {
      await monterCompte(
        tester,
        taille: const Size(390, 2400),
        surcharges: _avec(FauxPaiementsFoyer(paiements: _deux)),
      );
      final Finder ligne = find.byKey(CompteTuteurPage.paiementsKey);
      expect(ligne, findsOneWidget);
      expect(
        find.descendant(of: ligne, matching: _texte('Paiements')),
        findsOneWidget,
      );
      expect(find.textContaining('reçus'), findsNothing);
      await tester.ensureVisible(ligne);
      await tester.tap(ligne);
      await tester.pumpAndSettle();
      expect(find.byType(PaiementsComptePage), findsOneWidget);
    });
  });

  group('la page', () {
    testWidgets('montant rendu, statut en mots, jour au fuseau du profil, '
        'aucun recu promis', (WidgetTester tester) async {
      await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('paiements'),
        taille: const Size(390, 2400),
        surcharges: _avec(FauxPaiementsFoyer(paiements: _deux)),
      );
      expect(_texte(t.compte.tuteur.pagePaiements.titre), findsWidgets);
      final Finder recent = find.byKey(const ValueKey<String>('paiement-2'));
      expect(recent, findsOneWidget);
      // Le jour : le 13 novembre au profil (le 12 sur un appareil a UTC).
      expect(
        find.descendant(
          of: recent,
          matching: find.textContaining('13', findRichText: true),
        ),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: recent,
          matching: _texte(formaterMontant(const Montant(5500, 'USD'))),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: recent,
          matching: _texte(t.compte.tuteur.pagePaiements.statutEnConfirmation),
        ),
        findsOneWidget,
      );
      final Finder ancien = find.byKey(const ValueKey<String>('paiement-1'));
      expect(
        find.descendant(
          of: ancien,
          matching: _texte(t.compte.tuteur.pagePaiements.statutConfirme),
        ),
        findsOneWidget,
      );
      expect(_texte(t.compte.tuteur.pagePaiements.justificatif), findsNothing);
    });

    testWidgets('liste vide : « Aucun paiement enregistré »', (
      WidgetTester tester,
    ) async {
      await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('paiements'),
        surcharges: _avec(FauxPaiementsFoyer()),
      );
      expect(_texte(t.compte.tuteur.pagePaiements.aucunTitre), findsOneWidget);
    });

    testWidgets(
      'refus du serveur (42501) : un etat clair, sans « Reessayer »',
      (WidgetTester tester) async {
        await monterCompte(
          tester,
          depart: Routes.compteTuteurSousPage('paiements'),
          surcharges: _avec(_Refus()),
        );
        expect(
          _texte(t.compte.tuteur.pagePaiements.refusTitre),
          findsOneWidget,
        );
        expect(_texte(t.commun.etats.actions.reessayer), findsNothing);
      },
    );
  });

  testWidgets('arabe : « دفعة » d abord (a droite), puis le jour, le mois et '
      'l annee dans l ordre de lecture', (WidgetTester tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
    await monterCompte(
      tester,
      depart: Routes.compteTuteurSousPage('paiements'),
      direction: TextDirection.rtl,
      surcharges: _avec(
        FauxPaiementsFoyer(paiements: <PaiementFoyer>[_deux.last]),
      ),
    );
    // « دفعة 3 أكتوبر 2026 » : de droite a gauche, le mot, puis 3, puis 2026.
    final Finder ligne = find.byKey(const ValueKey<String>('paiement-1'));
    RenderParagraph? titre;
    for (final Element e
        in find
            .descendant(of: ligne, matching: find.byType(RichText))
            .evaluate()) {
      final RenderParagraph p = e.renderObject! as RenderParagraph;
      if (p.text.toPlainText().contains('2026')) titre = p;
    }
    expect(titre, isNotNull);
    final RenderParagraph p = titre!;
    final String s = p.text.toPlainText();
    expect(p.textDirection, TextDirection.rtl);
    double x(String morceau) => p
        .getBoxesForSelection(
          TextSelection(
            baseOffset: s.indexOf(morceau),
            extentOffset: s.indexOf(morceau) + morceau.length,
          ),
        )
        .first
        .left;
    final double mot = x('دفعة');
    final double jour = x('3');
    final double annee = x('2026');
    expect(mot, greaterThan(jour), reason: 'le mot avant la date');
    expect(jour, greaterThan(annee), reason: 'le jour avant l annee');
  });

  test('statut inconnu : jamais affiche brut', () {
    expect(libelleStatutPaiement('inconnu'), isNull);
    expect(libelleStatutPaiement('confirme'), 'Confirmé');
  });

  // Captures R3 (docs/current/captures/E2E/paiements-tuteur/) : le Compte avec
  // sa ligne « Paiements », et la page, a 390 et 1440, en francais et en
  // arabe. Donnees de test seulement. Jamais sans CAPTURE_DIR.
  group('Capture : PAIEMENTS-TUTEUR', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String ecran, String depart) in <(String, String)>[
      ('compte', Routes.tuteurCompte),
      ('page', '/tuteur/compte/paiements'),
    ]) {
      for (final double largeur in <double>[390, 1440]) {
        for (final AppLocale langue in <AppLocale>[
          AppLocale.fr,
          AppLocale.ar,
        ]) {
          final String nom =
              'paiements_${ecran}_${largeur.toInt()}_${langue.languageCode}';
          testWidgets(nom, (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
            await monterCompte(
              tester,
              depart: depart,
              taille: Size(largeur, 1800),
              surcharges: _avec(FauxPaiementsFoyer(paiements: _deux)),
              direction: langue == AppLocale.ar
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            );
            await stabiliser(tester);
            debugPrint('PNG ${await capturerVue(tester, nom)}');
          });
        }
      }
    }
  });
}
