# Offres, demandes et création des groupes — décision du directeur, 09/10/2026

Dictée par le directeur le 09/10/2026 au soir. Elle prévaut sur toute règle antérieure
qui la contredit (`00`, `01`, migrations 0043 et 0049, fiches du tableau). Elle vaut pour
toute l'application.

## 1. L'administration est en amont

- L'administration crée à l'avance des **offres** (créneaux vitrines) selon des modèles
  pensés pour les horaires des familles visées, surtout en Europe et en Amérique du Nord
  (fuseaux horaires, soirs de semaine, fins de semaine).
- **Seule l'administration publie une offre.** Aucune action d'une famille n'écrit dans la
  vitrine, ne publie, ne republie ni ne modifie une offre.

## 2. Ce que voit la famille connectée

- Des **cartes de vitrine** qui ne montrent que les jours et les heures du créneau (et ce
  qui sert à choisir : durée, langue, public enfant ou adulte). **Aucun nom d'enseignant**,
  aucune autre information.
- La famille **choisit parmi les cartes**. Elle peut aussi, discrètement, demander un
  créneau personnalisé ; une notice lui dit qu'il ne s'ouvrira que si d'autres élèves le
  choisissent et remplissent le quota de la classe (5 enfants, 6 adultes, lus dans
  `app_config`).
- **Aucune demande ne part sans jour ni heure.** L'envoi est bloqué tant que la demande
  n'est pas complète : à l'écran (pas de bouton grisé : le bouton reste actif et dit ce qui
  manque) **et** côté serveur (refus explicite, garde positive).

## 3. Ce que fait le système côté administration

- Toutes les demandes arrivent à l'administration.
- Le système **regroupe automatiquement les demandes qui se ressemblent** (mêmes jours,
  même heure locale, même public, même langue ; jours triés et dédoublonnés) et affiche
  pour chaque regroupement le nombre d'élèves et un bouton **« Créer la classe »**.
  Exemple : cinq élèves qui choisissent lundi, mardi, jeudi, 18 h–21 h donnent un
  regroupement prêt.
- À la création, **les élèves du regroupement sont intégrés automatiquement** dans la
  classe.
- Le système **propose aussitôt un enseignant** (genre compatible, créneaux libres,
  charge), que l'administration confirme.

## 4. La famille est tenue au courant à chaque étape

Notification **et** suivi visible dans son espace, à chaque passage :

| Étape | Ce que la famille voit | Prochaine étape annoncée |
| :--- | :--- | :--- |
| Demande envoyée | « Votre demande est arrivée à l'administration » | Constitution de la classe |
| Classe validée par l'administration | « Votre classe a été validée » | Affectation de l'enseignant |
| Enseignant affecté | « Classe validée · enseignant affecté » | Début des cours : date et heure locale |
| Refus ou retrait | Le motif, en clair | Ce qu'elle peut faire ensuite |

La famille ne voit jamais qui d'autre a demandé le même créneau ni combien de personnes
l'ont demandé avant l'ouverture.

## 5. Partage du travail (COHABITATION.md)

- **Serveur (ChatGPT)** : garde « jour et heure obligatoires », regroupement par
  ressemblance, création de classe depuis un regroupement avec intégration atomique des
  élèves, proposition d'enseignant (contrat C-04), états de la demande et notifications à
  chaque transition. Rien n'écrit dans la vitrine hors des RPC d'administration.
- **Écrans (Claude)** : file des regroupements et bouton « Créer la classe » dans
  l'administration, proposition d'enseignant, suivi en étapes et notifications côté
  famille.
- La vitrine elle-même (`lib/features/parcours_offres`) reste dans la zone interdite
  K-64 ; la garde d'envoi y sera faite par la session qui tient cette zone.
