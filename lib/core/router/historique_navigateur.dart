// PERSONNES-UNE-PAGE, etape (f) (contrat de navigation §4 : « ce qu'on vient
// de fermer ne se rouvre jamais par un geste de retour » ; « le glissement
// depuis le bord et la fleche font exactement la meme chose »).
//
// Dans un navigateur, une page empilee a son entree dans l'historique. Si la
// fleche de l'application retire la page sans reculer dans cet historique,
// l'entree reste : le retour du navigateur la rejoue, et la page qu'on vient
// de fermer se rouvre (vu en navigateur le 20/11/2026, depuis Candidatures,
// Enseignants et Comptes). La fleche recule donc dans l'historique du
// navigateur, comme son bouton de retour. Hors du web, il n'y a pas
// d'historique : la page se retire simplement. Meme motif que
// `fuseau_appareil.dart`.
export 'historique_navigateur_memoire.dart'
    if (dart.library.js_interop) 'historique_navigateur_web.dart';
