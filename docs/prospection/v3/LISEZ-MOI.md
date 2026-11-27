# Prospection v3 (27/11/2026)

« Vas-y » du directeur le 27/11/2026 pour le lundi 30/11 ; salutation « Assalamu alaykum » et signature
« Directeur, Rewayah Academy » validées. Rewayah Academy se présente comme le **complément en ligne** des cours
sur place, pour les familles qui ne peuvent pas venir (place, horaires, distance), jamais comme une concurrente.

- `lettres.py` : une lettre par culture (`en_uk`, `en_na`, `en_oc`, `en_eu`, `fr`, `fr_qc`, `ar`), deux objets
  chacune, et une relance unique par langue. Hadith « الدال على الخير كفاعله » (at-Tirmidhî 2670, vérifié sur
  dorar.net) ; la relecture par un enseignant exigée par la règle de marque n'a pas eu lieu : le « vas-y » du
  directeur en tient lieu.
- `plan.py` : plan d'une journée (destinataires de la feuille rapprochés le 27/11, paquets de taille aléatoire,
  heures ouvrables du destinataire, 20 % sans image tirés au hasard).
- `migration.py` : fabrique la migration du jour (`supabase/migrations/20261205100000_prospection_v3_jour1.sql`).
- Espagnol et portugais : non envoyés (pas d'accord du directeur).
