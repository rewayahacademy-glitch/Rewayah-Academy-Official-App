import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart'
    show PositionLecture;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/selecteur_motif.dart';
import 'package:rewayah_academy/core/widgets/zone_saisie.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/cahier/vue_cahier.dart';

import '../support/harnais.dart';

const String _seance = 's1';
final DateTime _debut = DateTime(2026, 9, 20, 17);

ParticipantBrouillon _participant({
  String id = 'e1',
  String prenom = 'Khadija',
  EtatPresence presence = EtatPresence.presente,
  UniteCurriculum? unite,
  bool lu = true,
  bool suspensionPermise = true,
}) => ParticipantBrouillon(
  membre: membreDeTest(studentId: id, identifiant: 'RA-$id', prenom: prenom),
  presence: presence,
  suspensionPermise: suspensionPermise,
  entreLe: _debut,
  derniereTraceLe: _debut.add(const Duration(minutes: 40)),
  unite: unite,
  // Une position de lecture commune donne la reprise proposee (doc 04 §20.1).
  position: lu ? const PositionLecture(page: 2, sourate: 2, verset: 5) : null,
);

BrouillonCahier _brouillon({
  List<ParticipantBrouillon>? participants,
  bool dejaDepose = false,
  int dureeMinutes = 45,
  int minutesInterruption = 0,
  List<EvenementSeance> evenements = const <EvenementSeance>[],
}) => BrouillonCahier(
  seanceId: _seance,
  debut: _debut,
  fin: _debut.add(const Duration(minutes: 45)),
  statut: StatutSeance.terminee,
  dureeMinutes: dureeMinutes,
  minutesInterruption: minutesInterruption,
  dejaDepose: dejaDepose,
  participants: participants ?? <ParticipantBrouillon>[_participant()],
  evenements: evenements,
);

List<Override> _surcharges({
  required FauxServiceEnseignant service,
  required FauxDepotRapports depot,
  bool horsLigne = false,
}) => <Override>[
  serviceEnseignantProvider.overrideWithValue(service),
  depotRapportsProvider.overrideWithValue(depot),
  serviceReseauProvider.overrideWithValue(
    FauxServiceReseau(horsLigneRendu: horsLigne),
  ),
];

/// Mesure sur un telephone reel, jamais sur la surface par defaut de
/// `flutter_test` (800 x 600, c'est-a-dire une tablette).
///
/// 390 x 844 est le gabarit de reference du produit, et c'est la ou l'enseignant
/// remplit son cahier : une fenetre plus haute cacherait les depassements au
/// lieu de les montrer.
void _telephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Le bouton est dans le flux, sous la reprise (planche 4) : on le rend
/// visible avant de le toucher.
Future<void> _valider(WidgetTester tester) async {
  final Finder bouton = find.byKey(const ValueKey<String>('cahier-valider'));
  await tester.ensureVisible(bouton);
  await tester.pumpAndSettle();
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}

/// Les decisions ecrites dans le contenu du cahier, par eleve.
Map<String, Map<String, dynamic>> _decisionsEnvoyees(
  Map<String, dynamic> contenu,
) {
  final Map<String, Map<String, dynamic>> parEleve =
      <String, Map<String, dynamic>>{};
  for (final Object? ligne in contenu['eleves']! as List<Object?>) {
    final Map<String, dynamic> decision = ligne! as Map<String, dynamic>;
    parEleve[decision['student_id']! as String] = decision;
  }
  return parEleve;
}

void main() {
  group('ENS-04 : le chemin des 45 secondes', () {
    testWidgets('tout est nominal : un seul geste depose le cahier', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon(
          participants: <ParticipantBrouillon>[
            _participant(prenom: 'Khadija'),
            _participant(id: 'e2', prenom: 'Bilal'),
          ],
        );
      final FauxDepotRapports depot = FauxDepotRapports();

      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: _surcharges(service: service, depot: depot),
        ),
      );
      await tester.pumpAndSettle();

      // Le constat dit qu'il n'y a rien a regarder : c'est ce qui autorise le
      // geste unique.
      expect(find.text(t.enseignant.cahier.toutEstNominal), findsOneWidget);
      expect(find.text(t.enseignant.cahier.exceptions), findsNothing);

      // UN SEUL tap, de l'ouverture au depot. C'est la mesure de la cible des
      // 45 secondes que le catalogue exige, et la seule qui soit verifiable.
      await _valider(tester);
      await tester.pumpAndSettle();

      expect(service.cahiersDeposes, hasLength(1));
      final Map<String, Map<String, dynamic>> envoyees = _decisionsEnvoyees(
        service.cahiersDeposes.single.contenu,
      );
      expect(envoyees.keys, <String>{'e1', 'e2'});
      // Le defaut, c'est « Continuer » : aucune ligne n'a ete touchee, et les
      // deux partent confirmees.
      expect(envoyees['e1']!['confirme'], isTrue);
      expect(envoyees['e2']!['confirme'], isTrue);
      expect(envoyees['e1']!.containsKey('motif_exception'), isFalse);
      expect(find.text(t.enseignant.cahier.depose), findsOneWidget);
    });

    testWidgets('la duree affichee est celle que la base a calculee', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      // La seance dure 45 minutes d'horloge, la base en compte 38 : c'est le
      // chiffre de la base qui s'affiche. Le depot sait calculer quatre durees
      // pour la meme seance ; l'ecran n'en calcule aucune.
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon(dureeMinutes: 38, minutesInterruption: 7);
      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: _surcharges(service: service, depot: FauxDepotRapports()),
        ),
      );
      await tester.pumpAndSettle();

      // DUREE-INSECABLE-2 : insecable, et ancree en tete (U+200E).
      expect(
        find.text("\u200E38\u00A0min de cours, dont 7\u00A0min d'interruption"),
        findsOneWidget,
      );
      expect(find.textContaining('45\u00A0min de cours'), findsNothing);
    });
  });

  group('ENS-04 : les exceptions sont les seules lignes a regarder', () {
    testWidgets('une presence inconnue est une exception, jamais une absence', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon(
          participants: <ParticipantBrouillon>[
            _participant(presence: EtatPresence.inconnu),
            _participant(id: 'e2', prenom: 'Bilal'),
          ],
        );

      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: _surcharges(service: service, depot: FauxDepotRapports()),
        ),
      );
      await tester.pumpAndSettle();

      // Elle demande un regard...
      expect(find.text(t.enseignant.cahier.exceptions), findsOneWidget);
      expect(find.text(t.enseignant.cahier.uneException), findsOneWidget);
      expect(find.text(t.enseignant.cahier.toutEstNominal), findsNothing);
      // ... et elle se dit « inconnu », jamais « absence » : invariant J3. Ne pas
      // savoir ne compte ni pour le suivi ni pour la paie, une absence compte
      // pour les deux.
      expect(find.text(t.presence.inconnu), findsOneWidget);
      expect(find.text(t.presence.absente), findsNothing);
    });

    testWidgets('une exception signalee part dans le cahier avec son motif', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon(
          participants: <ParticipantBrouillon>[
            _participant(presence: EtatPresence.absente),
          ],
        );

      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: _surcharges(service: service, depot: FauxDepotRapports()),
        ),
      );
      await tester.pumpAndSettle();

      // La feuille de reglage de l'eleve.
      await tester.tap(find.text('Khadija'));
      await tester.pumpAndSettle();

      // C'est le panneau partage `PresenceCorrectionPanneau` qui est branche
      // ici, avec sa regle de motif obligatoire : le cahier ne redessine pas une
      // feuille de correction.
      await tester.ensureVisible(
        find.text(t.enseignant.cahier.exceptionCorriger),
      );
      await tester.tap(find.text(t.enseignant.cahier.exceptionCorriger));
      await tester.pumpAndSettle();

      // FORM-L1 : le motif se choisit en puces ; sans motif, Valider dit ce
      // qui manque et rien ne part (bouton jamais grise, K-56).
      await tester.tap(find.text(t.commun.valider));
      await tester.pumpAndSettle();
      expect(find.text(t.formulaire.motif.manque), findsOneWidget);
      expect(find.text(t.enseignant.cahier.exceptionSucces), findsNothing);

      // Un motif propre a cette seance : « Autre », puis le texte.
      await tester.ensureVisible(find.byKey(SelecteurMotif.cleAutre));
      await tester.tap(find.byKey(SelecteurMotif.cleAutre));
      await tester.pumpAndSettle();
      final Finder champMotif = find.descendant(
        of: find.ancestor(
          of: find.text(t.enseignant.cahier.exceptionMotif),
          matching: find.byType(ZoneSaisie),
        ),
        matching: find.byType(TextField),
      );
      await tester.enterText(champMotif, 'connexion coupee des le debut');
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.commun.valider));
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.cahier.exceptionSucces), findsOneWidget);

      await tester.ensureVisible(find.text(t.enseignant.cahier.ajusterValider));
      await tester.tap(find.text(t.enseignant.cahier.ajusterValider));
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.cahier.exceptionConsignee), findsOneWidget);

      await _valider(tester);
      await tester.pumpAndSettle();

      final Map<String, dynamic> decision = _decisionsEnvoyees(
        service.cahiersDeposes.single.contenu,
      )['e1']!;
      expect(decision['confirme'], isFalse);
      expect(decision['motif_exception'], 'connexion coupee des le debut');
    });

    testWidgets('le code technique du curriculum n est jamais un titre', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon(
          participants: <ParticipantBrouillon>[
            _participant(
              unite: const UniteCurriculum(
                niveauId: 'n1',
                nomHumain: 'Les points de sortie du sin',
                codeTechnique: 'F1-PHO-01',
                cycle: 'fondation',
                ordre: 1,
              ),
            ),
          ],
        );

      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: _surcharges(service: service, depot: FauxDepotRapports()),
        ),
      );
      await tester.pumpAndSettle();
      // EN-12 : la ligne ne montre que le nom humain ; le code est dans la
      // feuille « Ajuster ».
      expect(find.text('F1-PHO-01'), findsNothing);
      await tester.tap(find.text('Les points de sortie du sin'));
      await tester.pumpAndSettle();

      final TextTheme textes = Theme.of(tester.element(find.text('F1-PHO-01')))
          .textTheme;
      final Text code = tester.widget<Text>(find.text('F1-PHO-01'));
      final Text nom = tester.widget<Text>(
        find.text('Les points de sortie du sin').last,
      );
      // Le nom humain porte le titre, le code reste un sous-texte : sa taille
      // est celle du petit corps de texte, jamais celle du nom. Interdiction UX
      // explicite de `0020_programme_pedagogique.sql`.
      expect(textes.bodySmall?.fontSize, isNotNull);
      expect(code.style?.fontSize, textes.bodySmall?.fontSize);
      expect(nom.style?.fontSize, textes.bodyMedium?.fontSize);
    });
  });

  group('ENS-04 : hors ligne et idempotence', () {
    testWidgets(
      'sans reseau, le cahier est mis en file et ne bloque personne',
      (WidgetTester tester) async {
        _telephone(tester);
        final FauxServiceEnseignant service = FauxServiceEnseignant()
          ..brouillonRendu = _brouillon()
          // Le serveur est injoignable : c'est exactement ce qui arrive hors
          // ligne, et le depot doit rester local.
          ..erreurDepot = Exception('reseau');
        final FauxDepotRapports depot = FauxDepotRapports();

        await tester.pumpWidget(
          hote(
            const CahierPage(seanceId: _seance),
            surcharges: _surcharges(
              service: service,
              depot: depot,
              horsLigne: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _valider(tester);
        await tester.pumpAndSettle();

        // Le cahier porte une cle, et il attend dans la file locale.
        expect(depot.cles, hasLength(1));
        expect(service.cahiersDeposes, isEmpty);
        // L'ecran le dit, et il ne retient pas l'enseignant : le retour a la
        // journee est la, tout de suite.
        // Jamais « Cahier enregistre » tant que le serveur n'a pas confirme
        // (doc 04 §20.7 et §20.8).
        expect(find.text(t.enseignant.cahier.enFileTitre), findsOneWidget);
        expect(find.text(t.enseignant.cahier.enFileDetail), findsOneWidget);
        expect(find.text(t.enseignant.cahier.depose), findsNothing);
        expect(find.text(t.enseignant.cahier.retourJournee), findsOneWidget);
      },
    );

    test('le rejeu envoie la cle de la redaction, et une seule fois', () async {
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..erreurDepot = Exception('reseau');
      final FauxDepotRapports depot = FauxDepotRapports();
      final ProviderContainer conteneur = ProviderContainer(
        overrides: _surcharges(service: service, depot: depot),
      );
      addTearDown(conteneur.dispose);

      final SoumissionCahier soumission = conteneur.read(
        soumissionCahierProvider,
      );
      final SortCahier premier = await soumission.soumettre(
        const CahierARendre(
          seanceId: _seance,
          decisions: <DecisionEleve>[DecisionEleve(studentId: 'e1')],
        ),
      );
      expect(premier, SortCahier.enFile);
      final List<String> clesEnFile = depot.cles;
      expect(clesEnFile, hasLength(1));

      // Le reseau revient.
      service.erreurDepot = null;
      expect(await soumission.rejouer(), 1);

      // La cle envoyee est celle de la REDACTION, pas une nouvelle : c'est elle
      // qui permet a la contrainte d'unicite de `lesson_reports` de refuser un
      // doublon.
      expect(service.cahiersDeposes.single.cle, clesEnFile.single);

      // Et un second rejeu n'ecrit pas une seconde fois : la file est vide.
      expect(await soumission.rejouer(), 0);
      expect(service.cahiersDeposes, hasLength(1));
      expect(depot.cles, isEmpty);
    });

    test('le contenu envoye porte sa version de schema', () async {
      final FauxServiceEnseignant service = FauxServiceEnseignant();
      final FauxDepotRapports depot = FauxDepotRapports();
      final ProviderContainer conteneur = ProviderContainer(
        overrides: _surcharges(service: service, depot: depot),
      );
      addTearDown(conteneur.dispose);

      await conteneur
          .read(soumissionCahierProvider)
          .soumettre(
            const CahierARendre(
              seanceId: _seance,
              decisions: <DecisionEleve>[DecisionEleve(studentId: 'e1')],
              noteGroupe: '  ',
            ),
          );

      final Map<String, dynamic> contenu =
          service.cahiersDeposes.single.contenu;
      // Sans version, le premier changement de format rendrait illisibles les
      // cahiers deja en file.
      expect(contenu['version'], 1);
      expect(contenu['session_id'], _seance);
      // Une note faite d'espaces n'est pas une note : rien ne part.
      expect(contenu.containsKey('note_groupe'), isFalse);
    });
  });

  group('ENS-04 : les six etats', () {
    testWidgets('chargement : un squelette, jamais un rond qui tourne', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon()
        // Sans delai, le faux resout son futur dans la micro-tache que le
        // premier `pump` vide, et l'etat de chargement n'existe jamais.
        ..delai = const Duration(milliseconds: 50);

      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: _surcharges(service: service, depot: FauxDepotRapports()),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(t.enseignant.cahier.valider), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text(t.enseignant.cahier.valider), findsOneWidget);
    });

    testWidgets('erreur : la phrase, Reessayer, et le depot reste possible', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..erreurLecture = Exception('table absente');

      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: _surcharges(service: service, depot: FauxDepotRapports()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.cahier.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      // Un cahier tardif vaut mieux qu'un cahier perdu : la validation reste
      // offerte, et son libelle dit qu'elle part sans constat.
      expect(find.text(t.enseignant.cahier.validerSansConstat), findsOneWidget);
    });

    testWidgets('vide : le constat n a pas pu etre deduit, et on le dit', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      // La lecture aboutit et ne rend rien : ce n'est pas une panne, et l'ecran
      // ne presente pas un formulaire vide comme si c'etait normal.
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon(
          participants: const <ParticipantBrouillon>[],
        );

      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: _surcharges(service: service, depot: FauxDepotRapports()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.cahier.vide), findsOneWidget);
      expect(find.text(t.enseignant.cahier.erreur), findsNothing);
      expect(find.text(t.enseignant.cahier.validerSansConstat), findsOneWidget);
    });

    testWidgets(
      'deja depose : le cahier se lit, et se corrige sans redepot direct',
      (WidgetTester tester) async {
        _telephone(tester);
        final FauxServiceEnseignant service = FauxServiceEnseignant()
          ..brouillonRendu = _brouillon(dejaDepose: true);

        await tester.pumpWidget(
          hote(
            const CahierPage(seanceId: _seance),
            surcharges: _surcharges(
              service: service,
              depot: FauxDepotRapports(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(t.enseignant.cahier.dejaDepose), findsOneWidget);
        // Aucun second depot n'est propose : la cle rend le doublon inoffensif,
        // mais l'ecran n'a pas a le provoquer.
        expect(find.text(t.enseignant.cahier.valider), findsNothing);
        expect(find.text(t.enseignant.cahier.validerSansConstat), findsNothing);
        // Il reste corrigeable (K-45, point 5).
        expect(find.text(t.enseignant.cahier.corriger), findsOneWidget);
        expect(find.text(t.enseignant.cahier.retourJournee), findsOneWidget);
        // Et il se lit : la presence de l'eleve est toujours la.
        expect(find.text('Khadija'), findsOneWidget);
      },
    );
  });

  group('ENS-04 : mobile a 390 x 844', () {
    testWidgets('cinq eleves et 200 % de taille de texte : rien ne debonde', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon(
          participants: <ParticipantBrouillon>[
            _participant(prenom: 'Khadija'),
            _participant(id: 'e2', prenom: 'Bilal'),
            _participant(
              id: 'e3',
              prenom: 'Aisha',
              presence: EtatPresence.inconnu,
            ),
            _participant(
              id: 'e4',
              prenom: 'Youssouf',
              presence: EtatPresence.enRetard,
            ),
            _participant(id: 'e5', prenom: 'Maryam'),
          ],
        );

      await tester.pumpWidget(
        hote(
          Builder(
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: const CahierPage(seanceId: _seance),
            ),
          ),
          surcharges: _surcharges(service: service, depot: FauxDepotRapports()),
        ),
      );
      await tester.pumpAndSettle();

      // Un depassement de mise en page leve une exception de rendu : ce test
      // echouerait de lui-meme. Ce qui se verifie ici en plus, c'est que le
      // bouton du bas reste atteignable sans defilement horizontal, et que les
      // deux exceptions sont bien remontees devant.
      expect(tester.takeException(), isNull);
      expect(find.text(t.enseignant.cahier.valider), findsOneWidget);
      expect(
        find.text(t.enseignant.cahier.plusieursExceptions(nombre: 2)),
        findsOneWidget,
      );
    });
  });

  group('ENS-04 : K-45 (reprise, integrite, correction)', () {
    testWidgets('sans reprise, rien ne part : un message calme, le champ', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon(
          participants: <ParticipantBrouillon>[_participant(lu: false)],
        );

      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: _surcharges(service: service, depot: FauxDepotRapports()),
        ),
      );
      await tester.pumpAndSettle();

      // Aucune position commune : aucune proposition, le champ est vide.
      await _valider(tester);
      expect(service.cahiersDeposes, isEmpty);
      expect(find.text(t.enseignant.cahier.repriseRequise), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('cahier-reprise')),
        'Sourate 78, verset 12',
      );
      await tester.pumpAndSettle();
      expect(find.text(t.enseignant.cahier.repriseRequise), findsNothing);
      await _valider(tester);

      expect(service.cahiersDeposes, hasLength(1));
      expect(
        service.cahiersDeposes.single.contenu['position_reprise'],
        'Sourate 78, verset 12',
      );
    });

    testWidgets('la reprise commune est proposee, et part avec le cahier', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon();

      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: _surcharges(service: service, depot: FauxDepotRapports()),
        ),
      );
      await tester.pumpAndSettle();
      await _valider(tester);

      expect(
        service.cahiersDeposes.single.contenu['position_reprise'],
        t.enseignant.cahier.repriseProposee(sourate: '2', verset: '5'),
      );
    });

    testWidgets('la phrase d integrite est au-dessus du bouton, mot pour mot', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon();

      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: _surcharges(service: service, depot: FauxDepotRapports()),
        ),
      );
      await tester.pumpAndSettle();

      final Finder phrase = find.text(
        'Ce que vous écrivez ici engage votre parole. Les hommes ne peuvent '
        'pas le vérifier, mais Allah voit tout.',
      );
      expect(phrase, findsOneWidget);
      final Finder bouton = find.byKey(
        const ValueKey<String>('cahier-valider'),
      );
      expect(
        tester.getBottomLeft(phrase).dy,
        lessThan(tester.getTopLeft(bouton).dy),
      );
      // Ni IA, ni jugement d'absence, ni document, ni brouillon (planche 4).
      expect(find.textContaining('IA'), findsNothing);
      expect(find.textContaining('Justifi'), findsNothing);
      expect(find.textContaining('Ajouter un document'), findsNothing);
      expect(find.textContaining('brouillon'), findsNothing);
    });

    testWidgets('apres validation, le cahier se corrige : Corrige le ...', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon();

      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: <Override>[
            ..._surcharges(service: service, depot: FauxDepotRapports()),
            horlogeCahierProvider.overrideWithValue(
              () => DateTime(2026, 9, 28, 16),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await _valider(tester);
      expect(find.text(t.enseignant.cahier.depose), findsOneWidget);

      await tester.tap(find.text(t.enseignant.cahier.corriger));
      await tester.pumpAndSettle();
      await _valider(tester);

      expect(service.cahiersDeposes, hasLength(2));
      expect(find.text(t.enseignant.cahier.depose), findsOneWidget);
      expect(find.text('Corrigé le lundi 28 septembre'), findsOneWidget);
    });
  });

  group('ENS-04 : EN-7b (suite par eleve, doc 04 §20.4)', () {
    Future<void> monter(WidgetTester tester, FauxServiceEnseignant s) async {
      _telephone(tester);
      await tester.pumpWidget(
        hote(
          const CahierPage(seanceId: _seance),
          surcharges: _surcharges(service: s, depot: FauxDepotRapports()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khadija'));
      await tester.pumpAndSettle();
    }

    testWidgets('Suspendre le nouveau, tape, part dans le cahier', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon();
      await monter(tester, service);

      final Finder suspendre = find.byKey(
        const ValueKey<String>('cahier-suite-suspendre'),
      );
      await tester.ensureVisible(suspendre);
      await tester.pumpAndSettle();
      await tester.tap(suspendre);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(t.enseignant.cahier.ajusterValider));
      await tester.tap(find.text(t.enseignant.cahier.ajusterValider));
      await tester.pumpAndSettle();
      await _valider(tester);

      final Map<String, dynamic> decision = _decisionsEnvoyees(
        service.cahiersDeposes.single.contenu,
      )['e1']!;
      expect(decision['suite'], 'suspendreNouveau');
      expect(decision['nouveau_suspendu'], isTrue);
    });

    testWidgets('sans permission academique, Suspendre n est pas propose', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnseignant service = FauxServiceEnseignant()
        ..brouillonRendu = _brouillon(
          participants: <ParticipantBrouillon>[
            _participant(suspensionPermise: false),
          ],
        );
      await monter(tester, service);

      expect(
        find.byKey(const ValueKey<String>('cahier-suite-continuer')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('cahier-suite-suspendre')),
        findsNothing,
      );
    });

    test('Continuer par defaut ne part pas dans le contenu', () {
      const DecisionEleve d = DecisionEleve(studentId: 'e1');
      expect(d.versJson().containsKey('suite'), isFalse);
      expect(d.nouveauSuspendu, isFalse);
      expect(
        const DecisionEleve(
          studentId: 'e1',
          suite: SuiteEleve.renforcer,
        ).versJson()['suite'],
        'renforcer',
      );
    });
  });
}
