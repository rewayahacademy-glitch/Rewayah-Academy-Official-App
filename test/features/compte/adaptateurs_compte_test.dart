// Adaptateurs et fonctions pures du Compte du tuteur (lot E) : identite du
// titulaire, acces des profils, fuseau et dates lisibles.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/acces_foyer_depuis_eleves.dart';
import 'package:rewayah_academy/core/capacites/identite_titulaire_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/villes_fuseau.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart';

import '../../fixtures/tuteur/foyers.dart';

EleveDuFoyer _eleve(String id, String prenom, {DateTime? fin}) => EleveDuFoyer(
  id: id,
  prenom: prenom,
  identifiantImmuable: 'STUD-$id',
  mode: InterfaceMode.standard,
  camera: CameraPolicy.forbidden,
  finAcces: fin,
);

void main() {
  group('methodeConnexionDepuis', () {
    test('google, lien par courriel, inconnue', () {
      expect(
        methodeConnexionDepuis(<String, dynamic>{'provider': 'google'}),
        MethodeConnexion.google,
      );
      expect(
        methodeConnexionDepuis(<String, dynamic>{'provider': 'email'}),
        MethodeConnexion.lienCourriel,
      );
      expect(
        methodeConnexionDepuis(<String, dynamic>{'provider': 'apple'}),
        MethodeConnexion.inconnue,
      );
      expect(
        methodeConnexionDepuis(<String, dynamic>{}),
        MethodeConnexion.inconnue,
      );
    });

    test('un compte courriel n est pas dit « lien » si le mot de passe est '
        'possible', () {
      expect(
        methodeConnexionDepuis(<String, dynamic>{
          'provider': 'email',
        }, motDePassePossible: true),
        MethodeConnexion.inconnue,
      );
    });
  });

  group('identiteDepuis', () {
    test('lit prenom, nom, statut, courriel ; rien n est invente', () {
      final IdentiteTitulaire lue = identiteDepuis(
        <String, dynamic>{
          'first_name': '  Awa ',
          'last_name': 'Ndiaye',
          'account_status': 'active',
        },
        courriel: 'awa@exemple.test',
        appMetadata: <String, dynamic>{'provider': 'email'},
      );
      expect(lue.prenom, 'Awa');
      expect(lue.nom, 'Ndiaye');
      expect(lue.courriel, 'awa@exemple.test');
      expect(lue.statut, AccountStatus.active);
      expect(lue.methodeConnexion, MethodeConnexion.lienCourriel);
    });

    test('champs absents : vides, statut inconnu, courriel null', () {
      final IdentiteTitulaire lue = identiteDepuis(
        <String, dynamic>{'first_name': null, 'account_status': 'inconnu'},
        courriel: '  ',
        appMetadata: <String, dynamic>{},
      );
      expect(lue.prenom, isEmpty);
      expect(lue.nom, isEmpty);
      expect(lue.courriel, isNull);
      expect(lue.statut, isNull);
      expect(nomComplet(lue), isNull);
    });
  });

  group('accesDepuisEleves', () {
    final DateTime maintenant = DateTime.utc(2026, 9, 24, 12);

    test('ordre stable par prenom puis identifiant, etats d affichage', () {
      final List<AccesBeneficiaire> acces = accesDepuisEleves(<EleveDuFoyer>[
        _eleve('b', 'Zineb', fin: DateTime.utc(2026, 9, 24, 12)),
        _eleve('c', 'amine', fin: DateTime.utc(2026, 10, 1)),
        _eleve('a', 'Amine'),
      ], maintenantUtc: maintenant);
      expect(acces.map((AccesBeneficiaire a) => a.eleveId), <String>[
        'a',
        'c',
        'b',
      ]);
      expect(acces[0].etatAffiche, EtatAccesAffiche.sansEcheance);
      expect(acces[1].etatAffiche, EtatAccesAffiche.actif);
      // L'instant d'echeance lui-meme est deja passe.
      expect(acces[2].etatAffiche, EtatAccesAffiche.expire);
      expect(
        acces.every((AccesBeneficiaire a) => a.statutServeur == null),
        isTrue,
      );
      expect(acces.every((AccesBeneficiaire a) => a.motif == null), isTrue);
    });

    test('l adaptateur lit les eleves du foyer et rien d autre', () async {
      final AccesFoyerDepuisEleves port = AccesFoyerDepuisEleves(
        lireEleves: () async => FoyersFictifs.foyerA,
        maintenantUtc: () => maintenant,
      );
      final List<AccesBeneficiaire> acces = await port.acces();
      expect(acces.map((AccesBeneficiaire a) => a.eleveId), <String>[
        FoyersFictifs.a1.id,
        FoyersFictifs.a2.id,
      ]);
      expect(
        acces.any((AccesBeneficiaire a) => a.eleveId == FoyersFictifs.b1.id),
        isFalse,
      );
    });
  });

  group('lisibilite', () {
    test('villeDuFuseau', () {
      expect(villeDuFuseauLibelle('Europe/Paris'), 'Paris');
      expect(villeDuFuseauLibelle('America/New_York'), 'New York');
      expect(
        villeDuFuseauLibelle('America/Argentina/Buenos_Aires'),
        'Buenos Aires',
      );
      expect(villeDuFuseauLibelle('UTC'), 'UTC');
    });

    test('dateLongue', () {
      expect(dateLongue(DateTime(2026, 10, 30, 9)), '30 octobre 2026');
      expect(dateLongue(DateTime(2026, 8, 1)), '1er août 2026');
    });

    test('statutAffiche : seul un statut lu se dit', () {
      expect(statutAffiche(AccountStatus.active)?.valide, isTrue);
      expect(statutAffiche(AccountStatus.provisionalActive)?.valide, isFalse);
      expect(statutAffiche(AccountStatus.pendingKyc), isNull);
      expect(statutAffiche(null), isNull);
    });
  });
}
