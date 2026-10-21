# UX_REVIEW_OFFRES-FAM-1 : suivi des demandes de créneau, côté famille

Date : 09/10/2026. Lot : OFFRES-FAM-1 (décision du directeur du 09/10/2026,
`DECISION-OFFRES-GROUPES-2026-10-09.md`, §2 et §4). Écran `/tuteur/demandes`
(`lib/features/suivi_demandes/`), carte d'entrée sur l'accueil famille, port
`lib/core/offres/port_suivi_demandes.dart`, adaptateur de démonstration
`lib/features/demo/suivi_demandes_demo.dart`.

## Demande du directeur (source des libellés)

- La famille est tenue au courant à chaque étape : notification **et** suivi
  visible dans son espace (§4).
- Étapes et phrases, mot pour mot : « Votre demande est arrivée à l'administration »
  (prochaine étape : constitution de la classe) ; « Votre classe a été validée »
  (prochaine étape : affectation de l'enseignant) ; « Classe validée · enseignant affecté »
  (début des cours : date et heure locale) ; refus ou retrait : le motif en clair et ce
  qu'elle peut faire ensuite.
- Créneau personnalisé : une notice dit qu'il ne s'ouvrira que si d'autres élèves le
  choisissent et remplissent la classe (§2).
- La famille ne voit jamais qui d'autre a demandé le même créneau ni combien de personnes
  l'ont demandé (§4). Aucun nom d'enseignant dans la vitrine (§2) ; dans le suivi, le nom
  n'apparaît qu'à l'étape 3 (consigne du lot).

## Libellés ajoutés (`suiviDemandes`)

Mot pour mot de la décision : les trois phrases de situation, les deux « Prochaine étape »
et la notice. Délégation du 02/10 (« le reste tu te débrouilles pour le bien de
l'académie ») pour les autres, rédigés par l'agent, à faire valider par le directeur :

- Titre : « Suivi des demandes de créneau »
- Contexte (K-58) : « Chaque demande avance en trois étapes. Vous êtes prévenu à chaque passage. »
- Titre de carte (qui et quoi) : « Demande de créneau {dePrenom} » (« Demande de créneau de Yusuf », « Demande de créneau d'Aïcha »)
- Rappel : « Jours choisis », « Heure choisie », « {debut} et {dernier} » (« Lundi, mardi et jeudi »), « {heure}, heure {deVille} » (« 18:00, heure de Paris »)
- Frise : « Demande envoyée », « Classe validée », « Enseignant affecté » ; états « Fait », « Prochaine étape », « À venir »
- Situation : « Votre demande est arrivée à l'administration », « Votre classe a été validée », « Classe validée · enseignant affecté »
- Prochaine étape : « Prochaine étape : constitution de la classe », « Prochaine étape : affectation de l'enseignant »
- Étape 3 : « Début des cours », « {date} à {heure}, heure {deVille} » (« Lundi 19 octobre à 17:30, heure de Paris »), « La date du premier cours s'affichera ici dès qu'elle sera fixée. », « Enseignant »
- Notice : « Ce créneau ne s'ouvrira que si d'autres élèves le choisissent et remplissent la classe. »
- Pastilles d'une demande close : « Demande retirée », « Demande non retenue »
- Motifs en clair : « Vous avez retiré cette demande. », « L'académie a retiré ce créneau de ses offres. », « La classe de ce créneau n'a pas pu être constituée. », « La direction n'a pas pu retenir cette demande. »
- Suite : « Vous pouvez choisir un autre créneau parmi ceux proposés. » ; sans capacité de rechoisir : « Aucun autre créneau n'est proposé pour le moment. Revenez sur cette page plus tard. »
- Lien : « Choisir un autre créneau pour {prenom} »
- Vide : « Aucune demande de créneau en cours. »
- Échec de chargement (K-59, revu par ECHELLE-CORR-ECRANS-1 le 10/10 : rien n'est affirmé de l'état du serveur, et la phrase ne laisse pas croire que la demande de créneau est perdue) : « Le suivi de vos demandes n'a pas pu être affiché : il est possible que la lecture ne soit pas parvenue jusqu'à Rewayah. Cet échec concerne seulement l'affichage du suivi : il ne dit rien de vos demandes de créneau. Réessayez dans un instant. »
- Hors ligne sans données (EA-HL-DOUBLE-1, dit ce qui manque) : « Le suivi des demandes n'a pas pu être chargé »
- Accueil : « Vos demandes de créneau », « {prenom} : {etat} », « Voir le suivi des demandes »
- Notifications : « Demande de créneau {dePrenom} : votre demande est arrivée à l'administration », « Demande de créneau {dePrenom} : votre classe a été validée », « Demande de créneau {dePrenom} : classe validée · enseignant affecté », « Demande de créneau {dePrenom} : {motif} »

## Contrôle UX

| Proposition | Règle et source | Conclusion | Conséquence dans l'écran |
| :--- | :--- | :--- | :--- |
| Une carte par élève concerné, détachées | K-55 (`PileCartes`) ; Gestalt, proximité | conforme | `PileCartes` (16) ; demandes en cours d'abord, closes ensuite |
| Frise d'étapes | WCAG 2.2 SC 1.4.1 (jamais la couleur seule) ; Nielsen n° 1, visibilité de l'état | ajustée | Trois signaux par étape : icône (coche pleine, horloge, sablier), mot (« Fait », « Prochaine étape », « À venir »), encre ; une ligne lue d'un tenant (`MergeSemantics`) |
| Phrase de situation, puis prochaine étape | Nielsen n° 1 ; décision §4 | conforme | La phrase du directeur en `bodyLarge` fort, la prochaine étape juste sous la frise |
| Heures dans le fuseau de la famille | 03 « locales et fuseaux » ; règle métier (le serveur rend l'heure murale du foyer) | conforme | Aucune conversion par l'appareil ; la ville du fuseau est dite (« heure de Paris », « heure de New York ») |
| Aucun nombre ni identité d'autres demandeurs, aucun enseignant avant l'étape 3 | Décision §4 ; DESIGN-GOV §4.3 (la visibilité des données ne bouge pas) | conforme | Le contrat n'a aucun champ pour eux ; le modèle efface l'enseignant avant l'étape 3 ; test dédié |
| Refus ou retrait | K-59 (ce qui s'est passé, quoi faire) ; Nielsen n° 9 | conforme | Pastille à mot + motif en clair + suite ; le lien n'existe que si le serveur rend la capacité, sinon une phrase (jamais grisé) |
| Aucun bouton plein | K-56 ; DESIGN-GOV §4 bis.2 règle 4 | conforme | Écran de lecture : aucune `ActionPrincipale` ; l'action rare est un `LienFleche` au bord de fin de sa carte (16 sous le contenu) |
| États | 03 §États ; DESIGN-GOV §4 bis.6 | conforme | `Skeleton.liste` dans `BlocAsynchrone`, contenu, `EmptyState` (registre subi), `EtatSysteme` avec « Réessayer », hors ligne par le bandeau de `PageShell` seul (bloc `EtatSansDonnees` seulement sans données) |
| Carte d'entrée de l'accueil | lib/CLAUDE.md (« brancher l'entrée, pas seulement la route ») | conforme | Silencieuse sans port, pendant la lecture et sans demande ; en échec, dit ce qui manque et garde le lien |
| 320 px, texte ×2, RTL | WCAG 2.2 SC 1.4.4 et 1.4.10 ; COUPE-MOTS-1 | conforme | Titres en `TexteSansCoupure`, `LigneCleValeur` empilée à 200 %, pastille sous le titre quand la ligne manque (`OverflowBar`) ; tests LTR et RTL |
| Capacité, pas rôle | invariant `CLAUDE.md` | conforme | La carte et l'écran ne lisent que le port et `peutChoisirAutreCreneau` |

## Besoin serveur (ligne Backend proposée)

Port `lib/core/offres/port_suivi_demandes.dart` : flux des demandes de créneau du foyer
connecté (une par élève concerné), avec l'étape (`envoyee`, `classe_validee`,
`enseignant_affecte`, `close`), le motif fermé de clôture (`retrait_famille`,
`offre_retiree`, `classe_non_constituee`, `refus_direction`), les jours ISO et l'heure
**en heure murale du fuseau du foyer**, le fuseau IANA du foyer, le drapeau
`personnalise`, la capacité `peut_choisir_autre_creneau`, et, à l'étape 3 seulement, le
nom d'affichage de l'enseignant et le début des cours (heure murale du foyer). Jamais de
nombre de demandeurs, d'identité d'autrui ni d'enseignant proposé non confirmé. RLS : le
foyer ne lit que ses demandes. Notification à chaque transition, titre et destination
`/tuteur/demandes` (le port des notifications existant suffit, sans modification).

## Réserves de la vérification corrigées (OFFRES-1B, 09/10/2026)

Statut : `présent dans le code` et `testé localement` (groupe « Reserves de la
verification (OFFRES-1B) » de `test/features/suivi_demandes/suivi_demandes_page_test.dart`,
chaque test rouge avant la correction et rouge de nouveau quand le défaut est remis).

| Réserve | Correction | Preuve |
| :--- | :--- | :--- |
| FAM 1 : `debutCours` lu par ses champs (`debut.hour`) sans vérifier `isUtc` ; un instant UTC aurait été affiché comme heure du foyer | Le contrat reste « heure murale du foyer ». `SuiviDemande` refuse un `DateTime` UTC (assertion en mise au point) ; en production, `heureMuraleDuFoyer` l'écarte et la carte dit « La date du premier cours s'affichera ici dès qu'elle sera fixée. » plutôt qu'une heure fausse. `debutCoursDemande` repasse par le même garde. Le constructeur n'est plus `const` (aucun appel `const` dans le dépôt) | « FAM 1 : un debut des cours en UTC est refuse au constructeur », « FAM 1 : en production, un instant UTC n affiche aucune heure » |
| FAM 2 : motif absent remplacé par `refusDirection`, faux pour un retrait de la famille | Nouvelle valeur `MotifCloture.inconnu`, repli neutre : « Cette demande est close. », pastille « Demande close », puis la suite selon la capacité (lien « Choisir un autre créneau pour … » ou « Aucun autre créneau n'est proposé pour le moment… ») | « FAM 2 : motif absent, phrase neutre et suite selon la capacite », « FAM 2 : le modele et la notification restent neutres » |
| FAM 3 : fuseau `Etc/UTC` rendu « heure d'UTC » | `deFuseau` : un identifiant du temps universel (`UTC`, `Etc/UTC`, `UCT`, `Universal`, `Zulu` et leurs formes `Etc/`) se dit « heure UTC », sans « de » ; une ville garde son « de » (« heure de Paris ») | « FAM 3 : fuseau universel, « heure UTC », jamais « heure d UTC » » |

**Port étendu.** `PortSuiviDemandes` est nouveau (créé le 09/10, aucun adaptateur serveur
ne l'emploie encore) : la valeur `inconnu` lui est ajoutée sans casser aucun appel. Ce
n'est pas un motif que le serveur doit écrire : c'est le repli du client quand le motif
est absent ou non reconnu. Ligne Contrats à relire par ChatGPT avant son adaptateur : un
motif de clôture inconnu se traduit par `inconnu`, jamais par un motif choisi à sa place ;
`debut_cours` arrive en heure murale du fuseau du foyer, jamais en instant UTC.

**Libellés ajoutés** (délégation du 02/10, rédigés par l'agent, à faire valider par le
directeur) :

- Pastille d'une demande close sans motif connu : « Demande close »
- Motif inconnu : « Cette demande est close. »
- Notification correspondante (composée, aucune clé nouvelle) : « Demande de créneau de Bilal : cette demande est close. »
- « heure UTC » : composé à partir de la clé existante `heureFuseau` (« {heure}, heure {deVille} ») ; aucune clé nouvelle.

## C-10 bis : une heure par jour (10/10/2026)

Statut : `présent dans le code` et `testé localement` (groupe « C-10 bis : une heure par
jour » de `test/features/suivi_demandes/suivi_demandes_page_test.dart`). Branche locale
`claude/c10-bis`, non poussée, non déployée.

**Défaut.** `CreneauDemande` portait une seule heure pour tous les jours, alors que le
serveur stocke `jours[]` et `heures_locales[]` en tableaux parallèles : une demande peut
avoir une heure différente selon le jour (semaine de changement d'heure, créneau
personnalisé). Un adaptateur aurait dû écraser les heures par la première.

**Contrat C-10 bis** (`lib/core/offres/port_suivi_demandes.dart`,
`lib/core/offres/occurrence_creneau.dart`) :

- `OccurrenceCreneau({required int jourIso, required int heure, int minute = 0})` :
  jour ISO 1 à 7, heure 0 à 23, minute 0 à 59, gardés par assertion ;
- `CreneauDemande({required Iterable<OccurrenceCreneau> occurrences})` : triées par jour,
  liste vide et jour en double refusés par assertion ; `occurrences` (liste non
  modifiable), `joursIso`, `heuresToutesEgales`. Aucun getter « l'heure du créneau ».
- Ligne Contrats à relire par ChatGPT avant son adaptateur : une occurrence par indice
  des deux tableaux, `jours[i]` avec `heures_locales[i]` ; jamais d'heure de repli
  prise au premier jour.

**Règle d'affichage.**

| Cas | Rendu | Règle et source | Conséquence |
| :--- | :--- | :--- | :--- |
| Toutes les heures égales | Inchangé : « Jours choisis » « Lundi, mardi et jeudi », « Heure choisie » « 18:00, heure de Paris » | Nielsen n° 4 (cohérence) ; décision du lot | Aucune régression pour le cas courant |
| Heures différentes | « Jours et heures choisis » « Lundi 18:00, mercredi 19:30 », puis « Fuseau horaire » « Heure de Paris » | WCAG 2.2 SC 1.3.1 (une valeur par ligne clé-valeur) ; COUPE-MOTS-1 | Le fuseau a sa propre ligne : une virgule de plus après la liste se serait confondue avec un jour ; jours du lundi au dimanche, chacun avec son heure |
| 320 px, texte ×2, LTR et RTL | Liste de sept jours à heures différentes sans débordement ni mot coupé | WCAG 2.2 SC 1.4.4 et 1.4.10 | `LigneCleValeur` empilée à 200 % |

**Libellés ajoutés** (`suiviDemandes`, ajoutés après `heureFuseau`, rien réordonné ;
rédigés par l'agent, à faire valider par le directeur ; déclarés dans
`tool/libelles_sources.json`) :

- « Jours et heures choisis »
- « {jour} {heure} » (« Lundi 18:00 »)
- « Fuseau horaire »
- « Heure {deVille} » (« Heure de Paris », « Heure UTC »)

**Démonstration.** Inès (étape 2) a désormais samedi 10:00 et dimanche 11:30.

**Contre-épreuve** (chaque défaut remis, tests rouges, puis annulé) :

1. Le constructeur écrase les heures par celle du premier jour → 13 rouges (dont
   « le creneau trie par jour et garde l heure de chaque jour », « heures differentes :
   chaque jour avec son heure… », « 2. classe validee… »).
2. L'écran affiche l'heure du premier jour sans vérifier qu'elles sont égales → 11 rouges.
3. Tri par jour retiré → 5 rouges.
4. Doublon de jour accepté → rouge « doublon de jour, liste vide, valeurs hors bornes :
   refuses ».
