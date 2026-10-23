# E-mails de l'application (COURRIELS-1, 23/10/2026)

Demande du directeur, 23/10/2026 : « une app capable d'envoyer des e-mails pour tous ses besoins,
automatiquement ou manuellement selon la situation » ; « chaque catégorie correspond à l'alias e-mail
dédié » ; « des templates légers au branding, qui n'ont pas besoin de temps pour se charger dans Gmail ».

Statuts : **présent dans le code, testé localement** (SQL 29/29 sur base neuve, séquence CI 16/16,
Deno 7/7) ; **migration installée sur staging** le 23/10 (7 catégories, 2 déclencheurs, tâche
planifiée) ; fonctions Edge **non déployées** ; **rien en production**.

## 1. Ce qui envoie quoi

| Catégorie | Part de | Réponses vers | Quand | Désinscription |
| :--- | :--- | :--- | :--- | :--- |
| `compte` | support@ | support@ | lien de connexion, confirmation, invitation au foyer, changement d'adresse | non (essentielle) |
| `inscription` | contact@ | contact@ | demande reçue, présentation, classe prête, demande clôturée | non |
| `classes` | support@ | support@ | enseignant affecté, remplacements, changement de classe, missions de contrôle | non |
| `facturation` | invoice@ | invoice@ | relance avant échéance, accès suspendu, accès rétabli | non |
| `recrutement` | recrutement@ | recrutement@ | messages manuels aux candidats | non |
| `direction` | contact@ | contact@ | message libre écrit par la direction | non |
| `nouvelles` | contact@ | contact@ | annonces de l'académie | **oui**, lien + en-tête un clic |

Les alias se changent sans code : écran « E-mails » de la direction, ou RPC
`admin_courriel_categorie_regler`. Une adresse hors `@rewayahacademy.com` est refusée par la base.

- **Automatique** : chaque ligne de `notifications` (toutes les fonctions existantes qui notifient)
  et chaque invitation au foyer met un e-mail en file (`courriels_sortants`) ; `pg_cron` appelle
  `courriels-envoi` chaque minute ; 5 essais espacés (1, 4, 9, 16 min), puis « échec » visible.
- **Manuel** : la direction écrit à une personne (profil ou adresse) dans la catégorie de son choix ;
  un double clic n'envoie qu'une fois (clé d'idempotence) ; elle relance un échec.
- **Jamais** : à un compte enfant (adresse technique `child_of`) ; une catégorie non essentielle à
  une adresse désinscrite ; un détail sensible dans le corps (l'e-mail ouvre l'application).
- **Connexion** : Supabase Auth envoie ses six e-mails lui-même, par le même SMTP, depuis support@,
  avec `supabase/templates/*.html` (générés du même gabarit par `supabase/templates/generer.ts`).

## 2. Le gabarit

`supabase/functions/_shared/courriel/gabarit.ts` : une table, styles en ligne, aucune police web,
aucun script, logo en tête et ornement au pied en PNG transparents (3,3 Ko et 0,5 Ko, servis par le
site : `/fr/assets/courriel-*.png`). Environ 3 Ko par message (Gmail coupe à 102 Ko). Couleurs de
`lib/core/theme/app_palette.dart`. Version texte jointe à chaque envoi. Typographie française
(espaces insécables) appliquée au rendu.

## 3. À faire une fois, par le directeur (dans cet ordre)

1. **Google Workspace** (admin.google.com) : choisir le compte d'envoi (celui qui porte les alias
   support@, contact@, invoice@, recrutement@). Gmail de ce compte, Paramètres, Comptes, « Envoyer
   des e-mails en tant que » : chaque alias doit y figurer. Sécurité du compte : validation en deux
   étapes, puis un **mot de passe d'application** (« Rewayah app »).
2. **Créer l'alias `dmarc@`** (rapports DMARC, voir §4).
3. **Supabase, projet de production**, Edge Functions, Secrets :
   `SMTP_UTILISATEUR` (adresse du compte), `SMTP_MOT_DE_PASSE` (mot de passe d'application),
   `COURRIELS_ENVOI_SECRET` (longue chaîne aléatoire). Optionnel : `COURRIEL_TRANSPORT=journal`
   pour une recette sans envoi réel.
4. **Supabase, Authentication, SMTP Settings** : activer, hôte `smtp.gmail.com`, port `465`,
   utilisateur et mot de passe ci-dessus, expéditeur `support@rewayahacademy.com`, nom
   « Rewayah Academy ». Puis **Email Templates** : coller chaque fichier de `supabase/templates/`
   (ou `supabase config push`).
5. **Supabase, SQL, Vault** : deux secrets nommés `courriels_envoi_url`
   (`https://<projet>.supabase.co/functions/v1/courriels-envoi`) et `courriels_envoi_secret`
   (la même valeur que `COURRIELS_ENVOI_SECRET`). Sans eux, la tâche planifiée ne fait rien.

## 4. DNS (Cloudflare) pour arriver en boîte de réception

Ne pas toucher au MX ni au SPF existant (`v=spf1 include:_spf.google.com -all` : il couvre déjà
l'envoi par Workspace). À ajouter :

1. **DKIM** : console Workspace, Gmail, Authentifier les e-mails, générer (2048 bits, préfixe
   `google`), poser le TXT `google._domainkey`, « Démarrer l'authentification ».
2. **DMARC**, après DKIM : TXT `_dmarc` = `v=DMARC1; p=quarantine; rua=mailto:dmarc@rewayahacademy.com`.
   `p=reject` après un mois sans rejet légitime.

## 5. Vérifier

- Base : `psql -f supabase/tests/scenarios_courriels.sql` sur base neuve (stub + migrations).
- Gabarit : `deno test --allow-read supabase/functions/_shared/courriel/`.
- Bout en bout (staging, `COURRIEL_TRANSPORT=journal`) : créer une notification, attendre une
  minute, `admin_courriels_lister()` montre « envoye ». Puis en réel vers une boîte Gmail et une
  boîte Outlook : en-têtes `dkim=pass spf=pass dmarc=pass` (« Afficher l'original »), lien
  « Se désabonner » de Gmail présent pour `nouvelles` seulement.
- Désinscription : la page `/fr/courriels/desinscription?jeton=…` demande confirmation ; un simple
  GET ne désinscrit jamais (les antivirus ouvrent les liens).

## 6. Limites connues

- Workspace : environ 2 000 envois par jour et par compte. Au-delà, `COURRIEL_TRANSPORT=resend`
  (clé `RESEND_API_KEY`, domaine vérifié chez Resend, DKIM sur un sous-domaine).
- Les e-mails sont en français ; les autres langues de l'application suivront avec la langue du profil.
- Les candidatures (branche `claude/lucid-mccarthy-qpk6yq`) n'ont pas encore d'e-mails
  automatiques ; la direction leur écrit dans la catégorie `recrutement`.
