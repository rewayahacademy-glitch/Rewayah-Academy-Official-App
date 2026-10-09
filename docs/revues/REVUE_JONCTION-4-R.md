<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
## Relecture de JONCTION-4 : statut des libellés (DIR-REP-1), fiche CORAN-320-1 et jonctions 282bc950 / 5a52ff30

**Verdict : ACCEPTÉE AVEC RÉSERVES.**

J'ai vérifié les trois points de la demande par des preuves, et j'ai refait moi-même les contre-épreuves et les captures. Il ne reste aucun défaut majeur. Les réserves portent sur des défauts antérieurs à la jonction et sur l'étendue des captures.

J'ai relu la branche `origin/corrections/c2-jonction-4`, tête `dca84077` (parents `96ec95f3`, puis `5a52ff30` et `282bc950`), dans le worktree jetable `rv-JONCTION-4-96`, en mode détaché. Ce worktree et celui de contre-épreuve sur `5396485b` sont retirés. Rien n'a été poussé.

### (1) Libellés : `tool/libelles_sources.json`

**Rempli.**

- **Ce qui a changé :**
  - Le fichier garde les mêmes 267 clés, dans le même ordre, sans doublon.
  - 176 entrées ont changé. Chacune disait auparavant « à/a faire valider » ou « a valider ». Chacune dit maintenant « rédigé par l'agent, validé par délégation le 09/10 (DIR-REP-1) ». Le contrôle par script ne trouve aucune anomalie.
  - Seule la phrase de statut change. Les anciennes formules du type « …c'est-à-dire… validé par délégation le 05/10 » sont aussi réécrites.
  - Les quatre clés nommées par l'étape sont converties : `classe.cartes.feuille.envoiNonConfirme`, `retraitNonConfirme`, `alertes.bandeauCourtUne` et `alertes.bandeauCourtPlusieurs`.
- **Ce qui reste :**
  - Exactement 17 entrées non converties. Toutes appartiennent à l'ensemble des 175 clés que modifie `origin/corrections/lib-dir-1`, comparé à sa base commune avec cette branche. Sur cette branche, elles sont déjà « validé par délégation le 05/10 » (DASH-LIB / LIB-DIR-1).
  - Aucune des 175 clés de lib-dir-1 n'a été convertie ici. La jonction n'ajoute donc pas de conflit propre avec lib-dir-1.
  - Le conflit de `merge-tree` sur `libelles_sources.json` existe déjà sur la base `corrections/revue-directeur-2026-10`.
- **Noms réels et assets (ASSETS-DIR-1) :** aucune entrée en attente.
- La liste des 17 clés laissées figure dans la fiche JONCTION-4.

### (2) Fiche CORAN-320-1 : `docs/current/REVUE-DIRECTEUR-2026-10.md`

**Rempli.**

- Les trois choix sont écrits « **décidé par délégation le 05/10** » : plafond de 130 %, mention repliée, choix de rendu replié.
- La fiche porte la mention « aucun accord écrit n'est plus demandé ».
- Aucun code n'est touché.
- Deux autres fiches du document disent encore « à valider par le directeur » (lignes 156 et 320). Elles sont hors du périmètre de l'étape ; je les signale seulement.

### (3) Relecture adverse des deux commits de jonction

**282bc950 : feuille des cartes passée par ZoneSaisie, avec le paramètre `sens`.**

- **Le diff relu :**
  - Le paramètre `sens` est optionnel, `null` par défaut, et transmis à `TextField.textDirection`. Les 21 fichiers de `lib` qui appellent ZoneSaisie gardent donc le même comportement.
  - Pour les aides et les erreurs, `helperMaxLines` passe de 6 à 8 et `errorMaxLines` reste à 8. Aucune perte.
- **Contre-épreuves que j'ai refaites :**
  - Sans `textDirection: sens`, `cartes_classe_test` échoue sur « modification, rtl : … champs dans le sens de leur texte ».
  - Avec la feuille d'avant (deux TextField), `zone_saisie_unique_test` échoue : « aucun champ multiligne hors de ZoneSaisie ».
  - Avec l'ancien libellé « Vérifiez la connexion… », `etat_sans_donnees_test` échoue sur la vérification du catalogue, en nommant `envoiNonConfirme`.
- **Captures que j'ai refaites :**
  - J'ai régénéré les 5 captures sur `5396485b`, le parent de la jonction, puis sur cette branche.
  - Mes 10 fichiers et les 10 fichiers déposés ont des md5 identiques, avant comme après. L'affirmation « identiques au pixel près » est donc confirmée.
  - J'ai ouvert les captures `erreurs ar rtl clair`, `mixte ar rtl sombre` et `mixte fr ltr clair` :
    - le titre arabe s'écrit de droite à gauche, et le texte français de gauche à droite ;
    - aucun mot n'est coupé ;
    - les erreurs se lisent en entier ;
    - le bouton « Enregistrer la carte » a le même rendu valide ou en erreur : il n'est pas grisé.

**5a52ff30 : exception de `coupe_mots_3_test` pour l'adresse d'une carte.**

- Sans l'exception, j'obtiens exactement 4 échecs : « Espace Classe enseignant », en fr et ar, standard et guidée. Le seul texte en cause est l'adresse `https://rewayah.academy/demo/recitation`.
- L'exception compare le paragraphe entier (`test/support/aucun_mot_coupe.dart:40`). Elle ne couvre donc aucun autre texte.
- C'est la même exception que `cartes_classe_test`, que la revue CARTES-PERSO-1b-R a acceptée.

### Vérifications générales

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | No issues found |
| `verifier_revue` | 1533 (égal à la base annoncée) |
| `verifier_jetons` | 37 lignes signalées, sans aucune sur `feuille_carte_classe` ni `zone_saisie` ; aucun code de production n'a changé depuis 5a52ff30 |
| `dart run slang` | aucun écart |
| Tests ciblés : cartes_classe, etat_sans_donnees, zone_saisie, zone_saisie_unique, coupe_mots_3 et 3b | 116 verts |
| `test/core/widgets`, `test/features/tc_espace_groupe`, `test/core/reseau` | +270, tous verts |
| `test/features` complet, `--concurrency=2` | +3037 ~2166, 0 échec |

Statut : présent dans le code, testé localement. Ni staging, ni déploiement.

### Réserves (aucune n'est majeure)

1. **Lecteur d'écran.** Les champs titre et texte de la feuille n'ont pas de nom : `ZoneSaisie` est appelée sans `libelle`. Le défaut existait avant 282bc950. La correction serait de passer `libelle` avec `libelleVisible`, et de retirer `_Libelle`.
2. **Arabe.** `ar.i18n.json` n'a pas de section `classe.cartes`, donc la feuille s'affiche en français en arabe. Le défaut existait déjà.
3. **Étendue des captures.** Elles ne couvrent que 320 x2. Il manque 390, 1440, l'Interface guidée et le fr sombre. Le minimum demandé par l'étape (ar 320 x2) est rempli.
4. **Observation.** À 320 x 568 avec texte x2, le champ texte est plafonné à 4 lignes puis défile, et le titre prend une majuscule en début de phrase. Ce comportement est voulu par SUPERPOS-1.
