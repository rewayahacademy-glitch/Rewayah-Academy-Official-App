// NAV-REFONTE 2c (schema accepte par le garde-cap le 11/11/2026) : l'entree
// de la carte de seance d'une Classe se calcule une fois
// (`entreeGroupeProvider`) ; les ecrans de `LecteurGroupe` et le halo vert de
// l'eleve adulte la lisent ; `CarteSession` la recoit, sans repli.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/core/widgets/halo_compte.dart';
import 'package:rewayah_academy/features/acces_finance/acces_finance.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/notifications/halo_salle.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/emplacements_groupe.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/entree_groupe.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';

import '../support/demo/classe_demo.dart';
import '../support/harnais.dart';

const String _id = DonneesClasseDemo.groupeId;

/// Ni periode financee ni essai restant : seances fermees (FIN4-13).
const AccesBeneficiaire _ferme = AccesBeneficiaire(
  eleveId: 'e1',
  prenom: 'Élève',
  etatAffiche: EtatAccesAffiche.sansEcheance,
  seancesPayantesOuvertes: false,
  essaisUtilises: 2,
  essaisMax: 2,
);

const CleEntreeGroupe _cle = (
  groupeId: _id,
  role: RoleEspaceGroupe.eleve,
  tutoiement: false,
  seanceParServeur: true,
);

List<Override> _surcharges(EtatDemoClasse etat, {bool ferme = false}) {
  final GroupSummaryVM groupe = DonneesClasseDemo.groupe(etat);
  return <Override>[
    groupeProvider(_id).overrideWith((Ref _) async => groupe),
    horlogeGroupeProvider(_id).overrideWith(
      (Ref _) => Stream<SessionClockVM>.value(DonneesClasseDemo.horloge(etat)),
    ),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
    seanceAnnuleeProvider(_id).overrideWithValue(false),
    accesAppelantProvider.overrideWithValue(
      ferme
          ? const AsyncData<AccesBeneficiaire?>(_ferme)
          : const AsyncData<AccesBeneficiaire?>(null),
    ),
    accueilAdulteProvider.overrideWith(
      (Ref _) async => const AccueilAdulteVM(prenom: 'Élève', groupeId: _id),
    ),
  ];
}

Future<ProviderContainer> _conteneur(
  EtatDemoClasse etat, {
  bool ferme = false,
}) async {
  final ProviderContainer c = ProviderContainer(
    overrides: _surcharges(etat, ferme: ferme),
  );
  addTearDown(c.dispose);
  final ProviderSubscription<EntreeCarte?> abonnement = c.listen(
    entreeGroupeProvider(_cle),
    (_, _) {},
  );
  addTearDown(abonnement.close);
  await c.read(groupeProvider(_id).future);
  await c.read(horlogeGroupeProvider(_id).future);
  return c;
}

void main() {
  group('entreeGroupeProvider : la seule source', () {
    test('fenetre ouverte, acces ouvert : « Rejoindre » est offert', () async {
      final ProviderContainer c = await _conteneur(
        EtatDemoClasse.fenetreOuverte,
      );
      final EntreeCarte? e = c.read(entreeGroupeProvider(_cle));
      expect(e?.emplacement?.estBouton, isTrue);
      expect(e?.rejoignable, isTrue);
    });

    test('seances fermees : le bouton est retire, rien a rejoindre', () async {
      final ProviderContainer c = await _conteneur(
        EtatDemoClasse.fenetreOuverte,
        ferme: true,
      );
      final EntreeCarte? e = c.read(entreeGroupeProvider(_cle));
      expect(e?.retiree, isTrue);
      expect(e?.rejoignable, isFalse);
    });

    test('avant l ouverture : une ligne d etat, rien a rejoindre', () async {
      final ProviderContainer c = await _conteneur(EtatDemoClasse.aVenir);
      final EntreeCarte? e = c.read(entreeGroupeProvider(_cle));
      expect(e?.emplacement?.estBouton, isFalse);
      expect(e?.rejoignable, isFalse);
    });
  });

  group('LecteurGroupe et le halo lisent la meme entree', () {
    testWidgets('la lecture de l ecran porte l entree du provider', (
      WidgetTester tester,
    ) async {
      LectureGroupe? lue;
      late ProviderContainer conteneur;
      await tester.pumpWidget(
        hote(
          Consumer(
            builder: (BuildContext contexte, WidgetRef _, Widget? _) {
              conteneur = ProviderScope.containerOf(contexte);
              return LecteurGroupe(
                groupeId: _id,
                seanceParServeur: true,
                construire: (BuildContext _, LectureGroupe l) {
                  lue = l;
                  return const SizedBox();
                },
              );
            },
          ),
          surcharges: _surcharges(EtatDemoClasse.fenetreOuverte),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(lue?.entree, isNotNull);
      expect(
        identical(lue?.entree, conteneur.read(entreeGroupeProvider(_cle))),
        isTrue,
      );
    });

    testWidgets('eleve adulte : halo vert quand la carte offre « Rejoindre »', (
      WidgetTester tester,
    ) async {
      EtatHaloCompte? vu;
      await tester.pumpWidget(
        hote(
          HaloVivant(
            source: SourceSalle.adulte,
            notifications: null,
            construire: (BuildContext _, EtatHaloCompte? h) {
              vu = h;
              return const SizedBox();
            },
          ),
          surcharges: _surcharges(EtatDemoClasse.fenetreOuverte),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(vu?.nature, NatureHalo.salle);
    });

    testWidgets('eleve adulte, seances fermees : aucun halo vert', (
      WidgetTester tester,
    ) async {
      EtatHaloCompte? vu;
      await tester.pumpWidget(
        hote(
          HaloVivant(
            source: SourceSalle.adulte,
            notifications: null,
            construire: (BuildContext _, EtatHaloCompte? h) {
              vu = h;
              return const SizedBox();
            },
          ),
          surcharges: _surcharges(EtatDemoClasse.fenetreOuverte, ferme: true),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(vu, isNull);
    });
  });

  test('les cinq ecrans reels fournissent l emplacement, aucun repli', () {
    // Tout montage de CarteSession dans lib/, hors sa definition.
    final Map<String, String> sources = <String, String>{
      for (final File f
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((File f) => f.path.endsWith('.dart')))
        f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
    };
    final Set<String> montages = <String>{
      for (final MapEntry<String, String> e in sources.entries)
        if (RegExp(r'(?<![\w.])CarteSession\(').hasMatch(e.value) &&
            !e.key.endsWith('tc_espace_groupe/carte_session.dart'))
          e.key,
    };
    expect(montages, <String>{
      // Les trois ecrans de LecteurGroupe, par LectureGroupe.carte.
      'lib/features/tc_espace_groupe/espace_groupe_page.dart',
      // Calculent par la meme fonction pure, avec leurs entrees (dette).
      'lib/features/accueil_eleve/accueil_accessibilite.dart',
      'lib/features/fiche_groupe/fiche_groupe_page.dart',
    });
    expect(
      sources['lib/features/tc_espace_groupe/espace_groupe_page.dart'],
      contains('emplacement: entree?.emplacement'),
    );
    for (final String f in <String>[
      'lib/features/accueil_eleve/accueil_accessibilite.dart',
      'lib/features/fiche_groupe/fiche_groupe_page.dart',
    ]) {
      expect(
        sources[f],
        contains('emplacement: CarteSession.emplacementPour('),
        reason: f,
      );
    }
    // Espace de la Classe, Ma classe adulte, Accueil adulte : par
    // LecteurGroupe, donc par entreeGroupeProvider.
    for (final String f in <String>[
      'lib/features/tc_espace_groupe/espace_groupe_page.dart',
      'lib/features/ma_classe_adulte/ma_classe_adulte_page.dart',
      'lib/features/accueil_adulte/accueil_adulte_page.dart',
    ]) {
      expect(sources[f], contains('LecteurGroupe('), reason: f);
      expect(sources[f], contains('identiteEtCarte('), reason: f);
    }
  });
}
