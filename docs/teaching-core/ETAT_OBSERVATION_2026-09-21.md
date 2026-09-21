# Observation du tuteur -- etat au 21/09/2026

Document d'etat de la branche `observation/lot-2026-09-21`. Il dit ce qui marche, ce qui attend, et
ce qui a ete mesure plutot que suppose.

> **Mise a jour du 21/09, second lot.** Les cinq migrations sont APPLIQUEES, la regle de visibilite
> est tenue par le serveur, l'annonce enseignant a la forme demandee, le temoin de l'enfant est
> branche dans les deux salles, et « Assister » ouvre la porte d'observation. Ce qui suit dit ce qui
> a ete mesure, pas ce qui a ete relu.

## La regle produit

Dictee par l'operateur le 21/09, mot pour mot :

> Le tuteur peut venir plusieurs fois selon les reglages de l'admin. Mais par defaut, il vient deux
> fois max, chaque visite 2 minutes max. Pourquoi ? Parce qu'il vient pour voir si son enfant est
> actif. Mais avec un groupe de 5 personnes il peut venir et trouver que ce n'est pas le tour de son
> enfant, donc il attend, et peut revenir apres, c'est pour augmenter les chances qu'il tombe sur le
> tour de son enfant en train de participer / lire / repondre.

L'administration peut changer ces valeurs **ou les annuler** (`SourcePolitique` : heriter de
l'Academie, personnaliser pour le groupe, desactiver).

Deux consequences que le code doit respecter, et qui ne se deduisent pas des chiffres seuls :

1. **Deux minutes PAR VISITE**, pas deux minutes partagees. D'ou un budget total de 240 s.
2. **Un ecran d'observation qui ne montre pas l'enfant ne rend pas le service.** Le parent ne vient pas
   verifier que le cours a lieu, il vient verifier que SON enfant participe.

## La regle de visibilite, tranchee par l'operateur

| Qui | Ce qu'il voit |
|---|---|
| L'enseignant | Un oeil + les prenoms des enfants observes, TRONQUES, et leur nombre |
| L'enfant observe | Un oeil + une mention discrete, sans action ni bouton |
| Les autres enfants du groupe | **Rien.** Ni dans la galerie video, ni en annonce |

**Precision de l'operateur sur la forme, cote enseignant.** L'oeil seul et la phrase nommant l'enfant
ne s'excluent pas : on combine les deux. A UN observateur, la phrase entiere -- « Tuteur de {prenom}
observe » -- avec son temps restant. A DEUX ou plus, les prenoms sont tronques, s'affichent quelques
secondes, puis **glissent derriere l'oeil** et cessent d'etre visibles ; il reste l'oeil et le nombre.
Le survol de la souris, la pression du doigt ou le focus clavier les font ressortir entierement ; leur
fin les renvoie derriere l'oeil.

Nommer l'enfant a l'enseignant est un choix, pas une fuite : il connait deja les cinq enfants de son
groupe, et savoir DE QUI le parent regarde est precisement ce qui lui sert. Le tuteur, lui, n'est
jamais nomme.

## Les cinq migrations, TOUTES APPLIQUEES

Appliquees en production le 21/09 dans cet ordre, apres autorisation de l'operateur. **Chaque bloc de
controle de sortie a ete REJOUE apres application et lu**, jamais suppose.

| Version en base | Fichier | Ce qu'elle fait |
|---|---|---|
| `20260921053639` | `0035_ressources_du_groupe_rejoue_visibilite.sql` | `ressources_du_groupe` rejoue la politique de visibilite de `library_resource` |
| `20260921053819` | `0036_observation_defauts_academie_et_plafond_visite_groupe.sql` | Defauts 2 visites / 120 s par visite / 240 s total / version `a2` ; 5e parametre a `definir_politique_observation_groupe` ; `budget_observation` borne la duree par visite |
| `20260921053926` | `0037_entrer_observation_rend_l_enfant_concerne.sql` | `entrer_observation` rend enfin `enfant_profile_id` |
| `20260921054047` | `0039_budget_observation_repond_sur_la_visite_en_cours.sql` | `budget_observation` repond sur la visite en cours ; `sortir_observation` reparee |
| `20260921054...` | `0040_tuteur_masque_et_annonce_reservee_a_son_enfant.sql` | `guardian_observer` rejoint les roles masques ; `annonce_observation_pour_moi` |

Defauts d'Academie, mesures avant et apres sur `app_config` :

| cle | avant | apres |
|---|---|---|
| `observation.max_visits_per_session` | 1 | **2** |
| `observation.max_seconds_per_visit` | null | **120** |
| `observation.max_total_seconds` | 120 | **240** |
| `observation.policy_version` | `"a1"` | `"a2"` |

`0034` et `0038` appartiennent au chantier R2 et **sont desormais sur `origin/main`** : l'ecart signale
dans la version precedente de ce document est clos, par l'agent R2. Elles restent appliquees en base
dans l'ordre inverse de leurs numeros (`0038` en `20260921043316`, `0034` en `20260921043922`) : sans
consequence tant que les deux chantiers restent independants, mais a savoir avant de reconstruire une
base depuis `supabase/migrations/`.

## Ce que 0040 fait, et ce qu'elle a coute

### A. Le tuteur sort de la galerie des autres enfants

Le defaut, lu dans le corps de la fonction en production : `v_invisible := (v_role in
('masked_controller', 'admin_masked'))`. `guardian_observer` absent, donc `hidden = false`, donc
LiveKit place le tuteur dans la galerie de chaque participant. La fonction **se contredisait
elle-meme** : son propre commentaire de capacites annonce, trois lignes plus haut, « guardian_observer :
rien ne se publie, MASQUE ».

`autoriser_jeton_video` est un point chaud traverse par six valeurs de role. **Une seule ligne a
change** ; le reste du corps est recopie caractere pour caractere depuis `pg_get_functiondef`. Les six
roles ont ete mesures avant et apres, la fonction REELLEMENT appelee sur une fixture montee puis
rejetee dans un bloc atomique (aucune ligne laissee en base) :

| role | ttl avant | ttl apres | hidden avant | hidden apres |
|---|---|---|---|---|
| `teacher` | 900 | 900 | false | false |
| `student` | 900 | 900 | false | false |
| **`guardian_observer`** | 120 | 120 | **false** | **true** |
| `masked_controller` | 900 | 900 | true | true |
| `admin_masked` | 900 | 900 | true | true |
| `admin_visible` | 900 | 900 | false | false |

Une seule case a bouge sur trente. Le `ttl = 120` du tuteur prouve au passage que `0036` et `0039`
tiennent : le serveur borne la visite a deux minutes, et non au TTL de 900.

**Droits.** L'ACL reelle a ete LUE avant d'ecrire (`proacl`) : `postgres` et `service_role`, rien
d'autre -- ni `PUBLIC`, ni `anon`, ni `authenticated`, ni `agent_ro`. Cette fonction n'est donc pas
appelable depuis le client ; elle passe par une fonction de bord sous `service_role`. Ecrire
`grant ... to authenticated` par habitude aurait ouvert l'emission de jetons video a tout compte
connecte.

### B. L'enfant observe l'apprend, et lui seul

Aucune lecture serveur ne le permettait : `annonces_observation` leve `insufficient_privilege` pour qui
n'est pas `sessions.teacher_id`, et la RLS de `guardian_session_visit` n'ouvre le SELECT qu'a
l'observateur ou a un admin. L'enfant est le SUJET de la ligne, jamais son observateur.

`annonce_observation_pour_moi(p_session_id)` porte **`v.enfant_profile_id = auth.uid()` dans son
WHERE**. Ce n'est pas un filtre d'affichage : c'est la seule ligne que la fonction puisse atteindre.
Elle rend deux faits, `observe` et `depuis`, et **aucun compteur** -- un « 1 observateur dans la salle »
renseignerait deja sur les autres foyers.

Une RPC plutot qu'une policy de plus : la RLS borne les LIGNES, pas les COLONNES. Ouvrir la table a
l'enfant lui donnerait l'identite de l'observateur, le numero de visite et le compteur de ses passages.

Mesure faite en base, deux enfants de foyers differents dans le meme groupe :

| appelant | reponse |
|---|---|
| l'enfant observe | `{"observe": true, "depuis": "..."}` |
| **l'autre enfant du groupe** | `{"observe": false, "depuis": null}` |
| le tuteur lui-meme | REFUS `42501` |
| `anon` (`auth.uid()` nul) | REFUS `42501` |
| l'enseignant, sur `annonces_observation` | intacte, avec `enfant_prenom` |

## Ce qui est livre cote application

| Lot | Etat |
|---|---|
| Salle video reelle sur l'ecran d'observation | Fait |
| Sortie de salle si la visite expire pendant la connexion | Fait |
| Annonce au professeur, **a la forme demandee** | Fait -- oeil + prenoms tronques qui glissent derriere l'oeil + nombre. Le repli est MESURE par les tests (facteur de largeur 1 -> 0 -> 1), jamais par `find.text` : replies, les prenoms restent dans l'arbre et un test ecrit dessus serait vert quoi qu'il arrive |
| Reglages d'observation par l'administration | Fait -- feuille ouverte depuis la ligne du groupe |
| **Bascule du bouton « Assister »** | **Fait** -- `/tc/observation/:seanceId`. L'inscription prealable par `assisterEnTuteur` est RETIREE : `entrer_observation` fait la meme inscription ET verifie le lien tuteur-enfant, la politique du groupe et le quota. Garder les deux, c'etait laisser la porte qui ne verifie rien decider si le parent entre |
| **Annonce a l'enfant** | **Fait** -- montee dans les DEUX salles cote eleve : `ClasseLivePage` (`/tc/classe`) et `SallePage` (`/salle`). N'en brancher qu'une laissait l'autre chemin muet |

**L'icone.** `AppIcons.observationEnCours` (oeil ouvert) a ete AJOUTEE ; l'indicateur detournait
`AppIcons.foyer`, un pictogramme de maison. Le point de code a ete **releve en sondant la police**, pas
devine : la police Phosphor embarquee n'a aucun nom de glyphe (table `post` en version 3.0), methode
documentee en `docs/HANDOFF.md` section 15.4. La grille rendue donne `0xe220` = oeil ouvert, et la
lecture est corroboree par ses deux voisins deja au catalogue et deja nommes -- `0xe222` = oeil ferme
(`observationFermee`), `0xe224` = oeil barre (`masquer`). Glyphe present dans les deux graisses.

**La contrainte `ELV-02`.** Verifiee avant d'ajouter quoi que ce soit : le groupe « deux blocs, rien
d'autre » compte `find.byType(BentoTile) == 2`, et RIEN d'autre. Une mention posee dans un bloc
existant ne la declenche pas. Le temoin n'a de toute facon pas ete pose a l'accueil : la visite du
tuteur a lieu PENDANT la seance, et l'enfant a quitte l'accueil des qu'il a rejoint.

## La divergence que l'application de 0036 a creee, et qui est fermee

`GuardianObservationPolicy.defautsNormatifs` affirmait encore 1 visite / 120 s -- les valeurs d'avant
`0036`. Ce constructeur existe pour « servir de reference ecrite a la specification » : une reference
qui contredit le serveur est pire qu'une reference absente, c'est elle que la session suivante aurait
recopiee. Realignee sur 2 visites / 120 s par visite / 240 s total.

Trois fichiers de test figeaient ces memes valeurs, dont
`test/teaching_core/q/q03_quota_observation_tuteur_test.dart`, qui encodait les ANCIENS defauts **comme
etant la specification** et restait vert parce qu'il lit une fixture et jamais la base. Son cas
principal s'appelait « une seule visite, et la seconde est refusee » : il affirmait exactement ce que
la regle produit interdit. Reecrit en « la SECONDE visite est accordee, la troisieme refusee ».

Un cas de `ecrans_observation_test.dart` figeait `maxVisitsPerSession == 2` apres une pression sur
« augmenter » depuis une Academie a 1 visite. Reecrit relativement (`academie.maxVisitsPerSession + 1`) :
fige en dur, il redevenait faux sans rien mesurer de plus.

## Ce qui a ete mesure, et comment

- **Les six roles de `autoriser_jeton_video`**, fonction reellement appelee, avant et apres `0040`.
- **Les quatre blocs de controle de sortie**, rejoues apres application et lus.
- **La vie privee de `annonce_observation_pour_moi`**, quatre appelants, dont l'enfant d'un autre foyer.
- **Le rayon d'explosion avant d'appliquer** : 0 groupe, 0 seance, 0 visite journalisee, 0 jeton video,
  8 profils. Aucune donnee a perdre.
- **`flutter test` sur tout le depot : 1740 tests, aucun rouge.**
- **`dart analyze` : aucun probleme. `dart run tool/verifier_jetons.dart` : 337 fichiers, aucune
  violation** -- les 10 violations pre-existantes que signalaient les rapports d'Agent G/E/D ont
  disparu entre-temps.

## Ce qui reste ouvert

1. **Etape 8 (E2E)** : rien n'a ete lance. La production Vercel a ete redeployee le 21/09 par l'agent
   qui a repare la chaine de deploiement ; l'avertissement « la prod sert un bundle du 19/09 » de la
   version precedente de ce document est donc perime, mais un E2E reste a faire.
2. **Le job `migrate-check` de `ci.yml`** echouait des `0030_tc_socle.sql:209` (`insert into
   storage.buckets` sans garde, alors que `0004:992` en a une). Defaut pre-existant, non corrige ici ;
   `ci.yml` a ete largement reecrit depuis par le lot deploiement, a re-mesurer.
3. **`ServiceVideo.assisterEnTuteur`** n'a plus aucun appelant dans `lib/` depuis la bascule
   d'« Assister ». La methode et la RPC `assister_seance` restent en place : les retirer touche
   l'interface, ses doubles et leurs tests, et n'etait pas demande. A arbitrer.
4. **`ar.i18n.json` porte un `tc.observation` VIDE** : tout le sous-arbre observation retombe deja en
   francais dans l'interface arabe, par `fallback_strategy: base_locale`. Pre-existant ; les cles
   ajoutees ici suivent le meme regime et ne creent pas de regression.
