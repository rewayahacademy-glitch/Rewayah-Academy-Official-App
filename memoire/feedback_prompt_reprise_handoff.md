---
name: feedback-prompt-reprise-handoff
description: "Toujours terminer une session ou un lot par un prompt de reprise prêt à copier-coller. Réaffirmé le 12/09/2026 : le but est l'ÉCONOMIE DE JETONS, donc le prompt doit nommer ce qu'il faut lire ET interdire de relire le code."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e168a07b-40e8-475d-9bff-e411ab2332b6
  modified: 2026-09-23T17:03:28.158Z
---

**Toujours finir une session, ou un lot livré, par un court prompt de reprise
prêt à copier-coller dans une nouvelle session.** Demandé explicitement par
l'opérateur le 6 septembre 2026, après le lot L7 de Rewayah Academy : le travail
était fini et le handoff écrit, mais il n'avait rien à coller pour repartir.

**Pourquoi.** L'opérateur ouvre les sessions suivantes lui-même, souvent
plusieurs jours après. Le fichier de handoff dit où reprendre, encore faut-il
que la session le lise **avant** de faire quoi que ce soit ; c'est précisément
ce qui a échoué le 6 septembre, quand une session s'est branchée sur PISI par
habitude. Le prompt de reprise est la première instruction lue, il est donc le
seul endroit sûr où pointer le bon dépôt et le bon fichier.

**Comment l'appliquer.** À la fin de la réponse, dans un bloc de code pour que
la copie soit propre. Trois lignes suffisent : le dépôt en absolu, l'ordre de
lecture (le handoff d'abord), et le lot à reprendre. Ni résumé du travail fait,
ni consigne de méthode : le handoff les porte déjà, et un prompt long ne se
copie pas. Exemple de la forme attendue :

```
Reprends Rewayah Academy, depot "D:\RA _APP\RA -OFFICIAL-APP", branche <branche>.
Lis docs/current/00_LIRE_D_ABORD.md EN PREMIER, puis docs/current/08_... section 5 bis.
Enchaine sur <le lot nomme par le directeur>. NE RELIS PAS TOUT LE CODE.
```

(Depuis la remise à plat du 23/09/2026, le « handoff » est `docs/current/08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md` ;
`docs/HANDOFF.md` et `docs/architecture/` sont archivés et ne doivent plus être nommés dans un prompt de reprise.)

**Réaffirmé et élargi le 12 septembre 2026**, en clôture du lot de remise au
vert : « fais ainsi à la fin de chaque session (toujours un prompt à la fin qui
aide l'agent suivant, pour ne pas qu'il se mette à relire tout le code) ».
L'opérateur ferme les sessions **pour économiser des jetons**, ce qui change la
cible du prompt : ce n'est plus seulement un pointeur vers le handoff, c'est un
**budget de lecture**. Trois ajouts devenus obligatoires :

1. **Nommer les fichiers à lire, et dire explicitement de ne pas lire le
   reste.** « NE RELIS PAS TOUT LE CODE. Lis exactement ceci : … » en tête.
2. **Porter les faits qu'un agent irait sinon chercher dans le code** : la
   mesure de référence (combien de tests verts), les recettes de poste qui ne
   se devinent pas, les pièges connus, les travaux parallèles d'autres outils.
3. **Mettre la dernière phrase de l'opérateur en premier**, avant tout plan
   écrit : c'est elle qui commande, pas la feuille de route du fichier.

Et mettre à jour la section « prompt de reprise » du handoff dans le même
mouvement : le bloc collé et le fichier doivent dire la même chose.

Voir [[rewayah-remise-au-vert-2026-09-11]] pour l'état courant, et
[[rewayah-etape4-dashboards-2026-09-06]] pour l'origine de la consigne.
