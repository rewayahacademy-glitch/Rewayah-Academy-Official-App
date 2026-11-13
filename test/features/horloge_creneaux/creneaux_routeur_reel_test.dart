// HORLOGE-ET-LIEU, correctifs de la partie A (13/11/2026, B1, B2 et I8) :
// chaque ecran corrige part du VRAI routeur de l'application (`routeurProvider`),
// jamais d'une page montee seule.
//
// B1 : un creneau de classe se lit a l'heure de la personne d'abord, puis
//      « Heure de La Mecque » en second ; jamais l'heure enregistree, brute.
// B2 : la direction saisit une heure dans SON fuseau ; l'ecran envoie ce fuseau
//      et montre l'equivalent a La Mecque avant d'envoyer.
// Deux etats de la base : classes encore a Paris (avant la migration), classes a
// La Mecque (apres). L'horloge est fixee : jeudi 12/11/2026 22:00 UTC, l'hiver.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/creneaux_classe.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/capacites/port_creation_classe.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/lieu/lieu_direction.dart';
import 'package:rewayah_academy/core/tc_horloge/apercu_creneau.dart';
import 'package:rewayah_academy/core/tc_horloge/creneau_chez_moi.dart';
import 'package:rewayah_academy/core/tc_horloge/fuseaux_interlocuteurs.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_groupes/feuille_reglages_classe.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import '../support_form_l2.dart';

const Map<String, Object?> _paris = <String, Object?>{
  'fuseau': 'Europe/Paris',
  'decalage_secondes': 3600,
  'prochain_changement': '2027-03-28T01:00:00Z',
  'decalage_apres': 7200,
  'changement_suivant': '2027-10-31T01:00:00Z',
};
const Map<String, Object?> _riyad = <String, Object?>{
  'fuseau': 'Asia/Riyadh',
  'decalage_secondes': 10800,
  'prochain_changement': null,
};

final DateTime _maintenant = DateTime.utc(2026, 11, 12, 22);

MonHorloge _lecture({Map<String, Object?>? moi = _paris}) =>
    MonHorloge.lire(<String, Object?>{
      'maintenant': '2026-11-12T22:00:00Z',
      'moi': ?moi,
      'academie': _riyad,
    });

class _PortFuseaux implements PortFuseauVu {
  _PortFuseaux(this.connus);

  /// Les fuseaux que le serveur sait rendre ; les autres : `null`.
  final Map<String, Map<String, Object?>> connus;

  @override
  Future<FuseauVu?> lire(String fuseau) async => FuseauVu.lire(connus[fuseau]);
}

class _PortApercu implements PortApercuCreneau {
  @override
  Future<ApercuCreneau?> lire({
    required String fuseau,
    required int jour,
    required int heure,
    String? fuseauCreneau,
  }) async {
    // L'equivalent a La Mecque d'un mercredi 19:00 a Paris : 21:00 ; puis la
    // vue de Paris, avant et apres son changement d'heure.
    if (fuseau == 'Asia/Riyadh') {
      return ApercuCreneau.lire(<String, Object?>{
        'jour_maintenant': 3,
        'maintenant': '21:00',
        'meme': true,
      });
    }
    return ApercuCreneau.lire(<String, Object?>{
      'jour_maintenant': 3,
      'maintenant': '19:00',
      'meme': false,
      'date_changement': '2027-03-28',
      'jour_apres': 3,
      'heure_apres': '20:00',
    });
  }
}

class _Direction implements PortLieuDirection {
  _Direction(this.changements);

  final List<ChangementHeureAVenir> changements;

  @override
  Future<List<ChangementHeureAVenir>> changementsHeure({
    int jours = 60,
  }) async => changements;

  @override
  Future<List<LieuEnseignantDirection>> lieux() async =>
      const <LieuEnseignantDirection>[];

  @override
  Future<List<IncoherenceLieu>> incoherences() async =>
      const <IncoherenceLieu>[];

  @override
  Future<void> verifier(String profilId) async {}
}

class _FauxCreneaux implements ServiceCreneauxClasse {
  final List<(int, int, String?, String?)> ajouts =
      <(int, int, String?, String?)>[];

  @override
  Future<int> ajouter({
    required String groupeId,
    required int jour,
    required int heure,
    String? fuseau,
    String? fuseauClasse,
  }) async {
    ajouts.add((jour, heure, fuseau, fuseauClasse));
    return 2;
  }

  @override
  Future<List<CreneauClasse>> lister(String groupeId) async => <CreneauClasse>[
    (jour: 3, heure: 21, duree: null),
  ];

  @override
  Future<int> modifier({
    required String groupeId,
    required CreneauClasse ancien,
    required CreneauClasse nouveau,
    required String motif,
    String? fuseau,
    String? fuseauClasse,
  }) async => 0;

  @override
  Future<int> retirer({
    required String groupeId,
    required CreneauClasse creneau,
    required String motif,
  }) async => 0;

  @override
  Future<void> reglerGenre({
    required String groupeId,
    required GenreClasse genre,
    required String motif,
  }) async {}
}

class _GroupesAdmin extends FauxGroupesFormL2 {
  _GroupesAdmin(this.fuseau, this.jour, this.heure);

  final String fuseau;
  final int jour;
  final int heure;

  @override
  Future<List<GroupeAdmin>> groupes() async => <GroupeAdmin>[
    GroupeAdmin(
      id: 'g1',
      libelle: 'An-Nour',
      type: TypePublicGroupe.enfant,
      seuilMax: 5,
      teacherId: 't-amina',
      teacherIdentifiant: 'ENS-AD-001',
      teacherPrenom: 'Amina',
      teacherNom: 'Diallo',
      creneau: Creneau(jour: jour, heure: heure, fuseau: fuseau),
      nombreMembres: 2,
      actif: true,
    ),
  ];
}

List<Override> _horloges(
  MonHorloge lecture, {
  required Map<String, Map<String, Object?>> fuseaux,
}) {
  poserMonHorlogePourTest(lecture);
  poserHorlogeCreneauxPourTest(() => _maintenant);
  return <Override>[
    // Hors Supabase, la vraie lecture rendrait null et viderait la lecture posee
    // (TEST-HORLOGE-SURCHARGE, registre des lots).
    monHorlogeProvider.overrideWith((Ref ref) async => lecture),
    portFuseauVuProvider.overrideWithValue(_PortFuseaux(fuseaux)),
    portApercuCreneauProvider.overrideWithValue(_PortApercu()),
  ];
}

FauxServiceEnseignant _enseignant(String fuseau, int jour, int heure) {
  return FauxServiceEnseignant()
    ..groupesRendus = <GroupeEnseignant>[
      GroupeEnseignant(
        id: 'g1',
        libelle: 'An-Nour',
        type: TypePublicGroupe.enfant,
        seuilMax: 5,
        creneau: Creneau(jour: jour, heure: heure, fuseau: fuseau),
        nbMembres: 2,
        creeLe: DateTime(2026, 9),
      ),
    ];
}

Future<void> _ficheEnseignant(
  WidgetTester tester, {
  required String fuseauClasse,
  required int jour,
  required int heure,
  required Map<String, Map<String, Object?>> fuseaux,
  Map<String, Object?>? moi = _paris,
}) async {
  await monterRouteur(
    tester,
    Routes.groupePour('g1'),
    source: FausseSourceSession(sessionActive(AppRole.teacher)),
    taille: const Size(1000, 900),
    enseignant: _enseignant(fuseauClasse, jour, heure),
    surcharges: _horloges(_lecture(moi: moi), fuseaux: fuseaux),
  );
  await tester.pumpAndSettle();
}

String _horaire(String jour, String heure) =>
    t.enseignant.ficheGroupe.creneauHebdo(jour: jour, heure: heure);

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));
  tearDown(() {
    poserMonHorlogePourTest(null);
    poserHorlogeCreneauxPourTest(null);
    viderFuseauxLusPourTest();
  });

  group('fiche de la classe de l enseignant (vrai routeur)', () {
    testWidgets('apres la migration (classe a La Mecque, mercredi 21:00) : '
        '19:00 a Paris, puis Heure de La Mecque', (tester) async {
      await _ficheEnseignant(
        tester,
        fuseauClasse: 'Asia/Riyadh',
        jour: 3,
        heure: 21,
        fuseaux: <String, Map<String, Object?>>{
          'Asia/Riyadh': _riyad,
          'Europe/Paris': _paris,
        },
      );
      expect(
        find.text(_horaire('mercredi', '19:00 · Heure de La Mecque : 21:00')),
        findsOneWidget,
      );
      expect(find.textContaining('Riyad'), findsNothing);
      expect(find.textContaining('21 h'), findsNothing);
    });

    testWidgets('avant la migration (classe a Paris, mercredi 19:00) : la meme '
        'ligne', (tester) async {
      await _ficheEnseignant(
        tester,
        fuseauClasse: 'Europe/Paris',
        jour: 3,
        heure: 19,
        fuseaux: <String, Map<String, Object?>>{
          'Asia/Riyadh': _riyad,
          'Europe/Paris': _paris,
        },
      );
      expect(
        find.text(_horaire('mercredi', '19:00 · Heure de La Mecque : 21:00')),
        findsOneWidget,
      );
    });

    testWidgets(
      'serveur pas encore a jour (aucune lecture de fuseau) : l heure '
      'du creneau et sa ville, jamais Riyad ni une heure devinee',
      (tester) async {
        await _ficheEnseignant(
          tester,
          fuseauClasse: 'Europe/Paris',
          jour: 3,
          heure: 19,
          fuseaux: const <String, Map<String, Object?>>{},
        );
        expect(
          find.text(_horaire('mercredi', '19:00 (heure de Paris)')),
          findsOneWidget,
        );
        expect(find.textContaining('La Mecque'), findsNothing);
      },
    );

    testWidgets('jour qui change : lundi 01:00 a La Mecque, dimanche 23:00 a '
        'Paris', (tester) async {
      await _ficheEnseignant(
        tester,
        fuseauClasse: 'Asia/Riyadh',
        jour: 1,
        heure: 1,
        fuseaux: <String, Map<String, Object?>>{
          'Asia/Riyadh': _riyad,
          'Europe/Paris': _paris,
        },
      );
      expect(
        find.text(_horaire('dimanche', '23:00 · Heure de La Mecque : 01:00')),
        findsOneWidget,
      );
    });
  });

  group('classes de la direction (vrai routeur)', () {
    Future<_FauxCreneaux> monter(
      WidgetTester tester, {
      required String fuseauClasse,
      required int jour,
      required int heure,
      required Map<String, Map<String, Object?>> fuseaux,
      Map<String, Object?>? moi = _paris,
    }) async {
      final _FauxCreneaux creneaux = _FauxCreneaux();
      await monterRouteur(
        tester,
        Routes.adminOperationsGroupes,
        source: FausseSourceSession(sessionActive(AppRole.admin)),
        taille: const Size(1440, 1600),
        surcharges: <Override>[
          ...surchargesFormL2(
            comptes: FauxComptesFormL2(comptesFormL2),
            groupes: _GroupesAdmin(fuseauClasse, jour, heure),
          ),
          portEnseignantsClasseProvider.overrideWithValue(
            FauxEnseignantsClasse(const []),
          ),
          portCreationClasseProvider.overrideWithValue(FauxCreationClasse()),
          serviceCreneauxClasseProvider.overrideWithValue(creneaux),
          ..._horloges(_lecture(moi: moi), fuseaux: fuseaux),
        ],
      );
      await tester.pumpAndSettle();
      return creneaux;
    }

    Future<void> presser(WidgetTester tester, Finder cible) async {
      await tester.ensureVisible(cible);
      await tester.pumpAndSettle();
      await tester.tap(cible);
      await tester.pumpAndSettle();
    }

    Future<void> ouvrirAjout(WidgetTester tester) async {
      await presser(
        tester,
        find.byWidgetPredicate(
          (Widget w) => w is MenuActions && (w.objet ?? '').contains('An-Nour'),
        ),
      );
      await presser(
        tester,
        find.text(t.admin.groupes.reglagesClasse.action).last,
      );
      await presser(
        tester,
        find.byKey(const ValueKey<String>('reglages-ajouter-creneau')),
      );
    }

    testWidgets('la liste dit l heure de la personne puis Heure de La Mecque '
        '(classe a La Mecque)', (tester) async {
      await monter(
        tester,
        fuseauClasse: 'Asia/Riyadh',
        jour: 3,
        heure: 21,
        fuseaux: <String, Map<String, Object?>>{
          'Asia/Riyadh': _riyad,
          'Europe/Paris': _paris,
        },
      );
      expect(
        find.textContaining('Mercredi 19:00 · Heure de La Mecque : 21:00'),
        findsWidgets,
      );
      expect(find.textContaining('21h'), findsNothing);
      expect(find.textContaining('Riyad'), findsNothing);
    });

    testWidgets('apres la migration : la feuille « Ajouter un creneau » saisit '
        'a l heure de Paris et envoie le fuseau, la classe est a La Mecque', (
      tester,
    ) async {
      final _FauxCreneaux creneaux = await monter(
        tester,
        fuseauClasse: 'Asia/Riyadh',
        jour: 3,
        heure: 21,
        fuseaux: <String, Map<String, Object?>>{
          'Asia/Riyadh': _riyad,
          'Europe/Paris': _paris,
        },
      );
      await ouvrirAjout(tester);
      // L'heure est saisie a l'heure de la personne, et l'ecran le dit.
      expect(find.text('Heure de Paris'), findsOneWidget);
      await presser(
        tester,
        find.byKey(const ValueKey<String>('creneau-jour-3')),
      );
      await presser(
        tester,
        find.byKey(const ValueKey<String>('creneau-heure')),
      );
      await presser(
        tester,
        find.text(t.admin.groupes.formulaire.heureValeur(heure: '19')).last,
      );
      // L'equivalent a La Mecque, AVANT d'envoyer.
      expect(find.byKey(LigneEquivalentMecque.cle), findsOneWidget);
      expect(
        find.text(
          t.tc.groupe.horloges.apercuClasse(jour: 'mercredi', heure: '21:00'),
        ),
        findsOneWidget,
      );
      await presser(tester, find.text(t.admin.groupes.creneau.envoyer).last);
      expect(creneaux.ajouts.single, (3, 19, 'Europe/Paris', 'Asia/Riyadh'));
    });

    testWidgets('avant la migration (classe a Paris) : le meme geste envoie '
        'Paris et Paris', (tester) async {
      final _FauxCreneaux creneaux = await monter(
        tester,
        fuseauClasse: 'Europe/Paris',
        jour: 2,
        heure: 17,
        fuseaux: <String, Map<String, Object?>>{'Europe/Paris': _paris},
      );
      await ouvrirAjout(tester);
      expect(find.text('Heure de Paris'), findsOneWidget);
      await presser(
        tester,
        find.byKey(const ValueKey<String>('creneau-jour-4')),
      );
      await presser(
        tester,
        find.byKey(const ValueKey<String>('creneau-heure')),
      );
      await presser(
        tester,
        find.text(t.admin.groupes.formulaire.heureValeur(heure: '18')).last,
      );
      await presser(tester, find.text(t.admin.groupes.creneau.envoyer).last);
      expect(creneaux.ajouts.single, (4, 18, 'Europe/Paris', 'Europe/Paris'));
    });

    testWidgets(
      'une direction sans fuseau connu saisit a l heure de La Mecque, '
      'et l ecran le dit',
      (tester) async {
        final _FauxCreneaux creneaux = await monter(
          tester,
          fuseauClasse: 'Asia/Riyadh',
          jour: 3,
          heure: 21,
          moi: null,
          fuseaux: <String, Map<String, Object?>>{'Asia/Riyadh': _riyad},
        );
        await ouvrirAjout(tester);
        expect(find.text(t.tc.groupe.horloges.heureMecque), findsWidgets);
        await presser(
          tester,
          find.byKey(const ValueKey<String>('creneau-jour-5')),
        );
        await presser(
          tester,
          find.byKey(const ValueKey<String>('creneau-heure')),
        );
        await presser(
          tester,
          find.text(t.admin.groupes.formulaire.heureValeur(heure: '20')).last,
        );
        // Saisi a l'heure de La Mecque : pas de ligne d'equivalent a montrer.
        expect(find.byKey(LigneEquivalentMecque.cle), findsNothing);
        await presser(tester, find.text(t.admin.groupes.creneau.envoyer).last);
        expect(creneaux.ajouts.single, (5, 20, 'Asia/Riyadh', 'Asia/Riyadh'));
      },
    );
  });

  group('comptes de la direction (vrai routeur) : changements d heure', () {
    Future<void> monterComptes(
      WidgetTester tester,
      String vue,
      List<ChangementHeureAVenir> changements,
    ) async {
      await monterRouteur(
        tester,
        '${Routes.adminPersonnesComptes}?vue=$vue',
        source: FausseSourceSession(sessionActive(AppRole.admin)),
        taille: const Size(1440, 1200),
        surcharges: <Override>[
          ...surchargesFormL2(comptes: FauxComptesFormL2(comptesFormL2)),
          portLieuDirectionProvider.overrideWithValue(_Direction(changements)),
        ],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('familles : un changement a venir, la date, la ville, le '
        'nombre de personnes, le decalage', (tester) async {
      await monterComptes(tester, 'familles', <ChangementHeureAVenir>[
        ChangementHeureAVenir(
          fuseau: 'Europe/Paris',
          transition: DateTime.utc(2027, 3, 28, 1),
          decalageAvant: const Duration(hours: 1),
          decalageApres: const Duration(hours: 2),
          familles: 12,
          enseignants: 3,
        ),
      ]);
      expect(find.text(t.lieu.changementsTitre), findsOneWidget);
      expect(find.textContaining('UTC+1'), findsOneWidget);
      expect(find.textContaining('UTC+2'), findsOneWidget);
      expect(find.textContaining('28 mars 2027'), findsOneWidget);
    });

    testWidgets('enseignants, aucun changement : l ecran le dit', (
      tester,
    ) async {
      await monterComptes(
        tester,
        'enseignants',
        const <ChangementHeureAVenir>[],
      );
      expect(
        find.text(t.lieu.changementsAucun(jours: '$joursChangementsHeure')),
        findsOneWidget,
      );
    });
  });
}
