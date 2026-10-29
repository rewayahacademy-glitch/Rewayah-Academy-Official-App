# Fiche : refonte de l'onboarding (admission, lot B), 29/10/2026

Demande du directeur (29/10, par le pilote) : refaire **tout** l'onboarding, pas seulement le premier écran ; style allégé, sans gros rectangles ; une question par écran ; les bonnes questions dans le bon ordre, pour que le profil qui arrive dans l'application soit le bon. Références : `docs/current/PARCOURS-ENTREE-2026-10-25.md` (§3 B et E), `docs/orchestration/ETUDE-ACCUEIL-ET-CLASSES-2026-10-25.md` (comparaison avec Riwayah), `docs/current/DECISION-ADMISSION-2026-10-27.md`.

Cette fiche est écrite **avant** de construire, comme l'étude le demande (« une fiche d'écran d'abord, validée par le directeur, puis une seule PR »). Rien de ce qui suit n'est encore codé, sauf le premier écran (deux choix égaux, branche `claude/admiring-brown-r6ai72-admission-b`).

## 1. Ce qui se contredit, à trancher d'abord

| # | Contradiction | Ce que je propose |
|---|---|---|
| C1 | PARCOURS-ENTREE (25/10) et l'étude : « **aucune attente de validation pour une famille** ». DECISION-ADMISSION (27/10, plus récente) : « **personne n'entre sans décision de la direction** », familles comprises. | La plus récente prévaut : la famille répond au questionnaire, crée son compte, puis attend sur « Votre demande est en cours ». Le lot B est codé ainsi. |
| C2 | Questionnaire **avant** le compte (PARCOURS-ENTREE §3 B, « sinon les gens fuient ») ; aujourd'hui, les questions de la classe (langue, niveau, objectif, moments, horaires) ne se posent qu'**après** l'admission, par enfant, dans `/tuteur/parcours`. | Les poser avant le compte, gardées sur l'appareil, puis envoyées avec la demande : la direction décide en voyant qui apprend et quoi (§4). |
| C3 | Un tuteur en attente **ne peut pas créer de profil élève** (`creer_profil_enfant` exige un compte actif) ; la direction déciderait donc sans voir les enfants. | Les enfants du questionnaire partent avec la demande (prénom, âge, réponses) ; leurs profils sont créés **à l'acceptation** (lot C), sans rien ressaisir. Changement serveur : §4. |
| C4 | Le genre de l'enfant n'est demandé nulle part (l'ajout d'un profil élève demande prénom, nom et âge) ; or les classes ont un genre et la clé des regroupements aussi. | Le demander pour chaque enfant (« Garçon » / « Fille »), une puce. À confirmer : à partir de quel âge les classes ne sont plus mixtes. |

## 2. Le style

- **Une question par écran**, « Étape x sur n » en haut, un seul bouton plein « Continuer » en bas (contrat K-56), « Retour » en lien.
- **Puces** (`FilterPill` en choix, ou cartes compactes `enLigne`) pour les choix courts : oui/non, âge, langue, moments, genre. **Cartes avec exemple** seulement pour le niveau et l'objectif, où une explication aide (étude, §2). Plus de grandes cartes à illustration ailleurs.
- **Aucun rectangle dans un rectangle** : questions et choix posés sur la page, comme la connexion (décision 6 de l'étude).
- Ordinateur, dès 840 points : deux volets, la question au début de ligne, les réponses à côté ; lettres A, B, C au clavier pour choisir (étude, §2).
- Références publiques : Material 3 (chips de choix, une action principale), Apple HIG (onboarding court, « demander seulement ce qui sert »), Baymard (une question par écran sur mobile, progression visible, compte en dernier). La revue détaillée ira dans `UX_REVIEW_ONBOARDING.md`, avec la PR.

## 3. Les questions, dans l'ordre

Neuf écrans au plus avant la connexion pour une famille d'un enfant, cinq pour « pour moi » (l'étude veut « moins de dix étapes ») ; chaque enfant de plus ajoute quatre écrans (prénom, âge, genre, niveau). Les deux codes d'invitation (enseignant, comptable) et « J'ai déjà un compte » sautent tout et vont à la connexion.

| # | Écran | Question | Réponses | Pour qui |
|---|---|---|---|---|
| 1 | Pour qui | « Pour qui créez-vous ce compte ? » | Je m'inscris pour moi · J'inscris mon enfant | tous |
| 2 | Enfant, prénom | « Comment s'appelle votre enfant ? » | prénom (saisi) | enfant |
| 3 | Enfant, âge | « Quel âge a {prénom} ? » | puces de 4 à 17 ans | enfant |
| 4 | Enfant, genre | « {Prénom} est… » | Un garçon · Une fille | enfant |
| 5 | Le parent aussi | « Suivez-vous aussi des cours ? » | Oui · Non | enfant |
| 6 | Langue du cours | « Dans quelle langue le cours doit-il être donné ? » | puces (liste existante) | tous |
| 7 | Niveau | « Où en est {prénom} aujourd'hui ? » (« Où en êtes-vous ? » pour moi) | cartes avec exemple (cinq niveaux existants) | une fois par apprenant |
| 8 | Objectif | « Que souhaitez-vous d'abord ? » | cartes (quatre objectifs existants) | tous |
| 9 | Moments | « Quels moments de la journée vous conviennent le mieux ? » | puces, plusieurs | tous |
| — | Pays et fuseau | détectés de l'appareil, confirmés d'une ligne (« Heure de Paris : changer ») ; le sélecteur avec recherche des enseignants s'ouvre si besoin | — | tous |
| — | Connexion | adresse, « Recevoir le lien » ou Google (inchangé) | — | tous |
| — | Vous | « Votre prénom et votre nom », puis « Vous êtes… » (Un homme · Une femme) | saisis, puce | tous |
| — | Récapitulatif | « Voici ce que nous avons compris » : vous, chaque apprenant et ses réponses ; « Ajouter un autre enfant » (lien, revient à 2) ; « Envoyer ma demande » | — | tous |

Pour « pour moi » : écrans 1, 6, 7, 8, 9. Pour une famille : 1 à 9 (l'écran 7 une fois par enfant, et une fois pour le parent s'il suit des cours).

Les horaires publiés (offres) **ne sont pas** dans l'onboarding : ils restent après l'admission, dans `/tuteur/parcours` (« Voici les horaires ouverts pour… »), puisque la direction décide d'abord. À trancher (§6, Q3).

## 4. Le profil obtenu et l'écran d'arrivée, pour chaque combinaison

| Réponses | Compte créé | Profils élèves | Demande | Avant la décision | Après acceptation |
|---|---|---|---|---|---|
| Pour moi | tuteur titulaire, `pending_kyc`, usage `moi` | le sien, `autonomous`, `adulte_18_plus`, créé tout de suite (déjà le cas) | `eleve_adulte` | « Votre demande est en cours » | accueil de l'élève adulte (`/eleve/adulte`), barre « Aujourd'hui · Apprendre · Suivi · Profil » (lot B2) |
| Mon enfant, parent sans cours | tuteur titulaire, `pending_kyc`, usage `famille` | aucun avant la décision ; un par enfant à l'acceptation, `minor`, cohorte d'après l'âge | `famille`, avec chaque enfant (prénom, âge, genre) et ses réponses | « Votre demande est en cours », avec la liste des enfants | accueil du tuteur (`/tuteur`) ; chaque enfant a son profil et ses réponses, son « Parcours » s'ouvre sur les horaires |
| Mon enfant, parent avec cours | tuteur titulaire, usage `famille`, « suit des cours » | le sien tout de suite (`autonomous`) ; ceux des enfants à l'acceptation | `famille`, enfants et parent | idem | accueil du tuteur ; le parent rejoint son espace d'élève par l'accueil |
| Enfant de 18 ans ou plus | — | — | — | l'écran 3 propose « Il a 18 ans ou plus : il crée son propre compte » | — |
| Code enseignant | inchangé (salle d'examen) | — | `enseignant` | portail de candidature | inchangé |
| Code comptable | inchangé | — | — | — | inchangé |
| J'ai déjà un compte | — | — | — | connexion | racine de son rôle |

Changements serveur que cela suppose (à écrire avec la PR, dans `supabase/`) :

1. La demande garde ses apprenants : une table `candidature_apprenants` (demande, prénom, âge, genre, langue, niveau, objectif, moments), lue par la direction au lot C. Aucune donnée d'enfant dans un compte créé avant la décision.
2. À l'acceptation (lot C), une fonction crée en une transaction les profils des enfants (comme `creer_profil_enfant`) et y range leurs réponses (comme le parcours d'aujourd'hui), puis active le tuteur.
3. `inscrire_titulaire` reçoit ces apprenants (JSON borné : 6 apprenants au plus, champs validés), dans la même transaction que la demande.

## 5. Ce qui est déjà fait sur la branche du lot B

- Premier écran : « Pour qui créez-vous ce compte ? », deux choix égaux côte à côte.
- Atterrissage de l'adulte « pour moi » sur son accueil adulte.
- Serveur : famille et élève adulte en attente avec leur demande, e-mail « Votre demande est bien reçue ».

## 6. Questions au directeur

| # | Question | Ma proposition |
|---|---|---|
| Q1 | C1 : la famille attend la décision (27/10) et non « aucune attente » (25/10) ? | Oui, la décision du 27/10 |
| Q2 | C3 : les enfants partent avec la demande et leurs profils sont créés à l'acceptation ? | Oui |
| Q3 | Les horaires publiés restent après l'admission ? | Oui : on ne propose pas un horaire avant d'avoir accepté la famille |
| Q4 | C4 : le genre de l'enfant est demandé ; à partir de quel âge les classes ne sont plus mixtes ? | Le demander toujours ; la règle d'âge vient de vous |
| Q5 | Neuf écrans au plus avant la connexion pour une famille d'un enfant, cinq pour « pour moi », comme ci-dessus ? | Oui |
