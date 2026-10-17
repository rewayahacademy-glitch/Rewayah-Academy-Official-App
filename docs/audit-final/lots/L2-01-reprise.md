# L2-01-reprise - `b09_remplacements` et `af_l2_01` ne dépendent plus du jour ni de l'heure

Reprise issue de L2-V (défaut D-1). Petit lot, scénarios seulement.

## 1. But et pourquoi

La création d'une classe (`weekday`, `hour_local`) matérialise ses séances. Dans `scenarios_b09_remplacements.sql`, la classe est le lundi à 18 h (Paris) et les séances de test sont posées à `clock_timestamp() + 2 days` et `+ 3 days`. Lancé un vendredi ou un samedi entre 17 h et 19 h (Paris), le scénario heurte `sessions_no_teacher_overlap` (ligne 106, l'erreur mesurée le 16/10). `scenarios_af_l2_01_jeton_remplacant_retrait.sql` recopie la même installation (ligne 73), et sa séance `...203` (`+ 5 days 3 hours 17 minutes`, classe le mercredi à 9 h) a le même défaut. La CI deviendrait intermittente.

## 2. Critère de réussite

1. Aucune séance de test de ces deux scénarios ne peut chevaucher une séance matérialisée, quel que soit le moment du lancement.
2. Preuve : chaque scénario passe sur base neuve, et passe encore quand `clock_timestamp()` est remplacé dans une copie par un instant de vendredi 17 h 30 (Paris) (méthode de L2-V : `sed` sur la ligne de la séance).
3. Aucune assertion modifiée, aucune migration touchée.

## 3. Ce qu'il faut lire

- `supabase/tests/scenarios_b09_remplacements.sql` lignes 38 à 110.
- `supabase/tests/scenarios_af_l2_01_jeton_remplacant_retrait.sql` lignes 48 à 152.
- `docs/audit-final/verifications/L2-V-2026-10.md` section 2 (mesure et simulation).

## 4. Fichiers autorisés et interdits

Autorisés : les deux scénarios ci-dessus. Interdits : migrations, `lib/**`, `.github/**`.

## 5. Étapes

1. Choisir pour chaque séance de test une heure qui ne tombe jamais sur le créneau de la classe : par exemple `date_trunc('day', clock_timestamp() at time zone 'Europe/Paris') + interval '3 days 3 hours'` ramené en `timestamptz` (3 h du matin, Paris), ou poser la classe de test sur une heure qui ne peut pas coïncider (`hour_local` 3) ; garder les écarts relatifs utiles au test (séance à venir, fenêtre d'entrée ouverte par `join_opens_at`).
2. Pour `af_l2_01`, faire de même pour `...202` et `...203`, et vérifier que la séance passée `...204` reste passée.
3. Rejouer sur base neuve, puis les deux copies simulées.

## 6. Vérifications

- `b09_remplacements` et `af_l2_01` PASS sur base neuve ; PASS sur les copies figées au vendredi 17 h 30 et au vendredi 5 h 30 (Paris).
- Rejeu complet : 87 scénarios PASS.

## 7. Pièges connus

- La matérialisation suit le fuseau de la classe : raisonner en heure de Paris, pas en UTC.
- `+ 3 days` garde l'heure du lancement : c'est la cause, ne pas seulement changer le nombre de jours.

## 8. Quand s'arrêter et demander

- Si une assertion dépend de l'heure exacte choisie (fenêtre d'entrée), s'arrêter et la nommer.

## 9. Commit

- Branche : `lots/L2-01R-scenarios-sans-heure`, partie de `lots/V2-candidate`.
- Message : `test(sql): b09 et af_l2_01 independants du jour et de l heure (L2-01-reprise)`.

## 10. Modèle conseillé

Haiku suffit.
