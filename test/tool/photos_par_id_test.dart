// PHOTOS-A (garde-cap, 04/11/2026) : tout portrait d'une personne lit
// `photoPersonneProvider(son id)`, par les composants existants (PhotoEleve,
// PhotoEnseignant, AvatarNom/TuileSansImage avec personneId). Un ecran qui
// passe encore une URL (`urlSignee:`) a un portrait tire son image d'une cle
// copiee ailleurs : la photo posee n'y apparait pas sans recharger.
//
// Ce test echoue si un fichier de lib/features passe `urlSignee:`, hors des
// composants eux-memes et du socle. Le socle ne peut que diminuer : un fichier
// du socle qui n'en a plus besoin doit en sortir.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les composants de portrait : ils transmettent l'URL lue a la source unique
/// a AvatarTile, c'est leur travail.
const Set<String> _composants = <String>{
  'lib/features/tc_mes_groupes/photo_enseignant.dart',
  'lib/features/foyer/photo_eleve.dart',
};

/// Ce qui reste a brancher, et seulement cela.
const Set<String> _socle = <String>{
  // PHOTOS-B (Fin de seance) : l'Accueil famille.
  'lib/features/accueil_famille/carte_classe_seance.dart',
  // Outil de developpement (GALERIE), force a false en production.
  'lib/features/_dev/galerie/catalogue_galerie.dart',
};

void main() {
  test('aucun ecran ne passe une URL de photo a un portrait', () {
    final RegExp url = RegExp(r'\burlSignee\s*:');
    final Set<String> fautifs = <String>{
      for (final FileSystemEntity f in Directory(
        'lib/features',
      ).listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !f.path.endsWith('.g.dart') &&
            url.hasMatch(f.readAsStringSync()))
          f.path.replaceAll(r'\', '/'),
    }..removeAll(_composants);
    expect(
      fautifs.difference(_socle),
      isEmpty,
      reason:
          'Ces ecrans passent une URL de photo au lieu de l id de la '
          'personne (personneId, PhotoEnseignant avec un vrai enseignantId) : '
          '${fautifs.difference(_socle)}',
    );
    expect(
      _socle.difference(fautifs),
      isEmpty,
      reason:
          'Ces fichiers n ont plus d URL de photo : retirez-les du socle, '
          'qui ne peut que diminuer : ${_socle.difference(fautifs)}',
    );
  });
}
