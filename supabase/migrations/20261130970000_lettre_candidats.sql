-- LETTRE-SERVEUR (20/11/2026) : la lettre aux candidats enseignants n'est rendue que par le serveur, et seulement a qui a le droit
-- de la lire (directeur, 20/11/2026 : « seulement les enseignants et les candidats qui ont complete les consentements [...] Ca doit
-- se faire aussi cote serveur »). Lot : docs/current/CANDIDATURES/LETTRE-CANDIDATS/LOT.md, section « Controle serveur ».
-- Contrat de la reponse : lib/features/candidature/lettre/port_lettre.dart (en tete du fichier ; c'est lui qui fait foi).
--
-- LIVRE ICI :
--   1. private.lettre_candidats_parties : le texte de la lettre, une ligne par partie (langue, version, rang, code, titre, corps).
--      Schema prive (jamais expose par l'API), RLS activee, AUCUNE politique, tous les droits retires aux roles clients.
--   2. Les 14 parties en francais, anglais et arabe, version 2026-11-20, recopiees MOT POUR MOT depuis
--      docs/current/CANDIDATURES/LETTRE-CANDIDATS/LETTRE-{fr,en,ar}.md, decoupees comme partiesDuDepot()
--      (test/features/candidature/faux_port_lettre.dart). Les INSERT sont engendres par un script, pas ecrits a la main.
--      C'est un texte de l'academie, aucune donnee de personne.
--   3. public.lire_lettre_candidats(p_langue text) -> jsonb, SECURITY DEFINER, search_path vide, executable par authenticated seul.
--      Acces : role enseignant dans le jeton (public.app_role()) ET profil enseignant non efface, au statut pending_kyc,
--      provisional_active ou active, acces non expire ; puis compte actif (account_status = 'active'), OU les trois accords lus par
--      public.etat_dossier() (la meme source que la page « Votre dossier » : contrat_signe, code_conduite_signe,
--      candidature.cadreReligieux.accepte ; le cadre n'est exige que s'il est publie, public.cadre_religieux_version_requise()).
--      Refus sans une ligne du texte : raison « role » (jeton d'un autre role ou sans role), « compte » (sans session, profil
--      absent, efface, desactive, acces expire, profil d'un autre role), « accords » avec « manques » dans l'ordre contrat,
--      conduite, cadre. Langue inconnue ou sans texte : le francais.
--
-- MOTS D'EFFACEMENT : ZERO (compte en mots entiers, commentaires et texte de la lettre compris). Un compte en sous-chaine trouve
-- seulement la colonne profiles.deleted_at (lue) et le mot anglais « deleted » du texte anglais (parties 8 et 12).
-- Aucune fonction existante n'est remplacee.
-- Sans BEGIN ni COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.etat_dossier()') IS NULL
     OR pg_catalog.to_regprocedure('public.app_role()') IS NULL
     OR pg_catalog.to_regprocedure('public.cadre_religieux_version_requise()') IS NULL
     OR pg_catalog.to_regnamespace('private') IS NULL THEN
    RAISE EXCEPTION 'LETTRE-SERVEUR : dependances absentes (etat_dossier, app_role, cadre religieux, schema private) ; rien n''est modifie';
  END IF;
  IF pg_catalog.to_regclass('private.lettre_candidats_parties') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.lire_lettre_candidats(text)') IS NOT NULL THEN
    RAISE EXCEPTION 'LETTRE-SERVEUR : deja installe ; rien n''est modifie';
  END IF;
END
$preflight$;

-- 1. La table du texte ------------------------------------------------------------------------------------------------------
CREATE TABLE private.lettre_candidats_parties (
  langue text NOT NULL CHECK (langue ~ '^[a-z]{2}$'),
  version text NOT NULL CHECK (version ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'),
  rang smallint NOT NULL CHECK (rang BETWEEN 1 AND 99),
  code text NOT NULL CHECK (code ~ '^p[1-9][0-9]?$'),
  titre text NOT NULL CHECK (pg_catalog.length(titre) BETWEEN 1 AND 300),
  corps text NOT NULL CHECK (pg_catalog.length(corps) >= 1),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT lettre_candidats_parties_pkey PRIMARY KEY (langue, version, rang),
  CONSTRAINT lettre_candidats_parties_code_unique UNIQUE (langue, version, code)
);
COMMENT ON TABLE private.lettre_candidats_parties IS
  'LETTRE-SERVEUR (20/11/2026) : la lettre aux candidats enseignants, une ligne par partie. Lue seulement par '
  'public.lire_lettre_candidats(text). RLS activee sans politique, aucun droit pour les roles clients. Source : '
  'docs/current/CANDIDATURES/LETTRE-CANDIDATS/LETTRE-{fr,en,ar}.md.';
ALTER TABLE private.lettre_candidats_parties ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.lettre_candidats_parties FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 2. Le texte (engendre depuis les trois fichiers ; ne pas retoucher a la main) ----------------------------------------------
-- fr : 14 parties, version 2026-11-20.
INSERT INTO private.lettre_candidats_parties (langue, version, rang, code, titre, corps) VALUES
('fr', '2026-11-20', 1, 'p1',
 $lettre_texte$Pourquoi vous recevez ce guide$lettre_texte$,
 $lettre_texte$Assalamu alaykum wa rahmatullahi wa barakatuh.

Le Prophète ﷺ a dit : « خيركم من تعلّم القرآن وعلّمه », « le meilleur d'entre vous est celui qui apprend le Coran et l'enseigne » (rapporté par al-Bukhârî). Les gens du Coran ont un rang à part. Celui qui l'enseigne porte la parole d'Allah jusqu'au cœur d'un enfant.

Ce travail est payé, et c'est normal. Mais sa vraie récompense est auprès d'Allah. Gardez cette intention en lisant tout ce qui suit.

Vous lisez ce guide parce que vous vous êtes inscrit, de vous-même, pour enseigner à Rewayah Academy, et que vous avez accepté nos conditions.

Vous êtes venu sans connaître notre nom, ni la paie, ni les personnes derrière l'académie. Nous n'avions rien dit, et c'était voulu. Vous êtes venu quand même. Cela nous a touchés.

En lisant vos messages, nous avons compris une chose. Certains d'entre vous pensent que ce sont eux qui ont besoin de nous. C'est le contraire. C'est l'académie qui a besoin de vous. Ce sont ces enfants, loin des écoles coraniques, qui ont besoin de vous. Ce sont leurs familles, et toute la communauté musulmane. Vous avoir avec nous est un honneur, pour nous.

Alors nous vous devons la vérité, toute la vérité : qui nous sommes, combien vous gagnerez, combien d'heures vous donnerez, ce que nous attendons de vous, et ce qui est dur dans ce travail.

Lisez jusqu'au bout. À la fin, vous saurez si vous continuez avec nous ou non. Les deux réponses sont respectables.$lettre_texte$),
('fr', '2026-11-20', 2, 'p2',
 $lettre_texte$Qui nous sommes$lettre_texte$,
 $lettre_texte$Nous nous appelons **Rewayah Academy**.

C'est une société officielle : **Rewayah Academy Ltd**, enregistrée en Angleterre et au pays de Galles sous le numéro **16624644**. Son siège est au 71-75 Shelton Street, Covent Garden, Londres WC2H 9JQ, Royaume-Uni. Tout le monde peut le vérifier dans le registre public des sociétés britanniques (Companies House).

L'académie existe depuis près de trois ans. Avant cela, chacun de nous enseignait de son côté, depuis des années.

Nos élèves sont surtout des musulmans de la diaspora. Ce sont des familles qui vivent loin des pays où l'on trouve une école coranique au coin de la rue.

Pendant ces trois ans, le même problème est revenu. Des élèves voulaient apprendre, et nous n'avions pas le bon enseignant pour eux. Il fallait refuser, ou faire attendre.

Cette fois, nous faisons l'inverse : **d'abord les enseignants, ensuite les élèves**. Nous ne promettons rien à une famille tant que nous n'avons pas des enseignants prêts.

Nous avons donc lancé un appel aux hommes et aux femmes du Coran. Plus de 2 000 personnes ont déjà répondu. Le premier jour, notre serveur est tombé sous le nombre. Et il en arrive encore chaque jour, du Golfe, d'Afrique, d'Europe, de plus de 50 nationalités. Vous êtes l'un d'eux.

### Comment on enseigne chez nous

Pas de Zoom, pas de Meet, pas de WhatsApp. L'académie a sa propre application, avec sa propre salle de classe en vidéo.

Chez nous, un élève entre dans **une classe**. Pensez à une classe de votre lycée ou de votre université : ses heures fixes, ses élèves, ses outils, son enseignant. Nous avons même la cloche qui sonne la fin du cours.

Les hommes enseignent aux garçons et aux hommes. Les femmes enseignent aux filles et aux femmes. Une seule exception : pour sauver une séance, un remplaçant de l'autre genre peut donner le cours ce jour-là (voir la partie 6).$lettre_texte$),
('fr', '2026-11-20', 3, 'p3',
 $lettre_texte$Ce que vous enseignerez$lettre_texte$,
 $lettre_texte$Cette application sert à une seule chose : **le Coran**.

Un élève qui débute commence par **les bases**, en quatre étapes :
1. Les lettres.
2. Lire avec les voyelles.
3. Lire dans le Coran.
4. Al-Fatiha et les sourates courtes, d'An-Nâs jusqu'à Az-Zalzalah.


En chemin, il apprend les règles simples du tajwid. D'abord il imite, ensuite il apprend le nom de la règle. Les plus jeunes apprennent aussi les paroles de la prière et les ablutions.

À la fin des bases, il passe un examen. Ensuite il continue avec le Coran : le lire en entier, ou le mémoriser.

Vous n'avez pas à inventer le programme. L'académie fixe les étapes, les objectifs et les dates, séance par séance. La manière d'expliquer, elle, vous appartient. Dans votre classe, c'est vous qui décidez.

**La langue du cours.** Vous expliquez dans la langue de vos élèves : français, anglais, arabe, poular, portugais, et d'autres. Une classe d'élèves arabophones reçoit un enseignant arabophone. Sachez seulement que beaucoup de nos élèves ne comprennent pas encore l'arabe : si vous parlez une autre langue en plus, plus de classes s'ouvrent à vous.

**Et les autres sciences ?** Le fiqh, la aqida, la sira approfondie ne s'enseignent pas ici. L'académie a une autre plateforme pour les sciences islamiques. Pour l'instant elle fonctionne en français et en poular seulement. Nous vous la présenterons quand elle s'ouvrira au monde.$lettre_texte$),
('fr', '2026-11-20', 4, 'p4',
 $lettre_texte$La paie$lettre_texte$,
 $lettre_texte$Une seule règle : **vous êtes payé par élève**. Plus vous avez d'élèves, plus vous gagnez. Pas d'élève, pas de paie.

Sur ce que paie chaque élève, presque la moitié vous revient :
- **47 %** pour une classe d'adultes ;
- **environ 45 %** pour une classe d'enfants.

|  | Classe d'enfants (6 à 17 ans) | Classe d'adultes |
| --- | --- | --- |
| Séances | 3 par semaine, 1 h chacune | 3 par semaine, 1 h 30 chacune |
| Pause dans la séance | 5 minutes | 10 minutes |
| Vos heures | 3 h par semaine, environ 13 h par mois | 4 h 30 par semaine, environ 19 h 30 par mois |
| Élèves dans la classe | 3 à 5, jamais plus de 5 | 3 à 6, jamais plus de 6 |
| Prix payé par l'élève, par mois | 55 $ | 65 $ |
| Votre part, par élève et par mois | environ 24 $ | environ 30 $ |
| Petite classe (3 élèves) | environ 72 $ par mois | environ 90 $ par mois |
| Classe pleine | 5 x 24 $ = environ 120 $ par mois | 6 x 30 $ = environ 180 $ par mois |


Les montants sont en dollars américains. Ils valent quand les élèves viennent à toutes les séances.

L'académie accorde parfois une remise à une famille : plusieurs enfants inscrits, un nouveau converti, et d'autres cas. **Ces remises ne touchent jamais votre part.** C'est l'académie qui les prend sur elle.

### Le minimum et le maximum

Pour **une** classe, comptez entre **70 $ et 180 $ par mois**. À l'heure, cela fait environ 9 $ pour une classe pleine, et environ 5 $ pour une classe de 3 élèves.

Vous pouvez avoir plusieurs classes, si vos horaires le permettent et s'il y a des classes pour vous. Un exemple : deux classes d'enfants pleines et une classe d'adultes pleine, cela fait 120 + 120 + 180 = 420 $ par mois, pour 10 h 30 de cours par semaine.

Cet exemple n'est pas une promesse. Vous pouvez aussi rester des mois sans classe, donc sans paie (voir la partie 7).

### Pourquoi 47 % pour les adultes et 45 % pour les enfants ?

Avec un adulte, presque tout se passe pendant votre cours. Avec un enfant, l'académie ajoute un suivi après le cours, pour que ses parents sachent où il en est et l'aident à la maison. Ce suivi a un coût.

### Pourquoi pas plus ?

Parce que l'académie coûte cher à faire tourner. Avec l'autre moitié, elle paie les serveurs de la salle vidéo, l'application et ceux qui la construisent, les frais de carte bancaire, l'envoi de votre paie, la comptabilité, l'administration, le suivi des enfants, et les impôts que toute société doit payer.

Vous verrez cette répartition, en pourcentages, dans votre espace enseignant. Nous n'avons rien à cacher.$lettre_texte$),
('fr', '2026-11-20', 5, 'p5',
 $lettre_texte$Comment et quand vous êtes payé$lettre_texte$,
 $lettre_texte$Après chaque séance, l'application calcule ce que vous avez gagné. Vous le voyez dans votre espace.

Le total du mois vous est envoyé **au plus tard le 5 du mois suivant**, par virement international (Wise) ou par un autre moyen selon votre pays. Les frais d'envoi sont pour l'académie. Dans quelques pays, les banques bloquent ces virements : si c'est votre cas, nous vous le dirons et nous chercherons avec vous un moyen autorisé.

Si vous recevez une classe au milieu d'un mois, vous êtes payé pour les séances qui restent dans ce mois, pas pour le mois entier.

### Ce qui fait monter ou baisser votre paie

Deux enseignants ne gagnent pas la même chose. Voici pourquoi.
- **Le nombre d'élèves.** Une classe de 3 rapporte moins qu'une classe de 5.
- **Le nombre de classes** que vous avez.
- **Les absences des élèves.** Si un élève manque une séance, vous recevez la moitié de sa part pour cette séance, pas la part entière. Nous l'avons voulu ainsi pour que chacun ait envie de garder ses élèves présents.
- **Les départs.** Si vos élèves quittent la classe un par un, votre paie baisse avec eux. Un élève reste là où il progresse et où il se sent respecté. Tous les départs ne seront pas votre faute. Mais c'est un risque réel, pensez-y avant de vous engager.
- **Les vacances des élèves.** Une famille peut mettre un élève en pause pour un mois. Pendant ce mois, vous n'êtes pas payé pour lui.
- **Les fermetures de l'académie.** Pas de cours à la fin du Ramadan et pendant l'Aïd al-Fitr (environ 20 jours), ni autour de l'Aïd al-Adha (10 jours). Pas de cours, pas de paie.
- **Vos propres absences.** Une séance donnée par un remplaçant est payée au remplaçant.
- **Le point de fin de séance.** À la fin du cours, vous indiquez en quelques touches ce que la classe a vu et où elle s'est arrêtée. Cela prend moins de 20 secondes. Tant que ce point manque, la paie du mois attend.$lettre_texte$),
('fr', '2026-11-20', 6, 'p6',
 $lettre_texte$Être à l'heure, être remplacé, s'absenter$lettre_texte$,
 $lettre_texte$L'académie ne tolère pas le manque d'assiduité. Voici pourquoi.

Nous sommes fermes avec les familles. Un élève qui manque un cours paie quand même son mois, et il rattrape seul. Alors nous devons tenir notre part : **à l'heure du cours, il y a un enseignant dans la salle. Toujours.**

### Si vous êtes en retard

Voici ce que fait l'application, minute par minute.
1. **20 minutes avant le cours**, la salle s'ouvre. Vous pouvez entrer et vous préparer.
2. **À l'heure du cours**, si vous n'êtes pas entré, vous recevez un rappel.
3. **3 minutes après**, un avertissement : si vous n'entrez pas, la séance sera donnée à un autre.
4. **8 minutes après**, c'est trop tard pour cette séance. Une alerte part chez tous les enseignants connectés.
5. Un remplaçant accepte et entre dans la salle, en général en moins d'une minute. Le but : que les élèves aient leur enseignant **11 minutes après l'heure, au plus tard**.


Si plusieurs enseignants acceptent en même temps, l'application choisit d'abord quelqu'un du même genre que la classe (un homme pour des hommes, une femme pour des femmes), puis quelqu'un qui parle sa langue. Sinon, c'est le premier disponible. Un homme peut donc remplacer dans une classe de femmes, et l'inverse, pour cette séance seulement.

**La paie de cette séance va au remplaçant, à 100 %.** Vous ne recevez rien pour elle.

### Ce que vous gardez, ce que vous risquez

Être remplacé une fois ne vous enlève pas votre classe. Elle reste la vôtre. Le remplaçant ne peut plus y entrer une fois sa séance finie.

Mais si cela se répète, vous recevez des avertissements. Et si cela continue, la classe passe à quelqu'un d'autre.

### Si vous devez vous absenter

Un voyage, un événement de famille, une maladie, qu'Allah nous en préserve : cela arrive à tout le monde. Prévenez la direction **avant**, avec votre date de départ et votre date de retour.

Un remplaçant tient votre classe pendant ce temps, et il est payé pour ses séances. À votre retour, vous reprenez votre classe.

Si vous ne revenez pas à la date annoncée, vous perdez cette classe. Vous ne perdez pas votre place à l'académie : vous restez, vous vous déclarez disponible, et une autre classe peut vous être confiée plus tard.

### Si c'est vous le remplaçant

Chaque séance de remplacement vous est payée. Ces gains s'additionnent dans votre espace. Ils vous sont envoyés quand ils atteignent un montant minimum fixé par la direction, pour éviter des virements de quelques dollars.$lettre_texte$),
('fr', '2026-11-20', 7, 'p7',
 $lettre_texte$Après l'entretien : ce qui se passe vraiment$lettre_texte$,
 $lettre_texte$Beaucoup d'entre vous pensent : « Je passe l'entretien, et le lendemain j'ai une classe. » **Non.** Voici les étapes.
1. **Votre dossier est accepté et l'entretien se passe bien.** Vous recevez l'accès à l'espace enseignant et un matricule officiel. À partir de là, une classe peut vous être confiée.
2. **Vous êtes formé à l'application.** L'académie vous montre comment marche la salle de classe.
3. **Vous attendez une classe.** Quelques jours, ou plusieurs mois.
4. **Une classe vous est confiée.** Vous recevez un message, et la classe apparaît sur votre accueil.


### Pourquoi faut-il attendre ?

On ne donne pas une classe au hasard. Il faut que tout colle entre vous et les élèves qui s'inscrivent :
- **le jour et l'heure** : les élèves choisissent un horaire, et vous devez être libre à ce moment ;
- **la langue** : vous devez parler celle des élèves ;
- **le genre** : un homme pour les garçons et les hommes, une femme pour les filles et les femmes ;
- **l'expérience** : des enfants qui débutent, des adultes, la mémorisation, ce n'est pas le même métier.


Un exemple. Douze élèves s'inscrivent cette semaine : huit petites filles qui parlent français, le soir en Europe, et quatre hommes qui parlent anglais, le matin. Il faut donc des enseignantes francophones libres le soir, et un enseignant anglophone libre le matin. Un très bon enseignant qui ne correspond à aucun de ces deux cas attendra les inscriptions suivantes.

Des classes s'ouvrent tout au long de l'année, pas seulement en début de mois.

**Notre conseil : ne quittez rien pour nous.** Gardez votre travail, continuez vos études, surveillez vos e-mails et l'application. Et faites des dou'as.

### Et s'il n'y a pas assez d'élèves pour 2 000 enseignants ?

C'est possible. Au début, c'est même probable. Nous ne pouvons pas donner une classe à chacun tout de suite.

Si vous êtes admis et sans classe, vous restez avec nous. Vous pouvez :
- **être remplaçant** : donner le cours d'un enseignant malade, absent ou en retard, et être payé pour chaque séance ;
- **attendre** qu'une classe s'ouvre ou se libère.


### Et les cours individuels ?

Beaucoup nous demandent des cours seul à seul : un enseignant pour un élève. L'académie étudie la possibilité d'en proposer, en plus des classes. Nous ne donnons aucune date.

Nous avons déjà pratiqué ce modèle. Il a montré ses limites, et il est bien plus dur qu'on ne le croit, pour l'enseignant comme pour l'élève. Nous ne l'ouvrirons que le jour où nous saurons bien le faire.$lettre_texte$),
('fr', '2026-11-20', 8, 'p8',
 $lettre_texte$Pourquoi nous demandons votre pièce d'identité et votre photo$lettre_texte$,
 $lettre_texte$Plusieurs d'entre vous ont posé la question. Elle est normale. Voici la réponse, sans détour.

Sur internet, il y a de tout. Et nous, nous avons des élèves dès l'âge de 6 ans.

Pensez à ce que voit un enseignant. Il voit le visage de l'enfant en vidéo. Il entend sa voix. Il connaît son prénom, son âge, ses horaires. Il lui parle trois fois par semaine, et l'enfant lui fait confiance.

Maintenant, imaginez que cette place soit donnée à n'importe qui. Voici ce qui peut arriver :
- **Quelqu'un qui ment sur son identité.** Un faux nom, un faux diplôme, et personne à retrouver le jour où il y a un problème.
- **Quelqu'un qui cherche les enfants, pas le Coran.** Ces personnes existent. Elles gagnent la confiance d'un enfant petit à petit, puis essaient de lui parler en privé, loin de ses parents.
- **Quelqu'un qui filme ou photographie.** L'image et la voix d'un enfant peuvent être copiées, gardées, diffusées.
- **Quelqu'un qui a été renvoyé ailleurs** pour un comportement grave, et qui revient sous un autre nom.
- **Quelqu'un qui passe l'entretien, puis fait enseigner un autre** à sa place.
- **Quelqu'un qui veut glisser d'autres idées** dans la tête des enfants, sous le nom du Coran.


Un seul de ces cas, et c'est un enfant blessé, une famille brisée, et la confiance dans toute l'académie qui tombe. Les honnêtes enseignants, c'est-à-dire vous, en paieraient le prix aussi.

Il y a aussi la loi. Nos élèves vivent dans beaucoup de pays. Les lois de protection de l'enfance nous demandent de savoir exactement à qui nous confions un enfant. Et pour vous envoyer votre paie, la banque exige votre vrai nom.

**Ce que nous faisons de vos documents.** Ils ne sont vus que par la direction. Ils ne sont jamais montrés aux élèves ni aux familles. Si vous retirez votre candidature, vous pouvez demander leur suppression.

**Ce que nous vous demandons en retour.** Ne demandez jamais à un élève son numéro ou un autre moyen de le joindre. Ne le contactez jamais en dehors de l'application. Ne filmez pas, ne photographiez pas la classe. C'est une règle sans exception.

Un parent nous confie ce qu'il a de plus cher. Montrer qui vous êtes, c'est le premier geste de confiance. Si vous étiez ce parent, vous l'exigeriez aussi.$lettre_texte$),
('fr', '2026-11-20', 9, 'p9',
 $lettre_texte$Ce que nous demandons, et ce qui est dur$lettre_texte$,
 $lettre_texte$### Qui nous avons refusé jusqu'ici

L'académie est sunnite, ouvertement, sur la voie d'Ahl as-Sunna. Elle défend ses valeurs. Celui qui s'y oppose n'a pas sa place parmi nous.

Jusqu'ici, nous n'avons refusé que deux sortes de candidatures :
- ceux qui n'ont pas signé **l'engagement religieux**. Ce texte demande de respecter le Coran, la Sunna, tous les Compagnons du Prophète ﷺ, d'abord les quatre califes bien guidés, et les pieux prédécesseurs ;
- ceux dont l'apparence allait clairement contre les règles de la religion : une coiffure interdite en islam, une tenue qui ne les respecte pas.


Pourquoi ? Parce qu'un enfant apprend d'abord en regardant son enseignant. Les enfants de la diaspora grandissent au milieu de toutes les idées de ce siècle. Ils sont l'espoir de demain, et ils sont fragiles. Bien choisir leur enseignant, c'est notre premier devoir.

### La difficulté que vous rencontrerez

Nous connaissons la diaspora depuis des années. Nous devons vous prévenir d'une chose.

Beaucoup de familles voient le cours comme un achat. Elles se sentent clientes, et pour elles l'enseignant est un vendeur. Et un client pense qu'il a toujours raison. Vous le sentirez dans leur façon de parler, d'écrire, de réclamer.

Nous savons que c'est une erreur. L'enseignant du Coran a un rang (له حرمته). Mais eux ne le savent pas encore. Personne ne le leur a appris.

C'est à vous de le leur apprendre, avec sagesse et bonne parole (بالحكمة والموعظة الحسنة), et avec patience. Ici, vous n'êtes pas seulement un enseignant. Vous êtes d'abord un prédicateur (داعية).

Un exemple. Un père vous écrit sèchement : « Je paie, donc mon fils doit avancer plus vite. » Vous pouvez vous vexer et lui répondre sur le même ton. Ou vous pouvez lui montrer calmement où en est son fils, ce qu'il doit réviser à la maison, et l'inviter à l'écouter réciter. Dans le premier cas, vous perdez un élève. Dans le second, vous gagnez souvent toute une famille.

Nous l'avons vu bien des fois : quand l'enseignant est plus sage et plus patient que l'élève, les choses finissent par s'arranger. Si cette patience vous pèse déjà, ce travail n'est pas pour vous. Mieux vaut le savoir aujourd'hui.$lettre_texte$),
('fr', '2026-11-20', 10, 'p10',
 $lettre_texte$L'académie voit ce qui se passe en classe$lettre_texte$,
 $lettre_texte$Nous préférons vous le dire avant, pas après.

**L'application note vos entrées et vos sorties**, et celles des élèves. Vous n'avez donc aucun cahier de présence à tenir : elle le fait pour vous.

**Elle mesure votre connexion pendant le cours** : bonne, faible ou perdue. Elle ne garde ni le son ni l'image. Le jour où une famille se plaint d'un cours, l'académie sait d'où venait le problème, et vous n'êtes pas accusé à tort.

**Une visite de contrôle peut avoir lieu, sans prévenir.** Un membre de la direction entre dans la salle. Vous ne le voyez pas, et il n'a ni micro ni caméra. Quand une enseignante donne son cours, la visite est toujours faite par une femme de l'équipe, jamais par un homme. Le visiteur regarde une chose : est-ce que l'enseignant travaille vraiment avec ses élèves ?

**Vous ne pouvez pas donner deux cours en même temps.** Le visiteur le voit. Et si vous quittez la salle plus de 30 secondes pendant votre cours, l'application vous en sort et prévient la direction.

Pour le reste, vous êtes libre. L'académie ne vous impose ni un endroit précis de la maison, ni une position, ni un décor. Elle demande deux choses : un endroit calme et une bonne connexion. Sans cela, ce sont les élèves qui en souffrent.$lettre_texte$),
('fr', '2026-11-20', 11, 'p11',
 $lettre_texte$Praxis, notre assistant$lettre_texte$,
 $lettre_texte$Vous êtes plus de 2 000. Vous parlez des dizaines de langues, vous vivez sous tous les fuseaux horaires, et vos messages arrivent jour et nuit. Notre équipe ne peut pas répondre à chacun assez vite.

Nous avons donc créé **Praxis**, un assistant d'intelligence artificielle. Ce n'est pas une personne, et il ne se fera jamais passer pour une personne.
- **Ce qu'il fait** : il répond aux questions qui reviennent, il donne des précisions, il vous dit où en est une démarche.
- **Ce qu'il ne fait pas** : il ne décide rien. Il n'accepte ni ne refuse personne, il ne donne pas de classe, il ne touche pas à la paie.
- **Qui le dirige** : la direction. Il n'agit que si elle lui confie une mission.


Où en est-il aujourd'hui ? Nous avons commencé à le tester. Il a fait quelques erreurs, alors nous l'avons mis en pause. Nous étudions ses réponses pour le régler, puis nous le relancerons. Certains d'entre vous ont peut-être déjà reçu un message de lui.

Quand il sera de retour, si sa réponse ne vous suffit pas, dites-le dans votre message : un membre de l'équipe prendra la suite.$lettre_texte$),
('fr', '2026-11-20', 12, 'p12',
 $lettre_texte$Si cela ne vous convient pas$lettre_texte$,
 $lettre_texte$Vous êtes libre de partir, à tout moment, sans vous justifier.

Rewayah Academy est une société anglaise. La loi l'oblige à respecter votre droit de vous retirer. Vous pouvez retirer votre candidature et demander la suppression de votre compte et de vos données. Après cela, vous ne recevrez plus aucun message de l'académie. Si vous changez d'avis, vous pouvez reprendre votre candidature vous-même pendant 7 jours après l'avoir retirée.

Pour cela, écrivez à **support@rewayahacademy.com**.$lettre_texte$),
('fr', '2026-11-20', 13, 'p13',
 $lettre_texte$Vos questions$lettre_texte$,
 $lettre_texte$**Je me suis inscrit. Suis-je déjà enseignant de l'académie ?** Pas encore. Vous êtes candidat. Il reste l'étude de votre dossier, puis l'entretien.

**Dois-je payer pour être admis ou pour la formation ?** Non. Rien, jamais. Si quelqu'un vous demande de l'argent en notre nom, c'est une fraude : prévenez-nous.

**Combien de temps vais-je attendre une classe ?** Nous ne le savons pas, et nous ne vous donnerons pas une date que nous ne pourrions pas tenir. Cela dépend des élèves qui s'inscrivent, de vos horaires, de votre langue et de votre expérience.

**À quelle heure seront mes cours ?** À l'heure choisie par les élèves de la classe, la même chaque semaine. On ne vous confiera une classe que si son horaire vous va. L'application affiche chaque horaire à votre heure, puis à l'heure de La Mecque, qui est l'horloge de l'académie.

**Combien vais-je gagner, exactement ?** Environ 24 $ par mois pour chaque enfant, environ 30 $ par mois pour chaque adulte, s'ils viennent à toutes les séances. Comptez vos élèves, multipliez, vous avez votre mois.

**Un élève est absent. Suis-je payé pour lui ?** À moitié. Vous recevez la moitié de sa part pour cette séance.

**J'ai été en retard une fois et on m'a remplacé. Ai-je perdu ma classe ?** Non. Vous avez perdu la paie de cette séance. Vous ne perdez la classe que si cela se répète, après des avertissements.

**De quoi ai-je besoin pour enseigner ?** Une bonne connexion internet, un ordinateur ou une tablette avec caméra et micro, et un endroit calme. Rien d'autre à installer que l'application de l'académie.

**Puis-je enseigner ailleurs en même temps ?** Oui, tant que vos autres heures ne tombent pas sur celles de l'académie. Ce qui est interdit, c'est de donner deux cours au même moment.

**Les montants peuvent-ils changer ?** Oui, la direction peut les revoir. Vous serez prévenu avant, et un mois déjà travaillé ne sera jamais touché.$lettre_texte$),
('fr', '2026-11-20', 14, 'p14',
 $lettre_texte$Pour décider$lettre_texte$,
 $lettre_texte$**Continuez avec nous si** vous acceptez d'être payé par élève, d'attendre peut-être longtemps votre première classe, d'être à l'heure à chaque séance, de montrer qui vous êtes, et d'être patient avec des familles qui ne connaissent pas encore le rang de l'enseignant du Coran.

**Ne continuez pas si** vous cherchez un revenu fixe et tout de suite, si vous ne pouvez pas tenir un horaire régulier, ou si l'engagement religieux de l'académie n'est pas le vôtre.

Dans les deux cas, qu'Allah vous récompense d'avoir répondu à notre appel.

La direction de Rewayah Academy

#Ra_staff$lettre_texte$);

-- en : 14 parties, version 2026-11-20.
INSERT INTO private.lettre_candidats_parties (langue, version, rang, code, titre, corps) VALUES
('en', '2026-11-20', 1, 'p1',
 $lettre_texte$Why you are receiving this guide$lettre_texte$,
 $lettre_texte$Assalamu alaykum wa rahmatullahi wa barakatuh.

The Prophet ﷺ said: « خيركم من تعلّم القرآن وعلّمه », "the best of you are those who learn the Qur'an and teach it" (reported by al-Bukhari). The people of the Qur'an have a special rank. The one who teaches it carries the word of Allah to the heart of a child.

This work is paid, and that is normal. But its true reward is with Allah. Keep this intention as you read everything below.

You are reading this guide because you signed up, by your own choice, to teach at Rewayah Academy, and you accepted our conditions.

You came without knowing our name, the pay, or the people behind the academy. We did not tell you anything, and we did this on purpose. You came anyway. This touched us.

When we read your messages, we understood one thing. Some of you think that you need us. It is the opposite. The academy needs you. These children, far from places where the Qur'an is taught, need you. Their families need you, and so does the whole Muslim community. Having you with us is an honour for us.

So we owe you the truth, the whole truth: who we are, how much you will earn, how many hours you will give, what we expect from you, and what is hard in this work.

Read to the end. At the end, you will know if you continue with us or not. Both answers deserve respect.$lettre_texte$),
('en', '2026-11-20', 2, 'p2',
 $lettre_texte$Who we are$lettre_texte$,
 $lettre_texte$Our name is **Rewayah Academy**.

It is an official company: **Rewayah Academy Ltd**, registered in England and Wales under number **16624644**. Its registered office is at 71-75 Shelton Street, Covent Garden, London WC2H 9JQ, United Kingdom. Anyone can check this in the public register of British companies (Companies House).

The academy has existed for almost three years. Before that, each of us taught on our own, for many years.

Most of our students are Muslims of the diaspora. They are families who live far from the countries where you can learn the Qur'an in every street.

During these three years, the same problem came back again and again. Students wanted to learn, and we did not have the right teacher for them. We had to say no, or ask them to wait.

This time, we do the opposite: **teachers first, students second**. We promise nothing to a family until we have teachers who are ready.

So we made a call to the men and women of the Qur'an. More than 2,000 people have already answered. On the first day, our server stopped working because there were so many. And more people still arrive every day, from the Gulf, from Africa, from Europe, from more than 50 nationalities. You are one of them.

### How we teach

No Zoom, no Meet, no WhatsApp. The academy has its own application, with its own video classroom.

With us, a student joins **a class**. Think of a class in your college or your university: fixed hours, its students, its tools, its teacher. We even have the bell that rings at the end of the lesson.

Men teach boys and men. Women teach girls and women. There is only one exception: to save a session, a substitute teacher of the other gender can give the lesson that day (see part 6).$lettre_texte$),
('en', '2026-11-20', 3, 'p3',
 $lettre_texte$What you will teach$lettre_texte$,
 $lettre_texte$This application has only one purpose: **the Qur'an**.

A beginner student starts with **the basics**, in four steps:
1. The letters.
2. Reading with the vowels.
3. Reading in the Qur'an.
4. Al-Fatiha and the short surahs, from An-Nas to Az-Zalzalah.


On the way, the student learns the simple rules of tajwid. First the student copies, then learns the name of the rule. The youngest students also learn the words of the prayer and the ablutions.

At the end of the basics, the student takes an exam. After that, the student continues with the Qur'an: reading all of it, or memorising it.

You do not have to create the programme. The academy sets the steps, the goals and the dates, session by session. But the way you explain belongs to you. In your class, you decide.

**The language of the lesson.** You explain in the language of your students: French, English, Arabic, Pulaar, Portuguese, and others. A class of Arabic-speaking students gets an Arabic-speaking teacher. But know this: many of our students do not understand Arabic yet. If you also speak another language, more classes are open to you.

**What about the other sciences?** Fiqh, aqida and detailed sira are not taught here. The academy has another platform for the Islamic sciences. For now it works in French and Pulaar only. We will present it to you when it opens to the world.$lettre_texte$),
('en', '2026-11-20', 4, 'p4',
 $lettre_texte$The pay$lettre_texte$,
 $lettre_texte$There is only one rule: **you are paid per student**. The more students you have, the more you earn. No student, no pay.

Out of what each student pays, almost half goes to you:
- **47 %** for a class of adults;
- **about 45 %** for a class of children.

|  | Class of children (6 to 17 years old) | Class of adults |
| --- | --- | --- |
| Sessions | 3 per week, 1 h each | 3 per week, 1 h 30 each |
| Break during the session | 5 minutes | 10 minutes |
| Your hours | 3 h per week, about 13 h per month | 4 h 30 per week, about 19 h 30 per month |
| Students in the class | 3 to 5, never more than 5 | 3 to 6, never more than 6 |
| Price paid by the student, per month | $55 | $65 |
| Your share, per student and per month | about $24 | about $30 |
| Small class (3 students) | about $72 per month | about $90 per month |
| Full class | 5 x $24 = about $120 per month | 6 x $30 = about $180 per month |


The amounts are in US dollars. They are correct when the students come to every session.

Sometimes the academy gives a discount to a family: several children enrolled, a new Muslim, and other cases. **These discounts never touch your share.** The academy pays for them itself.

### The minimum and the maximum

For **one** class, expect between **$70 and $180 per month**. Per hour, this is about $9 for a full class, and about $5 for a class of 3 students.

You can have several classes, if your hours allow it and if there are classes for you. An example: two full classes of children and one full class of adults make 120 + 120 + 180 = $420 per month, for 10 h 30 of lessons per week.

This example is not a promise. You can also stay for months without a class, so without pay (see part 7).

### Why 47 % for adults and 45 % for children?

With an adult, almost everything happens during your lesson. With a child, the academy adds a follow-up after the lesson, so that the parents know the child's progress and can help at home. This follow-up has a cost.

### Why not more?

Because the academy costs a lot to run. With the other half, it pays for the servers of the video classroom, the application and the people who build it, card payment fees, the sending of your pay, accounting, administration, the follow-up of the children, and the taxes that every company must pay.

You will see this split, in percentages, in your teacher space. We have nothing to hide.$lettre_texte$),
('en', '2026-11-20', 5, 'p5',
 $lettre_texte$How and when you are paid$lettre_texte$,
 $lettre_texte$After each session, the application calculates what you earned. You see it in your space.

The total for the month is sent to you **no later than the 5th of the next month**, by international transfer (Wise) or by another method, depending on your country. The academy pays the transfer fees. In a few countries, banks block these transfers. If this is your case, we will tell you, and we will look with you for a method that is allowed.

If you receive a class in the middle of a month, you are paid for the sessions left in that month, not for the whole month.

### What makes your pay go up or down

Two teachers do not earn the same amount. Here is why.
- **The number of students.** A class of 3 earns less than a class of 5.
- **The number of classes** you have.
- **Student absences.** If a student misses a session, you receive half of that student's share for that session, not the full share. We chose this so that everyone wants to keep their students present.
- **Students leaving.** If your students leave the class one by one, your pay goes down with them. A student stays where he makes progress and where he feels respected. Not every departure will be your fault. But it is a real risk. Think about it before you commit.
- **Student holidays.** A family can pause a student for one month. During that month, you are not paid for that student.
- **Academy closures.** There are no lessons at the end of Ramadan and during Eid al-Fitr (about 20 days), and none around Eid al-Adha (10 days). No lessons, no pay.
- **Your own absences.** A session given by a substitute teacher is paid to the substitute teacher.
- **The end-of-session report.** At the end of the lesson, you note in a few taps what the class covered and where it stopped. This takes less than 20 seconds. Until this report is done, the pay for the month waits.$lettre_texte$),
('en', '2026-11-20', 6, 'p6',
 $lettre_texte$Being on time, being replaced, being absent$lettre_texte$,
 $lettre_texte$The academy does not accept a lack of regular attendance. Here is why.

We are firm with families. A student who misses a lesson still pays for the month, and catches up alone. So we must do our part: **at the time of the lesson, there is a teacher in the classroom. Always.**

### If you are late

Here is what the application does, minute by minute.
1. **20 minutes before the lesson**, the classroom opens. You can enter and get ready.
2. **At the time of the lesson**, if you have not entered, you receive a reminder.
3. **3 minutes after**, a warning: if you do not enter, the session will be given to someone else.
4. **8 minutes after**, it is too late for this session. An alert goes to all the teachers who are connected.
5. A substitute teacher accepts and enters the classroom, usually in less than one minute. The goal: the students have their teacher **11 minutes after the start time, at the latest**.


If several teachers accept at the same time, the application first chooses someone of the same gender as the class (a man for men, a woman for women), then someone who speaks its language. If not, it is the first one available. So a man can replace a teacher in a class of women, and the opposite, for that session only.

**The pay for that session goes to the substitute teacher, 100 %.** You receive nothing for it.

### What you keep, what you risk

Being replaced once does not take your class away from you. It stays yours. The substitute teacher can no longer enter it once the session is over.

But if it happens again and again, you receive warnings. And if it continues, the class goes to someone else.

### If you must be absent

A trip, a family event, an illness, may Allah protect us from it: this happens to everyone. Tell the management **before**, with the date you leave and the date you come back.

A substitute teacher takes your class during that time, and is paid for those sessions. When you come back, you take your class again.

If you do not come back on the date you gave, you lose this class. You do not lose your place at the academy: you stay, you say you are available, and another class can be given to you later.

### If you are the substitute teacher

Each session you give as a substitute teacher is paid. These earnings add up in your space. They are sent to you when they reach a minimum amount set by the management, to avoid transfers of only a few dollars.$lettre_texte$),
('en', '2026-11-20', 7, 'p7',
 $lettre_texte$After the interview: what really happens$lettre_texte$,
 $lettre_texte$Many of you think: "I pass the interview, and the next day I have a class." **No.** Here are the steps.
1. **Your application is accepted and the interview goes well.** You receive access to the teacher space and an official ID number. From this point, a class can be given to you.
2. **You are trained to use the application.** The academy shows you how the classroom works.
3. **You wait for a class.** A few days, or several months.
4. **A class is given to you.** You receive a message, and the class appears on your home screen.


### Why must you wait?

We do not give a class at random. Everything must match between you and the students who sign up:
- **the day and the time**: the students choose a time, and you must be free at that time;
- **the language**: you must speak the language of the students;
- **the gender**: a man for boys and men, a woman for girls and women;
- **the experience**: beginner children, adults, memorisation: these are not the same job.


An example. Twelve students sign up this week: eight little girls who speak French, in the evening in Europe, and four men who speak English, in the morning. So we need French-speaking women teachers who are free in the evening, and an English-speaking man teacher who is free in the morning. A very good teacher who does not match either of these two cases will wait for the next sign-ups.

Classes open all through the year, not only at the start of the month.

**Our advice: do not leave anything for us.** Keep your job, continue your studies, check your e-mails and the application. And make du'a.

### What if there are not enough students for 2,000 teachers?

It is possible. At the start, it is even likely. We cannot give a class to everyone right away.

If you are accepted and you have no class, you stay with us. You can:
- **be a substitute teacher**: give the lesson of a teacher who is ill, absent or late, and be paid for each session;
- **wait** for a class to open or become free.


### What about one-to-one lessons?

Many people ask us for one-to-one lessons: one teacher for one student. The academy is studying the possibility of offering them, in addition to the classes. We give no date.

We have already used this model. It showed its limits, and it is much harder than people think, for the teacher and for the student. We will only open it on the day we know how to do it well.$lettre_texte$),
('en', '2026-11-20', 8, 'p8',
 $lettre_texte$Why we ask for your ID document and your photo$lettre_texte$,
 $lettre_texte$Several of you have asked this question. It is a normal question. Here is the answer, directly.

On the internet, there are all kinds of people. And we have students from the age of 6.

Think about what a teacher sees. The teacher sees the child's face on video. The teacher hears the child's voice. The teacher knows the child's first name, age and timetable. The teacher speaks to the child three times a week, and the child trusts the teacher.

Now, imagine that this place is given to just anyone. Here is what can happen:
- **Someone who lies about who they are.** A false name, a false diploma, and no one to find on the day there is a problem.
- **Someone who is looking for children, not for the Qur'an.** These people exist. They slowly win a child's trust, then try to speak to the child in private, away from the parents.
- **Someone who films or takes photos.** The image and the voice of a child can be copied, kept and shared.
- **Someone who was dismissed elsewhere** for serious behaviour, and who comes back under another name.
- **Someone who passes the interview, then makes another person teach** in their place.
- **Someone who wants to put other ideas** into the minds of children, in the name of the Qur'an.


Only one of these cases means a hurt child, a broken family, and the loss of trust in the whole academy. Honest teachers, that is to say you, would also pay the price.

There is also the law. Our students live in many countries. Child protection laws ask us to know exactly to whom we give a child. And to send you your pay, the bank requires your real name.

**What we do with your documents.** Only the management sees them. They are never shown to students or families. If you withdraw your application, you can ask for them to be deleted.

**What we ask from you in return.** Never ask a student for a phone number or any other way to contact them. Never contact a student outside the application. Do not film the class, do not take photos of the class. This rule has no exception.

A parent gives us what is most precious to them. Showing who you are is the first act of trust. If you were this parent, you would demand it too.$lettre_texte$),
('en', '2026-11-20', 9, 'p9',
 $lettre_texte$What we ask, and what is hard$lettre_texte$,
 $lettre_texte$### Who we have refused until now

The academy is Sunni, openly, on the path of Ahl as-Sunna. It defends its values. A person who opposes them has no place among us.

Until now, we have refused only two kinds of applications:
- people who did not sign **the religious commitment**. This text asks you to respect the Qur'an, the Sunnah, all the Companions of the Prophet ﷺ, first of all the four rightly guided caliphs, and the pious predecessors;
- people whose appearance clearly went against the rules of the religion: a hairstyle forbidden in Islam, or clothing that does not respect these rules.


Why? Because a child learns first by watching the teacher. Children of the diaspora grow up surrounded by all the ideas of this century. They are the hope of tomorrow, and they are fragile. Choosing their teacher well is our first duty.

### The difficulty you will face

We have known the diaspora for many years. We must warn you about one thing.

Many families see the lesson as a purchase. They feel like customers, and for them the teacher is a seller. And a customer thinks he is always right. You will feel it in the way they speak, write and complain.

We know this is a mistake. The teacher of the Qur'an has a rank and deserves respect (له حرمته). But they do not know this yet. No one has taught them.

It is your job to teach them, with wisdom and good words (بالحكمة والموعظة الحسنة), and with patience. Here, you are not only a teacher. You are first a caller to Islam (داعية).

An example. A father writes to you harshly: "I pay, so my son must move forward faster." You can feel offended and answer him in the same tone. Or you can calmly show him where his son is, what he must revise at home, and invite him to listen to his son recite. In the first case, you lose a student. In the second, you often win a whole family.

We have seen it many times: when the teacher is wiser and more patient than the student, things work out in the end. If this patience already feels heavy to you, this work is not for you. It is better to know it today.$lettre_texte$),
('en', '2026-11-20', 10, 'p10',
 $lettre_texte$The academy sees what happens in class$lettre_texte$,
 $lettre_texte$We prefer to tell you before, not after.

**The application records when you enter and leave**, and when the students do. So you do not have to keep an attendance register: the application does it for you.

**It measures your connection during the lesson**: good, weak or lost. It keeps neither the sound nor the image. On the day a family complains about a lesson, the academy knows where the problem came from, and you are not wrongly accused.

**A check visit can take place, without warning.** A member of the management enters the classroom. You do not see this person, and this person has no microphone and no camera. When a woman teacher gives her lesson, the visit is always made by a woman from the team, never by a man. The visitor looks at one thing: is the teacher really working with the students?

**You cannot give two lessons at the same time.** The visitor sees it. And if you leave the classroom for more than 30 seconds during your lesson, the application removes you and informs the management.

For the rest, you are free. The academy does not require a specific place in your home, a position or a background. It asks for two things: a quiet place and a good connection. Without these, it is the students who suffer.$lettre_texte$),
('en', '2026-11-20', 11, 'p11',
 $lettre_texte$Praxis, our assistant$lettre_texte$,
 $lettre_texte$There are more than 2,000 of you. You speak dozens of languages, you live in every time zone, and your messages arrive day and night. Our team cannot answer each person fast enough.

So we created **Praxis**, an artificial intelligence assistant. It is not a person, and it will never pretend to be a person.
- **What it does**: it answers the questions that come back often, it gives details, it tells you the status of a request.
- **What it does not do**: it decides nothing. It does not accept or refuse anyone, it does not give classes, it does not touch the pay.
- **Who directs it**: the management. It acts only when the management gives it a task.


Where is it today? We started to test it. It made some mistakes, so we paused it. We are studying its answers to adjust it, then we will start it again. Some of you may have already received a message from it.

When it comes back, if its answer is not enough for you, say so in your message: a member of the team will take over.$lettre_texte$),
('en', '2026-11-20', 12, 'p12',
 $lettre_texte$If this does not suit you$lettre_texte$,
 $lettre_texte$You are free to leave, at any time, without giving a reason.

Rewayah Academy is an English company. The law requires it to respect your right to withdraw. You can withdraw your application and ask for your account and your data to be deleted. After that, you will not receive any more messages from the academy. If you change your mind, you can restart your application yourself within 7 days after you withdrew it.

To do this, write to **support@rewayahacademy.com**.$lettre_texte$),
('en', '2026-11-20', 13, 'p13',
 $lettre_texte$Your questions$lettre_texte$,
 $lettre_texte$**I signed up. Am I already a teacher at the academy?** Not yet. You are a candidate. We still need to study your application, then there is the interview.

**Do I have to pay to be accepted or for the training?** No. Nothing, ever. If someone asks you for money in our name, it is a fraud: tell us.

**How long will I wait for a class?** We do not know, and we will not give you a date that we might not keep. It depends on the students who sign up, your hours, your language and your experience.

**At what time will my lessons be?** At the time chosen by the students of the class, the same time every week. You will only be given a class if its time suits you. The application shows each time in your own time, then in Makkah time, which is the academy's clock.

**How much will I earn, exactly?** About $24 per month for each child, about $30 per month for each adult, if they come to every session. Count your students, multiply, and you have your month.

**A student is absent. Am I paid for this student?** Half. You receive half of this student's share for that session.

**I was late once and someone replaced me. Have I lost my class?** No. You lost the pay for that session. You only lose the class if it happens again and again, after warnings.

**What do I need to teach?** A good internet connection, a computer or a tablet with a camera and a microphone, and a quiet place. Nothing else to install except the academy's application.

**Can I teach somewhere else at the same time?** Yes, as long as your other hours do not fall on the academy's hours. What is forbidden is giving two lessons at the same moment.

**Can the amounts change?** Yes, the management can review them. You will be told before, and a month already worked will never be touched.$lettre_texte$),
('en', '2026-11-20', 14, 'p14',
 $lettre_texte$To decide$lettre_texte$,
 $lettre_texte$**Continue with us if** you accept to be paid per student, to maybe wait a long time for your first class, to be on time for every session, to show who you are, and to be patient with families who do not yet know the rank of the teacher of the Qur'an.

**Do not continue if** you are looking for a fixed income right away, if you cannot keep a regular timetable, or if the religious commitment of the academy is not yours.

In both cases, may Allah reward you for answering our call.

The management of Rewayah Academy

#Ra_staff$lettre_texte$);

-- ar : 14 parties, version 2026-11-20.
INSERT INTO private.lettre_candidats_parties (langue, version, rang, code, titre, corps) VALUES
('ar', '2026-11-20', 1, 'p1',
 $lettre_texte$لماذا يصلك هذا الدليل$lettre_texte$,
 $lettre_texte$السلام عليكم ورحمة الله وبركاته.

قال النبي ﷺ: «خيركم من تعلّم القرآن وعلّمه» (رواه البخاري). لأهل القرآن منزلة خاصة. ومن يعلّمه يحمل كلام الله إلى قلب طفل.

هذا العمل مأجور، وهذا أمر طبيعي. لكن ثوابه الحقيقي عند الله. فاستحضر هذه النية وأنت تقرأ كل ما يأتي.

أنت تقرأ هذا الدليل لأنك سجّلت، باختيارك، لتعلّم في أكاديمية الرواية، ووافقت على شروطنا.

جئت ولم تكن تعرف اسمنا، ولا الراتب، ولا الأشخاص الذين يقفون وراء الأكاديمية. لم نقل شيئًا، وكان ذلك مقصودًا. ومع ذلك جئت. وهذا أثّر فينا.

حين قرأنا رسائلكم، فهمنا أمرًا. بعضكم يظن أنه هو المحتاج إلينا. والحقيقة عكس ذلك. الأكاديمية هي التي تحتاج إليكم. وهؤلاء الأطفال البعيدون عن الكتاتيب ودور القرآن هم الذين يحتاجون إليكم. وكذلك أسرهم، والأمة الإسلامية كلها. وجودكم معنا شرف لنا.

لذلك نحن مدينون لكم بالصدق، بالحقيقة كاملة: من نحن، وكم ستكسب، وكم ساعة ستعطي، وماذا ننتظر منك، وما الصعب في هذا العمل.

اقرأ حتى النهاية. وفي آخرها ستعرف هل تكمل معنا أم لا. وكلا الجوابين محترم.$lettre_texte$),
('ar', '2026-11-20', 2, 'p2',
 $lettre_texte$من نحن$lettre_texte$,
 $lettre_texte$اسمنا **أكاديمية الرواية** (Rewayah Academy).

وهي شركة رسمية: **Rewayah Academy Ltd**، مسجّلة في إنجلترا وويلز تحت الرقم **16624644**. مقرّها في 71-75 Shelton Street, Covent Garden, London WC2H 9JQ، المملكة المتحدة. ويستطيع أي شخص أن يتحقق من ذلك في السجل العام للشركات البريطانية (Companies House).

تعمل الأكاديمية منذ قرابة ثلاث سنوات. وقبل ذلك، كان كل واحد منا يعلّم وحده، منذ سنوات.

أغلب طلابنا مسلمون في بلاد المهجر. هم أسر تعيش بعيدًا عن البلدان التي تجد فيها كُتّابًا لتعليم القرآن في كل حيّ.

وخلال هذه السنوات الثلاث، تكررت المشكلة نفسها. طلاب يريدون التعلّم، ولا يوجد عندنا المعلّم المناسب لهم. فكنا نعتذر، أو نجعلهم ينتظرون.

هذه المرة نفعل العكس: **المعلّمون أولًا، ثم الطلاب**. لا نَعِد أي أسرة بشيء ما دام المعلّمون غير جاهزين.

لذلك أطلقنا نداءً إلى رجال القرآن ونسائه. وقد استجاب أكثر من 2000 شخص حتى الآن. وفي اليوم الأول، توقّف خادمنا من كثرة العدد. وما زال الناس يصلون كل يوم، من الخليج ومن إفريقيا ومن أوروبا، من أكثر من 50 جنسية. وأنت واحد منهم.

### كيف نعلّم عندنا

لا Zoom، ولا Meet، ولا WhatsApp. للأكاديمية تطبيقها الخاص، وفيه قاعة الدرس الخاصة بها بالفيديو.

عندنا، يدخل الطالب **فصلًا**. تذكّر فصلك في الثانوية أو في الجامعة: له ساعات ثابتة، وطلابه، وأدواته، ومعلّمه. بل عندنا أيضًا الجرس الذي يرنّ عند نهاية الدرس.

الرجال يعلّمون الأولاد والرجال. والنساء يعلّمن البنات والنساء. هناك استثناء واحد فقط: لإنقاذ حصة، قد يقدّم الدرس في ذلك اليوم معلّم بديل من الجنس الآخر (انظر القسم 6).$lettre_texte$),
('ar', '2026-11-20', 3, 'p3',
 $lettre_texte$ماذا ستعلّم$lettre_texte$,
 $lettre_texte$هذا التطبيق له غرض واحد فقط: **القرآن**.

الطالب المبتدئ يبدأ بـ**الأساسيات**، في أربع مراحل:
1. الحروف.
2. القراءة بالحركات.
3. القراءة في المصحف.
4. الفاتحة والسور القصيرة، من سورة الناس إلى سورة الزلزلة.


وفي الطريق، يتعلّم أحكام التجويد البسيطة. يقلّد أولًا، ثم يتعلّم اسم الحكم. ويتعلّم الصغار أيضًا أذكار الصلاة والوضوء.

في نهاية الأساسيات، يجتاز امتحانًا. ثم يكمل مع القرآن: يقرؤه كاملًا، أو يحفظه.

لست مطالبًا بوضع المنهج. الأكاديمية تحدد المراحل والأهداف والمواعيد، حصة بعد حصة. أما طريقة الشرح فهي لك. في فصلك، أنت من يقرّر.

**لغة الدرس.** تشرح بلغة طلابك: الفرنسية، الإنجليزية، العربية، الفُلانية (البولار)، البرتغالية، وغيرها. والفصل الذي طلابه يتكلمون العربية يُعطى لمعلّم يتكلم العربية. لكن اعلم أن كثيرًا من طلابنا لا يفهمون العربية بعد: فإن كنت تتكلم لغة أخرى إلى جانبها، تُفتح أمامك فصول أكثر.

**وماذا عن العلوم الأخرى؟** الفقه والعقيدة والسيرة المفصّلة لا تُدرَّس هنا. للأكاديمية منصّة أخرى للعلوم الشرعية. وهي تعمل الآن بالفرنسية والفُلانية فقط. وسنعرّفكم بها حين تُفتح للعالم.$lettre_texte$),
('ar', '2026-11-20', 4, 'p4',
 $lettre_texte$الراتب$lettre_texte$,
 $lettre_texte$قاعدة واحدة: **تُدفع لك المستحقات حسب عدد الطلاب**. كلما زاد طلابك، زاد ما تكسبه. لا طالب، لا راتب.

مما يدفعه كل طالب، يعود إليك قرابة النصف:
- **47 %** لفصل الكبار؛
- **حوالي 45 %** لفصل الأطفال.

|  | فصل الأطفال (من 6 إلى 17 سنة) | فصل الكبار |
| --- | --- | --- |
| الحصص | 3 في الأسبوع، ساعة واحدة لكل حصة | 3 في الأسبوع، ساعة و30 دقيقة لكل حصة |
| الاستراحة داخل الحصة | 5 دقائق | 10 دقائق |
| ساعاتك | 3 ساعات في الأسبوع، أي حوالي 13 ساعة في الشهر | 4 ساعات و30 دقيقة في الأسبوع، أي حوالي 19 ساعة و30 دقيقة في الشهر |
| عدد الطلاب في الفصل | من 3 إلى 5، ولا يزيد أبدًا عن 5 | من 3 إلى 6، ولا يزيد أبدًا عن 6 |
| ما يدفعه الطالب في الشهر | 55 $ | 65 $ |
| نصيبك، عن كل طالب في الشهر | حوالي 24 $ | حوالي 30 $ |
| فصل صغير (3 طلاب) | حوالي 72 $ في الشهر | حوالي 90 $ في الشهر |
| فصل مكتمل | 5 x 24 $ = حوالي 120 $ في الشهر | 6 x 30 $ = حوالي 180 $ في الشهر |


المبالغ بالدولار الأمريكي. وهي صحيحة حين يحضر الطلاب كل الحصص.

تمنح الأكاديمية أحيانًا تخفيضًا لبعض الأسر: عدة أطفال مسجّلين، أو مسلم جديد، وحالات أخرى. **هذه التخفيضات لا تمسّ نصيبك أبدًا.** الأكاديمية هي التي تتحمّلها.

### الحد الأدنى والحد الأقصى

عن **فصل واحد**، احسب ما بين **70 $ و180 $ في الشهر**. وبالساعة، هذا يعني حوالي 9 $ لفصل مكتمل، وحوالي 5 $ لفصل من 3 طلاب.

يمكن أن يكون لك أكثر من فصل، إن سمحت أوقاتك وكانت هناك فصول لك. مثال: فصلان مكتملان للأطفال وفصل مكتمل للكبار، أي 120 + 120 + 180 = 420 $ في الشهر، مقابل 10 ساعات و30 دقيقة من الدروس في الأسبوع.

هذا المثال ليس وعدًا. فقد تبقى أيضًا شهورًا بلا فصل، أي بلا راتب (انظر القسم 7).

### لماذا 47 % للكبار و45 % للأطفال؟

مع الكبير، يجري كل شيء تقريبًا أثناء درسك. أما مع الطفل، فتضيف الأكاديمية متابعة بعد الدرس، حتى يعرف والداه أين وصل ويساعداه في البيت. وهذه المتابعة لها كلفة.

### لماذا ليس أكثر؟

لأن تشغيل الأكاديمية مكلف. فبالنصف الآخر تدفع: خوادم قاعة الفيديو، والتطبيق ومن يبنونه، ورسوم البطاقات البنكية، وإرسال مستحقاتك، والمحاسبة، والإدارة، ومتابعة الأطفال، والضرائب التي على كل شركة أن تدفعها.

سترى هذا التوزيع، بالنسب المئوية، في فضاء المعلّم الخاص بك. ليس عندنا ما نخفيه.$lettre_texte$),
('ar', '2026-11-20', 5, 'p5',
 $lettre_texte$كيف ومتى تُدفع لك المستحقات$lettre_texte$,
 $lettre_texte$بعد كل حصة، يحسب التطبيق ما كسبته. وتراه في فضائك.

يُرسَل إليك مجموع الشهر **في موعد أقصاه يوم 5 من الشهر التالي**، عن طريق تحويل دولي (Wise) أو بوسيلة أخرى حسب بلدك. ورسوم الإرسال على الأكاديمية. في بعض البلدان، تمنع البنوك هذه التحويلات: إن كانت هذه حالتك، سنخبرك بذلك، وسنبحث معك عن وسيلة مسموح بها.

إن استلمت فصلًا في منتصف الشهر، تُدفع لك الحصص المتبقية من ذلك الشهر، لا الشهر كاملًا.

### ما الذي يرفع راتبك أو يخفضه

لا يكسب معلّمان المبلغ نفسه. وهذا هو السبب.
- **عدد الطلاب.** فصل من 3 يُدرّ أقل من فصل من 5.
- **عدد الفصول** التي عندك.
- **غياب الطلاب.** إذا غاب طالب عن حصة، تأخذ نصف نصيبه عن تلك الحصة، لا النصيب كاملًا. أردنا ذلك حتى يحرص كل واحد على حضور طلابه.
- **انسحاب الطلاب.** إذا ترك طلابك الفصل واحدًا بعد واحد، ينخفض راتبك معهم. الطالب يبقى حيث يتقدّم وحيث يشعر بالاحترام. ليس كل انسحاب خطأك. لكنه خطر حقيقي، ففكّر فيه قبل أن تلتزم.
- **عطل الطلاب.** يمكن للأسرة أن توقف الطالب مؤقتًا لمدة شهر. وخلال ذلك الشهر، لا تُدفع لك مستحقات عنه.
- **إغلاق الأكاديمية.** لا دروس في آخر رمضان وأثناء عيد الفطر (حوالي 20 يومًا)، ولا حول عيد الأضحى (10 أيام). لا دروس، لا راتب.
- **غيابك أنت.** الحصة التي يقدّمها المعلّم البديل تُدفع للمعلّم البديل.
- **ملخص نهاية الحصة.** في آخر الدرس، تُبيّن بلمسات قليلة ما درسه الفصل وأين توقف. ويستغرق ذلك أقل من 20 ثانية. وما دام هذا الملخص ناقصًا، تتأخر مستحقات الشهر.$lettre_texte$),
('ar', '2026-11-20', 6, 'p6',
 $lettre_texte$الالتزام بالوقت، والمعلّم البديل، والغياب$lettre_texte$,
 $lettre_texte$الأكاديمية لا تتسامح مع قلة الانضباط. وهذا هو السبب.

نحن حازمون مع الأسر. الطالب الذي يغيب عن درس يدفع شهره كاملًا، ويتدارك ما فاته وحده. لذلك علينا أن نقوم بما علينا: **في وقت الدرس، يوجد معلّم في القاعة. دائمًا.**

### إذا تأخرت

هذا ما يفعله التطبيق، دقيقة بدقيقة.
1. **قبل الدرس بـ20 دقيقة**، تُفتح القاعة. يمكنك الدخول والاستعداد.
2. **في وقت الدرس**، إن لم تدخل، يصلك تذكير.
3. **بعد 3 دقائق**، يصلك تنبيه: إن لم تدخل، ستُعطى الحصة لغيرك.
4. **بعد 8 دقائق**، يكون قد فات الأوان لهذه الحصة. ويُرسَل تنبيه إلى كل المعلّمين المتصلين.
5. يقبل معلّم بديل ويدخل القاعة، في أقل من دقيقة عادةً. والهدف: أن يكون مع الطلاب معلّمهم **بعد الموعد بـ11 دقيقة، على الأكثر**.


إذا قبل عدة معلّمين في الوقت نفسه، يختار التطبيق أولًا من هو من جنس الفصل نفسه (رجل لفصل رجال، وامرأة لفصل نساء)، ثم من يتكلم لغته. وإلا، فأول من يكون متاحًا. إذن قد يحلّ رجل محلّ معلّمة في فصل نساء، والعكس، في تلك الحصة فقط.

**راتب هذه الحصة يذهب إلى المعلّم البديل، بنسبة 100 %.** ولا تأخذ أنت عنها شيئًا.

### ما تحتفظ به، وما تخاطر به

أن يحلّ محلّك معلّم بديل مرة واحدة لا يُفقدك فصلك. يبقى الفصل فصلك. ولا يستطيع المعلّم البديل دخوله بعد انتهاء حصته.

لكن إذا تكرر ذلك، تصلك إنذارات. وإذا استمر، ينتقل الفصل إلى شخص آخر.

### إذا اضطررت إلى الغياب

سفر، أو مناسبة عائلية، أو مرض، عافانا الله وإياكم: هذا يحدث للجميع. أخبر الإدارة **مسبقًا**، مع تاريخ ذهابك وتاريخ عودتك.

يتولّى معلّم بديل فصلك خلال هذه المدة، وتُدفع له حصصه. وعند عودتك، تستعيد فصلك.

إن لم تعد في التاريخ الذي أعلنته، تفقد هذا الفصل. لكنك لا تفقد مكانك في الأكاديمية: تبقى معنا، وتعلن أنك متاح، ويمكن أن يُسند إليك فصل آخر لاحقًا.

### إذا كنت أنت المعلّم البديل

كل حصة تعوّض فيها تُدفع لك. وتتجمّع هذه المكاسب في فضائك. وتُرسَل إليك حين تبلغ حدًّا أدنى تحدده الإدارة، حتى نتجنب تحويلات ببضعة دولارات.$lettre_texte$),
('ar', '2026-11-20', 7, 'p7',
 $lettre_texte$بعد المقابلة: ما الذي يحدث فعلًا$lettre_texte$,
 $lettre_texte$كثير منكم يظن: «أجتاز المقابلة، وفي الغد يكون عندي فصل». **لا.** هذه هي المراحل.
1. **يُقبل ملفك وتمرّ المقابلة بخير.** تحصل على الدخول إلى فضاء المعلّم وعلى رقم تسجيل رسمي. ومن هنا، يمكن أن يُسند إليك فصل.
2. **تتدرّب على التطبيق.** تُريك الأكاديمية كيف تعمل قاعة الدرس.
3. **تنتظر فصلًا.** أيامًا قليلة، أو عدة شهور.
4. **يُسند إليك فصل.** تصلك رسالة، ويظهر الفصل في صفحتك الرئيسية.


### لماذا يجب الانتظار؟

لا نعطي فصلًا بشكل عشوائي. يجب أن يتوافق كل شيء بينك وبين الطلاب الذين يسجّلون:
- **اليوم والساعة**: الطلاب يختارون موعدًا، ويجب أن تكون متفرغًا فيه؛
- **اللغة**: يجب أن تتكلم لغة الطلاب؛
- **الجنس**: رجل للأولاد والرجال، وامرأة للبنات والنساء؛
- **الخبرة**: أطفال مبتدئون، أو كبار، أو حفظ: ليست المهنة نفسها.


مثال. سجّل هذا الأسبوع اثنا عشر طالبًا: ثماني بنات صغيرات يتكلمن الفرنسية، في المساء بتوقيت أوروبا، وأربعة رجال يتكلمون الإنجليزية، في الصباح. فنحتاج إذن إلى معلّمات يتكلمن الفرنسية ومتفرغات في المساء، وإلى معلّم يتكلم الإنجليزية ومتفرغ في الصباح. والمعلّم الممتاز الذي لا يناسب أيًّا من الحالتين سينتظر التسجيلات التالية.

تُفتح الفصول طوال السنة، لا في بداية الشهر فقط.

**نصيحتنا: لا تترك شيئًا من أجلنا.** احتفظ بعملك، وواصل دراستك، وتابع بريدك الإلكتروني والتطبيق. وأكثِر من الدعاء.

### وماذا لو لم يكن هناك طلاب يكفون 2000 معلّم؟

هذا ممكن. بل في البداية هو مرجّح. لا نستطيع أن نعطي كل واحد فصلًا في الحال.

إن قُبلت ولم يكن عندك فصل، تبقى معنا. ويمكنك:
- **أن تكون معلّمًا بديلًا**: تقدّم درس معلّم مريض أو غائب أو متأخر، وتُدفع لك كل حصة؛
- **أن تنتظر** حتى يُفتح فصل أو يصبح شاغرًا.


### وماذا عن الدروس الفردية؟

كثيرون يطلبون منا دروسًا فردية: معلّم واحد لطالب واحد. والأكاديمية تدرس إمكانية تقديمها، إلى جانب الفصول. ولا نحدد أي موعد.

لقد جرّبنا هذا النموذج من قبل. وظهرت حدوده، وهو أصعب بكثير مما يُظن، على المعلّم وعلى الطالب. ولن نفتحه إلا يوم نعرف كيف نقدّمه جيدًا.$lettre_texte$),
('ar', '2026-11-20', 8, 'p8',
 $lettre_texte$لماذا نطلب وثيقة هويتك وصورتك$lettre_texte$,
 $lettre_texte$طرح عدد منكم هذا السؤال. وهو سؤال طبيعي. وهذا هو الجواب، بلا مواربة.

في الإنترنت يوجد كل شيء. ونحن عندنا طلاب من سن 6 سنوات.

فكّر فيما يراه المعلّم. يرى وجه الطفل بالفيديو. ويسمع صوته. ويعرف اسمه وعمره ومواعيده. يكلّمه ثلاث مرات في الأسبوع، والطفل يثق به.

والآن، تخيّل أن هذا المكان أُعطي لأي شخص. هذا ما قد يحدث:
- **شخص يكذب في هويته.** اسم مزيّف، وشهادة مزيّفة، ولا أحد يمكن الوصول إليه يوم تقع مشكلة.
- **شخص يبحث عن الأطفال، لا عن القرآن.** هؤلاء موجودون. يكسبون ثقة الطفل شيئًا فشيئًا، ثم يحاولون الحديث معه على انفراد، بعيدًا عن والديه.
- **شخص يصوّر بالفيديو أو يلتقط الصور.** صورة الطفل وصوته يمكن نسخهما، والاحتفاظ بهما، ونشرهما.
- **شخص طُرد من مكان آخر** بسبب سلوك خطير، ويعود باسم آخر.
- **شخص يجتاز المقابلة، ثم يجعل غيره يعلّم** مكانه.
- **شخص يريد أن يدسّ أفكارًا أخرى** في عقول الأطفال، باسم القرآن.


حالة واحدة من هذه، والنتيجة طفل مجروح، وأسرة محطّمة، وثقة تسقط في الأكاديمية كلها. والمعلّمون الصادقون، أي أنتم، سيدفعون الثمن أيضًا.

وهناك القانون أيضًا. طلابنا يعيشون في بلدان كثيرة. وقوانين حماية الطفولة تطلب منا أن نعرف بالضبط لمن نسلّم الطفل. ولإرسال مستحقاتك، يشترط البنك اسمك الحقيقي.

**ماذا نفعل بوثائقك.** لا يراها إلا الإدارة. ولا تُعرض أبدًا على الطلاب ولا على الأسر. وإن سحبت ترشحك، يمكنك أن تطلب حذفها.

**ما نطلبه منك في المقابل.** لا تطلب أبدًا من طالب رقمه أو أي وسيلة أخرى للتواصل معه. ولا تتصل به أبدًا خارج التطبيق. ولا تصوّر الفصل بالفيديو ولا بالصور. هذه قاعدة بلا استثناء.

الوالد يأتمننا على أغلى ما عنده. وأن تُظهر من أنت هو أول خطوة في الثقة. ولو كنت مكان هذا الوالد، لطلبت ذلك أنت أيضًا.$lettre_texte$),
('ar', '2026-11-20', 9, 'p9',
 $lettre_texte$ما نطلبه، وما هو صعب$lettre_texte$,
 $lettre_texte$### من رفضناهم حتى الآن

الأكاديمية سنّية، بوضوح، على منهج أهل السنة. وهي تدافع عن قيمها. ومن يعارضها لا مكان له بيننا.

حتى الآن، لم نرفض إلا نوعين من الترشحات:
- من لم يوقّعوا **الالتزام الديني**. هذا النص يطلب احترام القرآن، والسنة، وجميع صحابة النبي ﷺ، وفي مقدّمتهم الخلفاء الراشدون الأربعة، والسلف الصالح؛
- من كان مظهرهم يخالف بوضوح أحكام الدين: قَصّة شعر محرّمة في الإسلام، أو لباس لا يحترمها.


لماذا؟ لأن الطفل يتعلّم أولًا بالنظر إلى معلّمه. وأطفال المهجر يكبرون وسط كل أفكار هذا العصر. هم أمل الغد، وهم ضعفاء. وحسن اختيار معلّمهم هو أول واجب علينا.

### الصعوبة التي ستواجهها

نعرف المهجر منذ سنوات. ويجب أن ننبّهك إلى أمر.

كثير من الأسر ترى الدرس كأنه شراء. يشعرون أنهم زبائن، والمعلّم عندهم بائع. والزبون يظن أنه دائمًا على حق. ستشعر بذلك في طريقة كلامهم، وكتابتهم، ومطالبتهم.

نحن نعلم أن هذا خطأ. فمعلّم القرآن له حرمته. لكنهم لا يعلمون ذلك بعد. لم يعلّمهم أحد.

وعليك أنت أن تعلّمهم ذلك، بالحكمة والموعظة الحسنة، وبالصبر. هنا، لست معلّمًا فقط. أنت قبل كل شيء داعية.

مثال. أب يكتب إليك بجفاء: «أنا أدفع، إذن يجب أن يتقدّم ابني أسرع». يمكنك أن تغضب وترد عليه بالأسلوب نفسه. أو يمكنك أن تُريه بهدوء أين وصل ابنه، وما الذي عليه أن يراجعه في البيت، وتدعوه إلى أن يستمع إليه وهو يتلو. في الحالة الأولى، تخسر طالبًا. وفي الثانية، تكسب غالبًا أسرة كاملة.

رأينا ذلك مرات كثيرة: حين يكون المعلّم أحكم وأصبر من الطالب، تنصلح الأمور في النهاية. وإن كان هذا الصبر يثقل عليك من الآن، فهذا العمل ليس لك. ومن الأفضل أن تعرف ذلك اليوم.$lettre_texte$),
('ar', '2026-11-20', 10, 'p10',
 $lettre_texte$الأكاديمية ترى ما يحدث في الفصل$lettre_texte$,
 $lettre_texte$نفضّل أن نقول لك ذلك من قبل، لا من بعد.

**يسجّل التطبيق دخولك وخروجك**، ودخول الطلاب وخروجهم. فلا تحتاج إلى دفتر حضور: التطبيق يقوم بذلك عنك.

**ويقيس اتصالك أثناء الدرس**: جيد، أو ضعيف، أو منقطع. ولا يحتفظ بالصوت ولا بالصورة. ويوم تشتكي أسرة من درس، تعرف الأكاديمية من أين جاءت المشكلة، فلا تُتّهم ظلمًا.

**قد تحدث زيارة مراقبة، دون إشعار.** يدخل عضو من الإدارة إلى القاعة. أنت لا تراه، وليس معه ميكروفون ولا كاميرا. وحين تقدّم معلّمة درسها، تقوم بالزيارة دائمًا امرأة من الفريق، ولا يقوم بها رجل أبدًا. والزائر ينظر إلى أمر واحد: هل يعمل المعلّم فعلًا مع طلابه؟

**لا يمكنك تقديم درسين في الوقت نفسه.** الزائر يرى ذلك. وإذا غادرت القاعة أكثر من 30 ثانية أثناء درسك، يُخرجك التطبيق ويُبلغ الإدارة.

وفي ما عدا ذلك، أنت حر. لا تفرض عليك الأكاديمية مكانًا معيّنًا في البيت، ولا وضعية، ولا خلفية. تطلب أمرين: مكانًا هادئًا واتصالًا جيدًا. ومن دونهما، يتضرر الطلاب.$lettre_texte$),
('ar', '2026-11-20', 11, 'p11',
 $lettre_texte$Praxis، مساعدنا$lettre_texte$,
 $lettre_texte$أنتم أكثر من 2000. تتكلمون عشرات اللغات، وتعيشون في كل المناطق الزمنية، ورسائلكم تصل ليلًا ونهارًا. وفريقنا لا يستطيع أن يرد على كل واحد بالسرعة الكافية.

لذلك أنشأنا **Praxis** (براكسيس)، وهو مساعد يعمل بالذكاء الاصطناعي. ليس إنسانًا، ولن يتظاهر أبدًا بأنه إنسان.
- **ما يفعله**: يجيب عن الأسئلة المتكررة، ويقدّم التوضيحات، ويخبرك أين وصل إجراء ما.
- **ما لا يفعله**: لا يقرّر شيئًا. لا يقبل أحدًا ولا يرفض أحدًا، ولا يعطي فصلًا، ولا يمسّ الراتب.
- **من يديره**: الإدارة. ولا يتصرف إلا إذا أسندت إليه مهمة.


أين وصل اليوم؟ بدأنا تجربته. ارتكب بعض الأخطاء، فأوقفناه مؤقتًا. ونحن ندرس إجاباته لضبطه، ثم سنعيد تشغيله. وربما وصلت بعضكم رسالة منه من قبل.

وحين يعود، إن لم يكفك جوابه، فاذكر ذلك في رسالتك: وسيتولّى الأمر عضو من الفريق.$lettre_texte$),
('ar', '2026-11-20', 12, 'p12',
 $lettre_texte$إن لم يناسبك هذا$lettre_texte$,
 $lettre_texte$أنت حر في المغادرة، في أي وقت، دون أن تبرّر.

أكاديمية الرواية شركة إنجليزية. ويُلزمها القانون باحترام حقك في الانسحاب. يمكنك أن تسحب ترشحك وتطلب حذف حسابك وبياناتك. وبعد ذلك، لن تصلك أي رسالة من الأكاديمية. وإن غيّرت رأيك، يمكنك أن تستأنف ترشحك بنفسك خلال 7 أيام من سحبه.

لذلك، اكتب إلى **support@rewayahacademy.com**.$lettre_texte$),
('ar', '2026-11-20', 13, 'p13',
 $lettre_texte$أسئلتكم$lettre_texte$,
 $lettre_texte$**سجّلت. هل أصبحت معلّمًا في الأكاديمية؟** ليس بعد. أنت مرشّح. بقيت دراسة ملفك، ثم المقابلة.

**هل يجب أن أدفع لأُقبل أو للتدريب؟** لا. لا شيء، أبدًا. إن طلب منك أحد مالًا باسمنا، فهو احتيال: أخبرنا.

**كم سأنتظر حتى أحصل على فصل؟** لا نعلم، ولن نعطيك موعدًا لا نستطيع الوفاء به. الأمر يتوقف على الطلاب الذين يسجّلون، وعلى أوقاتك، ولغتك، وخبرتك.

**في أي ساعة ستكون دروسي؟** في الساعة التي يختارها طلاب الفصل، وهي نفسها كل أسبوع. ولن يُسند إليك فصل إلا إذا كان موعده يناسبك. ويعرض التطبيق كل موعد بتوقيتك، ثم بتوقيت مكة المكرمة، وهو ساعة الأكاديمية.

**كم سأكسب بالضبط؟** حوالي 24 $ في الشهر عن كل طفل، وحوالي 30 $ في الشهر عن كل كبير، إن حضروا كل الحصص. احسب طلابك، واضرب، فتعرف دخل شهرك.

**غاب طالب. هل تُدفع لي مستحقاته؟** النصف. تأخذ نصف نصيبه عن تلك الحصة.

**تأخرت مرة واحدة فحلّ محلّي معلّم بديل. هل فقدت فصلي؟** لا. فقدت راتب تلك الحصة. ولا تفقد الفصل إلا إذا تكرر ذلك، بعد إنذارات.

**ماذا أحتاج لأعلّم؟** اتصالًا جيدًا بالإنترنت، وحاسوبًا أو جهازًا لوحيًا فيه كاميرا وميكروفون، ومكانًا هادئًا. ولا شيء آخر تثبّته غير تطبيق الأكاديمية.

**هل يمكنني أن أعلّم في مكان آخر في الوقت نفسه؟** نعم، ما دامت ساعاتك الأخرى لا تتعارض مع ساعات الأكاديمية. الممنوع هو تقديم درسين في اللحظة نفسها.

**هل يمكن أن تتغير المبالغ؟** نعم، يمكن للإدارة أن تراجعها. وستُبلَّغ قبل ذلك، ولن يُمسّ أبدًا شهر عملت فيه.$lettre_texte$),
('ar', '2026-11-20', 14, 'p14',
 $lettre_texte$لكي تقرّر$lettre_texte$,
 $lettre_texte$**أكمل معنا إذا** كنت تقبل أن تُدفع لك المستحقات حسب عدد الطلاب، وأن تنتظر ربما طويلًا فصلك الأول، وأن تلتزم بالوقت في كل حصة، وأن تُظهر من أنت، وأن تصبر على أسر لا تعرف بعد منزلة معلّم القرآن.

**لا تكمل إذا** كنت تبحث عن دخل ثابت وفوري، أو إذا كنت لا تستطيع الالتزام بموعد منتظم، أو إذا كان الالتزام الديني للأكاديمية لا يمثّلك.

وفي الحالتين، جزاك الله خيرًا على استجابتك لندائنا.

إدارة أكاديمية الرواية

#Ra_staff$lettre_texte$);

-- 3. La lecture --------------------------------------------------------------------------------------------------------------
CREATE FUNCTION public.lire_lettre_candidats(p_langue text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_profil public.profiles;
  v_compte_ok boolean := false;
  v_ouverte boolean := false;
  v_dossier jsonb;
  v_manques text[] := ARRAY[]::text[];
  v_langue text;
  v_version text;
BEGIN
  -- Sans session : refus (anon n'a de toute facon pas le droit d'executer).
  IF v_uid IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('acces', false, 'raison', 'compte');
  END IF;

  -- Le role se lit dans le jeton, en exigence positive : seul l'enseignant passe.
  IF NOT coalesce(public.app_role() = 'teacher'::public.app_role, false) THEN
    RETURN pg_catalog.jsonb_build_object('acces', false, 'raison', 'role');
  END IF;

  -- L'etat du compte : profil enseignant non efface, statut ouvert, acces non expire.
  SELECT p.* INTO v_profil FROM public.profiles p WHERE p.id = v_uid AND p.deleted_at IS NULL;
  v_compte_ok := coalesce(
    v_profil.role = 'teacher'::public.app_role
    AND v_profil.account_status IN ('pending_kyc', 'provisional_active', 'active')
    AND (v_profil.access_until IS NULL OR v_profil.access_until > pg_catalog.now()),
    false);
  IF NOT v_compte_ok THEN
    RETURN pg_catalog.jsonb_build_object('acces', false, 'raison', 'compte');
  END IF;

  IF v_profil.account_status = 'active' THEN
    -- L'enseignant actif lit la lettre.
    v_ouverte := true;
  ELSE
    -- Le candidat : les trois accords, lus a la meme source que la page « Votre dossier ».
    v_dossier := public.etat_dossier();
    IF NOT coalesce((v_dossier ->> 'contrat_signe')::boolean, false) THEN
      v_manques := v_manques || 'contrat'::text;
    END IF;
    IF NOT coalesce((v_dossier ->> 'code_conduite_signe')::boolean, false) THEN
      v_manques := v_manques || 'conduite'::text;
    END IF;
    IF public.cadre_religieux_version_requise() IS NOT NULL
       AND NOT coalesce((v_dossier #>> '{candidature,cadreReligieux,accepte}')::boolean, false) THEN
      v_manques := v_manques || 'cadre'::text;
    END IF;
    v_ouverte := pg_catalog.cardinality(v_manques) = 0;
  END IF;

  IF NOT v_ouverte THEN
    RETURN pg_catalog.jsonb_build_object('acces', false, 'raison', 'accords',
                                         'manques', pg_catalog.to_jsonb(v_manques));
  END IF;

  -- La langue : « fr », « en », « ar » (une forme « ar-EG » ou « en_GB » garde sa langue) ; sinon le francais.
  v_langue := pg_catalog.split_part(
    pg_catalog.replace(pg_catalog.lower(pg_catalog.btrim(coalesce(p_langue, ''))), '_', '-'), '-', 1);
  SELECT max(t.version) INTO v_version FROM private.lettre_candidats_parties t WHERE t.langue = v_langue;
  IF v_version IS NULL THEN
    v_langue := 'fr';
    SELECT max(t.version) INTO v_version FROM private.lettre_candidats_parties t WHERE t.langue = v_langue;
  END IF;
  IF v_version IS NULL THEN
    RAISE EXCEPTION 'LETTRE-SERVEUR : aucun texte de la lettre';
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'acces', true,
    'version', v_version,
    'langue', v_langue,
    'parties', (SELECT pg_catalog.jsonb_agg(
                         pg_catalog.jsonb_build_object('code', t.code, 'titre', t.titre, 'corps', t.corps)
                         ORDER BY t.rang)
                  FROM private.lettre_candidats_parties t
                 WHERE t.langue = v_langue AND t.version = v_version));
END;
$function$;

REVOKE ALL ON FUNCTION public.lire_lettre_candidats(text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.lire_lettre_candidats(text) TO authenticated;

-- 4. F86 : l'empreinte en commentaire ------------------------------------------------------------------------------------------
DO $f86$
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.lire_lettre_candidats(text) IS %L',
    'F86 candidate allowlist: signature=public.lire_lettre_candidats(p_langue text); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.lire_lettre_candidats(text)'::regprocedure))
    || '; guard_type=ROLE_POSITIVE_TEACHER_ACCOUNT_AND_ACCORDS; owner=postgres; search_path=""; reviewer=Claude a relire; '
    || 'date=2026-11-20. LETTRE-SERVEUR. Role enseignant du jeton (garde positive) ; profil enseignant ouvert ; compte actif ou '
    || 'accords de public.etat_dossier() ; ne rend que le texte de l''academie, jamais une donnee de personne. '
    || 'Must-pass: supabase/tests/scenarios_lettre_candidats.sql.');
END
$f86$;

-- 5. Controle final ----------------------------------------------------------------------------------------------------------
DO $controle$
DECLARE
  v_langue text;
  v_n integer;
BEGIN
  FOREACH v_langue IN ARRAY ARRAY['fr', 'en', 'ar'] LOOP
    SELECT count(*) INTO v_n FROM private.lettre_candidats_parties t
     WHERE t.langue = v_langue AND t.version = '2026-11-20';
    IF v_n IS DISTINCT FROM 14 THEN
      RAISE EXCEPTION 'LETTRE-SERVEUR : % parties en %, 14 attendues', v_n, v_langue;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_catalog.generate_series(1, 14) g(r)
                WHERE NOT EXISTS (SELECT 1 FROM private.lettre_candidats_parties t
                                   WHERE t.langue = v_langue AND t.version = '2026-11-20'
                                     AND t.rang = g.r AND t.code = 'p' || g.r)) THEN
      RAISE EXCEPTION 'LETTRE-SERVEUR : rangs ou codes incomplets en %', v_langue;
    END IF;
  END LOOP;
  IF (SELECT count(*) FROM private.lettre_candidats_parties) IS DISTINCT FROM 42 THEN
    RAISE EXCEPTION 'LETTRE-SERVEUR : 42 lignes attendues';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'private.lettre_candidats_parties'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'LETTRE-SERVEUR : RLS non activee';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_policy p
              WHERE p.polrelid = 'private.lettre_candidats_parties'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'LETTRE-SERVEUR : la table ne doit porter aucune politique';
  END IF;
  IF has_table_privilege('anon', 'private.lettre_candidats_parties', 'SELECT,INSERT,UPDATE,REFERENCES,TRIGGER')
     OR has_table_privilege('authenticated', 'private.lettre_candidats_parties', 'SELECT,INSERT,UPDATE,REFERENCES,TRIGGER')
     OR has_table_privilege('service_role', 'private.lettre_candidats_parties', 'SELECT,INSERT,UPDATE,REFERENCES,TRIGGER')
     OR has_table_privilege('agent_ro', 'private.lettre_candidats_parties', 'SELECT,INSERT,UPDATE,REFERENCES,TRIGGER') THEN
    RAISE EXCEPTION 'LETTRE-SERVEUR : un role client garde un droit sur la table';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'public.lire_lettre_candidats(text)'::pg_catalog.regprocedure
                    AND p.prosecdef AND 'search_path=""' = ANY (p.proconfig)) THEN
    RAISE EXCEPTION 'LETTRE-SERVEUR : la lecture doit etre SECURITY DEFINER avec search_path vide';
  END IF;
  IF has_function_privilege('anon', 'public.lire_lettre_candidats(text)', 'EXECUTE')
     OR has_function_privilege('agent_ro', 'public.lire_lettre_candidats(text)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.lire_lettre_candidats(text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'LETTRE-SERVEUR : droits d''execution inattendus (anon et agent_ro : non ; authenticated : oui)';
  END IF;
  IF coalesce(pg_catalog.obj_description('public.lire_lettre_candidats(text)'::pg_catalog.regprocedure, 'pg_proc'), '')
     NOT LIKE '%md5_functiondef='
       || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.lire_lettre_candidats(text)'::pg_catalog.regprocedure)) || '%' THEN
    RAISE EXCEPTION 'LETTRE-SERVEUR : empreinte F86 absente';
  END IF;
END
$controle$;
