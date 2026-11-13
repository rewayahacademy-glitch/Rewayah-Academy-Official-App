# Stratégie : les classes vitrines

> **PROPOSITION, rien n'est décidé ni construit par ce document.** Rédigé le 13/11/2026 à la demande du directeur du 12/11/2026 (« la marketplace des classes, les classes vitrines », le « matching des classes »).
> Relevé fait sur le commit `e0b3d936` et sur les branches `origin/claude/suivi-attente`, `origin/claude/horloge-lieu`, `origin/claude/priere-serveur`. Aucune lecture de la production n'a été faite pour ce document.

## 0. D'abord, ce qui est faux, incertain ou non prouvé

1. **Un document sur le même sujet existe déjà** : `STRATEGIE-FORMATION-DES-CLASSES.md` (même dossier, 12/11, « en vigueur par arbitrage de l'architecte »). Celui-ci ne le remplace pas : il le précise avec les fichiers, les lignes et le découpage. Il le contredit sur deux points (n° 4 et n° 5 ci-dessous). Deux documents pour une stratégie, c'est un doublon : décision D1.
2. **« Les classes se créent automatiquement quand le seuil est atteint » : c'est faux aujourd'hui.** Le serveur compte et dit « prêt ». La création est un geste de la direction, une classe à la fois, et seulement quand le compte atteint le maximum (5 ou 6), pas le minimum d'ouverture.
3. **La capacité a deux sources.** Le regroupement et la création lisent `app_config` (`groupe.capacite_enfant`, `groupe.capacite_adulte`). La finance et les tarifs publics lisent `politiques_commerciales`. Elles valent 5 et 6 des deux côtés dans les migrations ; rien ne les tient égales.
4. **La liste des enseignants n'est pas triée par convenance.** Le serveur filtre (genre, langue, plafond, chevauchement) puis rend la liste par ordre alphabétique. L'autre document dit « liste triée, existe côté serveur » : le filtre existe, le tri non.
5. **« Éviter le maghreb et l'ishâ » ne peut pas être garanti pour une vitrine sans enseignant.** Le calcul des prières existe, mais il part du lieu d'un enseignant. Une vitrine n'a pas d'enseignant, donc pas de lieu. Il faut un lieu de référence : décision D4.
6. **« Fratries séparées » est décidé (10/10) mais je n'ai trouvé aucune règle serveur qui l'applique.**
7. **Une vitrine ne peut commencer qu'à une heure ronde** (`heure_locale` entier de 0 à 23). « 19 h à 20 h 30 » passe ; « 19 h 30 » ne passe pas.
8. **Les chiffres de production** cités dans l'autre document (0 offre publiée, 0 demande, deux élèves réels, un seul enseignant) ne sont pas revérifiés ici.
9. **Trois lots dont cette stratégie dépend ne sont pas livrés** : suivi de l'attente, horloge de La Mecque, prière (« À LIVRER » au registre, lignes 41 à 43). Tout ce qui s'appuie sur eux est « présent dans le code d'une branche », rien de plus.
10. **Aucune preuve de charge** n'existe pour un grand nombre de demandes.

## 1. Ce qui existe, ce qui manque

Chemins relatifs à `supabase/migrations/` sauf mention.

### Ce qui existe

| Brique | Où | État |
|---|---|---|
| Vitrine sans enseignant : table `offres_horaires` (public enfant ou adulte, langue, fuseau, jours, heure, durée, brouillon / publiée / retirée) | `0043_offres_horaires_et_intentions.sql:319` | Présent ; écrans direction `lib/features/admin_offres/` |
| Durées : 60 minutes enfant, 90 minutes adulte, réglables | `0043…:536-537` ; durée d'une classe : `20261022000400…:109` | Présent. Conforme aux mots du directeur |
| Trois séances par semaine, réglable (`groupe.seances_par_semaine`) | `0049_creneau_personnalise_ouvert_au_quota.sql:208` | Présent |
| Tranches d'âge 6-9, 10-13, 14-17, adultes | `20261017110800_af_l2_08_reglages_decisions_1410.sql:25` | Présent |
| La famille voit les offres compatibles et en choisit une | `0043…:682` (`offres_compatibles`), `:825` (`choisir_offre_horaire`) ; `lib/core/offres/service_offres.dart:184,201` ; écran `lib/features/parcours_offres/` | Présent |
| Demande de la famille (`demandes_horaires_famille` : source offre ou personnalisée, états envoyée, classe validée, enseignant affecté, refusée, retirée) | `0050_demandes_horaires_privees_admin.sql:19` | Présent |
| Créneau personnalisé ouvert au quota | `0050…:106` (`demander_creneau_personnalise`) | Serveur présent ; **aucun écran ne l'appelle** |
| Regroupement automatique par créneau, public, langue, genre, niveau | `20261011121958_c11bis_f74_partition_key.sql:140,178` ; écran `lib/features/admin_regroupements/` | Présent |
| « Créer la classe » depuis un regroupement, classe créée sans enseignant (`en_attente_enseignant`) | `20261012100000_c11bis_gender_enum_fix.sql:4` ; `0055_classes_en_attente_enseignant.sql:10` | Présent, une classe à la fois, au maximum seulement (ligne 140) |
| Classe : `groupes` (`type_public`, `seuil_max` de 1 à 6, `teacher_id` qui peut être vide) | `0017_groupes_pedagogiques.sql:22-28` ; `0055…:6` | Présent |
| Capacités, minimum d'ouverture, objectifs de classes, jours de conservation de place | `20261017170000_fac_a_01_politiques_commerciales.sql:39-45`, valeurs ligne 100 | Présent, lu par la finance |
| Plafond de classes par enseignant (`enseignant.classes_max`, 3) | `20261022000200_classes_plafond_par_enseignant.sql:19` | Présent |
| Enseignants possibles pour une classe : genre, langue, plafond, disponibilité qui couvre toute la durée, aucun chevauchement | `20261023000000_classes_duree_bout_en_bout.sql:622` ; affectation vérifiée `20261021210100_c11bis_affectation_verifiee.sql:86` | Présent ; non trié |
| Disponibilités hebdomadaires de l'enseignant (`weekly_availability`, heure ronde, fuseau par ligne) | `0005_dashboards_affectation_regles.sql:380` | Présent |
| Changer l'enseignant d'une classe | `20261103100000_reaffecter_classe.sql:68,138` | Présent |
| Un rang déterministe existe déjà pour le remplacement (genre puis langue) | `20261119300000_remplacement_temps_reel.sql:217` | Présent : modèle à réutiliser, pas à copier |
| Prières par enseignant : heures sans prière, heures où une prière se ferme pendant le cours | `20261123930000_priere_serveur.sql:1765,1789` | Présent dans le code, non livré |
| Suivi de l'attente « comme une livraison » : cinq étapes, délai de 14 jours et point à 7 jours (`formation_delai_jours`, `formation_point_jours`), liste des demandes en retard pour la direction, aucun courriel à un mineur | branche `claude/suivi-attente`, `20261123960000_suivi_attente.sql`, `20261123962000_suivi_attente_pret.sql` ; écran `lib/features/attente_classe/` | Branche, non livré |
| Ville et fuseau de chaque foyer et de chaque enseignant ; aperçu « 19:00 en hiver, 20:00 en été chez vous » sur une offre | branche `claude/horloge-lieu`, `20261123943000_lieux.sql`, `20261123943100_apercu_offre.sql` | Branche, non livré |

### Ce qui manque

1. La vitrine n'a ni genre, ni tranche d'âge, ni niveau utilisable (le niveau est vide en production selon le commentaire de `0043…:328`).
2. Aucun cycle de vie de la vitrine au-delà de brouillon, publiée, retirée.
3. Aucune création automatique, aucun découpage en plusieurs classes, aucun minimum d'ouverture dans la création.
4. Aucun vœu de rechange.
5. Aucun écran pour le créneau personnalisé.
6. Aucun tri des enseignants.
7. Aucune règle de fratrie, aucune règle d'âges proches.
8. Aucune relance automatique au délai ; l'entrée en début de mois n'est pas construite.
9. Aucune vitrine ne tient compte des prières.
10. L'ancien appariement individuel (`enseignants_pour`, `teacher_student_assignments`) est toujours dans le code.

## 2. Le modèle

**Une classe vitrine est une offre de l'académie, sans enseignant.** On garde la table `offres_horaires` : on lui ajoute ce qui manque, on ne crée pas une seconde table.

| Champ | Aujourd'hui | À ajouter |
|---|---|---|
| Jours (trois) et heure de début | Oui | Rien |
| Durée | Oui | Posée par le public : 1 h enfant, 1 h 30 adulte |
| Public | Enfant ou adulte | **Tranche d'âge** (6-9, 10-13, 14-17, adultes) |
| Genre | Non | Hommes, femmes ; mixte seulement par exception |
| Niveau | Champ vide | Le niveau déclaré déjà utilisé par le regroupement |
| Langue du cours | Oui | Rien |
| Fuseau | Un fuseau par offre | Heure de l'académie quand l'horloge est livrée |
| Fuseaux visés | Non | Liste indicative, pour la direction seulement : à décider (D6) |

**Cycle de vie.** Cinq états, calculés par le serveur, jamais saisis à la main.

| État | Règle | Ce que voit la famille |
|---|---|---|
| Proposée | Publiée, aucun vœu | « En formation » |
| En remplissage | Au moins un vœu, sous le minimum | « En formation » |
| Ouverte | Minimum atteint : la classe est créée, des places restent | « Ouvre bientôt », puis l'heure du premier cours à l'adulte |
| Pleine | Maximum atteint : 5 enfants, 6 adultes | « Complète » ; un nouveau vœu ouvre une vitrine jumelle |
| Fermée | Retirée par la direction, ou éteinte au délai | Disparaît ; les familles concernées sont prévenues |

Jamais de nombre d'inscrits, jamais de nom d'élève, jamais d'enseignant sur la carte (décisions du 22/09 et du 09/10).

**Réglages de la direction.** L'architecture ne change pas ; seules ces valeurs changent.

| Réglage | Valeur connue | Source |
|---|---|---|
| Maximum enfant | 5 | Directeur 12/11 ; code |
| Maximum adulte | 6 | Directeur 12/11 ; code |
| Minimum d'ouverture | 4 dans `politiques_commerciales` | Code ; à confirmer (D2) |
| Capacité débutant | 4 dans le code | Contredit « 5 max par groupe enfant » : D3 |
| Durée enfant, adulte | 60, 90 minutes | Directeur 12/11 ; code |
| Séances par semaine | 3 | Code |
| Délai de formation, point d'étape | 14 et 7 jours | Décision du 30/09 ; branche suivi de l'attente |
| Classes par enseignant | 3 | Code |
| Nombre de vœux de rechange | à décider | D5 |
| Seuil d'alerte des créneaux personnalisés | à décider | D7 |

**Quand le minimum n'est pas atteint au délai.** Le système n'annule rien seul. Au point d'étape, il prévient la direction. Au délai, il propose à la famille adulte les vitrines compatibles les plus proches, avec un seul geste pour changer. La famille peut aussi attendre encore, avec son accord. La direction voit la liste des demandes en retard (elle existe déjà dans la branche du suivi de l'attente).

## 3. L'appariement élève vers classe, sans IA

Tout est filtre et tri. Aucune note, aucun score caché.

**Étape 1 : les filtres (une vitrine qui échoue n'est pas montrée).**

1. Tranche d'âge de l'élève.
2. Genre de l'élève.
3. Langue du cours.
4. Niveau. Un élève qui dit déjà lire passe d'abord l'entretien de lecture.
5. L'élève n'a pas déjà une classe active.

**Étape 2 : l'ordre des cartes.**

1. D'abord une **classe déjà lancée qui a une place** : on remplit avant de créer.
2. Puis les vitrines **ouvertes**.
3. Puis les vitrines **en remplissage**, la plus proche du minimum en premier.
4. Puis les vitrines **proposées**.
5. À égalité : l'heure la plus proche des disponibilités données par la famille, puis la plus ancienne.

**Étape 3 : le placement dans une classe.** Quand le minimum est atteint, le serveur découpe : le plus petit nombre de classes tel que chacune ait entre le minimum et le maximum, effectifs les plus égaux possible. Dans un découpage, les élèves sont rangés par date de naissance : les âges proches se retrouvent ensemble. À égalité, la demande la plus ancienne passe d'abord. Ce qui ne remplit pas une classe attend.

**Cas particuliers.**

| Cas | Règle |
|---|---|
| Fratrie | Décision du 10/10 : séparée. Deux enfants du même foyer ne sont jamais mis dans la même classe par le système. S'ils sont dans la même tranche et le même créneau, le serveur les met dans deux classes jumelles ; s'il n'y en a qu'une, le plus récent attend et le tuteur est prévenu. La direction peut accorder une exception nommée. Les enfants d'un même foyer se voient proposer en premier des créneaux qui ne se chevauchent pas |
| Adulte | Choisit et suit seul. Classe de 1 h 30, 6 au plus. Reçoit lui-même les messages |
| Passage à 18 ans | La classe en cours ne change pas ; le prochain placement se fait chez les adultes (même chemin) |
| Enfant de 6 à 9 ans | Classe de 1 h, 5 au plus. Le tuteur choisit. L'enfant ne voit ni date, ni délai, ni état d'attente (charte, arbitrages n° 99 et n° 106) |
| Fuseaux | Une vitrine a une seule heure, celle de l'académie. Chaque famille la lit dans son heure, hiver et été (aperçu de la branche horloge). Le système ne cache pas une vitrine à cause de l'heure locale : il la classe plus bas et affiche l'heure vraie. Une heure de nuit pour un enfant : à décider (D8) |
| Prière | Deux contrôles, tous deux calculés. À la publication : la vitrine est contrôlée contre le lieu de référence (D4) sur douze mois ; un croisement avec le maghreb ou l'ishâ bloque la publication ou l'avertit (D4). À l'affectation : contrôle contre le lieu réel de l'enseignant, avec les fonctions qui existent |
| Créneau personnalisé | Proposé seulement après la vitrine, jours et heure obligatoires, un seul à la fois par élève. Il devient une vitrine ordinaire au minimum ; sinon il s'éteint au délai |

## 4. L'affectation de l'enseignant

**Qui décide : la direction, d'un geste.** Le système classe ; il n'affecte pas seul (recommandation D9). Raison : aujourd'hui aucun enseignant n'a été validé par entretien ; une affectation sans regard n'a pas de preuve.

**Filtres (ils existent tous).** Compte actif et identité approuvée ; genre exigé par la classe ; langue du cours ; sous le plafond de classes ; disponibilités qui couvrent toute la durée, sur chaque jour ; aucun chevauchement avec ses autres classes ou séances.

**Tri (à construire, dans cet ordre).**

1. Aucune prière qui se ferme pendant le cours, sur douze mois (existe : `priere_creneaux_fermeture`).
2. Le moins de séances qui croisent l'entrée d'une prière.
3. A déjà enseigné ce public et ce niveau : à décider, la donnée n'est pas relevée (D10).
4. La charge la plus faible : moins de classes actives d'abord.
5. L'heure du cours tombe dans sa journée, dans son fuseau.
6. L'ancienneté à l'académie : date de validation la plus ancienne.
7. À égalité : ordre alphabétique, pour que le résultat soit toujours le même.

L'ordre de ces critères est un réglage de la direction, comme pour le remplacement (`private.remplacement_rang`). Une seule fonction de rang sert l'affectation, le changement d'enseignant et le remplacement.

**Ce que voit la direction.** Une page, un hub : « Formation des classes ». Les vitrines et leur état ; les regroupements avec leur compte ; les classes sans enseignant, chacune avec sa liste triée et, pour chaque nom, la raison de son rang en mots (« libre les trois jours », « 1 classe », « aucune prière croisée »). Les pages Offres, Regroupements et Planning y mènent par raccourci ; aucune liste n'est recopiée.

**Si personne ne convient.** La classe reste « en attente d'enseignant » (l'état existe). La famille adulte le lit tel quel. La direction voit le critère qui a écarté chacun, et le système remonte le besoin au recrutement : créneau, genre, langue. Une classe ne commence jamais sans enseignant. Mieux : une vitrine qu'aucun enseignant validé ne peut tenir n'est pas publiée, ou porte un avertissement (D11).

## 5. Ce que voit la famille

Un seul écran : le suivi de l'attente (branche `claude/suivi-attente`, `lib/features/attente_classe/`). Cette stratégie n'en crée pas d'autre ; elle lui fournit des états vrais.

| Moment | Tuteur ou élève adulte | Enfant |
|---|---|---|
| Vœu envoyé | « Demande envoyée », la vitrine choisie, l'heure chez lui | Rien |
| En remplissage | « Votre classe se forme », le délai honnête | Rien |
| Minimum atteint | « Votre classe ouvre » | Rien |
| Enseignant affecté | La carte de l'enseignant, le premier cours | De 10 à 17 ans : sa classe, quand elle existe |
| Tout est prêt | Notification et courriel | Sa classe apparaît dans son accueil |
| Délai dépassé | Les vitrines proches, ou attendre encore | Rien |

- **Aucune promesse de date à l'enfant.** Un enfant de 6 à 9 ans ne voit ni date ni délai. La date va au tuteur.
- **Aucune notification, aucun courriel, aucun push à un mineur** (décidé le 01/11 ; la garde serveur est dans la branche). Le tuteur est le destinataire.
- Jamais de prénom d'enfant dans un push.
- Le délai affiché est celui du réglage, pas une estimation.

## 6. L'argent

Aucune règle de prix ni de paie n'est proposée ici. Les décisions qui reviennent au directeur :

1. La famille paie-t-elle au vœu, à l'ouverture de la classe, ou au premier cours ?
2. Que devient un paiement si la classe ne se forme pas au délai ?
3. L'essai : avant ou après la formation de la classe ?
4. La place gardée (`jours_conservation_place`) vaut-elle pour un vœu sur une vitrine ?
5. Une classe ouverte au minimum et non au maximum : effet sur la paie de l'enseignant.
6. L'entrée en début de mois (décidée le 30/09, non construite) et son effet sur la première facture.
7. Le créneau personnalisé a-t-il un prix différent ?
8. Les capacités : une seule source entre `politiques_commerciales` et `app_config`. C'est une règle d'argent autant qu'une règle de classe.

Tout cela relève du lot HARMONISER-ARGENT (`A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`).

## 7. Les lots

Les noms reprennent FC-1 à FC-4 de l'autre document, pour ne pas créer une seconde numérotation au registre. Le directeur colle une migration seulement si elle contient un mot d'effacement ; sinon le pilote l'installe.

### FC-1 La vitrine complète

- **Tables et fonctions.** `offres_horaires` : genre, tranche d'âge, niveau. `offres_compatibles` : filtres et ordre de la partie 3. Une lecture de l'état de la vitrine. Une seule source des capacités. Vœux de rechange sur `demandes_horaires_famille`.
- **Écrans.** `admin_offres` (nouveaux champs), `parcours_offres` (cartes avec état, vœux de rechange, écran du créneau personnalisé).
- **Dépend de.** Horloge de La Mecque (heure de l'académie, aperçu chez la famille).
- **À coller.** Probablement rien si les colonnes sont seulement ajoutées ; à compter avant l'installation.
- **Risques.** `offres_compatibles` change de sortie : l'ancien client en dépend. La clé de regroupement change si le fuseau de l'offre change.

### FC-2 La création automatique

- **Tables et fonctions.** Découpage serveur (minimum, maximum, âges proches, fratrie). Création de toutes les classes d'un regroupement en une fois, à partir de `creer_classe_depuis_regroupement`. Journal de chaque création.
- **Écrans.** `admin_regroupements` : aperçu, déplacer un élève, exception nommée.
- **Dépend de.** FC-1 ; décisions D2, D3, D12.
- **À coller.** Rien de prévu.
- **Risques.** Deux créations en même temps sur le même regroupement : verrou par clé (règle du 10/10). Un mauvais découpage touche des familles réelles : aperçu obligatoire tant que D12 n'est pas tranchée.

### FC-3 Le tri des enseignants et l'offre réelle

- **Tables et fonctions.** Une fonction de rang commune (affectation, changement, remplacement). `enseignants_pour_classe` rendue triée, avec la raison en clair. Contrôle de prière d'une vitrine contre le lieu de référence. Besoin de recrutement par créneau.
- **Écrans.** Le hub « Formation des classes » ; la liste triée dans la feuille d'affectation.
- **Dépend de.** Prière, horloge ; D4, D9, D10.
- **À coller.** À compter : remplacer `private.remplacement_rang` peut demander un effacement.
- **Risques.** Toucher au remplacement, qui a une décision propre (07/11) : la règle du remplacement ne change pas, seule sa fonction est partagée.

### FC-4 Les promesses et la famille

- **Tables et fonctions.** Relance au point d'étape et au délai ; proposition des vitrines proches ; quatre mesures pour la direction (délai moyen, part des premiers vœux servis, attentes au-delà du délai, part des créneaux personnalisés).
- **Écrans.** Suivi de l'attente (états nouveaux), carte de mesures dans le hub.
- **Dépend de.** Suivi de l'attente livré ; FC-2.
- **À coller.** Si un nouvel événement de notification est ajouté : oui, comme pour « tout est prêt » (la contrainte des événements est remplacée).
- **Risques.** Envoyer un message à un mineur : interdit, la garde serveur doit être livrée avant.

### FC-5 Un seul chemin

- **Contenu.** Le changement de classe passe par le même mécanisme. Retrait de l'ancien appariement individuel.
- **Dépend de.** FC-2 ; accord écrit du directeur pour chaque suppression.
- **À coller.** Oui : c'est un lot d'effacement.
- **Risques.** Supprimer du code encore lu par un écran ; inventaire d'abord.

## 8. Les décisions du directeur

| N° | Décision | Recommandation | Raison |
|---|---|---|---|
| D1 | Deux documents de stratégie : lequel fait foi ? | Celui-ci porte le détail ; l'autre devient un résumé qui y renvoie | Un seul endroit par règle |
| D2 | Minimum d'ouverture | Garder 4, la valeur du code, réglable | Elle existe déjà et sert la finance |
| D3 | Classe de débutants à 4 au plus (30/09) ou 5 enfants (12/11) ? | La parole la plus récente : 5 enfants, 6 adultes, sans cas débutant | Une règle de moins, et c'est ce que vous avez dit le 12/11 |
| D4 | Lieu de référence pour « éviter le maghreb et l'ishâ » sur une vitrine | La Mecque, puis contrôle au lieu réel de l'enseignant à l'affectation | L'heure de l'académie est celle de La Mecque ; le second contrôle existe déjà |
| D4 bis | Un croisement bloque la publication ou avertit ? | Avertit fort, ne bloque pas | Les heures de prière bougent sur l'année ; bloquer viderait la vitrine |
| D5 | Nombre de vœux de rechange | Deux, comme l'autre document | Les classes se forment plus vite |
| D6 | « Fuseaux visés » sur une vitrine | Information pour la direction, jamais un filtre | Ne cacher aucune classe à une famille |
| D7 | Seuil d'alerte des créneaux personnalisés | Un sur dix, valeur de l'autre document, réglable | À confirmer : ce chiffre n'est pas de vous |
| D8 | Heure de nuit pour un enfant | Classer plus bas avec l'heure vraie, ne pas interdire | La famille décide |
| D9 | Le système affecte l'enseignant seul, ou propose ? | Il propose, la direction confirme d'un geste | Aucun enseignant validé à ce jour |
| D10 | Critère « a déjà enseigné ce public » | Le reporter : la donnée n'existe pas | Ne pas trier sur du vide |
| D11 | Publier une vitrine qu'aucun enseignant validé ne peut tenir ? | Oui, avec avertissement à la direction | Sinon aucune vitrine aujourd'hui |
| D12 | Création automatique sans aperçu ? | Automatique pour le cas simple (un regroupement, aucune exception) ; aperçu dès qu'il y a fratrie ou exception | « Le système agit seul » sans risque pour une famille |
| D13 | Fratrie : séparation stricte ou choix du tuteur ? | Garder la séparation du 10/10, exception nommée par la direction | Décision déjà prise |
| D14 | Créneau personnalisé visible des autres familles dès deux demandes ? | Oui, comme l'autre document | À confirmer : ce chiffre n'est pas de vous |
| D15 | Heures non rondes (19 h 30) | Non pour l'instant | Tout le calcul des chevauchements est à l'heure ronde |
| D16 | Ordre des critères du tri des enseignants | Celui de la partie 4 | Prière et charge d'abord |
