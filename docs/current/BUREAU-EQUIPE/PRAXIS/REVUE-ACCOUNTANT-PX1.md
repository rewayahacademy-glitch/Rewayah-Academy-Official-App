# PX-1 : relecture des 24 fonctions qui citent `accountant` (condition d'AR-1, 16/11/2026)

Le compte Praxis a le rôle `accountant`, le statut `disabled`, aucune session et aucune identité de connexion. Pour chaque
fonction qui cite `'accountant'` (relevé en production, lecture seule du schéma), pourquoi Praxis n'y gagne rien et n'y
apparaît pas comme destinataire. Deux raisons couvrent presque tout : (a) la fonction décide **d'après la session de
l'appelant** (`auth.uid()`, `app_role()`), et Praxis n'a jamais de session (R3) ; (b) la fonction filtre sur un compte
**actif** (`account_status = 'active'` ou `app_account_valid()`), et Praxis est `disabled`.

| Fonction | Ce qu'elle fait de `accountant` | Pourquoi Praxis n'y gagne rien, ni n'y est destinataire |
| :--- | :--- | :--- |
| `private.com_est_partie` | un `accountant` est « équipe » d'un fil `profilPaiement` | (a) paramètre `p_moi` = l'appelant humain ; Praxis écrit par `praxis_ecrire`, jamais par cette fonction |
| `private.com_lit_annonce_generale` | un `accountant` lit les annonces générales | (a) lecture d'un appelant authentifié |
| `private.fac_lecteur_politique`, `private.fac_saisisseur` | droit de lire / saisir la facturation | (a) décidé par la session de l'appelant |
| `private.notifier_direction` | destinataires : `admin`, et `accountant` si une destination comptable est donnée | (b) filtre `account_status = 'active'` : Praxis exclu. **Prouvé** par le scénario R13 (notification par rôle, aucune ligne pour Praxis) |
| `private.pai_releve_autorise`, `private.paiement_portee` | droit de lire le relevé de paie | (a) session de l'appelant |
| `private.personnel_actif` | « ce profil est-il du personnel actif ? » | (b) rend faux pour un compte `disabled` |
| `private.push1_apres_notification` | route une notification vers le push selon le rôle du destinataire | Praxis ne reçoit aucune notification (b) |
| `private.push_compte_autorise` | « ce compte peut-il recevoir un push ? » | (b) faux pour `disabled` |
| `private.suppr_retirer` | retire un profil (suppression de compte) | **Dette nommée** : un administrateur qui passerait l'identifiant de Praxis pourrait la déclencher. Aucune liste ne l'expose (R13), donc aucun écran ne le propose ; une garde propre à `private.comptes_officiels` n'est pas ajoutée ici (domaine des suppressions) |
| `private.versement_direction`, `private.versement_note_autorise` | droit sur les versements | (a) session de l'appelant |
| `public.accorder_mission` | un `accountant` actif peut porter une mission | (b) refuse un compte non actif : Praxis ne peut pas recevoir de mission |
| `public.autoriser_lecture_version` | lecture d'une ressource de bibliothèque selon le rôle | (a) |
| `public.capacites_referentiel_paiement`, `public.enregistrer_ligne_referentiel_paiement`, `public.lire_referentiel_paiement`, `public.options_paiement_confirmees` | référentiel de paiement, lu ou écrit par rôle | (a) |
| `public.com_mes_capacites` | capacités de messagerie de l'appelant | (a) |
| `public.emettre_factures_mois`, `public.enregistrer_paiement`, `public.series_tresorerie` | facturation, paiements, trésorerie | (a) |
| `public.inscrire_comptable_invite` | crée un `accountant` à partir d'un code d'invitation | sans objet pour Praxis (compte créé en base, pas par invitation) |

Résultat : 23 fonctions sans effet pour Praxis ; 1 dette nommée (`private.suppr_retirer`, par identifiant). Le comptage de
24 est celui du relevé du pilote ; la lecture de production du 16/11 en trouve 24 (23 avec `accorder_mission`, ajoutée par
BE-2a-1, comprise).
