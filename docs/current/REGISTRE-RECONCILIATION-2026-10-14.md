# Registre de réconciliation des spécifications - 14 octobre 2026

**Pourquoi ce fichier.** Les spécifications du directeur (septembre-octobre 2026) n'ont été reportées dans le dépôt qu'en partie : surtout le frontend. Les règles métier non « codables » (congés, prix, évaluations, cohortes, observation…) ont été perdues, et les documents d'origine supprimés. Quatre sources retrouvées sont maintenant conservées dans `docs/current/sources-directeur-2026-10/`. Ce registre en tire les règles, tranche les contradictions et compare avec l'application.

**Règle de lecture.** Sur un même sujet, la décision explicite la plus récente du directeur l'emporte. Une *proposition* (jury, expert, agent) ne devient jamais une décision parce qu'elle est récente. Une valeur choisie par un agent dans une migration n'est pas une décision : elle s'aligne sur la décision. L'application s'adapte au métier, pas l'inverse.

Statuts : **DÉCIDÉ** (directeur, daté) · **PROPOSÉ** (non adopté) · **REMPLACÉ** · **ÉCART APP** (le dépôt contredit ou n'a rien).

## 0. Sources, de la plus récente à la plus ancienne

| Date | Source | Nature |
|---|---|---|
| 14/10 | Dossier maître consolidé (`REWAYAH_DOSSIER_MAITRE_…`) | Recueil de toutes les annexes ci-dessous, avec son propre registre de divergences (§3) |
| 13/10 | Référentiel académique consolidé RA-CUR-2026.2 | Doctrine académique, points ouverts signalés |
| 12/10 | Spécifications finales des lots restants (annexe 15) | Mandat global ; snapshot des décisions au 12/10 |
| 02/10 | Guide frontend Finance V4 | **Décisions finance** qui remplacent V3 sur paie, remises, marge, essai |
| 30/09 | Stratégie de lancement V3 (annexe 22) + plan d'implémentation V3 | **Décisions** CAL, PRIX, AIDE, PROF, ATT, ABS, CONG, FIN |
| 29/09 | Vérité métier (annexe 16), politiques d'exploitation (annexe 17), avis experts E01-E04 | Faits + **propositions** de jury |
| 22/09 | `docs/current/00` à `07` (déjà dans le dépôt) | Contrat canonique initial |
| 18/09 | Référentiel RA-CUR-2026.1 (annexe 23) | Proposition académique initiale |

## 1. Programme et pédagogie

| Sujet | Règle retenue | Source | Remplacé / écart |
|---|---|---|---|
| Contenu du tronc commun | Nour al-Bayân, lecture Ḥafṣ ʿan ʿĀṣim, Al-Fātiḥa, sourates courtes jusqu'à Az-Zalzalah (99-114), Ṣalāh **et ablutions**, invocations quotidiennes | DÉCIDÉ 29/09 (directeur) | Les ablutions manquaient dans nos pages programme : ajoutées (démonstration pratique, sans fiqh détaillé) |
| Une matière essentielle, une en plus (70-80 % / 20-30 %) | Livre seul jusqu'à la chadda ; puis Fātiḥa, An-Nās, Al-Falaq, Al-Ikhlāṣ en plus ; puis paroles de la prière, puis invocations ; livre validé → le Coran devient l'essentiel | DÉCIDÉ 13/10 (directeur, dans cette session) | Le RA-CUR place Fātiḥa, Ikhlāṣ, Falaq, Nās en F2 (ordre différent) : l'ordre du directeur l'emporte |
| Méthode en séance | Rewayah fixe objectifs, étapes, échéances ; l'enseignant décide du reste | DÉCIDÉ 13/10 | Les minutages du RA-CUR (0-5 min accueil…) et la « fiche semaine 0-4 » d'E01 restent des **propositions**, jamais imposées |
| États de compétence | **À renforcer / Acquis / Stable** ; « Stable » = 3 observations sur au moins 2 semaines, dont une non préparée | DÉCIDÉ (RA-CUR, confirmé 12/10 et 13/10) | ÉCART APP : le cahier a 4 niveaux (`aRevoir / enProgres / acquis / maitrise`). Le cahier K-45 est gelé : ne pas y toucher, mais la projection famille doit parler en 3 états |
| Statuts de suite | Continuer / Renforcer / Suspendre le nouveau | RA-CUR | PRÉSENT (cahier `suite`) |
| Diagnostic d'entrée (D0) | Débutant déclaré → étape 1 sans épreuve ; diagnostic oral seulement si l'élève dit lire, ou après une longue interruption | 12/10 (« ne pas imposer d'épreuve à 95 % de débutants ») | Le RA-CUR exige D0 pour tous : point ouvert au 13/10, tranché ici dans le sens du 12/10 par délégation (K-65) |
| Orientation après les bases | Enfant : mémorisation proposée par défaut si prérequis stables, le tuteur peut demander la lecture ; adulte : choisit, sur conseil de l'enseignant | RA-CUR, confirmé 13/10 | Nos pages disaient « l'élève choisit » : corrigé |
| Travail à la maison | Une carte « Avant le prochain cours », 3 actions au plus ; « Fait » ≠ maîtrisé | RA-CUR, 12/10 | — |
| Groupe | Enseignement commun + progression individuelle bornée ; le groupe avance si 4/5 enfants (5/6 adultes) ont acquis ; consolidation commune si ≥ 40 % à renforcer ; un élève ne retarde pas le groupe de plus d'une séance | RA-CUR | Seuils internes, jamais affichés aux familles |
| Codes internes | F1-F4, T1-T6, H0-H6, I1, J0-J6, E1-E3 jamais visibles | Tous | — |
| Nour al-Bayân | Ne jamais inventer de pages : édition exacte et droits à vérifier | RA-CUR | Ouvert (photo du sommaire demandée au directeur) |

## 2. Calendrier et congés

| Sujet | Règle retenue | Source | Remplacé / écart |
|---|---|---|---|
| Ramadan | Les cours continuent au début du mois, avec moins de nouveau et plus de révision ; **fermeture du 20 Ramadan au 7 Shawwal inclus**, 20 jours au plus | DÉCIDÉ 30/09 (CONG-01) + RA-CUR §22 | REMPLACE le calendrier Drive 2025-2026 (congé sur tout le mois, 28/02-24/03/2026) et nos pages qui disaient « pas de cours pendant le Ramadan » : corrigé |
| Tabaski (Aïd al-Adha) | **Fermeture du 9 au 18 Dhu al-Hijja inclus, 10 jours** | DÉCIDÉ 30/09 | REMPLACE « environ une semaine » (RA-CUR) et le Drive (25/05-01/06/2026) |
| Dates | Dates grégoriennes publiées chaque année par la direction ; l'app ne décide pas l'observation lunaire | 30/09 | ÉCART APP : aucun réglage de calendrier |
| Été | Les cours continuent | Drive + pratique | — |
| Rencontres de récitation (Majālis) | **4 par an**, dont une juste après l'Aïd al-Fitr ; encouragement, jamais de promotion | RA-CUR, confirmé 13/10 | Nos pages parlaient de « 3 sessions d'examen » (calendrier Drive de l'ancienne académie) : corrigé |
| Vacances familiales hors calendrier | Pause individuelle ; peut demander un replacement au retour | RA-CUR | — |
| Facturation pendant un congé | Débit réduit selon les séances ouvertes, plancher 25 USD enfant / 30 USD adulte ; aucune séance ouverte = aucun débit ; prorata d'entrée sans second plancher | DÉCIDÉ 30/09 (CONG-02) | Finance, hors périmètre actuel ; formule complète au dossier maître §3.4. La proposition du 29/09 (prorata sans plancher) est REMPLACÉE |

## 3. Classes, âges, capacités

| Sujet | Règle retenue | Source | Écart app |
|---|---|---|---|
| Âge minimum | 6 ans, exception possible accordée par l'administration | DÉCIDÉ 13/10 | ÉCART : le serveur accepte 3-99, cohorte « 5 à 7 ans » |
| Cohortes | **6-9, 10-13, 14-17, 18+** | DÉCIDÉ 29/09, confirmé 12/10 | ÉCART : `0043` a semé 5-7 / 8-10 / 11-14 / 15-17 / 18+ (choix d'agent, calé sur un réglage d'interface). Correction par `update`, sans migration (zone backend) |
| Rythme | 3 séances/semaine, même enseignant sur tous les jours | DÉCIDÉ 29/09 | PRÉSENT |
| Durée | Enfant 60 min avec courte pause (5 min) ; adulte 90 min | 12/10 | Pause 6 min dans `0043` : écart mineur, réglage |
| Capacité | Enfant 5, adulte 6, **débutants 4** ; valeur effective = celle de la Classe | DÉCIDÉ V3 30/09 + V4 02/10, confirmé 12/10 | ÉCART : pas de capacité « débutant » |
| Minimum pour ouvrir | **4** ; en dessous, autorisation et budget tracés | DÉCIDÉ V3 + V4 | ÉCART : `groupe.minimum_lancement` = 3 (choix d'agent) |
| Formation d'une classe | 14 jours au plus, point à J7 ; prolongation de 7 jours avec accord du demandeur | DÉCIDÉ 30/09 (ATT-01) | À vérifier dans le suivi des demandes |
| Entrée dans une classe existante | Au début d'un mois, après placement | DÉCIDÉ 30/09 (CAL-03) | — |
| Langues des cours | Poular, français, anglais d'abord ; les autres attendent | 29/09, 12/10 | PRÉSENT (`langues_cours`) |
| Langues de l'app | fr, en, ar, es, pt | K-41 | — |
| Classes non mixtes | Décidé le 10/10 | Registre interne | ÉCART : non codé |
| Pause personnelle | Mois civil complet, annoncé 7 jours avant | DÉCIDÉ 30/09 (ABS-01) | — |
| Absence ordinaire | Ne réduit ni le prix ni la paie | 30/09, 02/10 | — |
| Enseignant titulaire absent | Revient dans les 14 jours : garde la classe ; au-delà : retiré de cette classe | DÉCIDÉ 30/09 (PROF-04) | — |

## 4. Évaluations

| Sujet | Règle retenue | Source | Écart |
|---|---|---|---|
| Qui déclenche | L'enseignant **propose**, le système/l'autorité planifie ; résultat ≠ promotion ≠ certificat | 12/10 | Nos pages l'avaient déjà ainsi |
| Mots publics du résultat | « Étape validée » · « Quelques points sont à renforcer » · « Une nouvelle vérification est nécessaire » ; jamais « Échec », surtout pour une panne | 12/10 | ÉCART APP : `evaluations` stocke `reussi / echec / a_revoir` (stockage acceptable, libellés à aligner). Nos pages corrigées |
| Examen de fin des bases | Passage proposé par l'enseignant quand l'élève est prêt, dans une séance d'évaluation planifiée ; la famille peut assister si la séance est ouverte par l'administration | 12/10 | REMPLACE « une des 3 sessions annuelles » de nos pages |
| Documents | Attestation fin des bases ; certificat de lecture ; certificat de mémorisation ; jamais « ijāzah » | RA-CUR, 12/10 | — |
| Recours | La famille peut demander une réévaluation par une autre personne ; ne peut pas imposer un passage | RA-CUR | — |

## 5. Salle, observation et vocabulaire (relevé de l'annexe 10, à jour au 14/10)

| Sujet | Règle retenue | Écart app |
|---|---|---|
| Observation du tuteur | 2 visites × 2 minutes par parent et par séance, visite écourtée consommée, ni micro ni caméra ; seuls l'enseignant et l'enfant concerné sont prévenus (12/10, remplace « 1 visite de 120 s ») | Base active : 1 visite, 120 s ; la correction `0036` est dans le dépôt mais non appliquée |
| Consentement d'observation | Paragraphe clair, case non précochée, versionné | Absent |
| Enregistrement | Ne jamais afficher « cours enregistré » sans enregistrement réel ; pas de captation tant que la politique n'est pas validée (12/10) | Contradictoire : textes et ADR-002 parlent d'enregistrement 30 jours |
| Fenêtre d'entrée | Une seule, vers T-20, réglable | Trois fenêtres coexistent (« dix minutes avant » dans les textes) |
| Vocabulaire | « Classe » (pas « groupe ») ; « Interface guidée » (pas « mode enfant ») ; « Ajouter un profil élève » ; jamais « Cours en cours » | Textes contraires encore présents |
| Navigation tuteur | Accueil · Foyer · Historique · Compte | Écart dans `nav_shell.dart` (Disponibilités, ancien matching) |

## 6. Finance (consignée, hors périmètre tant que la direction ne l'ouvre pas)

| Sujet | Règle retenue (la plus récente) | Remplacé |
|---|---|---|
| Prix | 50 USD enfant, 60 USD adulte, mois civil, premier mois au prorata | — |
| Remise familiale | Rangs 1-2 : 0 ; rang 3 : -5 ; rang 4 et + : -7 (V4 02/10, confirmé 12/10) | V3 5/10 USD ; proposition 29/09 5 %/10 % ; ancien 50/90/40 |
| Paie enseignant | 4 USD/h garantis, jusqu'à 7 USD/h selon le remplissage ; aide Internet séparée ; pas de bonus classe pleine (V4) | V3 20/26 USD + bonus 10/20 ; proposition 20/30 |
| Marge | Repère de pilotage (~30 %), jamais un blocage (V4) | V3 plancher 40 % |
| Essai | 2 séances, gratuites, ne consomment pas le solde (V4) | Le 12/10 demande une preuve commerciale avant d'écrire « gratuit » sur le site |
| Impayé | Place conservée 7 jours ; jamais de compte bloqué ; l'enfant ne voit jamais la raison | — |
| Bourses | 3 par tranche de 100 payants ; orphelins 12 mois (jusqu'à 18 ans), nouveaux convertis 6 mois | — |
| Congés | §2 ci-dessus | — |

## 7. Autres écarts relevés dans le dossier maître (annexes 10, 11, 24)

**Deux défauts de sécurité, à traiter en premier à l'ouverture du backend :**

- **Validation des dossiers (ADM-02)** : `decider_dossier` ne vérifie pas que le dossier est encore en attente (`0004:550`). Une seconde décision écrase la première sans rien dire. L'annexe 11 exige une version attendue (`stale_dossier`) et le refus d'un dossier déjà décidé (`already_decided`).
- **Pièces d'identité** : `read_kyc_documents()` accepte le rôle `controller` (`0004:187`). Or l'annexe 11 et la spec du 12/10 (§04.3) interdisent au contrôleur l'accès aux pièces.

**Écarts métier ou de produit (la règle la plus récente est retenue) :**

| Sujet | Règle retenue | État du dépôt |
|---|---|---|
| Polices | DM Sans pour les titres, Plus Jakarta Sans pour le texte latin. Source : V3 du 30/09, confirmée le 12/10 | Le dépôt utilise Bricolage Grotesque et Instrument Sans |
| Validation d'un dossier | Le serveur calcule `can_validate` et les blocages. Une confirmation est demandée avant de valider. Les accords signés sont vérifiés | Les trois cases sont locales, sans confirmation, et les accords ne sont pas lus |
| Genre de l'administrateur | La règle existe en base. Un écran doit permettre de compléter ce champ | L'administrateur est bloqué sans moyen de corriger |
| Photo de l'enseignant | Obligatoire et distincte de la pièce d'identité | Le champ est facultatif en base, et `decisions.md:1809` dit encore « jamais de photo » |
| Observation | Le serveur coupe l'accès quand le temps est écoulé. Le plafond par visite est contrôlé par le serveur | Seul le client fait ces contrôles |
| Durée après la fin du cours | Aucune décision récente | ADR-005 dit 10 min, les migrations disent 15 min : à aligner sur un seul réglage |
| Catalogue des écrans | La classe en direct, le dock et la Bibliothèque doivent y figurer | Aucune fiche |
| Pages légales | Suppression de compte, export des données et acceptation des CGU sont obligatoires avant d'ouvrir au public | Rien de tout cela n'existe |

Constat rassurant : l'annexe 24 (Teaching Core) a été bien reportée dans le dépôt, avec les migrations 0030 à 0033, `lib/core/tc_*` et `docs/teaching-core/`. Ce qui s'est perdu, ce sont surtout la finance, le calendrier, le référentiel académique et les décisions d'octobre.

## 8. Arbitrages vraiment ouverts (rien d'autre n'est à redemander)

1. Édition exacte de Nour al-Bayân (photo du sommaire) : pour relier les étapes au livre.
2. Liste validée des paroles de la prière, des ablutions et des invocations : validation scientifique du directeur.
3. Ce que paie une famille pendant la fermeture de Ramadan : la règle CONG-02 existe (plancher 25/30 USD) ; à confirmer seulement si la direction veut la changer.

Tout le reste est tranché par ce registre selon la règle « la décision la plus récente l'emporte ». Les écarts d'application (§3, §5, §7) attendent l'ouverture du backend par le directeur.
