// PUSH-1 : le Web Push du navigateur. Sur le web, `web/push_client.js` ;
// ailleurs (tests, applications natives), aucun push.
export 'navigateur_push_memoire.dart'
    if (dart.library.js_interop) 'navigateur_push_web.dart';
