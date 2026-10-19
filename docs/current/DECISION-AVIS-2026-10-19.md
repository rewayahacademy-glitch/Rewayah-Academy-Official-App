# Avis des familles et des élèves (directeur, 19/10/2026)

## Décision du directeur

- Les avis sont recueillis par un lien que la direction crée et publie. Le lien ouvre un
  formulaire simple, joli, aux couleurs de la marque, sans compte ni connexion.
- On demande : le pays de résidence, le nom, depuis quand la personne a rejoint
  l'académie, et ce que demande tout système d'avis sérieux (note, texte).
- Simple et transparent : la personne sait, avant d'envoyer, que son avis sera visible
  publiquement.
- Les avis publiés paraissent sur le site public.

## Choix d'application (Claude, délégué par le directeur)

1. **Modération avant publication.** Un avis déposé attend. La direction le publie ou le
   refuse. Elle ne modifie jamais le texte. Motifs de refus seulement : insulte, données
   personnelles d'un tiers (nom d'un enfant, d'un enseignant), publicité, hors sujet,
   doublon. Les avis négatifs respectueux sont publiés. Ces règles sont écrites sur le
   formulaire et sur la page du site.
2. **Champs du formulaire.**
   - Nom affiché (obligatoire, 2 à 60 caractères). Aide : « Votre prénom et l'initiale
     de votre nom suffisent. »
   - Vous êtes : parent ou tuteur d'un élève, ou élève adulte (obligatoire).
   - Pays de résidence (obligatoire, liste de pays, code ISO 3166-1 alpha-2).
   - Avec nous depuis : mois et année (obligatoire, pas dans le futur, pas avant 2015).
   - Note de 1 à 5 étoiles (obligatoire).
   - Titre (facultatif, 80 caractères au plus).
   - Votre avis (obligatoire, 20 à 1500 caractères).
   - Case obligatoire : « J'accepte que cet avis, mon nom affiché, mon pays et la date
     soient publiés sur le site de Rewayah Academy. »
   - Phrase visible : « Votre avis sera lu par la direction avant d'être publié. Pour le
     faire retirer plus tard, écrivez à support@rewayahacademy.com. »
   - Ne jamais demander le nom d'un enfant, un courriel ou un téléphone.
3. **Le lien.** Créé par la direction avec un libellé (par exemple « Familles octobre
   2026 »), une date de fin (90 jours par défaut, 365 au plus) et un nombre maximal
   d'avis (200 par défaut, 2000 au plus). Le jeton est aléatoire (24 octets), montré une
   seule fois à la direction, gardé en base sous forme d'empreinte sha256. La direction
   peut fermer un lien. Adresse du formulaire : `/avis/<jeton>` dans l'application.
4. **Site public.** Lu au moment du build seulement, comme les tarifs, par la RPC
   `avis_publics()`. Pas d'URL ni de clé dans le HTML. Page `/fr/avis` : moyenne, nombre
   d'avis, liste (nom affiché, pays, « avec nous depuis », note, titre, texte, date de
   publication), et l'explication de la collecte et de la modération. Pas de balisage
   d'étoiles pour les moteurs de recherche (Google ne l'accepte pas pour les avis qu'une
   entreprise publie sur elle-même). Un avis publié paraît au build suivant.
5. **Mots.** On écrit « avis », jamais « avis vérifié », « certifié » ou « garanti ».

## Contrat serveur (migration `20261019120000_avis_publics.sql`)

Tables (RLS active, aucune politique : accès par RPC seulement) :

- `public.avis_liens` : `id uuid`, `libelle text`, `jeton_empreinte bytea unique`,
  `cree_par uuid`, `cree_le timestamptz`, `expire_le timestamptz`, `avis_max int`,
  `avis_recus int default 0`, `ferme_le timestamptz null`.
- `public.avis` : `id uuid`, `lien_id uuid`, `nom_affiche text`, `qualite text`
  (`parent` | `eleve_adulte`), `pays char(2)`, `depuis date` (premier du mois),
  `note smallint 1..5`, `titre text null`, `texte text`, `accord_public_le timestamptz`,
  `statut text` (`en_attente` | `publie` | `refuse` | `retire`), `motif text null`,
  `depose_le timestamptz`, `modere_le timestamptz null`, `modere_par uuid null`,
  `publie_le timestamptz null`.

RPC (SECURITY DEFINER, `search_path = ''`, gardes positives, REVOKE de PUBLIC, anon,
service_role, agent_ro, puis GRANT ciblé) :

| RPC | Pour | Retour |
| --- | --- | --- |
| `avis_lien_creer(p_libelle text, p_jours int default 90, p_avis_max int default 200)` | direction | `jsonb {id, jeton, expire_le}` ; `jeton` en clair, une seule fois |
| `avis_liens_lister()` | direction | `jsonb` liste `{id, libelle, cree_le, expire_le, avis_max, avis_recus, ferme, actif}` |
| `avis_lien_fermer(p_id uuid)` | direction | `void` |
| `avis_lien_etat(p_jeton text)` | anon, authenticated | `jsonb {ouvert bool}` ; aucune autre information |
| `avis_deposer(p_jeton text, p_nom text, p_qualite text, p_pays text, p_depuis date, p_note int, p_titre text, p_texte text, p_accord boolean)` | anon, authenticated | `void` ; erreurs `22023` champ invalide (message = nom du champ), `P0002` lien fermé, expiré ou plein |
| `avis_lister_admin(p_statut text default null)` | direction | `jsonb` liste complète, plus `lien_libelle` |
| `avis_moderer(p_id uuid, p_statut text, p_motif text default null)` | direction | `void` ; `publie` ou `refuse` depuis `en_attente`, `retire` depuis `publie` ; motif obligatoire pour `refuse` et `retire` |
| `avis_publics()` | anon, authenticated | `jsonb {nombre, moyenne_dixiemes, avis:[{nom, qualite, pays, depuis, note, titre, texte, publie_le}]}`, avis publiés seulement, les plus récents d'abord, 200 au plus |

La direction est `public.app_role() = 'admin'` avec un compte valide, comme les autres
RPC de la direction.
