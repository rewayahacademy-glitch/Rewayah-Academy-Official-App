# Praxis : l'essai à blanc (étape 13 de `CHECKLIST-PRAXIS.md`)

Préparé par le pilote le 17/11/2026 à 8 h 20 UTC. **Rien n'est allumé.** En production au même moment : Praxis éteint
(`actif`, `autonome` et `donnees_reelles` faux), aucune clé émise, aucune proposition. Le connecteur `praxis-mcp` est
déployé (version 7, actif).

But : Praxis lit **un seul** fil de test et y répond, avec votre compte seulement. Personne d'autre ne peut être
touché : en mode essai, Praxis ne voit que les fils choisis et ne peut rien annoncer.

## Ce qu'il faut

- Votre compte de direction, avec la double vérification.
- Claude Code sur votre ordinateur. La connexion depuis claude.ai n'est pas prouvée : le connecteur attend la clé dans
  l'en-tête `Authorization: Bearer`, et claude.ai ne documente pas ce champ (`SECURITE-PRAXIS.md`, point ouvert).

## Les étapes, dans l'ordre

1. **Le fil de test.** Ouvrez une conversation de test avec le compte de Praxis, `#RA_PRAXIS`, dans la messagerie, et
   écrivez-y une phrase. Exemple : « Bonjour Praxis, ceci est un essai. »
2. **La clé.** Ouvrez Administration, puis Accès des agents IA, section Praxis. Émettez une clé de type « chat ».
   Elle commence par `prx_` et ne s'affiche qu'une fois : copiez-la.
3. **Le mode essai.** Dans la même section, choisissez ce seul fil comme fil d'essai.
4. **Allumer.** Activez l'interrupteur Praxis. Laissez « autonome » et « données réelles » fermés.
5. **Brancher Claude Code.** Dans un terminal, en remplaçant `prx_...` par la clé copiée :

   ```
   claude mcp add --transport http praxis https://gggmtelinlpseweouyav.supabase.co/functions/v1/praxis-mcp --header "Authorization: Bearer prx_..."
   ```

6. **L'essai.** Dans Claude Code, demandez : « Avec l'outil praxis, lis l'état, puis la boîte, puis réponds au fil de
   test par une phrase courte. »
7. **Vérifier.** Dans la messagerie, la réponse de Praxis apparaît dans le fil de test, et nulle part ailleurs.
8. **Éteindre.** Coupez l'interrupteur Praxis. Si vous ne gardez pas la clé, révoquez-la dans la même section.

## Si ça ne marche pas

Notez le message exact affiché par Claude Code ou par l'application, et donnez-le au pilote. Ne collez jamais la clé
dans une conversation : une clé montrée se révoque et se remplace.

## Après l'essai réussi

- Étape 12 : la phrase sur l'assistant dans la politique de confidentialité, à valider par vous.
- Étapes 10 et 11 : l'affichage de Praxis dans la messagerie et son image de profil (non livrés).
- Étape 14 : la mise en service, Praxis allumé hors mode essai, seulement après l'étape 12.
