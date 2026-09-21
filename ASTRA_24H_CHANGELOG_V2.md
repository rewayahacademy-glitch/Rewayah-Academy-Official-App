# Astra Core24 V2

## Base et ownership

- CORE24_BASELINE_SHA : `d5eb74c753caabb1085733880f672a8bcb34c14e`.
- Branche : `astra/core24-v2` ; worktree : `rewayah-astra-core24`.
- Le proprietaire a confirme que Z est arrete et demande de poursuivre sans son rapport de gel.
- Astra : migrations, RPC/RLS, Edge Functions, services/domaines partages et integration.
- Fable : features frontend ; aucun changement dans ses ecrans avant integration.
- Les documents Core24 V2 priment sur les anciennes regles contradictoires du sprint.

## P0.1 : correction locale verifiee

0033 cree deux nouvelles signatures sans retirer les anciennes : creer_groupe
(6 et 8 arguments), modifier_groupe (5 et 7 arguments). Les arguments
optionnels rendent les appels existants ambigus. La correction conserve les
signatures etendues, retire seulement les anciennes fonctions, restreint les
droits et recharge le cache PostgREST. Aucune ligne metier n'est supprimee.

Le service transmet maintenant le fuseau du Creneau et traduit les erreurs
PostgREST en erreur domaine sans details SQL. Les ecrans Fable ne sont pas touches.

Validation locale : reconstruction 0001-0033 sur PostgreSQL 17, test SQL rouge
avant / vert apres correction, 3 tests Flutter passes, analyse ciblee sans
anomalie, git diff --check sans erreur. Le harnais a besoin du stub Storage
ajoute pour les migrations Teaching Core. Ce stub ne va jamais sur Supabase.

Validation distante et recette globale non encore executees. La CLI Supabase
repond Unauthorized ; la connexion SQL trouvee localement vise un autre projet
que l'application. Aucun appel SQL n'a ete fait vers ce projet.

## P0.2 : socle KYC local

Table privee en ecriture `teacher_kyc_requirements`, RPC Admin idempotente et
auditee, contrat teacher_nda toujours requis, photo mineur verifiee par son
objet Storage avant le token. La fonction video historique est conservee dans
un schema non expose, inaccessible aux roles applicatifs. Codes domaine dans
l'Edge create-room-token. Le KYC famille ne ferme plus app_account_valid.

La recette SQL transactionnelle passe : famille pending_kyc, teacher requis,
auto-dispense et ecriture directe refusees, dispense sans contrat fermee,
dispense avec contrat ouverte, reactivation fermee, KYC approuve ouvert,
token mineur refuse avant upload et accepte apres, adulte sans photo accepte,
non-participant refuse. Les raccords session/ports et l'audit des autres portes
Teaching Core restent a terminer avant de declarer P0.2 livre.

## Integration

Fable a livre `ae59cd7` sur la base `ae61eb6`, descendante de `d5eb74c`.
Les corrections intermediaires de main sont donc necessaires a son integration,
notamment 0035 (visibilite Bibliotheque) et 0038 (hook de jeton).
Ses changements non commites ne sont pas integres.
