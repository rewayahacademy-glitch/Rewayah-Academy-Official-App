# DOSSIER POUR CHATGPT : faits vérifiés de Rewayah Academy

Préparé le 24/09/2026 par Claude Code (coordinateur), à partir du dépôt au commit `cefab7f` (branche `ui/tuteur-v1`) et des documents du directeur. Tout ce qui suit est sourcé ; ce qui n'a pas pu être prouvé est marqué « à vérifier ». Tu n'as pas accès au code : ce dossier est ta seule source sur l'existant.

## 0. L'essentiel, à lire en premier

1. **Application** : Flutter (Android, iOS, web), Supabase, LiveKit, stockage R2. Cours de Coran en visio par **classes stables** (groupe fixe, horaire récurrent, enseignant attitré). Rôles : tuteur (famille), élève adulte, élève enfant (Interface guidée), enseignant, administration, contrôleur, contrôleur invité, finance et comptable.
2. **Ordre des vagues** décidé par le directeur (section B) : Tuteur V1 (en cours de construction), puis **Classe et visio (priorité n° 1 : un élève et un enseignant se rencontrent et se voient)**, puis validation des dossiers par l'admin, backend, puis les autres rôles, le lecteur du Coran, la landing web, la publication.
3. **Système de design GELÉ** (section C) : palette, polices DM Sans (titres) et Plus Jakarta Sans (tout le reste), rayons, espacements, composants. Aucune nouvelle couleur ni police. Les maquettes existantes donnent la DISPOSITION, pas les couleurs.
4. **Règles du directeur** (section A, §1 bis et suivants) : une fonction = un seul endroit ; carte groupée = un seul rectangle à fins filets ; navigation, retour et déconnexion toujours accessibles ; web = vraie version ordinateur ; rien d'affiché comme fait sans garantie serveur ; plan fermé.
5. **Faits de produit tranchés par le directeur** : l'enregistrement audio des cours est RÉEL (bucket R2 dédié), la notice « Cours enregistré, visite de contrôle possible. » est conservée ; observation par le parent : 2 visites de 2 minutes par parent et par séance, une visite écourtée est consommée ; salle d'observation épurée avec un bandeau pleine largeur (décompte seconde par seconde, « 1/2 visite restante pour cette séance »).
6. **Deux points à signaler au directeur, pas à trancher seul** :
   - une règle d'éthique visuelle ancienne (archivée, section C) interdisait les images générées par une IA et recommandait vert et or pour les accents religieux. Le directeur te demande aujourd'hui de générer des maquettes : sa demande récente prime pour des MAQUETTES de travail, mais signale dans chaque document que les visuels destinés au public (icône, captures des stores, illustrations) doivent être validés contre cette règle ;
   - le dépôt ne contient **aucun logo** et l'icône de l'application est celle de Flutter par défaut : à prévoir dans le document de publication.

## Sommaire

- A. Décisions du coordinateur et réponses du directeur (fichier `03_DECISIONS_COORDINATEUR.md`)
- B. Vagues du projet et backlog de la vague Classe et visio
- C. Système de design gelé (valeurs réelles du code)
- D. Tuteur : écrans et états sans maquette, maquettes existantes et leurs erreurs
- E. Inventaire des écrans de tous les autres rôles, avec l'état réel du code
- F. Mandat original du directeur pour le rôle Tuteur (référence du niveau de détail attendu)

---

