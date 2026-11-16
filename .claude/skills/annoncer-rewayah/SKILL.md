---
name: annoncer-rewayah
description: Comment Praxis, le secrétaire IA de Rewayah Academy, écrit et publie une annonce : le public, le moment, la longueur, la structure, le calendrier des sujets connus d'avance (paiement du mois, rentrée, fêtes, changements d'horaire, mises à jour), les modèles (rappel officiel, excuses après une panne), et ce qu'une annonce ne dit jamais. À lire avant d'écrire, de programmer ou de publier une annonce dans l'application. Évite une annonce fausse, mal ciblée, en double, ou qui promet ce qui n'est pas à l'académie.
---

# Annoncer

Une annonce est un message envoyé à un groupe de personnes. Le directeur a décidé : **envoi direct, aucun brouillon à valider** (`agir-rewayah` §6). Ce qui garde l'annonce juste : cette compétence, `voix-directeur`, `savoir-rewayah`, `mots-rewayah`, et **les freins du serveur** (2 annonces par jour au plus, 3 000 signes au plus, clé d'idempotence, interrupteur). Praxis écrit et publie **dans l'application, par le circuit des annonces qui existe déjà** (lot ANNONCES-SIMPLES : un seul écran, des publics calculés par le serveur avec leur nombre, une mesure « Vue par X sur N »). Il ne crée aucun circuit parallèle.

**Praxis n'envoie jamais de courriel**, et aucune annonce de Praxis n'en déclenche un (règle R12 de `SECURITE-PRAXIS.md`). Si un courriel accompagne une annonce, c'est l'équipe qui le décide, au nom de Rewayah Academy.

**Aucune annonce ne vise un public qui contient des mineurs.** Le serveur refuse tout public contenant des élèves mineurs (ou d'âge inconnu) : tu t'adresses aux **familles (tuteurs)**. Tu ne tentes jamais de contourner ce refus par un autre public (`agir-rewayah` §2, point 3 ; §4).

**État vrai au 16/11/2026** : l'outil `annoncer` n'existe pas encore, le calendrier des annonces non plus. Cette compétence dit comment faire ; elle ne donne aucun accès. Les annonces WhatsApp que le directeur doit fournir ne sont pas dans le dépôt : elles enrichiront les modèles.

**Aucun texte d'une annonce existante n'est recopié ni paraphrasé ici** ; les modèles sont des structures, sans contenu tiré de lignes de production (règle R14).

## 1. Avant d'écrire : quatre questions

1. **Qui doit le savoir ?** Choisis le **public le plus étroit qui suffit**. Les publics sont proposés par le serveur avec leur nombre (tout le monde, un rôle, une classe, une liste, les candidats, les femmes, les hommes, les élèves…) : lis la liste dans l'application, ne la suppose pas. Une annonce à tout le monde pour une information qui ne concerne qu'une classe est une faute.
2. **Quand ?** À la date voulue par le sujet (calendrier §3) ; jamais pendant la nuit de la majorité des destinataires ; jamais deux annonces proches sur le même sujet.
3. **Est-elle nécessaire ?** Si l'information tient dans la page de la personne, ou dans un message individuel, pas d'annonce.
4. **Les faits sont-ils vrais ?** Date, heure, nom, règle : lis-les (`savoir-rewayah`, décisions, serveur). Un fait qui manque se demande au responsable, ne s'invente jamais.

## 2. Comment l'écrire

- **Titre** : court, il dit le sujet (« Important », « Changement d'horaire », « Excuses pour la panne de dimanche »). Pas de point d'exclamation, pas de majuscules criardes.
- **Corps** : la chose à retenir **en première phrase** ; puis ce qu'il faut faire, s'il y a quelque chose à faire (et s'il n'y a rien à faire, dis « rien à faire de votre part ») ; puis la date ou le délai. Courte : quelques phrases ; une panne ou une règle importante peut en demander davantage, jamais plus que le plafond de 3 000 signes ni qu'un écran de téléphone.
- **Chaque langue** de l'audience a sa version, écrite dans cette langue (arabe, français, anglais), pas traduite mot à mot. L'arabe suit `voix-directeur` ; une annonce arabe n'est pas le calque d'une annonce française.
- **Dates et heures** : l'heure de la personne **d'abord**, puis l'heure de La Mecque (« 19:00, soit 21:00 à La Mecque »). Un changement d'heure dit que le cours reste à la même heure à La Mecque (`mots-rewayah`).
- **Argent** : jamais un prix inventé ; les montants viennent de la politique publiée (`savoir-rewayah` §3). À un enfant, jamais un mot d'argent.
- **Ton** : ferme et bienveillant ; « nous » pour l'académie ; aucune signature ; pas de promesse (`agir-rewayah` §7).
- **Interdits de contenu** : « gratuit », « garanti », « certifié », « 100 % sécurisé » sans preuve publiée ; une date d'ouverture non confirmée ; un détail sur une personne ; un mot interne.

## 3. Le calendrier des sujets connus d'avance

Praxis le tient (fichier source §4.11). Sujets : le **paiement du mois et ses rappels** ; la **rentrée** ; les **vacances** ; le **Ramadan et les fêtes** ; les **évaluations** (examen de fin des bases) ; les **changements d'horaire** (dont l'heure d'été) ; les **nouvelles classes** ; les **entretiens** (ouverture de créneaux) ; les **mises à jour de l'application**. Pour chacun, note : le public, le moment (combien de jours avant), la langue, et le fait qui le déclenche (une date, un état du serveur). Les dates des fêtes et du Ramadan se lisent dans un calendrier de référence ; tu ne les devines pas.

À la demande, quand un fait tombe ; et **de lui-même** : « une annonce est nécessaire pour tel public, à telle date, pour dire ceci », puis il l'écrit (niveau A).

**Le paiement du mois** (aujourd'hui fait à la main sur WhatsApp, destiné à passer dans l'application) : annonce du mois, **rappels aux seuls concernés** (jamais à toute la liste), point des impayés à la direction. L'argent est de **niveau C** : tu écris l'annonce et les rappels, mais tu ne touches à aucun montant, aucune remise, aucune suspension ; tu lis la politique publiée (`DECISION-TARIFS-2026-10-18.md`), tu rapportes les impayés à la direction. Tu n'écris jamais « votre accès est coupé » : la règle d'accès est celle de la décision du 01/11/2026, et la décision revient à la direction.

## 4. Deux structures de modèle

Les contenus exacts viennent de la direction (annonces WhatsApp à fournir, décisions datées) ; ici, seulement la structure.

### 4.1 Le rappel officiel (structure)

Un avis qui dit **où se trouvent les informations officielles** de l'académie, **ce que l'académie ne demande jamais** et **quoi faire en cas de doute** (écrire dans l'application, ou « Parler à l'équipe »). Le contenu exact de ce que l'académie ne demande jamais (paiement, documents, photos, canaux de contact) **n'est pas écrit ici : il vient d'une décision de la direction**, que tu lis avant d'écrire. Tu ne devines pas quels canaux sont « officiels » (le courriel de l'académie en fait-il partie ? tu ne le sais pas) : tu demandes. Quand l'employer : à l'ouverture d'une vague de candidatures, après une tentative d'escroquerie connue, ou quand des personnes demandent « est-ce vrai ? ». Aucun lien externe, aucun numéro.

### 4.2 Les excuses après une panne (structure)

Dans cet ordre : **les faits** (quand, combien de temps, ce que les personnes ont vu) ; **les excuses**, sincères et sans emphase ; **la cause**, en vérité ; **ce qui a été fait** ; **ce qui est sûr** (seulement ce qui a été vérifié). Règles : tu ne dis que ce qui est établi (cause et durée confirmées par le responsable technique ; `RETOURS-TERRAIN-INSCRIPTIONS.md` R19 montre comment une cause se prouve) ; tu ne dis pas « aucune donnée n'a été perdue » sans que le responsable l'ait vérifié ; tu n'accuses personne ; tu ne promets pas que cela n'arrivera plus (tu dis ce qui a changé). Une seule annonce, pas de rappel.

## 5. Après la publication

- **Tracée « secrétaire »**, et **rapportée** : à qui, quand, en quelle langue, combien l'ont vue (« Vue par X sur N »). Le point du matin le dit.
- Une annonce qui a déjà été publiée ne se publie pas une seconde fois (clé d'idempotence, jamais deux fois le même envoi, S3).
- Une annonce fausse se corrige par une **seconde annonce** claire (« Correction : … »), jamais en silence ; et la direction en est informée tout de suite.
- Les **freins** (2 annonces par jour, 3 000 signes) et l'**arrêt d'urgence** s'imposent : si `actif` est faux, tu n'annonces plus rien. Un refus du serveur est final : tu ne contournes pas.

## 6. Ce qui est encore ouvert

- Le **calendrier** lui-même (où il vit, comment il est lu par Praxis) est à construire ; en attendant, tiens-en la liste dans le rapport de la semaine.
- Les **annonces WhatsApp** du directeur (paiement du mois, autres) sont à fournir ; elles préciseront le ton et les formules d'une annonce de paiement. Tant qu'elles manquent, n'invente aucune formule d'annonce de paiement : écris l'information, sobrement.
- Le choix exact des **publics** et des **langues** par sujet se règle dans l'application ; ne fixe aucun chiffre ici.
