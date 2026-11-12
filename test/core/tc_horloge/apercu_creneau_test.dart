// HORLOGE-ET-LIEU (12/11/2026, H1 et H3) : l'apercu d'un creneau choisi a
// l'heure d'un enseignant : l'heure de La Mecque ou il sera enregistre, et
// l'heure chez l'enseignant avant et apres son prochain changement d'heure.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/apercu_creneau.dart';

import '../../support/harnais.dart';

class _Port implements PortApercuCreneau {
  _Port(this._reponses);

  /// Les reponses dans l'ordre : le creneau enregistre, puis chez l'enseignant.
  final List<Map<String, Object?>?> _reponses;
  final List<Map<String, Object?>> appels = <Map<String, Object?>>[];

  @override
  Future<ApercuCreneau?> lire({
    required String fuseau,
    required int jour,
    required int heure,
    String? fuseauCreneau,
  }) async {
    appels.add(<String, Object?>{
      'fuseau': fuseau,
      'jour': jour,
      'heure': heure,
      'fuseauCreneau': fuseauCreneau,
    });
    return ApercuCreneau.lire(_reponses[appels.length - 1]);
  }
}

const Map<String, Object?> _enregistre = <String, Object?>{
  'maintenant': '21:00',
  'jour_maintenant': 3,
  'meme': true,
};
const Map<String, Object?> _chezParis = <String, Object?>{
  'maintenant': '19:00',
  'jour_maintenant': 3,
  'meme': false,
  'date_changement': '2027-03-28',
  'jour_apres': 3,
  'heure_apres': '20:00',
};

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  test('lire : une reponse illisible n est pas un apercu', () {
    expect(ApercuCreneau.lire(null), isNull);
    expect(ApercuCreneau.lire(<String, Object?>{'maintenant': '19:00'}), isNull);
    expect(
      ApercuCreneau.lire(<String, Object?>{
        'maintenant': '19:00',
        'jour_maintenant': 9,
        'meme': true,
      }),
      isNull,
    );
    final ApercuCreneau? ok = ApercuCreneau.lire(_chezParis);
    expect(ok?.heureApres, '20:00');
    expect(ok?.dateChangement, DateTime(2027, 3, 28));
  });

  test('la phrase : La Mecque, puis l enseignant avant et apres', () {
    final ResumeCreneauEnseignant r = ResumeCreneauEnseignant(
      jourAcademie: 3,
      heureAcademie: '21:00',
      chezEnseignant: ApercuCreneau.lire(_chezParis)!,
    );
    expect(
      phraseResumeCreneau(r, 'Europe/Paris'),
      'Enregistrée à l\'heure de La Mecque : mercredi 21:00. '
      'Chez l\'enseignant (Paris) : 19:00, puis 20:00 à partir du '
      'dimanche 28 mars 2027.',
    );
  });

  test('un enseignant sans changement d heure : toute l annee', () {
    final ResumeCreneauEnseignant r = ResumeCreneauEnseignant(
      jourAcademie: 3,
      heureAcademie: '21:00',
      chezEnseignant: ApercuCreneau.lire(<String, Object?>{
        'maintenant': '23:30',
        'jour_maintenant': 3,
        'meme': true,
      })!,
    );
    final String phrase = phraseResumeCreneau(r, 'Asia/Kolkata');
    expect(phrase, contains('mercredi 21:00'));
    expect(phrase, contains('23:30 toute l\'année'));
  });

  test('les deux lectures : le creneau a Riyad, puis revu chez l enseignant',
      () async {
    final _Port port = _Port(<Map<String, Object?>?>[_enregistre, _chezParis]);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        portApercuCreneauProvider.overrideWithValue(port),
      ],
    );
    addTearDown(container.dispose);
    final ResumeCreneauEnseignant? r = await container.read(
      resumeCreneauEnseignantProvider((
        fuseauEnseignant: 'Europe/Paris',
        jour: 3,
        heure: 19,
      )).future,
    );
    expect(r?.heureAcademie, '21:00');
    expect(port.appels.length, 2);
    // Premiere lecture : l'heure de l'enseignant (mercredi 19 h) vue a La
    // Mecque ; seconde : le creneau de La Mecque (mercredi 21 h) vu chez lui.
    expect(port.appels[0], <String, Object?>{
      'fuseau': fuseauAcademieDefaut,
      'jour': 3,
      'heure': 19,
      'fuseauCreneau': 'Europe/Paris',
    });
    expect(port.appels[1], <String, Object?>{
      'fuseau': 'Europe/Paris',
      'jour': 3,
      'heure': 21,
      'fuseauCreneau': null,
    });
  });

  for (final double largeur in <double>[320, 1440]) {
    for (final double echelle in <double>[1, 2]) {
      testWidgets('$largeur px, texte x$echelle : la ligne d apercu', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(largeur, 1200);
        addTearDown(tester.view.reset);
        final _Port port = _Port(<Map<String, Object?>?>[
          _enregistre,
          _chezParis,
        ]);
        await tester.pumpWidget(
          hote(
            MediaQuery(
              data: MediaQueryData(
                size: Size(largeur, 1200),
                textScaler: TextScaler.linear(echelle),
              ),
              child: const Scaffold(
                body: SingleChildScrollView(
                  child: LigneApercuClasse(
                    fuseauEnseignant: 'Europe/Paris',
                    jour: 3,
                    heure: 19,
                  ),
                ),
              ),
            ),
            surcharges: <Override>[
              portApercuCreneauProvider.overrideWithValue(port),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.byKey(LigneApercuClasse.cle), findsOneWidget);
        expect(find.textContaining('mercredi 21:00'), findsOneWidget);
        expect(find.textContaining('puis 20:00'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('sans reponse du serveur, ou a La Mecque meme : aucune ligne', (
    tester,
  ) async {
    await tester.pumpWidget(
      hote(
        const Scaffold(
          body: Column(
            children: <Widget>[
              LigneApercuClasse(
                fuseauEnseignant: 'Europe/Paris',
                jour: 3,
                heure: 19,
              ),
              LigneApercuClasse(
                fuseauEnseignant: 'Asia/Riyadh',
                jour: 3,
                heure: 21,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(LigneApercuClasse.cle), findsNothing);
  });
}
