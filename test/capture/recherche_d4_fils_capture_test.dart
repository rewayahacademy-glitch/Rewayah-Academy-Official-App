// RECHERCHE D4, partie « fils » du comptable (08/11/2026) : sur le VRAI routeur
// et le VRAI branchement (`moteursRechercheProduction`) avec des Messages qui
// rendent des donnees de test : le comptable trouve un fil « Profil de
// paiement » par le nom de la personne, un nom sans fil (vide confirme), la
// panne de la lecture, et le fil ouvert. Francais et arabe, a 390 et a 1440.
//
// Saute sans CAPTURE_DIR. Usage :
//   CAPTURE_DIR=docs/current/captures/E2E/recherche-d4-fils flutter test \
//     --no-pub test/capture/recherche_d4_fils_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_classe/roster_enseignant.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/recherche/ecran/ecran_recherche.dart'
    show cleChampRecherche;
import 'package:rewayah_academy/features/recherche/moteurs_production.dart';

import '../features/com_messages/support_messages.dart' show FauxMessagesMetier;
import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import '../teaching_core/h/faux/faux_ports_externes.dart' show FauxRoster;
import 'outil_capture.dart';

ResumeFil _fil(String id, TypeObjetLie type, String objetId, String libelle) =>
    ResumeFil(
      id: id,
      objet: ObjetLie(type: type, id: objetId, libelle: libelle),
      interlocuteurs: const <Participant>[
        Participant(id: 'p-fatima', nomAffiche: 'Fatima Diallo'),
      ],
    );

List<Override> _production({bool panne = false}) => <Override>[
  moteursRechercheProvider.overrideWith(moteursRechercheProduction),
  portMessagesMetierProvider.overrideWithValue(
    FauxMessagesMetier(
      resumesEnPlus: <ResumeFil>[
        _fil('f-1', TypeObjetLie.profilPaiement, 'b-1', 'Profil de paiement'),
        _fil('f-2', TypeObjetLie.classe, 'c-1', 'Classe An-Nour'),
      ],
    )..erreurListe = panne ? Exception('lecture refusee') : null,
  ),
  portRosterEnseignantProvider.overrideWithValue(FauxRoster()),
];

Future<void> _chercher(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(cleChampRecherche), texte);
  await tester.pump(const Duration(milliseconds: 300));
  await stabiliser(tester);
}

void main() {
  group('Capture RECHERCHE D4 fils du comptable', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    int rang = 0;
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String code = langue.languageCode;
        final int largeur = taille.width.toInt();
        final TextDirection direction = langue == AppLocale.ar
            ? TextDirection.rtl
            : TextDirection.ltr;

        Future<void> monter(WidgetTester tester, {bool panne = false}) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await monterRouteur(
            tester,
            Routes.recherche,
            source: FausseSourceSession(sessionActive(AppRole.accountant)),
            taille: taille,
            direction: direction,
            surcharges: _production(panne: panne),
          );
          await stabiliser(tester);
        }

        Future<void> photo(WidgetTester tester, String nom) async {
          rang++;
          debugPrint(
            'PNG ${await capturerVue(tester, '${rang.toString().padLeft(2, '0')}_${code}_${largeur}_$nom')}',
          );
        }

        testWidgets('$code $largeur : le comptable trouve un fil', (
          WidgetTester tester,
        ) async {
          await monter(tester);
          await _chercher(tester, 'fatima');
          expect(find.text('Profil de paiement'), findsOneWidget);
          expect(find.text('Classe An-Nour'), findsNothing);
          await photo(tester, 'comptable_fil_trouve');
        });

        testWidgets('$code $largeur : un nom sans fil, le vide', (
          WidgetTester tester,
        ) async {
          await monter(tester);
          await _chercher(tester, 'zzzzzz');
          await photo(tester, 'comptable_aucun_fil');
        });

        testWidgets('$code $largeur : une panne', (WidgetTester tester) async {
          await monter(tester, panne: true);
          await _chercher(tester, 'fatima');
          await photo(tester, 'comptable_panne');
        });
      }
    }
  });
}
