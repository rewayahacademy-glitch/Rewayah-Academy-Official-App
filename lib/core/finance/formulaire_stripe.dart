// Le formulaire de paiement de Stripe, monte dans la page de l'application
// (decision du directeur du 01/11/2026 : « le paiement doit se faire sur
// l'app, pas de sortir ailleurs »). Sur le web, Stripe.js monte son
// formulaire dans un element de la page ; hors web (et dans les tests),
// rien ne se monte.
export 'formulaire_stripe_memoire.dart'
    if (dart.library.js_interop) 'formulaire_stripe_web.dart';
