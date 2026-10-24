// La mise en mots d'un montant (FI-3a, guide Finance V4 §7 « Montants »,
// §11.3 « Chiffres »).
//
// Flutter formate un montant, il ne le calcule jamais (FI6). Ce fichier est
// le **seul** endroit du depot qui transforme un [Montant] en texte : un
// ecran n'ecrit jamais « 50 $ », « usd(50) » ni `mineur / 100` lui-meme.
//
// Regles, toutes tirees du guide :
// - « 50 $ », jamais « 50$ » (§11.3) : une espace insecable entre le nombre
//   et la devise, si bien que le montant ne passe jamais a la ligne ;
// - les centimes seulement quand il y en a : « 50 $ », « 143,20 $ » (les
//   exemples du guide §1.3 et §5.2) ;
// - la devise toujours identifiable (§7) : son symbole quand il est sans
//   ambiguite dans le produit (USD, EUR, GBP), sinon son code ISO ;
// - le signe explicite sur demande (§7) : « +5 $ », « −5 $ » (vrai signe
//   moins U+2212, pas un tiret). Un montant negatif garde toujours son signe.
//
// Le francais fixe les separateurs (virgule decimale, espace fine insecable
// pour les milliers). L'arabe garde les memes chiffres et la meme forme tant
// que le directeur n'a pas tranche l'ecriture des montants en arabe (question
// portee par FI-3a).

import 'montant.dart';

/// L'espace insecable entre le nombre et la devise.
const String _insecable = ' ';

/// L'espace fine insecable des milliers (typographie francaise).
const String _milliers = ' ';

/// Le vrai signe moins.
const String signeMoins = '−';

/// Les devises dont le nombre de decimales n'est pas 2 : la table ISO 4217
/// complete (exposants 0, 3 et 4).
///
/// Miroir exact de `private.devise_decimales` (migration
/// `20261021210300_fi_devises_decimales_iso4217.sql`), qui fait foi : le
/// serveur convertit avec cette table, le client la garde pour formater et
/// saisir hors ligne. `test/core/finance/decimales_devises_test.dart` lit la
/// migration et compare les deux tables : une devise se modifie des deux
/// cotes, jamais d'un seul.
const Map<String, int> decimalesHorsDefaut = <String, int>{
  // 0 decimale.
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
  // 3 decimales.
  'BHD': 3,
  'IQD': 3,
  'JOD': 3,
  'KWD': 3,
  'LYD': 3,
  'OMR': 3,
  'TND': 3,
  // 4 decimales.
  'CLF': 4,
  'UYW': 4,
};

/// Le nombre de chiffres apres la virgule d'une devise (ISO 4217). Une
/// devise hors de [decimalesHorsDefaut] en garde deux, le cas le plus
/// courant.
int decimalesDe(String devise) => decimalesHorsDefaut[devise] ?? 2;

/// Le facteur des unites mineures d'une devise : 100 pour l'USD, 1 pour le
/// franc guineen.
int _facteurMineur(String devise) {
  int facteur = 1;
  for (int i = 0; i < decimalesDe(devise); i++) {
    facteur *= 10;
  }
  return facteur;
}

/// Le montant d'une saisie en unites entieres (« 50 » dollars), converti en
/// unites mineures sans passer par un `double` (FI-11b). Une conversion
/// d'unite, jamais un calcul de prix.
Montant montantDepuisUnites(int unites, String devise) =>
    Montant(unites * _facteurMineur(devise), devise);

/// [montant] en unites entieres pour preremplir une saisie (« 50 »), ou
/// `null` quand il porte des centimes : une saisie entiere ne le
/// representerait pas sans le changer.
int? unitesEntieresDe(Montant montant) {
  final int facteur = _facteurMineur(montant.devise);
  return montant.mineur % facteur == 0 ? montant.mineur ~/ facteur : null;
}

/// Le symbole d'une devise quand il est sans ambiguite dans le produit, son
/// code ISO sinon.
String symboleDe(String devise) => switch (devise) {
  'USD' => r'$',
  'EUR' => '€',
  'GBP' => '£',
  _ => devise,
};

/// [montant] en texte : « 50 $ », « 143,20 $ », « 1 250 $ », « −5 $ » ; avec
/// [signe], un montant positif porte aussi le sien : « +5 $ ».
String formaterMontant(Montant montant, {bool signe = false}) {
  final int decimales = decimalesDe(montant.devise);
  final int absolu = montant.mineur.abs();
  final int diviseur = _facteurMineur(montant.devise);
  final int entier = absolu ~/ diviseur;
  final int reste = absolu % diviseur;
  final String partieEntiere = _grouper(entier);
  final String nombre = reste == 0
      ? partieEntiere
      : '$partieEntiere,${reste.toString().padLeft(decimales, '0')}';
  final String prefixe = montant.mineur < 0
      ? signeMoins
      : (signe && montant.mineur > 0 ? '+' : '');
  return '$prefixe$nombre$_insecable${symboleDe(montant.devise)}';
}

/// Les milliers separes par une espace fine insecable : 1 250, 12 500.
String _grouper(int n) {
  final String chiffres = n.toString();
  final StringBuffer sortie = StringBuffer();
  for (int i = 0; i < chiffres.length; i++) {
    if (i > 0 && (chiffres.length - i) % 3 == 0) sortie.write(_milliers);
    sortie.write(chiffres[i]);
  }
  return sortie.toString();
}
