# Étude du 25/10/2026 : accueil des familles, création des classes, regroupement

Demande du directeur (25/10, après les vidéos de Riwayah) : comparer leur parcours au nôtre sans
rien recréer, et étudier la création des classes, « très bancale » : à la création, le système ne
propose pas les élèves qui ont choisi ce créneau. Décisions du pilote, par délégation du 24/10.

## 1. Ce qui existe (lu dans le code et vérifié en production en lecture seule)

**Parcours famille.** Aucune demande avant le compte. Ordre réel : `/connexion` (compte d'abord),
`/inscription` (usage, identité, genre, récapitulatif, cartes `ChoiceCardGroup`), `/attente`
(compte `pending_kyc`, tout l'espace tuteur fermé jusqu'à validation par la direction), ajout d'un
enfant (prénom, nom, âge en puces), puis `/tuteur/parcours/:eleveId` : une question par page
(âge si manquant, langue, lieu ou fuseau parmi 8 lieux fixes, niveau, objectif, moments de la
journée, offres publiées en cartes). « Aucun horaire ne me convient » envoie un signal à
l'académie sans horaire souhaité. La demande de créneau personnalisé (décision du 09/10 §2) est
sur le serveur (`demandes_creneau_personnalise`, en production) mais absente de l'écran. Pas de
sélecteur de pays côté famille : il n'existe que dans la candidature des enseignants, avec la vraie
détection du fuseau de l'appareil (`fuseau_appareil_web.dart`). Sur ordinateur, le parcours reste
une colonne de 560 points : la disposition large de `PageEtape` n'est pas activée.

**Création des classes, deux chemins.** (a) Menu Classes, « Créer une classe » : public, genre,
enseignant classé (libre au créneau d'abord), jour en puces, heure de 6 h à 21 h, seuil, nom ;
aucun élève ; puis « Ajouter un élève » propose tous les comptes élèves, sans filtre.
(b) Tableau de bord, « Regroupements » (`/admin/operations/regroupements`) : les demandes des
familles sont regroupées par clé exacte (public, langue, instant UTC, genre, niveau), chaque
regroupement montre ses élèves et « Créer la classe », qui crée la classe et y intègre les élèves
d'un coup, puis propose un enseignant classé. C'est exactement ce que le directeur décrit, et c'est
en production (`regroupements_c11bis_admin`, `creer_classe_depuis_regroupement`,
`affecter_enseignant_classe_c11bis` existent dans la base). Il ne l'a jamais vu parce que le plan K2
l'a envoyé dans le menu Classes, et parce qu'aucune famille n'a encore fait de demande : la
production compte 8 classes, 1 offre, 1 élève. Un « taux de correspondance » (80 %, 90 %) n'existe
pas : le regroupement est tout ou rien sur la clé.

**Rien de tout cela n'est prouvé en production par le directeur.** Les preuves de charge exigées
le 10/10 (2 000 demandes) n'existent pas dans `supabase/tests`.

## 2. Comparaison avec Riwayah

| Point | Riwayah | Nous | Verdict |
| :-- | :-- | :-- | :-- |
| Une question par écran, progression | oui, 16 étapes | oui, cartes, sans compteur d'étapes | garder le nôtre, ajouter « étape x sur n » |
| Cartes avec titre et exemple | oui | cartes partout, même pour oui/non | puces compactes pour les choix courts, cartes seulement quand une explication aide |
| Pays et fuseau | liste avec recherche, fuseau détecté | 8 lieux fixes, fuseau deviné par décalage, sans heure d'été | reprendre le sélecteur et la détection déjà faits pour les enseignants |
| Horaire | roulette début/fin par jour | la famille choisit une offre publiée ; aucune roulette | garder les offres (décision du 09/10) ; la roulette ne sert qu'au créneau personnalisé et à la direction |
| Compte | dernier | premier, puis attente de validation | compte en dernier, pas d'attente pour une famille |
| Ordinateur | téléphone étiré | téléphone étiré | deux volets : réponses à gauche, question à droite, lettres A/B/C au clavier |
| « On a trouvé ton enseignant » | oui | non, et pas voulu | ne pas copier : chez nous la direction crée la classe |

## 3. Décisions

1. **Rien n'est recréé.** La Boucle 1 se termine (salle). Ensuite B2.1 et B2.2 se font avec le
   chemin (a) : les élèves actuels n'ont pas de demande, le filtre par créneau ne leur servirait à
   rien. La direction crée la classe et y ajoute ses élèves connus.
2. **Avant la Boucle 3 (candidats puis familles), un lot « accueil des familles »**, une fiche
   d'écran d'abord, validée par le directeur, puis une seule PR : compte en dernier et aucune
   attente de validation pour une famille ; pays et fuseau repris de la candidature des enseignants ;
   puces pour les choix courts, cartes avec exemple pour le niveau et l'objectif, compteur d'étapes ;
   deux volets sur ordinateur ; la demande de créneau personnalisé branchée sur ce qui existe déjà
   côté serveur, avec la roulette jour et heures qui empêche une fin avant le début ; moins de dix
   étapes.
3. **Création de classe, un seul ajout** : dans « Créer une classe », dès que jour, heure, public et
   genre sont choisis, la feuille montre les demandes compatibles (même clé que les regroupements)
   et les coche ; « Ajouter un élève » montre d'abord les élèves compatibles, puis les autres. Le
   « taux de correspondance » attendra : on l'ouvrira seulement si les regroupements par clé exacte
   restent trop petits, et sous la forme d'une tolérance simple (une heure d'écart, jours en partie
   communs), jamais d'un pourcentage affiché.
4. **Le sélecteur de la direction** (puces de jour, heure 6 h à 21 h) est revu dans le même lot que
   R1 et R5 (B2.2 bis) : roulette sur téléphone, grille de la semaine sur ordinateur.
5. **Preuve** : le directeur, avec un compte famille de test, fait une demande sur l'offre publiée,
   puis crée la classe depuis « Regroupements ». C'est la preuve du chemin (b), à faire quand la
   Boucle 1 est close.
6. **Page de connexion (directeur, 25/10, après le test du courriel)** : la marque est au cœur de
   tout ce qui précède l'accueil des vrais utilisateurs (pas de budget publicitaire, la
   différenciation vient d'un système moderne). Modèle : la page « Ne plus recevoir ces e-mails »
   (fond de marque plein, logo et nom en haut, illustration de l'arche, titre, texte, boutons posés
   directement sur la page, aucun conteneur emboîté). Sur téléphone, la connexion suit ce modèle :
   actions à même la page, sans rectangles dans des rectangles. Sur ordinateur, deux volets :
   l'illustration à gauche (celle des pages 404 du site public, déjà en code), le formulaire à
   droite sur fond caramel clair ; clair et sombre à décider dans la fiche. C'est un écran, une
   fiche d'écran validée par le directeur, puis une PR, **avant** l'invitation des enseignants et
   des élèves actuels (B2.1, B2.2), puisque la connexion est le premier écran qu'ils verront.
   Les autres écrans de ce lot (inscription, parcours) suivent la même règle.

## 4. Journal

| Date | Fait | Source |
| :-- | :-- | :-- |
| 2026-10-25 | Page de connexion : décision 6 ajoutée | pilote |
| 2026-10-25 | Étude écrite ; production lue en lecture seule (8 classes, 1 offre, 1 élève ; fonctions de regroupement présentes) | pilote |
