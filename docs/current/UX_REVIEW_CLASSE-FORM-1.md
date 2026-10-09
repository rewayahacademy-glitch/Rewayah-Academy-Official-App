# UX_REVIEW_CLASSE-FORM-1 : formulaire « Nouvelle classe » semi-automatique (09/10/2026)

- **Demande** : directeur, lot CLASSE-FORM-1 : un formulaire de création de classe
  semi-automatique et complet. Le genre de la classe est obligatoire. L'enseignant le plus
  adapté est proposé d'après ses créneaux libres et le genre de la classe. Le mot « groupe »
  disparaît des textes visibles.
- **Décisions** : les dix décisions D1 à D10 ont été **décidées par délégation le 09/10**
  (K-65 ; aucune question n'a été posée au directeur). Elles sont recopiées plus bas, avec
  leur raison.
- **Cadre** : DESIGN-GOV-2026-09-26 §4.2.
- **Sources** : les référentiels de la liste §4.1, tels que les revues précédentes du dépôt
  les ont relevés (`UX_REVIEW_DISPO-1.md`, `UX_REVIEW_AD-X.md`). **Aucune navigation web
  dans cette session le 09/10** : aucune source n'a été reconsultée ce jour. GOV.UK est
  exclu.
- **Limite §4.3** :
  - aucun état serveur ne change ;
  - rien sous `supabase/`, ni dans `service_groupes.dart`, `*_supabase.dart` ou
    `lib/core/domain/**` ;
  - le genre et le fuseau ne partent pas au serveur tant qu'il ne les accepte pas (D1). La
    section « Lignes serveur à ouvrir » le détaille.
- **Statut** : le code existe et il est testé localement. Il n'est ni sur staging, ni
  déployé, et aucune capture n'a été prise (`CAPTURE_DIR` n'a pas tourné dans ce lot).

| Proposition | Source | Règle utile | Conclusion | Modification | Dérogation |
|---|---|---|---|---|---|
| Une phrase de contexte ouvre la feuille, puis la légende de la marque d'obligation | K-58 ; Nielsen n°1 (visibilité de l'état) ; Baymard (signaler les champs obligatoires) | L'écran commence par dire à quoi il sert, et ce qui est requis se voit avant l'envoi | Conforme | `admin.groupes.formulaire.contexte` ; légende `formulaire.legendeObligatoire` ; le point fixe de `PointRappel` devant chaque titre, que le lecteur d'écran annonce « Champ obligatoire » | Les six champs sont tous obligatoires : la marque est répétée sur chacun plutôt qu'une seule phrase « tout est obligatoire », pour que l'œil la retrouve au moment de la décision |
| Ordre des champs : Public, Genre, Enseignant, Créneau, Seuil, Nom | K-57 (déduit > choisi > saisi) ; Hick | Ce qui filtre vient avant ce qui est filtré | Conforme | Le public et le genre classent la liste des enseignants. L'enseignant met ses créneaux libres en avant. Le public préremplit le seuil. Tout le reste préremplit le nom | Aucune |
| Public en deux cartes | K-58 ; `lib/CLAUDE.md` (tout choix passe par `ChoiceCardGroup`) | Chaque option dit quand la choisir et ce qu'elle change | Conforme | Enfants : « À choisir pour une classe d'enfants. Seuil proposé : 5 élèves. » Adultes : « … Seuil proposé : 6 élèves. » | Pas de carte « Autre » : le domaine SQL n'a que deux valeurs (`type_public`) |
| Genre en trois cartes, aucune présélection | Demande du directeur ; K-58 ; Nielsen n°5 (prévention des erreurs) | Une valeur sensible n'est jamais choisie à la place de l'admin | Conforme | Libellés accordés au public : Garçons / Filles chez les enfants, Hommes / Femmes chez les adultes, et Non déterminé. Chaque carte dit qui pourra prendre la classe | Cartes en liste et non côte à côte (`coteACote`) : à 320 px, trois colonnes de 90 px ne tiennent pas une phrase de conséquence. Pas de carte « Autre » (D2 : trois valeurs fermées) |
| Ligne honnête sous le genre (D1) | §1 (aucune donnée inventée) ; D5 (« non confirmé », jamais un faux succès) | Ne pas laisser croire qu'une valeur est enregistrée | Conforme | Rendue seulement quand l'adaptateur ne retient pas le genre (`PortCreationClasse.retientGenre` faux, c'est le cas de l'adaptateur réel) : « Le genre guide le choix de l'enseignant. Il sera enregistré avec la classe dès que le serveur l'acceptera : pour l'instant, il ne l'est pas. » | Aucune |
| Enseignant : liste classée, « le plus adapté » en tête avec sa raison | K-57 (meilleure option justifiée) ; K-58 ; Nielsen n°6 | Proposer, puis dire pourquoi | Conforme | `SelecteurPersonne` étendu (`mention`, `raisonIndisponible`, `obligatoire`, `aide`), sans composant nouveau. Ordre décrit par une phrase. Mention « Le plus adapté : libre à ce créneau, 2 classes en cours. » ou, sans créneau, « Le plus adapté : 3 créneaux libres, 1 classe en cours. » | Sans disponibilités rendues par la source (adaptateur réel, repli), personne n'est « le plus adapté » : la mention ne s'invente pas |
| Enseignant incompatible ou déjà en classe au créneau : visible, non choisissable, avec sa raison (D4) | K-58 ; `OptionChoix.disponible` (K3, option visible mais indisponible) | Jamais masqué en silence | Conforme | « Classe de filles : seule une enseignante peut la prendre. » ; « Déjà en classe à ce créneau : changez de créneau pour le choisir. » Un enseignant seulement « pas libre d'après ses disponibilités » reste choisissable, avec la mention « Pas libre à ce créneau d'après ses disponibilités. » | L'admin peut savoir mieux que la source : seul un conflit certain (genre, collision avec une classe active) bloque |
| Créneau : jours en puces, heures dans une liste, créneaux libres en tête (D6) | K-57 ; `UX_REVIEW_DISPO-1.md` (la grille jugée trop compliquée) ; Hick | Choisi, jamais tapé | Conforme | `FilterPill` pour les 7 jours ; `MenuFiltre<int>` de 6 h à 21 h (bornes de `GrilleSemaine`) ; enseignant choisi : « Créneaux libres de … » en puces, chacune règle le jour et l'heure. Sans disponibilités lisibles, une phrase le dit | Aucune |
| Fuseau déduit, affiché, jamais saisi (D6) | §1 ; Nielsen n°1 | Dire dans quel fuseau l'heure se lit | Conforme | Adaptateur qui transmet le fuseau : celui de l'enseignant, sinon celui par défaut. Adaptateur réel (qui ne le transmet pas) : « Heures lues dans le fuseau Europe/Paris, celui que le serveur retient pour l'instant… » (`coalesce(p_timezone_iana, 'Europe/Paris')`, `0033`) | Aucune |
| Seuil : `SelecteurEntier` 1 à 6, présélection 5 ou 6 (D7) | K-57 ; contrainte SQL `seuil_max between 1 and 6` (`0017:28`), défauts `0033` | Proposer tout le domaine, présélectionner le défaut du serveur | Conforme | La présélection suit le public tant que l'admin n'a pas choisi lui-même. Pas de saisie libre : 1 à 6 couvre tout | Aucune |
| Nom déduit, modifiable : le seul champ saisi (D8) | K-57 (justifier chaque « saisi ») | Préremplir ce qui se déduit | Ajusté | `ChampEtiquete` (marque obligatoire ajoutée au composant). « Filles, mardi 17 h ». Il cesse de suivre les choix dès que l'admin l'écrit, et les suit de nouveau s'il le vide | **Justification du champ saisi** : un nom de classe est un nom propre (« Classe An-Nour ») que rien dans les données ne permet de déduire ; la proposition suffit pour créer, l'écriture reste possible |
| Bouton « Créer la classe » toujours actif ; le premier manque se dit (K-56) | K-56 ; K-59 ; Nielsen n°9 | Un bouton qui ne peut pas aboutir n'est pas grisé | Conforme | Ordre du message : genre, enseignant, créneau, enseignant non choisissable, seuil, nom. Bouton au bord de fin (`AlignmentDirectional.centerEnd`), pleine largeur sauf sur bureau (contrat B) | Aucune |
| Échec de création | K-59 ; D5 | Dire quoi, la cause, quoi faire | Ajusté | `creerErreur` (« La création n'a pas abouti : {message} ») à l'encre `inkAlert`, lu dès qu'il paraît. La feuille garde tous les choix ; presser de nouveau renvoie les mêmes valeurs | Texte `creerErreur` inchangé (socle), à reprendre si la règle `erreur-sans-action` le vise |
| Hors ligne | `lib/CLAUDE.md` (bouton qui ne peut pas aboutir non rendu) ; `03_DESIGN_SYSTEM_ET_UX.md:26-31` | Le dire une fois, ne pas griser | Conforme | Le bouton n'est pas rendu : « Sans réseau, la classe ne peut pas être créée. Vos choix restent affichés : revenez quand la connexion est rétablie. » Même règle dans « Seuil maximal » | Aucune |
| « Seuil maximal » (modification) : même sélecteur, bouton jamais grisé (D7, K-56) | K-56 ; recensement FORM-AUTO-1 A3 | Même geste à la création et à la modification | Conforme | `TextField` et `onPress: … ? null :` retirés. Une valeur ancienne hors 1..6 n'est pas retenue en silence : presser dit « Il manque le seuil maximal… » | Aucune |
| Textes qui ne coupent aucun mot (320 px, texte ×2) | COUPE-MOTS-1 ; WCAG 1.4.4 | Aucun mot coupé | Ajusté | Titre, contexte et aide de `SelecteurPersonne`, raison d'indisponibilité de `ChoiceCardGroup` : passés en `TexteSansCoupure` | L'indication du champ de recherche de `SelecteurPersonne` (FORM-L2, `hintText`) est hors de ce lot : la garde l'exclut, avec sa raison écrite |

## Fiche d'écran ADM-09 « Nouvelle classe » (feuille de création)

Le dépôt n'a pas de catalogue d'écrans dans `docs/current/` : la fiche tient ici, au format
de la fiche archivée (`docs/archive/2026-09-pre-remise-a-plat/design/08-catalogue-ecrans.md`).

- **Rôle** : direction (admin). **Zone** : Opérations > Classes. **Écran parent** : ADM-09
  (`/admin/operations/groupes`, `GroupesPage`). **Profondeur** : feuille (`AppBottomSheet`).
- **Question de l'écran** : « Quelle classe ouvrir, avec qui, et quand ? »
- **Action principale** : « Créer la classe » (seul bouton plein de la feuille). **Actions
  secondaires** : toucher un créneau libre, une carte, une puce. **Destructif** : aucun.
- **Fichiers** :
  - `lib/features/admin_groupes/groupes_page.dart` (`_FeuilleCreation`, `_FeuilleSeuil`,
    `_BasDeFeuille`) ;
  - classement pur et repli : `lib/core/admin/enseignants_classe.dart` ;
  - ports : `lib/core/capacites/port_enseignants_classe.dart` et
    `lib/core/capacites/port_creation_classe.dart` ;
  - démonstration : `lib/features/demo/classe_form_demo.dart`, branché dans
    `mode_demonstration.dart`.
- **États** :
  - **chargement** : `Skeleton.liste` du `BlocAsynchrone` de `SelecteurPersonne` tant que
    la liste n'est pas lue ;
  - **contenu** : les six champs ;
  - **vide** : « Aucun compte enseignant actif » et quoi faire (FORM-L2, inchangé) ;
  - **erreur de lecture** : `EtatSysteme` « La liste des enseignants n'a pas pu être lue »,
    la cause probable et Réessayer, qui relit la source dédiée et les comptes ;
  - **erreur d'envoi** : `creerErreur`, la feuille reste ouverte avec les choix ;
  - **hors ligne** : bouton non rendu, une phrase le dit, les choix restent ; la page porte
    le bandeau `PageShell` une fois.
- **Mobile / tablette / bureau** : une colonne. Bouton pleine largeur sur téléphone et
  tablette, largeur du contenu au bord de fin sur bureau.
- **Accessibilité** : marque d'obligation lue (« Champ obligatoire » ; « Nom de la classe,
  champ obligatoire ») ; messages en `liveRegion` ; cartes entièrement cliquables (K-58) ;
  option indisponible lue avec sa raison.

### Champs (K-57 : déduit > choisi > saisi)

| # | Champ | Source de la valeur | Classement | Valeur de départ | Envoyé |
|---|---|---|---|---|---|
| 1 | Public | choix de l'admin, deux cartes | choisi | Enfants (valeur précédente du formulaire) | `type` |
| 2 | Genre de la classe | choix de l'admin, trois cartes | choisi, obligatoire | aucune (D1) | au port (`genre`) ; l'adaptateur réel ne le transmet pas (D1) |
| 3 | Enseignant | source dédiée `PortEnseignantsClasse`, sinon repli sur les comptes actifs ; classement pur `classerEnseignants` | déduit (ordre, mention) puis choisi | aucun | `teacherId` |
| 4 | Créneau (jour, heure) | créneaux libres de l'enseignant, sinon grille 6 h - 21 h | déduit (créneaux libres en tête) puis choisi | aucun | `creneau.jour`, `creneau.heure` |
| 4 bis | Fuseau | enseignant, sinon défaut serveur | déduit, affiché, non saisi | `Europe/Paris` tant que l'adaptateur ne transmet pas le fuseau | `creneau.fuseau` (non transmis par l'adaptateur réel) |
| 5 | Seuil maximal | défaut du serveur selon le public (5 ou 6, `0033`) | déduit puis choisi (1..6) | 5 | `seuilMax` |
| 6 | Nom de la classe | genre (ou public), puis créneau | déduit, modifiable : **seul champ saisi** | « Enfants », puis « Filles, mardi 17 h » | `libelle` |

**Justification du seul champ saisi** : l'admin peut vouloir un nom propre (« Classe
An-Nour »), qu'aucune donnée ne contient. La proposition déduite suffit pour créer sans
rien taper.

### Options et leur conséquence (K-58)

- **Enfants** : « À choisir pour une classe d'enfants. Seuil proposé : 5 élèves. »
- **Adultes** : « À choisir pour une classe d'adultes. Seuil proposé : 6 élèves. »
- **Hommes / Garçons** : « À choisir pour une classe d'hommes (de garçons) : seuls les
  enseignants hommes pourront la prendre. »
- **Femmes / Filles** : « À choisir pour une classe de femmes (de filles) : seules les
  enseignantes pourront la prendre. »
- **Non déterminé** : « À choisir quand le genre n'est pas encore connu : tous les
  enseignants pourront la prendre. »
- **Enseignant** : la mention « Le plus adapté : … » dit pourquoi. La raison
  d'indisponibilité dit pourquoi il ne se choisit pas et quoi faire.
- **Créneau libre** : la phrase « Créneaux libres de … : toucher un créneau règle le jour
  et l'heure. »
- **Seuil** : « Au-delà de ce nombre d'élèves, la classe est complète. Proposé : 5 pour des
  enfants, 6 pour des adultes ; 6 au plus. »

## Décisions D1 à D10 (décidées par délégation le 09/10)

- **D1. Création tant que le serveur ne stocke pas le genre.**
  - Un nouveau port `PortCreationClasse`. L'adaptateur réel délègue à `ServiceGroupes.creer`,
    avec les champs que la RPC accepte.
  - Le genre est exigé à l'écran. Une ligne honnête dit qu'il sera enregistré quand le
    serveur l'acceptera.
  - L'adaptateur de démonstration retient tout, genre compris.
  - Raison : ne pas bloquer l'admin, et ne rien prétendre.
- **D2. Compatibilité de genre.** Une classe d'hommes va à un enseignant, une classe de
  femmes à une enseignante, un genre non déterminé à tous. Raison : cohérent avec la
  décision du 02/10 sur REMPL-1, c'est le choix le plus prudent.
- **D3. Genre de l'enseignant.**
  - Jamais `profiles.gender`, réservé au KYC.
  - Source proposée : `teacher_profiles.titre` (sayyid / sayyida), déjà public.
  - Si le genre est inconnu, `genreCompatible` vaut nul : aucune mention, et l'enseignant
    reste proposable.
- **D4. Incompatible ou occupé.** L'enseignant reste visible, avec sa raison. Il est non
  choisissable (genre, collision) ou seulement marqué (pas libre d'après ses
  disponibilités). Jamais masqué en silence.
- **D5. « Le plus adapté ».**
  - Le premier enseignant de genre compatible ou inconnu, libre au créneau ; puis le moins
    chargé.
  - Sans créneau choisi : libre à au moins un créneau.
  - Mention courte avec sa raison.
- **D6. Créneau.**
  - Il se choisit, il ne se tape jamais : jours en puces, heures en liste.
  - Les créneaux libres de l'enseignant passent d'abord ; à défaut, la grille 6 h - 21 h.
  - Le fuseau est déduit et affiché.
- **D7. Seuil.** Choisi dans 1..6, avec une présélection à 5 (enfants) ou 6 (adultes). La
  feuille de modification utilise le même sélecteur, et son bouton n'est plus grisé.
- **D8. Nom.** Déduit, modifiable. C'est le seul champ saisi, justifié plus haut.
- **D9. Hors lot.** Restent des lignes Contrats « à venir », sans champ à l'écran : durée,
  date de début, langue, niveau, plusieurs séances par semaine, couleur (déduite par le
  serveur), contrôle de collision côté serveur.
- **D10. Vocabulaire.** Seules les valeurs visibles changent. Fait au commit `c89bb655`.

## Écarts voulus

1. **Genre non transmis par l'adaptateur réel (D1).** L'écran l'exige, le dit, et ne
   simule rien.
2. **Fuseau non transmis par l'adaptateur réel.**
   - L'écran affiche le fuseau que le serveur retient (`Europe/Paris`), et non celui de
     l'enseignant : afficher un autre fuseau serait faux.
   - Les créneaux sont comparés à l'heure près, fuseau ignoré (`memeHeure`) : la source
     rend tous les créneaux d'un enseignant dans son fuseau.
3. **Repli de la liste des enseignants.**
   - Tant que `enseignants_pour_classe` n'existe pas, la liste vient des comptes actifs
     (FORM-L2), avec la charge et les créneaux pris lus dans les classes déjà chargées.
   - Ni genre ni disponibilités : aucune mention « le plus adapté » en production avant la
     ligne serveur. Seule la collision avec une classe active est signalée.
4. **Cartes du genre et du public en liste**, et non côte à côte : à 320 px, les phrases de
   conséquence ne tiennent pas en trois colonnes.
5. **Garde de rendu à 320 × 2400 pour le texte ×2.**
   - La **page** Classes, derrière la feuille, déborde de 14 px à 320 × 1400 en texte ×2.
   - Mesuré aussi à la base `5336598a`, page seule, sans la feuille : l'écart existait déjà.
   - La feuille elle-même défile.
   - Correction hors de ce lot.
6. **Indication du champ de recherche de `SelecteurPersonne`** (FORM-L2) : exclue de la
   garde des mots coupés, avec sa raison. Ce composant FORM-L2 n'a pas changé sur ce
   point.

## Inventaire

**Créés**
- `lib/core/capacites/port_enseignants_classe.dart` : `GenreClasse`, `GenreEnseignant`,
  `EnseignantPropose`, `PortEnseignantsClasse`, `EnseignantsClasseIndisponible`
  (`DB-CLASSE-FORM-1`), provider.
- `lib/core/capacites/port_creation_classe.dart` : `PortCreationClasse`,
  `CreationClasseParServiceGroupes`, `fuseauServeurParDefaut`, provider.
- `lib/core/admin/enseignants_classe.dart` : `genreCompatible`, `classerEnseignants`,
  `enseignantsDepuisComptes`, `enseignantsDuPortProvider`, `enseignantsPourClasseProvider`.
- `lib/features/demo/classe_form_demo.dart` : `ClassesCreeesDemo`,
  `EnseignantsClasseDemo` (quatre enseignants, dont un de genre inconnu),
  `CreationClasseDemo`.
- `test/features/classe_form_1_test.dart`.

**Modifiés**
- `groupes_page.dart` : création et seuil.
- `selecteur_personne.dart` : `mention`, `raisonIndisponible`, `obligatoire`, `aide`, et
  `TexteSansCoupure`.
- `champ_etiquete.dart` : `obligatoire`.
- `choice_card_group.dart` : raison d'indisponibilité en `TexteSansCoupure`.
- `catalogue_galerie.dart` : état « mention, indisponible, obligatoire ».
- `mode_demonstration.dart` et `admin_x_demo.dart` : en `?demo=admin`, la création aboutit
  et la classe paraît dans la liste.
- `assets/i18n/fr.i18n.json` : 55 nouvelles clés (58 chaînes).
  - 52 sous `admin.groupes.formulaire`, dont 3 pluriels (`one` et `other`).
  - 3 sous `formulaire`.
  - `ar.i18n.json` n'est pas touché.
- `tool/libelles_sources.json` : 45 clés déclarées. Ce sont celles que la règle
  `libelle-sans-source` signalait ; les autres se lisent déjà dans `docs/`.
- `test/features/support_form_l2.dart` et `test/features/form_l2_selecteur_personne_test.dart`.

**Clés laissées sans lecteur** : `admin.groupes.champJour`, `champHeure`, `champSeuil`,
`champType`, `manqueNom`. Elles sont conservées pour ne rien casser hors du lot ; à
supprimer dans une passe i18n.

## Contre-épreuve (K-66.2)

Chaque défaut a été remis à la main, la suite jouée, puis le code restauré (`cp` de la
sauvegarde, `cmp` identique).

| Défaut remis | Commande | Résultat |
|---|---|---|
| Genre non exigé : ligne `if (_genre == null) return f.manqueGenre;` retirée de `_manque` | `flutter test test/features/classe_form_1_test.dart test/features/form_l2_selecteur_personne_test.dart` | +33 -1 : échoue « genre obligatoire : presser sans genre le dit, rien ne part » |
| « Le plus adapté » sans exiger « libre » | `flutter test test/features/classe_form_1_test.dart` | +23 -1 : échoue « collision : … aucune mention inventée » |
| Classement sans priorité aux choisissables | `flutter test test/features/classe_form_1_test.dart` | +21 -3 : échouent « classe de femmes », « classe d'hommes », « collision » |
| Après restauration | `flutter test test/features/classe_form_1_test.dart` | +24, All tests passed |

## Lignes serveur à ouvrir (feuille de liaison, onglets Backend et Contrats)

À copier telles quelles. Zone ChatGPT : rien de cela n'a été écrit par ce lot.

| Réf. | Onglet | Besoin | Aujourd'hui | Côté client, prêt |
|---|---|---|---|---|
| CF1-B1 | Backend | **Colonne `genre_public`** sur `public.groupes` : enum `hommes`, `femmes`, `indetermine` (nouveau type ; `public.gender` n'a pas de troisième valeur). Paramètre `p_genre_public` sur `creer_groupe` et `modifier_groupe`. Colonne rendue par `groupes_admin()` | absente (`0017:22-43`) | `GenreClasse`, `PortCreationClasse.creer(genre:)` |
| CF1-B2 | Backend | **RPC `enseignants_pour_classe(p_genre_public, p_type_public, p_weekday default null, p_hour_local default null, p_timezone_iana)`**, admin seulement, `SECURITY DEFINER` et `search_path = ''`. Rend `teacher_id`, `first_name`, `last_name`, `immutable_id`, `country`, `genre` (dérivé du titre public, voir CF1-B3), `timezone_iana`, `classes_actives`, `creneaux_pris jsonb`, `creneaux_libres jsonb` (= `weekly_availability` − affectations actives − créneaux des classes actives, `groupe_creneaux` compris) | absente ; aujourd'hui une lecture `disponibilites` par profil, accès admin non vérifié | `PortEnseignantsClasse.pourClasse`, `EnseignantPropose` |
| CF1-B3 | Contrats | **Genre de l'enseignant exposé via son titre public** (`teacher_profiles.titre` : sayyid → homme, sayyida → femme, nul → inconnu). **Jamais `profiles.gender`**, réservé au cloisonnement KYC (`0004:26`, `enums.dart` `Genre`) | non exposé | `GenreEnseignant` nullable, D3 |
| CF1-B4 | Backend | **Transmettre `p_timezone_iana` et `p_couleur_jeton`** dans `ServiceGroupesSupabase.creer` (`service_groupes.dart:253-269`). La RPC les accepte déjà (`0033:571-572`). Couleur déduite côté serveur ou par une règle écrite (D9) | non transmis : le fuseau vaut `Europe/Paris` côté serveur | `PortCreationClasse.retientFuseau` passera à vrai |
| CF1-B5 | Backend | **Relire `timezone_iana`** dans `GroupeAdmin.depuisJson` (`service_groupes.dart:69`) au lieu de `'Europe/Paris'` codé en dur ; `groupes_admin()` doit le rendre | codé en dur | aucun changement d'écran |
| CF1-B6 | Backend | **Contrôle de collision** dans `creer_groupe` et `modifier_groupe` : refuser une classe d'un enseignant déjà en classe active au même `weekday`, `hour_local` et fuseau, avec un message métier lisible | absent (`0033:564-630`) | le client signale déjà la collision qu'il voit (D4) ; l'échec serveur s'afficherait par `creerErreur` |
| CF1-C1 | Contrats | **Champs à venir (D9)**, sans champ à l'écran : durée de séance, date de début, langue, niveau ou programme, plusieurs séances par semaine, couleur | absents ou non pris par `creer_groupe` | aucun |
| CF1-C2 | Contrats | **Nouveaux ports** `port_enseignants_classe.dart` et `port_creation_classe.dart`, contrat commun (`COHABITATION.md:36-39`), à faire valider | créés par ce lot | adaptateurs par défaut : indisponible + repli, délégation à `ServiceGroupes` |

## Mineurs FORM-AUTO-1 reportés

Relevé du recensement FORM-AUTO-1 (`origin/pilotage/tuteur-v1:05_recette/FORM-AUTO-1/RECENSEMENT.md`),
lignes recalées sur la branche courante. Recopié tel quel, puis l'état après ce lot.


**(1) `_FeuilleMotif` de Programmes.** Ce motif est obligatoire pour supprimer un niveau ou publier une version. Le recensement ne le compte pas (absent de A7 et de L1), et `docs/current/FORM-L1-7-13_MOTIFS.md` n'en parle pas non plus.
- Ouvertures : `lib/features/admin_pedagogie_programmes/programmes_page.dart:514` (supprimer un niveau, `_ouvrirSupprimerNiveau` à :505) et `:540` (publier une version, `_ouvrirPublication` à :528).
- Classe : `:858` (état à `:877`).
- Champ libre `TextField` : `:918`.
- Bouton grisé tant que le motif est vide, contraire à K-56 : `:935` (`onPress: _motif.text.trim().isEmpty ? null : _envoyer`).
- La feuille du même nom dans Classes a déjà migré : `groupes_page.dart:1112`, `SelecteurMotif` à `:1181`.
- À ajouter à L1 : 2 champs de plus, donc 15 champs motif au lieu de 13.

**(2) Fuseau `'Europe/Paris'` codé en dur.**
- **Création de classe** : `lib/features/admin_groupes/groupes_page.dart:752` (et non plus :421). Cette valeur n'est de toute façon **jamais envoyée** au serveur :
  - `ServiceGroupesSupabase.creer` (`lib/core/admin/service_groupes.dart:253-269`) ne transmet pas de fuseau ;
  - la RPC accepte pourtant `p_timezone_iana` (`supabase/migrations/0033_tc_vues_rpc.sql:571`) ;
  - côté serveur, l'absence vaut `coalesce(p_timezone_iana, 'Europe/Paris')` (même fichier, vers :621).
  - Corriger le fuseau demande donc un ajout au port (paramètre fuseau sur `creer`). C'est une ligne Backend/Contrats, car `service_groupes.dart` est en zone ChatGPT.
- **Lecture d'une classe** : `lib/core/admin/service_groupes.dart:69`. Le créneau lu est forcé à `'Europe/Paris'` au lieu de lire `timezone_iana` dans `groupes_admin()`. Également en zone ChatGPT.
- **Valeurs de repli** (quand la donnée manque) :
  - `lib/core/planning/service_planning.dart:30` et `:293`
  - `lib/core/enseignant/modeles_enseignant.dart:235`
  - `lib/core/priere/reglages_priere.dart:23` et `:50`
  - `lib/features/disponibilites/disponibilites_page.dart:53`
  - `lib/features/parcours_offres/parcours_offres_page.dart:97`
- **Normal**, aucune correction à faire :
  - listes de pays : `profil_enseignant/declaration_choix.dart:41-43`, `parcours_offres/libelles_parcours.dart:118` ;
  - données de démonstration et de dev : `features/demo/*`, `_dev/*`, `core/tc_horloge/demonstration_horloge.dart`, `mode_demonstration.dart:161`.

**(3) Routes admin.**
- Les chemins sont des constantes dans `lib/core/router/routes.dart`, et les routes elles-mêmes (`GoRoute`) sont déclarées dans `lib/core/router/app_router.dart`.
- Le recensement disait « route non retrouvée » pour attribution, évaluations, progression, diagnostics, accès agents, conservation et fonctionnalités. Toutes existent :

| Écran | Chemin | `routes.dart` | `app_router.dart` |
|---|---|---|---|
| classes | `/admin/operations/groupes` | :434 | :968 |
| traitement | | :440 | :961 |
| attributions | | :444 | :975 |
| demandes | | :447 | :985 |
| dossiers | | :453 | :997 |
| comptes | | :456 | :1017 |
| diagnostics | | :468 | :1037 |
| progression | | :472 | :1044 |
| évaluations | | :476 | :1051 |
| programmes | | :479 | :1058 |
| qualité | | :482 | :1065 |
| règles | | :490 | :1081 |
| fonctionnalités | | :494 | :1088 |
| conservation des données | | :498 | :1095 |
| politique de revue KYC | | :503 | :1104 |
| journal | | :510 | :1116 |
| accès agents | | :514 | :1124 |
| observations | | :519 | :1133 |

- Le chemin de Classes dit encore « groupes » : il reste à renommer, ou à garder comme identifiant technique, au choix de CLASSE-FORM-1.


**État après CLASSE-FORM-1**
- **(1) `_FeuilleMotif` de Programmes** : non traité, hors du périmètre de ce lot. Reste
  rattaché à L1.
- **(2) Fuseau de la création** : la ligne `'Europe/Paris'` codée en dur dans
  `groupes_page.dart` a disparu. Le fuseau est déduit et affiché. Sa transmission attend
  CF1-B4, et sa relecture CF1-B5.
- **(3) Routes** : `/admin/operations/groupes` est gardée comme identifiant technique
  invisible (D10).
- **A3 (seuil, bouton grisé)** : traité (D7).

## Vérifications jouées (09/10, après le commit `487005f0`)

| Commande | Résultat |
|---|---|
| `dart run slang` | réussi |
| `dart analyze --fatal-infos` | No issues found! |
| `flutter test test/features/classe_form_1_test.dart` | +24, All tests passed |
| `flutter test test/widgets` | +298, All tests passed |
| `flutter test` (suite complète) | +6908 ~3642, All tests passed |
| `dart run tool/verifier_revue.dart` | 1420 violations, code 1 : le même total qu'à la base `c89bb655` (libelle-sans-source 1356, bouton-grise 34, plein-multiple 17, affirmation-reseau 5, avatar-taille 4, avatar-recompose 3, bouton-recompose 1) ; `--regle=mot-interne` : aucune violation |
| `dart run tool/verifier_jetons.dart` | 31 violations, code 1 : sortie identique à celle d'avant le lot (`diff` vide) |
