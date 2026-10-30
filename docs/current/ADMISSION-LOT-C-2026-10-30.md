# Admission, lot C : la direction accepte, refuse, demande des précisions, écrit, rapport du 30/10/2026

Décision : `docs/current/DECISION-ADMISSION-2026-10-27.md`, §3, §4 et §7 (lot C). Fiche : `docs/current/FICHE-ADMISSION-LOT-C-2026-10-30.md` (questions Q1 à Q5, écarts au §4).
Branche `claude/admission-c`, partie de `claude/admiring-brown-r6ai72-admission-b` (`cd3979e45`), en supposant B fusionné tel quel (consigne du pilote du 30/10).

## Ce qui est bloqué, inconnu ou non prouvé (à lire d'abord)

1. **Rien n'est prouvé sur staging ni en production.** La migration `supabase/migrations/20261030140000_admission_lot_c.sql` et son scénario `supabase/tests/scenarios_admission_lot_c.sql` sont rejoués sur Postgres 16 local (la CI tourne en 17), **non appliqués**. La migration suppose celles du lot B appliquées avant elle. Elle ne contient aucun `DROP`, `DELETE` ni `TRUNCATE` (règle du pilote du 30/10) : elle peut passer par `apply_migration` sans seconde confirmation.
2. **Le scénario n'est pas dans `.github/workflows/ci.yml`** (zone du directeur) : une étape à ajouter, sur le modèle des autres : `run: psql -h postgres -U postgres -v ON_ERROR_STOP=1 -f supabase/tests/scenarios_admission_lot_c.sql`.
3. **Les profils des enfants sont créés par l'application, pas par l'acceptation** (écart à la fiche, §4) : un profil d'élève exige un utilisateur d'authentification, que seule la fonction Edge `creer-profil-enfant` sait créer. Le tuteur accepté ouvre l'Accueil ; l'application crée les profils qui manquent puis les lie à la demande. Tant que le tuteur n'a pas ouvert l'application, ses enfants n'ont pas de profil. Testé contre un faux serveur seulement ; l'appel réel de la fonction Edge (qui rend `profile_id`) n'est pas prouvé.
4. **Q1 à Q5 répondues par le pilote le 30/10** (fiche, §4) : Q1 et Q2 construites telles que proposées ; Q4 et Q5 au lot E. Un refus d'admission n'a qu'une porte de réouverture, `annuler_refus_admission` (sept jours) : `rouvrir_candidat`, le geste des enseignants, refuse les familles et les élèves adultes (`{"erreur": "geste_admission", "utiliser": "annuler_refus_admission"}`, scénario négatif dans `scenarios_admission_lot_c.sql`).
5. **La réponse de la famille aux précisions passe par l'e-mail** : la page d'attente lui dit de répondre à l'e-mail reçu, qui part de la catégorie `inscription` (expéditeur et réponse `inscriptions@`, déjà configurés). La valeur en production n'est pas relue ; qu'une réponse arrive dans une boîte lue n'est pas prouvé.
6. **Les e-mails partent par la file existante** (`courriel_enfiler`) ; les trois modèles (`admission_acceptee`, `admission_refusee`, `admission_precisions`) sont écrits en français et en arabe et testés par Deno ; leur envoi réel n'est pas prouvé. Les fonctions Edge d'envoi doivent être redéployées pour connaître ces modèles.
7. **La liste blanche des fonctions volatiles reste rouge**, pour deux fonctions qui ne sont pas de ce lot (`ajouter_creneau_classe_admin`, `seance_a_rejoindre`), comme sur B. Les six fonctions de ce lot y sont ajoutées.

## Ce que fait ce lot

### Direction : Personnes, onglet « Demandes » (`/admin/personnes/demandes`)

- Deux listes séparées, choisies en haut : « Familles », « Élèves adultes ». La plus ancienne d'abord, « N demandes à traiter », recherche (nom, adresse e-mail, référence), 50 par page.
- Chaque carte : nom, état, date de réception, référence, et chaque apprenant (« Yasmine, 9 ans · niveau »).
- Toucher une carte ouvre sa feuille. Une demande à traiter ou à compléter porte **un seul bouton plein**, « Accepter la demande de … », et trois liens : « Demander des précisions », « Écrire à … », « Refuser la demande ».
  - **Accepter** : la demande passe à `confirmee`, le compte devient actif, l'e-mail « Votre demande est acceptée » part. Rejoué avec la même clé : le même résultat, un seul e-mail.
  - **Refuser** : une phrase choisie pour la personne (quatre modèles), un motif écrit pour la direction, puis une confirmation ; l'e-mail « Nous ne pouvons pas donner suite » part avec la phrase choisie, jamais le motif.
  - **Annuler le refus** : pendant sept jours (vérifié par `annuler_refus_admission`) ; après, le geste n'est plus proposé et le serveur le refuse.
  - **Annuler l'acceptation** (lien, sur une demande acceptée depuis moins de sept jours) : motif, confirmation ; la demande revient « à traiter », le compte repasse en attente, les profils des enfants sont mis de côté (`disabled`, jamais effacés). Refusé si un enfant est déjà dans une classe. Pas d'e-mail.
  - **Demander des précisions** : la demande passe « à compléter », l'e-mail « Il nous manque une information » part avec le texte.
  - **Écrire** : un message libre par e-mail, sans changer la demande, tracé au journal d'accès.
- Après un geste, la feuille ne propose plus rien (sa version est périmée) et la liste se relit. Hors ligne, rien ne part. Chaque refus du serveur a sa phrase.

### Famille et élève adulte

- **Page d'attente** : elle dit la précision demandée et comment répondre, ou « Nous ne pouvons pas donner suite » après un refus. Sans lecture, elle garde « Votre demande est en cours ».
- **Après l'acceptation** : la garde existante mène à l'Accueil ; les profils des enfants s'y créent puis le foyer se relit.

### Serveur (`20261030140000_admission_lot_c.sql`)

- Aucune contrainte élargie, aucune règle existante modifiée. Quatre règles propres : `accepter_admission` (de `recue` ou « à compléter » à `confirmee`), `preciser_admission` (de `recue` à `prequalification` / `a_completer`), `rouvrir_admission`, `annuler_admission` (de `confirmee` à `recue`).
- Fonctions publiques : `lister_demandes_admission`, `accepter_admission`, `refuser_admission`, `annuler_refus_admission`, `annuler_admission`, `demander_precisions_admission`, `contacter_admission` (direction) ; `ma_demande_admission`, `mes_apprenants_demande` (recréée, avec identifiant, réponses, profil lié, nom de famille, profil probable), `lier_apprenant_profil` (titulaire).
- Scénarios existants bornés aux règles hors admission (gestes `*_admission` exclus : `scenarios_cand_l2a1_moteur_salle_examen.sql`, `scenarios_cand_l2a2_gestes_direction.sql`, `scenarios_cand_l3_inscription_import.sql`) : ils figent la table de CAND-L2A1 et la parcourent avec des fixtures d'enseignants.

## Ce que le directeur vérifie, après fusion et migration (en gestes simples)

1. Créer une famille de test (lot B) : sa page dit « Votre demande est en cours ».
2. Dans l'administration, Personnes, onglet « Demandes », « Familles » : la demande est en tête, « 1 demande à traiter ».
3. Ouvrir la demande, toucher « Accepter la demande de … ». La famille reçoit l'e-mail « Votre demande est acceptée » ; en rouvrant l'application, elle entre dans son espace, et l'Accueil montre son enfant.
4. Créer une seconde famille de test, l'ouvrir, « Refuser la demande », choisir une phrase, écrire un motif, confirmer : la direction voit « La demande de … est refusée ; l'e-mail est en route. », la famille reçoit « Nous ne pouvons pas donner suite » et sa page le dit.

## Vérifications locales

Chiffres lus dans les sorties complètes, au commit poussé : voir le message au pilote.
