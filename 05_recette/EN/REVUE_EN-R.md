# REVUE_EN-R : revue croisée adversariale de la vague Enseignant (EN-R)

Rédigée le 27/09/2026 par une session qui n'a rien construit dans le lot.

- **Code** : `C:\RA\enseignant`, branche `ui/enseignant-v1`, dernier commit `d2420c1` (étapes EN-2 à EN-12). Vérifié par `git log` au début de cette revue : aucun autre agent n'a posé de commit après `d2420c1`.
- **Captures de recette** : `C:\RA\enseignant\build\captures\en12\<écran>\` (233 images PNG).
- **Références** : `ENSEIGNANT-2026-09-26.md` (règles E1 à E20), `CLASSE-ENTREE-2026-09-26.md` (règles R1 à R21), `STYLE-REFERENCE-CL4-2026-09-26.md` (K-42), `DESIGN-GOV-2026-09-26` (gelé), `12_enseignant/02_DECOUPAGE.md`, `UX_REVIEW_04_ENSEIGNANT.md`, `05_recette/EN/EN_RAPPORT.md`, spec `04_ENSEIGNANT.md` (§33 en particulier).
- **Décisions du directeur déjà actives sur ce lot** : K-45 (le cahier validé vaut séance payée, jamais bloquant, ton jamais punitif, historique des corrections réservé à l'académie, point rouge qui pulse) ; K-47 (la vérification d'identité, KYC, ne concerne que l'enseignant, jamais le tuteur).

Rien n'a été corrigé par cette revue : elle liste des constats, elle ne les applique pas.

## Méthode

Quatre relecteurs indépendants ont chacun repris tout ou partie de la vague : le découpage (`02_DECOUPAGE.md`), les 233 captures de recette d'EN-12, et la spec `04_ENSEIGNANT.md` lue section par section (dont le §33, les 14 questions anti-cauchemar). Chacun a produit ses constats séparément.

Une vérification adversariale a ensuite rouvert chaque constat un par un, directement dans le fichier et aux lignes citées, avant de le retenir :

- un constat confirmé dans le code garde sa gravité, ou la voit corrigée si une pièce complémentaire change l'appréciation (exemple : M8 ci-dessous, où une donnée annexe change la portée réelle du doublon) ;
- un constat réfuté en tout ou partie est réduit ou écarté, et la partie réfutée est dite explicitement (voir les constats marqués « en partie » ou « réfuté ») ;
- deux constats indépendants qui touchent le même défaut ont été fusionnés en une seule entrée, avec les deux jeux de preuves ; c'est noté à chaque fois ;
- rien n'est retenu sur la seule foi d'une capture ou de la mémoire d'une règle : la ligne de code et le libellé exact ont été relus.

## Vérification technique

| Commande | Résultat |
|---|---|
| `flutter analyze` (via `flutter-verrou.ps1`) | **No issues found**, code 0 |
| `flutter test` (suite complète) | Non rejouée dans cette revue : déjà exécutée dans `EN_RAPPORT.md` le 27/09/2026 (3 353 tests, 3 352 réussis, 1 échec déjà attribué à une étape antérieure hors périmètre EN-12, 1 379 mis de côté). Cette revue ne change aucun test, ce résultat reste valable. |

## Réponses aux 14 questions anti-cauchemar (spec §33)

| N° | Question | Réponse | Constats liés |
|---|---|---|---|
| 1 | Sait-on en moins de 10 s ce qu'il faut faire maintenant ? | En partie | Le fond est net (un seul bouton « Préparer la séance »), seul le libellé de compte à rebours diverge d'E11 (m14). |
| 2 | Préparer une séance sans formulaire ? | Oui | Aucun défaut relevé. |
| 3 | Entrer dans la salle sans rouvrir cinq menus ? | Oui | Aucun défaut relevé. |
| 4 | Voir l'élève sans voir sa vie privée ? | Oui | Aucun défaut relevé. |
| 5 | Changer de support sans quitter la visio ? | Oui | Aucun défaut relevé. |
| 6 | Appeler un élève sans lui ouvrir le micro à distance ? | Oui | « Appeler discrètement » et « {nom} vous appelle » confirmés dans le code. |
| 7 | Signaler un problème sans recopier Classe, séance, nom ? | En partie | Signalement sans Classe ni séance (m2a) ; Cahier de séance sans date ni Classe visibles (m2b). |
| 8 | Finir un cours normal sans écrire un paragraphe ? | Oui | Aucun défaut relevé. |
| 9 | Retrouver un cahier non terminé immédiatement ? | En partie | Un cahier validé hors ligne reste affiché « à remplir » (M2) ; au-delà de 3 cahiers en retard, aucune entrée pour les suivants (m1). |
| 10 | Déclarer une absence sans perdre sa Classe ? | Oui | Aucun défaut relevé. |
| 11 | Assurer un remplacement sans reconstruire l'historique ? | Non | La carte « Remplacement » n'ouvre rien (M1) ; la démonstration mélange Classe confirmée et offre encore ouverte (M8). |
| 12 | Travailler au clavier sur bureau ? | Oui | Raccourcis EN-KB confirmés (commit `5a303db`). |
| 13 | Lire l'écran à 200 % sans perdre les actions critiques ? | En partie | Titre et outils de la salle tronqués, dock sans infobulle (M3) ; disque de dock sous 48 px en dessous de 390 px (m10). |
| 14 | Une panne réseau laisse-t-elle comprendre sans refaire le travail ? | En partie | Cahier en attente d'envoi non signalé comme tel (M2) ; échec d'envoi du signalement, latent, sans état d'erreur (n1). |

Le rôle n'est pas terminé tant qu'une réponse n'est pas « oui » (règle du §33). Cinq questions restent en dessous de « oui » : 1, 7, 9, 11, 13, 14 (six en réalité, la question 1 n'étant qu'un écart de libellé et non un blocage).

## Bilan

**8 majeurs, 16 mineurs, 21 notes, et 2 points qui attendent une décision du directeur.**

Recommandation : l'étape ne passe pas à « vérifié » avant la correction des 8 majeurs, parce qu'ils répondent directement aux questions 9, 11, 13 et 14 du §33, qui restent en dessous de « oui ». Les mineurs et les notes peuvent suivre en un ou deux lots séparés.

## Majeurs

### M1. La carte « Remplacement » n'ouvre rien (Q11, spec §17.3, E11)

Ce que le code fait :
- `lib/features/journee/absence_remplacement_vue.dart` (`CarteRemplacement`, l. 170 à 216) : une `AppCard` sans `onPress` ni bouton, qui n'affiche que la Classe, la pastille, la date, l'heure, la durée et l'effectif.
- `lib/core/enseignant/absence_remplacement.dart` (`OffreRemplacement`, l. 58 à 70) : ne porte que `seanceId`, `classe`, `debut`, `fin` et `nbEleves`, sans `groupeId`.

Conséquence : aucun chemin ne mène au bloc « À préparer » ni au roster de la Classe remplacée. Le remplaçant doit reconstruire l'historique, ce que la spec §17.3 et la question 11 interdisent.

Réserve : dans la démonstration, toute Classe ouvre la même An-Nour (voir M6). La correction de structure sera donc juste, mais pas encore visible avec les données d'Al-Fatiha tant que M6 et M7 ne sont pas traités.

**Attendu** : ajouter `groupeId` à `OffreRemplacement`, le renseigner dans `enseignant_demo.dart` depuis `remplacement.classeId`. Donner à `CarteRemplacement` une seule action, avec le libellé existant `t.enseignant.journee.voirClasse` (« Voir la Classe », E11), qui pousse `Routes.groupePour(groupeId)`. Le bloc « À préparer » existant fournit déjà le support, la reprise et l'objectif. Aucun texte nouveau.

### M2. Un cahier en attente d'envoi n'est pas signalé comme tel et rouvre le formulaire (Q9, Q14, spec §20.8, K-45)

Ce que le code fait :
- `lib/features/journee/journee_page.dart` (`_ATerminer`, l. 708 à 781 ; lecture l. 169 à 222) : ne lit que `cahiersEnRetardProvider` (le serveur).
- `lib/core/enseignant/depot_cahiers.dart` (l. 25) : `depotRapportsProvider.enAttente()`, la file locale, n'est lu ni par la journée ni par `vue_cahier.dart`, qui ne connaît que le drapeau serveur `dejaDepose`.

Conséquence : un cahier validé hors ligne reste affiché « à remplir ». S'il est touché, l'enseignant retombe sur le formulaire, doit refaire le travail et risque un second dépôt. Le statut « En attente d'envoi » de §20.8 n'apparaît qu'un court instant, juste après la validation (`SortCahier.enFile`, `cahier_page.dart` l. 1036).

**Attendu** : dans `_Corps`, croiser aussi la file locale (`depotRapportsProvider.enAttente()`). Pour une séance présente dans la file, la ligne prend le libellé existant `t.enseignant.cahier.enFileTitre` (« En attente d'envoi », texte de §20.8) et l'appui ouvre l'état d'attente déjà existant (`EmptyState` `enFileTitre`/`enFileDetail`), jamais le formulaire. Aucun texte nouveau.

### M3. À 200 %, titre et outils de la salle sont tronqués, et le dock n'a pas d'infobulle (Q13, spec §28)

Ce que le code fait, constaté à deux endroits par deux relecteurs (fusionné ici) :
- `lib/features/salle_seance/chrome_seance.dart` (`_Titre`, l. 284 à 292, et titre l. 288) : `maxLines: 1`, le titre devient « Séanc… ».
- `lib/features/tc_dock/bouton_outil.dart` (l. 84 à 92) et `lib/features/salle_seance/dock_seance.dart` (`BoutonAppel`, l. 193 à 222 ; bascule l. 428 à 441) : outils réduits à « Poin… », « Mar… », « Mas… », « Ann… », dock d'appel en icônes seules sans `Tooltip`.
- `lib/features/salle_seance/outils_enseignement.dart` (l. 151 et l. 254, `maxLines: 1` + ellipsis) : les pastilles numérotées 1, 2, 3 du support sont rognées en bas.

Le libellé n'est lu que par `Pressable.libelleSemantique` : rien ne s'affiche visuellement pour confirmer l'action. Quitter la salle reste atteignable, ce n'est pas bloquant, mais la question 13 (« sans perdre les actions critiques ») n'est pas acquise.

**Attendu** : `chrome_seance.dart` l. 288 et `outils_enseignement.dart` l. 254 : `maxLines: 2` avec `softWrap`, ou icône seule au-delà d'un `textScaler` de 1,3, avec le libellé existant repris en `Tooltip` et `Semantics`. `BoutonAppel` et `bouton_outil.dart` : `Tooltip(message: libelleSemantique ?? libelle, excludeFromSemantics: true)`, même patron que `nav_shell.dart` l. 958. Pour les pastilles numérotées, laisser la hauteur suivre le texte plutôt que de la fixer. Libellés existants seulement.

### M4. Revue de Classe : les anomalies sont inertes, aucune action possible (spec §13.6, E2)

Ce que le code fait :
- `lib/features/revue_groupe/revue_groupe_page.dart` (l. 118 à 190, `_Liste`/`_Carte`) : une `AppCard` par anomalie, sans `onPress` ni chevron. `AnomalieRevue` porte pourtant `studentId`, et la page a déjà accès aux membres de la Classe.

La spec §13.6 attend des « anomalies actionnables » ; ici elles ne mènent nulle part.

**Attendu** : remplacer la colonne d'`AppCard` par un `GroupeReglages`, une `LigneRubrique` par anomalie (libellé = type, légende = élève et détail existants). `onPress` appelle `ouvrirFicheEleve` (`fiche_eleve_enseignant.dart`) avec le `MembreSeance` correspondant à `studentId`, ce qui donne accès à « Signaler un besoin ». Aucun libellé nouveau.

### M5. Revue de Classe (ENS-08) : aucune sortie, l'enseignant reste bloqué (R1)

Ce que le code fait :
- `lib/features/fiche_groupe/fiche_groupe_page.dart` (l. 286) : le bouton « Revue » appelle `GoRouter.of(context).go(Routes.revuePour(groupe.id))`.
- La route est une « pose » hors coquille (`app_router.dart`, l. 787 à 791, commentaire l. 762 : « Une pose s'atteint depuis un écran puis se quitte »).
- `revue_groupe_page.dart` (l. 53) : `PageShell` construit sans `onRetour`. `page_shell.dart` (l. 138) ne pose de `DisqueRetour` que si `onRetour != null`.

Conséquence : la pile ne contient que la Revue, sans disque retour ni barre. Visible sur `en12/revue_classe/en12_avec_anomalies_390_light.png` : aucune sortie visible. Sur téléphone, le geste retour quitte l'application.

**Attendu** : `fiche_groupe_page.dart` l. 286, remplacer `go` par `push`. Dans `RevueGroupePage`, passer `onRetour` à `PageShell` (`routeur.canPop() ? routeur.pop() : routeur.go(Routes.groupePour(groupeId))`), même patron que le Retour de l'Espace Classe (`fiche_groupe_page.dart`, l. 130 à 137). Le `DisqueRetour` n'a pas de texte visible : aucun libellé nouveau.

### M6. Dans Mes Classes, toute ligne ouvre la même Classe An-Nour, dans le mauvais état (E3, E11, R4)

Ce que le code fait :
- `lib/features/demo/demo_enseignant_page.dart` (l. 418 à 423) : `onOuvrirClasse: (String _) => context.go(adresseDemoClasse(RoleEntree.enseignant, EtatDemoClasse.fenetreOuverte))` ignore l'identifiant reçu.

Conséquence : Al-Fatiha, Al-Badr et Al-Ikhlas ouvrent toutes « Classe An-Nour », avec la salle déjà ouverte, alors que le « maintenant » de la démonstration est le lundi 28/09 à 16 h et que l'ouverture de la salle de démonstration est à 17 h 40 heure de Paris.

**Attendu** : transmettre l'identifiant reçu. En démonstration, n'ouvrir l'Espace Classe que pour `demo-classe-an-nour`, dans l'état `EtatDemoClasse.aVenir` (qui existe déjà, l. 80), pas `fenetreOuverte` ni `attente`. Pour les trois autres Classes, retirer la navigation tant qu'elle n'a pas sa propre donnée de démonstration. Aucun texte nouveau.

### M7. Deux Classes « An-Nour » différentes dans la démonstration (élèves, heure, effectif, reprise)

Ce que le code fait :
- `lib/features/demo/enseignant_demo.dart` (`classes[0]`, l. 280 à 292) : séance le lundi 28/09 à 17 h 30, 4 élèves (Yusuf, Mariam, Adam, Safiya, pages 12, 9, 14, 11).
- `lib/features/demo/classe_demo.dart` (élèves l. 143 à 170, `debutUtc` l. 205, horloge utilisateur « 18:00 ») : séance à 16 h 00 UTC (18 h à Paris), 3 élèves (Mariam, Yusuf, Aïcha, pages 24, 22, 24).

`classe_demo.dart` et `seance_demo.dart` servent aussi aux salles élève et tuteur (vague Classe, étape déjà fermée) : c'est déjà relevé en attente au point 2 d'`EN_RAPPORT.md`, cette revue confirme et précise l'écart avec les lignes exactes.

**Attendu** : aligner `DonneesEnseignantDemo.classes[0]` sur `classe_demo` (Mariam, Yusuf, Aïcha ; prochaine séance le 28/09 à 18 h ; reprises pages 24, 22, 24), et mettre à jour la séance liée `demo-seance-an-nour-2809` en conséquence. Tout reprend des données déjà existantes, sans texte nouveau. Ce point reste néanmoins listé en attente du directeur dans `EN_RAPPORT.md` (point 2) : la correction technique peut se faire, mais le choix final des données de démonstration lui revient.

### M8. Al-Fatiha à la fois Classe de l'enseignant (pastille Remplacement) et offre encore à accepter (Q11, spec §17.2, E1, E7)

Ce que le code fait, constaté à deux niveaux par deux relecteurs (fusionné ici) :
- `lib/features/demo/enseignant_demo.dart` (`classes[1]`, l. 294 à 305, `remplacement: true`) : Al-Fatiha listée dans Mes Classes avec la pastille Remplacement et sa séance du 29/09 à 18 h.
- `enseignant_demo.dart` (`offreRemplacement()`, l. 509 à 518) : propose en même temps d'assurer cette même séance `demo-seance-al-fatiha-2909`, non encore acceptée.

Déjà listé en attente aux points 1 et 17 d'`EN_RAPPORT.md`. Cette revue confirme le mécanisme exact et relève qu'il viole aussi §17.2 (« ne jamais afficher Remplaçant confirmé sur la seule base d'un envoi de notification »). Le remplaçant ne sait pas s'il est engagé.

**Attendu** : tant que l'offre n'est pas acceptée, retirer Al-Fatiha de la liste rendue à Mes Classes, en gardant `classes[1]` comme source de l'offre elle-même (ou attendre que `remplacementsConfirmesProvider` soit rempli). Donnée de démonstration seulement, sans texte nouveau. Le rapport de recette a déjà placé ce point en attente du directeur : cette revue le rappelle, elle ne le tranche pas.

## Mineurs

| N° | Constat | Preuve | Attendu |
|---|---|---|---|
| m1 | Au-delà de 3 cahiers en retard, les suivants n'ont aucune entrée (Q9, spec §11.4). La liste est coupée à 3 sans tri, et aucun autre écran (Mes Classes, Espace Classe) n'ouvre un cahier. | `journee_page.dart` (l. 77 `maximumATerminer = 3` ; l. 752 `cahiers.take(maximumATerminer)`) | Trier du plus ancien au plus récent avant `take(3)`. Si la liste dépasse 3, ajouter le lien sourcé « Voir tout » (§11.4, clé `voirTout` déjà présente) vers une liste complète titrée `t.enseignant.journee.aTerminer`, qui réutilise les mêmes lignes. |
| m2 | Le signalement n'emporte ni Classe ni séance ni horodatage (a), et le Cahier de séance ne dit pas de quelle séance il s'agit (b) (Q7, spec §22.2 et §20.3). | (a) `fiche_groupe/fiche_eleve_enseignant.dart` (`SignalementBesoin`, l. 317 à 339) et `salle_seance/signalement_seance.dart` (l. 14 à 24) ; (b) `cahier/cahier_page.dart` (`_Resume`, l. 543 à 605) | (a) Ajouter à `SignalementBesoin` `classe` (repris de `widget.eleve.classe`), un `seanceId` optionnel et un horodatage. (b) Dans `_Resume`, ajouter la ligne avec le libellé existant `t.enseignant.journee.cahierDetail` (déjà utilisé dans « À terminer »), remplie depuis `brouillon.debut`. Le nom de Classe ne vient que de `groupeId` : ne pas l'inventer, reporter à EN-BR. |
| m3 | Le bandeau « Démonstration » se rend en deux traits violets sans texte lisible sur toutes les captures qui le montrent, et recouvre la fin du bandeau hors ligne à 390 px. | `features/demo/repere_demonstration.dart` (l. 36 à 40) : `TextStyle` nu, sans `fontFamily` | Partir de `Theme.of(context).textTheme.labelSmall`, puis `copyWith(color: onTertiary, fontSize: 10, fontWeight: w700)`. Aucune couleur changée (K-37). |
| m4 | Le roster de la salle n'utilise pas `PhotoEleve` (E5, K-44) : initiale si connecté, silhouette générique sinon. | `salle_seance/panneau_eleves.dart` (`_Avatar`, l. 278 à 325) ; `salle_seance/vue_seance.dart` (`EleveSeance`, l. 118, aucune clé de photo) | Ajouter à `EleveSeance` une clé de photo facultative, alimentée par la démonstration. Dans `_Avatar`, remplacer le centre par `PhotoEleve(prenom, cleAvatar, diametre)`, garder la pastille de statut par-dessus. |
| m5 | Premiers pas : « Ajouter ma photo » s'étire sur toute la colonne à 1440 px, et double la ligne de rappel quand il ne reste qu'un manque. | `bienvenue_enseignant/bienvenue_page.dart` (`ActionPrincipale`, l. 364 à 376 ; ligne photo l. 289 à 294) | Sur bureau, largeur naturelle du bouton, aligné au bord de fin (K-42 §2, §6 ; R20). Le doublon avec un seul manque peut rester, ou la ligne peut être retirée. |
| m6 | Cahier : titre générique « Cahier de séance » sans Classe ni date, aucun retour visible dans l'état à remplir. | `cahier/cahier_page.dart` (l. 165 et l. 179, `PageShell` titre seul) | `PageShell` reçoit `onRetour: _retourJournee` (déjà existant, l. 287). Sous-titre avec la clé existante `enseignant.journee.cahierDetail`, construite depuis `brouillon.debut`. Le nom de Classe n'est pas dans `BrouillonCahier` : à passer depuis la ligne « À terminer » (clé `cahierLigne` existante). |
| m7 | Disponibilités : une grande `AppCard` par Classe sans chevron, et une pastille « Disponible » qui répète l'état normal ; « Mes disponibilités » suit directement le titre « Disponibilités ». | `disponibilites/disponibilites_page.dart` | Un `GroupeReglages` avec une `LigneRubrique` par Classe et un chevron vers le détail (K-42 §4). Garder « En attente de validation » et « Limite de charge atteinte » ; retirer la pastille « Disponible » et le sous-titre redondant. |
| m8 | Le support de la salle devient un arrêt de tabulation sans anneau de focus ni sémantique (WCAG 2.4.7). | `salle_seance/salle_seance.dart` (l. 232 et l. 535) : `FocusNode(debugLabel: 'support')` sans `skipTraversal` | `FocusNode(debugLabel: 'support', skipTraversal: true)` : `requestFocus` continue de fonctionner, la zone sort de l'ordre Tab. |
| m9 | Signaler un besoin : seule la pastille radio sélectionne la catégorie, taper le libellé ou l'icône ne fait rien (contrat B, cibles tactiles). | `fiche_groupe/fiche_eleve_enseignant.dart` (l. 512 à 518) : `LigneRubrique` avec `controle: Radio<CategorieBesoin>`, sans `onPress` | Donner à chaque ligne `onPress` qui choisit la catégorie, déplacer la `Radio` en position « marque » (qui laisse la ligne se presser), enveloppée dans `ExcludeFocus` pour éviter un second arrêt Tab. |
| m10 | Dock compact de la salle : au plancher de 48 px calculé, mais la case peut descendre sous 40 px vers 320 px de large ; le disque demandé y serait écrasé ou déborderait (pas de capture à 320 pour le confirmer directement). | `salle_seance/dock_seance.dart` (l. 419 à 440) : `reduit = max(min(diametre, parCase - xs), cibleTactile)` sur des boutons `Expanded` | Quand `parCase < cibleTactile`, ne plus répartir en `Expanded` : rangée défilante horizontale ou `Wrap` sur deux lignes, cases fixes à `cibleTactile`. Ajouter un test à 320 x 640 qui mesure les disques. |
| m11 | Cahier : le « point de prononciation noté » a disparu de la légende de la ligne élève, retiré par le lot 2 d'EN-12 (`b2ce26d`). Avant validation, on ne voit plus quels élèves ont un point consigné sans rouvrir chaque feuille. | `cahier/cahier_page.dart` (l. 509 à 537, `_ligne`) | Dans la chaîne de légende, après l'exception : `d?.pointPhonetique != null ? t.enseignant.cahier.pointPhonetiqueNote : (devoir...)`. Le libellé existe déjà. |
| m12 | Salle et résultat de séance : heure de fin et présence incohérentes pour An-Nour (séance de 18 h à 18 h 45, résultat affiché à « 15:16 » ; « 3 séances cette semaine » en salle contre « 3 séances sur les 3 dernières » dans l'Espace Classe ; « Pages 20 à 23 » contre « Page 22 »). | `demo/seance_demo.dart` (fiches l. 82 à 115, `FinSeance` `heureFin` `'15:16'`, l. 208 à 211) | Mettre `heureFin` à `'18:45'` (déduit de `finPrevueUtc`). Reprendre les valeurs de `classe_demo` pour `presenceRecente` et `aReprendre`. `seance_demo` sert aussi aux élèves et aux tuteurs : ne changer que ces valeurs. |
| m13 | Séances passées hors du rythme hebdomadaire : le cahier à remplir porte sur Al-Badr un samedi alors que son rythme est le jeudi, et la séance passée d'An-Nour tombe un jeudi alors que sa Classe a lieu le lundi (E15). | `demo/enseignant_demo.dart` (`seances()`, l. 385 à 397 ; `cahiersEnRetard()`, l. 412 à 425) | Placer Al-Badr au jeudi 24/09 à 17 h et An-Nour au lundi 21/09, à l'heure retenue en M7. Mettre à jour ensemble les identifiants et dates de `seances()`, `cahiers` et `cahiersEnRetard`, `heuresDeRetard` passe à 95. |
| m14 | La carte « Prochaine séance » dit « Cours dans 1 h 30 » au lieu de la ligne d'E11 (« Dans 1 h 24 »/« Dans 1 h 30 »), et ceci quel que soit le rôle. Deux relecteurs ont proposé des corrections différentes (fusionné ici, à trancher lors de la correction) : l'un retenait de ne pas toucher `emplacement_entree.dart` par prudence, l'autre relève que ce fichier reçoit déjà le rôle et porte déjà les clés `minuteurHeures`/`minuteurMinutes`, inutilisées ailleurs dans `lib`. | `core/tc_horloge/emplacement_entree.dart` (l. 127 à 129, `t.classe.entree.coursDans` rendu quel que soit `RoleEntree`) | Dans `EmplacementEntree`, qui reçoit déjà le rôle, rendre les clés `minuteurHeures`/`minuteurMinutes` (« Dans {heures} h {minutes} », « Dans {minutes} min ») pour `RoleEntree.enseignant` seulement, sans toucher au rendu des élèves et des tuteurs. Libellés déjà existants. |
| m15 | Fiche élève : la ligne « Dernière séance » affiche en réalité le dernier point travaillé (« Lecture fluide des lettres liées »), pas une date, alors qu'en salle le même intitulé porte une date. | `fiche_groupe/fiche_eleve_enseignant.dart` (l. 186 à 190) : `t.enseignant.eleve.derniereSeance` affiche `p?.dernierPoint` | La projection n'a pas de date de dernière séance : garder l'information sous la clé existante `ficheGroupe.dernierPoint` (« Dernier point : {texte} »), ou retirer la ligne. |
| m16 | Mots de développeur et formule obscure dans des messages d'erreur, sans source dans la spec : « Le serveur n'a pas répondu. », « Le corpus n'a pas été importé dans cet environnement. », « Il n'est pas supposé pour autant. » (spec §25.2 : pas d'identifiants ni de codes internes). | `assets/i18n/fr.i18n.json` (`creneaux.grilleErreurDetail` l. 3051 ; `salle.corpusAbsentDetail` l. 2914 ; `profil.statutInconnuDetail` l. 3014) | `grilleErreurDetail` devient « Les heures que vous avez déjà posées ne sont pas perdues. ». `corpusAbsentDetail` devient « Il n'y a rien à présenter. ». `statutInconnuDetail` devient « Nous n'avons pas pu lire votre statut. ». |

## Notes

1. Un échec d'envoi du signalement n'a ni `try` ni `catch` (`_envoyer`, `fiche_eleve_enseignant.dart` l. 407 à 434) : `_enCours` resterait vrai et le bouton bloqué en chargement. Latent, car aucun appelant enseignant ne passe encore `envoi` (K-28), mais à traiter avant BR-1 (spec §22.5).
2. Cahier sur bureau (1440) : « Rien à signaler » se lit avant « À regarder », l'ordre inverse du mobile (`cahier_page.dart`, branche large après l. 475 ; K-42 §6).
3. Fiche élève : le titre générique de la feuille répète aussitôt le prénom affiché à côté de la photo (`fiche_eleve_enseignant.dart` l. 58). Passer `eleve.prenom` comme titre de la feuille et retirer la répétition, en gardant l'identifiant Académie.
4. Cahier : le titre de section « Où la Classe s'est arrêtée » est répété mot pour mot par le `labelText` du champ juste en dessous (`cahier_page.dart` l. 250). Retirer `labelText`, lier le champ au titre par `Semantics(label)`.
5. Le support de démonstration affiche « Être attentif aux explications du professeur. », alors qu'E16 interdit « le professeur » dans un texte vu par l'élève (`demo/seance_demo.dart` l. 130). Retirer l'encadré de démonstration, sans texte de remplacement.
6. Pour Mariam, les données de démonstration divergent entre salle et hors salle : présence récente et niveau affiché différemment (`demo/seance_demo.dart` l. 121 ; `demo/enseignant_demo.dart`). À aligner sur une seule source (E20).
7. Détail d'une Classe disponible : le niveau affiche « 1 » seul, alors que la liste dit « Niveau 1 » (page de détail, ligne Niveau). Reprendre le libellé existant.
8. Cahier enregistré à 390 px : l'état est centré alors que les actions (« Corriger le cahier », « Retour à ma journée ») sont collées au bord droit, composition bancale (`cahier_page.dart`, `_DejaDepose`, l. 710 à 730). Aligner l'état au bord de début, comme le reste de la page.
9. Le commentaire de `_Personnel` parle de « trois destinations », alors que la navigation enseignant en a quatre (`profil_enseignant_page.dart` l. 651, E10). Commentaire seulement, l'interface elle-même est correcte.
10. Cahier : la ligne d'élève ne dit plus « Ajuster » au lecteur d'écran depuis que `libelleSemantique` a été retiré (`cahier_page.dart` l. 509 à 537 ; `groupe_reglages.dart` l. 15 à 48, `LigneRubrique` sans ce champ). Ajouter un `libelleSemantique` optionnel à `LigneRubrique`, transmis à `Pressable`, avec `t.enseignant.cahier.ajusterPour(eleve: ...)`, libellé existant.
11. Le focus ne se déplace pas vers le support quand deux ressources sans description se succèdent, l'objet rendu étant identique (`salle_seance.dart` l. 256 à 263). À corriger avec un signal de choix plutôt que l'identité de l'objet (visible surtout après BR-1).
12. Aucun test ne couvre le focus du support ni le retour de focus après fermeture d'un panneau (`fiche_groupe_test.dart` l. 423 ; `en10_salle_test.dart`). Trois tests à ajouter (focus sur la ligne d'élève, focus sur le support après choix de ressource, retour par `pop`).
13. Six clés i18n orphelines (`enseignant.bienvenue.fait`, `cahier.devoirAucun`, `profil.identifiantDetail`, `ficheGroupe.retour`, `ficheGroupe.dernierPoint`, et `cahier.pointPhonetiqueNote` si m11 n'est pas corrigé) : à retirer de `fr.i18n.json` et `ar.i18n.json`, puis régénérer par le verrou. `cahier.performance` et `cahier.faiblesses` sont des emplacements K-45 (point 3) à garder.
14. Dans les captures de la Revue de Classe, l'élève est nommé « Maryam » alors que partout ailleurs il est nommé « Mariam » (`enseignant_demo.dart` l. 286, `demo-eleve-maryam`). Ce même écart a été relevé indépendamment par trois relecteurs sur trois fichiers de test différents (`captures_en_test.dart` l. 842 à 864, `captures_en11_test.dart` l. 32 et 99) : à corriger une seule fois, en renommant aussi l'identifiant.
15. Un test du micro dépend d'une durée codée en dur de 4 s, alors que le vrai délai est `AppMouvement.retourLocalMaintien` (3 s) (`en12_micro_test.dart` l. 85 à 86). Utiliser la constante plutôt qu'un nombre.
16. Deux blocs de documentation se sont déplacés au mauvais endroit lors de rectifications précédentes : dans le profil (`profil_enseignant_page.dart` l. 34 à 60) et dans le cahier (`cahier_page.dart` l. 734 à 735, doc de l'ancienne `_LigneEleve`). À remonter ou supprimer, sans toucher au code.
17. L'offre Ar-Rahma est proposée « Disponible » le lundi à 18 h, en chevauchement avec la séance d'An-Nour du lundi (`enseignant_demo.dart`, offres l. 449 à 460, `autresJours: [1, 5]`). Retirer le lundi de cette liste, donnée seulement.
18. La bannière d'erreur partielle de la journée dit « prières, pauses ou rapports peuvent manquer » ; la spec §25.3 attend « cahiers », pas « rapports » (`fr.i18n.json` l. 2840). « Cours » n'est pas interdit par E17 et reste tel quel.
19. Le cahier en erreur ajoute « un cahier tardif vaut mieux qu'un cahier perdu », sans source et moralisateur au moment d'une panne (`fr.i18n.json`, `enseignant.cahier.erreurDetail` l. 2938 ; K-45). Retirer cette seconde moitié.
20. Le profil dit « recevoir des élèves », reste de l'ancien matching individuel alors que l'enseignant prend une Classe entière (`fr.i18n.json`, `statutValideDetail` l. 3006 ; E1). Retirer « et recevoir des élèves ».
21. Le profil justifie sa conception à l'enseignant : « un contrat qui s'édite depuis l'écran de la personne qu'il engage n'est plus un contrat. » (`fr.i18n.json`, `contratLectureSeule` l. 3028). Retirer cette explication, garder « Ces pièces sont en lecture seule. ».

## Points en attente du directeur

Ces deux constats ne peuvent pas être corrigés sans une décision, parce qu'ils touchent un texte contractuel ou un choix de casting sans source écrite. Rien n'a été changé.

1. **« Conservé trente jours » écrit en dur, alors que la durée est un réglage de l'académie ailleurs** (`assets/i18n/fr.i18n.json`, `contrat.pointEnregistrement` l. 594, contre la durée d'accès aux enregistrements réglée en l. 1435 à 1436). Aucune source dans la spec 04 ni dans les règles pour « trente jours ». Le texte date de l'étape 3 (`87b51b9`). Cette revue ne retire ni ne reformule un texte contractuel sans le directeur : il doit confirmer la durée, ou demander qu'elle soit tirée des données.
2. **La variante Sayyida est nommée « Amina », prénom explicitement cité par E20 parmi les données de planches à ne jamais recopier** (`demo/enseignant_demo.dart`, `nomAffiche` l. 257 à 258 ; `demo/classe_demo.dart`, `enseignanteVariante` l. 133 à 137). La variante elle-même reste obligatoire (E16) : ce n'est que le prénom qui pose problème. Aucun prénom féminin n'est sourcé ailleurs : le choix revient au directeur.

Pour mémoire, plusieurs majeurs de cette revue confirment ou précisent des points déjà en attente dans `EN_RAPPORT.md` sans les trancher à sa place : M7 précise le point 2 (deux Classes An-Nour), M8 précise les points 1 et 17 (Al-Fatiha en doublon), m14 précise le point 4 (libellé du compte à rebours), m16 précise le point 3 (mots de développeur). Le choix des données de démonstration et la décision finale sur ces points restent au directeur ; la correction de structure proposée ici (câblage, sources de données uniques) peut se faire sans attendre.
