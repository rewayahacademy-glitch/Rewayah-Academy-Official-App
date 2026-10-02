# RGPD (UE) : s'applique-t-il ? Représentant (art. 27) ? DPO (art. 37) ?

**Statut.** Relecture juridique par un agent, 02/10/2026. Répond au point « à faire » n° 10 de `../DPIA_CONTROLEUR.md` et aux points 3 et 14 de `09_consentements/CHARTE.md` §8.

**Faits retenus.** Rewayah Academy est une LTD anglaise, sans établissement dans l'Union européenne. Aucun utilisateur au Royaume-Uni. Des élèves, parents et enseignants sont dans l'UE (France notamment), d'autres en Amérique du Nord, en Afrique, au Moyen-Orient. Données stockées chez Cloudflare, Europe de l'Ouest.

**Sources.** RGPD art. 3, 27, 37, 38, 39 ; UK GDPR art. 37 ; lignes directrices de l'EDPB 3/2018 sur le champ d'application territorial (art. 3) ; lignes directrices du groupe de l'article 29 sur les DPO (WP 243 rév. 01), reprises par l'EDPB ; guide de l'ICO « Data protection officers ».

---

## 1. Le RGPD s'applique-t-il ? Oui

L'art. 3(2) applique le RGPD à un responsable établi hors de l'UE quand il traite les données de personnes **qui se trouvent dans l'UE** et que le traitement est lié :

- **(a) à une offre de services** à ces personnes, payante ou non. C'est le cas : l'académie propose ses cours à des familles de l'UE, en français, et les accepte. Les lignes directrices 3/2018 citent comme indices la langue, la monnaie, et le fait de viser expressément des clients d'un État membre. Un seul indice clair suffit quand l'offre est délibérée.
- **(b) au suivi du comportement** de ces personnes dans l'UE. Le contrôle des enseignants situés dans l'UE, et l'évaluation de la progression des élèves, en relèvent aussi.

**Conclusion : le RGPD s'applique, en plus du UK GDPR, pour toute personne qui se trouve dans l'UE.** Les deux textes sont presque identiques ; les mesures de la DPIA répondent aux deux. Les différences utiles : pas d'annexe 1 du DPA 2018 côté UE (voir `ART9_RELIGION.md`), et l'âge du consentement numérique de chaque pays (15 ans en France).

Le stockage en Europe de l'Ouest ne change rien à cette réponse : c'est la présence des personnes dans l'UE qui compte, pas le lieu des serveurs.

## 2. Faut-il un représentant dans l'UE (art. 27) ? Oui

L'art. 27 oblige le responsable visé par l'art. 3(2) à désigner par écrit un représentant dans un État membre où se trouvent des personnes concernées. Il y a une seule exception (art. 27(2)(a)) : un traitement **occasionnel**, qui ne porte pas **à grande échelle** sur des catégories particulières de données, et qui ne crée pas de risque.

L'exception ne s'applique pas : le traitement est **régulier** (cours chaque semaine), il porte sur une **donnée religieuse** (art. 9) et sur des **enfants**, et la DPIA relève des risques élevés avant mesures. Les trois conditions de l'exception sont cumulatives ; une seule qui manque suffit.

**Décision : désigner un représentant dans l'UE avant d'ouvrir l'application aux familles de l'UE.**

Recommandation pratique :

1. Le choisir **en France** (ou dans le pays de l'UE où vivent le plus d'utilisateurs). Il doit pouvoir répondre en français et en anglais.
2. Prendre un **prestataire spécialisé** « EU GDPR representative » plutôt qu'un proche : il faut un mandat écrit, une disponibilité réelle et une tenue du registre (art. 30) consultable par l'autorité. Le coût annuel est en général modeste pour une petite structure ; demander deux devis.
3. Écrire son nom et son adresse dans la politique de confidentialité, dans les textes A1 et dans `INFO_ELEVES_PARENTS.md` (champ `{representant_ue}`).
4. Lui donner une copie du registre des traitements et de la DPIA.
5. Le représentant ne remplace pas l'académie : elle reste responsable. Il n'y a pas de « guichet unique » pour un responsable hors UE ; chaque autorité nationale peut être saisie par ses résidents.

## 3. Faut-il un DPO (art. 37) ? Pas obligatoire au lancement, à revoir à un seuil

L'art. 37(1) (identique dans le RGPD et le UK GDPR) impose un DPO quand les **activités de base** du responsable consistent :

- (b) en un **suivi régulier et systématique à grande échelle** des personnes ; ou
- (c) en un traitement **à grande échelle** de catégories particulières de données (art. 9).

**Activités de base : oui.** Enseigner le Coran implique la donnée religieuse ; le contrôle est régulier et systématique. Le seul critère qui reste ouvert est la **grande échelle**.

**Grande échelle : pas au lancement.** Le WP 243 ne donne pas de chiffre. Il demande de regarder le nombre de personnes (en valeur ou en proportion de la population), le volume de données, la durée et l'étendue géographique. Il donne comme exemple de traitement qui n'est **pas** à grande échelle celui d'un professionnel isolé (un médecin, un avocat). Une académie qui démarre, avec quelques Classes, en est proche. Le volume réel n'est pas encore connu (point « à faire » n° 3 de la DPIA).

**Décision :**

1. **Pas de DPO obligatoire à l'ouverture.** L'analyse est écrite ici, ce que le WP 243 recommande de faire quand on conclut qu'un DPO n'est pas requis.
2. **Nommer un « référent protection des données »** (pas sous le titre « DPO », qui entraînerait toutes les obligations des art. 38 et 39) : une personne de l'équipe, joignable à `{contact_confidentialite}`, qui reçoit les demandes de droits et tient le registre.
3. **Seuil de revue, tranché ici** : revoir la question dès que l'un de ces points est atteint : **1 000 élèves actifs**, ou des élèves dans **plus de 10 pays**, ou l'ajout d'un enregistrement vidéo, ou un usage des rapports pour la paie. À ce seuil, désigner un DPO, interne ou externe (un DPO externe mutualisé est courant et peu coûteux).
4. Le chiffre de 1 000 est un **choix de prudence**, pas un seuil légal : un avocat pourrait le placer plus haut ou plus bas. Il est volontairement bas, car il s'agit d'enfants et d'une donnée religieuse.

## 4. Autres points de l'UE à retenir

| Point | Décision |
|---|---|
| Âge du consentement numérique | Il ne sert que pour les accords facultatifs (art. 8). Pour une famille de l'UE, on applique l'âge de son pays (15 ans en France). La charte le prévoit (principe 12). |
| Transferts depuis l'UE vers le Royaume-Uni | Couverts par la décision d'adéquation de la Commission européenne pour le Royaume-Uni. **À vérifier par l'équipe** : sa date d'échéance et son renouvellement, à la date de l'ouverture. |
| Transferts vers des contrôleurs situés hors Royaume-Uni et hors EEE | Si le contrôleur est un salarié de l'académie, il fait partie du responsable et l'accès à distance n'est en général pas analysé comme un transfert à un tiers. S'il est indépendant, c'est un destinataire distinct : un transfert encadré (IDTA de l'ICO ou clauses types avec l'addendum britannique) est nécessaire. **Choix tranché** : tant que ce cadre n'est pas signé, n'approuver comme contrôleurs que des personnes situées au Royaume-Uni, dans l'EEE ou dans un pays reconnu adéquat, ou liées à l'académie par un contrat de travail. Point où un avocat reste préférable. |
| Autorité de contrôle | ICO pour le Royaume-Uni ; pour l'UE, l'autorité du pays de chaque plaignant (pas de chef de file). |

## 5. Résumé

| Question | Réponse |
|---|---|
| Le RGPD s'applique ? | Oui, art. 3(2)(a) et (b), pour les personnes dans l'UE |
| Représentant UE (art. 27) ? | Oui, obligatoire ; prestataire en France, avant l'ouverture aux familles de l'UE |
| DPO (art. 37) ? | Non au lancement ; référent nommé ; revue à 1 000 élèves actifs ou plus de 10 pays |
