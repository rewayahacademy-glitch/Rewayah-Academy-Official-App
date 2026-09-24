---
name: feedback_une_liste_de_roles_masques_est_recopiee_partout
description: "Ajouter un role a une liste d'exemption ne ferme QUE la surface touchee : la meme liste est recopiee dans les vues, les policies et les fonctions. Les enumerer par requete AVANT de se declarer satisfait"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 51210283-842a-4a2d-a542-88fd7d656af2
  modified: 2026-09-21T08:58:41.485Z
---

**Le defaut.** Le 21/09, la regle produit disait : le tuteur qui observe un cours
est invisible des autres enfants. Le corps de `autoriser_jeton_video` portait
`v_role in ('masked_controller', 'admin_masked')` sans `guardian_observer`. Une
ligne ajoutee, six roles mesures avant/apres, une seule case changee sur trente,
migration livree. **Et la fuite restait entiere.**

La MEME liste a deux elements etait recopiee dans sept autres objets. La vue
`session_peers_v` -- proprietaire `postgres` (`rolbypassrls`), **sans**
`security_invoker`, donc hors RLS, et `authenticated` a le SELECT -- rendait a
chaque participant l'UUID et le PRENOM du tuteur par un simple
`GET /rest/v1/session_peers_v`. Le jeton disait « masque » pendant que PostgREST
rendait l'identite en clair. C'est PIRE que le defaut corrige : la galerie
montrait une presence, la vue donne un nom.

**La regle.** Avant de se declarer satisfait d'un masquage, ENUMERER les
surfaces. Une requete, pas une relecture :

```sql
-- vues
select c.relname, (c.reloptions::text like '%security_invoker%') as invoker,
       pg_get_userbyid(c.relowner), has_table_privilege('authenticated', c.oid, 'select')
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
 where n.nspname='public' and c.relkind='v'
   and pg_get_viewdef(c.oid, true) like '%<le_role_deja_masque>%';
-- policies
select c.relname, p.polname from pg_policy p join pg_class c on c.oid = p.polrelid
 where pg_get_expr(p.polqual, p.polrelid) like '%<le_role_deja_masque>%';
-- fonctions
select proname from pg_proc where prosrc like '%<le_role_deja_masque>%';
```

On cherche le role DEJA masque (`masked_controller`), pas celui qu'on ajoute :
c'est lui qui revele toutes les copies de la liste.

**Puis trier, et ecrire le tri.** Les surfaces n'exposent pas la meme
population : `presence_seance_v` a l'air identique mais son `WHERE` n'admet que
admin, controleur, enseignant de la seance, foyer et soi-meme -- aucun autre
enfant. La fermer n'aurait rien gagne et aurait coute un risque. **Ce qu'on
laisse ouvert se justifie par ecrit, dans la migration**, sinon la session
suivante refait la mesure ou, pire, ferme au hasard.

**Corriger au point unique quand il existe.** `est_observateur_masque(seance,
profil)` alimentait trois policies de `session_events` en
`NOT est_observateur_masque(...)`. Un seul `create or replace` les a fermees
toutes les trois. Trois listes recopiees dans trois policies finiraient par
diverger -- c'est exactement ce qui avait produit le defaut d'origine.

**Le corollaire cote portes.** La meme revue a trouve une SECONDE porte
d'inscription, `assister_seance`, qui inscrivait en `guardian_observer` sans
quota et sans journaliser de visite. Retirer son appelant Dart ne la fermait
pas : c'est le GRANT qui decide, pas l'absence d'appelant. Un `revoke`, pas un
`drop` -- un `drop` casse les doubles de test qui l'implementent encore.

**Comment tout cela a ete trouve.** Pas par relecture : par une revue
adversariale dont les agents avaient pour consigne de REFUTER, suivie d'une
phase ou chaque defaut allegue devait etre REPRODUIT pour compter. 16 allegues,
12 confirmes. Le plus grave etait invisible a qui relisait la migration, parce
qu'il n'etait pas DANS la migration -- il etait dans ce qu'elle ne touchait pas.

Voir [[feedback_security_definer_ne_rejoue_pas_la_policy]],
[[feedback_rls_borne_les_lignes_pas_les_colonnes_motif_litige]] et
[[feedback_mesurer_une_rpc_en_prod_sans_laisser_de_ligne]].
