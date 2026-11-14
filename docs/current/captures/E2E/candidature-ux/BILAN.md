# CANDIDATURE-UX : bilan (14/11/2026)

Ce lot n'est **PAS PROUVÉ** : il a été testé localement seulement. Il n'est ni sur staging, ni en production, et le directeur ne l'a pas vu.

## 1. Langue de l'application : choisie, puis remplacée

- **Cause trouvée.** La carte de langue du récapitulatif d'inscription appelait `LocaleSettings.setLocale` directement. Seul l'affichage changeait, jamais la préférence. À l'envoi, le profil naît. La persistance par compte (`_persisterParCompte`) ne trouve alors aucun réglage pour ce compte neuf : elle remet « Système », c'est-à-dire la langue de l'appareil (l'arabe chez le directeur). Le serveur ne la corrigeait pas non plus : la langue de la candidature va dans `candidatures.langue`, pas dans `profiles.langue_communication`.
- **Correction.**
  - La carte passe par la préférence (`PreferencesLocalesControleur.langue`).
  - Un choix fait sans compte devient celui du compte qui naît : il est écrit dans le cache du compte et part au serveur (`ma_langue_communication_regler`).
  - Après une déconnexion puis une reconnexion, la langue du compte revient.
- **English** est ajouté : une carte par langue chargée dans l'application (`AppLocale.values`).
- **Migration `20261125750000_candidature_langue_anglais.sql`** (demandée par le pilote le 14/11). Le CHECK de `candidatures.langue` passe à `fr`, `ar` ou `en` (DROP CONSTRAINT puis ADD CONSTRAINT, à coller par le directeur). La validation de `inscrire_candidat` est changée par ancre, avec des contrôles avant et après. Le client envoie la langue de l'écran telle quelle.
- **Ordre obligatoire.** Installer la migration **avant** de déployer le client. Sinon un candidat en anglais reçoit « langue » invalide.
- **Scénarios.** `scenarios_candidature_langue_anglais.sql` (nouveau) et `scenarios_cand_l3_inscription_import.sql` (adapté : `es` est refusé, `en` passe ; rouge avant l'adaptation). Rejoués sur Postgres 16 local, sur une base neuve. La CI tourne sur Postgres 17.

## 2. Longues listes : cartes énormes et gel au toucher

- **Cause du délai.** Chaque carte de `ChoiceCardGroup` alignait sa taille de texte sur celle de toutes ses voisines (`TexteSansCoupure.voisins`). Elle mesurait donc les mots de toutes les autres, à chaque reconstruction : N × N mesures de texte à chaque toucher.
- **Correction.** Au-delà de 6 options, une carte n'aligne plus son texte sur ses voisines (`maxVoisins`). Un nouveau mode `ChoiceCardGroup(compacte: true)` affiche des lignes de 48 à 56, espacées de 16 (K-55). La recherche est en tête, toujours visible. La saisie filtre la liste dans les mêmes lignes.

## 3. Riwayat

- « Je récite toutes les riwayat » vient en tête et exclut les autres choix. Elle retient les vingt codes, que le serveur accepte déjà (max 20).
- Viennent ensuite Hafs, Warsh, Qaloun, Shu'ba, Ad-Duri, As-Susi, puis « Une autre riwaya » avec sa recherche.
- « J'ai maîtrisé » n'est pas écrit : « Maîtrisé » ne s'affiche jamais (mots-rewayah).

## 4. Candidater ne coûte rien

- La phrase apparaît à l'accueil de l'inscription, sur la présentation (tuile « Candidater ne coûte rien ») et sur le récapitulatif d'envoi, en fr, en et ar.
- Le mot « gratuit » est évité : mots-rewayah l'interdit sans preuve dans la politique publiée.

## 6. « Votre dossier » : étape X sur 3

- En haut de l'écran, le nom de l'étape, puis « Étape X sur 3 » et la barre de progression. Le composant est `RangeeEtape` (celui de l'inscription), qui reçoit l'option `libelleComplet`.
- X est lu de l'étape que le serveur rend : `prequalification` vaut 1, `verifications` vaut 2, `confirmee` vaut 3.
- Au-dessus, la phrase de passage d'étape s'affiche en salle 2 ou 3, tant que la candidature est en cours.
- **Limite.** Le serveur ne dit pas que le candidat « vient » de passer : la phrase reste affichée pendant toute l'étape.
- Le nom de l'étape 3 reste « Bienvenue dans l'équipe » (mots-rewayah, 02/11). « Votre arrivée dans l'équipe » n'est pas écrit.
- Le KYC n'est pas touché (consigne du pilote).

## Captures

Les captures sont à 390 et 1440, en fr, en et ar :

- `langue-choix_*` : choix de la langue ;
- `langue-maternelle-*` : longues listes ;
- `riwayat*` : riwayat ;
- `presentation-gratuit_*` et `recapitulatif-gratuit_*` : gratuité ;
- `dossier-etape-2_*` et `dossier-etape-3_*` : étape X sur 3.
