# 09 - Matrice des scénarios (consentements, contrats, données)

Date : 25/09/2026. Rien ici n'est un avis juridique. Un article n'est cité que s'il est connu avec certitude ; sinon la mention est « à vérifier par un juriste ».

Abréviations : RGPD = règlement (UE) 2016/679. LIL = loi française Informatique et Libertés. GN = loi guinéenne L/2016/037/AN. SN = loi sénégalaise 2008-12 (autorité : CDP). Textes = `TEXTES_V2.md`. Écarts = `CHARTE.md` section 9.

Autres abréviations : UK GDPR = RGPD tel que conservé au Royaume-Uni (mêmes numéros d'articles) ; DPA 2018 = Data Protection Act 2018 ; ICO = Information Commissioner's Office ; Children's Code = ICO Age Appropriate Design Code (15 normes) ; CRA 2015 = Consumer Rights Act 2015 ; CCR 2013 = Consumer Contracts Regulations 2013.

Champ d'application (information du coordinateur, 25/09) :
- **Responsable du traitement : Rewayah Academy Ltd, société de droit anglais (Angleterre et pays de Galles).** Droit principal : UK GDPR et DPA 2018. Autorité principale : ICO. L'académie doit être enregistrée auprès de l'ICO et payer la « data protection fee ».
- Familles dans l'UE : le RGPD s'applique aussi (RGPD art. 3.2, offre de services à des personnes dans l'UE). Un représentant dans l'UE (RGPD art. 27) est probablement requis : juriste. Autorité compétente pour une famille française : CNIL.
- Familles en Guinée et au Sénégal : lois GN et SN en complément ; portée exacte à vérifier.
- Écrans enfants : le Children's Code de l'ICO est la référence de conception pour tous les rôles enfants (intérêt supérieur de l'enfant, réglages protecteurs par défaut, minimisation, aucun « nudge », géolocalisation coupée, transparence adaptée à l'âge, contrôle parental signalé à l'enfant).
- Âge du consentement numérique : 13 ans au Royaume-Uni (DPA 2018 s. 9, à vérifier), 15 ans en France (LIL art. 45), à vérifier en Guinée et au Sénégal. Quel âge s'applique à une famille française servie par une société anglaise : juriste. Règle de prudence proposée : le plus protecteur des deux (15 ans pour les familles en France).
- Contrat : le consommateur UE garde les protections impératives de son pays, quel que soit le droit choisi (Rome I art. 6).

## Point sensible : l'inscription révèle une conviction religieuse

- **Risque.** Être inscrit dans une école de Coran peut révéler une conviction religieuse. La Cour de justice de l'UE juge qu'une donnée qui révèle indirectement une catégorie sensible est elle-même sensible (arrêt C-184/20, 1er août 2022). Le RGPD art. 9.1 interdit par principe ce traitement, sauf exception de l'art. 9.2.
- **Base légale proposée.** Consentement explicite (UK GDPR et RGPD art. 9.2.a ; au Royaume-Uni, conditions complémentaires du DPA 2018 annexe 1 à vérifier), donné par la personne adulte ou par le titulaire de l'autorité parentale, en plus de la base du contrat (art. 6.1.b) pour le service. L'exception 9.2.d (organisme à but non lucratif à finalité religieuse, pour ses membres) ne vaut que si l'académie a ce statut : à vérifier par un juriste. Au Sénégal, la loi 2008-12 soumet les données sensibles à un régime renforcé (autorisation préalable de la CDP probable) : à vérifier. En Guinée : à vérifier.
- **Minimisation.** Aucun champ « religion », « pratique », « madhhab » ou « mosquée ». Aucune question sur la pratique des parents. Le niveau de lecture du Coran est une donnée pédagogique, pas une donnée de foi : ne pas l'enrichir de commentaires sur la pratique. Communications (courriels, SMS, notifications) au libellé neutre (« Rewayah », pas de verset ni de mot religieux dans l'objet ou l'aperçu de notification sur écran verrouillé). Libellé bancaire neutre à étudier. Pas de publicité ciblée, pas de partage avec des tiers à des fins commerciales, pas de réseaux sociaux intégrés qui pistent.
- **Texte.** Accord A0 (TEXTES_V2) : phrase explicite « Votre inscription montre que vous ou votre enfant apprenez le Coran. C'est une information sur la religion. »
- **Preuve.** Ligne d'accord A0 datée et versionnée ; registre des traitements avec la mention « donnée sensible, art. 9.2.a » ; AIPD (analyse d'impact, RGPD art. 35) car mineurs + donnée sensible + enregistrement.

## Matrice

Chaque ligne : risque ; règle ; parade dans le texte ; parade dans l'app ; preuve en audit.

### S01 - Le parent signe tout
- Risque : il dira plus tard « je n'avais pas compris ». Accord groupé contestable.
- Règle : RGPD art. 7.1 (le responsable doit prouver le consentement), 7.2 (demande distincte des autres sujets), 12 (langage clair), 13 (information).
- Texte : accords séparés A0 à A6, chacun avec quoi, pourquoi, qui voit, combien de temps, retrait, refus.
- App : un écran par accord ou une liste d'accords séparés ; résumé final ; reçu daté envoyé par courriel et visible dans Compte.
- Preuve : une ligne par accord (qui, pour quel enfant, sorte, version, empreinte du texte, langue, date serveur, appareil) ; copie du texte versionné conservée.

### S02 - Le parent refuse la caméra de son enfant
- Risque : pression, enfant pénalisé.
- Règle : RGPD art. 7.4 (consentement non lié à un service qui n'en a pas besoin) ; droit à l'image (en France, Code civil art. 9).
- Texte : A2 « Si vous refusez : votre enfant suit le cours avec la voix. L'enseignant ne le voit pas. Rien d'autre ne change. »
- App : caméra coupée par défaut (`camera_policy` = `forbidden`, déjà le cas) ; boutons « J'accepte » et « Je refuse » de même taille.
- Preuve : ligne de refus datée (un refus se trace aussi).

### S03 - Le parent refuse l'enregistrement audio
- Risque : l'enregistrement est présenté comme obligatoire sans justification, ou au contraire l'académie perd sa preuve de protection.
- Règle : si l'enregistrement sert la protection des enfants et la preuve en cas de plainte, la base est l'intérêt légitime (RGPD art. 6.1.f), pas le consentement. Il faut alors un test de mise en balance écrit, une information claire et un droit d'opposition (art. 21). Choix de la base : à valider par un juriste. Décision directeur 03 section 1 bis-2 : l'enregistrement est réel.
- Texte : A3 dit honnêtement que l'enregistrement fait partie du service, pourquoi, et ce qui se passe en cas d'opposition (examen au cas par cas ; proposition de cours en présence d'un parent à la place, ou fin du service sans frais pour la période non suivie).
- App : bouton « Je m'oppose à l'enregistrement » dans Compte, Mes accords ; formulaire court ; réponse sous un mois (art. 12.3).
- Preuve : test de mise en balance signé ; AIPD ; journal des oppositions et des réponses.

### S04 - Le parent signe puis retire un accord
- Risque : retrait ignoré, ou plus difficile que l'accord.
- Règle : RGPD art. 7.3 (retrait à tout moment, aussi simple que l'accord ; pas d'effet rétroactif).
- Texte : chaque accord dit « Vous pouvez retirer cet accord à tout moment dans Compte, Mes accords, en un geste. »
- App : interrupteur ou bouton « Retirer » à côté de chaque accord ; effet au prochain cours ; reçu du retrait. **Aujourd'hui impossible** : `contract_acceptances` n'a pas de retrait (Écart E2).
- Preuve : ligne de retrait datée, liée à l'accord retiré.

### S05 - Le parent refuse les conditions du service
- Risque : refus caché ou culpabilisant.
- Règle : le contrat (art. 6.1.b) est nécessaire au service ; le refuser empêche l'inscription, c'est proportionné si c'est dit.
- Texte : A1 « Sans cet accord, nous ne pouvons pas ouvrir le compte. Vos informations déjà saisies sont effacées sous 30 jours. »
- App : bouton « Je ne signe pas » visible, de même poids ; écran de sortie calme, sans reproche ; purge du brouillon.
- Preuve : trace de purge.

### S06 - Enfant filmé alors que le parent n'a pas donné d'accord caméra
- Risque : image d'un mineur sans accord. Aujourd'hui, `camera_auto_allow_min_age` = 11 : au-dessus de 11 ans la caméra serait autorisée sans accord du tuteur (texte `ageCameraAutoDetail`).
- Règle : droit à l'image ; RGPD art. 6 et 8 ; en France la majorité numérique est 15 ans (LIL art. 45).
- Texte : A2 dit que la caméra reste éteinte tant que le parent n'a pas dit oui, quel que soit l'âge (jusqu'à 15 ans au moins).
- App : supprimer l'autorisation automatique par âge, ou la porter à 15 ans pour la France et à l'âge validé par le juriste ailleurs (Écart E6).
- Preuve : réglage et accord datés par enfant.

### S07 - Visite d'observation d'un parent dans une classe où sont d'autres enfants
- Risque : un parent entend d'autres enfants, sans l'accord de leurs parents.
- Règle : RGPD art. 6 (base : consentement de chaque famille de la classe) ; vie privée des autres enfants.
- Texte : A4 dit que d'autres parents peuvent entendre votre enfant et que vous pouvez entendre les autres ; interdiction d'enregistrer.
- App : la classe n'ouvre les visites que si **toutes** les familles présentes ont dit oui (sinon les visites sont fermées pour cette séance) (Écart E7, à vérifier dans 0036/0037). Visite muette, caméra et micro coupés, bandeau permanent, journal d'entrée et de sortie (déjà prévu).
- Preuve : état des accords de la classe au moment de la visite ; journal des visites.

### S08 - Le parent refuse l'observation
- Risque : son enfant est exclu des classes de groupe.
- Règle : proportionnalité ; RGPD art. 7.4.
- Texte : A4 « Si vous refusez : personne ne vient observer les séances de votre enfant. Vous ne pouvez pas observer non plus. Votre enfant garde sa place. »
- App : les visites sont fermées dans les classes où une famille a refusé ; pas d'indication aux autres familles de qui a refusé.
- Preuve : ligne de refus ; journal de fermeture des visites.

### S09 - L'enseignant dérape (propos, geste, demande de contact privé)
- Risque : atteinte à l'enfant ; responsabilité de l'académie pour défaut de surveillance.
- Règle : obligations de protection de l'enfance selon le pays ; la plainte pénale relève des autorités. Signalement : à vérifier par un juriste pour chaque pays.
- Texte : A1 explique le bouton « Signaler », la visite de contrôle et l'enregistrement comme moyens de protection ; ne promet pas l'impossible (« nous ne pouvons pas tout voir en direct »).
- App : bouton « Signaler un problème » dans la salle et dans l'historique ; gel de l'enregistrement concerné (pas d'effacement à 30 jours pendant l'examen) ; suspension possible de l'enseignant ; coordonnées jamais visibles par l'enseignant (déjà le cas).
- Preuve : journal du signalement, gel, décision, délai de traitement ; charte enseignant signée.

### S10 - Enfant seul devant l'écran
- Risque : on reproche à l'académie un défaut de surveillance hors du cours.
- Règle : la surveillance à la maison relève du parent ; l'académie répond de ce qui se passe dans la séance.
- Texte : A1 « Pendant le cours, l'enseignant anime la séance. Il ne peut pas surveiller ce qui se passe chez vous. Pour les enfants de moins de ... ans, un adulte doit rester à portée de voix. » (âge à fixer par le directeur).
- App : rappel doux au premier cours ; pas de contact privé enseignant-enfant possible (déjà le cas).
- Preuve : texte signé ; absence de canal privé dans l'app.

### S11 - Une autre famille fait une capture d'écran ou enregistre avec un autre appareil
- Risque : image ou voix d'un enfant diffusée. L'académie ne peut pas l'empêcher techniquement.
- Règle : la famille qui capture est responsable ; atteinte à la vie privée et droit à l'image ; qualification pénale à vérifier par un juriste.
- Texte : A1 interdit toute capture ou enregistrement par les familles ; A2 et A4 disent honnêtement que l'académie ne peut pas l'empêcher à 100 %.
- App : sur Android, blocage de capture d'écran dans la salle (FLAG_SECURE) ; rappel dans la salle ; bouton Signaler ; exclusion de la famille fautive.
- Preuve : clause signée par la famille fautive ; journal de présence de la séance.

### S12 - Fuite de données (piratage, erreur de droits, jeton volé)
- Risque : enfants, pièces d'identité, donnée religieuse exposés.
- Règle : UK GDPR et RGPD art. 32 (sécurité), 33 (notification à l'autorité sous 72 heures : ICO, et autorités UE concernées via le représentant, à vérifier), 34 (information des personnes si risque élevé). SN et GN : obligations à vérifier.
- Texte : A1 décrit les mesures en mots simples et l'engagement de prévenir les familles. Pas de promesse de « risque zéro ».
- App : procédure écrite ; registre des violations ; RLS et journal chaîné (déjà en place).
- Preuve : registre des violations, même sans notification ; tests RLS ; procédure datée.

### S13 - Demande d'accès (copie de mes données)
- Règle : RGPD art. 15 ; réponse sous un mois (art. 12.3), gratuite.
- Texte : section Droits de A1.
- App : « Compte, Mes données, Demander une copie » ; export par l'admin. Absent aujourd'hui (Écart E3).
- Preuve : journal des demandes, date de réponse.

### S14 - Demande d'effacement
- Règle : RGPD art. 17, avec exceptions (obligation légale, constatation ou défense de droits en justice).
- Texte : A1 dit ce qui est effacé tout de suite, et ce qui est gardé et pourquoi (factures, preuve des accords, enregistrement gelé pour litige).
- App : « Supprimer mon compte » ; les preuves d'accord sont conservées à part, même si le profil est effacé (Écart E4 : `on delete cascade`).
- Preuve : journal d'effacement ; liste de ce qui est conservé et sa base.

### S15 - Demande de portabilité
- Règle : RGPD art. 20 (données fournies par la personne, traitées par consentement ou contrat).
- App : export JSON ou CSV (profil, créneaux, progression). Absent (Écart E3).

### S16 - Parents séparés, désaccord entre les deux parents
- Risque : l'un signe, l'autre conteste.
- Règle : en France, autorité parentale conjointe ; pour un acte usuel, un parent est présumé agir avec l'accord de l'autre envers les tiers de bonne foi (Code civil art. 372-2). L'inscription à un enseignement religieux peut ne pas être un acte usuel : à vérifier par un juriste. GN et SN : à vérifier.
- Texte : A1 « Vous déclarez avoir l'autorité parentale et, si vous la partagez, l'accord de l'autre parent. Si l'autre parent s'y oppose, prévenez-nous. »
- App : case de déclaration non précochée ; procédure « l'autre parent s'oppose » : suspension des cours sans pénalité jusqu'à accord ou décision de justice ; aucune donnée de l'enfant remise à l'autre parent sans vérification.
- Preuve : déclaration datée ; échanges archivés.

### S17 - Mineur de 15 ans ou plus qui veut décider seul
- Règle : en France, un mineur de 15 ans peut consentir seul à un service en ligne (LIL art. 45) ; en dessous, consentement conjoint mineur et parent. Au Royaume-Uni, 13 ans (DPA 2018 s. 9, à vérifier). Ailleurs : âge à vérifier par un juriste (GN, SN).
- Texte : variante « élève de 15 ans et plus » ; l'élève lit ses propres accords.
- App : à 15 ans, l'élève peut voir et retirer ses accords caméra, observation et photo ; le contrat de paiement reste au parent.
- Preuve : date de naissance ; ligne d'accord au nom de l'élève.

### S18 - L'enfant devient majeur
- App : à 18 ans, nouveaux accords au nom de l'élève ; le parent perd la vue sur ses données sauf accord de l'élève. Absent (Écart E9).

### S19 - Élève adulte
- Texte : variantes « adulte » de A0 à A6 (déjà prévues pour l'observation : `quiAdulte`, `caseAdulte`).
- App : l'adulte signe pour lui seul ; un proche adulte n'est jamais géré par le tuteur (`procheDescription` va dans ce sens).

### S20 - Transfert des données hors UE ou hors Guinée ou Sénégal
- Risque : données de familles européennes hébergées hors UE, ou données guinéennes et sénégalaises hébergées en Europe ou aux États-Unis sans formalité.
- Règle : responsable au Royaume-Uni : UK GDPR chapitre V (adéquation britannique, ou IDTA ou addendum britannique aux clauses types de l'UE) pour les transferts depuis le Royaume-Uni vers l'hébergement Supabase et vers l'Afrique ; RGPD art. 44 et suivants (décision d'adéquation art. 45, clauses types art. 46) pour les données de familles UE ; art. 28 (contrat de sous-traitance) avec Supabase, Cloudflare, LiveKit, Vercel. SN et GN : conditions de transfert à vérifier par un juriste.
- Texte : A1 nomme les prestataires, le pays d'hébergement et la garantie.
- App : rien à l'écran ; confirmer la région Supabase (non lisible dans le dépôt) et R2.
- Preuve : contrats de sous-traitance signés (DPA), liste des sous-traitants, clauses types.

### S21 - Conservation après le départ
- Règle : RGPD art. 5.1.e (durée limitée).
- Texte : tableau des durées dans A1 (voir TEXTES_V2).
- App : purge automatique (enregistrements 30 jours déjà prévus ; pièces d'identité : le texte dit « le temps de la vérification » mais la base garde 90 jours : Écart E5).
- Preuve : tâches de purge journalisées.

### S22 - Plainte d'une famille auprès de l'autorité
- Preuve à produire : registre des traitements, AIPD, textes versionnés, accords et retraits de la famille, journal des accès à ses données et aux enregistrements, réponses données dans les délais.
- App : historique des accords visible par la famille elle-même (partiel aujourd'hui).

### S23 - Décès d'un élève ou d'un parent
- Règle : en France, directives post mortem (LIL, articles sur les personnes décédées, numéro à vérifier par un juriste).
- App : procédure admin : clôture du compte, arrêt des communications, conservation minimale.

### S24 - Nouvelle version d'un texte
- Risque : considérer un ancien accord comme valant pour le nouveau texte.
- Règle : RGPD art. 7 ; information préalable.
- App : la nouvelle version est présentée avec « ce qui change » ; tant qu'elle n'est pas acceptée, l'ancien accord continue pour ce qu'il couvrait ; un traitement nouveau ne démarre pas sans accord. Le mécanisme existe pour l'observation (`/tuteur/compte/consentements`) mais `etat_dossier()` ne filtre pas la version (Écart E8).
- Preuve : chaque version archivée avec date de mise en service et empreinte.

### S25 - L'enseignant refuse l'enregistrement
- Règle : l'enseignant est salarié ou prestataire ; l'enregistrement de son travail relève du droit du travail ou du contrat de prestation (information préalable, proportionnalité) : à vérifier par un juriste selon son pays.
- Texte : E1 (contrat enseignant) explique l'enregistrement et la visite de contrôle avant signature (déjà fait par la carte d'accuse). Un refus rend la collaboration impossible si l'enregistrement est une mesure de protection des enfants : le dire avant la signature, pas après.
- Preuve : accuse `recording_and_control_notice` daté (existe).

### S26 - Visite de contrôle invisible
- Risque : surveillance cachée.
- Règle : loyauté (RGPD art. 5.1.a) ; information des personnes.
- Texte : A3 et E1 disent qu'un contrôleur de l'académie peut écouter sans être vu, et que chaque passage est inscrit au journal.
- App : bandeau permanent (existe) ; journal des visites de contrôle consultable par l'admin et, sur demande, par la famille.
- Preuve : journal chaîné (0009, 0012).

### S27 - Écoute d'un enregistrement
- Risque : écoute abusive.
- App : écoute réservée aux rôles désignés, avec motif, inscrite au journal (déjà annoncé par `pointEnregistrement`) ; la famille peut demander qui a écouté.
- Preuve : journal des écoutes.

### S28 - Photo de l'enfant
- Risque : photo utilisée hors de l'app (réseaux, publicité).
- Texte : A5 « La photo sert seulement à reconnaître votre enfant dans l'app. Elle n'est jamais publiée. »
- App : photo facultative, supprimable ; aucune utilisation promotionnelle sans accord spécifique séparé.

### S29 - Communications (rappels, nouvelles, promotions)
- Règle : les messages de service sont liés au contrat ; la prospection demande un accord (en France, Code des postes et communications électroniques L34-5, à vérifier) .
- Texte : A6 distingue messages de service (obligatoires) et nouvelles de l'académie (facultatives, désinscription en un geste).

### S30 - Agent IA avec jeton de lecture (0014)
- Risque : un tiers lit des données d'enfants.
- App : jeton limité, traçé, sans données d'identité ; mentionné dans le registre comme accès interne outillé.
- Preuve : journal des jetons.

### S31 - Droit de rétractation (famille consommateur)
- Risque : un parent demande à être remboursé 10 jours après l'achat ; ou l'académie facture sans avoir informé du droit de rétractation.
- Règle : CCR 2013 : 14 jours de rétractation pour un service conclu à distance ; si le service commence avant la fin du délai, il faut une demande expresse du consommateur ; en cas de rétractation ensuite, il paie une part proportionnée. Numéros de règlements à vérifier par un juriste. Familles UE : règles équivalentes de leur pays (Rome I art. 6).
- Texte : A1 bis (TEXTES_V2) : information sur la rétractation, case séparée non précochée « Je demande que les cours commencent avant la fin des 14 jours ».
- App : formulaire de rétractation dans Compte ; reçu daté.
- Preuve : ligne de demande expresse datée ; information remise avant paiement ; confirmation sur support durable (courriel).

### S32 - Clauses abusives et transparence du contrat
- Règle : CRA 2015 partie 2 (une clause abusive ne lie pas le consommateur ; exigence de transparence) ; en France, Code de la consommation (clauses abusives) : à vérifier.
- Texte : pas de clause d'exonération, pas de modification unilatérale sans préavis ni droit de résilier, pas de frais cachés.
- Preuve : relecture juridique datée du texte complet.

### S33 - Safeguarding et antécédents des enseignants
- Risque : un enseignant ayant des antécédents incompatibles avec le travail auprès d'enfants.
- Règle : politique de safeguarding (bonnes pratiques Keeping Children Safe in Education et NSPCC pour l'enseignement en ligne) ; contrôle DBS pour les enseignants au Royaume-Uni (niveau de contrôle à vérifier) ; équivalent (casier judiciaire) dans le pays de chaque enseignant : à vérifier par un juriste.
- Texte : A1 dit que chaque enseignant est vérifié avant d'enseigner et qu'une personne est désignée pour la protection des enfants ; contrat enseignant E1 prévoit la vérification et la conduite attendue.
- App : dossier enseignant avec date du dernier contrôle et échéance ; blocage d'affectation sans contrôle valide ; responsable safeguarding nommé et joignable depuis le bouton Signaler.
- Preuve : politique de safeguarding signée et datée ; registre des contrôles (sans copie du casier au-delà du nécessaire) ; formation des enseignants.

### S34 - Enregistrement ICO et conformité du responsable
- Risque : traitement sans enregistrement ni redevance ICO ; absence de représentant UE.
- App : aucune.
- Preuve : numéro d'enregistrement ICO, reçu de la redevance, contrat du représentant UE si requis.

### S35 - Écrans destinés aux enfants (Children's Code)
- Risque : un écran enfant pousse à partager plus (« nudge »), montre des réglages ouverts par défaut, ou cache à l'enfant que ses parents le suivent.
- Règle : Children's Code de l'ICO (15 normes) comme référence ; RGPD art. 25 (protection dès la conception).
- App : réglages les plus protecteurs par défaut (caméra coupée, pas de photo, pas de géolocalisation, pas de profilage) ; texte à la hauteur de l'âge ; l'enfant voit quand un parent ou un contrôleur peut écouter (bandeau permanent, déjà présent) ; pas de série, badge ou notification conçus pour retenir l'enfant au-delà du cours.
- Preuve : grille des 15 normes remplie écran par écran, jointe à l'AIPD.

## Les 5 risques majeurs

1. Consentement groupé : un seul « J'ai lu et j'accepte » couvre conditions, enregistrement audio et observation, sans bouton de refus ni texte complet (S01, S03, S08).
2. Donnée religieuse (art. 9) et mineurs sans base légale écrite, sans AIPD, sans registre (point sensible, S12).
3. Pas de retrait ni d'exercice des droits dans l'app (S04, S13 à S15), et preuve d'accord effaçable avec le profil (S14).
4. Caméra automatique dès 11 ans et observation dans une classe où toutes les familles n'ont pas dit oui (S06, S07).
5. Conformité du responsable non établie : enregistrement ICO, représentant UE, transferts (IDTA, clauses types) et sous-traitants non documentés (Supabase, R2, LiveKit, Vercel), droit de rétractation et contrôle des antécédents des enseignants absents (S20, S31, S33, S34).
