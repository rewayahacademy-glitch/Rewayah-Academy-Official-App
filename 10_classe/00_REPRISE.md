# Classe et visio : fiche de reprise (à lire en premier)

Préparée le 25/09/2026 par le poste B (coordinateur), à la demande du directeur : « sur ta prochaine séance tu commences direct, sans config ». Tableau de suivi : https://claude.ai/artifact/XMVyZJiLTcmMKTnhsbp3sU (lignes `CL-*`, consigne K-27).

## 1. Ce qui est déjà prêt (rien à configurer)

| Élément | Où |
|---|---|
| Branche de la vague | `ui/classe-v1`, partie de `ui/tuteur-v1` @ 3b41b12, poussée sur origin |
| Worktree | `C:\RA\classe` (paquets déjà récupérés, `flutter pub get` code 0) |
| Spec du directeur (CLV-01 à CLV-10) | `C:\RA\ressources\specs\02_classe_et_visio\02_CLASSE_ET_VISIO.md` |
| 10 images de référence (sombre, mobile, web étroit, desktop) | `C:\RA\ressources\lancement\classe image\` |
| Avis du directeur + décisions D1-D10 | `10_classe/02_DIRECTION_VISUELLE.md` (**prime sur les images**) |
| Inventaire du code existant pour la salle | `10_classe/01_INVENTAIRE_CODE.md` |
| Backlog déjà connu (micro absent des manifestes, deux salles, jeton vidéo, fenêtres d'entrée) | `08_BACKLOG_VAGUE_CLASSE_VISIO.md` |
| Gabarits G1-G9 et méthode sans maquette | `01_visuel/GABARITS.md` |
| Charte des consentements (enregistrement, observation) | `09_consentements/CHARTE.md` |

**À retenir de l'inventaire (agent Sonnet, 25/09, preuves dans `01_INVENTAIRE_CODE.md`)** : LiveKit (livekit_client 2.12.0, jeton serveur, webhook, présence) marche déjà dans **deux salles concurrentes**, `/salle` (`lib/features/salle/salle_page.dart`) et `/tc/classe` (`lib/features/tc_classe_live/classe_live_page.dart`). Le support partagé et les outils enseignant existent en code mais ne sont pas branchés (`lib/features/tc_mes_groupes/routes_tc_a.dart:70-82` passe `null`). Les contrats serveur de la spec §8 ont des équivalents dans `supabase/migrations/0033_tc_vues_rpc.sql` : **les mapper, ne jamais en créer de doublon**. Le retour « Revenir à la séance » n'existe pas. Le registre du 24/09 est en partie dépassé : revérifier au commit courant.

Commandes lourdes : toujours `& C:\RA\pilotage\outils\flutter-verrou.ps1 -Dossier C:\RA\classe -Commande "flutter <cmd>"`.

## 2. Ordre de travail et attribution

La règle : **aucun écran codé avant que le directeur ait validé les planches (CL-1)**. Tâches d'agent < 35 min, Sonnet pour inventaires, revues et tests.

| Lot | Poste | Contenu | Dépend de |
|---|---|---|---|
| **CL-1** | B (moi, Opus) | Planches de la salle refaite selon D1-D10 : une page artifact, mobile + desktop, clair + sombre, pour élève, guidée, enseignant ; états : support partagé, rien de partagé, mode focus, observation, reconnexion ; panneaux Élèves et Supports ; navigation web. Validation du directeur. | rien, **premier travail de la prochaine séance** |
| **CL-2** | B | Fondations : plan de fusion des deux salles (`/salle` et `/tc/classe`, garder la plus complète, prendre le meilleur de l'autre) ; permissions micro/caméra (manifeste Android, Info.plist iOS) ; fenêtre d'entrée unique (serveur) ; vérification du jeton vidéo (migrations 0042/0043). Tout ce qui touche serveur ou fichiers plateforme = **accord écrit du directeur** avant d'agir. | CL-1 en parallèle (plan seulement) |
| **CL-3** | B (agents) | Socle commun de la salle (D9) : `SalleSeance`, `ChromeSeance`, `ZoneSupport` (+ vide + focus), `VignetteVideo`, `DockSeance` (standard / guidée / enseignant), `PastilleSeance`, `BandeauConnexion`, `PanneauSeance`, `ResultatSeance`. Tests et captures. Devient le gabarit G10. | CL-1 validé |
| **CL-4** | A | Entrée : CLV-01 Espace Classe élève, CLV-02 Espace Classe enseignant, CLV-03 Préparation technique. | CL-3 |
| **CL-5** | A | Salle élève : CLV-04 standard, CLV-05 Interface guidée, CLV-09 Fin de séance élève. | CL-3 |
| **CL-6** | B (agents) | Salle enseignant : CLV-06, CLV-07 Élèves (enseignant **uniquement**), CLV-08 Supports, CLV-10 Fin de séance enseignant. | CL-3 |
| **CL-7** | A | Résilience : reconnexion (P05), réseau faible (P06), micro refusé (P09), caméra interdite (P10), séance prolongée (P11), salle terminée ou accès retiré (P12). | CL-4, CL-5 |
| **CL-R** | cloud ou Sonnet | Revue adversariale de chaque lot (rôle effectif respecté, rien d'interdit affiché, jetons du thème, i18n). | chaque lot |
| **CL-F** | B | Intégration dans `ui/classe-v1`, analyze + suite complète, recette §9 de la spec, dont une **vraie rencontre** élève-enseignant sur deux appareils (§9.1). | tous |

Poste A : prend CL-4, CL-5, CL-7 **après** avoir terminé le lot T (Tuteur). S'il est éteint, le poste B les donne à ses agents.

## 3. Décisions à demander au directeur (courtes, au bon moment)

1. Valider les planches CL-1 (et D6 : Interface guidée en mode focus par défaut ?).
2. Accord écrit pour CL-2 : fichiers plateforme micro/caméra, migration du jeton vidéo, contrats serveur de la spec §8.
Rien d'autre. Ne pas parler du questionnaire d'accueil (gelé).

## 4. Hors de cette vague (ne pas commencer)

Validation des dossiers enseignants par l'admin (spec admin), lecteur du Coran fidèle (après la visio), cahier pédagogique complet, bibliothèque complète.
