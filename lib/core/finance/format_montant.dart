// Mise en forme d'un montant rendu par le serveur (LT-3).
//
// Aucun calcul financier : le montant arrive deja arrete, en unites mineures
// et avec son code ISO 4217. On ne fait que placer la virgule et grouper les
// milliers, sur des chiffres, sans jamais passer par un nombre flottant.
// `intl` n'est pas une dependance du projet : ce formateur le remplace.

/// Les devises dont l'exposant ISO 4217 n'est pas 2 (liste de la norme :
/// exposant 0, 3 et 4).
///
/// ponytail: table fermee ; toute autre devise (XTS compris, dont l'exposant
/// ISO est « sans objet ») est lue avec deux decimales. Quand le serveur
/// rendra l'exposant avec le montant (DB-FIN-01), il remplacera cette table.
const Map<String, int> _exposants = <String, int>{
  // Exposant 0.
  'BIF': 0,
  'CLP': 0,
  'DJF': 0,
  'GNF': 0,
  'ISK': 0,
  'JPY': 0,
  'KMF': 0,
  'KRW': 0,
  'PYG': 0,
  'RWF': 0,
  'UGX': 0,
  'UYI': 0,
  'VND': 0,
  'VUV': 0,
  'XAF': 0,
  'XOF': 0,
  'XPF': 0,
  // Exposant 3.
  'BHD': 3,
  'IQD': 3,
  'JOD': 3,
  'KWD': 3,
  'LYD': 3,
  'OMR': 3,
  'TND': 3,
  // Exposant 4.
  'CLF': 4,
  'UYW': 4,
};

/// Espace fine insecable, separateur des milliers en francais.
const String _milliers = ' ';

/// Espace insecable entre le nombre et la devise.
const String _insecable = ' ';

/// « 1 234,50 EUR » : [mineur] unites mineures de [devise], a la francaise.
///
/// Un montant negatif porte le vrai signe moins (U+2212), lu « moins ».
String formaterMontant(int mineur, String devise) {
  final int exposant = _exposants[devise] ?? 2;
  final String chiffres = mineur.abs().toString().padLeft(exposant + 1, '0');
  final int coupure = chiffres.length - exposant;
  final String entier = chiffres.substring(0, coupure);

  final StringBuffer groupe = StringBuffer();
  for (int i = 0; i < entier.length; i++) {
    if (i > 0 && (entier.length - i) % 3 == 0) {
      groupe.write(_milliers);
    }
    groupe.write(entier[i]);
  }
  final String decimales = exposant == 0
      ? ''
      : ',${chiffres.substring(coupure)}';
  final String signe = mineur < 0 ? '−' : '';
  return '$signe$groupe$decimales$_insecable$devise';
}
