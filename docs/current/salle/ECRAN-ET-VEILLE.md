# L'écran qui s'éteint et la salle (lot ECRAN-EVEILLE, 11/11/2026)

Plainte du directeur, le 11/11/2026 : « quand l'écran s'éteint, la plupart du temps, la connexion
se coupe. Lorsqu'on rallume l'écran, on doit attendre que la reconnexion se fasse et que la voix
revienne. […] Il ne faut pas que l'extinction de l'écran coupe le réseau ou bien coupe la voix ou
le micro. »

**À savoir d'abord : rien de ce qui suit n'est prouvé en production.** Les tests automatiques
passent, mais un test vert n'est pas une preuve. La preuve, c'est le directeur qui la fait, sur
son téléphone, après fusion (voir « Comment le vérifier » en bas).

## 1. Ce que l'application fait maintenant

1. **L'écran reste allumé pendant toute la séance.** Dès que l'appel est ouvert, l'application
   demande au navigateur de ne pas éteindre l'écran. Elle le redemande chaque fois que la page
   revient au premier plan, parce que le navigateur rend ce verrou tout seul dès que la page est
   cachée. Elle le rend en quittant l'appel. Cela vaut aussi quand la salle est réduite et que
   la barre « Séance toujours en direct » est affichée.
2. **Au retour, l'appel reprend tout seul.** Si la connexion est tombée pendant la veille,
   l'application la rétablit sans qu'on touche à rien. Le micro et la caméra retrouvent l'état
   d'avant : ouvert reste ouvert, fermé reste fermé. Un micro que la personne avait fermé, ou que
   l'enseignant avait coupé, n'est jamais rouvert. Rien ne s'ouvre si le serveur n'en donne plus
   le droit. Le son reçu est relancé.
3. **Si la reprise échoue** au bout d'environ une minute et quart (les essais de LiveKit, environ
   45 secondes, puis les nôtres, environ 30 secondes), alors seulement la salle affiche
   « connexion perdue » avec « Réessayer », comme avant. Si la page est encore cachée à ce
   moment, l'application ne renonce pas : elle attend le retour et recommence.
4. **Rien n'est coupé quand la page passe en arrière-plan** : ni le micro, ni le son reçu, ni la
   connexion. Le code ne l'a jamais fait ; c'est vérifié (voir § 4).

## 2. Ce que le web peut garantir, et ce qu'il ne peut pas

Le verrou d'écran du web (« Screen Wake Lock ») empêche **l'extinction automatique** de l'écran
au bout de quelques minutes sans toucher. **Il ne peut pas empêcher la personne d'éteindre
l'écran elle-même**, ni le téléphone de passer en économie de batterie.

| Appareil | L'écran reste allumé ? | Source |
| :--- | :--- | :--- |
| Ordinateur, Chrome ou Edge | Oui, depuis la version 84 | MDN, données de compatibilité de `WakeLock.request` ; Chrome for Developers |
| Android, Chrome | Oui, depuis la version 84 | MDN, mêmes données (Chrome Android suit Chrome) |
| Ordinateur, Firefox | Oui, depuis la version 126 | MDN, mêmes données |
| Mac, Safari | Oui, depuis Safari 16.4 | MDN, mêmes données |
| iPhone, Safari (onglet) | Oui, depuis iOS 16.4 | MDN, mêmes données |
| iPhone, application installée sur l'écran d'accueil (PWA) | Oui seulement depuis iOS 18.4 ; avant, l'API existait mais ne marchait pas dans une application installée | MDN, mêmes données (note : « Does not work in standalone Home Screen Web Apps », bogue WebKit 254545) |
| Android, application installée (PWA) | Non vérifié séparément ; c'est le même moteur que Chrome | non vérifié |
| Navigateur trop ancien | Rien ne se passe, aucune erreur visible ; l'écran s'éteint comme avant | comportement de notre code |

Le navigateur peut **refuser** le verrou : économie d'énergie, batterie faible, page cachée, ou
réglage du système. MDN le dit ainsi : « A request may be rejected for a number of reasons,
including system settings (such as power save mode or low battery level) or if the document is
not active or visible. » Dans ce cas, l'application continue sans rien afficher.

Le verrou **est rendu tout seul** quand la page est cachée (onglet changé, fenêtre réduite,
écran éteint). MDN : « previously acquired locks are automatically released when document
becomes inactive » ; Chrome for Developers : « automatically released when you minimize a tab or
window ». C'est pour cela que l'application le redemande à chaque retour (recommandation de MDN :
« re-acquire screen wake lock if necessary when document becomes active (listen for
visibilitychange event) »).

Le verrou n'est accordé qu'en HTTPS (MDN : « available only in secure contexts »).
`app.rewayahacademy.com` est en HTTPS.

## 3. Quand la personne éteint l'écran elle-même (bouton d'arrêt)

Aucune source officielle ne décrit précisément ce cas : ni MDN, ni Chrome for Developers ne
parlent du bouton d'arrêt. Voici ce qui est établi, et ce qui ne l'est pas.

- **Établi** : la page devient « cachée », comme un onglet qu'on quitte. Le verrou d'écran est
  rendu par le navigateur (MDN, ci-dessus). L'application le redemande au rallumage.
- **Établi pour Chrome** : une page cachée qui utilise WebRTC ou joue du son n'est pas supprimée
  par Chrome, « unless under extreme resource constraints » (Chrome for Developers, « Page
  Lifecycle API », liste « Playing audio », « Using WebRTC »). La même page dit aussi que sur
  Android, iOS et Windows récents, le système peut arrêter une application à tout moment.
- **Non vérifié, Android Chrome** : que l'appel continue pendant que l'écran est éteint (voix
  entendue, micro qui part). C'est le comportement attendu d'une page WebRTC non gelée, mais nous
  ne l'avons pas mesuré. Si le réseau du téléphone s'endort et que la connexion tombe, notre
  reprise automatique la rétablit au rallumage.
- **Non vérifié, iPhone Safari** : des rapports de bogues WebKit (non officiels : bogues 226620,
  173268 et suivants) décrivent un micro mis en sourdine quand la page passe en arrière-plan,
  une piste qui s'arrête après environ 30 secondes en arrière-plan, et, dans une application
  installée, un micro perdu dès que l'écran se verrouille. Nous ne l'avons pas mesuré nous-mêmes.
  L'application traite ces cas au retour : une piste arrêtée est rouverte si elle était voulue
  ouverte, une piste en sourdine est relancée.
- **Ce que le web ne peut pas faire** : garder le micro d'un iPhone actif écran verrouillé. Si
  c'est indispensable, il faudra une application native (hors de ce lot ; c'est une décision du
  directeur).

**En pratique : pendant une séance, ne pas appuyer sur le bouton d'arrêt.** L'écran ne s'éteint
plus tout seul ; s'il est éteint à la main, l'appel reprend tout seul au rallumage, micro et
caméra comme avant, en quelques secondes au plus si la connexion était tombée.

## 4. Pourquoi le micro et la caméra revenaient fermés (cause trouvée)

- Pendant la veille, la connexion tombait. LiveKit essaie de la rétablir pendant environ 45
  secondes (dix essais), puis abandonne. La salle passait alors en « connexion perdue » ; le bouton
  « Réessayer » rouvrait **une salle neuve**, et une salle neuve s'ouvre toujours micro et caméra
  fermés (règle du 25/10/2026 : rien ne s'ouvre à l'entrée sans geste). D'où le micro fermé au
  retour. Correction : le moteur reprend lui-même l'appel, en gardant le souvenir de ce que la
  personne avait ouvert (`lib/core/video/livekit_session_provider.dart`, `_reprendreSansGeste`,
  `mediasARestaurer`).
- Dans un navigateur, Flutter ne signale jamais « application suspendue » (`paused`) : un onglet
  caché arrive en `hidden` (lu dans le moteur web de Flutter, `app_lifecycle_state.dart`). Le
  contrôleur de séance ne voyait donc jamais le retour. Il le voit maintenant
  (`lib/core/tc_classe/session_persistante.dart`).
- Sur téléphone natif, au retour, si la connexion n'avait jamais été perdue, le message de retour
  restait affiché pour rien (aucun événement ne venait le faire tomber). Corrigé : si le moteur
  dit que le lien est là, le message tombe tout de suite.
- **Le passage en arrière-plan ne coupait rien** : aucun code de la salle ne coupe le micro, le son
  reçu ou la connexion sur `paused`, `hidden` ou `inactive` (vérifié dans `lib/core/video`,
  `lib/core/tc_classe`, `lib/features/salle*` ; le seul autre observateur du cycle de vie de la
  salle, le chrono, se recalcule au retour et ne touche pas à l'appel).

## 5. Limites connues

- Application installée Android ou iOS (non web) : le verrou d'écran est **sans effet** ; il
  faudrait une nouvelle dépendance, interdite dans ce lot. La production est l'application web.
- Si le jeton d'entrée a expiré pendant une longue coupure (15 minutes par défaut), l'application
  en demande un neuf au serveur. Si le serveur refuse (séance terminée, accès retiré),
  l'application ne force rien : « connexion perdue » et « Réessayer », comme avant.
- Un navigateur peut refuser de rouvrir le micro sans geste. Dans ce cas, le bouton du micro le
  montre coupé, et un appui le rouvre.
- Si le serveur a changé les droits de la personne pendant la coupure, l'écran de la salle peut
  garder un temps les anciens boutons ; le moteur, lui, relit le droit avant d'ouvrir quoi que ce
  soit.

## 6. Comment le vérifier (directeur, en production, après fusion)

1. Téléphone Android, Chrome : entrer en séance, micro ouvert. Poser le téléphone sans le toucher
   plus longtemps que le délai de mise en veille réglé. **Attendu : l'écran ne s'éteint pas.**
2. Même séance : appuyer sur le bouton d'arrêt, attendre une minute, rallumer. **Attendu : la voix
   revient seule, le micro est toujours ouvert, sans rien toucher.**
3. Même essai micro fermé. **Attendu : le micro reste fermé.**
4. iPhone, Safari puis application installée (iOS 18.4 ou plus) : refaire 1 et 2.

## Sources

- MDN, Screen Wake Lock API : https://developer.mozilla.org/en-US/docs/Web/API/Screen_Wake_Lock_API
- MDN, `WakeLock.request()` : https://developer.mozilla.org/en-US/docs/Web/API/WakeLock/request
- Données de compatibilité MDN (`api/WakeLock.json`, lues le 11/11/2026) :
  https://github.com/mdn/browser-compat-data/blob/main/api/WakeLock.json
- Chrome for Developers, Screen Wake Lock : https://developer.chrome.com/docs/capabilities/web-apis/wake-lock
- Chrome for Developers, Page Lifecycle API : https://developer.chrome.com/docs/web-platform/page-lifecycle-api
- WebKit, bogue 254545 (verrou dans les applications installées) : https://bugs.webkit.org/show_bug.cgi?id=254545
- WebKit, rapports de bogues sur le micro en arrière-plan (non officiels) :
  https://bugs.webkit.org/show_bug.cgi?id=226620 , https://bugs.webkit.org/show_bug.cgi?id=173268
