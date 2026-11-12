// HEURE-PROFIL, partie salle (12/11/2026). Dans la salle, une heure se dit a
// l'heure du PROFIL de la personne, jamais a celle de l'appareil ; sans
// fuseau lu, l'heure de l'appareil, dite comme telle. Le texte se forme au
// dessin, a partir d'un instant reel.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/dates_appareil.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_salle.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';

import '../../support/harnais.dart';

MonHorloge _horloge(String fuseau, int decalageSecondes) =>
    MonHorloge.lire(<String, Object?>{
      'maintenant': '2026-11-12T05:00:00Z',
      'moi': <String, Object?>{
        'fuseau': fuseau,
        'decalage_secondes': decalageSecondes,
      },
    });

/// Une personne en Arabie saoudite (UTC+3).
final MonHorloge _riyad = _horloge('Asia/Riyadh', 10800);

/// Une personne en Guinee (UTC+0).
final MonHorloge _conakry = _horloge('Africa/Conakry', 0);

/// La fin d'une seance : 14:30 en temps universel.
final DateTime _fin = DateTime.utc(2026, 11, 12, 14, 30);

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    poserMonHorlogePourTest(null);
  });
  tearDown(() => poserMonHorlogePourTest(null));

  test('la meme fin de seance : 17:30 a Riyad, 14:30 a Conakry', () {
    poserMonHorlogePourTest(_riyad);
    expect(DepuisSalle.heure(_fin), '17:30');
    expect(DepuisSalle.heureDite(_fin), '17:30');
    poserMonHorlogePourTest(_conakry);
    expect(DepuisSalle.heure(_fin), '14:30');
    expect(DepuisSalle.heureDite(_fin), '14:30');
  });

  test('profil sans fuseau : l heure de l appareil, dite comme telle', () {
    final String appareil = heureDeLAppareil(_fin.toLocal());
    expect(DepuisSalle.heure(_fin), appareil);
    expect(DepuisSalle.heureDite(_fin), contains(appareil));
    expect(
      DepuisSalle.heureDite(_fin),
      contains(t.tuteur.accueil.heureAppareil),
    );
    expect(
      DepuisSalle.phraseDite('La salle ouvrira.', _fin),
      'La salle ouvrira. ${t.snt.planning.heureAppareil}',
    );
  });

  test('avec le fuseau du profil : aucune mention', () {
    poserMonHorlogePourTest(_riyad);
    expect(
      DepuisSalle.phraseDite('La salle ouvrira.', _fin),
      'La salle ouvrira.',
    );
  });

  testWidgets('l ecran de fin de l eleve dit l heure du profil, formee au '
      'dessin : elle suit le fuseau', (WidgetTester tester) async {
    Widget ecran() => hote(
      ResultatSeance(issue: IssueSeance.terminee, finA: _fin, onRetour: () {}),
    );
    await tester.pumpWidget(ecran());
    expect(
      find.textContaining(t.snt.planning.heureAppareil),
      findsOneWidget,
      reason: 'sans fuseau : la mention',
    );
    poserMonHorlogePourTest(_riyad);
    await tester.pumpWidget(hote(const SizedBox.shrink()));
    await tester.pumpWidget(ecran());
    expect(find.text(t.salle.fin.phraseHeure(heure: '17:30')), findsOneWidget);
    expect(find.textContaining(t.snt.planning.heureAppareil), findsNothing);
  });

  test('garde de source : dans les trois dossiers de la salle, aucune heure '
      'd appareil nue (ni toLocal(), ni .hour, ni .minute)', () {
    final RegExp nue = RegExp(r'\.toLocal\(\)|\.hour\b|\.minute\b');
    final List<String> fautes = <String>[];
    for (final String dossier in <String>[
      'lib/features/salle',
      'lib/features/salle_seance',
      'lib/features/salle_enseignant',
    ]) {
      for (final FileSystemEntity f in Directory(
        dossier,
      ).listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final List<String> lignes = f.readAsLinesSync();
        for (int i = 0; i < lignes.length; i++) {
          final String l = lignes[i];
          if (l.trimLeft().startsWith('//')) continue;
          if (nue.hasMatch(l)) fautes.add('${f.path}:${i + 1} $l');
        }
      }
    }
    expect(
      fautes,
      isEmpty,
      reason:
          'une heure de la salle passe par DepuisSalle.heure ou heureChezMoi '
          '(heure du profil), jamais par l heure de l appareil',
    );
  });
}
