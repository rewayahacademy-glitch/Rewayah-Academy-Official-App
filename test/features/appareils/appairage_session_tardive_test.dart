// AUTRE-PROFIL-ELEVE (12/11/2026) : rechargee sur son adresse, la page
// d'appairage s'ouvrait avant que la session connaisse le compte (mesure sur
// la pile locale : `profileId` encore nul a la demande de code). Le titulaire
// recevait alors une demande de code refusee par le serveur. La page attend
// le compte, puis decide : titulaire, aucune demande ; sinon, le code.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/statut_code_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_famille/feuille_autre_appareil.dart';
import 'package:rewayah_academy/features/appareils/appairage_page.dart';

import '../../support/harnais.dart';
import 'faux_statut_code.dart';

/// Une session qui arrive APRES l'ouverture de la page.
class _SessionTardive implements SourceSession {
  // Ferme par chaque test (addTearDown).
  // ignore: close_sinks
  final StreamController<SessionState> flux =
      StreamController<SessionState>.broadcast();

  @override
  Stream<SessionState> etats() => flux.stream;

  @override
  Future<void> rafraichir() async {}
}

const String _titulaireId = 'titulaire-1';

SessionState _session(String profil) => SessionState(
  resolue: true,
  role: AppRole.guardian,
  profileId: profil,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

Future<FauxServiceAppairage> _monter(
  WidgetTester tester,
  _SessionTardive session,
  String eleveId,
) async {
  final FauxServiceAppairage service = FauxServiceAppairage();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sourceSessionProvider.overrideWithValue(session),
        serviceAppairageProvider.overrideWithValue(service),
        portStatutCodeAppairageProvider.overrideWithValue(FauxStatutCode()),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: AppairagePage(eleveId: eleveId),
        ),
      ),
    ),
  );
  await tester.pump();
  return service;
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('le titulaire connu apres l ouverture : aucune demande de code', (
    WidgetTester tester,
  ) async {
    final _SessionTardive session = _SessionTardive();
    addTearDown(session.flux.close);
    final FauxServiceAppairage service = await _monter(
      tester,
      session,
      _titulaireId,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(service.codesDemandes, isEmpty);
    session.flux.add(_session(_titulaireId));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(service.codesDemandes, isEmpty);
    expect(find.byType(CorpsAutreAppareil), findsOneWidget);
  });

  testWidgets('un enfant, compte connu apres l ouverture : le code est '
      'demande une fois', (WidgetTester tester) async {
    final _SessionTardive session = _SessionTardive();
    addTearDown(session.flux.close);
    final FauxServiceAppairage service = await _monter(
      tester,
      session,
      'enfant-1',
    );
    await tester.pump(const Duration(seconds: 1));
    expect(service.codesDemandes, isEmpty);
    session.flux.add(_session(_titulaireId));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(service.codesDemandes, <String>['enfant-1']);
    expect(find.byType(CorpsAutreAppareil), findsNothing);
  });
}
