# BE-2b, écran « Équipe » : écarts au cahier

Le cahier `CAHIER-BE-2B-EQUIPE.md` n'est pas dans `main` (il vit sur la branche du pilote) ; cette note l'accompagne.

**Écarts acceptés par le pilote, 17/11/2026** (PR #592) :

1. **Menu « … »** : « Inviter une personne » et « Nouvelle mission » sont dans un menu ; seul « Accorder une mission » est visible. Avec deux boutons nommés, le premier nom de la liste tombait à 460 pt sur 360 x 800 (critère : moins de 300) ; mesuré après correction : 296 pt dans la coque réelle.
2. **Titre de section retiré** : « Personnes avec une mission » n'est plus affiché, pour la même raison.
3. **Une ligne par mission accordée** (et non une par personne), pour pouvoir retirer une mission précise.
4. **Onglet « Équipe » visible de toute la direction** : toutes ses lectures sont réservées à la direction active côté serveur ; port absent = état « indisponible ».
5. **Navigation par rôle** : le routeur et la coque (`routes.dart`, `app_router.dart`, `nav_shell.dart`) distinguent `AppRole.associe` (accueil et seul accès : « Candidatures »), comme pour les cinq autres rôles ; la barrière reste la RLS. **Aucune page ne lit le rôle** : la coque annonce aux pages celles qu'elle laisse ouvrir (`PagesOuvertesCoquille`) et la sous-navigation retire les autres sections.

**Reste ouvert** : aucune capacité du serveur ne dit « cette personne peut ouvrir les autres pages de Personnes » ; la portée est donc posée par la coque, pas lue sur une capacité. Si le pilote veut une capacité serveur, c'est à lui d'en décider le nom et le numéro.

**Non fait** : « Renvoyer » une invitation (suppose l'envoi d'un courriel), le texte du courriel d'invitation, l'écran d'inscription de l'associé.
