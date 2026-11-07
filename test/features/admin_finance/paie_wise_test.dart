// Lot FINANCE-ENSEIGNANT (06/11/2026) : « Paie des enseignants par Wise »
// dans l'onglet Paiements de la direction.
//   * le CSV : en-tetes puis lignes, exactement ce que rend le serveur, dans
//     l'ordre du modele ; separateur virgule, CRLF, UTF-8 ; colonnes publiques
//     de Wise (Name, sourceCurrency, targetCurrency, Amount, amountCurrency,
//     wise.com/help/articles/2663302) rendues telles quelles ;
//   * modele absent : la feuille le dit, aucun fichier ;
//   * pret : n lignes et total, enseignants a part, fichier enregistre par le
//     selecteur du systeme ;
//   * noter : champs requis, une seule cle par feuille ; 320 texte x2, 1440.
// Captures 390 et 1440, FR et AR, avec CAPTURE_DIR seulement.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_coordonnees_versement.dart';
import 'package:rewayah_academy/core/capacites/port_versements_paie.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_enregistrement_fichier.dart';
import 'package:rewayah_academy/features/admin_finance/paiements/feuille_noter_versement.dart';
import 'package:rewayah_academy/features/admin_finance/paiements/feuille_valider_coordonnees.dart';
import 'package:rewayah_academy/features/admin_finance/paiements/paie_wise.dart';

import '../../capture/outil_capture.dart';
import '../../support/garde_interface.dart';
import '../../support/mots_coupes.dart';
import '../paiements_recus/faux_versement.dart';

class _FauxFichier implements PortEnregistrementFichier {
  final List<(List<int>, String, String)> recus =
      <(List<int>, String, String)>[];

  @override
  Future<String?> enregistrerCopie({
    required List<int> octets,
    required String nomFichierPropose,
    required String typeMime,
  }) async {
    recus.add((octets, nomFichierPropose, typeMime));
    return 'blob:test';
  }
}

/// Les 17 en-tetes du modele Wise « Envoyer vers des comptes bancaires »,
/// USD vers USD, telecharge par le directeur le 06/11/2026.
const List<String> enTetesWise = <String>[
  'name',
  'recipientEmail',
  'paymentReference',
  'referenceNumber',
  'receiverType',
  'amountCurrency',
  'amount',
  'sourceCurrency',
  'targetCurrency',
  'type',
  'accountNumber',
  'BIC',
  'addressCountryCode',
  'addressCity',
  'addressFirstLine',
  'addressState',
  'addressPostCode',
];

/// Une ligne de test, telle que le serveur la rend (scenario SQL).
const List<String> ligneMamadou = <String>[
  'Mamadou Diallo',
  'mamadou@exemple.invalid',
  'Rewayah paie 2026-10',
  'RA-26-4817',
  'PERSON',
  'target',
  '31.74',
  'USD',
  'USD',
  'SwiftCode',
  '0012345678901',
  'ECOCGNGN',
  'GN',
  'Conakry',
  'Quartier Kaloum',
  '',
  '',
];

final ExportWise _export = ExportWise(
  exportId: 'x1',
  mois: DateTime(2026, 10),
  colonnes: enTetesWise,
  lignes: const <List<String>>[ligneMamadou],
  manquants: const <EnseignantSansCoordonnees>[
    EnseignantSansCoordonnees(
      enseignantId: 'e3',
      nom: 'Ousmane Ba',
      matricule: 'RA-26-1234',
      montant: Montant(1000, 'USD'),
      aucune: true,
    ),
  ],
  total: const Montant(3174, 'USD'),
);

Future<void> _monter(
  WidgetTester tester, {
  required PortCoordonneesVersement port,
  PortVersementsPaie? versements,
  PortEnregistrementFichier? fichier,
  Size taille = const Size(390, 2400),
  double densite = 1,
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
  TextDirection sens = TextDirection.ltr,
}) async {
  fixerVueCapture(tester, taille, densite);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    hoteCapture(
      Directionality(
        textDirection: sens,
        child: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: BlocPaieWise(),
          ),
        ),
      ),
      surcharges: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        portCoordonneesVersementProvider.overrideWithValue(port),
        portVersementsPaieProvider.overrideWithValue(
          versements ?? FauxVersements(),
        ),
        portEnregistrementFichierProvider.overrideWithValue(
          fichier ?? _FauxFichier(),
        ),
      ],
      echelleTexte: texte,
      themeMode: theme,
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await stabiliser(tester);
}

void main() {
  final a = t.admin.finance.paieWise;

  group('Le CSV Wise', () {
    test('les 17 en-tetes du modele Wise, dans l ordre, UTF-8 ; la ligne '
        'se relit colonne par colonne', () {
      final String csv = fichierCsvWise(_export);
      final List<String> lignes = utf8.decode(utf8.encode(csv)).split('\r\n');
      expect(lignes.last, isEmpty);
      expect(lignes, hasLength(3));
      expect(
        lignes.first,
        'name,recipientEmail,paymentReference,referenceNumber,receiverType,'
        'amountCurrency,amount,sourceCurrency,targetCurrency,type,'
        'accountNumber,BIC,addressCountryCode,addressCity,addressFirstLine,'
        'addressState,addressPostCode',
      );
      final List<String> relue = lignes[1].split(',');
      expect(relue, hasLength(17));
      for (int i = 0; i < 17; i++) {
        expect(relue[i], ligneMamadou[i], reason: enTetesWise[i]);
      }
      // Valeurs decidees : PERSON, frais payes par l'academie (target), USD
      // vers USD, SwiftCode ; montant au point, sans separateur de milliers
      // (wise.com/help/articles/2942777).
      expect(relue[4], 'PERSON');
      expect(relue[5], 'target');
      expect(relue[6], '31.74');
      expect(relue[9], 'SwiftCode');
    });

    test('une valeur inattendue avec virgule est mise entre guillemets', () {
      final ExportWise e = ExportWise(
        exportId: 'x',
        mois: DateTime(2026, 10),
        colonnes: const <String>['Name'],
        lignes: const <List<String>>[
          <String>['Diallo, "M"'],
        ],
        manquants: const <EnseignantSansCoordonnees>[],
        total: const Montant(0, 'USD'),
      );
      expect(fichierCsvWise(e), 'Name\r\n"Diallo, ""M"""\r\n');
    });

    test('nom du fichier et mois par defaut', () {
      expect(nomFichierWise(DateTime(2026, 10)), 'paie-wise-2026-10.csv');
      expect(moisPaieParDefaut(DateTime(2026, 1, 3)), DateTime(2025, 12));
    });
  });

  group('Bloc de la direction', () {
    testWidgets(
      'modele absent (garde-fou) : la feuille le dit, aucun fichier',
      (WidgetTester tester) async {
        final _FauxFichier fichier = _FauxFichier();
        await _monter(tester, port: FauxCoordonnees(), fichier: fichier);
        await _toucher(tester, find.byKey(BlocPaieWise.cleExporter));
        await _toucher(tester, find.byKey(FeuilleExportWise.cleAction));
        expect(find.byKey(FeuilleExportWise.cleModeleAbsent), findsOneWidget);
        expect(find.text(a.modeleAbsent), findsOneWidget);
        expect(fichier.recus, isEmpty);
      },
    );

    testWidgets(
      'pret : lignes, total, enseignants a part, fichier enregistre',
      (WidgetTester tester) async {
        final _FauxFichier fichier = _FauxFichier();
        final FauxCoordonnees port = FauxCoordonnees(export: _export);
        await _monter(tester, port: port, fichier: fichier);
        await _toucher(tester, find.byKey(BlocPaieWise.cleExporter));
        await _toucher(tester, find.byKey(FeuilleExportWise.cleAction));
        expect(port.exports, 1);
        expect(find.byKey(FeuilleExportWise.clePret), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('paie-wise-manquant-e3')),
          findsOneWidget,
        );
        expect(find.text(a.manquantAucune), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);
        await _toucher(tester, find.byKey(FeuilleExportWise.cleAction));
        expect(fichier.recus, hasLength(1));
        final (List<int> octets, String nom, String mime) =
            fichier.recus.single;
        expect(nom, 'paie-wise-2026-10.csv');
        expect(mime, 'text/csv');
        expect(utf8.decode(octets), fichierCsvWise(_export));
        expect(utf8.decode(octets).split('\r\n').first.split(','), enTetesWise);
        expect(find.text(a.fichierEnregistre), findsOneWidget);
      },
    );

    testWidgets('valider : seules les coordonnees a valider ; detail du compte '
        'd un tiers ; validation de la ligne lue', (WidgetTester tester) async {
      final FauxCoordonnees port = FauxCoordonnees();
      await _monter(tester, port: port);
      await _toucher(tester, find.byKey(BlocPaieWise.cleValider));
      expect(
        find.byKey(FeuilleValiderCoordonnees.cleEnseignant('e1')),
        findsNothing,
      );
      expect(
        find.byKey(FeuilleValiderCoordonnees.cleEnseignant('e2')),
        findsNothing,
      );
      await _toucher(
        tester,
        find.byKey(FeuilleValiderCoordonnees.cleEnseignant('e4')),
      );
      expect(find.text('Moussa Ndiaye'), findsOneWidget);
      expect(find.text('••••4444'), findsOneWidget);
      expect(find.text(a.compteTiers(lien: a.lien.parent)), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      await _toucher(tester, find.byKey(FeuilleValiderCoordonnees.cleAction));
      expect(port.validations, <(String, String)>[('e4', 'c4')]);
      expect(find.byKey(FeuilleValiderCoordonnees.cleFait), findsOneWidget);
    });

    testWidgets('noter : champs requis, puis un versement, une seule cle', (
      WidgetTester tester,
    ) async {
      final FauxVersements versements = FauxVersements();
      await _monter(tester, port: FauxCoordonnees(), versements: versements);
      await _toucher(tester, find.byKey(BlocPaieWise.cleNoter));
      await _toucher(tester, find.byKey(FeuilleNoterVersement.cleAction));
      expect(versements.notes, isEmpty);
      expect(find.text(a.erreurChamp), findsWidgets);

      await _toucher(
        tester,
        find.byKey(FeuilleNoterVersement.cleEnseignant('e1')),
      );
      final Finder montant = find.descendant(
        of: find.byKey(FeuilleNoterVersement.cleMontant),
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(montant);
      await tester.enterText(montant, '25,87');
      final Finder reference = find.descendant(
        of: find.byKey(FeuilleNoterVersement.cleReference),
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(reference);
      await tester.enterText(reference, 'TX-2026-11-0042');
      await tester.pump();
      await _toucher(tester, find.byKey(FeuilleNoterVersement.cleAction));
      expect(versements.notes, hasLength(1));
      final VersementANoter v = versements.notes.single;
      expect(v.enseignantId, 'e1');
      expect(v.montant, const Montant(2587, 'USD'));
      expect(v.reference, 'TX-2026-11-0042');
      expect(v.moyen, MoyenVersement.virementBancaire);
      expect(find.byKey(FeuilleNoterVersement.cleFait), findsOneWidget);
    });
  });

  group('Garde d interface', () {
    setUpAll(chargerPolicesDuDepot);

    testWidgets('320 a texte x2 : bloc et feuille preparee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: FauxCoordonnees(export: _export),
        taille: const Size(320, 5000),
        texte: 2,
      );
      expect(tester.takeException(), isNull);
      expect(motsCoupes(tester, find.byType(BlocPaieWise)), isEmpty);
      await _toucher(tester, find.byKey(BlocPaieWise.cleExporter));
      await _toucher(tester, find.byKey(FeuilleExportWise.cleAction));
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 sombre et RTL', (WidgetTester tester) async {
      await _monter(
        tester,
        port: FauxCoordonnees(export: _export),
        taille: const Size(1440, 1200),
        theme: ThemeMode.dark,
      );
      await _toucher(tester, find.byKey(BlocPaieWise.cleNoter));
      expect(tester.takeException(), isNull);
      await _monter(
        tester,
        port: FauxCoordonnees(export: _export),
        sens: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Captures (CAPTURE_DIR seulement)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final (String, Size, double) vue in <(String, Size, double)>[
        ('390', const Size(390, 1400), 2),
        ('1440', const Size(1440, 1100), 1),
      ]) {
        final TextDirection sens = langue == AppLocale.ar
            ? TextDirection.rtl
            : TextDirection.ltr;
        final String suffixe = '${vue.$1}_${langue.languageCode}';
        testWidgets('wise_export_pret_$suffixe', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            port: FauxCoordonnees(export: _export),
            taille: vue.$2,
            densite: vue.$3,
            sens: sens,
          );
          await _toucher(tester, find.byKey(BlocPaieWise.cleExporter));
          await _toucher(tester, find.byKey(FeuilleExportWise.cleAction));
          debugPrint(
            'PNG ${await capturer(tester, 'wise_export_pret_$suffixe')}',
          );
        });
        testWidgets('wise_modele_absent_$suffixe', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            port: FauxCoordonnees(),
            taille: vue.$2,
            densite: vue.$3,
            sens: sens,
          );
          await _toucher(tester, find.byKey(BlocPaieWise.cleExporter));
          await _toucher(tester, find.byKey(FeuilleExportWise.cleAction));
          debugPrint(
            'PNG ${await capturer(tester, 'wise_modele_absent_$suffixe')}',
          );
        });
        testWidgets('wise_valider_$suffixe', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            port: FauxCoordonnees(),
            taille: vue.$2,
            densite: vue.$3,
            sens: sens,
          );
          await _toucher(tester, find.byKey(BlocPaieWise.cleValider));
          await _toucher(
            tester,
            find.byKey(FeuilleValiderCoordonnees.cleEnseignant('e4')),
          );
          debugPrint('PNG ${await capturer(tester, 'wise_valider_$suffixe')}');
        });
        testWidgets('wise_noter_$suffixe', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            port: FauxCoordonnees(),
            taille: vue.$2,
            densite: vue.$3,
            sens: sens,
          );
          await _toucher(tester, find.byKey(BlocPaieWise.cleNoter));
          debugPrint('PNG ${await capturer(tester, 'wise_noter_$suffixe')}');
        });
      }
    }
  });
}
