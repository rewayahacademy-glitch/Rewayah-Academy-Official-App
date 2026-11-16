# Cahier BE-DOSSIER : le dossier en trois étages (lots BE-0b écran et BE-1d)

Zone : `lib/features/admin_candidature` seulement, ses tests, ses clés i18n (préfixe
`recrutement.dossier3`). Aucun serveur : tu n'emploies que ce que les ports donnent déjà.

À lire : `../STRATEGIE-BUREAU-EQUIPE-2026-11-15.md` §6 bis (constats de la vidéo, règles D1 à
D9) ; `candidature_page.dart` ; `blocs_candidature.dart` ; `gestes_proposes.dart` ;
`feuille_geste.dart` ; `piece_sur_place.dart` ; `reponses_candidature.dart` ;
`volet_conversation.dart` (à employer, pas à modifier dans son contenu).

## À faire

1. **Étage 1, fixe en haut** : nom, photo, référence, situation en une phrase (qui doit agir,
   et sur quoi).
2. **Étage 2, le résumé** : cinq lignes au plus (langues, niveau et ijaza, disponibilités,
   pays et versement, public). Aucune donnée nouvelle : celles des réponses.
3. **Étage 3, les rubriques repliées**, chacune avec une pastille (bon, à voir, manque) et
   **ses gestes à côté d'elle**, seulement ceux que le serveur propose déjà pour ce dossier :
   Photo, Pièce d'identité, Versement, Accords, chaque groupe de réponses, Entretien,
   Messages, Responsable (avec le nom s'il est fourni), Contact, Historique (avec le détail
   s'il est fourni). S'ouvre d'elle-même la rubrique qui bloque.
4. **« Contrôles » disparaît** comme bloc : la pastille de chaque rubrique le remplace. « Ce
   qui bloque » devient la phrase de l'étage 1.
5. **La photo s'affiche quand on la touche** (plein écran, fermeture par un geste ou par
   retour). Pas de bouton « voir en grand ». Même chose pour la pièce d'identité.
6. **La pièce se voit et se valide sur place.** Le lien « Ouvrir dans Dossiers à valider »
   ne reste que si la pièce ne peut pas être servie ici.
7. **Barre de décision fixe en bas** : les gestes proposés par le serveur, tous visibles
   (pas un seul à la fois). Un geste indisponible est grisé avec sa raison en mots simples.
8. **Plus de texte technique** (« Version du questionnaire : salle-examen-2 ») ; le bandeau
   « Messages pas en direct » ne s'affiche que dans la conversation.
9. Sur ordinateur (840 points et plus) : étages 1 et 2 à gauche, rubriques à droite, sans
   cadre qui défile (une seule barre de défilement, celle de la page).

## Interdit

Inventer un geste que le serveur ne propose pas (panier de demandes, impression, dispense,
« suivant » : ce sont d'autres lots). Supprimer un fichier. Toucher la liste des candidatures.

Phrase à rendre vraie : « Je juge un dossier sans faire défiler plus d'un écran, et chaque
bouton est à côté de sa rubrique. »
