# Décisions du directeur : module des candidatures (21/10/2026)

**Source.**
- Réponses du directeur dans la page d'arbitrage des questions de la revue
  (`docs/current/CANDIDATURES/LIRE_D_ABORD.md`, « Où le directeur répond »),
  enregistrées le 21/10/2026 entre 17:51 et 18:31 UTC. **Les 22 questions ont une
  réponse.**
- À 18:22-18:23, le directeur a passé `CAND-Q05`, `CAND-Q06` et `CAND-Q09` de « à
  discuter » à « je réponds autrement », avec le même texte.
- Vers 18:32, il a précisé dans la conversation : « pour tout ce qui est
  "discuter" tu prends ma précision en bas ». **Pour `CAND-Q01` et `CAND-Q03`,
  restées « à discuter », sa précision est donc sa réponse.**

Le texte des questions et des recommandations initiales est dans
`CANDIDATURES/REVUE_CRITIQUE_CANDIDATURES_2026-10-21.md`, section 9. Plusieurs
recommandations ont été révisées dans la page avant ses réponses ; quand il a
validé, il a validé la version révisée, citée ci-dessous. Les réponses de Claude à
ses remarques sont dans la même page, sous chaque question.

## 1. Décidé

| Question | Décision | Effet |
| :--- | :--- | :--- |
| `CAND-Q01` | **Valider la pièce d'identité fait entrer en salle 3** : « l'intéressé est affectable à 100 % car cela lui fait accéder à la salle 3, donc il a son compte fonctionnel ». | La validation de la pièce reste le geste d'admission. Mise en oeuvre annoncée au directeur (il peut s'y opposer dans la page) : le serveur n'accepte cette validation qu'une fois la salle 2 terminée (entretien conclu, engagement, accords signés, paiement confirmé), pour que « salle 3 » reste vrai. Le refus d'une nouvelle pièce d'une enseignante déjà active ne change pas. |
| `CAND-Q02` | **Lot serveur borné autorisé sur la base de test** (revue, section 5.3), pas en production. Directeur : « il faut compléter ». | Fin du « frontend seul » pour ce module, sur la base de test seulement. Toute application en production reste soumise à son feu vert. L'ajout des scénarios à la CI touche `.github/`, zone interdite aux agents : il demande un ordre distinct. |
| `CAND-Q03` | **Un lien public, partageable, sur la page « recrutement » du site.** Qui clique enregistre toutes ses informations. Les personnes déjà inscrites aux formulaires et sans courriel reçoivent ensuite le lien par WhatsApp. | Rouvre une entrée publique, alors que l'enseignant n'entre que sur invitation depuis le 17/10 (`DECISION-ENTREE-2026-10-17.md`). Les problèmes que le directeur a demandé de lui signaler deviennent les conditions de mise en oeuvre (section 2). |
| `CAND-Q04` | **L'onglet Invitations devient « Candidatures »**, l'invitation y devient une étape. | Pas de septième onglet dans Personnes. Une seule liste par personne. |
| `CAND-Q05` | **Inscription ouverte à tous les pays.** Les salles 2 et 3 ne s'ouvrent qu'aux personnes que l'académie peut payer. **Hors d'Afrique, Arabie saoudite comprise : virement bancaire.** L'Afrique est la zone où le paiement pose problème. Les autres restent en salle 1, libres de partir. **Ce module n'est pas un module de moyens de paiement** : aucune intégration (Stripe ou autre). | Le référentiel de paiement (`CAND-BR-13`) est déclaratif : il dit, pays par pays, quel moyen fonctionne, et ne verse rien. Une absence de moyen ne refuse pas la candidature : elle la garde en salle 1. Restent ouverts (section 3) : les pays et moyens d'Afrique, et le cas d'un candidat africain qui a un compte bancaire. |
| `CAND-Q06` | **Pas de WhatsApp pour l'entretien ni pour le contact avec les candidats** : « c'est la raison de la création de l'app ». **Un espace dédié dans l'app** sert au contact entre la direction et les candidats. | La voie 1 de l'entretien (revue, section 6.3) est abandonnée : l'entretien se fait dans l'app, et `CAND-BR-08` (voie 2) entre dans le lot. Seule exception, décidée par le directeur : l'envoi du lien d'inscription aux personnes sans courriel. |
| `CAND-Q07` | **La séparation femmes/hommes s'applique en base** aux candidatures et aux entretiens, même règle que les pièces d'identité. Directeur : « le super admin doit voir les deux côtés ». | La RLS et chaque RPC du module bornent la direction à son côté ; le super-admin lit les deux (exception de `0088`). Un simple masquage à l'écran ne compte pas (spec, section 7). |
| `CAND-Q08` | **L'évaluation d'un candidat est un constat d'entretien structuré** : niveau observé, riwaya, ijaza présentée. | Pas de référentiel neuf ; le contrôle `evaluation_validee` lit ce constat. |
| `CAND-Q09` | **Aucune mention à l'écran pendant l'entretien** : « c'est éphémère », seuls restent le rapport et les données de la personne. | Ni « Entretien non enregistré », ni « Visite de contrôle possible » (qui serait faux) ; aucun enregistrement ; aucune visite de contrôle. |
| `CAND-Q10` | **Le candidat est prévenu dans l'app et par courriel.** « L'autre session va construire l'envoi d'e-mails après sa session sur le site public. » | Ce module n'envoie aucun courriel : il garde la liste des courriels à envoyer (destinataire, modèle, date), que l'envoi lira une fois branché. D'ici là, l'écran dit « courriel pas encore envoyé », jamais « envoyé ». Le contrat de cette liste est à remettre à la session du site public. |
| `CAND-Q11` | **Le texte de l'engagement reprend la doctrine écrite** : « voie d'Ahl as-Sunna » et « à la lumière des salafs », sans nommer les Compagnons. | Le reste de la recommandation (texte distinct du code de conduite, français et arabe, « Je confirme », accepté dès la salle 1) est gardé sauf avis contraire. Le texte sera soumis au directeur avant publication. |
| `CAND-Q12` | **Le mot « salle » reste** (« par exemple "salle d'examen" »). | Noms proposés au directeur, à corriger dans la page s'ils ne lui vont pas : « Salle d'examen », « Salle de vérification et d'entretien », « Salle des prêts à enseigner » ; l'engagement : « Cadre religieux et pédagogique ». « La salle » désignant déjà la salle de cours, le bouton d'entretien dit « Rejoindre l'entretien ». À verser dans `.claude/skills/mots-rewayah` avec les écrans. |
| `CAND-Q13` | **Le parcours candidat est livré en arabe**, pour ses textes. | Clés i18n du parcours traduites en arabe, pas seulement en français. |
| `CAND-Q14` | **Le bouton d'entretien d'une ligne est un lien secondaire**, pas un bouton plein. | Un seul bouton plein par écran ; la carte entière reste cliquable. |
| `CAND-Q15` | **Les cinq défauts hors module sont confiés à des agents** : « sinon ça risque d'être oublié encore ». « Vérifie bien, car la plupart des erreurs ont été corrigées mais dans des branches isolées sur git. » | Avant d'écrire, chaque défaut est cherché dans toutes les branches du dépôt ; un correctif existant est repris plutôt que réécrit. Détail : `CANDIDATURES/CORRECTIFS_HORS_MODULE_PROPOSES.md`. |
| `CAND-Q16` | **Pour un doublon aux réponses différentes, la ligne la plus récente l'emporte** ; les autres restent en historique. | Règle de l'import (`MAPPAGE_IMPORT_FORMULAIRES.md`). |
| `CAND-Q17` | **Après l'import, les candidatures arrivent par le lien public** de la page recrutement, avec courriel confirmé et limite contre les robots. Plus d'imports périodiques. | Recommandation révisée après `CAND-Q03`, validée. L'import reste ponctuel, pour les personnes des formulaires. |
| `CAND-Q18` | **Deux issues pour une pièce : « à corriger » et le refus définitif** (pièce fausse, identité discordante). **Aucune expiration** tant qu'aucune date de validité n'est saisie. | Le refus définitif passe la candidature en `refusee` avec motif interne. |
| `CAND-Q19` | **Seule la direction mène les entretiens** pour la première vague. | La capacité `entretiens.mener` revient à la direction. |
| `CAND-Q20` | **Le tri montre des clés en clair, jamais un score** : besoin ouvert (genre, langue), niveau constaté, disponibilité, puis compte bancaire, à égalité seulement. | Pas de note calculée à l'écran (spec, section 4.3). |
| `CAND-Q21` | **Durée de conservation réglable, anonymisation sur le modèle existant** ; demande d'effacement faite depuis l'app, ou reçue par courriel et notée par la direction pour une personne sans compte ; **avis du juriste**. | Recommandation révisée après `CAND-Q06` (plus de WhatsApp), validée. La durée elle-même attend l'avis du juriste. |
| `CAND-Q22` | **Les pièces autres que l'identité (ijaza, diplôme) sont présentées et constatées à l'entretien** pour la première vague. | Aucun dépôt de ces pièces dans l'app pour l'instant ; un dépôt futur passerait par le coffre cloisonné par genre, jamais par un lien Drive. |

## 2. Conditions de mise en oeuvre signalées au directeur

**`CAND-Q03` : le lien public.**
1. **Compte candidat seulement.** Le lien crée un compte candidat, jamais un compte
   enseignant. Seul le passage en salle 3 en fait un enseignant.
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

**`CAND-Q06` : l'entretien et le contact.**
- L'entretien a lieu dans la salle vidéo de l'app dès la première vague : une
  séance « entretien », jamais payée, ouverte au seul candidat convoqué, sans
  enregistrement.
- L'espace de contact réutilise la messagerie métier existante
  (`supabase/migrations/20261016090000_com_back_1_messages_metier.sql` : un fil
  toujours lié à un objet, entre une personne et l'équipe d'administration). On y
  ajoute l'objet « candidature », et un compte candidat en attente y est admis.
- Aucun candidat ne voit les autres ni leurs coordonnées (spec, section 7).

## 3. Encore ouvert

**`CAND-Q05`, deux points.**
- Quels pays et quels moyens fonctionnent en Afrique (par exemple, le mobile money
  par pawaPay) ?
- Un candidat qui vit en Afrique et qui a un compte bancaire passe-t-il ?

L'écran du référentiel va dans Finance, sauf avis contraire.

**`CAND-Q12`.** Les trois noms de salle proposés attendent son accord ou sa
correction.

**`CAND-Q21`.** La durée de conservation attend l'avis du juriste.

## 4. Journal

La ligne correspondante est portée au journal
`08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md`, section 5 bis, à la date du
21/10/2026.
