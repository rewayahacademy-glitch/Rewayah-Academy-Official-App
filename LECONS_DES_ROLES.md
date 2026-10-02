# LEÇONS DES RÔLES : les 15 erreurs à ne plus refaire

Lecture obligatoire avant de commencer un rôle, une vague ou une revue (10 minutes).
Source : revues croisées (`05_recette/*/REVUE_*.md`), rapports de recette (`05_recette/*/RAPPORT.md`),
fichiers serveur (`1*_*/*-BR.md`), dépôts du tableau et consignes K-46, K-61. Rédigé le 02/10/2026.

Chaque leçon : ce qui s'est passé (avec la preuve), puis la règle **SI … ALORS …** qui l'empêche.
Les consignes du tableau priment ; ce document les illustre, il ne les remplace pas.

---

## 1. Travail resté sur le disque, puis perdu

**Observé.** Le poste B s'est éteint le 01/10 : CT-7, MA-8 et EN-7c étaient faits en partie mais
jamais poussés, tout a été perdu (dépôt `A-poste-B-eteint-2026-10-01`). La fin de la vague
Enseignant (0b01297) a été crue perdue parce que non poussée (dépôt `A-q-20260927-323f1000`).
Les sous-paquets C, E, O : « commits locaux, aucun push » (`05_recette/c`, `e`, `o/RAPPORT.md`).
CT-7 cru perdu au tableau alors qu'il était non commité (règle candidate `R-B-20261002-197748f8`).

**Règle.** SI un morceau de travail est fait, même partiel, ALORS commit + push sur la branche
du rôle + `@Y RELAIS` tout de suite, jamais seulement en fin d'étape. SI tu t'arrêtes ALORS tout
est poussé et « Maintenant » dit où reprendre (K-16, K-60.5). Rien de local ne fait foi.

## 2. Coder sans avoir réservé l'étape au tableau

**Observé.** Les lots 0 et 1 des corrections ont été faits sans mise à jour du tableau (K-61.7).
Des lignes CL-3 et CL-6 restaient « en cours » alors qu'elles étaient finies (`05_recette/CL/RAPPORT.md`).

**Règle.** SI tu prends une étape ALORS tu la réserves AVANT d'écrire une ligne de code
(get puis update `if_version`, statut `en_cours`, session). SI ce n'est pas au tableau ALORS
ça n'existe pas (K-03, K-48).

## 3. Travailler avec des consignes ou des décisions non relues

**Observé.** Le poste A a enchaîné AD-1 à AD-11 sans relire les consignes : K-42 (style de
référence) a été manquée, 5 étapes ont été reprises en HL-A-5 (K-46, dépôt `B-style-reference`).
EN-BR n'a pas vu K-47 (KYC enseignant seulement) déjà écrit dans AD-BR (`12_enseignant/EN-BR.md`).
La revue EA-R a écrit deux majeurs faux (M1, M3) parce qu'elle a jugé sur un résumé et non sur la
réponse du directeur (E3 = b, K-53.6) : les deux ont été annulés (`05_recette/EA/REVUE_EA-R.md`).
Un conseil de juriste a été donné alors que le directeur avait dit non (K-61.5).

**Règle.** SI tu démarres OU avant chaque nouvelle étape ALORS relis « Maintenant », les consignes
modifiées depuis ta dernière lecture et les dépôts « nouveau » (K-01, K-46). SI tu juges un écart
à une décision ALORS ouvre la décision elle-même (feuille des 45 réponses, champ
`decisions_directeur`, K-53, `DECISIONS_DELEGUEES_2026-10-02.md`), jamais un résumé.

## 4. Maquette mal suivie, ou réinventée

**Observé.** Environ 25 écarts à la maquette trouvés seulement en relisant les planches, puis
corrigés en passes de plus : avatar absent, liste de téléphone étirée sur 1100 px à l'ordinateur,
CTA sans flèche, compositions tablette divergentes (`05_recette/b`, `c`, `d`, `e`, `o/RAPPORT.md`).
La fiche élève était dite « conforme » alors que le document demandait d'autres actions et un autre
ordre (K-33). Les libellés sous les commandes de la salle MA ont été remplacés par notre dessin :
refusé par le directeur (K-61.4).

**Règle.** SI tu fais un écran ALORS relis la ligne du document source (actions, ordre de lecture)
EN PLUS de l'image, et liste les différences avant de coder. SI la maquette ou la consigne du
directeur dit quelque chose ALORS on la relève, on ne la réinvente pas (K-33, K-61.4).

## 5. Dire « fait » ou « déjà conforme » sans avoir vu la capture

**Observé.** AVATAR-1 passé « fait » en corrigeant les listes alors que le directeur montrait les
tuiles vidéo (« aucune différence ») ; CTRL-SALLE-1 « avatars déjà conformes » alors que les tuiles
débordaient (K-61.1, K-61.2). Un défaut « contenu clair en thème sombre » signalé par un agent
n'existait pas (K-33). Une rédaction « captures identiques » reposait sur des planches périmées
(`05_recette/b/RAPPORT.md` §9).

**Règle.** SI tu vas écrire « fait », « corrigé » ou « déjà conforme » ALORS ouvre toi-même la
capture « après » du MÊME écran, dans le MÊME état que celui montré par le directeur, et vérifie
l'endroit exact ; cherche toutes les variantes du défaut (grep du texte et du composant, avec et
sans vidéo, texte x2, 320 px) avant de dire « partout » (K-61.1). L'orchestrateur ne croit jamais
un agent sur parole.

## 6. Tests mal lancés, ou pas relancés

**Observé.** Deux agents du lot T ont corrigé un test puis conclu sans relancer la suite (K-29).
Le lot 3 des libellés a cassé un test (P12) que personne n'a vu : la suite complète avait été tuée
faute de mémoire (K-61.6). Deux suites en parallèle sur le même poste : suite tuée (MA-3,
`R-B-20260927-4d0f6eb7`). Suite lancée avec `CAPTURE_DIR` : 54 faux échecs (CT-4,
`R-B-20260927-68274ea4`). Un fichier modifié pendant la suite : faux échec (K-34). C, E, O :
« non lancés : analyse complète, suite complète, build web ».

**Règle.** SI tu lances Flutter (analyze, test, build, slang, pub get) ALORS seulement par
`flutter-verrou.ps1`, une commande lourde à la fois, sans `CAPTURE_DIR`, et rien modifié pendant
qu'elle tourne. SI une branche doit être « prête » ALORS tous les dossiers de tests passés un par un
(test/core, test/teaching_core, test/features, le reste), tous verts et cités. SI tu corriges après
un passage ALORS tu relances tout et tu cites le DERNIER passage (K-05, K-29).

## 7. Des tests qui prouvent la mauvaise chose

**Observé.** Le test de « Tester la caméra » validait le faux contrôle au lieu de le détecter
(`REVUE_CL-4.md` M1). Quatre tests sautés en MA-12 cachaient les deux bloquants de la vague
(`REVUE_MA-R.md` B1, B2) ; cinq tests sautés « pour garder la suite verte » en AD-11
(`05_recette/AD/RAPPORT.md`). Les tests EA montent leur propre routeur, jamais celui de l'app
(`REVUE_EA-R.md` m16). La démonstration CT garde la même mission avant et après la salle, donc
aucun test ne voit le rapport envoyé sur la mauvaise visite (`REVUE_CT-R.md` B1). Une fluidité de
60 images/s « prouvée » par un comptage de `pumpAndSettle` (`05_recette/P2-16/RAPPORT.md`).

**Règle.** SI tu écris un test ALORS il part de la vraie coquille et de la vraie route, il TAPE le
bouton et il échouerait si le défaut revenait (K-07). SI un test est rouge ALORS on corrige le code
ou on ouvre une ligne au tableau ; jamais un `skip` pour rester vert. SI un état change dans la vraie
vie (mission qui disparaît, réseau coupé) ALORS un test le fait changer.

## 8. Textes coupés et débordements à 200 % ou à 320 px

**Observé.** AD-11 : 6 commits de correction sur 8 écrans pour des débordements
(`05_recette/AD/RAPPORT.md` §4). Salle enseignant à 200 % : « Séanc… », « Poin… », dock sans
infobulle (`REVUE_EN-R.md` M3). Mon espace MA déborde de 147 px à 200 % (`REVUE_MA-R.md` B1),
mots coupés « Mari / am » (mineur 1). Tests passés sur une fenêtre tablette pour contourner un
débordement à 390 px (`05_recette/o/RAPPORT.md`).

**Règle.** SI tu livres un écran ALORS teste-le à 320 et 390 px, texte à 200 %, et en RTL forcé,
avant la revue, et ouvre les captures. SI un libellé ne tient pas ALORS il passe à la ligne ou
l'action devient icône + infobulle + libellé lu ; jamais un texte coupé sans alternative (K-41.6).

## 9. Écrans livrés sans leurs cinq états

**Observé.** Accueil et Ma classe adulte sans état hors ligne, et la route de démonstration force
le hors ligne à faux, donc jamais atteint (`REVUE_EA-R.md` M5). Accueil MA sans ses 5 états
(dépôt `C-handoff-cloud`). Échec de lecture confondu avec le chargement, liste vide confondue avec
l'erreur (`REVUE_CT-R.md` m2, `05_recette/b/RAPPORT.md`).

**Règle.** SI tu fais un écran ALORS il a ses cinq états (chargement, vide, erreur, hors ligne,
contenu), chacun atteignable en démonstration et testé (DESIGN-GOV). SI « null » et « liste vide »
veulent dire deux choses ALORS l'écran les distingue.

## 10. Messages qui affirment ce que l'app ne sait pas

**Observé.** « Test local terminé » affiché alors qu'aucun test de caméra n'a eu lieu
(`REVUE_CL-4.md` M1). Dix messages réseau affirmatifs comptés par `verifier_revue`
(dépôt `C-resultat-plan`) ; deux en EA-6. « Votre texte est gardé ici » sur un choix sans texte
(`REVUE_CT-R.md` m1).

**Règle.** SI un envoi échoue ou une coupure survient ALORS on dit « non confirmé », jamais
« n'a pas été envoyé » (D5). SI tu écris un message d'échec ALORS il dit ce qui manque, la cause
probable, l'action possible et ce qui reste fiable (K-59). SI aucune action réelle n'est branchée
ALORS aucun message de succès.

## 11. Boutons qui ne mènent nulle part

**Observé.** Carte « Remplacement » qui n'ouvre rien ; Revue de Classe sans sortie, le retour du
téléphone quitte l'app (`REVUE_EN-R.md` M1, M5). « Besoin d'aide ? » sans action
(`REVUE_MA-R.md` M3). « Ajouter ma famille » mène à « prochaine étape », et le rapport le comptait
« OK » (`REVUE_EA-R.md` m14). Consentements sans bouton qui y mène (`05_recette/a/RAPPORT.md`).
23 boutons grisés comptés par `verifier_revue`.

**Règle.** SI tu ajoutes un écran ALORS compte les références à sa route hors du routeur : zéro =
il n'existe pas. SI un bouton ne peut pas aboutir ALORS il n'est pas affiché (une ligne d'état à la
place), jamais grisé sans raison écrite, jamais inerte (K-07, R4, R10).

## 12. Libellés inventés, mots interdits, genre en dur

**Observé.** 1377 libellés sans source dans les branches fusionnées (`C-resultat-plan`) ; une
vingtaine en EA-6 ; phrases de développeur ou moralisatrices (« Le corpus n'a pas été importé… »,
« un cahier tardif vaut mieux qu'un cahier perdu », `REVUE_EN-R.md` m16, notes 19 à 21).
« Le professeur ne pourra pas vous entendre » : genre en dur (`REVUE_CL-4.md` M2). Prénom « Amina »
recopié des planches (E20). « 60 jours » en dur, prix sans mention démonstration (`REVUE_EA-R.md` m4, m6).

**Règle.** SI un texte n'est pas dans le document, la spec ou une décision ALORS il va au lexique
du rôle avec le statut « proposé par un agent », jamais en silence (K-53.4). SI la phrase parle de
l'enseignant ALORS titre et nom réels ou tournure neutre, jamais « le professeur » ni un genre en
dur (K-41.10). SI c'est un chiffre économique ou un délai ALORS il vient des données, jamais du code.
Le client ne voit jamais « admin » (K-53.6).

## 13. Composant partagé recopié, ou modifié en cassant les autres rôles

**Observé.** `_Carte` recopiée au lieu d'`AppCard`, écrans de résultat refaits à la main
(`REVUE_EA-R.md` M4). `PageShell` modifié : la bascule démonte le corps de 57 pages des autres
rôles (perte de saisie à la rotation) (`REVUE_AD-R.md` M4, m14, m15). `setting_row` change le
rendu des réglages d'observation (`REVUE_MA-R.md` mineur 2). Lecteur du Coran recopié : la copie a
déjà divergé (zoom perdu, M2). Deux API concurrentes de `LigneRubrique` : la fusion ne compile pas
(`REVUE_AD-R.md` M5).

**Règle.** SI un écran ou un composant existe chez un autre rôle ALORS on le réutilise, jamais de
copie (K-10, K-51). SI tu modifies un composant partagé ALORS teste au moins un écran de chaque
autre rôle qui l'utilise (rotation, 200 %, saisie gardée) et pars de la branche la plus avancée
pour éviter deux API concurrentes.

## 14. La démonstration touche le réel, ou la production reste ouverte

**Observé.** « Se déconnecter » appelle le vrai service d'authentification depuis `/demo/adulte`
(`REVUE_EA-R.md` M6). Le refus d'un dossier enseignant reste ouvert en production, sans garde
d'état (`REVUE_AD-R.md` M3). La démonstration s'ouvre si `ENVIRONNEMENT` n'est pas déclaré (m13).
Données de démonstration incohérentes : deux Classes « An-Nour » différentes, une Classe à la fois
confirmée et offerte, toute ligne ouvre la même Classe (`REVUE_EN-R.md` M6, M7, M8).

**Règle.** SI un écran tourne en démonstration ALORS chaque port appelé (auth compris) est un
double de démonstration, et un test tape chaque bouton qui pourrait partir au serveur. SI une
action n'est pas branchée (avant BR-1) ALORS elle est fermée en production. SI tu crées une donnée
de démonstration ALORS elle a une seule source, partagée par tous les rôles.

## 15. Confidentialité tenue par un masquage ou par le hasard

**Observé.** La rubrique « Paiements » du second adulte est affichée par défaut, puis masquée
quand la donnée arrive : en erreur réseau elle reste (`REVUE_EA-R.md` M2, F7). Les tuteurs
comptés « en attente de décision » malgré K-47 (`REVUE_AD-R.md` M1). URL des pièces d'identité
envoyées à la supervision ; cache KYC qui survivait à la déconnexion (`05_recette/AD/RAPPORT.md`
§4, §7). Le rapport du contrôleur rattaché à la mission « du moment », pas à la visite faite
(`REVUE_CT-R.md` B1, bloquant).

**Règle.** SI une donnée n'est pas permise à un rôle ALORS elle n'est jamais chargée ni affichée
pour lui, même pendant le chargement ou en erreur (la permission vient de l'absence de donnée,
jamais d'un bouton masqué). SI une action concerne un objet précis (visite, dossier) ALORS son
identifiant voyage avec elle (adresse, port), jamais « l'objet courant ».

---

## Aussi, en une ligne chacun

- SI tu commites ALORS `-m` en ligne de commande, jamais un sujet lu dans un fichier : deux BOM
  sont déjà entrés dans des sujets (`d7b006f`, `cef9fba`) (K-04).
- SI tu formates ALORS seulement tes fichiers : 55 fichiers reformatés par erreur au lot CL-4,
  rétablis par `ca841ef` (K-23).
- SI le directeur a répété une demande ALORS elle passe devant tout le reste du lot : BENTO-1,
  demandé « plus de 10 fois », restait ouvert (K-61.8).
- SI tu montres un écran au directeur ALORS règle d'abord toutes les lignes ouvertes sur cet écran,
  ou dis ce qui reste (K-61.3).
- SI un point n'est pas bloqué par une décision ALORS il devient une ligne `a_faire`, jamais
  « hors budget de temps » (K-32 ; `05_recette/a/RAPPORT.md` §2.1, EA-12a).
- SI tu écris un besoin serveur ALORS une ligne courte au tableau du fichier `<rôle>-BR.md`
  (quoi, où, pourquoi), numérotée dans l'ordre, sans écrire d'adaptateur serveur avant BR-1.
- SI un rapport dit « OK » ou « fait » ALORS la preuve est citée (fichier:test, capture, chiffre) ;
  sinon il écrit « non vérifié » et pourquoi (`05_recette/EA/RAPPORT.md`, Méthode).
