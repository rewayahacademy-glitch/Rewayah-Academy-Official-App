// Selection du texte (directeur, 07/11/2026) : tout le texte se copie ; la
// salle, les codes, les coordonnees de versement, les pieces d'identite et
// les coordonnees d'autrui ne se copient jamais.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/ligne_destination_masquee.dart';
import 'package:rewayah_academy/core/widgets/texte_protege.dart';
import 'package:rewayah_academy/features/admin_dossiers/revue_dossier.dart';
import 'package:rewayah_academy/features/appareils/emetteur_qr.dart';

import '../../support/demo/dossiers_demo.dart';
import '../../support/demo/mode_demonstration.dart';
import '../../support/hote_selection.dart';

const String _ordinaire = 'Le cours de tajwid commence a dix-huit heures';

void main() {
  testWidgets('un texte ordinaire se selectionne et se copie', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hoteSelection(const Text(_ordinaire)));
    expect(await toutCopier(tester), contains(_ordinaire));
  });

  testWidgets('l\'appui long ouvre le menu Copier', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hoteSelection(const Text(_ordinaire)));
    await tester.pump();
    await tester.longPress(find.text(_ordinaire));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Copier'), findsOneWidget);
  });

  testWidgets('TexteProtege : rien n\'est selectionne', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteSelection(
        const Column(
          children: <Widget>[
            Text(_ordinaire),
            TexteProtege(child: Text('SECRET-1234')),
          ],
        ),
      ),
    );
    final String copie = await toutCopier(tester);
    expect(copie, contains(_ordinaire));
    expect(copie, isNot(contains('SECRET-1234')));
  });

  testWidgets('un code d\'appairage ne se selectionne pas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteSelection(
        const Column(
          children: <Widget>[
            Text(_ordinaire),
            CodeEnClair(code: 'K7QX2M'),
          ],
        ),
      ),
    );
    expect(find.textContaining('K 7 Q X 2 M'), findsOneWidget);
    final String copie = await toutCopier(tester);
    expect(copie, contains(_ordinaire));
    expect(copie, isNot(contains('K 7 Q X 2 M')));
    expect(copie, isNot(contains('K7QX2M')));
  });

  testWidgets('un IBAN masque ne se selectionne pas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteSelection(
        const Column(
          children: <Widget>[
            Text(_ordinaire),
            LigneDestinationMasquee(
              destination: DestinationMasquee(
                type: 'Compte bancaire',
                suffixe: '9087',
                pays: 'France',
                devise: 'EUR',
                verification: EtatProfilPaiement.verifie,
              ),
            ),
          ],
        ),
      ),
    );
    expect(find.textContaining('9087'), findsOneWidget);
    final String copie = await toutCopier(tester);
    expect(copie, contains(_ordinaire));
    expect(copie, isNot(contains('9087')));
  });

  testWidgets('la valeur et la legende d\'une rubrique protegee ne se '
      'selectionnent pas, son libelle si', (WidgetTester tester) async {
    await tester.pumpWidget(
      hoteSelection(
        const GroupeReglages(
          titre: 'Titre ordinaire',
          lignes: <LigneRubrique>[
            LigneRubrique(
              libelle: 'Libelle ordinaire',
              valeur: 'VALEUR-SECRETE',
              legende: 'LEGENDE-SECRETE',
              protegee: true,
            ),
          ],
        ),
      ),
    );
    final String copie = await toutCopier(tester);
    expect(copie, contains('Libelle ordinaire'));
    expect(copie, isNot(contains('VALEUR-SECRETE')));
    expect(copie, isNot(contains('LEGENDE-SECRETE')));
  });

  testWidgets('une piece d\'identite (nom lu, piece) ne se selectionne pas', (
    WidgetTester tester,
  ) async {
    final RevueDossiersDemo port = RevueDossiersDemo(EtatRevueDemo.initial());
    final PageDossiers page = await port.listerDossiers();
    final DossierPourRevue dossier = await port.dossierPourRevue(
      page.elements.first.dossierId,
    );
    await tester.pumpWidget(
      hoteSelection(
        Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) =>
              RevueDossier(
                dossier: dossier,
                onDecision: (String _) {},
                onActualiser: () {},
              ),
        ),
        surcharges: surchargesDemoAdmin(environnement: 'staging'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    // Le nom et le prenom lus sur la piece sont affiches par la carte
    // d'identite, en plus du titre de la page (qui reste copiable).
    expect(find.text(dossier.nom), findsOneWidget);
    expect(find.text(dossier.prenom), findsOneWidget);
    final String copie = await toutCopier(tester);
    expect(copie, isNotEmpty);
    expect(dossier.nom.allMatches(copie).length, 1, reason: copie);
    expect(dossier.prenom.allMatches(copie).length, 1, reason: copie);
  });

  testWidgets('un appui long sur un secret ne copie jamais le secret', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteSelection(
        const Column(
          children: <Widget>[
            Text(_ordinaire),
            TexteProtege(child: Text('SECRET-1234', key: ValueKey('secret'))),
          ],
        ),
      ),
    );
    await tester.pump();
    String copie = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall appel) async {
        if (appel.method == 'Clipboard.setData') {
          copie = (appel.arguments as Map<Object?, Object?>)['text']! as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.longPress(find.byKey(const ValueKey<String>('secret')));
    await tester.pump(const Duration(milliseconds: 300));
    if (find.text('Copier').evaluate().isNotEmpty) {
      await tester.tap(find.text('Copier'));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(copie, isNot(contains('SECRET-1234')));
  });
}
