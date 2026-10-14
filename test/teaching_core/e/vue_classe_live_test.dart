import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_classe/roster_classe_vm.dart';
import 'package:rewayah_academy/core/tc_classe/session_live_vm.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/tc_classe_live/vue_classe_live.dart';

/// La composition de la Classe Live, verifiee **sans monter d'ecran**.
///
/// Trois gabarits, deux compositions, trois poids de video, cinq mots du lien :
/// c'est la meme discipline que `VueSalle.depuis` et `deciderRedirection`, et
/// c'est ce qui rend une salle testable sans SDK.
void main() {
  TeacherStudentProjection eleve(String prenom, EtatPresenceProjete etat) =>
      TeacherStudentProjection(
        firstName: prenom,
        academyId: 'RA-$prenom',
        liveStatus: etat,
        interfaceGuidee: false,
      );

  RosterClasseVM rosterDe(int combien) => RosterClasseVM(
    eleves: <TeacherStudentProjection>[
      for (int i = 0; i < combien; i++)
        eleve('E$i', EtatPresenceProjete.present),
    ],
    disponible: true,
  );

  SessionLiveVM seance({String? support, EtatSalle lien = EtatSalle.connecte}) =>
      SessionLiveVM(
        sessionId: 's1',
        groupeId: 'g1',
        libelleGroupe: 'Classe Al-Fatiha',
        enseignant: const EnseignantDeClasse(
          nomAffichage: 'Youssouf',
          titre: TitreEnseignant.sayyid,
        ),
        etatLien: lien,
        supportActifId: support,
      );

  VueClasseLive vue({
    required Gabarit gabarit,
    String? support,
    bool voitLeRoster = true,
    bool peutPiloter = true,
    EtatSalle lien = EtatSalle.connecte,
    bool suspension = false,
    int eleves = 4,
  }) => VueClasseLive.depuis(
    gabarit: gabarit,
    session: seance(support: support, lien: lien),
    roster: rosterDe(eleves),
    voitLeRoster: voitLeRoster,
    peutPiloterSupport: peutPiloter,
    suspensionNonConfirmee: suspension,
  );

  group('composition : le support domine des qu il existe', () {
    for (final Gabarit gabarit in Gabarit.values) {
      test('avec support, ${gabarit.name} : le support domine', () {
        expect(
          vue(gabarit: gabarit, support: 'r1').composition,
          CompositionClasse.supportDominant,
        );
        expect(vue(gabarit: gabarit, support: 'r1').supportDomine, isTrue);
      });

      test('sans support, ${gabarit.name} : la video reprend la place', () {
        expect(
          vue(gabarit: gabarit).composition,
          CompositionClasse.videoDominante,
        );
        expect(vue(gabarit: gabarit).poidsVideo, PoidsVideo.scene);
      });
    }
  });

  group('place du roster', () {
    test('mobile : en feuille, derriere un compteur compact', () {
      final VueClasseLive v = vue(gabarit: Gabarit.mobile, support: 'r1');
      expect(v.placeRoster, PlaceRoster.feuille);
      expect(v.compteurCompact, '4/4');
    });

    test('tablette et bureau : en colonne, sans compteur compact', () {
      for (final Gabarit g in <Gabarit>[Gabarit.tablette, Gabarit.desktop]) {
        final VueClasseLive v = vue(gabarit: g, support: 'r1');
        expect(v.placeRoster, PlaceRoster.colonne);
        // Le compteur ferait doublon a cote d'une colonne qui montre les
        // lignes, et un doublon finit par diverger.
        expect(v.compteurCompact, isNull);
      }
    });

    test('qui n a pas droit au roster ne le voit nulle part', () {
      for (final Gabarit g in Gabarit.values) {
        expect(
          vue(gabarit: g, voitLeRoster: false).placeRoster,
          PlaceRoster.masque,
        );
      }
    });
  });

  group('poids de la video', () {
    test('mobile avec support : vignette', () {
      expect(
        vue(gabarit: Gabarit.mobile, support: 'r1').poidsVideo,
        PoidsVideo.vignette,
      );
    });

    test('tablette et bureau avec support : bande', () {
      for (final Gabarit g in <Gabarit>[Gabarit.tablette, Gabarit.desktop]) {
        expect(vue(gabarit: g, support: 'r1').poidsVideo, PoidsVideo.bande);
      }
    });
  });

  group('Teaching Dock', () {
    test('il ne flotte que sur un support', () {
      expect(vue(gabarit: Gabarit.desktop).dockFlottant, isFalse);
      expect(
        vue(gabarit: Gabarit.desktop, support: 'r1').dockFlottant,
        isTrue,
      );
    });

    test('il n existe pas pour qui ne peut pas piloter le support', () {
      // La capacite vient du jeton signe (`can_publish_data`), jamais d'un
      // reglage d'ecran : proposer un dock a qui ne peut pas emettre offrirait
      // des gestes que le serveur refuserait.
      expect(
        vue(
          gabarit: Gabarit.desktop,
          support: 'r1',
          peutPiloter: false,
        ).dockFlottant,
        isFalse,
      );
    });
  });

  group('mot du lien', () {
    test('les quatre etats qui changent quelque chose portent un mot', () {
      expect(vue(gabarit: Gabarit.desktop, lien: EtatSalle.instable).motLien,
          MotLien.instable);
      expect(vue(gabarit: Gabarit.desktop, lien: EtatSalle.reconnexion).motLien,
          MotLien.reconnexion);
      expect(vue(gabarit: Gabarit.desktop, lien: EtatSalle.retabli).motLien,
          MotLien.retabli);
      expect(vue(gabarit: Gabarit.desktop, lien: EtatSalle.echec).motLien,
          MotLien.echec);
    });

    test('un lien sain ne dit rien', () {
      for (final EtatSalle etat in <EtatSalle>[
        EtatSalle.absent,
        EtatSalle.connexion,
        EtatSalle.connecte,
      ]) {
        expect(vue(gabarit: Gabarit.desktop, lien: etat).motLien, MotLien.aucun);
      }
    });

    test('une reconnexion ne demonte pas la salle', () {
      // `enSalle` reste vrai pendant la reconnexion : la seance continue, les
      // commandes restent actives, l'ecran ne se demonte pas.
      expect(seance(lien: EtatSalle.reconnexion).enSalle, isTrue);
      expect(seance(lien: EtatSalle.reconnexion).enReconnexion, isTrue);
    });
  });

  test('le retour de suspension est signale sans rien promettre', () {
    expect(
      vue(gabarit: Gabarit.mobile, suspension: true).avertitSuspension,
      isTrue,
    );
    expect(vue(gabarit: Gabarit.mobile).avertitSuspension, isFalse);
  });

  test('aucune barre d outils ne couvre le Coran', () {
    // Verite de construction, pas reglage : les commandes vivent dans
    // `PageImmersive.commandes`, donc SOUS le contenu et jamais en
    // surimpression. Le test existe pour qu'un changement de composition ne
    // puisse pas le rendre faux en silence.
    for (final Gabarit g in Gabarit.values) {
      expect(vue(gabarit: g, support: 'r1').commandesCouvrentLeSupport, isFalse);
    }
  });

  group('compteur compact', () {
    test('il compte les presents sur les inscrits, jamais sur le plafond', () {
      final RosterClasseVM roster = RosterClasseVM(
        eleves: <TeacherStudentProjection>[
          eleve('Amina', EtatPresenceProjete.present),
          eleve('Ilyas', EtatPresenceProjete.enRetard),
          eleve('Mariam', EtatPresenceProjete.attendu),
          eleve('Zayd', EtatPresenceProjete.absent),
        ],
        disponible: true,
        // Un plafond de cinq, quatre inscrits : « 2/4 » et jamais « 2/5 ».
        seuilMax: 5,
      );
      expect(roster.presents, 2);
      expect(roster.attendus, 4);
      expect(roster.compteurCompact, '2/4');
    });
  });
}
