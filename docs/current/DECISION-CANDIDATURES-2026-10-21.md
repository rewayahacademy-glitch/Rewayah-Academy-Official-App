# Décisions du directeur : module des candidatures (21/10/2026)

**Source.** Réponses du directeur dans la page d'arbitrage des questions de la revue
(`docs/current/CANDIDATURES/LIRE_D_ABORD.md`, « Où le directeur répond »),
enregistrées le 21/10/2026 entre 17:51 et 18:19 UTC. Elles portent sur `CAND-Q01`
à `CAND-Q09`. Les questions `CAND-Q10` à `CAND-Q22` n'ont pas encore de réponse.

Le texte des questions et des recommandations initiales est dans
`CANDIDATURES/REVUE_CRITIQUE_CANDIDATURES_2026-10-21.md`, section 9. Les réponses
de Claude aux remarques du directeur sont dans la même page, sous chaque question.

## 1. Décidé

| Question | Décision | Effet |
| :--- | :--- | :--- |
| `CAND-Q02` | **Lot serveur borné autorisé sur la base de test** (revue, section 5.3), pas en production. Directeur : « il faut compléter ». | Fin du « frontend seul » pour ce module, sur la base de test seulement. Toute application en production reste soumise à son feu vert. L'ajout des scénarios à la CI touche `.github/`, zone interdite aux agents : il demande un ordre distinct. |
| `CAND-Q04` | **L'onglet Invitations devient « Candidatures »**, l'invitation y devient une étape. | Pas de septième onglet dans Personnes. Une seule liste par personne. |
| `CAND-Q03`, principe | **Un lien public, partageable, sur la page « recrutement » du site.** Qui clique enregistre toutes ses informations. Les personnes déjà inscrites aux formulaires et sans courriel reçoivent ensuite le lien par WhatsApp. | Rouvre une entrée publique, alors que l'enseignant n'entre que sur invitation depuis le 17/10 (`DECISION-ENTREE-2026-10-17.md`). Le directeur a demandé qu'on lui signale les problèmes : voir section 2. Tranche aussi `CAND-Q17` (arrivée des candidatures après l'import). |
| `CAND-Q05`, principes | **Inscription ouverte à tous les pays.** Les salles 2 et 3 ne s'ouvrent qu'aux personnes que l'académie peut payer. **Hors d'Afrique, Arabie saoudite comprise : virement bancaire.** L'Afrique est la zone où le paiement pose problème. Les autres restent en salle 1, libres de partir. **Ce module n'est pas un module de moyens de paiement** : aucune intégration (Stripe ou autre). | Le référentiel de paiement (`CAND-BR-13`) est déclaratif : il dit, pays par pays, quel moyen fonctionne. Il ne verse rien. Une absence de moyen ne refuse pas la candidature : elle la garde en salle 1. |
| `CAND-Q06`, principe | **Pas de WhatsApp pour l'entretien ni pour le contact avec les candidats** : « c'est la raison de la création de l'app ». **Un espace dédié dans l'app** sert au contact entre la direction et les candidats. | La voie 1 de l'entretien (revue, section 6.3) est abandonnée. L'entretien se fait dans l'app, et `CAND-BR-08` (voie 2) entre dans le lot. Les recommandations qui passaient par WhatsApp (`CAND-Q10`, `CAND-Q21`) sont révisées. Seule exception, décidée par le directeur : l'envoi du lien d'inscription aux personnes sans courriel. |
| `CAND-Q07` | **La séparation femmes/hommes s'applique en base** aux candidatures et aux entretiens, même règle que les pièces d'identité. Directeur : « le super admin doit voir les deux côtés ». | La RLS et chaque RPC du module bornent la direction à son côté ; le super-admin lit les deux. Un simple masquage à l'écran ne compte pas (spec, section 7). |
| `CAND-Q08` | **L'évaluation d'un candidat est un constat d'entretien structuré** : niveau observé, riwaya, ijaza présentée. | Pas de référentiel neuf ; le contrôle `evaluation_validee` lit ce constat. |
| `CAND-Q09` | **Aucune mention à l'écran pendant l'entretien** : « c'est éphémère », seuls restent le rapport et les données de la personne. | Ni « Entretien non enregistré », ni « Visite de contrôle possible » (qui serait faux) ; aucun enregistrement ; aucune visite de contrôle. Seuls le compte rendu et la candidature persistent. |

## 2. Signalé au directeur, en attente de sa confirmation

**`CAND-Q03` : conditions proposées pour le lien public.**
1. **Compte candidat seulement.** Le lien crée un compte candidat, jamais un compte
   enseignant. Seul le geste de la direction en salle 3 en fait un enseignant.
2. **Contre les robots.** Courriel confirmé à l'inscription, et limite du nombre
   d'inscriptions par heure.
3. **Courriel obligatoire.** L'application se connecte par courriel
   (`lib/core/auth/service_auth.dart:52-56`). Les 32 personnes sans courriel
   devront en créer un ; le message WhatsApp doit le dire.
4. **Personnes déjà inscrites aux formulaires.**
   - Leurs anciennes réponses servent à les reconnaître (même courriel ou même
     téléphone) et à pré-remplir.
   - Elles ne créent pas de candidature à leur place.
   - Les anciens formulaires ne demandaient ni le pays de résidence, ni les moyens
     de paiement, ni l'engagement : tout le monde doit de toute façon compléter.
5. **Confidentialité.** L'inscription demande l'accord sur la confidentialité, ce
   que l'ancien formulaire en français ne faisait pas (`CAND-Q21`).
6. **Mise en ligne.** Le lien ne va sur le site public qu'une fois le serveur prêt,
   et avec le feu vert du directeur.

**`CAND-Q06` : proposition révisée.**
- L'entretien a lieu dans la salle vidéo de l'app dès la première vague : une
  séance « entretien », jamais payée, ouverte au seul candidat convoqué, sans
  enregistrement.
- L'espace de contact réutilise la messagerie métier existante
  (`supabase/migrations/20261016090000_com_back_1_messages_metier.sql` : un fil
  toujours lié à un objet, entre une personne et l'équipe d'administration). On y
  ajoute l'objet « candidature », et un compte candidat en attente y est admis.
- Aucun candidat ne voit les autres ni leurs coordonnées (spec, section 7).

## 3. Encore en discussion

**`CAND-Q01`.** Le directeur comprend « pièce validée = salle 3 = compte
fonctionnel », et demande s'il existe des subtilités.

La réponse lui a été faite : valider la pièce active aujourd'hui le compte sans
autre vérification. La personne devient affectable, peut rejoindre une séance
vidéo et être payée, avant même l'entretien.

Proposition révisée :
- valider la pièce reste le geste qui fait entrer en salle 3 ;
- mais le serveur le refuse tant que l'entretien, l'engagement, les accords et le
  paiement ne sont pas confirmés ;
- pour une enseignante déjà active, le refus d'une nouvelle pièce ne coupe le
  compte que si la pièce est fausse.

**`CAND-Q05`, deux points.**
- Quels pays et quels moyens fonctionnent en Afrique (par exemple, le mobile money
  par pawaPay) ?
- Un candidat qui vit en Afrique et qui a un compte bancaire passe-t-il ?

L'écran du référentiel va dans Finance, sauf avis contraire.

## 4. Ligne pour le journal (`08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md`, section 5 bis)

À reporter dans le journal quand cette branche rejoint la pile : la branche de ce
lot ne modifie aucun fichier existant.

| 2026-10-21 | **Décisions du directeur sur le module des candidatures** (`CAND-Q02` à `CAND-Q09`) : lot serveur borné autorisé sur la base de test ; Invitations devient Candidatures ; lien public d'inscription sur la page recrutement du site ; inscription ouverte à tous les pays, salles 2 et 3 réservées aux personnes que l'académie peut payer (virement bancaire hors d'Afrique) ; aucune intégration de paiement dans ce module ; **pas de WhatsApp** pour l'entretien ni le contact, un espace dédié dans l'app ; séparation femmes/hommes en base, le super-admin voyant les deux côtés ; évaluation par constat d'entretien ; aucune mention ni enregistrement pendant l'entretien. | Réponses dans la page d'arbitrage de la revue du 21/10. | `docs/current/DECISION-CANDIDATURES-2026-10-21.md`, `docs/current/CANDIDATURES/` | `CAND-Q01` et deux points de `CAND-Q05` en discussion ; `CAND-Q10` à `CAND-Q22` sans réponse. Rien n'est appliqué en production. |
