// Captures avant / apres de la pastille d'etat de seance (ON-AIR-1,
// ANNUL-VIS-1) a 320 px et a 1440 px, clair et sombre.
//
// « Avant » rend ce que les ecrans posaient a la main : une `StatusPill` avec
// le mot et un disque de statut, et la carte annulee sur `washAlert`.
// « Apres » rend le composant partage, au milieu d'un battement.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Mode
// d'emploi : `test/capture/LISEZ-MOI.md`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/pastille_etat_seance.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

import 'outil_capture.dart';

Widget _carteAvant(BuildContext context) {
  final AppPalette palette = AppPalette.of(context);
  final TextTheme textes = Theme.of(context).textTheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: StatusPill(libelle: t.etat.enDirect, ton: TonEtat.succes),
      ),
      Ecart.vLg,
      AppCard(
        surface: palette.washAlert,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StatusPill(libelle: t.etat.annule, ton: TonEtat.alerte),
            Ecart.vSm,
            Text(
              '10:00 - 11:00',
              style: palette.washAlert.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
            Text(
              t.tuteur.accueil.seanceAnnulee,
              style: palette.washAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _carteApres(BuildContext context) {
  final AppPalette palette = AppPalette.of(context);
  final TextTheme textes = Theme.of(context).textTheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const Align(
        alignment: AlignmentDirectional.centerStart,
        child: PastilleEtatSeance(etat: EtatPastilleSeance.enDirect),
      ),
      Ecart.vLg,
      AppCard(
        surface: surfaceCarteSeance(palette, annulee: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const PastilleEtatSeance(etat: EtatPastilleSeance.annulee),
            Ecart.vSm,
            TexteHeureSeance(
              heure: '10:00 - 11:00',
              annulee: true,
              style: textes.titleMedium,
            ),
            Ecart.vXs,
            LigneRaisonSeance(raison: t.tuteur.accueil.seanceAnnulee),
          ],
        ),
      ),
    ],
  );
}

Widget _ecran(Widget Function(BuildContext) carte) => Scaffold(
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Builder(builder: carte),
    ),
  ),
);

void main() {
  group('Capture : pastille d\'etat de seance', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ({String nom, Size taille, double densite}) vue
        in <({String nom, Size taille, double densite})>[
          (nom: '320', taille: const Size(320, 420), densite: 2),
          (nom: '1440', taille: const Size(1440, 420), densite: 1),
        ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final ({String nom, Widget Function(BuildContext) f}) etat
            in <({String nom, Widget Function(BuildContext) f})>[
              (nom: 'avant', f: _carteAvant),
              (nom: 'apres', f: _carteApres),
            ]) {
          testWidgets('${etat.nom}, ${vue.nom} px, ${mode.name}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, vue.taille, vue.densite);
            await tester.pumpWidget(
              hoteCapture(_ecran(etat.f), themeMode: mode),
            );
            // Une seconde : le point est au milieu de son premier battement.
            await stabiliser(tester);
            await capturer(
              tester,
              'l1-pastilles_${etat.nom}_${vue.nom}_${mode.name}',
            );
          });
        }
      }
    }
  });
}
