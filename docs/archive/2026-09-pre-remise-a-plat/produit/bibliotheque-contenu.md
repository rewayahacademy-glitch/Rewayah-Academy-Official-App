# Bibliothèque de contenu — Coran, invocations, tajwid, alphabet

> Source : cahier des charges déposé par l'opérateur dans
> `D:\RA _APP\pdf 00.txt`, repris ici en UTF-8 et confronté aux décisions déjà
> prises. **Portée : étape 5 et suivantes.** Ce document est repris à l'étape 2
> pour deux raisons seulement : il fixe la police du mushaf, qui est un jeton de
> l'étape 2, et il pose un budget de poids que toute décision d'asset doit
> respecter.

## Objectifs posés par l'opérateur

- **Zéro PDF comme outil principal de texte.** Le contenu est du texte dynamique
  (JSON, Markdown, SQLite) pour rester interactif, stylable et léger sur le
  réseau. Des PDF peuvent exister, ils ne sont pas le support principal.
- **Zéro partage d'écran en cours.** La synchronisation enseignant vers élève
  passe par des micro-paquets d'indexation, pas par un flux vidéo de l'écran.
- **Poids total de l'application visé sous 20 Mo**, en s'appuyant sur des
  technologies libres et des fichiers de données très légers.

## Modules

Chaque module sépare strictement le contenu, les données, de l'affichage.

| Module | Format de données | Rendu |
| :--- | :--- | :--- |
| **Coran (mushaf)** | API en ligne (Quran.com v4) plus un paquet local pour le hors ligne | Police officielle du Complexe du Roi Fahd, **KFGQPC Uthman Taha Naskh, intégrée aux assets**. Taille, couleurs et interligne réglables. Navigation par Juz, sourate, verset |
| **Invocations (Hisn al-Muslim)** | Un fichier local `hisn.json` sous 500 Ko : arabe, translittération, traduction française | Même police uthmanique pour l'arabe, liste épurée |
| **Livres de tajwid** | Fichiers Markdown | `flutter_markdown` : titres, tableaux de règles, gras |
| **Alphabet arabe** | `alphabet.json` associant chaque lettre à ses formes initiale, médiane, finale, plus un audio MP3 compressé | Grille de cartes animées et cliquables |

## Synchronisation en cours : micro-paquets

L'enseignant navigue, l'élève reçoit. Chaque action de l'enseignant émet un
petit objet JSON ; l'application de l'élève écoute en continu et met son
interface à jour, défilement, surbrillance ou lecture audio.

```json
{ "type": "quran",    "juz": 3, "surah": 2, "ayah": 255 }
{ "type": "dua",      "id": 42 }
{ "type": "tajwid",   "chapitre": "les_regles_du_meem" }
{ "type": "alphabet", "lettre": "ba", "action": "play_audio" }
```

Impact réseau en classe : presque nul, seul l'index circule.

## Confrontation avec les décisions déjà prises

Trois points où ce cahier des charges propose autre chose que ce qui est
tranché. Les ADR font foi.

| Le cahier des charges propose | Ce qui s'applique | Pourquoi |
| :--- | :--- | :--- |
| « Firebase Realtime Database, Supabase ou WebSockets » pour la synchronisation | **Supabase Realtime**, jamais Firebase | Le projet a un seul backend, `gggmtelinlpseweouyav`, avec sa RLS et son journal d'audit. Un second fournisseur temps réel doublerait le modèle d'autorisation et sortirait les événements de classe du périmètre déjà couvert |
| `firebase_database` dans la pile technique | `supabase_flutter`, déjà en place | Même raison |
| Rien sur qui pousse la page | **L'enseignant pousse, l'élève reçoit**, et le bouton « pousser la page suivante » est de premier niveau, pas caché dans un menu | `parcours-utilisateurs.md`, `ENS-03`. C'est ce qui rend le Coran utilisable par un enfant de six ans |

Deux points sont au contraire cohérents avec l'existant et confirment les
décisions prises : la police KFGQPC est déjà intégrée aux assets depuis
l'étape 2, et le refus du partage d'écran rejoint la politique « audio d'abord »
de l'ADR-001, qui est le levier de coût numéro un du produit.

## Ce que l'étape 2 en a déjà tiré

- `UthmanTahaNaskh` est déclarée dans `pubspec.yaml` et exposée par
  `AppTypography.document()`, hors du `TextTheme` : ce n'est pas un rôle
  d'interface, c'est un rendu de document dont la taille se pilote au cas par
  cas.
- Le budget de 20 Mo est le repère qui rend la mesure des polices lisible :
  `NotoSans-Variable` à 2 Mo consomme un dixième du budget à lui seul, pour une
  interface française. Voir `docs/architecture/etape-2-journal.md`.
- La table Drift `PagesMushafConsultees` tient l'index des pages déjà vues ; les
  octets vivent dans le cache média, jamais en base locale.

## Ce qui reste à décider

| # | Question | Bloque |
| :-- | :--- | :--- |
| 1 | Riwaya du mushaf, Warsh ou Hafs. La colonne `student_profiles.riwaya` existe et vaut `hafs` par défaut | Étape 5, déjà au registre des questions ouvertes sous le numéro 3 |
| 2 | Le Coran vient-il de l'API Quran.com, du paquet local, ou de pages pré-rendues. L'audit 1.4 et `parcours-utilisateurs.md` `ELV-04` retiennent des **pages pré-rendues**, pas une composition typographique à la volée. Ce cahier des charges propose du texte dynamique : les deux ne se rendent pas de la même façon | Étape 5 |
| 3 | Où vivent `hisn.json`, les fiches Markdown et les audios de l'alphabet : assets embarqués, donc comptés dans les 20 Mo, ou stockage distant mis en cache | Étape 5 |
