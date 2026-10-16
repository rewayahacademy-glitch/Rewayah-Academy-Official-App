# L2-08-reprise - Exception d'âge bornée aux moins de 6 ans ; formulaire client aligné sur 6 ans

Reprise issue de L2-V (défaut D-6). Deux parties : serveur et client.

## 1. But et pourquoi

Dans `20261017110800`, `v_exception` vaut vrai pour tout administrateur valide qui donne un motif, quel que soit l'âge, et il dispense alors de la vérification « l'appelant est ce tuteur » : l'exception dépasse la décision du 13/10 (âge minimum 6 ans, exception tracée par l'administration). Le journal `age_exception` n'est écrit que sous 6 ans. Côté client, `BornesAge.clientActuelle` accepte 3 à 18 ans : un tuteur qui saisit 4 ou 5 ans voit le formulaire accepter, puis un refus serveur générique.

## 2. Critère de réussite

1. Nouvelle migration : `v_exception` exige en plus `p_age < 6` ; au-delà, un motif administrateur est ignoré et la voie tuteur s'applique. Empreintes F86 recalculées.
2. Le scénario `af_l2_08` gagne deux cas : administrateur avec motif pour 7 ans et un autre tuteur : refus 42501 ; administrateur avec motif pour 5 ans : accepté et journalisé.
3. Client : borne basse à 6 ans dans `profil_eleve_brouillon.dart` (lot frontal séparé) ; message d'aide qui dit l'âge minimum.

## 3. Ce qu'il faut lire

- `supabase/migrations/20261017110800_af_l2_08_reglages_decisions_1410.sql` (fonction à sept paramètres).
- `supabase/tests/scenarios_af_l2_08_reglages_1410.sql`.
- `lib/core/foyer/profil_eleve_brouillon.dart` (`BornesAge`).

## 4. Fichiers autorisés et interdits

Serveur : une migration `20261017130800_af_l2_08_reprise_exception_age.sql`, le scénario. Client : `lib/core/foyer/profil_eleve_brouillon.dart`, ses tests. Interdits : migrations existantes.

## 5. Étapes

1. Copier la fonction, changer une ligne, recalculer l'empreinte.
2. Ajouter les deux cas au scénario ; preuve inverse sans la migration.
3. Client : borne 6, tests.

## 6. Vérifications

Rejeu complet, 87 scénarios PASS ; liste blanche PASS ; commandes Flutter du dépôt pour la partie client.

## 7. Pièges connus

- La surcharge à six paramètres délègue avec un motif nul : ne pas la toucher.

## 8. Quand s'arrêter et demander

- Si le directeur veut l'exception pour d'autres cas que l'âge : s'arrêter.

## 9. Commit

- Branches : `lots/L2-08R-exception-age` (serveur), `lots/L2-08R-bornes-client` (client).
- Messages : `fix(config): exception d age reservee aux moins de 6 ans (L2-08-reprise)` ; `fix(foyer): age minimum 6 ans dans le formulaire (L2-08-reprise)`.

## 10. Modèle conseillé

Haiku suffit pour chaque partie.
