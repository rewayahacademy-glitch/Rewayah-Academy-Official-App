# Fiche PHOTOS-PARTOUT (garde-cap, 04/11/2026), demande du directeur du 04/11 après-midi

Demande du directeur, telle qu'il l'a dite : « leur photo, même si maintenant on peut l'ajouter, elle ne s'affiche pas partout, elle ne synchronise pas. »

Inventaire fait sur main 0a6ee422, en lecture seule ; les points marqués « vérifié » ont été relus à la main par le garde-cap.

## Cause

`photoPersonneProvider(profileId)` (lib/core/photos/photo_personne.dart) est la seule source à jour : elle passe par `PortPhotos.sources`, et `envoyerMaPhoto` comme l'éditeur de photo d'un enfant la relisent. Mais une partie des écrans ne la lit pas. Selon les cas, ils :
- lisent une clé copiée dans une autre réponse (finance, recharge, `mes_groupes_famille_v.teacher_photo_cle`, `teacher_profiles.photo_storage_key` gardée dans des fournisseurs qui ne se libèrent jamais) ;
- ou ne reçoivent aucune photo (initiales seulement).

## Exige

1. **Une seule source pour l'affichage.** Tout portrait d'une personne lit `photoPersonneProvider(son id)`, par les composants existants : `PhotoEleve` avec `personneId`, `PhotoEnseignant` avec un vrai `enseignantId`, ou le portrait de `AvatarNom` avec l'id. On n'en crée pas un nouveau.
   - Aucun écran n'affiche une photo à partir de `cleAvatar`, `avatar_storage_key`, `teacher_photo_cle`, `photo_storage_key`, `avatarUrlProvider` ou `photoEnseignantUrlProvider`. Ces champs peuvent rester dans les données, jamais comme source de l'image.
2. **Mise à jour immédiate.** Après « Choisir une photo » (adulte, enseignant compris) ou la photo d'un enfant par le tuteur, tous les écrans ouverts ou rouverts montrent la nouvelle photo sans recharger l'application. Cela découle du point 1, puisque l'envoi relit déjà `photoPersonneProvider(id)`.
3. **« Photo à fournir »** (enseignant, Mes groupes, Espace du groupe, case photo de l'accueil enseignant) se décide sur la source partagée, jamais sur `teacher_photo_cle` lu au chargement.
4. **Écrans à brancher.** Le pilote répartit en deux PR au plus, zones séparées. Les numéros de ligne renvoient à main 0a6ee422.
   - Profil de l'enseignant, en-tête et portrait public : `PortraitPublic` construit `EnseignantVM(enseignantId: '')` (photo_publique.dart:187-195, vérifié). La photo n'y apparaît jamais. Il faut l'id de l'enseignant connecté.
   - Salle :
     - tuile et vignette de l'enseignant (salle_page.dart:1530-1539 et 3773-3775, vignette_video.dart:185-188, vérifié : seule `PorteeMediaSalle.photoVignette` est lue) ;
     - en-tête et capsule de séance (chrome_seance.dart:815, capsule_seance.dart:65 et 232) ;
     - observation par le tuteur (panneau_observation_tuteur.dart:542).
   - Suivi du foyer, sélecteur des enfants (composants_historique.dart:100-112, vérifié : aucune photo passée).
   - Accueil famille, sélecteur de profils, et Foyer : carte d'un membre, fiche de l'enfant (en-tête, Couleur, Finances), Mouvements (filtre et reçu). Ces écrans lisent aujourd'hui `avatar_storage_key` : il faut passer l'id.
   - Recharge (bénéficiaires, récapitulatif, résultat) et Mes finances de l'élève adulte : la clé `cleAvatar` est périmée, il faut passer l'id.
   - Catalogue des classes, mission du contrôleur, comptable (profil de paiement), membres d'un canal du Studio, réponse en attente « Vous » dans Communauté, Mon espace en Interface guidée.
   - Comptes de la direction : la photo n'est montrée que sur ordinateur (comptes_page.dart:911-919, `rendu` nul au téléphone). Elle doit être montrée aussi au téléphone.
5. **Hors lot, ne pas toucher :**
   - le second adulte reste en initiales (décision Q4) ;
   - le pied de navigation de la direction est un libellé, pas une personne ;
   - les écrans jamais montrés en production (`foyerTitulaireProvider` et `soldes()` indisponibles) ne sont branchés que s'ils passent par le même composant, sans travail en plus.
6. **Aucune migration, aucun texte nouveau.** Le serveur rend déjà la bonne photo par `photos_personnes`. La règle de visibilité reste celle du serveur : une personne absente de la réponse garde ses initiales.
7. **Preuve exigée, sur la pile locale :**
   - un tuteur pose la photo d'un enfant ; un enseignant pose la sienne. Sans recharger, le robot ouvre chaque écran du point 4 et vérifie que l'image est là, pas les initiales : 390 et 1440, FR et AR ;
   - capture avant et après pour chaque écran ;
   - un test qui échoue si un composant de portrait reçoit une clé ou une URL au lieu d'un id (garde contre le retour du défaut).

## Réutiliser, ne pas dupliquer

`photoPersonneProvider`, `PhotoEleve`, `PhotoEnseignant`, `AvatarNom`/`TuileSansImage`. Lire `docs/current/INVENTAIRE-NON-BRANCHE-2026-10-31.md` avant de commencer. Le bilan dit ce qui a été réutilisé.

## Risque signalé (déduit du code, non testé)

`avatarUrlProvider` et `photoEnseignantUrlProvider` ne se libèrent jamais, alors que leur URL signée vit 600 s. Après ce délai, une image sortie du cache retomberait sur les initiales. Le point 1 supprime ce risque, puisque ces fournisseurs ne servent plus à l'affichage.
