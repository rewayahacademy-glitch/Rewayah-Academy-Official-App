// Lot RESEAU-PREUVE (directeur, 11/11/2026) : la salle envoie au serveur le
// premier etat stable du lien du participant local, et seulement le sien.
// Le rythme et les refus sont prouves dans
// `test/core/video/releve_qualite_test.dart` ; ici, le branchement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart'
    show groupesEnseignantProvider;
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/releve_qualite.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/seuils_reseau.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';

import '../../support/harnais.dart';
import '../../teaching_core/e/faux/faux_classe.dart';

typedef _Ligne = ({String seance, String profil, EtatReleve etat, bool micro});

class _FauxReleve implements PortReleveQualite {
  final List<_Ligne> lignes = <_Ligne>[];

  @override
  Future<ReponseReleve> noter({
    required String seanceId,
    required String profilId,
    required EtatReleve etat,
    required bool microOuvert,
  }) async {
    lignes.add((
      seance: seanceId,
      profil: profilId,
      etat: etat,
      micro: microOuvert,
    ));
    return ReponseReleve.ecrite;
  }
}

AccesSalle _acces() => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: 'student',
  capacites: const CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: false,
    peutPublierDonnees: false,
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

ParticipantSalle _p(
  String id,
  String role,
  QualiteLien qualite, {
  bool local = false,
}) => ParticipantSalle(
  identite: id,
  nom: id,
  role: role,
  estLocal: local,
  micro: true,
  camera: false,
  parle: false,
  qualite: qualite,
);

void main() {
  testWidgets('la salle ecrit la ligne du participant local, des que son lien '
      'est stable, et jamais celle d un autre', (WidgetTester tester) async {
    final _FauxReleve releve = _FauxReleve();
    final FauxMoteurSalle moteur = FauxMoteurSalle();
    final List<Override> surcharges = <Override>[
      sourceSessionProvider.overrideWithValue(
        FausseSourceSession(
          const SessionState(
            resolue: true,
            role: AppRole.student,
            profileId: 'p1',
            accountStatus: AccountStatus.active,
            lectureProfil: LectureProfil.presente,
          ),
        ),
      ),
      servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
      serviceVideoProvider.overrideWithValue(
        FauxServiceVideo(acces0: _acces()),
      ),
      moteurSalleProvider.overrideWithValue(moteur),
      servicePresenceProvider.overrideWithValue(FauxServicePresence()),
      portAnnonceObservationEnfantProvider.overrideWithValue(
        FauxAnnonceObservationEnfant(),
      ),
      portAnnonceObservationProvider.overrideWithValue(
        FauxAnnonceObservation(),
      ),
      groupesEnseignantProvider.overrideWith(
        (Ref _) async => const <GroupeEnseignant>[],
      ),
      portReleveQualiteProvider.overrideWithValue(releve),
    ];
    await tester.pumpWidget(
      hoteRoutant(
        depart: Routes.salle,
        surcharges: surcharges,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.salle,
            builder: (BuildContext _, GoRouterState _) =>
                const SallePage(seanceId: 's1'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    moteur.publier(<ParticipantSalle>[
      _p('prof', 'teacher', QualiteLien.perdue),
      _p('p1', 'student', QualiteLien.mediocre, local: true),
      _p('autre', 'student', QualiteLien.mediocre),
    ]);
    await tester.pump();
    expect(
      releve.lignes,
      isEmpty,
      reason: 'pas encore stable : rien ne part sur une mesure d une seconde',
    );

    // Le filtre lit l'heure reelle : on laisse passer la tenue pour de vrai,
    // puis on fait sonner sa minuterie.
    await tester.runAsync(
      () => Future<void>.delayed(
        tenueAvantChangement + const Duration(milliseconds: 200),
      ),
    );
    await tester.pump(tenueAvantChangement);
    await tester.pump();

    expect(releve.lignes, <_Ligne>[
      (seance: 's1', profil: 'p1', etat: EtatReleve.faible, micro: true),
    ]);
  });
}
