# Parcours de bout en bout (ligne d'arrivée), en LOCAL

Tout tourne sur une pile locale : rien n'écrit en production.

```
tool/e2e/pile.sh            # Supabase local (CLI 2.122), Mailpit, fonctions Edge, LiveKit --dev, build web, serveur 8090
tool/e2e/amorcer.sh         # direction + enseignant validé, en SQL local (seuls comptes hors interface)
node tool/e2e/parcours_2.mjs  # puis 3, 4, 5 (dans cet ordre : 4 et 5 réutilisent les données de 2 et 3), puis 1, 6, 8
node tool/e2e/etat.mjs <n>    # reporte le verdict dans docs/current/ETAT-OUVERTURE.md
```

- Captures, journal et verdict : `docs/current/captures/E2E/parcours-<n>/`.
- Réparations de pile (le dépôt `supabase/` n'est pas modifié, une copie est adaptée dans `/tmp/e2e-pile`) :
  numéros de migration en double renumérotés pour le CLI ; SMTP Gmail coupé (Mailpit) et confirmation
  d'e-mail activée ; relais HTTPS (`relais_https.mjs`) car l'application refuse une URL `http` ; clé
  publiable locale (la clé anon locale porte `iss=supabase-demo`, refusée) ; certificat du proxy injecté
  dans le conteneur des fonctions Edge (téléchargement de `jsr.io`).
- Le parcours 2 règle le fuseau de l'enseignant de test pour que la séance commence dans l'heure, quelle
  que soit l'heure UTC ; le parcours 5 attend l'ouverture de la salle (20 minutes avant).
- Prérequis : Docker, Node 22, Flutter stable dans `/opt/flutter`, Playwright dans `/opt/node-tools`.
