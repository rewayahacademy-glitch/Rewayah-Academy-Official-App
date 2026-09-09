# Rewayah Academy — App

Application MVP de gestion des cours de Coran en visio pour Rewayah Academy. Flutter, Supabase, LiveKit.

## Comment utiliser cette documentation

**Ne lis jamais tous les fichiers de `docs/` d'un coup.** Chaque dossier de code a son propre `CLAUDE.md` qui pointe vers le document pertinent pour ce dossier précis :

- `supabase/CLAUDE.md` pour tout ce qui touche au schéma, aux policies RLS, aux fonctions et aux migrations.
- `lib/CLAUDE.md` pour tout ce qui touche aux écrans, aux composants Flutter et au thème.

Si ta tâche touche les deux, lis les deux fichiers concernés, pas l'ensemble de `docs/`.

## Le registre des décisions, à consulter avant toute question d'architecture

`docs/architecture/decisions.md` est le document vivant du projet. Il contient toutes les décisions déjà prises (ADR-001 à ADR-014 à ce jour) et, en fin de fichier, le registre unique des questions encore ouvertes.

**Avant de proposer une architecture, un choix technique ou une interprétation d'une zone ambiguë des specs, vérifie d'abord si ce point a déjà été tranché dans ce fichier.** Une décision déjà prise ne se rediscute pas sans le signaler explicitement à l'opérateur du projet.

Toute nouvelle décision prise pendant le développement s'ajoute à ce même fichier, comme un nouvel ADR à la suite des précédents. Jamais dans un nouveau document séparé.

## Documents historiques, à ne lire que sur demande explicite

`docs/historique/` contient les documents qui ont servi à cadrer le projet avant le début du code : l'audit initial complet et les deux documents de vérification de couverture. Leur contenu utile a été repris dans `decisions.md`. Ne les ouvre que si l'opérateur du projet demande explicitement de reconstituer l'historique d'une décision.
