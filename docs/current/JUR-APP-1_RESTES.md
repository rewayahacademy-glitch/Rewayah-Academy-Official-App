# JUR-APP-1 : ce qui reste, et pourquoi

Étape JUR-APP-1 : porter dans l'app les textes juridiques validés le 02/10/2026
(pilotage `14_controleur/juridique/SIGNATURES_2026-10-02.md`). Les textes
portés (E-1, E-2, A3, E1, clause enseignant, case art. 9) le sont mot pour mot.
Ce fichier liste ce qui n'est **pas** porté, avec la raison (et, depuis le
05/10/2026, ce qui a été porté ensuite : sections 1 et 4). Rien n'y est
inventé.

## 1. Politique de contrôle des enseignants (partie B) : fait le 05/10/2026 (ASSETS-DIR-1)

La clause signée par l'enseignant dit : « La politique de contrôle, jointe à ce
contrat et disponible dans votre espace, explique tout. En signant, vous
confirmez l'avoir reçue. »

**Fait (décidé par délégation le 05/10/2026).** Le directeur a fourni, par ses
e-mails Companies House et Rapid Formations, les quatre valeurs de la section
10. Source : pilotage `14_controleur/juridique/COORDONNEES_LEGALES.md` (et la
section 10 déjà remplie dans `POLITIQUE_CONTROLE_ENSEIGNANTS.md`) :

- `{numero_societe}` : 16624644, immatriculée en Angleterre et au pays de
  Galles ;
- `{adresse_siege}` : 71-75 Shelton Street, Covent Garden, Londres WC2H 9JQ,
  Royaume-Uni ;
- `{contact_confidentialite}` : support@rewayahacademy.com, une seule
  constante, `InformationControle.contactConfidentialite`
  (`lib/features/salle_seance/information_controle.dart`), reprise par E-2 et
  par la section 10 ;
- `{representant_ue}` : « pas encore désigné ; l'application ne s'ouvre pas
  aux familles de l'Union européenne avant sa désignation ».

Ce qui est dans le code, dans un même commit :

1. la partie B portée mot pour mot (`t.contrat.politique`, sections 1 à 10,
   listes et passages en gras gardés), en lecture partagée
   (`AppBottomSheet.ouvrirLecture`, `ouvrirPolitiqueControle` dans
   `lib/features/dossier/politique_controle.dart`), sans route propre ; seul
   écart : le renvoi interne « (voir `RGPD_UE.md`) » de la section 10 n'est pas
   porté (document du pilotage que l'enseignant ne peut pas ouvrir) ;
2. le lien « Lire la politique de contrôle » (`LienFleche`) sous la clause du
   contrat (`signature_page.dart`) et dans le profil de l'enseignant, section
   des contrats (`profil_enseignant_page.dart`), lisible quel que soit l'état
   de la lecture des acceptations ;
3. `VersionsContrat.politiqueControlePubliee` vaut `true` : hors
   démonstration, un vrai enseignant lit et signe la version `2026-10-jur`
   (clause, lien, case art. 9) ;
4. tests : `test/features/dossier_test.dart` (« hors démonstration, politique
   de contrôle publiée… », garde-fou injectable conservé avec
   `politiquePubliee: false`), `test/features/politique_controle_test.dart`
   (texte, section 10, 320 et 1440, texte 100 et 200 %, clair et sombre, aucun
   mot coupé, dernière phrase atteinte), `test/features/profil_enseignant_test.dart`
   (entrée du profil) ; captures `jur_app1_contrat_enseignant*.png` régénérées
   et `jur_app1_politique_controle.png` ajoutée.

Une adresse e-mail est plus large que l'écran à 320 et texte 200 % : elle ne
passe à la ligne qu'après « @ » et avant ses points intérieurs (espace sans
chasse invisible, `coupuresAdresse`), décidé par délégation le 05/10/2026.

**Conditions restantes AVANT fusion dans `main` :**

- alias support@rewayahacademy.com : **créé par le directeur le 05/10/2026** (fait) ;
- **représentant dans l'UE avant toute ouverture aux familles de l'UE** :
  remplacer alors la phrase de la section 10 (`t.contrat.politique.s10.texte`)
  par son nom et son adresse, nouvelle version du contrat enseignant à prévoir ;
- inscription à l'ICO : **non bloquante** (décision du directeur, 05/10/2026) ;
  il s'inscrit après la mise en production et les tests (`COORDONNEES_LEGALES.md`).

Les enseignants ayant signé `2026-09` entre-temps ne sont pas reconvoqués
d'eux-mêmes (`etat_dossier()` ne filtre pas la version, voir l'en-tête de
`versions_contrat.dart`) : re-signature de `2026-10-jur` **décidée le 05/10/2026**
(décisions par délégation, tableau DIR-REP-1) ; écran de re-signature à prévoir.

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

Porté mot pour mot et **visible depuis le 05/10/2026** (ASSETS-DIR-1, décidé
par délégation) : `InformationControle.contactConfidentialite` vaut
support@rewayahacademy.com (source : pilotage `COORDONNEES_LEGALES.md`), la
même constante que la section 10 ci-dessus. Le lien « En savoir plus » de
l'élève ouvre donc E-2. L'alias
support@rewayahacademy.com existe depuis le 05/10/2026.

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
