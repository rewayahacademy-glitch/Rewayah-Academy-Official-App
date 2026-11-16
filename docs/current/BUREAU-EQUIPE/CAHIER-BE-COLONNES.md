# Cahier BE-COLONNES : comparer les candidats sans ouvrir un seul dossier

Décision du directeur (16/11/2026) : « d'accord pour les colonnes dans la liste ». Le
directeur lit plus de 1 000 dossiers : sur ordinateur, la liste des candidatures montre les
mêmes critères que le tableau de synthèse du dossier, en colonnes, triables et filtrables.

**Ne commence qu'après la fusion de la PR 508** : le tableau de synthèse du dossier y crée
la table de correspondance des libellés courts (`lib/core/candidature/synthese_candidature.dart`).
Elle est réutilisée ici, jamais recopiée.

## Zone

`supabase/**` (plage `20261128300000` à `20261128300900`), `lib/core/candidature`,
`lib/features/admin_candidatures`. Clés i18n : préfixe `recrutement.colonnes`.

## À faire

1. Serveur : chaque ligne rendue par `lister_candidatures` porte une `synthese` (langues
   d'explication, mémorisation, ijaza, jours disponibles, plage horaire, pays et moyen de
   versement, publics), lue de la dernière réponse du candidat. Ni contact, ni pièce. Pas de
   lecture en plus par ligne au-delà d'une seule jointure sur la dernière réponse (base sous
   charge) ; mesurer en production par un bloc annulé (`supabase/CLAUDE.md`) et écrire le
   temps dans la PR.
2. Tri serveur par ijaza et par mémorisation, en plus des tris existants.
3. Écran, à 840 points et plus : une table, une ligne par candidat (nom, situation, puis les
   colonnes de la synthèse en mots-clés courts), en-têtes cliquables pour trier, filtres de
   la PR 505 en tête (ijaza, langue, jours, heures, public). Au téléphone : la liste actuelle,
   avec une seule ligne de mots-clés sous le nom.
4. Toucher une ligne ouvre le dossier (`push`), le retour retrouve la table au même endroit.
5. Aucune colonne qui défile dans un cadre fixe (DECISION-DEFILEMENT) ; à 884 points (pliable
   déplié) les colonnes les moins utiles se masquent, rien ne déborde.

Phrase à rendre vraie : « Sur ordinateur, je compare cinquante candidats d'un coup d'œil et
je trie par ijaza sans ouvrir un seul dossier. »
