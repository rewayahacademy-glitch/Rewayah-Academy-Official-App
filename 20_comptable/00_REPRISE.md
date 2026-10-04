# Comptable V1 (Finance opérationnelle) : reprise

Déposé le 04/10/2026 par la session 268bd1ef (poste A), à la demande du directeur : « dépose cette nouvelle étape et découpe-la pour que les sessions ne se gênent pas en parallèle ». La session locale du poste A planifie seulement ; l'exécution revient aux sessions cloud.

## 1. Règle de style (directeur, 04/10, K-63)

« Les différences de styles et thème ne doivent pas influencer, le thème de l'app reste en vigueur, alors si une maquette est différente on prend le layout et le reste sans prendre le nouveau style visuel qu'elle introduit. »

La spec dit la même chose (§3) : les maquettes valent pour la composition, la hiérarchie, la densité, la place des actions, la relation liste / détail / contexte, jamais pour une couleur, un shell ou une police. Les polices citées par la spec (§3.3, R-FIN-27, 28) ne s'appliquent que si ce sont déjà celles de l'application : sinon, ne rien changer et écrire une ligne TH-2 (K-37).

## 2. Sources

- `V/REWAYAH_FINANCE_OPERATIONNELLE_COMPTABLE_V1.md` : spec de référence, 62 sections (frontière §1, recettes §50 à §57, plan §58, critères de fin §61).
- `V/CPT-H00_reference_sombre.png` : la planche que la spec désigne comme référence de composition prioritaire (§3.3, « première high-fi Finance dark intégrale », à confirmer par CPT-0).
- `V/CPT-H01` à `CPT-H08` : autres planches, non homogènes (§3.1). Noms d'origine dans le dossier « à faire\compta » du directeur ; correspondance gardée dans l'historique git de ce commit.
- Rôle existant : `17_finance/` (Finance V1, branche `ui/finance-v1`), `AppRole.accountant`, route `/comptable` qui affiche aujourd'hui `ComptePage` (17_finance/00_REPRISE.md:72).

## 3. Frontière

Frontend seulement (spec §1.1) : aucune migration, RLS, RPC, webhook, secret, intégration Stripe / Verto / pawaPay / Wise, aucun vrai paiement, aucune vraie coordonnée bancaire. Tout passe par des ports neutres, démo hors production (K-09). Les contrats serveur vont dans `CPT-BR.md` (K-28). Interdits habituels (K-19) inchangés.

## 4. Branches

`ui/comptable-v1` (base, worktree `D:\RA_TUTEUR\cpt`) depuis `origin/ui/finance-v1` après FI-VAGUE-CORR ; sous-branches `ui/cpt-pay`, `ui/cpt-tres`, `ui/cpt-enc`, `ui/cpt-ben`, `ui/cpt-ctr`, `ui/cpt-dir`, chacune avec son worktree `D:\RA_TUTEUR\cpt-<voie>`. Fusion par CPT-FUS seulement. Jamais `main`.

## 5. Lien avec Communications V1

« Relancer » réutilise Messages métier (spec §27, R-FIN-21) : port neutre posé par CPT-F, branché sur le vrai fil par CPT-COM après COM-FUS. Aucune messagerie Finance.

## 6. Découpage

Voir `02_DECOUPAGE.md` (généré) : 18 étapes, 8 voies (CPT, CPT-PAY, CPT-TRES, CPT-ENC, CPT-BEN, CPT-CTR, CPT-DIR, VERIF) plus CPT-Q.
