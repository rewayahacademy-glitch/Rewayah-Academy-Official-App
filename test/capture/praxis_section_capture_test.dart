// Captures de la section « Praxis » de « Acces des agents IA » (PX-3, R3) :
// 360 px de large, francais et arabe (de droite a gauche), clair.
//
// Etats : contenu (reglages, cles, journal), cle emise (le secret montre une
// fois), vide (aucune cle, aucun envoi), erreur de lecture, hors ligne,
// double verification manquante. Sur la VRAIE page « Acces des agents IA » :
// la section est posee sous la liste des jetons d'observation.
//
// Les donnees sont fictives (`test/support/faux_service_praxis.dart`) : aucune
// personne reelle, aucune vraie cle. Saute sans CAPTURE_DIR (voir
// `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/service_agent.dart';
import 'package:rewayah_academy/core/agent/service_praxis.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/admin_acces_agents/acces_agents_page.dart';
import 'package:rewayah_academy/features/admin_acces_agents/section_praxis.dart';

import '../support/faux_service_praxis.dart';
import 'outil_capture.dart';

/// Un service d'observation vide : seule la section Praxis est montree.
class _AgentsVide implements ServiceAgent {
  @override
  Future<List<JetonAgent>> lister() async => <JetonAgent>[];

  @override
  Future<List<PersonneObservable>> personnes() async =>
      <PersonneObservable>[];

  @override
  Future<JetonEmis> emettre({
    required String libelle,
    required String profilObserve,
    required int dureeHeures,
    required bool identiteMasquee,
  }) async => throw UnimplementedError();

  @override
  Future<bool> revoquer(String id) async => true;
}

enum _Etat { contenu, cleEmise, vide, erreur, horsLigne, doubleVerification }

FauxServicePraxis _faux(_Etat etat) {
  final List<List<LigneJournalPraxis>> pages = <List<LigneJournalPraxis>>[
    <LigneJournalPraxis>[
      ligneJournalFictive(
        9,
        extrait: 'Bonjour, votre demande est bien reçue. La direction vous répondra.',
      ),
      ligneJournalFictive(8, issue: 'plafond_fil', extrait: null),
      ligneJournalFictive(
        7,
        outil: 'annoncer',
        extrait: 'Rappel : la rentrée des classes aura lieu lundi.',
      ),
    ],
  ];
  return switch (etat) {
    _Etat.vide => FauxServicePraxis(
      etat: const EtatPraxis(
        actif: false,
        autonome: false,
        envoisParHeure: 30,
        cles: <ClePraxis>[],
      ),
    ),
    _Etat.erreur || _Etat.horsLigne => FauxServicePraxis(
      erreurEtat: Exception('panne'),
      erreurJournal: Exception('panne'),
    ),
    _Etat.doubleVerification => FauxServicePraxis(pages: pages)
      ..refusDroit = true,
    _ => FauxServicePraxis(
      etat: EtatPraxis(
        actif: true,
        autonome: false,
        envoisParHeure: 30,
        cles: <ClePraxis>[
          clePraxisFictive(derniereUtilisation: DateTime(2026, 11, 15, 18)),
          clePraxisFictive(
            id: 'c2',
            libelle: 'Routine du soir',
            prefixe: 'prx_9f8e7d6c',
            usage: UsageClePraxis.routine,
            etat: EtatClePraxis.revoquee,
          ),
          clePraxisFictive(
            id: 'c3',
            libelle: 'Essai de la semaine dernière',
            prefixe: 'prx_5a4b3c2d',
            etat: EtatClePraxis.expiree,
          ),
        ],
      ),
      pages: pages,
    ),
  };
}

Future<void> _ouvrir(WidgetTester tester, _Etat etat) async {
  final FauxServicePraxis faux = _faux(etat);
  final List<Override> surcharges = <Override>[
    servicePraxisProvider.overrideWithValue(faux),
    serviceAgentProvider.overrideWithValue(_AgentsVide()),
    if (etat == _Etat.horsLigne)
      horsLigneProvider.overrideWith((ref) => Stream<bool>.value(true)),
  ];
  await tester.pumpWidget(
    hoteCapture(const AccesAgentsPage(), surcharges: surcharges),
  );
  await stabiliser(tester);

  Future<void> toucher(Finder cible) async {
    await tester.ensureVisible(cible);
    await stabiliser(tester);
    await tester.tap(cible);
    await stabiliser(tester);
  }

  if (etat == _Etat.cleEmise) {
    final Finder champ = find.byType(TextField);
    await tester.ensureVisible(champ.last);
    await tester.enterText(champ.last, 'Conversation du directeur');
    await stabiliser(tester);
    await toucher(find.byKey(ClesPraxis.emettre));
  }
  if (etat == _Etat.doubleVerification) {
    await toucher(find.byKey(ClesPraxis.interrupteur));
  }
  // La section est sous la liste des jetons : on la met a l'ecran.
  final Finder titre = find.text(t.admin.praxis.titre);
  if (titre.evaluate().isNotEmpty) {
    await tester.ensureVisible(titre.first);
    await stabiliser(tester);
  }
  expect(tester.takeException(), isNull);
}

void main() {
  group('Capture : section Praxis (PX-3)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final _Etat etat in _Etat.values) {
        final String nom = 'praxis_${etat.name}_${langue.languageCode}_360';
        testWidgets(nom, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(tester, const Size(360, 2400), 1);
          await _ouvrir(tester, etat);
          debugPrint('PNG ${await capturer(tester, nom)}');
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
        });
      }
    }
  });
}
