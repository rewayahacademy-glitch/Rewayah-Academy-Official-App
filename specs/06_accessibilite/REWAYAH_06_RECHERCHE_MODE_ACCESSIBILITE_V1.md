# Rewayah - 06 - Recherche et cadrage du Mode Accessibilité

**Date :** 27/09/2026  
**Statut :** RECHERCHE + CADRAGE PRODUIT/UX À INTÉGRER DANS `06_ELEVE_ENFANT.md`  
**Périmètre actuel :** FRONTEND ONLY  
**Terme produit canonique :** **Mode Accessibilité**  
**Terme à déprécier dans les nouvelles specs/UI :** `mode enfant`, `Interface guidée`

---

## 0. Décision structurante

Le Mode Accessibilité n'est **pas un rôle** et n'est **pas défini par l'âge**.

Il est une **couche de présentation et d'assistance** applicable à l'espace élève.

Il peut servir :
- à un enfant ;
- à une personne âgée ;
- à une personne ayant une déficience visuelle, motrice, cognitive ou d'apprentissage ;
- à une personne peu à l'aise avec le numérique ;
- à tout élève qui préfère une interface plus simple.

L'âge, le statut de mineur, la responsabilité du tuteur et les permissions restent des sujets distincts.

**Règle :**
> Les permissions dépendent de l'identité, du rôle et des règles métier. Le Mode Accessibilité ne donne ni ne retire de droits.

---

# 1. Convergence de la recherche externe

Les recommandations convergent fortement sur les points suivants.

## 1.1 W3C / WAI - accessibilité cognitive

À reprendre dans Rewayah :
- mots usuels ;
- phrases courtes ;
- blocs courts ;
- contenu non ambigu ;
- whitespace généreux ;
- quantité d'information limitée ;
- fonctions répétées identifiées de la même manière ;
- navigation et actions prévisibles ;
- aide facilement trouvable et toujours au même endroit ;
- éviter de dépendre de la mémoire ;
- permettre de corriger facilement les erreurs ;
- réduire les distractions.

Conséquence Rewayah :
- une tâche principale par écran ;
- une action dominante ;
- pas de dashboard surchargé ;
- pas de changement arbitraire de libellés ;
- pas de commandes cachées derrière des gestes complexes.

## 1.2 WCAG 2.2

Base cible : **WCAG 2.2 AA**.

En complément :
- focus visible sur web/desktop ;
- aucune action essentielle uniquement par glisser-déposer ;
- cibles suffisamment grandes et espacées ;
- statut accessible autrement que par couleur ;
- ordre de lecture sémantique ;
- labels accessibles cohérents ;
- erreurs explicites et réparables.

## 1.3 Android / Material

Android recommande des cibles tactiles d'au moins **48 x 48 dp**, plus grandes lorsque cela améliore l'utilisation.

Décision Rewayah :
- 48 dp = plancher commun ;
- en Mode Accessibilité, privilégier 52-56 dp pour les actions majeures lorsque la composition le permet ;
- augmenter la zone cliquable même si l'icône visible est plus petite.

## 1.4 Apple

À couvrir dans la recette :
- texte agrandi jusqu'à 200 % ou davantage lorsque la plateforme le permet ;
- contraste suffisant ;
- ne jamais différencier un état par couleur seule ;
- prise en charge de la réduction des animations ;
- interface sombre ;
- technologies d'assistance et contrôle vocal du système.

Le Mode Accessibilité ne doit pas construire un moteur de commandes vocales propre à Rewayah.

## 1.5 ICO - enfants

Pour les mineurs :
- confidentialité forte par défaut ;
- explications courtes au moment où une action sensible est faite ;
- pas de nudge vers moins de confidentialité ;
- choix neutres ;
- contrôle parental visible pour l'enfant lorsque de la supervision est active ;
- information adaptée au niveau de compréhension ;
- divulgation progressive ;
- autonomie croissante chez les adolescents.

Les tranches ICO sont des références de recherche, pas les cohortes métier Rewayah.

## 1.6 UNICEF

Principes retenus :
- intérêt supérieur de l'enfant comme considération première ;
- design avec les enfants et non uniquement pour eux ;
- protection, participation, autonomie et confidentialité à équilibrer ;
- ne pas utiliser la donnée ou la conception pour maximiser l'engagement au détriment du bien-être.

## 1.7 GOV.UK / recherche inclusive

Ne pas considérer la conformité technique comme suffisante.

La recette doit inclure de vrais utilisateurs avec :
- handicap visuel ;
- handicap moteur ;
- besoins cognitifs ;
- personnes âgées ;
- personnes utilisant des technologies d'assistance ;
- enfants de plusieurs tranches d'âge.

---

# 2. Architecture produit proposée

## 2.1 Deux axes séparés

### Axe A - situation de la personne

Exemples :
- mineur sous responsabilité ;
- adulte autonome ;
- élève émancipé ;
- titulaire/tuteur.

Cela détermine :
- permissions ;
- données visibles ;
- décisions pouvant être prises ;
- validations nécessaires.

### Axe B - présentation

Exemples :
- Mode Accessibilité activé ;
- présentation standard.

Cela détermine uniquement :
- densité ;
- taille ;
- navigation visuelle ;
- quantité de texte affichée immédiatement ;
- accompagnement ;
- feedback ;
- animations.

Ne jamais fusionner ces deux axes.

---

# 3. Navigation

Le Mode Accessibilité ne doit pas apprendre une autre application à l'utilisateur.

Conserver autant que possible les destinations canoniques de l'élève :

1. **Accueil**
2. **Ma classe**
3. **Coran**
4. **Mon espace**

Même sens, mêmes routes, mêmes intitulés.

Le Mode Accessibilité agit sur la présentation :
- labels toujours visibles ;
- grandes cibles ;
- moins de raccourcis concurrents ;
- informations secondaires derrière divulgation progressive ;
- aucune fonction canonique dupliquée.

---

# 4. Règles de composition du Mode Accessibilité

## 4.1 Une priorité évidente

Chaque écran doit répondre immédiatement à :
- Où suis-je ?
- Que dois-je faire maintenant ?
- Que se passera-t-il si j'appuie ici ?
- Comment revenir ?
- Où demander de l'aide ?

## 4.2 Densité

- 1 action dominante par écran ;
- 3 actions/tâches principales maximum visibles avant divulgation ;
- pas de mur de texte ;
- pas de grille dense sur mobile ;
- pas d'informations décoratives sans utilité.

## 4.3 Texte

- français simple ;
- titres concrets ;
- verbes d'action ;
- phrases courtes ;
- éviter les codes académiques internes ;
- ne pas infantiliser les adultes qui utilisent le Mode Accessibilité.

Exemple :
- mauvais : `Niveau F2 - progression 67 %`
- meilleur : `En ce moment : lire avec les voyelles`
- détail disponible ensuite pour qui le souhaite.

## 4.4 Icônes

- icône + texte pour les actions majeures ;
- jamais une icône abstraite seule si le sens peut être ambigu ;
- même fonction = même icône + même libellé partout.

## 4.5 Cibles

- minimum 48 dp ;
- préférer 52-56 dp pour CTA et lignes majeures en Mode Accessibilité ;
- espace suffisant entre actions destructives et actions principales.

## 4.6 Couleur

- couleur jamais seule pour signifier absence, retard, succès, danger ou sélection ;
- ajouter texte, icône ou forme ;
- états de focus visibles sur desktop/web.

## 4.7 Mouvement

- aucune animation essentielle ;
- respecter `Reduce Motion` / préférences plateforme ;
- transitions brèves et calmes ;
- aucun mouvement continu décoratif ;
- aucun clignotement.

## 4.8 Audio

Audio possible comme **aide**, jamais comme seule façon de comprendre.

Prévoir :
- texte équivalent ;
- replay ;
- volume système ;
- pas de lecture automatique agressive.

---

# 5. Accueil élève en Mode Accessibilité

Ordre recommandé :

1. Salutation courte
2. **Prochaine séance**
3. CTA contextuel unique
4. **Avant le prochain cours** - maximum 3 tâches
5. Accès direct au Coran/support
6. Aide

Éviter :
- statistiques multiples ;
- grandes métriques ;
- comparaisons ;
- classement ;
- badges inutiles ;
- actualités non essentielles.

La progression détaillée reste accessible depuis la classe ou le suivi canonique, mais ne domine pas l'accueil.

---

# 6. Classe

Avant la séance :
- photo du Sayyid/Sayyida ;
- nom de la classe ;
- heure locale ;
- durée ;
- état très clair ;
- CTA `Rejoindre` uniquement lorsque réellement permis ;
- message discret : tablette ou ordinateur conseillé, téléphone pris en charge.

Pendant la séance :
- support pédagogique primaire ;
- chrome réduit ;
- contrôles secondaires minimisés ;
- suivi automatique du contenu partagé par le professeur ;
- aucune obligation de retrouver manuellement la bonne page ;
- réseau faible expliqué simplement ;
- reconnexion calme et automatique lorsque possible.

Après la séance :
- prochaine action ;
- travail court ;
- support à reprendre ;
- pas de tableau de statistiques envahissant.

---

# 7. Coran et ressources

Mode Accessibilité :
- taille et zoom simples ;
- mode verset disponible ;
- focus visuel ;
- progression de lecture compréhensible ;
- gros contrôles précédent/suivant ;
- téléchargement/offline expliqué ;
- reprise à la dernière position autorisée.

Ne pas :
- altérer le texte canonique ;
- ajouter des overlays gênant la lecture ;
- dépendre de gestes complexes uniquement.

---

# 8. Aide

Une entrée d'aide doit rester au même endroit dans toute la variante.

Proposition :
- bouton/ligne `Besoin d'aide ?`
- accès en 1 ou 2 actions maximum ;
- aide contextuelle courte ;
- contact humain si le canal existe réellement.

Ne jamais afficher une promesse de support qui n'existe pas.

---

# 9. Mineurs : protections supplémentaires

Ces protections dépendent du statut mineur, pas du Mode Accessibilité lui-même.

- confidentialité forte par défaut ;
- collecte minimale ;
- pas de géolocalisation inutile ;
- pas de nudge pour partager plus ;
- pas de publicité comportementale ;
- pas de classement public ;
- pas de dark patterns ;
- actions sensibles expliquées au moment de l'action ;
- supervision parentale rendue visible lorsque le produit la prévoit.

### Observation d'une séance

Si un tuteur observe une séance :
- l'enfant concerné doit recevoir une indication claire et discrète ;
- les autres élèves ne doivent pas recevoir l'information ;
- ne pas cacher la supervision à l'enfant lorsqu'elle est visible selon la politique produit.

---

# 10. Autonomie progressive

Ne pas traiter tous les mineurs de la même manière.

Les cohortes Rewayah restent :
- 6-9
- 10-13
- 14-17
- 18+

La recherche externe peut guider la formulation, mais ne remplace pas ces cohortes.

## 6-9
- explications très courtes ;
- davantage d'indices visuels ;
- peu de décisions sensibles ;
- accompagnement du tuteur plus fort.

## 10-13
- commencer à expliquer le pourquoi ;
- donner plus de contrôle sur les actions non sensibles ;
- permettre les demandes prévues par la politique produit.

## 14-17
- ton proche de l'adulte ;
- autonomie accrue ;
- explications de confidentialité plus complètes ;
- éviter tout habillage enfantin.

## 18+
- adulte autonome ;
- peut garder le Mode Accessibilité si cela lui convient ;
- aucune bascule automatique vers une interface plus dense.

---

# 11. Activation du Mode Accessibilité

Le Mode Accessibilité doit pouvoir exister indépendamment de l'âge.

Cible produit à préserver :

- enfant : politique de défaut selon les décisions Rewayah ;
- tuteur : peut gérer l'interface de son profil mineur selon ses droits ;
- adolescent : demandes d'évolution selon la politique active ;
- adulte : peut activer ou désactiver lui-même le Mode Accessibilité ;
- personne âgée ou en situation de handicap : même expérience, sans libellé stigmatisant ni interface enfantine.

Aucun changement de mode ne doit :
- modifier un rôle ;
- augmenter une permission ;
- exposer une donnée supplémentaire ;
- contourner le tuteur ou l'administration.

---

# 12. Risques à empêcher

1. **Infantilisation**
   - pictogrammes trop enfantins ;
   - mascottes omniprésentes ;
   - ton bébé pour un adulte.

2. **Deux applications divergentes**
   - routes différentes ;
   - fonctions différentes ;
   - labels différents.

3. **Fausse simplicité**
   - cacher une fonction essentielle sans moyen clair de la retrouver.

4. **Dépendance à l'âge**
   - forcer un adulte à l'interface standard ;
   - supposer qu'un enfant précis a les mêmes besoins que tous les enfants de son âge.

5. **Accessibilité cosmétique**
   - grosses polices mais ordre de lecture mauvais ;
   - grandes cartes avec petites zones cliquables ;
   - couleurs accessibles mais interactions confuses.

6. **Surcharge sensorielle**
   - animations ;
   - sons automatiques ;
   - gradients forts ;
   - multiples alertes.

7. **Supervision invisible**
   - tuteur observant sans indication lorsque la politique exige une information visible.

8. **Erreur de permissions**
   - une bascule UI qui change réellement caméra, droits ou visibilité sans autorité serveur.

---

# 13. Recette obligatoire

## Formats
- mobile 390
- tablette 768
- desktop 1440

## Thèmes
- clair
- sombre

## Accessibilité
- texte 200 %
- VoiceOver/TalkBack
- clavier intégral sur web/desktop
- focus visible
- contraste
- Reduced Motion
- pas de couleur seule
- RTL si activé
- zoom
- orientation pertinente

## Profils de test humain à rechercher avant finalisation
- enfant 6-9 + tuteur ;
- enfant 10-13 ;
- adolescent 14-17 ;
- adulte faible aisance numérique ;
- personne âgée ;
- utilisateur basse vision ;
- utilisateur avec limitation motrice/dextérité ;
- utilisateur avec besoins cognitifs/lecture ;
- utilisateur lecteur d'écran.

La conformité automatique seule ne vaut pas validation UX.

---

# 14. Handoff Claude Code

Pendant la vague `06` :

- FRONTEND ONLY ;
- cartographier l'existant avant modification ;
- ne pas créer de backend pour faire fonctionner une maquette ;
- ne pas créer une seconde architecture de navigation ;
- ne pas dupliquer les écrans standard ;
- Mode Accessibilité = variante de présentation des mêmes fonctions canoniques ;
- mutualiser les composants ;
- respecter les tokens gelés ;
- DM Sans titres, Plus Jakarta Sans reste ;
- vrais layouts desktop ;
- états loading/empty/error/offline/permission ;
- aucune permission sensible décidée localement ;
- signaler tout contrat manquant.

**Nouvelle terminologie :**
- utiliser `Mode Accessibilité` dans les nouvelles specs et l'UI ;
- ne plus écrire `mode enfant` ;
- remplacer progressivement `Interface guidée` dans les documents actifs concernés, sans refactor opportuniste hors périmètre.

---

# 15. Références externes étudiées

- W3C Web Accessibility Initiative - WCAG 2.2
- W3C WAI - Cognitive Accessibility / COGA
- Android Developers - Accessibility
- Apple Developer - Accessibility declarations and platform accessibility
- Information Commissioner's Office - Children's Code / Age Appropriate Design
- UNICEF Innocenti - Children's Best Interests in Digital Policy and Practice
- GOV.UK Service Manual - accessibility and inclusive design

Ces références orientent la conception. Les règles métier Rewayah et les décisions explicites du directeur restent l'autorité produit.
