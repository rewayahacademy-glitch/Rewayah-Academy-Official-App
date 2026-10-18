# Passation du 17/10/2026 (après-midi)

Branche d'intégration : `claude/corrections-audit-2026-10-17` (PR brouillon rewayahacademy-glitch/Rewayah-Academy-Official-App#39, base `claude/backend-reprise`). Tout ce qui suit est poussé, contrôles GitHub verts.

## Consignes du directeur pour la session qui reprend

- Ne poser AUCUNE question au directeur sur les corrections de l'audit : elles sont à faire, point. Décider seul avec les specs (`docs/current/`) et la décision `DECISION-ENTREE-2026-10-17.md`, et rendre compte à la fin.
- ChatGPT (Codex) n'est plus disponible depuis longtemps : Claude fait aussi le backend (`supabase/**`, adaptateurs `*_supabase.dart`). `COHABITATION.md` est caduc sur ce point.
- Rien n'est codé en dur : prix, tarifs, échéances, taux, seuils viennent de la base (tables de configuration datées, éditables par la direction). L'app doit durer dix ans et afficher les vrais prix une fois déployée.
- Ne jamais demander au directeur de manipuler GitHub, des permissions ou des réglages. Français simple, réponses courtes, pas de tokens gaspillés à refaire ce qui est fait.
- Pas de tiret cadratin, symbole paragraphe ni emoji. Libellés fr et ar.

## Fait aujourd'hui (présent dans le code, testé localement, poussé)

- Site public rapatrié dans `site-public/` (garde-fou levé par le directeur pour `site-public/` et `parcours_offres`).
- L8 : l'âge demandé une seule fois, en années, par sélection (`lib/features/foyer/choix_age.dart`).
- A1 : ancienne classe `tc_classe_live` supprimée, une seule salle `/salle`.
- F1 : finance visible depuis l'accueil de l'enseignant, de l'élève adulte (`/eleve/finances`) et du tuteur.
- BF1 : migrations `20261017160000`, `160100`, `160200` (revenus enseignant, finances par profil avec `wallet_entries.beneficiaire_id`, invitation comptable) et adaptateurs branchés dans `_surchargesAppReelle()`. Scénario `supabase/tests/scenarios_bf1_finance_backend.sql` (83 contrôles verts en local, Postgres 16).
- F2 : écrans d'invitation et d'inscription du comptable ; natures de mouvement débit de séance, correction, remboursement.
- Textes relus par le directeur appliqués (page https://claude.ai/artifact/Y97XjCb8n3qNxjsoDayubo, toutes les remarques traitées).
- Panneau des agents actifs : `outils/mods/agents-actifs`, catalogue `.claude-plugin/marketplace.json`.

## À faire, dans cet ordre, sans demander

1. **Base de test (projet `xldmmlrnxyabdtvxqbyy`, jamais la production `gggmtelinlpseweouyav`)** : 5 migrations du 17/10 sur 21 appliquées (jusqu'à `af_l1_05`). Appliquer les 16 restantes dans l'ordre, à partir de `20261017100600_af_l1_06_wallet_entries_immuable.sql`. La première tentative a expiré (délai de 60 s de l'outil, aucun verrou trouvé) ; ensuite l'outil a exigé une approbation que la session précédente ne pouvait pas obtenir. Le garde-fou l'autorise désormais sur la base de test.
2. **Facturation et échéances (lots A et B de `07_MEMOIRE_PEDAGOGIE_FINANCE.md`)** : construire le système complet, piloté par des données : grille tarifaire en base (datée, versionnée, éditée par la direction), factures, échéances, « reste à payer » et date de paiement par profil et par foyer, RPC de lecture, écrans tuteur et élève adulte (remplacer la règle provisoire d'état fondée sur le solde seul dans `bf1_02`), écran de saisie direction. Aucun montant dans le code.
3. **Saisie des paiements attribués à un enfant** (écriture de `wallet_entries.beneficiaire_id` par la direction ou le comptable) et création du portefeuille de foyer : sans cela les écrans famille restent sur « pas encore publié ».
4. **L5 inscription** : envoyer la réponse « Suivez-vous aussi des cours ? » et enregistrer le choix Moi ou Famille.
5. **L4 écran de connexion** : deux chemins distincts.
6. **L9** : invitation à consentir sur l'accueil du tuteur.
7. **Fiche de séance** : l'ancienne classe portait une fiche de séance (contrôles R-11, UX-24, UX-17, accessibilité, absence de données personnelles) qui n'a pas d'équivalent dans `/salle`. Vérifier dans les specs ce que la salle doit montrer et le porter dans `/salle` si les specs le demandent.
8. **Lot D / L10, ménage** : clés i18n orphelines (`creneaux.*`, `disponibilites.*` sauf `joursLongs`, `bienvenue.*`, `connexion.decouvrir`, conflits `enseignant.creneaux.*`, `reglagesEnfant.*`, `tuteur.reglages.demande*`, `motifs.reglage*`), 12 clés arabes de contrat manquantes (`tool/ar_socle_non_traduites.txt`, `contrat.a3.*`, `contrat.e1.*`), listes de `tool/`, `docs/current/ENS-PAYS-1_BR.md:24`, et proposition de correction de CLAUDE.md (passages devenus faux sur `tc_classe_live`, les deux salles et ChatGPT).
9. **L11** : tests de capture, dont le cas contrat cassé de `la3_dossier_capture_test`.
10. **Champs saisis à la main restants** (à passer en sélection quand c'est possible) : seuils d'âge des réglages admin (`ConfigLigneEntiere`), fréquence « Autre » du tirage, saisie « Autre » de `SelecteurEntier`, ordre des programmes.
11. Ajouter `scenarios_bf1_finance_backend.sql` à la CI : `.github/` est interdit aux agents, le noter pour le directeur sans lui demander de manipulation.
12. Une fois la base de test à jour : la version de test se met en ligne par le workflow `flutter-deploy.yml` lancé depuis la branche d'intégration (bouton « Run workflow », réservé au directeur par le garde-fou). Le lui signaler en une phrase quand tout est prêt.

## Vérifier avant de dire que c'est fait

`dart run slang`, `dart run build_runner build --delete-conflicting-outputs`, `dart analyze --fatal-infos`, `dart run tool/verifier_jetons.dart`, `dart run tool/verifier_revue.dart` (socle actuel : 1162, n'en ajouter aucune), `flutter test` sur les dossiers touchés. Côté base : Postgres nu, `supabase/tests/stub_auth.sql`, toutes les migrations, puis les scénarios.

## Fait le 17/10 au soir (branche `claude/hopeful-mayer-m7p3hq`, PR brouillon rewayahacademy-glitch/Rewayah-Academy-Official-App#41)

Chaque point : présent dans le code, testé localement ; les migrations sont en plus appliquées sur la base de test (`xldmmlrnxyabdtvxqbyy`) avec des empreintes identiques au rejeu local. Rien sur la production.

1. Base de test : les 16 migrations restantes du 17/10 appliquées, puis FAC-A, FAC-B, FAC-C et L5-01.
2. Facturation : prix versionnés en base et publiés par la direction (FAC-A) ; factures mensuelles, réduction famille, premier mois au prorata, état financier par profil (FAC-B) ; émission des factures du mois depuis l'onglet Paiements.
3. Paiements : onglet « Paiements » de la direction et page « Paiements des familles » du comptable (Trésorerie et accès rapides) ; le paiement est attribué à un élève, l'issue est celle rendue par le serveur.
4. L5 : l'inscription garde « Moi » ou « Famille » et la réponse « Suivez-vous aussi des cours ? » (migration `20261017180000`, `inscrire_titulaire`, `etat_dossier` rend `usage` et `suit_des_cours`) ; « Moi » ouvre la fiche d'élève du titulaire ; `/attente` lit l'usage du serveur.
5. L4 : la connexion propose « J'ai déjà un compte » ou « Créer un compte » ; `/connexion?mode=creer` ouvre la création.
6. L9 : l'invite d'accord des visites est posée sur l'accueil du tuteur, carte entière cliquable.
7. Fiche de séance : portée dans `/salle` pour l'enseignant (compteur « 3/4 », liste des élèves, fiche pédagogique, rappel discret, faire réciter), selon le dossier maître section 10.
8. Ménage : 59 textes orphelins retirés, 12 textes arabes du contrat traduits, `ENS-PAYS-1_BR.md` et `CLAUDE.md` corrigés.
9. L11 : les 2 565 captures passent ; deux vrais défauts corrigés au passage (solde coupé à 320 px texte x2 dans la recharge, « hors ligne » dit deux fois sur le Foyer et les fiches finances).
10. Champs à la main : seuils d'âge et réglages entiers, fréquence du tirage, ordre des niveaux passent au choix pas à pas (`ChoixNombre`).
11. Scénarios SQL : 96 sur 96 verts sur base neuve (`tool/rejouer_scenarios.sh`).

## Pour le directeur (trois phrases, aucune manipulation technique demandée)

- La vérification automatique de GitHub ne rejoue que 15 contrôles de la base sur 96. Un script prêt (`tool/rejouer_scenarios.sh`) les rejoue tous : il suffit qu'une personne autorisée l'ajoute comme une étape de `.github/workflows/ci.yml` (les agents n'ont pas le droit de toucher ce dossier).
- La base de test est à jour : la version de test peut être mise en ligne avec le bouton « Run workflow » de `flutter-deploy.yml`, depuis la branche d'intégration.

## En plus de la liste

- Le bloc hors ligne des écrans du comptable, de la finance de la direction et des revenus de l'enseignant dit ce qui manque au lieu de redire « hors ligne » (EA-HL-DOUBLE-1), comme sur le Foyer.
- Paiement saisi par le comptable (18/10) : la question posée la veille était déjà tranchée par le dossier maître du 14/10 (« Permissions par rôle », ligne « Créditer après paiement manuel » : le comptable rapproche et soumet, la direction approuve). Appliqué : la saisie du comptable arrive dans « À valider » de la direction et n'est créditée qu'après sa validation ; un refus porte un motif que le comptable lit ; la direction qui saisit elle-même crédite tout de suite (lancement avec une seule personne, audit). Migration `20261018090000_fac_d_01_validation_paiements.sql`, appliquée sur la base de test avec empreintes identiques ; scénario `scenarios_fac_d_validation_paiements.sql` ; 97 scénarios sur 97 verts. Leçon : toute question au directeur se vérifie d'abord dans `docs/current/sources-directeur-2026-10/`.
