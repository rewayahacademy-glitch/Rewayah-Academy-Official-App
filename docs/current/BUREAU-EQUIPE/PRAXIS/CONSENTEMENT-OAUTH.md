# PX-OAUTH 2d : la page de consentement (textes, adresse, comportement)

Suite de `PLAN-OAUTH.md` (PX-OAUTH phase 1, PR #627). Écran neuf autorisé par le plan accepté (Pilote Équipe, 17/11/2026) : une page, une tâche, un seul bouton plein.

- **Adresse** : `/admin/securite-audit/praxis-autoriser?demande=<identifiant>` (sous-arbre `/admin` : la direction seule ; sans session, la connexion garde l'adresse en `retour`). La fonction `praxis-oauth` y renvoie la personne depuis `/authorize`.
- **Ce que la page lit** : `direction_praxis_oauth_lire` (client, hôte, état, droit d'autoriser). **Ce qu'elle décide** : `direction_praxis_oauth_decider`, avec la double vérification (feuille du code si la session est en `aal1`) ; le geste est sensible, il attend le serveur et n'est jamais annoncé comme fait avant sa réponse.
- **Le retour** : le navigateur n'est renvoyé que vers `https://claude.ai/api/mcp/auth_callback?code=…` ou `?error=access_denied` (seconde barrière, après la liste blanche de la base). Toute autre adresse : « La décision n'est pas confirmée. Recommencez. » et rien n'est ouvert.
- **États** : chargement (squelette), contenu, vide (demande inconnue), erreur de lecture, hors ligne sans donnée, demande déjà traitée, demande expirée, compte sans côté ouvert à Praxis (« Autoriser » absent).

## Textes (français ; l'anglais et l'arabe suivent le sens)

- Titre : « Autoriser une connexion à Praxis »
- Demande : « « {client} » ({hote}) demande à se connecter à Praxis en votre nom. »
- Demande sans hôte lisible : « « {client} » demande à se connecter à Praxis en votre nom. »
- Ce que Praxis pourra et ne pourra pas faire : les textes de la section Praxis d'« Accès des agents » (« Pourra », « Ne pourra pas »), réutilisés tels quels.
- Durée : « La connexion prend fin au bout de 90 jours au plus. Vous pouvez la couper à tout moment dans Accès des agents. »
- Boutons : « Autoriser » (le seul bouton plein) · « Refuser » (un lien)
- Compte sans côté : « Votre compte n'ouvre aucun côté à Praxis : vous ne pouvez pas autoriser cette connexion. »
- Décision non confirmée : « La décision n'est pas confirmée. Recommencez. »
- Demande déjà traitée : « Cette demande a déjà été traitée » · « Relancez la connexion depuis l'application qui l'a demandée. »
- Demande expirée : « Cette demande a expiré » · « Une demande dure dix minutes. Relancez la connexion depuis l'application qui l'a demandée. »
- Demande inconnue : « Cette demande n'existe pas » · « Relancez la connexion depuis l'application qui l'a demandée. »
- Après « Autoriser » : « Connexion autorisée » · « Retour vers {hote}. Si rien ne se passe, revenez dans l'application qui l'a demandée. » · « Si rien ne se passe, revenez dans l'application qui l'a demandée. »
- Après « Refuser » : « Connexion refusée » · « Rien n'a été autorisé. »
- Lien : « Accès des agents »
- Lecture : « Cette demande n'a pas pu être chargée » · « Cette demande n'a pas pu être lue. Réessayez. »
- Client sans nom : « Un client sans nom »
