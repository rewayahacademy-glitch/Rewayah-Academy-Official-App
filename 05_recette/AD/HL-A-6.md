# HL-A-6 : KYC enseignant seulement (K-47), corrections et fin (27/09/2026)

Branche `ui/admin-v1`. Commits : 797701d (parcours tuteur sans KYC), 071d135 (file ADM-02 enseignants seulement), 2fac423 (corrections d'audit). Aucun fichier `supabase/` touché : les besoins serveur sont dans `11_admin/AD-BR.md` (BR-1.a à h, plus la section « HL-A-6 fin »).

## Pour le tuteur
- Aucune pièce, aucune vérification, aucun refus de pièce : `/attente/piece` lui est fermé ; ses accords (accusé ADR-011, conditions) restent.
- En démonstration : il arrive directement sur son accueil `/tuteur` (planche, écran 15).
- En production avant BR-1 (le serveur le fait naître `pending_kyc`) : « Votre compte est créé. L'ouverture de votre compte n'est pas encore automatique. Vous n'avez aucun document à envoyer. L'académie peut l'ouvrir pour vous : joignez-la. » avec Actualiser et Se déconnecter (planche, écran 16). Aucune promesse « en cours ».
- Rôle illisible : l'écran affiche « illisible » avec Réessayer. Il n'exige plus de pièce : seul un enseignant se voit demander une pièce.
- Textes foyer et appairage : « compte/accès ouvert » au lieu de « dossier validé ».

## Pour l'admin
- ADM-02 (liste, détail, pièce, décision, relecture) et les lignes « À traiter » de l'Accueil ne montrent que des enseignants. Il ne reste plus de lien mort vers une fiche de tuteur écartée.
- Dispense famille retirée : ExigencePiece.dispensee, « Aucune pièce requise », type Tuteur et la clé i18n orpheline.
- Banc : les personas famille « en vérification » et « pièce refusée » sont remplacés par « Famille - accès en préparation ».

## Ce qui attend BR-1
- BR-1.a/b : statut initial et porte d'accès du tuteur. Sans cela, un tuteur réel reste sur `/attente`, et aucun écran admin ne peut l'ouvrir, puisque `decider_dossier` exige une pièce.
- BR-1.c : `dossiers_en_attente` réservé aux enseignants. En attendant, la tuile compteur de l'Accueil et la page Comptes comptent encore les tuteurs.
- BR-1.d : `etat_dossier()` doit rendre `piece_requise` selon le rôle et toujours rendre le rôle. BR-1.e : fermer le dépôt de pièce au tuteur. BR-1.f : garde `teacher` dans `decider_dossier`. BR-1.g : l'événement de paiement qui ouvre l'accès. BR-1.h : les tuteurs déjà en `pending_kyc` et leurs pièces.
- Question au directeur : faut-il encore demander le genre au tuteur, et pour quelle raison ?

## Chiffres
- `flutter analyze --fatal-infos` complet : 0 problème.
- `flutter test` complet : **2973 réussis, 892 sautés (captures sans CAPTURE_DIR), 0 échec**, en 14 min 43 (`suite_complete_hl_a6.log`, un seul passage).
- Ciblés : attente, tableau de bord, foyer, dossier : 161 réussis ; planche : 48 réussis.
- Planche `captures/HL-A-5` : 16 écrans × 3 tailles × 2 thèmes = 96 PNG, dont 12 nouveaux (`tuteur_apres_inscription_*`, `tuteur_attente_ouverture_*`). 4 captures ouvertes et contrôlées : attente ouverture téléphone clair, tablette sombre, ordinateur sombre ; après inscription téléphone sombre, tablette clair.
- Réserve : le repère « Démonstration » apparaît aussi sur l'écran 16, qui représente pourtant la production. Il vient de l'hôte de capture (RepereDemonstration), pas de l'écran.
