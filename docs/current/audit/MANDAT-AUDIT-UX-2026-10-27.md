# Mandat d'audit UI et UX, par rôle (directeur, 27/10/2026)

Ordre du directeur, 27/10/2026 au soir : « Il faut leur faire comprendre ce que je voulais, où on
devait arriver, et eux vont déterminer où nous en sommes en comparant les specs du début et les
objectifs. Surtout l'UI et l'UX. »

Ce mandat est une **recette**, pas un chantier. L'auditeur ne corrige rien. Il dit, preuve à
l'appui, ce qui manque, ce qui est mal placé, en double, trop grand, non branché ou cassé.

## 1. Ce que l'audit cherche

L'audio et la vidéo de la salle marchent : le directeur l'a prouvé. **Ils sont hors du champ.**

Le directeur a constaté que la plupart des fonctions existent, mais qu'elles sont :

- **mal placées** : pas à l'endroit où un utilisateur les cherche d'instinct ;
- **en double** : la même action à deux endroits, avec deux noms ;
- **non branchées** : le bouton existe, l'écran s'affiche, mais rien n'est enregistré côté serveur ;
- **mal dimensionnées** : trop grandes sur ordinateur, trop petites au doigt ;
- **déclarées faites et absentes** : un agent a dit « fait », le directeur ne le trouve pas.

Ces défauts sont trop nombreux pour que le directeur s'en souvienne. L'audit les trouve tous, rôle
par rôle, écran par écran, bouton par bouton.

## 2. Exemples réels donnés par le directeur (à confirmer, pas à supposer)

Salle, côté enseignant :

1. Un gros bouton « Afficher le Coran » occupe le centre, alors que la bibliothèque à droite a le
   Coran avec un autre bouton « Présenter ». C'est un doublon, et le centre est pris alors qu'il ne
   doit montrer que le support (Coran, tableau ou autre support), rien d'autre.
2. Fermer le Coran est compliqué : le chemin n'est pas évident.
3. On ne peut pas choisir une page précise. Pour aller à une page d'Al-Baqarah, il faut cliquer sur
   les flèches page par page. Demandé plus de cinq fois, déclaré fait à chaque fois. L'attendu est
   celui de tout lecteur du Coran public (Quran.com, Tarteel, Ayah) : aller à une sourate, à un
   juz, à un hizb ou à un numéro de page, en deux gestes au plus.

Interface de l'enseignant en général : « la plupart des choses sont faites, mais pas au bon
endroit, pas branchées, trop grandes, ou en double ».

## 3. Les sources de vérité, dans cet ordre

1. Les décisions datées du directeur dans `docs/current/` (la plus récente gagne).
2. `docs/current/SALLE-PLAN-2026-10-24.md` pour la salle (standard Google Meet pour les commandes,
   page du Coran plein écran, rien au centre sauf le support).
3. `docs/current/01_PRODUIT_ET_PARCOURS.md` et `06_SPEC_FONCTIONNELLE_MVP.md`.
4. `docs/current/audit/CHECKLIST-INITIALE-2026-10-18.md` : les spécifications demandées depuis le
   début. Elle sert à **retrouver les promesses oubliées**. Une ligne qu'une décision plus récente
   a changée suit la décision récente ; l'auditeur note le conflit sans trancher.
5. `.claude/skills/mots-rewayah/SKILL.md` pour tout texte visible.

## 4. Les standards publics de placement

Avant de tester un écran, l'auditeur écrit la **carte des emplacements attendus** : pour chaque
action, où un standard public la place, avec la source. Puis il compare à ce qu'il voit.

| Sujet | Standard de référence |
| :-- | :-- |
| Navigation principale | Material 3 : barre en bas au téléphone (3 à 5 entrées), rail ou tiroir à gauche sur ordinateur ; Apple HIG pour l'iPhone |
| Actions d'un écran | Material 3 : action principale unique et visible, actions secondaires dans la barre du haut ou un menu ⋯ ; aucune action principale cachée |
| Commandes d'appel en salle | Google Meet Android et web (loi du 24/10, `SALLE-PLAN`) |
| Support au centre de la salle | Google Meet présentation, Zoom partage : le centre montre le contenu, jamais un bouton |
| Lecteur du Coran | Quran.com, Tarteel : sélecteur sourate, juz, page ; glisser pour tourner ; fermeture évidente |
| Espace de l'enseignant | Google Classroom : classes, séances, travail, élèves, chacun à un endroit unique |
| Formulaires | Material 3 et Baymard : étiquette au-dessus du champ, erreur sous le champ, bouton d'envoi en bas |
| Tailles | Cible tactile 48 × 48 au téléphone (Material), 24 × 24 minimum (WCAG 2.2 AA, 2.5.8) ; sur ordinateur, rien de surdimensionné |
| Lisibilité | WCAG 2.2 AA : contraste 4,5:1, texte agrandi à 200 % sans perte, focus visible |
| Principes | Les dix heuristiques de Nielsen : visibilité de l'état, cohérence, prévention des erreurs, reconnaissance plutôt que rappel |

## 5. La tenue de chaque utilisateur, et ses objectifs

L'auditeur endosse chaque rôle comme une vraie personne. Un objectif non atteint en un temps
raisonnable, ou atteint par un chemin qu'un utilisateur ordinaire ne trouverait pas, est un défaut.

### Enseignant (ordinateur portable, 1366 × 768 et 1440 × 900 ; puis tablette 768)

Sayyid ou Sayyida, à l'aise avec Google Meet, pas avec l'informatique. Il arrive cinq minutes avant
la séance.

1. Voir sa journée : quelles séances, quelle classe, quelle heure, combien d'élèves.
2. Rejoindre la bonne séance en un geste depuis l'accueil.
3. En salle : ouvrir le Coran à une page précise (sourate, juz ou numéro), en deux gestes.
4. Présenter cette page à toute la classe ; changer de page ; vérifier que l'élève suit.
5. Pointer, surligner, annoter, effacer ; ouvrir puis fermer le tableau.
6. Fermer le Coran et revenir à la scène vide, sans chercher.
7. Voir qui est présent ; couper le micro d'un élève.
8. Quitter ; remplir la fiche de séance (présence, page de reprise, travail à préparer).
9. Retrouver ensuite cette fiche, sa classe, ses élèves, ses créneaux, son profil.

### Tuteur (téléphone 390 × 844, puis ordinateur)

Parent pressé, sur téléphone, entre deux tâches.

1. Voir son foyer et chaque élève en un coup d'œil.
2. Voir la prochaine séance de chaque élève : jour, date, heure locale, durée, classe, enseignant.
3. Ajouter un profil élève ; connecter l'appareil de l'élève.
4. Recevoir et retrouver les notifications : classe créée, horaire changé, séance annulée ou
   remplacée (migration en production depuis le 27/10).
5. Suivre une demande d'inscription étape par étape.
6. Voir l'historique, la présence, le travail à préparer, la progression lisible.
7. Observer une séance dans la limite permise.
8. Gérer son compte ; se déconnecter.

### Élève enfant (Interface guidée, téléphone ou tablette, appareil connecté par le tuteur)

Enfant de 8 ans qui sait à peine lire.

1. Ouvrir l'application et voir tout de suite sa prochaine séance.
2. Toucher « Rejoindre » au bon moment ; entrer en salle.
3. Voir la page du Coran en plein écran, rien d'autre.
4. Comprendre qu'il attend son enseignant.
5. Quitter et revenir.
6. Voir son travail à préparer.

Défaut connu du 27/10, à reproduire en premier : après connexion par le tuteur, l'élève « ne voit
rien ». Les données arrivent sur l'appareil (40 séances lues), la cause est dans l'application.

### Élève adulte (téléphone, puis ordinateur)

1. Aujourd'hui · Apprendre · Suivi · Profil : chaque entrée mène à ce qu'elle annonce.
2. Prochaine séance, Rejoindre, salle, bibliothèque, travail, progression.

### Direction (ordinateur 1440 × 900)

1. Voir les personnes, les familles, les élèves, les enseignants, sans doublon d'écran.
2. Voir les demandes d'inscription, les regrouper, « Créer la classe ».
3. Créer une classe, lui donner un enseignant et un horaire, la retrouver.
4. Changer un horaire, annuler une séance, remplacer un enseignant, et vérifier que la famille est
   notifiée.
5. Suivre une famille ; ouvrir un dossier ; voir l'historique de ses actions.
6. Vérifier qu'aucun écran de la direction n'est accessible depuis un autre rôle.

Contrôleur, comptable, évaluateur : seulement si un compte existe. Sinon, « Non testable : aucun
compte », et la liste de ce qui serait à tester d'après la checklist §6.10 à §6.12.

## 6. Méthode, écran par écran

1. Capture à 390, 768 et 1440, en clair et en sombre.
2. **Inventaire de chaque élément interactif** : libellé, place, taille mesurée.
3. Pour chacun : la place attendue (carte du §4), l'action réelle, et la preuve que le serveur l'a
   gardée (recharger la page, la donnée est toujours là ; ou l'autre rôle la voit).
4. Les doublons : la même action à deux endroits, sur le même écran ou dans deux écrans voisins.
5. Les cinq états : chargement, contenu, vide, erreur, hors ligne.
6. Les mots : aucun mot interdit par `mots-rewayah`, aucun code interne visible.
7. Pour chaque défaut, chercher dans le code (lecture seule) et classer :
   absent · présent non routé · présent non branché · branché mais cassé · présent mal placé.
   Méthode de recherche : checklist §0.3. Donner le fichier et la ligne probables.

## 7. Le rapport

Un fichier par rôle : `docs/current/audit/RAPPORT-<ROLE>-2026-10-28.md`. Captures dans
`docs/current/audit/captures/<role>/`, moins de 300 Ko chacune.

En tête, quinze lignes au plus : les défauts les plus graves d'abord.

Puis une table :

| Écran | Élément | Attendu (spec + standard) | Constaté | Preuve | Classe | Gravité | Code |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |

- **Classe** : Manquant · Mal placé · Doublon · Taille · Non branché · Cassé · Texte · Conforme.
- **Gravité** : Bloquant (l'objectif est impossible) · Gênant (possible mais difficile) · Finition.
- **Code** : statut (absent, non routé, non branché, cassé, mal placé) et fichier:ligne probable.

Aucun « Conforme » sans preuve. « Je ne sais pas » est une réponse acceptée.

## 8. Ce que l'auditeur ne fait pas

- Aucune correction de code, aucune nouvelle fonction, aucune proposition de refonte.
- Aucune écriture sur Supabase, Vercel ou `main` ; aucun paiement ; aucune suppression.
- Un seul profil élève de test, nommé « Test audit », signalé au directeur.
- Ne lit pas `docs/archive/`.
