{{flutter_js}}
{{flutter_build_config}}

// Lot ouverture rapide (29/10/2026).
// - Aucun service worker : celui de Flutter est obsolete et le fichier servi
//   ne fait que se desinscrire puis RECHARGER la page, ce qui doublait la
//   premiere ouverture. Le fichier reste construit : un ancien service worker
//   encore installe le recoit a sa prochaine mise a jour et se retire.
// - Le moteur de rendu (canvaskit) est servi par l'application, plus par
//   www.gstatic.com (web/index.html le precharge).
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
});
