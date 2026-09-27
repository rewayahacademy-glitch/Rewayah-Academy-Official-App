# Rewayah - Décisions foyer, conjoint, paiements et succession - V1

**Date :** 27/09/2026  
**Statut :** DÉCISIONS PRODUIT VALIDÉES PAR LE DIRECTEUR + CONTRATS FRONTEND À PRÉSERVER  
**Destinataire :** Claude Code  
**Périmètre actuel :** FRONTEND ONLY  
**Domaines impactés :** Élève adulte, Tuteur, Onboarding, Administration, Finance, Notifications  
**Ne pas lancer :** migration, RLS/RPC, nouveau schéma Supabase, logique financière de production, refonte auth, refonte LiveKit.

---

## 0. Objet du document

Ce document fixe le modèle familial à conserver pendant la verticale `05_ELEVE_ADULTE` et les vagues suivantes.

Il remplace les anciennes formulations trop larges du type « enfants ou proches » lorsqu'elles impliquent qu'un adulte autonome pourrait devenir un profil géré par un tuteur.

Principe central :

> Rewayah distingue strictement le compte adulte, le profil élève, la responsabilité de tuteur sur un mineur, l'appartenance à un forfait famille et les droits de paiement.

Une appartenance familiale ou commerciale ne donne jamais automatiquement accès aux données pédagogiques, messages, notifications privées ou historiques d'un autre adulte.

Le modèle financier détaillé n'est pas encore mûr. Le frontend doit donc préserver les points d'entrée et les états, sans coder de pourcentage, prix, quantité de crédits, durée commerciale, seuil de remise ou règle de facturation en dur.

---

# 1. Modèle canonique du foyer

Un foyer Rewayah comporte :

1. **Un titulaire unique**
   - propriétaire fonctionnel du foyer ;
   - seul gestionnaire de sa composition ;
   - seul à ajouter les profils mineurs ;
   - seul à initier les paiements/recharges pour les membres du foyer ;
   - peut lui-même être élève.

2. **Une seule place adulte supplémentaire**
   - destinée au conjoint ou à la conjointe ;
   - compte Rewayah distinct ;
   - identité et espace élève indépendants ;
   - ne devient pas co-gestionnaire du foyer ;
   - ne peut pas ajouter des enfants ;
   - ne peut pas inviter un autre adulte ;
   - ne peut pas modifier la composition du foyer.

3. **Des profils mineurs sous la responsabilité du titulaire**
   - ajoutés uniquement par le titulaire ;
   - chaque profil conserve son identité pédagogique, sa classe, son historique et son solde ;
   - l'adulte invité n'obtient aucun droit Tuteur automatique sur eux dans ce MVP.

Le foyer n'est donc pas une fusion de comptes.

---

# 2. Règle de genre pour la place adulte

Le genre est une donnée de base recueillie pendant l'inscription.

Il n'existe aucune fonction utilisateur de changement de genre dans l'application.

La place adulte suit le genre du titulaire :

- titulaire homme : libellé **« Ajouter une conjointe »** et seule une femme peut occuper la place ;
- titulaire femme : libellé **« Ajouter un conjoint »** et seul un homme peut occuper la place.

Les libellés doivent rester cohérents partout :

### Titulaire homme
- Ajouter une conjointe
- Inviter ma conjointe
- Ma conjointe

### Titulaire femme
- Ajouter un conjoint
- Inviter mon conjoint
- Mon conjoint

### Garde-fou technique

Ne jamais utiliser une erreur d'invitation pour révéler publiquement si un email/téléphone existe déjà dans Rewayah ou quel genre est enregistré sur ce compte.

Une invitation peut être envoyée de façon neutre. L'éligibilité réelle est vérifiée lorsqu'un destinataire authentifié tente de l'accepter.

### Correction d'une erreur de saisie

Il n'existe pas de « changement de genre » en libre-service.

Une éventuelle erreur de saisie initiale doit, si ce besoin est retenu plus tard, relever d'une correction administrative auditée. Ne pas créer de réglage utilisateur pour cela.

---

# 3. Onboarding à conserver pour la vague dédiée

Le choix d'usage reste composé de deux options :

## Moi uniquement

Texte de compréhension :

> Je souhaite utiliser Rewayah pour moi-même.

## Moi et ma famille

Texte de compréhension cible :

> Utilisez Rewayah pour vous-même si vous le souhaitez, inscrivez vos enfants et ajoutez un conjoint ou une conjointe à votre forfait famille.

Ne plus employer « proches » comme catégorie ouverte.

Explication secondaire possible :

> Le forfait famille comprend un titulaire, un conjoint ou une conjointe adulte, et les enfants ou adolescents sous la responsabilité du titulaire. Chaque adulte conserve son propre compte.

### Important

Choisir « Moi et ma famille » :

- ne crée pas automatiquement un profil élève pour le titulaire ;
- ne crée pas automatiquement un compte pour le conjoint ;
- ne donne aucune permission pédagogique entre les deux adultes ;
- ne déclenche aucune remise calculée localement ;
- réserve seulement la capacité fonctionnelle de construire un foyer.

---

# 4. Passage ultérieur de « Moi uniquement » vers une famille

Un adulte déjà inscrit seul doit pouvoir évoluer sans recréer son compte ni son identité élève.

Point d'entrée à prévoir dans `Mon espace` :

**Ajouter ma famille**

Explication :

> Vous pouvez ajouter vos enfants et inviter un conjoint ou une conjointe à rejoindre votre forfait famille. Votre espace élève reste inchangé.

Le flux réutilise la même architecture familiale que l'onboarding.

Aucun historique, classe, progression, travail, solde ou identité élève n'est dupliqué.

---

# 5. Invitation du second adulte

## 5.1 Règles

- une seule place adulte supplémentaire existe ;
- une seule invitation adulte peut être active à la fois ;
- une invitation en attente réserve temporairement cette place ;
- le titulaire peut annuler une invitation en attente ;
- une invitation expirée ou annulée avant acceptation ne déclenche aucun délai anti-abus ;
- l'adulte invité doit accepter depuis son propre compte ;
- si aucun compte n'existe, il crée son compte personnel puis reprend l'invitation ;
- l'acceptation ne fusionne jamais les comptes.

## 5.2 États frontend à prévoir

1. Place disponible
2. Invitation en préparation
3. Invitation envoyée
4. Invitation acceptée
5. Invitation expirée
6. Invitation annulée
7. Destinataire inéligible
8. Compte déjà rattaché à un autre foyer
9. Erreur réseau
10. Réponse tardive après annulation

Aucun succès ne doit être fabriqué localement.

---

# 6. Permissions du second adulte

Le second adulte :

- possède son propre compte ;
- possède son propre profil élève s'il étudie ;
- voit ses propres cours ;
- voit ses propres messages ;
- voit ses propres notifications ;
- voit sa propre progression ;
- voit son propre historique ;
- voit son propre solde selon les droits du rôle Élève adulte ;
- bénéficie du forfait famille selon la future politique économique.

Il ne peut pas :

- ajouter un enfant ;
- modifier un enfant ;
- inviter un adulte ;
- retirer le titulaire ;
- gérer le foyer ;
- consulter les messages privés du titulaire ;
- consulter la progression du titulaire ;
- consulter les données pédagogiques des mineurs ;
- observer une séance d'un mineur au titre du seul lien conjugal ;
- consulter les moyens de paiement du titulaire ;
- accéder aux données KYC du titulaire ou des enfants.

Le fait d'être conjoint ne vaut pas permission Tuteur.

---

# 7. Paiement et solde

## 7.1 Décision de gouvernance

Le **titulaire paie pour le foyer**.

Il peut initier une recharge :

- pour lui-même s'il possède un profil élève ;
- pour un enfant ;
- pour plusieurs enfants ;
- pour le conjoint ou la conjointe ;
- pour une sélection de bénéficiaires ;
- pour tous les bénéficiaires éligibles du foyer.

Le second adulte n'est pas le gestionnaire financier du foyer tant qu'il reste rattaché comme adulte invité.

Lorsqu'il quitte le foyer et redevient adulte autonome, il récupère les commandes de paiement propres à son compte selon le rôle Élève adulte standard.

## 7.2 Pas de portefeuille familial

Maintenir strictement :

> **1 profil élève = 1 solde.**

Le « total foyer » éventuel est uniquement un récapitulatif.

Il n'est jamais :

- un portefeuille partagé ;
- une réserve commune ;
- une permission de transfert ;
- un solde dans lequel plusieurs élèves consomment librement.

## 7.3 Visibilité financière minimale

Parce que le titulaire finance le foyer, il peut disposer de la projection minimale nécessaire à la recharge :

- bénéficiaire ;
- solde ou besoin de recharge réellement autorisé ;
- offre/devis applicable ;
- état d'accès nécessaire au paiement.

Cela ne lui donne pas accès automatiquement au journal financier complet du conjoint, à ses moyens de paiement personnels ou à des informations sans rapport avec la recharge familiale.

## 7.4 Recharge individuelle ou groupée

Le flux existant de recharge par bénéficiaire doit rester compatible avec :

- un seul profil ;
- plusieurs profils sélectionnés ;
- tous les profils éligibles.

Le récapitulatif doit toujours séparer :

- qui reçoit quoi ;
- montant payé ;
- quantité de solde attribuée ;
- éventuelle remise commerciale ;
- statut de chaque attribution.

Aucune répartition implicite ou égale n'est supposée.

---

# 8. Réduction famille : ne pas figer l'économie maintenant

La partie économique n'est pas suffisamment mûre pour arrêter :

- le pourcentage de remise ;
- un prix fixe ;
- un seuil exact ;
- une quantité de crédits ;
- une durée ;
- une date d'effet après séparation ;
- une règle de cumul.

Donc :

> Le foyer fournit un **contexte d'éligibilité commerciale**, pas une formule de remise codée dans Flutter.

La future verticale Finance doit déterminer la politique réelle via des règles versionnées.

Interdictions dans le frontend :

- `if members >= 2 => -10%`
- prix famille codé en dur ;
- seuil codé en dur ;
- crédit bonus créé localement ;
- ancienne grille tarifaire reprise comme vérité de production.

Les anciens prix ou exemples restent des références historiques, pas des constantes.

---

# 9. Séparation et sortie du forfait famille

## 9.1 Qui peut engager la sortie ?

Les deux adultes peuvent rompre le rattachement.

### Côté adulte invité
Action :

**Quitter le forfait famille**

### Côté titulaire
Action :

**Retirer mon conjoint**  
ou  
**Retirer ma conjointe**

Aucune partie n'a besoin de l'autorisation de l'autre pour sortir du rattachement.

## 9.2 Effets

La séparation du foyer :

- ne supprime aucun compte ;
- ne supprime aucun profil élève ;
- ne supprime aucun cours ;
- ne supprime aucun historique ;
- ne supprime aucun solde ;
- ne transfère aucun crédit ;
- ne déclenche aucun remboursement automatique ;
- ne recalcule pas rétroactivement les achats passés.

Les éventuels arrangements financiers entre les deux adultes après séparation relèvent d'eux-mêmes. Rewayah ne joue pas le rôle d'arbitre matrimonial.

Les effets futurs sur le tarif famille restent définis par la politique Finance active et ne doivent pas être inventés ici.

## 9.3 Notifications obligatoires

Si l'adulte invité quitte :

- le titulaire reçoit une notification explicite.

Exemple :

> **Mariama a quitté votre forfait famille.**  
> Son compte, ses cours et son solde restent indépendants. Votre foyer a été mis à jour.

Si le titulaire retire l'adulte invité :

- l'adulte invité reçoit une notification explicite.

Exemple :

> **Vous avez été retirée du forfait famille de Mamadou.**  
> Votre compte, vos cours, votre historique et votre solde restent disponibles.

Si le service push n'est pas disponible, l'événement doit au minimum apparaître dans le centre de notifications/états de l'application lors de la prochaine ouverture.

Ne jamais faire disparaître silencieusement un membre.

---

# 10. Délai anti-abus et remplacement du second adulte

Le délai s'applique uniquement après qu'une place adulte a été **effectivement occupée**, puis libérée.

Une invitation jamais acceptée ne compte pas comme séparation.

## 10.1 Première séparation effective

Après le premier départ d'un second adulte :

- délai minimum de **60 jours** avant un nouveau rattachement ;
- puis validation administrative obligatoire du nouveau rattachement.

## 10.2 Deuxième séparation effective et suivantes

À partir de la deuxième séparation effective du même foyer :

- délai minimum de **120 jours** avant tout nouveau rattachement ;
- ce délai ne dépasse plus 120 jours ;
- validation administrative obligatoire à chaque nouveau rattachement.

Formule canonique :

- séparation n°1 -> 60 jours ;
- séparation n°2 -> 120 jours ;
- séparation n°3 -> 120 jours ;
- séparation n°4 et suivantes -> 120 jours.

## 10.3 Refus administratif

Un refus administratif :

- ne remet pas automatiquement le compteur de délai à zéro ;
- ne redémarre pas automatiquement une nouvelle période de 60 ou 120 jours ;
- permet une nouvelle demande après correction du motif, selon le workflow Admin.

## 10.4 UX pendant le délai

Afficher une date claire, par exemple :

> **Nouvelle invitation possible à partir du 18 décembre 2026.**

Ne pas afficher un bouton qui échouera seulement après soumission.

Après expiration du délai, le titulaire peut initier le nouveau rattachement.

Le nouvel adulte accepte d'abord l'invitation, puis le rattachement reste :

> **En attente de validation administrative**

jusqu'à décision réelle.

---

# 11. Cas où l'adulte invité appartient déjà à un autre foyer

Un adulte ne peut appartenir qu'à un seul forfait famille actif à la fois.

Si le compte invité est déjà membre ou titulaire d'un autre foyer :

- pas de fusion automatique ;
- pas de double appartenance ;
- pas de migration silencieuse des enfants ;
- pas de transfert de droits.

Afficher un état neutre :

> **Ce compte ne peut pas rejoindre ce forfait actuellement.**

Les cas complexes appartiennent à une procédure administrative future.

---

# 12. Décès du titulaire et « demande héritage »

## 12.1 Principe

Le second adulte déjà rattaché peut demander à reprendre **la titularité du foyer** si le titulaire est déclaré décédé.

Cette fonction ne transfère jamais le compte personnel du titulaire.

Elle transfère uniquement, après validation, la gouvernance du foyer.

Nom utilisateur de la démarche :

**Demande de reprise du foyer**

Motif système :

**Décès déclaré du titulaire**

Le terme interne « demande héritage » peut être conservé dans le suivi interne si nécessaire, mais l'interface doit expliquer concrètement ce qui est repris.

## 12.2 Déclenchement

L'adulte invité lance la demande.

Le système notifie :

- l'administration ;
- le compte du titulaire concerné.

Notification au titulaire :

> **Une demande de reprise de votre foyer a été déposée en indiquant votre décès.**  
> Si cette demande est erronée, refusez-la.

Action :

**Refuser la demande**

## 12.3 Délai

Si le titulaire ne répond pas pendant **30 jours** :

- cela ne valide pas automatiquement la demande ;
- cela retire seulement le blocage d'absence de réponse ;
- l'administration doit encore examiner et accepter la reprise.

Aucune titularité n'est transférée automatiquement au jour 30.

## 12.4 Notification Administration

Exemple :

> **Demande de reprise de foyer**  
> Mariama Diallo demande la reprise du foyer de Mamadou Diallo pour décès déclaré du titulaire.

L'administration peut :

- accepter ;
- refuser ;
- demander les vérifications prévues par la future procédure.

Toute décision doit être auditée.

## 12.5 Si le titulaire refuse

Si le titulaire clique **Refuser la demande** :

- la reprise n'est pas accordée automatiquement ;
- la demande devient contestée/refusée selon le workflow retenu ;
- l'administration voit le refus ;
- aucune permission du foyer n'est transférée.

## 12.6 Ce qui est transféré après validation

Le nouvel adulte devient titulaire du foyer et peut gérer :

- les profils mineurs existants ;
- la composition future du foyer selon les règles actives ;
- les paiements futurs du foyer ;
- les parcours Tuteur attachés aux mineurs.

## 12.7 Ce qui n'est jamais transféré

Le nouveau titulaire ne reçoit jamais automatiquement :

- les identifiants de connexion du défunt ;
- ses messages privés ;
- ses conversations ;
- son historique pédagogique personnel ;
- ses moyens de paiement enregistrés ;
- ses documents KYC ;
- ses données privées sans rapport avec la gestion du foyer.

Il s'agit d'une **succession de titularité du foyer**, pas d'une prise de contrôle du compte personnel.

## 12.8 Anti-abus

Prévoir au minimum côté contrat futur :

- une seule demande active ;
- idempotence ;
- traçabilité ;
- refus du titulaire ;
- décision Admin ;
- aucun transfert client-side ;
- aucune décision automatique fondée uniquement sur l'inactivité du compte.

---

# 13. Titulaire suspendu, supprimé ou inaccessible

Une suspension ou une suppression technique ne prouve jamais un décès.

Le parcours « reprise du foyer » reste fondé sur un **décès déclaré**.

Ne pas promouvoir automatiquement le conjoint parce que :

- le titulaire ne s'est pas connecté ;
- le titulaire est suspendu ;
- le compte est verrouillé ;
- un paiement a échoué.

Les autres procédures exceptionnelles relèvent de l'Administration et ne doivent pas être inventées dans `05_ELEVE_ADULTE`.

---

# 14. Émancipation à 18 ans : préserver l'existant

Le parcours d'émancipation existe déjà dans le produit et ne doit pas être réinventé.

Contrat fonctionnel à préserver :

1. le profil atteint 18 ans ;
2. il peut demander son émancipation ;
3. le titulaire reçoit la demande ;
4. le titulaire accepte ou refuse selon le parcours existant ;
5. en cas d'acceptation, l'élève devient un adulte autonome avec l'interface standard adulte ;
6. l'identité pédagogique reste la même ;
7. l'âge change dans les informations de base ;
8. historique, progression, classe, travail et solde sont conservés ;
9. aucune nouvelle identité élève n'est créée ;
10. l'adulte émancipé récupère les capacités du compte adulte prévues par le produit, notamment ses paiements personnels ;
11. il peut ensuite, comme tout adulte autonome, créer son propre foyer et utiliser sa place conjoint/conjointe selon les règles du présent document.

Important :

> Un enfant émancipé ne devient jamais « le second adulte conjoint » du foyer parental.

Son autonomie produit est distincte de la place conjugale.

---

# 15. Effets sur les autres rôles

## 15.1 Enseignant

Aucun impact visible.

L'enseignant ne doit jamais recevoir :

- information de séparation ;
- état du forfait famille ;
- identité du conjoint ;
- réduction ;
- demande héritage ;
- historique des rattachements.

Une séparation familiale ne retire pas un élève de sa classe.

## 15.2 Élève adulte

Doit pouvoir être :

- adulte seul ;
- titulaire de foyer ;
- second adulte invité ;
- élève + titulaire simultanément ;
- élève + second adulte simultanément.

L'espace Élève reste indépendant de l'espace Tuteur/Foyer.

## 15.3 Tuteur

Le titulaire reste l'unique gestionnaire des mineurs.

Le second adulte n'obtient pas le rôle Tuteur par simple rattachement.

## 15.4 Administration

Deux futurs types de dossiers distincts sont à prévoir :

1. **Validation d'un remplacement du second adulte**
2. **Demande de reprise du foyer après décès déclaré du titulaire**

Ces dossiers ne doivent pas être fusionnés avec le KYC `ADM-02`.

L'administration ne doit voir que les informations nécessaires à la décision.

## 15.5 Finance

Finance décidera plus tard :

- prix ;
- réduction famille ;
- seuil d'éligibilité ;
- date d'effet ;
- validité des offres ;
- impact commercial d'une séparation ;
- crédits ;
- remboursement ;
- cumul avec gratuité/bourse.

Le présent document ne fixe aucune de ces valeurs.

---

# 16. Matrice de permissions frontend

| Action | Titulaire | Second adulte | Mineur | Enseignant | Admin |
|---|---:|---:|---:|---:|---:|
| Voir son propre espace élève | Oui si élève | Oui si élève | Oui selon interface | Non | Selon admin, hors ce flux |
| Ajouter un profil mineur | Oui | Non | Non | Non | Non en libre-service |
| Inviter le second adulte | Oui | Non | Non | Non | Non |
| Annuler une invitation en attente | Oui | Non | Non | Non | Selon support futur |
| Quitter le forfait | Sans objet | Oui | Non | Non | Non |
| Retirer le second adulte | Oui | Non | Non | Non | Exception future |
| Initier une recharge foyer | Oui | Non | Non | Non | Selon Finance |
| Voir données pédagogiques du conjoint | Non | Non au-delà des siennes | Non | Selon classe seulement | Selon capacités |
| Voir données pédagogiques des mineurs | Oui selon rôle Tuteur | Non au MVP | Son propre profil | Selon classe | Selon capacités |
| Demander reprise du foyer | Non | Oui | Non | Non | Reçoit et décide |
| Valider remplacement adulte | Non | Non | Non | Non | Oui |
| Valider reprise du foyer | Non | Non | Non | Non | Oui |

Cette matrice est une cible de permissions. Ne pas l'implémenter par masquage de boutons seulement.

---

# 17. Contrat sécurité pour Claude Code

## FRONTEND ONLY

Pendant la vague actuelle :

- ne pas créer de migration ;
- ne pas créer de nouvelle RLS ;
- ne pas créer de RPC ;
- ne pas inventer de table `families`, `spouses`, `inheritance_requests`, etc. comme si elle existait ;
- ne pas modifier l'auth pour faire fonctionner une maquette ;
- ne pas coder de remise ;
- ne pas coder de prix ;
- ne pas coder de délai côté client comme autorité métier ;
- ne pas coder de mutation de rôle réelle depuis Flutter.

Le frontend peut :

- représenter les surfaces ;
- représenter les états ;
- préparer les view models ;
- déclarer les contrats nécessaires ;
- utiliser des fixtures isolées en démonstration ;
- marquer les dépendances serveur manquantes.

## Principes de sécurité futurs obligatoires

Quand le backend sera explicitement autorisé :

- le client ne peut jamais s'attribuer le rôle titulaire/Tuteur ;
- le client ne peut jamais modifier directement son foyer ;
- les délais 60/120 jours sont décidés par le serveur ;
- l'éligibilité de genre est décidée par le serveur ;
- le nombre d'adultes est contrôlé côté serveur ;
- une personne ne peut appartenir qu'à un foyer actif ;
- aucune réduction n'est accordée par une condition Flutter ;
- les mutations sont idempotentes ;
- les décisions sensibles sont auditées ;
- tests d'accès horizontal obligatoires ;
- changement de profil sur le même appareil sans fuite de cache ;
- réponse réseau tardive ne doit jamais rattacher un adulte après annulation ;
- aucun identifiant ou donnée privée d'un autre foyer ne doit être devinable par invitation.

---

# 18. États critiques à maqueter ou spécifier

Les surfaces suivantes doivent être couvertes dans les specs concernées, même si toutes ne reçoivent pas une maquette dédiée :

1. Adulte seul
2. Titulaire sans conjoint
3. Invitation conjoint en attente
4. Invitation expirée
5. Invitation annulée
6. Conjoint actif
7. Conjoint quitte le foyer
8. Titulaire retire le conjoint
9. Cooldown 60 jours
10. Nouvelle demande après 60 jours
11. Validation Admin en attente
12. Validation Admin refusée
13. Second départ
14. Cooldown 120 jours
15. Troisième départ et suivants, toujours 120 jours
16. Demande de reprise du foyer
17. Demande refusée par le titulaire
18. Jour 30 sans réponse, attente Admin
19. Reprise validée
20. Reprise refusée
21. Adulte invité déjà dans un autre foyer
22. Erreur réseau pendant une mutation
23. Double clic / double soumission
24. Notification non délivrable en push mais visible dans l'application
25. Émancipation d'un élève devenu adulte sans perte de données

---

# 19. Copywriting à conserver

## Entrée famille

**Ajouter ma famille**

> Inscrivez vos enfants et invitez un conjoint ou une conjointe à rejoindre votre forfait famille. Votre espace élève reste inchangé.

## Titulaire homme

**Ajouter une conjointe**

> Votre conjointe utilisera son propre compte. Elle ne pourra pas gérer votre foyer ni les profils élèves que vous avez créés.

## Titulaire femme

**Ajouter un conjoint**

> Votre conjoint utilisera son propre compte. Il ne pourra pas gérer votre foyer ni les profils élèves que vous avez créés.

## Sortie du second adulte

**Quitter le forfait famille**

> Votre compte, vos cours, votre historique et votre solde restent disponibles. Le rattachement au forfait famille prendra fin.

## Retrait par le titulaire

**Retirer ma conjointe** / **Retirer mon conjoint**

> Son compte, ses cours, son historique et son solde ne seront pas supprimés.

## Cooldown

**Nouvelle invitation indisponible**

> Une nouvelle demande pourra être déposée à partir du {date}. Elle devra ensuite être validée par l'administration.

## Reprise du foyer

**Demande de reprise du foyer**

> Utilisez cette démarche si le titulaire du foyer est décédé. La demande sera signalée au compte concerné et examinée par l'administration.

---

# 20. Points volontairement ouverts

Ne pas transformer ces points en décisions implicites :

1. Montant ou pourcentage de réduction famille
2. Nombre d'élèves actifs nécessaire pour obtenir une réduction
3. Formule de crédit
4. Durée de validité du solde
5. Date exacte de fin d'un avantage tarifaire après sortie
6. Remboursement commercial
7. Frais de paiement
8. Fournisseur de paiement
9. Traitement fiscal/comptable
10. Preuve exigée par l'Administration pour une reprise après décès
11. Procédure de correction d'une erreur initiale de genre
12. Transfert volontaire de titularité entre adultes vivants
13. Attribution future éventuelle de droits Tuteur au conjoint sur les mineurs

Ces sujets appartiennent à Finance, Administration, Onboarding ou Sécurité selon le cas.

---

# 21. Recette fonctionnelle minimale

Claude doit préparer les tests/contrats suivants sans inventer le backend :

- un adulte `Moi uniquement` peut ouvrir le point d'entrée `Ajouter ma famille` sans perdre son profil élève ;
- le titulaire voit un libellé conjoint/conjointe cohérent avec son genre enregistré ;
- un seul second adulte peut être actif ;
- une seule invitation peut être en attente ;
- une invitation annulée ne déclenche aucun cooldown ;
- un départ effectif déclenche 60 jours au premier remplacement ;
- un nouveau départ ultérieur déclenche 120 jours ;
- le délai ne dépasse jamais 120 jours ;
- un refus Admin ne redémarre pas le délai ;
- le conjoint sortant conserve son compte et son solde ;
- le titulaire est notifié si le conjoint quitte ;
- le conjoint est notifié s'il est retiré ;
- le titulaire peut préparer une recharge nominative pour tous les bénéficiaires autorisés, conjoint inclus ;
- chaque bénéficiaire conserve son propre solde ;
- aucun prix/remise n'est calculé localement ;
- un enseignant ne voit aucun détail familial ;
- le second adulte ne peut pas ajouter un enfant ;
- une demande de reprise du foyer notifie le titulaire et l'Admin ;
- le titulaire peut refuser la demande ;
- après 30 jours sans réponse, aucune reprise automatique n'a lieu ;
- une validation Admin reste obligatoire ;
- la reprise transfère la titularité du foyer, pas le compte privé de l'ancien titulaire ;
- l'émancipation conserve l'identité pédagogique et les données de l'élève.

---

# 22. Handoff immédiat à Claude Code

1. Ajouter ce document aux décisions actives du chantier frontend.
2. Référencer ces décisions depuis `05_ELEVE_ADULTE.md`.
3. Conserver une note explicite pour la future reprise Onboarding/Famille.
4. Prévoir les surfaces et états nécessaires dans les maquettes Élève adulte et Tuteur sans lancer de backend.
5. Ne pas modifier le moteur financier.
6. Ne pas redéfinir l'émancipation existante, seulement vérifier que `05_ELEVE_ADULTE` reste compatible.
7. Signaler toute contradiction avec le code actuel au lieu de la résoudre silencieusement.
8. Pour toute capacité serveur absente, créer une dépendance/contract request documentée plutôt qu'un comportement local.
9. Ne pas laisser les anciennes mentions « proches adultes » ou permissions familiales larges contredire ce document dans les instructions actives.
10. Avant toute future implémentation backend de ce domaine, exiger une revue sécurité séparée et des tests d'accès horizontal.

---

# 23. Sources internes à relire par Claude

- `DOSSIER_POUR_CHATGPT.md`
- `REWAYAH_TUTEUR_SOLDES_RECHARGES_ACCES_V1.md`
- `07_MEMOIRE_PEDAGOGIE_FINANCE.md`
- `06_SPEC_FONCTIONNELLE_MVP.md`
- `03_ADMIN_VALIDATION_DOSSIERS(1).md`
- `REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md`
- décisions récentes du directeur sur `Moi uniquement / Moi et ma famille`
- implémentation existante de l'émancipation

En cas de contradiction, les décisions explicites du présent document priment pour le modèle foyer/conjoint, sans autoriser une modification backend pendant la phase FRONTEND ONLY.
