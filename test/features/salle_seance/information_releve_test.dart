// Lot RESEAU-PREUVE (11/11/2026) : la phrase d'information du releve de
// qualite de connexion, lue dans « En savoir plus » du bandeau de la salle, a
// la suite des textes E-1 et E-2 et sous son propre titre. Mot pour mot le
// texte de `docs/current/TEXTES-VALIDES/INFORMATION-RELEVE-QUALITE.md`, et
// les memes faits dans la politique de confidentialite de l'application.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/salle_seance/information_controle.dart';
import 'package:rewayah_academy/features/salle_seance/mention_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

VueSeance _vue(RoleSeance role, {bool? tutoiement}) => VueSeance(
  role: role,
  nomClasse: 'Classe',
  nomEnseignant: 'Sayyid Ibrahim',
  initialesEnseignant: 'SI',
  enregistrementConfirme: true,
  tutoiement: tutoiement,
);

Future<void> _ouvrir(
  WidgetTester tester,
  VueSeance vue, {
  Size taille = const Size(390, 844),
  double echelleTexte = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(
        body: Center(child: MentionSeance(vue: vue)),
      ),
      echelleTexte: echelleTexte,
    ),
  );
  await stabiliser(tester);
  // Sous 388 de large, pas de lien : la mention elle-meme ouvre la lecture.
  final Finder lien = find.text(t.salle.informationControle.lien);
  await tester.tap(lien.evaluate().isEmpty ? find.byType(MentionSeance) : lien);
  await stabiliser(tester);
}

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('180 jours, la direction seule, ni son ni image, rien pour un eleve '
      'mineur : le texte dit ce que le serveur fait', () {
    final Traductions$salle$releve$fr r = t.salle.releve;
    expect(r.adulte, contains('bonnes, faibles ou perdues'));
    expect(r.adulte, contains('ni le son ni l\'image'));
    expect(r.adulte, contains('Pour un élève mineur, elle ne garde rien'));
    expect(r.adulte, contains('vous opposer à ce relevé'));
    expect(r.mineur, contains('Sur ta connexion à toi, elle ne garde rien'));
    expect(r.guidee, contains('ni ta voix ni ton image'));
    expect(r.guidee, contains('elle ne garde rien sur ta connexion'));
    for (final String texte in <String>[r.adulte, r.mineur]) {
      expect(texte, contains('gardé 180 jours, puis effacé'));
      expect(texte, contains('Seule la direction peut le lire'));
      expect(texte, isNot(contains('deux ans')));
    }
  });

  test('la politique de confidentialite dit les memes faits, avec la base '
      'legale et le droit de s opposer', () {
    final List<String> blocs = t.juridique.confidentialite.s5.blocs;
    final String tout = blocs.join(' ');
    expect(tout, contains('Le relevé de connexion'));
    expect(tout, contains('Pour un élève mineur, elle ne garde rien'));
    expect(tout, contains('intérêt légitime'));
    expect(tout, contains('Seule la direction peut le lire'));
    expect(tout, contains('gardé 180 jours, puis effacé'));
    expect(tout, contains('aucune décision automatique'));
    // Le droit de s'opposer est dit a part (RGPD, art. 21(4)).
    expect(blocs.last, startsWith('Vous pouvez vous opposer à ce relevé'));
  });

  test('les cles sont, mot pour mot, les textes du registre des textes '
      'valides, en francais et en arabe', () async {
    final String registre = File(
      'docs/current/TEXTES-VALIDES/INFORMATION-RELEVE-QUALITE.md',
    ).readAsStringSync();
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      await LocaleSettings.setLocale(langue);
      final Traductions$salle$releve$fr r = t.salle.releve;
      for (final String texte in <String>[
        r.titre,
        r.titreGuidee,
        r.adulte,
        r.mineur,
        r.guidee,
      ]) {
        expect(registre, contains(texte), reason: '${langue.name} : $texte');
      }
    }
  });

  testWidgets('eleve adulte : sous E-2, le titre et la version des adultes', (
    WidgetTester tester,
  ) async {
    await _ouvrir(tester, _vue(RoleSeance.eleve, tutoiement: false));
    final Traductions$salle$releve$fr r = t.salle.releve;
    // E-2 est toujours la, sans un mot de change.
    expect(find.text(t.salle.informationControle.e2.p1), findsOneWidget);
    expect(find.text(r.titre), findsOneWidget);
    expect(find.text(r.adulte), findsOneWidget);
    expect(find.text(r.mineur), findsNothing);
    // Le titre du releve vient apres le texte E-2.
    expect(
      tester.getTopLeft(find.text(r.titre)).dy,
      greaterThan(
        tester.getTopLeft(find.text(t.salle.informationControle.e2.p3)).dy,
      ),
    );
  });

  testWidgets('eleve mineur hors Interface guidee : la version tutoyee, qui '
      'dit que rien n est garde pour lui', (WidgetTester tester) async {
    await _ouvrir(tester, _vue(RoleSeance.eleve, tutoiement: true));
    final Traductions$salle$releve$fr r = t.salle.releve;
    expect(find.text(r.mineur), findsOneWidget);
    expect(find.text(r.adulte), findsNothing);
  });

  testWidgets('Interface guidee : sous E-1, le titre et la phrase de '
      'l enfant', (WidgetTester tester) async {
    await _ouvrir(tester, _vue(RoleSeance.guidee));
    final Traductions$salle$releve$fr r = t.salle.releve;
    expect(find.text(t.salle.informationControle.e1.p1), findsOneWidget);
    expect(find.text(r.titreGuidee), findsOneWidget);
    expect(find.text(r.guidee), findsOneWidget);
    expect(find.text(r.adulte), findsNothing);
  });

  test('l enseignant n a pas cette lecture sur son bandeau : il lit la '
      'politique de confidentialite', () {
    expect(
      const TexteInformationControle(role: RoleSeance.enseignant).releve,
      isNull,
    );
    expect(InformationControle.texteDisponible(RoleSeance.enseignant), isFalse);
  });

  for (final (Size taille, double echelle) in <(Size, double)>[
    (const Size(320, 690), 2),
    (const Size(1440, 900), 1),
  ]) {
    testWidgets('${taille.width.toInt()} en texte x$echelle : la lecture '
        'defile jusqu au bout de la phrase, sans debordement', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        _vue(RoleSeance.eleve, tutoiement: false),
        taille: taille,
        echelleTexte: echelle,
      );
      expect(tester.takeException(), isNull);
      final Finder phrase = find.text(t.salle.releve.adulte);
      await tester.scrollUntilVisible(
        phrase,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -10000));
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
      final Rect cadre = tester.getRect(phrase);
      expect(cadre.bottom, lessThanOrEqualTo(taille.height));
      expect(cadre.left, greaterThanOrEqualTo(0));
      expect(cadre.right, lessThanOrEqualTo(taille.width));
    });
  }

  testWidgets('arabe : le titre et la phrase, de droite a gauche', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    await _ouvrir(tester, _vue(RoleSeance.guidee));
    expect(find.text(t.salle.releve.titreGuidee), findsOneWidget);
    expect(find.text(t.salle.releve.guidee), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
