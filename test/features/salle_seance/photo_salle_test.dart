// PHOTOS-A (04/11/2026) : dans la salle, le compte et la capsule lisent la
// photo de la personne a la source unique (`photoPersonneProvider(id)`),
// par l'id que la vue de la seance porte. Jamais une cle copiee ailleurs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/capsule_seance.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_salle.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../support/harnais.dart';

const String _idProf = 'b0000000-0000-4000-8000-000000000001';
const String _idEleve = 'c0000000-0000-4000-8000-000000000002';
const String _url = 'https://photos.invalid/prof.jpg';

AccesSalle _acces(String role) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: role == 'teacher',
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

VueSeance _vue(String role) => DepuisSalle.vue(
  salle: VueSalle.depuis(
    materielPret: true,
    acces: _acces(role),
    etatMoteur: EtatSalle.connecte,
    participants: const <ParticipantSalle>[],
    qualite: QualiteLien.bonne,
  ),
  mode: InterfaceMode.standard,
  nomEnseignantConnu: 'Sayyida Amina',
  idEnseignant: _idProf,
  monProfil: _idEleve,
)!;

void main() {
  test('enseignant : son compte porte son id', () {
    final VueSeance vue = _vue('teacher');
    expect(vue.idEnseignant, _idProf);
    expect(vue.idEleve, isNull);
    expect(vue.compte.id, _idProf);
  });

  test('eleve : son compte porte son id, la capsule celui de l enseignant', () {
    final VueSeance vue = _vue('student');
    expect(vue.idEnseignant, _idProf);
    expect(vue.copyWith().idEnseignant, _idProf);
    expect(vue.copyWith().idEleve, _idEleve);
  });

  testWidgets('la capsule montre la photo lue a la source unique', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        Material(
          child: SectionContexte(
            vue: _vue('student'),
            actions: const ActionsSeance(),
          ),
        ),
        surcharges: <Override>[
          photoPersonneProvider.overrideWith(
            (Ref ref, String id) async => id == _idProf ? _url : null,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final Iterable<AvatarTile> tuiles = tester.widgetList<AvatarTile>(
      find.byType(AvatarTile),
    );
    expect(tuiles.map((AvatarTile t) => t.urlSignee), contains(_url));
  });
}
