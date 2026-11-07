// SALLE-3-ACCUEIL : captures de la carte « Bienvenue dans l'equipe » de
// l'espace enseignant sans Classe, en francais et en arabe, 390 x 844 et
// 1440 x 900, clair. Donnees de test seulement. Jamais sans `CAPTURE_DIR`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_coordonnees_versement.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/carte_bienvenue_equipe.dart';
import 'package:rewayah_academy/features/paiements_recus/etat_coordonnees.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

const String _id = 'prof-1';
const SessionState _session = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: _id,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  required bool arabe,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: '/',
      direction: arabe ? TextDirection.rtl : null,
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext _, GoRouterState _) => const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: CarteBienvenueEquipe(),
            ),
          ),
        ),
      ],
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(FausseSourceSession(_session)),
        mesCoordonneesVersementProvider.overrideWith(
          (Ref _) async => const MesCoordonneesVersement(
            deviseCible: 'USD',
            champs: <ChampDemande>[],
            enregistre: false,
            complet: false,
          ),
        ),
        profilEnseignantProvider.overrideWith(
          (Ref _) async => const ProfilEnseignant(
            prenom: 'Salma',
            identifiant: 'RA-26-0001',
          ),
        ),
        disponibilitesProvider(_id)
            .overrideWith((Ref _) async => const <Creneau>[]),
        baseLocaleEnMemoire(),
      ],
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture : carte Bienvenue dans l\'equipe', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final bool arabe in <bool>[false, true]) {
      final String langue = arabe ? 'ar' : 'fr';
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String s = '${taille.width.toInt()}x${taille.height.toInt()}';
        testWidgets('carte, $langue $s', (WidgetTester tester) async {
          await tester.runAsync(
            () => LocaleSettings.setLocale(arabe ? AppLocale.ar : AppLocale.fr),
          );
          addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
          await _monter(tester, taille, arabe: arabe);
          debugPrint(
            'PNG ${await capturerVue(tester, 'bienvenue_equipe_${langue}_$s')}',
          );
        });
      }
    }
  });
}
