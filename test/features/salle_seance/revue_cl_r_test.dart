// Retours de la revue croisee CL-R : fiche depliee par identifiant, clavier
// des panneaux (Echap, retour du focus, etat « selectionne ») et liste des
// eleves reservee a l'enseignant dans l'adaptateur `/salle`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_salle.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';
import '../../teaching_core/e/faux/faux_classe.dart';

void _rien() {}
void _eleve(EleveSeance _) {}

FicheEleveSeance _fiche(String niveau) => FicheEleveSeance(
  niveau: niveau,
  objectifActuel: 'Objectif',
  derniereSeance: 'Hier',
  aReprendre: 'Rien',
  presenceRecente: '3/3',
  travailActuel: 'Lecture',
);

/// Une salle d'enseignant dont Eleves et Supports basculent vraiment.
class _Hote extends StatefulWidget {
  const _Hote();

  @override
  State<_Hote> createState() => _HoteState();
}

class _HoteState extends State<_Hote> {
  PanneauOuvert _panneau = PanneauOuvert.aucun;

  void _basculer(PanneauOuvert p) =>
      setState(() => _panneau = _panneau == p ? PanneauOuvert.aucun : p);

  @override
  Widget build(BuildContext context) => SalleSeance(
    vue: DonneesSeanceDemo.vue(
      RoleSeance.enseignant,
      EtatDemoSalle.eleves,
    ).copyWith(panneau: _panneau),
    actions: ActionsSeance(
      onRetour: _rien,
      onQuitter: _rien,
      onMicro: _rien,
      onCamera: _rien,
      onEleves: () => _basculer(PanneauOuvert.eleves),
      onSupports: () => _basculer(PanneauOuvert.supports),
      onCommandes: () => _basculer(PanneauOuvert.commandes),
      onRappeler: _eleve,
      onChoisirPourReciter: _eleve,
      onNoter: _eleve,
      onSignaler: _eleve,
    ),
  );
}

Future<void> _monterSalle(WidgetTester tester, Size taille) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(hoteCapture(const _Hote()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

String? _focus() => FocusManager.instance.primaryFocus?.debugLabel;

void main() {
  group('Panneau Eleves : fiche depliee par identifiant', () {
    testWidgets('deux « Amine » : deplier l\'un ne deplie pas l\'autre', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(640, 1000), 1);
      await tester.pumpWidget(
        hoteCapture(
          SizedBox(
            height: 900,
            child: PanneauEleves(
              eleves: <EleveSeance>[
                EleveSeance(
                  id: 'a1',
                  prenom: 'Amine',
                  statut: StatutEleveSeance.connecte,
                  fiche: _fiche('Niveau A1'),
                ),
                EleveSeance(
                  id: 'a2',
                  prenom: 'Amine',
                  statut: StatutEleveSeance.connecte,
                  fiche: _fiche('Niveau A2'),
                ),
              ],
              actions: const ActionsSeance(onRetour: _rien, onQuitter: _rien),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final Finder premier = find.byKey(const ValueKey<String>('eleve-a1'));
      final Finder second = find.byKey(const ValueKey<String>('eleve-a2'));
      expect(premier, findsOneWidget);
      expect(second, findsOneWidget);
      // Au depart : seul le premier est deplie.
      expect(find.text('Niveau A1'), findsOneWidget);
      expect(find.text('Niveau A2'), findsNothing);

      await tester.tap(
        find.descendant(of: second, matching: find.byType(Pressable)).first,
      );
      await tester.pump();
      expect(find.text('Niveau A2'), findsOneWidget);
      expect(find.text('Niveau A1'), findsNothing);
    });
  });

  group('Panneaux Eleves et Supports : clavier', () {
    // EN-9 : sur bureau, le panneau Eleves reste ouvert a droite du support ;
    // Echap ne le ferme donc qu'en web etroit.
    for (final MapEntry<String, Size> taille in <String, Size>{
      'web etroit': const Size(640, 1000),
    }.entries) {
      testWidgets('Echap ferme le panneau, le focus revient au bouton '
          '(${taille.key})', (WidgetTester tester) async {
        await _monterSalle(tester, taille.value);
        await tester.tap(find.byKey(const ValueKey<String>('bouton-eleves')));
        await tester.pump();
        expect(find.byType(PanneauEleves), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(PanneauSeance), findsNothing);
        expect(_focus(), 'bouton-eleves');
      });
    }

    testWidgets('la croix ferme Supports et rend le focus aux Commandes', (
      WidgetTester tester,
    ) async {
      // TB-4 : la Bibliotheque s'ouvre depuis les Commandes ; sa fermeture
      // rend le focus au declencheur.
      await _monterSalle(tester, const Size(640, 1000));
      await tester.tap(
        find.byKey(const ValueKey<String>('declencheur-commandes')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('commandes-bibliotheque')),
      );
      await tester.pump();
      expect(find.byType(PanneauSeance), findsOneWidget);

      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Pressable &&
              w.libelleSemantique == t.salle.seance.fermerPanneau,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(PanneauSeance), findsNothing);
      expect(_focus(), 'declencheur-commandes');
    });

    testWidgets('le bouton du panneau ouvert se dit selectionne', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      await _monterSalle(tester, const Size(1440, 900));
      // EN-9 : sur bureau, Eleves est ouvert d'office ; TB-4 : on ouvre
      // les Commandes.
      final Finder commandes = find.byKey(
        const ValueKey<String>('declencheur-commandes'),
      );
      expect(
        tester.getSemantics(commandes),
        isNot(isSemantics(isSelected: true)),
      );
      await tester.tap(commandes);
      await tester.pump();
      // Revue du 09/10 (TB-5) : ouvertes, les Commandes remplacent leur
      // declencheur (une seule entree « Commandes » visible) ; le panneau se
      // dit par son titre et se ferme par sa « Reduire ».
      expect(commandes, findsNothing);
      expect(find.byKey(CommandesPedagogiques.cle), findsOneWidget);
      expect(
        find.bySemanticsLabel(t.salle.seance.commandes.titre),
        findsWidgets,
      );
      semantique.dispose();
    });
  });

  group('DepuisSalle : liste des eleves', () {
    List<PresenceParticipant> inscrits() => <PresenceParticipant>[
      presenceDe(profilId: 'p1', prenom: 'Mariam', identifiant: 'RA-Mariam'),
      presenceDe(profilId: 'p2', prenom: 'Yusuf', identifiant: 'RA-Yusuf'),
      presenceDe(
        profilId: 't1',
        prenom: 'Amina',
        role: 'teacher',
        identifiant: 'RA-Amina',
      ),
    ];

    VueSeance? vue(String role) => DepuisSalle.vue(
      salle: VueSalle.depuis(
        materielPret: true,
        acces: accesDe(role),
        etatMoteur: EtatSalle.connecte,
        participants: const <ParticipantSalle>[],
        qualite: QualiteLien.inconnue,
      ),
      mode: InterfaceMode.standard,
      presence: inscrits(),
      monProfil: 'p1',
    );

    test('enseignant : les inscrits eleves', () {
      expect(vue('teacher')!.eleves.map((EleveSeance e) => e.prenom), <String>[
        'Mariam',
        'Yusuf',
      ]);
    });

    test('eleve : jamais la liste de ses camarades', () {
      final VueSeance? v = vue('student');
      expect(v, isNotNull);
      expect(v!.role, isNot(RoleSeance.enseignant));
      expect(v.eleves, isEmpty);
    });
  });
}
