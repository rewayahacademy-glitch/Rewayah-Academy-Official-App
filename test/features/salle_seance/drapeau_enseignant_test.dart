// DRAPEAUX (04/11/2026) : le pays de l'enseignant arrive dans la salle par
// l'annuaire de la seance (la Classe de la famille ou son propre profil),
// puis la vue de la seance, et s'ecrit sous son nom (capsule, compte).
// Jamais avec le seul prenom de la presence ; jamais pour le compte d'un
// eleve.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/pays_enseignant.dart';
import 'package:rewayah_academy/features/salle/annuaire_seance.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/capsule_seance.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_salle.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../support/harnais.dart';

const String _idProf = 'b0000000-0000-4000-8000-000000000001';

AccesSalle _acces(String role) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: role == 'teacher' || role == 'student',
    peutPublierVideo: role == 'teacher',
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

VueSalle _salle(String role) => VueSalle.depuis(
  materielPret: true,
  acces: _acces(role),
  etatMoteur: EtatSalle.connecte,
  participants: const <ParticipantSalle>[],
  qualite: QualiteLien.bonne,
);

AnnuaireSeance _annuaire({String? pays, String prenom = 'Amina'}) =>
    AnnuaireSeance(
      enseignant: (
        id: _idProf,
        prenom: prenom,
        titre: TitreEnseignant.sayyida,
        clePhoto: null,
        pays: pays,
      ),
    );

VueSeance _vue(String role, AnnuaireSeance annuaire) => DepuisSalle.vue(
  salle: _salle(role),
  mode: InterfaceMode.standard,
  nomEnseignantConnu: annuaire.enseignant,
  paysEnseignant: annuaire.paysEnseignant,
)!;

void main() {
  group('annuaire', () {
    test('le pays de la fiche de l enseignant, avec son nom', () {
      final AnnuaireSeance annuaire = _annuaire(pays: "Côte d'Ivoire");
      expect(annuaire.enseignant, 'Sayyida Amina');
      expect(annuaire.paysEnseignant, "Côte d'Ivoire");
    });

    test('identite masquee (prenom vide) : ni nom ni pays', () {
      final AnnuaireSeance annuaire = _annuaire(pays: 'Maroc', prenom: '');
      expect(annuaire.enseignant, isNull);
      expect(annuaire.paysEnseignant, isNull);
    });

    test('sans fiche : aucun pays', () {
      expect(AnnuaireSeance().paysEnseignant, isNull);
    });
  });

  group('vue de la seance', () {
    test('eleve : le pays de son enseignant, pas sur son propre compte', () {
      final VueSeance vue = _vue('student', _annuaire(pays: 'Maroc'));
      expect(vue.paysEnseignant, 'Maroc');
    });

    test('enseignant : son compte porte son pays', () {
      final VueSeance vue = _vue('teacher', _annuaire(pays: 'Maroc'));
      expect(vue.paysEnseignant, 'Maroc');
      expect(vue.compte.pays, 'Maroc');
    });

    test('sans nom de l annuaire : aucun pays', () {
      final VueSeance vue = DepuisSalle.vue(
        salle: _salle('student'),
        mode: InterfaceMode.standard,
        paysEnseignant: 'Maroc',
      )!;
      expect(vue.paysEnseignant, isNull);
    });
  });

  testWidgets('la capsule ecrit le pays et son drapeau sous le nom', (
    WidgetTester tester,
  ) async {
    final VueSeance vue = _vue('student', _annuaire(pays: 'Maroc'));
    await tester.pumpWidget(
      hote(
        Material(
          child: SectionContexte(vue: vue, actions: const ActionsSeance()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PaysEnseignant), findsOneWidget);
    expect(find.text('Maroc'), findsOneWidget);
  });
}
