import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, alors que `ProviderContainer.overrides` en attend une liste.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/learning_assignment.dart';
import 'package:rewayah_academy/core/tc_parcours/port_travail_a_venir.dart';
import 'package:rewayah_academy/core/tc_parcours/source_contenu_seance.dart';

import 'faux/faux_ports_externes.dart';

const String _groupe = 'g1';
const String _coran = 'res-coran';

LearningAssignment _travail({
  required String id,
  IntentionPedagogique intention = IntentionPedagogique.aRevoir,
  ContentRange? plage,
  String? studentId,
  String? consigne,
}) => LearningAssignment(
  id: id,
  groupId: _groupe,
  studentId: studentId,
  resourceId: _coran,
  contentRange: plage,
  purpose: intention,
  instructions: consigne,
  startsAtUtc: DateTime.utc(2026, 9, 20),
  createdBy: 'ens-1',
  status: StatutAssignation.aFaire,
);

ContentRange _versets({
  int sourate = 2,
  int premier = 255,
  int dernier = 257,
}) => ContentRange(
  resourceId: _coran,
  debut: ContentPosition.ayah(
    resourceId: _coran,
    sourate: sourate,
    ayah: premier,
  ),
  fin: ContentPosition.ayah(
    resourceId: _coran,
    sourate: sourate,
    ayah: dernier,
  ),
);

void main() {
  group('avant le prochain cours', () {
    test('aucune tache : aucune action, et aucune invention', () async {
      final TravailAVenir travail = TravailAVenir(
        FauxAssignations(),
        const ContenuSeanceIndisponible(),
      );

      expect(await travail.avantProchainCours(groupeId: _groupe), isEmpty);
    });

    test('une a trois taches se rendent telles quelles', () async {
      for (int nombre = 1; nombre <= 3; nombre++) {
        final TravailAVenir travail = TravailAVenir(
          FauxAssignations(
            travaux: <LearningAssignment>[
              for (int i = 0; i < nombre; i++) _travail(id: 't$i'),
            ],
          ),
          const ContenuSeanceIndisponible(),
        );

        final List<SlotAction> actions = await travail.avantProchainCours(
          groupeId: _groupe,
        );
        expect(actions, hasLength(nombre));
      }
    });

    test('au dela de trois, le plafond tient', () async {
      final FauxAssignations assignations = FauxAssignations(
        travaux: <LearningAssignment>[
          for (int i = 0; i < 7; i++) _travail(id: 't$i'),
        ],
      );
      final TravailAVenir travail = TravailAVenir(
        assignations,
        const ContenuSeanceIndisponible(),
      );

      final List<SlotAction> actions = await travail.avantProchainCours(
        groupeId: _groupe,
      );

      expect(actions, hasLength(plafondActionsAvantCours));
      expect(
        assignations.derniereLimite,
        plafondActionsAvantCours,
        reason: 'le plafond est demande au port, pas tronque a l ecran',
      );
    });

    test('une tache portant un range Coran se lit en clair', () async {
      final TravailAVenir travail = TravailAVenir(
        FauxAssignations(
          travaux: <LearningAssignment>[
            _travail(
              id: 't1',
              intention: IntentionPedagogique.aRenforcer,
              plage: _versets(),
            ),
          ],
        ),
        const ContenuSeanceIndisponible(),
      );

      final List<SlotAction> actions = await travail.avantProchainCours(
        groupeId: _groupe,
      );

      expect(actions.single.libelle, contains('Sourate 2'));
      expect(actions.single.libelle, contains('255'));
      expect(actions.single.libelle, contains('257'));
      expect(actions.single.intention, IntentionPedagogique.aRenforcer);
    });

    test('une consigne courte remplace la plage', () async {
      final TravailAVenir travail = TravailAVenir(
        FauxAssignations(
          travaux: <LearningAssignment>[
            _travail(id: 't1', plage: _versets(), consigne: 'Revoir le tajwid'),
          ],
        ),
        const ContenuSeanceIndisponible(),
      );

      final List<SlotAction> actions = await travail.avantProchainCours(
        groupeId: _groupe,
      );

      expect(actions.single.libelle, contains('Revoir le tajwid'));
      expect(actions.single.libelle, isNot(contains('Sourate')));
    });

    test('le travail nominatif d un autre eleve ne s affiche pas', () async {
      final TravailAVenir travail = TravailAVenir(
        FauxAssignations(
          travaux: <LearningAssignment>[
            _travail(id: 'groupe'),
            _travail(id: 'autre', studentId: 'eleve-2'),
          ],
        ),
        const ContenuSeanceIndisponible(),
      );

      final List<SlotAction> actions = await travail.avantProchainCours(
        groupeId: _groupe,
        studentId: 'eleve-1',
      );

      expect(actions.map((SlotAction a) => a.id), <String>['groupe']);
    });
  });

  group('non branche n est pas vide', () {
    test('le provider canonique rend null, et ne leve pas', () {
      final ProviderContainer conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);

      // Il levait, autrefois, pour ne pas laisser croire a un groupe sans
      // travail. La crainte est honoree par le type : `null` dit « non
      // branche », et l'Espace Groupe d'Agent A l'affiche au lieu de planter.
      expect(conteneur.read(portTravailAVenirProvider), isNull);
    });

    test('sans port branche, le travail a venir vaut null, pas []', () async {
      final ProviderContainer conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);

      final List<SlotAction>? actions = await conteneur.read(
        travailAVenirProvider((groupeId: _groupe, studentId: null)).future,
      );

      expect(
        actions,
        isNull,
        reason: 'une liste vide affirmerait qu il n y a rien a preparer',
      );
    });

    test('port branche et sans travail : une liste vide, pas null', () async {
      final ProviderContainer conteneur = ProviderContainer(
        overrides: <Override>[
          portTravailAVenirProvider.overrideWithValue(
            TravailAVenir(
              FauxAssignations(),
              const ContenuSeanceIndisponible(),
            ),
          ),
        ],
      );
      addTearDown(conteneur.dispose);

      final List<SlotAction>? actions = await conteneur.read(
        travailAVenirProvider((groupeId: _groupe, studentId: null)).future,
      );

      expect(actions, isEmpty);
    });
  });

  group('reprendre le cours : contextuelle, jamais permanente', () {
    test('sans position connue, aucune action de reprise', () async {
      final TravailAVenir travail = TravailAVenir(
        FauxAssignations(travaux: <LearningAssignment>[_travail(id: 't1')]),
        const ContenuSeanceIndisponible(),
      );

      final List<SlotAction> actions = await travail.avantProchainCours(
        groupeId: _groupe,
      );

      expect(
        actions.any((SlotAction a) => a.id == 'tc.parcours.reprendre'),
        isFalse,
      );
    });

    test('avec une position, l action apparait en tete et se lit', () async {
      final TravailAVenir travail = TravailAVenir(
        FauxAssignations(travaux: <LearningAssignment>[_travail(id: 't1')]),
        FauxContenuSeance(
          reprisesDeGroupe: <String, ContentPosition>{
            _groupe: const ContentPosition.ayah(
              resourceId: _coran,
              sourate: 2,
              ayah: 255,
            ),
          },
        ),
      );

      final List<SlotAction> actions = await travail.avantProchainCours(
        groupeId: _groupe,
      );

      expect(actions.first.id, 'tc.parcours.reprendre');
      expect(actions.first.libelle, contains('Sourate 2'));
      expect(actions.first.libelle, contains('255'));
      expect(
        actions.first.intention,
        isNull,
        reason: 'reprendre n est pas une sixieme intention pedagogique',
      );
    });

    test(
      'la reprise prend une place, elle ne repousse pas le plafond',
      () async {
        final TravailAVenir travail = TravailAVenir(
          FauxAssignations(
            travaux: <LearningAssignment>[
              for (int i = 0; i < 3; i++) _travail(id: 't$i'),
            ],
          ),
          FauxContenuSeance(
            reprisesDeGroupe: <String, ContentPosition>{
              _groupe: const ContentPosition.page(resourceId: _coran, page: 12),
            },
          ),
        );

        final List<SlotAction> actions = await travail.avantProchainCours(
          groupeId: _groupe,
        );

        expect(actions, hasLength(plafondActionsAvantCours));
        expect(actions.first.id, 'tc.parcours.reprendre');
      },
    );
  });
}
