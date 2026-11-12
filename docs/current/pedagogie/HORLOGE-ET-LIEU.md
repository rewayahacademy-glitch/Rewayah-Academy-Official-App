# L'heure de l'académie et le lieu de chacun

> **EN VIGUEUR par arbitrage de l'architecte pédagogique (12/11/2026), sur délégation du directeur. Le directeur peut corriger toute règle à tout moment ; une correction datée de sa part l'emporte.**
>
> Origine : demande du directeur du 12/11/2026 (« une horloge universelle pour l'application, celle de La Mecque, et tous les autres doivent s'adapter ; à l'inscription, chacun définit son emplacement, précisément, pour les enseignants aussi »), arbitrée par l'architecte pédagogique. Lot de construction : `docs/current/pedagogie/lots/LOT-HORLOGE-ET-LIEU.md`.

## En deux phrases

Tous les cours de l'académie sont fixés à l'heure de La Mecque, qui ne change jamais. Chacun lit pourtant ses heures d'abord à l'heure de sa propre ville, et l'application lui dit à l'avance quand cette heure bouge à cause du changement d'heure de son pays.

## Les sept règles

**H1. L'heure de l'académie est l'heure de La Mecque** (fuseau `Asia/Riyadh`, UTC+3, aucun changement d'heure). C'est l'horloge de référence : tout créneau de classe est défini et enregistré dans ce fuseau. Raisons : elle ne change jamais ; l'emploi du temps d'un enseignant ne bouge donc plus deux fois par an ; deux classes de pays différents ne peuvent plus se chevaucher chez un enseignant quand leurs pays changent d'heure à des dates différentes ; un créneau choisi hors des prières d'un enseignant le reste toute l'année quand il vit dans une zone sans changement d'heure. Ce fuseau est un réglage de la direction (valeur par défaut `Asia/Riyadh`), jamais écrit en dur dans le code.

**H2. Chacun lit ses heures à l'heure de sa ville d'abord.** L'architecte arbitre ici contre « tous les autres doivent s'adapter » pris à la lettre : les gens vivent à l'heure de leur ville, et leur faire convertir de tête ferait manquer des cours. Partout où une heure de cours est montrée à une personne : son heure locale en grand, « heure de La Mecque » en second, discrètement (par exemple « 19 h · 21 h à La Mecque »). La direction voit les deux, et l'heure locale de l'enseignant.

**H3. Le changement d'heure d'un pays est annoncé, jamais subi.** Dans un pays qui change d'heure, l'heure locale d'un cours bouge d'une heure deux fois par an (19 h l'hiver, 20 h l'été à Paris, par exemple). Chaque personne concernée est prévenue 14 jours avant et la veille, avec l'heure exacte avant et après (« À partir du dimanche 28 mars, votre cours passe de 19 h à 20 h »). Pour un mineur, c'est le tuteur qui est prévenu. À la création d'un créneau et à l'inscription dans une classe, l'écran montre les deux heures de l'année (« 19 h en hiver, 20 h en été chez vous »).

**H4. Les classes qui existent déjà ne bougent pour personne le jour de l'installation.** On garde l'instant réel des séances à venir : un cours à 19 h à Paris en novembre devient 21 h à La Mecque, et reste à 19 h à Paris en novembre. Le jour de la semaine est recalculé si la conversion passe minuit. La première conséquence visible sera au prochain changement d'heure du pays de la famille, annoncé comme en H3. La direction peut alors déplacer le créneau par le geste existant si les familles le préfèrent.

**H5. La ville de chacun est obligatoire.** Chaque foyer (par son adulte) et chaque enseignant indique sa ville. L'application propose d'abord les villes du fuseau de l'appareil, puis une recherche. On enregistre : le nom de la ville, le pays, le fuseau, et les coordonnées du centre de la ville. Jamais d'adresse, jamais la position de l'appareil, jamais une position précise.
- Un enfant ne saisit rien : il reçoit la ville de son foyer.
- Pour un enseignant, la ville est saisie par lui et vérifiée par la direction, parce que les zones des enseignants sont connues de l'académie. Le lieu de prière de l'enseignant (autre lot) pourra être prérempli par cette ville.
- Les personnes déjà inscrites indiquent leur ville à leur prochaine ouverture de l'application : une étape courte, expliquée (« pour afficher vos heures de cours, et bientôt vos heures de prière »). On peut la reporter un nombre limité de fois (réglage de la direction, 3 par défaut), pas indéfiniment. Pendant ce temps, le fuseau déjà connu continue de servir.
- La ville n'est jamais montrée aux autres élèves ni aux autres familles : seuls la personne, son foyer et la direction la lisent.

**H6. Les incohérences sont signalées, jamais corrigées seules.** Le système signale à la direction toute personne dont le pays, le fuseau et la ville ne concordent pas (fait connu : une enseignante enregistrée avec le pays Guinée et le fuseau Europe/Paris). Il ne change rien tout seul.

**H7. Les heures de prière sont un autre lot.** Les heures de prière et la pause de prière ne sont pas dans ce lot (lot PRIERE-1). Ce lot leur laisse seulement des données propres : le fuseau de chaque classe est le fuseau de référence, et chacun a une ville avec ses coordonnées.

## Ce que cette décision ne change pas

- Les instants des séances (le moment réel où le cours a lieu) ne sont jamais déplacés par la conversion.
- Aucun nouveau mot d'argent, aucune règle de paie ni de présence : seul le découpage par fuseau est revu s'il en dépend.
- Aucun service externe n'est appelé depuis l'application avec la position de l'utilisateur.

## Ce qui reste à la direction

Le fuseau de référence (`Asia/Riyadh` par défaut), le nombre de reports permis de l'étape « ville » (3 par défaut), la vérification de la ville d'un enseignant, et le déplacement d'un créneau quand un changement d'heure déplace l'heure locale d'une famille.
