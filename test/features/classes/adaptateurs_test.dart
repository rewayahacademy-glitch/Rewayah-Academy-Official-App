import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart'
    show Creneau;
import 'package:rewayah_academy/features/classes/domaine/adaptateurs_existants.dart';
import 'package:rewayah_academy/features/classes/domaine/classe_vm.dart';
import 'package:rewayah_academy/features/classes/domaine/conformite.dart';
import 'package:rewayah_academy/features/classes/domaine/erreur_domaine.dart';

import '../../support/harnais.dart';

/// Un service de groupes qui enregistre ce qu'on lui demande de creer.
class _Groupes implements ServiceGroupes {
  final List<String> crees = <String>[];
  Object? erreurAuDeuxieme;

  @override
  Future<List<GroupeAdmin>> groupes() async => const <GroupeAdmin>[];

  @override
  Future<List<MembreGroupe>> membres(String groupeId) async =>
      const <MembreGroupe>[];

  @override
  Future<String> creer({
    required String teacherId,
    required TypePublicGroupe type,
    required String libelle,
    required Creneau creneau,
    int? seuilMax,
  }) async {
    if (crees.length == 1 && erreurAuDeuxieme != null) {
      // ignore: only_throw_errors
      throw erreurAuDeuxieme!;
    }
    crees.add('$libelle@${creneau.jour}-${creneau.heure}');
    return 'g${crees.length}';
  }

  @override
  Future<void> modifier({
    required String groupeId,
    required String libelle,
    required int seuilMax,
    required Creneau creneau,
  }) async {}

  @override
  Future<void> ajouterEleve({
    required String groupeId,
    required String studentId,
    required String motif,
  }) async {}

  @override
  Future<void> retirerEleve({
    required String groupeId,
    required String studentId,
    required String motif,
  }) async {}

  @override
  Future<void> cloturer({required String groupeId, required String motif}) async {}
}

CompteAdmin _compte({
  required String id,
  required AppRole role,
  EtatPiece piece = EtatPiece.aucune,
  int contrats = 0,
}) => CompteAdmin(
  profilId: id,
  identifiant: id,
  prenom: 'P',
  nom: 'N',
  role: role,
  etat: AccountStatus.pendingKyc,
  inscritLe: DateTime(2026, 9, 1),
  accesJusquAu: null,
  foyerId: null,
  piece: piece,
  contrats: contrats,
  aEnseignant: false,
  enfantsDuFoyer: 0,
);

void main() {
  group('Une Classe se lit depuis groupes_admin() sans rien inventer', () {
    test('le public, le creneau, la capacite et l etat viennent de la ligne', () {
      const GroupeAdmin g = GroupeAdmin(
        id: 'g1',
        libelle: 'Perles',
        type: TypePublicGroupe.adulte,
        seuilMax: 6,
        teacherId: 't1',
        teacherIdentifiant: 'ENS-001',
        teacherPrenom: 'Amina',
        teacherNom: 'Diallo',
        creneau: Creneau(jour: 4, heure: 20, fuseau: 'Africa/Conakry'),
        nombreMembres: 2,
        actif: true,
      );
      final ClasseVM c = classeDepuisGroupeAdmin(
        g,
        regles: const ReglesClasse(fuseauIana: 'Europe/Paris', dureeMinutes: 60),
      );
      expect(c.publicClasse, PublicClasse.adultes);
      expect(c.creneau.jourIso, 4);
      expect(c.creneau.heure, 20);
      expect(c.creneau.fuseauIana, 'Africa/Conakry');
      expect(c.capacite, 6);
      expect(c.inscrits, 2);
      expect(c.duree, const Duration(minutes: 60));
      expect(c.etat, EtatPublication.publiee);
      expect(c.enseignant?.nomAffichage, 'Amina Diallo');
    });

    test('une duree inconnue reste inconnue, jamais zero', () {
      const GroupeAdmin g = GroupeAdmin(
        id: 'g1',
        libelle: 'Perles',
        type: TypePublicGroupe.enfant,
        seuilMax: 5,
        teacherId: 't1',
        teacherIdentifiant: 'ENS-001',
        teacherPrenom: null,
        teacherNom: null,
        creneau: Creneau(jour: 1, heure: 17, fuseau: 'Europe/Paris'),
        nombreMembres: 0,
        actif: false,
      );
      final ClasseVM c = classeDepuisGroupeAdmin(
        g,
        regles: const ReglesClasse(fuseauIana: 'Europe/Paris'),
      );
      expect(c.duree, isNull);
      expect(c.etat, EtatPublication.cloturee);
    });
  });

  group('La publication passe par creer_groupe, et dit ses limites', () {
    test('sans enseignant, la capacite serveur manque et rien n est cree', () async {
      final _Groupes groupes = _Groupes();
      final ClassesAdminDepuisExistant port = ClassesAdminDepuisExistant(
        groupes: () => groupes,
        programme: () => throw StateError('non appele'),
        configuration: () => throw StateError('non appele'),
        comptes: () => throw StateError('non appele'),
      );
      const BrouillonClasse sans = BrouillonClasse(
        libelle: 'A',
        publicClasse: PublicClasse.enfants,
        creneau: CreneauClasse(jourIso: 1, heure: 17, fuseauIana: 'Europe/Paris'),
      );
      await expectLater(
        port.publier(const <BrouillonClasse>[sans]),
        throwsA(
          isA<EchecDomaine>().having(
            (EchecDomaine e) => e.motif,
            'motif',
            MotifEchec.capaciteAbsente,
          ),
        ),
      );
      expect(groupes.crees, isEmpty);
    });

    test('un lot se publie case par case, et un echec en chemin se compte', () async {
      final _Groupes groupes = _Groupes()..erreurAuDeuxieme = StateError('panne');
      final ClassesAdminDepuisExistant port = ClassesAdminDepuisExistant(
        groupes: () => groupes,
        programme: () => throw StateError('non appele'),
        configuration: () => throw StateError('non appele'),
        comptes: () => throw StateError('non appele'),
      );
      const BrouillonClasse base = BrouillonClasse(
        libelle: 'A',
        publicClasse: PublicClasse.enfants,
        creneau: CreneauClasse(jourIso: 1, heure: 17, fuseauIana: 'Europe/Paris'),
        enseignantId: 't1',
      );
      await expectLater(
        port.publier(<BrouillonClasse>[
          base,
          base.surCreneau(
            const CreneauClasse(jourIso: 2, heure: 17, fuseauIana: 'Europe/Paris'),
          ),
          base.surCreneau(
            const CreneauClasse(jourIso: 3, heure: 17, fuseauIana: 'Europe/Paris'),
          ),
        ]),
        throwsA(
          isA<EchecPublicationPartielle>()
              .having((EchecPublicationPartielle e) => e.faites, 'faites', 1)
              .having((EchecPublicationPartielle e) => e.total, 'total', 3),
        ),
      );
      expect(groupes.crees, <String>['A@1-17']);
    });
  });

  group('La conformite se projette de ce que la base rend deja', () {
    test('un enseignant sans piece : KYC requis, non commence', () {
      final ConformiteCompte c = conformiteDepuisCompte(
        _compte(id: 't1', role: AppRole.teacher, contrats: 2),
      );
      expect(c.exigence, ExigenceKyc.requise);
      expect(c.etat, EtatKyc.nonCommence);
      expect(c.contratAccepte, isTrue);
      expect(c.clearanceOperationnelle, isFalse);
    });

    test('un enseignant a la piece validee est cleare', () {
      final ConformiteCompte c = conformiteDepuisCompte(
        _compte(
          id: 't1',
          role: AppRole.teacher,
          piece: EtatPiece.validee,
          contrats: 1,
        ),
      );
      expect(c.clearanceOperationnelle, isTrue);
    });

    test('un tuteur : KYC facultatif, et aucune dispense inventee', () {
      final ConformiteCompte c = conformiteDepuisCompte(
        _compte(id: 'g1', role: AppRole.guardian),
      );
      expect(c.exigence, ExigenceKyc.optionnelle);
      expect(c.dispense, isNull);
      expect(c.estDispense, isFalse);
    });

    test('une dispense cleare sans piece, jamais sans contrat', () {
      const ConformiteCompte sansContrat = ConformiteCompte(
        exigence: ExigenceKyc.dispensee,
        etat: EtatKyc.nonCommence,
        contratAccepte: false,
      );
      expect(sansContrat.kycSatisfait, isTrue);
      expect(sansContrat.clearanceOperationnelle, isFalse);
      const ConformiteCompte avec = ConformiteCompte(
        exigence: ExigenceKyc.dispensee,
        etat: EtatKyc.nonCommence,
        contratAccepte: true,
      );
      expect(avec.clearanceOperationnelle, isTrue);
    });
  });

  group('La precondition d entree se lit du foyer', () {
    EleveDuFoyer membre({
      required String id,
      required InterfaceMode mode,
      String? cleAvatar,
    }) => EleveDuFoyer(
      id: id,
      prenom: 'Amina',
      identifiantImmuable: 'STUD-$id',
      mode: mode,
      camera: CameraPolicy.forbidden,
      cleAvatar: cleAvatar,
    );

    test('un membre en mode enfant sans photo est bloque, avec sa photo non', () async {
      final FauxServiceAppairage appairage = FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[
          membre(id: 'e1', mode: InterfaceMode.enfant),
          membre(id: 'e2', mode: InterfaceMode.enfant, cleAvatar: 'e2/1.jpg'),
        ];
      final PreconditionDepuisFoyer port = PreconditionDepuisFoyer(
        appairage: () => appairage,
      );
      expect((await port.pour(membreId: 'e1')).bloqueParPhoto, isTrue);
      expect((await port.pour(membreId: 'e2')).bloqueParPhoto, isFalse);
    });

    test('un membre en mode standard n est jamais bloque par une photo', () async {
      // Le mode standard couvre aussi l'adulte autonome : inventer un blocage
      // ici serait inventer une regle.
      final FauxServiceAppairage appairage = FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[
          membre(id: 'a1', mode: InterfaceMode.standard),
        ];
      final PreconditionDepuisFoyer port = PreconditionDepuisFoyer(
        appairage: () => appairage,
      );
      expect((await port.pour(membreId: 'a1')).bloqueParPhoto, isFalse);
    });

    test('un foyer illisible rend l inconnu, jamais une erreur', () async {
      final PreconditionDepuisFoyer port = PreconditionDepuisFoyer(
        appairage: () => throw StateError('aucun backend'),
        monProfilId: () => throw StateError('aucune session'),
      );
      final PreconditionSalle p = await port.pour();
      expect(p.bloqueParPhoto, isFalse);
      expect(p.photoRequise, isNull);
    });
  });
}
