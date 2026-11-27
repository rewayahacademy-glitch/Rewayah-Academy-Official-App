# Inventaire de ce qui n'est pas en production, et plan pour l'y mettre (27/11/2026)

Demande du directeur du 27/11/2026 : relire les sessions ouvertes et archivées, lister tout ce qu'il a demandé
ou que les agents ont proposé et qui n'est pas en production, avec son niveau d'avancement, puis un plan pour
finir et mettre en production, sans se contredire avec les mises à jour faites depuis.

Relevé fait le 27/11/2026 sur `main` `6f6f1339` (#723), base de production `gggmtelinlpseweouyav`, en lecture seule.

## 0. D'abord : ce qui est faux, bloqué ou non prouvé

1. **Praxis n'est pas arrêté côté serveur.** Le directeur a demandé de l'arrêter le 21/11 à 23 h 26. Lu en
   production le 27/11 : `private.praxis_reglages` porte `actif = true` et `autonome = true` (réglé le 20/11 à 02 h 07).
   La seule clé est une clé `routine`, expirée le 24/11 à 11 h 53, dernière utilisation le 23/11 à 05 h 18. Praxis ne peut
   donc plus agir seul depuis le 24/11, mais **parce que sa clé a expiré**, pas parce qu'on l'a coupé. Une nouvelle clé
   le relancerait aussitôt en autonome. Seule tâche planifiée Praxis encore active : `praxis-purge-journal`.
2. **Le registre des lots ment par retard.** Sur 63 branches que `REGISTRE-LOTS.md` donne « À LIVRER / en cours /
   brouillon », **60 sont déjà dans `main`** et leurs migrations sont présentes en production (objets sondés). La vraie
   dette n'est pas là où le registre la place. Même chose pour `BUREAU-EQUIPE/SUIVI.md` (figé au 16/11 19 h).
3. **Six migrations tournent en production sans aucun fichier dans git** : `prospection_courriels_2611`,
   `prospection_correctif_ligne_68`, `prospection_langue_lettres_en_attente`, `prospection_pause_anciennes_lettres`,
   `be2a2_associe_texte_exact`, `d1bis_vue_famille_lecture_seule_filtre_mineurs`. Une base rejouée depuis le dépôt
   n'est donc pas la production.
4. **89 fichiers de migration de `main` n'ont pas de ligne dans l'historique de production**, alors que leurs objets y
   sont (60 sondés, tous présents ; 22 non sondés un par un). L'historique n'est pas fiable pour savoir ce qui est installé.
5. **Presque rien n'est « fait » au sens du directeur.** Des dizaines de lots sont en production mais aucun n'a été
   prouvé par le directeur depuis K1-K3 (24/10). La Boucle 1 n'a pas ses quatre phrases vraies : K4 « jamais vrai en
   production » (30/10), aucune preuve trouvée après. Le présent plan sort de la Boucle 1 sur demande du directeur ;
   CLAUDE.md dit encore qu'elle prévaut : à mettre à jour sur décision datée.
6. **Les aperçus de PR seraient construits avec les secrets de la production** (PR #26, ouverte depuis octobre ; risque
   probable, non prouvé). Le staging est figé au 23/10.
7. **Limites de cette lecture.** Les sessions pilotes sont trop longues pour l'outil : plusieurs fenêtres ont été lues
   par leur résumé de compaction ou par ce que le pilote a consigné dans le dépôt. Non lus en brut : les messages du
   directeur du 12/11 au 15/11 au soir (Pilote-Messages), le 06/11, du 07/11 soir au 12/11 (garde-cap), le 15/11 et le
   début du 16/11 (Fable-personnel), les pilotes du 23/10 et du 29/10. Une demande faite seulement dans ces fenêtres et
   jamais consignée peut manquer ici.

## 1. Niveaux d'avancement employés

| Niveau | Sens |
|---|---|
| **N0** | demandé ou spécifié, rien de codé (ou décision attendue) |
| **N1** | codé sur une branche, sans PR |
| **N2** | PR ouverte, non fusionnée |
| **N3** | dans `main`, mais incomplet en production (migration, réglage, geste externe manquant) |
| **N4** | dans `main` et en production, jamais prouvé par le directeur |

## 2. Inventaire

### A. Praxis (secrétaire IA)

| Élément | Niveau | Où | Ce qui manque |
|---|---|---|---|
| Arrêt de Praxis demandé le 21/11 | N3 | réglage serveur | interrupteur encore `actif`/`autonome` (§0.1) ; le garde-fou a refusé l'écriture à l'agent |
| Clé `routine` expirée le 24/11 | N3 | `private.praxis_cles` | décider : remplacer (Praxis repart) ou laisser éteint et couper l'interrupteur |
| PX-OAUTH : le chat du directeur relié à Praxis | N2 | #627, #632 → #633 → #637 → #638 | #632 en conflit depuis le 21/11 ; migrations non installées, à renuméroter (`20261130500000`, `20261130600000`) ; **collision** : `20261129990000` pris par #638 et par `claude/px-bd-support` ; l'essai du connecteur par le directeur, demandé six fois du 17 au 20/11, jamais fait |
| Bras droit de Praxis en chat (« qu'il m'aide surtout à 100 % », 17/11) | N2 | #625, #626, #628, #630 | gelées et en conflit depuis le 17/11 ; seul le volet Bibliothèque a été refusé (#631) |
| `claude/px-bd-support`, `claude/px2-ecran`, `claude/pilote-equipe-jour` | N1 | branches sans PR | à trier ; absentes du registre |
| PX-COURRIEL (« il ne faut pas lui amputer les bras »), PX-REVEIL (réveil sur événement), mention IA discrète aux familles | N0 | — | demandés le 17/11, aucun code |
| PX-BULLE-3 (#635), Praxis sur ses bulles | N4 | `main` | dernier mot du directeur après #634 : « ça n'a pas marché » ; jamais revérifié |

### B. Guide de l'enseignant contre l'application (alerte du 21/11)

| Élément | Niveau | Ce qui manque |
|---|---|---|
| P1 part enfant (guide ~45 % ; règle 47 %) | N0 | décision : taux retenu (45 %, 24 $ fixes ou 43,6 %), et lequel prévaut |
| P2 élève absent payé à moitié (`absence_eleve_payee: false`) | N0 | décision puis code de paie |
| P3 montants en dollars donnés aux candidats | N0 | décision (guide ou règle du 22/10) |
| L1 arabe langue de cours (refusé le 22/10) | N0 | décision |
| A2 avertissements, A5 enseigner ailleurs, A6 sortie > 30 s signalée, P5 minimum du remplaçant | N0 | décision puis code |

L'agent chargé de ces lignes (`…xd1xV6…`) s'est arrêté sans rien écrire : décision non confirmée par le directeur.

### C. Parcours de l'enseignant et bureau

| Élément | Niveau | Où / ce qui manque |
|---|---|---|
| Plan PARCOURS-ENSEIGNANT (vagues P, A à G) | N0 | plan du 19/11 non validé ; `PARCOURS-ENSEIGNANT/RESTE-A-FAIRE.md` |
| Page « Personnes » à refaire (« j'ai tout détesté », 21/11) | N0 | références à montrer avant code |
| Restes des maquettes (chargement et mise à jour avec Praxis, tableau de bord, icônes, mouvement, en-tête) | N0 | `RESTE-A-FAIRE.md` §1-3 |
| PE-A7 prévenir quand un moment d'entretien s'ouvre (D-6) | N2 | #655, « ne pas fusionner sans décision » |
| D-2 versements Algérie, Guinée, Liberia ; D-3 rouvrir les entretiens ; D-4 « Demander une précision » ; D-5 message au dispensé d'entretien | N0 | décisions |
| Courriel d'invitation d'un associé | N0 | texte à valider |
| Pages de l'associé décidées par le rôle et non par une capacité | N3 | contraire à l'invariant « un widget lit une capacité » |
| Gelés sans ordre : BE-COLONNES, BE-1e panier, BE-1f grille, BE-1g impression, LP-3 à LP-7, étape D (1 217 réponses perdues), étape E (« confirmée » → « première classe »), BE-2c, BE-2d, vagues 3 à 5 (Studio), SEC-4 | N0 | ne pas lancer sans ordre |
| `claude/import-rapide` (`20261125100000`), `claude/prevenir-tous` (`20261125200000`) | N1 | branches sans PR, migrations absentes de l'historique ; peut-être remplacées par `main` : à vérifier avant toute reprise |
| Bouton « i » de Messages emporté par la barre repliée (« Faut-il le corriger aussi ? », 16/11) | N0 | sans réponse ; au pilote de trancher (consigne 22) |

### D. Programme et pédagogie (suspendu par « arrête tout », 15/11)

| Élément | Niveau | Où / ce qui manque |
|---|---|---|
| Lots 1, 2, 3 (socle, calendrier, bibliothèque) | N4 | dans `main`, migrations présentes, non prouvés |
| Lot 7 Apprendre | N4 | livré **non conforme à la maquette** |
| Lots 4, 5 (seule la partie A, plan de classe), 8 | partiel | `REPRISE-PROGRAMME-PEDAGOGIQUE.md` |
| Lot 6 POINT-DE-SEANCE | N1 | `claude/point-de-seance`, migration `20261125000000` non installée ; « tient lieu de cahier » non construit ; décision paie point de séance contre cahier attendue |
| Lots 9 à 14 (chemin, lecteur, moteur de suivi, évaluations, livret) | N0 | rien |
| Classes vitrines FC-1 à FC-4 | N0 | stratégie sur branche, 17 décisions dont 7 d'argent |
| CAHIER-C4 à C8 | N0 | seuls C1, C2, C3 codés |

### E. Argent : paie, paiement, versements

| Élément | Niveau | Ce qui manque |
|---|---|---|
| HARMONISER-ARGENT phase 2 : règle 3 (suppression encadrée), règle 4 (arrêt temporaire), trois questions | N0 | règles 1 et 2 tranchées le 23/11 |
| Plan paiement du 23/11 : P1 paiement réel de 1 $ par le directeur, P7 page unique « Paiements », P8 ménage, P9 famille test | N0 | rien lancé |
| Payer une dette de famille dans l'application | N0 | — |
| Stripe Tax | N3 | préparé, éteint |
| Audit famille : correctifs 5 et 9, liste « familles en attente d'un horaire » | N0 | — |
| Correction du grand livre (`20261129850000` réservée), insertion directe dans `wallet_entries` | N0 | dettes |
| Verto : payer les enseignants sans voir leurs coordonnées (aujourd'hui stockées en clair) | N0 | stratégie, réponse de Verto attendue ; **risque de sécurité** à traiter même sans Verto |
| B2.3 présents d'une séance tenue sur Meet ; B2.4 tableau actifs / réguliers / à surveiller | N0 | — |
| Gestes du directeur : webhook Stripe (remboursements), clés Stripe de production (FN-011), image de marque Stripe | N0 | hors code |

### F. Messagerie

| Élément | Niveau | Ce qui manque |
|---|---|---|
| #538, #540, #546, #551, #566, #612, #618, #622, #634, #635 | N4 | jamais vus par le directeur |
| « Enregistrer l'image » | N3 | règle CORS sur le `GET` du seau R2_MESSAGING (Cloudflare, directeur) |
| Bandeau « Nouvelle version » | N0 | **un bandeau existe déjà** (`lib/core/version/bandeau_nouvelle_version.dart`, 25/10) : vérifier avant de rien écrire |
| « Parler à l'équipe », canal du Studio dans la nouvelle présentation, plantage depuis un profil (jamais reproduit), contraste du lecteur vocal, image de Praxis en octets dans le code, double appel de `com_envoyer_message` (peut-être réglé par #657) | N0 | — |
| `images_messagerie_test` échoue en local | N3 | à corriger |
| Notes « POUR JEUDI SOIR » | N1 | `claude/messagerie-px-bulle-jeudi`, sans PR |

### G. Salle et séance

| Élément | Niveau | Ce qui manque |
|---|---|---|
| Journal des sorties | N3 | livré éteint ; textes et durée à valider |
| « Mes accords », « Je m'absente un instant », vidéo des camarades fermée côté serveur de visio | N0 | — |
| 27 points HARMONIE-SALLE ; restes K4 n° 9, 10, 12, 14, 18 (dont décalage audio ~0,5 s) | N0 | causes du son coupé, de l'entrée du 2e élève, de la voix en entretien : non mesurées ; rien essayé sur vrais appareils |
| Séances qui s'enchaînent (FN-006, FN-117) | N0 | — |

### H. Socle, sécurité, infrastructure

| Élément | Niveau | Ce qui manque |
|---|---|---|
| Aperçus de PR sur les secrets de production | N2 | #26, décision du directeur depuis le 08/11 |
| Staging figé au 23/10 | N3 | — |
| BASE-ECONOME étapes 1, 3 à 7 (cron, veille broadcast, sondage unique, mode dégradé, essai de charge, alertes), `tool/verifier_charge.dart`, index des clés étrangères, liste des messages paginée | N0 | stratégie du 15/11, seules 0 et 2 faites |
| Scénarios SQL hors de `ci.yml` (au moins 8 : `image_candidat`, `nouveau_fils`, `com_compte_officiel`, `pause_proposee`, `journal_sorties`, `camarades_prenoms`, `session_peers_matricule`, `com_lister_fils_econome`) | N0 | zone `.github/` interdite aux agents : ordre du directeur |
| Six migrations de production sans fichier git ; historique incomplet | N3 | §0.3, §0.4 |
| `vercel.json` renvoie tout vers l'accueil au lieu de « introuvable » ; `supabase/setup-cli` en `latest` | N0 | zones interdites |
| Purge des pièces d'identité jamais exécutée | N3 | — |
| Politique de confidentialité en anglais et en arabe à relire | N0 | — |
| Site public : la racine va vers `/langue` et non `/fr/` | N3 | écart avec `DECISION-DOMAINE` |
| Compte propre de l'élève adulte, horloge côté client, PRESENCE-AVENIR, remplacement (5 propositions jamais validées), communauté, contenu de la Bibliothèque, courriel aux familles importées, avis de l'élève après séance | N0 | décisions ou lots jamais lancés |
| Dettes : date limite d'étape un jour trop tôt (21 h-minuit UTC), test de la prière qui casse le lundi, code mort de la transition 24 | N0 | — |

### I. Prospection

| Élément | Niveau | Ce qui manque |
|---|---|---|
| 100 lettres programmées, premier paquet le 29/11 à 21 h 24 UTC | N3 | rien d'envoyé encore |
| Relance du jour 2, lettres en espagnol et en portugais | N0 | — |
| `claude/prospection-envois-v2` (27/11) | N1 | sans PR |
| Quatre migrations de prospection | N3 | en production sans fichier git |

### J. En production, jamais prouvé par le directeur (N4, le plus rapide à « finir »)

Ces lots n'ont besoin que d'une preuve : cloche style C (#696, #698), annonces serveur et traduction (#693, #694, #697),
R-06 en attente ; guide de l'enseignant et ses commentaires (#665, #687, #690, #692, #695) ; lots famille et paiement
(#699 à #719) ; messagerie (§F) ; carte des gestes, vague 2 (missions, associé, écran Équipe), PX-1, PX-2 ; programme
lots 1-3, plan de classe A, prière, horloge et lieu, suivi de l'attente ; paie (fenêtre, reconnexion, revenus) ;
annonces simples ; incident candidats ; recrutement (salle 2, audit portail, complément, dispense) ; noms de classes,
CAHIER-C1, paie de la direction et du remplaçant, I1, C1, fin de séance.

### K. Abandonné ou remplacé (à ne pas relancer)

Lecture des pièces par un modèle (#623) ; recodage de la Bibliothèque par Praxis (#631) ; italique et `#RA_PRAXIS`
(→ `#Ra_Praxis`) ; retrait des entretiens de Praxis (#650, annulé par #653) ; #609 (→ #645) ; #580 (→ #581) ;
compte séparé pour Praxis (refusé le 17/11) ; image du directeur comme avatar (→ portrait de référence, #649) ;
« annonces jamais masquables » (→ décision du 21/11) ; 17 % (→ 15 %) ; transfert de solde entre profils ; règle de
remboursement du 07/11 ; renvoi des lettres mal traduites (« non », 27/11) ; les 79 lettres longues ; arc de marque
de la messagerie ; collage des migrations par le directeur (→ consigne 21) ; goutte entre profils ; filtre de langue
du remplacement ; cadre en ur, ha, tr ; PR #382 (contenu remplacé dans `main`, à fermer) ; PR #421 (remplacée).

## 3. Questions au directeur, dans l'ordre où elles débloquent le plus

1. Praxis : couper l'interrupteur (actif et autonome à `false`), ou émettre une nouvelle clé ? Et le « point du jour » ?
2. Guide contre application : P1 (quel taux enfant), P2, P3, L1 ; le guide prévaut-il, ou la règle ?
3. R-06 : une notification qui mène à un objet s'ouvre-t-elle directement, ou d'abord par son détail ?
4. Valider (ou non) le plan PARCOURS-ENSEIGNANT ; décider PE-A7 (#655), D-2 à D-5.
5. PR #26 (aperçus sur staging) : on la reprend ?
6. Rouvrir le chantier pédagogique (suspendu le 15/11) ? Si oui : point de séance contre cahier pour la paie.
7. PX-OAUTH : faire l'essai du connecteur, pour qu'on puisse finir la pile #632-#638.
8. Remise de famille du petit frère quand l'aîné ne paie pas ; familles à prix spécial ; facture de Dyna.
9. Ajouter les scénarios SQL manquants à `ci.yml` (zone qu'un agent ne peut pas toucher sans ordre).

## 4. Plan de remise en production

Règles tenues : une étape, une PR ; quatre agents au plus, zones séparées ; les agents ouvrent les PR, le pilote
fusionne et installe les migrations (checklist de `supabase/CLAUDE.md`) ; « fait » = prouvé par le directeur.

**Étape 0 (aujourd'hui, sans code).** Le directeur répond aux questions 1 à 3. Si « couper Praxis » : le pilote
installe une migration d'une ligne (`UPDATE private.praxis_reglages SET actif=false, autonome=false`) ou le directeur
le fait dans « Accès des agents IA ».

**Étape 1 (hygiène, 1 PR documentaire + 1 PR de migrations).**
- Remettre `REGISTRE-LOTS.md` d'aplomb : les 60 lignes livrées passent à LIVRÉ (#N), les 9 branches absentes y entrent
  (`px-bd-support`, `px2-ecran`, `pilote-equipe-jour`, `messagerie-px-bulle-jeudi`, `prospection-envois-v2`,
  `point-de-seance`, `import-rapide`, `prevenir-tous`, `photos-ecrans`). Mettre `BUREAU-EQUIPE/SUIVI.md` à jour.
- Rapatrier dans git les six migrations de production sans fichier (texte lu dans
  `supabase_migrations.schema_migrations.statements`), pour que le dépôt redevienne la production.
- Fermer #382 et #421 (remplacées). Régler la collision `20261129990000`.

**Étape 2 (preuve, le plus rentable).** Une feuille de recette par parcours pour le directeur, sur la production, avec
les lots N4 du §J regroupés en cinq passages : (1) candidat → enseignant ; (2) famille → paiement ; (3) messagerie,
annonces et cloche ; (4) direction : dossiers, gestes, équipe ; (5) salle et programme. Chaque défaut trouvé devient
une ligne de `RETOURS-TERRAIN` et une PR courte.

**Étape 3 (finir ce qui est déjà codé).** Agent 1 : pile PX-OAUTH (rebase, renumérotation, essai du connecteur), puis
bras droit #625-#630 sans le volet Bibliothèque. Agent 2 : petits restes messagerie (bouton « i », contraste, test
local, image Praxis en asset ; vérifier le bandeau existant au lieu d'en écrire un). Agent 3 : trier
`import-rapide`, `prevenir-tous`, `point-de-seance`, `photos-ecrans` contre `main` (livrer, ou marquer REMPLACÉ).
Agent 4 : rien, ou les dettes courtes (date limite d'étape, test de la prière du lundi).

**Étape 4 (décisions puis code).** Dès les réponses : lignes du guide (B), HARMONISER-ARGENT règles 3 et 4, plan
paiement P1, P7-P9, page « Personnes » (références d'abord), coordonnées bancaires stockées en clair.

**Étape 5 (sur ordre seulement).** Chantier pédagogique (lots 4-14, classes vitrines, CAHIER-C4-C8), BASE-ECONOME,
vagues BE gelées, salle (HARMONIE-SALLE, essais sur vrais appareils), prospection suite.

## 5. Sources de ce relevé

Rapports des lecteurs de sessions et du vérificateur (scratchpad de la session du 27/11, non versionné), recoupés avec
git (`origin/main`, `tool/registre_lots.sh`), l'API GitHub (13 PR ouvertes, toutes en brouillon), l'historique des
déploiements (100 derniers runs sur `main` : 99 verts, 1 annulé ; dernier commit applicatif #721 en ligne sur Vercel)
et des lectures SQL en production (réglages et clés de Praxis, objets des migrations douteuses).
