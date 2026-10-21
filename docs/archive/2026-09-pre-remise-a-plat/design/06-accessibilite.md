# 06 — Accessibilité

Le produit sert un enfant de six ans, un parent qui lit mal le français, un
enseignant sur un téléphone d'entrée de gamme en Guinée, et un opérateur qui
passe la journée sur un tableau dense. Aucun de ces quatre n'est un cas limite.

## 1. Le contraste est mesuré, jamais apprécié

**Tous les jetons de couleur du produit sont mesurés**, et les chiffres sont
écrits dans `docs/produit/design-tokens.md` §1. Aucun jeton n'entre dans la
palette sans sa mesure.

Seuils appliqués :

| Élément | Seuil | Règle |
| :--- | :-: | :--- |
| Texte courant | 4,5:1 | Sans exception |
| Texte de 24 pt et plus, ou 19 pt gras | 3:1 | Employé nulle part par défaut : on vise 4,5 partout |
| Contrôle, contour porteur de sens, icône porteuse de sens | 3:1 | C'est ce que `borderStrong` garantit |
| Élément décoratif | aucun | Et il ne porte donc **aucun** sens |

Le mécanisme qui tient la règle n'est pas la vigilance : c'est l'API. Le thème
n'expose que des paires `(fond, encre)`, et les encres destinées aux fonds
clairs passent par un type qui ne peut pas servir de fond. Une paire illisible
est structurellement impossible à écrire.

**Le piège déjà payé** : `surfaceAlert.applyTo(...)` posé sur la page écrivait en
blanc, puisque le blanc est l'encre prévue pour le fond rouge. Blanc sur le fond
général mesure 1,19:1 : le message existait dans l'arbre et n'existait pas à
l'écran. D'où `inkAlert`, qui est l'encre rouge pour fond clair. La même logique
vaut pour les trois autres familles sémantiques.

## 2. Cibles et gestes

| Mode | Cible minimale | Écart minimal entre deux cibles |
| :--- | :-: | :-: |
| Standard | 44 | 8 |
| Enfant | 72 | 12 |

Déjà porté par `AppMetriques`, et par `materialTapTargetSize: padded` pour les
widgets Material non enrobés.

- Aucun geste n'est le **seul** chemin vers une action. Un glissement pour
  supprimer double toujours un bouton dans un menu.
- Aucun appui long comme seul chemin. Il est découvrable par personne.
- Aucune zone cliquable plus petite que sa cible visible ; l'inverse est permis
  et souhaitable.

## 3. Taille de texte

L'application doit tenir jusqu'à **200 %** de la taille système sans perte de
fonction. Ce qui implique :

- Aucune hauteur fixe sur un conteneur qui porte du texte.
- Aucun `maxLines: 1` sur un libellé porteur de sens. Un titre peut être borné,
  un état ne peut pas.
- Les boutons grandissent avec leur texte, ils ne le rognent pas.
- Une ligne de tableau dense peut passer en deux lignes ; elle ne peut pas
  couper un mot au milieu.

Le facteur d'échelle du mode enfant, 1,2, **s'ajoute** à la préférence système.
Il ne la remplace pas et ne la plafonne pas.

## 4. Lecteur d'écran

- Toute icône seule porte un label sémantique. Une icône décorative est
  explicitement exclue de l'arbre, jamais laissée sans label.
- L'ordre de lecture suit l'ordre visuel. Une grille Bento qui se lit dans le
  désordre est mal construite, ce n'est pas au lecteur d'écran de s'adapter.
- Un état qui change à distance est annoncé : le passage d'un cours en direct,
  l'arrivée d'un rapport, l'alerte de prière.
- Un champ en erreur annonce son message, pas seulement sa couleur.
- Le bandeau permanent de la salle est lu **une fois à l'entrée**, pas à chaque
  reconstruction : c'est une information, pas une alerte répétée.

## 5. RTL et bilinguisme

L'arabe est la langue principale du produit. Il n'y a donc pas de « support
RTL », il y a un produit bidirectionnel.

- Aucun `EdgeInsets` ni alignement non directionnel dans les écrans.
- Les icônes directionnelles se miroitent : retour, suivant, chevrons de liste,
  flèche de partage.
- **Ne se miroitent pas** : l'horloge, la progression du temps, les logos, les
  icônes de média (lecture, pause), les chiffres.
- Un texte mixte français-arabe reste lisible sans que l'écran choisisse sa
  police : la police latine déclare la police arabe d'interface en repli.
- Les chaînes ne se concatènent jamais. Une phrase construite par morceaux est
  intraduisible et se casse en RTL. Tout passe par `slang`, avec des paramètres
  nommés.

## 6. Mode d'interface, et pourquoi ce n'est pas un « mode enfant »

Le vocabulaire compte. Le mode simplifié sert :

- un enfant de six ans ;
- une personne âgée ;
- une personne peu à l'aise avec le numérique ;
- quiconque a besoin de moins de décisions à l'écran.

L'âge fixe la valeur **par défaut**, il ne définit pas le mode. Un tuteur peut le
changer enfant par enfant (`TUT-05`), et le seuil vit dans `app_config`, pas dans
le code (ADR-009, ADR-016).

Conséquence pour l'implémentation : ne jamais écrire de logique métier sur
`age < 8`. La logique se lit sur le mode, et le mode se lit sur le profil.

### Le zéro-lecture

Pour les moins de huit ans, **le libellé parlé compte plus que le texte**. Le
composant `AudioLabel` retrouve un fichier son à partir de la même clé que le
texte, pour que les deux ne puissent pas diverger. Un écran de niveau B qui
présente une décision sans libellé parlé n'est pas fini.

⚠ Les fichiers son ne sont pas enregistrés : `assets/audio/fr/` est vide. C'est
une dette connue, pas un oubli de conception.

## 7. Réduction du mouvement

Traitée dans `04-systeme-mouvement.md` §5. Le point à retenir ici : une
animation qui porte du sens est **remplacée**, pas supprimée. La pulsation du
bloc « cours dans moins de 5 minutes » devient une bordure fixe.

## 8. Ce qui reste ouvert

| Sujet | État |
| :--- | :--- |
| Enregistrement des libellés audio français | Non fait. `assets/audio/fr/` vide |
| Traduction arabe de l'interface | Déclarée, vide. `strings_ar.g.dart` existe |
| Test au lecteur d'écran sur appareil réel | Jamais fait : aucun appareil Android disponible sur ce poste |
| Contraste en mode sombre | **Fait au lot T3.** Toutes les mesures ont été refaites, aucune transposée depuis le clair — `design-tokens.md` §12, `AppPalette.sombre()`, `test/theme/contraste_sombre_test.dart` |
