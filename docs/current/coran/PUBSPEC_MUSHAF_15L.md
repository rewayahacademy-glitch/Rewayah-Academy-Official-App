# MUSHAF-15L : bloc à ajouter dans `pubspec.yaml`

Décision du directeur du 11/10/2026, 11 h 35 : la police KFGQPC UthmanicHafs v3.0 entre dans
`pubspec.yaml`, **pour cette police seulement**. Les sessions Claude n'écrivent pas `pubspec.yaml`
(garde-fou) : Codex applique ce bloc sur la branche `claude/mushaf-15l`.

## Pourquoi

`UthmanTahaNaskh-Regular.otf` (v0.10) n'a pas 16 codepoints du texte officiel (alef wasla U+0671,
U+06E1, tanwin ouvert U+08F0 à U+08F2, U+06E5 à U+06E8, etc.) ni aucun des signes de pause :
44 102 mots sur 77 432 ont au moins une lettre sans glyphe. `UthmanicHafs-v-3.0.ttf` les porte.

## Bloc exact

Sous `flutter:`, dans la liste `fonts:` existante (même niveau que `family: UthmanTahaNaskh`) :

```yaml
    # Coran, mise en page du Mushaf de Medine en 15 lignes (MUSHAF-15L) : la
    # police KFGQPC qui porte tous les codepoints du texte et ses signes de pause.
    - family: UthmanicHafs
      fonts:
        - asset: assets/fonts/UthmanicHafs-v-3.0.ttf
```

Rien d'autre ne change dans `pubspec.yaml` (aucune dépendance). Le fichier de police et sa licence
(`assets/fonts/LICENSE-UthmanicHafs.txt`) sont déjà dans la branche.

## Contraintes de licence (EULA KFGQPC)

Usage, copie et distribution gratuits ; la police ne peut être ni vendue, ni modifiée, ni altérée.
Elle est donc embarquée telle quelle. L'application ne la sous-ensemble pas.

## Tant que le bloc n'est pas appliqué

Le code de production choisit la famille par la constante `FamilleMushaf15L.nom` (valeur
`UthmanicHafs`). Sans l'entrée `pubspec`, Flutter ne trouve pas la famille et retombe sur la police
de secours : la mise en page reste juste, les glyphes manquants sont ceux de la police de secours.
Les tests et les captures chargent la police depuis le fichier avec `FontLoader`.
