# UX_REVIEW_OFFRES-ADM-1 : « Classes à ouvrir », les demandes réunies côté administration (09/10/2026)

- **Demande** : directeur, décision du 09/10/2026 (`DECISION-OFFRES-GROUPES-2026-10-09.md`
  §1 et §3), étape OFFRES-ADM-1. Le système regroupe les demandes qui se ressemblent (mêmes
  jours, même heure locale, même fuseau, même public, même langue) ; chaque regroupement
  montre ses jours, son heure, son public, sa langue, son nombre d'élèves et « prête » quand
  le quota est atteint ; « Créer la classe » crée la classe, y intègre les élèves, puis
  enchaîne sur la proposition d'enseignant que l'administration confirme ; à la fin, « Les
  familles ont été prévenues ».
- **Cadre** : DESIGN-GOV-2026-09-26 §4.2 ; règles K-54 à K-59 de `lib/CLAUDE.md`.
- **Sources** : les référentiels de la liste §4.1, tels que les revues précédentes du dépôt
  les ont relevés (`UX_REVIEW_CLASSE-FORM-1.md`, `UX_REVIEW_REMPL-1.md`). **Aucune
  navigation web dans cette session le 09/10** : aucune source n'a été reconsultée ce jour.
  GOV.UK est exclu.
- **Limite §4.3** : aucun état serveur n'est décidé à l'écran. Le regroupement, le quota,
  les heures dans les autres fuseaux, l'atomicité de la création, l'idempotence, les
  capacités et les notifications sont portés par le serveur (port
  `PortRegroupementsAdmin`). Rien sous `supabase/`, ni dans un `service_*.dart` ou un
  `*_supabase.dart`. Aucun port existant n'est modifié.
- **Statut** : `présent dans le code` et `testé localement` (21 tests widget et unitaires).
  Ni sur staging, ni déployé ; aucune capture prise. En production le port est absent :
  l'écran dit « Disponible au branchement serveur » et n'invente rien.

## Pourquoi un nouveau dossier `admin_regroupements`

`admin_demandes` (`ADM-06`) traite une autre sorte de demande : une demande de changement
de règle ou de réaffectation, une à la fois, avec un verdict accorder / refuser et un
motif. Les demandes de créneau des familles ne se jugent pas une par une : elles se
lisent réunies, et l'action est la création d'une classe. Mêler les deux dans
`demandes_page.dart` aurait donné deux files et deux gestes sur un même écran. Le nouvel
écran vit donc dans `lib/features/admin_regroupements/`, sous Opérations, et réutilise ce
que CLASSE-FORM-1 a construit (voir « Réutilisé, pas dupliqué »).

## Revue des propositions

| Proposition | Source | Règle utile | Conclusion | Modification | Dérogation |
|---|---|---|---|---|---|
| Une carte par regroupement : titre « jours · heure », puis heure de référence, autres fuseaux, public, langue, élèves | Décision §3 ; Nielsen n°1 (visibilité de l'état) ; K-55 | Ce qui sert à décider se lit sans ouvrir la carte ; cartes détachées (`PileCartes`) | Conforme | `LigneCleValeur` pour chaque donnée ; chiffres tabulaires pour l'heure et les élèves | Aucune |
| Heure de référence et fuseaux utiles dits par la ville | Décision §1 (familles d'Europe et d'Amérique du Nord) ; COUPE-MOTS-1 ; WCAG 1.4.4 | Un fuseau se lit, il ne se déchiffre pas ; aucun mot coupé à 320 px en texte ×2 | Ajusté | « 18 h, heure de Paris » ; « 17 h à London · 12 h à Toronto » ; « 5 h le lendemain à Paris ». Le nom IANA (`America/Los_Angeles`) se coupait à 320 px ×2 : la ville en est tirée (`villeDuFuseau`) | Les heures des autres fuseaux sont calculées par le serveur ; le client n'en convertit aucune |
| « Prête » / « Incomplète » par trois signaux | `lib/CLAUDE.md` (jamais la couleur seule) ; WCAG 1.4.1 | Pastille au ton, mot dans la pastille, phrase dessous | Conforme | `StatusPill` succès ou avertissement ; « Le quota est atteint… » ou « Il manque {n} élèves pour atteindre le quota. Vous pouvez quand même créer la classe. » | Aucune |
| Quota lu dans le port | Décision §2 (5 enfants, 6 adultes, lus dans `app_config`) ; `02_ARCHITECTURE` | Une règle de l'académie ne se recopie pas dans le client | Conforme | `RegroupementDemandes.quota` ; aucun 5 ni 6 dans l'écran. Les valeurs n'existent que dans l'adaptateur de démonstration | Aucune |
| Tri : prêtes d'abord, puis les plus nombreuses ; une phrase le dit | Demande du directeur ; Nielsen n°1 ; Hick | L'ordre se comprend sans légende cachée | Conforme | `trierRegroupements` (pur, testé) ; phrase `tri` sous le titre de section. À égalité : premier jour, heure, identifiant (ordre stable) | Aucune |
| Classe créée mais enseignant pas encore confirmé : en tête, « Enseignant à confirmer » | `lib/CLAUDE.md` (alerte urgente en tête) ; Nielsen n°3 (contrôle et liberté) | Fermer la feuille au milieu ne perd rien : la suite se reprend | Ajusté | Section `sectionAFinir` avant les demandes ; bouton « Choisir l'enseignant », qui rouvre la feuille directement à la proposition | Dépend du serveur : `regroupements()` rend la classe créée tant qu'elle n'a pas d'enseignant (ligne Contrats) |
| Un seul bouton plein à l'écran | K-56 | Les autres actions sont secondaires | Conforme | Le bouton de la première carte actionnable est plein, les suivants secondaires (même règle que REMPL-1) | Aucune |
| « Créer la classe » jamais grisé ; avant le quota, la feuille dit « incomplète » et l'administration confirme | Demande du directeur ; K-56 ; K-58 (conséquence dite avant le choix) ; Nielsen n°5 | Un bouton qui ne peut pas aboutir n'est pas grisé ; une conséquence se dit avant | Conforme | La carte ouvre la feuille (étape de confirmation) ; la feuille dit « Cette classe sera incomplète : 2 élèves sur 5. Elle ouvrira quand même… » ; le bouton dit « Créer la classe incomplète » | Aucune |
| Genre de la classe exigé dans la feuille, trois cartes sans présélection | CLASSE-FORM-1 (D1, D2) ; K-58 | Le même geste qu'à la création d'une classe | Conforme | Mêmes cartes et mêmes textes que CLASSE-FORM-1 (`genre_classe_libelles.dart`, sorti de `groupes_page.dart`) ; presser sans genre dit « Il manque le genre de la classe… » | La ligne « genre non enregistré » de CLASSE-FORM-1 n'est pas reprise : le nouveau port reçoit le genre par contrat |
| Nom de la classe déduit, affiché, non saisi | K-57 (déduit > choisi > saisi) ; CLASSE-FORM-1 D8 | Ce qui se déduit ne se tape pas | Ajusté | « Filles, lundi, mardi, jeudi 18 h », même forme que CLASSE-FORM-1 ; phrase « Déduit du genre, du public, des jours et de l'heure. » | Le nom n'est pas modifiable dans cette feuille : rien ne le demande, et la feuille reste courte (écart 3) |
| Proposition d'enseignant : premier choix présélectionné, avec sa raison ; incompatible visible avec la sienne | Décision §3 ; CLASSE-FORM-1 D2, D4, D5 ; K-57 ; K-58 | Proposer, dire pourquoi, laisser confirmer | Conforme | `enseignantsPourClasseProvider` + `classerEnseignants` (étendu à plusieurs séances : libre à **chacun** des jours) ; mention « Premier choix : libre à ce créneau, … » ; raison « Classe de filles : seule une enseignante peut la prendre. » | Aucune |
| Fin : « Les familles ont été prévenues. » | Décision §3 et §4 | Dire ce qui s'est passé, en clair | Conforme | Phrase en `liveRegion`, avec « Classe … : … en est l'enseignant. » | La notification elle-même est envoyée par le serveur |
| Double appui : un seul envoi | Nielsen n°5 ; D5 | Un geste répété ne crée rien en double | Conforme | Drapeau d'envoi + `ActionPrincipale.enCours` ; **une seule `cleEnvoi` par feuille**, que le serveur rend idempotente | Aucune |
| Création concurrente par deux membres de la direction | Décision §3 ; K-59 | Dire ce qui s'est passé et quoi faire | Conforme | `CreationDejaFaite` : « Un autre membre de la direction vient de créer cette classe : rien n'a été créé en double. Fermez cette feuille pour retrouver la liste à jour. » ; la file est relue | Aucune |
| Réponse perdue | D5 (« non confirmé », jamais « non envoyé ») ; K-59 | Ne rien supposer | Conforme | « La création n'est pas confirmée : la réponse du serveur n'est pas arrivée. Pressez de nouveau : la même demande sera reprise, sans classe en double. » | Aucune |
| Capacité absente : pas de bouton, une phrase | `lib/CLAUDE.md` (un widget lit une capacité, jamais un rôle ; bouton non rendu plutôt que grisé) | Ce que la personne ne peut pas faire ne s'offre pas | Conforme | `peutCreerClasse`, `peutAffecterEnseignant` rendus par le serveur ; phrases `nonOuvert`, `affectationNonOuverte` | Aucune |
| Aucun nom d'élève | Demande du directeur ; `02_ARCHITECTURE` (mineurs) | Montrer le nombre, jamais la liste | Conforme | Le port ne rend que `nombreEleves` | Aucune |

## Fiche d'écran « Classes à ouvrir »

- **Rôle** : direction (admin), par capacité. **Zone** : Opérations. **Route** :
  `/admin/operations/regroupements` (`Routes.adminOperationsRegroupements`). **Entrée** :
  raccourci « Classes à ouvrir » de l'Accueil admin (`ADM-01`), juste sous l'Espace de
  traitement.
- **Question de l'écran** : « Quelles classes ouvrir, avec quels élèves ? »
- **Action principale** : « Créer la classe » (première carte). **Feuille** : « Créer la
  classe » ou « Créer la classe incomplète », puis « Confirmer l'enseignant », puis
  « Fermer ».
- **Fichiers** :
  - `lib/core/offres/port_regroupements_admin.dart` (port, provider, nouveaux types) ;
  - `lib/features/admin_regroupements/regroupements_page.dart` (écran) ;
  - `lib/features/admin_regroupements/feuille_classe_regroupement.dart` (feuille en trois
    étapes) ;
  - `lib/features/admin_regroupements/regroupements_libelles.dart` (tri et mise en mots,
    purs) ;
  - `lib/features/demo/regroupements_demo.dart` (adaptateur de démonstration, branché dans
    `surchargesDemoAdmin`).
- **États** :
  - **chargement** : `Skeleton.liste` dans `BlocAsynchrone` ;
  - **contenu** : deux sections, « Enseignant à confirmer » puis « Demandes réunies » ;
  - **vide** : « Aucune demande en attente » ;
  - **erreur** : `EtatSysteme` et « Réessayer » ;
  - **hors ligne** : le bandeau de `PageShell` une fois ; `EtatSansDonnees` seulement si
    rien n'a pu être lu ; dans la feuille, le bouton n'est pas rendu et une phrase le dit ;
  - **port absent (production)** : `EtatSysteme` indisponible, « Disponible au branchement
    serveur ».
- **Mobile / tablette / bureau** : une colonne de 760 au plus ; bouton de feuille pleine
  largeur sur téléphone et tablette, largeur du contenu au bord de fin sur bureau
  (`BasDeFeuille`).
- **Accessibilité** : titres de carte en `header` ; messages et résultats en `liveRegion` ;
  RTL et texte ×2 vérifiés à 320 px.

## Réutilisé, pas dupliqué

- `PortEnseignantsClasse`, `enseignantsPourClasseProvider`, `classerEnseignants`
  (CLASSE-FORM-1) : la proposition d'enseignant. `classerEnseignants` reçoit un paramètre
  facultatif `creneaux` (plusieurs séances par semaine) ; les appels existants ne changent
  pas.
- Les cartes de genre, les raisons et la mention « Premier choix » : sorties telles quelles
  de `groupes_page.dart` vers `lib/features/admin_groupes/genre_classe_libelles.dart`.
- Le bas de feuille (bouton plein, largeur, repli hors ligne) et le message d'alerte :
  sortis de `groupes_page.dart` vers `lib/features/admin_groupes/bas_de_feuille.dart`
  (`BasDeFeuille`, `MessageAlerte`). `groupes_page.dart` les importe ; son rendu ne change
  pas (tests CLASSE-FORM-1 verts).

## Écarts voulus

1. **Fuseaux dits par la ville**, pas par l'identifiant IANA complet : il ne tient pas à
   320 px en texte ×2, et « heure de Paris » se lit mieux. L'identifiant reste dans le port.
2. **Classe créée sans enseignant** : si la feuille se ferme avant la confirmation,
   l'écran compte sur le serveur pour rendre la classe dans `regroupements()` (champ
   `classe`), afin de reprendre la proposition. Sans cela, la classe resterait sans
   enseignant hors de cet écran.
3. **Nom non modifiable ici** : déduit et affiché. Le renommage d'une classe n'existe pas
   encore dans `ADM-09` ; il se fera là, pas dans cette feuille.
4. **Comparaison des créneaux à l'heure près, fuseau ignoré** (`memeHeure`), comme
   CLASSE-FORM-1 : les créneaux libres de l'enseignant sont lus dans son fuseau, ceux du
   regroupement dans le fuseau de référence. Juste quand les deux coïncident, approximatif
   sinon ; le serveur pourra rendre des créneaux libres déjà convertis.
5. **Aucune traduction arabe** des nouveaux libellés : repli sur le français
   (`fallback_strategy: base_locale`), comme les lots précédents.

## Lignes Contrats et Backend à ouvrir

- **Contrats (nouveau port, aucun port existant modifié)** : `PortRegroupementsAdmin`
  (`lib/core/offres/port_regroupements_admin.dart`) : `regroupements()`, `creerClasse
  (regroupementId, genre, libelle, cleEnvoi)` → `ClasseCreee` / `CreationDejaFaite` /
  `CreationRefusee(motif)`, `affecterEnseignant(classeId, enseignantId)` → `affecte` /
  `dejaAffecte`. À relire par ChatGPT avant son adaptateur `*_supabase.dart`.
- **Backend (ChatGPT)** :
  - RPC de lecture des regroupements : clé de ressemblance (jours triés et dédoublonnés,
    heure locale, fuseau, public, langue), nombre d'élèves, quota lu dans `app_config`,
    heures dans les fuseaux utiles, capacités `peut_creer_classe` et
    `peut_affecter_enseignant`, classe créée sans enseignant ; **aucun nom d'élève** ;
  - RPC de création atomique : classe + intégration des élèves en une transaction ;
    refus explicite `deja_creee` si une classe existe déjà pour ce regroupement ;
    idempotence sur `cle_envoi` ; genre enregistré ; notification « classe validée » aux
    familles ;
  - RPC d'affectation : garde positive, refus `deja_affecte`, notification « enseignant
    affecté » avec la date et l'heure locale du premier cours ;
  - source `enseignants_pour_classe` (déjà demandée par CLASSE-FORM-1) : genre public,
    créneaux libres, charge.
- **Branchement** : `portRegroupementsAdminProvider` reste `null` en production tant que
  l'adaptateur réel n'est pas relu (COHABITATION §2, branchement final par Claude).

## Contre-épreuve

Trois défauts remis un à un, chacun rend des tests rouges, puis annulé :

1. Tri sans la règle « prêtes d'abord » → rouge : « prets d abord, puis le plus grand
   nombre ». Au premier passage, ce défaut restait vert (les regroupements prêts étaient
   aussi les plus nombreux) : un cas « prête avec moins d'élèves qu'une incomplète » a été
   ajouté, et le défaut est alors devenu rouge.
2. Quota écrit en dur (5 enfants, 6 adultes) au lieu du port → rouge : « le quota vient du
   port, jamais d une valeur ecrite ici ».
3. Création concurrente prise pour un succès → rouge : « deux membres de la direction :
   message clair, rien en double ».

## Libellés ajoutés

Déclarés aussi dans `tool/libelles_sources.json` (source : décision du directeur du 09/10,
§1 et §3, étape OFFRES-ADM-1).

| Clé | Texte |
|---|---|
| `admin.regroupements.titre` | Classes à ouvrir |
| `admin.regroupements.sousTitre` | Les demandes des familles qui se ressemblent sont réunies : mêmes jours, même heure, même fuseau, même public, même langue. |
| `admin.regroupements.tri` | Les demandes prêtes à ouvrir une classe d'abord, puis les plus nombreuses. |
| `admin.regroupements.indisponibleTitre` | Disponible au branchement serveur |
| `admin.regroupements.indisponiblePhrase` | Les demandes réunies s'afficheront ici dès le branchement serveur. D'ici là, rien n'est affiché : aucune demande n'est inventée. |
| `admin.regroupements.erreur` | Les demandes réunies n'ont pas pu être lues : le serveur n'a pas répondu. Réessayez dans un instant. |
| `admin.regroupements.sansDonnees` | Les demandes réunies n'ont pas pu être chargées |
| `admin.regroupements.vide` | Aucune demande en attente |
| `admin.regroupements.videDetail` | Les nouvelles demandes des familles apparaîtront ici, réunies quand elles se ressemblent. |
| `admin.regroupements.sectionAFinir` | Enseignant à confirmer |
| `admin.regroupements.sectionDemandes` | Demandes réunies |
| `admin.regroupements.cleJours` | Jours |
| `admin.regroupements.cleHeure` | Heure de référence |
| `admin.regroupements.cleAilleurs` | Ailleurs |
| `admin.regroupements.clePublic` | Public |
| `admin.regroupements.cleLangue` | Langue |
| `admin.regroupements.cleEleves` | Élèves |
| `admin.regroupements.heure` | {heure} h |
| `admin.regroupements.heureMinutes` | {heure} h {minutes} |
| `admin.regroupements.heureFuseau` | {heure}, heure {deVille} |
| `admin.regroupements.ailleursMemeJour` | {heure} à {ville} |
| `admin.regroupements.ailleursVeille` | {heure} la veille à {ville} |
| `admin.regroupements.ailleursLendemain` | {heure} le lendemain à {ville} |
| `admin.regroupements.eleves.one` | {n} élève sur {quota} |
| `admin.regroupements.eleves.other` | {n} élèves sur {quota} |
| `admin.regroupements.pret` | Prête |
| `admin.regroupements.incomplete` | Incomplète |
| `admin.regroupements.pretDetail` | Le quota est atteint : la classe peut ouvrir complète. |
| `admin.regroupements.manquent.one` | Il manque {n} élève pour atteindre le quota. Vous pouvez quand même créer la classe. |
| `admin.regroupements.manquent.other` | Il manque {n} élèves pour atteindre le quota. Vous pouvez quand même créer la classe. |
| `admin.regroupements.nonOuvert` | La création de cette classe ne vous est pas ouverte : un membre de la direction qui en a le droit peut la faire. |
| `admin.regroupements.affectationNonOuverte` | La confirmation de l'enseignant ne vous est pas ouverte : un membre de la direction qui en a le droit peut la faire. |
| `admin.regroupements.classeAttend` | Classe {libelle} créée : son enseignant reste à confirmer. |
| `admin.regroupements.creer` | Créer la classe |
| `admin.regroupements.creerIncomplete` | Créer la classe incomplète |
| `admin.regroupements.choisirEnseignant` | Choisir l'enseignant |
| `admin.regroupements.contexte.one` | L'élève de ces demandes sera intégré à la classe dès sa création. Vous confirmerez ensuite l'enseignant proposé. |
| `admin.regroupements.contexte.other` | Les {n} élèves de ces demandes seront intégrés à la classe dès sa création. Vous confirmerez ensuite l'enseignant proposé. |
| `admin.regroupements.incompletePhrase.one` | Cette classe sera incomplète : {n} élève sur {quota}. Elle ouvrira quand même, et d'autres élèves pourront la rejoindre. |
| `admin.regroupements.incompletePhrase.other` | Cette classe sera incomplète : {n} élèves sur {quota}. Elle ouvrira quand même, et d'autres élèves pourront la rejoindre. |
| `admin.regroupements.nomDetail` | Déduit du genre, du public, des jours et de l'heure. |
| `admin.regroupements.dejaCreee` | Un autre membre de la direction vient de créer cette classe : rien n'a été créé en double. Fermez cette feuille pour retrouver la liste à jour. |
| `admin.regroupements.refusee` | La classe n'a pas été créée : {motif}. Vérifiez les demandes, puis pressez de nouveau. |
| `admin.regroupements.nonConfirmee` | La création n'est pas confirmée : la réponse du serveur n'est pas arrivée. Pressez de nouveau : la même demande sera reprise, sans classe en double. |
| `admin.regroupements.creee.one` | Classe {libelle} créée : {n} élève intégré. |
| `admin.regroupements.creee.other` | Classe {libelle} créée : {n} élèves intégrés. |
| `admin.regroupements.enseignantTitre` | Enseignant proposé |
| `admin.regroupements.enseignantContexte` | Le premier choix tient compte du genre de la classe, de ses créneaux libres aux mêmes jours et à la même heure, puis du nombre de ses classes. Ces heures sont comparées telles quelles, sans conversion de fuseau : si l'enseignant vit dans un autre fuseau, vérifiez avec lui avant de confirmer. Confirmez-le ou choisissez une autre personne. (texte revu par OFFRES-1B, réserve ADM 1) |
| `admin.regroupements.confirmerEnseignant` | Confirmer l'enseignant |
| `admin.regroupements.enseignantHorsLigne` | Sans réseau, l'enseignant ne peut pas être confirmé. Votre choix reste affiché : revenez quand la connexion est rétablie. |
| `admin.regroupements.affectationNonConfirmee` | L'enseignant n'est pas confirmé : la réponse du serveur n'est pas arrivée. Pressez de nouveau. |
| `admin.regroupements.dejaAffecte` | Un autre membre de la direction a déjà confirmé l'enseignant de cette classe : votre choix ne remplace pas le sien. (texte revu par OFFRES-1B, réserve ADM 3) |
| `admin.regroupements.famillesPrevenues` | Les familles ont été prévenues. |
| `admin.regroupements.famillesClasseValidee` | Les familles ont été prévenues que leur classe est validée. (OFFRES-1B, réserve ADM 2) |
| `admin.regroupements.termineDetail` | Classe {libelle} : {enseignant} en est l'enseignant. |
| `admin.tableau.outilsRegroupements` | Classes à ouvrir |
| `admin.tableau.outilsRegroupementsDetail` | Les demandes des familles réunies quand elles se ressemblent, et la création de leur classe. |

## Réserves de la vérification corrigées (OFFRES-1B, 09/10/2026)

Statut : `présent dans le code` et `testé localement` (groupe « Reserves de la
verification (OFFRES-1B) » de `test/features/admin_regroupements/regroupements_page_test.dart`,
chaque test rouge avant la correction et rouge de nouveau quand le défaut est remis).
Aucun port ni aucune logique de classement modifiés.

| Réserve | Correction | Preuve |
| :--- | :--- | :--- |
| ADM 1 : « créneaux libres à ces jours et à cette heure » promettait une comparaison que `memeHeure` (`lib/core/admin/enseignants_classe.dart`) fait sans fuseau | Texte nuancé, logique inchangée : « Ces heures sont comparées telles quelles, sans conversion de fuseau : si l'enseignant vit dans un autre fuseau, vérifiez avec lui avant de confirmer. » Comparer dans le même fuseau demanderait une base de fuseaux que le dépôt n'embarque pas (écart voulu n° 4) : ni simple ni sûr ici ; le serveur pourra rendre des créneaux libres déjà convertis | « ADM 1 : le texte de proposition ne promet pas une comparaison dans le meme fuseau » |
| ADM 2 : rien ne disait, à la création, que les familles sont prévenues de la validation de leur classe (décision §4) | Sous « Classe … créée », la feuille dit « Les familles ont été prévenues que leur classe est validée. » ; après l'affectation, « Les familles ont été prévenues. » comme avant | « ADM 2 : a la creation, les familles sont prevenues que leur classe est validee ; apres l affectation, prevenues » |
| ADM 3 : « déjà affecté par un autre » affichait « Un autre membre de la direction a déjà confirmé un enseignant pour cette classe : rien n'a changé. » puis « Les familles ont été prévenues » | Une seule phrase, en `liveRegion` : « Un autre membre de la direction a déjà confirmé l'enseignant de cette classe : votre choix ne remplace pas le sien. » ; « Les familles ont été prévenues » n'est plus affiché dans ce cas | « ADM 3 : deja affecte par un autre, une seule phrase claire » (320 px, texte ×2, LTR et RTL) |

Aucun bouton grisé ajouté ; un seul bouton plein (« Fermer ») sur l'étape de fin.

## C-11 bis : une heure par jour (10/10/2026)

Statut : `présent dans le code` et `testé localement` (groupe « C-11 bis : une heure par
jour » de `test/features/admin_regroupements/regroupements_page_test.dart`). Branche
locale `claude/c10-bis`, non poussée, non déployée.

**Même défaut que C-10 bis.** `RegroupementDemandes` portait `jours` et une seule
`reference` (`HeureDansFuseau`) pour tous les jours, et `autresFuseaux` une heure par
fuseau sans dire pour quel jour. Les demandes réunies pouvant avoir une heure différente
selon le jour, la clé de ressemblance devient « mêmes jours, même heure pour chacun ».

**Contrat C-11 bis** (`lib/core/offres/port_regroupements_admin.dart`) :

- `RegroupementDemandes({…, required String fuseau, required Iterable<OccurrenceCreneau>
  occurrences, List<HeureDansFuseau> autresFuseaux, …})` remplace `jours` + `reference` ;
  occurrences triées par jour ; liste vide et jour en double refusés par assertion ;
  getters `jours` et `heuresToutesEgales` ; le constructeur n'est plus `const` ;
- `HeureDansFuseau.jourIso` (`int?`) : le jour de l'occurrence que cette heure traduit ;
  nul, elle vaut pour tous les jours, ce que l'assertion n'admet que si toutes les
  heures de référence sont égales ;
- tri (premier jour, puis heure de ce jour), nom déduit et créneaux comparés à
  l'enseignant (`creneauxDe`) lisent l'heure de chaque jour.
- Ligne Contrats à relire par ChatGPT avant son adaptateur : une occurrence par jour,
  et une heure d'un autre fuseau par jour quand les heures diffèrent.

**Règle d'affichage** (la même que C-10 bis) : heures égales, la carte et la feuille
restent inchangées (« Lundi, mardi, jeudi · 18 h », « Jours », « Heure de référence »
« 18 h, heure de Paris ») ; heures différentes, le titre et la ligne « Jours et heures »
disent « Mardi 20 h, jeudi 20 h 30 », puis « Fuseau de référence » « Heure de Los
Angeles », et « Ailleurs » dit le jour de chaque heure (« Mardi : 5 h le lendemain à
Paris · Jeudi : 5 h 30 le lendemain à Paris »). Testé à 320 px, texte ×2, LTR et RTL,
feuille ouverte.

**Libellés ajoutés** (`admin.regroupements`, ajoutés après `ailleursLendemain`, rien
réordonné ; rédigés par l'agent, à faire valider par le directeur ; déclarés dans
`tool/libelles_sources.json`) :

| Clé | Texte |
|---|---|
| `admin.regroupements.cleJoursHeures` | Jours et heures |
| `admin.regroupements.cleFuseau` | Fuseau de référence |
| `admin.regroupements.fuseauValeur` | Heure {deVille} |
| `admin.regroupements.jourHeure` | {jour} {heure} |
| `admin.regroupements.ailleursJour` | {jour} : {ailleurs} |

**Démonstration.** Le regroupement adultes en anglais (Los Angeles) a désormais mardi
20 h et jeudi 20 h 30, et une heure de Paris par jour.

**Contre-épreuve** : les mêmes défauts que C-10 bis rendent rouges les tests C-11 bis
(heures écrasées par la première, heure commune affichée sans vérification, tri retiré,
doublon accepté, heure d'un autre fuseau sans jour acceptée), puis annulés.
