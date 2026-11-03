// ANTI-ROBOT (03/11/2026) : le rendu du widget Turnstile. Sur le web, le
// script de Cloudflare (charge par web/index.html) monte son widget dans un
// element de la page ; hors web (et dans les tests), rien ne se monte.
export 'rendu_turnstile_memoire.dart'
    if (dart.library.js_interop) 'rendu_turnstile_web.dart';
