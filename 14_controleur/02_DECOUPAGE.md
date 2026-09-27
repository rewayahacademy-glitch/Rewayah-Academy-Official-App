# Vague Contrôleur : découpage en étapes (CT-0 à CT-RC)

## Où et comment

- **Branche proposée** `ui/controleur-v1`, créée depuis la pointe de `ui/enseignant-v1` (1108a4a au 27/09) au moment de CT-1b, avec l'accord de l'orchestrateur.
  - Raison : c'est la branche la plus récente ; elle contient la salle unique `/salle` avec `RoleSalle.controleur`, `PageParcours`, `NavShell` adaptatif à 4 destinations (modèle enseignant), `PhotoEnseignant`, `/compte` et l'outillage de démonstration (`/demo/salle`, `/demo/enseignant`, `environnementAutoriseDemo`).
  - `ui/admin-v1` (2fac423) n'est pas fusionnée (plan `13_fusion`, après BR-1) : rien de l'admin n'est requis pour la démonstration contrôleur.
- **Worktree** nouveau `C:\RA\controleur`. On ne travaille jamais dans `C:\RA\enseignant`.
- **Un seul agent qui committe à la fois** (K-30), tâches de moins de 35 minutes (K-16).
- **Modèles.** Opus pour le design et le code d'écran. Sonnet pour les tests, captures, preuves et relectures. Haiku pour les écritures du tableau.
- **Démonstration seulement** (K-35), aucun serveur (K-28) : les fournisseurs réels restent en place ; la démonstration les surcharge par `/demo/controleur?ecran=…&etat=…`, gardée par `environnementAutoriseDemo`.
- **Besoins serveur (une ligne BR-1)** : capacité Contrôleur datée et bornée par périmètre, projection multi-rôle pour `Compte > Espaces`, attribution pseudo-aléatoire des missions pendant les séances en direct, faits automatiques, rapport transmis automatiquement à la sortie, compléments, fils Admin, journal d'audit, révocation immédiate. Détail dans `CT-BR.md` (CT-10).
- **Définition de « fait »** (K-7) : écran atteint depuis la vraie coquille et un test qui tape le vrai bouton ; `analyze` à 0 ; suite complète relancée après la dernière correction (K-29) ; captures 390, 768, 1440, clair et sombre ; relues par l'orchestrateur avant `verifie`.
- **Interdits** : main, PR, supabase/, .github/, vercel.json, pubspec.yaml ; thème et couleurs (K-37 ; si besoin, une ligne TH-2) ; rendu du Coran ; secrets ; `dart format` sur un dossier (K-23) ; toute traduction avant LG-1 (K-41) ; tout libellé métier absent du document (question au directeur).

## Les étapes

| Étape | Contenu | Réutiliser, sans fork | Modèle, durée |
|---|---|---|---|
| **CT-0** | Préparation : planches classées, comparaison, rectifications, règles C1 à C21, découpage, reprise. | — | fait |
| **CT-1a** | `UX_REVIEW_08_CONTROLEUR.md` (DESIGN-GOV §4) : sources officielles datées (doc §18 : ICO monitoring, DPIA, Children's Code, WCAG 2.2, M3, HIG, OWASP) et décision par écran. Document seulement, **obligatoire avant le code**. | modèle `12_enseignant/UX_REVIEW_04_ENSEIGNANT.md` | Opus, 30 min |
| **CT-1m** | `CONTROLEUR_EXISTING_MAPPING.md` (doc §17.2-3) : preuves fichier:ligne de CTR-01, `/salle` contrôleur, `/compte` Espaces, `NavShell`, composants ; carte fonction → route → composant → modification minimale. Document seulement. | `00_REPRISE.md` de cette vague | Sonnet, 25 min |
| **CT-1b** | Socle, en quatre parties (détail sous le tableau). | `nav_shell.dart`, `enseignant_demo.dart`, `demo_enseignant_page.dart`, `outil_capture.dart` | Opus, 35 min |
| **CT-2** | CTR-01 Contrôle refondu : un seul emplacement de mission (C14), ligne calme puis « Commencer le contrôle » quand la séance est en direct (C1), « Compte rendu à terminer », une ligne de charge (C11) ; états : chargement, aucune mission, séance pas encore en direct, en direct, mission indisponible, hors ligne, accès retiré ; deux colonnes sur bureau. Retrait du planning global. | `PlanningControleurPage` (remplacée), `ActionPrincipale`, `AppCard`, `EtatSysteme`, `EmptyState`, `Skeleton`, `OfflineBanner`, `PhotoEnseignant` | Opus, 35 min, puis Sonnet pour tests et captures |
| **CT-3** | CTR-02 Observation dans `/salle` rôle contrôleur : zone haute « Contrôle Rewayah », état réseau, Son reçu, Agrandir le support, Quitter (secondaire) ; tests des interdits (micro, caméra, chat, main levée, annotation…) ; reconnexion réelle ; sortie → CTR-03. | `salle_page.dart`, `vue_salle.dart`, `PageImmersive`, `_Rappel` existant, `PermanentNotice` | Opus, 35 min |
| **CT-4** | CTR-03 Compte rendu, écran initial : faits automatiques repliés en tête (C4), question, trois cartes sans présélection, « Rien à signaler » en une action, notice de transmission automatique (C2), « Plus tard » → bloc à terminer, `EcranResultat` avec lien « Écrire à l'administration ». | `PageParcours`, `ChoiceCardGroup`, `LigneCleValeur`, `EcranResultat`, `LocalFeedback` | Opus, 35 min |
| **CT-5** | CTR-03A Observation structurée : nature, domaine, personne concernée (roster autorisé, prénom seulement), texte, récapitulatif, « Envoyer le compte rendu » ; « Signaler un point important » ; brouillon en mémoire seulement (C12). | `PageParcours`, `PageEtape`, `ChoiceCardGroup`, `GroupeReglages`, `LigneCleValeur` | Opus, 35 min |
| **CT-6** | CTR-04 Échanges : liste de fils (Réponse reçue, En attente), fil avec contexte épinglé, champ de réponse ; démonstration sans envoi réel (E7). Nouveau composant de fil, générique, dans `lib/core/widgets/` (aucun n'existe). | `PageShell`, `GroupeReglages`, `SignalRow`, `StatusPill`, `EmptyState` | Opus, 35 min |
| **CT-7** | CTR-05 Historique (filtres Période, Classe, État ; lignes groupées ; C18) et CTR-06 Détail (Mission, Faits automatiques, Observation, Compléments, Échanges ; aucune édition). | `DataCollection`, `FilterPill`, `MenuFiltre`, `GroupeReglages`, `LigneCleValeur`, `SectionHeader` | Opus, 35 min |
| **CT-8** | CTR-03B Complément : même parcours, bandeau « Ce complément sera ajouté au rapport existant. », rapport parent intact (C10). | le parcours de CT-5, `PermanentNotice` pour le bandeau si la signature le permet, sinon `EtatSysteme` | Opus, 25 min |
| **CT-9** | Commutation et états transverses : Enseignant et Admin → Contrôle par `Compte > Espaces` (démonstration), raccourci d'en-tête vers le même sélecteur, retour après sortie de mission ; utilisateur sans capacité ; accès révoqué pendant la navigation (P-CTR-01) ; mission indisponible (P-CTR-08) ; propre Classe exclue. | `compte_page.dart` (`_espacesPour`), `NavShell`, `EtatSysteme` | Opus, 35 min |
| **CT-10** | Lexique (`fr.i18n.json`, C16, textes contrôleur seulement), `CT-BR.md` (besoins serveur, doc §9-11), lignes au tableau : 15 bloquants sécurité et légal (doc §15), impacts Enseignant (§12), Admin (§13), Tuteur (§3.4). | `fr.i18n.json`, modèle `12_enseignant/EN-BR.md` | Sonnet, 30 min |
| **CT-11** | Revue frontière des données visibles (doc §17.14) : test qui parcourt chaque écran de démonstration et vérifie l'absence des champs interdits (C8) ; aucune donnée de démonstration en production (recette 32). | tests existants de `/demo`, `environnementAutoriseDemo` | Sonnet, 30 min |
| **CT-12** | Recette : les 32 scénarios du doc §16 ; captures 390, 768, 1440, clair et sombre, texte 200 %, RTL structurel, clavier ; rapport `05_recette/CT/CT_RAPPORT.md` en français simple. | `captures_en_test.dart`, `outil_capture.dart` | Sonnet, 35 min, en deux agents si besoin |
| **CT-R** | Revue croisée par une autre session : contre C1 à C21, R1 à R21, K-42, DESIGN-GOV contrats A à E, et les deux décisions du 27/09. | modèle `05_recette/CL/REVUE_CL-4.md` | Opus, 30 min |
| **CT-RC** | Corrections de la revue, puis la planche web du directeur (format CL-4), publiée par l'orchestrateur. | — | Opus, 35 min |

**Détail de CT-1b, le socle.**
1. Coquille contrôleur à 4 destinations (C13) : Contrôle `/controleur`, Historique `/controleur/historique`, Échanges `/controleur/echanges`, Compte `/compte`. Pages provisoires pour les trois nouvelles routes. Note dans le code : le choix « une seule destination, sans barre » est remplacé par le doc 08 du 27/09.
2. Données de démonstration `lib/features/demo/controleur_demo.dart` : missions (aucune, séance pas encore en direct, en direct, indisponible), faits automatiques, roster minimal, rapports (Envoyé, Complément ajouté, À terminer), fils Admin, trois profils (contrôleur externe, Enseignant-Contrôleur, Admin-Contrôleur), dates 2026, données cohérentes (C19).
3. Route `/demo/controleur`, gardée par `environnementAutoriseDemo`.
4. Squelette `test/features/controleur_recette/captures_ct_test.dart`.

## Ordre et dépendances

1. CT-1a et CT-1m (documents, en parallèle), puis CT-1b.
2. CT-2, CT-3, CT-4, CT-5, dans l'ordre (le parcours mission → salle → compte rendu).
3. CT-6, CT-7, puis CT-8 (dépend de CT-5 et CT-7).
4. CT-9 (dépend de CT-1b et CT-2).
5. CT-10 et CT-11, puis CT-12.
6. CT-R, puis CT-RC.

Chaque étape passe par trois états : `fait` avec une preuve (commit, tests, captures) ; l'orchestrateur relit les captures ; puis `verifie`.
