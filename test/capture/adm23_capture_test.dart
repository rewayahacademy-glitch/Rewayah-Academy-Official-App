// Captures d'ADM-23 (« Importer les formulaires de candidature »), sur la VRAIE
// application et le vrai routeur en demonstration d'administration : la barre
// laterale, la page, les huit pas.
//
// Pas : deposer (vide, fichier choisi, noms a corriger, analyse en cours),
// apercu, colonnes (liste, question d'une colonne), doublons (liste, cas),
// erreurs, comptes (ecart), confirmation (envoi en cours), rapport. Etats :
// fichier illisible, fichier vide, analyse en echec, colonnes a associer,
// hors ligne, jeton perime, import non confirme, acces refuse, double
// verification, capacite indisponible. 390x844 et 1440x900, clair et sombre ;
// 768x1024 ; l'arabe de droite a gauche.
//
// Les donnees sont fictives, posees par le double du port
// (`test/fixtures/candidature/faux_import_candidatures.dart`) : aucune personne
// reelle, aucune adresse reelle. Saute sans CAPTURE_DIR (voir
// `test/capture/LISEZ-MOI.md`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_import_candidatures.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/composants_import.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/controleur_import.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/pas_comptes.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/pas_depot.dart';
import 'package:rewayah_academy/features/admin_import_inscriptions/selecteur_csv.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../fixtures/candidature/faux_import_candidatures.dart';
import 'outil_capture.dart';

// Pages entieres : une capture n'est que la fenetre, la vue est donc haute pour
// montrer un pas jusqu'a son bouton (dit dans la preuve).
const Size _telephoneHaut = Size(390, 2800);
const Size _tabletteHaute = Size(768, 1800);
const Size _bureauHaut = Size(1440, 1500);
const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

/// Le nom d'un export Google Sheets : « classeur - onglet.csv ».
const String _nomFichier = 'Formulaire enseignants - Réponses.csv';

class _Selecteur implements SelecteurCsv {
  _Selecteur(this.texte, {this.nom = _nomFichier});

  final String texte;
  final String nom;

  @override
  Future<CsvChoisi?> choisir() async => CsvChoisi(nom: nom, texte: texte);
}

/// Monte la VRAIE application en demonstration d'administration, ouverte sur
/// l'import des formulaires, avec le port [port].
Future<void> _monter(
  WidgetTester tester,
  PortImportCandidatures? port, {
  ThemeMode mode = ThemeMode.light,
  bool horsLigne = false,
  Stream<bool>? reseau,
  String? texte,
  String nom = _nomFichier,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        if (port != null)
          portImportCandidaturesProvider.overrideWithValue(port),
        selecteurCsvProvider.overrideWithValue(
          _Selecteur(texte ?? csvFormulaires, nom: nom),
        ),
        if (horsLigne || reseau != null)
          horsLigneProvider.overrideWith(
            (Ref _) => reseau ?? Stream<bool>.value(true),
          ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  unawaited(routeur.push<void>(Routes.adminPersonnesCandidaturesImport));
  await stabiliser(tester);
  await stabiliser(tester);
}

Future<void> _enHaut(WidgetTester tester) async {
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    if (etat.position.axis == Axis.vertical) {
      etat.position.jumpTo(etat.position.minScrollExtent);
    }
  }
  await tester.pump();
}

Future<void> _photo(WidgetTester tester, String nom) async {
  await _enHaut(tester);
  debugPrint('PNG ${await capturer(tester, 'ADM-23/$nom')}');
}

Future<void> _toucher(WidgetTester tester, Key cle) async {
  final Finder f = find.byKey(cle);
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await stabiliser(tester);
}

Future<void> _suivant(WidgetTester tester) =>
    _toucher(tester, ActionsDuPas.actionKey);

Future<void> _choisirFichier(WidgetTester tester) =>
    _toucher(tester, PasDepot.carteFichierKey);

/// Conduit le parcours jusqu'au pas [pas] (fichier normal, defauts).
Future<void> _jusqua(WidgetTester tester, PasImport pas) async {
  await _choisirFichier(tester);
  if (pas == PasImport.depot) return;
  await _suivant(tester); // analyser
  if (pas == PasImport.apercu) return;
  await _suivant(tester); // apercu -> colonnes
  if (pas == PasImport.colonnes) return;
  await _suivant(tester); // colonnes -> doublons
  if (pas == PasImport.doublons) return;
  await _suivant(tester); // doublons -> erreurs
  if (pas == PasImport.erreurs) return;
  await _suivant(tester); // erreurs -> comptes
  if (pas == PasImport.comptes) return;
  await _toucher(tester, const ValueKey<String>('import-attendu-aucun'));
  await _suivant(tester); // comptes -> confirmation
  if (pas == PasImport.confirmation) return;
  await _suivant(tester); // importer
}

/// Un champ de saisie du pas des comptes.
Finder _saisie(Key cle) =>
    find.descendant(of: find.byKey(cle), matching: find.byType(EditableText));

Future<void> _ecrire(WidgetTester tester, Key cle, String texte) async {
  await tester.ensureVisible(_saisie(cle));
  await tester.pump();
  await tester.enterText(_saisie(cle), texte);
  await stabiliser(tester);
}

/// Un export dont un guillemet n'est jamais referme.
const String _csvGuillemet =
    'Horodateur,"هل أنت\n21/10/2026 09:15:00,ذكر,Personne Test 01';

/// Un export qui n'a que son en-tete.
String get _csvVide => titresFormulaire.join(',');

/// Un etat de l'ecran : son nom, et comment l'atteindre.
typedef _Etat = ({
  String nom,
  Future<void> Function(WidgetTester tester, ThemeMode mode) atteindre,
});

final List<_Etat> _etats = <_Etat>[
  (
    nom: 'depot-nom-sans-onglet',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(
        tester,
        FauxImportCandidatures(),
        mode: mode,
        nom: 'export.csv',
      );
      await _choisirFichier(tester);
    },
  ),
  (
    nom: 'depot-noms-a-corriger',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(tester, FauxImportCandidatures(), mode: mode);
      await _choisirFichier(tester);
      await _toucher(tester, PasDepot.corrigerNomsKey);
    },
  ),
  (
    nom: 'depot-analyse-en-cours',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..apercuRetenu = Completer<ApercuImport>();
      await _monter(tester, port, mode: mode);
      await _choisirFichier(tester);
      await _suivant(tester);
    },
  ),
  (
    nom: 'depot-fichier-illisible',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(
        tester,
        FauxImportCandidatures(),
        mode: mode,
        texte: _csvGuillemet,
      );
      await _choisirFichier(tester);
    },
  ),
  (
    nom: 'depot-fichier-vide',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(
        tester,
        FauxImportCandidatures(),
        mode: mode,
        texte: _csvVide,
      );
      await _choisirFichier(tester);
    },
  ),
  (
    nom: 'depot-analyse-echec',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurApercu = (int n) => StateError('muet');
      await _monter(tester, port, mode: mode);
      await _choisirFichier(tester);
      await _suivant(tester);
    },
  ),
  (
    nom: 'depot-hors-ligne',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(
        tester,
        FauxImportCandidatures(),
        mode: mode,
        horsLigne: true,
      );
      await _choisirFichier(tester);
    },
  ),
  (
    nom: 'apercu-colonnes-a-associer',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurApercu = (int n) => n == 1
            ? MappageIncomplet(
                champs: const <ChampManquant>[
                  ChampManquant.nom,
                  ChampManquant.contact,
                ],
                colonnes: colonnesTest(
                  sauf: <ChampFormulaire>{
                    ChampFormulaire.nom,
                    ChampFormulaire.telephone,
                    ChampFormulaire.courriel,
                  },
                ),
              )
            : null;
      await _monter(tester, port, mode: mode);
      await _choisirFichier(tester);
      await _suivant(tester);
    },
  ),
  (
    nom: 'colonnes-a-associer',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurApercu = (int n) => n == 1
            ? MappageIncomplet(
                champs: const <ChampManquant>[ChampManquant.nom],
                colonnes: colonnesTest(
                  sauf: <ChampFormulaire>{ChampFormulaire.nom},
                ),
              )
            : null;
      await _monter(tester, port, mode: mode);
      await _jusqua(tester, PasImport.apercu);
      await _suivant(tester);
    },
  ),
  (
    nom: 'colonnes-ambigu',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurApercu = (int n) => n == 1
            ? EntetesAmbigus(
                champs: const <ChampFormulaire>[ChampFormulaire.nom],
                colonnes: colonnesTest(),
              )
            : null;
      await _monter(tester, port, mode: mode);
      await _jusqua(tester, PasImport.apercu);
      await _suivant(tester);
    },
  ),
  (
    nom: 'colonnes-question',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(tester, FauxImportCandidatures(), mode: mode);
      await _jusqua(tester, PasImport.colonnes);
      await _toucher(tester, const ValueKey<String>('import-colonne-4'));
    },
  ),
  (
    nom: 'colonnes-relecture',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(tester, FauxImportCandidatures(), mode: mode);
      await _jusqua(tester, PasImport.colonnes);
      await _toucher(tester, const ValueKey<String>('import-colonne-5'));
      await _toucher(tester, const ValueKey<String>('import-champ-aucun'));
    },
  ),
  (
    nom: 'doublons-cas',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(tester, FauxImportCandidatures(), mode: mode);
      await _jusqua(tester, PasImport.doublons);
      await _toucher(
        tester,
        const ValueKey<String>('import-doublon-g1a2b3c4d5e6'),
      );
    },
  ),
  (
    nom: 'doublons-choix-fait',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(tester, FauxImportCandidatures(), mode: mode);
      await _jusqua(tester, PasImport.doublons);
      await _toucher(
        tester,
        const ValueKey<String>('import-doublon-g1a2b3c4d5e6'),
      );
      await _toucher(
        tester,
        const ValueKey<String>('import-doublon-option-ligne-3'),
      );
    },
  ),
  (
    nom: 'doublons-aucun',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(
        tester,
        FauxImportCandidatures(
          apercuRendu: apercuTest(groupes: const <GroupeDoublons>[]),
        ),
        mode: mode,
      );
      await _jusqua(tester, PasImport.doublons);
    },
  ),
  (
    nom: 'erreurs-aucune',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(
        tester,
        FauxImportCandidatures(
          apercuRendu: apercuTest(
            lignes: const <LigneApercu>[
              LigneApercu(ligne: 2, issue: IssueLigne.nouvelle),
            ],
          ),
        ),
        mode: mode,
      );
      await _jusqua(tester, PasImport.erreurs);
    },
  ),
  (
    nom: 'comptes-autres-nombres',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(tester, FauxImportCandidatures(), mode: mode);
      await _jusqua(tester, PasImport.comptes);
      await _toucher(tester, const ValueKey<String>('import-attendu-autres'));
      await _ecrire(tester, PasComptes.champLignesKey, '438');
    },
  ),
  (
    nom: 'confirmation-envoi',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..confirmationRetenue = Completer<RapportImport>();
      await _monter(tester, port, mode: mode);
      await _jusqua(tester, PasImport.confirmation);
      await _suivant(tester);
    },
  ),
  (
    nom: 'confirmation-non-confirme',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurConfirmation = (int n) =>
            n == 1 ? const ImportHorsLigne() : null;
      await _monter(tester, port, mode: mode);
      await _jusqua(tester, PasImport.confirmation);
      await _suivant(tester);
    },
  ),
  (
    nom: 'confirmation-jeton-perime',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurConfirmation = (int n) => n == 1 ? const JetonPerime() : null;
      await _monter(tester, port, mode: mode);
      await _jusqua(tester, PasImport.confirmation);
      await _suivant(tester);
    },
  ),
  (
    nom: 'confirmation-hors-ligne',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      final StreamController<bool> reseau = StreamController<bool>();
      addTearDown(reseau.close);
      reseau.add(false);
      await _monter(
        tester,
        FauxImportCandidatures(),
        mode: mode,
        reseau: reseau.stream,
      );
      await _jusqua(tester, PasImport.confirmation);
      reseau.add(true);
      await stabiliser(tester);
    },
  ),
  (
    nom: 'rapport-rejoue',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(
        tester,
        FauxImportCandidatures(rapportRendu: rapportTest(rejoue: true)),
        mode: mode,
      );
      await _jusqua(tester, PasImport.rapport);
    },
  ),
  (
    nom: 'acces-refuse',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(
        tester,
        FauxImportCandidatures(
          capacitesRendues: const CapacitesImportCandidatures(),
        ),
        mode: mode,
      );
    },
  ),
  (
    nom: 'acces-double-verification',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(
        tester,
        FauxImportCandidatures(
          capacitesRendues: const CapacitesImportCandidatures(
            doubleVerificationRequise: true,
          ),
        ),
        mode: mode,
      );
    },
  ),
  (
    nom: 'acces-double-verification-en-route',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurConfirmation = (int n) => const DoubleVerificationRequise();
      await _monter(tester, port, mode: mode);
      await _jusqua(tester, PasImport.confirmation);
      await _suivant(tester);
    },
  ),
  (
    nom: 'acces-indisponible',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      await _monter(tester, null, mode: mode);
    },
  ),
  (
    nom: 'acces-chargement',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..capacitesRetenues = Completer<CapacitesImportCandidatures>();
      await _monter(tester, port, mode: mode);
    },
  ),
  (
    nom: 'acces-lecture-echec',
    atteindre: (WidgetTester tester, ThemeMode mode) async {
      final FauxImportCandidatures port = FauxImportCandidatures()
        ..erreurCapacites = StateError('muet');
      await _monter(tester, port, mode: mode);
    },
  ),
];

/// Les etats montres aussi en arabe.
const Set<String> _etatsArabes = <String>{
  'depot-nom-sans-onglet',
  'depot-fichier-illisible',
  'colonnes-a-associer',
  'colonnes-question',
  'doublons-cas',
  'comptes-autres-nombres',
  'confirmation-non-confirme',
  'rapport-rejoue',
  'acces-double-verification',
};

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('ADM-23 : captures', skip: sautSansCapture, () {
    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    // Les huit pas : telephone clair et sombre, tablette, bureau clair et
    // sombre, puis l'arabe de droite a gauche au telephone et au bureau.
    for (final (String nom, Size taille, ThemeMode mode, bool arabe)
        in <(String, Size, ThemeMode, bool)>[
          ('390', _telephoneHaut, ThemeMode.light, false),
          ('390', _telephoneHaut, ThemeMode.dark, false),
          ('768', _tabletteHaute, ThemeMode.light, false),
          ('1440', _bureauHaut, ThemeMode.light, false),
          ('1440', _bureauHaut, ThemeMode.dark, false),
          ('390', _telephoneHaut, ThemeMode.light, true),
          ('1440', _bureauHaut, ThemeMode.light, true),
        ]) {
      final EdgeInsets zone = nom == '390' ? _zoneSure : EdgeInsets.zero;
      final String suffixe = '${nom}_${arabe ? 'ar' : mode.name}';
      testWidgets('les huit pas $suffixe', (WidgetTester tester) async {
        if (arabe) {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        }
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        final FauxImportCandidatures port = FauxImportCandidatures();
        await _monter(tester, port, mode: mode);
        await _photo(tester, '1-depot-vide_$suffixe');
        await _choisirFichier(tester);
        await _photo(tester, '1-depot-fichier_$suffixe');
        await _suivant(tester);
        await _photo(tester, '2-apercu_$suffixe');
        await _suivant(tester);
        await _photo(tester, '3-colonnes_$suffixe');
        await _suivant(tester);
        await _photo(tester, '4-doublons_$suffixe');
        await _suivant(tester);
        await _photo(tester, '5-erreurs_$suffixe');
        await _suivant(tester);
        await _photo(tester, '6-comptes_$suffixe');
        await _toucher(
          tester,
          const ValueKey<String>('import-attendu-fichier2110'),
        );
        await _photo(tester, '6-comptes-ecart_$suffixe');
        await _suivant(tester);
        await _photo(tester, '7-confirmation_$suffixe');
        await _suivant(tester);
        await _photo(tester, '8-rapport_$suffixe');
      });
    }

    // Chaque etat : telephone clair et sombre, bureau clair ; certains en
    // arabe au telephone.
    for (final _Etat etat in _etats) {
      for (final (String nom, Size taille, ThemeMode mode, bool arabe)
          in <(String, Size, ThemeMode, bool)>[
            ('390', _telephoneHaut, ThemeMode.light, false),
            ('390', _telephoneHaut, ThemeMode.dark, false),
            ('1440', _bureauHaut, ThemeMode.light, false),
            if (_etatsArabes.contains(etat.nom))
              ('390', _telephoneHaut, ThemeMode.light, true),
          ]) {
        final EdgeInsets zone = nom == '390' ? _zoneSure : EdgeInsets.zero;
        final String suffixe = '${nom}_${arabe ? 'ar' : mode.name}';
        testWidgets('etat ${etat.nom} $suffixe', (WidgetTester tester) async {
          if (arabe) {
            await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
          }
          fixerVueCapture(tester, taille, 1, zoneSure: zone);
          await etat.atteindre(tester, mode);
          await _photo(tester, 'etat-${etat.nom}_$suffixe');
        });
      }
    }
  });
}
