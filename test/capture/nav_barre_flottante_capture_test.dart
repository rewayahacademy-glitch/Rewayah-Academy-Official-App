// Captures du lot NAV-REFONTE, etape 1 (decisions du directeur du 09/11/2026) :
// la barre flottante du telephone, pilule et cercle Compte, pour chaque role
// NavShell ; 320 et 1440 (la colonne laterale ne change qu'a l'etape 3),
// texte x1 et x2, clair et sombre, arabe, Mode Accessibilite.
//
// Scene composee avec le VRAI NavShell et les vraies destinations
// (`destinationsPour`) ; le contenu de page est un gabarit vide. Saute sans
// CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart' show sansPersonneConnectee;
import 'outil_capture.dart';

typedef _Cas = ({
  String nom,
  AppRole role,
  bool adulte,
  int actif,
  Size vue,
  double texte,
  ThemeMode theme,
  AppLocale langue,
  InterfaceMode mode,
});

const Size _tel = Size(320, 700);
const Size _bureau = Size(1440, 900);

final List<_Cas> _cas = <_Cas>[
  for (final (String n, AppRole r, bool a, int i)
      in <(String, AppRole, bool, int)>[
        ('tuteur', AppRole.guardian, false, 1),
        ('eleve', AppRole.student, false, 2),
        ('eleve-adulte', AppRole.student, true, 0),
        ('enseignant', AppRole.teacher, false, 2),
        ('enseignant-compte-ouvert', AppRole.teacher, false, 3),
      ])
    (
      nom: '${n}_320_x1_clair',
      role: r,
      adulte: a,
      actif: i,
      vue: _tel,
      texte: 1,
      theme: ThemeMode.light,
      langue: AppLocale.fr,
      mode: InterfaceMode.standard,
    ),
  for (final (
        String suffixe,
        double texte,
        ThemeMode theme,
        AppLocale langue,
        InterfaceMode mode,
      )
      in <(String, double, ThemeMode, AppLocale, InterfaceMode)>[
        (
          '320_x2_clair',
          2,
          ThemeMode.light,
          AppLocale.fr,
          InterfaceMode.standard,
        ),
        (
          '320_x1_sombre',
          1,
          ThemeMode.dark,
          AppLocale.fr,
          InterfaceMode.standard,
        ),
        (
          '320_x2_sombre',
          2,
          ThemeMode.dark,
          AppLocale.fr,
          InterfaceMode.standard,
        ),
        (
          '320_x1_arabe',
          1,
          ThemeMode.light,
          AppLocale.ar,
          InterfaceMode.standard,
        ),
        (
          '320_x1_accessibilite',
          1,
          ThemeMode.light,
          AppLocale.fr,
          InterfaceMode.enfant,
        ),
        (
          '320_x2_accessibilite',
          2,
          ThemeMode.light,
          AppLocale.fr,
          InterfaceMode.enfant,
        ),
        (
          '320_x1_accessibilite_arabe',
          1,
          ThemeMode.dark,
          AppLocale.ar,
          InterfaceMode.enfant,
        ),
      ])
    (
      nom: 'tuteur_$suffixe',
      role: AppRole.guardian,
      adulte: false,
      actif: 1,
      vue: _tel,
      texte: texte,
      theme: theme,
      langue: langue,
      mode: mode,
    ),
  for (final (String suffixe, ThemeMode theme, double texte)
      in <(String, ThemeMode, double)>[
        ('1440_x1_clair', ThemeMode.light, 1),
        ('1440_x2_sombre', ThemeMode.dark, 2),
      ])
    (
      nom: 'enseignant_$suffixe',
      role: AppRole.teacher,
      adulte: false,
      actif: 2,
      vue: _bureau,
      texte: texte,
      theme: theme,
      langue: AppLocale.fr,
      mode: InterfaceMode.standard,
    ),
];

void main() {
  group(
    'Capture : barre flottante et cercle Compte',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      for (final _Cas c in _cas) {
        testWidgets(c.nom, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(c.langue));
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, c.vue, 1);
          final List<Destination> destinations = destinationsPour(
            role: c.role,
            mode: c.mode,
            eleveAdulte: c.adulte,
          );
          await tester.pumpWidget(
            hoteCapture(
              NavShell(
                destinations: destinations,
                indexActif: c.actif,
                onAller: (_) {},
                child: PageShell(
                  titre: destinations[c.actif].libelle,
                  child: const SizedBox(height: 200),
                ),
              ),
              surcharges: <Override>[sansPersonneConnectee()],
              themeMode: c.theme,
              echelleTexte: c.texte,
              interfaceMode: c.mode,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, 'nav-barre_${c.nom}')}');
        });
      }
    },
  );
}
