# La prière à l'heure : décision et contrat (lot PRIERE-1)

> **EN VIGUEUR par arbitrage de l'architecte pédagogique (12/11/2026), sur délégation du directeur. Le directeur peut corriger toute règle à tout moment ; une correction datée de sa part l'emporte.**

## À valider par le directeur (lecture en cinq minutes)

Tout ce qui suit est **en vigueur par défaut**, posé par l'architecte pédagogique ; le directeur le confirme ou le change dans Configuration > Règles > La prière, sans code. Détail : §6.

1. **Méthode de calcul : Ligue islamique mondiale** (Fajr 18°, Isha 17°). Modifiable pour toute l'académie, ou pour un enseignant.
2. **Asr : selon la majorité des écoles** (ombre égale à la hauteur de l'objet). L'autre choix : ombre double (école hanafite).
3. **Prière du vendredi : plage de 12 h 30 à 14 h 30**, heure de l'enseignant ; le réglage « assiste à la prière du vendredi » est faux par défaut et posé par la direction.
4. **Durées : 10 minutes** de pause (de 5 à 20 par pas de 5), **20 minutes pour le Maghrib du Ramadan** ; marges de 5 minutes au début et de 15 minutes à la fin du cours.
5. **La règle « prière qui se ferme »** (arbitrée le 13/11/2026) : une prière entrée **moins de 20 minutes avant le cours** et dont le temps se ferme pendant le cours porte la pause, qui commence **10 minutes après le début** du cours ; elle passe avant la prière qui entre pendant le cours ; entrée 20 minutes ou plus avant : aucune pause. Les **deux réglages** sont `priere.marge_avant_cours_minutes` (20) et `priere.delai_fermeture_minutes` (10).
6. **Zéro saisie (PRIERE-2, 13/11/2026)** : l'enseignant partage sa position d'un toucher (« Utiliser ma position »), arrondie à environ un kilomètre ; **la méthode suit le pays du lieu** pour neuf pays (liste et justification ligne par ligne au § 3 ter), la méthode de l'académie ailleurs ; la direction lit une liste et ne corrige qu'une exception. Le directeur valide une phrase (« méthode selon le pays », activée) : il ne remplit rien.
7. **Rappel du Ramadan 2027** : mettre `priere.ramadan_en_cours` à **vrai vers le 8 février 2027**, puis à **faux vers le 9 mars 2027** (à la main, aucun calendrier n'est branché).

**Ordre d'installation. PRIERE-1 (installée) : la migration `20261123930000_priere_serveur.sql` AVANT la fusion. PRIERE-2 : la migration `20261124500000_priere_zero_saisie.sql` AVANT la fusion de la branche (voir § 3 ter).**
- Migration d'abord : l'ancienne application ne lit que sa propre ligne `prayer_settings` (aucune en production) et n'écrit rien ; elle ne voit aucun changement, jamais une erreur.
- Fusion d'abord, base non migrée : la nouvelle application appelle des fonctions qui n'existent pas encore ; l'enseignant voit le bandeau d'échec partiel de sa journée et les écrans de prière leur état d'erreur (textes, jamais un message brut), l'élève ne voit simplement pas la pause, la section « La prière » des Règles reste cachée, jusqu'à l'installation.
- Un seul bloc dans l'éditeur SQL : oui, 98 Ko, 2 097 lignes, ni `BEGIN` ni `COMMIT` (l'éditeur l'envoie en une requête, donc une seule transaction : tout passe ou rien ne change) ; **pas rejouable** : un second collage s'arrête à la première création déjà faite et ne change rien.

Ce que le directeur n'a pas à décider ici : le calcul des heures (prouvé contre le paquet `adhan`, écart 0 minute) et la protection des données (la position d'un enseignant n'est lue que par lui et la direction ; aucune pratique religieuse n'est écrite au journal).


**La demande du directeur (12/11/2026, résumé fidèle).** Permettre de prier à l'heure : au minimum l'enseignant de la salle, qui est seul et dans une zone connue de l'académie ; les élèves sont dans des zones éloignées. Trouver un schéma stable pour commencer et finir les cours en évitant les prières, surtout le Maghreb et l'Ichâ, dont l'heure change avec la saison. L'académie doit fonctionner seule, sans lui. Il avait demandé un outil d'heures de prière il y a plus de deux mois.

Les valeurs chiffrées sont dans `REGLAGES.md` (partie 8, « La prière »), qui fait foi ; les arbitrages sont au registre (`ARBITRAGES.md`, partie 10, C34 à C45). Ce document dit la décision, le contrat avec la salle, ce qui reste à valider et ce qui reste à faire.

## 1. Ce que l'existant faisait, et pourquoi il ne servait pas (mesuré le 12/11/2026, lecture seule de la production)

- La table `prayer_settings` existe depuis la migration 0005 : **0 ligne**, et **aucun écran ne l'écrit** (le service d'enregistrement n'est appelé nulle part). Le module `lib/core/priere/` existe mais ne peut pas servir.
- Le calcul des heures était fait **dans l'application**, à partir du lieu de l'enseignant seulement, avec le paquet Dart `adhan`. Les élèves et les tuteurs pouvaient lire la position de l'enseignant (politique `prayer_settings_parties_read`) : c'est une donnée personnelle qui ne devait pas leur être ouverte.
- Une seule enseignante, pays Guinée, mais fuseau enregistré Europe/Paris : **incohérence signalée à la direction, jamais corrigée automatiquement.** 2 classes actives à 19 h (fuseau Europe/Paris) : une d'adultes de 90 minutes, une d'enfants de 60 minutes. Tous les foyers en Europe/Paris ; ni pays ni ville pour les élèves.

## 2. Les arbitrages de l'architecte (en vigueur, à lire tels quels)

**P1. Principe.** L'académie n'oblige jamais personne à choisir entre son cours et sa prière. Trois protections : prévenir à la création du créneau ; la pause de la séance placée à l'heure de la prière ; un retrait individuel de l'élève (ce dernier point est hors de ce lot : il se fera dans la salle, sans motif enregistré).

**P2. Une seule source des heures de prière : le serveur.** Calcul astronomique déterministe, sans IA et sans service externe, en SQL. L'application ne calcule plus rien elle-même : les écrans existants lisent le serveur (un seul chiffre partout).

**P3. **[Amendé le 13/11/2026, PRIERE-2 : voir § 3 ter ; l'enseignant partage sa position d'un toucher, la direction garde le pouvoir de corriger.]** Le lieu de prière de l'enseignant est fixé par la direction** (nom du lieu, latitude, longitude, fuseau), parce que les zones des enseignants sont connues de l'académie ; l'enseignant peut le lire et ajuster chaque prière de −30 à +30 minutes (bornes existantes). La méthode de calcul et l'école pour l'Asr sont des réglages de la direction : valeur par défaut pour toute l'académie (réglage `app_config` ; défaut : Ligue islamique mondiale, Asr selon la majorité des écoles), surchargeable par enseignant. **Ces deux choix relèvent du fiqh : valeur par défaut en vigueur, à valider par le directeur et ses associés.**

**P4. Une seule pause par séance.** Quand une prière ENTRE pendant la séance pour l'enseignant, la pause de la séance est placée à l'entrée de cette prière. Sinon la pause reste où la salle la place (après le milieu). Si deux prières entrent pendant la même séance, la pause va à la première dont la fenêtre est courte (le Maghreb d'abord) ; l'autre se prie après le cours. **[Amendé le 13/11/2026 : la pause va à la première dans l'ordre du temps qui n'est pas en zone de fin ; voir §3, point 4.]**

**P5. Durée de la pause de prière :** réglage de la direction, 10 minutes par défaut (bornes 5 à 20, par pas de 5) ; pendant le Ramadan, pour le Maghreb (rupture du jeûne) : 20 minutes par défaut. Le Ramadan est connu par le calendrier de l'académie (un autre lot le construit) : dans ce lot, un seul réglage booléen `priere.ramadan_en_cours`, posé par la direction, faux par défaut.

**P6. Bornes.** Si la prière entre dans les 5 premières minutes, la pause est placée à 5 minutes du début ; si elle entre dans les 15 dernières minutes, aucune pause de prière n'est prévue (l'enseignant prie à la fin du cours) et la pause ordinaire s'applique. Valeurs en réglages.

**P7.** La pause de prière ne réduit ni la présence ni la paie (c'est déjà la règle de la pause) et ne prolonge pas la séance : l'heure de fin reste celle annoncée aux familles.

**P8. Le schéma stable des horaires, côté direction.** Pour un créneau donné (jour, heure, fuseau, durée) et un enseignant, le serveur calcule sur les 12 mois à venir combien de séances croisent l'entrée d'une prière, laquelle, et sur quelles périodes (« ce créneau croise le Maghreb de l'enseignant de novembre à mars, 40 séances »). Il liste aussi, pour un enseignant et un jour, les heures de début qui ne croisent aucune prière de toute l'année (« créneaux sans prière »). C'est un **avertissement** montré à la direction, jamais un blocage : une petite école garde sa liberté, et la pause de prière protège de toute façon. Le calcul tient compte du changement d'heure du fuseau de la classe (l'heure locale de la classe est fixe, donc l'heure chez l'enseignant bouge deux fois par an).

**P9. Vendredi.** Réglage par enseignant « assiste à la prière du vendredi » (faux par défaut ; la direction le pose) et une plage en heure locale de l'enseignant (défaut 12 h 30 à 14 h 30, réglable). Si le réglage est vrai, un créneau qui chevauche cette plage le vendredi est signalé en avertissement fort à la direction ; pas de blocage automatique. **À valider par le directeur et ses associés.**

**P10. Les élèves.** Dans ce lot, aucune donnée de lieu n'est demandée aux familles et aucun calcul par élève. Ils voient seulement, avant et pendant le cours, « Pause de prière à HH:MM » dans leur fuseau. La carte des croisements par élève est un lot ultérieur.

**P11. Mot affiché :** « Pause de prière » (ar : « استراحة الصلاة »). Noms des prières, en français courant, tels qu'ils existent déjà dans les textes de l'application (`priere.*`) : Fajr, Dhuhr, Asr, Maghrib, Isha (l'usage en place est gardé ; ni « Maghreb » ni « Ichâ » n'étaient écrits dans les textes).

## 3. Comment le serveur place la pause (règle unique)

Pour une séance qui commence en `s`, finit en `e` (durée `L` minutes), avec l'enseignant qui enseigne réellement (le titulaire, ou le remplaçant accepté) :

1. Il lit le lieu, la méthode, l'école d'Asr et les ajustements de cet enseignant. **Sans lieu, aucune ligne.**
2. Il calcule les cinq heures d'entrée sur les trois jours civils qui entourent la séance, et retient les prières dont l'entrée `t` tombe dans `[s, e)`. Aucun croisement ne passe par une heure locale : tout est comparé en instants absolus.
2 bis. **Priere qui se ferme (ARBITRÉ le 13/11/2026, à valider par le directeur avec les autres points de fiqh).** Une prière entrée **moins de `priere.marge_avant_cours_minutes`** (20) avant `s`, dont le **temps se ferme avant `e`** (lever du soleil pour le Fajr ; entrée de la prière suivante pour les autres), porte la pause : début `s + priere.delai_fermeture_minutes` (10), durée habituelle (20 pour le Maghrib en Ramadan). Elle **prime** sur la prière qui entre pendant la séance (celle-ci a tout son temps après le cours) : toujours une seule pause par séance. Entrée 20 minutes ou plus avant `s` : aucune pause (chacun avait le temps). Si la pause de la prière qui se ferme ne tient pas (avant la fin, marge de fin), la règle ordinaire reprend. Les gardes-fous restent : pause dans la séance, marge de fin, durée 5/10/15/20.
3. Pour chacune, `o = t − s`. Si `o` est dans les 5 premières minutes, la pause est placée à `s + 5 min`. Si `o` dépasse `L − fin_marge`, la prière est écartée : l'enseignant prie à la fin du cours. Sinon la pause est placée à `t`.
4. S'il reste plusieurs prières, **la première dans l'ordre du temps qui n'est pas en zone de fin** l'emporte (amendé le 13/11/2026 sur la revue indépendante : « la fenêtre la plus courte » faisait manquer la première, dont la fenêtre se ferme à l'entrée de la seconde, donc dans la séance). Même logique que la prière qui se ferme : celle qui serait perdue passe d'abord, une seule pause.
5. La durée est celle du réglage (10 minutes) ; 20 minutes pour le Maghrib quand `priere.ramadan_en_cours` est vrai. La pause ne dépasse jamais l'heure de fin de la séance : la marge de fin est au moins égale à la durée de la pause (voir « Choix pris seul », n° 1).
6. Résultat : une ligne dans `seance_pause_prevue`, ou aucune.

**Cas non défini.** Aux très hautes latitudes, le soleil peut ne jamais se lever ni se coucher (jour polaire, nuit polaire) : le calcul n'existe pas. Le serveur ne devine rien : il **ne place aucune pause de prière** pour cette séance et écrit une ligne au journal de la direction (`log_sensitive_access`, action `priere_calcul_indefini`). Quand seuls le Fajr ou l'Isha ne se définissent pas par leur angle (été, latitudes moyennes et hautes), le calcul retombe sur la règle de la nuit partagée en deux, la même que celle du paquet de référence ; l'heure est alors marquée **approchée** (aperçu de la direction, journal), et la pause est placée quand même. Sur les latitudes où l'académie est présente aujourd'hui (Guinée), aucun de ces cas ne se produit.

## 3 ter. PRIERE-2 : la prière sans formulaire (amendement de P3, 13/11/2026)

**Le retour du directeur** (13/11/2026, en ouvrant « Lieux de prière », un mur de boutons radio) : « Je ne vais jamais remplir ces formulaires moches et anciens. Si l'app ne peut pas calculer elle-même tout ça alors à toi de régler cela. » **Arbitré : l'application calcule tout ; personne ne remplit de formulaire ; la direction lit et, rarement, corrige une exception.**

**P3 amendé.** Le lieu n'est plus fixé par la direction seule. Qui a posé le lieu est enregistré (`prayer_settings.lieu_source`) :

- **`enseignant`** : l'enseignant touche « Utiliser ma position » (`priere_ma_position`, réservée à l'enseignant connecte, pour lui-même : aucun paramètre ne désigne une autre personne ; refus de l'élève, du tuteur, de la direction, de l'anonyme, et de tout mineur). Le serveur **arrondit latitude et longitude au centième de degré** (environ un kilomètre) avant d'écrire : la position exacte n'est ni stockée ni affichée ; il reçoit le fuseau IANA de l'appareil (vérifié), donne le nom « Votre position, fuseau Africa/Conakry » (aucun service externe) et recalcule aussitôt les pauses. Journal : qui et quand, jamais la position. Refus de géolocalisation ou échec : « Position non partagée. Vous pouvez réessayer, ou la direction posera votre lieu. » ; jamais un formulaire de coordonnées pour l'enseignant. La lecture de la position passe par l'API du navigateur (`dart:js_interop`, aucun paquet, aucun secret) ; hors web, la lecture n'est pas disponible et l'écran le dit.
- **`direction`** : posé à la main (réglage avancé de la feuille « Corriger », replié par défaut). **Il n'est jamais écrasé** ni par l'enseignant (refus « lieu posé par la direction »), ni par l'automatique. La direction garde son pouvoir de corriger et de retirer.
- **`auto`** : posé depuis la ville de l'enseignant (lot HORLOGE-ET-LIEU). `private.priere_lieu_auto(p_enseignant, p_nom, p_lat, p_lng, p_fuseau)` ne pose le lieu que si la direction n'en a pas posé un à la main **et** si l'enseignant n'a pas partagé sa propre position (la sienne, plus précise, l'emporte : choix pris seul, voir la fiche) ; elle remplace un lieu `auto` plus ancien (changement de ville) et rend vrai quand elle a posé.

**Le lot HORLOGE-ET-LIEU pose lui-même le déclencheur `lieux_priere_auto` sur `public.lieux`** (lieux d'enseignant seulement, erreur avalée) : il relaie vers `private.priere_lieu_auto(p_enseignant uuid, p_nom text, p_lat numeric, p_lng numeric, p_fuseau text)` **si elle existe** ; ce lot ne pose donc aucun `CREATE TRIGGER` du même nom (il échouerait « already exists »), et ne livre plus aucune fonction de déclencheur (pas de code mort).

**Le rattrapage des villes déjà enregistrées (demande de l'architecte).** Si `public.lieux` existe à l'installation de la migration (ordre « horloge avant »), `private.priere_rattraper_villes()` appelle une fois `private.priere_lieu_auto` pour chaque ville **d'enseignant** (`profil_id` non nul ; une ville de foyer n'est jamais lue), jamais par-dessus un lieu posé par la direction ou par l'enseignant (la fonction le refuse), l'erreur d'une ligne est avalée avec un avertissement et les autres passent. Les colonnes lues sont celles de `20261123943000_lieux.sql` du lot horloge (`profil_id`, `ville`, `latitude`, `longitude`, `fuseau_iana`), lues par SQL dynamique : sans la table, la fonction rend 0 et rien ne se passe. Prouvé : (1) scénario SQL committé (deux villes d'enseignants, un foyer, un élève, un lieu de la direction, la position partagée d'un enseignant, une ville invalide, rejeu) ; (2) ordre réel sur Postgres nu, `public.lieux` créée avec les colonnes du lot horloge avant la migration : 2 lieux posés en `auto`, le lieu de la direction intact (les lieux déjà posés avant la migration gardent `lieu_source = 'direction'` par défaut).

Si `public.lieux` existe sans ce déclencheur à l'installation de la migration, elle l'écrit dans un avis (`NOTICE`) et ne pose rien. La fonction `private.priere_lieu_auto` est `SECURITY DEFINER`, `search_path` vide, sans droit pour `authenticated`, `anon` ni `PUBLIC` ; elle valide les bornes et le fuseau et rend faux sans rien écrire si l'un est invalide.

**La méthode suit le pays du lieu** (`priere.methode_selon_pays`, vrai par défaut ; le pays se déduit du fuseau du lieu, jamais d'une saisie). Ordre : surcharge de la direction, puis méthode usuelle du pays, puis méthode de l'académie (Ligue islamique mondiale). Neuf fuseaux seulement, chacun justifié par la documentation du paquet `adhan` qui nomme la méthode d'après l'institution ou la région du pays :

| Fuseau | Pays | Méthode | Justification |
|---|---|---|---|
| `Asia/Riyadh` | Arabie saoudite | Umm al-Qura | « Umm al-Qura University, Makkah » : l'institution du pays |
| `Asia/Qatar` | Qatar | Qatar | la méthode porte le nom du pays |
| `Asia/Kuwait` | Koweït | Koweït | la méthode porte le nom du pays |
| `Asia/Dubai` | Émirats arabes unis | Golfe (Dubaï) | « The Gulf Region » |
| `Africa/Cairo` | Égypte | Autorité générale égyptienne | « Egyptian General Authority of Survey » |
| `Asia/Karachi` | Pakistan | Karachi | « University of Islamic Sciences, Karachi » |
| `Asia/Singapore` | Singapour | Singapour | la méthode porte le nom du pays |
| `Europe/Istanbul` | Turquie | Turquie (Diyanet) | l'autorité religieuse du pays |
| `Asia/Tehran` | Iran | Téhéran | « Institute of Geophysics, University of Tehran » |

Non déduites, et pourquoi : l'Amérique du Nord (la méthode ISNA est dite « non recommandée » par le paquet lui-même) ; le Moon Sighting Committee (ce n'est pas un pays). Tout autre fuseau, dont la Guinée et la France : la méthode de l'académie. **Valeur en vigueur, à valider par le directeur** : il valide une phrase, il ne remplit rien. Le réglage se coupe d'un interrupteur (Configuration > Règles > La prière) : la méthode de l'académie reprend partout.

**L'écran de la direction, refait.** « Lieux de prière des enseignants » est une liste à lire : par enseignant, sa zone (nom) et d'où vient le lieu, ses cinq heures du jour, la méthode appliquée et son origine (choisie par la direction, usuelle du pays, ou celle de l'académie), et, sans lieu, « En attente : l'enseignant n'a pas encore partagé sa position ». Aucun champ visible. Une seule action secondaire par ligne, « Corriger », qui ouvre une feuille courte : le vendredi par un interrupteur (les heures seulement s'il est activé), un seul bouton plein, et sous « Réglage avancé » (replié) la méthode (menu compact, « Automatique » par défaut), l'école d'Asr et la pose du lieu à la main. La correction (`priere_corriger`) ne change ni la position ni la source du lieu ; le journal garde « réglage corrigé », jamais la valeur. La liste de la direction (`priere_enseignants_vue`) ne rend aucune coordonnée. La section « La prière » des Règles : des phrases et des interrupteurs (méthode selon le pays, Ramadan), les valeurs chiffrées repliées.

**Ordre d'installation de PRIERE-2.** La migration `20261124500000_priere_zero_saisie.sql` **avant** la fusion. Migration d'abord : l'application de PRIERE-1 (en production) appelle `priere_enseignants_liste`, `priere_lieu_definir` et `priere_reglages_lire`, qui existent toujours avec la même forme ; elle ne voit rien changer. Fusion d'abord, base non migrée : la nouvelle application appelle `priere_ma_position`, `priere_enseignants_vue` et `priere_corriger`, absentes ; l'enseignant voit « Il est possible que votre position ne soit pas parvenue jusqu'à Rewayah » et la direction l'état d'erreur de sa liste (des textes, jamais un message brut), et la section des Règles reste cachée tant que la clé `priere.methode_selon_pays` manque.

## 3 bis. La prière dont le temps se termine pendant la séance (arbitré le 13/11/2026)

Constat du 13/11 (avant l'arbitrage, figé puis remplacé) : le serveur ne regardait que l'entrée d'une prière dans la séance, donc le Fajr dont le temps se ferme au lever du soleil pendant un cours n'avait aucune pause, et la pause d'une prière qui se ferme à l'entrée de la suivante était celle de la suivante. **L'architecte a tranché (règle 2 bis ci-dessus)**, scénarios de la section 9 de `scenarios_priere_serveur.sql` :

- Fajr entré 10 minutes avant un cours qui enjambe le lever du soleil : pause du Fajr, à `s + 10`.
- Maghrib entré 5 minutes avant un cours de 90 minutes où l'Isha entre : une seule pause, celle du Maghrib ; l'Isha a tout son temps après.
- Maghrib entré 30 minutes avant : aucune pause du Maghrib ; la pause de l'Isha s'il entre pendant le cours.
- Dhuhr entré 10 minutes avant un cours où l'Asr entre : pause du Dhuhr. Maghrib entré 5 minutes avant un cours de 45 minutes où l'Isha n'entre pas : aucune pause (le temps ne se ferme pas pendant le cours).
- Le lever du soleil est calculé par le serveur comme `adhan` le calcule (écart 0 minute sur la matrice de référence, ajustements de méthode compris : Dubaï −3, Turquie −7).
- **Lecture pour la direction** : `public.priere_creneaux_fermeture(enseignant, jour, fuseau, durée)` rend les heures de début où, au moins une fois sur 12 mois, une prière se ferme pendant le cours ; la lecture d'un créneau porte la même liste (`heures_fermeture`). Les « heures sans prière » excluent désormais ces heures. Elle servira le lot FC-3 pour déconseiller ces créneaux ; son branchement dans l'écran n'est pas fait ici.
- Ce que le système ne sait toujours pas : si l'enseignant a déjà prié.

## 4. Le contrat avec la salle (livré exactement)

`public.seance_pause_prevue` (lecture seule pour la salle) :

| Colonne | Type | Sens |
|---|---|---|
| `session_id` | uuid, clé | la séance |
| `debut_prevu_utc` | timestamptz | début de la pause de prière |
| `duree_minutes` | int | 10 par défaut ; 20 pour le Maghrib du Ramadan |
| `motif` | text | `priere` dans ce lot |
| `priere` | text | `fajr`, `dhuhr`, `asr`, `maghrib`, `isha` |
| `calcule_le` | timestamptz | quand le serveur l'a calculée |

- **Aucune ligne quand aucune prière n'entre pendant la séance.** Aucun droit direct (RLS activée, tous les droits retirés à `anon` et `authenticated`).
- **Lecture : `public.pause_prevue_seance(p_session_id uuid)`**, qui rend `debut_prevu_utc`, `duree_minutes`, `motif`, `priere` à la direction, à l'enseignant de la séance (titulaire ou remplaçant accepté), aux élèves de la classe et à leur foyer ; **jamais un lieu**. Refus pour tout autre : étranger, anonyme, élève d'une autre classe.
- **Remplissage par le serveur** : à la création ou au changement d'heure d'une séance ; au changement du lieu ou des réglages de prière de l'enseignant ; au changement des réglages de l'académie `priere.*` ; au changement d'enseignant de la séance (remplacement : la pause suit le lieu de celui qui enseigne réellement) ; par un recalcul planifié chaque nuit pour les séances des 14 prochains jours.
- **Stockage (choix pris seul, n° 2).** Pour ne retirer aucune ligne par un `DELETE` (la migration n'en contient aucun), la donnée est stockée dans `seance_pause_prevue_stock` (colonne `retiree_le`) ; `seance_pause_prevue` est une **vue** qui ne montre que les lignes non retirées. Pour la salle, c'est une table en lecture : `select … from public.seance_pause_prevue where session_id = …` ne rend aucune ligne quand aucune prière n'entre.
- **Qui peut lire le stock et la vue (exigence de l'architecte, 12/11/2026).** `seance_pause_prevue_stock` et la vue `seance_pause_prevue` appartiennent à `postgres` ; aucune ligne d'ACL autre que celle du propriétaire (donc rien pour `PUBLIC`, `anon`, `authenticated`, `service_role`, `agent_ro`), prouvé par `has_table_privilege` sur chaque droit et par la liste des ACL. Le stock a la RLS et aucune politique. La vue n'est **pas** `security_invoker` : elle lit avec les droits de son propriétaire, ce qui n'ouvre aucune porte autour de la RLS du stock puisque personne d'autre n'a de droit sur la vue ; seules des fonctions SECURITY DEFINER propriétaires de `postgres` la traversent (`pause_prevue_seance`, qui décide qui lit, et le déclencheur de la salle). Le contrôle final de la migration refuse l'installation si le propriétaire, un droit ou `security_invoker` s'écarte de ce schéma.
- **Bornes exigées par la salle.** `duree_minutes` est 5, 10, 15 ou 20 (CHECK du stock : entre 5 et 20 ET multiple de 5 ; les réglages de la direction ont les mêmes bornes, refus de 7, 12, 25). `debut_prevu_utc` n'est jamais avant le début prévu et `debut_prevu_utc + durée` jamais après la fin prévue : une pause de 20 minutes dont la prière entre 16 minutes avant la fin ne tient pas, donc **aucune ligne**. Prouvé sur toutes les lignes du contrat, en Ramadan comme hors Ramadan.
- **Ce que fait la salle de cette ligne (écrit ici à sa demande).** Au passage de la séance à `in_progress`, un déclencheur SECURITY DEFINER lit `select p.debut_prevu_utc, p.duree_minutes, p.motif from public.seance_pause_prevue p where p.session_id = $1 order by p.debut_prevu_utc limit 1` et copie l'heure, la durée et le motif dans `pause_seances`. Une erreur de lecture ne retarde jamais le début d'une séance. Si l'enseignant commence après l'heure de la ligne, la salle propose la pause tout de suite tant qu'elle tient avant la fin prévue. La pause de prière est déclenchée par l'écran de l'enseignant (aucune minuterie serveur) ; la prière prime même si la classe a coupé sa pause ordinaire. L'emboîtement (priere + salle) est prouvé par `supabase/tests/scenarios_priere_emboitement_salle.sql`, qui se déclare « sauté » tant que la migration de la salle n'est pas installée.
- Ce lot ne touche à aucun objet `pause_*` (tables, fonctions, déclencheurs) : la salle lira cette table depuis son propre déclencheur. La fonction `pause_prevue_seance` porte le nom exigé par le contrat ; elle est neuve et n'en remplace aucune.

## 4 bis. L'heure de l'académie et le fuseau de la classe (précision de l'architecte, 12/11/2026)

L'heure de l'académie devient l'heure de La Mecque (lot HORLOGE-ET-LIEU : les créneaux de classe seront enregistrés en `Asia/Riyadh`, sans changement d'heure). Ce lot **ne suppose jamais** que le fuseau d'une classe est celui des familles ni celui de l'enseignant : le calcul part de l'instant réel (UTC) de la séance et du lieu de l'enseignant qui enseigne. Les croisements sur 12 mois sont testés avec une classe en `Europe/Paris` ET en `Asia/Riyadh` : même instant réel, même lecture ; avec `Asia/Riyadh` et un enseignant sans changement d'heure (Conakry), un créneau sans croisement le reste toute l'année et un créneau qui croise le Maghrib le croise à chaque séance (le « schéma stable » voulu par le directeur) ; avec `Europe/Paris` des séances d'été ne croisent plus rien. Le lieu de prière fixé par la direction peut être prérempli plus tard depuis la ville de l'enseignant (lot HORLOGE-ET-LIEU, branché par l'architecte) : la table et l'écran reçoivent déjà un lieu rempli ; aucune table de ce lot-là n'est lue ici.

## 4 ter. Dans la salle : le retrait individuel de l'élève (règle arrêtée, construite par la session de la salle)

Règle finale, écrite ici pour mémoire : geste neutre « Je m'absente un instant » ; l'élève qui reste dans l'application ne laisse aucune trace (ni rapport, ni journal, ni durée, ni motif) ; s'il quitte l'application pendant le retrait, la sortie est consignée comme toute autre, sans motif et sans mention du retrait ; seule la coupure après 30 secondes est suspendue pendant le retrait ; durée maximale en réglage (10 minutes par défaut), une fois par séance par défaut. Ce lot ne construit rien de cela.

## 5. Les lectures de la direction

- **Croisements d'une classe sur 12 mois** : pour chaque créneau de la classe, chaque prière croisée, ses périodes consécutives (« de novembre à mars »), le nombre de séances, combien auront une pause de prière placée et combien la verront tomber dans les dernières minutes (l'enseignant prie après le cours).
- **Heures sans prière** d'un enseignant pour un jour de la semaine, dans le fuseau de la classe : les heures de début qui ne croisent aucune entrée de prière sur toute l'année.
- **Vendredi** (P9) : si l'enseignant « assiste à la prière du vendredi », le nombre de séances de l'année qui chevauchent sa plage, en avertissement fort.
- **Incohérences d'un enseignant** : le fuseau du compte diffère du fuseau du lieu de prière ; le fuseau du lieu de prière ne correspond pas à sa longitude ; le pays du compte ne correspond pas au lieu de prière ; le pays du compte ne correspond pas à son propre fuseau, **même quand aucun lieu n'est posé** (le cas relevé en production : pays Guinée, fuseau Europe/Paris). Signalement seulement : rien n'est corrigé automatiquement. Le contrôle du pays est un contrôle de vraisemblance (vingt pays connus) : un pays hors table ne produit aucun signal.

## 6. Ce qui est « à valider par le directeur et ses associés »

Valeurs en vigueur par défaut, à valider ; la direction peut les changer sans code :

1. **Méthode de calcul de l'académie : Ligue islamique mondiale** (Fajr 18°, Isha 17°). Surchargeable par enseignant.
2. **École pour l'Asr : selon la majorité des écoles** (ombre égale à la hauteur de l'objet). Surchargeable par enseignant.
3. **Plage de la prière du vendredi : 12 h 30 à 14 h 30**, heure de l'enseignant, et le réglage « assiste à la prière du vendredi » (faux par défaut, posé par la direction).
4. **Durées** : 10 minutes (5 à 20, par pas de 5) ; Maghrib du Ramadan 20 minutes.
5. **Bornes** : 5 minutes au début, 15 minutes à la fin.
6. **Repli de haute latitude** (nuit partagée en deux) quand l'angle ne se définit pas.
7. **Règle de la prière qui se ferme** (§3, 2 bis) : marge de 20 minutes avant le cours, pause à 10 minutes après son début. ARBITRÉ par l'architecte le 13/11/2026, à faire valider avec les autres points de fiqh.

## 6 bis. Rappels datés pour le directeur

- **Ramadan 2027 : basculer `priere.ramadan_en_cours` à la main** (Configuration > Règles > La prière) : **vrai vers le 8 février 2027, retour à faux vers le 9 mars 2027** (dates de l'architecte, à confirmer sur le calendrier de l'académie ; le réglage n'est pas branché sur un calendrier). Tant qu'il est vrai, la pause du Maghrib dure 20 minutes.

## 6 ter. Dettes nommées de ce lot (revue du 13/11/2026)

- **L'export des données personnelles** (`mes_donnees_export`) ne contient pas les colonnes neuves de `prayer_settings` (surcharges de méthode et d'école, vendredi, lieu actif, ajustements) : quatre lots redéfinissent cette fonction ; la recopier ici reviendrait à écraser ou à perdre leurs changements selon l'ordre de fusion. À faire par un lot qui reprend la définition la plus récente de `main`.
- **Une ligne `prayer_settings` retirée à la main en SQL** (hors anonymisation) n'est reprise qu'au recalcul de nuit : un déclencheur sur l'effacement ne peut pas s'écrire sans le mot que le serveur Supabase fait confirmer. Le cas du compte désactivé ou anonymisé est couvert tout de suite (déclencheur sur le statut du profil, qui précède le retrait des réglages).

## 7. Ce qui reste pour les lots suivants

- **Le retrait individuel de l'élève dans la salle** (P1, troisième protection), sans motif enregistré.
- **La carte des croisements par élève** (P10) : lieu de l'élève, donnée demandée aux familles avec leur accord.
- **Le Ramadan branché sur le calendrier de l'académie** : aujourd'hui, un réglage booléen posé à la main.
- **La prière dont le temps se termine pendant la séance** : traitée depuis le 13/11/2026 (§3, 2 bis, et §3 bis). Reste à brancher la liste des créneaux concernés dans la création d'une classe (lot FC-3).
- **L'avertissement à la création d'un créneau** (P1, première protection) : les lectures de la direction existent ; leur branchement dans le parcours de création d'une classe est un lot suivant.
- **Le nettoyage de `lib/core/priere/`** (calcul local désormais inutilisé) : autre lot ; aucun fichier n'est supprimé ici.
