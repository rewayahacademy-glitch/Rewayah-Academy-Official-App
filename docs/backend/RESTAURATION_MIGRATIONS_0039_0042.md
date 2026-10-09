# Restauration de la provenance des migrations 0039–0042

Date : 2026-10-09  
Branche de travail : `codex/backend-migrations-historiques`  
Base : `ccr-1b1bfa0b-m1kvkk` (SHA observé : `3163fb1be623b0e6650a92a5d04b011e79e46bf0`)  
Source : `observation/lot-2026-09-21` @ `0bfc9e46c0ddc4a013273b8ced8a49791e327ba8`

La décision consignée dans l’onglet Questions!B-01-Q1 autorise la restauration des quatre fichiers appliqués mais absents de la branche ccr. Ils ont été repris sans changement sous leurs noms d’origine. Les SHA blob Git sont identiques entre la source et cette branche, ce qui établit l’identité octet pour octet :

| Fichier | SHA blob | Taille source (octets) |
|---|---|---:|
| 0039_budget_observation_repond_sur_la_visite_en_cours.sql | 1e50a938a1a49d487fa19969be75dc02c7e8d20d | 25751 |
| 0040_tuteur_masque_et_annonce_reservee_a_son_enfant.sql | c4a67775fe0d2dbc96dadf7864754ec381a33ab6 | 23660 |
| 0041_les_surfaces_d_invisibilite_oubliees_par_0040.sql | 34152262d4b150af2fa63f40e65b280220fd3f82 | 16558 |
| 0042_etat_presence_fermee_et_jeton_video_verifie_le_compte.sql | c634a7e5b25f9090bbc0cac04503891033bf6bfb | 12315 |

Cette restauration reconstitue la source des migrations historiques déjà présentes au ledger PROD. Elle ne change pas leur contenu, ne les réapplique pas et n’écrit rien dans Supabase.

La validation prévue par Q1 reste à faire sur un PostgreSQL vierge : rejouer `stub_auth`, les migrations dans l’ordre jusqu’à 0043 et les scénarios `scenarios_*.sql`. Aucun résultat de rejeu n’est revendiqué ici.