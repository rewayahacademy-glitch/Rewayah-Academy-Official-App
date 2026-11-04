# Décision du directeur : la liste est la page (défilement), 01/11/2026

Statut : **décidé**, sans date de fin (« d'ici jusqu'en 2049 »). Prévaut sur tout document antérieur
qui la contredit, y compris `DECISION-LISTES-2026-10-23.md` et `03_DESIGN_SYSTEM_ET_UX.md`.

## Les mots du directeur

> « Le tableau est enfermé dans un cadre de hauteur fixe, qui défile à l'intérieur. C'est ce qui
> coupe la moitié de la page. […] mais je ne savais pas le décrire, je voulais même t'envoyer une
> vidéo pour que tu puisses voir comment la liste disparaît sous un gros header... alors ça il faut
> le supprimer définitivement et marquer partout que cela est interdit dans toute l'app d'ici
> jusqu'en 2049. La liste doit être la page, et partout où il y a du contenu qui a besoin de
> scroll. »

Constat qui l'a déclenchée : Opérations › Classes, au bureau, le 01/11/2026. La table vit dans un
cadre de hauteur fixe sous un en-tête épais ; la première ligne passe sous l'en-tête de colonnes,
la moitié de l'écran ne sert à rien.

## La règle

1. **Interdit, partout, dans toute l'application** : un contenu qui défile dans un cadre de
   hauteur fixe à l'intérieur d'une page. Une liste, une table, un historique, un texte long, une
   fiche ne défilent jamais dans une boîte posée au milieu d'un écran.
2. **La liste est la page.** Quand un contenu a besoin de défiler, c'est la page entière qui
   défile, avec lui. Il n'y a qu'une barre de défilement par écran : celle de la page.
3. **Rien de gros ne reste collé au-dessus du contenu.** Le titre, les filtres et les explications
   défilent avec la page. Seule une barre fine (en-têtes de colonnes d'une table, ou barre d'une
   sélection en cours) peut rester visible en haut, et elle ne cache jamais une ligne.
4. **Ce qui est utile une seule fois prend peu de place** : filtres, en-têtes, phrases d'aide se
   replient ou passent derrière une icône (voir `DECISION-LISTES-2026-10-23.md`, amendé le même
   jour pour le rendu de bureau).
5. **Un contenu tiers** (par exemple le formulaire de paiement de Stripe) prend la hauteur de son
   contenu ; c'est la page qui défile, jamais le cadre.

Seule exception admise sans nouvelle décision : ce qui ne défile pas du tout (la page du Coran en
salle, la vidéo). Toute autre exception exige une décision datée du directeur, nommée dans ce
fichier.

## Ce que cela impose aux agents

- Avant d'écrire un écran : aucun `SizedBox` ou `ConstrainedBox` de hauteur fixe autour d'un
  `ListView`, d'un `SingleChildScrollView`, d'un `Scrollbar`, d'une table ou d'un `HtmlElementView`
  qui défile ; aucun `Expanded` de liste sous un en-tête épais qui ne défile pas.
- Une garde automatique doit le refuser à l'analyse (à ajouter à `tool/verifier_revue.dart`, règle
  `cadre-defilant`, lot du socle des listes).
- Toute PR d'écran dit dans son bilan : « une seule barre de défilement, celle de la page ».
- Les écrans existants qui violent la règle sont corrigés dans la refonte des listes (L1 puis les
  lots suivants) ; la liste des écrans touchés est tenue par ce lot.
