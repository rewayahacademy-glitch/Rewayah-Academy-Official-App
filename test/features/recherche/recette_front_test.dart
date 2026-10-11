// RECH-REC : recette front de la recherche, sur le double de demonstration
// (spec RECH-03 §10, §14, §16 ; REC-01 a REC-14, SEC-R05, R11, R21).
//
// Ce fichier ne remplace pas les tests de chaque domaine : il rejoue, sur
// TOUS les moteurs raccordables (D1 a D4 et le socle de demonstration), des
// saisies adversariales, la reprise apres une panne, l'absence de toute
// reponse hors du corpus, et il mesure le temps de reponse du double. Il
// n'affirme rien de serveur : RLS, index, plans et charge restent a prouver
// sur staging par Codex (K-68).

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Provider, ProviderContainer;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_encaissements.dart';
import 'package:rewayah_academy/core/recherche/budgets_recherche.dart';
import 'package:rewayah_academy/core/recherche/modeles_recherche.dart';
import 'package:rewayah_academy/core/recherche/moteurs_demo_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_classe/port_roster_enseignant.dart';
import 'package:rewayah_academy/core/tc_classe/roster_enseignant.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_groupe/demonstration_groupes.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';
import 'package:rewayah_academy/features/demo/comptable/encaissements_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/recherche/domaines/classes_supports/moteurs_classes_supports.dart';
import 'package:rewayah_academy/features/recherche/domaines/enseignants_pedagogie_controle/moteurs_enseignants_pedagogie_controle.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/moteurs_familles_eleves.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/port_resolution_ra.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/resolution_ra_demo.dart';
import 'package:rewayah_academy/features/recherche/domaines/finance_communications/moteurs_finance_communications.dart';

final DateTime _maintenant = DateTime(2026, 10, 11, 18);

/// Les saisies adversariales de REC-11 / SEC-R11 / SEC-R21.
final List<String> _hostiles = <String>[
  '<script>alert(1)</script>',
  '<b>Aicha</b>',
  "'; DROP TABLE eleves; --",
  '" OR 1=1 --',
  '%',
  '_',
  r'\\',
  '.*',
  '(a+)+\$',
  '\u0000\u0000',
  'RA-AB0012; select *',
  'RA-%%%%',
  '${String.fromCharCode(0x202E)}evil',
  'a' * 5000,
  List<String>.filled(40, 'mot').join(' '),
  '${'😀' * 200}fatiha',
  'الفاتحة ﷽',
  'Al-Fātiḥa 1:1',
];

ProviderContainer _conteneur() {
  final ProviderContainer c = ProviderContainer(
    // Les ports de demonstration de chaque module, jamais ceux de production.
    overrides: [
      portGroupesProvider.overrideWithValue(GroupesDemonstrationLocale()),
      portCatalogueProvider.overrideWithValue(CatalogueLocal()),
      portRosterEnseignantProvider.overrideWithValue(_RosterVide()),
      missionControleProvider.overrideWith((ref) async => null),
      portAccesFoyerProvider.overrideWithValue(const AccesFoyerDemo()),
      portClassesFoyerProvider.overrideWithValue(const ClassesFoyerDemo()),
      portResolutionRaProvider.overrideWithValue(
        const ResolutionRaDemo(<String, ElevePourRa>{
          'RA-AB0012': ElevePourRa(
            eleveId: DonneesDemo.aichaId,
            prenom: 'Aïcha',
          ),
        }),
      ),
      portEncaissementsProvider.overrideWithValue(EncaissementsDemo()),
      portMessagesMetierProvider.overrideWithValue(
        MessagesMetierDemo(
          role: RoleDemoCommunications.tuteur,
          maintenant: _maintenant,
        ),
      ),
      portStudioProvider.overrideWithValue(StudioDemo(maintenant: _maintenant)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

final _tous = Provider<List<MoteurRechercheDomaine>>(
  (ref) => <MoteurRechercheDomaine>[
    ...moteursClassesSupports(ref),
    ...moteursEnseignantsPedagogieControle(ref),
    ...moteursFamillesEleves(ref),
    ...moteursFinanceCommunications(ref),
  ],
);

void main() {
  group('REC-11 : saisies adversariales, tous les moteurs raccordables', () {
    for (final EspaceRecherche espace in EspaceRecherche.values) {
      test('${espace.name} : erreur controlee, rien d\'invente', () async {
        final ProviderContainer c = _conteneur();
        final PortRecherche port = PortRechercheParMoteurs(c.read(_tous));
        final ContexteRecherche contexte = ContexteRecherche(espace: espace);
        final List<DomaineRecherche> servis = await port.portees(contexte);
        for (final String brut in _hostiles) {
          // Le garde-fou de saisie de l'ecran borne avant tout appel.
          final RequeteNormalisee q = RequeteNormalisee.de(brut, contexte);
          if (q.validite != ValiditeRequete.valide) continue;
          expect(
            q.texte.length,
            lessThanOrEqualTo(BudgetsRecherche.longueurMaximale),
          );
          expect(
            q.texte.split(' ').length,
            lessThanOrEqualTo(BudgetsRecherche.termesMaximum),
          );
          for (final DomaineRecherche d in servis) {
            final ReponseDomaine r = await port.rechercher(
              domaine: d,
              requete: q.texte,
              contexte: contexte,
            );
            switch (r) {
              case ReponseEchec():
                break;
              case ReponseOk(:final List<ResultatRecherche> elements):
                for (final ResultatRecherche e in elements) {
                  // Une saisie hostile ne se retrouve jamais rendue telle
                  // quelle comme titre, contexte ou extrait.
                  for (final String? texte in <String?>[
                    e.titre,
                    e.contexte,
                    e.extrait,
                  ]) {
                    expect(texte ?? '', isNot(contains('<script')));
                    expect(texte ?? '', isNot(contains('DROP TABLE')));
                  }
                  expect(
                    jsonEncode(<String>[e.titre, e.reference]),
                    isNot(contains('<script')),
                  );
                }
            }
          }
        }
      });
    }
  });

  group('REC-12 : reprise apres panne, pas de faux succes', () {
    test(
      'un domaine en panne puis revenu : echec nomme, puis resultats',
      () async {
        final ProviderContainer c = _conteneur();
        final List<MoteurRechercheDomaine> moteurs = c.read(_tous);
        final MoteurRechercheDomaine fils = moteurs.firstWhere(
          (MoteurRechercheDomaine m) => m.domaine == DomaineRecherche.fils,
        );
        int appels = 0;
        final PortRecherche port = PortRechercheParMoteurs(
          <MoteurRechercheDomaine>[_Intermittent(fils, () => ++appels == 1)],
        );
        const ContexteRecherche contexte = ContexteRecherche(
          espace: EspaceRecherche.famille,
        );
        final ReponseDomaine panne = await port.rechercher(
          domaine: DomaineRecherche.fils,
          requete: 'classe',
          contexte: contexte,
        );
        expect(panne, isA<ReponseEchec>());
        final ReponseDomaine repris = await port.rechercher(
          domaine: DomaineRecherche.fils,
          requete: 'classe',
          contexte: contexte,
        );
        expect(repris, isA<ReponseOk>());
      },
    );

    test('sans moteur : aucun domaine, aucune reponse inventee', () async {
      const PortRecherche port = PortRechercheParMoteurs(
        <MoteurRechercheDomaine>[],
      );
      for (final EspaceRecherche e in EspaceRecherche.values) {
        expect(await port.portees(ContexteRecherche(espace: e)), isEmpty);
      }
    });
  });

  group('REC-01 / REC-07 : isolement par espace, double de demonstration', () {
    test('aucun domaine hors du perimetre de l\'espace n\'est servi', () async {
      final ProviderContainer c = _conteneur();
      final PortRecherche port = PortRechercheParMoteurs(c.read(_tous));
      Future<Set<DomaineRecherche>> servis(EspaceRecherche e) async =>
          (await port.portees(ContexteRecherche(espace: e))).toSet();
      expect(await servis(EspaceRecherche.comptable), <DomaineRecherche>{
        DomaineRecherche.finances,
        DomaineRecherche.fils,
      });
      expect(
        (await servis(EspaceRecherche.eleveGuide))
            .intersection(<DomaineRecherche>{
              DomaineRecherche.finances,
              DomaineRecherche.personnes,
              DomaineRecherche.fils,
              DomaineRecherche.pedagogie,
            }),
        isEmpty,
      );
      expect(
        (await servis(EspaceRecherche.famille))
            .contains(DomaineRecherche.finances),
        isFalse,
      );
    });
  });

  group('performance perçue : temps de reponse du double de demonstration', () {
    test(
      'p95 sur 3 000 elements par domaine (mesure, pas une promesse)',
      () async {
        final List<MoteurRechercheDomaine> moteurs = moteursDemoRecherche();
        const ContexteRecherche contexte = ContexteRecherche(
          espace: EspaceRecherche.enseignant,
        );
        final List<int> durees = <int>[];
        final Stopwatch montre = Stopwatch();
        final List<String> requetes = <String>[
          'fatiha',
          'classe',
          'coran',
          'niveau',
          'mariam',
          'omar',
          'tajwid',
          'arabe',
          'lecon',
          'support',
        ];
        for (int tour = 0; tour < 20; tour++) {
          for (final String q in requetes) {
            for (final MoteurRechercheDomaine m in moteurs) {
              montre
                ..reset()
                ..start();
              await m.rechercher(requete: q, contexte: contexte);
              montre.stop();
              durees.add(montre.elapsedMicroseconds);
            }
          }
        }
        durees.sort();
        final int p50 = durees[(durees.length * 0.50).floor()];
        final int p95 = durees[(durees.length * 0.95).floor()];
        final int p99 = durees[(durees.length * 0.99).floor()];
        // ignore: avoid_print
        print(
          'RECH-REC p50=${p50 / 1000} ms p95=${p95 / 1000} ms '
          'p99=${p99 / 1000} ms sur ${durees.length} requetes de moteur '
          '(double en memoire, machine d\'integration)',
        );
        // Garde large : un double en memoire qui depasserait 250 ms au p95
        // signalerait un balayage fautif, pas une charge serveur.
        expect(p95, lessThan(250 * 1000));
      },
    );
  });
}

/// Un moteur qui echoue tant que [enPanne] rend vrai.
class _Intermittent implements MoteurRechercheDomaine {
  _Intermittent(this._vrai, this.enPanne);

  final MoteurRechercheDomaine _vrai;
  final bool Function() enPanne;

  @override
  DomaineRecherche get domaine => _vrai.domaine;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) =>
      _vrai.disponiblePour(contexte);

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  }) {
    if (enPanne()) throw StateError('panne');
    return _vrai.rechercher(
      requete: requete,
      contexte: contexte,
      curseur: curseur,
      limite: limite,
    );
  }
}

class _RosterVide extends PortRosterEnseignant {
  @override
  Future<List<TeacherStudentProjection>> rosterDeGroupe(
    String groupeId,
  ) async => const <TeacherStudentProjection>[];

  @override
  Future<List<TeacherStudentProjection>> rosterDeSeance(
    String sessionId,
  ) async => const <TeacherStudentProjection>[];

  @override
  Future<TeacherStudentProjection?> fiche({
    required String academyId,
    String? sessionId,
  }) async => null;

  @override
  Stream<List<TeacherStudentProjection>> suivreRoster(String sessionId) =>
      const Stream<List<TeacherStudentProjection>>.empty();
}
