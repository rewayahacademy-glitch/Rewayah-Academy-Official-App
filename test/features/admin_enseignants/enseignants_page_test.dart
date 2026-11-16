// LP-2 : la liste des enseignants. Une ligne par personne, sa phase, ce qui
// compte dans cette phase, le badge « Nouveau », un menu « ... » et une
// selection servis par le serveur (gestes, gestesGroupables).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_lot_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/enseignants/port_enseignants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/badge_nouveau.dart';
import 'package:rewayah_academy/features/admin_enseignants/enseignants_page.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart';

class _AppelEnseignants {
  _AppelEnseignants(this.filtre, this.tri, this.page);

  final FiltreEnseignants filtre;
  final TriEnseignants tri;
  final int page;
}

/// Le port de la liste, en memoire : il rend la page qu'on lui donne et note les
/// requetes.
class _FauxEnseignants implements PortEnseignants {
  _FauxEnseignants(this.lignes, {this.compteurs, this.erreur});

  final List<LigneEnseignant> lignes;
  final CompteursEnseignants? compteurs;
  final Exception? erreur;
  final List<_AppelEnseignants> appels = <_AppelEnseignants>[];

  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) async {
    appels.add(_AppelEnseignants(filtre, tri, page));
    final Exception? e = erreur;
    if (e != null) throw e;
    final List<LigneEnseignant> choisies = <LigneEnseignant>[
      for (final LigneEnseignant l in lignes)
        if ((filtre.phase == null || l.phase == filtre.phase) &&
            (filtre.nouveau != true || l.dossier.nouveau))
          l,
    ];
    return PageEnseignants(
      lignes: choisies,
      total: choisies.length,
      page: page,
      taillePage: 50,
      compteurs:
          compteurs ??
          const CompteursEnseignants(
            parPhase: <PhaseEnseignant, int>{
              PhaseEnseignant.candidat: 1,
              PhaseEnseignant.accueil: 1,
              PhaseEnseignant.enPoste: 1,
            },
            nouveaux: 1,
            sansDossier: 2,
          ),
    );
  }
}

LigneEnseignant _ligne(
  String id,
  String nom,
  PhaseEnseignant phase, {
  bool nouveau = false,
  List<String> manque = const <String>[],
  String? quiAttend,
  List<String> gestes = const <String>[],
  List<String> groupables = const <String>[],
  ClassesEnseignant classes = const ClassesEnseignant(
    nombre: 0,
    heuresSemaine: 0,
  ),
}) => LigneEnseignant(
  dossier: ligneTest(id: id, nom: nom, nouveau: nouveau),
  phase: phase,
  manque: manque,
  quiAttend: quiAttend,
  gestes: gestes,
  gestesGroupables: groupables,
  classes: classes,
);

List<LigneEnseignant> _lignes() => <LigneEnseignant>[
  _ligne(
    'c1',
    'Amina Diallo',
    PhaseEnseignant.candidat,
    nouveau: true,
    quiAttend: 'direction',
    gestes: <String>['refuser', 'mettre_en_pause', 'valider_piece'],
    groupables: <String>['refuser', 'mettre_en_pause'],
  ),
  _ligne(
    'c2',
    'Bilal Haddad',
    PhaseEnseignant.accueil,
    manque: <String>['photo_absente', 'langues_absentes'],
    quiAttend: 'enseignant',
    gestes: <String>['mettre_en_pause'],
    groupables: <String>['mettre_en_pause'],
  ),
  _ligne(
    'c3',
    'Farah Nasser',
    PhaseEnseignant.enPoste,
    classes: const ClassesEnseignant(nombre: 2, heuresSemaine: 3),
  ),
];

Future<void> _monter(
  WidgetTester tester, {
  PortEnseignants? port,
  double largeur = 390,
  void Function(LigneCandidature)? ouvrir,
}) => monterRecrutement(
  tester,
  chemin: Routes.adminPersonnesEnseignants,
  ecran: (GoRouterState _) => EnseignantsPage(ouvrirCandidature: ouvrir),
  surcharges: <Override>[
    portEnseignantsProvider.overrideWithValue(port),
    portCandidaturesDirectionProvider.overrideWithValue(
      FauxCandidaturesDirection(
        lignes: const <LigneCandidature>[],
        capacitesRendues: capacitesGestes,
      ),
    ),
  ],
  largeur: largeur,
  hauteur: 3000,
);

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('fonctions pures : ce que le serveur annonce', () {
    test(
      'un nom de geste du serveur devient le geste que l\'ecran sait faire',
      () {
        expect(gesteDuServeur('refuser')?.name, 'refuser');
        expect(gesteDuServeur('retirer')?.name, 'consignerRetrait');
        expect(gesteDuServeur('mettre_en_pause')?.name, 'mettreEnPause');
        // Un geste que l'ecran ne sait pas faire n'est pas devine.
        expect(gesteDuServeur('affecter_classe'), isNull);
        expect(gesteDuServeur('definir_responsable'), isNull);
      },
    );

    test(
      'les gestes de lot sont ceux que TOUTES les lignes retenues permettent',
      () {
        final List<LigneEnseignant> l = _lignes();
        expect(gestesDeLot(<LigneEnseignant>[l[0]]), <GesteLot>[
          GesteLot.mettreEnPause,
          GesteLot.refuser,
        ]);
        expect(gestesDeLot(<LigneEnseignant>[l[0], l[1]]), <GesteLot>[
          GesteLot.mettreEnPause,
        ]);
        expect(gestesDeLot(<LigneEnseignant>[l[0], l[2]]), isEmpty);
        expect(gestesDeLot(const <LigneEnseignant>[]), isEmpty);
      },
    );

    test('la phase, la famille et ce qui manque se disent en mots', () {
      expect(libellePhase(PhaseEnseignant.enPoste), 'En poste');
      expect(tonDePhase(PhaseEnseignant.absent).name, 'alerte');
      expect(libelleManque('photo_absente'), 'photo');
      expect(libelleManque('inconnu'), isNull);
      expect(phraseManque(_lignes()[1]), 'Il manque : photo, langues');
      expect(phraseManque(_lignes()[0]), isNull);
    });

    test('la section « Enseignants » est avant Invitations, sans decaler les index', () {
      final List<String> chemins = <String>[
        for (final ({String libelle, String chemin}) o in ongletsPersonnes())
          o.chemin,
      ];
      expect(chemins.indexOf(Routes.adminPersonnesEnseignants), 6);
      expect(chemins.indexOf(Routes.adminPersonnesSuppressions), 5);
      expect(chemins.last, Routes.adminPersonnesAdmissions);
      expect(
        chemins.indexOf(Routes.adminPersonnesInvitations),
        chemins.indexOf(Routes.adminPersonnesEnseignants) + 1,
      );
    });
  });

  group('la liste', () {
    testWidgets('une ligne par personne : phase, resume, badge « Nouveau »', (
      tester,
    ) async {
      await _monter(tester, port: _FauxEnseignants(_lignes()));
      expect(find.text('Amina Diallo'), findsOneWidget);
      expect(find.text('Bilal Haddad'), findsOneWidget);
      expect(find.text('Farah Nasser'), findsOneWidget);
      // Les phases, en mots.
      expect(find.text('Candidat'), findsWidgets);
      expect(find.text('Accueil'), findsWidgets);
      expect(find.text('En poste'), findsWidgets);
      // Ce qui manque a la personne en accueil ; les classes de celle en poste.
      expect(find.text('Il manque : photo, langues'), findsOneWidget);
      expect(find.textContaining('2 classes'), findsOneWidget);
      // Qui attend quoi.
      expect(find.text('Attend : la direction'), findsOneWidget);
      expect(find.text('Attend : l\'enseignant'), findsOneWidget);
      // Le badge, sur la seule ligne nouvelle.
      expect(find.byType(BadgeNouveau), findsOneWidget);
      expect(_cle('enseignants-total'), findsOneWidget);
      expect(find.text('3 enseignants'), findsOneWidget);
      // Les comptes sans dossier sont dits, jamais caches.
      expect(
        find.text(t.admin.listeEnseignants.sansDossier(n: 2)),
        findsOneWidget,
      );
    });

    testWidgets(
      'le menu « Phase » : les nombres, et le choix filtre au serveur',
      (tester) async {
        final _FauxEnseignants port = _FauxEnseignants(_lignes());
        await _monter(tester, port: port);
        await tester.tap(_cle('enseignants-phase'));
        await laisser(tester);
        expect(find.textContaining('En poste · 1'), findsOneWidget);
        expect(find.textContaining('Nouveaux · 1'), findsOneWidget);
        await tester.tap(find.textContaining('En poste · 1'));
        await laisser(tester);
        expect(port.appels.last.filtre.phase, PhaseEnseignant.enPoste);
        expect(find.text('Farah Nasser'), findsOneWidget);
        expect(find.text('Amina Diallo'), findsNothing);
        // Les nouveaux : le filtre `nouveau` part au serveur.
        await tester.tap(_cle('enseignants-phase'));
        await laisser(tester);
        await tester.tap(find.textContaining('Nouveaux · 1'));
        await laisser(tester);
        expect(port.appels.last.filtre.nouveau, isTrue);
        expect(port.appels.last.filtre.phase, isNull);
      },
    );

    testWidgets('la recherche ne s\'ouvre qu\'a la loupe', (tester) async {
      final _FauxEnseignants port = _FauxEnseignants(_lignes());
      await _monter(tester, port: port);
      expect(_cle('enseignants-recherche'), findsNothing);
      await tester.tap(_cle('enseignants-loupe'));
      await laisser(tester);
      expect(_cle('enseignants-recherche'), findsOneWidget);
      await tester.enterText(_cle('enseignants-recherche'), 'Bilal');
      await tester.pump(const Duration(milliseconds: 400));
      await laisser(tester);
      expect(port.appels.last.filtre.recherche, 'Bilal');
    });

    testWidgets('le toucher d\'une ligne ouvre le dossier de candidature', (
      tester,
    ) async {
      LigneCandidature? ouverte;
      await _monter(
        tester,
        port: _FauxEnseignants(_lignes()),
        ouvrir: (LigneCandidature l) => ouverte = l,
      );
      await tester.tap(_cle('enseignant-c2'));
      await laisser(tester);
      expect(ouverte?.id, 'c2');
    });

    testWidgets(
      'le menu « ... » ne propose que les gestes que le serveur permet',
      (tester) async {
        await _monter(
          tester,
          port: _FauxEnseignants(_lignes()),
          ouvrir: (LigneCandidature _) {},
        );
        await tester.tap(_cle('enseignant-menu-c1'));
        await laisser(tester);
        expect(
          find.text(t.admin.candidatures.liste.ouvrirDossier),
          findsOneWidget,
        );
        expect(find.text('Mettre en pause'), findsOneWidget);
        expect(find.textContaining('Refuser'), findsOneWidget);
        // Un geste que le serveur n'annonce pas n'est pas offert.
        expect(find.text('Demander une précision'), findsNothing);
      },
    );

    testWidgets(
      'la selection : « Selectionner » et les gestes groupables de TOUTES les lignes',
      (tester) async {
        await _monter(tester, port: _FauxEnseignants(_lignes()));
        await tester.tap(_cle('enseignants-selectionner'));
        await laisser(tester);
        await tester.tap(_cle('enseignant-c1'));
        await laisser(tester);
        // Une ligne : pause et refus.
        expect(_cle('enseignants-lot-mettreEnPause'), findsOneWidget);
        expect(_cle('enseignants-lot-refuser'), findsOneWidget);
        await tester.tap(_cle('enseignant-c2'));
        await laisser(tester);
        // Deux lignes : seulement ce que les deux permettent.
        expect(_cle('enseignants-lot-mettreEnPause'), findsOneWidget);
        expect(_cle('enseignants-lot-refuser'), findsNothing);
        await tester.tap(_cle('enseignant-c3'));
        await laisser(tester);
        // La troisieme ne groupe rien : aucune operation, la phrase le dit.
        expect(_cle('enseignants-lot-mettreEnPause'), findsNothing);
      },
    );

    testWidgets('sans geste groupable, « Selectionner » n\'est pas rendu', (
      tester,
    ) async {
      await _monter(
        tester,
        port: _FauxEnseignants(<LigneEnseignant>[
          _ligne('c3', 'Farah Nasser', PhaseEnseignant.enPoste),
        ]),
      );
      expect(_cle('enseignants-selectionner'), findsNothing);
    });
  });

  group('les etats', () {
    testWidgets('sans port : la capacite est dite indisponible', (
      tester,
    ) async {
      await _monter(tester);
      expect(_cle('enseignants-indisponible'), findsOneWidget);
    });

    testWidgets('un refus du serveur est dit en mots', (tester) async {
      await _monter(
        tester,
        port: _FauxEnseignants(
          const <LigneEnseignant>[],
          erreur: const CapaciteIndisponible('LP-1'),
        ),
      );
      expect(_cle('enseignants-indisponible'), findsOneWidget);
    });

    testWidgets('aucun enseignant : l\'etat vide, sans bouton', (tester) async {
      await _monter(
        tester,
        port: _FauxEnseignants(
          const <LigneEnseignant>[],
          compteurs: const CompteursEnseignants(),
        ),
      );
      expect(_cle('enseignants-vide'), findsOneWidget);
    });

    testWidgets('en arabe, les mots du module', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      addTearDown(
        () => tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr)),
      );
      await _monter(tester, port: _FauxEnseignants(_lignes()));
      expect(find.text(t.admin.listeEnseignants.phases.enPoste), findsWidgets);
      expect(find.textContaining('Enseignants'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
