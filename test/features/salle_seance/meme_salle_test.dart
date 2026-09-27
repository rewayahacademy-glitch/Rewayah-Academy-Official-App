// `/tc/classe` et `/salle` rendent la MEME salle (T8, plan de code CL-2).
//
// Pour un meme role et un meme etat (memes inscrits, meme visite), la Classe
// Live montee avec le faux moteur (`test/teaching_core/e/faux/faux_classe.dart`)
// et la salle de `/salle` (`SalleSeance` construite par `DepuisSalle` depuis
// la meme `VueSalle`) affichent exactement les memes textes. Aucune seconde
// salle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/tc_classe/session_live_vm.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_salle.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_classe_live/classe_live_page.dart';

import '../../teaching_core/e/faux/faux_classe.dart';
import '../../teaching_core/e/support/hote_classe.dart';

void main() {
  const String seance = 's1';
  const String classe = 'Classe An-Nour';

  List<PresenceParticipant> inscrits() => <PresenceParticipant>[
    presenceDe(profilId: 'p1', prenom: 'Mariam', identifiant: 'RA-Mariam'),
    presenceDe(
      profilId: 'p2',
      prenom: 'Yusuf',
      identifiant: 'RA-Yusuf',
      etat: EtatPresence.enAttente,
    ),
    presenceDe(
      profilId: 't1',
      prenom: 'Amina',
      role: 'teacher',
      identifiant: 'RA-Amina',
    ),
  ];

  const List<AnnonceObservation> visite = <AnnonceObservation>[
    AnnonceObservation(
      libelle: 'Tuteur de Mariam observe',
      enfantConcerneId: 'RA-Mariam',
      prenomEnfant: 'Mariam',
    ),
  ];

  /// Les textes visibles, tries : l'ordre de lecture n'est pas compare.
  List<String> textes(WidgetTester tester) =>
      tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .where((String s) => s.trim().isNotEmpty)
          .toList()
        ..sort();

  for (final LargeurEcran ecran in <LargeurEcran>[
    LargeurEcran.mobile,
    LargeurEcran.desktop,
  ]) {
    testWidgets('enseignant, visite : memes textes a ${ecran.name}', (
      WidgetTester tester,
    ) async {
      final FauxMoteurClasse moteur = FauxMoteurClasse();
      final FauxServiceVideoClasse video = FauxServiceVideoClasse(
        acces0: accesDe('teacher'),
      );
      await monterClasse(
        tester,
        contexte: const ContexteClasseLive(
          sessionId: seance,
          groupeId: 'g1',
          libelleGroupe: classe,
          // `/salle` ne connait pas encore le titre (BR-1) : sans titre, les
          // deux hotes nomment l'enseignante de la meme facon.
          enseignant: EnseignantDeClasse(nomAffichage: 'Amina'),
        ),
        surcharges: surchargesClasse(
          moteur: moteur,
          video: video,
          preVol: FauxPreVolClasse(),
          presence: FauxPresenceClasse(lignes: inscrits()),
          annonces: FauxAnnonceObservation(lignes: visite),
        ),
        ecran: ecran,
        mouvementReduit: true,
      );
      expect(find.byType(SalleSeance), findsOneWidget);
      final List<String> classeLive = textes(tester);

      // La salle de `/salle`, depuis la meme `VueSalle`.
      final VueSalle salle = VueSalle.depuis(
        materielPret: true,
        acces: accesDe('teacher'),
        etatMoteur: EtatSalle.connecte,
        participants: const <ParticipantSalle>[],
        qualite: QualiteLien.inconnue,
      );
      final VueSeance vue = DepuisSalle.vue(
        salle: salle,
        mode: InterfaceMode.standard,
        presence: inscrits(),
        annonces: visite,
        nomClasse: classe,
        groupeId: 'g1',
      )!;
      void rien() {}
      // Un autre arbre : la Classe Live est d'abord demontee.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              builder: (BuildContext context, Widget? enfant) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: enfant ?? const SizedBox.shrink(),
              ),
              home: SalleSeance(
                vue: vue,
                actions: ActionsSeance(
                  onQuitter: rien,
                  onMicro: rien,
                  onCamera: rien,
                  onZoomMoins: rien,
                  onZoomPlus: rien,
                  onEleves: rien,
                  onReseau: rien,
                  onNaviguer: (String _) {},
                  onRappeler: (EleveSeance _) {},
                  onChoisirPourReciter: (EleveSeance _) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final List<String> salleUnique = textes(tester);

      expect(classeLive, salleUnique);
      // Et c'est bien la salle attendue : compteur derive (I-6), notice de
      // visite, jamais d'absent.
      expect(
        classeLive,
        contains(t.salle.seance.compteurEleves(connectes: 1, inscrits: 2)),
      );
      expect(
        classeLive,
        contains(t.salle.seance.tuteurDeObserve(prenom: 'Mariam')),
      );
      expect(
        classeLive.where((String s) => s.toLowerCase().contains('absent')),
        isEmpty,
      );
    });
  }
}
