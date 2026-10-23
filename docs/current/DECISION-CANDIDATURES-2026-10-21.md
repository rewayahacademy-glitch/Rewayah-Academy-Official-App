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

## 1 bis. Décidé le 22/10/2026 : faire connaître l'offre aux élèves depuis la salle d'attente

Le directeur, le 22/10 : profiter de la salle d'attente des candidats (près de 500
personnes) pour qu'ils fassent connaître l'académie, en rappelant la valeur d'être
la cause qu'une personne apprenne le Coran ; « un geste facile », une carte « très
jolie, très partageable sur une story ». Puis, après l'étude : « il ne faut pas que
les prix soient sur la carte. Il faut laisser ça sur le site public […] La carte doit
être simple et avoir le design de site si nécessaire. Des éléments simples, pas
beaucoup. Un hadith peut suffire […] En arabe, c'est الدال على الخير كفاعله.
Maintenant, tu décris, bien, tu ajoutes une description. Tu peux pousser, mais sans
mentir, sans forcer aussi les gens. Donc, pour l'instant, on peut laisser les
enseignants de côté et se concentrer seulement sur les élèves. »

| Point | Décision |
| :--- | :--- |
| Quoi | Une tuile « Faites connaître Rewayah » dans le portail de la salle d'attente : une carte au format story à partager (menu de partage du téléphone, enregistrer l'image, copier le lien). |
| Pour qui | **L'offre pour les élèves seulement.** Le recrutement des enseignants est laissé de côté pour l'instant. |
| La carte | Simple, peu d'éléments, au style du site public ; **aucun prix** (ils restent sur le site public) ; **un seul hadith** : « الدال على الخير كفاعله », avec sa traduction ; une description courte ; le lien vers l'offre. |
| Le ton | Encourager sans mentir et sans forcer. Facultatif, et sans aucun effet sur la candidature. |
| L'angle (directeur, 22/10, après coup) | « Ce n'est pas bon en marketing, tu leur demandes de faire une action sans aucune contrepartie […] le hadith seul ne peut pas se faire […] Il faut penser aux élèves. Il faut leur parler de l'intérêt que l'élève va avoir. Pas Rewayah Academy. » **Aucun texte ne demande d'agir pour l'académie.** La tuile parle à celui qui partage de la personne qui apprendra (« Un proche veut apprendre le Coran ? ») ; la carte parle au futur élève de ce qu'il gagne ; le hadith reste, en motif personnel, pas seul. Les mots exacts sont soumis au directeur avec les captures. |
| Source du hadith | La formulation « الدال على الخير كفاعله » est celle que rapporte at-Tirmidhi (n° 2670, d'après Anas) ; Muslim (n° 1893) rapporte le même sens sous la forme « من دل على خير فله مثل أجر فاعله ». La référence affichée et la traduction française sont à confirmer par le directeur avant toute mise en ligne. |
| Carte redessinée, appel à l'action et langues (22/10, soir) | **Rejet de la carte** (« trop nulle et moche ») et direction du directeur : « l'utilisation de l'arc décoratif est définie dans le brandbook, je préfère celui avec bordure seule agrandi (s'affiche pas entièrement parce qu'il est grand) et surtout tamisé… utilise aussi le portail comme subtilement pour indiquer la rentrée dans le bonheur du Coran et le savoir pour l'élève ». **Carte** : fond violet profond uni ; le symbole contour officiel (`symbole-contour.svg`, jamais redessiné) à 1,85 fois la largeur, coupé par les bords, en blanc à 7 %, son axe sur celui de la porte ; un portail (porte en arche et chemin de lumière courbe qui s'élargit vers le lecteur, deux aplats, sans dégradé, la lumière la plus vive près de la porte) ; typographie suisse ; la signature « بوّابتك نحو القرآن » (M-26) près de la porte ; le QR sur plaque blanche ; le hadith tout en bas, discret. **Deux variantes** selon le genre lu sur le profil de la personne qui partage, **jamais deviné** : les hommes (genre inconnu compris : la composition sans personnage, mots neutres) ; les femmes (teinte mauve prune, silhouette de femme voilée de dos, sans visage, qui marche dans la lumière, quelques fleurs ton sur ton). Les couleurs des femmes sont **proposées, hors charte** (comme les teintes d'identité, M-23) : le directeur les valide sur les captures. **Seconde consigne, prioritaire** : « personnalise celle des femmes davantage pour leur donner courage à partager (couleur plus adaptée aux femmes, des illustrations féminines) et ta phrase d'appel à l'action est nulle. Je pense à quelque chose qui allie la fierté de participer à un geste noble (partage du savoir) et la simplicité […] je veux aider au moins une personne à apprendre la parole d'Allah en partageant […] Et surtout peu de mots. » **Effet** : la tuile et la page disent « Aidez une personne à apprendre la parole d'Allah. » (« Aidez une sœur… » pour une femme ; en arabe « ساعد شخصًا على تعلّم كلام الله » et, au féminin, « ساعدي أختًا على تعلّم كلام الله »), le bouton dit « Je partage » (« أشارك ») ; les explications sont supprimées, **seule reste** la mention « Facultatif : partager ne change rien à votre candidature. » ; la carte, lue par le futur élève, garde un titre court sur ce qu'il gagne. **Langues** (« prends la langue de la personne qui partage et adapte sa carte à sa langue », « pas les langues vernaculaires, juste les internationales ; regarde la langue dans laquelle le candidat veut enseigner et utilise celle-là », « ne me demande pas de valider des traductions », puis « il va aussi avoir le portugais ») : la carte existe en **français, anglais, portugais et arabe, et seulement dans ces quatre langues**. Langue de départ : la première langue d'enseignement du candidat (réponse `languesExplication`) qui est le français, l'anglais ou le portugais, sinon la langue de l'application (français ou arabe) ; quatre puces la changent avant de partager. Les textes de la carte sont dans un fichier de données (`lib/features/partage_offre/textes_carte.dart`), traduits par l'agent d'après le français et l'arabe, **sans validation demandée** ; ceux de l'app (tuile, page, boutons) restent en français et en arabe. Statut : présent dans le code, testé localement (tests de widget, rendu réel en PNG) ; ni staging ni production. |
| Carte des femmes sans personnage (23/10) | « La carte à partager féminine contient le dessin d'un personnage qui est nul, il faut le supprimer, n'utilise pas de personnage, ajoute juste des éléments féminins comme des fleurs discrètes ou un ornement féminin (tout discret). » **Prévaut sur la silhouette de la ligne ci-dessus.** La carte des femmes ne porte **aucune figure humaine** : seulement une fine branche fleurie en trait, ton sur ton, à faible contraste, au bas du chemin de lumière, sans dégradé (`lib/features/partage_offre/branche_fleurie.dart`). La variante des hommes est inchangée. Teinte inchangée (toujours proposée, hors charte). |
| La lumière et les ténèbres de la carte (23/10, **exception datée au « aucun dégradé » du cahier visuel**) | « sur les cartes partageables (la lumière de la porte n'est pas cohérente sur les deux), elle n'est pas droite et ne donne pas cette sensation de lumière qui sache [chasse] l'ombre car toute la carte adopte la même lumière partout. regarde mes images. une sorte de dégradé qui montre la dissipation de la lumière de l'immensité des ténèbres. » (images de référence : une porte en arche debout, ouverture blanche éblouissante, halo doux sur le mur, lumière au sol en trapèze à bords rectilignes qui s'élargit vers le spectateur, la plus vive au seuil et dissipée peu à peu ; le reste de la scène sombre, plus sombre vers les bords.) **Prévaut sur le « chemin de lumière courbe en deux aplats, sans dégradé » de la ligne du 22/10 et sur « au bas du chemin de lumière » de la ligne ci-dessus.** **Exception** : le cahier des charges visuel (A.4) dit « aucun dégradé (logo, ornement, fonds) » ; la demande datée du directeur prévaut pour **la lumière et l'obscurité de cette scène seulement** (registre de marque, M-29). Le logo (blanc, plat, jamais redessiné), le symbole contour (filigrane, un trait blanc à 7 % partout où il se voit), le cadre en arche de la porte (un trait d'une couleur et d'une opacité fixes), la branche fleurie, la plaque du QR et le fond de la carte restent des **aplats**. Les couleurs restent des **jetons** (`AppPaletteCarte` : un éclat et des ténèbres s'y ajoutent, nommés). **Effet** (`lib/features/partage_offre/decor_carte.dart`) : la porte est debout sur une ligne de sol (le seuil) ; son ouverture (52 pt de large, le haut de la porte à 29 % de la hauteur de la carte) est la zone la plus claire **de la scène** : un blanc pur au cœur qui retombe vers la teinte de la variante sur ses bords (la plaque blanche du QR et les textes restent blancs aussi : ce sont des éléments de l'interface, pas de la lumière), avec un **halo** large qui déborde sur son cadre et sur le mur, sans creux entre l'ouverture et le cadre (de l'ouverture vers le mur, la lumière ne fait que baisser) ; le **faisceau** qu'elle pose au sol **part exactement du seuil** (sa base est l'ouverture) et ses deux bords sont des **droites** (11° et 40° sous l'horizontale) qui s'écartent vers le lecteur, vers le bas et vers le côté opposé à la porte : aucune courbe, aucune bande plate ; un dégradé linéaire le long du faisceau, très vif au seuil, un peu plus clair au centre qu'aux bords, qui s'éteint jusqu'à disparaître ; tout le reste est dans les **ténèbres** (un violet presque noir de la teinte de la variante, de plus en plus dense vers les bords et les coins, un peu de lumière ambiante autour de la porte seulement). **Le sol n'a aucun motif** : le symbole contour est un décor du mur, il s'éteint dans l'ombre en arrivant au seuil de la porte (fondu vertical de 80 pt, dans l'exception datée) et ne traverse jamais le faisceau. **Les deux variantes ont la même lumière** : la même géométrie et **la même luminosité à chaque endroit de la scène, à 5 % près** (mesuré sur les pixels, 16 points, `carte_partage_test.dart`) ; seule la teinte change. Pour cela, les couleurs proposées des femmes ont été recalibrées le 23/10 (relecture visuelle : leur scène était 20 à 30 % plus claire, donc plus embrumée) : fond prune `#542C62` (au lieu de `#6B3A87`, de même profondeur que le violet des hommes), ténèbres `#190924`, lumière `#A24BB7` puis `#D192E4` ; elles restent **proposées, hors charte**, à valider sur les captures. La branche fleurie des femmes, toujours sans personnage, est dans la pénombre au bord du faisceau, sans jamais le couper. Les textes et le QR restent lisibles : chaque texte est mesuré sur le pixel le plus clair qu'il traverse (au moins 6,46:1 relevé, seuil 4,5:1). Statut : présent dans le code, testé localement (tests de géométrie et de pixels sur le rendu réel, captures `PARTAGE-v4`) ; ni staging ni production. |

## 1 ter. Décidé le 22/10/2026 : le questionnaire de la Salle d'examen

Réponses du directeur aux huit questions de l'audit
(`CANDIDATURES/AUDIT_QUESTIONNAIRE_SALLE_EXAMEN_2026-10-22.md`, section 5).

| Point | Décision |
| :--- | :--- |
| Langues d'enseignement | **Autant de langues que la personne veut**, sans plafond : « le programme, il est international ». C'est la langue dans laquelle l'enseignant explique qui décide de sa Classe : l'élève ou le parent choisit sa langue parmi celles qui sont disponibles, et l'académie affecte un enseignant qui la parle. |
| Poular | **Poular, peul et fulfulde sont une seule langue**, sous le code `poular`. |
| Arabe | **L'arabe n'est pas une langue de cours.** « Notre public principal, c'est les Africains de la diaspora […] des Peuls, des Malinkés, des Soussous, des Swahili, des Haoussa. » La liste des langues d'enseignement doit proposer ces langues. Effet : l'arabe sort des langues de cours de l'offre (`tarifs-2026-10-18.json`, encarts et `regles_publiques.langues`, le 22/10) ; le site public, zone protégée, suit par sa propre session. |
| Publics | **Les tranches d'âge, au choix** : 6-9, 10-13, 14-17 ans, adultes ; « beaucoup de gens ne sont pas à l'aise à enseigner certaines tranches d'âge ». |
| Mémorisation et ijaza | **Deux questions** : « celui qui a une ijaza a mémorisé, mais toute personne qui a mémorisé n'a pas une ijaza ». |
| Continuité | **Oui** : l'engagement à tenir sa Classe aux mêmes jours et heures. |
| Paiement | **S'assurer que les personnes qui s'engagent pourront être payées** : le contrôle de paiement reste une condition d'entrée en salle 2. |
| Charge maximale | **Trois Classes au plus par enseignant pour l'instant**, réglable par la direction dans les réglages. **Posé le 22/10 côté serveur** (`testé localement`, ni staging ni production) : réglage `enseignant.classes_max` de la table des réglages de la direction (3 par défaut, entier de 1 à 80, changement journalisé comme les autres réglages), vérifié chaque fois qu'un enseignant reçoit une Classe (`plafond_classes_atteint`) ; une Classe close et un remplacement ponctuel ne comptent pas ; une baisse ne retire aucune Classe déjà tenue. La question « combien de Classes souhaitez-vous ? » propose de 1 à ce maximum. L'écran du réglage et les phrases de refus du client restent à faire. |
| Disponibilités | Le directeur, le 22/10 : « les formulaires de base ne sont pas des références en termes d'architecture et de choix […] c'étaient des formulaires pilotes » ; la grille doit « couvrir tout ce que l'académie a besoin pour déterminer réellement les créneaux de l'enseignant et les faire matcher avec ceux de l'élève ». Constat : la grille de blocs de quatre heures ne le permet pas (une Classe commence à une heure entière, trois fois par semaine aux mêmes jours, pour 60 ou 90 minutes, et l'affectation lit les disponibilités heure par heure). Posé le 22/10 côté serveur (`testé localement`) : disponibilités heure par heure, dans l'heure locale du candidat, au format que lit l'affectation. Le cours d'adultes de 90 minutes, qui n'était pas comparé correctement (une seule durée de 60 minutes, une ligne d'une heure par séance), l'est depuis le 22/10 (`testé localement`, ni staging ni production : `supabase/migrations/20261022000400_classes_affectation_couvre_toute_la_duree.sql`) : la durée est celle de la Classe, et chaque heure touchée par la séance doit être déclarée. **Reste ouvert** : le côté élève, les créneaux libres affichés, et la durée des séances matérialisées (60 minutes pour toutes les Classes, adultes comprises ; spec consolidée 2.1 bis). |
| Paie, en arabe | **« الراتب » (« الراتب الشهري »), jamais « أجر »**, qui ferait penser à la récompense d'Allah. |
| Formulaires pilotes | Les réponses des formulaires Google sont gardées (les personnes inscrites restent), mais **leurs questions ne sont pas une référence** pour concevoir le questionnaire. |

## 1 quater. Décidé le 22/10/2026 : les autres compétences des candidats, et le portugais

| Point | Décision |
| :--- | :--- |
| Autres compétences | Le directeur : « profiter de ce grand nombre pour faire d'autres recrutements […] il faut leur demander […] glisser discrètement ces demandes […] sans les ennuyer avec trop de questions […] être transparent » (exemples : une assistante pour le groupe des femmes, des comptables, des social media managers). Conception retenue (« à toi de faire ») : `CANDIDATURES/PROPOSITION_AUTRES_COMPETENCES.md` ; parcours facultatif de trois écrans dans la salle d'attente, après l'envoi, avec la raison dite en premier ; filtre côté direction, séparation femmes et hommes respectée. **Précision du directeur, 22/10** : « il faut être spécifique dans ce que tu vas demander comme compétence : social media management, relations publiques, design graphique, montage vidéo, administration, spécialistes en pédagogie, etc. » : la liste fermée de domaines vagues est remplacée par un **catalogue de compétences précises, en base** (25 compétences en six familles : communication, administration, finances et droit, pédagogie, technique, autre ; ajout seul ou désactivation, jamais de suppression ; lu par le candidat et la direction, écrit par la direction seule, journalisé ; filtre de la liste par code ou par famille). **Serveur écrit le 22/10** (`présent dans le code`, `testé localement`, ni staging ni production) : `supabase/migrations/20261022000500_cand_autres_competences.sql`, `CANDIDATURES/PROPOSITION_AUTRES_COMPETENCES.md` section 7 (sept points à soumettre), `CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md` sections 3 bis et 3 ter ; l'écran, l'écran du catalogue de la direction et les textes restent à faire. |
| Langues de la carte de partage | Langues internationales seulement : français, anglais, portugais (« il va aussi avoir le portugais »), arabe ; par défaut la langue dans laquelle le candidat veut enseigner si c'est l'une d'elles, sinon la langue de l'app. Le directeur ne valide pas les traductions : Claude les fait. |

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
