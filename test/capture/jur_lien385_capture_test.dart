// Captures de JUR-LIEN-385-1 (decisions du directeur du 05/10/2026).
//
// Q-3 = b : le lien « En savoir plus » de la salle est cache sous 388 de
// large (la mention ouvre alors la lecture) ; present a 390 et 1440. Salle
// guidee a 320 x 690 et 390 x 844, texte x1, x1,5 et x2, et 1440 x 900, clair
// et sombre.
//
// Q-2 = a : l'ecran de nouvelle signature du contrat enseignant (politique de
// controle publiee, contrat 2026-09 deja signe), clair et sombre.
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/resignature_contrat.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/dossier/versions_contrat.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/dossier/signature_page.dart';
import 'package:rewayah_academy/features/salle_seance/information_controle.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

class _Enseignant extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.teacher,
    profileId: 'p1',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

void main() {
  group('Capture JUR-LIEN-385-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String nom, Size taille, double densite, double echelle)
        in <(String, Size, double, double)>[
          ('320x690_t100', const Size(320, 690), 2, 1),
          ('320x690_t150', const Size(320, 690), 2, 1.5),
          ('320x690_t200', const Size(320, 690), 2, 2),
          ('390x844_t100', const Size(390, 844), 2, 1),
          ('390x844_t150', const Size(390, 844), 2, 1.5),
          ('390x844_t200', const Size(390, 844), 2, 2),
          ('1440x900_t100', const Size(1440, 900), 1, 1),
        ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String m = mode == ThemeMode.light ? 'clair' : 'sombre';
        testWidgets('salle guidee $nom $m', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, densite);
          await tester.pumpWidget(
            hoteCapture(
              SalleDemo(
                role: RoleSeance.guidee,
                etat: EtatDemoSalle.repos,
                onSortir: () {},
              ),
              themeMode: mode,
              echelleTexte: echelle,
              interfaceMode: InterfaceMode.enfant,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          final bool lien =
              taille.width >= InformationControle.largeurMinimaleLien;
          expect(
            find.text(t.salle.informationControle.lien),
            lien ? findsOneWidget : findsNothing,
          );
          final String etat = lien ? 'lien' : 'sans_lien';
          debugPrint(
            'PNG ${await capturer(tester, 'jur385_salle_${nom}_${etat}_$m')}',
          );
        });
      }
    }

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final String m = mode == ThemeMode.light ? 'clair' : 'sombre';
      testWidgets('contrat enseignant a signer de nouveau $m', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 2400), 1);
        final FauxServiceDossier dossier = FauxServiceDossier()
          ..etatRendu = const EtatDossier(
            profilExiste: true,
            role: AppRole.teacher,
            statutCompte: AccountStatus.active,
            accuseSigne: true,
            contratSigne: true,
          );
        await tester.pumpWidget(
          hoteCapture(
            const ContratPage(),
            themeMode: mode,
            surcharges: <Override>[
              serviceDossierProvider.overrideWithValue(dossier),
              politiqueControlePublieeProvider.overrideWithValue(true),
              sessionProvider.overrideWith(_Enseignant.new),
              acceptationsProvider.overrideWith(
                (_) async => <Acceptation>[
                  Acceptation(
                    sorte: SorteContrat.contratEnseignant,
                    version: VersionsContrat.courante,
                    accepteeLe: DateTime(2026, 9, 21),
                  ),
                ],
              ),
            ],
          ),
        );
        await stabiliser(tester);
        expect(find.text(t.contrat.resignature), findsOneWidget);
        debugPrint(
          'PNG ${await capturer(tester, 'jur385_contrat_resignature_$m')}',
        );
      });
    }
  });
}
