// RELEVE-SUIVI point 4 (08/11/2026) : la fiche d'un eleve dans la salle,
// remplie par le suivi deja branche (etape, observations du cahier, page de
// la Classe). En production, seul le niveau etait lu : chaque test ci-dessous
// est ROUGE sans ce lot.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/fiche_groupe/etape_eleve.dart';
import 'package:rewayah_academy/features/fiche_groupe/observations_eleve.dart';
import 'package:rewayah_academy/features/salle/suivi_fiche_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

const FicheEleveSeance _vide = FicheEleveSeance(
  niveau: 'Les bases',
  objectifActuel: '',
  derniereSeance: '',
  aReprendre: '',
  presenceRecente: '',
  travailActuel: '',
);

const EtapeEleve _etape = EtapeEleve(
  studentId: 'p1',
  nom: 'Lire avec les voyelles',
  objectifs: <String>['Lit le tanwin'],
);

final ObservationsEleve _obs = ObservationsEleve(
  studentId: 'p1',
  notees: DateTime(2026, 11, 6),
  aRenforcer: const <String>['Lit le tanwin', 'Lit la chadda'],
  pretBilan: false,
);

SuiviClasseSalle _suivi({
  AsyncValue<Map<String, EtapeEleve>>? etapes,
  AsyncValue<Map<String, ObservationsEleve>>? observations,
  AsyncValue<int?>? page,
}) => (
  etapes:
      etapes ??
      const AsyncData<Map<String, EtapeEleve>>(<String, EtapeEleve>{
        'p1': _etape,
      }),
  observations:
      observations ??
      AsyncData<Map<String, ObservationsEleve>>(<String, ObservationsEleve>{
        'p1': _obs,
      }),
  pageClasse: page ?? const AsyncData<int?>(24),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('la fiche dit l etape, les points a reprendre et la page', () {
    final FicheEleveSeance f = ficheAvecSuivi(
      _vide,
      profilId: 'p1',
      suivi: _suivi(),
    );
    expect(f.niveau, 'Les bases');
    expect(f.objectifActuel, 'Lire avec les voyelles');
    expect(f.aReprendre, 'Lit le tanwin, Lit la chadda');
    expect(f.derniereSeance, t.tc.classe.fiche.page(page: 24));
  });

  test('une source en panne dit « Non disponible » pour ce seul fait', () {
    final FicheEleveSeance f = ficheAvecSuivi(
      _vide,
      profilId: 'p1',
      suivi: _suivi(
        observations: AsyncError<Map<String, ObservationsEleve>>(
          StateError('42501'),
          StackTrace.empty,
        ),
      ),
    );
    expect(f.aReprendre, t.compte.nonDisponible);
    expect(f.objectifActuel, 'Lire avec les voyelles');
    expect(f.derniereSeance, t.tc.classe.fiche.page(page: 24));
  });

  test('pendant la lecture : faits vides (la carte ne les montre pas)', () {
    final FicheEleveSeance f = ficheAvecSuivi(
      _vide,
      profilId: 'p1',
      suivi: (
        etapes: const AsyncLoading<Map<String, EtapeEleve>>(),
        observations: const AsyncLoading<Map<String, ObservationsEleve>>(),
        pageClasse: const AsyncLoading<int?>(),
      ),
    );
    expect(f.objectifActuel, isEmpty);
    expect(f.aReprendre, isEmpty);
    expect(f.derniereSeance, isEmpty);
  });

  test('eleve sans donnees, ou sans profil connu : rien d invente', () {
    for (final String? profil in <String?>['p-autre', null]) {
      final FicheEleveSeance f = ficheAvecSuivi(
        _vide,
        profilId: profil,
        suivi: _suivi(page: const AsyncData<int?>(null)),
      );
      expect(f.objectifActuel, isEmpty);
      expect(f.aReprendre, isEmpty);
      expect(f.derniereSeance, isEmpty);
    }
  });

  test('un fait deja projete par le roster n est jamais remplace', () {
    const FicheEleveSeance roster = FicheEleveSeance(
      niveau: 'Les bases',
      objectifActuel: 'Objectif du roster',
      derniereSeance: 'Page 3',
      aReprendre: 'Point du roster',
      presenceRecente: '3 / 4 cours',
      travailActuel: '1 élément(s)',
    );
    final FicheEleveSeance f = ficheAvecSuivi(
      roster,
      profilId: 'p1',
      suivi: _suivi(),
    );
    expect(f.objectifActuel, 'Objectif du roster');
    expect(f.derniereSeance, 'Page 3');
    expect(f.aReprendre, 'Point du roster');
    expect(f.presenceRecente, '3 / 4 cours');
  });

  test('la vraie salle complete les fiches par le suivi de sa Classe', () {
    final String salle = File('lib/features/salle/salle_page.dart')
        .readAsStringSync();
    expect(salle, contains('_suiviClasse(ref),'));
    expect(salle, contains('etapes: ref.watch(etapesElevesClasseProvider('));
    expect(
      salle,
      contains('observations: ref.watch(observationsClasseProvider('),
    );
    expect(salle, contains('pageClasse: ref.watch(pageRepriseClasseProvider('));
  });
}
