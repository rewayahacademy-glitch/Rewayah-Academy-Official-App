# Libellés des Communications : relecture croisée (05/10/2026)

Décision du 05/10, prise par délégation du directeur (D-FUS-8, libellés `com.*` = b ; artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW) : pas de page de validation ; les sessions valident les libellés « proposés par un agent » par relecture croisée (vocabulaire de `docs/current`, K-59, pas de jargon) et les marquent « validé par délégation le 05/10 ».

**Relu** : `origin/ui/communications-v1` @ `27689f94`, `tool/libelles_sources.json` et `assets/i18n/fr.i18n.json` (lecture seule ; aucun code modifié par cette relecture). Une session qui n'a écrit aucun libellé COM.

**Grille** : (1) vocabulaire de `docs/current` et des textes déjà livrés (« académie », « Classe », « la direction » ou « l'Administration », K-53.6) ; (2) K-59 et D5 (`lib/CLAUDE.md`) : un échec dit ce qui manque, la cause probable et quoi faire, « non confirmé » jamais « non envoyé », contrôle `affirmation-reseau` ; (3) aucun jargon ni mot de développeur visible (`mot-interne`, `docs/current/03` : aucun code interne visible) ; (4) fautes. Le motif « … n'a pas encore été confirmé. Réessayez dans un instant. » est tenu pour conforme : c'est le texte retenu pour le signalement par D-FUS-2 = a (05/10).

## Périmètre et comptes

- Entrées de `libelles_sources.json` marquées « proposé par un agent » sous `com.*` et `notifications.*` : **698**.
- Dont **15 entrées orphelines** : la source existe, la clé n'existe plus dans `fr.i18n.json` (textes regroupés par COM-RC : lecture d'un message dans `com.socle.composants.lecture.*`, fermer et effacer la recherche dans les clés partagées hors `com`). Rien à valider ; à retirer de `libelles_sources.json` (liste en fin de fichier).
- **Libellés relus : 683** (639 `com.*`, 44 `notifications.*`).
- **À corriger : 25**. **Validés par délégation le 05/10 : 658** (non recopiés ici).
- Hors de ce compte, une correction déjà décidée le 05/10 : `com.communaute.garde.reponse.avertissement` (source « spec … à valider », pas « agent »). `com.communaute.garde.reponse.consigneBlocage` et `com.communaute.reponses.refusee` sont bons (décision du 05/10).

| Sous-bloc | Relus | À corriger | Validés |
|---|---:|---:|---:|
| `com.annonces` | 191 | 17 | 174 |
| `com.communaute` | 104 | 3 | 101 |
| `com.messages` | 61 | 3 | 58 |
| `com.socle` | 91 | 0 | 91 |
| `com.studio` | 132 | 1 | 131 |
| `com.vocal` | 60 | 0 | 60 |
| `notifications.*` | 44 | 1 | 43 |
| **Total** | **683** | **25** | **658** |

## Corrections proposées

Chaque nouveau texte passe les contrôles de `tool/verifier_revue.dart` relus le 05/10 (`affirmation-reseau`, `mot-interne`, `libelle-ambigu` ; aucune clé `erreur*`). À appliquer avec la source « relecture croisée du 05/10 (LIBELLES_COM_RELECTURE.md), validé par délégation le 05/10 » dans `libelles_sources.json`, et le même sens en arabe (D-FUS-1 = a).

| # | Clé | Texte actuel | Nouveau texte | Motif |
|---|---|---|---|---|
| 1 | `com.communaute.garde.reponse.avertissement` | « Cette réponse semble contenir une promotion commerciale. Retirez le lien, le code ou l'offre avant de publier. » | « Cette réponse semble contenir une promotion commerciale. Retirez le lien, le code ou l'offre avant de l'envoyer. » | décision du 05/10 (par délégation) : une réponse s'envoie, elle ne se publie pas |
| 2 | `com.annonces.publieur.nature.toutes` | « Toute l'école la reçoit. Réservez-la à ce qui concerne tout le monde. » | « Toute l'académie la reçoit. Réservez-la à ce qui concerne tout le monde. » | vocabulaire : « académie » (docs/current/01 « Académie et pilotage » ; 38 occurrences de « l'académie » dans fr.json contre 4 de « l'école », toutes dans com.annonces) |
| 3 | `com.annonces.administration.matrice.detail` | « La règle de l'école, appliquée à chaque publication. » | « La règle de l'académie, appliquée à chaque publication. » | vocabulaire : « académie » |
| 4 | `com.annonces.demoPublication.toutes` | « Toute l'école » | « Toute l'académie » | vocabulaire : « académie » |
| 5 | `com.annonces.demoPublication.audiencesDirection` | « Toute l'école, un public ou une Classe » | « Toute l'académie, un public ou une Classe » | vocabulaire : « académie » |
| 6 | `com.studio.aujourdhui.acces.messagesDetail` | « Les fils avec les familles, les enseignants et les contrôleurs » | « Les conversations avec les familles, les enseignants et les contrôleurs » | jargon : « fil » ; les Messages disent « conversation » partout (com.messages.*) |
| 7 | `notifications.types.reponseFil` | « Réponse à un fil » | « Réponse dans une conversation » | jargon : « fil » ; même mot que les Messages |
| 8 | `com.messages.types.autre` | « Objet lié » | « Autre sujet » | jargon : « objet lié » (terme de spec, vu par les familles) ; « sujet » comme com.messages.entree.titreObjet |
| 9 | `com.messages.panneau.objets` | « Objets liés » | « À propos de » | jargon : « objets liés » ; reprend « à propos de » de com.messages.entete.semantique |
| 10 | `com.messages.panneau.inaccessible` | « Vous n'avez plus accès à cet objet. La conversation reste lisible. » | « Ce sujet ne vous est plus ouvert. La conversation reste lisible. » | jargon : « objet » |
| 11 | `com.communaute.demo.choisir` | « Choisissez une situation à essayer, dans la coquille Enseignant. » | « Choisissez une situation à essayer, vue par un enseignant. » | jargon : « coquille » (mot de développeur) |
| 12 | `com.annonces.publieur.etapes.audience` | « Audience de l'annonce » | « Destinataires de l'annonce » | jargon : « audience » ; le publieur dit déjà « les destinataires » (contexte.contenu, contexte.previsualisation) |
| 13 | `com.annonces.publieur.contexte.audience` | « Choisissez qui reçoit l'annonce. Seules les audiences que vous pouvez viser sont proposées. » | « Choisissez qui reçoit l'annonce. Seuls les destinataires que vous pouvez viser sont proposés. » | jargon : « audience » |
| 14 | `com.annonces.publieur.contexte.publication` | « Relisez l'audience et la date, puis publiez. Rien n'est publié avant la confirmation. » | « Relisez les destinataires et la date, puis publiez. Rien n'est publié avant la confirmation. » | jargon : « audience » |
| 15 | `com.annonces.publieur.manqueAudience` | « Choisissez une audience pour continuer. » | « Choisissez les destinataires pour continuer. » | jargon : « audience » |
| 16 | `com.annonces.publieur.aucuneCibleTitre` | « Aucune audience ouverte » | « Aucun destinataire ouvert » | jargon : « audience » |
| 17 | `com.annonces.publieur.aucuneCible` | « Vous ne pouvez publier vers aucune audience pour le moment. Demandez l'accès à la direction. » | « Vous ne pouvez publier pour aucun destinataire pour le moment. Demandez l'accès à la direction. » | jargon : « audience » |
| 18 | `com.annonces.administration.matrice.audiences` | « Audiences » | « Destinataires » | jargon : « audience » |
| 19 | `com.annonces.administration.indicateurs.regles` | « Règles de portée » | « Droits de publication » | jargon : « règles de portée » |
| 20 | `com.annonces.administration.matrice.titre` | « Règles de portée et autorisations » | « Droits de publication des annonces » | jargon : « règles de portée » |
| 21 | `com.annonces.administration.matrice.vide` | « Aucune règle de portée n'est configurée. » | « Aucun droit de publication n'est configuré. » | jargon : « règle de portée » |
| 22 | `com.communaute.garde.panne` | « La politique de la Communauté n'a pas pu relire ce contenu : rien n'est parti. Vérifiez la connexion, puis réessayez. » | « La vérification de ce contenu n'est pas confirmée, sans doute à cause de la connexion : rien n'a été publié. Vérifiez la connexion, puis réessayez. » | K-59 et jargon : « La politique de la Communauté n'a pas pu relire » affirme un échec et prête une action à une règle ; on dit ce qui manque (vérification non confirmée), la cause probable et quoi faire |
| 23 | `com.annonces.administration.indicateurs.echec` | « {libelle} : lecture impossible » | « {libelle} : non chargé. Vérifiez la connexion, puis rechargez la page. » | K-59 : « lecture impossible » ne dit ni la cause ni quoi faire |
| 24 | `com.communaute.reponses.nonConfirmee` | « Cette réponse n'a pas encore été confirmée. » | « Cette réponse n'a pas encore été confirmée. Vérifiez votre connexion, puis renvoyez-la. » | K-59 : ni cause ni action dans la phrase (le bouton « Renvoyer la réponse » seul ne suffit pas au lecteur d'écran) |
| 25 | `com.annonces.publieur.horsLigne` | « Vous êtes hors ligne : cette annonce n'est pas encore confirmée. Reconnectez-vous, puis réessayez. » | « Vous êtes hors ligne : cette annonce n'est pas encore confirmée. Réessayez quand la connexion revient. » | ambiguïté : « Reconnectez-vous » se lit comme « connectez-vous à votre compte » |
| 26 | `com.annonces.demo.roles.admin` | « Administration » | « Direction » | cohérence : com.messages.demo.roles.admin dit « Direction » pour le même choix |

## Points relevés sans correction

- Les libellés de démonstration (`*.demo.*`) ne sont jamais rendus en production ; ils sont relus avec la même grille (une seule correction : `com.communaute.demo.choisir`).
- « Classe » avec majuscule : choix de la spec Communications V1 et du reste de l'application, gardé.
- `com.annonces.publieur.publiee` (« Annonce publiée. Les destinataires la reçoivent. ») n'est rendu qu'après l'accusé du serveur (COM-BR-10) : gardé.
- « Admissions & familles », « Pédagogie & qualité », « Planning & remplacements », « Produit & technique » : textes exacts de la spec §9.1, gardés.

## Entrées orphelines de `libelles_sources.json` (à retirer)

- `com.messages.recherche.fermer`
- `com.messages.recherche.effacer`
- `com.messages.fil.auteurEtMoment`
- `com.messages.fil.pieceJointe`
- `com.messages.fil.vocal`
- `com.messages.fil.vocalSansDuree`
- `com.messages.fil.horodatage`
- `com.communaute.recherche.fermer`
- `com.studio.canal.pieceJointe`
- `com.studio.canal.vocal`
- `com.studio.canal.vocalSansDuree`
- `com.studio.canal.horodatage`
- `com.studio.canal.auteurEtMoment`
- `com.studio.recherche.fermer`
- `com.studio.recherche.effacer`
