// FAC-C-01 : l'onglet « Paiements » de la direction (fiche ADM-PAI).
//
// - la liste : « A regulariser » (reste a payer rendu) puis « A jour » ;
// - la fiche : montant prerempli avec le reste a payer, reference
//   facultative, une seule action pleine ; l'issue est celle que rend la
//   source (mois regle, il manque encore, deja enregistre) ; montant
//   illisible, refus, issue inconnue (« Reessayer » rejoue la meme cle et
//   le meme montant), hors ligne ;
// - la liste se relit apres un paiement ;
// - les etats : chargement, indisponible, erreur, vide ;
// - 320 px texte x2 et 1440 px, clair et sombre, LTR et RTL ;
// - la lecture d'une saisie de montant.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_saisis.dart';
import 'package:rewayah_academy/core/capacites/rpc_finance_supabase.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_finance/paiements/paiements_page.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

const ElevePourPaiement _bilal = ElevePourPaiement(
  profilId: 'e2',
  prenom: 'Bilal',
  nom: 'F1',
  matricule: 'RA-26-4817',
  resteAPayer: Montant(5000, 'USD'),
);

const ElevePourPaiement _yasmine = ElevePourPaiement(
  profilId: 'e1',
  prenom: 'Yasmine',
  nom: 'F1',
  matricule: 'RA-26-1203',
  resteAPayer: Montant(0, 'USD'),
);

/// L'etat financier rendu par le serveur (base rejouee, FAC-C-01).
Map<String, dynamic> _finance({
  required String etat,
  int? manque,
}) => jsonDecode(
  '{"age": null, "etat": "$etat", "solde": {"devise": "USD", "mineur": 0}, '
  '"classe": "An-Nour", "manque": '
  '${manque == null ? 'null' : '{"devise": "USD", "mineur": $manque}'}, '
  '"prenom": "Bilal", "periode": null, "profilId": "e2", "cleAccent": "e2", '
  '"cleAvatar": null, "estAdulte": false, "mensualite": {"devise": "USD", '
  '"mineur": 5000}, "prochainDebit": null, "essaisUtilises": null, '
  '"finConservation": null, "lignesMensualite": []}',
) as Map<String, dynamic>;

class _Port implements PortPaiementsSaisis {
  _Port({
    this.liste = const <ElevePourPaiement>[_bilal, _yasmine],
    this.erreurListe,
    this.reponses = const <Object>[],
  });

  final List<ElevePourPaiement> liste;
  final Object? erreurListe;

  /// Une reponse par envoi, dans l'ordre : un [PaiementEnregistre] ou
  /// l'erreur a lever.
  final List<Object> reponses;
  int lectures = 0;
  final List<(String, Montant, String, String?)> envois =
      <(String, Montant, String, String?)>[];

  @override
  Future<List<ElevePourPaiement>> eleves() {
    lectures++;
    final Object? e = erreurListe;
    return e == null
        ? Future<List<ElevePourPaiement>>.value(liste)
        : Future<List<ElevePourPaiement>>.error(e);
  }

  @override
  Future<PaiementEnregistre> enregistrer({
    required String profilId,
    required Montant montant,
    required String cle,
    String? reference,
  }) {
    envois.add((profilId, montant, cle, reference));
    final Object r = reponses[envois.length - 1];
    return r is PaiementEnregistre
        ? Future<PaiementEnregistre>.value(r)
        : Future<PaiementEnregistre>.error(r);
  }
}

PaiementEnregistre _fait({
  required String etat,
  int? manque,
  bool nouveau = true,
}) => PaiementEnregistre(
  paiementId: '1',
  nouveau: nouveau,
  finance: financesProfilJson(_finance(etat: etat, manque: manque)),
);

Widget _hote(
  PortPaiementsSaisis port, {
  double echelle = 1,
  Brightness luminosite = Brightness.light,
  TextDirection sens = TextDirection.ltr,
  bool horsLigne = false,
}) => ProviderScope(
  overrides: <Override>[
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
    sansPersonneConnectee(),
    portPaiementsSaisisProvider.overrideWithValue(port),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
      themeMode: luminosite == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (BuildContext context, Widget? app) => Directionality(
        textDirection: sens,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(echelle)),
          child: app!,
        ),
      ),
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

void _taille(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _ouvrirBilal(WidgetTester tester) =>
    _toucher(tester, find.byKey(PaiementsBloc.cleEleve('e2')));

Finder _champ(Key cle) =>
    find.descendant(of: find.byKey(cle), matching: find.byType(TextField));

Future<void> _enregistrer(WidgetTester tester) =>
    _toucher(tester, find.byKey(FeuillePaiement.cleEnregistrer));

void main() {
  final p = t.admin.finance.pai;

  group('liste', () {
    testWidgets('a regulariser puis a jour, montants rendus par la source', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(_Port()));
      await tester.pumpAndSettle();
      expect(find.text(p.sousTitre), findsOneWidget);
      expect(find.text(p.aRegulariser), findsOneWidget);
      // Le titre de la section et la valeur de la ligne de Yasmine.
      expect(find.text(p.aJour), findsNWidgets(2));
      expect(find.text('Bilal F1'), findsOneWidget);
      expect(find.text('RA-26-4817'), findsOneWidget);
      expect(
        find.text(formaterMontant(const Montant(5000, 'USD'))),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Bilal F1')).dy,
        lessThan(tester.getTopLeft(find.text('Yasmine F1')).dy),
      );
      verifierUnSeulBoutonPlein(tester, maximum: 0);
    });

    testWidgets('vide : une phrase, aucune ligne', (WidgetTester tester) async {
      await tester.pumpWidget(_hote(_Port(liste: const <ElevePourPaiement>[])));
      await tester.pumpAndSettle();
      expect(find.byKey(PaiementsBloc.cleVide), findsOneWidget);
      expect(find.text(p.videTitre), findsOneWidget);
    });
  });

  group('fiche', () {
    testWidgets('montant prerempli, une action pleine, mois regle, liste '
        'relue', (WidgetTester tester) async {
      final _Port port = _Port(reponses: <Object>[_fait(etat: 'finance')]);
      await tester.pumpWidget(_hote(port));
      await tester.pumpAndSettle();
      await _ouvrirBilal(tester);
      expect(find.text(p.feuilleTitre(prenom: 'Bilal')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(_champ(FeuillePaiement.cleMontant))
            .controller!
            .text,
        '50',
      );
      expect(find.text(p.enregistrer(prenom: 'Bilal')), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      await tester.enterText(
        _champ(FeuillePaiement.cleReference),
        '  VIR-2026-10  ',
      );
      await _enregistrer(tester);
      expect(port.envois, hasLength(1));
      expect(port.envois.single.$1, 'e2');
      expect(port.envois.single.$2, const Montant(5000, 'USD'));
      expect(port.envois.single.$4, 'VIR-2026-10');
      expect(find.text(p.faitTitre), findsOneWidget);
      expect(find.text(p.moisRegle(prenom: 'Bilal')), findsOneWidget);
      expect(find.byKey(FeuillePaiement.cleEnregistrer), findsNothing);
      expect(port.lectures, 1);
      await _toucher(tester, find.text(p.fermer));
      expect(port.lectures, 2);
    });

    testWidgets('paiement partiel : il manque encore, dit par la source', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port(
        reponses: <Object>[_fait(etat: 'expire', manque: 2000)],
      );
      await tester.pumpWidget(_hote(port));
      await tester.pumpAndSettle();
      await _ouvrirBilal(tester);
      await tester.enterText(_champ(FeuillePaiement.cleMontant), '30');
      await _enregistrer(tester);
      expect(port.envois.single.$2, const Montant(3000, 'USD'));
      expect(port.envois.single.$4, isNull);
      expect(
        find.text(
          p.ilManque(
            montant: formaterMontant(const Montant(2000, 'USD')),
            prenom: 'Bilal',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('deja enregistre : rien n a ete ajoute', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(
          _Port(reponses: <Object>[_fait(etat: 'finance', nouveau: false)]),
        ),
      );
      await tester.pumpAndSettle();
      await _ouvrirBilal(tester);
      await _enregistrer(tester);
      expect(find.text(p.dejaEnregistre), findsOneWidget);
    });

    testWidgets('montant illisible : la phrase, rien ne part', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port();
      await tester.pumpWidget(_hote(port));
      await tester.pumpAndSettle();
      await _ouvrirBilal(tester);
      for (final String saisie in <String>['', '0', 'abc', '12,345']) {
        await tester.enterText(_champ(FeuillePaiement.cleMontant), saisie);
        await _enregistrer(tester);
        expect(find.text(p.erreurMontant), findsOneWidget);
      }
      expect(port.envois, isEmpty);
    });

    for (final (MotifRefusPaiement motif, String Function() phrase)
        in <(MotifRefusPaiement, String Function())>[
          (MotifRefusPaiement.droits, () => t.admin.finance.pai.refusDroits),
          (
            MotifRefusPaiement.invalide,
            () => t.admin.finance.pai.refusInvalide,
          ),
        ]) {
      testWidgets('refus ${motif.name} : rien n a ete enregistre', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _hote(_Port(reponses: <Object>[RefusPaiement(motif)])),
        );
        await tester.pumpAndSettle();
        await _ouvrirBilal(tester);
        await _enregistrer(tester);
        expect(find.text(p.refusTitre), findsOneWidget);
        expect(find.text(phrase()), findsOneWidget);
        expect(find.byKey(FeuillePaiement.cleEnregistrer), findsNothing);
      });
    }

    testWidgets('issue inconnue : « Reessayer » rejoue la meme cle et le '
        'meme montant', (WidgetTester tester) async {
      final _Port port = _Port(
        reponses: <Object>[
          StateError('panne'),
          _fait(etat: 'finance'),
        ],
      );
      await tester.pumpWidget(_hote(port));
      await tester.pumpAndSettle();
      await _ouvrirBilal(tester);
      await tester.enterText(_champ(FeuillePaiement.cleMontant), '50,50');
      await _enregistrer(tester);
      expect(find.text(p.inconnuTitre), findsOneWidget);
      expect(find.text(p.reessayer), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      await _enregistrer(tester);
      expect(port.envois, hasLength(2));
      expect(port.envois[1].$3, port.envois[0].$3);
      expect(port.envois[1].$2, const Montant(5050, 'USD'));
      expect(port.envois[0].$2, const Montant(5050, 'USD'));
      expect(find.text(p.moisRegle(prenom: 'Bilal')), findsOneWidget);
    });

    testWidgets('hors ligne : une phrase, aucun envoi possible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(_Port(), horsLigne: true));
      await tester.pumpAndSettle();
      await _ouvrirBilal(tester);
      expect(find.text(p.horsLigne), findsOneWidget);
      expect(find.byKey(FeuillePaiement.cleEnregistrer), findsNothing);
    });
  });

  group('etats', () {
    testWidgets('chargement : le squelette', (WidgetTester tester) async {
      final Completer<List<ElevePourPaiement>> attente =
          Completer<List<ElevePourPaiement>>();
      await tester.pumpWidget(_hote(_PortSuspendu(attente.future)));
      await tester.pump();
      expect(find.byType(Skeleton), findsWidgets);
      attente.complete(const <ElevePourPaiement>[]);
      await tester.pumpAndSettle();
    });

    for (final (String nom, Object erreur, NatureEtat nature)
        in <(String, Object, NatureEtat)>[
          (
            'indisponible',
            const CapaciteIndisponible('FI-BR-14'),
            NatureEtat.indisponible,
          ),
          ('erreur', StateError('panne'), NatureEtat.echecServeur),
        ]) {
      testWidgets('$nom : l etat systeme, aucune ligne', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_hote(_Port(erreurListe: erreur)));
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (Widget w) => w is EtatSysteme && w.nature == nature,
          ),
          findsOneWidget,
        );
        expect(find.byKey(PaiementsBloc.cleEleve('e2')), findsNothing);
      });
    }
  });

  group('mise en page', () {
    for (final (Size taille, double echelle) in <(Size, double)>[
      (const Size(320, 640), 2),
      (const Size(1440, 900), 1),
    ]) {
      for (final Brightness luminosite in Brightness.values) {
        for (final TextDirection sens in TextDirection.values) {
          testWidgets('${taille.width.toInt()} px, texte x$echelle, '
              '${luminosite.name}, ${sens.name} : liste et fiche sans '
              'debordement', (WidgetTester tester) async {
            _taille(tester, taille);
            await tester.pumpWidget(
              _hote(
                _Port(reponses: <Object>[_fait(etat: 'expire', manque: 2000)]),
                echelle: echelle,
                luminosite: luminosite,
                sens: sens,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await _ouvrirBilal(tester);
            expect(tester.takeException(), isNull);
            verifierUnSeulBoutonPlein(tester);
            await _enregistrer(tester);
            expect(tester.takeException(), isNull);
            expect(find.text(p.faitTitre), findsOneWidget);
          });
        }
      }
    }
  });

  group('lecture d une saisie', () {
    test('mineurDepuisSaisie', () {
      expect(mineurDepuisSaisie('50', 'USD'), 5000);
      expect(mineurDepuisSaisie(' 50,5 ', 'USD'), 5050);
      expect(mineurDepuisSaisie('50.05', 'USD'), 5005);
      expect(mineurDepuisSaisie('1 500', 'USD'), 150000);
      expect(mineurDepuisSaisie('0', 'USD'), isNull);
      expect(mineurDepuisSaisie('-5', 'USD'), isNull);
      expect(mineurDepuisSaisie('5,123', 'USD'), isNull);
      expect(mineurDepuisSaisie('abc', 'USD'), isNull);
      expect(mineurDepuisSaisie('1500000', 'GNF'), 1500000);
      expect(mineurDepuisSaisie('15,5', 'GNF'), isNull);
    });

    test('saisieDepuisMontant', () {
      expect(saisieDepuisMontant(const Montant(5000, 'USD')), '50');
      expect(saisieDepuisMontant(const Montant(5050, 'USD')), '50,50');
      expect(saisieDepuisMontant(const Montant(5, 'USD')), '0,05');
      expect(saisieDepuisMontant(const Montant(0, 'USD')), '');
      expect(saisieDepuisMontant(const Montant(1500000, 'GNF')), '1500000');
    });
  });
}

class _PortSuspendu extends _Port {
  _PortSuspendu(this._attente);

  final Future<List<ElevePourPaiement>> _attente;

  @override
  Future<List<ElevePourPaiement>> eleves() => _attente;
}
