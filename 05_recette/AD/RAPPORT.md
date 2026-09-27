# Rapport de la vague Admin (dossiers KYC) — pour le directeur

*Rédigé le 27/09/2026. Branche `ui/admin-v1`, dépôt `D:\RA_TUTEUR\admin`.*

## En bref (sans jargon)

- Nous avons construit tout l'écran où un administrateur regarde le dossier d'un enseignant, vérifie ses papiers, et dit oui ou non. C'est fait à l'écran, testé, et les images sont prises en clair et en sombre, sur téléphone et sur ordinateur.
- **Dire « oui » (valider un enseignant) ne marche pas encore en production.** Le bouton reste grisé avec le message « La validation est indisponible pour le moment. » C'est volontaire : le serveur ne garantit pas encore que dire « oui » active vraiment le compte correctement. Tant que ça n'est pas garanti, on préfère bloquer plutôt que risquer une erreur.
- **Dire « non » (refuser) marche en production, mais avec un risque** : si deux administrateurs refusent le même dossier en même temps (ou le même administrateur deux fois de suite), le serveur accepte les deux refus au lieu d'en bloquer un. Il faudra décider si on ferme aussi le refus en attendant la correction.
- L'accessibilité (utilisation au clavier, texte agrandi, écran très étroit) est maintenant **entièrement corrigée, sauf un point qui attend votre décision** : l'onglet « Politique de genre » déborde à 320 px avec la police de test (probablement pas avec la vraie police, voir §4) — 4 cas, 5 tests, volontairement « sautés » pour garder la suite verte.
- **Rien n'est fusionné dans la branche principale (`main`).** Tout reste sur la branche de travail `ui/admin-v1`, qui est bien poussée en ligne. Aucune mise en production n'a eu lieu à cause de ce travail.
- Ce rapport et les captures ne touchent que le dossier de recette (`05_recette\AD`) ; rien n'a été commité depuis ce dossier.

---

## 1. Étapes de la vague et commits

La vague part de l'écran général (« coque ») et va jusqu'à l'accessibilité (AD-11). Chaque étape a son ou ses commits sur `ui/admin-v1` :

| Étape | Sujet | Commit(s) |
|---|---|---|
| AD-4 | Ports neutres de revue (dossiers + politique de genre), pont de démonstration `?demo=admin` | `b2d53fe`, corrections `5028dac` |
| AD-S | Coque admin alignée sur 02A (recherche en feuille, thème, pied utilisateur) | `d3cb857`, corrections `ab1101c` |
| AD-5 | File ADM-02A (liste des dossiers), maître-détail 1440, squelette de chargement | `c7c6555`, `7694c84`, corrections `e636017` |
| HL-A-1 | Squelette de capture, pastille alignée, focus au titre quand la file se vide | `0d5bda5` |
| AD-6 | Revue ADM-02B (fiche d'un dossier : identité, pièce, vérifications, accords) | `cdc55b0`, captures `b76d370`, corrections `8192bf8` |
| AD-7 | Visionneuse de pièce ADM-02C (plein écran / dialogue, zoom) | `466fdcc`, captures `37b7430`, corrections `d932248` |
| HL-A-2 | Aperçu signé (60 s), images seulement — repris dans le commit AD-7 `466fdcc` | *(pas de commit séparé)* |
| HL-A-3 | Alignement des liens de vérification, réglages par mesure de texte | `4d0890e` |
| AD-8 | Décisions ADM-02D (refus) / ADM-02E (validation), machine d'état de session | `ac796cb`, captures `33e80e1`, corrections `bba3293` |
| HL-A-4 | `AppBottomSheet` respecte le retour système et le clavier | `3dd89f4` |
| AD-9 | Politique de genre KYC (réglage Super Admin) | `15c6cd7`, captures `c691a34`, corrections `045a035` |
| AD-10 | Portail d'attente : famille dispensée, pièce absente, retour après décision | `ff1a933`, corrections `1be1150` |
| AD-11 | Accessibilité (reflow, clavier, texte 200 %), langues (K-41), critères de recette, corrections des défauts trouvés, captures de preuve | `bc4c619`, `049a954`, `4542bfd`, puis 6 commits de restes `d5ead30`, `c30cf29`, `98a0d86`, `17b70e3`, `6a40d07`, `e124872`, puis captures `f73dd41` |

*Note (corrigée) : l'étape **AD-G1** existe bel et bien, mais côté pilotage, pas côté code : c'est le contrôle des règles gelées DESIGN-GOV-2026-09-26 (comparaison ligne à ligne avec la spec), rapporté dans `11_admin/AD-G1_CONTROLE.md` (dépôt pilotage), commit `db9238c` — un seul fichier de rapport ajouté, aucun fichier du dépôt `admin` touché. AD-G1 a donc été fait **sans commit de code**, ce qui est normal pour une étape de contrôle. Dans l'historique du dépôt `admin`, la première étape de code de la vague est **AD-4** ; le nom le plus proche pour la coque générale est AD-S.*

## 2. État de la branche `ui/admin-v1`

- **Dernier commit poussé :** `f73dd41` — « admin(AD-11): captures de preuve accessibilite - coque, file, revue, visionneuse, refus, validation, politique a 320x640 (reflow) et 390x844 texte 200 %, clair et sombre ; erreurs de rendu relevees au journal (DEFAUT) sans faire echouer la capture ; saute sans CAPTURE_DIR ». Vérifié avec `git -C D:\RA_TUTEUR\admin log --oneline -1`.
- `git status` : branche à jour avec `origin/ui/admin-v1`, aucun fichier en attente (arbre propre).
- Aucune Pull Request ouverte, `main` non touché.
- Ordre réel des commits AD-11 après `4542bfd` (critères de recette prouvés) : 6 commits de correction des défauts d'accessibilité — `d5ead30` → `c30cf29` → `98a0d86` → `17b70e3` → `6a40d07` → `e124872` — puis `f73dd41` (captures de preuve). Un précédent rapport avait annoncé `1be1150` comme point de départ ; ce n'est pas exact, `1be1150` est le commit *précédent* la vague AD-11 (corrections AD-10).

## 3. Chiffres du dernier passage complet

| Contrôle | Résultat |
|---|---|
| `flutter analyze --fatal-infos` (tout le dépôt) | Aucun problème (« No issues found! »), code 0, 13,5 s |
| `flutter test --reporter expanded` (suite complète, un seul passage sous verrou, 02:50–03:05) | **+2967 réussis, ~844 sautés, 0 échec** — « All tests passed! », code 0, 915 s — journal `suite_complete_ad11_final.log` |
| Échecs constatés | Aucun (donc aucune relance nécessaire) |

Sur les 844 tests sautés, **271 viennent de la vague Admin** :
- **267 tests de capture**, sautés parce que `CAPTURE_DIR` n'est pas posé pendant la suite (voulu ; ils passent tous quand la variable est posée) : coque_admin 7, AD-5 10, AD-6 44, AD-7 32, AD-8 70, AD-9 50, AD-10 38, AD-11 16.
- **5 tests de la politique de genre**, bloqués par une décision du directeur (4 entrées dans `_restes`, voir tableau ci-dessous) : reflow 320, reflow 400 %, texte 200 %, Tab (focus jamais masqué), cibles 48 px à 320 (partage la même entrée `_restes` que le reflow 320, donc 2 tests sautés pour cette seule entrée).

L'origine des autres tests sautés (~573) n'a pas été vérifiée dossier par dossier.

## 4. Accessibilité (tableau écran × critère)

**Tableau final.** Tous les défauts trouvés par `test/accessibilite/admin_ad11_test.dart` (liste `_restes`) sont corrigés après 6 passages de correction, **sauf la politique de genre (AD-9), bloquée par une décision du directeur** (voir plus bas). 32 captures de preuve AD-11 existent dans `captures\AD-11` (320×640 et 390×844 à 200 %, clair/sombre, 0 échec).

| Écran | Reflow 320 / 400 % | Clavier | Focus non masqué | Texte 200 % (390/1440) | Cibles 48 px | Libellés |
|---|---|---|---|---|---|---|
| AD-S coque | corrigé / corrigé | ok | ok | corrigé / corrigé | ok | ok |
| ADM-02A file | corrigé / corrigé | ok | ok | corrigé / corrigé | ok | ok |
| ADM-02B revue | corrigé / corrigé | corrigé (ordre de tabulation file→détail) | corrigé | corrigé / corrigé | ok à 320, ok à 1440 | ok |
| ADM-02C visionneuse | corrigé / corrigé | ok | ok à 320, ok à 1440 | corrigé / corrigé | ok à 320, ok à 1440 | ok |
| ADM-02D refus | corrigé / corrigé | corrigé (clavier virtuel, 320 et 1440) | corrigé | corrigé / corrigé | ok à 320, ok à 1440 | ok |
| ADM-02E validation | corrigé / corrigé | ok | ok à 320, ok à 1440 | corrigé / corrigé | ok à 320, ok à 1440 | ok |
| AD-9 politique | **bloqué (décision) / bloqué (décision)** | ok | **bloqué (décision) à 320**, ok à 1440 | **bloqué (décision) à 390** / corrigé à 1440 | **bloqué (décision) à 320**, ok à 1440 | ok |
| AD-10 /attente | ok / corrigé | ok | ok | ok / ok | ok | ok |

Survol de ligne à la souris simulée : **tranché**, ce n'est pas un défaut de l'écran mais une limite du banc de test (le `FocusManager` reste en mode « touch » après un `tester.tap`, donc `onShowHoverHighlight` n'est jamais appelé) ; le test n'est plus sauté et passe. À confirmer si on le souhaite sur un vrai poste avec une vraie souris.

Corrections faites (dans les composants partagés, sans doubler le code) : tiroir admin borné à 320 px et son libellé, en-tête de `PageShell` qui défile désormais avec le corps sous 360 px de haut (390/200 % et 1280×1024/400 %), `AppBottomSheet` qui défile d'un bloc sous 360 px et se retire du clavier virtuel au bureau, squelette du détail remplacé par un `Wrap`, ordre de tabulation du maître-détail (`FocusTraversalGroup`), défilement automatique de la barre d'onglets et de la file jusqu'à l'élément focalisé, étiquette du motif de refus passée en `Text` multiligne, colonne de la visionneuse qui défile sous 360 px de haut.

**Bloqué par décision du directeur — politique de genre (AD-9) :** 4 entrées dans `_restes` (5 tests, la cible 48 px à 320 partageant l'entrée du reflow 320) restent sautées. Cause commune : l'onglet « Politique de genre pour la revue KYC » de `SousNavigationDomaine` mesure 576 px de large avec la police de test (plus que la vue de 320 px), et le `Tab` de Material ne passe pas à la ligne (`softWrap: false`) — le toucher et le focus retombent hors de l'onglet. Corriger demande un onglet sur deux lignes ou un libellé plus court dans ce composant **partagé**, visible sur tous les lots déjà livrés (Pédagogie, Personnes, Sécurité, Configuration) : c'est pour cela que la décision revient au directeur, de même que la question de faire charger les vraies polices au banc de test pour ce cas. **Élément nouveau pour cette décision** : avec les vraies polices, la capture `ad11_7_politique_320x640@1_dark.png` montre l'onglet entier dans une vue de 320 px — le débordement de 576 px viendrait donc de la police de test utilisée par le banc, pas de l'écran réel.

Point additionnel prouvé : la garde du routeur admin est vérifiée pour chaque rôle (admin passe, tuteur → accès refusé, enseignant/contrôleur/comptable/élève renvoyés chez eux), la tuile compteur de l'accueil mène à la bonne route et redescend après une décision, la purge de la file au changement de profil/déconnexion est prouvée, les trois états de la liste ADM-02A (actualisation, sélection retirée, capacité absente) sont prouvés, le contraste des pastilles de statut est prouvé (≥4,5:1 texte, ≥3:1 pastille), et aucune URL de stockage ne part vers Sentry (corrigé). Le focus clavier et le survol souris sont désormais prouvés.

Le focus visible au sens strict (2.4.7) n'a été mesuré que par ce dernier test ; ailleurs, seule la bordure de focus des champs est couverte (`clavier_test.dart`).

## 5. Langues (K-41)

Audit des 43 fichiers `lib` touchés par la vague (hors fichiers générés `*.g.dart`).

**Corrigé** (deux écarts, tous deux introduits par cette vague) :
- Date/heure/zone de revue écrites en dur (`dd/MM/yyyy`, `HH:mm`, `'UTC'`) → remplacées par 3 clés `dossiers.file` (`dateChiffres`, `heureChiffres`, `zoneUtc`).
- Nom complet construit par concatenation (`'${prenom} ${nom}'`) → remplacé par la clé existante `dossiers.decision.nomComplet`.

**Reste, hors vague** (code déjà présent avant, non touché ici) : formats de date en dur dans `attente_page.dart`, `journal_page.dart`, `consentement_observation_page.dart`, `profil_enseignant_page.dart` ; pluriel fait à la main dans `comptes_page.dart` ; concaténations de libellés dans `journal_page.dart` et `service_validation.dart`.

**Reste, dans la vague mais non rouvert faute de défaut prouvé** : le choix « de / d' » par élision de code (peut donner la même phrase dans une autre langue) ; les données de démonstration en français (pas du texte d'interface) ; une reconnaissance d'erreur basée sur le texte français renvoyé par le serveur (fragile si le serveur change son message) ; les chiffres restent en écriture latine (`intl` n'est pas une dépendance, `pubspec.yaml` interdit d'y toucher).

**Traductions arabes du nœud `dossiers` : absentes.** 0 clé sur 121 dans `strings_ar.g.dart` ; repli sur le français. En attente des textes fournis ou validés par le directeur.

## 6. Frontière (aucun élargissement de permission)

- `git diff 73f12c8..HEAD -- supabase .github vercel.json pubspec.yaml lib/core/theme` est **vide** : rien touché côté secrets, CI, configuration de déploiement ou thème.
- Aucun appel serveur nouveau. Les seules lignes ajoutées contenant `.rpc(`, `.from(`, `functions.invoke`, `createSignedUrl` ou `storage.` sont des commentaires, des `select` Riverpod, ou une variable locale nommée `rpc` qui enveloppe une méthode déjà existante.
- Trois appels déjà présents dans la base sont réutilisés tels quels : la RPC `dossiers_en_attente` (file), `storage.from(...).createSignedUrl` 60 s (visionneuse), la RPC `decider_dossier` (décision).
- La politique de genre (AD-9) ne fait aucun appel serveur : le port renvoie `CapaciteIndisponible` (AD-BR-16/17).

## 7. Matrice de recette (60 critères)

27 critères prouvés par un test, 16 non prouvés (défaut ou absence de test), 17 dépendent du serveur (hors de portée du client).

| Critère | Statut | Preuve / raison |
|---|---|---|
| 22.1 Admin autorisé → ADM-02 | prouvé | Coque + pont de démo, testés ; la file réelle dépend du serveur (AD-BR-01) |
| 22.1 Compteur Accueil → même route | non prouvé | Aucun test ne tape la tuile du compteur elle-même |
| 22.1 Enseignant sans habilitation | non prouvé | Redirections testées seulement pour élève/tuteur, sur une autre route |
| 22.1 Tuteur sans habilitation | prouvé | Redirection vers accès refusé, testée |
| 22.1 Élève sans habilitation | prouvé | Redirection testée |
| 22.1 Contrôleur/comptable sans habilitation | non prouvé | Aucun test pour ces deux rôles sur cette route |
| 26 quater Accès par capacités | serveur | AD-BR-18 : aucune capacité serveur dédiée, `app_role` seul |
| 22.2 File réellement revue par le serveur (AC-01) | serveur | AD-BR-01 : manque une ligne par personne, total et curseur |
| 22.2 Liste vide réelle | prouvé | Testé (adaptateur de production, faux service) |
| 22.2 Pagination / filtre sans résultat fabriqué | serveur | AD-BR-01 : aucun curseur ; absence conforme à la revue UX |
| 22.2 Position restaurée après retour | prouvé | Testé (focus sur la ligne, mémorisation de la position) |
| 22.3 Bon dossier ouvert | prouvé | Testé |
| 22.3 Aucune fuite d'un autre dossier (AC-02) | serveur | AD-BR-02 : détail reconstruit depuis la file en cache |
| 22.3 Trois vérifications du vrai contrat | serveur | Libellés réels affichés mais jamais recontrôlés côté serveur (AD-BR-05) |
| 22.3 Accords si disponibles, aucune donnée financière | prouvé | Testé, carte masquée en production |
| 22.4 Lecture de pièce autorisée par le serveur (AC-03/15) | serveur | AD-BR-03 : pas d'audit par pièce |
| 22.4 Aucun chemin/URL dans l'interface | prouvé | Testé ; `object_key` reste exposé côté serveur |
| 22.4 Aucun secret dans les journaux / Sentry (22.8) | non prouvé | Affirmé par un commentaire seulement, non testé pour Sentry à l'époque (corrigé depuis, voir §4) |
| 22.4 Purge des caches (déconnexion, changement de compte, réponse tardive) | non prouvé au départ, **prouvé après correction** | 3 tests ajoutés ; défaut corrigé (la file suit maintenant le profil) |
| 22.5 Validation impossible si non autorisée (AC-04) | prouvé | Testé |
| 22.5 Confirmation obligatoire, succès seulement après le serveur (AC-05) | prouvé | Testé |
| 22.5 Double clic idempotent | prouvé | Testé côté client, dans une session |
| 22.5/22.6 Conflit concurrent (AC-06/17) | serveur | AD-BR-06 : aucune garde d'état, une 2e décision écrase la 1re |
| 22.5 File et compteur mis à jour après décision | non prouvé au départ, **prouvé après correction** | Compteur testé après correction (voir §4) |
| 22.6 Motif obligatoire (AC-07) | prouvé | Testé |
| 22.6 Motif conservé après erreur/annulation (AC-22) | prouvé | Testé |
| 22.6 Motif affichable au titulaire, aucune note interne | prouvé | Testé |
| 22.7 Formats 390/768/1440, clair/sombre | prouvé | Captures AD-5 à AD-10 |
| 22.7 Texte 200 % (AC-09) | prouvé, sauf politique de genre | 4 cas bloqués par décision du directeur (§4) |
| 22.7 Clavier complet, hover/focus visibles | prouvé, sauf politique de genre | Focus, hover et parcours clavier corrigés ou tranchés ; le Tab de la politique reste bloqué par décision (§4) |
| AC-21/26 quater Reflow 320 et 400 % | prouvé, sauf politique de genre | 4 cas bloqués par décision du directeur (§4) |
| 22.8 RLS, storage, expiration, rôles, audit | serveur | AD-BR-03, 06, 16, 17 |
| AC-08 Résultat inconnu jamais présenté comme un succès | prouvé | Testé |
| AC-10 Genre absent ne bloque plus la revue | serveur (prouvé en démo) | Filtre de genre codé en dur côté serveur (AD-BR-16) |
| AC-11 Renvoi vers /compte/profil | serveur | Bouton absent, dépend d'AD-BR-20 |
| AC-12/P-ADM-08 Famille dispensée, pièce absente | prouvé (démo) | Testé ; en production l'exigence reste « requise » (AD-BR-29) |
| AC-13/P-ADM-09 Nouvelle révision sans reprise des preuves | serveur (prouvé en démo) | AD-BR-02, AD-BR-28 |
| AC-14 Une seule décision et une seule trace | serveur (prouvé en démo) | Ni `command_id` ni `get_decision_result` (AD-BR-07) |
| AC-16 Droits retirés, données purgées | serveur (client prouvé) | Purge client testée ; refus serveur = AD-BR-02/03 |
| AC-18 Suspension effective après validation | serveur | Aucun test ; état d'accès réel non rendu |
| AC-19 Appel direct sans contrôle refusé par le serveur | serveur | AD-BR-05 |
| AC-20 1440, colonnes, visionneuse modale | prouvé | Testé |
| AC-23/P-ADM-11 Retour du titulaire après validation | prouvé (démo) | Testé ; signal serveur = AD-BR-26 |
| 26 ter États 02B/02C/02D/02E | prouvé | Captures AD-6 à AD-8 |
| 26 ter États 02A (Actualisation, Sélection retirée, Capacité absente, Date indisponible) | prouvé après correction | Ajouté et testé dans AD-11 (`ad11_criteres_test.dart`) |
| 26 quater Démonstration hors production, mention visible | prouvé | Garde fermée en production, testée |
| **Validation en production** | **prouvé — FERMÉE** | Voir §8 |
| Aucune permission élargie | prouvé | Diff vide (§6) |
| Aucune promesse fausse | prouvé | Testé (aucune promesse de notification/compte activé) |
| UX_REVIEW modifications 1–22, 24–27 | prouvé | Rapports AD-S, AD-5 à AD-10 |
| UX_REVIEW modif. 23 (OfflineBanner paramétrable) | non prouvé | Question ouverte (§9) |
| UX_REVIEW modif. 28 (AD-11 : texte 200 %, reflow, contraste, réduction de mouvement) | prouvé, sauf 2 points | Contraste, reflow et 200 % prouvés sauf politique de genre (bloquée par décision, §4) ; réduction de mouvement toujours non appliquée (question 8, §9) |
| 00_MAQUETTES rectifications 1–8 | prouvé | Testé |
| 00_MAQUETTES rectification 9 (états absents des images) | non prouvé | Couvert pour 02B–02E et AD-9, reste pour 02A (en partie corrigé depuis, voir 26 ter 02A) |
| K-41 Langues | non prouvé | 0 clé arabe sur le nœud `dossiers` (§5) |
| §28.1-2 ADM-02 atteint, dossier réel | serveur | Parcours prouvé ; dossier réel = AD-BR-01/02 |
| §28.3-11 Pièce réelle, décision atomique, audit, cloisonnement, politique de genre serveur | serveur | AD-BR-03, 05, 06, 07, 16, 17, 18, 20 |
| §28.12-14 Layouts 390/768/1440, audit UX livré | prouvé | Captures + document UX livré |
| §28.15 DESIGN-GOV publié | non prouvé | Publication dans Suivi Rewayah non vérifiable depuis le dépôt |
| §28.16 Tous les tests critiques verts avec preuves | non prouvé | Suite verte (+2967 ~844 -0) ; 5 tests d'accessibilité restent sautés comme défauts, tous sur la politique de genre bloquée par décision (§4) ; statut opérationnel **NON TERMINÉ** tant que la décision n'est pas prise |

## 8. Ce qui dépend du serveur (renvoi AD-BR)

Le détail complet est dans `AD-BR.md` (dépôt `admin`). Rappel des règles qui bloquent le plus :

- **AD-BR-01** : la RPC `dossiers_en_attente` ne renvoie pas une ligne par personne, ni le total, ni un curseur → pas de vraie pagination/filtre.
- **AD-BR-02** : pas de `get_dossier_for_review` → le détail est reconstruit depuis le cache de la file, jamais relu à la source.
- **AD-BR-03** : la lecture de pièce (`createSignedUrl`, 60 s) n'est pas auditée par pièce ; la policy de stockage couvre tout le compartiment (seau) KYC.
- **AD-BR-05** : les trois vérifications ne partent pas avec `decider_dossier` — rien n'empêche une décision sans elles côté serveur.
- **AD-BR-06** : `decider_dossier` n'a aucune garde d'état → une seconde décision écrase la première (conflit non protégé).
- **AD-BR-07** : pas de `command_id` ni de `get_decision_result` → aucune protection serveur contre une décision jouée deux fois.
- **AD-BR-16/17/18** : la politique de genre et les capacités administrateur sont codées en dur côté serveur, sans capacité dédiée ni audit.
- **AD-BR-20** : pas de RPC auditée pour le genre → le bouton « Compléter mon profil » reste caché.
- **AD-BR-26/27/28/29** : appels `etat_dossier`/`refreshSession` à chaque retour (non optimisés), promesse de notification retirée, réutilisation des preuves à la resoumission non garantie côté serveur, exigence de pièce toujours « requise » même pour une famille dispensée.

Tant que ces règles ne sont pas corrigées côté serveur, les critères marqués « serveur » dans la matrice (17 sur 60) resteront non garantis en production, même si l'écran se comporte correctement en démonstration.

## 9. Points et questions pour le directeur (dédupliqués)

| # | Question | Valeur appliquée par défaut (en attendant votre décision) |
|---|---|---|
| 1 | Faut-il aussi fermer le **refus** en production, comme la validation, tant qu'AD-BR-06/07 ne sont pas corrigés ? | Le refus reste **ouvert** (risque de double décision en cas de conflit) |
| 2 | Faut-il figer la démonstration aussi en **staging** (elle est fermée en production, ouverte en staging qui partage les mêmes clés Supabase) ? | La démonstration reste **ouverte en staging**, fermée seulement en production |
| 3 | Le panneau ADM-02E doit-il s'afficher en feuille (mobile) plutôt qu'en boîte de dialogue à 390 px (Q-AD8-2) ? | **Feuille** (comportement actuel) |
| 4 | Le message du bandeau hors-ligne doit-il être personnalisable par écran (Q-AD8-4) ? | Message **fixe**, non paramétrable |
| 5 | Faut-il afficher le bouton « Compléter mon profil » avant que la RPC de genre auditée (AD-BR-20) existe (Q41/E4) ? | Bouton **absent** |
| 6 | Faut-il limiter la fréquence des appels `etat_dossier` / `refreshSession` à chaque retour sur l'écran (AD-BR-26, K-09) ? | Appels **à chaque retour**, sans limite |
| 7 | Faut-il un contour visuel distinct pour le bouton tertiaire inactif (Q-AD7-7) ? | **Aucun contour** distinct, style tertiaire standard conservé |
| 8 | Faut-il réduire le mouvement de `AppBottomSheet.ouvrir` quand le système le demande (HU-1) ? | Mouvement **non réduit**, animation standard toujours jouée |
| 9 | Qui fournit/valide les textes arabes du nœud `dossiers` (121 clés, K-41) ? | **Repli sur le français** en attendant |
| 10 | Faut-il un onglet sur deux lignes (ou un libellé plus court) dans `SousNavigationDomaine` pour la politique de genre à 320 px, et faut-il faire charger les vraies polices au banc de test (§4) ? Tant que non tranché, 4 cas (5 tests) restent sautés et la vague AD-11 n'est pas close (§28.16). | **Aucun changement** de `SousNavigationDomaine` ni du banc de test ; les 5 tests restent sautés |

## 10. ATTENTION — Validation en production et consigne de fusion

**La validation d'un enseignant est FERMÉE en production.** L'écran affiche « La validation est indisponible pour le moment. » et le bouton Valider reste inactif, tant que le contrat de conséquence n'existe pas côté serveur (c'est-à-dire : tant que `decider_dossier` ne garantit pas et ne dit pas ce qu'il active réellement — comptes, accords, capacités). C'est un choix volontaire de sécurité, conforme à la spécification : **aucune validation n'est possible hors démonstration** jusqu'à ce que ce contrat existe (AD-BR-02/06).

**Consigne : ne pas fusionner `ui/admin-v1` dans `main` sans une décision explicite du directeur.** Pousser sur `main` déploie réellement en production sur ce dépôt. Le travail reste sur la branche dédiée jusqu'à votre feu vert, en particulier sur les points de la section 9 (refus ouvert, démonstration en staging, 5 tests d'accessibilité restants sur la politique de genre).
