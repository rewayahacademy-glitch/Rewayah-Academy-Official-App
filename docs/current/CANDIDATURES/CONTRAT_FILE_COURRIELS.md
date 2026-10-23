# Contrat de la file des courriels du recrutement (`CAND-Q10`)

**Pour qui.** La session qui construit l'envoi des courriels, après le site public
(`DEC:33` : « l'autre session va construire l'envoi d'e-mails après sa session sur
le site public »). Ce document lui dit ce que le module des candidatures écrit,
ce qu'elle lit, ce qu'elle écrit en retour, et ce que personne n'écrit jamais.

**Statut :** `spécifié`, **proposition**. Rien de ce qui suit n'existe en base,
sauf `candidatures.langue` (prérequis L3, posé le 23/10 par CAND-L3 ; section 9) :
la file s'écrit au lot L5 (`SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md`, désormais
`CONS`, section 11). Les noms de table, de fonctions et de modèles sont proposés ;
L5 peut les changer, pas les règles. Une règle de `CONS` 7.3 qui diffère d'ici
s'applique, sauf les écarts de la section 10, soumis au directeur. Relu le
21/10/2026 par une relecture critique : 19 défauts relevés, tous corrigés ici.

## 1. Qui fait quoi

| Acteur | Fait | Ne fait jamais |
| :--- | :--- | :--- |
| Module des candidatures | écrit une ligne `a_envoyer` à chaque événement de la liste fermée (section 3), dans la transaction du geste ; passe une ligne pas encore prise à `annule` quand elle n'a plus de sens (section 6) | envoyer ; écrire `envoye` ou `echec` |
| Envoi (construit par la session du site public, exécuté dans le projet Supabase, section 4) | prend des lignes, compose le courriel depuis son modèle, l'envoie, écrit `envoye` ou `echec` | lire une autre table du module ; écrire un texte dans la file ; changer un destinataire, un modèle ou un paramètre |
| Direction | lit l'état d'un courriel dans la candidature ; renvoie un courriel en `echec` (section 5) | changer un état ; lire les paramètres de la file |
| Candidat | rien | lire la file |

La colonne « Ne fait jamais » de l'envoi est une règle de l'envoi, pas une barrière
de la base : la clé de service qu'il tient lit aussi `profiles` et l'API
d'administration d'Auth (section 4).

## 2. La table

Nom proposé : `public.candidature_courriels`. RLS activée, aucune policy, aucun
privilège de table pour `PUBLIC`, `anon`, `authenticated`, `agent_ro` ni
`service_role` : tout passe par les fonctions de la section 4.

| Colonne | Type | Règle |
| :--- | :--- | :--- |
| `id` | `uuid` | clé ; sert aussi de clé d'idempotence chez le fournisseur |
| `candidature_id` | `uuid` | `public.candidatures(id)`, `ON DELETE RESTRICT` |
| `destinataire_profil` | `uuid` ou nul | le compte du candidat |
| `destinataire_courriel` | `text` ou nul | seulement pour une ligne sans compte (invitation) : `candidature_contacts.courriel`, valide et normalisé (`MAPPAGE_IMPORT_FORMULAIRES.md` §4), recopié à l'écriture parce que le code d'invitation y est lié |
| | | **exactement un** des deux destinataires est renseigné (`CHECK`) |
| `modele` | `text` | liste fermée de la section 3 (`CHECK`) |
| `langue` | `text` | `fr` ou `ar`. Pour un compte : recopiée de `candidatures.langue` (prérequis L3, section 9). Pour une ligne sans compte : `ar` si elle vient de l'import du questionnaire arabe (A1 et A2, `MAPPAGE_IMPORT_FORMULAIRES.md` §1) ; `fr` pour une ligne reprise d'une invitation existante (`CONS` 3.3) |
| `parametres` | `jsonb` | clés exactement celles du modèle (section 3), types vérifiés par un `CHECK` sur une fonction privée `IMMUTABLE` ; jamais un texte libre |
| `etat` | `text` | `a_envoyer`, `envoye`, `echec`, `annule` |
| `cree_le` | `timestamptz` | UTC |
| `bail` | `uuid` ou nul | tiré à chaque prise, rendu par la prise, exigé par les deux fonctions de marquage ; remis à nul avec `pris_le` |
| `pris_le` | `timestamptz` ou nul | posé avec `bail` quand l'envoi prend la ligne |
| `tentatives` | `integer` | `>= 0`, compté à chaque prise |
| `prochaine_tentative` | `timestamptz` | `cree_le` au départ, repoussée après un échec passager |
| `envoye_le` | `timestamptz` ou nul | écrit par l'envoi seul, avec `envoye` |
| `fournisseur_id` | `text` ou nul | identifiant du message chez le fournisseur, écrit avec `envoye` |
| `cause` | `text` ou nul | liste fermée (`CHECK`). Avec `echec` : `adresse_refusee`, `adresse_absente`, `fournisseur_indisponible`, `modele_inconnu`, `issue_inconnue`, `autre`. Avec `annule` : `remplace`, `invitation_retiree`, `candidature_close`, `inscrite`, `perimee`. Nulle sinon. Jamais le texte brut du fournisseur, qui peut contenir l'adresse |
| `renvoi_de` | `uuid` ou nul | la ligne `echec` que celle-ci renvoie (section 5) |

Index unique partiel `(candidature_id) WHERE modele = 'nouveau_message' AND etat =
'a_envoyer'` (section 3).

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
| `invitation` | 3 | `code` (texte), `expire_le` (UTC) | l'inscription avec le code (`lib/core/router/app_router.dart:322-326`) |
| `complement_demande` | 7, 23 | aucun | `/attente` |
| `admis_salle_verification` | 10 | aucun | `/attente` |
| `piece_a_corriger` | 15 | aucun | `/attente/piece` |
| `entretien_planifie` | 11, premier entretien de la candidature | `debut` (UTC), `duree_min` (entier), `fuseau` (nom IANA, celui du candidat) | `/attente/entretien` |
| `entretien_reprogramme` | 11, quand la candidature a déjà un entretien d'issue `annule`, `manque_candidat` ou `manque_intervieweur` ; ou 12 suivi de 11 en un seul geste (écart 5) | mêmes paramètres | `/attente/entretien` |
| `entretien_annule` | 12, issue `annule` seulement | aucun | `/attente` |
| `pause_posee` | 18 (pose) | `message` (clé du modèle de message choisi, liste fermée), `reprise_le` (date, facultative) | `/attente` |
| `pause_levee` | 18 (levée) | aucun | `/attente` |
| `refus` | 16 | `message` (clé du modèle de message choisi, liste fermée) | `/attente` |
| `retrait_enregistre` | 17 | aucun | `/attente` |
| `entree_salle_prets` | 14 | aucun | l'accueil de l'app |
| `paiement_possible` | 9 | aucun | `/attente` |
| `nouveau_message` | message de la direction dans le fil `candidature` (`CONS` 7.1) | aucun | `/attente/messages` |

Règles :
- **Pas de lien en paramètre.** Le chemin est fixé par le modèle ; l'envoi y
  ajoute l'origine de l'app qu'il tient de sa configuration. La base ne connaît
  aucun domaine.
- **`/attente/entretien` et `/attente/messages`** sont les chemins proposés pour
  `CAND-02` et `CAND-05` (`docs/current/CATALOGUE_ECRANS_RECRUTEMENT.md`). Ils
  n'existent pas encore (`lib/core/router/routes.dart:70-87`). Aucun modèle qui y
  mène n'est écrit avant que la route existe.
- **Le code d'invitation** n'existe, dans la file, que dans `invitation`, et seule
  la fonction de prise le rend (`CONS` 3.3). Il reste aussi dans
  `public.invitations_enseignant.code`, et la direction le lit aujourd'hui : voir
  le prérequis de la section 9.
- **Le refus et le retrait** ne disent jamais le motif interne. Le courriel de
  refus reprend le modèle de message choisi par la direction : la clé est dans la
  file, le texte chez l'envoi. Même chose pour la pause, avec sa date de reprise
  quand elle existe, pour que le courriel et `/attente` disent la même chose
  (`CONS` 10, `/attente` : « en pause (modèle, reprise) ; refusée (modèle) »).
- **`nouveau_message`** ne porte jamais le texte du message. Une seule ligne
  `a_envoyer` à la fois par candidature, tenue par l'index unique partiel de la
  section 2 et un `INSERT … ON CONFLICT DO NOTHING` : deux messages envoyés au même
  instant n'en écrivent qu'une.
- **L'heure d'un entretien** s'écrit dans le fuseau du candidat, avec le nom de ce
  fuseau, et dans sa langue. L'envoi la formate ; la file garde l'UTC.
- **Le nom affiché** pour la formule d'appel n'est pas dans la file : la fonction
  de prise le lit au profil, ou dans `candidatures.nom_complet` pour une ligne sans
  compte, et le rend avec l'adresse.
- **Sans courriel** : l'entretien manqué (transition 12, issues `manque_*`), la
  réouverture (19) et l'infirmation d'un moyen de paiement (25 puis 8). `CONS` 7.2
  ne les liste pas ; écart 6.

## 4. Ce que l'envoi appelle

**Où tourne l'envoi.** Dans une fonction Edge du projet Supabase
(`supabase/functions/`, ouverte une à une dans `config.toml`, comme les autres),
appelée par une tâche planifiée. La clé de service ne quitte pas le projet
Supabase : jamais dans le projet Vercel, ni dans le dépôt ou le code du site
public. Précédent : les fonctions Edge du dépôt tiennent déjà la clé
(`supabase/functions/_shared/clients.ts`).

Trois fonctions `SECURITY DEFINER`, `SET search_path = ''`, propriétaire
`postgres`, `REVOKE EXECUTE` de `PUBLIC`, `anon`, `authenticated` et `agent_ro`,
**`GRANT EXECUTE` à `service_role` seul**. C'est l'écart assumé à la règle du
dépôt qui retire `service_role` des fonctions d'administration : ici l'appelant est
la fonction Edge de l'envoi. Même choix que la file des invitations de conjoint
(`M/0053_invitations_foyer.sql:69-71`), mais par fonctions plutôt que par droits de
table.

**`prendre_courriels_candidature(p_limite integer)`**
- `p_limite` entre 1 et 50, sinon refus.
- Candidates : lignes `a_envoyer` dont `prochaine_tentative <= now()` et dont le
  bail est libre (`pris_le` nul ou plus vieux que 15 minutes), plus anciennes
  d'abord (`cree_le`, puis `id`), avec `FOR UPDATE SKIP LOCKED` : deux envois
  simultanés ne prennent jamais la même ligne.
- **Ordre par candidature.** Une ligne n'est prise que si aucune ligne `a_envoyer`
  plus ancienne de la même candidature n'attend encore : les courriels d'une
  candidature partent dans l'ordre des gestes (une « pause levée » ne part jamais
  avant la « pause posée »).
- **Péremption.** Ne sont pas rendues, et passent `annule` (cause `perimee`) : un
  `entretien_planifie` ou `entretien_reprogramme` dont `debut` est passé ; une
  `invitation` dont `expire_le` est passé ; toute autre ligne créée il y a plus de
  7 jours.
- Pose `bail` (nouveau `uuid`) et `pris_le = now()`, ajoute 1 à `tentatives`.
- Rend, par ligne : `id`, `bail`, `modele`, `langue`, `parametres`, l'adresse et le
  nom affiché lus à cet instant.
- Un compte sans adresse confirmée ne part pas : la ligne passe `echec`, cause
  `adresse_absente`, et n'est pas rendue.

**`marquer_courriel_candidature_envoye(p_id uuid, p_bail uuid, p_fournisseur_id text)`**
- Seulement sur une ligne `a_envoyer` dont `bail = p_bail` : passe `envoye`, écrit
  `envoye_le = now()` et `fournisseur_id`, remet `bail` et `pris_le` à nul.
- Rejouée avec le même `fournisseur_id` sur une ligne `envoye` : rend vrai sans
  rien écrire. Toute autre situation rend faux, sans écrire.

**`marquer_courriel_candidature_echec(p_id uuid, p_bail uuid, p_cause text, p_definitif boolean)`**
- Seulement sur une ligne `a_envoyer` dont `bail = p_bail` ; toute autre situation
  rend faux, sans rien écrire.
- `p_cause` dans la liste des causes d'échec (section 2).
- Échec passager (`p_definitif` faux) et moins de 10 tentatives : la ligne reste
  `a_envoyer`, `bail` et `pris_le` reviennent à nul, `prochaine_tentative` recule
  de `5 min × 2^(tentatives-1)`, plafonné à 6 h (environ 22 h en tout).
- Sinon : `echec`, avec la cause.

**Idempotence.** Le fournisseur retenu accepte une clé d'idempotence valable au
moins 24 h : c'est une condition de son choix (section 7). L'envoi lui passe `id`.
Un envoi dont l'issue est inconnue (délai dépassé sans réponse du fournisseur)
marque `echec`, cause `issue_inconnue`, définitif : mieux vaut un courriel à
renvoyer à la main qu'un courriel en double.

## 5. Renvoyer un courriel

Pour une ligne `echec`, la direction (`candidatures.decider`, de son côté, geste
journalisé) écrit une nouvelle ligne `a_envoyer` du même modèle, avec les mêmes
paramètres et `renvoi_de` qui pointe la ligne en échec. Pour `invitation`,
seulement si le code n'est ni utilisé, ni révoqué, ni expiré. La ligne `echec` ne
change pas. Geste neuf : écart 7.

## 6. Annulation avant départ

Le module passe une ligne `a_envoyer` dont le bail est libre à `annule` quand elle
n'a plus de sens avant de partir :
- l'invitation est retirée ou expire (cause `invitation_retiree`) ;
- la personne s'inscrit (transition 5) avant le départ de `invitation` (cause
  `inscrite`) ;
- un entretien est annulé ou reprogrammé avant que son `entretien_planifie` ou
  `entretien_reprogramme` ne parte : la ligne précédente passe `annule` (cause
  `remplace`), la nouvelle part seule ; si la précédente est déjà partie, la
  nouvelle part aussi. Dans le geste enchaîné (écart 5), aucune ligne
  `entretien_annule` n'est écrite ;
- un `entretien_reprogramme` est écrit alors qu'un `entretien_annule` de la même
  candidature attend : `entretien_annule` passe `annule` (cause `remplace`) ;
- la pause est levée avant le départ de `pause_posee` : les deux lignes passent
  `annule` (cause `remplace`) ;
- la candidature est refusée ou retirée (transitions 16 et 17) : toute autre ligne
  `a_envoyer` de la candidature passe `annule` (cause `candidature_close`), sauf la
  ligne `refus` ou `retrait_enregistre` écrite par le même geste ; l'entretien
  annulé par ce geste n'écrit pas d'`entretien_annule`.

Une ligne prise (bail en cours) ne s'annule pas : elle peut être en train de
partir. Une ligne `envoye`, `echec` ou `annule` ne change plus.

## 7. Ce que l'envoi garantit en retour

- Un courriel par ligne, un seul destinataire : ni copie, ni copie cachée, ni
  liste.
- Aucune pièce jointe, aucun pixel de suivi, aucun accusé de lecture : l'app ne
  dit jamais « lu » (`CONS` 7.5).
- **Une adresse de réponse qui mène à la direction, lue par elle.** Une personne
  sans compte (courriel `invitation`) n'a pas d'autre voie pour demander
  l'effacement (`DEC:44`) ou refuser la suite, et une demande de retrait peut
  arriver par courriel (`CONS` 4.2, transition 17). Les courriels aux comptes
  renvoient d'abord au fil de la candidature dans l'app (`DEC:29`).
- Un fournisseur qui accepte une clé d'idempotence (section 4), et une adresse
  d'expédition sur le domaine de l'académie, avec ses enregistrements d'envoi (SPF,
  DKIM). Le choix appartient à la session de l'envoi, avec le feu vert du
  directeur.

## 8. Ce que voient l'écran et la direction

| État | Écran de la direction (`ADM-21`) | Candidat |
| :--- | :--- | :--- |
| `a_envoyer` | « Courriel pas encore envoyé » | rien |
| `envoye` | « Courriel envoyé le … » | rien |
| `echec` | « Courriel non parti », la cause en mots simples et le geste pour le renvoyer (section 5 ; texte selon `mots-rewayah`, `lib/CLAUDE.md` K-59) | rien |
| `annule` | rien, sauf dans l'historique | rien |

Jamais « reçu », jamais « lu » (`CONS` 7.3). La lecture de la candidature rend,
par courriel : modèle, état, date de création, date d'envoi, cause. Jamais les
paramètres ni l'adresse.

## 9. Mise en service et prérequis

- **Prérequis L3 : la langue.** Aucune table ne garde aujourd'hui la langue d'un
  compte : l'app prend celle de l'appareil à chaque démarrage
  (`lib/core/i18n/langue_demarrage.dart:78-88`, `profiles` sans colonne de langue,
  `M/0001_fondations.sql:71-84`). L3 ajoute `candidatures.langue` (`fr` ou `ar`,
  non nulle pour une candidature avec compte), remplie par la RPC d'inscription
  avec la langue de l'app à ce moment. **Fait le 23/10 (CAND-L3, `testé localement`)** :
  `candidatures.langue` existe (`fr` ou `ar`, contrainte) et `inscrire_candidat` la remplit
  depuis son paramètre `p_langue`, jamais déduite (une langue absente ou inconnue refuse l'inscription,
  champ `langue` nommé). Elle reste **nulle** pour une candidature née avant ce lot, pour une ligne `recue`
  gardée pour suivi (une personne sans compte) et pour un compte né de l'ancienne
  `inscrire_enseignant_invite`, qui ne crée pas de candidature : la reprise de L3 (spec 3.3) les
  renseigne, et pour une ligne sans compte l'envoi suit la règle de la section 2 (`ar` pour l'import du
  questionnaire arabe). **La file elle-même n'existe toujours pas** : CAND-L3 n'écrit aucune ligne
  `a_envoyer`, `lister_a_prevenir_candidats` et `consigner_prevenu_candidat` ne servent que le lien
  d'inscription envoyé hors de l'app (WhatsApp, `CAND-Q06`).
- **Prérequis L3 : le code d'invitation.** `inviter_enseignant` et
  `invitations_enseignant_admin()` rendent aujourd'hui le code à la direction
  (`M/20261016100300_contrats_invitations_enseignant.sql:63-64`, `:76-91`, `:134`,
  `:164` ; écran `lib/features/admin_invitations/invitations_page.dart:126-129`).
  L3 le retire de ce qu'elles rendent, sauf canal nommé par le directeur pour
  l'intervalle (`CONS` 3.3). Tant que ce n'est pas fait, la direction lit le code.
- **Base de test.** La file se remplit dès L5. Branché sur la base de test,
  l'envoi n'écrit qu'aux adresses d'une liste blanche tenue dans sa configuration.
  Les lignes écrites avant son branchement passent `annule` (cause `perimee`) à son
  premier passage.
- **Production.** Aucune invitation n'est émise tant que l'envoi n'existe pas
  (`CONS` 3.3), sauf canal nommé par le directeur pour l'intervalle.
- **Deux envois distincts** (`CONS` 7.3) : le courriel de confirmation et le lien
  de connexion passent par Supabase Auth (SMTP d'authentification,
  `enable_confirmations = true`, `supabase/config.toml:229` et `:239-247`) ; cette
  file passe par l'envoi de la section 4. Le premier conditionne la mise en ligne
  du lien d'inscription, le second l'état « Courriel envoyé le … ».
- **Conservation.** La durée de garde des lignes, et de l'adresse d'une ligne sans
  compte, suit `CAND-Q21` (avis du juriste). Aucune purge avant sa décision.
- **Base des envois sans compte.** La base légale des courriels `invitation`
  envoyés aux personnes des formulaires avant leur inscription est soumise au
  juriste avec `CAND-Q21` (`CONS` 8.4). Rien n'est affirmé sur sa couverture avant
  l'avis.
- **Précédent.** La file des invitations de conjoint
  (`public.email_outbox_invitation_foyer`, `M/0053_invitations_foyer.sql:55-71`)
  attend le même envoi : états `en_attente`, `envoye`, `echec`, `annule`. L'envoi
  peut lire les deux. Les unifier est un autre lot, hors de ce module.

## 10. Écarts proposés à `CONS`, à soumettre au directeur

1. Un quatrième état, `annule`, écrit par le module seul (section 6), comme dans
   la file des invitations de conjoint.
2. Aucun lien en paramètre : le modèle fixe le chemin (section 3). `CONS` 7.3
   citait « dates, liens ».
3. Le nom affiché et l'adresse d'un compte se lisent au moment de l'envoi, pas à
   l'écriture : la file ne garde aucun nom.
4. Une seule ligne `nouveau_message` en attente par candidature.
5. « Reprogrammer » depuis un entretien planifié (état inaccessible, `CONS` 6.2)
   enchaîne les transitions 12 et 11 en un seul geste, que `CONS` 4.2 ne définit
   pas : issue et motif à fixer.
6. Trois événements ne préviennent pas le candidat, parce que `CONS` 7.2 ne les
   liste pas : l'entretien manqué, la réouverture après un refus ou un retrait, et
   l'infirmation d'un moyen de paiement. Proposé : modèles `entretien_manque`,
   `candidature_rouverte` et `paiement_non_disponible`, sans paramètre, vers
   `/attente`.
7. Un geste neuf de la direction, « Renvoyer le courriel » (section 5).

## 11. Recette du lot L5 (à ajouter à `CONS` 12)

| Cas | Attendu |
| :--- | :--- |
| un candidat, puis la direction, lisent la table et appellent les trois fonctions | permission refusée, 0 ligne |
| chaque geste de la section 3 | 1 ligne `a_envoyer`, bon modèle, bons paramètres ; aucun autre geste n'écrit de ligne |
| paramètres avec une clé de plus, ou un texte libre | refus, rien d'écrit |
| deux prises successives de 10 lignes sur 15, la seconde dans le bail de la première | 10 puis 5, 0 ligne en commun |
| deux prises simultanées (deux sessions `psql`, hors `scenarios_*.sql`, preuve écrite à part) | ensembles disjoints, 15 lignes au plus |
| `envoye` ou `echec` avec un bail périmé, puis repris par un autre envoi | faux, 0 écriture |
| `envoye` rejoué avec le même identifiant | vrai, 0 écriture |
| 10 échecs passagers | `echec` à la dixième prise ; délais croissants, plafonnés à 6 h |
| compte sans adresse confirmée | `echec`, cause `adresse_absente`, ligne non rendue |
| `pause_posee` en attente de nouvelle tentative, puis `pause_levee` | `pause_levee` n'est pas prise avant que `pause_posee` soit partie ou close |
| entretien reprogrammé avant le départ du premier courriel | 1 `annule`, 1 `a_envoyer` |
| refus d'une candidature dont `entretien_planifie` attend | 1 `annule`, 1 `refus` `a_envoyer`, 0 `entretien_annule` |
| `entretien_planifie` dont `debut` est passé, `invitation` expirée | non rendues, `annule`, cause `perimee` |
| trois messages de la direction de suite | 1 seule ligne `nouveau_message` en attente |
| renvoi d'une ligne `echec` | 1 nouvelle ligne `a_envoyer` avec `renvoi_de` ; la ligne `echec` inchangée ; 1 ligne de journal |
| lecture de la candidature par la direction | modèle, état, dates, cause ; 0 paramètre, 0 adresse |
| écran avant tout envoi | « Courriel pas encore envoyé », jamais « envoyé » |
