# Manuscrit du directeur, « Programme du jour pour Claude… » (reçu le 19/11/2026)

Transcription mot à mot de la page manuscrite. L'orthographe est celle du directeur, corrigée
seulement là où le sens ne change pas. Les renvois `[→ lot]` sont ajoutés par l'agent et renvoient
à `SUIVI.md`.

## Partie 1 (encre noire)

- Corriger les erreurs logiques et UX du parcours d'inscription des candidats et des élèves…
  `[→ vagues A et B]`
- Chaque input d'un candidat doit avoir sa sortie côté admin (la plupart existe aujourd'hui…).
  `[→ PE-B3]` Et pour réclamer une complétion, le formulaire doit avoir le nom exact, pour
  permettre de savoir exactement ce que l'on réclame. Ex. :

  > في الملف تقول « ميثاق معلم »، ينبغي في استمارة طلب التوضيح « ميثاق معلم »، والعكس بالعكس تماما.

  Traduction : dans le dossier on dit « charte de l'enseignant » ; le formulaire de demande de
  précision doit dire lui aussi « charte de l'enseignant », et exactement pareil dans l'autre
  sens. `[→ PE-B2]`

## Partie 2 (encre jaune) : amélioration des perfs de l'interface admin

**Réorganiser les pages de la population de l'app.** Traiter la cohabitation entre les types
d'utilisateurs : le candidat, qui deviendra ensuite enseignant avec un espace complet et toutes les
fonctions et options nécessaires ; ensuite les élèves (là aussi, ils sont de simples candidats au
début ; là aussi, montrer tous leurs inputs avec une UI claire qui permet de décider facilement sur
un ou plusieurs candidats à la fois) ; ensuite les familles et leurs enfants (à toi de voir comment
traiter l'interaction visuelle et l'affichage entre le contenant « famille » et le contenu
« children », sachant que chacun d'eux peut être élève en même temps). `[→ PE-C8]`

**Supprimer les pages répétitives du traitement des candidats.** Actuellement on y accède via le
dashboard, mais cela ne mène pas à la même page, et surtout ça ne permet pas de faire des actions…
On peut aussi y accéder via le profil d'une personne quand on est dans une conversation, ou
directement via le menu du panneau latéral, mais tous ces accès sont parfois différents (la page
qui s'affiche après) ; c'est soit la page, soit ce sont les actions. Bref, tu as compris : je veux
un système uniforme qui mène à la même chose, mais à toi de voir où ajouter un aperçu avant de
donner accès à la page complète… `[→ PE-C1]`

J'ai oublié : parfois cette page donne un aperçu du document d'identité de la personne, et parfois
on doit cliquer pour le voir, mais je ne sais pas c'est quand ni où, ça tombe juste sur moi.
`[→ PE-C3]`

**Le bulk action** : on peut sélectionner plusieurs en ce moment, mais ça ne sert à rien car ça
n'ouvre rien. `[→ PE-C4]` En plus, les filtres marchent bien, mais il reste le filtre du temps pour
afficher de l'ancien au récent. `[→ PE-C4]` Et surtout les interfaces secondaires (les bottom menus,
ou tout ce qui s'affiche quand on veut afficher une simple fonction ; et même pour afficher un
message, juste pour voir, on doit ouvrir toute la page messagerie). `[→ PE-D3, PE-C7]`

## Partie 3 (encre jaune) : épingler

Permettre au reviewer d'épingler un profil pour le retrouver facilement. Ex. : on parle avec une
personne dans le chat, on la trouve intéressante, alors on l'épingle pour la retrouver sans
chercher dans toute la page… L'épinglage peut être un signe (icône) qui suit son profil, en plus
d'une page spéciale pour les profils épinglés. Cela me permettra de bien choisir mon équipe juste
en les épinglant lorsque je les vois sur une liste ou ailleurs. On peut aussi grouper plusieurs
pour les épingler ou annuler l'épinglage, ou d'autres actions comme inviter, ou bien chat de
groupe. `[→ PE-C5]`
