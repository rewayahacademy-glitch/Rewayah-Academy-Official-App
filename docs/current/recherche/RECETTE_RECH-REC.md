# RECH-REC : recette front de la recherche (REC-01 à REC-14)

Fiche RECH-REC, voie VERIF, lot RECH-FIN (11/10/2026). Source : spec RECH-03 V3 §10, §14, §16
(branche `docs/specs-entrantes-2026-10-10` @ db050205). Recette **front** sur le double de démonstration :
aucun accès à staging, aucune requête vers la production, aucun serveur. Le vérificateur doit être un
non-auteur ; cette recette est celle de l'auteur du lot RECH-FIN et reste à contre-vérifier.

Statuts de preuve : `spécifié`, `codé`, `test local`, `test staging`, `prêt à activer`, `bloqué`.
Rien n'est `test staging` ni `prêt à activer` : le serveur de recherche (RPC, RLS, index) est à Codex
(K-68, lignes Contrats C-31 à C-33) et n'existe pas encore.

Preuve locale au SHA `b173096b` : `flutter test` complet 14 036 réussis, 0 échec (6 765 ignorés par
conception) ; `dart analyze --fatal-infos` 0 ; `verifier_jetons` 18 ; `verifier_revue` 1 217 (identique à la base).

## 1. Verdict par domaine

| Domaine | Moteur | spécifié | codé | test local | test staging | prêt à activer | bloqué par |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| Classes | `MoteurClassesGroupes` (D1) | oui | oui | oui | non | non | adaptateur serveur C-32 ; filtre local sur un petit corpus, démonstration seulement |
| Supports | `MoteurSupportsCatalogue` (D1) | oui | oui | oui | non | non | adaptateur serveur C-32 ; CAP29-0 (`PortBibliothequeAdmin`) non lu |
| Personnes (familles, élèves, RA exact) | `MoteurPersonnesFoyer` (D2) | oui | oui | oui | non | non | contrat serveur de résolution d'un RA exact (`DB-RECH-RA`, Immatriculation non livrée) ; aucun annuaire côté admin hors RA exact |
| Enseignants | `MoteurEnseignantsDesClasses` (D3) | oui | oui | oui | non | non | C-33 ; pas d'annuaire pour l'enseignant ni l'administration |
| Pédagogie (élèves de mes classes) | `MoteurPedagogieEleves` (D3) | oui | oui | oui | non | non | C-33 |
| Contrôle | `MoteurControleMission` (D3) | oui | oui | oui | non | non | C-33 ; mission réelle à lire côté serveur |
| Remplacements | `MoteurRemplacements` (D3) | oui | oui | oui | non | non | REMPL-BR : `portRemplacementsProvider` nul en production |
| Finances | `MoteurEncaissements` (D4) | oui | oui (comptable seul) | oui | non | non | serveur de recherche financière ; bénéficiaire, Direction, second adulte : aucun moteur (CPT-Q1 ouvert) |
| Fils et canaux | `MoteurFils` (D4) | oui | oui | oui | non | non | serveur Communications ; Studio réservé à l'administration en V1 |
| Publications / évaluations (REC-06) | aucun | oui | non | non | non | non | pas de domaine côté front |
| Coran (sourate, verset, page) | aucun | oui | non | non | non | non | rendu du Coran interdit à ce lot ; pas de domaine |

Lecture : tous les domaines codés sont `test local` et **aucun n'est prêt à activer**. En production
`moteursRechercheProvider` reste vide : aucune loupe ne s'affiche, aucune donnée de démonstration n'est servie.

## 2. REC-01 à REC-14

| REC | Ce que le front prouve (test local) | Ce qui reste serveur ou non couvert | Verdict |
| :--- | :--- | :--- | :--- |
| 01 Foyers | RA inconnu, d'un autre foyer ou retiré : même réponse vide, jamais d'indice (`familles_eleves_test`, `familles_eleves_surface_test`) ; un début de RA n'interroge pas le serveur ; recherche par nom bornée au foyer ; aucun total, aucun export ; titre et contexte ne répètent pas le RA | API, suggestions, compteurs serveur, liens directs réautorisés à l'ouverture | test local, serveur non prouvé |
| 02 Classes | les classes et remplacements viennent des ports « mes classes » ; une offre prise par un collègue n'est jamais trouvée (`enseignants_pedagogie_controle_test`) | enseignant affecté contre autre enseignant sous RLS ; remplacement expiré à l'instant T | test local partiel |
| 03 Champs | note privée, objectif, RA d'élève : ne font pas remonter un élève (D3) ; montants, moyen, prestataire non cherchés (`finance_communications_test`) ; aperçu de message non cherché ; effectif non cherché (D1) | champs cachés côté index et suggestions serveur | test local |
| 04 Contrôle | mission expirée = refus `contexteRevoque`, jamais un vide ; ni élève, ni rapport, ni effectif (D3) | roster, rapport et fil sous mission étrangère ; KYC | test local partiel |
| 05 Finance | seul l'espace comptable est servi (`finance_communications_test`, `recette_front_test`) ; refus du module = échec, pas un vide | **bénéficiaire, Direction, second adulte : aucun moteur** (hors écart assumé, CPT-Q1) ; projections exactes serveur | **non couvert hors comptable** |
| 06 Publications | aucun domaine publications dans le front | alias EV, publication retirée : tout | spécifié seulement |
| 07 Session | changement de compte vide requête, résultats et curseurs (SEC-R07) ; droit retiré en cours de route ; session expirée (`controleur_recherche_test`) | JWT ancien après retrait de capacité | test local partiel |
| 08 Pagination | curseur d'une autre requête, d'un autre espace ou falsifié refusé (`classes_supports_test`, `familles_eleves_test`, `controleur_recherche_test`) ; page plafonnée à 50 ; « Voir davantage » sans total | droits revérifiés entre deux pages ; tri déterministe serveur | test local partiel |
| 09 Messages | la barre commune ne matche ni le corps ni l'aperçu d'un fil ; un fil non métier est écarté ; canaux par nom seulement (`finance_communications_test`) ; le module dédié (`recherche_fils`, `recherche_studio`) n'est pas touché | conservation des messages, lisibilité côté serveur | test local |
| 10 Langues | français sans accent, translittération repliée, arabe sans voyelles brèves, RTL (`normalisation_test`, `recherche_formats_test`) | anglais, poular, sourate / verset / page : **non testés** ; source du Coran non touchée | test local partiel |
| 11 Robustesse | 18 saisies hostiles (HTML, SQL, regex, NUL, RTL override, 5 000 caractères, 40 termes, émojis, arabe) rejouées sur tous les moteurs et les 7 espaces (`recette_front_test`) : jamais d'exception, jamais de reflet de la saisie ; bornes 160 caractères et 8 termes ; réponse obsolète ignorée ; délai à 3 s | injection côté serveur, limite de débit serveur | test local ; écart E1 ci-dessous |
| 12 Disponibilité | panne = échec nommé, jamais « aucun résultat » ; reprise après panne (échec puis résultats) ; sans moteur, aucun domaine ni réponse inventée | domaine non implémenté côté serveur | test local |
| 13 Charge | **non faisable par le front.** Mesure du double en mémoire : p50 0,42 ms, p95 0,79 ms, p99 1,66 ms sur 600 requêtes de moteur à 3 000 éléments par domaine | dataset synthétique, RLS réelle, p95/p99 sur staging | bloqué (staging) |
| 14 Cycle de vie | aucun historique de requêtes, aucun cache partagé ni persistant dans `lib/core/recherche` et `lib/features/recherche` ; purge au changement de compte | suppression, archivage, retrait de publication, purge des copies | test local partiel |

## 3. Écarts constatés par cette recette (à traiter, non corrigés ici : RECH-REC est en lecture seule sur le code)

| # | Écart | Preuve | Gravité |
| :--- | :--- | :--- | :--- |
| E1 | **Corrigé (commit E1, 11/10)** : la coupe se fait sur les runes (`RequeteNormalisee.de`), test d'un émoji à la frontière dans `normalisation_test.dart`. Constat d'origine : la coupe à 160 caractères de `RequeteNormalisee.de` (`budgets_recherche.dart`) travaille en unités UTF-16 : une saisie avec un émoji sur la coupe laisse une moitié de paire de substitution (dernier code `0xD83D`). La chaîne n'est plus du texte valide à envoyer au serveur. | mesure : `'a' * 159 + '😀fatiha'` rend 160 unités, dernier code `0xD83D` | faible ; corrigé |
| E2 | Les moteurs de domaine filtrent localement un corpus déjà autorisé (D1, D3, D4, filtre par nom de D2). Ce n'est pas une recherche : ils ne sont valables qu'en démonstration. | commentaires de réserve dans chaque moteur ; `moteursRechercheProvider` vide en production | information |
| E3 | La démonstration ne branche D2 que dans la coque du tuteur. Finance et fils n'ont de double de démonstration que dans les modules (`EncaissementsDemo`, `MessagesMetierDemo`, `StudioDemo`) et ne sont pas posés dans `moteursRechercheProvider` d'une démonstration de coque. | `mode_demonstration.dart` | information |
| E4 | Mesure de performance : un double en mémoire ne dit rien d'un serveur ; l'écran lui-même (rendu, défilement) n'a pas de p95 mesuré. | `recette_front_test` | information |
| E5 | Captures faites (§5), sauf la maquette 07 (salle : fichiers réservés). | `docs/current/captures/RECH-REC/` | information |

## 4. Ce qu'il faut pour activer

1. Contrats lignes C-31 à C-33 servies par Codex, plus le contrat de résolution d'un RA exact (Immatriculation) ;
2. rejouer REC-01 à REC-14 sur staging avec RLS réelle, dataset synthétique et mesure p95 / p99 (gates D et E) ;
3. décision CPT-Q1 (finance pour bénéficiaire, Direction, second adulte) avant tout moteur de finance côté famille ;
4. (E1 corrigé) ;
5. vérificateur non auteur sur ce document et sur les captures.

## 5. Captures contre les sept maquettes

Produites par `test/capture/rech_rec_capture_test.dart` (vrai routeur, vraies polices, doubles de démonstration ; saute sans `CAPTURE_DIR`) et rangées dans `docs/current/captures/RECH-REC/` : captures `rec_*.png`, planches `planche_0N_*.png` (maquette | capture), maquettes copiées dans `maquettes/`. Playwright n'a pas servi : les captures Flutter rendues par le moteur de test sont la méthode du dépôt (`test/capture/LISEZ-MOI.md`).

| Maquette | Capture | Écarts constatés (maquette contre écran réel) |
| :--- | :--- | :--- |
| 01-M famille | `planche_01_famille.png` (390, puis RA exact D2) | La maquette montre Mes classes et Supports avec « Voir tout » par section ; l'écran groupe par domaine avec « Voir davantage » et des puces `Tout / Classes / Supports` (« Mes classes » n'est pas le libellé du domaine). Titre « Recherche » (maquette) contre « Rechercher » (texte §5). Le résultat par RA exact (Personnes) n'a pas de maquette. |
| 02-M guidée | `planche_02_guidee.png` | Écran d'Interface guidée conforme à RECH-2 ; pas d'aide audio sur la liste (composant `AudioLabel` non posé). |
| 03-D enseignant sombre | `planche_03_enseignant.png` | Pas d'encart « Informations pédagogiques seulement » ; navigation prise du code, pas de la maquette. |
| 04-D admin clair | `planche_04_admin.png` (puis fils et canaux D4) | La maquette montre « Actions disponibles » et « Personnes dans votre périmètre » : non rendus (pas de domaine personnes pour l'administration hors RA exact, pas de bloc d'actions). Pas de puce « Période ». |
| 05-D comptable | `planche_05_comptable.png` | La maquette est un tableau Référence / Objet / Date / État avec pastilles d'état ; l'écran rend des lignes (référence, famille) : le résultat de recherche n'a ni date ni état dans sa liste blanche. Pas de puces de domaine (un seul domaine servi). Pas de note « montants non visibles ». Le menu du comptable allume « Compte » sur `/recherche`, comme pour tous les rôles (page commune). |
| 06-M états | `planche_06_etats.png` (vide, hors ligne, domaine en panne) | Les états sont ceux de RECH-2 ; la capture « domaine en panne » montre les résultats d'un domaine et laisse le message du domaine en panne sous le pli. |
| 07-T tablette Classe | non capturée | Salle, `tc_classe_live`, `tc_dock` : fichiers réservés, hors lot. |

Ces écarts sont des constats, pas des corrections : la maquette n'élargit jamais une permission (DESIGN-GOV §1) et le tableau d'opérations demanderait une date et un état dans `ResultatRecherche`, à décider avec Codex.
