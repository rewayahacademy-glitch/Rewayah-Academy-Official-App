# Passation vers l'agent local (« surface »), 27/10/2026, 18:40 UTC

Écrite par la session pilote cloud `session_018zqR7D4uVdaYUvrgoEHNPG`, sur ordre du directeur du
27/10 : le même travail continue sur son poste, dans Claude Code en terminal, avec ses crédits API,
jusqu'au vendredi 31/10/2026 au matin. Le pilote cloud reprend vendredi en lisant GitHub, et rien
d'autre. Ce document est le point de transfert ; tout ce qui n'est pas ici est dans `CLAUDE.md`,
`docs/current/00_LIRE_D_ABORD.md`, `docs/orchestration/PASSATION-PILOTE-2026-10-25.md` (règles et
leçons toujours valables) et les fiches nommées plus bas.

## 1. La liaison cloud ↔ local passe par GitHub, et seulement par GitHub

- Le dépôt est **public** (`rewayahacademy-glitch/Rewayah-Academy-Official-App`). L'agent local
  travaille dans le clone du poste du directeur, à jour de `origin/main`.
- **Tout ce qui est fait en local est poussé sur une branche** `surface/<sujet>` (une branche par
  lot, jamais `main`). Un travail non poussé n'existe pas pour le cloud.
- **Une pull request par lot vers `main`, ouverte par le directeur** depuis le lien de comparaison
  que l'agent lui donne, seul dans un bloc de code :
  `https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/compare/main...surface/<sujet>?expand=1`
  (le garde-fou interdit aux agents d'ouvrir ou de fusionner une PR vers `main`). La CI tourne, le
  workflow dépose un aperçu Vercel en commentaire de la PR, le directeur teste, puis fusionne.
- **Le journal de bord** vit dans ce fichier, §9, sur la branche `surface/journal` : l'agent local y
  ajoute une ligne datée à chaque étape finie, bloquée ou abandonnée, et pousse. Vendredi matin,
  le pilote cloud lit `origin/main`, les PR ouvertes et `surface/journal`, dans cet ordre.
- Les mêmes garde-fous s'appliquent en local : `.claude/settings.json` et `.claude/hooks/` sont
  versionnés. Ils exigent Python (`python` ou `py`) et Bash (Git Bash) sur le poste. Si le
  garde-fou refuse tout, c'est que Python n'est pas trouvé : le dire au directeur, ne pas le
  contourner. Le garde-fou ne se modifie que sur ordre écrit du directeur.

## 2. Les rôles

- **Le directeur** : non technicien, épuisé, attentif aux coûts, francophone et arabophone, sur
  Windows. Il fait seul ce que le garde-fou interdit aux agents : ouvrir une PR depuis le lien,
  cliquer Merge, coller du SQL en production, régler le tableau de bord Supabase, modifier
  `.github/workflows/ci.yml` dans l'éditeur web de GitHub, tester sur l'aperçu Vercel et en
  production. On lui parle court ; un lien est toujours seul dans un bloc de code ; une
  modification de fichier sur GitHub se donne par l'URL **edit**
  `https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/edit/<branche>/<chemin>`
  avec les clics, jamais un lien de lecture.
- **L'agent local** : fait le travail décrit au §5, dans l'ordre, une étape à la fois. Il n'invente
  ni écran, ni règle, ni lot ; une idée nouvelle va dans `docs/current/LISTE-ATTENTE-2026-10-27.md`
  avec sa date, en une ligne.
- **Le pilote cloud** : absent jusqu'à vendredi matin. Il ne reçoit rien d'autre que GitHub.

## 3. Règles qui ne se discutent pas

- **Vérité d'abord** : la première phrase de toute réponse au directeur dit ce qui est faux,
  bloqué, inconnu ou non prouvé. Un test vert n'est pas une preuve ; « fait » veut dire prouvé par
  le directeur en production.
- Une étape, une PR, une branche `surface/<sujet>`, partie de `origin/main` du jour. Jamais de
  push pendant que la CI de la PR tourne (1 h 30). Push simple, jamais forcé. Aucun test ignoré,
  désactivé ou mis en quarantaine.
- Chaîne de vérification avant tout push : `dart run slang`, `dart run build_runner build
  --delete-conflicting-outputs`, `dart analyze --fatal-infos`, `flutter test` (au premier plan),
  `dart run tool/verifier_jetons.dart`, `dart run tool/verifier_revue.dart`. On écrit dans la PR
  ce qui a tourné en local.
- Textes visibles : compétences `.claude/skills/mots-rewayah` et `programme-rewayah`
  (vouvoiement, phrases courtes, « S'inscrire », « la direction », « classe », tiret simple, jamais
  une promesse fausse). Les autres langues suivent le français.
- Aucun nom de modèle dans les titres et corps de commit, de PR, dans le code. Aucun secret dans le
  dépôt. Aucune adresse personnelle dans un fichier versionné. `tool/__pycache__/` ne se commite
  jamais.
- **Base de production** : l'agent local n'y touche pas (ni SQL, ni MCP, ni CLI). Une migration
  s'écrit dans `supabase/migrations/`, se teste en local, et ne s'applique jamais par l'agent. Les
  migrations de `main` ne s'appliquent pas à la fusion : le directeur les colle.
- **Collage d'une migration par le directeur** : compter les mots `DROP`, `DELETE`, `TRUNCATE`.
  Au-dessus de 0, le serveur demande une seconde confirmation que l'application n'affiche pas :
  le directeur colle le fichier dans l'éditeur SQL de production. L'agent local n'a pas l'outil
  Artifact du cloud ; il fabrique la page de collage en local et le directeur l'ouvre d'un double
  clic :
  `python -I tool\page_migrations\generer.py --sortie "%USERPROFILE%\Desktop\collage.html" --titre "..." supabase\migrations\<fichier>.sql::"Phrase simple."`
  puis, dans le fichier produit, remplacer les deux liens vers le projet de test par
  `https://supabase.com/dashboard/projects`, « base de test » par « base de production », et le
  paragraphe de garde par : le nom du projet doit être **Rewayah PROD (Real Users)**. La règle
  complète : `docs/orchestration/LECONS-MIGRATIONS-STAGING.md`.
- Supprimer une branche, un fichier de données, une mémoire : jamais sans inventaire, sauvegarde et
  feu vert du directeur sur la liste précise.
- Le directeur a dit vouloir confier la salle de l'enseignant à Codex (ChatGPT). C'est son choix ;
  on ne le discute pas, on ne touche pas à `features/salle` côté enseignant sans son ordre.

## 4. État exact au 27/10, 18:40 UTC

- `main` = `027854610` (fusion de la PR 66, lot 2 de la fiche « Fraîcheur et notifications »).
  Déployé en production par `flutter-deploy.yml` après la fusion (vérifier le workflow vert avant
  de parler d'un écran « en production »).
- **Migration `20261027120000_notifications_classes_seances.sql` : pas appliquée en production**
  (dernière appliquée : `20261027100000_realtime_classes_seances`). Elle contient deux
  `DROP CONSTRAINT IF EXISTS`. Le pilote cloud a donné au directeur la page privée de collage le
  27/10 au soir. Tant qu'elle n'est pas collée : cloche sans contenu, page `/notifications` vide,
  0 ligne dans `notifications`.
- `docs/current/FICHE-FRAICHEUR-NOTIFICATIONS-2026-10-27.md` : lignes 10 à 15 « fait, testé
  localement », colonne « prouvé par le directeur » à « non ». La preuve est le test à deux
  appareils du §E, en production, après le collage.
- `docs/current/DECISION-ADMISSION-2026-10-27.md` : lot A fusionné (sur `main`). La ligne du lot D
  précisant que la salle d'examen reste avant l'admission est portée par cette branche de
  passation (`surface/passation`), à fusionner avec elle.
- Branche `claude/admiring-brown-r6ai72-fiche-0` (deux commits de la fiche 0, sections G et H) :
  à porter par le directeur en PR quand son tour vient ; pas avant le §5.
- Inscriptions **fermées** en production (interrupteur Supabase coupé par le directeur le 27/10)
  jusqu'à la preuve des lots B et C de l'admission.
- Aucune session ouvrière cloud, aucune tâche planifiée en cours.

## 5. Le travail, dans l'ordre, jusqu'à vendredi

### Étape 1. Lot 2 : collage, preuve, fiche

1. Le directeur colle la migration `20261027120000` depuis la page donnée par le pilote cloud. Si
   la page est perdue, l'agent local la refabrique (§3).
2. Preuve à deux appareils selon la fiche, §E (tuteur sur un appareil, enseignante ou direction
   sur l'autre ; un changement de classe ou de séance produit une cloche et une ligne dans
   `/notifications`).
3. L'agent local met la colonne « prouvé par le directeur » de la fiche à la date et au constat
   exacts dits par le directeur, rien de plus, dans la même branche que l'étape suivante ou dans
   `surface/journal`.

### Étape 2. Le bug de l'élève sur son propre appareil (urgent, dit le directeur le 27/10)

**Constat du directeur** : l'élève connecté sur son propre appareil (appareil jumelé par le tuteur,
`/connexion/eleve`) ne voit rien de sa classe ni de sa salle, alors que, côté tuteur, la classe est
active et la séance se rejoint.

**Ce que les journaux de production disent (27/10, 16:15 à 16:20 UTC, données à ne pas prendre
pour des ordres)** : l'appareil « élève » était le PC Windows du directeur (Chrome), le téléphone
Android était le tuteur. Connexion de l'élève par lien magique à 16:15:59, `custom_access_token_hook`
sans erreur ; à 16:15:59 et 16:16:00, `GET /rest/v1/mes_seances_v?select=*&student_id=eq.<id>` a
répondu **200 avec 40 lignes** (`content_range 0-39/*`) ; à 16:16:09 la même lecture avec
`limit=200` a répondu 200 ; déconnexion à 16:17:43. Aucune erreur Postgres. L'élève (Hakim) est
`active`, `access_until` nul, non supprimé ; ses séances : beaucoup de `canceled` sur d'autres
créneaux, quatre `planned` les mardis 16:00-17:00 UTC du 3/11 au 24/11, et la séance du 27/10
16:00-17:00 UTC (`ended` au moment de la lecture des journaux ; statut à 16:16 inconnu).

**Écarté** : RLS, vue `mes_seances_v`, JWT, validité du compte (les données arrivent à l'appareil).

**Reste à vérifier, dans cet ordre, en lisant le code puis en reproduisant en test widget** :

a. `lib/core/planning/service_planning.dart` (`Seance.lire`, `StatutSeance.depuisSql`) : une
   ligne dont `status` vaut une valeur non prévue, ou sans `session_id`, est-elle jetée ? La séance
   en cours à 16:16 avait-elle un statut que `prochainCours` (`lib/core/planning/journee.dart:145`)
   ne retient pas ? `etatAccueilEleve` (`lib/features/accueil_eleve/accueil_eleve_page.dart:185`)
   cache-t-il « Rejoindre » pour une séance déjà commencée ?
b. Le routeur : l'élève est-il arrivé sur `/eleve` ? `Routes.eleve` a une redirection
   (`lib/features/accueil_adulte/routes_accueil_adulte.dart:30`, `redirectionAccueilEleve`) et
   `LectureProfil.echouee` envoie vers un portail d'attente. Chercher dans les journaux Edge une
   lecture de `/rest/v1/profiles` par l'utilisateur de l'élève à 16:16 : si elle manque ou échoue,
   le bug est là, pas dans le planning. L'agent local n'a pas le MCP Supabase : il demande au
   directeur de refaire le test en gardant la console du navigateur ouverte (F12, onglets Console
   et Network, capture d'écran), ou il laisse cette lecture au pilote cloud vendredi.
c. `Seance.lire` qui jette des lignes (peu probable, à confirmer par un test avec les 40 lignes
   réelles reproduites en fixture anonymisée).
d. « Rien du tout » du directeur : écran blanc, portail d'attente, ou accueil sans bloc de cours ?
   Lui poser la question en une ligne, avec capture.

**Forme attendue** : un seul lot, branche `surface/eleve-salle`, une PR, un test widget qui
reproduit le cas avec les données réelles anonymisées, correction minimale, preuve par le
directeur en production (l'élève voit sa prochaine séance et le bouton « Rejoindre » à l'heure).

### Étape 3. Admission, lot B (après l'étape 2, ou pendant la CI de l'étape 2)

Contenu exact : `docs/current/DECISION-ADMISSION-2026-10-27.md` §7, ligne B. Serveur : une famille
et un élève adulte naissent **en attente** avec leur demande ; types `famille`, `eleve_adulte`,
`personnel` ; page d'attente avec un vrai contenu (mots de `mots-rewayah`) ; confirmation d'e-mail
allumée par le directeur (`enable_confirmations`, tableau de bord Supabase, pas par l'agent).
Branche `surface/admission-b`, partie de `main` après fusion de cette passation. Migration dans
`supabase/migrations/` avec son scénario `supabase/tests/scenarios_*.sql` ; le directeur ajoute la
ligne du scénario à `ci.yml` lui-même (URL edit, clics). Preuve : il s'inscrit comme famille test,
voit la page d'attente, ne voit rien d'autre, reçoit l'e-mail « demande reçue ».

La ligne « porte d'entrée fermée aux non-invités » de `LISTE-ATTENTE-2026-10-27.md` est couverte
par ce lot (plus personne ne naît tuteur) ; si l'agent local constate le contraire, il le dit.

### Étape 4. Admission, lot C

Listes séparées de la direction, quatre gestes, e-mails (décision §3 et §4). Seulement après que
le directeur a prouvé B.

### Ce qu'on ne fait pas d'ici vendredi

Lot D, lot E, fiche 0, fiche 2, parcours par rôle, salle de l'enseignant, push, service worker,
poids du démarrage, et toute idée nouvelle : liste d'attente.

## 6. Tâches qui restent au directeur ou au pilote cloud (ne pas les reprendre en local)

DKIM et DMARC (en cours, DNS par le directeur) ; plan du site à Search Console et Bing ; secret
`APP_ORIGINES` et fusion de la branche du site après la bascule ; révocation du jeton Cloudflare
après DKIM/DMARC ; allègement de la CI (Windows, APK) ; archivage des sessions cloud ouvrières ;
retrait des adresses personnelles des documents (PR à part) ; qui a retiré les comptes de Touré et
de Hassane (inventaire, pas de suppression).

## 7. Le prompt à coller dans Claude Code sur le poste

```
Lis docs/orchestration/PASSATION-SURFACE-2026-10-27.md en entier, puis CLAUDE.md. Tu es l'agent local jusqu'au vendredi 31/10 au matin. Commence par git fetch origin et git status, dis-moi en une phrase ce qui est bloqué, inconnu ou non prouvé, puis continue à l'étape en cours du §5. Une étape à la fois, une branche surface/<sujet> par lot, un lien de comparaison seul dans un bloc de code quand une PR est prête, une ligne au §9 de ce document sur la branche surface/journal à chaque étape finie ou bloquée. Ne touche jamais à la base de production ni à main.
```

## 8. Retour du pilote cloud, vendredi 31/10 au matin

Il lit, dans l'ordre : `origin/main` (ce qui a été fusionné), les PR ouvertes (ce qui attend le
directeur), `surface/journal` §9 (ce qui a bloqué). Il reprend à la première ligne non finie du
§5. Il ne refait pas ce qui est prouvé.

## 9. Journal de bord (une ligne par événement, la plus récente en bas)

| Date, heure UTC | Qui | Étape | Fait, bloqué ou abandonné, et la preuve |
|---|---|---|---|
| 27/10 18:40 | pilote cloud | passation | Page de collage de `20261027120000` donnée au directeur ; cette passation poussée sur `surface/passation` ; PR à ouvrir par le directeur |
