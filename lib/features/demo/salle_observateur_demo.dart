// TB-11a (plan V2 §5, UX-21) : la salle des observateurs en demonstration,
// `/demo/salle?obs=tuteur&tb=ped03` (hors production).
//
// La VRAIE salle (`SallePage`), en role tuteur observateur ou controleur,
// ses ports video, pre-vol et presence remplaces par les doubles de
// `salle_controleur_demo.dart` (aucun serveur, aucun WebRTC, K-28), et la
// presentation suivie fournie par les donnees de la demonstration (la
// source reelle n'existe pas avant TB-BR).

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/domain/enums.dart';
import '../../core/presence/service_presence.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/pre_vol.dart';
import '../../core/video/service_video.dart';
import '../salle/salle_page.dart';
import '../salle_seance/presentation_observee.dart';
import '../salle_seance/vue_seance.dart';
import 'controleur_demo.dart' show EtatDemoControleur;
import 'demo_controleur_page.dart'
    show cheminDemoCompteRenduControleur, surchargesCoquilleControleurDemo;
import 'repere_demonstration.dart';
import 'salle_controleur_demo.dart';
import 'seance_demo.dart';

/// Les deux observateurs de la salle (plan V2 §5).
enum ObservateurDemo {
  /// Le tuteur observateur (`guardian_observer`).
  tuteur,

  /// Le controleur (`masked_controller`).
  controleur,
}

/// Les situations proposees aux observateurs : la salle sans presentation
/// (SAL-00), puis le tableau libre et les trois affichages (PED-01 a 04).
const List<SituationTb> situationsObservateur = <SituationTb>[
  SituationTb.sal00,
  SituationTb.ped01,
  SituationTb.ped02,
  SituationTb.ped03,
  SituationTb.ped04,
];

/// La page presentee dans la demonstration des observateurs : la troisieme
/// (bornee au nombre de pages), pour que la page lue ne soit pas la
/// premiere par defaut.
const int _pageObservee = 3;

/// La presentation suivie dans [situation], ou `null` : rien de presente
/// (la salle garde sa scene). Memes donnees que la salle des participants
/// (une seule source, `DonneesSeanceDemo`).
PresentationObservee? presentationObserveeDemo(SituationTb? situation) {
  final SupportPageFixe s = DonneesSeanceDemo.supportPageFixe;
  final SupportPageFixe page = SupportPageFixe(
    id: s.id,
    version: s.version,
    titre: s.titre,
    page: _pageObservee.clamp(1, s.total),
    total: s.total,
    largeurCanonique: s.largeurCanonique,
    hauteurCanonique: s.hauteurCanonique,
    mention: s.mention,
  );
  return switch (situation) {
    SituationTb.ped01 => const PresentationObservee(
      tableauLibre: DonneesSeanceDemo.tableauLibre,
    ),
    SituationTb.ped02 => PresentationObservee(
      supportPresente: page,
      affichage: AffichagePartage.support,
      tableauLibre: DonneesSeanceDemo.tableauLibre,
    ),
    SituationTb.ped03 => PresentationObservee(
      supportPresente: page,
      tableauLibre: DonneesSeanceDemo.tableauLibre,
    ),
    SituationTb.ped04 => PresentationObservee(
      supportPresente: page,
      affichage: AffichagePartage.tableau,
      tableauLibre: DonneesSeanceDemo.tableauLibre,
    ),
    _ => null,
  };
}

/// La VRAIE salle (`SallePage`) d'un observateur, sans serveur.
class SalleObservateurDemo extends StatelessWidget {
  /// Cree la salle.
  const SalleObservateurDemo({
    required this.observateur,
    required this.seanceId,
    this.presentation,
    super.key,
  });

  /// Le tuteur observateur ou le controleur.
  final ObservateurDemo observateur;

  /// La seance observee.
  final String seanceId;

  /// La presentation suivie, ou `null` : rien de presente.
  final PresentationObservee? presentation;

  @override
  Widget build(BuildContext context) {
    final String roleJeton = switch (observateur) {
      ObservateurDemo.tuteur => roleJetonTuteurDemo,
      ObservateurDemo.controleur => roleJetonControleurDemo,
    };
    return ProviderScope(
      overrides: <Override>[
        ...switch (observateur) {
          ObservateurDemo.controleur => surchargesCoquilleControleurDemo(
            EtatDemoControleur.enDirect,
          ),
          ObservateurDemo.tuteur => <Override>[
            sessionProvider.overrideWith(_SessionTuteurDemo.new),
          ],
        },
        moteurSalleProvider.overrideWith(
          (Ref _) => MoteurSalleControleurDemo(),
        ),
        serviceVideoProvider.overrideWithValue(
          ServiceVideoControleurDemo(role: roleJeton),
        ),
        servicePreVolProvider.overrideWithValue(const PreVolControleurDemo()),
        // Les lecteurs derives sont surcharges aussi : sans declaration de
        // dependances, ils vivraient dans le conteneur racine et liraient
        // les vrais ports (Riverpod, portee imbriquee).
        preVolProvider.overrideWith(
          (Ref _) => const PreVolControleurDemo().verifier(),
        ),
        presenceSeanceProvider.overrideWith(
          (Ref _, String _) => Stream<List<PresenceParticipant>?>.value(null),
        ),
        servicePresenceProvider.overrideWithValue(
          const PresenceControleurDemo(),
        ),
        presentationObserveeProvider.overrideWith(
          (Ref _, String _) => presentation,
        ),
      ],
      child: RepereDemonstration(
        child: SallePage(
          seanceId: seanceId,
          cheminCompteRenduControle: cheminDemoCompteRenduControleur,
        ),
      ),
    );
  }
}

/// La session du tuteur de la demonstration : resolue, active.
class _SessionTuteurDemo extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.guardian,
    profileId: 'demo-tuteur',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}
