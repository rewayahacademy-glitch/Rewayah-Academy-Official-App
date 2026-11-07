# Décision du directeur, 07/11/2026 : le remplacement, préférence de genre sans filtre

> « l'alerte doit partir à tout le monde, sans filtrer par langue. Il faut juste ajouter un petit
> paramètre qui permet de privilégier une femme pour les classes femmes et un homme pour les classes
> hommes. J'ai dit privilégier, j'ai pas dit de filtrer […] la seule alerte pour une classe […]
> d'hommes adultes doit partir chez les hommes et chez les femmes. […] Si aucun enseignant homme ne se
> présente à la minute pour une classe homme et qu'au même moment une femme se présente, le système
> doit privilégier la femme parce que c'est elle qui est présente. Et vice versa […] Vu que c'est
> temporaire, c'est acceptable. Mais si au même moment plusieurs personnes cliquent, le système doit
> attendre au moins 5 à 10 secondes avant d'accepter quelqu'un […] il faudra inscrire cela dans les
> informations de l'application. »
>
> Plus tôt le même jour : « il accepte et dans une minute max il est déjà dans la classe » ; « ce
> système doit être le meilleur au monde ».

Cette décision est une **exception datée**, valable pour le remplacement seulement, à la séparation
femmes-hommes. Le remplacement dure une séance, 1 h à 1 h 30 au plus. Les classes stables et le
recrutement restent séparés comme avant.

## Les règles

1. **Une seule alerte, envoyée à toute l'équipe**, hommes et femmes, sans filtre de langue. Chacun la
   reçoit en notification sur l'appareil, avec « J'accepte ».
2. **Une fenêtre de préférence**, réglable de 5 à 10 secondes (8 par défaut), ouverte au premier
   « J'accepte » :
   - si le premier à accepter est **du genre de la classe**, il est retenu tout de suite, sans
     attendre ;
   - si le premier à accepter est **de l'autre genre**, le système attend la fin de la fenêtre. Si
     quelqu'un du genre de la classe accepte pendant ce temps, c'est lui qui est retenu. Sinon,
     c'est le premier qui avait accepté.
   - Dans un même genre, c'est l'heure d'acceptation qui départage : le premier arrivé gagne.
3. **Le serveur tranche seul, une seule fois.** Aucun écran ne choisit. Les autres reçoivent aussitôt
   « Un autre enseignant a pris ce cours. Merci. ».
4. **La minute reste la règle.** Entre l'alerte et l'entrée en classe, il ne faut pas plus d'une
   minute, fenêtre comprise.
5. **Les paramètres** se changent sans toucher au code (`app_config`) :
   - `remplacement.priorite_genre` : activée par défaut ;
   - `remplacement.fenetre_priorite_secondes` : 8 par défaut, de 5 à 10.
6. **L'information est écrite dans l'application** : dans l'alerte, dans la page des remplacements et
   dans l'accueil de l'équipe. Une phrase suffit : « Priorité à un enseignant du même genre que la
   classe ; s'il n'y en a pas, le premier présent, car un remplacement est temporaire. »
