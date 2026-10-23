// Hors web : aucune page de paiement au lancement (guide Finance V4 §1.6).

/// Ne fait rien hors web.
void ouvrirPagePaiement(Uri page) {}

/// L'adresse de retour [route] dans l'application ; hors web, la route seule.
String adresseApplication(String route) => route;
