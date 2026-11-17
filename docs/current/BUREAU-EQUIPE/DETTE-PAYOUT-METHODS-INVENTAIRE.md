# DETTE-PAYOUT-METHODS-INVENTAIRE : qui lit `payout_methods` et `payouts`

Préparation de la décision qui fermera la dette du 08/11 (GARDE-VERSEMENTS) et du 17/11 (arbitrage de #594).
**Document seul : aucune migration, aucun changement de code, aucune ligne de production lue.**
Date : 17/11/2026. Auteur : BE-GESTES, à la demande du pilote.

## Ce qui est prouvé, et ce qui ne l'est pas

| Affirmation | Statut |
| :--- | :--- |
| Aucun écran, aucun adaptateur Flutter, aucune fonction Edge ne lit ni n'écrit ces deux tables | **présent dans le code** (recherche sur `lib/`, `supabase/functions/`, `tool/`, `site-public/`, jeu de migrations du dépôt à `f8fba8bf`) |
| Les politiques, droits, fonctions, déclencheurs, vues et clés étrangères ci-dessous existent en production | **vérifié en production**, par lecture du catalogue seule (`pg_policies`, `pg_class.relacl`, `pg_proc`, `pg_trigger`, `pg_constraint`, `pg_get_viewdef`) |
| Les deux tables sont vides | **non prouvé** : je n'ai lu aucune ligne (règle R14). Les statistiques du moteur disent 0 ligne vivante, 0 insertion, 0 mise à jour, 0 lecture séquentielle, 0 lecture par index depuis la dernière remise à zéro des compteurs. Ces compteurs peuvent être remis à zéro ; c'est un fort indice, pas une preuve. Le directeur ou le pilote peut la faire en une requête `count(*)` s'ils le décident |
| Fermer la lecture ne casserait rien en production aujourd'hui | **déduit** de la ligne 1 et de la ligne 3, **non testé** : aucune migration n'est écrite ici |

## 1. Les deux tables

- `public.payout_methods` : `id`, `profile_id` (clé étrangère vers `profiles`), `kind`, **`details jsonb`** (les coordonnées de versement : c'est la donnée sensible), `last_modified_at`, `deleted_at`, `created_at`. Créée dans `0001_fondations.sql`.
- `public.payouts` : `id`, `wallet_id` (vers `wallets`), `payout_method_id` (vers `payout_methods`), `amount_minor`, `status` (`requested`, `paid`, `failed`, `cancelled`), `created_at`. Créée dans `0001_fondations.sql`.
- RLS active sur les deux, non forcée (le propriétaire `postgres` la contourne).

## 2. État réel en production (catalogue, 17/11/2026)

**Droits** (`relacl`) : `postgres` et `service_role` tous droits ; `agent_ro` lecture ; `authenticated` **lecture seule** (GARDE-VERSEMENTS, `20261121600000`). `anon` : aucun.

**Politiques** (4) :

| Table | Politique | Commande | Rôles | Qui entre |
| :--- | :--- | :--- | :--- | :--- |
| `payout_methods` | `payout_methods_admin_accountant_all` | ALL | `agent_ro`, `authenticated` | `admin` ou `accountant` valide (`app_account_valid()`), sans second facteur |
| `payout_methods` | `payout_methods_family_read` | SELECT | `agent_ro`, `authenticated` | tuteur, ou élève autonome, valide, pour les profils de **son** foyer |
| `payouts` | `payouts_admin_accountant_all` | ALL | `agent_ro`, `authenticated` | `admin` ou `accountant` valide |
| `payouts` | `payouts_family_read` | SELECT | `agent_ro`, `authenticated` | tuteur ou élève autonome valide, pour les portefeuilles de **son** foyer |

Les politiques ALL de direction et de comptabilité restent écrites « FOR ALL », mais l'écriture est déjà sans effet : `authenticated` n'a plus que `SELECT`. Reste donc, côté direction et comptabilité, **la lecture**, et c'est elle que la dette veut fermer.

**Fonctions** qui nomment ces tables dans leur code (recherche sur `prosrc`, tous schémas applicatifs) :

| Fonction | Définer ? | Ce qu'elle fait | Touchée par une fermeture des politiques ? |
| :--- | :--- | :--- | :--- |
| `public.mes_donnees_export()` | oui, propriétaire `postgres` | lit `payout_methods` de l'appelant (`kind`, « coordonnées enregistrées oui/non », date) pour l'export de ses données | non : le propriétaire contourne la RLS |
| `public.reprendre_alimentation_tresorerie()` | oui | rejoue `UPDATE public.payouts SET status = status` pour relancer le déclencheur de trésorerie | non |
| `private.cpt_anonymiser(uuid)` | **non** (invoker, propriétaire `postgres`) | efface `details` et pose `deleted_at` sur les moyens du profil anonymisé | non en pratique : appelée par `public.traiter_demande_suppression`, `SECURITY DEFINER`, donc exécutée avec les droits du propriétaire. À re-prouver par le scénario `scenarios_cpt_suppression_export.sql` après toute fermeture |

**Déclencheur** : `payouts_tresorerie_alimentation` sur `payouts` (après insertion ou changement de `status`), fonction `public.x217_alimenter_payout`, `SECURITY DEFINER`. Il lit `NEW`, pas la table : aucune dépendance à la lecture.

**Vues** (`pg_get_viewdef` tous schémas applicatifs) : **0**. **Clés étrangères** : `payout_methods → profiles`, `payouts → wallets`, `payouts → payout_methods` (aucune ne dépend d'une politique de lecture).

**Fonctions Edge** : 0. Les mentions de « payout » dans `supabase/functions/_shared/` (courriel, push, textes, tests) sont des libellés, pas des lectures de ces tables.

## 3. Côté application (`lib/`)

Aucun appel `.from('payouts')`, `.from('payout_methods')` ni `rpc` de versement n'existe dans `lib/`, aucun adaptateur `*_supabase.dart` ne les nomme.

Les deux ports qui parlent de ces objets sont **indisponibles en production** :

- `portPayoutProvider` (`lib/core/capacites/port_payout.dart:296`) : par défaut `PayoutIndisponible`, et `lib/main.dart` ne le surcharge pas. Ses écrans (`comptable/paiements/confirmation/confirmation_payout.dart` 51 mentions, `paiements_page.dart`, `detail_paiement_page.dart`) sont derrière `payoutOuvertProvider`, faux en production.
- `portBeneficiairesPaiementProvider` (`lib/core/capacites/port_beneficiaires_paiement.dart:179`) : par défaut `BeneficiairesPaiementIndisponibles`, non surchargé dans `main.dart`. Ses écrans (`comptable/beneficiaires/*`, `admin_finance/reserve_delegation/exceptions_delegation.dart`) sont derrière `beneficiairesOuvertsProvider`, faux en production.
- Les démonstrations (`lib/features/demo/comptable/*`, 34 mentions dans `paiements_demo.dart` seule) vivent derrière `PLAYGROUND` et ne touchent aucune table.

Restent des mentions de texte, d'icône, de statut ou de route (`strings_*.g.dart`, `app_icons.dart`, `statuts_comptable.dart`, `pastilles_comptable.dart`, `routes.dart`) : sans accès aux tables. `NETTOYAGE-INVENTAIRE.md` (ligne `portPayoutProvider`) a déjà noté : « Table `payouts`, aucune RPC de vérification ni de soumission. La paie réelle passe par `versement_export_wise`, `versement_paie_noter`, `versement_paie_annuler` ».

**La paie réelle n'utilise pas ces deux tables.** Elle passe par `public.versements_paie` (migration `20261110710000`) et par `versement_coordonnees_direction` (migration `20261110700000`), toutes deux sans droit direct et lues par fonctions `SECURITY DEFINER`. `payouts` et `payout_methods` sont le modèle du premier schéma (`0001`), jamais branché sur un écran.

## 4. Lecteurs futurs déjà écrits dans les contrats (non codés)

| Contrat | Ce qu'il lirait | Conséquence si la lecture directe est fermée |
| :--- | :--- | :--- |
| `CONTRAT-CPT-BR-18-19.md` : `exporter_selection_comptable(p_ids uuid[], p_cle text)` | lignes de `payouts` désignés, `kind` seulement de `payout_methods` (jamais `details`) | la fonction n'existe pas encore dans les migrations ; le contrat la dit appelée depuis une fonction `SECURITY DEFINER` : si elle est écrite ainsi, aucun effet |
| `PortPayout` (préparer, valider, payer un lot) | `payouts` en lecture et en écriture | l'adaptateur n'est pas écrit ; il devra passer par des RPC définer, comme `versements_paie` (la lecture directe ne suffit déjà plus, l'écriture directe est fermée depuis le 08/11) |
| `PortBeneficiairesPaiement` (profil de paiement d'un bénéficiaire) | `payout_methods` | idem. Le contrat du port prévoit une vue du profil sans `details` en clair (à confirmer à l'écriture de l'adaptateur) |

## 5. Ce qui se casserait si la lecture direction et comptabilité était fermée (`USING (false)`)

**En production : rien de visible.** Aucune lecture applicative, aucune vue, aucune fonction invoker ne passe par ces politiques. Les fonctions définer continuent.

**Dans les scénarios de test, 6 assertions** :

| Scénario | Lignes | Pourquoi elle casse |
| :--- | :--- | :--- |
| `scenarios_garde_versements.sql` | 94 (« 2 : admin : la lecture des moyens de versement reste ») | l'admin lit `payout_methods` par le client et attend 1 ligne |
| `scenarios_dette_comptable_ecritures.sql` | 87, 88 (comptable : `payouts`, `payout_methods`), 92, 93 (direction : idem) | « lectures conservées pour la direction et la comptabilité » : 1 ligne attendue, 0 reçue |

Pour mémoire, ne cassent pas : `scenarios_garde_versements.sql` lignes 103 et 116-118 (tuteur lit son foyer ; droits), `scenarios_dette_comptable_ecritures.sql` lignes 99, 100, 103 (tuteur et autre foyer), `scenarios_af_l1_02_foyer_role.sql` et `scenarios_af_l1_v_contournements.sql` (l'enfant lit 0 : plus vrai encore), `scenarios_cpt_suppression_export.sql`, `scenarios_codex2_tresorerie.sql`, `scenarios_snt_seance_non_tenue.sql` (lecture faite sans passer par `authenticated` : à relire pour la ligne 45, qui compte `payouts`, avant la migration). La liste est issue d'une lecture, pas d'une exécution : la preuve réelle viendra de la CI de la PR de fermeture.

**Effet de bord à connaître** : les deux politiques ALL listent aussi le rôle `agent_ro`. Les fermer à `false` enlève à `agent_ro` la lecture des lignes de ces deux tables (le droit `SELECT` reste, la RLS les masque). C'est cohérent avec l'esprit de la dette (R14) ; à confirmer par le pilote, car GARDE-VERSEMENTS exige à l'installation que `agent_ro` garde `SELECT` : le privilège reste, seul le contenu est masqué.

## 6. Proposition chiffrée

Trois options, par ordre de portée. **Recommandation : option B.**

| Option | Contenu | Migration | Tests à adapter | Effet en production |
| :--- | :--- | :--- | :--- | :--- |
| **A. Ne rien changer** | la dette reste ouverte ; la lecture reste bornée à direction et comptabilité valides | 0 | 0 | aucun ; `details` (coordonnées) reste lisible par tout comptable valide sans second facteur, par l'API |
| **B. Fermer `payout_methods` seulement** (recommandée) | `ALTER POLICY payout_methods_admin_accountant_all` à `USING (false) WITH CHECK (false)` ; `payouts` reste lisible (montants et statuts, sans coordonnées) | 1 fichier, **1** `ALTER POLICY`, 0 mot d'effacement, sans `BEGIN`/`COMMIT`, avec préflight sur le texte de la politique actuelle | **3** assertions (`garde_versements` 94 ; `dette_comptable_ecritures` 88 et 93), plus le commentaire d'en-tête de `dette_comptable_ecritures` | aucun visible (0 lecture applicative, tables vides selon les statistiques) |
| **C. Fermer les deux** | `ALTER POLICY` sur `payout_methods_admin_accountant_all` **et** `payouts_admin_accountant_all` | 1 fichier, **2** `ALTER POLICY`, mêmes garde-fous | **6** assertions (les 6 du §5) | aucun visible ; ferme aussi la lecture directe des montants de versement |

Pourquoi B : la donnée sensible est `payout_methods.details` (IBAN, numéro de mobile money), pas `payouts` (montants et statuts ; les montants de la paie réelle sont aussi dans `versements_paie` et `tresorerie_mouvements`). B ferme exactement le risque nommé le 08/11 sans toucher à ce que la trésorerie utilise. C est plus propre en principe, mais ferme aussi une lecture dont personne n'a besoin tant qu'aucun adaptateur n'existe ; elle se décidera avec l'adaptateur de `PortPayout`.

Dans les trois cas, la **lecture par la famille** (`*_family_read`) n'est pas touchée : un tuteur ou un élève autonome voit ses propres lignes, et aucun écran ne s'en sert.

Variante écartée : retirer `SELECT (details)` par colonne. Elle cacherait aussi `details` au tuteur sur ses propres coordonnées, ce que la décision du directeur n'a pas demandé, et ne règle rien de plus que B.

## 7. Décisions attendues du directeur (si la dette se ferme)

1. A, B ou C ? (recommandation : B)
2. `agent_ro` perd-il la lecture des lignes de ces tables ? (recommandation : oui, R14)
3. Quand l'adaptateur de `PortPayout` et celui de `PortBeneficiairesPaiement` seront écrits, passent-ils par RPC `SECURITY DEFINER` avec second facteur (`aal2`) pour tout ce qui montre `details` ? (recommandation : oui, comme `versement_coordonnees_direction`)

## 8. Ce que ce document n'a pas fait

- Aucune ligne de `payouts` ni de `payout_methods` lue (R14). Les statistiques ci-dessus sont des compteurs du moteur.
- Aucune migration écrite ni installée, aucune politique modifiée.
- Aucun scénario exécuté : la liste des assertions qui casseraient vient de la lecture des fichiers.
- La liste des fonctions vient de `prosrc` ; une fonction qui construirait le nom de table dans une chaîne dynamique n'apparaîtrait pas. Aucune n'a été trouvée dans le dépôt (recherche de `payout` insensible à la casse dans `supabase/migrations`).
