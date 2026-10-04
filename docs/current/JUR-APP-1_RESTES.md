# JUR-APP-1 : ce qui reste, et pourquoi

Étape JUR-APP-1 : porter dans l'app les textes juridiques validés le 02/10/2026
(pilotage `14_controleur/juridique/SIGNATURES_2026-10-02.md`). Les textes
portés (E-1, E-2, A3, E1, clause enseignant, case art. 9) le sont mot pour mot.
Ce fichier liste ce qui n'est **pas** porté, avec la raison. Rien n'y est
inventé.

## 1. Politique de contrôle des enseignants (partie B) : question au directeur

La clause signée par l'enseignant dit : « La politique de contrôle, jointe à ce
contrat et disponible dans votre espace, explique tout. En signant, vous
confirmez l'avoir reçue. »

La partie B de `POLITIQUE_CONTROLE_ENSEIGNANTS.md` est **validée** (« je
valide », 02/10), mais **pas complète** : sa section 10 « Contact » garde
quatre champs non remplis :

- `{numero_societe}` (numéro d'immatriculation de Rewayah Academy Ltd) ;
- `{adresse_siege}` ;
- `{contact_confidentialite}` (le référent données n'est pas nommé, déjà
  ouvert au 02/10) ;
- `{representant_ue}` (représentant dans l'UE, ouvert au 02/10).

L'application ne la joint donc **nulle part** pour l'instant : ni lien depuis
la clause du contrat, ni page dans l'espace enseignant. Elle ne sera portée
qu'avec ses quatre valeurs.

**Conséquence :** tant qu'elle n'est pas publiée, la clause fait confirmer la
réception d'une pièce que l'app ne montre pas. **Ne pas faire signer le contrat
enseignant (version `2026-10-jur`) à un vrai enseignant avant la publication de
la politique.** La doc 08 §14.1 impose de toute façon la publication avant la
première visite réelle.

**Question au directeur :** pouvez-vous fournir le numéro de société, l'adresse
du siège, le contact confidentialité et le représentant dans l'UE (ou
décider d'une formule provisoire écrite par vous pour la section 10) ? Dès
réception, la partie B sera portée mot pour mot en pièce lisible, liée depuis
la clause du contrat et rangée dans l'espace enseignant.

## 2. A0 (information sur la religion, paragraphe « Qui voit » corrigé)

Validé (`CORRECTIONS_A0_A3.md` §1). **Non porté** : aucun écran de
l'application n'affiche A0 aujourd'hui (aucune clé A0 dans
`assets/i18n/fr.i18n.json`, aucun écran du consentement religion dans
`lib/`). Le texte A0 de `09_consentements/TEXTES_V2.md` (version `2026-10-v2`)
n'a jamais été implémenté ; porter la seule correction sans l'écran qui la
porte n'a pas de sens. À faire avec l'écran de consentement A0, au moment où il
est inscrit au catalogue et implémenté.

## 3. P-1 (information des parents ; élève adulte en version « vous »)

Validé (`INFO_ELEVES_PARENTS.md`). **Non porté** : P-1 va « à l'inscription,
après A3 ; politique de confidentialité ». Aucun de ces deux endroits n'existe
dans l'application : l'écran d'inscription du tuteur qui suivrait A3 n'est pas
au catalogue, et l'app n'a pas de page de politique de confidentialité. À faire
avec ces écrans.

## 4. E-2 (élève de 13 à 17 ans)

Porté mot pour mot, mais **caché** tant que `{contact_confidentialite}` manque
(`InformationControle.contactConfidentialite == null`) : pas de texte affiché
avec un trou ou une adresse inventée. Même valeur que la section 10 ci-dessus.

## 5. Phrase « Tu peux aussi appuyer sur Signaler. » de E-1

Portée, mais cachée tant que le bouton « Signaler » de l'élève n'existe pas
dans la salle (écart E16) : le texte suit la réalité.

## 6. Lien « En savoir plus » à 320 de large

À 390 et au-delà, le lien tient sur la ligne de la mention : la salle ne bouge
pas (haut du cours à 100, comme sans lien). Sous environ 385 de large, la
mention seule remplit la ligne (`PermanentNotice`, sans paramètre, ADR-011 :
le lien ne peut pas entrer dans son texte) : le lien passe dessous, avec la
seule hauteur de son texte (16), et le cours descend de 16 (contre 72 avant
correction). Sa cible tactile (72 en guidée) déborde sans prendre de hauteur.
Si le directeur veut zéro à 320, les seules voies restantes sont : cacher le
lien sous cette largeur, ou ouvrir l'ADR-011 pour que la mention porte le lien
dans son texte. **Décision du directeur.**
