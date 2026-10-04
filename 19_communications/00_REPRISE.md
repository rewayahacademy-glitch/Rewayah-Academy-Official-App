# Communications V1 : reprise (lire ceci d'abord)

Chantier ajouté par le directeur le 04/10/2026 (dossier « à faire »). Voies du tableau : **COM** (socle, fusion, captures), puis **COM-MSG**, **COM-VOC**, **COM-COMU**, **COM-STU**, **COM-ANN** en parallèle après COM-F. Une session par voie. Les revues `…-R` sont dans la voie VERIF.

## 1. Règle de style : elle prime sur les maquettes

Décision du directeur, 04/10 : « les différences de styles et thème ne doivent pas influencer, le thème de l'app reste en vigueur, alors si une maquette est différente on prend le layout et le reste sans prendre le nouveau style visuel qu'elle introduit ».

- **On prend dans la maquette** : l'ordre des zones, les proportions, la densité, les panneaux et leurs liens, la place des actions, les textes de la spec.
- **On ne prend pas** : les couleurs, les dégradés, les ombres, les rayons, les polices, les pastilles colorées (vert « Publiée », orange « Planifiée », rose « En attente », les icônes sur fond coloré), le fond lavande pastel des planches. On utilise à la place les tokens, cartes groupées et composants Rewayah qui existent déjà (K-37, K-42, spec §1.3).
- Un écart de style vu sur une maquette n'est **pas** une ligne TH-2. On ouvre une ligne TH-2 seulement s'il manque vraiment un token, sans jamais créer de couleur locale.
- **Shell** : les maquettes montrent toutes « Tuteur » et « Foyer » en navigation, à tort. On prend le shell réel du rôle : Enseignant pour la Communauté, Admin pour l'administration, équipe interne pour Le Studio (spec §1.2, §17).

## 2. Sources

| Quoi | Où |
|---|---|
| Spec du directeur (34 sections, frontend seulement) | `V/REWAYAH_COMMUNICATIONS_FRONTEND_V1.md` |
| Planche mobile A : COM-M01 Messages, COM-M02 Communauté, COM-M03 Studio canal | `V/COM-M01-M03_planche_A_mobile.png` |
| COM-W01 Messages métier, ordinateur | `V/COM-W01_messages_metier.png` |
| COM-W02 Communauté enseignants, ordinateur | `V/COM-W02_communaute_enseignants.png` |
| COM-W03 Le Studio, canal, ordinateur | `V/COM-W03_studio_canal.png` |
| COM-W04 Administration des communications | `V/COM-W04_administration_communications.png` |
| Le Studio en sombre : navigation Aujourd'hui, Discussions, Espaces, panneau À propos | `V/COM-W00-W03_studio_bureau_sombre.png` |

**Maquettes citées par la spec et absentes du dossier** : planche B mobile (COM-M04 Aujourd'hui, COM-M05 Focus, COM-M06 Notifications), COM-W00 `tableau_de_bord_rewayah_pastel.png` et COM-W03F `interface_studio_en_mode_focus.annotate.png`.
- Ces écrans se construisent à partir du texte de la spec (§7, §10, §13, §16).
- Pour COM-W00, on part de la colonne de navigation de la maquette sombre.
- Ce manque ne bloque rien. Il est noté dans QUESTIONS.md.

**Maquette sombre, ce qu'on écarte** :
- l'onglet « Tâches » : la spec §14 refuse un moteur de tâches concurrent ;
- le bouton d'appel vidéo : §32, aucun appel depuis les messages ;
- « Nouvel espace » : aucune création de canal sans capability.

On garde sa structure : navigation, liste des discussions, fil, panneau À propos.

## 3. Frontière

- Le chantier est **frontend seulement** (spec §2). Il n'y a aucun serveur, aucune migration, ni LiveKit, ni push.
- Chaque contrat serveur manquant est écrit dans `COM-BR.md` (K-28) et sera branché à BR-1.
- Les ports sont neutres par défaut, branchés seulement dans main.dart, et la démonstration n'existe jamais en production (K-09, DEMO-ENV-1).
- Une seule fonction a un seul endroit (spec §14). Il n'y a pas de chat libre, pas de DM entre enseignants, pas de marketplace.

## 4. Branche

- Branche commune : `ui/communications-v1`. Elle est créée par COM-F depuis `origin/corrections/revue-directeur-2026-10`, au plus récent. Son worktree est `D:\RA_TUTEUR\com`.
- Chaque voie parallèle a sa sous-branche, créée depuis `ui/communications-v1` après COM-F :

  | Voie | Sous-branche | Worktree |
  |---|---|---|
  | COM-MSG | `ui/com-msg` | `D:\RA_TUTEUR\com-msg` |
  | COM-VOC | `ui/com-voc` | `D:\RA_TUTEUR\com-voc` |
  | COM-COMU | `ui/com-commu` | `D:\RA_TUTEUR\com-commu` |
  | COM-STU | `ui/com-stu` | `D:\RA_TUTEUR\com-stu` |
  | COM-ANN | `ui/com-ann` | `D:\RA_TUTEUR\com-ann` |

- COM-FUS réunit les sous-branches dans `ui/communications-v1` (K-14), jamais dans `main`.

## 5. Découpage

Le découpage est dans `02_DECOUPAGE.md`. L'ordre des étapes sur le tableau va de 1300 à 1353.
