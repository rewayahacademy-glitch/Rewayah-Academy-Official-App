// Suite de BE-2a-2 : l'inscription d'un associe invite. Chaque etat (port
// absent, saisie, verification, formulaire, code inconnu, expire ou deja utilise,
// hors ligne, panne, creation refusee ou non confirmee), le lien avec `code`
// verifie des l'ouverture, et ce que le serveur recoit.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/equipe/port_inscription_associe.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/inscription/associe_page.dart';

import '../../support/harnais.dart';
import '../../support/monter_recrutement.dart';

class _Port implements PortInscriptionAssocie {
  _Port({
    this.verification = const CodeAssocieValide(null),
    this.creation = ResultatInscriptionAssocie.consommee,
    this.erreurVerification,
    this.erreurCreation,
  });

  final ResultatCodeAssocie verification;
  final ResultatInscriptionAssocie creation;
  final Exception? erreurVerification;
  final Exception? erreurCreation;
  final List<String> codesVerifies = <String>[];
  final List<Map<String, String>> creations = <Map<String, String>>[];
  Completer<void>? attente;

  @override
  Future<ResultatCodeAssocie> verifier(String code) async {
    codesVerifies.add(code);
    await attente?.future;
    if (erreurVerification != null) throw erreurVerification!;
    return verification;
  }

  @override
  Future<ResultatInscriptionAssocie> inscrire({
    required String code,
    required String prenom,
    required String nom,
    required String genre,
  }) async {
    creations.add(<String, String>{
      'code': code,
      'prenom': prenom,
      'nom': nom,
      'genre': genre,
    });
    if (erreurCreation != null) throw erreurCreation!;
    return creation;
  }
}

Future<void> _monter(
  WidgetTester tester, {
  PortInscriptionAssocie? port,
  bool horsLigne = false,
  String? depart,
  FausseSourceSession? session,
  double largeur = 390,
}) => monterRecrutement(
  tester,
  chemin: Routes.inscriptionAssocie,
  depart: depart,
  autres: <String>[
    Routes.inscriptionUsage,
    Routes.connexion,
    Routes.adminPersonnesCandidatures,
  ],
  ecran: (state) => AssociePage(codeInitial: state.uri.queryParameters['code']),
  surcharges: <Override>[
    portInscriptionAssocieProvider.overrideWithValue(port),
    sourceSessionProvider.overrideWithValue(session ?? FausseSourceSession()),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
);

Future<void> _verifier(WidgetTester tester, String code) async {
  await tester.enterText(find.byKey(AssociePage.cleCode), code);
  await tester.tap(find.byKey(AssociePage.cleVerifier));
  await laisser(tester);
}

Future<void> _remplir(WidgetTester tester, {bool genre = true}) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('associe-prenom')),
    'Karim',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('associe-nom')),
    'Associe',
  );
  if (genre) {
    await tester.tap(find.text(t.inscription.genreHomme));
    await laisser(tester);
  }
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final r = t.inscription.associe;

  testWidgets('port absent : une phrase, aucun champ', (tester) async {
    await _monter(tester);
    expect(
      find.byKey(const ValueKey<String>('associe-indisponible')),
      findsOneWidget,
    );
    expect(find.byKey(AssociePage.cleCode), findsNothing);
  });

  testWidgets('saisie vide : erreur de champ, rien n\'est envoye', (
    tester,
  ) async {
    final _Port port = _Port();
    await _monter(tester, port: port);
    await tester.tap(find.byKey(AssociePage.cleVerifier));
    await laisser(tester);
    expect(find.text(r.champVide), findsOneWidget);
    expect(port.codesVerifies, isEmpty);
  });

  testWidgets('verification en cours : le bouton le dit, le champ est fige', (
    tester,
  ) async {
    final _Port port = _Port()..attente = Completer<void>();
    await _monter(tester, port: port);
    await tester.enterText(find.byKey(AssociePage.cleCode), 'abcd-efgh-jkmn');
    await tester.tap(find.byKey(AssociePage.cleVerifier));
    await tester.pump(const Duration(milliseconds: 100));
    expect(port.codesVerifies, <String>['abcd-efgh-jkmn']);
    port.attente!.complete();
    await laisser(tester);
  });

  testWidgets('code valide : le formulaire (date, prenom, nom, genre)', (
    tester,
  ) async {
    final _Port port = _Port(
      verification: CodeAssocieValide(DateTime.utc(2026, 12, 1)),
    );
    await _monter(tester, port: port);
    await _verifier(tester, 'ABCD-EFGH-JKMN');
    expect(
      find.byKey(const ValueKey<String>('associe-valide')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('associe-prenom')),
      findsOneWidget,
    );
    expect(find.byKey(AssociePage.cleCreer), findsOneWidget);
    expect(find.text(r.genreHommeExplication), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un lien avec le code le verifie des l\'ouverture', (
    tester,
  ) async {
    final _Port port = _Port();
    await _monter(
      tester,
      port: port,
      depart: '${Routes.inscriptionAssocie}?code=ABCD-EFGH-JKMN',
    );
    expect(port.codesVerifies, <String>['ABCD-EFGH-JKMN']);
    expect(find.byKey(AssociePage.cleCreer), findsOneWidget);
  });

  group('code refuse : vide, avec la suite', () {
    for (final (String nom, ResultatCodeAssocie res, String cle)
        in <(String, ResultatCodeAssocie, String)>[
          ('inconnu', const CodeAssocieInconnu(), 'associe-inconnue'),
          ('expire', const CodeAssocieExpire(), 'associe-expiree'),
          (
            'deja utilise',
            const CodeAssocieDejaUtilise(),
            'associe-deja-utilisee',
          ),
        ]) {
      testWidgets(nom, (tester) async {
        await _monter(tester, port: _Port(verification: res));
        await _verifier(tester, 'ABCD-EFGH-JKMN');
        expect(find.byKey(ValueKey<String>(cle)), findsOneWidget);
        expect(find.byKey(AssociePage.cleCreer), findsNothing);
      });
    }
  });

  testWidgets('hors ligne : la phrase, aucun bouton', (tester) async {
    await _monter(tester, port: _Port(), horsLigne: true);
    expect(find.text(r.horsLigne), findsOneWidget);
    expect(find.byKey(AssociePage.cleVerifier), findsNothing);
  });

  testWidgets('verification en panne : une phrase vraie, le code est garde', (
    tester,
  ) async {
    await _monter(tester, port: _Port(erreurVerification: Exception('x')));
    await _verifier(tester, 'ABCD-EFGH-JKMN');
    expect(find.text(r.erreur), findsOneWidget);
    expect(find.byKey(AssociePage.cleVerifier), findsOneWidget);
  });

  testWidgets('verification : reseau manquant dit hors ligne', (tester) async {
    await _monter(
      tester,
      port: _Port(erreurVerification: const HorsLigneInscriptionAssocie()),
    );
    await _verifier(tester, 'ABCD-EFGH-JKMN');
    expect(find.text(r.horsLigne), findsOneWidget);
  });

  testWidgets('creation sans genre : rien n\'est envoye', (tester) async {
    final _Port port = _Port();
    await _monter(tester, port: port);
    await _verifier(tester, 'ABCD-EFGH-JKMN');
    await _remplir(tester, genre: false);
    await tester.ensureVisible(find.byKey(AssociePage.cleCreer));
    await tester.tap(find.byKey(AssociePage.cleCreer));
    await laisser(tester);
    expect(find.text(r.champsManquants), findsOneWidget);
    expect(port.creations, isEmpty);
  });

  testWidgets(
    'creation : le serveur recoit code, prenom, nom, genre ; arrivee',
    (tester) async {
      final _Port port = _Port();
      await _monter(tester, port: port, session: FausseSourceSession());
      await _verifier(tester, 'ABCD-EFGH-JKMN');
      await _remplir(tester);
      await tester.ensureVisible(find.byKey(AssociePage.cleCreer));
      await tester.tap(find.byKey(AssociePage.cleCreer));
      await laisser(tester);
      expect(port.creations, <Map<String, String>>[
        <String, String>{
          'code': 'ABCD-EFGH-JKMN',
          'prenom': 'Karim',
          'nom': 'Associe',
          'genre': 'male',
        },
      ]);
      expect(
        find.text('temoin:${Routes.adminPersonnesCandidatures}'),
        findsOneWidget,
      );
    },
  );

  testWidgets('creation refusee par le serveur : une phrase par cause', (
    tester,
  ) async {
    for (final (Exception erreur, String phrase) in <(Exception, String)>[
      (
        const RefusInscriptionAssocie(
          CauseRefusInscriptionAssocie.sessionRefusee,
        ),
        r.sessionRefusee,
      ),
      (
        const RefusInscriptionAssocie(
          CauseRefusInscriptionAssocie.champsRefuses,
        ),
        r.champsRefuses,
      ),
      (const HorsLigneInscriptionAssocie(), r.horsLigne),
      (Exception('x'), r.nonConfirme),
    ]) {
      await _monter(tester, port: _Port(erreurCreation: erreur));
      await _verifier(tester, 'ABCD-EFGH-JKMN');
      await _remplir(tester);
      await tester.ensureVisible(find.byKey(AssociePage.cleCreer));
      await tester.tap(find.byKey(AssociePage.cleCreer));
      await laisser(tester);
      expect(find.text(phrase), findsOneWidget, reason: phrase);
      expect(
        find.text('temoin:${Routes.adminPersonnesCandidatures}'),
        findsNothing,
      );
    }
  });

  testWidgets('creation : code devenu inconnu entre-temps, retour au vide', (
    tester,
  ) async {
    await _monter(
      tester,
      port: _Port(creation: ResultatInscriptionAssocie.dejaUtilisee),
    );
    await _verifier(tester, 'ABCD-EFGH-JKMN');
    await _remplir(tester);
    await tester.ensureVisible(find.byKey(AssociePage.cleCreer));
    await tester.tap(find.byKey(AssociePage.cleCreer));
    await laisser(tester);
    expect(
      find.byKey(const ValueKey<String>('associe-deja-utilisee')),
      findsOneWidget,
    );
  });

  testWidgets('320 px : aucun debordement', (tester) async {
    await _monter(tester, port: _Port(), largeur: 320);
    await _verifier(tester, 'ABCD-EFGH-JKMN');
    expect(tester.takeException(), isNull);
  });
}
