# Audit du parcours des familles : les angles morts avant l'arrivée en nombre (22/11/2026)

Demande du directeur (22/11/2026) : « une vision d'ensemble de tout le parcours pour voir les angles morts ; regarde surtout les expériences du parcours enseignant qui sont consignées, les erreurs à éviter ». Les inscriptions des familles commencent : 279 courriels en file, 4 demandes acceptées en production (2 élèves adultes, 2 familles, lues le 22/11).

**Ce qui est faux, inconnu ou non prouvé, en premier.**
- Rien ici n'est « fait » : « fait » veut dire « prouvé par le directeur en production ». Cet audit lit le code de `main` et la production en lecture seule. Aucune famille n'a encore parcouru le chemin complet jusqu'à un premier cours.
- Le dépôt et la production sont à jour sur les lots du 22/11 (onboarding, source `?ref`, frise, aperçu des horaires avec La Mecque) : les fonctions existent en production (lu le 22/11). Les noms des migrations enregistrées en production ne sont pas ceux des fichiers du dépôt : on ne peut pas comparer par le nom, seulement par l'objet.
- Non vérifié : ce que fait le serveur d'envoi sur un rebond de courriel ; si une famille en attente peut ouvrir `/attente/messages` ; l'effet réel d'un changement d'heure sur une classe déjà formée (le code le prévoit, aucune classe de famille n'existe pour l'essayer).

**Méthode.** Chaque étape est lue dans le code (fichier:ligne ou migration) puis confrontée aux leçons du parcours enseignant (`RETOURS-TERRAIN-INSCRIPTIONS.md` : L1 à L12, R1 à R44, M1 à M4). Gravité : **bloquant** (une famille ne peut pas avancer, ou on lui promet ce qui n'est pas tenu), **important** (la famille avance mais perd confiance, ou la direction ne voit pas), **confort**.

## Ce qui est déjà tenu (leçons enseignant appliquées aux familles)

- Adresse mal tapée (R25) : suggestion « Vouliez-vous dire gmail.com ? » à la connexion et au questionnaire (`lib/core/auth/suggestion_courriel.dart`, `connexion_page.dart:952`, `acces_questionnaire.dart:278`).
- Lien par courriel dans la langue (R10, R27) pour un compte neuf : `service_auth.dart:90-97` envoie `data.langue` ; sujets et corps par langue (`supabase/templates/sujets.txt`).
- Lien ouvert ailleurs (R28, FN-111) : message dédié et code à six chiffres (`lib/features/connexion/lien_ailleurs.dart`, `saisie_code_courriel.dart`).
- Choix « apprendre ou enseigner » dès l'entrée (R23, R29, D10 de `ONBOARDING-PRAXIS-2026-11-22.md`).
- Aucun horaire inventé : l'onboarding ne demande pas d'horaire avant l'admission (D6) ; la carte d'accueil dit « aucun horaire ne correspond » (`carte_horaire.dart:10`).
- Fuseau : lu sur l'appareil, jamais par défaut (D12) ; l'heure de la personne d'abord, celle de La Mecque en second (`20261130988000_apercu_offre_mecque.sql`).
- `?ref` gardé 30 jours, noté une fois au compte (`lib/core/source_inscription/source_inscription.dart`, migration `ref_suivi`).
- Suppression et pause : le serveur existe (`20261108600000_supprimer_comptes.sql`, `20261123910000_calendrier_pauses.sql`).

## Étape 1. Site public, lien `?ref`, vers la connexion

| Ce qui existe | Angle mort | Gravité | Preuve | Correctif | Leçon |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Le site recopie `ref` sur ses liens (`site-public/build_site.py:109-123`) ; l'application le garde et le note une fois connectée. | La note part seulement quand la session existe (`source_inscription.dart:96`). Lien ouvert sur un autre appareil : le `ref` reste sur le premier. La question « Comment avez-vous connu Rewayah ? » reste posée, c'est voulu. | confort | `source_inscription.dart:92-117` ; `ONBOARDING-PRAXIS` §7.6 dit « `?ref=` absent de main » : faux depuis #699. | Corriger la phrase fausse du §7.6 ; rien d'autre. | R7 |
| Le site dit : « pas d'essai gratuit, vous payez au début, 14 jours » (`site-public/content/pages.json`). | Rien dans l'application ne dit « vous payez au début » avant le premier cours (étape 8). | important | `pages.json` (phrases « Vous payez au début », « remboursons… moins les séances déjà suivies »). | Mettre le premier paiement dans la frise et dans le courriel d'acceptation. | R36 |
| Prix du site : dollars, hors taxes (`tarifs-2026-10-18.json`). | La famille d'Europe ou du Royaume-Uni lit « hors taxes » : aucune taxe n'est calculée au paiement (aucune trace de taxe dans `recharge-payer` ni dans les migrations). Ni le site ni l'onboarding ne disent en quelle devise on débite. | important | Recherche `automatic_tax`, `tax_rate` sans résultat dans `supabase/functions` et `supabase/migrations`. | Décision du directeur : taxes (oui ou non, qui), puis une phrase sur la devise avant la demande. | L5 |

## Étape 2. Connexion et lien par courriel

| Ce qui existe | Angle mort | Gravité | Preuve | Correctif | Leçon |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Lien par courriel, code à six chiffres, Google, anti-robot. | La langue du lien repose sur la langue de l'appareil au premier envoi. Une famille qui revient, dont le compte n'a pas de langue enregistrée, reçoit les courriels suivants en français (étape 5). | important | `service_auth.dart:90-97` ; production : 0 compte sur 4 a une langue (lu le 22/11). | Écrire la langue de l'interface au compte dès `inscrire_titulaire` (correctif 2). | R27 |
| Blocage anti-robot corrigé (R43). | Une personne bloquée à l'entrée ne peut pas nous écrire de l'intérieur. L'aide du compte exige un compte valide : sans compte, aucune sortie. | important | `canal_support()` lève « compte inactif » sans compte valide (production, lu le 22/11) ; `aide_page.dart:18-60`. | Ligne « Une difficulté pour entrer ? Écrivez à support@ » sur la connexion et sur la page d'attente. | R30, R41, L8 |
| Lien demandé 9 fois (R41) : message de panne. | « À faire » encore ; le même écran sert aux candidats et aux familles. | confort | `RETOURS-TERRAIN` R41. | Poser le message de panne une fois pour tous. | R41 |

## Étape 3. Onboarding avec Praxis

| Ce qui existe | Angle mort | Gravité | Preuve | Correctif | Leçon |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Questionnaire avant le compte, une question par écran, plusieurs enfants, langue des explications, lecture, fuseau (`lib/features/inscription/questionnaire/`). | La **langue de l'interface** n'est écrite nulle part pour la famille : `inscrire_titulaire` ne reçoit ni ne pose `candidatures.langue` ni `profiles.langue_communication`. | bloquant pour les familles non francophones | `20261130979000_onboarding_praxis.sql:160-330` (aucune écriture de langue de compte) ; production : 26 courriels de famille envoyés, tous en `fr` ; 0 compte sur 4 avec une langue. | Passer la langue de l'interface à `inscrire_titulaire` et l'écrire sur la candidature (la suite existe : `courriel_langue_a_l_entree`, étape 3 de `20261130966000`). | R10, R27, L6 |
| Le récapitulatif dit : « remboursé dans les 14 jours, moins les séances déjà suivies ». | Aucun prix, aucune devise, aucun « on paie quand ». La famille ne voit un prix qu'après l'acceptation (`/tuteur/foyer/prix`). | important | `assets/i18n/fr.i18n.json`, clés `onboarding.recap.*` : seule la ligne de remboursement parle d'argent. | Une ligne avec le prix par mois et « payé au début », lue de la politique, jamais écrite en dur. | R36 |
| Frères et sœurs : l'écran final dit que « chacun aura sa classe et son enseignant » (D7). | Rien dans le serveur n'empêche deux enfants du même foyer d'être regroupés dans la même classe : ni le regroupement ni la création de classe ne lisent le foyer pour les séparer. La promesse n'est tenue que si la direction y pense. | important | `0077_regroupements_admin_c11bis.sql:137,218` (le foyer sert à l'heure, pas à séparer) ; aucune règle « un foyer, une classe » trouvée (recherche `fratrie`, `meme_classe`). | Règle serveur au regroupement : deux élèves d'un foyer ne partagent pas une classe, sinon avertissement à la direction. | L1 |
| Un adolescent de moins de 18 ans seul est orienté vers un parent. | Cul-de-sac possible : un jeune sans parent proche n'a aucune suite. | confort | `ONBOARDING-PRAXIS` §7.5. | Une phrase « Demandez à un parent d'ouvrir la demande avec vous ». | R30 |
| Brouillon gardé sur l'appareil. | Famille qui commence sur le téléphone et termine sur l'ordinateur : brouillon absent. | confort | `memoire_appareil_web.dart`, `brouillon_inscription.dart`. | Le dire en une phrase. | L1 |

## Étape 4. Demande d'admission et attente (`/attente`)

| Ce qui existe | Angle mort | Gravité | Preuve | Correctif | Leçon |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Page « Votre demande est en cours » ; frise de l'inscription (`frise_inscription.dart`) ; courriel `admission_recue` (22 envoyés, lus le 22/11). | La page dit : « Nous vous écrivons à votre adresse dès que la direction a répondu ». Si l'adresse est fausse ou le courriel rebondit, la famille n'a aucune autre voie, et la direction ne voit aucun rebond. | important | `attente_page.dart:628-700` ; aucun écran de rebond côté direction (recherche dans `lib/features/admin_*`). | Afficher à la direction « courriel non distribué » sur la demande ; proposer à la famille « Vérifier mon adresse » depuis `/attente`. | R25, R42 |
| « Lue par la direction » reste « en cours » tant que rien n'est décidé. | Honnête, mais aucune date de réponse : la famille ne sait pas combien de temps attendre. | important | `frise_inscription.dart:1-25` ; `attente_page.dart:520`. | Écrire le délai réel que tient la direction (décision du directeur), ou « sans délai promis » en clair. | R33, L1 |
| Messagerie et aide. | Une famille en attente n'a **aucun** bouton « Écrire à la direction » : la page ne donne que « répondez à l'e-mail ». `/attente/messages` existe pour les candidats ; rien ne prouve qu'une famille y entre. | bloquant | `attente_page.dart:628-700` (pas d'entrée de messages) ; `entree_messages_contexte.dart:69` ; `MESSAGERIE-MATRICE.md` ligne 9 (rôle « candidat »). | Poser l'entrée « Écrire à la direction » sur `/attente` pour la famille et ouvrir la route à son rôle. | R1, L3, R30 |
| Modifier sa demande. | Après l'envoi, la famille ne peut rien corriger (âge, prénom, langue, lecture) avant la décision. Le récapitulatif promet « réponses corrigeables après l'acceptation ». | important | Aucun geste de modification sur `/attente` ; `ONBOARDING-PRAXIS` §3 point 4. | Passer par la messagerie (correctif 3) ; une demande de correction visible ensuite. | R34, L2 |
| Retrait. | Pas de retrait de demande pour la famille : pas de risque R31, mais pas de sortie non plus. | confort | `attente_page.dart` : aucun retrait ; production : les 17 demandes « retirées » sont les comptes égarés d'enseignants (PE-A4). | Laisser ainsi ; si un retrait est ajouté, il se défait seul pendant un délai. | R31, L9 |

## Étape 5. Décision de la direction : accepter, à compléter, refuser

| Ce qui existe | Angle mort | Gravité | Preuve | Correctif | Leçon |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Accepter : courriel `admission_acceptee`, compte actif, profils des enfants rendus actifs (`20261030140000_admission_lot_c.sql:170-205`). | Le courriel dit seulement « Votre espace est ouvert : entrez dans l'application ». Il ne dit pas la suite : choisir un horaire, puis payer. Quatre courriels envoyés, tous en français. | bloquant | `modeles_fr.ts:95-97` ; production : `admission_acceptee`, 4 envoyés, langue `fr`. | Réécrire le courriel : 1) choisir un horaire, 2) vous serez prévenu quand la classe est prête, 3) paiement au début. | R22, R33, L10 |
| À compléter : courriel `admission_precisions` et phrase sur `/attente`. | « Répondez simplement à l'e-mail » : aucune boîte de réception n'est reliée à la demande (aucun traitement de courriel entrant dans le dépôt). La direction doit lire une boîte, retrouver la demande et la rouvrir à la main. La famille ne peut pas répondre dans l'application. | bloquant | clé `attente.precisionsReponse` ; recherche `courriels_entrants`, `imap` sans résultat ; R42 : 12 fils sans réponse. | Réponse dans l'application (correctif 3) ; la réponse remet la demande « à traiter » chez la direction. | R1, R42, L3 |
| Refuser : courriel `admission_refusee` avec motif prédéfini (`modeles_fr.ts:31-36`). | La famille ne voit pas le motif dans l'application : la page dit « L'e-mail que nous vous avons envoyé vous en dit la raison ». Un courriel perdu ou en spam, et le motif n'existe plus pour elle. Aucune sortie. | important | clé `attente.demandeRefuseeDetail` ; contraste avec l'enseignant refusé, dont `etat.motifRefus` s'affiche (`attente_page.dart:521-545`). | Afficher le motif sur `/attente` et la voie « écrire à la direction ». | R30, R33 |
| Annuler une acceptation (7 jours) : aucun courriel (`annuler_admission`). | Le compte repasse en attente sans un mot : la famille voit « Votre demande est en cours » comme au premier jour. | important | `20261030140000_admission_lot_c.sql:268-271` (« Aucun e-mail »). | Message « La direction reprend l'examen de votre demande », ou geste « Écrire » imposé avant d'annuler. | R26 |
| Annuler un refus (7 jours) : la demande revient « en cours ». | Aucun courriel non plus : une famille qui a lu « nous ne pouvons pas donner suite » ne saura pas qu'elle est rouverte. | important | `annuler_refus_admission` (même fichier). | Même courriel. | R31 |
| Écran de la direction (`admissions_page.dart`). | Les gestes existent ; manquent l'ancienneté de chaque demande et un tri « les plus anciennes d'abord » : avec 279 lettres, la file se creuse en désordre. | important | `admissions_page.dart` (liste et pagination ; aucune colonne d'ancienneté ni signal de retard). | Colonne « en attente depuis » et vue « à répondre » par ancienneté. | R14, L3 |

## Étape 6. Fiches des élèves et plusieurs enfants

| Ce qui existe | Angle mort | Gravité | Preuve | Correctif | Leçon |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Profils créés depuis les réponses, rien à ressaisir (`candidature_apprenants.profil_eleve_id`). | Donnée possiblement saisie deux fois : prénom et âge demandés à l'onboarding, puis le tuteur peut devoir confirmer l'âge dans la fiche (`choix_age.dart`). Non vérifié. | confort | `lib/features/foyer/choix_age.dart` ; `ONBOARDING-PRAXIS` D6. | Vérifier que la fiche reprend l'âge de l'onboarding. | K-57 |
| Accueil de la famille par enfant (`parcours_du_profil_choisi.dart`, carte d'horaire par enfant). | Plusieurs enfants dans des classes différentes : la frise de l'inscription est par demande, la frise de classe par enfant ; l'ordre dans lequel les enfants passent à « horaire à choisir » n'est pas expliqué. | confort | `accueil_famille_page.dart:516-571`. | Une ligne par enfant en tête de l'accueil. | R33 |
| Direction : réponses de la demande lues (#701), nouveaux champs (#705). | À prouver par le directeur. | confort | `REGISTRE-LOTS.md`, ligne PARCOURS-BOUT-EN-BOUT. | Preuve par le directeur. | R24 |

## Étape 7. Choix d'offre et d'horaire, créneau sur mesure, fuseaux

| Ce qui existe | Angle mort | Gravité | Preuve | Correctif | Leçon |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Cartes d'offre (jours, heures, sans nom d'enseignant) ; aperçu à l'heure de la famille puis à La Mecque. | Aucun horaire ouvert : la carte propose « Me prévenir si de nouveaux horaires ouvrent ». **Rien ne lit ni n'envoie cette demande** : le geste écrit une ligne `matching_requests` de nature `horaire_insatisfait`, qu'aucun écran de la direction ne lit, et la publication d'une offre n'envoie aucun avis. | bloquant | `carte_horaire.dart:10,129` ; `0043_offres_horaires_et_intentions.sql:880-909` ; recherche `horaire_insatisfait` dans `lib/` : seul `service_offres.dart:223` l'écrit ; aucune notification liée à la publication d'une offre. | Relier : à la publication d'une offre, avis aux familles en attente concordantes ; écran « familles en attente d'un horaire » pour la direction. Sinon retirer la promesse du libellé. | R22, R32, L10 |
| Créneau sur mesure : quota de 5 enfants ou 6 adultes avant ouverture. | La famille ne sait pas combien de temps ce créneau peut rester sans classe ; la décision du 09/10 interdit de montrer le nombre de demandeurs, donc la phrase doit dire autre chose. | important | `DECISION-OFFRES-GROUPES-2026-10-09.md` §2 ; `demander_creneau_personnalise` (`0049`). | Phrase « La classe s'ouvre quand assez de familles choisissent ce moment ; vous serez prévenu. Rien d'autre à faire. » | R22, L10 |
| Heure fixée à La Mecque ; changement d'heure annoncé (« votre cours du mercredi passe de 19:00 à 20:00 »). | Une classe de familles de deux hémisphères voit son heure locale bouger à des dates différentes : prévu dans l'aperçu, non éprouvé sur une classe réelle. | important | `20261130988000_apercu_offre_mecque.sql` ; `mots-rewayah` ligne 60. | Essai de bout en bout avec une classe d'essai avant la première vague. | R19 |
| Fuseau lu sur l'appareil. | Une famille qui déménage ou voyage : le fuseau du profil est celui du jour d'inscription. Où se change-t-il ? Non vérifié. | confort | `ONBOARDING-PRAXIS` D12. | Vérifier le geste dans « Compte ». | R38 |

## Étape 8. Paiement (prix, devise, échec, remboursement 14 jours)

| Ce qui existe | Angle mort | Gravité | Preuve | Correctif | Leçon |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Recharge par profil, formulaire dans l'application, factures mensuelles, relances J-7/J-3/J-1, suspension le 4 (`20261018170000_fac_f_relances_suspension.sql`). | **Aucune étape de paiement dans la frise de l'inscription ni dans le courriel « Tout est prêt »**, alors que le site dit « vous payez au début » et que `DECISION-TARIFS` dit « on paye avant de commencer les cours ». Le premier paiement n'est ni demandé ni daté. La suspension ne joue que si une facture reste impayée après son échéance. | bloquant | `frise_inscription.dart:60-85` (sept étapes, aucune de paiement) ; `modeles_fr.ts:207-218` (aucun mot sur le paiement) ; `DECISION-TARIFS-2026-10-18.md` (décision du 01/11). | Une étape « Premier paiement » dans la frise ; les avis `classe_validee` et `tout_est_pret` disent quoi payer et avant quand. Le directeur tranche : le premier cours est-il refusé tant que rien n'est payé ? | R33, R36, L10 |
| Prix en dollars. | Une famille européenne paie en dollars : aucun choix de devise visible ; taxes absentes (étape 1). | important | `tarifs-2026-10-18.json` (`devise: USD`) ; `format_montant.dart` connaît EUR et GBP mais la politique ne les publie pas. | Décision du directeur : dollars seulement, dit clairement avant la demande. | R36, R37 |
| Échec de paiement : page de résultat qui relit l'état. | L'échec de la première recharge est le premier contact d'argent de la famille : le message dit-il quoi faire (K-59) ? Non éprouvé avec une vraie carte refusée. | important | `app_router.dart:1313` (`result`) ; `suivi_paiement.dart`. | Essai avec la carte d'essai de Stripe et captures. | R19 |
| Remboursement de 14 jours ; D11 : « moins les séances déjà suivies ». | La règle n'est pas harmonisée : départ du délai, mois réservé, arrêt temporaire et suppression d'un profil se contredisent. Supprimer un profil ne touche à aucun compte d'argent. | important | `A-HARMONISER-REGLES-ARGENT-ET-ARRET.md` (dette ouverte) ; `20261108600000_supprimer_comptes.sql:34` ; pause : préavis de 7 jours (`20261123910000_calendrier_pauses.sql:19,68`). | Décider le lot HARMONISER-ARGENT avant les premiers paiements ; en attendant, l'écran de suppression dit la règle. | L5 |

## Étape 9. Formation de la classe, enseignant, absence et remplacement

| Ce qui existe | Angle mort | Gravité | Preuve | Correctif | Leçon |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Regroupement automatique, « Créer la classe », proposition d'enseignant ; avis `classe_validee`, `enseignant_affecte`, `tout_est_pret` (5 `enseignant_affecte` envoyés, en français). | La famille voit « Classe en formation » sans date ni volume : la décision du 09/10 interdit de dire combien de demandes. Il faut dire autre chose (le rythme réel de la direction). | important | `frise_inscription.dart` ; `DECISION-OFFRES-GROUPES` §4. | Phrase de rythme donnée par le directeur. | R33 |
| Enseignant absent : courriels `enseignante_absente`, `seance_annulee`, `remplacement_*` aux familles. | Le texte lu par la famille doit rester au masculin générique (`mots-rewayah` ligne 20) ; à relire dans les quatre langues. | confort | `modeles_fr.ts` ; `mots-rewayah` ligne 20. | Relecture des textes, pas des clés. | M4 |
| Remplaçant : règle unique (`DECISION-REMPLACEMENT-2026-11-07.md`). | Le paiement du remplaçant (P5) et l'avertissement avant perte de la classe (A2) du guide ne sont pas tenus : cela touche la fiabilité promise aux familles. | important | `RESTE-A-FAIRE.md` §0 ; `REGLES-NOUVELLES.md`. | Poursuivre les lignes P1 à P5, A2 à A6. | R36 |
| Capacité réelle. | 4 familles acceptées, 5 `enseignant_affecte` envoyés : la capacité à absorber 279 familles n'est pas mesurée (places libres par langue, genre et public). | bloquant | `courriels_sortants` (lu le 22/11) ; aucune vue « capacité » trouvée dans `admin_tableau`. | Une ligne de tableau de bord : places libres par langue, genre et public. | L5 |

## Étape 10. Salle, premier cours, compte rendu, suivi parent

| Ce qui existe | Angle mort | Gravité | Preuve | Correctif | Leçon |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Une salle `/salle` pour tous les rôles ; préparation avant la séance (`liste_preparation.dart`, `salle_rejoignable.dart`). | Le jeton refuse un élève suspendu pour paiement (`create-room-token`), mais un nouvel élève n'est suspendu qu'après une échéance impayée : sans premier paiement, le premier cours peut se tenir. | important | `create-room-token/index.ts:142-204` ; `fac_eleve_suspendu` ne lit que les suspensions posées (`20261018170000`, l.157-166). | Décision liée à l'étape 8 : l'accès au premier cours exige le premier paiement. | L1 |
| Compte rendu : cahier de l'enseignant, avis de séance terminée, bloc de suivi du parent (`bloc_compte_rendu.dart`). | Langue : l'enseignant écrit dans sa langue ; la famille la lit-elle traduite ? Non vérifié. | important | `suivi_foyer/bloc_compte_rendu.dart` ; `20261103600000_seance_terminee_avis.sql`. | Vérifier la traduction à l'envoi comme pour les annonces (`annonces_fermer_traduire`). | R27, M4 |
| Plusieurs enfants dans des classes différentes. | Une famille de deux enfants à deux horaires reçoit-elle deux avis séparés ? La portée « foyer » est prévue ; à essayer avec deux enfants. | confort | `20261108100000_courriels_ux.sql:21`. | Essai avec deux enfants. | R33 |

## Étape 11. Messagerie et aide (support@)

| Ce qui existe | Angle mort | Gravité | Preuve | Correctif | Leçon |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Page « Aide » du compte (`/tuteur/compte/aide`) lisant `canal_support()`. | **Le canal d'aide n'est pas configuré en production** : la ligne `support_canal` de `app_config` n'existe pas (lu le 22/11). La page dit « aucun canal ». Le site, lui, publie `support@rewayahacademy.com`. | bloquant | Production : lecture de `app_config` pour `support_canal`, aucune ligne ; `aide_page.dart:18-60` ; `site-public/content/pages.json:37`. | Un geste de la direction : `configurer_canal_support('courriel', 'support@rewayahacademy.com')` (à ordonner par le directeur ; aucune écriture faite ici). | R30, R42 |
| Messagerie « Écrire à … » dans la classe, le dossier, la cloche (matrice). | Qui répond, en combien de temps ? 12 fils sans réponse chez les candidats ; une seule personne répond. | bloquant | `RETOURS-TERRAIN` R42. | Fixer qui répond aux familles et le délai affiché, avant le premier envoi de masse. | R42 |
| Photos dans la messagerie. | Règle d'origine du stockage (CORS) à vérifier avant d'ouvrir les photos aux familles. | important | `RETOURS-TERRAIN` M3. | Vérifier en production. | M3, R35 |

## Étape 12. Arrêt, suppression, données

| Ce qui existe | Angle mort | Gravité | Preuve | Correctif | Leçon |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Pause d'un mois (préavis, 2 mois sur 12) ; suppression de compte et de profil ; export `mes-donnees`. | Pas de règle codée pour « arrêt en cours de mois » : la famille ne sait pas ce qu'elle doit pour le mois commencé. | important | `A-HARMONISER-REGLES-ARGENT-ET-ARRET.md` règle 4 (décidée le 07/11, non codée) ; `calendrier_pauses.sql:68`. | Coder la règle 4 ; une phrase avant la confirmation. | L9 |
| Geste d'abandon (quitter une classe, supprimer un profil). | Aucune annulation pendant un délai côté famille. | important | `20261108600000_supprimer_comptes.sql` ; la restauration existe seulement côté direction (`supprimer_bis_restaurer`). | Délai de reprise visible pour la famille. | R31, L9 |
| Compte désactivé ou suspendu. | La seule sortie est « Contacter l'académie », un lien vers les mentions légales. | important | `attente_page.dart:560-585` (commentaire COMPTE-SUSPENDU). | Remplacer par le canal d'aide configuré (correctif 1). | R30 |

## Côté direction : où voit-elle chaque étape et que doit-elle faire ?

| Étape | Où | Ce qui manque | Gravité |
| :-- | :-- | :-- | :-- |
| Demande reçue | `admin_admissions` (gestes accepter, préciser, refuser, annuler) ; notification `admission_recue`. | Ancienneté et tri ; courriel non distribué. | important |
| Réponse de la famille | Boîte de courriels lue par un humain ou Praxis. | Aucun lien entre la réponse et la demande ; aucune relance automatique. | bloquant |
| Horaire à choisir | `admin_regroupements`, `admin_demandes`. | Les familles qui ont touché « Me prévenir » sont invisibles. | bloquant |
| Classe à créer | « Créer la classe », proposition d'enseignant. | Aucune règle « frères et sœurs dans des classes différentes » ; aucune vue de capacité. | important |
| Premier paiement | `admin_finance` (encaissements, rapprochement). | Aucune vue « classe prête, premier paiement manquant ». | important |
| Aide | `configurer_canal_support`. | Non configuré. | bloquant |

## Les 10 correctifs à faire avant que les familles arrivent en nombre

Ordre : ce qui bloque d'abord, puis ce qui trompe, puis ce qui se voit.

1. **Configurer le canal d'aide** (`support@`) et le poser sur la connexion et sur `/attente` : l'aide du compte dit « aucun canal » (R30, L8). Geste de la direction, une ligne.
2. **Écrire la langue de l'interface au compte de la famille** dès l'envoi de la demande : 26 courriels de famille sur 26 sont partis en français (R27, L6).
3. **Poser « Écrire à la direction » sur `/attente`** pour la famille et ouvrir la route : une famille « à compléter » ou refusée n'a que « répondez à l'e-mail » (R1, R30, L3).
4. **Faire vivre « Me prévenir si de nouveaux horaires ouvrent »** : avis à la publication d'une offre, liste de ces familles chez la direction ; sinon retirer la promesse (R22, R32, L10).
5. **Mettre le premier paiement dans le parcours** : étape dans la frise, mots dans `classe_validee` et `tout_est_pret`, décision du directeur sur l'accès au premier cours (R33, R36).
6. **Réécrire le courriel d'acceptation** : choisir un horaire, vous serez prévenu, paiement au début (R22, R33).
7. **Montrer le motif de refus et la suite dans l'application**, et envoyer un courriel quand une acceptation ou un refus est annulé (R26, R30).
8. **Règle serveur « frères et sœurs dans des classes différentes »** au regroupement (D7, L1).
9. **Mesurer la capacité** : places libres par langue, genre et public, en tête du tableau de bord ; essai complet avec une classe d'essai avant d'ouvrir à 279 familles (L5, R19).
10. **Décider les règles d'argent avant le premier paiement** : taxes et devise, accès sans paiement, arrêt et suppression (HARMONISER-ARGENT).

Les lignes « confort » et les vérifications non faites (rebond de courriel, traduction du compte rendu, essai de deux enfants, essai de changement d'heure) restent dans les tableaux ci-dessus.

## Règle pour les agents qui reprennent un de ces points

- Chaque ligne se ferme par une PR et la preuve du directeur ; ajouter le problème vécu à `RETOURS-TERRAIN-INSCRIPTIONS.md` (consigne 20).
- Cet audit ne modifie aucun code ni aucune donnée.

## Suites du 22/11/2026 : correctifs de la PR `claude/audit-famille-correctifs` (brouillon)

Ordre du directeur : « l'infrastructure complète pour accueillir 100 familles », sans les points 5 et 10 (argent,
décision du directeur) ni le 9 (capacité). **Rien n'est prouvé en production** : les cinq migrations
(20261201011000 à 20261201015000) ne sont pas installées ; « fait » veut dire « prouvé par le directeur ».

| Point | Ce que fait la PR | Où | Preuve locale |
| :-- | :-- | :-- | :-- |
| 1. Canal d'aide | Ligne `support_canal` (`support@rewayahacademy.com`, courriel) posée si absente ; `canal_support_public()` la lit sans compte ; ligne d'aide sur la connexion et sur `/attente`. | `20261201011000`, `lib/features/connexion/aide_entree.dart` | scénario SQL, 4 tests de widget, captures |
| 2. Langue | `inscrire_titulaire(..., p_langue)` écrit la langue de l'interface au compte et à la demande (fr, ar, en) ; rattrapage des comptes déjà acceptés dont la demande porte une langue, sinon rien. | `20261201011000`, `service_dossier.dart` | scénario SQL |
| 3. Écrire à la direction | Le titulaire d'une demande en attente, à compléter ou refusée ouvre son fil « candidature » (messagerie existante, aucun nouvel écran). | `20261201012000`, `attente_page.dart`, `MESSAGERIE-MATRICE.md` ligne 21 | scénario SQL, `verifier_conversations` |
| 4. Me prévenir | Une offre de l'administration publiée prévient une fois les demandes compatibles (langue, public) : notification et courriel `horaire_ouvert`. Liste « familles en attente d'un horaire » pour la direction : **pas faite** (non demandée dans le lot). | `20261201013000`, `modeles_*.ts` | scénario SQL |
| 6. Courriel d'acceptation | Dit la suite (horaire, avis, paiement au début) en fr, en, ar. | `modeles_fr.ts`, `modeles_en.ts`, `modeles_ar.ts` | rendu sous Node ; test Deno écrit, non joué |
| 7. Refus et reprise | Le motif (modèle) se lit sur `/attente` ; courriel `admission_reprise` quand une acceptation ou un refus est annulé. | `20261201014000`, `attente_page.dart` | scénario SQL, tests de widget |
| 8. Frères et sœurs | `ajouter_eleve_groupe` et `creer_classe_depuis_regroupement` refusent deux enfants d'un même foyer dans une classe (refus nommé, phrase dans les deux écrans). | `20261201015000` | scénario SQL |

Limites dites : la réponse d'une famille « à compléter » ne remet pas la demande « à traiter » (la direction voit le
message et son badge) ; si deux frères sont parmi les premiers d'un regroupement, « Créer la classe » est refusée
tout entière et la direction doit les séparer ; une famille en attente lit désormais aussi les annonces qui lui sont
adressées (`com_annonce_lecteur` suit l'appelant de la messagerie).
