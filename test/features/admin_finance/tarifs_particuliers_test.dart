// Lot (A), 02/11/2026 : « Accès offert » et « Prix spécial » dans l'onglet
// « Paiements » de la direction.
//
// - la liste des remises actives (les bourses de la politique n'y sont pas) ;
// - depuis la fiche de paiement d'un eleve : la fiche « Accès offert ou prix
//   spécial », reduction et raison controlees avant envoi, ce qui part au
//   serveur (nature, reduction en pour mille, mois de fin, raison) ;
// - les refus rendus par le serveur (remise deja active) ;
// - le retrait d'une remise, raison obligatoire ;
// - l'adaptateur Supabase : lecture de `bourses_lister`, parametres et refus.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_saisis.dart';
import 'package:rewayah_academy/core/capacites/port_tarifs_particuliers.dart';
import 'package:rewayah_academy/core/capacites/tarifs_particuliers_supabase.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_finance/paiements/paiements_page.dart';
import 'package:rewayah_academy/features/admin_finance/paiements/tarifs_particuliers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/harnais.dart';

const ElevePourPaiement _bilal = ElevePourPaiement(
  profilId: 'e2',
  prenom: 'Bilal',
  nom: 'F1',
  matricule: 'RA-26-4817',
  resteAPayer: Montant(5500, 'USD'),
);

class _Paiements implements PortPaiementsSaisis {
  @override
  Future<List<ElevePourPaiement>> eleves() async => <ElevePourPaiement>[_bilal];

  @override
  Future<PaiementEnregistre> enregistrer({
    required String profilId,
    required Montant montant,
    required String cle,
    String? reference,
  }) => throw UnimplementedError();

  @override
  Future<FacturesEmises> emettreFactures(DateTime mois) async =>
      const FacturesEmises(emises: 0, financees: 0);
}

class _Tarifs implements PortTarifsParticuliers {
  _Tarifs({this.remises = const <TarifParticulier>[], this.refus});

  List<TarifParticulier> remises;
  final MotifRefusTarif? refus;
  final List<Map<String, Object?>> envois = <Map<String, Object?>>[];

  @override
  Future<List<TarifParticulier>> liste() async => remises;

  @override
  Future<void> accorder({
    required String profilId,
    required NatureTarif nature,
    required DateTime moisFin,
    required String motif,
    int? pourMille,
  }) async {
    envois.add(<String, Object?>{
      'profil': profilId,
      'nature': nature,
      'moisFin': moisFin,
      'motif': motif,
      'pourMille': pourMille,
    });
    final MotifRefusTarif? r = refus;
    if (r != null) throw RefusTarif(r);
  }

  @override
  Future<void> retirer({
    required String profilId,
    required String motif,
  }) async {
    envois.add(<String, Object?>{'retrait': profilId, 'motif': motif});
  }
}

final TarifParticulier _offertYasmine = TarifParticulier(
  profilId: 'e1',
  prenom: 'Yasmine',
  nom: 'F1',
  nature: NatureTarif.accesOffert,
  pourMille: 1000,
  moisFin: DateTime(2027, 1),
  motif: 'Famille aidee',
);

final TarifParticulier _bourseOmar = TarifParticulier(
  profilId: 'e4',
  prenom: 'Omar',
  nature: NatureTarif.bourse,
  pourMille: 300,
  moisFin: DateTime(2027, 4),
  motif: 'Bourse de la politique',
);

Widget _hote(_Tarifs tarifs) => ProviderScope(
  overrides: <Override>[
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
    sansPersonneConnectee(),
    portPaiementsSaisisProvider.overrideWithValue(_Paiements()),
    portTarifsParticuliersProvider.overrideWithValue(tarifs),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      home: const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: PaiementsBloc(),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Finder _champ(Key cle) =>
    find.descendant(of: find.byKey(cle), matching: find.byType(TextField));

Future<void> _ouvrirTarifBilal(WidgetTester tester) async {
  await _toucher(tester, find.byKey(PaiementsBloc.cleEleve('e2')));
  await _toucher(tester, find.byKey(FeuillePaiement.cleTarif));
}

void main() {
  final p = t.admin.finance.tarifs;

  setUp(() {
    // Ecran assez haut pour la fiche entiere.
  });

  testWidgets('la liste montre les acces offerts et prix speciaux, pas les '
      'bourses de la politique', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _hote(_Tarifs(remises: <TarifParticulier>[_offertYasmine, _bourseOmar])),
    );
    await tester.pumpAndSettle();
    expect(find.text(p.titre), findsOneWidget);
    expect(find.byKey(BlocTarifsParticuliers.cleLigne('e1')), findsOneWidget);
    expect(find.byKey(BlocTarifsParticuliers.cleLigne('e4')), findsNothing);
    expect(find.text(valeurTarif(_offertYasmine)), findsOneWidget);
    expect(find.text('Famille aidee'), findsOneWidget);
  });

  testWidgets('vide : une phrase', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_hote(_Tarifs()));
    await tester.pumpAndSettle();
    expect(find.byKey(BlocTarifsParticuliers.cleVide), findsOneWidget);
  });

  testWidgets('prix special : reduction et raison controlees, puis ce qui '
      'part au serveur', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final _Tarifs tarifs = _Tarifs();
    await tester.pumpWidget(_hote(tarifs));
    await tester.pumpAndSettle();
    await _ouvrirTarifBilal(tester);
    expect(find.text(p.feuilleTitre(prenom: 'Bilal')), findsOneWidget);
    await _toucher(tester, find.text(p.choixPrix));
    // Rien n'est saisi : deux erreurs, rien n'est envoye.
    await _toucher(tester, find.byKey(FeuilleTarifParticulier.cleEnvoyer));
    expect(find.text(p.erreurReduction), findsOneWidget);
    expect(find.text(p.erreurRaison), findsOneWidget);
    expect(tarifs.envois, isEmpty);
    await tester.enterText(_champ(FeuilleTarifParticulier.cleReduction), '35');
    await tester.enterText(
      _champ(FeuilleTarifParticulier.cleRaison),
      'Inscrit avant novembre 2026',
    );
    await _toucher(tester, find.byKey(FeuilleTarifParticulier.cleEnvoyer));
    expect(tarifs.envois, hasLength(1));
    expect(tarifs.envois.single['nature'], NatureTarif.prixSpecial);
    expect(tarifs.envois.single['pourMille'], 350);
    expect(tarifs.envois.single['motif'], 'Inscrit avant novembre 2026');
    final DateTime fin = tarifs.envois.single['moisFin']! as DateTime;
    expect(fin.day, 1);
    expect(find.text(p.faitTitre), findsOneWidget);
  });

  testWidgets('acces offert : aucune reduction a saisir ; remise deja active, '
      'le refus le dit', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final _Tarifs tarifs = _Tarifs(refus: MotifRefusTarif.dejaActive);
    await tester.pumpWidget(_hote(tarifs));
    await tester.pumpAndSettle();
    await _ouvrirTarifBilal(tester);
    expect(find.byKey(FeuilleTarifParticulier.cleReduction), findsNothing);
    expect(find.text(p.offertAide(prenom: 'Bilal')), findsOneWidget);
    await tester.enterText(_champ(FeuilleTarifParticulier.cleRaison), 'Aide');
    await _toucher(tester, find.byKey(FeuilleTarifParticulier.cleEnvoyer));
    expect(tarifs.envois.single['nature'], NatureTarif.accesOffert);
    expect(tarifs.envois.single['pourMille'], isNull);
    expect(find.text(p.refusTitre), findsOneWidget);
    expect(find.text(p.refusDejaActive(prenom: 'Bilal')), findsOneWidget);
  });

  testWidgets('retirer une remise : raison obligatoire', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final _Tarifs tarifs = _Tarifs(remises: <TarifParticulier>[_offertYasmine]);
    await tester.pumpWidget(_hote(tarifs));
    await tester.pumpAndSettle();
    await _toucher(tester, find.byKey(BlocTarifsParticuliers.cleLigne('e1')));
    expect(find.text(p.retirerTitre(prenom: 'Yasmine')), findsOneWidget);
    await _toucher(tester, find.byKey(FeuilleTarifParticulier.cleEnvoyer));
    expect(find.text(p.erreurRaison), findsOneWidget);
    expect(tarifs.envois, isEmpty);
    await tester.enterText(_champ(FeuilleTarifParticulier.cleRaison), 'Fin');
    await _toucher(tester, find.byKey(FeuilleTarifParticulier.cleEnvoyer));
    expect(tarifs.envois.single, <String, Object?>{
      'retrait': 'e1',
      'motif': 'Fin',
    });
    expect(find.text(p.retireTitre), findsOneWidget);
  });

  group('lectures pures', () {
    test('la reduction saisie : un entier de 1 a 99, en pour mille', () {
      expect(pourMilleDepuisSaisie('35'), 350);
      expect(pourMilleDepuisSaisie(' 5 % '), 50);
      expect(pourMilleDepuisSaisie('0'), isNull);
      expect(pourMilleDepuisSaisie('100'), isNull);
      expect(pourMilleDepuisSaisie('12,5'), isNull);
    });

    test('les mois de fin : le mois courant et les 23 suivants', () {
      final List<DateTime> mois = moisDeFin(DateTime(2026, 11, 2));
      expect(mois.first, DateTime(2026, 11));
      expect(mois.last, DateTime(2028, 10));
      expect(mois, hasLength(24));
    });
  });

  group('adaptateur Supabase', () {
    test('lit bourses_lister et envoie les bons parametres', () async {
      final List<(String, Map<String, dynamic>?)> appels =
          <(String, Map<String, dynamic>?)>[];
      final TarifsParticuliersSupabase port =
          TarifsParticuliersSupabase.avecAppel((
            String f,
            Map<String, dynamic>? params,
          ) async {
            appels.add((f, params));
            if (f == 'bourses_lister') {
              return <Object?>[
                <String, dynamic>{
                  'profilId': 'e1',
                  'prenom': 'Yasmine',
                  'nom': 'F1',
                  'matricule': 'RA-26-1203',
                  'pourMille': 350,
                  'moisDebut': '2026-11-01',
                  'moisFin': '2027-01-01',
                  'motif': 'Inscrite avant',
                  'nature': 'prix_special',
                },
              ];
            }
            return null;
          });
      final List<TarifParticulier> l = await port.liste();
      expect(l.single.nature, NatureTarif.prixSpecial);
      expect(l.single.pourMille, 350);
      expect(l.single.moisFin, DateTime(2027, 1));
      await port.accorder(
        profilId: 'e2',
        nature: NatureTarif.accesOffert,
        moisFin: DateTime(2027, 3, 15),
        motif: 'Aide',
      );
      expect(appels.last.$1, 'accorder_tarif_particulier');
      expect(appels.last.$2, <String, dynamic>{
        'p_profil': 'e2',
        'p_nature': 'acces_offert',
        'p_pour_mille': null,
        'p_mois_fin': '2027-03-01',
        'p_motif': 'Aide',
      });
    });

    test('un refus du serveur devient RefusTarif', () async {
      Future<Object?> refuse(String code) async =>
          throw PostgrestException(message: 'refus', code: code);
      for (final (String code, MotifRefusTarif motif)
          in <(String, MotifRefusTarif)>[
            ('42501', MotifRefusTarif.droits),
            ('22023', MotifRefusTarif.invalide),
            ('BO002', MotifRefusTarif.dejaActive),
          ]) {
        final TarifsParticuliersSupabase port =
            TarifsParticuliersSupabase.avecAppel(
              (String _, Map<String, dynamic>? _) => refuse(code),
            );
        await expectLater(
          port.retirer(profilId: 'e1', motif: 'Fin'),
          throwsA(
            isA<RefusTarif>().having((RefusTarif r) => r.motif, 'motif', motif),
          ),
        );
      }
    });
  });
}
