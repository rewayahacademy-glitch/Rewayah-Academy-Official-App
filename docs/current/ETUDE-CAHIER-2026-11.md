# Étude du cahier de l'enseignant, novembre 2026

Session ETUDE-CAHIER, lancée le 05/11/2026 par le garde-cap à la demande du directeur (`PLAN-LOTS.md` §7, rang 22 d). C'est une étude : aucun code de `lib/` ni de `supabase/` n'est modifié, aucune migration n'est écrite. Source de la mission : `docs/current/VISION-ECOLE-2026-11-05.md` (sur la branche du pilote au 05/11, pas encore dans `main`).

Statut de chaque affirmation : **lu dans le code** (fichier et ligne), **mesuré en production** (lecture seule, 05/11/2026, aucune écriture), **source publique** (lien en fin de document), **proposé** (ma recommandation, rien n'est décidé).

---

## 0. Ce qui est faux, bloqué ou inconnu, en premier

1. **Le cahier actuel ne sert à aucun des cinq usages de la vision.** Ce qu'il enregistre n'est relu par personne pour continuer, ni calculé pour mesurer. Preuves au §2.
2. **Le remplaçant ne voit pas où continuer.** La préparation de séance, qui devait afficher « où la classe s'est arrêtée », rend toujours `null` en production (`lib/features/fiche_groupe/preparation_seance.dart:71`, commentaire « aucune source serveur à ce jour »). La position écrite dans le cahier n'est relue nulle part.
3. **La colonne vertébrale n'existe pas dans les données.** En production le 05/11 : programme, 1 version et **0 publiée**, 1 niveau ; progression des élèves, 0 ligne ; évaluations, 0 ; supports de la Bibliothèque, 0 ; contenu présenté en classe enregistré côté serveur, 0. Aucun indicateur n'est calculable tant que le programme n'est pas en base.
4. **Le vrai blocage n'est pas l'écran du cahier : c'est le programme en données.** Les étapes, leurs objectifs, les lignes numérotées des supports et les durées par tranche d'âge doivent exister en base. Une partie de ce contenu dépend du directeur (supports Rewayah, objectifs validés). Je ne sais pas où en est l'écriture du livre de lecture Rewayah : **inconnu**.
5. **La stratégie recommandée retire des champs au cahier.** Or le cahier K-45 est gelé (« n'y ajoute aucun champ sans décision datée », `programme-rewayah` §5). Retirer ou remplacer demande donc une décision datée du directeur. Je ne présente rien de tout cela comme décidé.
6. **Les temps par séance des références (§1.2) sont des estimations** faites à partir de leurs descriptions publiques, pas des mesures. Aucune de ces plateformes ne publie un chronométrage.

---

## 1. Les références du marché

**Précision du directeur (05/11, transmise par le garde-cap) :** ne pas prendre les écoles coraniques en ligne comme modèles, parce qu'elles sont en retard, et regarder plutôt Duolingo et les autres. **J'écarte donc les écoles coraniques en ligne et les carnets de hifz** (Manzil, Sabaq, Hifz Tracker) : ce sont des registres à remplir à la main, ce que nous cherchons justement à quitter. Le directeur a raison sur ce point. Il a demandé qu'on le dise s'il se trompe : deux nuances sont nécessaires (voir le bloc « Les deux nuances » plus bas).

Question posée : comment ces services suivent-ils l'avancement sans corvée pour l'enseignant ? Je ne recopie ni marque ni écran : je relève le principe.

### 1.1 Le suivi vu par l'élève, la famille et la direction (références principales)

| Référence | Position dans un parcours | Objectifs à court terme | Vitesse et date | Régularité | Mesure | Calculé seul |
|---|---|---|---|---|---|---|
| **Duolingo** | Un chemin d'unités groupées en sections ; chaque unité vise un but de communication | L'unité en cours | Un score de progression unique (sur 160, calé sur les niveaux européens) | La série de jours (« streak ») | Petits exercices à chaque leçon, points de passage entre sections | Tout : aucune saisie humaine |
| **Khan Academy** (maîtrise) | Le cours, l'unité, la compétence | Les objectifs de maîtrise fixés par l'enseignant | Le pourcentage de compétences maîtrisées | (non central) | Exercices et contrôles d'unité ; un niveau monte ou redescend selon les réponses | Niveau de chaque compétence, rapport par classe et par élève |
| **Busuu** | Chapitres calés sur les niveaux européens | Le plan d'étude : jours, minutes, niveau visé | **Une date prévue d'arrivée**, calculée au départ, et un bilan chaque semaine du temps fait contre le temps promis | Le respect du plan de la semaine | Un test de passage entre chaque chapitre | La date prévue et l'écart au plan |

**Ce que Rewayah en prend :**
1. **Une position unique et lisible** dans un chemin d'étapes (Duolingo, Busuu). Chez nous : l'étape, puis l'endroit exact (support, page, ligne).
2. **Une date prévue, comparée chaque semaine à la date promise** (Busuu). Chez nous, la promesse est la date limite de l'étape, et l'écart se dit « dans les temps » ou « en retard ».
3. **Des petits contrôles qui ferment une étape** (points de passage de Duolingo, tests de chapitre de Busuu, contrôles d'unité de Khan). Chez nous : le petit bilan et l'examen de fin des bases, que le serveur propose et que l'enseignant confirme.
4. **Un niveau qui peut redescendre** (Khan). Chez nous : « Stable » calculé, jamais saisi, et retiré si l'élève rechute.

**Ce que Rewayah n'en prend pas :** la série de jours comme mesure du progrès. Même un article grand public le dit : la série prouve qu'on ouvre l'application, pas qu'on apprend. Chez nous, la régularité, c'est la présence aux 3 cours de la semaine et le travail fait avant le cours suivant.

### 1.2 Le côté enseignant (là où un vrai professeur fait cours)

| Référence | Ce qu'elle demande à l'enseignant | Estimation par séance | Ce qu'elle tire seule | Ce que voient la famille et la direction |
|---|---|---|---|---|
| **Preply** (cours particuliers en visio) | Rien à écrire, et seulement si l'enseignant et l'élève y consentent | 0 s | Un compte rendu structuré quelques minutes après le cours : résumé, retours, temps de parole, vocabulaire, suite conseillée | L'élève et l'enseignant, dans leur conversation |
| **Outschool, ClassDojo Tutor** (cours en visio) | Relire le résumé tiré de la transcription, le corriger ou le laisser partir | 0 à 30 s | Le compte rendu de séance | La famille reçoit le résumé, envoyé seul après 4 heures si l'enseignant ne fait rien |
| **Toddle, Seesaw** (outils de classe) | Rattacher un travail ou une observation à un objectif du référentiel | 5 à 15 s par observation | La progression par objectif dans le temps, qui alimente le bulletin | La famille voit la progression par objectif ; la direction, un tableau par objectif |
| **Brightwheel** (petite enfance) | Une observation courte, rattachée à un jalon | 5 à 15 s par observation | Un dossier par jalon, sans bilan à rédiger | La famille voit un fil en direct ; la direction, les rapports par jalon |
| **Kumon** (professeur et fiches) | Corriger, fixer un temps cible | environ 10 s par élève | Le temps et le score de chaque fiche, en couleur au-delà de la cible | La famille voit l'historique des fiches, et si les erreurs baissent |

### 1.3 Les deux nuances, que le directeur a demandé de signaler

- **Duolingo n'a pas d'enseignant.** Il sait tout mesurer parce que l'élève fait tout dans l'application. Chez Rewayah, l'apprentissage a lieu en direct avec un enseignant : il faut donc emprunter le côté élève à Duolingo, Khan et Busuu, et le côté enseignant à Preply, Outschool et Toddle. Ces outils ne sont pas coraniques.
- **Tarteel n'est pas une école, et il est en avance.** C'est une application qui écoute la récitation avec l'IA. Selon sa fiche de magasin, elle relève les mots oubliés, faux ou ajoutés et les voyelles fausses, mais pas encore le tajwid ni la prononciation. Elle garde l'historique des fautes, montre les sourates solides et les versets à retravailler, et laisse fixer une portion avec une échéance. Ce qu'on en prend : **les points à renforcer sont rattachés à un endroit précis du texte**, pas à une catégorie générale. Ce qu'on n'en fait pas : un modèle d'école, car rien n'y remplace l'enseignant.

**Ce que font les meilleurs, en cinq principes :**

1. **Le référentiel d'abord.** Toute observation est rattachée à un objectif du parcours (Khan, Toddle, Brightwheel). Jamais de texte libre comme donnée principale.
2. **La machine capte, l'enseignant confirme.** Ce qui se mesure seul (présence, position, durée, transcription) n'est jamais redemandé (Preply, Outschool, Kumon).
3. **L'exception seulement.** On touche ce qui sort de l'ordinaire ; le reste vaut « comme prévu » (Outschool, qui envoie seul).
4. **Le rythme est un calcul, pas une saisie.** La position est comparée au plan pour en tirer une date prévue (Busuu).
5. **Chacun voit sa partie, en mots simples.** La famille voit un état et la suite ; la direction, une liste triée par risque.

**Ce qui manque au marché, et que Rewayah peut faire :** aucun de ces services ne suit une classe stable qui avance dans un programme à étapes, avec des dates limites et un remplaçant. Rewayah le peut, parce que la salle, le programme et la présence sont dans la même application.

**Option payante, non retenue.** Le compte rendu tiré de la transcription (Preply, Outschool) coûterait la transcription de chaque cours. Il heurte aussi la règle « pas de captation tant que la politique n'est pas validée » (registre §5). Je ne le recommande pas : la position et la présence suffisent, et elles ne coûtent rien.

---

## 2. Diagnostic du cahier actuel

### 2.1 Ce qu'il demande (lu dans le code)

Écran `lib/features/cahier/cahier_page.dart` (1 611 lignes, 115 textes `enseignant.cahier.*`). Pour la classe : « Où la Classe s'est arrêtée » (sourate et verset), obligatoire. Pour chaque élève, dans la feuille « Ajuster » (`cahier_page.dart:1011-1370`) :

| Champ | Forme | Stockage |
|---|---|---|
| Performance | 4 niveaux : à revoir, en progrès, acquis, maîtrise | `content.eleves[].performance` |
| Faiblesses | 6 cases : makharij, madd, ghunna, waqf, fluidité, mémorisation | `content.eleves[].faiblesses` |
| La suite | continuer, renforcer, suspendre le nouveau | `content.eleves[].suite` |
| Point de prononciation | choix d'un makhraj | `content.eleves[].point_phonetique` |
| Objectif de l'élève | **texte libre** | `content.eleves[].objectif_personnel` |
| Devoir de l'élève | **texte libre** | `content.eleves[].travail_maison` |
| Exception de présence | correction ou excuse, avec motif | trigger `lesson_reports_appliquer_exceptions` |
| Note de classe | texte libre | `content.note_groupe` |

Le tout part en **un seul bloc JSON** par séance, inséré par le client dans `lesson_reports.content` (`lib/core/enseignant/service_enseignant.dart:155`, table `0001_fondations.sql:221`). Depuis le 31/10, un cahier par classe et par semaine suffit, et **la paie de la séance attend ce cahier** (`20261103000000_cahier_hebdomadaire.sql`, en-tête point 4).

### 2.2 Ce qui sert, ce qui ne sert pas

| Élément | Sert-il ? | Preuve |
|---|---|---|
| Présence et durée déduites | **Oui** : préremplies par le serveur, ce qui est juste | `brouillon_cahier`, `20261103300000_cahier_remplacant.sql:103-235` |
| Cahier ouvert au remplaçant | **Oui** pour le remplir | même migration, porte « enseignant effectif » |
| Position de reprise | **Non relue.** Écrite en texte (« Sourate 2, verset 61 »), jamais relue par la préparation de séance, la salle ni le remplaçant | `preparation_seance.dart:71` rend `null` ; aucun lecteur de `position_reprise` côté serveur |
| Position proposée | **Mauvaise source.** Elle vient de la position de lecture personnelle de l'élève dans le Mushaf, pas de la page présentée en classe. Pour un élève des bases (livre de lecture, support, page, ligne), l'unité est fausse | `brouillon_cahier` lit `student_reading_position` ; règle contraire : `programme-rewayah` §5 |
| Mémoire de la page présentée en classe | **Locale à l'appareil.** Un remplaçant sur un autre appareil ne l'a pas | `lib/features/salle/memoire_page_classe.dart:16` |
| Préremplissage « devoir, performance et faiblesses précédents » | **Ne marche pas.** Le client lit des clés que le serveur n'envoie pas | `modeles_enseignant.dart:477-484` contre `brouillon_cahier` (aucune clé `devoir_precedent`, `performance_precedente`, `faiblesses_precedentes`) |
| Performance, faiblesses, suite | **Non calculés.** Aucun trigger ni aucune fonction ne les transforme en progression, en « Stable » ou en besoin d'examen | seuls triggers sur `lesson_reports` : exceptions de présence et avis de fin de séance |
| 4 niveaux de performance | **Contraire au décidé** : 3 états face aux familles, « Stable » calculé sur 3 observations en 2 semaines | registre §1 et §8 bis |
| 6 faiblesses de tajwid | **Pas rattachées au programme.** Elles ne parlent pas des étapes 1 et 2 (les lettres, les voyelles), qui occupent l'essentiel des bases | `FaiblesseRecitation`, `modeles_enseignant.dart:788` |
| Objectif et devoir en texte libre | **Incalculables** : ni emploi du temps de révision, ni « fait ou pas fait » | les tables `learning_assignment` (devoir structuré) existent et sont vides |
| Lecture par la direction | **Brute**, séance par séance, élève par élève | `lib/features/admin_groupes/cahiers_classe.dart` ; `lire_cahier_admin` |
| Ce que voit la famille | Le niveau et des jalons ; ni date limite, ni rythme | `progression_famille`, `20261018190000_ped_cahier_partage.sql:281` |

### 2.3 Ce que disent les données de production (05/11, lecture seule)

| Mesure | Valeur |
|---|---|
| Séances tenues | 95 |
| Classes | 18 |
| Cahiers déposés | 6 |
| Cahiers avec performance, faiblesses, objectif ou devoir | **0** sur 6 : les 6 ne contiennent que la présence confirmée et la position |
| Positions de reprise distinctes | 2 (« Sourate 112, verset 3 », puis 5 fois « Sourate 2, verset 61 ») |
| Programme publié | 0 |
| Progression des élèves, évaluations | 0, 0 |
| Supports, devoirs structurés, contenu présenté enregistré | 0, 0, 0 |

Prudence : ces cahiers sont sans doute des essais du directeur ; on ne peut pas en tirer un comportement d'enseignant. Mais le signal est net : **même en test, seul le minimum qui débloque est rempli**, et la même position est recopiée 5 fois. C'est le comportement attendu d'un formulaire vécu comme une corvée.

### 2.4 Les données qui manquent pour les 5 usages

| Usage (vision §3) | Il faut | Existe ? |
|---|---|---|
| Le remplaçant sait où continuer | La position de la classe (support, page, ligne), relue avant la séance | Écrite en texte, jamais relue ; page présentée gardée sur l'appareil seulement |
| La direction mesure | Étape de chaque élève, plan de l'étape, date limite, vitesse, besoin d'examen | Rien de calculé ; programme non publié |
| La famille sait | Étape, date limite, rythme en mots simples, travail avant le prochain cours | Niveau et jalons seulement |
| L'élève connaît son étape | Idem, en Interface guidée pour l'enfant | Idem |
| L'enseignant suit sans travail en plus | Position et points à renforcer préremplis, rien à retaper | Préremplissage cassé, champs libres |

---

## 3. Ce que je critique, y compris dans la vision du directeur (consigne V2)

1. **On a construit le formulaire avant le référentiel.** Le cahier demande des jugements (4 niveaux, 6 faiblesses) qui ne s'accrochent à aucun objectif d'étape. Sans objectif auquel les rattacher, ces jugements ne peuvent rien mesurer. Les références font l'inverse : le référentiel d'abord, puis l'observation d'un clic sur un objectif.
2. **Lier la paie au cahier complet fabrique des cahiers vides.** Un enseignant qui doit remplir pour être payé remplit le minimum : c'est ce qu'on voit (§2.3). La présence et la durée prouvent déjà que le cours a eu lieu. **Proposé** : la paie attend seulement la confirmation de la position, qui prend 5 secondes et qui sert au remplaçant ; le reste n'est plus une condition de paie.
3. **Un cahier hebdomadaire ne suffit pas au remplaçant.** Si le cahier de la semaine est déposé vendredi, le remplaçant de mercredi ne sait pas où lundi s'est arrêté. La position doit se capter **à chaque séance, toute seule**, quelle que soit la règle du cahier.
4. **La position doit venir de la salle, jamais d'une saisie.** Le programme le dit déjà (`programme-rewayah` §5), mais l'écran demande encore de choisir sourate et verset. Le directeur avait raison sur le fond ; l'outil ne l'applique pas.
5. **Le « Où suis-je ? » des bases n'est pas dans le Coran.** Trois étapes sur quatre se lisent dans le livre de lecture. Tant que ce livre n'a pas ses lignes numérotées en base, aucune position exacte n'est possible pour un débutant. C'est un travail de contenu du directeur, pas un écran.
6. **Ne pas tout mesurer.** Une donnée qui ne change aucune décision n'est pas demandée (vision §4). Le point de prononciation et les faiblesses de tajwid par séance n'alimentent aucune décision écrite : je propose de les garder seulement comme « points à renforcer » choisis dans les objectifs de l'étape.

---

## 4. La stratégie recommandée (une seule)

**En une phrase : le cahier cesse d'être un formulaire ; l'application écrit le compte rendu à partir de la salle et du programme, et l'enseignant le confirme en moins de 20 secondes.**

### 4.1 Le programme est la colonne vertébrale

Chaque étape porte, en données versionnées (règle de stabilité 4) :
- ses **objectifs observables**, peu nombreux (par exemple, pour l'étape 1, « reconnaît les lettres seules », « les prononce depuis leur point de sortie ») ;
- sa **plage de support** : du support, page, ligne au support, page, ligne (le livre Rewayah, puis le Mushaf pour l'étape 4) ;
- sa **durée prévue et sa date limite par tranche d'âge** (réglages, valeurs de `programme-rewayah` §3) ;
- les **examens** qui la ferment (bilan périodique pour les étapes 1 à 3, examen de fin des bases).

Les tables `programme_versions` et `programme_niveaux` existent (`0020`) ; il leur manque les objectifs, la plage de support et les durées.

### 4.2 Ce que l'application remplit seule

| Donnée | Source déjà présente ou à brancher |
|---|---|
| Présence et minutes | `etat_presence`, événements de séance (en service) |
| **Position de la classe** | La dernière page ou ligne présentée dans la salle, enregistrée **au serveur** à chaque changement de page (`session_shared_content.group_resume_position`, `0032`, aujourd'hui vide ; remplace la mémoire locale) |
| Ce qui a été couvert pendant la séance | La différence entre la position de début et la position de fin |
| Le travail avant le prochain cours | « Relire de telle ligne à telle ligne » : la plage couverte, écrite en devoir structuré (`learning_assignment.content_range`, purpose `review`, `0032`, vide) |
| L'emploi du temps de révision | Tiré de ces devoirs, sans saisie (`programme-rewayah` §6) |
| Les points à renforcer reportés | Ceux de la séance précédente, encore ouverts |

### 4.3 Ce que l'enseignant fait, en moins de 20 secondes

1. **« La classe s'est arrêtée ici »** : la page et la ligne présentées, déjà affichées. Juste, ou corriger d'un toucher.
2. **Seulement les exceptions** : toucher un élève, puis un objectif de l'étape à renforcer (liste fermée, 3 à 5 objectifs), ou « prêt pour le bilan ».
3. Une note facultative, jamais obligatoire.

Tout le reste vaut « comme prévu ». Les 3 états visibles (À renforcer, Acquis, Stable) restent ; « Stable » est calculé (3 observations en 2 semaines, dont une non préparée), jamais saisi.

### 4.4 Ce que le serveur calcule

| Indicateur | Calcul proposé |
|---|---|
| **Position** | Étape, et part de la plage de l'étape couverte (lignes couvertes sur lignes de l'étape) |
| **Vitesse** | Lignes par semaine sur les 4 dernières semaines, comparées au rythme prévu (lignes de l'étape divisées par la durée prévue de la tranche) |
| **Risque sur la date limite** | Date de fin projetée au rythme actuel, comparée à la date limite : « Dans les temps », « À surveiller », « En retard ». La date limite recule seulement des fermetures et des pauses accordées |
| **Besoin d'examen** | Plage de l'étape couverte et objectifs acquis, ou date limite dans moins de N semaines (réglage), ou « prêt pour le bilan » de l'enseignant : le serveur **propose**, l'enseignant confirme, l'administration planifie (`evaluations`, `0023`). Jamais automatique |
| **Points à renforcer** | Objectifs marqués « À renforcer » sur les dernières séances, par élève et par classe (règle du groupe : consolidation commune si 40 % ou plus) |
| **Absences** | Déjà comptées par la présence |

Tous les seuils sont des réglages de la console, jamais en dur (consigne V5).

### 4.5 Ce que voit chacun

| Qui | Ce qu'il voit |
|---|---|
| **Enseignant** | Avant le cours : « On reprend page 14, ligne 6 », et les élèves à renforcer, sur quoi. Après : l'écran de confirmation. Sur sa classe : qui est en retard, qui est prêt pour un bilan |
| **Remplaçant** | Exactement la même carte avant le cours, sans rien demander à personne |
| **Famille** | L'étape, la date limite, le rythme en mots (« dans les temps »), le travail avant le prochain cours ; après une absence, l'endroit exact à rattraper. Seulement la partie de son enfant |
| **Élève** | Son étape, sa date limite, son travail ; en Interface guidée pour l'enfant |
| **Direction** | Une liste de classes triée par risque (`DataCollection`), avec filtres « En retard », « Examen à prévoir », « Cahier non confirmé » ; puis la classe, puis l'élève |

### 4.6 Ce qu'on réutilise, ce qu'on écarte (inventaire du 31/10)

Réutilisé : `programme_versions`, `programme_niveaux` (`0020`) ; `progression_historique` (`0021`) ; `evaluations` (`0023`) ; `session_shared_content` et le module `core/tc_etat_partage` (en partie non branché) ; `learning_assignment` (`0032`) ; `brouillon_cahier` et la porte du remplaçant ; `etat_presence` ; `progression_famille`, `compte_rendu_famille` ; l'écran direction `cahiers_classe.dart` ; `DataCollection`. Le bloc `lesson_reports` reste, pour l'historique et la paie.

Écarté : `tc_flux_academique` et `port_post_cours` (doublon du cahier, l'inventaire dit déjà de ne pas les brancher) ; le résumé par transcription (coût, captation non autorisée) ; le sélecteur de sourate et verset comme source principale (il reste seulement pour corriger).

---

## 5. Les étapes de construction

Une étape, une PR, une preuve faite par le directeur en production après fusion. Aucune migration n'est écrite ici.

| Lot | Contenu | Tables et écrans touchés | Preuve attendue |
|---|---|---|---|
| **C0, décisions** (directeur, sans code) | 1. Lever le gel K-45 pour remplacer les champs du cahier. 2. La paie attend la confirmation de la position, plus le cahier complet. 3. Valider 3 à 5 objectifs par étape des bases. 4. Dire où en sont les supports Rewayah numérotés | aucun | Décision datée écrite dans `08` §5 bis |
| **C1, position automatique** (le premier usage, possible tout de suite avec le Mushaf) | La salle enregistre au serveur la dernière page présentée par classe ; la préparation de séance la lit ; le remplaçant la voit | `session_shared_content` ; `memoire_page_classe.dart`, `preparation_seance.dart`, `fiche_groupe_page.dart`, salle | Le directeur présente une page sur un appareil, puis ouvre la classe comme remplaçant sur un autre : « On reprend page X » s'affiche |
| **C2, programme en données** | Objectifs, plage de support, durées et dates limites par tranche ; publication d'une version par la direction | `programme_niveaux` et tables liées ; écran programme de la direction | Le directeur publie la version 1 des bases et la voit dans la fiche d'un élève |
| **C3, cahier de confirmation** | L'écran devient : position (juste ou corriger), exceptions par objectif, « prêt pour le bilan ». Observations enregistrées en lignes, une par élève et par objectif ; devoir structuré écrit seul | `lesson_reports` (gardé) et une table d'observations ; `learning_assignment` ; `cahier_page.dart` réduit ; textes `enseignant.cahier.*` | Le directeur chronomètre : moins de 20 secondes pour une classe de 5 sans exception ; les lignes sont visibles |
| **C4, indicateurs au serveur** | Position, vitesse, date projetée, risque, besoin d'examen, « Stable », points à renforcer | fonctions de lecture par classe et par élève ; réglages | Scénarios SQL dans la CI, puis le directeur voit les chiffres d'une classe d'essai |
| **C5, vue direction** | Liste des classes triée par risque, filtres, détail élève | écran direction (liste) | Le directeur trouve en 10 secondes la classe en retard |
| **C6, vue famille et élève** | Étape, date limite, rythme, travail, rattrapage après absence | `progression_famille` étendue ; écrans famille et élève | Le directeur, en tuteur d'essai, lit l'étape et la date limite de l'enfant |
| **C7, examen proposé** | Le serveur propose, l'enseignant confirme, l'administration planifie | `evaluations` ; carte de l'enseignant ; liste de la direction | Une classe d'essai arrivée en fin de plage fait apparaître la proposition |
| **C8, emploi du temps de révision** | Tiré des devoirs structurés, imprimable | `learning_assignment` ; écran famille | Le directeur imprime l'emploi du temps d'un élève d'essai |

**Ordre recommandé : C0, puis C1 tout de suite** (il sert le remplaçant dès cette semaine, sans attendre le contenu du programme), puis C2, C3, C4, puis C5 à C8.

**Ce que la stratégie ne règle pas seule.** Tant que le livre de lecture Rewayah n'a pas ses lignes numérotées en base, la position et la vitesse des étapes 1 à 3 restent approximatives (page présentée sans ligne). Le Coran de l'étape 4 et au-delà est déjà numéroté (sourate, verset, page).

---

## Sources publiques (consultées le 05/11/2026)

- Khan Academy, calcul du pourcentage de maîtrise : https://support.khanacademy.org/hc/en-us/articles/48411237993357-How-is-my-mastery-percentage-calculated
- Khan Academy, suivre la maîtrise d'une classe : https://support.khanacademy.org/hc/en-us/articles/360031123551-How-can-I-monitor-Mastery-progress-
- Kumon, comprendre la progression de l'élève : https://www.kumon.com/resources/understanding-student-progress-in-kumon-what-to-look-for-and-where-to-find-it/
- Kumon Connect : https://www.kumon.com/resources/how-kumon-connect-works/
- Brightwheel, rapports de progression : https://mybrightwheel.com/blog/preschool-progress-report
- Brightwheel, rapport quotidien : https://mybrightwheel.com/preschool-daily-report/
- Outschool, outils d'IA pour les enseignants (résumé relu ou envoyé seul après 4 heures) : https://support.outschool.com/en/articles/9655399-outschool-s-ai-tools-for-teachers
- ClassDojo Tutor, résumés de séance : https://tutor-help.classdojo.com/hc/en-us/articles/33653998401037-Session-Summaries
- Duolingo, comment apprendre avec le chemin : https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo
- Duolingo, le score de progression : https://blog.duolingo.com/duolingo-score/
- Ce que la série de jours ne prouve pas (Android Authority) : https://www.androidauthority.com/reasons-give-up-duolingo-streak-3543009
- Busuu, le plan d'étude et sa date prévue : https://blog.busuu.com/new-feature-study-plan-achieve-language-learning-goals/
- Busuu, aide sur le plan d'étude : https://help.busuu.com/hc/en-us/articles/16097312171153-What-s-a-Study-Plan-How-do-I-make-one
- Busuu, méthode (chapitres et tests de passage) : https://business.busuu.com/our-method
- Preply, compte rendu de leçon : https://help.preply.com/en/articles/8800590-lesson-insights-experiment
- Preply, comment l'IA produit ce compte rendu : https://preply.com/en/blog/part-ii-how-preply-uses-ai-to-give-you-personalized-lesson-insights
- Toddle, plateforme de classe (observations rattachées aux objectifs) : https://www.toddleapp.com/independent-schools/
- Tarteel, fiche de magasin : https://apps.apple.com/us/app/-/id1391009396

Les descriptions de Tarteel, Toddle, Brightwheel et Preply viennent de leurs propres pages : ce sont en partie des textes de vente, non vérifiés en usage. Les carnets de hifz consultés d'abord (Manzil, Sabaq, Hifz Tracker) sont écartés sur précision du directeur du 05/11.
