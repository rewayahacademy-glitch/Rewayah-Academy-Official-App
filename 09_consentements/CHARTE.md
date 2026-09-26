# 09 - Charte des consentements et contrats (tous rôles, tous agents)

Date : 25/09/2026. S'applique à tout texte d'accord, de contrat, d'information ou de conservation, pour tous les rôles : tuteur, enfant, élève adulte, enseignant, admin, contrôleur.

## 0. Qui est responsable, quel droit

- Responsable du traitement : **Rewayah Academy Ltd, société de droit anglais** (Angleterre et pays de Galles), numéro {numero_societe}, siège {adresse_siege}.
- Droit principal : UK GDPR et Data Protection Act 2018. Autorité principale : ICO (enregistrement et « data protection fee »).
- Familles dans l'UE : RGPD aussi (art. 3.2) ; représentant dans l'UE (art. 27) probablement requis.
- Familles en Guinée et au Sénégal : lois L/2016/037/AN et 2008-12 en complément.
- Consommateurs : Consumer Rights Act 2015 (clauses abusives, transparence), Consumer Contracts Regulations 2013 (rétractation 14 jours) ; un consommateur UE garde les protections impératives de son pays (Rome I art. 6).
- Enfants : Children's Code de l'ICO = référence de conception pour tout écran vu par un enfant ; politique de safeguarding.

## 1. Principes

1. **Loyauté.** On dit tout ce qu'on fait, avant de le faire. Rien de caché dans un texte long.
2. **Pas de clause d'exonération.** Jamais « l'académie décline toute responsabilité ». Une telle clause est abusive, réputée non écrite, et se retourne contre nous en audit. On protège l'académie par la loyauté, la preuve et la proportionnalité.
3. **Un accord = un sujet.** Pas de consentement groupé. Le contrat de service est distinct des accords facultatifs.
4. **Le refus est un vrai choix.** Même poids visuel que l'accord. Conséquence annoncée, proportionnée, sans reproche.
5. **Retrait aussi simple que l'accord** (RGPD art. 7.3). Au même endroit pour tous : Compte, Mes accords.
6. **Rien de précoché, rien d'implicite.** Le silence, la présence en classe ou la poursuite de la navigation ne valent pas accord.
7. **La bonne base légale.** Contrat pour ce qui est nécessaire au service ; consentement pour le facultatif ; consentement explicite pour la donnée religieuse ; intérêt légitime (avec opposition) pour la protection, si le juriste le valide. Ne jamais demander un « consentement » pour ce qu'on fera de toute façon.
8. **Minimisation.** Ne collecter que le nécessaire. Aucune donnée de pratique religieuse. Messages au titre neutre.
9. **Honnêteté sur les limites.** Dire ce qu'on ne peut pas empêcher (captures par d'autres familles, surveillance à la maison).
10. **Le texte suit la réalité.** Un bandeau ou un texte ne décrit que ce que le serveur fait vraiment (ex. enregistrement réel).
11. **Langue et lisibilité.** Français facile, phrases courtes, pas de tiret cadratin. Même version en poular et anglais, traduite par un humain.
12. **Mineurs.** Le parent décide ; l'enfant est informé avec des mots de son âge ; l'élève décide seul des accords facultatifs à partir de l'âge du consentement numérique : 13 ans au Royaume-Uni (DPA 2018 s. 9, à vérifier), 15 ans en France (LIL art. 45), à vérifier en Guinée et au Sénégal. En cas de doute, le plus protecteur.
13. **Children's Code (15 normes ICO).** Intérêt supérieur de l'enfant ; réglages protecteurs par défaut ; minimisation ; aucun « nudge » vers moins de protection ; géolocalisation coupée ; pas de profilage ; transparence adaptée à l'âge ; l'enfant voit quand un parent ou l'académie peut l'écouter ou le suivre ; outils pour signaler et exercer ses droits.

## 2. Gabarit d'un texte d'accord

```
Titre : <sujet en 3 à 6 mots>
Ce que nous faisons. <1 à 3 phrases>
Pourquoi. <1 à 2 phrases>
Qui voit. <rôles précis ; ce qu'ils ne voient pas>
Combien de temps. <durée chiffrée ; événement de départ>
Comment retirer. <chemin exact dans l'app ; quand le retrait compte>
Si vous refusez. <conséquence exacte et proportionnée ; « rien d'autre ne change » si vrai>
[ J'accepte ] [ Je refuse ]
Métadonnées : sorte, version, base légale, rôle, variantes (tuteur, adulte, 15 ans et plus), clés i18n.
```

Interdit dans un texte : « décline toute responsabilité », « en aucun cas », « sans limite », « irrévocable » (pour un accord), « en continuant vous acceptez », formules culpabilisantes (« vous priverez votre enfant... »).

## 3. Gabarit d'écran

- Titre, texte du gabarit, lien « Lire le texte complet » si un texte long existe.
- Deux boutons côte à côte ou l'un sous l'autre, **même taille, même style** (pas de bouton gris pâle pour le refus).
- Aucune case précochée. Une case seulement pour une déclaration (ex. autorité parentale).
- Pas de compte à rebours, pas de fenêtre qui revient pour faire changer d'avis. Un rappel au plus lors d'une nouvelle version.
- Après le choix : **reçu daté** à l'écran (date, heure, version) et copie par courriel ou dans Compte.
- **Compte, Mes accords** : liste de chaque accord avec état (accepté, refusé, retiré), date, version, texte lisible, bouton « Retirer » ou « Accepter ».
- Hors ligne : ne jamais enregistrer un accord localement en le montrant comme acquis ; dire « pas encore enregistré ».
- Accessibilité : lecteur d'écran, contraste, cible tactile de 48 px.

## 4. Preuves à conserver pour chaque choix

| Champ | Exemple |
|-------|---------|
| Qui décide | `profile_id` du signataire |
| Pour qui | `student_profile_id` si c'est pour un enfant |
| Qualité | tuteur, élève 15 ans et plus, adulte, enseignant |
| Sorte | `camera`, `observation`... |
| Décision | accepté, refusé, retiré, opposition |
| Version et empreinte | `2026-10-v2` + empreinte SHA-256 du texte affiché |
| Langue | fr, ff, en |
| Horodatage serveur | `now()` côté base, jamais l'heure de l'appareil |
| Canal | appli Android, web, iOS ; version de l'app |
| Lien | l'accord que ce retrait annule |

Les lignes sont en ajout seul (déjà le cas pour `contract_acceptances`) et survivent à l'effacement du profil (pseudonymisées) le temps de la prescription. Chaque version de texte est archivée avec sa date de mise en service.

## 5. Registre des traitements (RGPD art. 30) à tenir

Un traitement par ligne, avec finalité, base légale, catégories de personnes et de données, destinataires, sous-traitants, transferts, durée, mesures de sécurité :

1. Gestion des comptes et du foyer. 2. Vérification d'identité (KYC). 3. Organisation des cours et affectation. 4. Visio en direct (LiveKit). 5. Enregistrement audio (R2). 6. Visite de contrôle. 7. Visites d'observation des parents. 8. Suivi pédagogique et évaluations. 9. Facturation et paiements. 10. Messages de service et nouvelles. 11. Journal d'audit. 12. Accès agent IA en lecture (jetons 0014). 13. Signalements et protection de l'enfance. 14. Gestion des demandes de droits.

Mention sur 1, 3, 4, 8 : donnée pouvant révéler une conviction religieuse (art. 9).

## 6. Dossier d'audit (ce qu'on montre à l'autorité)

1. Registre des traitements (section 5).
2. Analyse d'impact (AIPD, RGPD art. 35) : mineurs, donnée religieuse, enregistrement, observation.
3. Test de mise en balance pour l'enregistrement et la visite de contrôle (si intérêt légitime).
4. Tous les textes, versionnés, avec date de mise en service et captures des écrans (accord, refus, retrait).
5. Extraction des accords, refus et retraits d'une personne donnée, en moins d'une heure.
6. Contrats de sous-traitance (Supabase, Cloudflare, LiveKit, Vercel, prestataire de paiement, envoi de courriels) ; région d'hébergement ; garanties de transfert.
7. Politique de conservation et journaux des purges.
8. Politique de sécurité : RLS, journal chaîné, tests, gestion des secrets, contrôle des accès aux enregistrements.
9. Registre des violations de données et procédure 72 heures.
10. Registre des demandes de droits et délais de réponse.
11. Procédure de signalement et de protection de l'enfance, charte enseignant signée.
12. Formalités : numéro d'enregistrement ICO et reçu de la data protection fee ; contrat du représentant UE si requis ; déclaration ou autorisation CDP (Sénégal) ; formalités Guinée.
13. Nom et contact du référent données (DPO si obligatoire : à vérifier).
14. Transferts : analyses de transfert, IDTA ou addendum britannique, clauses types UE, pour chaque flux (Royaume-Uni vers hébergement, Royaume-Uni vers Afrique, UE vers Royaume-Uni).
15. Politique de safeguarding datée, responsable désigné, registre des contrôles d'antécédents des enseignants (DBS au Royaume-Uni, équivalent ailleurs), formations.
16. Grille Children's Code remplie écran par écran pour les écrans enfants.
17. Contrat consommateur : information précontractuelle, rétractation, demandes expresses de démarrage anticipé, confirmations sur support durable.

## 7. Règles par rôle

- **Tuteur** : A0 à A6 (TEXTES_V2) ; déclaration d'autorité parentale.
- **Enfant de moins de 15 ans** : un écran d'explication à sa hauteur (« Ton cours est écouté pour te protéger. Tu peux éteindre ta caméra. Si quelque chose te gêne, dis-le à tes parents ou appuie sur Signaler. »). Pas de décision demandée.
- **Élève de 15 ans et plus** : voit et gère ses accords facultatifs (caméra, observation, photo).
- **Élève adulte** : variantes « vous », décide seul, jamais géré par un autre adulte.
- **Enseignant** : contrat, E1 (enregistrement, contrôle), confidentialité des familles, interdiction de contact privé, charte de conduite, obligation de signaler.
- **Admin et contrôleur** : engagement de confidentialité signé ; chaque écoute et chaque visite avec motif, au journal ; accès au minimum.

## 8. À faire valider par un juriste avant la production

1. Base légale de l'enregistrement audio et de la visite de contrôle invisible (intérêt légitime ou autre) ; test de mise en balance.
2. Base de la donnée religieuse (art. 9.2.a ou 9.2.d selon le statut de l'académie).
3. Statut juridique, pays d'établissement, besoin d'un représentant UE (art. 27) et d'un DPO.
4. Âge de décision seul de l'enfant en Guinée et au Sénégal ; âge du seuil caméra.
5. Formalités auprès de la CDP (Sénégal) et de l'autorité guinéenne (nom et procédure) ; applicabilité de L/2016/037/AN et de la loi 2008-12, articles précis.
6. Transferts : région Supabase, R2, LiveKit ; clauses types ; conditions de transfert depuis la Guinée et le Sénégal.
7. Inscription d'un enfant à un enseignement religieux : acte usuel ou non (parents séparés).
8. Durées de conservation (compte après départ, journal d'audit, preuves d'accord, factures selon le pays).
9. Texte complet des conditions (A1) et contrat enseignant, y compris clause de non-concurrence (validité selon pays).
10. Procédure de signalement de maltraitance par pays.
11. Directives post mortem et décès.
12. Messages de prospection (règles par pays).
13. Blocage de capture d'écran et clause d'interdiction de captation (qualification, sanctions).
14. Enregistrement ICO, montant de la redevance, nécessité d'un représentant UE et choix de celui-ci.
15. Mécanismes de transfert UK (adéquation, IDTA, addendum) et UE ; conditions de transfert vers et depuis la Guinée et le Sénégal.
16. Âge du consentement numérique applicable à chaque famille (UK 13, France 15, Guinée, Sénégal) quand le responsable est au Royaume-Uni.
17. Rétractation CCR 2013 et règles UE équivalentes ; clause de droit applicable et de juridiction (Rome I art. 6, Bruxelles I bis pour les familles UE) ; conformité CRA 2015 du texte complet.
18. Safeguarding : niveau de contrôle DBS requis pour des enseignants en ligne, équivalents en Guinée, au Sénégal et en France ; obligations de signalement.
19. Conditions du DPA 2018 annexe 1 pour la donnée religieuse au Royaume-Uni.

## 9. Écarts trouvés dans le code actuel (corrections à faire, non codées)

| # | Écart | Où | Correction |
|---|-------|----|------------|
| E1 | Un seul accord `guardian_terms` couvre conditions, enregistrement et observation : consentement groupé | `signature_page.dart`, `versions_contrat.dart`, `contract_acceptances` | Sortes séparées (TEXTES_V2), une ligne par choix |
| E2 | Pas de refus ni de retrait enregistrables ; table sans colonne décision | `0004` section 7 | Table `consent_events` en ajout seul (décision accepté, refusé, retiré, opposition) ; RPC `retirer_accord` |
| E3 | Aucun écran de droits (accès, effacement, portabilité, opposition) ni suppression de compte | Compte | Compte, Mes données ; registre des demandes |
| E4 | `contract_acceptances.profile_id ... on delete cascade` : la preuve disparaît (ou la suppression du profil échoue à cause du trigger) | `0004` | Référence pseudonymisée, pas de cascade, durée de conservation propre |
| E5 | `kyc.intro` dit « conservée le temps de la vérification » mais `kyc_retention_days` = 90 | `fr.i18n.json`, `0004` | Aligner texte et purge (A7) ; purger dès décision |
| E6 | `camera_auto_allow_min_age` = 11 : caméra sans accord du tuteur au-dessus de 11 ans | `0001`, config admin | Seuil 15 minimum (France), à valider par pays ; accord A2 obligatoire en dessous |
| E7 | Rien ne montre que l'observation ne s'ouvre que si toutes les familles de la classe ont accepté | `0036`, `0037` (non appliquées) | Porte serveur : visites fermées si une famille n'a pas accepté la version en cours |
| E8 | `etat_dossier()` ne filtre pas la version : un compte actif continue sous un texte non accepté | `versions_contrat.dart` (commentaire) | Tout traitement nouveau vérifie l'accord de la version en cours côté serveur |
| E9 | Pas de bascule à 15 ans ni à 18 ans | profils élèves | Tâche datée : nouvelles demandes d'accord au nom de l'élève |
| E10 | « Lire le texte complet » (`contrat.lireTexte`) : clé sans écran, texte intégral inexistant | `signature_page.dart` | Rédiger, publier, archiver ; lien réel |
| E11 | Pas de bouton « Je refuse » à la signature | `signature_page.dart` | Deux boutons de même poids ; écran de sortie |
| E12 | Accord sans enfant désigné, sans empreinte de texte, sans langue, sans canal | `contract_acceptances` | Champs de la section 4 |
| E13 | Pas de reçu daté envoyé à la famille | signature, consentements | Reçu à l'écran et par courriel |
| E14 | Photo de l'enfant sans information ni durée | fiche élève, photo | Texte A5 ; purge au départ |
| E15 | Pas de déclaration d'autorité parentale ni de procédure « l'autre parent s'oppose » | inscription | Case de déclaration, procédure admin |
| E16 | Pas de bouton Signaler dans la salle ni de gel d'enregistrement lié | salle, `session_recordings` | Bouton, statut `gele`, purge suspendue |
| E17 | Pas de blocage de capture d'écran dans la salle | salle (Android) | FLAG_SECURE ; rappel dans la salle |
| E18 | Le changement de `camera_policy` n'a pas de trace datée visible (à vérifier dans le journal 0009) | `service_appairage.dart` | Événement de journal à chaque changement |
| E19 | Région d'hébergement et sous-traitants non documentés dans le dépôt | `supabase/config.toml` | Fiche sous-traitants dans le dossier d'audit |
| E20 | Aucune explication pour l'enfant lui-même | salle, interface guidée | Écran enfant (section 7), conforme au Children's Code |
| E21 | Aucune identité du responsable (Rewayah Academy Ltd, numéro, adresse, ICO) dans l'app | signature, Compte | Clé `accordsV2.responsable` ; page Informations légales |
| E22 | Aucune information ni formulaire de rétractation de 14 jours, ni demande expresse de démarrage anticipé | paiement, Compte | Texte A1 bis ; formulaire ; trace datée |
| E23 | Aucun suivi des contrôles d'antécédents des enseignants ; affectation possible sans contrôle | dossier enseignant, affectation | Date et échéance du contrôle ; blocage serveur de l'affectation |
| E24 | Aucun responsable safeguarding joignable depuis l'app | salle, Compte | Contact dans Signaler et dans A1 |

## Décision du directeur du 26/09/2026 : photo de l'élève

1. **La photo de l'élève s'affiche** chez son enseignant, à l'administration **et chez les élèves de sa Classe** : roster, fiche élève, salle, cahier, dossiers.
   - Raison donnée par le directeur : si le tuteur a choisi une photo, c'est que l'enseignant et l'administration en ont besoin.
   - La vidéo est déjà permise en classe, et les camarades la voient ; la photo, qui en dit moins, l'est donc aussi.
   - Les initiales ne servent que de repli, quand aucune photo n'a été déposée.
2. **Le consentement se donne à l'inscription de l'enfant.**
   - Le texte A5 (`TEXTES_V2.md`) est présenté pendant l'inscription, avec les autres accords. Sa ligne « Qui voit » dit désormais : l'enseignant de {prenom}, les élèves de sa Classe et l'équipe.
   - Il reste un accord distinct (principe 3), retirable au même endroit que les autres (principe 5).
3. **Correction.** Une règle « initiales seulement, jamais la photo de l'élève » avait été ajoutée par un agent sans décision du directeur. Elle est retirée partout.