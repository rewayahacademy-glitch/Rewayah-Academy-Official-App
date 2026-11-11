// Garde des mots de resultat interdits a l'ecran (mots-rewayah section 4,
// relayee par le pilote le 11/11/2026) : « Reussi », « Echec », « En progres »,
// « Maitrise » et « A revoir » ne s'affichent jamais. Ils peuvent rester dans
// la base, jamais dans un texte visible.
//
// La garde lit assets/i18n/*.i18n.json et refuse toute valeur qui EST l'un de
// ces mots (un libelle, pas une phrase qui le contient). Les cas encore
// ouverts sont nommes dans [_exceptions], avec leur raison : la liste ne fait
// que retrecir, une entree se retire des que la decision est prise.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const Set<String> _interdits = <String>{
  'réussi',
  'échec',
  'en progrès',
  'maîtrisé',
  'à revoir',
};

/// Cle -> raison. En attente d'une decision du directeur ou du pilote
/// (message de l'agent B du 11/11/2026).
const Map<String, String> _exceptions = <String, String>{
  'enseignant.cahier.niveauEnProgres':
      'echelle de 4 niveaux, mots-rewayah en donne 3 : mot a decider',
  'enseignant.cahier.niveauMaitrise':
      '« Acquis » existe deja dans la meme echelle : mot a decider',
  'tc.outils.intention.aRevoir':
      'intention de revision, distincte de « A renforcer » : mot a decider',
  'tc.parcours.intention.revoir':
      'intention de revision, distincte de « A renforcer » : mot a decider',
  'comptable.statuts.paiement.reussi':
      'statut d un virement, pas un resultat d eleve : mot a decider',
};

Iterable<(String, String)> _valeurs(Object? o, String chemin) sync* {
  if (o is Map<String, dynamic>) {
    for (final MapEntry<String, dynamic> e in o.entries) {
      yield* _valeurs(e.value, chemin.isEmpty ? e.key : '$chemin.${e.key}');
    }
  } else if (o is String) {
    yield (chemin, o);
  }
}

void main() {
  test('aucun libelle i18n n est un mot de resultat interdit', () {
    final List<String> fautes = <String>[];
    for (final File f
        in Directory('assets/i18n')
            .listSync()
            .whereType<File>()
            .where((File f) => f.path.endsWith('.i18n.json'))) {
      final Object? json = jsonDecode(f.readAsStringSync());
      for (final (String cle, String valeur) in _valeurs(json, '')) {
        if (_interdits.contains(valeur.trim().toLowerCase()) &&
            !_exceptions.containsKey(cle)) {
          fautes.add('${f.path} : $cle = « $valeur »');
        }
      }
    }
    expect(fautes, isEmpty);
  });

  test('chaque exception sert encore (la liste ne fait que retrecir)', () {
    final Map<String, Object?> fr = jsonDecode(
      File('assets/i18n/fr.i18n.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final Map<String, String> valeurs = <String, String>{
      for (final (String cle, String valeur) in _valeurs(fr, '')) cle: valeur,
    };
    for (final String cle in _exceptions.keys) {
      expect(
        _interdits.contains(valeurs[cle]?.trim().toLowerCase()),
        isTrue,
        reason: '$cle n est plus un mot interdit : retirer l exception',
      );
    }
  });
}
