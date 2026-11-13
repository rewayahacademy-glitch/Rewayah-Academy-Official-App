// HORLOGE-ET-LIEU (12/11/2026, H1 et H2) : l'heure de l'academie est celle de La
// Mecque ; chacun lit son heure d'abord, « Heure de La Mecque » en second.
// Un cours a 21 h a La Mecque s'affiche 23 h 30 a Delhi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/fuseaux_interlocuteurs.dart';
import 'package:rewayah_academy/core/tc_horloge/heure_double.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/tc_horloge/port_interlocuteurs.dart';

import '../../support/harnais.dart';

const Map<String, Object?> _paris = <String, Object?>{
  'fuseau': 'Europe/Paris',
  'decalage_secondes': 3600,
  'prochain_changement': '2027-03-28T01:00:00Z',
  'decalage_apres': 7200,
  'changement_suivant': '2027-10-31T01:00:00Z',
};
const Map<String, Object?> _delhi = <String, Object?>{
  'fuseau': 'Asia/Kolkata',
  'decalage_secondes': 19800,
  'prochain_changement': null,
};
const Map<String, Object?> _riyad = <String, Object?>{
  'fuseau': 'Asia/Riyadh',
  'decalage_secondes': 10800,
  'prochain_changement': null,
};
const Map<String, Object?> _abidjan = <String, Object?>{
  'fuseau': 'Africa/Abidjan',
  'decalage_secondes': 0,
  'prochain_changement': null,
};

// Mercredi 18/11/2026, 18:00 UTC : 19 h a Paris, 21 h a La Mecque, 23 h 30 a Delhi.
final DateTime _seance = DateTime.utc(2026, 11, 18, 18);

MonHorloge _poser(
  Map<String, Object?> moi, {
  Map<String, Object?>? academie = _riyad,
}) {
  final MonHorloge lecture = MonHorloge.lire(<String, Object?>{
    'maintenant': '2026-11-12T22:00:00Z',
    'moi': moi,
    'academie': ?academie,
  });
  poserMonHorlogePourTest(lecture);
  return lecture;
}

InterlocuteursClasse _lus({
  required Map<String, Object?> moi,
  Map<String, Object?>? enseignant,
  bool classe = false,
}) => InterlocuteursClasse.lire(<String, Object?>{
  'maintenant': '2026-11-12T22:00:00Z',
  'moi': moi,
  'enseignant': ?(enseignant == null
      ? null
      : <String, Object?>{
          'titre': 'sayyid',
          'prenom': 'Karim',
          'pays': 'CI',
          'remplacant': false,
          ...enseignant,
          'source': classe ? 'classe' : 'enseignant',
        }),
});

class _Port implements PortInterlocuteurs {
  const _Port(this.lus);
  final InterlocuteursClasse lus;

  @override
  Future<InterlocuteursClasse?> lire(String groupeId) async => lus;
}

void main() {
  tearDown(() => poserMonHorlogePourTest(null));

  test('mon_horloge lit l horloge de l academie, ou rien', () {
    final MonHorloge avec = MonHorloge.lire(<String, Object?>{
      'maintenant': '2026-11-12T22:00:00Z',
      'moi': _paris,
      'academie': _riyad,
    });
    expect(avec.academie?.fuseau, 'Asia/Riyadh');
    expect(avec.academie?.decalage, const Duration(hours: 3));
    expect(avec.academie?.prochainChangement, isNull);
    final MonHorloge sans = MonHorloge.lire(<String, Object?>{
      'maintenant': '2026-11-12T22:00:00Z',
      'moi': _paris,
    });
    expect(sans.academie, isNull);
  });

  test('un cours a 21 h a La Mecque : 19 h a Paris, 23 h 30 a Delhi', () {
    _poser(_paris);
    expect(heureChezMoi(_seance), '19:00');
    expect(heureMecqueSiDifferente(_seance), '21:00');
    _poser(_delhi);
    expect(heureChezMoi(_seance), '23:30');
    expect(heureMecqueSiDifferente(_seance), '21:00');
  });

  test('a La Mecque meme, aucune seconde heure', () {
    _poser(_riyad);
    expect(heureChezMoi(_seance), '21:00');
    expect(heureMecqueSiDifferente(_seance), isNull);
  });

  test('l ete a Paris, 20 h chez soi et toujours 21 h a La Mecque', () {
    _poser(_paris);
    final DateTime ete = DateTime.utc(2027, 4, 7, 18);
    expect(heureChezMoi(ete), '20:00');
    expect(heureMecqueSiDifferente(ete), '21:00');
  });

  test('sans horloge de l academie lue, pas de seconde heure', () {
    _poser(_paris, academie: null);
    expect(heureMecqueSiDifferente(_seance), isNull);
    final List<LigneHeure> lignes = lignesInterlocuteurs(
      _lus(moi: _paris, enseignant: _abidjan),
      _seance,
    );
    expect(lignes.where((LigneHeure l) => l.fuseau == 'Asia/Riyadh'), isEmpty);
  });

  test('famille a Paris, enseignant a Abidjan : sa ligne puis La Mecque', () {
    _poser(_paris);
    final List<LigneHeure> lignes = lignesInterlocuteurs(
      _lus(moi: _paris, enseignant: _abidjan),
      _seance,
    );
    expect(lignes.length, 2);
    expect(lignes[0].heure, '18:00');
    expect(lignes[0].libelle, 'Chez Sayyid Karim');
    expect(lignes[1].libelle, t.tc.groupe.horloges.heureMecque);
    expect(lignes[1].heure, '21:00');
    expect(lignes[1].ville, isEmpty);
  });

  test('l heure de la classe a l academie se dit « Heure de La Mecque », '
      'sans doublon', () {
    _poser(_paris);
    final List<LigneHeure> lignes = lignesInterlocuteurs(
      _lus(moi: _paris, enseignant: <String, Object?>{..._riyad}, classe: true),
      _seance,
    );
    expect(lignes.length, 1);
    expect(lignes.single.libelle, t.tc.groupe.horloges.heureMecque);
    expect(lignes.single.heure, '21:00');
  });

  test('une classe pas encore convertie garde « Heure de la classe »', () {
    _poser(_delhi);
    final List<LigneHeure> lignes = lignesInterlocuteurs(
      _lus(moi: _delhi, enseignant: <String, Object?>{..._paris}, classe: true),
      _seance,
    );
    // La classe est encore a Paris : sa ligne ne se dit pas « La Mecque », et
    // La Mecque vient en plus, en second.
    expect(lignes.first.libelle, t.tc.groupe.horloges.heureGroupe);
    expect(lignes.first.heure, '19:00');
    expect(lignes.last.libelle, t.tc.groupe.horloges.heureMecque);
    expect(lignes.last.heure, '21:00');
  });

  for (final double largeur in <double>[320, 390, 1440]) {
    for (final double echelle in <double>[1, 2]) {
      testWidgets('$largeur px, texte x$echelle : heure chez soi puis '
          'Heure de La Mecque, sans debordement', (tester) async {
        final MonHorloge lecture = _poser(_paris);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(largeur, 1200);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hote(
            MediaQuery(
              data: MediaQueryData(
                size: Size(largeur, 1200),
                textScaler: TextScaler.linear(echelle),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: HeureDouble(groupeId: 'g1', instantUtc: _seance),
                ),
              ),
            ),
            surcharges: <Override>[
              // Hors Supabase, la vraie lecture rendrait null et viderait la
              // lecture posee (TEST-HORLOGE-SURCHARGE, registre des lots).
              monHorlogeProvider.overrideWith((Ref ref) async => lecture),
              portInterlocuteursProvider.overrideWithValue(
                _Port(_lus(moi: _paris, enseignant: _abidjan)),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.text(t.tc.groupe.horloges.chezVous), findsOneWidget);
        expect(find.textContaining('19:00'), findsOneWidget);
        expect(find.text(t.tc.groupe.horloges.heureMecque), findsOneWidget);
        expect(find.text('21:00'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
