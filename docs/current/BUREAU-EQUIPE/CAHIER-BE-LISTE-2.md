# Cahier BE-LISTE-2 : un seul système de filtres, la liste remonte

Retour du directeur sur la production (16/11/2026, captures du téléphone) : « Il y a combien
de types de filtres ici et de tri ? Je vois des tableaux, des rectangles, des pastilles. Il
faut unifier le système pour libérer de la place. La liste s'affiche trop bas. » « Le message
jaune des deux côtés, je l'ai compris : il faut qu'il soit fermable. » Et la rangée
« 383 candidatures / Sélectionner / Trier » : « des pastilles placées au hasard ».

## Ce qui est vrai aujourd'hui (captures du directeur, 360 de large)

Avant le premier nom, il y a **sept** blocs : le titre et le sélecteur de section (le mot
« Candidatures » deux fois), « Outils », le bandeau jaune, « Qui attend quoi » (trois groupes
de lignes), la carte « À traiter » (qui répète « À compléter 107 » sous le nom
« 107 informations manquantes »), la recherche, les puces « Toutes / Plus », puis une rangée
nombre, « Sélectionner » et « Trier » cassée en deux lignes. **Quatre façons de filtrer** et
une de trier, chacune avec sa forme.

## La règle

Un seul système, trois rangées au plus avant le premier nom, au téléphone comme sur ordinateur.

1. **Rangée 1** : le titre **est** le sélecteur de section (« Candidatures ▾ »), plus
   l'icône « Outils ». Le mot n'apparaît qu'une fois.
2. **Rangée 2** : le champ de recherche, avec à sa droite deux icônes : « Filtres » (avec le
   nombre de filtres posés) et « Trier ». Les deux ouvrent une feuille (au téléphone) ou un
   menu (ordinateur). La feuille « Filtres » contient tous les filtres d'aujourd'hui (étape,
   état, issue, pause, versement, pays, genre, compétences, et ceux de la PR 505 : ijaza,
   langue, jours, heures, public, pièce en attente, responsable).
3. **Rangée 3** : **les files**, une seule rangée de puces qui passent à la ligne si besoin
   (jamais de défilement de côté), chacune avec son nombre, venant de « Qui attend quoi » et
   de « À traiter » réunis : En examen 176 · Pièce à valider 169 · Entretien à planifier 40 ·
   À compléter 107 · Versement impossible 51 · Toutes 383 ; plus Entretiens en retard,
   Bloquées, Confirmées indisponibles **seulement si leur nombre n'est pas zéro**. Une puce
   touchée = la file choisie (une seule à la fois) ; la puce choisie est pleine. La puce
   « Entretien à planifier » dit, sous forme d'icône d'alerte, qu'aucun créneau n'est ouvert.
4. Sous les files, une ligne de texte simple : « 383 candidatures » à gauche, « Sélectionner »
   à droite, sur la même ligne, alignés. Plus de bouton « Trier » ici.
5. **Le bandeau « Lecture des deux côtés » se ferme** : « J'ai compris » le fait disparaître
   pour ce compte (mémoire de l'appareil existante), et il ne revient pas. Une petite icône
   à côté du titre le rappelle au toucher.
6. Les cartes « Qui attend quoi » et « À traiter » disparaissent comme cartes : leurs
   nombres vivent dans les puces des files. Leurs phrases d'explication (« la plus ancienne
   depuis 1 jour », « à valider dans le dossier ») passent dans la feuille « Filtres », en
   petit, sous chaque file.

## Zone

`lib/features/admin_candidatures` seulement (carte_attentes, carte_alertes, candidatures_page,
etat_entete_liste), ses tests, clés i18n `recrutement.file`. Aucune donnée ni lecture du
serveur en plus : les nombres viennent des lectures existantes (`attentes_recrutement()` et
les alertes). Rien supprimé hors de ce dossier.

## Mesure

À 360 × 800, le haut de la première ligne de candidature sous **300** points (aujourd'hui
plus de 1 500 quand « Qui attend quoi » est déplié). Mesures dans `journal.txt`, captures à
360, 673, 884 et 1366, en français et en arabe, aucun débordement.

Phrase à rendre vraie : « J'ouvre Candidatures, je vois mes files avec leurs nombres et les
premiers noms tout de suite ; un seul bouton pour filtrer, un seul pour trier. »

## Révision du 16/11 (directeur, sur la capture de la PR 515)

« Regarde les dimensions de la recherche ! Cinq lignes pour ces filtres ? Pourquoi pas un menu
déroulant ? » Les files ne sont plus des puces : **un seul menu déroulant « File »**, qui
affiche la file choisie et son nombre (« En examen · 176 ▾ ») et s'ouvre sur la liste des
files avec leurs nombres et leur phrase courte. Au téléphone, deux rangées au plus avant la
liste : (1) titre-sélecteur et Outils ; (2) recherche compacte (48), menu File, Filtres,
Trier. Le nombre de candidatures et « Sélectionner » restent sur une ligne au-dessus du
premier nom. Cible : premier nom sous 300 points à 360 × 800.
