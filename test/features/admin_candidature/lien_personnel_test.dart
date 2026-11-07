// INVITATIONS-PERSONNELLES (lot 7, 07/11/2026), option (a) du garde-cap :
// « Copier le lien d'inscription » d'une ligne de suivi sans adresse.
//
// Ce que le test prouve :
// - l'entree n'existe dans « Autres gestes » que pour une ligne gardee pour
//   suivi (recue, en cours) SANS adresse, au super administrateur, port servi ;
// - la feuille : l'adresse saisie part au serveur avec la ligne ; un refus est
//   dit en mots ; pret : le code et le lien, affiches et selectionnables ;
// - la copie : presse-papiers ; refusee, « selectionnez le lien » et le lien
//   reste a l'ecran ;
// - une coupure : « non confirme », « Reessayer » avec la meme adresse.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_invitations_personnelles.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/admin_candidature/blocs_candidature.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_lien_personnel.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../fixtures/candidature/faux_import_candidatures.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidature.dart';

class _Faux implements PortInvitationsPersonnelles {
  final List<(String, String)> appels = <(String, String)>[];
  ResultatLien Function(String courriel) reponse = (String _) => LienPret(
    code: 'ABCD-EFGH-JKMN',
    expireLe: DateTime.utc(2026, 11, 21, 10),
  );
  Exception? erreur;

  @override
  Future<ApercuInvitationsPersonnelles> apercu() => throw UnimplementedError();

  @override
  Future<ResultatInvitationsPersonnelles> envoyer({
    required int attendu,
    int limite = limiteInvitationsParEnvoi,
  }) => throw UnimplementedError();

  @override
  Future<ResultatLien> lienPour({
    required String candidatureId,
    required String courriel,
  }) async {
    appels.add((candidatureId, courriel));
    final Exception? e = erreur;
    if (e != null) throw e;
    return reponse(courriel);
  }
}

String get _action => t.candidatsFlux.invitationsPersonnelles.lienCopie.action;

Future<void> _monter(
  WidgetTester tester,
  _Faux? faux, {
  EtapeCandidature etape = EtapeCandidature.recue,
  bool courrielAObtenir = true,
  bool peutImporter = true,
}) => monterCandidature(
  tester,
  port: FauxCandidaturesDirection(
    capacitesRendues: capacitesGestes,
    details: <DetailCandidature>[
      detailTest(
        etape: etape,
        etat: null,
        courrielAObtenir: courrielAObtenir,
        provenance: null,
      ),
    ],
  ),
  surcharges: <Override>[
    portImportCandidaturesProvider.overrideWithValue(
      FauxImportCandidatures(
        capacitesRendues: CapacitesImportCandidatures(
          peutImporter: peutImporter,
        ),
      ),
    ),
    portInvitationsPersonnellesProvider.overrideWithValue(faux),
  ],
);

Future<bool> _entreePresente(WidgetTester tester) async {
  final Finder menu = find.byKey(BlocProchaineAction.cleMenu);
  if (menu.evaluate().isEmpty) return false;
  await tester.ensureVisible(menu);
  await laisser(tester, fois: 2);
  await tester.tap(menu, warnIfMissed: false);
  await laisser(tester);
  final bool la = find.text(_action).evaluate().isNotEmpty;
  return la;
}

Future<void> _ouvrirFeuille(WidgetTester tester) async {
  expect(await _entreePresente(tester), isTrue);
  await tester.tap(find.text(_action).last);
  await laisser(tester);
  expect(find.byKey(FeuilleLienPersonnel.cleChamp), findsOneWidget);
}

Future<void> _preparer(WidgetTester tester, String adresse) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(FeuilleLienPersonnel.cleChamp),
      matching: find.byType(EditableText),
    ),
    adresse,
  );
  await laisser(tester, fois: 2);
  final Finder b = find.byKey(FeuilleLienPersonnel.clePreparer);
  await tester.ensureVisible(b);
  await laisser(tester, fois: 2);
  await tester.tap(b);
  await laisser(tester);
}

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('l entree du menu', () {
    testWidgets('ligne de suivi sans adresse, super administrateur', (
      tester,
    ) async {
      await _monter(tester, _Faux());
      expect(await _entreePresente(tester), isTrue);
    });

    testWidgets('absente si la ligne a une adresse', (tester) async {
      await _monter(tester, _Faux(), courrielAObtenir: false);
      expect(await _entreePresente(tester), isFalse);
    });

    testWidgets('absente hors d une ligne de suivi', (tester) async {
      await _monter(tester, _Faux(), etape: EtapeCandidature.prequalification);
      expect(await _entreePresente(tester), isFalse);
    });

    testWidgets('absente pour qui ne peut pas importer', (tester) async {
      await _monter(tester, _Faux(), peutImporter: false);
      expect(await _entreePresente(tester), isFalse);
    });

    testWidgets('absente sans le port', (tester) async {
      await _monter(tester, null);
      expect(await _entreePresente(tester), isFalse);
    });
  });

  group('la feuille', () {
    testWidgets('pret : le code et le lien, selectionnables ; copie', (
      tester,
    ) async {
      final _Faux faux = _Faux();
      final List<String> copies = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall appel) async {
          if (appel.method == 'Clipboard.setData') {
            copies.add(
              (appel.arguments as Map<Object?, Object?>)['text']! as String,
            );
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _monter(tester, faux);
      await _ouvrirFeuille(tester);
      verifierUnSeulBoutonPlein(tester);
      await _preparer(tester, 'personne@test.invalid');
      expect(faux.appels, <(String, String)>[('c1', 'personne@test.invalid')]);
      expect(find.byKey(FeuilleLienPersonnel.cleCode), findsOneWidget);
      expect(find.text('ABCD-EFGH-JKMN'), findsOneWidget);
      expect(
        find.byType(SelectableText),
        findsNWidgets(2),
        reason: 'le code et le lien se selectionnent',
      );
      expect(find.byKey(FeuilleLienPersonnel.clePreparer), findsNothing);
      await tester.tap(find.byKey(FeuilleLienPersonnel.cleCopier));
      await laisser(tester);
      expect(copies.single, contains('invitation=1&code=ABCD-EFGH-JKMN'));
      expect(
        find.text(t.candidatsFlux.invitationsPersonnelles.lienCopie.copie),
        findsOneWidget,
      );
    });

    testWidgets('copie refusee : le lien reste, la phrase dit quoi faire', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall appel) async {
          if (appel.method == 'Clipboard.setData') {
            throw PlatformException(code: 'refus');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _monter(tester, _Faux());
      await _ouvrirFeuille(tester);
      await _preparer(tester, 'personne@test.invalid');
      await tester.tap(find.byKey(FeuilleLienPersonnel.cleCopier));
      await laisser(tester);
      expect(
        find.text(t.candidatsFlux.invitationsPersonnelles.lienCopie.copieEchec),
        findsOneWidget,
      );
      expect(find.byKey(FeuilleLienPersonnel.cleLien), findsOneWidget);
    });

    testWidgets('refus du serveur : dit en mots, le champ reste', (
      tester,
    ) async {
      final _Faux faux = _Faux()
        ..reponse = (String _) => const LienRefuse(RefusLien.adresseUtilisee);
      await _monter(tester, faux);
      await _ouvrirFeuille(tester);
      await _preparer(tester, 'deja@test.invalid');
      expect(find.byKey(FeuilleLienPersonnel.cleRefus), findsOneWidget);
      expect(
        find.text(
          t
              .candidatsFlux
              .invitationsPersonnelles
              .lienCopie
              .refus
              .adresseUtilisee,
        ),
        findsOneWidget,
      );
      expect(find.byKey(FeuilleLienPersonnel.cleChamp), findsOneWidget);
      expect(find.byKey(FeuilleLienPersonnel.cleCode), findsNothing);
    });

    testWidgets('coupure : non confirme, Reessayer avec la meme adresse', (
      tester,
    ) async {
      final _Faux faux = _Faux()
        ..erreur = const InvitationsPersonnellesHorsLigne();
      await _monter(tester, faux);
      await _ouvrirFeuille(tester);
      await _preparer(tester, 'personne@test.invalid');
      expect(find.byKey(FeuilleLienPersonnel.cleNonConfirme), findsOneWidget);
      expect(
        tester
            .widget<ActionPrincipale>(
              find.byKey(FeuilleLienPersonnel.clePreparer),
            )
            .libelle,
        t.commun.reessayer,
      );
      faux.erreur = null;
      await tester.tap(find.byKey(FeuilleLienPersonnel.clePreparer));
      await laisser(tester);
      expect(faux.appels.last.$2, 'personne@test.invalid');
      expect(find.byKey(FeuilleLienPersonnel.cleCode), findsOneWidget);
    });
  });
}
