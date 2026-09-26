# Vague Admin : validation des dossiers (spec 03), reprise

Préparée le 26/09/2026 par le poste B, coordinateur. Le découpage de cette page est aussi inscrit au tableau de suivi (https://claude.ai/artifact/XMVyZJiLTcmMKTnhsbp3sU), étapes `AD-*`.

## À lire, dans cet ordre, et rien d'autre

1. **Règles gelées du directeur** : `projet/ressources:memoire/DESIGN-GOV-2026-09-26.md`. Elles restent immuables jusqu'à une nouvelle décision datée du directeur.
2. **Spec** : `projet/ressources:specs/03_admin_validation_dossiers/03_ADMIN_VALIDATION_DOSSIERS_V1_2.md`.
   - Lire §5 à §16 et §18 à §28.
   - Lire §17 seulement pour les étapes BR-1.
3. **Consignes du tableau** : K-27, K-28, K-35, K-37 et K-38.

## Base de travail

- **Branche** : `ui/admin-v1`, créée depuis `origin/ui/tuteur-v1`.
  - Hash de départ : `73f12c8` ou plus récent, après `git fetch`.
- **Worktree** : `C:\RA\admin`.
- **Pilotage** : ce dossier, `11_admin/`, sur la branche `pilotage/tuteur-v1`.
- **Commandes Flutter lourdes** : `outils/flutter-verrou.ps1 -Dossier C:\RA\admin`.
- **Zones interdites** :
  - `main` et les PR ;
  - `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml` ;
  - le thème et les couleurs (K-37) ;
  - le Coran ;
  - les secrets.
- **Démonstration seulement.** Aucun branchement serveur : tout besoin serveur s'écrit en une ligne dans `AD-BR` (K-28, K-35).
- **Lire le serveur reste permis** (`supabase/`, RLS, RPC) : c'est nécessaire pour les relevés. Le modifier est interdit.
- **Données de démonstration** : synthétiques, avec la mention visible « Démonstration » et « Document fictif » sur les pièces. Aucune vraie identité.
- **Agents** :
  - chaque tâche dure moins de 35 minutes ;
  - Opus pour le design, les rôles et les relevés ;
  - Sonnet seulement pour le mécanique.

## Découpage (dans l'ordre)

| Étape | Contenu | Sortie attendue |
|---|---|---|
| AD-1 | **Relevé du code existant (§3, §24).**<br>• Route ADM-02 et ses deux entrées : Personnes et compteur Accueil.<br>• Les 3 libellés exacts des vérifications, avec leur source i18n et code.<br>• Le champ genre lu et l'endroit où il bloque.<br>• La politique Super Admin : existe-t-elle ?<br>• Le profil admin en lecture seule.<br>• Les composants réutilisables (§26 ter).<br>• Le portail `/attente`.<br>• Chaque fait cité avec `fichier:ligne`. | `11_admin/01_RELEVE.md` |
| AD-2 | **Revue UX 2026 (§4 des règles gelées).**<br>• Confronter chaque disposition `PROPOSITION` aux référentiels.<br>• Pour chacune : la règle, la source, la date, la conclusion. | `11_admin/UX_REVIEW_03_ADMIN_DOSSIERS.md` |
| AD-3 | **Maquettes (6 images, §21 et §26 quater).**<br>• 02A desktop sombre, 02A mobile clair, 02B mobile sombre, 02C desktop sombre, 02D desktop sombre, 02E mobile clair.<br>• Faites après AD-1 (vrais libellés) et AD-2.<br>• Aucune n'existe encore. Le directeur choisit qui les produit : lui (comme pour le tuteur et la classe), ou le poste sous forme de proposition à valider. | Images dans `11_admin/V/`, validées par le directeur avant AD-5 |
| AD-4 | **Socle de démonstration admin.**<br>• Ports (interfaces) des services du §17, sans serveur.<br>• Jeu de données synthétique : enseignant, tuteur, famille dispensée, pièce absente, conflit.<br>• Mention « Démonstration ». | Code et tests |
| AD-5 | **ADM-02A, file des dossiers (§9, §26 ter).**<br>• Mobile 390, tablette 768.<br>• Bureau 1440 en maître-détail : file 336, gap 24, détail 728.<br>• Squelettes de chargement.<br>• Les 7 états avec leurs textes exacts. | Code, tests qui touchent les boutons, 4 captures |
| AD-6 | **ADM-02B, revue du dossier (§10).**<br>• 4 cartes.<br>• Vérifications réelles tirées d'AD-1, aucune inventée.<br>• 8 états. | Idem |
| AD-7 | **ADM-02C, visionneuse de pièce (§11).**<br>• Modale sur bureau, plein écran sur mobile.<br>• Zoom.<br>• Échap et retour de focus.<br>• 6 états. | Idem |
| AD-8 | **ADM-02D refus et ADM-02E validation (§12 à §14, P-ADM-10).**<br>• État de décision réussie.<br>• Cas « résultat inconnu » : jamais de double décision.<br>• « Abandonner le motif saisi ? » | Idem |
| AD-9 | **Politique de genre KYC (§15, décision D-ADM-KYC-GENRE-01).**<br>• Réglage réservé au Super Admin.<br>• Politique désactivée : le genre ne filtre plus rien.<br>• Profil du reviewer. | Idem, tests activé et désactivé en démonstration |
| AD-10 | **Parcours tuteur, famille et titulaire (P-ADM-08, 09, 11).**<br>• Dossier famille sans pièce requise.<br>• `/attente` après un refus, puis Corriger.<br>• Retour après validation. | Idem |
| AD-11 | **Recette (§20, §22, §23).**<br>• Accessibilité : reflow 320, clavier, focus jamais masqué, texte à 200 %.<br>• Planche de validation : 4 captures par écran, publiée en page web (K-21, K-35). | `05_recette/AD/RAPPORT.md` et la planche |
| AD-R | **Revue croisée**, par une autre session. | L'étape passe à « vérifié » |
| AD-BR | **Besoins serveur de la spec (§17, §16, §28)** : RPC, RLS, audit, atomicité, concurrence, politique de genre côté serveur. Une ligne par besoin, rien n'est codé avant BR-1. | Liste dans `11_admin/AD-BR.md` |

Hors périmètre, à ne pas construire (§25) : les comptes du personnel, les suspensions, les rôles, la photo publique, l'onboarding enseignant, les notifications et les e-mails.
