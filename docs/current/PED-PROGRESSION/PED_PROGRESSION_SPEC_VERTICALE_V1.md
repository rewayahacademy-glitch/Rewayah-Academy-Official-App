# REWAYAH · PED-PROGRESSION · Suivi pédagogique continu

**Version :** 1.0 · 11 octobre 2026  
**Nature :** spécification verticale **DELTA UX/UI** et contrat d'intégration frontend, sans recréation fonctionnelle  
**Statut :** **SPÉCIFICATION PROPOSÉE, À VALIDER PAR LA DIRECTION** ; aucune implémentation ni recette n'est présumée  
**Exécutant :** Claude Code · Flutter Android/iOS/tablette/web/desktop  
**Frontière d'autorisation :** **FRONTEND ONLY**. Interdits dans ce lot : SQL, Supabase, RLS/RPC, edge functions, schéma, authentification, R2, LiveKit, jobs, réécriture des API, déploiement, fusion Git et changements de production. Les contrats manquants deviennent des dépendances nommées, pas des tâches autorisées.  
**Livrable recherché :** rendre intelligible, cohérente et accessible la progression continue de chaque élève **à partir des écrans réellement existants**, sans ajouter de saisie à l'enseignant.

## 0. Décision en une phrase

**La page canonique « Progression » explique la trajectoire académique sur plusieurs séances.** « Historique → Détail de séance » décrit une séance précise ; « Travail à préparer » décrit les actions à préparer ; le cahier K-45 reste la source des observations enseignantes. Aucun écran ne duplique la fonction des autres.

### 0.1 Ce document ne rouvre pas les décisions du 11 octobre

- Cahier enseignant **K-45 inchangé**, obligatoire et prérempli, correction possible, cible de moins de 45 secondes par séance entière ; il conditionne déjà la validation de séance et les règles de rémunération.
- **PED-APRÈS V1** demeure le contrat de restitution **par séance** et de politique de partage : activée par défaut, exception Classe/élève, publication manuelle ciblée, révocation et confidentialité. Le présent lot **ne reprogramme pas ce contrat**.
- La progression n'est **pas** une synthèse de tous les cahiers bruts. L'interface consomme une projection autorisée et validée : jamais une requête directe aux notes confidentielles.
- Une fonction = un endroit ; préservation du shell, des composants, routes, textes validés, high-fi existantes et tokens gelés. Une nouvelle destination, un nouveau sous-menu ou une duplication de service constituent des défauts.
- Les décisions des rôles, classes, limites commerciales, paiements, contrôle et pédagogie restent celles des documents les plus récents. Ne pas coder une capacité de 5/6 au prétexte que le référentiel académique mentionne une cible pédagogique différente des paramètres opérationnels ; afficher la capacité de Classe fournie par sa source.

### 0.2 Sources et autorité

1. Dernière décision explicite de la direction.
2. Autorisations, confidentialité et décisions métier en vigueur.
3. **`REWAYAH_PED_APRES_SPEC_VERTICALE_V1_2026-10-11.md`** (11/10), notamment séparation cahier brut, résumé familial et progression.
4. **`REWAYAH_REFERENTIEL_ACADEMIQUE_V1(1).docx`** (18/09), §§ 4, 8–15, 17, 19–22, 26–30 : compétence, continuité, classe/cohorte, observations, autonomie et validation humaine.
5. **`REWAYAH_TEACHING_CORE_MULTI_AGENTS_V1(2).docx`**, groupe/espace pédagogique permanent, préparation, travail, autorisation.
6. **`REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md`**, `03_DESIGN_SYSTEM_ET_UX.md`, high-fi déjà validées, contrats et code du dépôt **au HEAD réel de Claude**, puis référentiels officiels Material 3, Flutter Adaptive/Responsive, WCAG 2.2 AA et Apple HIG pour l'expérience.
7. Le présent document définit le **delta frontend** quand les éléments ci-dessus ne le définissent pas. Il ne crée aucune nouvelle règle académique.

### 0.3 Vérité du code : constat ciblé, **pas** certification du HEAD actuel

Consultation de la branche `ccr-1b1bfa0b-m1kvkk` du dépôt `rewayahacademy-glitch/Rewayah-Academy-Official-App`, à rapprocher du HEAD utilisé par Claude :

| Existant identifié | Fonction | Conclusion / instruction |
|---|---|---|
| `lib/features/classe_tuteur/progression_classe_page.dart` | `ProgressionClassePage`, route déjà commentée `/tuteur/classes/:classeId/progression`; niveau humain + liste de jalons ; chargement/vide/erreur | **Conserver et enrichir uniquement si une source réelle le permet.** Pas de seconde page « Mon évolution ». |
| `lib/core/capacites/port_progression_famille.dart` | `ProgressionEleve(eleveId, niveauHumain?, jalons[])`, `PortProgressionFamille`, provider | Implémentation de repli `ProgressionFamilleIndisponible`, code `DB-CRS-11`, sur la branche examinée. **Ne jamais transformer des données fictives en progression réelle.** |
| `lib/features/classe_tuteur/travail_classe_page.dart` | `TravailClassePage`, assignations et états serveur | L'ordre et les états existent ; « fait » n'est pas « acquis ». Aucun second module Devoirs. |
| `lib/features/suivi_foyer/detail_seance_page.dart` | Historique → Détail | Régi par PED-APRÈS. Ce lot ne le réécrit pas. |
| `lib/features/cahier/cahier_page.dart`, `lib/features/cahier/vue_cahier.dart` | Cahier K-45, décisions individuelles, position de reprise | **GELÉ** dans ce lot ; ne pas ajouter de champ « note de progression ». |
| `lib/features/fiche_groupe/preparation_seance.dart` | `PreparationSeance` = support prévu, reprise, objectif ; `ProjectionEleve` = objectif, présence récente, reprise, dernier point et avatar | Les providers de préparation/projection sont en repli sans source dans la branche examinée. **Ne pas ajouter de « À renforcer » à la carte Préparation : commentaire source explicite de limitation à trois éléments.** |
| `lib/features/tc_espace_groupe/espace_groupe_page.dart` | Espace Groupe pour les rôles autorisés, emplacement de progression secondaire | Réutiliser cet emplacement s'il est accessible ; ne pas créer une page élève redondante. |
| `lib/features/admin_pedagogie_progression/progression_page.dart`, `lib/core/admin/service_progression.dart` | `ADM-11` et service `progression_admin`, listes des élèves, cycle/niveau, blocages/dérogations, actions administratives existantes | **Préserver** le registre et ses permissions ; ne pas ajouter un second cockpit de progression. |
| `lib/features/admin_pedagogie_qualite/qualite_page.dart` | Contrôle qualité / files d'anomalies | **Préserver** l'autre finalité ; aucun nouveau module « Alertes pédagogiques ». |
| PR GitHub **#21**, `codex/backend-f2-after-c` → `ccr-1b1bfa0b-m1kvkk` | Travaux F2 de raccordement | Au contrôle consulté, **ouverte, brouillon, non fusionnée, non fusionnable en l'état**. Interdiction de supposer qu'elle livre la projection complète ou d'intervenir sur son périmètre. |

**Note d'intégrité :** toute lecture d'une branche ou d'une PR n'est qu'un instantané. Claude doit contrôler ses fichiers, imports, routes, tests et PR concurrentes avant de coder et noter les divergences ; il ne peut invoquer cet inventaire comme preuve de livraison.

---

## 1. Portée fermée et définition du fini

### Inclus : quatre expériences existantes, pas de nouveau produit

**P01 · Famille/tuteur :** lire le **niveau décidé**, l'**objectif actuel**, les **compétences réellement évaluées**, les **jalons institutionnels**, et, lorsque autorisés, un **prochain point de vigilance** à l'endroit `Classe → Progression`. Ces informations peuvent être absentes indépendamment les unes des autres : chaque absence est explicitée sans inventer du contenu.

**P02 · Élève enfant/adulte :** voir depuis son **Espace de Classe** une progression simplifiée adaptée au rôle et aux données réellement autorisées. L'enfant conserve l'« Interface guidée » ; l'adulte voit ses propres résultats ; pas d'accès indirect à l'espace parent d'un autre élève.

**P03 · Enseignant :** retrouver les informations déjà prévues pour préparer la prochaine séance et poursuivre le groupe, sans rapport supplémentaire. Le travail de chaque élève se gère par les contrôles existants et K-45, non par une nouvelle interface de saisie.

**P04 · Administration :** consulter le registre `ADM-11`, discerner les élèves nécessitant une **décision humaine** et retrouver les exceptions et changements de niveau existants. Les statuts pédagogiques non servis ne doivent pas être déduits localement.

### Hors périmètre strict

Les **évaluations structurées de gate, jury, passage de niveau, certificats, Majālis, moteur académique, création/versionnement du curriculum, algorithmes de calcul des compétences et règles d'alerte automatiques nouvelles** relèvent de la verticale suivante **PED-ÉVALUATIONS** ou d'une décision distincte. On peut **afficher des décisions officielles déjà fournies** ; on ne les fabrique pas.

Également exclus : nouvelle page « Statistiques », graphiques calculés localement, scores ou pourcentages décoratifs, intelligence artificielle qui juge l'élève, nouveau rapport hebdomadaire/mensuel, messagerie supplémentaire, notification automatique, réforme du cahier, du système de paie, de l'interface vidéo ou du module présence.

### Conditions de clôture

La verticale est **spécifiée** quand routes et comportements sont exhaustivement décrits. Elle est **implémentée frontend** quand les quatre surfaces réutilisées sont atteignables, visuellement conformes, testées dans tous les états et branchées à des ports existants ou marquées honnêtement indisponibles. Elle n'est **pas livrée de bout en bout** tant que les données, autorisations et projections nécessaires n'ont pas de preuve d'intégration et de recette réelle.

---

## 2. Modèle fonctionnel et vocabulaire non ambigu

### 2.1 Les cinq objets à ne jamais fusionner

| Objet | Définition | Source d'autorité | UI canonique |
|---|---|---|---|
| **Cahier de séance** | Compte rendu par enseignant, éventuellement avec notes internes, décisions par élève et reprise | K-45 et confirmation du service | Cahier enseignant ; **jamais exposé brut à la famille** |
| **Résumé familial d'une séance** | Projection partageable et autorisée d'une séance **précise** | Contrat PED-APRÈS, politique effective et publication | Tuteur `Historique → Détail de séance` |
| **Travail à préparer** | Actions assignées pour le prochain cours, échéance et statut de réalisation | Assignations autorisées | `Classe → Travail à préparer`, carte « Avant le prochain cours » (max. trois actions sur l'aperçu) |
| **Progression continue** | Niveau académique décidé, objectif courant, compétence évaluée, jalon et état individuel dans le temps | Projection académique **validée** et autorisée ; historique des décisions | `Classe → Progression` ; miroir simplifié enfant/adulte seulement via contrat existant |
| **Pilotage pédagogique** | Suivi des exceptions, cohortes, placements, changements de niveau et décisions | Service administratif/contrôle selon habilitations | `Administration → Pédagogie → Progression` (`ADM-11`) et qualité existante |

**Invariant anti-boucle :** un lien « Voir le travail à préparer » ouvre sa route actuelle ; un lien « Voir le détail de cette séance » ouvre l'Historique actuel ; une information de Progression reste sur sa page. Aucun bouton n'ouvre une seconde copie de la même donnée.

### 2.2 Chaîne causale attendue et statut des preuves

```
Séance tenue → K-45 prérempli → validation confirmée par la source métier
       ├── résumé de séance partageable → PED-APRÈS / Historique
       ├── travail assigné confirmé → Travail à préparer
       ├── décisions et observations reconnues par le référentiel
       │     └── projection académique autorisée → Progression
       └── exceptions institutionnelles → ADM-11 / qualité existantes

Avant la séance suivante : le professeur consulte l'objectif, le support,
la reprise et les seules informations utiles et autorisées déjà prévues.
```

- Les flèches représentent des **dépendances métier attendues**, non la preuve que tous les raccordements existent en octobre 2026.
- Le cahier **ne décerne pas automatiquement** un diplôme, ne réussit pas un gate et ne transforme pas mécaniquement « Continuer » en « Acquis ».
- Une observation tardive, une absence, une tâche non effectuée ou un indicateur de présence ne constituent **pas** une évaluation de maîtrise.
- Une correction K-45 affecte la projection **uniquement si** le contrat et ses règles de publication/correction le garantissent. Sinon, afficher la dernière projection académique officiellement confirmée et signaler sa fraîcheur lorsque la source l'indique.

### 2.3 Niveaux d'observation

Le référentiel académique distingue :

| État académique | Sens à exposer | Règle UI |
|---|---|---|
| **À renforcer** | Maîtrise pas suffisamment fiable ; prévoir renforcement | Ne pas présenter comme sanction, échec ou retard personnel. |
| **Acquis** | Compétence montrée, stabilité encore susceptible de confirmation | Ne pas substituer « terminé définitivement ». |
| **Stable** | Stabilité vérifiée dans la durée et dans d'autres contextes | Afficher **uniquement si la source officielle le confirme**. |
| **Non évalué / non renseigné** | Pas de jugement autorisé | Texte `Aucune appréciation de maîtrise n'est disponible pour cette compétence.` ou masquer une ligne absente selon le contexte. |

**Seuils normatifs, à ne pas calculer dans Flutter :** « Stable » demande au moins **trois observations sur deux semaines**, dont **une non préparée**, selon le référentiel V1. Les catégories **E1 mineure, E2 majeure, E3 critique** existent également. Ce document les cite pour empêcher une fausse stabilisation, **pas** pour prescrire à Claude une formule cliente. Le futur moteur d'évaluation et son autorité les appliqueront.

### 2.4 Progression du groupe et de l'individu

La Classe enseigne une unité commune ; l'élève peut avoir une quantité, un passage et un rythme individuel. Le groupe ne se fige pas indéfiniment sur une personne ; le dispositif prévoit renforcement, revue de cohorte et proposition humaine de transfert. Le référentiel V1 indique notamment des repères tels que 40 % du groupe encore en renforcement, écart persistant ou révision longue dégradée. **Ne coder aucun seuil d'alerte dans un widget.** La UI n'affiche que les décisions/alertes justifiées et servies par le domaine métier, sans comparer publiquement des élèves.

### 2.5 Parcours académiques

Le référentiel contient `D0 → F1–F4 → G0`, puis `T1–T6` **ou** `H0–H6 → I1`. La destination Progression doit pouvoir **présenter le libellé humain** du cycle et son objectif si le contrat le fournit. Elle ne doit pas contenir un arbre académique géant ni exposer les codes `F1`, `H3` ou un identifiant interne à la famille.

En Ḥifẓ, les trois flux officiels sont **Nouveau**, **À consolider**, **Révision longue**. S'ils sont réellement fournis à l'élève concerné, ils peuvent apparaître comme trois libellés de suivi, sans jauge estimée, calendrier automatique inventé ou pression à produire plus de nouveau. La dégradation de la révision ancienne peut justifier une suspension du nouveau, mais c'est une **décision pédagogique**, non un « retard » calculé côté Flutter.

### 2.6 Règles temporelles et historiques

- L'acquisition est un **état décidé**, pas une estimation extrapolée du temps d'inscription, du nombre de séances ou des devoirs cochés.
- Les jalons officiellement franchis restent consultables comme événements du parcours si le contrat les expose, y compris après changement d'enseignant ou de Classe selon les autorisations du compte.
- Ne pas effacer l'historique suite à une réorientation, reprise après pause, changement d'enseignant ou édition d'une nouvelle version de curriculum.
- Les versions de curriculum publiées ne sont pas réécrites rétroactivement ; l'interface montre la version/cycle applicable si disponible et utile, sans en fabriquer une.
- Les dates de décisions et mises à jour affichées sont les dates **du service** converties localement, jamais le timestamp du rendu local pris pour une validation.
- Si un service renvoie une correction, montrer la dernière **version académique autorisée** ; le journal sensible des corrections K-45 reste réservé à l'académie selon les droits existants.

---

## 3. Carte des fonctions anti-doublon et des points d'entrée

| Identifiant | Fonction | Écran/surface unique | Point d'entrée | Action et destination |
|---|---|---|---|---|
| `PED-PROG-TUT-01` | Consulter trajectoire de **son** élève | `ProgressionClassePage` existante | Fiche de Classe tuteur → `Progression` | Retour vers cette Classe ; accès élève sélectionné conservé |
| `PED-PROG-TUT-02` | Voir évaluation de **cette séance** | `DetailSeancePage` régi par PED-APRÈS | Historique → séance | Lien éventuel `Voir la progression` vers `PED-PROG-TUT-01` |
| `PED-PROG-TRV-01` | Consulter le travail avant cours | `TravailClassePage` | Classe → `Travail à préparer` | Liste existante ; aperçu max. trois actions ailleurs |
| `PED-PROG-ELV-01` | Voir sa progression simplifiée | Emplacement progression déjà prévu dans `EspaceGroupePage` ou route élève préexistante **à prouver** | Espace de sa Classe | Aucun écran frère créé si emplacement déjà présent |
| `PED-PROG-ENS-01` | Préparer prochain cours | Fiche Groupe enseignant, `PreparationSeance` | Enseignant → Classe → préparation existante | Support, reprise, objectif, sans copie de K-45 |
| `PED-PROG-ENS-02` | Prendre décision sur prestation d'un élève | K-45 existant | Après séance → cahier | Maintenir la feuille d'ajustement existante ; aucune saisie supplémentaire |
| `PED-PROG-ADM-01` | Examiner niveaux et blocages | `ADM-11 ProgressionPage` | Admin → Pédagogie → Progression | Liste, filtres, actions actuelles |
| `PED-PROG-ADM-02` | Voir anomalies/qualité | `QualitePage` existante | Admin → Pédagogie → Qualité | Ne pas doubler la liste dans Progression |
| `PED-PROG-GATE-01` | Gate, promotion institutionnelle, certificats | **Verticale PED-ÉVALUATIONS** sauf actions admin existantes | Navigation existante si déjà autorisée | Pas d'ajout ni de redesign ici |

**Règle de navigation :** raccourcis autorisés uniquement s'ils ouvrent le **même composant/route canonique** ; ne pas créer une « Progression globale » dans `Compte`, `Foyer`, `Accueil` ou `Historique`. Le retour depuis chaque niveau 2 doit fonctionner sur mobile, tablette et web, sans dépendre d'un geste système unique.

---

## 4. Matrice des capacités et périmètre de lecture

| Acteur | Voir son niveau/objectif | Voir observations de séance | Voir compétences/jalons | Décider progression | Voir autres élèves |
|---|---|---|---|---|---|
| Tuteur d'un mineur **autorisé** | Projection familiale de cet élève, si exposée | Selon **PED-APRÈS** | Projection autorisée de cet élève seulement | Non ; demande de réévaluation **uniquement via flux existant s'il existe** | Non |
| Élève enfant | Projection simplifiée **de lui-même** | Consignes destinées à l'enfant, pas cahier brut | Si autorisé et adapté | Non | Non |
| Élève adulte autonome | Son propre état académique | Ses informations selon **droits adultes existants** | Son propre parcours | Non ; demande via procédure existante si disponible | Non |
| Enseignant assigné | Objectifs pédagogiques de ses élèves assignés | K-45 de ses séances, selon habilitation | Roster/projection limitée nécessaire à l'enseignement | Appréciation professionnelle, renforcement et recommandations dans le périmètre accordé | **Seulement** ses élèves assignés, données pédagogiques minimales |
| Admin habilité | Niveau, jalons, exceptions | Selon domaine et permission | Données académiques nécessaires | Actions administratives existantes avec motif, traçabilité et source confirmée | Uniquement les données autorisées par sa compétence |
| Contrôleur | Seulement les vues définies par sa mission | Pas de nouvel accès via ce lot | Selon autorisation explicite existante | Non sauf capacité métier existante et prouvée | Pas d'ouverture générale |
| Comptable | Non | Non | Non | Non | Non par la progression |

**Impossibilités :** jamais de coordonnées de famille, KYC, statut financier, justificatif de paie, note confidentielle, identité d'autres élèves ou erreur brute de serveur dans le rendu Progression familial. Une permission ne naît jamais d'un widget ni d'un drapeau local.

---

## 5. Spécification écran TUTEUR : `PED-PROG-TUT-01`

**Identifiant conservé dans le code :** `ProgressionClassePage` ; **route décrite dans le code examiné :** `/tuteur/classes/:classeId/progression` (vérifier route effective) ; **shell et navigation :** tuteur existant `Accueil · Foyer · Historique · Compte`, avec la Classe comme contexte, sans nouvelle entrée principale. **Famille multienfants :** le contexte `eleveId` reste explicite ; ne jamais utiliser un identifiant d'élève antérieur lors d'un changement de sélection.

### 5.1 Intention et une seule tâche

**Question à laquelle la page répond :** « Où en est cet élève, que travaille-t-il maintenant et quel est le prochain cap validé ? » Cette vue n'est ni le détail du dernier cours, ni un échéancier de devoirs, ni un bulletin de notes. L'action primaire est **la lecture** : aucun CTA principal ne doit être inventé pour remplir la page.

### 5.2 Contenu, ordre canonique

1. **Header du `CadreClasse` déjà utilisé** : retour vers Classe, titre exact `Progression`, sous-titre existant, identité de l'élève et de la Classe via composants existants. Interdiction d'ajouter une deuxième barre d'onglets.
2. **Bloc principal unique `Parcours actuel`** : `Niveau actuel` si `niveauHumain` autorisé ; `Objectif actuel` si le domaine fournit une formulation réelle ; `Parcours` (Fondations, Tilāwah ou Ḥifẓ) seulement si exposé, libellé humain. Ne pas afficher de « prochain niveau » calculé ni de date estimée.
3. **Bloc `Compétences`** **seulement si le contrat a été enrichi et le statut réellement validé** : ligne par compétence pertinente pour l'étape actuelle, libellé humain, pastille `À renforcer` / `Acquis` / `Stable`, explication courte non culpabilisante disponible au lecteur d'écran. Ordre demandé : **objectif en cours**, points à renforcer éventuellement, acquis, stables ; cet ordre est un ordre de présentation, pas une règle de tri académique. Les contenus non prouvés n'apparaissent pas.
4. **Bloc `Étapes franchies`**, réemploi de la liste `jalons` existante ; n'afficher que les jalons institutionnels décidés/servis. Si les jalons ne portent ni date ni lien, ne leur ajouter ni chronologie graphique fictive, ni source ni badge de certificat.
5. **Bloc optionnel `Pour avancer`** : recommandation pédagogique **déjà confirmée comme partageable** (renforcer une compétence, préparer une révision, suspension du nouveau expliquée). Si seul un devoir existe, **un seul lien secondaire** `Voir le travail à préparer` pointe sur sa page réelle ; ne pas recopier la liste de devoirs ici.
6. **Zone secondaire discrète `Dernière mise à jour`** uniquement si la source fournit une date académique réelle ; jamais `mis à jour aujourd'hui` par simple affichage local.

**Contrat actuel minimal :** `niveauHumain` et `jalons`. **En absence de données supplémentaires, ne pas rendre les blocs 2–5 enrichis fictifs** ; conserver exactement la représentation actuelle, en l'améliorant sur des critères UX vérifiables si un défaut existe.

### 5.3 Composition responsive

- **320–599 dp (mobile)** : une seule colonne et **une carte par sujet**, jamais une mini-carte par ligne. Ordre `Header → Parcours actuel → Compétences → Étapes franchies → Pour avancer`. Les lignes internes sont séparées par des filets discrets en retrait. Pas d'illustration qui réduit la lecture ou d'anneau de progression chiffré. Retour touchable ; navigation basse inchangée. Si seulement niveau + jalons sont présents, les rendre dans la carte existante sans surface vide décorative.
- **600–1199 dp (tablette/fenêtre compacte)** : rail selon système existant ; colonne principale lisible, éventuellement panneau secondaire `Étapes franchies` à droite **seulement si l'espace réellement disponible après text scaling** le permet. L'ordre de lecture sémantique reste identique ; pas de sidebar interne.
- **1200 dp et plus (desktop/web)** : vraie composition desktop : shell latéral existant, zone centrale bornée, **colonne principale ~2/3, secondaire ~1/3** si densité de contenu suffisante. Ne pas étirer la page mobile sur toute la largeur ni créer un dashboard administratif. Les actions secondaires se comportent comme liens/boutons, hover/focus visible. Retour et navigation restent accessibles.
- **RTL** : le Coran et les libellés arabes suivent leur direction, sans inverser la logique des jalons ; ne pas coder des marges `left/right` non directionnelles. **Text scaling ×2**, iOS grandes polices, clavier et lecteur d'écran obligatoires.

### 5.4 États complets et microcopy (tuteur, vouvoiement)

| ID | Déclencheur | Texte exact affichable | Interaction/garantie |
|---|---|---|---|
| `TUT-S00` | Chargement de l'élève | `Chargement de la progression…` | Squelette/état existant ; ne pas montrer l'élève précédent |
| `TUT-S01` | Niveau et jalons réels seulement | `Niveau actuel` ; `Étapes franchies` | Reprendre la page actuelle ; aucun statut nouveau |
| `TUT-S02` | Projection enrichie autorisée | `Parcours actuel` ; `Objectif actuel` ; `Compétences` ; `Étapes franchies` | Afficher uniquement champs présents |
| `TUT-S03` | Aucun niveau ni jalon | `Aucune progression à afficher pour le moment.` | Complément : `Les étapes apparaîtront lorsque leur validation sera disponible.` |
| `TUT-S04` | Port indisponible `DB-CRS-11` ou équivalent | `La progression n'est pas disponible pour le moment.` | Laisser retour et autres fonctions actives ; ne jamais interroger cahier brut |
| `TUT-S05` | Erreur passagère | `Impossible de charger la progression.` | `Réessayer`, invalidation du seul provider de l'élève courant |
| `TUT-S06` | Hors ligne, fraîcheur non vérifiable | `Connexion nécessaire pour consulter la progression actualisée.` | Aucune compétence obsolète affichée comme actuelle |
| `TUT-S07` | Permission refusée | `Vous n'avez pas accès à cette progression.` | Ne jamais afficher fragment d'ancien élève ; retour |
| `TUT-S08` | Élève hors de la Classe choisie | `Ce profil élève n'appartient plus à cette Classe.` | Retour Classe ou sélecteur existant ; ne pas reconstituer un historique non autorisé |
| `TUT-S09` | Aucun jalon mais niveau réel | `Aucune étape validée à afficher pour le moment.` | Ne pas mettre une coche automatique |
| `TUT-S10` | Compétences non servies mais niveau/jalons présents | **Aucun bloc Compétences artificiel** | Le reste de la progression demeure accessible |
| `TUT-S11` | Nouvelle décision validée | `Dernière mise à jour : {date locale}` | Seulement si fourni et autorisé |
| `TUT-S12` | Pause / suspension du nouveau, décision réellement publiée | `Le nouveau contenu est temporairement suspendu.` + raison partageable si fournie | Texte factuel, sans jugement, sans prédiction de reprise |
| `TUT-S13` | Changement d'élève/foyer/compte | `Chargement de la progression…` | Écran purgé avant nouvelle projection ; pas de flash inter-foyers |

**Copie enfant sur cette page ?** Non : l'espace tuteur reste en vouvoiement. Le microcopy de l'enfant se trouve à la section 6.

### 5.5 Interactions

- Le retour mène **exactement** à la Classe avec le même élève sélectionné ; un refresh ne doit pas renvoyer à l'accueil global.
- Le bloc `Étapes franchies` est une lecture, **pas** une liste de boutons sauf jalon portant un accès réel à un détail déjà autorisé.
- Si un lien de travail est servi, il ouvre **la route Travail existante**, en préservant les identifiants.
- Aucun bouton `Valider l'étape`, `Passer au niveau suivant`, `Corriger la note`, `Télécharger certificat` ou `Contacter l'enseignant` n'est ajouté par défaut.
- État de progression d'un autre élève ne doit jamais subsister en mémoire visuelle lors d'un changement de sélection ; les clés de provider doivent inclure l'identité nécessaire et invalider correctement.

### 5.6 Critères d'acceptation UX locaux

- Un tuteur entre depuis une **vraie carte Classe**, touche `Progression`, comprend le niveau actuel sans interpréter de codes académiques.
- Un tuteur change d'enfant : aucun nom, objectif, jalon ou état précédent n'apparaît, même brièvement.
- Un jalon marqué « Stable » doit pouvoir être attribué à une **décision académique servie**, pas à une fonction de widget.
- Aucune tâche maison n'est recopiée pour produire un second suivi.
- Sous 320 dp et texte ×2, tous titres, valeurs et retours sont accessibles sans dépassement ; la version desktop n'est pas une extension horizontale du mobile.

---

## 6. Spécification élève enfant / adulte : `PED-PROG-ELV-01`

### 6.1 Localisation

**Réutiliser l'emplacement de progression** déjà prévu dans `EspaceGroupePage` ou dans une page propre à l'élève **seulement si elle existe réellement au HEAD**. Audit obligatoire des rôles/guards/routage. Interdiction de copier `ProgressionClassePage` en `ProgressionEnfantPage` si une composition paramétrée est suffisante. L'élève mineur ne devient pas son propre tuteur ; l'adulte autonome n'est pas artificiellement placé dans un foyer administré par un parent.

### 6.2 Information visible

- **Commune :** un libellé de niveau réellement autorisé ; l'objectif personnel du moment s'il est disponible ; une prochaine action **déjà assignée** qui renvoie à la zone de travail du Groupe ; éventuellement un jalon validé.
- **Enfant, Interface guidée :** faible densité, au maximum **trois informations principales simultanées** : `Ce que j'apprends`, `Ce que je sais faire`, `Mon prochain travail` si données correspondantes ; gros éléments et étiquette audio **uniquement si composant AudioLabel existant et pertinent**. Ne pas exposer d'erreurs E1/E2/E3, de statut institutionnel complexe, de comparaison avec la Classe, ni de tableau de note.
- **Adulte :** contenu académique autonome et non infantilisant, même source autorisée, libellés humains. Le lecteur n'obtient jamais des comptes rendus privés d'autres élèves.
- **Hifz :** si les trois flux sont réellement exposés et exploitables, leur affichage est possible ; sinon les cacher sans calculer des pages à réviser.

### 6.3 Placement et tailles

- **Mobile enfant :** placer la progression **après l'action dominante de séance**, jamais devant `Rejoindre`. Une seule carte regroupée ou une surface d'information déjà prévue ; pas de navigation dans cinq panneaux. Cibles adaptées à l'enfant, icône + mot, étiquettes vocales si disponibles ; animations réduites respectées.
- **Tablette/desktop :** l'Espace Groupe déjà composé a priorité ; ne pas créer une deuxième colonne de données académiques si elle écrase le support ou la préparation. Le texte reste lisible, les actions clavier atteignables.
- **Adulte :** densité légèrement supérieure possible ; même hiérarchie de tâches. Ne pas dupliquer la carte `Avant le prochain cours`.

### 6.4 Textes et états

| Contexte | Texte exact | Comportement |
|---|---|---|
| Enfant, objectif réel | `Ce que j'apprends` | Texte objectif validé, non rédigé par le widget |
| Enfant, jalon réel | `Ce que je sais faire` | Phrase courte fournie et adaptée à l'âge |
| Enfant, tâche réelle | `Mon prochain travail` | Un seul raccourci vers l'action canonique ; pas de checkbox supplémentaire |
| Enfant, aucune source | `Ton progrès n'est pas disponible.` | Ne pas afficher `Tu n'as rien appris.` |
| Adulte, niveau réel | `Votre progression` | Lecture du niveau/objectif autorisé |
| Adulte, aucune source | `Votre progression n'est pas disponible pour le moment.` | Les autres zones Classe restent accessibles |
| Erreur réseau | `Impossible de charger la progression.` | `Réessayer` si pertinent |
| Accès refusé | `Cette progression n'est pas accessible.` | Aucun contournement par deep-link |
| Hors ligne | `Connexion nécessaire pour vérifier votre progression.` | Pas de niveau affiché comme confirmé si accès non vérifiable |

**Règle de langage enfant :** tutoiement ; phrases courtes, concrètes ; ne pas dire « niveau insuffisant », « redoublement », « classement » ou « tu es en retard ».

### 6.5 Recette

Le parcours peut être utilisé au doigt sans lecture de longs paragraphes ; le bouton de cours reste dominant ; l'adulte voit ses propres données ; une transition Interface guidée/standard ne change **aucun droit d'accès** ni aucun état académique.

---

## 7. Spécification enseignant : `PED-PROG-ENS-01`

### 7.1 Ne rien reconstruire

Le **cahier K-45** collecte déjà décisions pédagogiques individuelles et reprise. La **préparation de Classe** expose déjà son contrat : **support prévu, position de reprise, objectif**. Le code examiné interdit explicitement d'ajouter des notes et des « points à renforcer » à la **carte Préparation**. Respecter cette limite.

L'enseignant voit les projections individualisées **uniquement depuis le roster/panneau pédagogique déjà autorisé**, si elles existent : objectif personnel, présence récente utile, dernière position et dernier point dans les formes minimales définies dans `ProjectionEleve`. Ne pas insérer une seconde fiche pédagogique cachée dans la préparation ni élargir la projection avec des données familiales.

### 7.2 Parcours canonique

1. Ouvrir `Enseignant → Classe/Groupe` par la navigation existante.
2. Lire **la prochaine séance**, le support, l'objectif commun et la **position de reprise confirmée** dans le composant de préparation déjà prévu.
3. Consulter, lorsque la surface existante l'autorise, les éléments individuels nécessaires sans quitter le contexte du cours.
4. Pendant la classe, conserver les outils pédagogiques actuels ; la progression n'impose aucun nouveau clic.
5. Après la classe, accéder au **seul K-45** : confirmer par défaut `Continuer`, ajuster les exceptions individuelles, vérifier la position de reprise, valider. Objectif **moins de 45 secondes** pour le cahier complet.
6. La séance suivante doit retrouver les dernières données **confirmées** via les contrats métier ; si elles ne sont pas disponibles, le widget ne les invente pas et ne renvoie pas l'enseignant vers un formulaire parallèle.

### 7.3 États de préparation

| État | Texte conseillé | Décision |
|---|---|---|
| Trois champs réels disponibles | `Préparer la prochaine séance` ; `Support prévu` ; `Reprise` ; `Objectif` | Garder composition existante et valeurs réelles |
| Un champ absent | Ne pas afficher de valeur fictive | Les autres champs restent consultables |
| Source totalement absente | `La préparation de cette séance n'est pas disponible.` | Pas de calcul local à partir d'un cahier potentiellement non validé |
| Source en erreur | `Impossible de charger la préparation.` | `Réessayer` dans la surface existante si elle le permet |
| Cahier précédent en file hors ligne | `Cahier en attente d'envoi.` | La reprise n'est pas qualifiée de confirmée tant que la source ne l'a pas validée |
| Élève transféré/changement d'enseignant | Données uniquement d'élèves actuellement autorisés | L'historique académique persiste côté domaine sans divulguer l'ancien roster |

### 7.4 Qualité mesurable

Pour enseigner, aucune tâche de progression ne doit ajouter **un nouveau formulaire**. Le professeur doit pouvoir retrouver le contexte utile avant la séance en **moins d'une minute**, référence du référentiel V1, et le cahier reste sous sa cible de 45 secondes ; mesurer dans une recette de navigation et signaler toute régression.

---

## 8. Spécification administration : `PED-PROG-ADM-01`

### 8.1 Conserver le registre `ADM-11`

Route et navigation **à relever dans le HEAD** ; libellé visible : `Pédagogie → Progression`. Le `ProgressionPage` actuel dispose d'une liste/tableau adaptive, d'un filtre par cycle, des informations élève/Classe/niveau/date et des exceptions `blocage`/`dérogation`, ainsi que des actions existantes `poserException`, `clorerException`, `promouvoir` avec motif. **Ne pas remplacer le registre par un nouveau « cockpit 360° ».**

L'admin a besoin d'une **file de décisions** et non de lire chaque cahier en séquence. Si un statut supplémentaire est souhaité mais non servi par la projection administrative réelle, il reste une **dépendance académique**, pas une colonne calculée côté Flutter.

### 8.2 Objets et hiérarchie

1. Shell admin existant ; `Pédagogie` actif.
2. En-tête `Progression`, courte description existante.
3. Filtre par cycle et autres filtres **seulement s'ils existent déjà** et filtrent un dataset autorisé ; pas de filtres fictifs.
4. Collection/table actuelle, colonnes nécessaires et légitimes déjà existantes : `Élève`, `Classe`, `Niveau`, `Depuis`, `Exception` ; respecter la largeur disponible et les vues mobile en cartes/groupes.
5. Actions contextuelles existantes, visibles **uniquement** selon la capacité du rôle et l'état du dossier : proposer/lever une exception, changer le niveau selon la procédure réelle.
6. La qualité, le contrôle, les demandes de réévaluation et les alertes institutionnelles **restent dans leur domaine canonique s'il existe**, pas dans un panneau dupliqué.

### 8.3 Action sensible et garde d'intégrité

- Une promotion administrative existante n'est **pas** la validation automatique d'un gate ; la décision académique officielle exige ses prérequis et la responsabilité humaine. Le fait que l'action soit présente dans `service_progression.dart` ne prouve pas que toutes les validations de la nouvelle doctrine académique sont intégrées. **Ne changer ni la RPC ni la règle serveur ici ; signaler toute divergence à PED-ÉVALUATIONS.**
- Avant toute action de progression : réutiliser la **confirmation**, le **motif** et les **états du service** déjà prévus. Si l'état a changé entre lecture et geste : recharger et signaler le conflit ; pas de succès optimiste fictif.
- Ne jamais donner à un contrôleur ou comptable un droit par déduction du lien visible.

### 8.4 Responsive et comportements

- **Mobile :** une liste adaptive lisible, chaque élève en ligne/carte groupée, jamais des cellules illisibles latéralement ; actions contextuelles accessibles par menu et focus.
- **Tablette :** le tableau est autorisé seulement quand sa largeur réelle et le texte agrandi le permettent.
- **Desktop :** tableau performant avec en-têtes, listes paginées/virtualisées si nécessaire, filtres accessibles et actions sans modal de page complète pour une simple exception. Ne pas transformer le registre en succession de petites cartes géantes.
- Conserver ordre et navigation clavier, libellés sémantiques, indicateurs non fondés sur la couleur seule, contrastes AA et mode clair/sombre.

### 8.5 États et messages d'administration

| Situation | Texte | Action |
|---|---|---|
| Chargement | `Chargement des progressions…` | État existant sans table fantôme |
| Zéro élève | `Aucune progression à afficher.` | Conserver filtres utiles et navigation |
| Aucun résultat filtre | `Aucun élève ne correspond à ce filtre.` | Retour `Tous les cycles` si existant |
| Erreur lecture | `Impossible de charger les progressions.` | `Réessayer` |
| Élève sans niveau | `Niveau non déterminé` | Ne pas fabriquer `Débutant` à sa place |
| Élève sans Classe | `Sans Classe` | Ne pas le supprimer de la liste si la source l'inclut |
| Exception existante | `Blocage` ou `Dérogation` selon contrat existant | Détail/action conditionnée à autorisation |
| Écriture en cours | `Enregistrement en cours…` | Neutraliser double soumission |
| Écriture refusée | `La modification n'a pas été enregistrée.` | Garder ancienne valeur, proposer `Réessayer` si sûr |
| Version obsolète / conflit | `La progression a changé. Actualisez avant de poursuivre.` | `Actualiser` ; aucune deuxième commande automatique |
| Autorisation refusée | `Vous n'avez pas accès à cette action.` | Pas d'outil de contournement |
| Données académiques incomplètes | `Certaines informations de progression ne sont pas disponibles.` | Ne pas afficher une alerte « À risque » calculée sans preuve |

**Interdit absolu :** masquer « pas de niveau » en poussant automatiquement un cycle, une évaluation ou une date ; comparer des enseignants sur une vitesse brute de progression ; créer des indicateurs de rendement monétaires dans l'écran pédagogique.

---

## 9. Règles transversales de données, confidentialité et états

### 9.1 Contrats à consommer, pas à développer dans ce lot

| Référence | Entrée conceptuelle | Sortie exigée pour afficher une fonctionnalité | Repli frontend |
|---|---|---|---|
| `PortProgressionFamille.progression(eleveId)` existant | Élève autorisé par session | Version actuelle : `niveauHumain?`, `jalons[]` ; enrichissement seulement si déjà implémenté sur la branche effective | `Progression non disponible` |
| Projection académique enrichie **[DÉPENDANCE À ÉTUDIER, pas API créée]** | Élève/cycle et capacité du demandeur | Objectif confirmé, compétences avec états décidés, jalons/date/version, recommandation partageable, fraîcheur | Afficher seulement champs sûrs disponibles, aucun nouvel état calculé |
| `PortAssignations` existant | Classe/élève autorisés | Devoirs, échéances, statuts réels | Repli déjà prévu dans `TravailClassePage` |
| `PortResumeSeanceFamille` et politiques PED-APRÈS | Élève + séance + permission familiale | Texte partageable par séance et état de diffusion | Inaccessible/indisponible, **jamais cahier brut** |
| `PreparationSeance` / `ProjectionEleve` existants | Classe/enseignant autorisés | Support, reprise, objectif ; projection individuelle minimale | Ne pas inventer de données, conserver carte existante |
| `ServiceProgression` admin existant | Capacité admin effective | Liste de progression + exceptions/actions autorisées | Afficher erreur actionnable ; ne pas faire de join client inter-foyers |

**Interdiction :** aucun widget Flutter n'effectue lui-même une agrégation de `lesson_reports`, `progression_historique`, événements LiveKit, notes privées ou présence pour déclarer une compétence Stable, un niveau ou une note globale. Si la fonctionnalité exige une projection serveur absente, écrire `BLOQUÉ PAR CONTRAT`, porter le besoin au dossier d'intégration, **ne pas écrire le backend**.

### 9.2 Priorités de partage : pas de confusion avec PED-APRÈS

Une progression institutionnelle validée, un travail assigné et le résumé d'une séance ne sont pas le même objet ni automatiquement soumis aux mêmes règles de visibilité. Le domaine métier doit servir **une projection propre à chaque surface** et à son droit d'accès :

- La révocation d'un **compte rendu de séance** doit empêcher sa lecture dans l'Historique et tout raccourci qui reconstituerait ce compte rendu.
- Elle n'efface **pas** automatiquement un **niveau institutionnel déjà validé** ou un travail distinctement autorisé. **Inversement**, elle ne doit pas permettre d'exposer par la page Progression une note confidentielle ou une observation de séance révoquée.
- La présentation de données de compétence provenant d'une séance **non partageable** requiert une décision contractuelle explicite sur ce qui relève de la progression institutionnelle et ce qui relève de la note de séance. En l'absence de cette distinction : ne montrer que les valeurs académiques officielles déjà exposées.
- Les droits d'un élève adulte autonome ne sont pas une copie de ceux d'un parent : seul son contrat autorise ses lectures.

### 9.3 États synchronisés

1. **Chargement** par élève et par Classe : aucune projection d'un autre compte ne doit être conservée visuellement.
2. **Vidé / pas encore évalué** : neutre, non culpabilisant ; absence de donnée ≠ mauvais résultat.
3. **Erreur réseau** : action Réessayer du bon provider ; blocage local et retour permis.
4. **Hors ligne** : pas de projection sensible supposée encore autorisée ; respecter politique cache de l'application, sans créer de logique client d'autorisation.
5. **Refus de permission / suspension compte** : aucune donnée partielle affichée ; accès réduit selon garde existante.
6. **Correction K-45** : attendre confirmation du service de projection ; pas d'affichage anticipé de statut « Stable ».
7. **Changement de Classe/enseignant** : conserver l'histoire officiellement servie, mais supprimer les projections d'un roster auquel l'utilisateur n'a plus accès.
8. **Cas école réelle/démo** : la démonstration peut illustrer des fixtures **explicitement étiquetées** dans l'environnement autorisé ; production n'a jamais de repli silencieux sur des données fictives.

### 9.4 Exactitude, performance et scalabilité UI

- Agrégation, permissions, versionnement, tri des décisions et pagination globale relèvent du contrat existant ou d'un chantier ultérieur. Le widget ne télécharge pas la vie pédagogique entière pour un résumé.
- Une liste administrative volumineuse respecte pagination/virtualisation si le composant existant les supporte ; si le service actuel livre tout d'un coup, consigner le risque sans créer un serveur de remplacement côté Flutter.
- Ordre des jalons : respecter l'ordre servi **s'il est normatif** ; ne jamais trier un code académique comme une date. Si le serveur ne donne pas d'ordre sûr, garder l'ordre existant, remonter besoin de contrat.
- Dates dans le fuseau utilisateur, instants serveur autoritatifs ; format localisé FR/EN/AR via i18n existante.
- Pas de nouvelles valeurs HEX, typographiques, rayons, constantes de spacing, seuils métier, numéros de cursus ou horaires codés en dur.

---

## 10. Design system, accessibilité et rédaction UX

### 10.1 Invariants visuels

- **Titres français : DM Sans.** Texte latin courant, chiffres, horaires : **Plus Jakarta Sans**. Police arabe installée inchangée.
- **Tokens gelés** pour palette presque monochrome, accent lavande mesuré, light/dark, rayons, spacing et états. Pas de hardcoding de style dans les widgets métiers.
- **Carte regroupée = un seul rectangle** séparé par des filets internes ; éviter « cartes dans cartes » et multiples puces/badges décoratifs.
- Priorité visuelle : **niveau/objectif confirmé** > points à renforcer utiles > étapes franchies > explications secondaires. **Pas** de barre de progression fictive à 63 %.
- **Un titre, une tâche et une seule action dominante** par écran ; Progression est essentiellement une **lecture** et n'exige aucun grand bouton call-to-action.
- Tous les états light/dark ; largeur 320, 390, 768, 1024, 1440, 1920 selon composants adaptatifs ; texte ×2 ; souris, clavier, hover et focus ; sans mouvement obligatoire.

### 10.2 Sémantique

- Cibles interactives selon contrat design system, minimum pratique **48 dp** là où le standard du projet le requiert.
- Les pastilles `À renforcer`, `Acquis`, `Stable` restent **textuelles**, non différenciées par couleur seule. L'ordre Semantics lit : compétence → état → recommandation, pas d'icônes répétées sans sens.
- S'il existe une timeline de jalons, l'ordre de lecture doit être rigoureusement chronologique **sur décision officielle**, avec date annoncée si vraiment disponible. Sinon préférer une liste neutre.
- Raccourcis `Travail` et `Historique` disposent d'un intitulé accessible qui identifie l'élève/Classe sans révéler une donnée privée dans une alerte système.
- Aucune animation de célébration ne doit simuler une certification ou une réussite non décidée.

### 10.3 Lexique à imposer

| Utiliser | Éviter/interdire |
|---|---|
| `Progression`, `Niveau actuel`, `Objectif actuel`, `Étapes franchies`, `À renforcer`, `Acquis`, `Stable` | `Score pédagogique`, `classement`, `échec`, `mauvais élève`, `redoublement` |
| `Classe`, `Séance`, `Travail à préparer`, `Interface guidée` | `Groupe` comme titre public, `Session`, `mode enfant`, `matching` |
| `Sayyid` / `Sayyida` dans le contexte de cours | Variantes non validées au même emplacement |
| `Séance en direct` ou lexique existant de salle | `Cours en cours` (interdit) |
| `Progression non disponible` quand source absente | `Aucun progrès` si service manquant |

---

## 11. High-fi : **DEUX nécessaires, pas davantage par défaut**

### 11.1 Décision argumentée

La page tuteur `ProgressionClassePage` observée ne montre aujourd'hui que le niveau humain et les jalons. Les modifications envisagées introduisent **une nouvelle hiérarchie de lecture** (objectif courant, compétences **si réellement servies**, jalons, aide contextuelle). Cette structure n'est pas suffisamment couverte par les high-fi de **Classe Details**, Accueil ou Historique déjà validées. **Deux planches de progression sont justifiées pour éviter que Claude improvise la composition mobile/desktop.**

À l'inverse, **aucune nouvelle high-fi** pour Cahier K-45, Travail à préparer, pré-séance enseignant, Historique PED-APRÈS ou `ADM-11`, **sauf si l'audit compare des captures actuelles à un changement fonctionnel majeur non couvert**. Les trois planches déjà validées de PED-APRÈS **ne sont pas à recréer**.

### 11.2 Brief fermé des deux planches obligatoires

**`IMG-PED-PROG-01_tuteur_progression_mobile_sombre.png`**

- Format **390 × 844**, thème sombre existant, sans chrome décoratif autour de l'écran ni barre système inventée ; la vraie navigation tuteur reste `Accueil · Foyer · Historique · Compte`.
- Header `Progression` et retour vers la Classe, enfant et Classe via le composant réel.
- Un bloc hiérarchisé `Parcours actuel` : niveau humain **illustratif et marqué démonstration** dans le brief de production, objectif académique réel lorsqu'il existe ; aucune durée prévisionnelle.
- Un seul bloc `Compétences` avec maximum trois lignes d'exemple **visuellement simulées**, états textuels `À renforcer`, `Acquis`, `Stable`, séparateurs fins. **Ces libellés ne donnent aucune autorisation de création de données.**
- Un bloc `Étapes franchies` avec un ou deux jalons fictifs clairement identifiés **pour la maquette seulement** ; ne pas leur attribuer de certificat automatique.
- `Voir le travail à préparer` sous forme de raccourci secondaire vers la page canonique, si une source autorisée le permet.
- Prévoir le cas sous-ensemble niveau + jalons sans rendre de faux blocs Compétences/objectif.
- Contraste AA, CTA secondaire discret, typographie gelée, troncation interdite. **Rendu fidèle à la maquette de Classe existante**, pas nouvelle identité graphique.

**`IMG-PED-PROG-02_tuteur_progression_desktop_clair.png`**

- Format **1440 × 900** minimum, thème clair déjà validé, shell desktop réel et panneau latéral intact.
- Même identité et ordre de lecture que la planche mobile, avec largeur bornée ; colonne centrale principale (parcours/compétences), panneau contextuel droit (jalons/travail) **si utile**, pas de métriques fictives.
- Même niveau de détail de textes que la spec ; aucun chiffre d'assiduité, jauge de performance, tableau scolaire ou pourcentage décoratif.
- États `données partielles` et `source indisponible` décrits dans une annexe d'états à la spec ou par annotation, **pas besoin d'une troisième high-fi**.
- Conserver les composants existants et les vrais comportements web (clavier, hover, focus, clic).

**Validation des planches :** direction valide l'ordre, la hiérarchie, la densité, les groupements, la cohérence du mobile et du desktop avec les high-fi déjà approuvées. Les **valeurs illustratives doivent être remplacées en production par des valeurs autorisées**. La planche ne modifie jamais un contrat métier.

### 11.3 Conditions où une troisième planche serait nécessaire

Uniquement si l'audit du HEAD démontre une restructuration obligatoire non couverte de `ADM-11` ou du roster enseignant, Claude remonte un **écart démontré avec capture et chemin**, puis demande validation de la **seule** planche correspondante. Aucune série automatique clair/sombre de 12 images.

---

## 12. Exécution Claude : phases atomiques, avec garde anti-conflits

**T0 · Gel et inventaire (aucun code).** Relever branche/HEAD, `git status`, worktrees/agents actifs, PR F2, chemins réels, captures validées, états des providers et provenance des données. Produire la carte `écran → route → composant → provider → modèle → contrat → source → permission → test`. Pour chaque capacité choisir un état unique : `EXISTE ET FONCTIONNE`, `EXISTE MAIS NON ROUTÉ`, `EXISTE MAIS NON RACCORDÉ`, `ÉCART UX`, `ABSENT`, `NON VÉRIFIABLE`. Donner SHA/preuve, pas impressions.

**T1 · Revue produit/UX.** Comparer cinq sources : capture actuelle du HEAD, high-fi existantes de Classe/Historique, Bible V2, contrat métier, deux nouvelles high-fi une fois validées. Noter les écarts de contenu réel, ordre, navigation, style, a11y. Aucun changement si conforme ; ne jamais « améliorer » un écran sans défaut identifié.

**T2 · Famille, delta minimal.** Conserver `ProgressionClassePage`, `PortProgressionFamille`, `CadreClasse`, composants existants. Autoriser uniquement les sections dont les données sont garanties. Si le port réel reste indisponible, améliorer états de lecture et garder les capacités enrichies **BLOQUÉES PAR CONTRAT** ; pas de source brutale `lesson_reports`.

**T3 · Élève, delta uniquement si écart.** Vérifier l'`EspaceGroupePage` par rôle et âge, sa zone de progression, source et droits. Aucune nouvelle route si la zone actuelle suffit. Ne pas promettre de Hifz ou certificat automatique.

**T4 · Enseignant, contrôle de cohérence.** Vérifier `PreparationSeance`/`ProjectionEleve` et K-45, la reprise et la continuité réelle. Corriger seulement erreur de représentation ou navigation prouvée. Aucune nouvelle information dans la carte Préparation, aucun champ K-45.

**T5 · Administration, contrôle de cohérence.** Vérifier `ADM-11`, filtres et permissions réelles ; préserver `service_progression.dart` et sa frontière serveur. Toute incohérence entre action `promouvoir` et exigences de gate devient **dépendance PED-ÉVALUATIONS**, non correction RPC dans cette branche.

**T6 · Revue indépendante par discipline.** Faire contrôler le delta par : (a) UX/adaptive Flutter/Material 3, (b) design system et fidélité high-fi, (c) accessibilité WCAG, (d) pédagogie/métier, (e) protection des données et sources autorisées, (f) QA multi-rôles. Chaque revue produit **preuves, réserves et décision** ; pas de « 100 % validé » sans tests.

**T7 · Recette Flutter.** Tests de widget/navigation par action réellement touchée, tests des états, captures mobile/tablette/desktop, light/dark, liens, changement d'élève/foyer, erreur/hors-ligne, test non-régression K-45 et PED-APRÈS. `flutter analyze`, tests ciblés et build local si autorisés par l'environnement sans écraser worktree d'un autre agent.

**T8 · Handoff et clôture.** Fournir diff borné, captures avant/après, inventaire des tests et résultats réellement constatés, liste des capacités BLOQUÉES PAR CONTRAT, décisions pédagogiques à traiter dans PED-ÉVALUATIONS, revue des high-fi. **Aucun merge, déploiement, migration ni modification PROD sans ordre distinct.**

### Règles impératives d'intégration

- Si un autre agent a l'ownership du service/du fichier : **ne pas l'éditer**, ouvrir un point d'interface avec chemin et contrat précis.
- Fichiers de préférence à modifier : composants de présentation déjà cités et fichiers d'i18n propres à leur domaine ; en cas de besoin de modification de provider/route partagé, demander à l'intégrateur responsable, pas de second routeur.
- Toute proposition de nouveau modèle contient une source et une validation d'accès ; le frontend peut **décrire** un port future mais pas fabriquer la réponse métier.
- Jamais d'effacement d'un comportement existant utile, ni de suppression globale d'anciens composants sans preuve et approbation.

---

## 13. Recette fermée : 39 cas minimum

**Règle de preuve :** chaque cas reçoit `PASS` (preuve + environnement + SHA), `FAIL`, `BLOCKED` (contrat nommé), ou `NON TESTÉ`. Un état simulé n'est jamais déclaré « PASS réel ». Les tests de navigation partent d'une destination visible et cliquent/touchent le contrôle : un simple `router.go()` en test ne suffit pas.

| ID | Scénario vérifiable | Résultat attendu |
|---|---|---|
| R01 | Tuteur → ouvre Classe → touche `Progression` | Même page canonique, bon élève, route accessible |
| R02 | Retour depuis Progression | Retour à cette Classe, bon élève conservé |
| R03 | Élève réel avec `niveauHumain` seulement | Niveau visible, aucun jalon/objectif/compétence fictifs |
| R04 | Élève avec jalons validés | Texte humain, icônes accessibles, aucun certificat inventé |
| R05 | Élève sans niveau ni jalon | État neutre `Aucune progression…` |
| R06 | Provider `DB-CRS-11` indisponible | État explicite, aucun fallback `lesson_reports` |
| R07 | Erreur réseau | `Réessayer` recharge le bon provider, retour fonctionne |
| R08 | Texte agrandi ×2 à 320 dp | Aucun overflow, focus et retours visibles |
| R09 | 390 dp thème sombre | Regroupements, contrastes, navigation tuteur conformes |
| R10 | 768 dp thème clair | Adaptation fluide, pas de panneau compressé |
| R11 | 1440 × 900 desktop clair | Vraie composition bureau, pas mobile étiré |
| R12 | Desktop clavier / focus / Escape pertinent | Ordre prévisible et focus visible |
| R13 | Lecteur d'écran | En-têtes, statuts et liens compréhensibles |
| R14 | RTL/arabe/anglais | Direction et i18n robustes, pas de texte coupé |
| R15 | Réduction de mouvement | Aucun état dépendant d'une animation |
| R16 | Tuteur change d'enfant | Aucun flash ni donnée du précédent |
| R17 | Déconnexion/changement de foyer | Données mises hors affichage et accès vérifié |
| R18 | Accès tuteur A à élève B | Permission refusée, zéro donnée B |
| R19 | Élève transféré de Classe | Contexte courant cohérent ; historique seulement si autorisé |
| R20 | Résumé PED-APRÈS révoqué | Progression ne reconstitue pas la note confidentielle révoquée |
| R21 | Niveau officiel toujours autorisé après révocation d'un résumé | Niveau institutionnel ne disparaît pas arbitrairement si contrat séparé le garantit |
| R22 | « À renforcer » réellement validé | Texte exact, non culpabilisant ; aucune étiquette « échec » |
| R23 | « Acquis » réellement validé | Ne se transforme pas en « Stable » |
| R24 | « Stable » absent de la source | Aucune inférence locale depuis trois séances |
| R25 | Performance E1/E2/E3 dans cahier | Aucun score brut ni classement familial calculé |
| R26 | Travail marqué `fait` | Ne valide pas compétence, jalon ni niveau |
| R27 | Travail à préparer depuis Progression | Lien vers page existante, zéro duplication de liste |
| R28 | Historique → Détail → lien éventuel Progression | Même destination canonique, pas de second résumé |
| R29 | Enfant en Interface guidée | Cours dominant, textes courts, aucune note confidentielle |
| R30 | Enfant passe en UI standard | Aucun changement de permission/données académiques |
| R31 | Adulte autonome | Voit son état seulement, sans parent fictif |
| R32 | Enseignant prépare séance | Support + reprise + objectif, pas de second formulaire |
| R33 | Projection enseignant sans source | Aucune note individuelle inventée, état sûr |
| R34 | Enseignant dépose K-45 | Aucune nouvelle saisie ni validation fictive de progression |
| R35 | Cahier en file hors ligne | Aucune reprise confirmée avant accusé autoritatif |
| R36 | Admin ouvre `ADM-11` | Liste/filtre/colonnes/actions préservés |
| R37 | Admin ouvre élève sans niveau / sans Classe | `Niveau non déterminé` / `Sans Classe`, pas de disparition |
| R38 | Admin non habilité agit | Action absente ou refusée, sans escalade |
| R39 | Action admin échoue / conflit de version | État antérieur restauré, erreur et actualisation possibles |

**Cas complémentaires obligatoires si la projection enrichie est effectivement servie :** demi-données, objectif vide, jalons longs, liste de compétences longue/paginée, suspendre nouveau Hifz, réorientation, correction après K-45, changement de curriculum, continuité d'un enseignant remplaçant et état d'observation non partageable. Décrire le résultat observé, pas seulement « testé ».

---

## 14. Matrice de validation finale et limites documentées

| Revue indépendante | Question bloquante | Preuve attendue |
|---|---|---|
| **Produit** | Un seul écran source par fonction ? Aucune redéfinition de PED-APRÈS ? | Carte anti-doublon validée et chemins réels |
| **Pédagogie** | Le widget infère-t-il une maîtrise, un gate ou un certificat ? | Absence de calcul de passage dans la UI, cas R22–R26 |
| **UX/UI** | L'objectif apparaît-il avant les jalons secondaires sans surcharge ? | Captures conformes aux 2 nouvelles planches validées et high-fi existantes |
| **Accessibilité** | Enfant, mobile étroit, texte ×2, desktop et RTL utilisables ? | Tests et revue WCAG 2.2 AA documentés |
| **Confidentialité** | Des notes internes, autres élèves ou états révoqués passent-ils ? | Tests inter-comptes/deeplinks, contrats de source autorisés ; audit serveur requis séparément pour vérité réelle |
| **Technique** | Les changements restent-ils dans le frontend et respectent-ils les owners ? | Diff strict, HEAD, imports, tests et branches notés |
| **Recette** | Les parcours sont-ils vraiment touchables depuis leurs entrées ? | Captures, tests de tap/clic, résultats R01–R39 |

**Trois verrous à transmettre, sans les résoudre hors périmètre :**

1. **Source familiale réelle de progression :** `PortProgressionFamille` renvoie indisponible dans la branche examinée ; le statut de la PR F2 et du câblage doit être revérifié.
2. **Projection académique enrichie :** aucune preuve, dans le contrat actuel examiné, que l'objectif courant, les états par compétence, l'historique et les alertes pédagogiques autorisées sont exposés à la famille. Ne pas afficher les blocs comme réels tant que ce contrat ne les fournit pas.
3. **Gouvernance des transitions :** la distinction entre état « Stable », décision de passage de niveau, promotion administrative et certificat doit être vérifiée dans **PED-ÉVALUATIONS**. Ne pas reconcevoir le moteur académique dans ce chantier de présentation.

**Critère de sortie final :** le directeur reçoit une UI lisible, fidèle au design de Rewayah, honnête sur ses sources, sans duplication ni régression. Claude livre **un rapport de preuves**, pas une affirmation globale de complétude.

---

## Annexe A · Réserves et contradictions à ne pas trancher silencieusement

- **Référentiel vs capacités opérationnelles :** le référentiel académique V1 propose enfants 5/60 et adultes 6/90 ; `00_LIRE_D_ABORD.md` fixe des capacités par défaut opérationnelles 4 enfants/5 adultes. Cette verticale ne modifie **ni** la Classe ni sa capacité : données configurées de la Classe font foi à l'écran.
- **Progression institutionnelle vs observations familiales révoquées :** deux projections distinctes exigent une séparation effective des données. Toute frontière insuffisante reste **BLOQUÉE PAR CONTRAT**.
- **Gates et promotion administrative :** l'existence de l'action admin n'atteste pas la conformité au curriculum F1–I1. Transmettre ce risque au chantier PED-ÉVALUATIONS.
- **Référentiel académique non intégralement validé pour publication externe :** corpus précis Ṣalāh/invocations et mapping à l'édition Nour al-Bayân retenue ; ne pas inventer les textes/pages.
- **Dates et hiérarchie des documents :** le présent fichier n'annule aucune décision plus récente, ni contrat autoritatif appliqué au service ; toute divergence doit être consignée avec source et arbitrage.

## Annexe B · Texte de handoff Claude Code

> **Mission : PED-PROGRESSION, frontend only.** Lis la spécification `REWAYAH_PED_PROGRESSION_SPEC_VERTICALE_V1_2026-10-11.md`, la Bible frontend V2, les maquettes déjà validées et le PED-APRÈS du 11/10. Commence par l'étape T0 sans écrire de code ; retrouve le HEAD réel et les agents actifs, et compare le code aux preuves listées. Préserve entièrement K-45, les routes et fonctions existantes. Ne crée aucun dashboard, formulaire, service ou rôle supplémentaire. Un port non raccordé doit produire un état indisponible, jamais des données déduites d'un cahier brut. Les deux nouvelles high-fi ciblent seulement l'écran Progression mobile et desktop et exigent validation visuelle avant modification de layout. Après audit, propose le diff minimal, puis implémente seulement les écarts frontend autorisés, avec revue UX/accessibilité/pédagogie/confidentialité et recette R01–R39. Ne touche ni SQL/Supabase, ni LiveKit, ni fusion, ni déploiement. Arrête-toi pour arbitrage si une permission, une nouvelle route ou un nouveau contrat serveur est indispensable. Termine par preuves et liste de dépendances, pas par une promesse de fonctionnement intégral.

## Annexe C · Document source et niveau de preuve

- `REWAYAH_PED_APRES_SPEC_VERTICALE_V1_2026-10-11.md` : spécification du partage après séance, version 1.0, **implémentation non confirmée**.
- `REWAYAH_REFERENTIEL_ACADEMIQUE_V1(1).docx` : doctrine de compétence, stabilité, progression cohorte, travail, évaluation humaine, charge de l'enseignant et calendrier.
- `REWAYAH_TEACHING_CORE_MULTI_AGENTS_V1(2).docx` : Groupe permanent, préparation de séance, outils et séparation des projections.
- `REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md`, `03_DESIGN_SYSTEM_ET_UX.md` : design tokens, composition adaptive, accessibilité et états.
- GitHub, branche `ccr-1b1bfa0b-m1kvkk`, fichiers énumérés dans §0.3 : **inspection ciblée**, non une validation intégrale du dépôt.
- GitHub PR #21 : `https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/pull/21` ; au contrôle réalisé dans le cadre de cette rédaction : **draft, ouverte, non fusionnée, mergeable=false**.
