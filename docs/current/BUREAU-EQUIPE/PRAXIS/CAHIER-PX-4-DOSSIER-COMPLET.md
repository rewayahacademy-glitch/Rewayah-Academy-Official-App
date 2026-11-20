# Cahier PX-4 : Praxis lit tout le dossier, se forge un avis, ouvre le dialogue (20/11/2026)

Ordre du directeur, 20/11/2026 : « J'espère que tu lui as donné les outils nécessaires pour lire tout le contexte d'un
dossier […] sinon, s'il se base seulement sur les données basiques, ce n'est pas la peine, car les filtres savent déjà
faire tout ça. Il doit être une vraie IA […] pour trouver les pépites parmi les pépites ; s'il le faut, ouvrir le
dialogue avec eux […] sans harceler ni mettre la pression. […] J'ai besoin d'un assistant. » Trois précisions du même
jour sont intégrées : l'empathie mesurée (§4), le contexte ouvert (§4), l'entretien écrit (§6).

Migration : `supabase/migrations/20261130200000_praxis_dossier_complet.sql`. Scénario :
`supabase/tests/scenarios_praxis_dossier_complet.sql`. Bâti sur PX-3 (`20261130100000`).

## 0. Ce qui est faux, bloqué ou non prouvé

- **Rien n'est installé ni déployé.** La migration n'a tourné que sur un Postgres 16 local (la production est en 17).
  La fonction Edge `praxis-mcp` n'est pas déployée : tant qu'elle ne l'est pas, aucun outil neuf n'existe pour Praxis.
- **Le texte de confidentialité ne couvre pas ce lot** (§9) : il faut le modifier AVANT la mise en service.
- **`boite` et `ecrire` n'ont pas reçu les filtres et la `raison` demandés : ce sont deux outils NEUFS**,
  `boite_candidats` et `ouvrir`. Raison : dans `outils.ts`, un outil appelle une seule fonction de la base, et la boîte
  des candidats rend des candidatures (une personne peut ne pas avoir de conversation), pas des fils. Les noms et les
  arguments de `boite` et `ecrire` sont inchangés ; leurs descriptions renvoient vers les outils neufs.
- **`ecrire` change de comportement dans les conversations de candidature** (question laissée ouverte par le cahier
  PX-3, §6) : sans raison, Praxis ne fait plus que RÉPONDRE (la personne a écrit et la direction n'a pas répondu depuis
  dans la conversation), sinon `raison_requise` ; 2 messages de suite au plus (3 avant). La routine en production
  appelle `ecrire` toutes les heures : elle recevra ces refus tant que sa consigne n'emploie pas `ouvrir`.
- **Féliciter après l'accueil final n'est pas livré.** `a_feliciter` ne connaît que l'admission en salle de
  vérification (`admettre_verifications`). À l'accueil (étape `confirmee`), la conversation de candidature est fermée
  (`praxis_fil_refus`, `com_paires`) : il faudrait la rouvrir 72 heures, ce lot ne le fait pas.
- **Le questionnaire ne contient aucun texte libre.** Toutes les réponses sont des choix dans des listes. La « vision »
  ne se lit donc dans aucun champ : elle vient de la conversation ou de l'entretien écrit. Sans dialogue, Praxis ne
  peut pas la noter.
- **Le filtre de mots est un filtre de mots.** Il refuse des termes français, anglais et quelques termes arabes ; une
  périphrase passe. La règle tient d'abord par la description de l'outil. « 5 questions au plus » se compte aux points
  d'interrogation.
- **Les dossiers sans majorité attestée sont fermés à `dossier`** : tous les candidats importés sans compte le sont.
  C'est l'ordre (« de majorité non attestée : fermés ») ; cela peut laisser une grande partie de la file illisible.
- **`scenarios_sec1_praxis.sql` reste ROUGE à une vérification qui ne vient pas de ce lot** : « R1 : aucun EXECUTE
  dynamique » cherche le mot `execute` sans tenir compte de la casse, et deux fonctions de PX-3 le portent dans un
  commentaire en français (`praxis_gestes_ligne`, `direction_praxis_valider`). Non modifié (c'est un garde-fou : au
  pilote de trancher). Avec cette seule vérification rendue sensible à la casse, sur une copie jetée, tout le fichier
  est vert. `scenarios_px2_preparer.sql` reste rouge pour la raison déjà dite par le cahier PX-3 (mots `piece`, `photo`).
- **Les tests Deno ne sont pas lancés** (pas de `deno`). `outils.ts` passe `tsc --strict`. `praxis_test.ts` : la liste
  des noms d'outils est mise à jour, aucun cas neuf n'est écrit.
- **Aucun écran** ne lit `direction_praxis_impressions`. **La routine ne connaît pas ces outils** (`ROUTINE-PRAXIS.md`
  non modifié, hors zone).
- **Pile `pepite`** : non ajoutée aux rangements (il aurait fallu réécrire un CHECK) ; l'étiquette suffit.
- Budget dépassé : le lot a pris bien plus que 80 minutes (deux précisions reçues en cours de route).

## 1. Ce qui est livré

| Point | Outil du connecteur | Fonction |
| :-: | :--- | :--- |
| 1 | `dossier` | `praxis_dossier(cle, CAND-…)` |
| 2 | `noter_impression` | `praxis_noter_impression(…)`, table `private.praxis_impressions`, lecture `direction_praxis_impressions(etiquette, limite, decalage)` |
| 3 | `boite_candidats`, `ouvrir` | `praxis_boite_candidats(cle, filtre, jours, limite)`, `praxis_ouvrir(cle, CAND-…, raison, texte, cle_idempotence)`, table `private.praxis_ouvertures`, limites dans `private.praxis_ouverture_refus` |
| 4 | `lire` (filtres) | `praxis_lire` remplacée |
| + | entretien écrit | raisons `entretien_ecrit`, `relance_entretien` de `ouvrir` ; filtre `a_interroger` |

Scénario : 92 vérifications isolées, plus 9 refus d'appel ; toutes vertes en local (Postgres 16).

## 2. `dossier` : ce qui est rendu, ce qui ne l'est jamais

Rendu : `reference`, `cote`, `langue`, `etape`, `etat`, `source`, `anciennete_jours`, `attente_jours`,
`jours_sans_activite_candidat`, `a_un_compte`, `pays_residence`, `fuseau`, `versement` (`pays`, `possible`),
`entretien` (`prevu`, `passe` et son issue, `dispense`, `aucun`), `entretien_ecrit` (`aucun`, `en_cours`, `repondu`),
`manquants`, `attend_direction`, `complet`, `complement_en_cours`, `gestes`, `historique` (60 derniers : date, type,
geste, auteur, étapes et états avant et après), `praxis` (rangement, impression courante avec notes, contexte et
synthèse, nombre d'impressions passées, ouvertures), `conversation` (des comptes, et l'identifiant du fil s'il est
lisible), et sous `contenu_tiers` : `prenom`, `questionnaire` (version, source, date, et les réponses de la liste
blanche : `langueMaternelle`, `languesExplication`, `niveauMemorisationDeclare`, `niveauLectureTajwid`, `riwayat`,
`ijazaPresentable`, `experienceDebutants`, `disponibilitesDeclarees`, `fuseauIana`, `classesSouhaitees`,
`debutPossible`, `publics`, `paysResidence`, `paysVersement`, `heuresParSemaine`), `autres_competences` (domaines,
texte « autre », disponibilité, accord), `entretien_ecrit_reponses` (les messages du candidat depuis la dernière série).

Jamais : courriel, téléphone, nom complet, date de naissance, pièce, photo, `compteBancaire`, `operateurs`,
`moyensAccessibles`, tout montant, notes et compte rendu d'entretien, `motif_interne` des événements, lectures de
contact. Un champ ajouté demain au questionnaire n'est pas rendu tant qu'il n'est pas nommé dans la liste blanche.

Fermé, avec la même réponse `candidature_inconnue` : inconnu, autre type, refusé, retiré, en pause, restreint,
majorité non attestée, compte mineur, autre côté. Plafond : 120 lectures par heure (`plafond_dossiers`).

## 3. Les impressions

Étiquettes : `pepite`, `solide`, `a_creuser`, `reserve`. Critères de 1 à 5, facultatifs : `maitrise`, `pedagogie`,
`vision`, `comportement`, `disponibilite`. Confiance : `faible`, `moyenne`, `forte`. Texte : 800 signes. Par ajout :
la dernière fait foi, les précédentes sont gardées. 120 par heure. Une impression ne change rien au dossier et n'écrit
à personne.

## 4. Empathie mesurée : le contexte éclaire, il ne juge pas

Directeur, 20/11/2026 : « il doit avoir une empathie, mesurée mais existante, pour pouvoir savoir qui choisir entre des
candidats ex æquo […] élargis, tu verras des schémas », puis : « c'est toi l'IA, creuse les scénarios ».

- **Le contexte de vie est un fait à peser, jamais un jugement sur la personne.** Il ne s'additionne pas aux cinq
  critères : il éclaire un choix entre candidats de même valeur.
- L'impression porte un **contexte ouvert** : 12 éléments au plus, chacun `{theme, constat, source, effet}`. Le thème
  est libre (60 signes) ; le constat fait 200 signes au plus ; la **source est obligatoire** (quelle réponse du dossier,
  quel message) ; l'effet vaut `atout`, `risque` ou `a_verifier`. Thèmes suggérés dans la description de l'outil, non
  limitatifs : besoin du travail, connexion et électricité, moyen de recevoir un versement, disponibilité et fuseau,
  charge de famille ou autre emploi, expérience avec les enfants ou les débutants, langues réellement parlées, matériel,
  constance dans les échanges, ton et patience à l'écrit, motivation exprimée, ancienneté, ce que la personne apporterait
  de rare.
- Le nom d'un pays est admis, comme fait de contexte (réseau, versement), jamais comme motif. Un versement difficile ou
  encadré se nomme « conformité du versement à examiner par la direction », en termes neutres.
- Refusé par le serveur (`texte_interdit`, avec le mot trouvé), dans le texte, le contexte et la synthèse : ethnie,
  couleur, apparence, handicap, santé, religion pratiquée (courant, école), opinion, situation de couple, et toute
  accusation (terroriste, criminel, fraudeur, escroc, délinquant, extrémiste ; anglais et arabe compris).
- La **synthèse** (facultative) : `utile_pour`, `situation`, `reserves`, `video` (vrai ou faux), `video_pourquoi`.
- La direction lit le contexte et la synthèse dans `direction_praxis_impressions`.

## 5. Ouvrir le dialogue : toutes les limites

| Limite | Code du refus |
| :--- | :--- |
| Dossier fermé, sans compte, ou déjà confirmé | `candidature_inconnue` |
| La conversation est fermée à Praxis (mineur, côté, essai, données réelles) | le code de `praxis_fil_refus`, ou `hors_essai`, `donnees_reelles_fermees` |
| Entre 21 h et 8 h chez le candidat, fuseau connu | `heure_tardive` |
| 2 messages de Praxis de suite sans réponse | `plafond_fil` |
| La direction a écrit dans la conversation depuis moins de 48 heures | `direction_recente` |
| Une question, relance ou série par personne tous les 7 jours | `ouverture_recente` |
| Relance : rien ne manque, ou la personne a agi depuis moins de 3 jours | `relance_sans_objet` |
| 3 relances en tout par personne | `plafond_relances` |
| 25 ouvertures par 24 heures, au total | `plafond_ouvertures` |
| Félicitations : aucune admission depuis 72 heures | `felicitations_sans_objet` |
| Félicitations : déjà faites pour cette décision, ou quelqu'un a écrit depuis | `deja_felicite` |
| Plafond horaire des envois (partagé avec `ecrire`) | `plafond` |

Filtres de `boite_candidats` : `a_approfondir`, `sans_nouvelles` (`jours` de 3 à 60), `a_feliciter`, `a_interroger`.
Chaque ligne dit `permis`, ou le `refus` qui empêche d'écrire maintenant. La conversation ouverte est la conversation
standard de candidature (type `candidature`, le candidat et l'académie) ; le message passe par
`private.com_envoyer_message_interne`, comme tout message de Praxis. Les ouvertures sont journalisées sous `ecrire`.

## 6. L'entretien écrit

Directeur, 20/11/2026 : trop de candidats pour les voir tous en vidéo ; quelques questions simples par écrit.

- `ouvrir` avec la raison `entretien_ecrit` : de 1 à 5 questions par envoi (`trop_de_questions`), une seule série
  ouverte par candidat (`entretien_en_cours` tant qu'il n'a pas répondu), 2 séries en tout (`plafond_entretiens`).
- `relance_entretien` : une seule par série, 7 jours après, si le candidat n'a pas répondu
  (`relance_entretien_sans_objet`, `entretien_deja_relance`). Jamais au-delà.
- Les réponses se lisent dans `dossier` (`contenu_tiers.entretien_ecrit_reponses`), puis Praxis note une impression
  avec sa synthèse.
- **Praxis ne change jamais l'étape.** Dispenser de la vidéo se propose avec `preparer` (`dispenser_entretien`, PX-3),
  que la direction valide. Le scénario vérifie qu'aucune étape, proposition ni dispense ne bouge.
- Non fait : les questions ne sont pas des objets suivis un par un ; une série est un message.

## 7. `lire` pour chercher les meilleurs

Filtres neufs : `etiquette`, `sans_impression` (booléen), `ijaza` (`oui`, `pret_test`, `non`), `riwaya`,
`langue_explication`, `public` (`6_9`, `10_13`, `14_17`, `adultes`), `tri` (`attente`, `vision`). Chaque ligne rend
`impression` (étiquette, vision, confiance) ou null. Les filtres existants et l'ordre par défaut ne changent pas.

## 8. Décisions prises, et pourquoi

1. Trois fonctions remplacées, corps recopié par `pg_get_functiondef` sur la base rejouée, empreinte contrôlée, ajouts
   marqués `PX-4` : `praxis_lire` (de PX-3), `praxis_ecrire` (de `20261129910000`), `praxis_noter_refus` (de PX-3).
2. Zéro mot d'effacement : aucune contrainte existante n'est réécrite.
3. Une table des ouvertures, parce que le journal est purgé à douze mois et ne peut pas porter « 3 en tout ».
4. Toutes les limites dans une seule fonction, lue par la boîte (pour dire `permis`) et par `ouvrir` (pour refuser).
5. Listes blanches mises à jour, chacune commentée : `scenarios_praxis_travail.sql` (clé `impression`),
   `scenarios_cand_autres_competences.sql` (`praxis_dossier` lit les autres compétences),
   `scenarios_sec1_praxis.sql` (R2, R4, AR-10, R1 : les outils de PX-4 et ceux que PX-3 n'avait pas ajoutés).

## 9. Confidentialité

Texte validé (`docs/current/TEXTES-VALIDES/POLITIQUE-CONFIDENTIALITE-PRAXIS.md`) : « Un assistant numérique, appelé
Praxis, aide l'académie à répondre aux familles et aux candidats dans la messagerie de l'application. […] Il lit les
messages des conversations avec l'académie pour y répondre ou préparer une réponse. Il ne lit […] ni les pièces
d'identité, ni les paiements. »

Ce texte **ne permet pas** ce lot : il ne dit ni que l'assistant lit les réponses du dossier de candidature, ni qu'il
écrit le premier, ni qu'il note une impression sur les candidats (un classement de personnes, avec leur situation), ni
qu'il mène un entretien écrit. `dossier` rend aussi le pays de versement et « versement possible ou non », que « ni les
paiements » peut sembler exclure. À modifier et à faire valider par le directeur avant d'ouvrir les outils. La
publication effective de ce texte dans l'application n'a pas été vérifiée ici.

## 10. Liste de contrôle d'installation (pilote)

Avant, en lecture seule :
1. `schema_migrations` contient `20261130100000` (PX-3) et pas `20261130200000`.
2. Empreintes `md5(prosrc)` : `praxis_lire` `85ff7182883d73d39d3bb51298b2f75b`, `praxis_ecrire`
   `d224d33664646855a7b79a28c6dbddc3`, `praxis_noter_refus` `d13a327123e66d50ccc51c617ba8d1ee`.
3. `private.praxis_impressions` et `private.praxis_ouvertures` n'existent pas.
4. Compter les mots d'effacement du fichier : zéro.

Après :
5. Les deux tables : RLS active, aucune politique, aucun droit client, zéro ligne.
6. `has_function_privilege` : les quatre outils neufs et les trois remplacés pour `service_role` seul ;
   `direction_praxis_impressions` pour `authenticated` seul ; les sept aides privées pour personne.
7. Les trois fonctions remplacées : `SECURITY DEFINER`, propriétaire `postgres`, `search_path` vide.
8. `private.praxis_reglages` inchangé.
9. Déployer `praxis-mcp` ; `tools/list` rend 22 outils.
10. Mettre à jour la consigne de la routine et le texte de confidentialité avant d'ouvrir.
