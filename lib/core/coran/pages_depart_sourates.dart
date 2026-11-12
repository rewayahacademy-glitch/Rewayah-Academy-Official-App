// SOMMAIRE-SOURATES (directeur, 11/11/2026 : « la table des sourates manque,
// alors qu'elle est standard depuis 14 siecles ; ne bricolez pas le Coran,
// prenez le standard »).
//
// La page ou commence chacune des 114 sourates dans l'edition lue par
// l'application ([codeMushafReference], le Mushaf de Medine en 604 pages).
// Ces nombres ne sont PAS ecrits a la main : ils sont tires du corpus du depot
// (`supabase/migrations/0013_corpus_coranique.sql`, source Tanzil
// quran-data.xml, la meme qu'en base), par la requete
//
//   select sourate_numero, min(page_numero)
//   from public.verset v join public.mushaf m on m.id = v.mushaf_id
//   where m.code = 'madina-hafs-604'
//   group by sourate_numero order by sourate_numero;
//
// `test/core/coran/pages_depart_sourates_test.dart` relit ce corpus et refuse
// tout ecart : on ne corrige jamais un nombre ici sans que le corpus change.
//
// Pourquoi une constante et non une lecture : la pagination d'une edition
// imprimee ne change pas ; la lire demanderait 114 requetes (ou une lecture
// nouvelle a ouvrir cote serveur) pour afficher une table que le lecteur
// attend tout de suite. Les NOMS des sourates, eux, restent lus du corpus
// (`souratesProvider`) : aucun nom n'est recopie.
library;

/// La page de depart de chaque sourate, de la 1re (indice 0) a la 114e.
const List<int> pagesDeDepartDesSourates = <int>[
  1,
  2,
  50,
  77,
  106,
  128,
  151,
  177,
  187,
  208,
  221,
  235,
  249,
  255,
  262,
  267,
  282,
  293,
  305,
  312,
  322,
  332,
  342,
  350,
  359,
  367,
  377,
  385,
  396,
  404,
  411,
  415,
  418,
  428,
  434,
  440,
  446,
  453,
  458,
  467,
  477,
  483,
  489,
  496,
  499,
  502,
  507,
  511,
  515,
  518,
  520,
  523,
  526,
  528,
  531,
  534,
  537,
  542,
  545,
  549,
  551,
  553,
  554,
  556,
  558,
  560,
  562,
  564,
  566,
  568,
  570,
  572,
  574,
  575,
  577,
  578,
  580,
  582,
  583,
  585,
  586,
  587,
  587,
  589,
  590,
  591,
  591,
  592,
  593,
  594,
  595,
  595,
  596,
  596,
  597,
  597,
  598,
  598,
  599,
  599,
  600,
  600,
  601,
  601,
  601,
  602,
  602,
  602,
  603,
  603,
  603,
  604,
  604,
  604,
];

/// La page ou commence la sourate [numero] (1 a 114), ou `null` hors bornes.
int? pageDeDepartDeLaSourate(int numero) =>
    numero < 1 || numero > pagesDeDepartDesSourates.length
    ? null
    : pagesDeDepartDesSourates[numero - 1];
