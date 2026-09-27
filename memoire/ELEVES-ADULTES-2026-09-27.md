# ELEVES-ADULTES-2026-09-27 : règles réutilisables du foyer, du conjoint, des paiements et de la succession (F1 à F24)

**Sources.**
- Document du directeur : `specs/07_eleves_adultes/REWAYAH_DECISIONS_FOYER_FAMILLE_V1.md` (V1, 27/09/2026, 877 lignes). Ne le relire que par section, à la demande de l'étape (§ indiqué). Ce fichier en garde l'essentiel.
- Six planches : pilotage `16_eleves_adultes/V/PLANCHE-1..6.png`.
- Rectifications : pilotage `16_eleves_adultes/V/00_MAQUETTES_ELEVES_ADULTES.md`.

**Ordre d'autorité.**
1. La demande la plus récente du directeur.
2. DESIGN-GOV (gelé).
3. K-42, le style CL-4.
4. CLASSE-ENTREE (R1 à R21).
5. Le présent fichier.
6. Le document foyer et famille V1.
7. Les planches, qui sont des exemples de composition et jamais une règle métier ni une permission.

Les règles E5 (photo de l'élève), E6 (rien de calculé dans Flutter), E7 (pas de faux succès), E12 (pastille seulement pour une exception), E13 (lignes groupées plutôt qu'onglets), E17 (lexique) et E20 (données de démonstration datées de 2026) du fichier ENSEIGNANT s'appliquent aussi ici.

## Modèle du foyer

- **F1. Le foyer n'est pas une fusion de comptes** (doc §0, §1). On distingue toujours :
  - le compte adulte ;
  - le profil élève ;
  - la responsabilité de tuteur sur un mineur ;
  - l'appartenance au forfait famille ;
  - le droit de payer.
  - Une appartenance ne donne jamais accès aux cours, messages, notifications, progression ou historique d'un autre adulte.
- **F2. Un titulaire unique, une seule place adulte, des profils mineurs** (doc §1).
  - Le titulaire seul gère la composition, ajoute les mineurs, invite, retire et paie. Il peut aussi être élève.
  - La place adulte est destinée au conjoint ou à la conjointe, avec son propre compte et son propre espace élève. Il ou elle n'ajoute pas d'enfant, n'invite personne, ne modifie pas le foyer.
  - Le mot « proches » n'est plus une catégorie. Aucun écran ne propose « un proche adulte » comme profil géré.
- **F3. Les libellés suivent le genre du titulaire, partout et sans exception** (doc §2).
  - Titulaire homme : « Ajouter une conjointe », « Inviter ma conjointe », « Ma conjointe », « Retirer ma conjointe ».
  - Titulaire femme : « Ajouter un conjoint », « Inviter mon conjoint », « Mon conjoint », « Retirer mon conjoint ».
  - Les accords suivent (« elle », « lui »). Le genre vient de l'inscription. Aucun réglage « changer de genre » n'existe.
  - Un texte d'entrée générique (doc §19) garde « un conjoint ou une conjointe ».
- **F4. Une invitation ne révèle rien** (doc §2, §11, §17). Elle part de façon neutre.
  - Aucun message ne dit si une adresse existe déjà chez Rewayah, ni le genre d'un compte.
  - L'éligibilité se lit quand le destinataire connecté accepte.
  - Un compte déjà dans un autre foyer lit seulement : « Ce compte ne peut pas rejoindre ce forfait actuellement. »
- **F5. Les dix états de l'invitation existent tous à l'écran** (doc §5.2) : place disponible, en préparation, envoyée, acceptée, expirée, annulée, destinataire inéligible, déjà rattaché à un autre foyer, erreur réseau, réponse tardive après annulation.
  - Une seule invitation active. Le titulaire peut l'annuler. Une invitation annulée ou expirée ne déclenche aucun délai.
  - Une réponse tardive n'affiche jamais un rattachement après une annulation.
  - Le double envoi est neutralisé : le bouton passe en attente, une seule demande part.

## Permissions

- **F6. Être conjoint ne vaut pas permission de tuteur** (doc §6, §15.3, matrice §16).
  - Le second adulte ne voit ni les données pédagogiques des mineurs, ni la progression, les messages, les moyens de paiement ou les pièces du titulaire. Il n'observe pas une séance d'enfant au titre du seul lien conjugal.
  - Le titulaire ne voit pas les données pédagogiques du conjoint : ni sa Classe, ni son niveau, ni ses séances. Il voit seulement ce que la recharge exige (F10).
- **F7. Une permission ne se fait jamais par un bouton masqué seulement** (doc §16). En démonstration, l'écran d'un rôle ne reçoit tout simplement pas les données qu'il n'a pas le droit de voir.
- **F8. L'enseignant ne voit rien du foyer** (doc §15.1) : ni séparation, ni forfait, ni conjoint, ni remise, ni reprise, ni historique des rattachements. Une séparation ne retire jamais un élève de sa Classe. La recette le vérifie.

## Paiements et solde

- **F9. Un profil élève, un solde** (doc §7.2).
  - Pas de portefeuille familial, pas de réserve commune, pas de transfert.
  - Un « total du foyer » n'est qu'un récapitulatif, jamais une somme à dépenser, jamais un « budget ».
- **F10. Le titulaire paie pour le foyer, avec une vue minimale** (doc §7.1, §7.3) : le bénéficiaire, son solde ou son besoin de recharge autorisé, l'offre applicable et l'état d'accès. Rien de plus sur le conjoint.
  - Tant qu'il est rattaché, le second adulte n'a pas la gestion financière du foyer. Seul, il retrouve ses paiements personnels.
- **F11. La recharge vaut pour un, plusieurs ou tous les bénéficiaires** (doc §7.4). Le récapitulatif sépare toujours, pour chaque bénéficiaire :
  - qui reçoit ;
  - le montant payé ;
  - la quantité de solde attribuée ;
  - l'éventuelle remise ;
  - le statut de l'attribution.
  - Aucune répartition égale n'est supposée.
- **F12. Aucun chiffre économique dans Flutter** (doc §8, §20). Sont interdits en dur :
  - un pourcentage, un prix, un pack, un taux (« 1 € = 12 unités »), un seuil (« Bientôt épuisé »), un crédit bonus, une durée de validité, une remise ;
  - toute ancienne grille tarifaire.
  - D'ici BR-1, tout vient des données de démonstration, marqué « Démonstration ». Une remise ne s'affiche que si le serveur la rend.
- **F13. Payer ne produit jamais un succès local** (E7). En démonstration, le paiement s'arrête sur un état honnête. Aucun moyen de paiement réel ni numéro de carte n'est affiché, même masqué.

## Séparation, délai, succession

- **F14. Les deux adultes peuvent sortir, sans l'accord de l'autre** (doc §9.1) : « Quitter le forfait famille » côté invité, « Retirer ma conjointe » ou « Retirer mon conjoint » côté titulaire. Chaque sortie passe par une confirmation destructive qui dit ce qui ne change pas.
- **F15. Une sortie ne supprime rien** (doc §9.2) : ni compte, ni profil, ni cours, ni historique, ni solde. Aucun crédit transféré, aucun remboursement automatique, aucun recalcul du passé. Rewayah n'arbitre pas.
- **F16. Aucun membre ne disparaît en silence** (doc §9.3). L'autre adulte reçoit une notification, et, sans push, l'événement apparaît dans le centre de notifications à la prochaine ouverture. Textes du doc §9.3.
- **F17. Le délai de remplacement est rendu par le serveur, jamais calculé** (doc §10, §17).
  - Il ne suit qu'une place réellement occupée puis libérée : première séparation 60 jours, puis 120 jours, jamais plus de 120.
  - Chaque nouveau rattachement attend la validation de l'administration. Un refus ne remet pas le compteur à zéro.
  - L'écran affiche la date rendue (« à partir du {date} »), sans compte à rebours relatif, et **aucun bouton qui échouerait après envoi** : la ligne de la place dit l'état (R4).
  - L'écran n'explique pas les 60 et 120 jours en permanence : seulement quand le délai s'applique.
- **F18. La reprise du foyer est une succession de titularité, pas une prise de compte** (doc §12, §13).
  - Nom à l'écran : « Demande de reprise du foyer », motif « Décès déclaré du titulaire ». « Héritage » reste un mot interne.
  - Une seule demande active ; le titulaire est notifié et peut « Refuser la demande » ; l'administration décide toujours.
  - Au jour 30 sans réponse, rien n'est transféré : la demande passe seulement en attente de l'administration.
  - Jamais transférés : identifiants, messages, conversations, historique personnel, moyens de paiement, pièces, données privées du défunt.
  - Suspension, inactivité, compte verrouillé ou paiement échoué ne prouvent jamais un décès.
- **F19. L'émancipation à 18 ans n'est pas réinventée** (doc §14). Même identité élève, données conservées, paiements personnels ensuite. Un enfant émancipé ne devient jamais le second adulte du foyer parental.

## Écran et style

- **F20. L'espace élève et l'espace foyer restent séparés** (doc §15.2). Un adulte peut être seul, titulaire, second adulte, élève et titulaire, élève et second adulte.
  - Une fonction a un seul emplacement (E3) : l'entrée « Ajouter ma famille » vit dans Mon espace (doc §4), pas aussi dans l'accueil ni dans une tuile rapide.
  - Navigation à 4 destinations au plus, dans le même ordre partout.
- **F21. L'état d'une place se lit sur sa ligne** (R4, K-42 point 3). La ligne du conjoint dit « Invitation envoyée », « En attente de validation administrative » ou « Nouvelle invitation possible à partir du {date} », et devient l'action quand elle est possible.
- **F22. Les textes du doc §19 sont repris mot pour mot**, puis vérifiés en EA-1a. Tout texte d'information ou d'accord suit la charte pilotage `09_consentements` (gabarit §2, refus aussi simple que l'accord, reçu daté). Il est montré au directeur en français ; l'anglais fait foi dans l'application à LG-1.
- **F23. Droit anglais d'abord.** Rewayah Academy Ltd : UK GDPR, DPA 2018 et Children's Code de l'ICO d'abord, RGPD en complément.
  - L'adresse du conjoint invité est une donnée d'un tiers : minimisation, aucune relance, rien de conservé après expiration sans raison (durée à fixer avec la charte).
  - Une demande de reprise pour décès est traitée comme sensible : l'administration ne voit que le nécessaire.
  - Photo de l'élève adulte : visible par son enseignant, l'administration et les camarades de sa Classe (E5), couverte par l'accord donné à l'inscription.
- **F24. Démonstration seulement** (K-28, K-35). Aucune migration, RLS, RPC, table `families`, `spouses` ou `inheritance_requests`, aucune mutation de rôle depuis Flutter (doc §17).
  - Les écrans lisent des ports ; la démonstration les surcharge par `/demo/adulte?ecran=…&etat=…`, gardée par `environnementAutoriseDemo`.
  - Chaque capacité serveur absente devient une ligne de `16_eleves_adultes/EA-BR.md` (BR-1), jamais un comportement local.
  - Le questionnaire d'accueil (doc §3) est réservé à sa vague dédiée ; cette vague n'y touche pas.
