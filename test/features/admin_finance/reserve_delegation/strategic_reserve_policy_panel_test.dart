// CPT-DIR-1 : `StrategicReservePolicyPanel` (spec §9.2 a §9.6, §37 ; R-FIN-08,
// R-FIN-09).
//
// - modes d'objectif (montant fixe, couverture en mois), cinq regles
//   d'alimentation, cadences, seuil, retrait soumis a validation ;
// - 10 USD et 1 000 000 USD s'enregistrent pareil (aucune plage codee) ;
// - saisie illisible : rien n'est envoye, l'erreur dit quoi corriger ;
// - echec : la phrase reste, la cle d'idempotence est reprise a l'identique ;
// - 320 px texte x2, RTL, sombre : aucune exception de mise en page.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_politique_reserve.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/features/admin_finance/reserve_delegation/strategic_reserve_policy_panel.dart';
import 'package:rewayah_academy/features/demo/comptable/direction_demo.dart';

import 'support_direction.dart';

final c = t.comptable.direction;

typedef _Appel = ({BrouillonPolitiqueReserve brouillon, String cle});

class _Hote {
  _Hote(this.politique, {this.echec});

  final PolitiqueReserve politique;
  Object? echec;
  final List<_Appel> appels = <_Appel>[];

  Widget panneau() => StrategicReservePolicyPanel(
    politique: politique,
    onEnregistrer: (BrouillonPolitiqueReserve b, String cle) async {
      appels.add((brouillon: b, cle: cle));
      final Object? e = echec;
      if (e != null) throw e;
    },
  );
}

Finder _champ(String libelle) => find.descendant(
  of: find.byWidgetPredicate(
    (Widget w) => w is Semantics && w.properties.label == libelle,
  ),
  matching: find.byType(TextField),
);

Future<void> _taper(WidgetTester tester, String libelle, String texte) async {
  await tester.ensureVisible(_champ(libelle));
  await tester.enterText(_champ(libelle), texte);
  await tester.pump();
}

Future<void> _choisir(WidgetTester tester, String libelle) async {
  final Finder f = find.text(libelle);
  await tester.ensureVisible(f.first);
  await tester.tap(f.first);
  await tester.pump();
}

Finder get _enregistrer =>
    find.byKey(StrategicReservePolicyPanel.enregistrerKey);

Future<void> _appuyer(WidgetTester tester) async {
  final Finder bouton = find.descendant(
    of: _enregistrer,
    matching: find.text(c.enregistrer),
  );
  await tester.ensureVisible(bouton);
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}

void main() {
  final r = c.reservePanneau;
  final PolitiqueReserve fixe = PolitiqueReserveDemo.cibleFixe;
  final PolitiqueReserve mois = PolitiqueReserveDemo.couvertureMois;

  testWidgets('cible fixe : la politique en vigueur est reprise, rien a '
      'enregistrer tant que rien ne change', (WidgetTester tester) async {
    taille(tester, const Size(900, 3000));
    final _Hote h = _Hote(fixe);
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();

    expect(
      find.text(c.versionDepuis(version: '2', date: '15 septembre 2026')),
      findsOneWidget,
    );
    expect(find.text(c.auteur(auteur: 'La direction')), findsOneWidget);
    expect(
      tester.widget<TextField>(_champ(r.montantCible)).controller!.text,
      '5000',
    );
    expect(
      tester.widget<TextField>(_champ(r.montantAuto)).controller!.text,
      '1000',
    );
    expect(tester.widget<TextField>(_champ(r.seuil)).controller!.text, '80');
    expect(find.text(r.nombreMois), findsNothing);
    expect(find.text(c.aucuneModification), findsOneWidget);
    expect(h.appels, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('couverture en mois : le champ des mois remplace le montant, '
      'jamais « 3 mois » en titre', (WidgetTester tester) async {
    taille(tester, const Size(900, 3000));
    final _Hote h = _Hote(mois);
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(_champ(r.nombreMois)).controller!.text,
      '3',
    );
    expect(find.text(r.montantCible), findsNothing);
    // Regle « jusqu'a l'objectif » : ni montant ni pourcentage a saisir.
    expect(find.text(r.montantAuto), findsNothing);
    expect(find.text(r.pourcentageAuto), findsNothing);
    expect(find.textContaining('3 mois'), findsNothing);
  });

  testWidgets('R-FIN-08, 09 : 10 USD et 1 000 000 USD s enregistrent pareil, '
      'aucune plage codee', (WidgetTester tester) async {
    taille(tester, const Size(900, 3000));
    for (final (String saisie, int mineur) cas in <(String, int)>[
      ('10', 1000),
      ('1000000', 100000000),
      ('1 000 000', 100000000),
    ]) {
      final _Hote h = _Hote(fixe);
      await tester.pumpWidget(hoteDirection(h.panneau()));
      await tester.pumpAndSettle();
      await _taper(tester, r.montantCible, cas.$1);
      await _appuyer(tester);
      expect(h.appels, hasLength(1), reason: cas.$1);
      expect(
        h.appels.single.brouillon.montantCible,
        Montant(cas.$2, 'USD'),
        reason: cas.$1,
      );
      expect(find.text(c.enregistree), findsOneWidget);
    }
  });

  testWidgets('cinq regles d alimentation : seul le champ utile apparait, '
      'et le brouillon ne porte que lui', (WidgetTester tester) async {
    taille(tester, const Size(900, 4000));
    final _Hote h = _Hote(fixe);
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();

    for (final String libelle in <String>[
      r.regle.desactivee,
      r.regle.montantFixe,
      r.regle.pourcentage,
      r.regle.jusquAObjectif,
      r.regle.proposee,
    ]) {
      expect(find.text(libelle), findsOneWidget, reason: libelle);
    }

    await _choisir(tester, r.regle.pourcentage);
    expect(find.text(r.pourcentageAuto), findsOneWidget);
    expect(find.text(r.montantAuto), findsNothing);
    await _taper(tester, r.pourcentageAuto, '12,5');
    await _appuyer(tester);
    BrouillonPolitiqueReserve b = h.appels.last.brouillon;
    expect(b.regleAlimentation, RegleAlimentation.pourcentage);
    expect(b.pourcentageAutoPourMille, 125);
    expect(b.montantAuto, isNull);

    await _choisir(tester, r.regle.desactivee);
    expect(find.text(r.cadenceTitre), findsNothing);
    expect(find.text(r.montantAuto), findsNothing);
    expect(find.text(r.pourcentageAuto), findsNothing);
    await _appuyer(tester);
    b = h.appels.last.brouillon;
    expect(b.regleAlimentation, RegleAlimentation.desactivee);
    expect(b.montantAuto, isNull);
    expect(b.pourcentageAutoPourMille, isNull);

    await _choisir(tester, r.regle.proposee);
    expect(find.text(r.cadenceTitre), findsOneWidget);
    await _choisir(tester, r.cadence.hebdomadaire);
    await _appuyer(tester);
    b = h.appels.last.brouillon;
    expect(b.regleAlimentation, RegleAlimentation.proposee);
    expect(b.cadence, CadenceAlimentation.hebdomadaire);
  });

  testWidgets('les cinq cadences du §9.4 sont proposees', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(900, 4000));
    final _Hote h = _Hote(fixe);
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();
    for (final String libelle in <String>[
      r.cadence.clotureCycle,
      r.cadence.hebdomadaire,
      r.cadence.mensuelle,
      r.cadence.apresEncaissementConsolide,
      r.cadence.manuelle,
    ]) {
      expect(find.text(libelle), findsOneWidget, reason: libelle);
    }
    expect(find.byType(ChoiceCardGroup), findsNWidgets(2));
  });

  testWidgets('passer au mode couverture en mois, retirer le seuil et la '
      'validation du retrait', (WidgetTester tester) async {
    taille(tester, const Size(900, 4000));
    final _Hote h = _Hote(fixe);
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();

    await _choisir(tester, r.modeMois);
    expect(find.text(r.nombreMois), findsOneWidget);
    expect(find.text(r.montantCible), findsNothing);
    await _taper(tester, r.nombreMois, '6');
    await _taper(tester, r.seuil, '');
    final Finder interrupteur = find.byType(Switch);
    await tester.ensureVisible(interrupteur);
    await tester.tap(interrupteur);
    await tester.pump();
    await _appuyer(tester);

    final BrouillonPolitiqueReserve b = h.appels.single.brouillon;
    expect(b.modeObjectif, ModeObjectifReserve.couvertureMois);
    expect(b.nombreMois, 6);
    expect(b.montantCible, isNull);
    expect(b.seuilAlertePourMille, isNull);
    expect(b.retraitSoumisValidation, isFalse);
  });

  testWidgets('saisie illisible : rien n est envoye, chaque champ dit quoi '
      'corriger', (WidgetTester tester) async {
    taille(tester, const Size(900, 4000));
    final _Hote h = _Hote(fixe);
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();

    await _taper(tester, r.montantCible, '0');
    await _taper(tester, r.montantAuto, 'abc');
    await _taper(tester, r.seuil, '150');
    expect(
      find.text(c.erreurMontant),
      findsNothing,
      reason: 'pas avant le geste',
    );
    await _appuyer(tester);

    expect(h.appels, isEmpty);
    expect(find.text(c.erreurMontant), findsNWidgets(2));
    expect(find.text(c.erreurPourcentage), findsOneWidget);
    expect(find.text(c.corrigezChamps), findsOneWidget);
  });

  testWidgets('echec : la phrase reste, la meme cle d idempotence est '
      'reprise, puis une modification en change', (WidgetTester tester) async {
    taille(tester, const Size(900, 4000));
    final _Hote h = _Hote(fixe, echec: StateError('coupure'));
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();

    await _taper(tester, r.montantCible, '7000');
    await _appuyer(tester);
    expect(find.text(c.erreurEnregistrement), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(
      find.text(c.erreurEnregistrement),
      findsOneWidget,
      reason: 'un echec ne disparait pas seul',
    );

    await _appuyer(tester);
    expect(h.appels, hasLength(2));
    expect(h.appels[1].cle, h.appels[0].cle);

    await _taper(tester, r.montantCible, '7500');
    await _appuyer(tester);
    expect(h.appels[2].cle, isNot(h.appels[0].cle));
  });

  testWidgets('capacite absente : « pas encore disponible », sans affirmer '
      'que rien n est parti', (WidgetTester tester) async {
    taille(tester, const Size(900, 4000));
    final _Hote h = _Hote(fixe, echec: const CapaciteIndisponible('CPT-BR-12'));
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();
    await _taper(tester, r.montantCible, '7000');
    await _appuyer(tester);
    expect(find.text(c.enregistrementIndisponible), findsOneWidget);
  });

  testWidgets('le titre reste « Réserve stratégique », aucune phrase de '
      'sanction ni mot interne', (WidgetTester tester) async {
    taille(tester, const Size(900, 4000));
    final _Hote h = _Hote(mois);
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();
    final RegExp interdit = RegExp(
      r'\badmin\b|sanction|p[ée]nalit|insuffisant',
      caseSensitive: false,
    );
    for (final String texte in textes(tester)) {
      expect(interdit.hasMatch(texte), isFalse, reason: texte);
    }
  });

  for (final (String, double, TextDirection, Brightness) cas
      in <(String, double, TextDirection, Brightness)>[
        ('320 px, texte x2', 2, TextDirection.ltr, Brightness.light),
        ('RTL', 1, TextDirection.rtl, Brightness.light),
        ('sombre', 1, TextDirection.ltr, Brightness.dark),
      ]) {
    testWidgets('mise en page : ${cas.$1}, sans debordement', (
      WidgetTester tester,
    ) async {
      taille(
        tester,
        cas.$1 == '320 px, texte x2'
            ? const Size(320, 900)
            : const Size(390, 900),
      );
      final _Hote h = _Hote(fixe);
      await tester.pumpWidget(
        hoteDirection(
          h.panneau(),
          echelle: cas.$2,
          sens: cas.$3,
          luminosite: cas.$4,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(r.montantCible), findsOneWidget);
    });
  }
}
