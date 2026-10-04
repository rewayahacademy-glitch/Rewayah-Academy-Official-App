# Relecture DASH-MA-PROD : verdict REFUSEE

Le lot est refusé pour un seul défaut majeur : hors ligne, l'Accueil affiche un bouton « Réessayer » grisé. Les quatre autres défauts sont mineurs. Les outils ne montrent aucune régression.

## Ce qui est solide

- **Routage**
  - `/eleve` passe par `AccueilEleveSelonPresentation`. Le choix se lit dans `modeAccessibiliteActifProvider` (une capacité, pas un rôle).
  - `/eleve/aide` est protégée par la garde de préfixe `/eleve`.
- **Port neutre de production**
  - `CapaciteIndisponible('MA-BR')`, sans retentative automatique.
  - Aucune donnée inventée (D10).
  - En production, l'Accueil MA affiche donc l'état « Prochaine séance pas encore affichée ici », avec « Voir ma classe ».
- **Cinq états** : chargement, contenu, vide, erreur, indisponible, plus le hors ligne. Le Coran et l'aide restent visibles dans tous les états.
- **Composants partagés** (ActionPrincipale, EmptyState, EtatSysteme)
  - Ils passent à `TexteSansCoupure`, et le médaillon se place au-dessus du texte au-delà de 130 %.
  - La contre-épreuve prouve que ces changements sont nécessaires : 6 échecs sur l'ancien code.
  - 1334 tests d'autres écrans qui utilisent ces composants passent toujours.
- **Libellés** : les 6 nouveaux libellés sont déclarés dans `tool/libelles_sources.json`, avec la mention « à faire valider par le directeur ».
- **Outils**
  - `dart analyze --fatal-infos` : aucun problème.
  - verifier_jetons : 39 violations, comme sur la base (listes identiques).
  - verifier_revue : 1627 violations, comme sur la base (listes identiques).
- **Contre-épreuves** : ancienne route, 31 échecs ; `_insecable` neutralisé, 2 échecs.

## Défauts

### Majeur

**Bouton « Réessayer » grisé hors ligne**
- **Où** : `accueil_accessibilite.dart:293`. Le lot passe `horsLigne` à `CarteSession` sans `onReessayer`.
- **Effet** : `carte_session.dart:426-440` rend « Réessayer » avec onPress nul, donc grisé. `carte_session.dart:209-211` masque alors « Voir ma classe ».
- **Règle violée** : aucun bouton grisé. L'exception D9 ne couvre que « Rejoindre » inerte hors ligne.
- **Preuves**
  - Capture `ma_prod_horsligne_390_clair.png`.
  - Sonde dans le test : `Réessayer onPress=false`.
- **Test manquant** : le test hors ligne ne vérifie pas ce point.

### Mineurs

1. **Deux colonnes supprimées sans validation**
   - Ce lot remplace la composition en deux colonnes (à partir de 840 / facteur) par une seule colonne.
   - Q3 porte sur une colonne face au Bento ; la fiche ELV-02-MA (l.358) garde les deux colonnes.
   - C'est un écart à faire trancher par le directeur.
2. **« ; » orphelin à 320 px x2** dans `videPhrase` (`fr.i18n.json:663`). Il faut une espace insécable avant « ; ».
3. **Commentaire faux** : `accueil_accessibilite.dart:217` annonce U+2011, alors que le code insère « - » suivi de U+2060.
4. **Durée scindée** : « 3 h / 28 » sur deux lignes à 320 px x2. Le composant CarteSession est antérieur au lot.

## Captures vues

contenu 320x2 clair, erreur 320x2 sombre, contenu 1440 clair, indisponible 390 sombre, vide 320x2 clair, aide 320x2 sombre, hors ligne 390 clair.

## Côté serveur, consigné sans bloquer

La source réelle de l'Accueil MA (ligne MA-BR, BR-1) n'existe pas encore.

## Pour accepter

1. Hors ligne :
   - soit passer un `onReessayer` réel ;
   - soit ne pas transmettre `horsLigne` et garder « Voir ma classe » actif, avec le bandeau de PageShell.
   - Ajouter un test qui échoue sur le code actuel : aucune ActionPrincipale avec onPress nul hors ligne.
2. Remplacer l'espace avant « ; » par une espace insécable.
3. Corriger le commentaire U+2011.
4. Faire confirmer par le directeur l'abandon des deux colonnes, ou les rétablir.

## Contre-revue adverse

Verdict confirmé : oui. Verdict final retenu : **REFUSEE**.

Le refus tient. J'ai vérifié le défaut majeur sur un worktree détaché à ef272b74 (origin/corrections/c2-ma-prod), retiré depuis.

1. Dans lib/features/accueil_eleve/accueil_accessibilite.dart, vers la ligne 286, CarteSession reçoit `horsLigne: horsLigne` mais aucun `onReessayer`. Dans carte_session.dart:426-440, quand `e.reessayer` est vrai, une ActionPrincipale « Réessayer » est rendue avec `onPress: widget.onReessayer`, qui vaut donc null. Dans carte_session.dart:209-211, `actionHorsEntree` (« Voir ma classe ») est masquée quand `emplacement.reessayer` est vrai.

2. La capture ma_prod_horsligne_390_clair.png, que j'ai ouverte, montre bien un « Réessayer » au libellé gris sous « Tu es hors ligne ». « Voir ma classe » n'apparaît pas.

3. Dans docs/current/DASH_STRATEGIE.md (origin/corrections/c2-dash1), la règle D9 se lit : « 0 bouton grisé hors exception ». La seule exception nommée est « Rejoindre », qui reste présent et inerte hors ligne. Un « Réessayer » qui ne relance rien n'est pas couvert. Sur la base af20f6c2, accueil_accessibilite ne passait pas `horsLigne` à CarteSession : le défaut vient donc bien de ce lot, et il part en production avec le montage sur /eleve. Le défaut est majeur, et à lui seul il justifie le refus.

Les points mineurs sont réels aussi :
- La fiche ELV-02-MA (DASH_STRATEGIE l.358) garde « une colonne ; deux à partir de 840 / facteur de texte ». Le lot retire ces deux colonnes.
- Dans fr.i18n.json:663, l'espace avant « ; » est une espace ordinaire, donc sécable. Le point-virgule peut se retrouver seul en début de ligne.
- Le commentaire annonce U+2011, alors que le code fait `replaceAll('-', '-⁠')`.
- Le relecteur a vu « 3 h / 28 » scindé sur la capture contenu 320 x2. Je n'ai pas rouvert cette capture.

Je n'ai trouvé aucun défaut infondé et aucun défaut grave manqué qui changerait le verdict.

