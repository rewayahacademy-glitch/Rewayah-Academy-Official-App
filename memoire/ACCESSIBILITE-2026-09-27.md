# ACCESSIBILITE-2026-09-27 : règles réutilisables du Mode Accessibilité (MA1 à MA24)

**Préfixe.** « MA » et non « A », pour ne pas confondre avec le contrat A de DESIGN-GOV (espacement) ni avec les textes A1 à A5 des consentements.

**Sources.**
- Document du directeur : `specs/06_accessibilite/REWAYAH_06_RECHERCHE_MODE_ACCESSIBILITE_V1.md` (27/09/2026, 532 lignes). **Ne pas le relire en entier** : ce fichier en garde l'essentiel, avec le § d'origine.
- Quatre planches : pilotage `15_accessibilite/V/PLANCHE-1..4.png`.
- Rectifications : pilotage `15_accessibilite/V/00_MAQUETTES_ACCESSIBILITE.md`.

**Ordre d'autorité.**
1. La demande la plus récente du directeur.
2. DESIGN-GOV (gelé).
3. K-42, le style CL-4.
4. CLASSE-ENTREE (R1 à R21), et ENSEIGNANT (E1 à E20) pour ce qui touche la salle et la Classe.
5. Le présent fichier.
6. Le document 06.
7. Les planches, qui sont des exemples de composition et jamais une règle métier.

**Exceptions gelées qui priment sur le document 06.**
- Thème figé chrome / violet (K-37). Tout besoin de couleur, de contraste ou de thème propre au Mode Accessibilité devient **une ligne TH-2**, jamais une modification.
- Le rendu du Coran est intouchable.
- GOV.UK n'est pas une référence de design (DESIGN-GOV §4.1). Le §1.7 du document 06 n'est retenu que pour la recette avec de vrais utilisateurs, jamais pour justifier une composition.
- Académie = LTD anglaise : UK GDPR et ICO Children's Code d'abord, RGPD en complément.

## Nature du mode

- **MA1. Le Mode Accessibilité n'est ni un rôle ni un âge** (doc §0, §2). C'est une couche de présentation de l'espace élève.
  - Il ne donne ni ne retire aucun droit, ne change aucune route, n'expose aucune donnée de plus, ne contourne ni le tuteur ni l'administration (§11).
  - Deux axes séparés, jamais fusionnés : la situation de la personne (mineur, adulte, tuteur…) décide des permissions ; la présentation décide seulement de la densité, de la taille, de la navigation visuelle, du texte immédiat, de l'accompagnement, du retour et des animations.
- **MA2. Une seule application** (§3, §12 point 2). Mêmes destinations, mêmes routes, mêmes libellés, mêmes fonctions que la présentation standard.
  - Pas d'écran dupliqué : un écran standard reçoit une variante de présentation, sans fork.
  - Le modèle existant `InterfaceMode` (valeurs `enfant` et `standard`, SQL `child` et `standard`) est réutilisé. On ne renomme pas l'énumération ni la valeur SQL (pas de refactor opportuniste, doc §14) ; un nom de base plus juste est une ligne BR-1.
- **MA3. Terminologie** (§14). Dans les textes visibles et les nouvelles specs : « Mode Accessibilité » et « présentation standard ».
  - On n'écrit plus « mode enfant » ; « Interface guidée » est remplacé dans les textes actifs concernés.
  - Aucune description liée à l'âge (« sans lecture », « reconnaît des images »), aucun libellé stigmatisant (§11).
- **MA4. Pas d'infantilisation** (§4.3, §10, §12 point 1). Ni mascotte, ni pictogramme enfantin, ni ton « bébé ».
  - Un adulte, une personne âgée ou un adolescent de 14 à 17 ans voient une interface sobre.
  - Le tutoiement n'est employé que là où l'existant le fait déjà pour l'élève mineur (« Ton parent observe la séance ») ; un adulte est vouvoyé.
- **MA5. Pas de permission décidée localement** (§12 point 8, §14). Une bascule d'affichage ne touche jamais la caméra, le micro, la visibilité ni un droit. L'autorité est le serveur (BR-1).

## Composition

- **MA6. Cinq questions par écran** (§4.1) : où suis-je, que dois-je faire maintenant, que se passe-t-il si j'appuie, comment revenir, où demander de l'aide.
- **MA7. Une tâche, une action dominante** (§4.2). Trois tâches au plus visibles avant divulgation (R17 : « Avant le prochain cours », 3 au plus). Pas de mur de texte, pas de grille dense sur mobile, pas de décor sans utilité (K-42 : on ne remplit pas un vide).
- **MA8. Texte simple** (§4.3) : titres concrets, verbes d'action, phrases courtes, pas de code interne (« Niveau F2 – 67 % » devient une phrase ; le détail vient ensuite).
- **MA9. Icône + texte pour toute action majeure** (§4.4). Jamais une icône seule ambiguë. Même fonction, même icône et même libellé partout. Les libellés existants priment sur ceux des planches.
- **MA10. Cibles** (§4.5) : 48 dp au plancher ; 52 à 56 dp pour les boutons et lignes majeures en Mode Accessibilité quand la composition le permet ; la zone cliquable peut dépasser l'icône. `ActionPrincipale` (52) et `GroupeReglages` (48) sont réutilisés ; les valeurs prouvées de `app_metriques.dart` priment (DESIGN-GOV §4 bis). Espace net entre une action destructive et l'action principale.
- **MA11. Jamais la couleur seule** (§4.6) pour absence, retard, succès, danger ou sélection : un mot, une icône ou une forme l'accompagne. Focus visible sur web et bureau. Couleur ou contraste insuffisant : ligne TH-2.
- **MA12. Mouvement** (§4.7) : aucune animation essentielle, aucun mouvement décoratif continu, aucun clignotement.
  - Tout passe par `lib/core/mouvement` (`Mouvement.duree`) et les jetons du contrat E ; en réduction de mouvement, durée 0 et translation 0.
  - La préférence de l'appareil **et** la préférence locale `animationsReduites` sont respectées toutes deux.
- **MA13. Audio = aide, jamais seul chemin** (§4.8) : texte équivalent, rejouer, volume du système, aucune lecture automatique agressive.
- **MA14. Aide au même endroit** (§8) : une entrée « Besoin d'aide ? » atteignable en une ou deux actions, toujours au même emplacement.
  - Aucune promesse de support qui n'existe pas. Tant que le canal n'est pas décidé (DB-CPT-07), l'entrée mène à la page d'aide honnête existante ; pas de « On est là pour t'aider ».
- **MA15. Texte agrandi à 200 %** sans perte (§1.4, §13) : rien de coupé, deux colonnes seulement si la largeur utile divisée par le facteur de texte dépasse 840 (K-42 point 6).
- **MA16. Ordre de lecture et lecteur d'écran** (§1.2, §12 point 5) : ordre sémantique, `Semantics` cohérents, une seule annonce par changement (K-42 point 7), aucune action essentielle par glisser seul ni par geste complexe seul.

## Écrans élève

- **MA17. Navigation à 4 destinations** (§3) : Accueil, Ma classe, Coran, Mon espace, libellés toujours visibles. Barre en bas sur mobile, rail sur tablette, barre latérale sur ordinateur.
  - Le Mode Accessibilité n'a plus « aucune destination » (ancienne règle du mode enfant) : il a les mêmes 4 destinations que la présentation standard.
  - Aucune navigation de l'app dans la salle (tâche focalisée, comme E4 et R1 à R21).
- **MA18. Accueil** (§5), dans cet ordre : salutation courte, « Prochaine séance » (emplacement unique `EmplacementEntree`, R4 et E11), un seul bouton contextuel, « Avant le prochain cours » (3 au plus), accès direct au Coran ou au support, aide.
  - Sans statistiques, grandes métriques, comparaison, classement, badge ni actualité. Sans cloche de notification (non garanties).
- **MA19. Ma classe** (§6) : photo de l'enseignant (`PhotoEnseignant`, titre Sayyid ou Sayyida, R18), nom de la Classe, heure locale, durée, état clair.
  - « Rejoindre » n'existe que lorsque l'entrée est réellement permise ; avant, une ligne d'état calme (R4). Jamais de bouton actif à côté de « Disponible dans 20 min ».
  - Mention discrète : tablette ou ordinateur conseillé, téléphone pris en charge.
- **MA20. Pendant la séance** (§6) : support dominant, chrome réduit, commandes secondaires minimisées, suivi automatique du support de l'enseignant, réseau faible expliqué simplement (R11, R12), reconnexion calme. Micro et caméra coupés à l'entrée (R8). Aucune fonction absente du contrat (discussion, participants, lever la main).
- **MA21. Après la séance** (§6) : la prochaine action, un travail court, le support à reprendre. Aucun jugement automatique (« Très bien ! ») ni affirmation de présence tirée d'un chrono (E8, R7).
- **MA22. Coran** (§7) : autour du rendu, jamais dedans. Taille et zoom simples, mode verset (`vue_verset_agrandi`), gros contrôles Précédent et Suivant, reprise à la dernière position autorisée, hors ligne expliqué. Aucun calque sur le texte, aucun geste complexe comme seul chemin.

## Mineurs et activation

- **MA23. Protections des mineurs** (§9, ICO Children's Code) : elles dépendent du statut mineur, pas du Mode Accessibilité.
  - Confidentialité forte par défaut, collecte minimale, pas de nudge, pas de classement public, pas de dark pattern, explication courte au moment d'une action sensible.
  - **Observation** : l'enfant observé reçoit une indication claire et discrète (textes existants « Ton parent observe la séance. » / « Votre parent observe la séance. ») ; les autres élèves ne la reçoivent pas.
  - Aucun âge affiché sur l'écran de l'élève (minimisation) : les cohortes 6-9, 10-13, 14-17, 18+ guident le ton, jamais l'affichage.
- **MA24. Activation** (§10, §11) : aucune bascule automatique liée à l'âge vers une interface plus dense ; un adulte peut garder le Mode Accessibilité.
  - Tuteur : gère la présentation de son profil mineur (page existante `/tuteur/foyer/:eleveId/interface`).
  - Adulte autonome : active ou désactive lui-même, depuis Mon espace. En démonstration seulement ; l'écriture réelle attend BR-1.
  - Adolescent ou enfant : une demande n'est affichée que lorsque la politique et son contrat existent (DB-FOY-04) ; d'ici là, aucune fausse demande.
  - Toute écriture est relue, jamais optimiste (comme `InterfaceElevePage`).

## Recette (§13)

Formats 390, 768, 1440 ; clair et sombre ; texte à 200 % ; TalkBack (téléphone Android du directeur) et arbre `Semantics` testé ; clavier intégral et focus visible sur web ; animations réduites (appareil et préférence locale) ; jamais la couleur seule ; RTL simulé ; zoom ; orientation. La conformité automatique ne vaut pas validation UX : les tests avec de vrais utilisateurs (profils du §13) sont une étape ultérieure, avec consentement (UK GDPR, Children's Code), hors de cette vague.
