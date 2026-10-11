// RECETTE-NUIT-A : garde de balayage. Balayage des ecrans sans parametre atteints depuis le
// routeur par l'eleve, le tuteur et l'enseignant, a 360 px, en francais et en
// arabe (RTL) : aucune exception de mise en page, aucun mot coupe, aucune
// cible tactile sous 48.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';

import '../capture/outil_capture.dart';
import '../router/support_routeur.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';

const double _cible = 48;

List<String> _cibles(WidgetTester tester) {
  final List<String> petites = <String>[];
  for (final Element e in find.byType(Pressable).evaluate()) {
    final Pressable p = e.widget as Pressable;
    if (p.onPress == null) continue;
    final Rect r = tester.getRect(find.byWidget(p));
    if (r.width < _cible - 0.5 || r.height < _cible - 0.5) {
      petites.add(
        '${p.libelleSemantique ?? '?'} ${r.width.round()}x${r.height.round()}',
      );
    }
  }
  return petites;
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  final Map<AppRole, List<String>> parRole = <AppRole, List<String>>{
    AppRole.student: <String>[
      Routes.eleve,
      Routes.eleveSuivi,
      Routes.eleveAide,
      Routes.eleveAdulte,
      Routes.eleveAdulteSeances,
      Routes.eleveAdulteDemandes,
      Routes.compte,
      Routes.compteReglages,
      Routes.tcGroupes,
    ],
    AppRole.guardian: <String>[
      Routes.tuteurAccueil,
      Routes.tuteurFoyer,
      Routes.tuteurFoyerAppareils,
      Routes.tuteurFoyerRecharge,
      Routes.tuteurSuivi,
      Routes.tuteurClasses,
      Routes.tuteurClassesCatalogue,
      Routes.tuteurCompte,
      Routes.tuteurComptePreferences,
      Routes.tuteurCompteApparence,
      Routes.tuteurCompteConsentements,
      Routes.tuteurNotifications,
      Routes.tuteurMessages,
      Routes.tuteurDemandes,
      Routes.tuteurPresentation,
      Routes.tuteurReglages,
      Routes.tuteurDisponibilites,
      Routes.ficheElevePour('inconnu'),
      Routes.parcoursPour('inconnu'),
      Routes.seancePour('inconnue'),
      Routes.classePour('inconnue', eleveId: 'inconnu'),
      Routes.observationsSeancePour('inconnue'),
    ],
    AppRole.teacher: <String>[
      Routes.enseignantJournee,
      Routes.enseignantRemplacements,
      Routes.enseignantClasses,
      Routes.enseignantCreneaux,
      Routes.enseignantProfil,
      Routes.enseignantRevenus,
      Routes.enseignantMessages,
      Routes.enseignantCommunaute,
      Routes.enseignantNotifications,
      Routes.compte,
      Routes.tcGroupes,
      Routes.cahierPour('inconnue'),
      Routes.groupePour('inconnu'),
      Routes.revuePour('inconnu'),
      Routes.publierAnnoncePour('inconnu'),
    ],
  };
  for (final MapEntry<AppRole, List<String>> e in parRole.entries) {
    for (final String chemin in e.value) {
      for (final (bool, double, bool) v in <(bool, double, bool)>[
        (false, 1, false),
        (true, 1, false),
        (false, 1.6, true),
        (true, 1.6, true),
        (false, 1, true),
      ]) {
        final bool ar = v.$1;
        final double echelle = v.$2;
        final bool sombre = v.$3;
        testWidgets(
          '${e.key.name} $chemin ${ar ? 'ar' : 'fr'} x$echelle ${sombre ? 'sombre' : 'clair'} 360',
          (WidgetTester tester) async {
            await tester.runAsync(
              () => LocaleSettings.setLocale(ar ? AppLocale.ar : AppLocale.fr),
            );
            addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
            await monterRouteur(
              tester,
              chemin,
              source: FausseSourceSession(sessionActive(e.key)),
              taille: const Size(360, 780),
              direction: ar ? TextDirection.rtl : null,
              echelle: echelle,
              themeMode: sombre ? ThemeMode.dark : ThemeMode.light,
              interface: e.key == AppRole.student && echelle > 1
                  ? InterfaceMode.enfant
                  : InterfaceMode.standard,
            );
            final Object? ex = tester.takeException();
            expect(ex, isNull, reason: 'exception de mise en page : $ex');
            expect(
              motsCoupes(tester, find.byType(Scaffold)),
              isEmpty,
              reason: 'un mot coupe ou tronque',
            );
            expect(_cibles(tester), isEmpty, reason: 'cible tactile sous 48');
          },
        );
      }
    }
  }

  for (final MapEntry<AppRole, List<String>> e in parRole.entries) {
    for (final String chemin in e.value) {
      testWidgets('${e.key.name} $chemin hors ligne', (
        WidgetTester tester,
      ) async {
        await monterRouteur(
          tester,
          chemin,
          source: FausseSourceSession(sessionActive(e.key)),
          taille: const Size(360, 780),
          surcharges: <Override>[
            horsLigneProvider.overrideWith(
              (Ref ref) => Stream<bool>.value(true),
            ),
          ],
        );
        expect(tester.takeException(), isNull);
        expect(
          find.byType(OfflineBanner),
          findsWidgets,
          reason: "l'etat hors ligne se dit",
        );
      });
    }
  }
}
