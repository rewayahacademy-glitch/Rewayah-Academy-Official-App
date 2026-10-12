/// Hors navigateur (mobile, bureau, tests) : aucun onglet a ouvrir. L'ecran
/// ne pose alors aucun bouton « Ouvrir » (jamais un bouton qui ne peut pas
/// aboutir) ; `url_launcher` n'est pas une dependance du projet.
bool Function(Uri)? ouvreurOngletNatif() => null;
