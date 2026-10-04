// La saisie des deux panneaux de politique (CPT-DIR-1) : lire un nombre, un
// montant ou un pourcentage tapes, et les rendre dans le texte d'un champ.
//
// **Jamais un `double`** : l'argent est un entier en unites mineures, un
// pourcentage un entier en pour mille (regle transverse du depot). La lecture
// travaille sur les chiffres du texte. **Aucune borne commerciale** : seul un
// nombre strictement positif est exige, et douze chiffres entiers au plus
// (limite technique de l'entier, pas une plage de politique ; R-FIN-08, 09).

import '../../../core/finance/format_montant.dart';
import '../../../core/finance/montant.dart';

/// Le nombre maximal de chiffres de la partie entiere d'une saisie.
const int chiffresEntiersMax = 12;

/// La devise de lancement, utilisee quand la politique n'en porte aucune.
const String deviseDeLancement = 'USD';

/// Les caracteres qu'une saisie accepte : chiffres, separateur decimal,
/// espaces (milliers).
final RegExp caracteresSaisie = RegExp(r'[0-9 .,  ]');

final RegExp _nombre = RegExp(r'^(\d{1,12})(?:[.,](\d+))?$');

/// Lit [texte] comme un nombre positif a [decimales] decimales au plus, et le
/// rend multiplie par `10^decimales` (entier). `null` : vide, zero, trop de
/// decimales ou illisible.
int? lireDecimal(String texte, int decimales) {
  final String net = texte.replaceAll(RegExp(r'[\s  ]'), '');
  final RegExpMatch? m = _nombre.firstMatch(net);
  if (m == null) return null;
  final String fraction = m.group(2) ?? '';
  if (fraction.length > decimales) return null;
  final String complet = '${m.group(1)}${fraction.padRight(decimales, '0')}';
  final int valeur = int.parse(complet);
  return valeur > 0 ? valeur : null;
}

/// Lit un entier strictement positif.
int? lireEntier(String texte) => lireDecimal(texte, 0);

/// Lit un montant dans [devise], en unites mineures.
Montant? lireMontant(String texte, String devise) {
  final int? mineur = lireDecimal(texte, decimalesDe(devise));
  return mineur == null ? null : Montant(mineur, devise);
}

/// Lit un pourcentage (0 exclu, 100 inclus, une decimale au plus) et le rend
/// en pour mille.
int? lirePourMille(String texte) {
  final int? v = lireDecimal(texte, 1);
  return v != null && v <= 1000 ? v : null;
}

String _ecrire(int echelle, int decimales) {
  if (decimales == 0) return '$echelle';
  int facteur = 1;
  for (int i = 0; i < decimales; i++) {
    facteur *= 10;
  }
  final int reste = echelle % facteur;
  final String entier = '${echelle ~/ facteur}';
  return reste == 0
      ? entier
      : '$entier,${reste.toString().padLeft(decimales, '0')}';
}

/// Le texte d'un champ pour [montant] (vide quand il est nul).
String texteMontant(Montant? montant) =>
    montant == null ? '' : _ecrire(montant.mineur, decimalesDe(montant.devise));

/// Le texte d'un champ pour [pourMille] (vide quand il est nul).
String textePourMille(int? pourMille) =>
    pourMille == null ? '' : _ecrire(pourMille, 1);

/// Le texte d'un champ pour un entier (vide quand il est nul).
String texteEntier(int? n) => n == null ? '' : '$n';
