// L'ouverture de la page de paiement du prestataire (FI-BR-06) et l'adresse
// a laquelle il ramene. Au lancement, le paiement se fait sur le web et en
// PWA (guide Finance V4 §1.6) : la page Stripe remplace l'application dans
// l'onglet, puis Stripe ramene a la page de resultat, qui relit l'etat.
// Hors web, rien ne s'ouvre (aucun achat integre au lancement).
export 'page_paiement_memoire.dart'
    if (dart.library.js_interop) 'page_paiement_web.dart';
