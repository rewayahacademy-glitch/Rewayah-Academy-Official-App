# Contrat de la file des courriels du recrutement (`CAND-Q10`)

**Pour qui.** La session qui construit l'envoi des courriels, après le site public
(`DEC:33` : « l'autre session va construire l'envoi d'e-mails après sa session sur
le site public »). Ce document lui dit ce que le module des candidatures écrit,
ce qu'elle lit, ce qu'elle écrit en retour, et ce que personne n'écrit jamais.

**Statut :** `spécifié`, **proposition**. Rien de ce qui suit n'existe en base :
la file s'écrit au lot L5 (`SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md`, désormais
`CONS`, section 11). Les noms de table, de fonctions et de modèles sont proposés ;
L5 peut les changer, pas les règles. Une règle de `CONS` 7.3 qui diffère d'ici
s'applique, sauf les quatre écarts de la section 9, soumis au directeur.

## 1. Qui fait quoi

| Acteur | Fait | Ne fait jamais |
| :--- | :--- | :--- |
| Module des candidatures | écrit une ligne `a_envoyer` à chaque événement de la liste fermée (section 3), dans la transaction du geste ; passe une ligne pas encore partie à `annule` quand elle n'a plus de sens (section 6) | envoyer ; écrire `envoye` ou `echec` |
| Envoi (session du site public) | prend des lignes, compose le courriel depuis son modèle, l'envoie, écrit `envoye` ou `echec` | lire une autre table du module ; écrire un texte dans la file ; changer un destinataire, un modèle ou un paramètre |
| Direction | lit l'état d'un courriel dans la candidature (section 7) | changer un état ; lire les paramètres (le code d'invitation) |
| Candidat | rien | lire la file |

## 2. La table

Nom proposé : `public.candidature_courriels`. RLS activée, aucune policy, aucun
privilège de table pour `PUBLIC`, `anon`, `authenticated`, `agent_ro` ni
`service_role` : tout passe par les fonctions de la section 4.

| Colonne | Type | Règle |
| :--- | :--- | :--- |
| `id` | `uuid` | clé ; sert aussi de clé d'idempotence chez le fournisseur |
| `candidature_id` | `uuid` | `public.candidatures(id)`, `ON DELETE RESTRICT` |
| `destinataire_profil` | `uuid` ou nul | le compte du candidat |
| `destinataire_courriel` | `text` ou nul | seulement pour une ligne sans compte (invitation d'une réponse importée) : le courriel importé valide, normalisé (`MAPPAGE_IMPORT_FORMULAIRES.md` §4) |
| | | **exactement un** des deux destinataires est renseigné (`CHECK`) |
| `modele` | `text` | liste fermée de la section 3 (`CHECK`) |
| `langue` | `text` | `fr` ou `ar` : la langue d'interface choisie à l'inscription ; pour une ligne importée sans compte, `ar`, car seules les réponses du questionnaire arabe (A1 et A2) sont importées (`CONS` 7.3, `MAPPAGE_IMPORT_FORMULAIRES.md` §1) |
| `parametres` | `jsonb` | clés exactement celles du modèle (section 3), types vérifiés par un `CHECK` sur une fonction privée ; jamais un texte libre |
| `etat` | `text` | `a_envoyer`, `envoye`, `echec`, `annule` |
| `cree_le` | `timestamptz` | UTC |
| `pris_le` | `timestamptz` ou nul | posé quand l'envoi prend la ligne (bail, section 4) |
| `tentatives` | `integer` | `>= 0`, compté à chaque prise |
| `prochaine_tentative` | `timestamptz` | `cree_le` au départ, repoussée après un échec passager |
| `envoye_le` | `timestamptz` ou nul | écrit par l'envoi seul, avec `envoye` |
| `fournisseur_id` | `text` ou nul | identifiant du message chez le fournisseur, écrit avec `envoye` |
| `cause` | `text` ou nul | liste fermée (section 4), écrite avec `echec` ou `annule` ; jamais le texte brut du fournisseur, qui peut contenir l'adresse |

La file ne garde **aucun nom**, aucun téléphone, aucune réponse, aucun motif
interne, aucun constat ni compte rendu. Le seul courriel stocké est celui d'une
ligne sans compte ; pour un compte, l'adresse se lit au moment de l'envoi, pour
qu'un changement d'adresse suive le compte.

## 3. Les modèles

Liste fermée : `invitation`, plus les événements des notifications (`CONS` 7.2).
Le texte de chaque modèle s'écrit en `fr` et en `ar` avec les écrans du module,
selon `.claude/skills/mots-rewayah`, et passe devant le directeur avant la
première mise en ligne. Il vit chez l'envoi, jamais dans la file.

| Modèle | Transition (`CONS` 4.2) | Paramètres | Le bouton mène à |
| :--- | :--- | :--- | :--- |
| `invitation` | 3 | `code` (texte), `expire_le` (UTC) | l'inscription avec le code (`lib/core/router/app_router.dart:323-326`) |
| `complement_demande` | 7, 23 | aucun | `/attente` |
| `admis_salle_verification` | 10 | aucun | `/attente` |
| `piece_a_corriger` | 15 | aucun | `/attente/piece` |
| `entretien_planifie` | 11 | `debut` (UTC), `duree_min` (entier), `fuseau` (nom IANA, celui du candidat) | `/attente/entretien` |
| `entretien_reprogramme` | 12 puis 11 dans le même geste | mêmes paramètres | `/attente/entretien` |
| `entretien_annule` | 12 | aucun | `/attente` |
| `pause_posee` | 18 (pose) | aucun | `/attente` |
| `pause_levee` | 18 (levée) | aucun | `/attente` |
| `refus` | 16 | aucun | `/attente` |
| `retrait_enregistre` | 17 | aucun | `/attente` |
| `entree_salle_prets` | 14 | aucun | l'accueil de l'app |
| `paiement_possible` | 9 | aucun | `/attente` |
| `nouveau_message` | message de la direction dans le fil `candidature` (`CONS` 7.1) | aucun | `/attente/messages` |

Règles :
- **Pas de lien en paramètre.** Le chemin est fixé par le modèle ; l'envoi y
  ajoute l'origine de l'app qu'il tient de sa configuration. La base ne connaît
  aucun domaine.
- **Le code d'invitation** n'existe que dans `invitation`, et seule la fonction
  de prise le rend (`CONS` 3.3).
- **Le refus et le retrait** ne disent jamais le motif ; le texte du modèle suffit
  (`CONS` 4.2, `PORTS §5` point 4).
- **`nouveau_message`** ne porte jamais le texte du message. Une seule ligne
  `a_envoyer` à la fois par candidature : si une ligne `nouveau_message` attend
  déjà, aucune autre ne s'ajoute.
- **L'heure d'un entretien** s'écrit dans le fuseau du candidat, avec le nom de ce
  fuseau, et dans sa langue. L'envoi la formate ; la file garde l'UTC.
- **Le nom affiché** pour la formule d'appel n'est pas dans la file : la fonction
  de prise le lit au profil (ou à la réponse importée, pour une ligne sans compte)
  et le rend avec l'adresse.

## 4. Ce que l'envoi appelle

Trois fonctions `SECURITY DEFINER`, `SET search_path = ''`, propriétaire
`postgres`, `REVOKE EXECUTE` de `PUBLIC`, `anon`, `authenticated` et `agent_ro`,
**`GRANT EXECUTE` à `service_role` seul**. C'est l'écart assumé à la règle du
dépôt qui retire `service_role` des fonctions d'administration : ici l'appelant est
la fonction serveur de l'envoi, qui tient la clé de service. Même choix que la
file des invitations de conjoint (`M/0053_invitations_foyer.sql:69-71`), mais par
fonctions plutôt que par droits de table.

**`prendre_courriels_candidature(p_limite integer)`**
- `p_limite` entre 1 et 50, sinon refus.
- Prend les lignes `a_envoyer` dont `prochaine_tentative <= now()` et dont le bail
  est libre (`pris_le` nul ou plus vieux que 15 minutes), plus anciennes d'abord,
  avec `FOR UPDATE SKIP LOCKED` : deux envois simultanés ne prennent jamais la
  même ligne.
- Pose `pris_le = now()`, ajoute 1 à `tentatives`.
- Rend, par ligne : `id`, `modele`, `langue`, `parametres`, l'adresse et le nom
  affiché lus à cet instant.
- Un compte sans adresse confirmée ne part pas : la ligne passe `echec`, cause
  `adresse_absente`, et n'est pas rendue.

**`marquer_courriel_candidature_envoye(p_id uuid, p_fournisseur_id text)`**
- Seulement sur une ligne `a_envoyer` déjà prise : passe `envoye`, écrit
  `envoye_le = now()` et `fournisseur_id`.
- Rejouée avec le même `fournisseur_id` sur une ligne `envoye` : rend vrai sans
  rien écrire. Toute autre situation rend faux, sans écrire.

**`marquer_courriel_candidature_echec(p_id uuid, p_cause text, p_definitif boolean)`**
- `p_cause` dans la liste fermée : `adresse_refusee`, `adresse_absente`,
  `fournisseur_indisponible`, `modele_inconnu`, `autre`.
- Échec passager (`p_definitif` faux) et moins de 5 tentatives : la ligne reste
  `a_envoyer`, `pris_le` revient à nul, `prochaine_tentative` recule de
  `5 min × 2^(tentatives-1)`, plafonné à 6 h.
- Sinon : `echec`, avec la cause.

**Idempotence.** L'envoi passe `id` comme clé d'idempotence au fournisseur quand
celui-ci l'accepte : un envoi qui tombe entre l'acceptation du fournisseur et
`marquer_…_envoye` ne double pas le courriel au tour suivant.

## 5. Ce que l'envoi garantit en retour

- Un courriel par ligne, un seul destinataire : ni copie, ni copie cachée, ni
  liste.
- Aucune pièce jointe, aucun pixel de suivi, aucun accusé de lecture : l'app ne
  dit jamais « lu » (`CONS` 7.5).
- Pas d'adresse de réponse qui mène quelque part : le contact passe par l'app
  (`DEC:29`, `CAND-Q06`). Le courriel le dit.
- Un fournisseur et une adresse d'expédition choisis avec le feu vert du
  directeur, sur le domaine de l'académie, avec ses enregistrements d'envoi
  (SPF, DKIM). Le choix appartient à la session de l'envoi.

## 6. Annulation avant départ

Le module passe une ligne `a_envoyer` à `annule` (cause `remplace` ou
`invitation_retiree`) quand elle n'a plus de sens avant de partir :
- l'invitation est retirée ou expire avant l'envoi ;
- un entretien est annulé ou reprogrammé avant que `entretien_planifie` ne parte :
  la ligne précédente est annulée, la nouvelle part seule ; si la précédente est
  déjà partie, la nouvelle part aussi.

Une ligne prise (`pris_le` dans le bail) ne s'annule pas : elle peut être en
train de partir. Une ligne `envoye` ou `echec` ne change plus.

## 7. Ce que voient l'écran et la direction

| État | Écran de la direction (`ADM-21`) | Candidat |
| :--- | :--- | :--- |
| `a_envoyer` | « Courriel pas encore envoyé » | rien |
| `envoye` | « Courriel envoyé le … » | rien |
| `echec` | « Courriel non parti » | rien |
| `annule` | rien, sauf dans l'historique | rien |

Jamais « reçu », jamais « lu » (`CONS` 7.3). La lecture de la candidature rend,
par courriel : modèle, état, date de création, date d'envoi, cause. Jamais les
paramètres ni l'adresse.

## 8. Mise en service

- **Base de test.** La file se remplit dès L5 ; rien ne part tant que l'envoi
  n'existe pas.
- **Production.** Aucune invitation n'est émise tant que l'envoi n'existe pas
  (`CONS` 3.3), sauf canal nommé par le directeur pour l'intervalle.
- **Deux envois distincts** (`CONS` 7.3) : le courriel de confirmation et le lien
  de connexion passent par Supabase Auth (SMTP d'authentification,
  `enable_confirmations = true`, `supabase/config.toml:229` et `:239-247`) ; cette
  file passe par l'envoi de la section 4. Le premier conditionne la mise en ligne
  du lien d'inscription, le second l'état « Courriel envoyé le … ».
- **Conservation.** La durée de garde des lignes, et de l'adresse d'une ligne sans
  compte, suit `CAND-Q21` (avis du juriste). Aucune purge avant sa décision.
- **Précédent.** La file des invitations de conjoint
  (`public.email_outbox_invitation_foyer`, `M/0053_invitations_foyer.sql:55-71`)
  attend le même envoi : états `en_attente`, `envoye`, `echec`, `annule`. L'envoi
  peut lire les deux. Les unifier est un autre lot, hors de ce module.

## 9. Écarts proposés à `CONS` 7.3, à soumettre au directeur

1. Un quatrième état, `annule`, écrit par le module seul (section 6), comme dans
   la file des invitations de conjoint.
2. Aucun lien en paramètre : le modèle fixe le chemin (section 3). `CONS` 7.3
   citait « dates, liens ».
3. Le nom affiché et l'adresse d'un compte se lisent au moment de l'envoi, pas à
   l'écriture : la file ne garde aucun nom.
4. Une seule ligne `nouveau_message` en attente par candidature.

## 10. Recette du lot L5 (à ajouter à `CONS` 12)

| Cas | Attendu |
| :--- | :--- |
| un candidat, puis la direction, lisent la table et appellent les trois fonctions | permission refusée, 0 ligne |
| chaque geste de la section 3 | 1 ligne `a_envoyer`, bon modèle, bons paramètres ; aucun autre geste n'écrit de ligne |
| paramètres avec une clé de plus, ou un texte libre | refus, rien d'écrit |
| deux prises simultanées de 10 lignes sur 15 | ensembles disjoints, 15 lignes au plus |
| `envoye` rejoué avec le même identifiant | vrai, 0 écriture |
| 5 échecs passagers | `echec` à la cinquième prise ; délais croissants entre les prises |
| compte sans adresse confirmée | `echec`, cause `adresse_absente`, ligne non rendue |
| entretien reprogrammé avant le départ du premier courriel | 1 `annule`, 1 `a_envoyer` |
| trois messages de la direction de suite | 1 seule ligne `nouveau_message` en attente |
| lecture de la candidature par la direction | modèle, état, dates, cause ; 0 paramètre, 0 adresse |
| écran avant tout envoi | « Courriel pas encore envoyé », jamais « envoyé » |
