# Lot LETTRE-CANDIDATS : la lettre de vérité aux candidats enseignants (ouvert le 20/11/2026)

**Statut au 20/11/2026 au soir : À LIVRER, codé sur la branche, testé localement seulement.** Rien
n'est en production ni prouvé par le directeur.

- Texte français **validé** par le directeur le 20/11 (« OUI c'est bon »), plus deux ajouts demandés
  après ce « oui » (mérite des gens du Coran, cours individuels), à relire par lui.
- Traductions arabe et anglaise faites par agent, **non relues par un humain** (`LETTRE-ar.md`,
  `LETTRE-en.md`). Langues choisies d'après les candidatures en base le 20/11 : `ar` 396, `en` 171,
  `fr` 41, sans langue 21.
- Page : `lib/features/candidature/lettre/` (page, corps, Praxis), route `Routes.lettreEnseignants`
  (`/lire/lettre-enseignants`), entrée dans « À savoir » du candidat. Le texte est dans
  `assets/i18n/*.i18n.json` sous `recrutement.lettre`.
- **Qui la lit** (directeur, 20/11 : « seulement les enseignants et les candidats qui ont complété
  les consentements […] Ça doit se faire aussi côté serveur ») : le routeur n'ouvre `/lire` qu'au rôle
  enseignant (actif, ou candidat en attente) ; la famille, l'élève, la direction et un compte suspendu
  sont refusés ; sans connexion, la connexion puis retour à la page. Le lien se partage donc entre
  enseignants et candidats, et la page reste dans l'application.
- **Contrôle serveur.** Le texte de la lettre n'est plus dans l'application compilée : il est retiré
  des fichiers de traduction (seule la tête de page y reste) et la page lit le port
  `lib/features/candidature/lettre/port_lettre.dart` (forme exacte de la réponse en tête du fichier).
  Tant que l'adaptateur n'est pas branché, le port dit « capacité indisponible » et la page n'affiche
  aucun texte. Le texte source reste dans `LETTRE-fr.md`, `LETTRE-en.md`, `LETTRE-ar.md`. **Le
  pilote prend le serveur** (réponse du 20/11, 22 h 45) sur une branche empilée sur celle-ci
  (`claude/lettre-serveur`) : table des textes sous RLS, fonction
  `public.lire_lettre_candidats(p_langue text)` (rôle enseignant actif, ou candidat aux accords
  acceptés ; sinon refus et liste de ce qui manque, sans texte), migration `20261130970000`, adaptateur
  `*_supabase.dart`, entrée dans le profil de l'enseignant (clé `recrutement.lettre.entree`, route
  `Routes.lettreEnseignants`), retrait de la ligne « La paie d'un enseignant » de « À savoir ». La PR
  finale vers `main` sera celle de la branche empilée.
- **Un seul Praxis** (directeur, 20/11 : « il ne doit pas apparaître plusieurs fois sur la même
  viewport, il est en haut, il saute et rebondit avec le scroll ») : dans la tête fixe de la page
  (`PageShell.enteteSecondaire`), il change de phrase avec la partie lue et saute à chaque changement
  et à chaque reprise du défilement ; aucun saut sous « Réduire les effets ».
- Verrou : un candidat dont le contrat, le code de conduite ou l'engagement religieux publié manque
  voit ce qui manque et « Accepter mes accords ». **Limite** : le texte est compilé dans l'application,
  le verrou est un affichage, pas un secret.
- Écarts aux règles du dépôt, signalés au directeur : l'emoji demandé (la cloche) est retiré de
  l'application (règle « zéro emoji » contrôlée par la CI) ; « groupes » remplacé par « cas » (mot
  interdit) ; une bande fixe en haut de page, petite, sur ordre du directeur malgré
  `DECISION-DEFILEMENT-2026-11-01` (« rien de gros collé au-dessus du contenu »).
- **Toute règle de la lettre absente de l'application ou contraire** : `REGLES-NOUVELLES.md` (25 lignes).
- Encore ouverts : l'entrée dans l'espace enseignant (l'espace existe et sert en production depuis
  près de deux mois ; l'emplacement est à choisir avec le pilote, qui coordonne le branchement) ; la ligne « La paie
  d'un enseignant : s'affichera ici… » de « À savoir » contredit maintenant la lettre (zone de la
  session « Parcours candidat enseignant », prévenue) ; le montrer aux élèves et aux familles donnerait
  les montants de la paie, ce que la décision du 22/10 réservait aux pourcentages.

## L'ordre du directeur (20/11/2026)

> « je veux leur écrire aujourd'hui car jusqu'à présent ils se sont inscrits mais n'ont aucune info
> sur leur salaire, le nombre de cours. » […] « en lisant ce document les candidats doivent être
> définitivement capable de savoir s'ils vont ou pas continuer avec nous. »

> « tu écris dans le dépôt nécessaire pour que ça ne soit pas oublié […] toi tu devras le créer ce
> texte en forme de site interne que les candidats verront dans l'espace d'attente, mais aussi dans
> l'espace enseignant. » Praxis animé dans la page « pour aider à détendre l'atmosphère, pointer les
> endroits pour guider ». « s'il dit que la page n'est pas prête alors tu crées d'abord le mini site
> en dehors, tu me montres sa maquette et tu attends la page pour transporter et brancher. »

## Ce qui reste à faire, dans l'ordre

1. **Validation du texte français** par le directeur (document de travail cité dans `LETTRE-fr.md`).
   Ensuite seulement, le texte entre dans `docs/current/TEXTES-VALIDES/`.
2. **Le mini-site interne** : une page longue, la page défile (`DECISION-DEFILEMENT-2026-11-01.md`),
   un sommaire qui mène à chaque partie, Praxis animé qui accueille et pointe les passages importants
   (paie, attente d'une classe, retard, pièce d'identité). Un seul Praxis : `lib/core/vivant/praxis_vivant.dart`
   et la compétence `praxis-rewayah` ; on ne le redessine pas.
3. **Où la page se branche** (interface : session « Parcours candidat enseignant ») :
   - espace d'attente du candidat : la rubrique « À savoir » de l'onglet Messages existe depuis #662
     (`lib/features/candidature/a_savoir_candidat.dart`, emplacements `paie`, `cours`, `entretiens`,
     vides et prévus pour ce contenu). Ne pas créer une seconde rubrique ;
   - espace enseignant : emplacement à choisir avec la même session.
4. **Qui la voit** (directeur, 20/11) : seulement le candidat qui a accepté les accords requis ; les
   autres voient la page, verrouillée, avec ce qui leur manque. **Le serveur décide**, jamais l'écran
   (lecture à créer ou à réutiliser : chercher d'abord ce que `etat_dossier` et les versions requises
   de `contract_required_versions` donnent déjà).
5. **Traductions** : après validation du français, l'arabe d'abord (près de 80 % des candidats sont
   arabophones, directeur, 20/11). Aucune traduction automatique des versets et invocations
   (`mots-rewayah`).

## Décisions données par le directeur le 20/11, dans les commentaires du texte

Elles sont **dans la lettre**, mais **pas encore dans les sources de vérité ni dans l'application**.
Tant que les lignes « Écart » ne sont pas fermées, la lettre promet quelque chose de faux.

| Décision du 20/11 | Écart avec l'existant |
| --- | --- |
| Part de l'enseignant : **47 % pour les adultes, environ 45 % pour les enfants** (suivi des enfants après le cours) | `DECISION-TARIFS-2026-10-18.md` (19/10) et la base disent 47 % pour tous. Nouvelle décision datée à écrire, réglage à changer en base |
| **Élève absent : l'enseignant reçoit la moitié de sa part** pour la séance (« sinon ils ne vont pas faire d'effort pour les garder ») | `absence_eleve_payee: false` dans `tarifs-2026-10-18.json` ; la paie ne paie que le présent. Décision à écrire, calcul à changer |
| **L'arabe est une langue de cours** : une classe d'élèves arabophones reçoit un enseignant arabophone (« près de 80 % des candidats sont des arabes ») | Décision du 22/10 contraire (`savoir-rewayah` §5, `langues_cours`). À écrire comme nouvelle décision, puis corriger les compétences |
| **Montants donnés aux candidats inscrits** (« avant qu'ils s'inscrivent » : pourcentages ; « aujourd'hui ils sont inscrits, ils ont le droit de savoir combien ils vont gagner ») | Amende la décision du 22/10 (pourcentages seulement) pour les candidats inscrits. À écrire dans `DECISION-TARIFS` et `savoir-rewayah` §4 |
| L'académie existe depuis **près de trois ans** ; avant, chacun enseignait de son côté | Dossier maître : lancement le 01/05/2024. Formulation retenue, pas d'écart |
| Versement : **officiellement au plus tard le 5**, en pratique avant | Conforme |
| Une classe reçue en cours de mois : **payée sur les séances restantes du mois** | Conforme au paiement à la séance, à vérifier dans le calcul |
| Le remplaçant reçoit **100 %** de la paie de la séance | À vérifier dans le calcul |
| Perdre une classe (absence déclarée non tenue) **ne fait pas perdre l'accès** : l'enseignant se déclare disponible pour d'autres classes | À vérifier dans le code |
| **Enseigner ailleurs est permis**, sauf aux mêmes heures | Nouvelle règle, à écrire |
| **Hors de la salle plus de 30 secondes pendant son cours : l'enseignant est sorti et la direction prévenue** | **Introuvable dans le dépôt le 20/11.** La règle des 30 s existe pour les élèves et a été retirée de l'entretien (registre des lots, QUALITE-VIDEO-ENTRETIEN). À vérifier avant validation |
| Visite de contrôle incognito ; **une enseignante est toujours visitée par une femme** | Visite incognito existante (`06` §, contrôleur). Le choix d'une visiteuse : à vérifier |
| Remise aux **nouveaux convertis** (jamais imputée à l'enseignant) | Absente de `tarifs-2026-10-18.json`. À écrire |
| Matricule au format **« #xxxxxx@ra »** | L'application délivre `RA-26-4817` (`DECISION-IMMATRICULATION-2026-10-12.md`). Lot à part, « pas urgent » (directeur). La lettre ne donne pas de format |
| Praxis : **en service, mis en pause** après quelques erreurs, en réglage avant relance | Conforme à l'état du 20/11 (PX-6, retrait annulé, PR #653) |
| Adresse pour se retirer : **support@rewayahacademy.com** | Conforme |

**Encore ouverts** : le montant minimum pour verser les gains d'un remplaçant ; le nombre
d'avertissements avant de perdre une classe ; une relecture juridique de la phrase sur les lois de
protection de l'enfance (partie 8) ; les chiffres « plus de 2 000 candidats » et « plus de 50
nationalités » (tableau Google, non ouvert par l'agent).

## Délais de retard écrits dans la lettre (lus dans la base, pas inventés)

Salle ouverte 20 min avant (`PARCOURS-OUVERTURE-2026-11-01.md`) ; avertissement à T+3
(`remplacement.avertissement_minutes`) ; perte de la séance et alerte à T+8
(`remplacement.perte_acces_minutes`) ; remplaçant en classe à T+11 au plus
(`remplacement.debut_remplacant_minutes`). Si un de ces réglages change, la lettre change.

## Coordination

- **Interface** : session « Parcours candidat enseignant » (accueil du candidat, #662).
- **Praxis animé** : le pilote de l'équipe (Praxis, secrétaire IA).
- Si la page n'est pas prête : maquette hors de l'application, montrée au directeur, puis transport.

## Maquette (20/11/2026)

Hors application, en attente de la page : https://claude.ai/artifact/4HDGDYh15w9cS5EEkifcu5.
Sources dans `maquette/` : `template.html` + `build.py` produisent `lettre-candidats.html` depuis `LETTRE-fr.md`
(`python3 build.py LETTRE-fr.md template.html lettre-candidats.html`). Praxis y est dessiné en SVG d'après la fiche
de `praxis-rewayah` §2, pour la maquette seulement : dans l'application, on utilise le composant du dépôt, jamais ce dessin.
Les phrases de Praxis et ses gestes par partie sont des propositions.

Réponse de la session « Parcours candidat enseignant » (20/11) : une ligne dans « À savoir » ouvre une page dédiée,
fichier neuf `lib/features/candidature/lettre_candidats_page.dart` avec sa route ; `a_savoir_candidat.dart` modifiable
pour cette seule ligne ; prévenir avant de toucher `accueil_candidat.dart`, `messages_candidat.dart`, `attente_page.dart` ;
textes fr, en, ar ; Praxis par `AvatarPraxisCandidat` (`praxis_candidat.dart`), Praxis de référence avec la PR 664.
Verrou : aucune lecture « accords requis acceptés » vérifiée ; piste `public.etat_dossier()`, sinon migration à partir
de `20261130970000`. Espace enseignant : rien de construit ni de validé, question au directeur.

## Le guide et ses interactions (directeur, 20/11/2026, 23 h)

> « la page "lettres" qui doit s'appeler autre chose que lettre, je veux qu'il y ait quelques
> interactions avec elle ; je veux que les gens puissent y commenter directement, ces commentaires
> doivent être vus par l'admin et par Praxis qui peut y répondre directement ; on peut aussi laisser
> des likes et vois pour le dislike ça peut aider. Ces interactions sont publiques, les autres peuvent
> le voir, sauf les commentaires. »

**Nom** (choix de l'agent, à confirmer) : « Guide de l'enseignant » (en : « Teacher's guide » ;
ar : « دليل المعلّم »), adresse `/lire/guide-enseignant`. Les clés internes `recrutement.lettre.*`
et la constante `Routes.lettreEnseignants` gardent leur nom ; seuls les mots visibles et la valeur de
l'adresse changent.

**Par partie** (choix de l'agent) : chaque partie a son « J'aime » et son « Pas clair », et son fil de
commentaires. Un avis sur une partie précise dit à la direction quel passage réécrire ; un avis sur
toute la page ne le dirait pas. « Pas clair » plutôt que « Je n'aime pas » : le directeur veut que le
désaccord « aide » ; il signale un passage à reformuler, pas une humeur.

**Qui voit quoi** :
- les nombres de « J'aime » et de « Pas clair » de chaque partie : tous les lecteurs ;
- l'avis donné par un lecteur : lui seul (on montre les totaux, jamais qui a cliqué) ;
- un commentaire et ses réponses : son auteur, la direction et Praxis ; jamais les autres lecteurs.

**Contrat serveur** (forme JSON, même règle d'accès que la lecture du guide) :
- `lire_interactions_guide()` →
  `{"parties": [{"code": "p1", "jaime": 12, "pas_clair": 3, "mon_avis": "jaime" | "pas_clair" | null}],
    "commentaires": [{"id": "uuid", "partie": "p4", "corps": "...", "cree_le": "ISO 8601",
                      "auteur": "moi" | "direction" | "praxis", "parent_id": "uuid" | null}]}`
  (`commentaires` : seulement les fils de l'appelant, réponses comprises) ;
- `donner_avis_guide(p_partie text, p_avis text)` : `jaime`, `pas_clair`, ou nul pour retirer ; un seul
  avis par lecteur et par partie ; rend la ligne de la partie, à jour ;
- `commenter_guide(p_partie text, p_corps text)` : 1 à 2 000 caractères ; rend le commentaire ;
- côté direction : `commentaires_guide_direction()` (tous les fils, avec le nom et le rôle de l'auteur)
  et `repondre_commentaire_guide(p_commentaire uuid, p_corps text)` (réponse signée « direction ») ;
- côté Praxis : la même lecture et une réponse signée « praxis », par ses outils (Praxis est en pause
  au 20/11 : il répondra quand il sera relancé ; la direction répond d'ici là).

**Partage du travail** : la page du lecteur (boutons, fil, champ) est dans ma zone, sur le port
`port_lettre.dart` ; les tables, les fonctions, l'adaptateur, l'écran de la direction et les outils de
Praxis sont hors de ma zone (garde-fou) : proposés au pilote, sur sa branche empilée.

**Côté lecteur, fait sur une branche à part, `claude/guide-interactions` (20/11, 23 h 30 ; à la
demande du pilote, pour que la PR de la lecture ne porte aucun bouton sans serveur)** : port
`PortInteractionsGuide` dans `port_interactions_guide.dart` (forme JSON en tête de la section), indisponible par défaut ; boutons « J'aime » et
« Pas clair » sous chaque partie, l'avis s'affiche tout de suite et revient en arrière si le serveur
refuse ; « Commenter cette partie » ouvre le fil privé du lecteur (ce qu'il a écrit, les réponses de
la direction et de Praxis, un champ, « Envoyer mon commentaire »). Rien ne s'affiche tant que le
serveur des interactions n'est pas branché. Tests sur un faux serveur. Le pilote prend le serveur
(lot 2) après la fusion de la lecture (lot 1), et pose d'abord au directeur la question de la
messagerie : un commentaire ouvre-t-il un fil de la messagerie existante (`MESSAGERIE-MATRICE.md`),
plutôt qu'un second circuit ?

**Correction (20/11, 23 h 30)** : jusqu'ici, Praxis ne suivait pas la lecture : `PageShell` fait
défiler toute la tête avec une page défilante, et il disparaissait en haut. La page garde maintenant sa
tête fixe et fait défiler le corps seul (`REGLES-NOUVELLES.md`, I4) ; un test vérifie qu'il reste en
haut après le défilement.

## Décisions du directeur du 21/11/2026

1. **Tête fixe : oui.** À la question « Tu gardes Praxis collé en haut malgré la règle du 01/11
   (`DECISION-DEFILEMENT-2026-11-01.md`) ? », le directeur a répondu le 21/11/2026 : « Oui, tête
   fixe ». Le titre court et la bande de Praxis restent fixes et seul le corps défile. C'est une
   exception à la règle du 01/11, valable **pour cette page seulement** ; la règle reste en vigueur
   partout ailleurs.
2. **Commentaires : pas dans la messagerie.** Réponse du directeur du 21/11/2026 : « En tout cas on
   ne doit pas surcharger la messagerie ». L'agent recommande un **circuit à part**, accepté dans le
   cadre posé par le directeur : les commentaires restent attachés à leur partie du guide (contrat
   JSON ci-dessus : `commenter_guide`, `commentaires_guide_direction`,
   `repondre_commentaire_guide`). La direction les lit sur une liste à elle, qui reste à faire
   (pilote, lot 2). Aucun fil de la messagerie n'est ouvert et la matrice `MESSAGERIE-MATRICE.md`
   ne change pas. Il reste une seule question ouverte, à poser au directeur au moment du lot 2 : où
   la direction voit qu'un commentaire attend une réponse (pastille dans son menu, ou rien).
