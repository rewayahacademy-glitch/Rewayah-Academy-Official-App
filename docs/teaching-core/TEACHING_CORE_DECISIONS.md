# TEACHING_CORE_DECISIONS.md

> Les décisions qui font autorité sur le chantier Teaching Core.
> Deux origines, une seule force : **elles s'appliquent toutes de la même façon.**
>
> - **Normative (spec §1.1)** — décision produit déjà figée par la spécification. Un agent ne la
>   rediscute pas et ne la contourne pas « pour simplifier son code ».
> - **Arbitrage Agent 0** — point que la spec laissait ouvert ou que la réalité du dépôt impose de
>   trancher. Tranché ici, une fois, pour les neuf agents.
>
> Format : **Sujet | Décision | Raison**. Un agent en désaccord écrit
> `docs/teaching-core/TC_CONTRACT_REQUEST_<X>.md`. Il ne décide pas seul.

---

## D-01 — Photo enseignant

**Origine :** Normative (spec §1.1)

| | |
|---|---|
| **Sujet** | Photo de l'enseignant dans les espaces Groupe et Classe. |
| **Décision** | **Photo professionnelle publique obligatoire** pour tout enseignant actif ou assignable, **distincte des pièces KYC**. Elle est affichée sur la carte du Groupe, dans l'Espace Groupe et dans le header de la Classe Live. Son absence déclenche un **état d'erreur ou de migration explicite**, jamais un avatar générique silencieux. |
| **Raison** | Le groupe doit être reconnaissable d'un coup d'œil et l'enseignant identifiable humainement. Un avatar générique masquerait une donnée manquante au lieu de la signaler. Le point était « anciennement non tranché » ; il l'est désormais. |
| **Conséquence dépôt** | **`teacher_profiles` (0001:90-98) n'a AUCUNE colonne photo/avatar.** `student_profiles` a `avatar_storage_key`, `teacher_profiles` n'a rien. C'est un manque serveur → `TC_CONTRACT_REQUEST_A.md`. Le patron d'upload et d'URL signée existe (`lib/core/appairage/service_avatar.dart`) : on persiste la **clé**, jamais l'URL signée. |

---

## D-02 — Titres enseignants

**Origine :** Normative (spec §1.1)

| | |
|---|---|
| **Sujet** | Comment nommer l'enseignant dans le contexte cours. |
| **Décision** | **Sayyid / Sayyida**. En arabe : **سيد / سيدة**. **Pas de Ustaz / Ustazah**, nulle part. Le titre s'applique partout dans le contexte cours : carte du Groupe, Espace Groupe, header de Classe Live, annonces. |
| **Raison** | Décision produit figée. La cohérence du vocabulaire fait partie de l'identité de l'académie. |
| **Conséquence dépôt** | Aucun titre enseignant n'existe aujourd'hui en base ni en Dart. `TitreEnseignant { sayyid, sayyida }` est un contrat neuf (CONTRACTS §1). Les deux formes arabes sont fournies comme valeurs littérales dans le sous-arbre `tc` de l'agent concerné : c'est la seule exception à la règle « aucun agent ne produit de traduction arabe ». |

---

## D-03 — Pipeline i18n slang

**Origine :** Arbitrage Agent 0

| | |
|---|---|
| **Sujet** | Neuf agents parallèles et **un seul** fichier de libellés. |
| **Décision** | **Aucun agent Teaching Core ne modifie** `assets/i18n/fr.i18n.json`, `lib/core/i18n/strings.g.dart`, `lib/core/i18n/strings_fr.g.dart`, `slang.yaml` ni `build.yaml`. Chaque agent dépose ses libellés dans **`docs/teaching-core/i18n/tc_i18n_<AGENT>.json`**, borné à son propre sous-arbre `tc.<domaine>.*`, et écrit son UI contre une **façade de constantes** dans son namespace, chaque constante annotée `// TC-I18N: tc.<domaine>.<ecran>.<element>`. Agent Z fusionne les neuf JSON, régénère, remplace les constantes et supprime les façades. Détail complet : `TEACHING_CORE_PROTECTED_FILES.md` §4. |
| **Raison** | `slang.yaml` n'active **pas** `namespaces` : il y a **une** source de 68 Ko / 617 clés et **une** sortie générée **et versionnée** de 244 Ko. Les trois fichiers sont déjà modifiés par le chantier enseignant. Neuf agents produiraient neuf conflits sur le JSON **et** neuf conflits sur 244 Ko de code généré **qu'on ne fusionne pas à la main**. Le chantier enseignant applique déjà ce mécanisme (`i18n_A.json` … `i18n_E.json`) : il est éprouvé. |
| **Sous-arbres** | A `tc.groupe.*` · B `tc.bibliotheque.*` · C `tc.coran.*` · D `tc.outils.*` · E `tc.classe.*` · F `tc.realtime.*` · G `tc.observation.*` · H `tc.parcours.*` · Q aucun. Aucun n'est préfixe d'un autre ; la racine `tc` n'entre en collision avec aucun des 34 espaces de noms existants. |

---

## D-04 — Routes et routeur

**Origine :** Arbitrage Agent 0

| | |
|---|---|
| **Sujet** | Poser un écran sans toucher au routeur global. |
| **Décision** | Chaque agent qui produit un écran écrit `lib/features/tc_<ecran>/routes_tc_<lettre>.dart` contenant ses constantes de chemin sous le **préfixe réservé `/tc/…`** et **une fonction** `List<RouteBase> routesTc<Lettre>()` qui **retourne** des routes. **Cette fonction ne construit jamais un `GoRouter`.** Agent Z l'appelle depuis `app_router.dart`, promeut les constantes dans `routes.dart` et ajuste `redirection.dart`. Pour développer et tester, l'agent construit son propre `GoRouter` **dans `test/teaching_core/<lettre>/support/`** — hors de `lib/`, donc hors de la règle CI. |
| **Raison** | `app_router.dart` et `routes.dart` sont PROTECTED (chantier enseignant + spec §16.2). `tool/verifier_jetons.dart` (lignes 261-268) fait échouer la CI si un second fichier de `lib/` construit un `GoRouter`, **et** si `app_router.dart` n'en construit plus aucun. Il n'existe aujourd'hui **aucun mécanisme de déclaration de route modulaire** : tout est écrit à la main dans deux fichiers. Cette convention rend le branchement final **mécanique plutôt que conflictuel**. |
| **Piège nommé** | `redirection.dart` redirige toute route hors préfixe de rôle vers la racine du rôle. **Un écran posé sans ajustement de ce fichier sera inatteignable.** Et une route sans entrée de navigation n'existe pas (`feedback_brancher_l_entree_pas_la_route`) — or `nav_shell.dart` est PROTECTED **et plafonné à 4 destinations par assertion**, l'enseignant en ayant déjà 4. Toute demande de destination est donc un **arbitrage produit**, à formuler dans le CONTRACT_REQUEST. |

---

## D-05 — Icônes

**Origine :** Arbitrage Agent 0

| | |
|---|---|
| **Sujet** | `lib/core/icons/app_icons.dart` est un catalogue unique et la CI refuse tout `IconData` ou `Icons.` ailleurs. |
| **Décision** | Un agent qui a besoin d'une icône absente **utilise une icône existante comme placeholder**, annotée `// TC-ICONE: <nom souhaité>`, et liste sa demande sous une section **« ICÔNES DEMANDÉES »** de son `TC_CONTRACT_REQUEST_<X>.md`. Agent Z les ajoute **en un seul lot**. Aucun agent n'édite `app_icons.dart`. |
| **Raison** | Fichier unique partagé = point de collision certain entre neuf agents. Et la règle CI est là pour une raison : un `IconData` construit ailleurs échappe au catalogue et casse la cohérence visuelle. |
| **Déjà disponibles et utiles** | `coran`, `cahier`, `cours`, `pause`, `micro` / `microCoupe`, `camera` / `cameraCoupee`, `pedagogie`, `controleQualite`, `qr`, `appareil`, `suivi`, `chevron`, `ajouter`. |

---

## D-06 — Tests et harnais

**Origine :** Arbitrage Agent 0

| | |
|---|---|
| **Sujet** | `test/support/harnais.dart` est un fichier unique de 40,5 Ko, déjà modifié par le chantier enseignant. |
| **Décision** | **Tous les tests Teaching Core vivent sous `test/teaching_core/<lettre>/`.** Chaque agent écrit ses propres faux dans `test/teaching_core/<lettre>/faux/` et son propre hôte de test dans `test/teaching_core/<lettre>/support/`. **Aucun agent n'écrit dans `test/support/`, `test/features/`, `test/router/`, `test/video/`, `test/coran/`, ni aucun autre répertoire de test existant.** Agent Q possède en plus `test/teaching_core/fixtures/`. Agent Z consolidera dans `harnais.dart` à l'intégration, pas avant. |
| **Raison** | Collision garantie sinon. `test/features/salle_test.dart`, `journee_test.dart`, `creneaux_test.dart`, `profil_enseignant_test.dart` et les tests router/vidéo sont **tous** modifiés par le chantier enseignant. En revanche le patron d'override de `test/features/salle_test.dart` (lignes 72-74) est **à lire et à reproduire** : c'est le modèle exact pour tester une Classe Live sans SDK. |

---

## D-07 — « Interface guidée », et non « mode enfant »

**Origine :** Normative (spec §1.1) + arbitrage Agent 0 sur la portée

| | |
|---|---|
| **Sujet** | Le socle entier nomme « enfant » le concept que la spec veut appeler « Interface guidée ». |
| **Décision** | **Aucune UI produit n'écrit « mode enfant », nulle part.** Le nom visible est **« Interface guidée »**. <br>**Arbitrage de portée : c'est un renommage de LIBELLÉ, pas de valeur ni d'identifiant.** La valeur SQL `public.interface_mode = 'child'` **ne change pas**. Les identifiants Dart existants (`InterfaceMode.enfant`, `AppMetriques.estEnfant`, `AppTypography.enfant`, `AppTypography.facteurEnfant`, `AppTouchTarget.enfant`) **ne sont pas renommés en phase parallèle**. Les contrats Teaching Core exposent un booléen nommé `interfaceGuidee`. |
| **Raison** | Renommer la valeur SQL exigerait une migration, **interdite** (D-12). Renommer les identifiants Dart toucherait le socle partagé, **PROTECTED**, et les 31 fichiers du pattern de service. Le besoin produit est que l'**utilisateur** ne lise jamais « mode enfant » : c'est un problème d'i18n, et il se règle dans le sous-arbre `tc` de chaque agent. L'âge peut **suggérer** un mode, jamais le définir à lui seul. |
| **Conséquence** | Interface guidée = grandes cibles tactiles, chrome réduit, navigation minimale, suivi automatique du contenu présenté, feedback visuel/audio utile, moins de texte et plus d'actions directes. **Elle peut être utilisée par un enfant, une personne âgée ou toute personne qui en bénéficie.** `AudioLabel` (libellé qui se lit **et** se parle, résolu par la même clé slang via `CleAudio`) lui est indispensable — et ce n'est **pas** de la reconnaissance vocale, c'est de la restitution. |

---

## D-08 — « Amina B. » : la contradiction sur le nom de famille

**Origine :** Arbitrage Agent 0

| | |
|---|---|
| **Sujet** | La maquette de la spec §10.1 affiche `Amina B.`, donc une **initiale de nom de famille**, alors que `0005_dashboards_affectation_regles.sql` (lignes 699-722) a **explicitement retiré `last_name`** de `teacher_roster_v` au nom d'ADR-008. |
| **Décision** | **ADR-008 l'emporte. Personne ne réintroduit `last_name`, pas même une initiale.** La désambiguïsation se fait par **prénom + `academy_id`** (= `immutable_id`, ex. `RA-AB0012`), exactement comme le fait déjà `lib/features/journee/journee_page.dart` (lignes 276-281). La maquette de la spec est traitée comme une esquisse, pas comme une exigence de donnée. |
| **Raison** | La priorité n°1 de la spec elle-même (§1) est « sécurité, confidentialité, RLS, décisions métier et contraintes backend **existantes** ». Le retrait de `last_name` est un défaut de sécurité corrigé (défaut 3.8), documenté, et tenu **côté serveur** par une vue. Le réintroduire pour une maquette recasserait la seule protection qui tienne réellement — et un agent qui « ne voit pas » la colonne serait tenté de la reconstituer par jointure, ce qui est exactement le contournement à interdire. |
| **Conséquence** | `TeacherStudentProjection` ne porte **ni `lastName`, ni initiale**. C'est un test contractuel explicite d'Agent Q : « aucune PII dans teacher projection ». |

---

## D-09 — Coran : source canonique structurée, PDF dérivé

**Origine :** Normative (spec §1.1 et §1.2)

| | |
|---|---|
| **Sujet** | Le statut du corpus coranique et celui du PDF. |
| **Décision** | La **source de vérité reste structurée et immuable**. La fidélité de page est assurée par un **moteur de layout ou des assets de layout dédiés**. Un PDF ou un raster **ne devient jamais** la source canonique interactive. Un PDF téléchargeable est un **artefact dérivé d'une version**, correspondant à l'édition retenue et à ses droits de distribution. Aucun screenshot, aucune image n'est envoyée comme substitut au renderer. |
| **Raison** | Contradiction neutralisée par la spec §1.2 entre un « ancien rendu Coran pré-rendu » et le Coran structuré. Le dépôt a déjà tranché dans le même sens : l'invariant **J6** est inscrit en commentaire dans `lib/core/coran/service_coran.dart` — « aucun champ ne porte d'identifiant de fichier, le Coran n'est pas un PDF paginé ». Et `0013_corpus_coranique.sql` explique pourquoi l'API quran.com a été rejetée : interdiction de cacher plus d'une semaine, donc **incompatible avec le hors ligne**. |
| **Licence** | Le corpus est Tanzil Uthmani v1.1, **CC-BY 3.0**, avec un bloc de copyright à reproduire **verbatim**. Ne jamais retoucher le texte ni supprimer le bloc. L'attribution est déjà affichée au pied de chaque page par `coran_page.dart` : **la conserver**. |

---

## D-10 — Aucune commande vocale

**Origine :** Normative (spec §1.1)

| | |
|---|---|
| **Sujet** | Piloter la classe à la voix. |
| **Décision** | **NON.** Aucun moteur de commandes vocales n'est construit, ni côté enseignant, ni côté élève. Le professeur utilise **son micro normal** pour parler, corriger, appeler et guider. Aucune action logicielle n'est déclenchée par la parole. |
| **Raison** | « Ne pas coder une commande dédiée pour chaque interaction humaine. » L'app absorbe la bureaucratie et les calculs ; elle n'intercepte pas la relation pédagogique. C'est aussi un invariant de la Phase 6 d'Agent Z : « aucune commande vocale implémentée ». |
| **À ne pas confondre** | `AudioLabel` et `CleAudio` (restitution d'un libellé à voix haute pour l'Interface guidée) ne sont **pas** de la reconnaissance vocale. Ils restent autorisés et recommandés. |

---

## D-11 — `pubspec.yaml` gelé

**Origine :** Arbitrage Agent 0 (spec §16.2 et §16.4)

| | |
|---|---|
| **Sujet** | Ajouter une dépendance. |
| **Décision** | **Aucun agent ne modifie `pubspec.yaml` ni `pubspec.lock`.** Toute dépendance manquante devient une section **« DÉPENDANCE DEMANDÉE »** du `TC_CONTRACT_REQUEST_<X>.md`, avec le paquet, la version, la raison, et **ce qui a été essayé avec l'existant avant de la demander**. Seul Agent Z l'ajoute. |
| **Raison** | `pubspec.yaml` porte un commentaire normatif : `sentry_flutter` est bloqué en 8.x pour ne pas rétrograder `path_provider_android`, **qui porte le répertoire du cache Drift, donc le mode hors ligne, qui est un invariant produit**. Une dépendance ajoutée à la légère par un agent parmi neuf peut casser le hors ligne sans que personne le voie. |
| **Demandes attendues** | **Agent B** : un renderer PDF (`pdfx` / `syncfusion_flutter_pdfviewer` / `pdfrx`) et éventuellement `flutter_markdown` — à peser contre le budget de 20 Mo posé par `docs/produit/bibliotheque-contenu.md`. **Agent A** : `timezone` + `intl` **seulement si** le rendu serveur des horloges s'avère insuffisant. **Agent C** : rien pour le rendu, mais l'embarquement d'un jeu de polices QCF passerait aussi par ici. |
| **Déjà disponible, ne pas redemander** | `file_picker 12.2.0` couvre `saveFile()` et `getDirectoryPath()` : **la règle §6.5 « passer par le sélecteur système, jamais /sdcard » se satisfait sans aucune dépendance nouvelle.** Ni `share_plus`, ni `path_provider` ne sont nécessaires pour cela. |

---

## D-12 — Aucune migration Supabase en phase parallèle

**Origine :** Arbitrage Agent 0

| | |
|---|---|
| **Sujet** | La numérotation des migrations. |
| **Décision** | **Aucun agent Teaching Core ne crée, ne modifie ni ne supprime de migration Supabase.** Dernière migration de notre baseline : **`0024`**. Le chantier enseignant occupe **`0025` à `0029`** (non commitées, donc invisibles chez nous). Toute migration Teaching Core partirait de **`0030+`** : **c'est interdit**. Toute table, vue, RPC, policy ou colonne manquante devient une section **« DEMANDE SQL »** du `TC_CONTRACT_REQUEST_<X>.md`, pour Agent Z. |
| **Raison** | Aucun mécanisme de réservation de numéro n'existe. Neuf agents aveugles les uns aux autres **et** aveugles aux cinq migrations enseignantes produiraient des collisions de numéro et des ordres d'application incohérents. La spec l'écrit d'ailleurs deux fois : « aucun agent ne crée une migration partagée » (§16.4) et « pas de migration » (PROMPT F). |
| **Forme imposée de la demande SQL** | Nom exact de l'objet · colonnes et types · RLS attendue · rôle appelant · **et la table existante qu'elle étend**. Une table neuve n'est demandée que si `TEACHING_CORE_EXISTING_MAPPING.md` §9 et §10 ne montrent aucun équivalent. |
| **Deux règles de sécurité à répéter dans chaque demande** | (1) **Jamais `grant execute` à `agent_ro` sur une RPC volatile ou d'écriture** — `get_advisors` ne le détecte pas. (2) Toute nouvelle vue d'exposition **répète le filtre d'appelant et le masquage `agent_identite_masquee()` colonne par colonne** : le motif est dupliqué à la main dans le dépôt, et une surface oubliée est une fuite avec une bannière devant. |
| **Demandes SQL attendues** | A : `sessions.groupe_id` + matérialisation par groupe, `groupes.timezone_iana` exposée, couleur, cours/niveau, `join_opens_at` configurable, photo enseignant. B : tables ressource/version/artefact + bucket Storage. C : `verset.ligne` peuplé (ou assets de layout). E : projection pédagogique enseignant + lecture de `student_reading_position`. F : persistance de `SharedContentState`. G : politique d'observation, table de visites, quota avant token, entrée Admin. H : `student_concern`, `session_feedback`, séparation `internal_details`/`family_summary`. |

---

## D-13 — Fenêtre de connexion : T-20 par défaut, configurable

**Origine :** Normative (spec §1.1)

| | |
|---|---|
| **Sujet** | Quand le bouton « Rejoindre » s'active. |
| **Décision** | **Environ 20 minutes avant la séance, valeur configurable.** L'attente avant T0 **ne compte pas comme présence académique**. |
| **Raison** | Laisser à l'élève le temps de se préparer sans fausser le temps académique crédité. |
| **Conséquence dépôt — bloquante** | La valeur actuelle est **T-10, en dur, dupliquée trois fois** : `autoriser_jeton_video()` (0010), `etat_presence()` (0010) et `seuilOuvertureSalle` dans `journee_page.dart` **[PROTECTED]**. Elle n'est **pas** dans `app_config`, contrairement aux trois seuils de présence. **Aucun agent ne pose une quatrième constante.** `SessionClockVM` lit `joinOpensAtUtc` et `fenetreAcces` depuis le port. La remontée vers `app_config` est une demande SQL d'Agent A. |
| **Défaut latent à signaler, pas à corriger** | Le jour où la fenêtre passera à T-20, deux choses casseront : `etat_presence()` rend `presente` dès le premier `joined` **sans comparer à `started_at`**, et `VuePresence.depuis` calcule la durée depuis `entre_le` brut. Un élève entré à T-20 verrait « en salle depuis 38 min » pour un cours commencé il y a 18 min. La correction (borner à `max(entreLe, debutSeance)`) va dans `TC_CONTRACT_REQUEST_A.md` — **pas dans une édition spontanée** de `lib/core/presence/vue_presence.dart`. |

---

## D-14 — Observation tuteur : bornée par le serveur

**Origine :** Normative (spec §1.1 et §11)

| | |
|---|---|
| **Sujet** | Le tuteur qui veut voir son enfant en cours. |
| **Décision** | Accès **automatique** après validation serveur, **sans acceptation de l'enseignant**, et **borné par politique serveur**. Défauts : observation **activée**, **1 visite**, **120 secondes** totales par séance, micro **interdit**, caméra **interdite**, publication data/chat **interdite**. **Configurable par groupe** : l'Admin choisit hériter de l'Académie, personnaliser ou désactiver. Le modèle supporte `max_visits_per_session` et `max_total_observation_seconds` ; un plafond par visite peut s'ajouter **sans contourner le plafond total**. |
| **Raison** | La règle ancienne « rien ne se ferme tout seul » reste vraie pour les écrans ordinaires. **L'observation tuteur en est une exception de sécurité/produit bornée serveur**, donc elle se termine automatiquement à la limite autorisée (spec §1.2). |
| **Règle d'implémentation, non négociable** | **La borne est serveur.** Vérification du lien tuteur-enfant, de la session active, du groupe, de la policy et du quota **AVANT le token**. Le client **ne peut pas prolonger** sa visite en modifiant un timer. À la limite : sortie client **+ révocation/expulsion serveur** si nécessaire. Un compte à rebours Dart est un **affichage**, jamais l'application de la limite. **Agent G ne crée jamais une règle seulement côté client.** |
| **Ce que voit le tuteur** | Support partagé, enseignant, son propre enfant si le média est autorisé, et un compte à rebours discret de son budget. **Aucun roster complet, aucune fiche d'un autre élève, aucun micro, aucune caméra, aucun outil pédagogique.** |
| **Annonce** | L'enseignant voit « Tuteur d'Amina observe » puis un petit indicateur avec le temps restant. L'enfant concerné peut recevoir un indicateur discret. Les autres élèves ne sont pas interrompus. **Pas de notification de sortie.** |
| **Journalisation** | Chaque intervalle est journalisé avec `entered_at`, `left_at`, `duration_seconds`, `visit_number` et **`policy_version`**. ⚠ `session_events` ne porte aujourd'hui **aucun** de ces trois derniers champs, et `policy_version` n'existe nulle part dans le dépôt : c'est une demande SQL. |

---

## D-15 — Admin dans la classe : visible ou incognito

**Origine :** Normative (spec §1.1 et §11.5)

| | |
|---|---|
| **Sujet** | L'entrée d'un administrateur dans une séance. |
| **Décision** | **Deux modes, choisis AVANT l'entrée.** *Observer discrètement* : invisible aux participants, **pas de micro, pas de caméra, pas d'annonce**. *Rejoindre la classe* : visible, **micro et caméra permis, annonce faite**, sous un nom institutionnel clair — par exemple « **Administration Rewayah** ». Un Admin autorisé peut accéder à n'importe quel groupe **sans en être membre**. |
| **Raison** | L'administration a deux besoins distincts — constater sans perturber, et intervenir. Les confondre produirait soit une intrusion, soit une impuissance. |
| **Non négociable** | **L'incognito est invisible aux participants mais jamais invisible à l'audit.** |
| **Conséquence dépôt** | **L'entrée Admin est aujourd'hui impossible** : `rejoindre_observation()` lève `insufficient_privilege` pour tout rôle ≠ `controller`, et l'enum `participant_role` n'a que quatre valeurs. Demande SQL d'Agent G. ⚠ Si un rôle d'observation admin est ajouté, **il faut l'ajouter aux DEUX listes d'exemption de 0012** (`guard_session_participant_cap`, `guard_session_overlap`) — sinon l'admin sera refusé par un déclencheur écrit pour tout autre chose. C'est exactement le défaut 2 déjà documenté dans 0012. |

---

## D-16 — Contrôleur : incognito uniquement

**Origine :** Normative (spec §1.1 et §11.6)

| | |
|---|---|
| **Sujet** | Le contrôle qualité en séance. |
| **Décision** | **Incognito uniquement.** Aucun micro, aucune caméra, aucune publication data. Ne figure pas dans la liste des participants visible. Chaque visite est auditée avec identité, session, entrée, sortie et durée. **On ne lui donne pas le choix d'un mode visible dans ce chantier.** |
| **Raison** | Un contrôleur visible n'observe plus la séance réelle. |
| **Conséquence dépôt** | **Ce flux existe déjà, complet, de bout en bout** (0012 : `rejoindre_observation`, invisibilité fermée sur quatre surfaces, exemption des deux déclencheurs, écriture `controller_observation_started` dans `audit_logs`) et CTR-01 est en production (`lib/features/controleur/`), avec bandeau permanent « visite journalisée ». **Agent G ne le refait pas : il le consomme.** Ce qui manque au Contrôleur, c'est l'accès **par groupe** — `mes_seances_v` raisonne par séance à élève unique, héritage 1-à-1. |

---

## D-17 — Feedback enseignant : occasionnel et agrégé

**Origine :** Normative (spec §1.1 et §12.1)

| | |
|---|---|
| **Sujet** | Le retour de l'élève/tuteur sur le cours. |
| **Décision** | **Micro-feedback occasionnel, ultra rapide, agrégé.** Un tap, terminé. Échantillonnage **configurable, pas systématique**. Questions **dynamiques et variables** : une même question ne revient qu'après que les autres ont été affichées. **Aucun commentaire obligatoire. Jamais de leaderboard public.** L'enseignant ne voit **jamais** « tel élève m'a mis telle note » : il voit une tendance agrégée, **et seulement après un seuil minimum d'échantillons**. |
| **Raison** | Un feedback systématique devient anxiogène et perd son sens ; un feedback nominatif détruit la relation pédagogique. |
| **Non négociable** | Les privilèges de fin d'année utilisent **un ensemble de signaux**. Le feedback élève/tuteur n'est qu'un **signal faible** parmi qualité, ponctualité, fiabilité, obligations et résultats de contrôle. **Aucun score brut n'est utilisé seul pour accorder un privilège.** |

---

## D-18 — Couleur du Groupe

**Origine :** Normative (spec §1.1 et §4.6)

| | |
|---|---|
| **Sujet** | Personnaliser un groupe. |
| **Décision** | Couleur d'identification choisie dans une **palette large et contrôlée**, cible **32 à 40 teintes/variantes accessibles**. **Jamais un sélecteur hex libre.** **La couleur n'est jamais le seul identifiant du groupe** : toute UI qui l'affiche affiche aussi le nom. |
| **Raison** | La personnalisation sert à **reconnaître** le groupe, pas à créer cent applications différentes. Pas de thèmes personnalisés, pas de fonds arbitraires, pas de layouts différents. Et une couleur seule est un défaut d'accessibilité — le dépôt tient déjà cette règle sous le nom d'invariant **J7** (« jamais une couleur seule »), appliqué par construction dans `StatusPill`, qui refuse une pastille sans libellé. |
| **Conséquence dépôt** | `groupes` n'a **aucune colonne couleur**. `lib/core/theme/app_palette.dart` est le **seul** fichier autorisé à poser une couleur littérale, et il est READ-ONLY. La palette administrée est donc **une demande à Agent Z**, pas une initiative d'agent. |

---

## D-19 — Le Groupe est permanent, la Classe Live est temporaire

**Origine :** Normative (spec §0, §4 et PROMPT 0)

| | |
|---|---|
| **Sujet** | La relation entre le Groupe et la séance. |
| **Décision** | **Le Groupe est l'espace pédagogique permanent. La Classe Live est un état temporaire du Groupe.** Le Groupe existe avant, pendant et après le cours. Y accèdent : les élèves inscrits, le tuteur légal d'un élève mineur, l'enseignant assigné et les rôles administratifs autorisés. Le Contrôleur **n'obtient pas** un espace Groupe complet par défaut : il accède aux séances qu'il doit observer. |
| **Raison** | C'est l'invariant qui rend cohérents la bibliothèque du groupe, la reprise de position, les assignations et le roster. Sans lui, chaque séance repart de zéro. |
| **Conséquence dépôt — bloquante** | **`public.sessions` n'a aucune colonne `groupe_id`**, aucune table de jonction n'existe, et `materialiser_seances()` lit `teacher_student_assignments` (le modèle 1-à-1 d'avant le pivot). **Un groupe créé aujourd'hui ne produit aucune séance.** L'invariant n'a donc **aucun support en base**. A, E et H travaillent contre des ports et des fixtures, et la demande SQL va dans `TC_CONTRACT_REQUEST_A.md`. ⚠ `0017` déclare explicitement que les deux modèles **coexistent** en attendant un lot dédié avec **audit RLS complet** : la suppression de `teacher_student_assignments` n'est pas dans ce chantier. |

---

## D-20 — Une seule Bibliothèque

**Origine :** Normative (spec §6 et PROMPT B)

| | |
|---|---|
| **Sujet** | La bibliothèque hors classe et la bibliothèque en classe. |
| **Décision** | **C'est la même.** Il n'existe pas `LibraryOutsideClass` et `LibraryInsideClass` comme systèmes séparés. En classe, elle s'ouvre comme un **panneau** (latéral ou sheet selon la largeur) et **la room LiveKit reste connectée**. Choisir une ressource remplace le support actif, sans quitter la salle. Ordre de découverte en classe : **Récents > Ce groupe > Tous les supports > Recherche**. |
| **Raison** | Deux bibliothèques divergeraient en contenu, en état offline et en droits. « Une fonctionnalité existe une seule fois » est un invariant produit, et « aucune page Groupe ne doit inventer une deuxième bibliothèque » est un critère de non-régression. |
| **Conséquence** | Agent A **ne code pas** de bibliothèque : il expose un slot rempli par `PortCatalogue`. Agent E **n'ouvre pas** une seconde surface : il utilise `ClassLibraryPicker` d'Agent B. |

---

## D-21 — Suivi automatique du professeur

**Origine :** Normative (spec §1.1)

| | |
|---|---|
| **Sujet** | Ce que voit l'élève pendant une présentation dirigée. |
| **Décision** | **L'élève suit automatiquement l'état partagé. Aucun bouton « Revenir au professeur » n'est requis.** Le zoom **local** de l'élève reste indépendant et ne casse pas la position pédagogique partagée. L'enseignant peut explicitement passer tout le groupe en affichage agrandi/focus. |
| **Raison** | Un élève de sept ans perdu dans le Mushaf ne va pas chercher un bouton. Le contenu pédagogique primaire prime sur le contrôle, qui prime sur le chrome UI. |

---

## D-22 — Nommage des rapports et des demandes

**Origine :** Arbitrage Agent 0

| | |
|---|---|
| **Sujet** | `docs/parallel-reports/` est déjà occupé par le chantier enseignant, avec **exactement les noms** que la spec nous prescrit. |
| **Décision** | **Aucun agent Teaching Core n'écrit dans `docs/parallel-reports/`.** Tous les livrables documentaires vivent dans **`docs/teaching-core/`**, préfixés `TC_` :<br>• rapport → `docs/teaching-core/TC_AGENT_<X>_REPORT.md`<br>• demande → `docs/teaching-core/TC_CONTRACT_REQUEST_<X>.md`<br>• libellés → `docs/teaching-core/i18n/tc_i18n_<X>.json`<br>• plan de test → `docs/teaching-core/TC_TEST_PLAN.md` |
| **Raison** | Le chantier enseignant a déjà créé `AGENT_A_REPORT.md` … `AGENT_E_REPORT.md`, `CONTRACT_REQUEST_A.md` … `CONTRACT_REQUEST_E.md` et `i18n_A.json` … `i18n_E.json`. **La collision serait totale sur A, B, C, D et E** — et silencieuse, puisque ces fichiers sont invisibles depuis nos worktrees. |
| **Lecture recommandée** | `docs/parallel-reports/02-livekit-audit.md` (audit du 14/09, 308 lignes) est **dans notre baseline** et reste **à lire** avant tout travail LiveKit. Lecture seule. |

---

## D-23 — Fidélité Mushaf : STOP obligatoire, pas d'improvisation

**Origine :** Arbitrage Agent 0, sur la base de la spec §7.2

| | |
|---|---|
| **Sujet** | Le mode Mushaf 604 pages fidèle. |
| **Décision** | **Les données du dépôt ne permettent pas la fidélité demandée. Agent C ne fabrique pas une fausse page.** Il livre : (a) un `PortLayoutMushaf` **enfichable** avec une implémentation `LayoutIndisponible` qui rend un état **explicite** ; (b) les deux modes réellement faisables — **mode verset reflowable responsive** et **mode focus/classe** ; (c) `docs/teaching-core/TC_CONTRACT_REQUEST_C.md` chiffrant le manque. `DisponibiliteLayout` ne vaut **jamais `fidele`** sans données de ligne réelles. |
| **Raison** | Trois manques cumulés, chacun suffisant. **(1)** `verset.ligne` est NULL sur les **6236** lignes : `0013` ne l'insère pas, délibérément, parce que le layout QPC v2 compte **83 668** mots contre **77 881** pour Tanzil et qu'elle refuse de deviner une correspondance sur un texte sacré. **(2)** Aucune granularité sub-verset : `verset.page_numero` désigne la page où le verset **commence**, donc un verset à cheval sur deux pages est attribué à une seule, et on ne peut pas couper une page au bon mot. **(3)** Aucune police glyphe-par-page ni asset de layout : `UthmanTahaNaskh-Regular.otf` est une police de texte courant, la largeur des lignes dépend du moteur de texte et non de l'édition — et `docs/architecture/etape-5-salle-coran-presence.md` (lignes 89-93) laisse la question **explicitement ouverte**. La spec §7.2 tranche d'avance : « si les données disponibles ne permettent pas une fidélité suffisante, l'agent doit STOP et documenter le manque. Il ne doit pas improviser une composition. » |
| **Options à chiffrer dans la demande** | (a) peupler `verset.ligne` par migration à partir d'une source portant texte **et** lignes ; (b) acquérir un jeu de polices QCF (604 fichiers) **avec sa licence** ; (c) embarquer un fichier de coordonnées de layout. Toutes passent par Agent Z (migration et/ou `pubspec.yaml` et/ou `assets/`). |
| **Point juridique à nommer** | `assets/fonts/` contient un fichier de licence pour Bricolage, InstrumentSans et Phosphor, **mais aucun pour UthmanTahaNaskh ni pour NotoSansArabic**. Une police du Complexe du Roi Fahd redistribuée sans notice est un risque à signaler, pas à ignorer. |

---

## D-24 — Session persistante : le shell ne possède pas la room

**Origine :** Normative (spec §9.4) + arbitrage Agent 0 sur le chemin

| | |
|---|---|
| **Sujet** | Naviguer pendant un cours. |
| **Décision** | **Le contrôleur de room/session est au niveau applicatif, pas attaché au widget de la page Classe.** Retourner au Groupe, à l'Accueil ou ouvrir la Bibliothèque **ne coupe pas volontairement LiveKit**. Une **barre compacte « Cours en cours »** permet de revenir instantanément. Si l'OS suspend réellement le processus, on applique la machine de reconnexion existante — **sans promettre une connexion impossible** lorsque la plateforme tue le réseau. |
| **Raison** | « Naviguer dans Rewayah ne doit pas, à lui seul, couper la classe Live active » est un invariant produit. |
| **Conséquence dépôt** | Le moteur **est déjà** un Provider racine (`moteurSalleProvider`), donc unique pour l'application — **le socle est bon**. Mais `_SallePageEtat.initState()` appelle `_entrer()` et `dispose()` appelle inconditionnellement `_moteur.quitter()` (`salle_page.dart:111` et `:122`), et `/salle` **n'est dans aucune `ShellRoute`**. **Agent E ne corrige pas `salle_page.dart`** : le fichier est PROTECTED. Il construit `PortSessionPersistante` et son implémentation dans `lib/core/tc_classe/`, et demande à Agent Z l'arbitrage de routage. |
| **Détail à reproduire à l'identique** | La sortie volontaire appelle `annoncerSortie` (→ `quitter_salle`, `source='user_action'`) **AVANT** `_moteur.quitter()`, et le webhook déduplique dans une fenêtre de 30 s. **L'ordre est porteur d'information.** ⚠ Mais `annoncerSortie` **avale volontairement l'échec** : acceptable pour une trace, **inacceptable** si ce geste doit fermer un quota d'observation (voir D-14). |

---

## D-25 — Politique d'enregistrement audio : ne pas la redéfinir

**Origine :** Normative (spec §1.2)

| | |
|---|---|
| **Sujet** | Les anciens documents se contredisent sur l'enregistrement audio. |
| **Décision** | **Ce chantier ne redéfinit pas cette politique.** Les agents **consomment** la politique existante et **ne créent pas une nouvelle règle**. |
| **Raison** | Une règle d'enregistrement inventée par un agent de feature deviendrait une troisième version contradictoire. |
| **État du dépôt, pour information** | `session_recordings` (0001) est une table de **métadonnées sans producteur** : aucun `startEgress`, aucune configuration R2, aucune URL signée (audit 02 §7), et `recording_retention_days = 30` dans `app_config`. **Hors périmètre Teaching Core — mais à ne pas croire acquis.** |

---

## D-26 — Stubs de port pendant la phase parallèle

**Origine :** Arbitrage Agent 0

| | |
|---|---|
| **Sujet** | Un consommateur ne peut pas compiler tant que le producteur n'a pas publié son port. |
| **Décision** | Le consommateur déclare un **stub local** dans son **propre répertoire possédé** : `lib/core/tc_<son_domaine>/ports_externes/<nom_du_port>.dart`, avec l'en-tête `// TC-STUB-PORT: canonique = <chemin> (Agent <X>)`. Le stub contient **uniquement** la classe abstraite et les types de valeur, **copiés à l'identique** depuis `TEACHING_CORE_CONTRACTS.md`. Jamais une implémentation. Agent Z les supprime à l'intégration. |
| **Raison** | La spec exige que « chaque feature expose son API publique minimale et compile avec mocks/adapters locaux ». Sans convention, chaque agent inventerait sa propre copie, elles divergeraient, et l'intégration échouerait au moment le plus coûteux. Le stub vivant dans un répertoire **possédé**, la disjonction de l'ownership est préservée. |
| **Sanction** | Toute divergence entre un stub et le contrat canonique est un **BLOCKER** au contrôle pré-merge. Un agent qui a besoin d'une méthode absente du contrat **ne l'ajoute pas à son stub** : il écrit un CONTRACT_REQUEST. |

---

## D-27 — `namespaces` slang : bonne cible, mauvais moment

**Origine :** Arbitrage Agent 0

| | |
|---|---|
| **Sujet** | Fallait-il activer `namespaces: true` dans `slang.yaml` et éclater `fr.i18n.json` ? |
| **Décision** | **Non, pas maintenant.** C'est la bonne cible **à terme** : elle supprimerait la collision i18n **à la source**, en donnant à chaque agent son propre fichier de libellés. Mais elle exige de modifier `slang.yaml`, d'éclater un fichier de 68 Ko et de **régénérer 244 Ko de code versionné**, le tout pendant que le chantier enseignant est **en vol** sur ces trois mêmes fichiers. On retient donc le mécanisme D-03, moins élégant et bien moins risqué. Agent Z pourra proposer la bascule **après** l'intégration, comme un lot à part entière. |
| **Raison** | Le bon arbitrage n'est pas « quelle solution est la meilleure » mais « quelle solution ne casse pas un chantier qui tourne ». Une régénération complète de `strings_fr.g.dart` pendant que l'autre chantier y écrit produirait un conflit **non fusionnable à la main**, sur le fichier le plus gros du dépôt. |

---

## D-28 — Ordre d'intégration et rôle d'Agent Z

**Origine :** Normative (spec, PROMPT immuable Z)

| | |
|---|---|
| **Sujet** | Dans quel ordre les branches rejoignent l'intégration. |
| **Décision** | Ordre **immuable** : contrats partagés → **B** Library → **C** Quran → **A** Group Space → **H** Academic Flow → **D** Teaching Tools → **F** Realtime → **E** Classroom Shell → **G** Observation → **Q** QA final. Après **chaque** intégration : `flutter analyze`, tests concernés, build ciblé, contrôle des routes et du wiring, **aucun redesign opportuniste**. La branche `integration/teaching-core` part du **`TARGET_SHA`** incluant l'Admin/enseignant finalisé, **jamais** de `TEACHING_BASELINE_SHA`, et **jamais** directement dans `main`. |
| **Raison** | L'ordre suit les dépendances de contrats : B produit `ContentPosition`, `ContentRange` et `LibraryResource`, dont dépendent C, D, F et H. E arrive tard parce qu'il consomme cinq ports. |
| **Conséquence pour les agents** | **Aucun agent ne merge vers `main`. Aucun agent ne rebase sur une branche feature.** Un conflit Git ne se résout **jamais** mécaniquement par `ours`/`theirs` : on comprend la propriété du fichier et on préserve la décision **la plus récente et la plus normative**. |
| **Condition de départ** | Aucune intégration tant qu'un seul lot est `BLOCKED` au contrôle pré-merge. |

---

## Annexe — Les douze invariants que la Phase 6 d'Agent Z devra prouver

Ils ne sont pas négociables et chacun renvoie à une décision ci-dessus.

1. Une seule Library — *D-20*
2. Un seul Quran source of truth — *D-09*
3. Un seul LiveKit provider — *MAPPING §9.4*
4. Un seul router — *D-04*
5. Aucune PII famille chez l'enseignant — *D-08, CONTRACTS §0 et §12*
6. Aucune annotation ne modifie la source — *CONTRACTS §5 et §10*
7. Aucune visite tuteur hors quota — *D-14*
8. Aucune entrée précoce ne fausse la présence — *D-13*
9. Aucun DST calculé par offset hardcodé — *CONTRACTS §3*
10. Aucun « mode enfant » visible dans le produit — *D-07*
11. Sayyid/Sayyida partout dans le contexte cours — *D-02*
12. Aucune commande vocale implémentée — *D-10*
