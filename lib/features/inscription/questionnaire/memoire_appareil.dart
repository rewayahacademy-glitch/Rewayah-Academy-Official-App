// Ou le questionnaire d'inscription attend la connexion. Sur le web, le
// `localStorage` du navigateur : le lien de connexion s'ouvre souvent dans un
// nouvel onglet, et les reponses doivent l'y retrouver. Hors web, la memoire
// de l'application.
export 'memoire_appareil_memoire.dart'
    if (dart.library.js_interop) 'memoire_appareil_web.dart';
