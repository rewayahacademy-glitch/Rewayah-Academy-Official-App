// Mon compte du tuteur en demonstration (L4-02) : la carte d'identite ne
// tombe plus dans l'etat « indisponible » ; elle lit l'identite du titulaire
// par le double de demonstration, sans nom nouveau.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

void main() {
  test(
    'demonstration tuteur : l identite du titulaire est lue, pas indisponible',
    () async {
      final ProviderContainer conteneur = ProviderContainer(
        overrides: surchargesDemoTuteur(environnement: 'staging'),
      );
      addTearDown(conteneur.dispose);

      final IdentiteTitulaire identite = await conteneur.read(
        identiteTitulaireProvider.future,
      );

      expect(identite.prenom, 'Mamadou');
      expect(identite.nom, 'Diallo');
      expect(identite.courriel, 'mamadou.diallo@example.com');
      expect(identite.methodeConnexion, MethodeConnexion.lienCourriel);
    },
  );
}
