// Captures du tolere n° 1 et 18 (08/11/2026) : « Mon espace » de
// l'Interface guidee sur `/compte`, la demande de presentation standard du
// mineur envoyee, puis la meme demande sans reseau. 390x844 @3 et
// 1440x900 @1, clair, francais et arabe. Donnees de test uniquement.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/demande_presentation_supabase.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/accessibilite/port_demande_presentation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/accueil_eleve/mon_espace_accessibilite.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';

import '../support/harnais.dart' show FauxServiceReseau;
import 'outil_capture.dart';

class _Port implements PortDemandePresentation {
  @override
  Future<void> demanderPresentationStandard() async {}
}

class _Session extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.student,
    profileId: 'p-eleve',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

void main() {
  group('Capture : Mon espace guide', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (Size taille, double densite) in <(Size, double)>[
      (const Size(390, 844), 3),
      (const Size(1440, 900), 1),
    ]) {
      final String format =
          '${taille.width.toInt()}x${taille.height.toInt()}@${densite.toInt()}';
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        for (final bool horsLigne in <bool>[false, true]) {
          final String cas =
              '${langue.languageCode}_${horsLigne ? 'hors_ligne' : 'envoyee'}';
          testWidgets('$format, $cas', (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(tester, taille, densite);
            await tester.pumpWidget(
              hoteCapture(
                const MonEspaceAccessibiliteBranche(),
                interfaceMode: InterfaceMode.enfant,
                surcharges: <Override>[
                  sessionProvider.overrideWith(_Session.new),
                  prenomDuCompteProvider.overrideWith(
                    (Ref _) async =>
                        langue == AppLocale.ar ? 'ياسمين' : 'Yasmine',
                  ),
                  portDemandePresentationProvider.overrideWithValue(_Port()),
                  modeAccessibiliteActifProvider.overrideWithValue(true),
                  serviceReseauProvider.overrideWithValue(
                    FauxServiceReseau(horsLigneRendu: horsLigne),
                  ),
                ],
              ),
            );
            await stabiliser(tester);
            final Finder ligne = find.text(
              t.accessibilite.monEspace.presentationStandard,
            );
            await tester.ensureVisible(ligne);
            await tester.tap(ligne);
            await stabiliser(tester);
            expect(
              find.text(
                horsLigne
                    ? t.accessibilite.monEspace.demandeHorsLigne
                    : t.accessibilite.monEspace.demandeEnvoyee,
              ),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, 'me_${format}_$cas')}');
            await tester.pumpWidget(const SizedBox());
            await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
          });
        }
      }
    }
  });
}
