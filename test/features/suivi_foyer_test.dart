import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/suivi_foyer/suivi_foyer_page.dart';

import '../support/harnais.dart';

/// Une fenetre haute, et large ou etroite selon ce qu'on mesure.
///
/// **Haute** parce que la fenetre par defaut de `flutter_test` fait 800 x 600,
/// gabarit tablette plus court que tout telephone : ce qui depasse n'est
/// simplement pas construit. **La largeur est un sujet** comme a `CTR-01` : au
/// dela de 1024 le suivi rend un tableau dense, en dessous une carte par cours.
void _fenetre(WidgetTester tester, {double largeur = 1400}) {
  tester.view.physicalSize = Size(largeur, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Le 13 septembre 2026 a 10h30, fige.
final DateTime _maintenant = DateTime(2026, 9, 13, 10, 30);

Seance _seance({
  required String id,
  required int ilYAMinutes,
  StatutSeance? statut = StatutSeance.terminee,
  String eleveId = 'enf-1',
  String elevePrenom = 'Sofia',
  String enseignantPrenom = 'Rachid',
}) {
  final DateTime debut = _maintenant.subtract(Duration(minutes: ilYAMinutes));
  return Seance(
    id: id,
    debut: debut,
    fin: debut.add(const Duration(minutes: 60)),
    statut: statut,
    eleveId: eleveId,
    elevePrenom: elevePrenom,
    eleveIdentifiant: 'STUD-000001',
    enseignantId: 'ens-1',
    enseignantPrenom: enseignantPrenom,
    enseignantIdentifiant: 'TEACH-000001',
  );
}

PresenceParticipant _presence({
  required String seanceId,
  required String profilId,
  EtatPresence etat = EtatPresence.absente,
}) => PresenceParticipant(
  seanceId: seanceId,
  profilId: profilId,
  role: 'student',
  prenom: 'Sofia',
  identifiantImmuable: 'STUD-000001',
  etat: etat,
  consolide: false,
);

Future<void> _monter(WidgetTester tester, FauxServiceSuivi suivi) async {
  await tester.pumpWidget(
    hote(
      SuiviFoyerPage(horloge: () => _maintenant),
      surcharges: <Override>[serviceSuiviProvider.overrideWithValue(suivi)],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TUT-06 : ce que le parent lit du cours', () {
    testWidgets('la date, l\'enfant, l\'enseignant et l\'etat', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[_seance(id: 'a', ilYAMinutes: 90)],
          presencesRendues: <PresenceParticipant>[
            _presence(
              seanceId: 'a',
              profilId: 'enf-1',
              etat: EtatPresence.finalisee,
            ),
          ],
        ),
      );

      expect(find.text(t.tuteur.suivi.aujourdhui(heure: '09:00')), findsOneWidget);
      expect(find.text('Sofia'), findsOneWidget);
      // Prenom ET identifiant immuable de l'enseignant, jamais son nom de
      // famille (ADR-008) : c'est ce qui permet de le nommer sans ambiguite
      // dans une demande de reaffectation.
      expect(find.text('Rachid · TEACH-000001'), findsOneWidget);
      expect(find.text(t.presence.finalisee), findsOneWidget);
    });

    testWidgets('hier se dit « Hier », avant-hier se date', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[
            // 24 h et 30 min en arriere : le 12 septembre a 10h00.
            _seance(id: 'hier', ilYAMinutes: 1470),
            // Trois jours en arriere : le 10 septembre a 10h30.
            _seance(id: 'avant', ilYAMinutes: 4320),
          ],
        ),
      );

      expect(find.text(t.tuteur.suivi.hier(heure: '10:00')), findsOneWidget);
      expect(
        find.text(t.tuteur.suivi.date(date: '10/09/2026', heure: '10:30')),
        findsOneWidget,
      );
    });

    testWidgets('l\'ecran ne propose AUCUNE action : il se lit', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[_seance(id: 'a', ilYAMinutes: 90)],
          presencesRendues: <PresenceParticipant>[
            _presence(seanceId: 'a', profilId: 'enf-1'),
          ],
        ),
      );

      // Corriger un etat, excuser une absence : ce sont deux gestes de
      // l'enseignant et de l'administration, avec motif et entree de journal
      // (section 6.5). Un bouton ici donnerait au foyer le droit de corriger ce
      // qui compte pour la paie de l'enseignant.
      expect(find.byType(ActionPrincipale), findsNothing);
    });
  });

  group('TUT-06 : le sort du cours prime sur l\'etat de l\'enfant', () {
    testWidgets('un cours annule ne dit jamais « Absence »', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[
            _seance(id: 'a', ilYAMinutes: 90, statut: StatutSeance.annulee),
          ],
          presencesRendues: <PresenceParticipant>[
            _presence(seanceId: 'a', profilId: 'enf-1'),
          ],
        ),
      );

      expect(find.text(t.tuteur.suivi.annule), findsOneWidget);
      expect(find.text(t.presence.absente), findsNothing);
    });

    testWidgets('un enseignant absent se dit « Cours non tenu »', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[
            _seance(
              id: 'a',
              ilYAMinutes: 90,
              statut: StatutSeance.enseignantAbsent,
            ),
          ],
          presencesRendues: <PresenceParticipant>[
            _presence(seanceId: 'a', profilId: 'enf-1'),
          ],
        ),
      );

      expect(find.text(t.tuteur.suivi.nonTenu), findsOneWidget);
      expect(find.text(t.presence.absente), findsNothing);
    });

    testWidgets('une absence de l\'eleve, elle, se dit', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[
            _seance(id: 'a', ilYAMinutes: 90, statut: StatutSeance.eleveAbsent),
          ],
          presencesRendues: <PresenceParticipant>[
            _presence(seanceId: 'a', profilId: 'enf-1'),
          ],
        ),
      );

      expect(find.text(t.presence.absente), findsOneWidget);
    });
  });

  group('TUT-06 : une presence indisponible n\'efface pas l\'historique', () {
    testWidgets('les cours restent lisibles, les etats disent inconnu', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[_seance(id: 'a', ilYAMinutes: 90)],
          presencesRendues: null,
        ),
      );

      expect(find.text('Rachid · TEACH-000001'), findsOneWidget);
      // Invariant J3 : ne pas savoir ne compte pour rien, une absence compte
      // pour le suivi et pour la paie.
      expect(find.text(t.presence.inconnu), findsOneWidget);
      expect(find.text(t.presence.absente), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
    });
  });

  group('TUT-06 : deux rendus, trois etats vides', () {
    testWidgets('le tableau dense sort au desktop, pas au telephone', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[_seance(id: 'a', ilYAMinutes: 90)],
        ),
      );

      // L'en-tete de colonnes n'existe qu'en rendu tableau.
      expect(find.text(t.tuteur.suivi.colonneEnseignant), findsOneWidget);

      _fenetre(tester, largeur: 390);
      await tester.pumpAndSettle();

      expect(find.text(t.tuteur.suivi.colonneEnseignant), findsNothing);
      // En carte, les colonnes secondaires se rejoignent sur une seule ligne,
      // separees par un point median : c'est la regle de transformation de
      // `05-regles-responsive.md` section 4, et le libelle de l'enseignant y est
      // donc contenu, pas isole.
      expect(
        find.textContaining('Rachid · TEACH-000001'),
        findsOneWidget,
      );
    });

    testWidgets('un foyer sans cours n\'est pas une panne, et n\'offre rien', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(tester, FauxServiceSuivi());

      expect(find.text(t.tuteur.suivi.vide), findsOneWidget);
      // Aucun bouton : l'attribution d'un enseignant se decide ailleurs, et le
      // foyer n'a rien a faire pour l'obtenir.
      expect(find.byType(ActionPrincipale), findsNothing);
    });

    testWidgets('presser deux fois la meme pilule relache le filtre', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[
            _seance(id: 'a', ilYAMinutes: 90),
            _seance(
              id: 'b',
              ilYAMinutes: 180,
              eleveId: 'enf-2',
              elevePrenom: 'Ines',
              enseignantPrenom: 'Hafsa',
            ),
          ],
        ),
      );

      // L'enseignant sert de temoin, jamais le prenom de l'enfant : celui-ci
      // est aussi le libelle de sa pilule, et le finder trouverait la pilule.
      await tester.tap(find.widgetWithText(FilterPill, 'Ines'));
      await tester.pumpAndSettle();

      expect(find.text('Rachid · TEACH-000001'), findsNothing);

      await tester.tap(find.widgetWithText(FilterPill, 'Ines'));
      await tester.pumpAndSettle();

      expect(find.text('Rachid · TEACH-000001'), findsOneWidget);
    });

    testWidgets('une lecture impossible se dit et se reessaie', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceSuivi suivi = FauxServiceSuivi()
        ..erreurAJeter = StateError('reseau');
      await _monter(tester, suivi);

      expect(find.text(t.tuteur.suivi.erreur), findsOneWidget);

      suivi
        ..erreurAJeter = null
        ..seancesRendues = <Seance>[_seance(id: 'a', ilYAMinutes: 90)];
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();

      expect(find.text('Rachid · TEACH-000001'), findsOneWidget);
    });

    testWidgets('le squelette precede la premiere lecture', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      // Le faux prend son temps : sans delai, il repond dans la micro-tache
      // suivante et l'ecran n'est jamais en chargement pendant une frame.
      final FauxServiceSuivi suivi = FauxServiceSuivi()
        ..delai = const Duration(milliseconds: 50);
      await tester.pumpWidget(
        hote(
          SuiviFoyerPage(horloge: () => _maintenant),
          surcharges: <Override>[serviceSuiviProvider.overrideWithValue(suivi)],
        ),
      );
      // Une seule frame : la lecture n'a pas encore rendu la main.
      await tester.pump();

      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);

      await tester.pumpAndSettle();
    });
  });

  group('TUT-06 : le filtre par enfant', () {
    testWidgets('la rangee n\'apparait qu\'a partir de deux enfants', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[_seance(id: 'a', ilYAMinutes: 90)],
        ),
      );

      // Un seul enfant au suivi : proposer « tous les enfants » serait un
      // filtre sans choix.
      expect(find.text(t.tuteur.suivi.tousLesEnfants), findsNothing);
    });

    testWidgets('retenir un enfant ne retient que ses cours', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(
        tester,
        FauxServiceSuivi(
          seancesRendues: <Seance>[
            _seance(id: 'a', ilYAMinutes: 90),
            _seance(
              id: 'b',
              ilYAMinutes: 180,
              eleveId: 'enf-2',
              elevePrenom: 'Ines',
              enseignantPrenom: 'Hafsa',
            ),
          ],
        ),
      );

      expect(find.text(t.tuteur.suivi.tousLesEnfants), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterPill, 'Ines'));
      await tester.pumpAndSettle();

      expect(find.text('Hafsa · TEACH-000001'), findsOneWidget);
      expect(find.text('Rachid · TEACH-000001'), findsNothing);
    });
  });
}
