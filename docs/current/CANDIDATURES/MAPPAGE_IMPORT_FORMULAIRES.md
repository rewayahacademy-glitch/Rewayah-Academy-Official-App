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
| E | ما هي لغتك الأم (langue maternelle) | `langueMaternelle` | table 3.2 |
| F | بأي لغات تستطيع أن تشرح للطالب وتصحح له أخطاءه (langues d'explication et de correction, choix multiple) | `languesExplication` | table 3.2 ; découpage selon la liste d'options, jamais sur la seule virgule |
| G | ما مستواك في حفظ القرآن (niveau de mémorisation) | `niveauMemorisationDeclare` | table 3.3 |
| H | هل تستطيع تقديم شهادة أو إجازة تثبت مستواك عند المقابلة (certificat ou ijaza présentable à l'entretien) | `ijazaPresentable` | table 3.4 |
| I | هل لديك خبرة في تعليم المبتدئين القراءة (expérience avec les débutants) | `experienceDebutants` | table 3.4 |
| J | هل تستطيع التدريس في ساعات متأخرة من الليل بتوقيت مكة المكرمة (créneaux, heure de La Mecque, choix multiple) | `disponibilitesDeclarees` | table 3.5 ; fuseau `Asia/Riyadh` |
| K | كم ساعة في الأسبوع تستطيع التدريس بانتظام (heures par semaine) | `heuresParSemaine` | table 3.6 |
| L | متى تستطيع أن تبدأ (début possible) | `debutPossible` | table 3.6 |
| M | أوافق على أن يتصل بي فريق المشروع عبر واتساب (accord pour un contact WhatsApp) | `consentementWhatsApp` | `أوافق` (j'accepte) donne vrai, daté de l'horodatage ; ce consentement ne vaut que pour le contact, jamais pour une autre finalité |
| N | البريد الألكتروني (courriel) | `courriel` | section 4 |

**Champs de préqualification que A ne remplit pas** (ils viennent du candidat,
dans `CAND-01`) : pays de résidence, pays de versement, fuseau IANA, publics
enseignables, compte bancaire, opérateurs accessibles, accord de rémunération,
cadre religieux, riwaya. Aucun ne se déduit de l'import.

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

| Libellé source | Langue | Code proposé | Dans `langues_cours` |
| :--- | :--- | :--- | :-: |
| العربية | arabe | `ar` | non |
| الإنجليزية | anglais | `english` | oui |
| الفرنسية | français | `francais` | oui |
| الفولاني ـ فولفولدي | peul (fulfulde) | `ff` | **à valider** : le poular de l'académie est une variété du peul, l'équivalence est une décision |
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
| لغة أخرى اكتبها (autre, à préciser) | autre | `autre_a_preciser` | non ; le formulaire n'a pas gardé le texte saisi |

### 3.3 Niveau de mémorisation déclaré (colonne G)

| Libellé source | Valeur |
| :--- | :--- |
| حفظت القرآن كله (j'ai mémorisé tout le Coran) | `coran_entier` |
| عندي إجازة قراءة وإقراء (ijaza de lecture et d'enseignement) | `ijaza_lecture_enseignement` |
| حفظت أكثر من 10 أجزاء (plus de dix juz') | `plus_de_10_juz` |
| حفظت أقل من 10 أجزاء (moins de dix juz') | `moins_de_10_juz` |
| لم أحفظ، لكنني أقرأ القرآن قراءة جيدة بالتجويد (pas mémorisé, bonne lecture avec tajwid) | `bonne_lecture_sans_memorisation` |

C'est une **déclaration**, jamais un constat : le constat de niveau se fait à
l'entretien (`CAND-Q08`). Les libellés visibles se prennent dans `mots-rewayah`
(« mémoriser le Coran », jamais les codes internes).

### 3.4 Ijaza présentable et expérience (colonnes H et I)

| Libellé source | Valeur |
| :--- | :--- |
| نعم (oui) | `oui` |
| لا (non) | `non` |
| لا، لكني مستعد لإجراء اختبار لتحديد المستوى (non, mais prêt à un test de niveau) | `pret_a_un_test` |

En colonne I, le formulaire propose aussi l'option de H (« prêt à un test ») :
elle s'importe `non_pret_a_un_test`, avec un avertissement d'import.

### 3.5 Créneaux (colonne J, heure de La Mecque)

Chaque créneau s'importe comme **créneau récurrent** avec son heure locale et le
fuseau `Asia/Riyadh`, jamais converti en heure absolue, jamais recopié dans
`weekly_availability` (« Fuseaux IANA en stockage, UTC pour les instants »).

| Libellé source | Valeur |
| :--- | :--- |
| من 8 مساءً إلى 10 مساءً | créneau 20 h - 22 h |
| من 10 مساءً إلى 12 منتصف الليل | créneau 22 h - 24 h |
| من 12 منتصف الليل إلى 2 صباحاً | créneau 0 h - 2 h |
| من 2 صباحاً إلى 4 صباحاً | créneau 2 h - 4 h |
| أُفضّل التدريس من الصبح إلى الظهر (بتوقيت مكة) | préférence « du matin à midi », **pas un créneau** : bornes non données |
| أُفضّل التدريس من الظهر إلى المغرب (بتوقيت مكة) | préférence « de midi au maghrib », **pas un créneau** : le maghrib change chaque jour |
| جاهز في أي وقت من اليوم | `toute_heure` |
| لا أستطيع التدريس بعد الساعة 8 مساءً | contrainte « pas après 20 h » |

Une ligne qui combine `toute_heure` avec des créneaux précis, ou la contrainte
« pas après 20 h » avec des créneaux de nuit, s'importe telle quelle avec un
avertissement (24 lignes au comptage du 21/10).

### 3.6 Heures par semaine et début (colonnes K et L)

| Libellé source | Valeur |
| :--- | :--- |
| أقل من 3 ساعات | `moins_de_3` |
| من 3 إلى 5 ساعات في الأسبوع | `de_3_a_5` |
| من 6 إلى 10 | `de_6_a_10` |
| أكثر من 10 | `plus_de_10` |
| يمكن لي البدء فورا | `immediat` |
| في الشهر القادم | `mois_prochain` |
| خلال 3 أشهر | `sous_3_mois` |
| لا أعرف بعد | `inconnu` |

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
