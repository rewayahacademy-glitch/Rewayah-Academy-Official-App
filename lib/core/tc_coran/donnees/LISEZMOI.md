# Mise en page du Mushaf de Médine en 15 lignes (MUSHAF-15L)

Fichiers `layout_madina_15*.g.dart` : **générés** par `tool/generer_layout_madina_15.dart`, ne pas
modifier à la main. Ils ne contiennent aucun asset : la structure (page, ligne, type, centrage,
plage sourate:aya) et le texte de chaque ligne, avec les signes de pause. La police qui dessine ce
texte est KFGQPC UthmanicHafs v3.0 (`assets/fonts/UthmanicHafs-v-3.0.ttf`, licence
`assets/fonts/LICENSE-UthmanicHafs.txt`, déclaration `pubspec.yaml` décrite dans
`docs/current/coran/PUBSPEC_MUSHAF_15L.md`).

## Sources et licences

| Donnée | Source | Licence / droits |
| :--- | :--- | :--- |
| Texte (UthmanicHafs v3.0, 77 432 mots), sauts de page et de ligne, juz, signes de pause | paquet npm `@quran.ws/text` **0.1.0**, `data/hafs.json` (dépôt `quran-ws/quran-text`) | **CC-BY-4.0** (le paquet) ; le texte et la police restent la propriété du KFGQPC (« Use, Copy, Distribute », ni vendus, ni modifiés, ni altérés) |
| Quarts de hizb (240) | paquet npm `quran-meta` **7.0.0**, `HizbQuarterList` de `HafsLists` | MIT |
| Validation des lignes (par l'auteur du paquet) | KFGQPC `hafsData_v2-0.csv` (`UthmanicHafs_v2-0.zip`) : 6 236 versets sur 6 236 concordent | publication du Complexe du Roi Fahd |

Pourquoi ce jeu et pas un autre : le texte est celui du KFGQPC et ses lignes sont recoupées avec le
fichier officiel verset par verset. Le jeu `zonetecde/mushaf-layout` (GitHub) a été écarté après
contrôle : 17 sourates sans cadre, codes de sourate dupliqués, pages 586 et 590 à 12 lignes.

**Attribution exigée par CC-BY-4.0** : le lecteur la montre à l'écran à côté de celle de Tanzil
(`tc.coran.mushaf.page15.creditMiseEnPage`, au pied du lecteur quand la mise en page est celle de
l'édition).

## Reproduire

```
npm pack @quran.ws/text@0.1.0 quran-meta@7.0.0
tar -xzf quran.ws-text-0.1.0.tgz   # package/data/hafs.json
tar -xzf quran-meta-7.0.0.tgz      # package/dist/HafsLists-*.js
# hizb.json : {"quarters": [...HizbQuarterList...]} (242 entrées : sentinelle 0, 240 quarts, fin 6237)
dart run tool/generer_layout_madina_15.dart --hafs=hafs.json --hizb=hizb.json
```

Empreintes SHA-256 des entrées utilisées :

```
31186b3ac554ea8d5db1dbc1f67ac5a6d3bd99a62091d04ff73f39be18bf2568  package/data/hafs.json
1253ca645d602d93dc2a1aaf02cfdca362c434cc580f647b3d8206e4709650f0  quran.ws-text-0.1.0.tgz
0e05d5313abe87ee7679c524c05dd67a9457191c0637c24541922c0e971fc8b4  quran-meta-7.0.0.tgz
6da1066fe9e5379d100c90b527efe93c714b63db6c1c42fb98c97a0e3dd80afa  hizb.json
```

## Invariants (testés dans `test/core/tc_coran/layout_madina_15_test.dart`)

604 pages ; 15 lignes par page, 8 pour les pages 1 et 2 ; 8 820 lignes de texte, 114 cadres de
sourate, 112 basmalas (ni Al-Fatiha, dont la basmala est le verset 1, ni At-Tawba) ; 6 236 fins de
verset, chaque `sourate:aya` une fois, dans l'ordre du mushaf ; 30 juz, 60 hizb, 240 quarts.

## Ce que la mise en page ne dit pas

- Le **centrage** d'une ligne de texte n'est pas dans la source : les huit lignes de la page 1 sont
  centrées, et une ligne qui termine une sourate reste courte et centrée quand elle ne remplit pas
  le cadre (`SectionLigne.termineLaSourate`, décidé au rendu, seuil 88 % de la largeur de la page).
- Les glyphes de deux signes d'Arabic Extended-B (U+0888, U+08CC) ne sont pas dans la police ;
  ils ne figurent pas dans le texte généré (contrôlé sur les 6 fichiers).
- Les lignes des modes « lecture agrandie » et « focus » restent en flux Unicode (corpus Tanzil).
