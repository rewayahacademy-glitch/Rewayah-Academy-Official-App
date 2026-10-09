import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/age_eleve.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/tc_classe/port_rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/session_live_vm.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/tc_classe_live/classe_live_page.dart';
import 'package:rewayah_academy/features/tc_classe_live/roster_classe.dart';
import 'package:rewayah_academy/features/tc_classe_live/scene_classe.dart';
import 'package:rewayah_academy/features/tc_observation_ui/indicateur_observation.dart';

import 'faux/faux_classe.dart';
import 'support/hote_classe.dart';

/// Le port de l'age fixe (MA-TUTOIEMENT-1).
class _AgeFixe implements PortAgeEleve {
  const _AgeFixe(this.age);

  final AgeEleve age;

  @override
  AgeEleve ageDeLEleve() => age;
}

/// La Classe Live montee pour de vrai, aux trois gabarits.
///
/// **Sans SDK, sans reseau, sans compte LiveKit** : le faux moteur rejoue ce que
/// le vrai publie, et c'est tout ce dont cet ecran depend.
void main() {
  const String seance = 's1';

  TeacherStudentProjection fiche(String prenom, {String? niveau}) =>
      TeacherStudentProjection(
        firstName: prenom,
        academyId: 'RA-$prenom',
        level: niveau,
        liveStatus: EtatPresenceProjete.inconnu,
        interfaceGuidee: false,
      );

  ContexteClasseLive contexte({
    String? support,
    WidgetBuilder? bibliotheque,
    WidgetBuilder? dock,
    int? seuilMax,
  }) => ContexteClasseLive(
    sessionId: seance,
    groupeId: 'g1',
    libelleGroupe: 'Classe Al-Fatiha',
    enseignant: const EnseignantDeClasse(
      nomAffichage: 'Youssouf',
      titre: TitreEnseignant.sayyid,
      photoCleOuUrl: 'https://exemple.invalid/photo.jpg',
    ),
    supportActifId: support,
    support: support == null
        ? null
        : (BuildContext _) => const Text('support presente'),
    bibliotheque: bibliotheque,
    dock: dock,
    seuilMax: seuilMax,
  );

  List<PresenceParticipant> troisEleves() => <PresenceParticipant>[
    presenceDe(profilId: 'p1', prenom: 'Amina', identifiant: 'RA-Amina'),
    presenceDe(
      profilId: 'p2',
      prenom: 'Ilyas',
      identifiant: 'RA-Ilyas',
      etat: EtatPresence.enAttente,
    ),
    presenceDe(profilId: 'p3', prenom: 'Mariam', identifiant: 'RA-Mariam'),
    presenceDe(
      profilId: 't1',
      prenom: 'Youssouf',
      role: 'teacher',
      identifiant: 'RA-Youssouf',
    ),
  ];

  ({
    FauxMoteurClasse moteur,
    FauxServiceVideoClasse video,
    FauxPreVolClasse preVol,
    FauxRappelDiscret rappel,
    FauxAnnonceObservation annonces,
    FauxAnnonceObservationEnfant annonceEnfant,
    List<Override> surcharges,
    List<String> journal,
  })
  banc({
    String role = 'teacher',
    List<PresenceParticipant>? presence,
    List<TeacherStudentProjection>? fiches,
    EchecRappel? echecRappel,
    List<AnnonceObservation> annonces = const <AnnonceObservation>[],
    bool monTuteurObserve = false,
  }) {
    final List<String> journal = <String>[];
    final FauxAnnonceObservation annonceur = FauxAnnonceObservation(
      lignes: annonces,
    );
    final FauxAnnonceObservationEnfant annonceurEnfant =
        FauxAnnonceObservationEnfant(observe: monTuteurObserve);
    final FauxMoteurClasse moteur = FauxMoteurClasse(journal: journal);
    final FauxServiceVideoClasse video = FauxServiceVideoClasse(
      acces0: accesDe(role),
      journal: journal,
    );
    final FauxPreVolClasse preVol = FauxPreVolClasse();
    final FauxRappelDiscret rappel = FauxRappelDiscret(echec: echecRappel);
    return (
      moteur: moteur,
      video: video,
      preVol: preVol,
      rappel: rappel,
      annonces: annonceur,
      annonceEnfant: annonceurEnfant,
      journal: journal,
      surcharges: surchargesClasse(
        moteur: moteur,
        video: video,
        preVol: preVol,
        presence: FauxPresenceClasse(lignes: presence),
        roster: FauxRosterEnseignant(
          fiches: fiches ?? const <TeacherStudentProjection>[],
        ),
        rappel: rappel,
        annonces: annonceur,
        annonceEnfant: annonceurEnfant,
      ),
    );
  }

  /// Le compteur du bouton Eleves (salle de seance unique, I-6).
  Finder compteur(int connectes, int inscrits) => find.textContaining(
    t.salle.seance.compteurEleves(connectes: connectes, inscrits: inscrits),
  );

  /// Ouvre le panneau Eleves de la salle de seance.
  Future<void> ouvrirEleves(WidgetTester tester) async {
    await tester.tap(find.textContaining(t.salle.seance.eleves).first);
    await tester.pumpAndSettle();
  }

  group('layout', () {
    testWidgets('bureau, support actif : roster en colonne, support present', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(presence: troisEleves());
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1', seuilMax: 5),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.desktop,
      );

      // La salle de seance unique, celle de `/salle` : aucune seconde salle.
      expect(find.byType(SalleSeance), findsOneWidget);
      expect(find.byType(PanneauRoster), findsNothing);
      expect(find.text('support presente'), findsOneWidget);
      // Le compteur derive du roster (I-6) : deux connectes sur trois.
      expect(compteur(2, 3), findsOneWidget);
      // EN-9 : sur bureau, le panneau Eleves est ouvert d'office a droite
      // du support, sans passer par le bouton.
      expect(find.text('Amina'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('telephone, support actif : roster en feuille', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(presence: troisEleves());
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.mobile,
      );

      expect(find.text('support presente'), findsOneWidget);
      // Replie derriere le bouton Eleves : « Eleves 2/3 ».
      expect(compteur(2, 3), findsOneWidget);
      expect(find.text('Amina'), findsNothing);

      await ouvrirEleves(tester);
      expect(find.text('Amina'), findsOneWidget);
    });

    testWidgets('sans support, la video reprend la place', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(presence: troisEleves());
      await monterClasse(
        tester,
        contexte: contexte(),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.tablette,
      );

      // Rien de partage : la salle le dit, sans support invente.
      expect(find.byType(SceneClasse), findsNothing);
      expect(find.textContaining('Youssouf'), findsWidgets);
      expect(find.text('support presente'), findsNothing);
    });

    testWidgets('un support non branche se dit, il ne laisse pas un blanc', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(presence: troisEleves());
      await monterClasse(
        tester,
        contexte: const ContexteClasseLive(
          sessionId: seance,
          groupeId: 'g1',
          libelleGroupe: 'Classe Al-Fatiha',
          enseignant: EnseignantDeClasse(nomAffichage: 'Youssouf'),
          // Une ressource est designee, mais personne ne la rend encore.
          supportActifId: 'r1',
        ),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.tablette,
      );

      expect(find.text(t.tc.classe.support.aucun), findsOneWidget);
      expect(find.byType(EmptyState), findsWidgets);
    });

    testWidgets('le titre de l enseignant est Sayyid ou Sayyida', (
      WidgetTester tester,
    ) async {
      // Decision D-01 : pas d'avatar generique silencieux.
      final banc0 = banc();
      await monterClasse(
        tester,
        contexte: const ContexteClasseLive(
          sessionId: seance,
          groupeId: 'g1',
          libelleGroupe: 'Classe Al-Fatiha',
          enseignant: EnseignantDeClasse(
            nomAffichage: 'Youssouf',
            titre: TitreEnseignant.sayyida,
          ),
        ),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.tablette,
      );

      // Sayyid / Sayyida, jamais Ustaz (decision D-02) : le compte en haut
      // a droite est celui de la personne devant l'ecran (I-9).
      expect(find.textContaining('Sayyida Youssouf'), findsWidgets);
      expect(find.textContaining('Ustaz'), findsNothing);
    });
  });

  group('roster', () {
    testWidgets('un roster indisponible n est pas un roster vide', (
      WidgetTester tester,
    ) async {
      // La presence rend `null` : c'est l'invariant J3.
      final banc0 = banc();
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.desktop,
      );

      // J3 : un roster illisible ne devient ni un zero ni un « vide ».
      expect(compteur(0, 0), findsNothing);
      expect(find.text(t.tc.classe.roster.vide), findsNothing);
      expect(find.textContaining('bsent'), findsNothing);
    });

    testWidgets('un roster vide le dit autrement', (WidgetTester tester) async {
      final banc0 = banc(presence: <PresenceParticipant>[]);
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.desktop,
      );

      // Lu, et vide : c'est un vrai zero.
      expect(compteur(0, 0), findsOneWidget);
    });

    testWidgets('l eleve ne voit pas la liste de ses camarades', (
      WidgetTester tester,
    ) async {
      // Le jeton decide, pas le compte : `voitLesParticipants` est faux pour un
      // eleve, et c'est une decision de protection des mineurs.
      final banc0 = banc(role: 'student', presence: troisEleves());
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.desktop,
      );

      expect(find.byType(PanneauRoster), findsNothing);
      expect(find.byType(BoutonRoster), findsNothing);
      expect(find.textContaining(t.salle.seance.eleves), findsNothing);
      expect(find.text('Amina'), findsNothing);
    });

    // Matrice des roles : rien de reserve a l'enseignant (Eleves, Supports,
    // outils, Reseau, pagination active) chez l'eleve standard ni la guidee,
    // meme quand le contexte fournit le dock, la Bibliotheque et un support
    // pagine.
    for (final (String nom, InterfaceMode mode) in <(String, InterfaceMode)>[
      ('eleve standard', InterfaceMode.standard),
      ('interface guidee', InterfaceMode.enfant),
    ]) {
      testWidgets('$nom : rien de reserve a l enseignant sur /tc/classe', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle semantique = tester.ensureSemantics();
        final banc0 = banc(role: 'student', presence: troisEleves());
        await monterClasse(
          tester,
          contexte: ContexteClasseLive(
            sessionId: seance,
            groupeId: 'g1',
            libelleGroupe: 'Classe Al-Fatiha',
            enseignant: const EnseignantDeClasse(
              nomAffichage: 'Youssouf',
              titre: TitreEnseignant.sayyid,
            ),
            supportActifId: 'r1',
            descriptionSupport: DonneesSeanceDemo.support,
            support: (BuildContext _) => const Text('support presente'),
            bibliotheque: (BuildContext _) => const Text('bibliotheque'),
            dock: (BuildContext _) => const Text('dock'),
            onNoter: () {},
            onSignaler: () {},
          ),
          surcharges: banc0.surcharges,
          ecran: LargeurEcran.desktop,
          mode: mode,
        );

        expect(find.byType(SalleSeance), findsOneWidget);
        for (final String reserve in <String>[
          t.salle.seance.eleves,
          t.salle.seance.supports,
          t.salle.seance.reseau,
          t.salle.seance.outils.titre,
          t.salle.seance.outils.pointeur,
          t.salle.seance.outils.marquer,
          t.salle.seance.outils.masquer,
          t.salle.seance.outils.annoter,
        ]) {
          expect(find.text(reserve), findsNothing, reason: reserve);
          expect(find.bySemanticsLabel(reserve), findsNothing, reason: reserve);
        }
        expect(
          find.bySemanticsLabel(t.salle.seance.pagePrecedente),
          findsNothing,
        );
        expect(
          find.bySemanticsLabel(t.salle.seance.pageSuivante),
          findsNothing,
        );
        expect(find.text('dock'), findsNothing);
        expect(find.text('bibliotheque'), findsNothing);
        semantique.dispose();
      });
    }

    testWidgets('enseignant, route ouverte directement : chevron et coin', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      final banc0 = banc(role: 'teacher', presence: troisEleves());
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.desktop,
      );

      // Images CLV-06 et CLV-07 : chevron retour, cloche, reglages et menu
      // du compte, meme sans page a depiler (route ouverte par `go`).
      expect(find.bySemanticsLabel(t.salle.seance.retour), findsOneWidget);
      expect(find.bySemanticsLabel(t.salle.seance.reglages), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(t.salle.seance.notifications)),
        findsWidgets,
      );
      semantique.dispose();
    });

    testWidgets('quinze eleves tiennent dans la colonne', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(
        presence: <PresenceParticipant>[
          for (int i = 0; i < 15; i++)
            presenceDe(
              profilId: 'p$i',
              prenom: 'Eleve${i.toString().padLeft(2, '0')}',
            ),
        ],
        fiches: <TeacherStudentProjection>[
          for (int i = 0; i < 15; i++) fiche('Eleve$i'),
        ],
      );
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.desktop,
      );

      await ouvrirEleves(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Eleve00'), findsOneWidget);
    });
  });

  group('session persistante', () {
    testWidgets('demonter l ecran ne coupe pas le cours', (
      WidgetTester tester,
    ) async {
      // **L'invariant du lot.** C'est exactement ce que faisait
      // `salle_page.dart`, dont le `dispose` appelait `quitter` sans condition.
      final banc0 = banc(presence: troisEleves());
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.tablette,
      );
      expect(banc0.moteur.entrees, hasLength(1));

      // On navigue ailleurs : l'arbre de la Classe Live est demonte.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(banc0.moteur.departs, 0);
    });

    testWidgets('ouvrir la Bibliotheque ne deconnecte pas', (
      WidgetTester tester,
    ) async {
      // Decision D-20 : en classe, la Bibliotheque s'ouvre comme un panneau, et
      // la room reste connectee. Aucune navigation, aucun `quitter`.
      final banc0 = banc(presence: troisEleves());
      await monterClasse(
        tester,
        contexte: contexte(
          support: 'r1',
          bibliotheque: (BuildContext _) => const Text('catalogue'),
        ),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.desktop,
      );

      await tester.tap(find.textContaining(t.salle.seance.supports).first);
      await tester.pumpAndSettle();

      expect(find.text('catalogue'), findsOneWidget);
      expect(banc0.moteur.departs, 0);
      expect(banc0.video.sorties, isEmpty);
    });

    testWidgets('le retour d une suspension ne coupe rien, et ne promet rien', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(presence: troisEleves());
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.tablette,
      );

      // **Rien ne se verifie PENDANT la suspension, et ce n'est pas une
      // limite du test** : `SchedulerBinding` coupe les frames des l'etat
      // `paused`. Une application suspendue ne rend aucune image, donc un
      // message affiche a ce moment ne serait jamais lu. C'est au RETOUR que
      // tout se joue.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(banc0.moteur.departs, 0);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(banc0.moteur.departs, 0);
      // Le doute est dit, et il tient : rien ne promet que le lien a survecu.
      expect(find.text(t.tc.classe.lien.retourDeSuspension), findsOneWidget);

      // Le moteur reconfirme : le doute tombe, sans que personne n ait a agir.
      banc0.moteur.poser(EtatSalle.connecte);
      await tester.pumpAndSettle();
      expect(find.text(t.tc.classe.lien.retourDeSuspension), findsNothing);
    });

    testWidgets('quitter annonce la sortie AVANT de deconnecter', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(presence: troisEleves());
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.tablette,
      );
      banc0.journal.clear();

      await tester.tap(find.text(t.salle.quitter).last);
      await tester.pumpAndSettle();
      // La confirmation, une seule fois.
      await tester.tap(find.text(t.salle.seance.quitterCahier).last);
      await tester.pumpAndSettle();

      expect(banc0.journal, <String>['annonce', 'deconnexion']);
      expect(banc0.moteur.departs, 1);
    });
  });

  group('etat du lien', () {
    testWidgets('une reconnexion se dit, et la salle reste montee', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(presence: troisEleves());
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.tablette,
      );

      banc0.moteur.poser(EtatSalle.reconnexion);
      // Deux images : la premiere livre l evenement du flux, la seconde
      // reconstruit l ecran que le `setState` a marque sale.
      await tester.pump();
      await tester.pump();

      expect(find.text(t.salle.seance.reconnexion), findsOneWidget);
      // La seance continue : le support reste a l'ecran.
      expect(find.text('support presente'), findsOneWidget);
      expect(banc0.moteur.departs, 0);
    });

    testWidgets('un lien sain ne dit rien', (WidgetTester tester) async {
      final banc0 = banc(presence: troisEleves());
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.tablette,
      );

      expect(find.text(t.salle.seance.reconnexion), findsNothing);
      expect(find.text(t.tc.classe.lien.reconnexion), findsNothing);
      expect(find.text(t.tc.classe.lien.instable), findsNothing);
    });
  });

  group('fiche et rappel discret', () {
    testWidgets('un rappel qui echoue est le seul a dire quelque chose', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(
        presence: troisEleves(),
        fiches: <TeacherStudentProjection>[
          fiche('Amina', niveau: 'Decodage consolide'),
        ],
        echecRappel: const EchecRappel(MotifEchecRappel.transport),
      );
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.desktop,
      );

      await ouvrirEleves(tester);
      // La fiche de la premiere connectee est deja depliee (CLV-07).
      if (find.text(t.salle.seance.rappeler).evaluate().isEmpty) {
        await tester.tap(find.text('Amina'));
        await tester.pumpAndSettle();
      }
      expect(find.text(t.salle.seance.rappeler), findsOneWidget);

      await tester.tap(find.text(t.salle.seance.rappeler));
      await tester.pump();
      await tester.pump();

      expect(find.text(t.tc.classe.rappel.echec), findsOneWidget);
      // Le temps passe : le retour local disparait tout seul.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('un rappel qui part ne dit rien du tout', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(
        presence: troisEleves(),
        fiches: <TeacherStudentProjection>[fiche('Amina')],
      );
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.desktop,
      );

      await ouvrirEleves(tester);
      // La fiche de la premiere connectee est deja depliee (CLV-07).
      if (find.text(t.salle.seance.rappeler).evaluate().isEmpty) {
        await tester.tap(find.text('Amina'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(t.salle.seance.rappeler));
      await tester.pump();
      await tester.pump();

      // Reussite silencieuse : aucun message, aucun accuse. La seule preuve est
      // hors de l'ecran.
      expect(banc0.rappel.appels, <(String, String)>[(seance, 'RA-Amina')]);
      expect(find.text(t.tc.classe.rappel.echec), findsNothing);
    });

    testWidgets('choisir pour reciter ne change pas le support', (
      WidgetTester tester,
    ) async {
      // Spec section 10.3 : changer d'eleve ne change ni la page, ni le focus,
      // ni le stylet, ni le support.
      final banc0 = banc(
        presence: troisEleves(),
        fiches: <TeacherStudentProjection>[fiche('Amina')],
      );
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.desktop,
      );

      await ouvrirEleves(tester);
      // La fiche de la premiere connectee est deja depliee (CLV-07).
      if (find.text(t.salle.seance.rappeler).evaluate().isEmpty) {
        await tester.tap(find.text('Amina'));
        await tester.pumpAndSettle();
      }
      // EN-9 : l'action s'intitule « Faire réciter » dans la salle.
      await tester.tap(find.text(t.salle.seance.faireReciter));
      await tester.pumpAndSettle();

      expect(find.text('support presente'), findsOneWidget);
      expect(banc0.moteur.departs, 0);
    });
  });

  group('observation', () {
    const List<AnnonceObservation> uneVisite = <AnnonceObservation>[
      AnnonceObservation(
        libelle: 'Tuteur d Amina observe',
        tempsRestant: Duration(seconds: 90),
        enfantConcerneId: 'RA-Amina',
        prenomEnfant: 'Amina',
      ),
    ];

    testWidgets('une annonce de tuteur s affiche avec son temps restant', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(presence: troisEleves(), annonces: uneVisite);
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.tablette,
        mouvementReduit: true,
      );

      // Le flux est demande pour CETTE seance, et l'en-tete porte ce qu'il
      // rend : c'est le cablage qui manquait, pas le composant.
      expect(banc0.annonces.demandes, <String>[seance]);
      // La notice de visite de la salle unique (I-2, EN-9) : « Un parent
      // observe cette séance », a la place du texte de la mention.
      expect(find.text(t.salle.seance.unParentObserve), findsOneWidget);
    });

    testWidgets('l eleve ne lit pas les annonces, et ne les demande meme pas', (
      WidgetTester tester,
    ) async {
      // Le jeton dit « student » : la seule autorite sur le role.
      final banc0 = banc(
        role: 'student',
        presence: troisEleves(),
        annonces: uneVisite,
      );
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.tablette,
        mouvementReduit: true,
      );

      // Un eleve qui apprendrait qu'un tuteur observe saurait aussi DE QUI :
      // le libelle porte un prenom. Le flux n'est donc pas meme ouvert.
      expect(banc0.annonces.demandes, isEmpty);
      expect(find.byType(IndicateurObservation), findsNothing);
      expect(find.text('Tuteur d Amina observe'), findsNothing);
      expect(find.textContaining('Tuteur de'), findsNothing);
    });

    testWidgets('l enfant observe lit la mention discrete, et rien de plus', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(
        role: 'student',
        presence: troisEleves(),
        monTuteurObserve: true,
      );
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.tablette,
        mouvementReduit: true,
      );

      // La lecture est demandee pour CETTE seance, et elle s'allume.
      expect(banc0.annonceEnfant.demandes, <String>[seance]);
      expect(find.text(t.salle.seance.votreParentObserve), findsOneWidget);
      // Et rien de ce que lit l'enseignant : ni prenom d'un autre enfant, ni
      // compteur d'observateurs. C'est la specification 11.3.
      expect(find.byType(IndicateurObservation), findsNothing);
      expect(find.textContaining('Tuteur de'), findsNothing);
    });

    // MA-TUTOIEMENT-1 (decision A4 = a) : en Mode Accessibilite (guidee), le
    // registre suit l'age, jamais la presentation. Avant le correctif,
    // `DepuisClasseLive` ne passait rien et `VueSeance` repliait sur la
    // presentation : la guidee etait tutoyee quel que soit son age.
    for (final (String nom, AgeEleve? age, bool tu)
        in <(String, AgeEleve?, bool)>[
          ('enfant (mineur connu)', AgeEleve.mineur, true),
          ('adulte connu', AgeEleve.adulte, false),
          ('age inconnu, port neutre', null, false),
        ]) {
      testWidgets('MA-TUTOIEMENT-1 : guidee, $nom : '
          '${tu ? 'tutoyee' : 'vouvoyee'}', (WidgetTester tester) async {
        final banc0 = banc(
          role: 'student',
          presence: troisEleves(),
          monTuteurObserve: true,
        );
        await monterClasse(
          tester,
          contexte: contexte(support: 'r1'),
          surcharges: <Override>[
            ...banc0.surcharges,
            if (age != null)
              portAgeEleveProvider.overrideWithValue(_AgeFixe(age)),
          ],
          ecran: LargeurEcran.tablette,
          mode: InterfaceMode.enfant,
          mouvementReduit: true,
        );
        expect(find.byType(SalleSeance), findsOneWidget);
        expect(
          find.text(t.salle.seance.tonParentObserve),
          tu ? findsOneWidget : findsNothing,
        );
        expect(
          find.text(t.salle.seance.votreParentObserve),
          tu ? findsNothing : findsOneWidget,
        );
      });
    }

    testWidgets('l enfant NON observe ne lit rien, et le serveur le dit', (
      WidgetTester tester,
    ) async {
      final banc0 = banc(role: 'student', presence: troisEleves());
      await monterClasse(
        tester,
        contexte: contexte(support: 'r1'),
        surcharges: banc0.surcharges,
        ecran: LargeurEcran.tablette,
        mouvementReduit: true,
      );

      // Le flux est bien ouvert -- l'eleve a le droit de demander -- mais il
      // rend faux : `annonce_observation_pour_moi` borne sa reponse a la ligne
      // de l'appelant, donc l'enfant d'un autre foyer recoit `observe: false`.
      expect(banc0.annonceEnfant.demandes, <String>[seance]);
      expect(find.text(t.salle.seance.votreParentObserve), findsNothing);
    });

    testWidgets(
      'l enseignant ne demande jamais l annonce reservee a l enfant',
      (WidgetTester tester) async {
        final banc0 = banc(presence: troisEleves(), annonces: uneVisite);
        await monterClasse(
          tester,
          contexte: contexte(support: 'r1'),
          surcharges: banc0.surcharges,
          ecran: LargeurEcran.tablette,
          mouvementReduit: true,
        );

        // Le serveur la lui refuserait de toute facon (il n'est pas membre du
        // groupe) : ne pas la demander evite de battre une RPC qui refuse.
        expect(banc0.annonceEnfant.demandes, isEmpty);
        expect(find.text(t.salle.seance.votreParentObserve), findsNothing);
      },
    );
  });
}
