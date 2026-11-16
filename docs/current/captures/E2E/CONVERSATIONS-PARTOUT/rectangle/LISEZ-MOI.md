# Rectangle derrière le champ de saisie (CONVERSATIONS-PARTOUT, 16/11/2026)

Consigne du directeur : « supprime le rectangle ». `avant/` : le dépôt avant le correctif ; `apres/` : après.
Le champ et le bouton image reposent directement sur le fond du fil (`_SurFondDuFil` dans `fil_discussion.dart`), sans bande
ni retrait propre ; la phrase d'aide sous le champ n'existe plus. Fichiers : le canal du Studio (390, 1440, clair et sombre,
fil en page à titre) et le fil de Messages (390 et 1440). La garde de rendu est `test/core/widgets/fil_saisie_sans_rectangle_test.dart`.

Limite : le canal du Studio garde sa zone grise dans la page blanche (écart nommé dans `docs/current/MESSAGERIE-MATRICE.md`,
ligne 24). Rien n'est prouvé en production.
