# Audit du journal de Praxis (`private.praxis_journal`) : ce qui est borné, ce qui ne l'est pas

Auteur : BE-GESTES, 17/11/2026. Demande du pilote : inventaire, schéma et code seulement, **sans coder**.
Méthode : le texte de chaque fonction `praxis_*` (base rejouée de 0001 à `20261129840000`, plus `20261129860000` de #597 en cours de fusion) et celui de la fonction Edge `supabase/functions/praxis-mcp`. Aucune ligne de journal lue (R14). Seule lecture de production : l'empreinte de `praxis_noter_refus` (schéma), pour #597. **Le texte des autres fonctions n'a pas été relu en production fonction par fonction** : il vient du dépôt, dont les migrations sont installées.

## 1. Ce qu'écrit chaque appel

Toute l'écriture passe par **une seule fonction** : `private.praxis_noter(cle, emise_par, outil, issue, fil, ids, texte, debut)`, qui fait un `INSERT` dans `private.praxis_journal`. Chaque outil l'appelle **une fois par appel, sur tous ses chemins, refus compris**, dès que la clé **existe** dans `private.praxis_cles` :

- clé de forme invalide ou inconnue (`cle_invalide`, `cle_inconnue`) : **aucune ligne** (le `cle_id` est nul, les outils n'écrivent pas) ;
- clé **révoquée, expirée**, émetteur invalide ou sans côté, interrupteur éteint, routine sans autonomie : **une ligne par appel** (l'issue est la cause interne), sauf `praxis_noter_refus`, qui exclut depuis #597 les quatre premières causes ;
- clé valide : une ligne par appel, `ok` ou la cause du refus.

À chaque porte franchie, `private.praxis_porte` fait aussi **un `UPDATE` de `praxis_cles.derniere_utilisation_le`** (une seconde écriture par appel valide).

Contenu d'une ligne : `cle_id`, `emise_par`, `outil` (≤ 40), `issue` (≤ 60), `fil_id`, `ids_touches` (tableau d'uuid), `duree_ms`, `cree_le`, et `texte_envoye` (≤ 3 000 signes) **seulement** pour `ecrire` et `annoncer` en `ok`. Trois index (clé primaire, `(outil, issue, cree_le DESC)`, `(fil_id, cree_le DESC)` partiel), plus l'index partiel de #597.

## 2. Outil par outil : lignes écrites et plafond existant

| Outil | Lignes par appel | Issues écrites | Plafond qui le borne déjà | Ce qui n'est pas borné |
|---|---|---|---|---|
| `praxis_etat` | 1 | `ok`, causes de refus | aucun | tout |
| `praxis_boite` | 1 | `ok`, `parametre`, causes | aucun (lecture : 200 fils, `p_limite` ≤ 50, bornent la **réponse**, pas le nombre d'appels) | tout |
| `praxis_fil` | 1 | `ok`, `parametre`, refus de fil (`fil_inconnu`, hors cotes, mineur…), causes | aucun | tout |
| `praxis_ecrire` | 1 | `ok`, `parametre`, `longueur`, `fil_inconnu`, `rejoue`, `plafond`, `plafond_fil`, refus de fil, causes | **les messages écrits** : `envois_par_heure` (réglage 1 à 120, **30 par défaut**), lu au journal (`outil = 'ecrire' AND issue = 'ok'`, 1 h) ; **3 messages de suite sans réponse par fil** (`plafond_fil`) | **les lignes de refus** : un appel au-delà du plafond écrit encore une ligne `plafond` ou `plafond_fil` ; idem `parametre`, `longueur`, `rejoue` |
| `praxis_annoncer` | 1 | `ok`, `parametre`, `longueur`, `essai`, `donnees_reelles_fermees`, `rejoue`, `plafond_annonces`, `public`, `mineur`, `refusee`, causes | **2 annonces par 24 h** (`ok`), lues au journal ; 3 000 signes ; clé d'idempotence | **les lignes de refus** (y compris `plafond_annonces`) |
| `praxis_calendrier_lire` | 1 | `ok`, `parametre`, causes | aucun (réponse ≤ 100 lignes) | tout |
| `praxis_calendrier_ajouter` | 1 | `ok`, `parametre`, `plafond`, causes | **500 entrées `prevu` au total** (stock, pas un débit) | les lignes de refus ; le stock plafonné se vide à mesure que les dates passent |
| `praxis_rendre_compte` | 1 | `ok`, `parametre`, causes | aucun (lit 50 lignes du journal) | tout |
| `praxis_lire` | 1 | `ok`, `essai`, `donnees_reelles_fermees`, `parametre` (quatre chemins), causes | aucun (les bornes de pagination bornent la réponse) | tout |
| `praxis_preparer` | 1 | `ok`, `essai`, `donnees_reelles_fermees`, `parametre`, `longueur`, `rejoue`, `candidature_inconnue`, `geste_non_servi`, `elements_invalides`, `plafond_propositions`, causes | **50 propositions `proposee` au total** (stock) ; clé d'idempotence | les lignes de refus |
| `praxis_noter_refus` | 1 si accepté | `parametre` | **60 par clé et par heure glissante** (#597) | rien d'autre ; **60 est écrit en dur** (voir §5) |

Les outils `direction_praxis_*` n'écrivent pas dans ce journal (ils écrivent dans `audit_logs` par `log_sensitive_access`, hors sujet ici).

## 3. Les couches au-dessus de la base

- **Fonction Edge `praxis-mcp`** (`supabase/functions/_shared/praxis/mcp.ts`) : une seule borne, **la taille du corps (16 Kio, réponse 413)**, lue en octets. **Aucune limite de débit** (recherche de `limit`, `rate`, `429`, `plafond`, `throttle` : aucune occurrence en dehors de ce commentaire : « toute la vérification se fait en base »).
- **Rétention** : aucune. Le journal est « à ajout seul » (déclencheur sur `UPDATE`, aucun droit de suppression pour les rôles de l'API, aucune migration du dépôt ne crée de tâche de purge ; **je n'ai pas relu les tâches `pg_cron` de la production**). Dans le dépôt, les lignes ne disparaissent jamais.

## 4. Ce qui n'est pas borné, en une phrase

**Une clé existante (même révoquée) peut écrire autant de lignes qu'elle fait d'appels**, par n'importe lequel des dix outils : les plafonds actuels bornent **ce que Praxis envoie** (messages, annonces, propositions, entrées de calendrier), jamais **combien de lignes le journal reçoit**. Pire, **le refus d'un plafond écrit lui-même une ligne** : atteindre `plafond` ne ralentit pas le journal, il continue de grossir à chaque appel. Un appel `etat` en boucle remplit le journal sans jamais rien envoyer.

Ordre de grandeur (**estimation, non mesurée en production** ; aucune ligne lue) : une ligne sans texte pèse de l'ordre de 150 octets, plus trois index, soit de l'ordre de 300 octets en tout. À 10 appels par seconde soutenus, cela fait de l'ordre de 36 000 lignes par heure, de l'ordre de 10 Mo par heure, de l'ordre de 250 Mo par jour, sans purge.

Conséquences au-delà de l'espace disque : (a) l'écran « ce que Praxis a envoyé » (`direction_praxis_journal`, pages de 100) est noyé par des lignes de lecture ; (b) `praxis_etat` et `praxis_rendre_compte` comptent le journal (`outil`, `issue`, `cree_le`) et ralentissent avec lui ; (c) les plafonds `ecrire` et `annoncer` **se lisent au journal** : tout système qui limiterait ou supprimerait les lignes `ok` de ces deux outils ferait sauter leurs plafonds (voir §6).

## 5. Dettes

- **`praxis_noter_refus` : 60 par heure écrit en dur** (accepté par le pilote, 17/11, avec #597). Le rendre réglable demande une colonne de `private.praxis_reglages` : non fait.
- Le compte de #597 inclut aussi les lignes `parametre` écrites par les autres outils (plus strict que prévu, accepté).

## 6. Proposition (aucun code) : un plafond global par clé

Principes :
1. **Au guichet, pas à l'écriture.** `private.praxis_porte` est l'entrée unique de tous les outils. Y mettre le plafond : au-delà de N lignes de journal pour la clé sur l'heure glissante, la porte rend une cause `plafond_journal` et l'outil répond `{erreur: 'plafond_journal'}`. **Ne pas** faire sauter l'`INSERT` dans `private.praxis_noter` : sauter des lignes `ok` de `ecrire` et `annoncer` fausserait leurs propres plafonds (§4 c).
2. **Une seule ligne témoin par clé et par heure** (issue `plafond_journal`), pour que la direction voie la clé qui s'emballe sans que le journal grossisse.
3. **Un index** `(cle_id, cree_le DESC)` pour le compte (ou la généralisation de l'index partiel de #597).
4. **Valeur de départ à décider** : mon ordre de grandeur est de l'ordre de 600 lignes par clé et par heure (10 par minute), très au-dessus de l'usage légitime d'un agent (quelques dizaines d'appels par session), très en dessous d'une boucle. **Réglable** dans `private.praxis_reglages` (comme `envois_par_heure`), pas en dur.
5. **Clés révoquées ou expirées** : décider s'il faut les journaliser du tout. Leurs tentatives sont une information de sécurité (« quelqu'un rejoue une ancienne clé ») : les garder, mais **sous le même plafond global**, avec la ligne témoin.
6. **Rétention** : question séparée, non traitée ici. Le journal est volontairement sans suppression ; une politique de conservation (archivage, partition par mois) demande une décision du pilote, car elle contredit « ajout seul » telle qu'écrite dans R11.

## 7. Questions pour le pilote

- **(a)** Le principe « au guichet » (`praxis_porte`) te convient-il, avec une ligne témoin par clé et par heure ?
- **(b)** Valeur de départ (je propose 600 par clé et par heure) et réglable en base ?
- **(c)** Les tentatives avec une clé révoquée ou expirée : les garder (sous le plafond), ou ne plus rien écrire ?
- **(d)** Rétention du journal : un lot à part, ou on attend de voir la croissance réelle ?
