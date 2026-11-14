// QUALITE-VIDEO-ENTRETIEN et RA-STAFF (directeur, 14/11/2026) : la salle d'un
// entretien rendue avec de vraies polices, cote direction et cote candidat, a
// 1440 et 390, a cote d'un cours. Les cadres video sont des aplats : la
// capture montre leur place et leur taille (a comparer a un cours), pas une
// image reelle. La taille de chaque cadre est ecrite dans
// `tailles-cadres.txt` du dossier de sortie. Sautee sans CAPTURE_DIR.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/presentation_observee.dart';

import '../support/demo/salle_controleur_demo.dart';
import 'outil_capture.dart';

class _Session extends SessionControleur {
  _Session(this.role);
  final AppRole role;
  @override
  SessionState build() => SessionState(
    resolue: true,
    role: role,
    profileId: 'moi',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

class _Moteur extends MoteurSalleControleurDemo {
  _Moteur(this.liste);
  final List<ParticipantSalle> Function(String role) liste;
  final StreamController<List<ParticipantSalle>> _p =
      StreamController<List<ParticipantSalle>>.broadcast();
  @override
  Future<void> rejoindre(AccesSalle acces) async {
    await super.rejoindre(acces);
    Timer.run(() => _p.add(liste(acces.role)));
  }

  @override
  Stream<List<ParticipantSalle>> get participants => _p.stream;
  @override
  Widget? renduVideo(String identite) =>
      ColoredBox(key: ValueKey<String>('video-$identite'), color: Colors.green);
}

ParticipantSalle _q(String id, String nom, String role, bool local) =>
    ParticipantSalle(
      identite: id,
      nom: nom,
      role: role,
      estLocal: local,
      micro: true,
      camera: true,
      parle: false,
      qualite: QualiteLien.bonne,
    );

Future<void> _mesurer(
  WidgetTester tester,
  String nom,
  Size taille,
  String roleJeton,
  List<ParticipantSalle> Function(String) liste,
) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      ProviderScope(
        overrides: <Override>[
          sessionProvider.overrideWith(() => _Session(AppRole.teacher)),
          moteurSalleProvider.overrideWith((Ref _) => _Moteur(liste)),
          serviceVideoProvider.overrideWithValue(
            ServiceVideoControleurDemo(role: roleJeton),
          ),
          servicePreVolProvider.overrideWithValue(const PreVolControleurDemo()),
          preVolProvider.overrideWith(
            (Ref _) => const PreVolControleurDemo().verifier(),
          ),
          presenceSeanceProvider.overrideWith(
            (Ref _, String _) => Stream<List<PresenceParticipant>?>.value(null),
          ),
          servicePresenceProvider.overrideWithValue(
            const PresenceControleurDemo(),
          ),
          presentationObserveeProvider.overrideWith((Ref _, String _) => null),
        ],
        child: const SallePage(seanceId: 'seance-entretien'),
      ),
    ),
  );
  await stabiliser(tester);
  await tester.pump(const Duration(seconds: 1));
  await stabiliser(tester);
  final StringBuffer b = StringBuffer(
    '$nom ${taille.width.toInt()}x${taille.height.toInt()}:\n',
  );
  for (final Element e
      in find
          .byWidgetPredicate(
            (Widget w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('video-'),
          )
          .evaluate()) {
    final RenderBox r = e.renderObject! as RenderBox;
    b.writeln(
      '  ${(e.widget.key! as ValueKey<String>).value} ${r.size.width.toStringAsFixed(0)}x${r.size.height.toStringAsFixed(0)}',
    );
  }
  tailles.write(b);
  await capturer(tester, nom);
}

final StringBuffer tailles = StringBuffer();

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDownAll(() {
    if (dossierCapture != null) {
      File(cheminSortie('tailles-cadres').replaceAll('.png', '.txt'))
          .writeAsStringSync(tailles.toString());
    }
  });
  group('salle d entretien', skip: sautSansCapture, () {
    List<ParticipantSalle> entretien(String role) => <ParticipantSalle>[
      _q('moi', 'Moi', role, true),
      _q(
        'cand',
        role == 'intervieweur' ? 'Khadija' : 'Hafsa',
        role == 'intervieweur' ? 'candidat' : 'intervieweur',
        false,
      ),
      if (role == 'intervieweur') _q('dir2', 'Hafsa', 'intervieweur', false),
    ];
    List<ParticipantSalle> cours(String role) => <ParticipantSalle>[
      _q('moi', 'Moi', role, true),
      _q('e1', 'Yasmine', 'student', false),
      _q('e2', 'Idriss', 'student', false),
    ];
    for (final Size s in <Size>[const Size(1440, 900), const Size(390, 844)]) {
      testWidgets(
        'intervieweur ${s.width}',
        (WidgetTester t) => _mesurer(
          t,
          '01_direction_${s.width.toInt()}',
          s,
          'intervieweur',
          entretien,
        ),
      );
      testWidgets(
        'candidat ${s.width}',
        (WidgetTester t) => _mesurer(
          t,
          '02_candidat_${s.width.toInt()}',
          s,
          'candidat',
          entretien,
        ),
      );
      testWidgets(
        'enseignant ${s.width}',
        (WidgetTester t) => _mesurer(
          t,
          '03_cours_enseignant_${s.width.toInt()}',
          s,
          'teacher',
          cours,
        ),
      );
    }
  });
}
