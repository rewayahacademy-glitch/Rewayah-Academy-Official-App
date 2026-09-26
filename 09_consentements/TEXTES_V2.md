# 09 - Textes révisés, version v2 (2026-10-v2)

Statut : **projet, à valider par un juriste avant production** (voir CHARTE section 8).
Langue : français facile. Phrases courtes. Pas de tiret cadratin. Traductions poular et anglais à faire par un traducteur humain, relues par un locuteur, avec la même version.

Principe : un accord = un sujet. Chaque accord a deux boutons de même poids : « J'accepte » et « Je refuse ». Rien n'est précoché. Chaque accord se retire dans **Compte, Mes accords**. Chaque choix (oui, non, retrait) donne un reçu daté.

Nouvelles sortes proposées en base (Écart E1) : `service_terms`, `sensitive_data`, `camera`, `recording_objection` (opposition, pas un accord), `observation`, `photo`, `news`. Version de toutes : `2026-10-v2`.

Identité du responsable, à afficher dans A1 et dans le texte complet (clé `accordsV2.responsable`) :
« Rewayah Academy Ltd, société de droit anglais (Angleterre et pays de Galles), immatriculée sous le numéro {numero_societe}, siège : {adresse_siege}. Enregistrée auprès de l'ICO sous le numéro {numero_ico}. Contact données : {contact_donnees}. Représentant dans l'Union européenne : {representant_ue} (si requis). »

Mots à remplacer : {prenom} = prénom de l'enfant ; {duree_enreg} = durée de conservation des enregistrements (30 jours aujourd'hui) ; {n_visites}, {minutes} lus depuis la politique de la classe ; {pays_hebergement} à confirmer.

---

## A0 - Information sur la religion (donnée sensible)

Rôle : tuteur (pour l'enfant), élève adulte. Obligatoire pour s'inscrire, car sans elle le service n'est pas possible. Base : consentement explicite (RGPD art. 9.2.a), à valider par un juriste.

Nouvelles clés : `accordsV2.religion.*` (titre, quoi, pourquoi, quiVoit, duree, retrait, refus, caseTuteur, caseAdulte).

> **Titre :** Une information sur la religion
>
> **Ce que nous faisons.** Votre inscription montre que {prenom} apprend le Coran. C'est une information sur la religion. La loi la protège de façon spéciale.
>
> **Pourquoi.** Nous en avons besoin pour donner les cours. Nous ne demandons rien d'autre sur votre religion ou votre pratique.
>
> **Qui voit.** L'enseignant de {prenom} et l'équipe de l'académie. Personne d'autre. Nous ne la vendons pas. Nous ne l'utilisons pas pour de la publicité. Nos messages ont un titre neutre.
>
> **Combien de temps.** Tant que {prenom} est inscrit, puis {duree_apres_depart} (à fixer, voir A1).
>
> **Comment retirer.** Compte, Mes accords, Retirer. Le retrait arrête les cours à la fin de la période payée. Ce qui a été fait avant reste valable.
>
> **Si vous refusez.** Nous ne pouvons pas donner de cours. Nous effaçons ce que vous avez saisi sous 30 jours.
>
> [ J'accepte ] [ Je refuse ]

---

## A1 - Conditions du service

Remplace : `contrat.titre`, `contrat.intro`, `contrat.lireTexte`, `contrat.accepter`, `contrat.caseRequise` (côté tuteur et élève adulte). Nouvelles clés : `accordsV2.conditions.*`. Le texte complet (aujourd'hui inexistant) doit être écrit et publié à une adresse fixe, en version `2026-10-v2`.

> **Titre :** Les conditions du service
>
> **Qui nous sommes.** Rewayah Academy Ltd, société de droit anglais, numéro {numero_societe}, {adresse_siege}. Nous sommes responsables de vos données.
>
> **Ce que nous faisons.** Nous donnons des cours de Coran en direct, en visio, avec un enseignant. Pour cela, nous gardons : votre nom, votre courriel ou téléphone, le prénom et l'âge de {prenom} (jamais sa date de naissance), ses horaires, sa présence, ses progrès, et vos paiements.
>
> **Pourquoi.** Pour organiser les cours, suivre les progrès, vous facturer et protéger les enfants.
>
> **Qui voit.** L'enseignant voit le prénom, le niveau et les progrès. Il ne voit jamais votre nom complet, votre courriel ni votre téléphone. L'équipe de l'académie voit ce qui est utile à son travail. Nos prestataires techniques hébergent les données pour nous : {liste_prestataires} en {pays_hebergement}. Ils n'ont pas le droit de s'en servir pour eux.
>
> **Combien de temps.**
> - Compte et progrès : tant que vous êtes inscrit, puis {duree_apres_depart}.
> - Enregistrements audio : {duree_enreg} jours, sauf s'il y a un signalement en cours.
> - Pièce d'identité : effacée dès la vérification faite, et au plus tard après {kyc} jours.
> - Factures : le temps fixé par la loi comptable.
> - Preuve de vos accords et refus : le temps de pouvoir la montrer en cas de litige.
>
> **Ce que vous vous engagez à faire.**
> - Vous avez l'autorité parentale sur {prenom}. Si vous la partagez, l'autre parent est d'accord. S'il ne l'est pas, dites-le-nous.
> - Pour un jeune enfant, un adulte reste à portée de voix pendant le cours. L'enseignant anime le cours. Il ne peut pas surveiller ce qui se passe chez vous.
> - Personne chez vous ne filme, ne photographie ni n'enregistre le cours. Les autres enfants ont droit au respect de leur vie privée. Si cela arrive, nous pouvons suspendre le compte.
>
> **Ce que nous nous engageons à faire.** Protéger vos données. Vous prévenir vite si elles sont exposées. Répondre à vos demandes sous un mois. Traiter chaque signalement. Vérifier chaque enseignant avant qu'il enseigne à des enfants. Une personne de l'académie est chargée de la protection des enfants : {responsable_safeguarding}.
>
> **Vos droits.** Voir vos données, les corriger, les effacer, les récupérer, vous opposer, retirer un accord. Tout se fait dans Compte, Mes données, ou en écrivant à {contact_donnees}. Vous pouvez aussi vous plaindre auprès d'une autorité : l'ICO au Royaume-Uni, la CNIL en France, la CDP au Sénégal, l'autorité compétente en Guinée (nom à vérifier).
>
> **La loi du contrat.** Le contrat suit le droit anglais. Si vous habitez dans un autre pays, vous gardez les protections de consommateur de votre pays. Vous pouvez saisir le tribunal de votre pays.
>
> **Si vous refusez.** Nous ne pouvons pas ouvrir le compte. Nous effaçons ce que vous avez saisi sous 30 jours.
>
> [ Lire le texte complet ] [ J'accepte ] [ Je refuse ]

Déclaration séparée, case non précochée (clé `accordsV2.conditions.declarationAutorite`) : « Je déclare avoir l'autorité parentale sur {prenom}. »

---

## A1 bis - Le droit de changer d'avis (14 jours)

Rôle : tuteur ou élève adulte qui paie. Base : CCR 2013 (Royaume-Uni) et règles équivalentes du pays de la famille ; à valider par un juriste. Nouvelles clés : `accordsV2.retractation.*`. Affiché avant le paiement, puis confirmé par courriel.

> **Titre :** Vous pouvez changer d'avis pendant 14 jours
>
> **Ce que dit la loi.** Après votre achat, vous avez 14 jours pour changer d'avis, sans donner de raison.
>
> **Si les cours commencent avant la fin des 14 jours.** Vous pouvez nous demander de commencer tout de suite. Si vous changez d'avis ensuite, vous payez seulement les cours déjà suivis. Le reste vous est remboursé.
>
> **Comment faire.** Compte, Paiements, Changer d'avis. Ou écrivez à {contact_donnees}. Nous vous remboursons sous 14 jours.
>
> [ ] Je demande que les cours commencent avant la fin des 14 jours. (case facultative, non précochée)
>
> **Si vous ne cochez pas.** Les cours commencent après les 14 jours. Vous pouvez aussi cocher plus tard.

---

## A2 - La caméra de l'enfant

Remplace : `ficheEleve.camera.autorisee`, `ficheEleve.camera.interdite`, `admin.configuration.ageCameraAutoDetail`. Nouvelles clés : `accordsV2.camera.*`. Base : consentement (RGPD art. 6.1.a), droit à l'image.

> **Titre :** La caméra de {prenom}
>
> **Ce que nous faisons.** Si vous dites oui, {prenom} peut allumer sa caméra pendant le cours. Elle est éteinte au départ. {prenom} peut l'éteindre à tout moment.
>
> **Pourquoi.** Voir l'enfant aide parfois l'enseignant à corriger la posture ou à garder l'attention. Ce n'est pas nécessaire pour apprendre.
>
> **Qui voit.** L'enseignant et les élèves de la même séance. Les parents en visite ne voient pas l'image. L'image n'est pas enregistrée.
>
> **Attention.** Nous interdisons aux familles de faire des captures d'écran. Mais nous ne pouvons pas l'empêcher sur tous les appareils.
>
> **Combien de temps.** L'image n'est pas gardée. Votre choix est gardé tant que {prenom} est inscrit.
>
> **Comment retirer.** Fiche de {prenom}, Caméra, ou Compte, Mes accords. Le changement compte au prochain cours.
>
> **Si vous refusez.** {prenom} suit le cours avec la voix. Rien d'autre ne change.
>
> [ J'accepte ] [ Je refuse ]

`admin.configuration.ageCameraAutoDetail` v2 : « Âge à partir duquel l'élève peut décider seul de sa caméra. En dessous, seul l'accord du tuteur ouvre la caméra. » (valeur proposée : 15 pour les familles en France ; 13 au Royaume-Uni selon DPA 2018 s. 9 à vérifier ; à valider par pays. Children's Code : caméra coupée par défaut à tout âge).

---

## A3 - L'enregistrement audio et la visite de contrôle (information et opposition)

Remplace : `contrat.pointEnregistrement`, `contrat.pointControle`, `accuse.titre`, `accuse.compris`, `enseignant.profil.contratAccuse`. **Le bandeau `salle.bandeauPermanent` est gardé mot pour mot** (décision 03 section 1 bis-2). Base proposée : intérêt légitime, protection des enfants (RGPD art. 6.1.f), avec droit d'opposition (art. 21) ; à valider par un juriste. Ce n'est pas une case à cocher : c'est une information à lire, avec un bouton d'opposition.

> **Titre :** Les cours sont enregistrés (le son seulement)
>
> **Ce que nous faisons.** Chaque cours est enregistré en audio. Pas d'image. Un contrôleur de l'académie peut aussi écouter un cours en direct, sans être vu. La salle le rappelle en permanence.
>
> **Pourquoi.** Pour protéger les enfants et les enseignants. Si quelqu'un signale un problème, nous pouvons vérifier ce qui s'est passé.
>
> **Qui écoute.** Seulement les personnes de l'académie chargées de la qualité et de la protection, pour une raison précise. Chaque écoute est inscrite au journal, avec le nom de qui écoute. Vous pouvez demander qui a écouté.
>
> **Combien de temps.** {duree_enreg} jours, puis effacé. S'il y a un signalement, l'enregistrement est gardé jusqu'à la fin de l'examen.
>
> **Si vous n'êtes pas d'accord.** Vous pouvez vous opposer : Compte, Mes accords, Je m'oppose à l'enregistrement. Nous vous répondons sous un mois. Nous chercherons une solution avec vous. Si aucune n'est possible, vous pouvez arrêter sans frais pour les cours pas encore suivis.
>
> [ J'ai lu ] [ Je m'oppose ]

Version enseignant (E1, clés `accordsV2.enregistrementEnseignant.*`) : même texte, « Pourquoi » complété par « C'est aussi une preuve pour vous si une famille se plaint à tort. » ; « Si vous refusez » : « Nous ne pouvons pas vous confier d'élèves, car cette mesure protège les enfants. Nous vous le disons avant votre signature. »

---

## A4 - Les visites d'observation des parents

Remplace : `consentement.texte.*` (titre, quiResponsable, quiResponsableDetail, quiAdulte, quiAdulteDetail, pourquoi, pourquoiDetail, limites, limitesDetail, caseResponsable, caseAdulte). `consentement.comment.*` est gardé. Base : consentement de chaque famille de la classe.

> **Titre :** Les visites des parents
>
> **Ce que nous faisons.** Les parents des élèves d'une classe peuvent venir écouter une séance, peu de temps. Ils entendent l'enseignant et les élèves qui parlent, y compris {prenom}. Ils ne peuvent ni parler, ni écrire, ni se montrer. Vous aussi, vous pouvez venir écouter.
>
> **Pourquoi.** Pour suivre les progrès de son enfant sans déranger la classe.
>
> **Qui.** Seulement les parents des élèves de la même classe. Chaque visite est inscrite au journal.
>
> **Limites.** {n_visites} visites de {minutes} minutes par séance et par parent. Enregistrer ou filmer pendant une visite est interdit.
>
> **Combien de temps.** Rien n'est gardé de la visite, sauf le journal (qui, quand, combien de temps), gardé {duree_journal}.
>
> **Comment retirer.** Compte, Mes accords, Retirer. Le changement compte à la prochaine séance.
>
> **Si vous refusez.** Aucun parent ne vient écouter la classe de {prenom}. Vous ne pouvez pas faire de visite non plus. {prenom} garde sa place. Les autres familles ne savent pas qui a refusé.
>
> [ J'accepte ] [ Je refuse ]

Variante adulte : remplacer « {prenom} » par « vous » et « Vous aussi, vous pouvez venir écouter » par rien.

---

## A5 - La photo de l'enfant

Remplace : `ficheEleve…photoLegende` et ajoute `accordsV2.photo.*`.

> **Titre :** La photo de {prenom}
>
> **Ce que nous faisons.** Vous pouvez ajouter une photo du visage de {prenom}. C'est facultatif.
>
> **Pourquoi.** Pour que l'enseignant reconnaisse {prenom} dans l'app.
>
> **Qui voit.** L'enseignant de {prenom}, les élèves de sa Classe et l'équipe. La photo n'est jamais publiée, ni sur un site ni sur un réseau.
>
> **Combien de temps.** Tant que vous la laissez. Elle est effacée quand vous la supprimez ou quand {prenom} quitte l'académie.
>
> **Comment retirer.** Fiche de {prenom}, Photo, Supprimer.
>
> **Si vous refusez.** Un avatar s'affiche à la place. Rien d'autre ne change.
>
> [ Ajouter une photo ] [ Pas de photo ]

---

## A6 - Les messages

Nouvelles clés : `accordsV2.messages.*`.

> **Titre :** Les messages que vous recevez
>
> **Toujours.** Les messages utiles aux cours : rappels, changements d'horaire, factures, sécurité. Ils sont nécessaires au service.
>
> **Si vous le voulez.** Les nouvelles de l'académie : nouveaux cours, événements. Au plus {n} par mois.
>
> **Comment retirer.** Compte, Messages, ou le lien en bas de chaque message.
>
> **Si vous refusez.** Vous ne recevez que les messages utiles aux cours.
>
> [ Je veux les nouvelles ] [ Non merci ]

---

## A7 - Textes courts à ajuster

- `kyc.intro` v2 : « Une photo lisible suffit. Elle sert seulement à vérifier votre identité. Elle est effacée dès la vérification faite, et au plus tard après {kyc} jours. » (aligne le texte sur `kyc_retention_days`).
- `contrat.accepteLe` et `consentement.compte.accepteLe` : garder, et ajouter « Version {version}. Voir le texte. Retirer. »
- Nouveaux : `accordsV2.recu` « Votre choix est enregistré le {date} à {heure}. Version {version}. Une copie vous est envoyée. » ; `accordsV2.refusRecu` « Votre refus est enregistré le {date}. Vous pouvez changer d'avis à tout moment. » ; `accordsV2.retraitRecu` « Votre accord est retiré le {date}. Il compte à partir de la prochaine séance. »
- Nouvelle version d'un texte : `accordsV2.nouvelleVersion` « Ce texte a changé. Voici ce qui change : {resume}. Tant que vous n'avez pas répondu, rien de nouveau ne s'applique à vous. »

## Récapitulatif

9 textes : A0 religion, A1 conditions (avec l'identité de Rewayah Academy Ltd), A1 bis rétractation, A2 caméra, A3 enregistrement et contrôle (plus E1 enseignant), A4 observation, A5 photo, A6 messages, A7 textes courts (kyc, reçus, nouvelle version).

