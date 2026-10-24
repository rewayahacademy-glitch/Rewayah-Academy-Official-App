---
name: mots-rewayah
description: Le vocabulaire unique de Rewayah Academy pour tout texte visible (écrans, notifications, e-mails, pages publiques, documents pour les familles, enseignants ou administration). À lire avant d'écrire ou de modifier un texte i18n (assets/i18n), une fiche d'écran, un message d'erreur ou une page destinée à une personne. Évite qu'un agent invente des mots ou réintroduise un mot interdit.
---

# Les mots de Rewayah

On n'invente pas de langage. Une famille doit comprendre du premier coup, sans apprendre de vocabulaire. Les mots ci-dessous sont **décidés** : ne les change pas sans une décision datée du directeur dans `docs/current/`. Si un mot manque, prends le plus simple et le plus courant, puis ajoute-le ici dans le même commit.

Sources : les décisions du directeur (annexe 10 du dossier maître, spécification du 12/10, commentaires des 13 et 14/10), consolidées dans `docs/current/REGISTRE-RECONCILIATION-2026-10-14.md`. Pour le programme lui-même, lis aussi la compétence `programme-rewayah`.

## 1. Le ton

- **Ferme et bienveillant.** Rewayah vend la rigueur et l'assiduité. On ne promet pas de souplesse : jamais « ce n'est pas grave », « on vous trouvera un autre créneau », « vous serez remboursé de l'absence ».
- Phrases courtes, avec le bénéfice d'abord. Le vouvoiement pour les adultes et les tuteurs, le tutoiement pour l'enfant en Interface guidée.
- Ne dis jamais ce qui n'est pas vrai : pas de « Place réservée » avant que ce soit le cas, pas de « Cours enregistré » sans enregistrement réel, pas de « paiement confirmé » au retour d'une page de paiement.
- N'écris jamais « certifié », « garanti », « 100 % sécurisé » ou « gratuit » sans une preuve dans la politique publiée.
- À l'enfant, on ne parle jamais d'argent : « Accès à cette classe temporairement indisponible. Ton tuteur peut gérer l'accès. »
- Pas de tiret long : utilise le tiret simple.

## 2. Les mots de l'application

| On écrit | On n'écrit jamais |
|---|---|
| Classe | groupe (sauf dans le code) |
| Interface guidée | mode enfant |
| Ajouter un profil élève | ajouter un enfant |
| Séance toujours en direct | cours en cours, temps négatif |
| Rejoindre | entrer, se connecter au cours |
| S’inscrire (bouton court de l’en-tête du site public, sous 1100 px ; « Commencer mon inscription » au-delà) | s’enregistrer, créer un compte |
| Sayyid, Sayyida (en salle) | Ustaz, Monsieur, Madame |
| Travail à préparer, Avant le prochain cours | devoirs, homework |
| la direction, l'administration | admin |
| Votre parent observe le cours (à l'enfant concerné seulement) | Ton tuteur regarde le cours |
| Accueil · Foyer · Historique · Compte (navigation du tuteur) | Disponibilités, Suivi, Réglages en onglet principal |
| Aujourd'hui · Apprendre · Suivi · Profil (élève adulte) | la navigation du tuteur recopiée |
| Journée · Créneaux · Profil (enseignant) | une quatrième entrée |
| Déposer ma candidature (enseignant sans code) · Envoyer ma candidature (bouton du récapitulatif) · J'ai un code d'invitation | s'inscrire comme enseignant, devenir prof |
| Indicatif du pays (téléphone) · politique de confidentialité | code pays, préfixe, charte, RGPD |

## 3. Les mots du programme

| On écrit | On n'écrit jamais |
|---|---|
| les bases | Fondations, F1, F2… |
| étape, niveau | palier, module, cycle, unité |
| matière principale, matière secondaire | essentiel, en plus, fil |
| à finir avant le… (date limite) | deadline, échéance académique |
| séance de consolidation | révision groupée, récap |
| les sourates courtes, d'Al-Fatiha à Az-Zalzalah | petit Coran |
| examen de fin des bases | porte d'Az-Zalzalah, gate, G0 |
| lire tout le Coran · mémoriser le Coran | Tilawah, Hifz, T1-T6, H0-H6 |
| petit bilan | contrôle |
| rencontre de récitation | Majlis |
| rattraper ce cours (l'élève, seul) | cours de rattrapage offert |
| demander une pause d'un mois | geler, suspendre l'abonnement |
| lecture enregistrée (du programme) | audio du cours, enregistrement du professeur |
| qiraat (lectures du Coran), pour traduire القراءات : « Institut des qiraat (lectures du Coran) » (directeur, 22/10/2026) | lectures du Coran seul |
| emploi du temps de révision | planning, programme de révision personnalisé |
| dans la langue choisie à l'inscription | les cours sont en français |
| nos familles vivent loin des écoles coraniques | le nom d'un pays ou d'un continent |

## 4. Résultats et états

| Situation | Mots exacts |
|---|---|
| Résultat d'une évaluation | « Étape validée » · « Quelques points sont à renforcer » · « Une nouvelle vérification est nécessaire » |
| État d'une compétence, montré aux familles | « À renforcer » · « Acquis » · « Stable » (seulement si le serveur le confirme) |
| Suite décidée par l'enseignant | « Continuer » · « Renforcer » · « Suspendre le nouveau » |
| Panne de connexion pendant une évaluation | jamais « échec » : l'état reste technique |
| Certificat | « Attestation des bases », « Certificat de lecture », « Certificat de mémorisation ». Jamais « ijaza » pour un certificat Rewayah |

Les mots « Réussi », « Échec », « En progrès », « Maîtrisé » et « À revoir » ne s'affichent jamais. Ils peuvent rester dans la base de données, jamais à l'écran.

## 5. Les codes internes

F1-F4, T1-T6, H0-H6, I1, J0-J6, E1-E3, D0, G0, K-45, CAP-19, les identifiants de lot et les noms de tables ne s'affichent jamais à une famille, à un élève ou à un enseignant.

## 6. Avant de pousser un texte

1. Cherche dans `assets/i18n/fr.i18n.json` si une clé existe déjà avec le bon mot : réutilise-la.
2. Vérifie qu'aucun mot de la colonne « On n'écrit jamais » n'entre dans ton diff : `git diff -U0 | grep -i -E "mode enfant|cours en cours|ajouter un enfant|essentiel|en plus|palier|fondations|majlis|tilawah|hifz|échec|maîtrisé"`.
3. Les autres langues (en, ar, es, pt) suivent le sens du français. Pas de traduction automatique des versets ni des invocations.
