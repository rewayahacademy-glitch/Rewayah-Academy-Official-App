/// Un identifiant immuable (« TEACHER-AS-000001 ») tel qu'il s'affiche :
/// chaque trait d'union devient insecable (U+2011), pour que l'identifiant
/// passe entier a la ligne au lieu de se couper a son trait d'union
/// (COUPE-MOTS-4, decide par delegation le 09/10). La donnee, elle, garde
/// son trait d'union ordinaire : seul l'affichage change.
String identifiantInsecable(String identifiant) =>
    identifiant.replaceAll('-', '‑');
