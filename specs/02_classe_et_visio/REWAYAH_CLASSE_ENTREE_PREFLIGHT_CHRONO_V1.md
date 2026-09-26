# REWAYAH — Cartographie UX/UI des 3 écrans d’entrée de Classe
## Espace Classe Élève · Espace Classe Enseignant · Préparation technique avant entrée
### Version de cadrage pour maquettes high-fi et intégration verticale

> Statut : **spécification de cartographie UX/UI**
>
> Objectif : figer l’architecture fonctionnelle et visuelle de ces trois écrans avant création des maquettes.
>
> Important : ce document **ne demande pas de reprendre les lots déjà terminés**. Il ajoute les règles à la référence commune et prépare leur application au moment pertinent.

---

# 0. Règle d’or d’orchestration

Ces directives doivent être :

1. ajoutées au **tableau de suivi partagé** entre les agents ;
2. ajoutées à la **mémoire / documentation canonique active** utilisée par l’orchestrateur ;
3. reliées au chantier `Classe / Teaching Core / UI vertical` ;
4. conservées comme règle durable pour toutes les futures implémentations concernées.

## Ne pas interrompre le chantier actuel

Si une directive de ce document ne peut pas être intégrée immédiatement sans casser l’ordre de travail actuel :

- **ne pas revenir en arrière** ;
- **ne pas rouvrir les lots déjà terminés** ;
- créer une entrée explicite dans le tableau de suivi ;
- marquer cette entrée `À appliquer lors de la passe Classe / Live correspondante` ;
- continuer immédiatement les étapes verticales actuellement en cours.

Exception unique : le Directeur demande explicitement de revenir sur un écran ou un lot précis.

Cette règle vaut notamment pour le **chrono interne de Classe Live** ajouté dans ce document.

---

# 1. Modèle mental global

La **Classe** est l’espace pédagogique permanent.

La **Classe Live** est un état temporaire de cette Classe.

Le parcours cible doit rester conceptuellement simple :

```text
MES CLASSES
    ↓
CARTE DE CLASSE
    ↓
ESPACE CLASSE
    ↓
fenêtre de connexion ouverte
    ↓
PRÉPARATION TECHNIQUE
    ↓
ATTENTE / CONNEXION
    ↓
CLASSE LIVE
    ↓
RETOUR ESPACE CLASSE
```

L’utilisateur ne doit jamais avoir l’impression d’ouvrir plusieurs produits différents.

---

# 2. Principes UX transversaux

## 2.1 Une responsabilité principale par écran

### Espace Classe Élève
Répond à :

> « Quel est mon prochain cours et qu’est-ce que je dois faire avant ? »

### Espace Classe Enseignant
Répond à :

> « Quel cours vais-je donner, à qui, et qu’est-ce que je dois préparer ? »

### Préparation technique
Répond à :

> « Mon appareil est-il prêt pour entrer dans la classe ? »

Ne pas mélanger ces responsabilités.

---

# 3. Écran A — Espace Classe Élève

## 3.1 Nature de l’écran

Ce n’est pas une salle d’attente vidéo.

C’est la **maison pédagogique permanente** de l’élève pour cette Classe.

Pas de sidebar interne spécifique à la Classe.

Pas de multiplication d’onglets.

La page reste verticale, calme et lisible.

## 3.2 Ordre canonique

Ordre stable :

1. identité de la Classe ;
2. Session dominante ;
3. `Avant le prochain cours` ;
4. Bibliothèque de la Classe ;
5. progression ou résumé utile si pertinent.

## 3.3 En-tête de Classe

Afficher au minimum :

- nom humain de la Classe ;
- cours / niveau utiles ;
- photo publique obligatoire de l’enseignant ;
- titre `Sayyid` ou `Sayyida` ;
- nom d’affichage de l’enseignant.

Ne jamais afficher des codes backend comme identité principale.

## 3.4 Session Card dominante

Informations minimales :

- jour et date ;
- heure locale de l’élève ;
- éventuellement heure de la Classe / de l’enseignant lorsque réellement utile ;
- durée ;
- countdown avant la séance ;
- état de la séance ;
- CTA `Rejoindre` uniquement lorsque la fenêtre d’accès est réellement ouverte.

### Exemple

```text
PROCHAINE SÉANCE

Lundi 28 septembre
18:00 Riyad
Durée : 1 h

Cours dans 3 h 28

                         [ Rejoindre ]
```

Le CTA `Rejoindre` ne doit pas être affiché pendant plusieurs jours sous forme désactivée.

Avant ouverture de la fenêtre de connexion, afficher simplement le temps restant.

## 3.5 États à prévoir dans les maquettes

La Session Card doit posséder au minimum ces états :

- session future ;
- fenêtre de connexion ouverte ;
- préparation en cours ;
- attente avant démarrage ;
- session en direct ;
- session terminée ;
- session annulée ;
- hors ligne / information indisponible ;
- changement d’horaire / notice DST si applicable.

## 3.6 Avant le prochain cours

Maximum **3 actions visibles**.

Exemples métier possibles selon les données réellement disponibles :

- revoir une plage ;
- apprendre ;
- renforcer ;
- entretenir ;
- préparer une évaluation ;
- reprendre un support.

Ne pas créer une longue todo-list.

Ne pas ajouter de formulaire narratif lourd.

## 3.7 Bibliothèque

Présenter les supports de la Classe avec couvertures reconnaissables.

Exemple :

```text
Supports de la Classe                       Voir tout →

[ Coran ]   [ Qaida ]   [ Invocations ]
```

La Bibliothèque utilisée ici doit être la même source que celle utilisée pendant la Classe Live.

Aucun système parallèle `Bibliothèque hors classe` / `Bibliothèque en classe`.

---

# 4. Écran B — Espace Classe Enseignant

## 4.1 Même identité, rôle différent

L’écran partage avec l’élève :

- identité de Classe ;
- Session Card ;
- enseignant ;
- horaires ;
- durée ;
- countdown.

Mais son objectif est opérationnel.

## 4.2 Ordre recommandé

1. identité de Classe ;
2. Session Card ;
3. préparation de la prochaine séance ;
4. roster pédagogique ;
5. travail actuel / progression de groupe ;
6. supports récents et Bibliothèque ;
7. anomalies utiles uniquement si elles nécessitent une attention.

## 4.3 Session Card Enseignant

Même logique temporelle que côté élève.

Lorsque la fenêtre d’entrée est ouverte, une action dominante mène vers la préparation technique.

Le libellé final peut être résolu par le copywriting, mais la logique cible est :

```text
[ Préparer l’entrée ]
```

ou

```text
[ Rejoindre la classe ]
```

Le clic ne doit pas connecter directement la Room sans passer par le contrôle pré-cours prévu pour l’enseignant.

## 4.4 Préparer la séance

Afficher uniquement les informations opérationnelles utiles :

- support prévu ;
- position de reprise ;
- travail / objectif prévu ;
- accès à la Bibliothèque ;
- reprise contextuelle du dernier support si disponible.

`Reprendre le cours` n’est pas une rubrique permanente.

C’est une action contextuelle.

## 4.5 Roster pédagogique

L’enseignant doit connaître l’élève **pédagogiquement**, pas personnellement.

Données possibles dans la projection autorisée :

- prénom ;
- identifiant Académie ;
- niveau ;
- parcours ;
- unité / objectif courant ;
- dernière séance ;
- point de reprise ;
- présence récente ;
- travail en cours ;
- notes pédagogiques autorisées ;
- état live.

Ne jamais afficher dans ce contexte :

- téléphone ;
- email privé ;
- adresse ;
- identité détaillée du foyer ;
- paiements ;
- données privées des tuteurs ;
- géolocalisation ;
- identifiants techniques d’appareil.

---

# 5. Écran C — Préparation technique avant entrée

## 5.1 Principe

Le Preflight est une couche intermédiaire entre l’Espace Classe et la Classe Live.

Il ne doit pas être conçu comme une Classe Live miniature.

Il vérifie les capacités locales nécessaires puis transmet l’utilisateur vers la Room réelle.

---

# 6. Préflight Enseignant

## 6.1 Vérifications

Vérifier selon capacités de plateforme :

- réseau ;
- microphone ;
- sortie audio ;
- caméra si utile et autorisée ;
- périphérique choisi ;
- permissions nécessaires.

Ajouter le contexte pédagogique utile :

- Classe ;
- temps avant début ;
- support prévu ;
- position de reprise ;
- nombre d’élèves attendus.

## 6.2 État des médias à l’entrée

Règle Rewayah :

- micro enseignant **OFF à l’entrée** ;
- caméra enseignant **OFF à l’entrée** ;
- activation volontaire ensuite.

Donc l’interface doit écrire par exemple :

```text
✓ Micro détecté
  Micro coupé à l’entrée
```

et non :

```text
✓ Micro activé
```

Même règle pour la caméra.

## 6.3 Hiérarchie des actions

Un seul CTA dominant :

```text
[ Entrer dans la classe ]
```

Les actions suivantes restent secondaires ou tertiaires :

- changer de micro ;
- choisir une caméra ;
- tester le son ;
- ouvrir les paramètres système.

Ne pas créer quatre gros boutons concurrents.

---

# 7. Préflight Élève

## 7.1 Principe

Le parcours normal doit être beaucoup plus léger que celui de l’enseignant.

Les vérifications doivent être **silencieuses autant que possible**.

L’élève ne doit intervenir que si :

- une permission indispensable est refusée ;
- un périphérique nécessaire manque ;
- une condition bloque réellement l’entrée ;
- une action humaine est nécessaire.

## 7.2 État normal

Exemple :

```text
Tout est prêt

✓ Connexion
✓ Audio
✓ Accès à la classe

Vous entrerez avec le micro coupé.

                         [ Entrer dans la classe ]
```

## 7.3 Problème technique

Exemple :

```text
Votre micro n’est pas accessible

Le professeur ne pourra pas vous entendre
tant que l’accès au micro reste bloqué.

[ Autoriser le micro ]

Continuer si le cours peut être suivi sans micro
```

Les messages doivent être humains.

Ne jamais afficher dans l’interface utilisateur des erreurs brutes de type :

- ICE failed ;
- RTP timeout ;
- SDP error ;
- TURN failed.

Ces informations restent dans les logs techniques.

---

# 8. Réseau et reconnexion

Utiliser les signaux du moteur LiveKit existant.

Ne pas créer un second moteur parallèle de mesure réseau.

États UX recommandés :

- Connexion bonne ;
- Connexion instable ;
- Reconnexion… ;
- Connexion rétablie ;
- Impossible de se reconnecter.

Ne pas transformer le preflight en speedtest avec Mbps comme métrique principale.

---

# 9. Permissions et périphériques

## 9.1 Principe

Ne pas demander caméra et micro dès l’ouverture de l’application.

Demander les permissions dans le contexte où elles deviennent utiles.

Si une politique interdit une caméra, ne pas demander inutilement son autorisation.

## 9.2 Web et plateformes

La maquette doit accepter que certains sélecteurs ne soient pas disponibles partout.

Exemple :

```text
Micro
[ Microphone du Mac ▼ ]

Caméra
[ FaceTime HD ▼ ]

Sortie audio
[ Sortie système ]
```

Si la plateforme ne permet pas de sélectionner explicitement la sortie audio, ne pas afficher un faux contrôle inerte uniquement pour préserver la symétrie.

---

# 10. Architecture logique cible

Avant de créer quoi que ce soit, mapper les abstractions déjà présentes dans le dépôt.

Ne pas créer un doublon sémantique.

```text
GroupHomeVM
      │
SessionClockVM
      │
      ▼
ESPACE CLASSE
      │
join autorisé ?
      │
      ▼
Preflight / préparation
      │
      ├── périphériques
      ├── permissions
      ├── réseau
      └── politique de rôle
      │
      ▼
ReadyToJoin
      │
      ▼
autorisation / token
      │
      ▼
LiveSessionController existant
      │
      ▼
LiveKit Room
```

Si une abstraction équivalente existe déjà, la réutiliser.

Si un contrat manque et que sa création implique une modification hors ownership, produire la demande de contrat prévue par le protocole du Teaching Core au lieu de contourner l’architecture.

---

# 11. Skeletons et états asynchrones

Rétablir systématiquement le pattern Skeleton déjà existant dans Rewayah.

Pour l’Espace Classe :

- skeleton fidèle à la Session Card ;
- skeleton fidèle aux blocs attendus ;
- aucun spinner central générique comme première réponse.

Pour le Preflight :

- chaque test peut évoluer indépendamment ;
- ne pas bloquer toute la page si un seul contrôle est encore en vérification.

---

# 12. Responsive

## Mobile

### Élève
Une colonne :

```text
Session
↓
Avant le prochain cours
↓
Bibliothèque
↓
Progression utile
```

### Enseignant
Une colonne, avec les éléments de préparation ordonnés par priorité.

### Preflight
Une colonne, aperçu compact puis readiness.

## Tablette

Deux colonnes uniquement lorsque cela améliore réellement la lecture.

## Desktop / Web

Ne jamais agrandir artificiellement le mobile.

### Élève
Contenu centré avec Session dominante et contenu secondaire maîtrisé.

### Enseignant
Session + préparation / roster possibles en composition multi-colonnes.

### Preflight
Pattern recommandé :

```text
┌──────────────────────────┬────────────────────────────┐
│                          │ Équipement                 │
│      Aperçu média        │ ✓ Micro                   │
│                          │ ✓ Audio                   │
│                          │ ✓ Réseau                  │
│                          │ ○ Caméra coupée           │
├──────────────────────────┴────────────────────────────┤
│ Contexte de la séance                                  │
│ Support · reprise · élèves attendus                    │
│                                  [ Entrer dans la classe ]
└────────────────────────────────────────────────────────┘
```

Le CTA reste proche du contexte qu’il confirme.

---

# 13. NOUVELLE DÉCISION DIRECTEUR — Chrono interne de Classe Live

## 13.1 Besoin produit

La Classe Live doit posséder un **chrono interne de séance** visible pendant le cours.

Le professeur et, lorsque pertinent, l’élève doivent pouvoir savoir immédiatement :

1. combien de temps s’est écoulé depuis le début de la séance ;
2. combien de temps reste sur la durée prévue.

Exemple pour une séance de **1 h 30** après 30 minutes :

```text
Écoulé
30 min

Temps restant
01:00:00
```

Le temps restant descend progressivement vers :

```text
00:00:00
```

## 13.2 Règle UX

Le chrono ne doit pas devenir un gros composant anxiogène.

Il doit rester :

- lisible ;
- toujours accessible ;
- secondaire par rapport au support pédagogique ;
- stable spatialement ;
- suffisamment visible pour être consulté d’un coup d’œil.

### Desktop / tablette

Placement recommandé dans l’en-tête de Classe Live :

```text
Classe An-Nour · Sayyida Amina

Écoulé 30 min        Reste 01:00:00
```

ou sous forme compacte équivalente.

### Mobile

Format compact dans l’en-tête, par exemple :

```text
30 min écoulées · 1 h restante
```

ou

```text
30:00  ↑     01:00:00  ↓
```

Le choix final de copywriting sera figé lors des maquettes.

## 13.3 Source du temps

Le chrono ne doit pas dépendre uniquement d’un `Timer` local Flutter.

Claude doit d’abord identifier les champs temporels canoniques déjà présents dans le domaine/session.

Le calcul doit dériver d’une source temporelle autoritative :

```text
temps_ecoule = maintenant_autoritatif - debut_effectif
temps_restant = fin_prevue - maintenant_autoritatif
```

La durée prévue vient de la séance réelle.

Ne jamais hardcoder `1 h`, `1 h 30`, etc.

## 13.4 Reconnexion / background

Une perte réseau ou le passage temporaire en arrière-plan ne met pas le cours en pause.

À la reconnexion :

- recalculer depuis les timestamps canoniques ;
- ne pas reprendre un compteur local suspendu ;
- éviter toute dérive d’horloge perceptible.

Le chrono de cours est indépendant du calcul d’assiduité.

Il ne doit pas devenir une preuve de présence.

## 13.5 Fin du temps prévu

Lorsque le temps restant atteint zéro :

```text
00:00:00
```

Ne pas afficher immédiatement une valeur négative comme :

```text
-00:03:27
```

Préférer :

```text
Temps prévu écoulé
```

L’indicateur de temps écoulé peut continuer :

```text
1 h 33 écoulées
```

si la séance reste réellement ouverte.

Aucune déconnexion automatique ne doit être déduite de cette règle sans décision métier distincte.

## 13.6 Tâche différée obligatoire

Créer dans le tableau partagé une tâche dédiée, par exemple :

```text
LIVE-CHRONO-01
Chrono interne de Classe Live
```

La tâche doit mentionner :

- durée dynamique de séance ;
- elapsed time ;
- remaining time jusqu’à `00:00:00` ;
- comportement T0 ;
- comportement dépassement ;
- reconnexion ;
- background / retour foreground ;
- responsive mobile / tablette / desktop ;
- tests de dérive temporelle ;
- non-interférence avec présence et assiduité.

### Priorité d’orchestration

**Ne pas interrompre les lots actuels uniquement pour cette demande.**

Si le chantier Classe Live correspondant n’est pas en cours :

1. enregistrer la tâche ;
2. la rattacher à l’étape Classe Live ;
3. continuer les étapes actuellement prévues ;
4. l’implémenter lorsque la vague concernée est atteinte.

Le Directeur ajoute cette décision maintenant afin qu’elle **ne soit jamais oubliée**.

---

# 14. Maquettes nécessaires

Ne pas produire 30 variantes.

Minimum recommandé :

1. `CLS-ELV-01` — Espace Classe Élève, session future ;
2. `CLS-ELV-02` — Espace Classe Élève, fenêtre T-20 ouverte ;
3. `CLS-ENS-01` — Espace Classe Enseignant, préparation normale ;
4. `CLS-ENS-02` — Espace Classe Enseignant, fenêtre d’entrée ouverte ;
5. `PRE-ENS-01` — Preflight Enseignant, tout prêt ;
6. `PRE-ELV-01` — Preflight Élève, état normal minimal ;
7. `PRE-ERR-01` — Preflight avec problème nécessitant une action ;
8. `LIVE-TIMER-01` — référence compacte du chrono dans la Classe Live.

## Format des planches

### Mobile
Plusieurs états peuvent être regroupés sur une même planche.

### Web
Une interface par planche.

---

# 15. Règles CTA à appliquer

- un seul CTA visuellement dominant par contexte de décision ;
- CTA d’avancement au `trailing` dans les interfaces LTR ;
- retour au `leading` ;
- action rattachée à un bloc placée dans ou immédiatement après ce bloc ;
- gap standard contenu lié → CTA : **16 dp** ;
- gap entre boutons du même groupe : **8 dp** ;
- ne jamais placer un CTA solitaire au bas d’un grand écran si le contenu auquel il appartient se trouve très loin au-dessus ;
- ne jamais placer plusieurs CTA pleins de même poids qui se concurrencent.

---

# 16. Critères d’acceptation

Le lot n’est conforme que si :

- l’Espace Classe est clairement distinct de la Classe Live ;
- l’élève dispose d’un espace calme et pédagogique ;
- l’enseignant dispose d’un espace de préparation sans exposition de PII famille ;
- le bouton Rejoindre respecte la vraie fenêtre serveur ;
- le preflight enseignant vérifie réseau / médias / contexte ;
- le preflight élève reste presque silencieux en situation normale ;
- micro et caméra restent OFF à l’entrée selon la politique Rewayah ;
- aucun système parallèle de Bibliothèque ou de LiveKit n’est recréé ;
- les skeletons existants sont utilisés ;
- le web n’est pas un simple mobile agrandi ;
- les CTAs respectent la grammaire Rewayah ;
- la tâche `LIVE-CHRONO-01` est enregistrée même si son implémentation est différée ;
- le chrono final affiche simultanément le temps écoulé et le temps restant ;
- la reconnexion ne provoque pas de dérive du chrono ;
- le chrono n’est jamais utilisé comme preuve d’assiduité.

---

# 17. Instruction finale à l’orchestrateur

Avant toute implémentation :

1. inscrire cette cartographie dans le suivi partagé ;
2. confirmer les contrats / composants déjà existants ;
3. protéger les lots déjà terminés contre une reprise opportuniste ;
4. préparer les références visuelles nécessaires ;
5. poursuivre la vague verticale courante ;
6. appliquer ces règles au moment où chaque écran concerné entre réellement en implémentation.

**Aucun redesign rétroactif global maintenant.**

Les écarts existants sont enregistrés et seront harmonisés au bon moment, sauf ordre explicite du Directeur.
