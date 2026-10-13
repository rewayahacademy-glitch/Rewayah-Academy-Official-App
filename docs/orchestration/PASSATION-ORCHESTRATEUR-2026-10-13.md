# Passation de l'orchestration (13/10/2026)

De : l'orchestrateur Claude, session cloud `session_019TSYR41XkiUyca1QoFUd3y`.
À : le prochain orchestrateur, quel que soit l'agent.
Ce document **remplace** `PASSATION-ORCHESTRATEUR-2026-10-11.md`. Le document du 11/10 reste
valable pour les règles, les décisions et les erreurs à ne pas refaire (§3, §4 et §12) ; il est
périmé pour l'état des lots, des sessions et de Codex.

À lire avant toute action, dans cet ordre :
1. ce fichier ;
2. `CLAUDE.md` ;
3. `docs/current/00_LIRE_D_ABORD.md` ;
4. `docs/orchestration/PASSATION-FIN-CODEX-2026-10-13.md`, qui fait foi pour l'état exact de
   chaque lot backend.

## 1. Ce qui a changé depuis le 11/10

- **Codex est fini.** Son abonnement s'est terminé le 13/10. Il n'y a plus d'agent backend.
  Le backend (`supabase/**`, services, `*_supabase.dart`) revient à Claude. Le garde-fou l'interdit
  aux sessions Claude : seul le directeur peut lever cette zone, par un ordre explicite et daté.
  Tant qu'il ne l'a pas fait, le backend est **gelé**. Il faut le lui dire simplement, sans
  contourner le garde-fou.
- **La feuille Google** (`1v3uuQD9…72WA`) est figée. La ligne 1 des onglets `Codex1 · en cours`
  et `Codex2 · en cours` renvoie au document de fin de Codex. Le jeton Sheets de Codex a expiré.
  Ne plus y attendre de réponse.
- **La routine de contrôle de Codex** (`trig_01HWiuu6J1kymWRzwYhumXdH`) est désactivée. Ne pas
  la recréer : il n'y a plus rien à surveiller.
- **Le PC du directeur est nettoyé** (§5). Tout le travail qui n'existait qu'en local est
  maintenant sur GitHub.

## 2. Le rôle

- Orchestrer les sessions Claude : écrans, relecture et intégration non autrice. Trancher seul les
  questions techniques, par délégation (K-65).
- **Parler au directeur en français simple**, en peu de lignes, sans jargon. Il n'est pas
  technicien.
- **Le contredire quand son idée est mauvaise.** C'est un ordre de sa part : « interdit d'être
  d'accord avec moi si l'idée est mauvaise ».
- **Ne pas lui faire faire de copier-coller inutile.** Il en est fatigué. Écrire soi-même sur le
  tableau ou dans les documents. Quand une action doit se passer sur son PC, lui donner **un seul
  bloc PowerShell complet**, qui ne supprime rien sans vérification préalable (§6).
- **Être sûr avant de casser quoi que ce soit.** Il l'a dit à propos de sa connexion Google et du
  site public. Vérifier sur GitHub avant d'affirmer, puis le dire avec la preuve.
- Réutiliser les sessions existantes. Ne jamais créer de nouvelle session sans son accord.

## 3. Règles permanentes (rappel court ; le détail est au §3 du document du 11/10)

- Pas de push sur `main`, pas de PR vers `main`, pas de fusion de PR, pas de push forcé.
  **Pousser sur `main`, c'est mettre en production.**
- Ni PROD ni STAGING sans un GO du directeur sur un périmètre précis. Jamais la clé `service_role`.
- **GitHub Actions est hors service** : les minutes sont épuisées et il n'y aura pas d'abonnement.
  Toute preuve passe par le rejeu local (PG17, `flutter test`). Les croix rouges de CI sur une PR
  ne sont donc pas des régressions.
- `.claude/hooks/garde.py` ne se modifie que sur ordre du directeur.
  Zones interdites : `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`, `site-public/`,
  `parcours_offres`, `*_supabase.dart`.
  Le garde-fou exige aussi des refspecs **écrites en clair** dans `git push` : pas de variable,
  pas de motif.
- Aucune donnée réelle d'élève ou de famille dans le chat, Git, un test ou la feuille.
- Un lot n'entre dans une branche d'intégration qu'après une vérification par une session **non
  autrice**.

## 4. État au 13/10, et quoi faire ensuite (par ordre)

| # | Quoi | Où | Prochaine action |
| :--- | :--- | :--- | :--- |
| 1 | Backend CONFIRMÉ, pas encore intégré | `PASSATION-FIN-CODEX` §2 | Gelé tant que le directeur n'a pas ouvert `supabase/` à Claude. Ensuite : intégrer dans `codex/backend-canon-fixes` (base `481e9921`, 65/65 en UTF8). |
| 2 | Petites corrections backend (CHANGES) | `PASSATION-FIN-CODEX` §3 | Même condition. |
| 3 | Lots inachevés : IMM-BACK-2, COM-BACK-1 (décisions du directeur attendues), CAP29, C-36 à C-40 | `PASSATION-FIN-CODEX` §4 | Pour COM-BACK-1 : poser au directeur les questions de `docs/orchestration/COM-BACK-1-PROPOSITION.md` (sur la branche `codex/com-back-1-wip` @ `8e0893bb`), en français simple. |
| 4 | Écrans restants : IMM-FRONT-1, IMM-ACCUEIL-FRONT, branchement de l'écran d'envoi CAP29 | branche d'intégration `ccr-1b1bfa0b-m1kvkk` (tête `d5e45ec8` au 13/10) | Travail Claude possible tout de suite, sur des branches `claude/<lot>`. |
| 5 | BR-1, la mise en production du lot | `BR1-CARTE-BRANCHEMENT.md` | GO du directeur attendu vers le 15/10. Avant : Supabase Auth « Confirm Email » activé et CI Postgres en UTF8 (`PASSATION-FIN-CODEX` §5). |
| 6 | Retirer le mode démo par mot de passe | `archive/pc-2026-10-13/patchs`, fichier `rewayah-prod-release.patch` | Ce code est encore dans `main`, inactif en production (`DEMO_AUTH` jamais défini). C'est un petit lot sûr. La partie `service_auth.dart` est dans la zone services : à faire avec l'accord du directeur. |
| 7 | Site public | `codex/site-public-local-2026-10-13` @ `31134c81` (la version la plus récente ; remplace `codex/site-public-preview-main` @ `6549d3c2`) | **Pas publié, et c'est voulu.** Le reprendre seulement sur ordre du directeur (K-64 : Claude Opus). Le publier demande une PR vers `main`, donc une décision du directeur. |
| 8 | Captures | `docs/current/captures` : 4 879 images, 567 Mo | Règle nouvelle : au plus une capture par écran validé ; les autres restent dans le scratchpad. Un lot d'allègement est possible plus tard, sur ordre, sans jamais réécrire l'historique. |
| 9 | Draft PR #34 (documents de passation) | branche `claude/beautiful-ptolemy-xmhiki`, vers `ccr-1b1bfa0b-m1kvkk` | Documents seulement. La CI est rouge à cause d'Actions ; un commentaire l'explique déjà. À fusionner dans ccr par un non-auteur. |

Questions qui attendent encore le directeur (reprises du 11/10, toujours ouvertes à ma
connaissance) :
- CORAN-320-FOND-1 : peut-on retoucher le cadre du mushaf sans toucher au texte ?
- La relecture de l'arabe par un locuteur natif.
- La validation du texte juridique F70 (0090).

## 5. Le PC du directeur (Windows, disques C: et D:)

- **Dépôt principal :** `D:\RA _APP\RA -OFFICIAL-APP`. C'est le seul à garder.
  Il exclut `docs/current/captures` par sparse-checkout ; `git sparse-checkout disable` les
  remet.
- **Copies Codex :** environ 140 copies de travail supprimées le 13/10. Il reste environ 70 Go
  libres sur D: et 32 Go sur C:.
- **Archives sur GitHub :**
  - `archive/pc-2026-10-13/<ancien nom>` : 17 branches qui n'étaient que sur le PC ;
  - `archive/pc-2026-10-13/patchs` : les modifications jamais commitées.
- **À ne pas toucher :**
  - `C:\Users\dell\.claude\skills\apple-hig`, un module de Claude ;
  - les photos, les téléchargements et les visuels de cours du directeur ;
  - `D:\RA_TUTEUR`, un ancien projet tuteur, sauf demande expresse.
- La mémoire Claude locale du directeur est dans `C:\Users\dell\.claude\projects\C--\memory\`.

## 6. Comment faire agir le PC du directeur (leçons du 13/10)

- Toujours `git --no-pager …` ou `git -C <dossier> --no-pager …`. Sans cela : « cannot spawn
  less », et la commande échoue en silence.
- Écrire les résultats dans un fichier `.txt` du Bureau et demander le fichier, pas l'écran. Le
  chat accepte 5 fichiers par envoi.
- Le directeur lance PowerShell en administrateur : le dossier courant est
  `C:\WINDOWS\system32`. Toujours utiliser des chemins complets.
- Pour supprimer : `cmd /c rmdir /s /q "<dossier>"`, puis
  `git -C "D:\RA _APP\RA -OFFICIAL-APP" worktree prune`. Avant de supprimer, toujours :
  `git log HEAD --not --remotes` vide, `status --porcelain` vide, ou une sauvegarde
  (`bundle` + `.patch`) contrôlée.
- Un dossier « copie » (où `.git` est un fichier) partage ses branches avec le dépôt principal.
  `git log --branches --not --remotes` y est donc commun à toutes les copies : vérifier copie
  par copie avec `HEAD`.
- Les avertissements « LF will be replaced by CRLF » ne sont pas des erreurs.

## 7. Sessions Claude

La liste du 11/10 (§5 de l'ancien document) est probablement périmée. Avant d'envoyer un lot,
lire l'état réel avec `list_sessions` / `get_session`, et réutiliser une session libre qui a déjà
Flutter. Ne pas en créer sans accord.

## 8. Erreurs commises le 13/10, à ne pas refaire

- **`git ls-remote` filtré sur `codex/*` seulement.** Les branches `codex2/*` ont semblé
  « disparues ». Toujours lister les deux familles.
- **Une relation de parenté de commits prise pour vraie sans vérification** (B-09 : c'est
  `a8c7a6a5` qui contient r4, pas l'inverse). Vérifier avec `git merge-base --is-ancestor`.
- **Une première liste de ménage trop large** (vérification par branches partagées). Elle a été
  corrigée par une vérification copie par copie.
- **Des commandes PowerShell sans `--no-pager`** : deux échecs.
