# ENS-PAYS-1 : ce que le serveur doit exposer (BR-1)

Demande du directeur, 04/10/2026 : « Je veux que le pays de chaque enseignant apparaisse sur sa carte publiquement. La carte que le tuteur verra, les élèves, le contrôleur, l'administration, tout le monde. Si ça peut être avec le drapeau tant mieux. »

Le client est prêt (branche `corrections/ens-pays-1`) : chaque modèle lit la clé `teacher_country` dès qu'elle existe, et n'affiche rien tant qu'elle manque. Cette étape ne touche pas `supabase/` (K-19). Reste à faire en BR-1, dans une migration nouvelle.

## Donnée source

`teacher_profiles.country` (texte libre, `0001_fondations.sql`), écrit par `maj_profil_enseignant(p_country)` (`0027`). Depuis FORM-L8, c'est le nom français d'un des 19 pays de `paysProposes`, ou le texte de « Autre ». Le client en déduit le code ISO pour le drapeau ; aucun code n'est stocké.

## Colonnes à ajouter

Une seule colonne par projection, `teacher_country text`, avec **le même masquage que le prénom** : `case when public.agent_identite_masquee() then null else tp.country end`. Rien d'autre du profil enseignant n'est exposé (pas de langues, pas de fuseau, pas de nom de famille en plus).

| Projection (dernière définition lue) | Lue par (client) | Rôles | Ligne à ajouter |
| :--- | :--- | :--- | :--- |
| `public.mes_groupes_famille_v` (`0033_tc_vues_rpc.sql`, l. 140) | `groupeDepuisLigne` → `EnseignantVM.pays` (`lib/core/tc_groupe/groupes_supabase.dart`) | tuteur, élève, élève adulte, Mode Accessibilité | `case when public.agent_identite_masquee() then null else tp.country end as teacher_country` (jointure `tp` déjà présente ; ajouter `tp.country` au `group by`) |
| `public.mes_seances_v` (`0014_acces_agent.sql`, l. 888) | `Seance.enseignantPays` (`lib/core/planning/service_planning.dart`) | élève enfant (accueil), tuteur (historique, détail) | joindre `left join public.teacher_profiles tp on tp.profile_id = ens.id and tp.deleted_at is null`, puis `case when public.agent_identite_masquee() then null else tp.country end as teacher_country` |
| `public.groupes_admin()` (`0033_tc_vues_rpc.sql`, l. 694) | `GroupeAdmin.teacherPays` (`lib/core/admin/service_groupes.dart`) | administration (Groupes) | colonne de retour `teacher_country text`, même `case` ; changer la signature impose `drop function` puis `create` et de rejouer les `grant` |
| `public.comptes_admin()` (`0015_administration_voit_les_personnes.sql`, l. 126) | `CompteAdmin.paysEnseignant` (`lib/core/admin/service_comptes.dart`) | administration (Comptes) | colonne de retour `teacher_country text` : `tp.country` pour `role = 'teacher'`, `null` pour les autres rôles, même `case` de masquage |
| mission et rapports du contrôleur (contrat `14_controleur/CT-BR.md`, pas encore en base) | `MissionControle.paysEnseignant`, `RapportControle.paysEnseignant` | contrôleur | ajouter `teacher_country` au contrat de la mission et du rapport, même masquage |
| catalogue des classes ouvertes (« Choisir une classe » du tuteur) : **aucune source en base** (DB-CRS-07, `port_catalogue_classes.dart`) | `ClasseOuverte.enseignant` → `EnseignantSeance.pays` (`lib/core/seance_famille/seance_famille.dart`) | tuteur | la vue ou RPC du catalogue, quand elle sera creee, rend `teacher_country` avec le meme `case` que le prenom ; le client l'affiche deja (donnees de demonstration `catalogue_demo.dart`) |
| seances de la famille (`seanceFamilleDepuis`, `port_seances_famille.dart`) | `EnseignantSeance.pays`, repris de `Seance.enseignantPays` | tuteur, eleve | **rien de plus** : la meme colonne `teacher_country` de `mes_seances_v` (ligne ci-dessus) |
| seance en direct, `/salle` (salle unique depuis le 17/10/2026 ; l'ancienne classe `/tc/classe`, son `ContexteClasseLive` et `session_live_vm.dart` sont supprimes) | aucun champ pays : la salle n'affiche pas le pays de l'enseignant | eleve, tuteur, controleur | **rien a faire** : aucune lecture nouvelle dans la salle (le jeton LiveKit et `etat_presence()` ne portent pas le pays, et n'ont pas a le porter) ; si la salle doit un jour le montrer, la meme colonne `teacher_country` de `mes_groupes_famille_v` suffit |
| suivi de l'eleve (`/eleve/suivi`, colonne « Pays ») | `Seance.enseignantPays` | eleve | **rien de plus** : `mes_seances_v.teacher_country` |
| `public.enseignants_pour(uuid)` (`0016_masquage_coherent_en_observation.sql`, l. 305) | `EnseignantCandidat.pays` (déjà lu, `json['country']`) | administration (Attribution) | **déjà exposé**, mais **non masqué** : `tp.country` sort même quand `agent_identite_masquee()` cache le prénom. À aligner : `case when v_masque then null else tp.country end`. En attendant, le client ne l'affiche que si l'identité est connue |

## RLS et masquage

- Toutes ces projections sont déjà `security_barrier` ou `security definer` avec leurs filtres ; la colonne ajoutée n'élargit pas les lignes visibles, elle ajoute une donnée publique de l'enseignant à des lignes déjà permises.
- Sous masquage d'agent, un pays parmi quelques enseignants peut suffire à reconnaître la personne : il suit donc le prénom (nul).
- Tests SQL à ajouter (scénarios BR-1) : la famille d'un élève de la classe lit `teacher_country` ; une famille hors classe ne lit aucune ligne ; un agent masqué lit `null` ; `anon` ne lit rien.

## Ce que le client fait déjà

- Pays nul ou vide : aucune ligne, pas de « inconnu ».
- Nom du pays toujours écrit ; drapeau seulement si l'appareil le dessine (mesure), jamais deux lettres.
- Tableaux de l'administration et suivi de l'eleve : la colonne du pays n'apparaît que si une ligne au moins porte un pays (pas de colonne vide avant BR-1). Comptes et suivi : en-tête « Pays » (seuls des enseignants y ont un pays) ; Groupes : « Pays de l'enseignant ».
- Identite masquee (prenom vide) : aucun pays n'est ecrit, meme si la projection en rendait un.
