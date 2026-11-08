// Captures de HARMONISATION-A (dette 2, 08/11/2026) : « Je suis pret »
// pendant la fenetre de priorite. La carte de preparation montre « Vous etes
// en tete… » et le compte a rebours (ou, pas en tete, la phrase d'attente),
// comme l'acceptation d'une absence. 390x844 @3 et 1440x900 @1, clair,
// francais et arabe. Donnees de test uniquement.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/absence_remplacement.dart';
import 'package:rewayah_academy/core/enseignant/port_remplacements.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/remplacements/remplacements_page.dart';

import 'outil_capture.dart';

class _Connecte extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.teacher,
    profileId: 'p-connecte',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

class _Flux implements PortRemplacements {
  _Flux(this.offres);

  final List<OffreCommune> offres;

  @override
  Stream<List<OffreCommune>> suivre() =>
      Stream<List<OffreCommune>>.value(offres);

  @override
  Future<ResultatPriseRemplacement> prendre(
    String seanceId, {
    void Function(AttenteRemplacement attente)? enAttente,
  }) async => ResultatPriseRemplacement.acceptee;
}

/// Le serveur repond « en attente » et ne tranche pas pendant la capture.
class _PretEnAttente implements PortPretRemplacement {
  _PretEnAttente({required this.enTete});

  final bool enTete;
  final Completer<ResultatPret> _jamais = Completer<ResultatPret>();

  @override
  Future<ResultatPret> seDeclarerPret(
    String seanceId, {
    void Function(AttenteRemplacement attente)? enAttente,
  }) {
    enAttente?.call(
      AttenteRemplacement(
        fin: DateTime.now().add(const Duration(seconds: 7)),
        enTete: enTete,
      ),
    );
    return _jamais.future;
  }
}

class _AucunConfirme extends RemplacementsControleur {
  @override
  List<OffreRemplacement> build() => const <OffreRemplacement>[];
}

final OffreRemplacement _offre = OffreRemplacement(
  seanceId: 'capture-pret',
  classe: 'Classe des adultes',
  debut: DateTime(2026, 11, 12, 18),
  fin: DateTime(2026, 11, 12, 18, 45),
  nbEleves: 4,
);

void main() {
  group(
    'Capture : HARMONISATION-A, « Je suis pret » en attente',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      for (final (Size taille, double densite) in <(Size, double)>[
        (const Size(390, 844), 3),
        (const Size(1440, 900), 1),
      ]) {
        final String format =
            '${taille.width.toInt()}x${taille.height.toInt()}@${densite.toInt()}';
        for (final AppLocale langue in <AppLocale>[
          AppLocale.fr,
          AppLocale.ar,
        ]) {
          for (final bool enTete in <bool>[true, false]) {
            final String cas =
                '${langue.languageCode}_${enTete ? 'en_tete' : 'attente'}';
            testWidgets('$format, $cas', (WidgetTester tester) async {
              await tester.runAsync(() => LocaleSettings.setLocale(langue));
              fixerVueCapture(tester, taille, densite);
              await tester.pumpWidget(
                hoteCapture(
                  const RemplacementsPage(),
                  surcharges: <Override>[
                    sessionProvider.overrideWith(_Connecte.new),
                    portRemplacementsProvider.overrideWithValue(
                      _Flux(<OffreCommune>[
                        OffreCommune(
                          offre: _offre,
                          etat: EtatOffreCommune.preparation,
                        ),
                      ]),
                    ),
                    portPretRemplacementProvider.overrideWithValue(
                      _PretEnAttente(enTete: enTete),
                    ),
                    horsLigneProvider.overrideWith(
                      (Ref _) => Stream<bool>.value(false),
                    ),
                    remplacementsConfirmesProvider.overrideWith(
                      _AucunConfirme.new,
                    ),
                  ],
                ),
              );
              await stabiliser(tester);
              await tester.tap(
                find.byKey(
                  ValueKey<String>('remplacement-pret-${_offre.seanceId}'),
                ),
              );
              await tester.pump(const Duration(milliseconds: 300));
              expect(find.byType(AttentePriorite), findsOneWidget);
              expect(tester.takeException(), isNull);
              debugPrint(
                'PNG ${await capturer(tester, 'pret_${format}_$cas')}',
              );
              await tester.pumpWidget(const SizedBox());
              await tester.runAsync(
                () => LocaleSettings.setLocale(AppLocale.fr),
              );
            });
          }
        }
      }
    },
  );
}
