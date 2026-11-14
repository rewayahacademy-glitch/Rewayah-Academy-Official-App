# Mentions : liste des villes

La liste des villes de Rewayah Academy (`public.villes_ref`) vient de **GeoNames** (https://www.geonames.org), fichier `cities15000` (villes de plus de 15 000 habitants), téléchargé le 12/11/2026, avec `admin1CodesASCII` pour le nom de la région.

Licence : **Creative Commons Attribution 4.0 International** (https://creativecommons.org/licenses/by/4.0/). Mention obligatoire, affichée sous le champ de recherche de la ville : « Liste des villes : GeoNames, CC BY 4.0 » (et en arabe).

Ce que Rewayah en fait : le nom (latin ; arabe pour les pays arabes quand GeoNames en donne un), le pays, la région, le fuseau IANA, la latitude et la longitude du centre arrondies à trois décimales (environ 100 mètres), la population en milliers. Le nom arabe est une valeur de GeoNames choisie par une règle simple (premier nom en graphie arabe, pays arabes seulement) : il n'a pas été relu à la main.

Fichiers :

| Fichier | Rôle |
|---|---|
| `supabase/migrations/20261123942100` à `20261123942150` | six morceaux, 34 215 villes en tout |
| `supabase/migrations/20261123942200` | contrôle d'effectif |
| `supabase/donnees_villes/villes_secours_plus_de_50000.sql` | variante de secours, un seul fichier, 12 405 villes de plus de 50 000 habitants (à poser à la place des six morceaux si leur collage échoue, jamais en plus) |
