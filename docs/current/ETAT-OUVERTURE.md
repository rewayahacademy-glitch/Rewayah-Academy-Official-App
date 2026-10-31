# État de la ligne d'arrivée

Toute session, pilote ou agent, commence par ce fichier (`METHODE-2026-11-01.md`, règle 3).
Une ligne par parcours de `PARCOURS-OUVERTURE-2026-11-01.md`, mise à jour à chaque passage du
test de bout en bout.

Vert en local : le test de bout en bout passe sur la pile locale, captures datées à l'appui.
Rouge : il échoue, cause écrite. Non écrit : aucun test encore. **Vert en local n'est pas une
recette en production** : la dernière colonne ne se remplit que quand le directeur l'a faite.

| # | Parcours | Vert en local | Cause si rouge | Dernier passage | Captures | Recette prod (directeur) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | La direction valide un enseignant | rouge en local (pièges) ; chemin prévu vert | Pièges joués (captures/E2E/parcours-1/pieges.md, 31/10 21:42 UTC) : un PDF passe pour une pièce d'identité (FN-101), une signature au nom d'un autre passe (FN-102), code en minuscules refusé (UX-016), rechargement qui perd tout (UX-017), lien déjà utilisé mal expliqué (UX-018), retour à « Pour qui » (UX-013). Chemin prévu vert : pièce factice, pièce lue par une personne du même genre, production non jouée. Constat : UX-015. | 2026-10-31 21:10 UTC | [parcours-1](captures/E2E/parcours-1/) |  |
| 2 | La direction crée une classe à plusieurs séances | rouge en local (pièges) ; chemin prévu vert | Chemin prévu rejoué vert sur le code de main (31/10 23:31 UTC). Pièges (parcours-2/pieges.md) : Échap perd la saisie sans prévenir (UX-031) ; fuseau affiché brut (UX-030). Constats : UX-003, UX-004. | 2026-10-31 23:31 UTC | [parcours-2](captures/E2E/parcours-2/) |  |
| 3 | Une famille et un adulte s'inscrivent, la direction les accepte | rouge en local (pièges) ; chemin prévu vert | Chemin prévu rejoué vert sur main (31/10 23:34 UTC) ; e-mail de confirmation reçu dans Mailpit (envoi réel de production non prouvé). Pièges (parcours-3/pieges.md) : lien ouvert sur un autre appareil → « Se connecter » sans un mot, questionnaire perdu (FN-111) ; « 5 ans » accepté (UX-032). Constats : UX-005, UX-006, UX-007, UX-014. | 2026-10-31 23:34 UTC | [parcours-3](captures/E2E/parcours-3/) |  |
| 4 | La direction place un élève | rouge en local | Chemin vert le 31/10 à 20:40 UTC (avant la fusion de main). Passage sur main de 23:35 UTC rouge par un artefact de mon nettoyage SQL (classe close sans retirer ses membres : corrigé), qui a prouvé l'erreur brute UX-019. Pièges (parcours-4/pieges.md) : erreur brute (UX-019), « Ajouter un élève » absent de la fiche de la classe (UX-008). Constats : UX-008, UX-009. | 2026-10-31 23:35 UTC | [parcours-4](captures/E2E/parcours-4/) |  |
| 5 | Tenir la séance (Rejoindre, vidéo, page du Coran) | rouge en local (pièges) ; chemin prévu vert | Chemin prévu rejoué vert sur main (31/10 23:41 UTC) ; limites : son prouvé par les pistes et l'état du micro, élève entré par le tuteur (voir 5 bis). Pièges (parcours-5/pieges.md) : salle ouverte deux fois → « connexion perdue » trompeuse (UX-038), le tuteur qui sort lit « La séance est terminée » (UX-039), écran de fin de l'enseignant à une autre navigation (UX-040). Revue aux deux largeurs : UX-033, UX-034, UX-037. Constats : UX-010, UX-011, UX-012. | 2026-10-31 23:41 UTC | [parcours-5](captures/E2E/parcours-5/) |  |
| 5 bis | L'élève rejoint depuis son propre appareil (connexion de l'élève, pas du tuteur) | rouge en local (FN-006 Bloquant) ; chemin de l'enfant vert | Limites : l'entrée « Connecter l'appareil d'un élève » est masquée par la construction de test (AUTH_PAR_MOT_DE_PASSE) : écran ouvert par /connexion/eleve, la suite (code du tuteur, code personnel, Accueil, « Rejoindre ») est jouée à l'écran ; l'enseignant est entré par l'onglet Classes (FN-006). Constats : UX-021, UX-027 | 2026-10-31 23:09 UTC | [parcours-5bis](captures/E2E/parcours-5bis/) |  |
| 6 | Présence et cahier | vert en local | Présence calculée seule (Yanis : 3 min sur 60, « partielle »), lue en base comme la direction. Cahier : « Aujourd'hui » › « Cahier de transmission d'… » › « Où la Classe s'est arrêtée » (sourate et verset, obligatoire) › « Valider le cahier de transmission » › « Cahier de transmission enregistré ». Verdict de ce passage établi sur la capture 05 et la base (motif de confirmation du script corrigé après coup). La ligne « À terminer » n'apparaît qu'après la clôture automatique (FN-006). | 2026-10-31 21:49 UTC | [parcours-6](captures/E2E/parcours-6/) |  |
| 7 | La famille voit la classe, la présence, et paie | rouge en local | paiement non joue : cle Stripe absente (production et pile locale) ; l'ecran dit « group:Profil à recharger Récapitulatif par profil Moyen de paiement » ; Étapes 1-2 vertes : enfant, classe, « Voir la classe » ; Historique › « Séance du … » : arrivée 21:42, sortie 21:49, « 3 min sur 60, Présence partielle » (présence encore « en cours de vérification »). Étape 3 rouge : clé Stripe absente (production et pile locale), l'écran dit « Paiement pas encore disponible. Aucun paiement n'a été effectué » ; « Recharger » absent du Foyer tant que l'accès est « sans échéance », écran ouvert par son adresse. Constats : FN-106, FN-107, UX-025 | 2026-10-31 22:47 UTC | [parcours-7](captures/E2E/parcours-7/) |  |
| 8 | L'élève adulte suit sa classe | rouge en local (FN-006 Bloquant) ; chemin joué vert | Étapes 1-2 (21:21 UTC) : « Bonjour E2E Adulte » + sa classe, « Rejoindre la séance d'… », l'enseignant voit « E2E Adulte, Connecté ». Étape 3 (23:19 UTC, captures/E2E/parcours-8-apres) : « Dernières séances », « Voir tout » : « Samedi 31 octobre 22:15 à 23:45 » (ni présence ni minutes pour l'adulte). Rouge par la règle : FN-006 (séances enchaînées, l'enseignant passe par Classes). | 2026-10-31 23:19 UTC | [parcours-8](captures/E2E/parcours-8/) |  |
| A | Cas réel : l'adulte qui devient tuteur (inscrite « pour moi », puis « Ajouter un profil élève » à son nom) | rouge en local | Le Foyer dit « Aucun profil élève » à une élève adulte (UX-023) ; un profil mineur à son propre nom se crée sans avertissement (FN-104) ; « 18 ans ou plus » pour un enfant : bien bloqué, mais sans lien vers « pour moi » (UX-022) | 2026-10-31 22:31 UTC | [cas-A](captures/E2E/cas-A/) |  |
| B | Cas réel : la mère qui s'inscrit sous le nom de l'enfant, puis ajoute deux profils pour le même enfant | rouge en local | « Comment vous appelez-vous ? » ne dit pas « vous, le parent » (UX-024) ; acceptée sans avertissement (FN-105) ; 4 personnes du même nom dans le foyer, aucun contrôle de doublon (FN-104) | 2026-10-31 22:34 UTC | [cas-B](captures/E2E/cas-B/) |  |
| M | E-mails de l'application (file `courriels_sortants` → fonction `courriels-envoi` → Mailpit) | rouge en local | 115 e-mails envoyés et reçus dans Mailpit (10 modèles) après branchement local (coffre, secret, relais SMTPS). Contenu : FN-108 (mauvais public : « Un élève rejoint votre classe » au tuteur, « Votre enseignant est connu » à l'enseignant), UX-026 (ni classe, ni enfant, heure sans fuseau). Limite : en production, l'envoi réel (Gmail) n'est pas prouvé ici | 2026-10-31 23:05 UTC | [courriels](captures/E2E/courriels/exemplaires.md) |  |
| F | Finance : paie des enseignants, factures du mois, revenus de l'enseignant | rouge en local | Factures de novembre émises depuis l'interface : 55 $ (enfant) et 65 $ (adulte), au barème v2.0.0 : justes. Paie d'octobre : 0 $ (élève seulement « partiel », cohérent avec « payé par élève présent »), mais le détail échoue (FN-109). Revenus d'octobre non consultables (UX-029). Non branché : Vue globale, réserve, délégation, reçus de la famille (FN-110). Statistiques : aucun écran trouvé hors « Vue globale » (non branchée) | 2026-10-31 23:28 UTC | [finance](captures/E2E/finance/) |  |

## Lots en cours (se finissent, puis plus rien hors ligne d'arrivée)

| PR | Objet | Parcours servi | État |
|---|---|---|---|
| 98 | Remplacement automatique de l'enseignant absent | hors ligne (déjà commencé) | fusionnée le 31/10 ; fonction courriels-envoi redéployée par deploy.yml (version 12) |
| 100 | Séance ouverte par le jeton vidéo | 5 | rejouée par-dessus la 98 (a985822cf), 21/21 et 11/11 en local ; migration et fusion au matin (aucun appel Supabase la nuit) |
| 103 | Cahier hebdomadaire | 6 | fusionnée le 31/10, migration posée et vérifiée en production |
| 104 | Confier une classe à un autre enseignant | 2 | fusionnée le 31/10, migration posée et vérifiée en production |
| 106 | L'exception du cahier corrige la présence | 6 | fusionnée le 31/10 (480a19ca3) ; migration posée en production, corps identique au fichier (md5), déclencheur présent, fonction fermée à authenticated |
| 108 | Le remplaçant dépose le cahier (FN-002) | 6 | CI verte, relue par le pilote ; ouvre aussi une quatrième porte, hors des trois annoncées : `etat_presence` admet l'enseignant effectif comme 5e chemin (sans cela le brouillon du remplaçant restait refusé) ; ne fusionne pas avant la réponse du directeur sur la règle ; migration 20261103300000 à poser au matin, après relecture des politiques et des corps de production ; règle par défaut à confirmer par le directeur |
| 95 | Factures le 1er, relances | 7 | retenue jusqu'au 04/11 |

## Écart entre les migrations du dépôt et la production

Contrôle en lecture seule du 31/10 à 19 h 30 (UTC) : 288 fichiers de `supabase/migrations` sur
`main` comparés à la liste enregistrée en production. Tout écart compte comme un rouge tant qu'il
n'est pas expliqué.

| Migration du dépôt | Enregistrée en production | Objets présents en production | État |
|---|---|---|---|
| 0006, 0007, 0008 | sous les noms `0006_init`, `0007_init`, `0008_init` | oui | expliqué |
| `20261012113000_f86_observation_policy_guard` | non | oui (garde présente) | appliquée, non enregistrée |
| `20261012114000_f86_observation_entry_guard` | non | oui (garde présente) | appliquée, non enregistrée |
| `20261012140000_kyc_controller_storage_policy_retired` | non | oui (politique `kyc_lecture_admin` absente) | appliquée, non enregistrée |
| `20261027120000_notifications_classes_seances` | non | oui (7 fonctions, 6 déclencheurs, contrainte à jour) | appliquée, non enregistrée |
| `remplacement_auto` (PR 98, pas encore sur `main`) | non (collée par le directeur dans l'éditeur SQL) | oui : table présente, tâche planifiée active, 55 passages réussis (relu par l'ancien pilote le 31/10) | appliquée, non enregistrée |

Aucune migration de rattrapage de l'enregistrement sans décision du directeur.

## Dette en attente (on ne la règle pas maintenant)

Décrite et suivie dans le registre `UX-CONSTATS.md`, table « Constats fonctionnels » : FN-001 (CI
30/154), FN-002 (cahier du remplaçant), FN-003 (1799 minutes, affichage faux, argent juste), FN-004
et FN-005 (scénarios rouges sur `main`), FN-006 (séances qui s'enchaînent, bloquant), FN-007 (F1),
FN-008 (F2), FN-009 et FN-010 (foyers A et B), FN-011 (clés Stripe).
