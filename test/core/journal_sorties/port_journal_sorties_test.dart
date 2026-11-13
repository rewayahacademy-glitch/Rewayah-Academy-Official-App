// HORS-SALLE-2 (directeur, 12/11/2026 au soir) : la logique du journal des
// sorties de l'application, sans ecran.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/journal_sorties/journal_sorties_demonstration.dart';
import 'package:rewayah_academy/core/journal_sorties/journal_sorties_supabase.dart';
import 'package:rewayah_academy/core/journal_sorties/libelles_sorties.dart';
import 'package:rewayah_academy/core/journal_sorties/port_journal_sorties.dart';
import 'package:rewayah_academy/core/tc_classe/garde_hors_application.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/faux_journal_sorties.dart';

void main() {
  group('reglages publics (regles_academie)', () {
    test('le delai et le journal sont lus quand le serveur les rend', () {
      final ReglagesSorties? r = ReglagesSorties.depuisRegles(<String, Object?>{
        'capacite_enfant': 5,
        'sorties_delai_secondes': 45,
        'sorties_journal_actif': true,
      });
      expect(r?.delai, const Duration(seconds: 45));
      expect(r?.journalActif, isTrue);
    });

    test('serveur d avant le lot ou compte hors parcours : rien', () {
      expect(
        ReglagesSorties.depuisRegles(<String, Object?>{'capacite_enfant': 5}),
        isNull,
      );
      expect(ReglagesSorties.depuisRegles(null), isNull);
    });

    test('le delai de la garde vient du reglage, la constante sinon', () async {
      final ProviderContainer avec = ProviderContainer(
        overrides: <Override>[
          portJournalSortiesProvider.overrideWithValue(
            FauxJournalSorties(
              reglagesRendus: const ReglagesSorties(
                journalActif: false,
                delai: Duration(seconds: 75),
              ),
            ),
          ),
        ],
      );
      addTearDown(avec.dispose);
      expect(
        avec.read(delaiHorsApplicationProvider),
        AppDelais.horsApplicationEleve,
      );
      await avec.read(reglagesSortiesProvider.future);
      expect(
        avec.read(delaiHorsApplicationProvider),
        const Duration(seconds: 75),
      );

      final ProviderContainer sans = ProviderContainer(
        overrides: <Override>[
          portJournalSortiesProvider.overrideWithValue(FauxJournalSorties()),
        ],
      );
      addTearDown(sans.dispose);
      await sans.read(reglagesSortiesProvider.future);
      expect(
        sans.read(delaiHorsApplicationProvider),
        AppDelais.horsApplicationEleve,
      );
    });
  });

  group('etat des accords', () {
    AccordSortiesEleve eleve(String id, {bool autonome = false}) =>
        AccordSortiesEleve(
          eleveId: id,
          prenom: id,
          autonome: autonome,
          enCours: false,
        );

    test('proposee seulement journal allume, texte connu, une decision', () {
      expect(
        EtatAccordsSorties(
          journalActif: false,
          versionCourante: 'v1',
          eleves: <AccordSortiesEleve>[eleve('a')],
        ).propose,
        isFalse,
      );
      expect(
        const EtatAccordsSorties(
          journalActif: true,
          versionCourante: 'v1',
          eleves: <AccordSortiesEleve>[],
        ).propose,
        isFalse,
      );
      expect(
        EtatAccordsSorties(
          journalActif: true,
          versionCourante: 'v1',
          eleves: <AccordSortiesEleve>[eleve('a')],
        ).propose,
        isTrue,
      );
    });

    test('l eleve adulte decide pour lui-meme', () {
      final EtatAccordsSorties e = EtatAccordsSorties.depuisJson(
        const <String, dynamic>{
          'journalActif': true,
          'versionCourante': 'sorties-2026-11-v1',
          'eleves': <Object?>[
            <String, dynamic>{
              'eleveId': 'moi',
              'prenom': 'Karim',
              'autonome': true,
              'enCours': true,
              'accepteLe': '2026-11-13T09:00:00Z',
            },
          ],
        },
      );
      expect(e.eleves.single.autonome, isTrue);
      expect(e.eleves.single.accepteLe, DateTime.utc(2026, 11, 13, 9));
    });
  });

  group('resume et mises en mots', () {
    test('trois sorties, 4 min 15 au total, par eleve', () {
      final Map<String, ResumeSorties> r = ResumeSorties.parEleve(<SortieApp>[
        ...troisSorties('e1'),
        ...troisSorties('e2').take(1),
      ]);
      expect(r['e1']?.nombre, 3);
      expect(r['e1']?.totalSecondes, 255);
      expect(r['e2']?.nombre, 1);
    });

    test('« 3 sorties, 4 min 15 s », durees exactes et insecables', () {
      LocaleSettings.setLocaleSync(AppLocale.fr);
      final String ligne = LibellesSorties.resume(
        const ResumeSorties(nombre: 3, totalSecondes: 255),
      );
      expect(ligne, '3\u00a0sorties, 4\u00a0min\u00a015\u00a0s');
      expect(LibellesSorties.duree(120), '2\u00a0min');
      expect(LibellesSorties.duree(90), '1\u00a0min\u00a030\u00a0s');
      expect(LibellesSorties.duree(45), '45 s');
      expect(LibellesSorties.nombre(1), '1 sortie');
    });
  });

  group('serveur ancien ou absent : tout se replie sans erreur visible', () {
    JournalSortiesSupabase adaptateur(Exception erreur) =>
        JournalSortiesSupabase(() => throw erreur);

    test('noter rend faux, lire rend vide, reglages rend null', () async {
      final JournalSortiesSupabase a = adaptateur(
        const PostgrestException(message: 'absente', code: 'PGRST202'),
      );
      expect(
        await a.noterSortie(seanceId: 's1', secondes: 40, sortieSalle: true),
        isFalse,
      );
      expect(await a.sortiesSeance('s1'), isEmpty);
      expect(await a.reglages(), isNull);
      expect(await a.accords(), isNull);
    });

    test('un compte que le serveur refuse : pas de page', () async {
      expect(
        await adaptateur(
          const PostgrestException(message: 'refus', code: '42501'),
        ).accords(),
        isNull,
      );
    });

    test('une panne de reseau remonte a la page de l accord', () async {
      expect(
        adaptateur(Exception('reseau')).accords(),
        throwsA(isA<Exception>()),
      );
    });
  });

  test('la demonstration suit la regle : rien sans accord', () async {
    final JournalSortiesDemonstration d = JournalSortiesDemonstration();
    expect(
      await d.noterSortie(seanceId: 's', secondes: 30, sortieSalle: false),
      isFalse,
    );
    await d.accepter(eleveId: 'demo-eleve-1', version: 'sorties-2026-11-v1');
    expect(
      await d.noterSortie(seanceId: 's', secondes: 30, sortieSalle: false),
      isTrue,
    );
    await d.retirer('demo-eleve-1');
    expect(
      await d.noterSortie(seanceId: 's', secondes: 30, sortieSalle: false),
      isFalse,
    );
    expect(await d.sortiesSeance('s'), hasLength(1));
  });
}
