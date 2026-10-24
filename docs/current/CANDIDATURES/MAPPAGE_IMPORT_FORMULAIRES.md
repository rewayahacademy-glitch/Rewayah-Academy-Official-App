# CANDIDATURES · Mappage des formulaires Google vers la candidature (proposition)

**Statut :** `spécifié` seulement, **proposition non décidée**. Préparé comme la
spécification le demande pour l'import (§9 : « préparer le parcours frontend et
documenter le contrat attendu »). Il sert d'entrée par défaut à l'étape
« association des colonnes » d'`ADM-23` et au contrat `PortImportCandidatures`
(`CONTRAT_PORTS_CANDIDATURES.md`, section 2). Ce document ne contient **que** des
en-têtes de colonnes et des libellés d'options de formulaire, jamais une réponse
d'une personne.

**Dépend de :** `CAND-Q02` et `CAND-Q03` (l'import existe-t-il, et la candidature
commence-t-elle avant l'invitation), `CAND-Q13` (arabe), `CAND-Q15` (langues
enregistrées par leur code), `CAND-Q16` (doublons).

**Mis à jour le 22/10/2026** selon les réponses du directeur sur le questionnaire de la
Salle d'examen (`DECISION-CANDIDATURES-2026-10-21.md`, section 1 ter ; version
`salle-examen-1`, `supabase/migrations/20261022000000_cand_l2a1_moteur_salle_examen.sql`,
C17) : poular, peul et fulfulde ne font qu'une langue, le code `poular` (plus de `ff`) ;
l'arabe n'est plus une langue de cours, il reste une langue maternelle ; « autre
langue » est le code `autre` ; la mémorisation et l'ijaza sont deux questions ;
`pret_test` ; les heures par semaine deviennent des classes souhaitées. Les colonnes
G, H, K et les langues (E, F) se convertissent comme dit plus bas ; une valeur sans
équivalent n'est jamais devinée, elle reste vide et la personne répond.

**Mis à jour le 22/10/2026 (disponibilités, C18)** : le champ `disponibilitesDeclarees`
est une grille de **plages par jour ISO, à bornes en heures entières**, dans le fuseau
unique de `fuseauIana` (celle que lit l'affectation, section 3.5 et spec consolidée 2.1
bis). Les formulaires ne donnent **aucun jour** : la colonne J ne pré-remplit plus rien.

## 1. Ce qui s'importe, et ce qui ne s'importe pas

| Source | Décision proposée |
| :--- | :--- |
| A1 et A2 (questionnaire arabe « تعليم القرآن عن بعد », 14 colonnes identiques) | **importées**, vers l'étape `recue` |
| B (onglet « Enseignants (Réponses) », formulaire français) | **non importée** : déjà dans le périmètre de l'import des inscriptions (`C/DECISION-IMMATRICULATION-2026-10-12.md:68-70`) ; chaque ligne est rendue `dejaConnue` |
| Photos d'identité et captures (liens Drive de B) | **jamais importées** : la pièce passe par le dépôt de l'application |

## 2. Colonnes de A vers les champs de la candidature

En-têtes repérés **après normalisation** : espaces de tête et de fin retirés,
apostrophe initiale retirée, tatwil (ـ) et émojis retirés. Le mappage se fait sur
l'en-tête normalisé, jamais sur la position.

| Col. | En-tête source | Champ cible | Règle |
| :-: | :--- | :--- | :--- |
| A | Horodateur | `recueLe` et part de la référence source | instant UTC ; la référence source = classeur, onglet, horodatage |
| B | هل أنت (vous êtes) | `genre` | table 3.1 ; colonne privilégiée, jamais affichée dans une liste |
| C | الاسم الكامل (nom complet) | `nomAffiche` | espaces normalisés ; pas de découpage prénom et nom (impossible à faire sans deviner) ; écriture conservée (arabe ou latine) |
| D | رقم الواتساب مع رمز الدولة (WhatsApp avec indicatif) | `telephone` et `indicePays` | section 4 ; `indicePays` est un **indice** déduit de l'indicatif, jamais un pays de résidence ni un pays de versement déclarés |
| E | ما هي لغتك الأم (langue maternelle) | `langueMaternelle` (facultative) | table 3.2 ; `ff` devient `poular`, `ar` reste valable |
| F | بأي لغات تستطيع أن تشرح للطالب وتصحح له أخطاءه (langues d'explication et de correction, choix multiple) | `languesExplication` | table 3.2 ; découpage selon la liste d'options, jamais sur la seule virgule ; `ff`, peul, fulfulde deviennent `poular` ; `ar` est retiré (avertissement) ; aucun plafond |
| G | ما مستواك في حفظ القرآن (niveau de mémorisation) | `niveauMemorisationDeclare` | table 3.3 (la mémorisation seule : l'ijaza vient de la colonne H) |
| H | هل تستطيع تقديم شهادة أو إجازة تثبت مستواك عند المقابلة (certificat ou ijaza présentable à l'entretien) | `ijazaPresentable` | table 3.4 |
| I | هل لديك خبرة في تعليم المبتدئين القراءة (expérience avec les débutants) | `experienceDebutants` | table 3.4 |
| J | هل تستطيع التدريس في ساعات متأخرة من الليل بتوقيت مكة المكرمة (créneaux, heure de La Mecque, choix multiple) | **aucun** (ne pré-remplit pas `disponibilitesDeclarees`) | table 3.5 ; les formulaires ne donnent aucun jour ; le libellé d'origine est gardé tel quel dans la réponse importée, jamais converti ni lu comme une disponibilité |
| K | كم ساعة في الأسبوع تستطيع التدريس بانتظام (heures par semaine) | `classesSouhaitees` | table 3.6 : les tranches d'heures se convertissent en classes (1 à 3) |
| L | متى تستطيع أن تبدأ (début possible) | `debutPossible` | table 3.6 |
| M | أوافق على أن يتصل بي فريق المشروع عبر واتساب (accord pour un contact WhatsApp) | `consentementWhatsApp` | `أوافق` (j'accepte) donne vrai, daté de l'horodatage ; ce consentement ne vaut que pour le contact, jamais pour une autre finalité |
| N | البريد الألكتروني (courriel) | `courriel` | section 4 |

**Champs de préqualification que A ne remplit pas** (ils viennent du candidat,
dans `CAND-01`) : pays de résidence, pays de versement, fuseau IANA, publics
enseignables (les tranches d'âge 6-9, 10-13, 14-17 et adultes ; le formulaire
d'origine ne les demandait pas), disponibilités (plages par jour : le formulaire ne
donne aucun jour, 3.5), compte bancaire, opérateurs accessibles, moyens
accessibles (champ facultatif et informatif, nouveau), accord de rémunération, cadre
religieux, riwaya. Aucun ne se déduit de l'import.

## 3. Correspondance des libellés d'options

### 3.1 Genre (colonne B)

| Libellés source (deux graphies chacun) | Valeur |
| :--- | :--- |
| ذكر · ذ كـــــر (avec émoji) | `male` |
| أنثى · أنـــثــى (avec émoji) | `female` |

### 3.2 Langues (colonnes E et F)

Le référentiel `langues_cours` ne compte que `poular`, `francais` et `english`
(`supabase/migrations/0043_offres_horaires_et_intentions.sql:75-78`). Une langue
hors référentiel s'importe sous un code de langue neutre (ISO 639), marquée « hors
référentiel » : elle nourrit la décision d'ouvrir une langue de cours, elle ne
l'ouvre pas. Tout s'enregistre **par code**, jamais par nom (`CAND-Q15`).
Quand la direction ajoute une langue à `langues_cours`, elle prend le code de ce
tableau, pour que les valeurs importées et les saisies libres s'y rattachent ; un
code hors référentiel ne s'affiche jamais tel quel
(`CORRECTIFS_HORS_MODULE_PROPOSES.md`, section 3).

**Décisions du directeur du 22/10** (`DECISION-CANDIDATURES-2026-10-21.md`, section
1 ter), appliquées à l'import :
- **poular, peul et fulfulde sont une seule langue, le code `poular`** (une entrée du
  référentiel). Il n'y a plus de code `ff` : le libellé « الفولاني ـ فولفولدي » et
  toute valeur `ff`, `peul` ou `fulfulde` s'importent `poular` ; si la personne a
  coché deux équivalents, `poular` n'est écrit qu'une fois ;
- **l'arabe n'est pas une langue de cours.** En colonne F (`languesExplication`), `ar`
  est retiré de la liste, avec l'avertissement d'import « arabe retiré : pas une langue
  de cours » ; une personne qui n'avait coché que l'arabe garde une liste vide et
  répond elle-même. En colonne E (`langueMaternelle`), `ar` reste valable ;
- **aucun plafond** au nombre de langues d'explication ;
- « لغة أخرى اكتبها » s'importe sous le code **`autre`** (plus `autre_a_preciser`) : la
  sortie « autre langue » de la liste, un code et jamais un texte. Le formulaire n'a pas
  gardé le texte saisi. `autre` n'est jamais recopié dans `teacher_profiles.languages`
  (il ne désigne aucune classe) ;
- le malinké (maninka) et le soussou, que le formulaire d'origine n'offrait pas
  (ses répondants ont dû choisir « autre »), sont dans la liste du questionnaire sous
  `man` et `sus`, au même titre que le haoussa, le wolof, le bambara, le soninké, le
  mandinka et le swahili : le public principal de l'académie est celui de la diaspora
  africaine.

| Libellé source | Langue | Code proposé | Dans `langues_cours` |
| :--- | :--- | :--- | :-: |
| العربية | arabe | `ar` | non ; langue maternelle seulement, jamais une langue d'explication (22/10) |
| الإنجليزية | anglais | `english` | oui |
| الفرنسية | français | `francais` | oui |
| الفولاني ـ فولفولدي | peul (fulfulde) | `poular` | **oui** : poular, peul et fulfulde sont une seule langue (décision du 22/10) |
| الهاوسا | haoussa | `ha` | non |
| الولوف | wolof | `wo` | non |
| البشتو | pachto | `ps` | non |
| الأردية | ourdou | `ur` | non |
| السونينكي | soninké | `snk` | non |
| البامبارا | bambara | `bm` | non |
| السواحيلية | swahili | `sw` | non |
| الماندينكا | mandinka | `mnk` | non |
| الأورومو | oromo | `om` | non |
| الأمهرية | amharique | `am` | non |
| اليوروبا | yoruba | `yo` | non |
| البنغالية | bengali | `bn` | non |
| الفارسية | persan | `fa` | non |
| الإندونيسية | indonésien | `id` | non |
| الصومالية | somali | `so` | non |
| الهندية | hindi | `hi` | non |
| الأوزبكية | ouzbek | `uz` | non |
| التركية | turc | `tr` | non |
| الألمانية | allemand | `de` | non |
| البرتغالية | portugais | `pt` | non |
| الروسية | russe | `ru` | non |
| لغة أخرى اكتبها (autre, à préciser) | autre | `autre` | non ; le formulaire n'a pas gardé le texte saisi |
| (aucun : absent du formulaire d'origine) | malinké (maninka) | `man` | non ; ajouté à la liste du questionnaire le 22/10 |
| (aucun : absent du formulaire d'origine) | soussou | `sus` | non ; ajouté à la liste du questionnaire le 22/10 |

### 3.3 Niveau de mémorisation déclaré (colonne G)

Le questionnaire pose **deux questions** (directeur, 22/10 : « celui qui a une ijaza a
mémorisé, mais toute personne qui a mémorisé n'a pas une ijaza ») : la quantité mémorisée
(`niveauMemorisationDeclare` : `aucune`, `moins_10_juz`, `de_10_a_29_juz`,
`coran_entier`) et l'ijaza (`ijazaPresentable`, table 3.4). La colonne G mélangeait les
deux : l'une de ses cinq options était une ijaza.

| Libellé source | `niveauMemorisationDeclare` | Remarque |
| :--- | :--- | :--- |
| حفظت القرآن كله (j'ai mémorisé tout le Coran) | `coran_entier` | |
| عندي إجازة قراءة وإقراء (ijaza de lecture et d'enseignement) | **aucune valeur** | une ijaza n'est pas une quantité mémorisée : « qui a une ijaza a mémorisé » (directeur, 22/10) ne dit pas combien, et la règle de ce document est de ne jamais deviner (84 réponses sur 440 ; en faire du `coran_entier` leur ferait déclarer le Coran entier à leur place). Avertissement d'import « ijaza déclarée en G : mémorisation à renseigner » ; la personne répond. **Ne renseigne pas non plus** `ijazaPresentable`, qui ne vient que de la colonne H |
| حفظت أكثر من 10 أجزاء (plus de dix juz') | `de_10_a_29_juz` | le Coran entier a sa propre option |
| حفظت أقل من 10 أجزاء (moins de dix juz') | `moins_10_juz` | |
| لم أحفظ، لكنني أقرأ القرآن قراءة جيدة بالتجويد (pas mémorisé, bonne lecture avec tajwid) | `aucune` | la bonne lecture n'est pas une mémorisation : elle se dit par `niveauLectureTajwid`, que l'import ne pré-remplit pas |

C'est une **déclaration**, jamais un constat : le constat de niveau se fait à
l'entretien (`CAND-Q08`). Les libellés visibles se prennent dans `mots-rewayah`
(« mémoriser le Coran », jamais les codes internes).

### 3.4 Ijaza présentable et expérience (colonnes H et I)

`ijazaPresentable` (colonne H) a trois valeurs depuis le 22/10 : `oui`, `pret_test`,
`non` (89 réponses sur 440 étaient « prêt à un test »). `experienceDebutants`
(colonne I) garde `oui` et `non`.

| Libellé source | Valeur |
| :--- | :--- |
| نعم (oui) | `oui` |
| لا (non) | `non` |
| لا، لكني مستعد لإجراء اختبار لتحديد المستوى (non, mais prêt à un test de niveau) | `pret_test` |

En colonne I, le formulaire propose aussi l'option de H (« prêt à un test »). Elle
n'a pas d'équivalent dans `experienceDebutants` (`oui` ou `non` seulement) : **elle ne
pré-remplit rien**, la personne répond, avec un avertissement d'import. (Le mappage
produisait avant le 22/10 la valeur `non_pret_a_un_test`, que le serveur n'aurait pas
acceptée.)

### 3.5 Créneaux (colonne J, heure de La Mecque) : lus, jamais importés comme disponibilités

**La colonne J ne pré-remplit aucun champ** (décision du 22/10, C18). Le champ
`disponibilitesDeclarees` est une liste de plages par jour ISO à bornes en heures
entières (« lundi de 18 h à 21 h »), dans le fuseau `fuseauIana`, au format que lit
l'affectation (`weekly_availability`, une ligne par heure couverte : spec consolidée 2.1
bis). Les libellés du formulaire sont des tranches horaires **sans jour** (« de 8 h à
10 h du soir ») : y mettre un jour reviendrait à deviner, et faire déclarer à la personne
des heures qu'elle n'a pas dites. La personne remplit la grille dans l'application.

Le libellé d'origine est **gardé tel quel** dans la réponse importée, lisible par la
direction (une indication à reprendre à l'entretien), jamais converti en heure absolue,
jamais lu comme une disponibilité, jamais recopié dans `weekly_availability` (« Fuseaux
IANA en stockage, UTC pour les instants »). Les heures de La Mecque (`Asia/Riyadh`) ne
sont d'ailleurs pas forcément celles de la personne : son fuseau est celui qu'elle déclare.

| Libellé source | Sens du libellé (lecture pour la direction) |
| :--- | :--- |
| من 8 مساءً إلى 10 مساءً | de 20 h à 22 h, heure de La Mecque, sans jour |
| من 10 مساءً إلى 12 منتصف الليل | de 22 h à 24 h, heure de La Mecque, sans jour |
| من 12 منتصف الليل إلى 2 صباحاً | de 0 h à 2 h, heure de La Mecque, sans jour |
| من 2 صباحاً إلى 4 صباحاً | de 2 h à 4 h, heure de La Mecque, sans jour |
| أُفضّل التدريس من الصبح إلى الظهر (بتوقيت مكة) | préférence « du matin à midi », **pas un créneau** : bornes non données |
| أُفضّل التدريس من الظهر إلى المغرب (بتوقيت مكة) | préférence « de midi au maghrib », **pas un créneau** : le maghrib change chaque jour |
| جاهز في أي وقت من اليوم | `toute_heure` |
| لا أستطيع التدريس بعد الساعة 8 مساءً | contrainte « pas après 20 h » |

Une ligne qui combine `toute_heure` avec des créneaux précis, ou la contrainte
« pas après 20 h » avec des créneaux de nuit, s'importe telle quelle avec un
avertissement (24 lignes au comptage du 21/10). Rien de cela n'entre dans
`disponibilitesDeclarees`.

### 3.6 Heures par semaine, classes souhaitées et début (colonnes K et L)

Le questionnaire ne demande plus des heures mais des **classes souhaitées** :
`classesSouhaitees` vaut `1`, `2` ou `3` (directeur, 22/10 : trois Classes au plus par
enseignant pour l'instant, réglable par la direction : l'écran propose de 1 au maximum en vigueur,
et le serveur accepte tout entier de 1 à 80 quel que soit ce maximum, pour qu'une réponse envoyée ne
devienne jamais invalide). Une classe d'enfants tient trois
séances d'une heure par semaine, une classe d'adultes trois séances d'une heure et demie
(`DECISION-TARIFS-2026-10-18.md`). La conversion prend la **borne basse**, pour ne pas
promettre plus de classes que d'heures :

| Libellé source (colonne K) | `classesSouhaitees` | Remarque |
| :--- | :--- | :--- |
| أقل من 3 ساعات (moins de 3 h) | aucune valeur | ne tient pas une classe entière ; avertissement d'import, la personne répond |
| من 3 إلى 5 ساعات في الأسبوع | `1` | |
| من 6 إلى 10 | `2` | |
| أكثر من 10 | `3` | le plafond du questionnaire |

| Libellé source (colonne L) | `debutPossible` |
| :--- | :--- |
| يمكن لي البدء فورا | `immediat` |
| في الشهر القادم | `mois_prochain` |
| خلال 3 أشهر | `sous_3_mois` |
| لا أعرف بعد | `inconnu` |

Les anciens codes `moins_de_3`, `de_3_a_5`, `de_6_a_10`, `plus_de_10` n'existent plus
dans la définition ; ils ne servent qu'à lire la colonne K.

## 4. Contacts : normalisation sans deviner

| Cas | Règle |
| :--- | :--- |
| Téléphone avec `+` ou `00` et un indicatif reconnu | normalisé en `+` et chiffres seulement |
| Indicatif sans `+` ni `00` | `+` ajouté **seulement** si l'indicatif est reconnu en tête et que la longueur est plausible ; sinon « indicatif à confirmer » |
| Numéro au format national (commence par 0), ou trop court ou trop long | conservé tel quel, marqué « indicatif à confirmer » ; jamais complété |
| `0` national en trop après l'indicatif | signalé en avertissement, conservé tel quel |
| Cellule stockée comme nombre | relue comme texte avant toute normalisation |
| Courriel | espaces retirés, minuscules ; un courriel mal formé (un numéro, une faute de domaine) n'est ni une clé de rapprochement ni une adresse d'invitation : marqué « courriel à obtenir » |
| Courriel absent | « courriel à obtenir » ; la candidature ne s'invite pas (`CAND-Q03`) |

## 5. Doublons

- **Clé** : courriel normalisé **ou** téléphone normalisé. Le nom seul ne relie
  jamais deux lignes.
- **Proposé, jamais appliqué seul** : la direction choisit, pour chaque groupe, la
  ligne retenue ou « personnes distinctes » (`PortImportCandidatures.confirmer`).
- **Ligne proposée par défaut** : la plus récente ; les autres restent dans
  l'historique de la référence source (`CAND-Q16`).
- **Renvois identiques** à l'horodatage près : proposés comme doublons exacts.
- **Écriture différente du nom** dans un groupe relié par le contact (arabe et
  latine, élément ajouté) : l'écran montre les deux.

## 6. Contrôle avant import

À l'essai à blanc, les quatre compteurs de la spec §9 (nouvelles, déjà connues,
ignorées, à corriger) sont rendus avec, pour référence, les comptes agrégés du
21/10 (section 2 de la revue) : 440 lignes dans A, 409 personnes une fois les
doublons de A rapprochés, aucune ligne de A déjà présente dans B. Un écart entre
ces chiffres et l'essai à blanc se lit avant de confirmer, jamais après.
