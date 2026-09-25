# Lot T — Complément Tuteur : tri

Base : `origin/ui/tuteur-v1` @ `92f5cf7` (lots A, B, C, D, E, O, animations intégrés). Branche `ui/tuteur-v1-t`, worktree `D:\RA_TUTEUR\lot-t`. Poste A. 25/09/2026.
Sources : `REWAYAH_TUTEUR_COMPLEMENTS_CONSOLIDES_PROMPT_CLAUDE_V2.md` + 8 planches (`docs de lancement\tutuor image\Tuteur complement`, la n° 8 = la n° 7 datée 2026).
Légende : ✅ présent et vérifié · 🟡 présent, incomplet · ❌ absent · 🔌 dépendance serveur · ➖ non applicable.

## 1. Soldes, recharges, remises, accès (§5, S01 à S11) — le gros manque

| Élément | État | Preuve | Écart |
|---|---|---|---|
| S01 Soldes et recharges, entrée Compte | ❌ | aucune route ni clé i18n | à construire |
| S02 solde d'un profil, bloc fiche élève | ❌ | `fiche_eleve_page.dart:238` (place réservée en commentaire) | à construire |
| Foyer : total + solde par membre | ❌ | `ligne_membre.dart` (classe · accès seulement) | à construire |
| Accueil : ligne de solde discrète | ❌ | `accueil_famille_page.dart` | à construire |
| S03-S06 recharge (profils, répartition, vérifier, résultat) | ❌ | — | à construire, sans paiement réel |
| S07-S08 mouvements, détail, remise liée à une séance | ❌ | — | à construire |
| S09 gérer les accès | 🟡 | `compte/acces_page.dart`, `fiche/acces_page.dart` (lecture de `access_until`) | pas de sélection ni d'action |
| S10-S11 conséquences, résultat d'annulation | ❌ | — | à construire, confirmation désactivée tant que les conséquences sont inconnues |
| Paiements (liste, détail, justificatif) | 🟡 🔌 | `paiements_page.dart`, port indisponible `DB-CPT-03` | pas de détail d'un paiement |
| Moyens de paiement | ❌ 🔌 | commentaire `compte_tuteur_page.dart:44` | explication d'indisponibilité seulement |

Serveur : tables `wallets`, `wallet_entries`, `payouts`, `payout_methods`, `fx_rates`, `sessions.credit_amount_minor` existent (migration 0001) mais « schéma seulement (ADR-003) » : aucune RPC, aucune fonction Edge, aucun paiement. **Conséquence : tout le domaine se construit derrière des ports neutres « indisponible » en production + données de démonstration isolées (K-09). Aucun solde, prix ni succès fictif en production.** Dépendances à déclarer : `DB-FIN-01` lecture des soldes, `-02` mouvements, `-03` devis de recharge, `-04` paiement et attribution, `-05` aperçu des conséquences d'annulation, `-06` annulation d'accès.

## 2. Parcours transversaux (§4)

| Parcours | État | Écart retenu pour le lot T |
|---|---|---|
| Ajouter un profil | 🟡 🔌 | brouillon en mémoire seulement, « proche »/« moi » non créables (DB-FOY-01/02) : hors lot (serveur) |
| Choisir une classe | 🔌 | catalogue fermé en production, contrat sans langue/fuseau (C-14) : hors lot |
| Fiche : photo | 🟡 | **choix Prendre / Choisir / Annuler + mention « ce n'est pas un document d'identité »** |
| Appareils : caméra refusée | 🟡 | **bouton « Ouvrir les réglages »** (si le paquet déjà présent le permet, sinon demande) |
| Appareils : PIN, profils autorisés, retrait en séance | 🔌 | aucun service côté tuteur : hors lot, dépendance déclarée |
| Comprendre un accès | 🟡 | cause absente côté serveur : conforme, rien à faire |
| Planning, travail, support, progression | 🟡 🔌 | ports non branchés (DB-CRS-*) : hors lot |
| Détail d'une séance passée | 🟡 | **lien « Voir les mouvements associés »** (après les mouvements) |
| Historique | ✅ séances / 🔌 observations | rien |
| Notifications | 🟡 🔌 | **filtre Tous / Non lus + « Ce contenu n'est plus disponible »** en démonstration |
| Préférences : apparence | 🟡 | **sélecteur de thème, voir §3** |
| Préférences : animations, taille du texte | 🟡 | interrupteurs sans effet (E-5) : hors lot |
| Informations perso, sécurité, aide, légal | 🟡 🔌 | lecture seule honnête (DB-CPT-01/02/07) : hors lot |
| Routes orphelines | ✅ | `/tuteur/parcours/:eleveId` et `/tuteur/compte/consentements` sont reliées (constats des revues C et A obsolètes) |
| Retour cassé | 🟡 | détail de ressource de la bibliothèque sans `?retour=` (m5 lot C) : **corrigé au passage** |

## 3. Sélecteur de thème (ordre du directeur)

Aujourd'hui : `apparence_page.dart:68-88` = `ChoiceCardGroup` à 3 cartes **empilées verticalement** ; `BasculeTheme` (pilule soleil/lune, en-tête tablette et bureau) ; une seule préférence `preferencesLocalesProvider`, défaut `systeme` ✅, persistée en base locale (Drift) sauf **sur le web : mémoire seulement** (choix perdu au rechargement).
À faire : composant partagé `lib/core/widgets/selecteur_theme.dart`, 3 cases horizontales sur une carte standard, « Selon le système » par défaut, choix mémorisé (y compris web si une dépendance déjà présente le permet, sinon demande), test qui tape chaque case.

## 4. Plan fermé (lignes du tableau, phase « Complément Tuteur », poste A)

| Ligne | Tâche (< 40 min) |
|---|---|
| LT-1 | Sélecteur de thème 3 cases, partagé, persistance, test qui tape chaque case |
| LT-2 | Ports finance neutres + modèles (soldes, mouvements, devis, recharge, accès) + démonstration isolée ; dépendances DB-FIN-01 à 06 consignées |
| LT-3 | Composants partagés : résumé de solde, ligne bénéficiaire (solde + accès), sélection de profils, résultat par profil |
| LT-4 | Foyer (total + solde par membre, Recharger tous, Gérer les accès) et Compte (entrée Soldes et recharges) → S01 |
| LT-5 | S02 : bloc « Solde de [Prénom] » dans la fiche, dernière remise, ligne discrète sur l'Accueil |
| LT-6 | S07-S08 : mouvements (filtres) et détail d'un mouvement / d'une remise |
| LT-7 | S03-S04 : recharge, sélection nominative et répartition |
| LT-8 | S05-S06 : vérifier la recharge et résultat par profil (paiement indisponible en production) |
| LT-9 | S09-S11 : gérer les accès, conséquences, résultat |
| LT-10 | Web : Soldes, Recharge, Accès en deux colonnes (planche 06) |
| LT-11 | Fiche : photo Prendre / Choisir / Annuler ; scanner : Ouvrir les réglages ; retour du détail de ressource |
| LT-12 | Paiements : détail d'un paiement ; séance passée : lien mouvements ; notifications : filtre et cible supprimée |
| LT-13 | Captures 390x844 et 1440x900 clair et sombre + planches maquette \| rendu |
| LT-R | Revue du lot |
| LT-F | Corrections, suite complète, branche publiée |

Questions ouvertes (demandes/T.md) : ordre des cases (planche : Système · Clair · Sombre ; consigne : Clair · Sombre · Selon le système) ; la pilule de l'en-tête reste-t-elle ?
