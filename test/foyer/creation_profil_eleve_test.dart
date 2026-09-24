import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/foyer/port_creation_profil_eleve.dart';
import 'package:rewayah_academy/core/foyer/profil_eleve_brouillon.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FunctionException, FunctionsFetchException;

import '../fixtures/tuteur/faux_creation_profil_eleve.dart';
import '../support/harnais.dart';

/// Un service d'appairage dont la creation attend qu'on la libere.
class _AppairageLent extends FauxServiceAppairage {
  final Completer<void> liberation = Completer<void>();

  @override
  Future<void> creerEnfant({
    required String prenom,
    required String nom,
    required int age,
    String? niveau,
  }) async {
    await liberation.future;
    await super.creerEnfant(prenom: prenom, nom: nom, age: age);
  }
}

const BrouillonProfilEleve _complet = BrouillonProfilEleve(
  prenom: '  Eleve C1 ',
  nom: ' Famille C ',
  age: 9,
);

void main() {
  group('K3 : validation du brouillon', () {
    const BornesAge bornes = BornesAge.clientActuelle;

    test('un brouillon vide signale les trois champs requis, dans l ordre', () {
      final Map<ChampProfilEleve, ErreurChamp> erreurs =
          const BrouillonProfilEleve().valider(bornes);

      expect(erreurs.keys, <ChampProfilEleve>[
        ChampProfilEleve.prenom,
        ChampProfilEleve.nom,
        ChampProfilEleve.age,
      ]);
      expect(erreurs.values.toSet(), <ErreurChamp>{ErreurChamp.requis});
    });

    test('des espaces seuls ne remplissent pas un champ', () {
      expect(
        const BrouillonProfilEleve(
          prenom: '   ',
          nom: '\t',
          age: 9,
        ).valider(bornes).keys,
        <ChampProfilEleve>[ChampProfilEleve.prenom, ChampProfilEleve.nom],
      );
    });

    test('les bornes sont incluses, et leur depassement se nomme', () {
      expect(_complet.copyWith(age: bornes.min).valider(bornes), isEmpty);
      expect(_complet.copyWith(age: bornes.max).valider(bornes), isEmpty);
      expect(
        _complet.copyWith(age: bornes.min - 1).valider(bornes),
        <ChampProfilEleve, ErreurChamp>{
          ChampProfilEleve.age: ErreurChamp.horsBornes,
        },
      );
      expect(
        _complet.copyWith(age: bornes.max + 1).valider(bornes),
        <ChampProfilEleve, ErreurChamp>{
          ChampProfilEleve.age: ErreurChamp.horsBornes,
        },
      );
    });

    test('effacer l age le rend de nouveau requis', () {
      expect(
        _complet.sansAge().valider(bornes),
        <ChampProfilEleve, ErreurChamp>{
          ChampProfilEleve.age: ErreurChamp.requis,
        },
      );
      expect(_complet.sansAge().prenom, _complet.prenom);
    });
  });

  group('K3 : qui peut creer quoi', () {
    final CreationProfilEleveAppairage port = CreationProfilEleveAppairage(
      FauxServiceAppairage(),
    );

    test('seul un enfant ou mineur, pour un compte actif', () {
      expect(
        port.peutCreer(PourQui.enfantOuMineur, porte: PorteAcces.actif),
        isTrue,
      );
      for (final PourQui choix in <PourQui>[
        PourQui.procheAdulte,
        PourQui.moiMeme,
      ]) {
        expect(port.peutCreer(choix, porte: PorteAcces.actif), isFalse);
      }
      for (final PorteAcces porte in PorteAcces.values.where(
        (PorteAcces p) => p != PorteAcces.actif,
      )) {
        expect(
          port.peutCreer(PourQui.enfantOuMineur, porte: porte),
          isFalse,
          reason: porte.name,
        );
      }
    });
  });

  group('K3 : creation par creerEnfant', () {
    test(
      'une creation reussie envoie des valeurs nettoyees et relit le foyer',
      () async {
        final FauxServiceAppairage service = FauxServiceAppairage();
        int relectures = 0;
        final CreationProfilEleveAppairage port = CreationProfilEleveAppairage(
          service,
          relireFoyer: () => relectures++,
        );

        final ResultatCreationProfil resultat = await port.creer(_complet);

        expect(resultat, isA<ProfilCree>());
        expect((resultat as ProfilCree).eleveId, isNull);
        expect(service.enfantsCrees.single, (
          prenom: 'Eleve C1',
          nom: 'Famille C',
          age: 9,
        ));
        expect(relectures, 1);
      },
    );

    test(
      'un choix non creable ou un brouillon invalide ne partent pas',
      () async {
        final FauxServiceAppairage service = FauxServiceAppairage();
        final CreationProfilEleveAppairage port = CreationProfilEleveAppairage(
          service,
        );

        final ResultatCreationProfil adulte = await port.creer(
          _complet.copyWith(pourQui: PourQui.procheAdulte),
        );
        final ResultatCreationProfil trop = await port.creer(
          _complet.copyWith(age: 40),
        );

        expect((adulte as CreationRefusee).motif, MotifRefusCreation.refuse);
        expect(
          (trop as CreationRefusee).motif,
          MotifRefusCreation.ageHorsBornes,
        );
        expect(service.enfantsCrees, isEmpty);
      },
    );

    test('un refus 4xx connu se nomme, sans relire le foyer', () async {
      final Map<String, MotifRefusCreation> attendus =
          <String, MotifRefusCreation>{
            'compte tuteur non valide': MotifRefusCreation.compteNonValide,
            'age hors bornes': MotifRefusCreation.ageHorsBornes,
            'prenom, nom et age sont requis': MotifRefusCreation.refuse,
          };
      for (final MapEntry<String, MotifRefusCreation> cas in attendus.entries) {
        int relectures = 0;
        final CreationProfilEleveAppairage port = CreationProfilEleveAppairage(
          FauxServiceAppairage()
            ..erreurAJeter = FunctionException(
              status: cas.key == 'prenom, nom et age sont requis' ? 400 : 403,
              details: <String, dynamic>{'error': cas.key},
            ),
          relireFoyer: () => relectures++,
        );

        final ResultatCreationProfil resultat = await port.creer(_complet);

        expect((resultat as CreationRefusee).motif, cas.value, reason: cas.key);
        expect(relectures, 0, reason: cas.key);
      }
    });

    test('une reponse perdue est incertaine, et le foyer se relit', () async {
      for (final Object panne in <Object>[
        const FunctionsFetchException(details: 'coupure'),
        const FunctionException(status: 504),
        const FunctionException(status: 500),
        StateError('delai depasse'),
      ]) {
        int relectures = 0;
        final CreationProfilEleveAppairage port = CreationProfilEleveAppairage(
          FauxServiceAppairage()..erreurAJeter = panne,
          relireFoyer: () => relectures++,
        );

        expect(
          await port.creer(_complet),
          isA<CreationIncertaine>(),
          reason: '$panne',
        );
        expect(relectures, 1, reason: '$panne');
      }
    });

    test('une double soumission ne cree qu un profil', () async {
      final _AppairageLent service = _AppairageLent();
      final CreationProfilEleveAppairage port = CreationProfilEleveAppairage(
        service,
      );

      final Future<ResultatCreationProfil> premier = port.creer(_complet);
      final Future<ResultatCreationProfil> second = port.creer(_complet);
      expect(identical(premier, second), isTrue);

      service.liberation.complete();
      await Future.wait(<Future<ResultatCreationProfil>>[premier, second]);
      expect(service.enfantsCrees, hasLength(1));

      // Une fois la premiere terminee, une nouvelle creation repart.
      await port.creer(_complet);
      expect(service.enfantsCrees, hasLength(2));
    });
  });

  group('K3 : le double du port', () {
    test('rejoue une creation incertaine et garde les envois', () async {
      final FauxCreationProfilEleve faux = FauxCreationProfilEleve(
        resultat: const CreationIncertaine(),
      );

      expect(await faux.creer(_complet), isA<CreationIncertaine>());
      expect(faux.envois.single, _complet);
    });
  });
}
