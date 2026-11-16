# Cahier BE-LISTE : les retours et l'entrée (lots BE-0c et BE-1c)

Zone : `lib/features/admin_candidatures`, `lib/features/admin_traitement`,
`lib/features/admin_tableau`, `lib/features/admin_dossiers/file_dossiers.dart`, les lignes
`context.go` nommées ci-dessous dans `lib/features/admin_comptes/comptes_page.dart` et
`lib/features/admin_candidature/creneaux_entretien_page.dart`, et le routeur par ajout. Clés
i18n : préfixe `recrutement.file`.

À lire : `../STRATEGIE-BUREAU-EQUIPE-2026-11-15.md` §1 et §6 bis ;
`docs/current/CANDIDATURES/REVUE_PARCOURS_DIRECTION_2026-11-14.md` ; `candidatures_page.dart` ;
comment `comptes_page.dart` garde vue, état et tri dans l'adresse (modèle à suivre).

## À faire

1. **Retour = d'où l'on vient.** Deviennent des `push` (ou gardent la pile) :
   `traitement_page.dart:88,90`, `tableau_de_bord_page.dart:94`, `comptes_page.dart:1553,1564`,
   `candidatures_page.dart:994,1019`, `creneaux_entretien_page.dart:111`. Le bouton « Retour à
   l'accueil » de `file_dossiers.dart:56` revient à l'écran précédent s'il y en a un.
2. **Filtres, tri, page et recherche de la liste des candidatures dans l'adresse**, comme
   Comptes : un retour, un rechargement ou un lien partagé retrouvent la même liste.
3. **La position de défilement** de la liste est retrouvée au retour d'un dossier.
4. **« Personnes » ouvre Candidatures** tant qu'il y a des candidatures en cours (aujourd'hui :
   « Dossiers à valider »).
5. **En-tête de liste réduit au téléphone** : le premier nom est visible sans défiler plus
   d'un écran. Les cinq liens (Invitations, Prévenir, Créneaux, Codes, Importer) vont dans un
   seul menu « Outils » ; le bandeau « Lecture des deux côtés » tient sur une ligne, dépliable ;
   la carte « Qui attend quoi » reste, repliable, et se souvient de son état.
6. **Une seule file** : dans la carte « Qui attend quoi », la ligne « Pièce d'identité à
   valider » ouvre la liste des candidatures filtrée, pas une autre page. Les pages
   « Dossiers à valider » et « Traitement » restent en place (aucune suppression).

## Interdit

Toucher le contenu du dossier (`candidature_page.dart`, `blocs_candidature.dart` : un autre
agent y travaille). Supprimer une page ou une route. Changer un filtre serveur.

Phrase à rendre vraie : « J'ouvre un dossier depuis n'importe où, "retour" me ramène d'où je
viens, avec mes filtres et ma place dans la liste. »
