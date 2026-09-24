---
name: feedback-verifier-document-officiel-avant-audit
description: "Avant de produire un audit/document de cartographie sur demande, chercher d'abord s'il en existe déjà un committé dans docs/ — sinon risque de dupliquer avec des conclusions divergentes et de perdre la confiance de l'utilisateur"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f2bdadcd-fa1f-4073-917a-632de6156d60
  modified: 2026-09-23T17:04:13.664Z
---

Quand une mission demande de produire un document de cartographie, d'audit ou
de décision d'architecture (« lis X avant toute modification », « fige
l'architecture »), **chercher d'abord dans `docs/` (grep large, pas seulement
la racine du dépôt) si un document de ce type existe déjà et s'il est
committé**, avant d'en écrire un nouveau à un autre emplacement.

**Pourquoi** : le 19/09/2026, une session Rewayah Academy a produit
`ADMIN_IA_AUDIT.md` à la racine du dépôt (non committé) sans découvrir que
`docs/architecture/ADMIN_IA_AUDIT.md` existait déjà, **committé sur `main`**
(commit `f2d1a93`, avant même la refonte connexion du même soir). Les deux
documents répondaient à la même mission (8 domaines admin) mais divergeaient
sur des points structurants : routes plates vs routes NESTED par domaine,
autorisation ou non de pages placeholder pour un domaine sans fonction,
ampleur de la refonte d'`ADM-01`. Une session suivante a construit un shell
en suivant le mauvais document (le sien, pas celui déjà accepté), l'a
découvert seulement après implémentation complète, et l'a présenté à
l'utilisateur comme un choix à trancher — provoquant une colère justifiée :
**« je t'ai donné des specs [...] c'est parce que tu rates toujours tes
missions [...] l'audit a été fait exprès pour ne pas que tu dévies »**.
L'utilisateur avait déjà tranché en committant ce document ; il n'y avait
rien à re-trancher, et reposer la question a été lu comme une nouvelle
déviation, pas comme de la prudence.

**Comment appliquer** : avant d'écrire un document de décision, `grep -r`
un mot-clé distinctif de la mission (ex. nom d'un domaine, code d'écran) sur
tout `docs/`, pas seulement le dossier où on s'apprête à écrire. Un document
déjà committé prime toujours sur une intuition ou une préférence de session,
même si la mission en cours ne le cite pas explicitement par son chemin
complet. Si un doublon divergent est découvert **après** avoir commencé à
coder dessus, ne pas demander à l'utilisateur de choisir entre les deux : le
document committé gagne par défaut, sauf indication contraire explicite.
Depuis le 23/09/2026, seul `docs/current/` fait foi : un document de `docs/archive/`
(dont l'ancien `docs/architecture/`) est une trace historique, jamais une règle.

Voir [[rewayah_admin_ia_audit_2026-09-19]] pour le détail de ce cas et l'état
final du lot IA-01 une fois réaligné sur le document officiel.
