# Onboarding en petit jeu guidé par Praxis (22/11/2026)

**Statut : maquette validée par le directeur le 22/11/2026, codée par le lot ONBOARDING-PRAXIS (une PR,
brouillon), pas encore prouvée en production.** Maquette cliquable, seule référence du parcours, des textes,
des branches et des interludes : `docs/current/maquettes/onboarding-praxis/prototype.html` (version 4).
Directeur, 22/11 : « si tu rends quelque chose qui n'est pas fidèle, tu auras un problème avec moi ».
Là où ce document et la maquette diffèrent, **la maquette l'emporte**.

Remplace l'ordre des écrans de `FICHE-ONBOARDING-2026-10-29.md` §3 ; garde ses décisions (§7) : demande
envoyée avec ses apprenants, décision de la direction avant l'entrée, horaires après l'admission.

Règles tenues : « déduit > choisi > saisi » ; une question par écran ; vouvoiement (l'enfant ne répond
jamais ici) ; le Praxis de référence de l'application (`lib/core/vivant/entree/praxis_reference.dart`,
`Corps` et `peindrePraxis`, gestes `Geste` et visages `Expr` de `gestes_praxis.dart`, employés sans les
modifier ; directeur, 22/11 : « il faut ajouter les gestes ») avec le visage et le geste de la maquette à
chaque écran (salut à l'accueil et à la fin, il montre les choix, main sur le cœur à la famille et au
récapitulatif, il réfléchit au chemin, il envoie le lien), phrases courtes, jamais de reproche, ni promesse ni mot interdit (`mots-rewayah`). Point rouge
sur les champs obligatoires.

## 0. Décisions du directeur du 22/11/2026 (datées, en vigueur)

| # | Décision |
| :--- | :--- |
| D1 | **Aucune question « enseignante obligatoire »** : l'académie décide. |
| D2 | **Langues** : la liste des langues des enseignants (environ 25), groupée (les plus demandées ; Afrique ; Asie ; Europe) ; une **langue principale** (l'orientation va vers elle dès qu'un enseignant est disponible), une **langue de secours** facultative, et un champ libre « une langue absente de la liste » pour mesurer la demande. |
| D3 | **Lecture** : Hafs (présélectionnée), Warsh, « une autre lecture (à préciser) » avec un champ texte. |
| D4 | **Prénoms** : des lettres seulement (toute écriture, arabe comprise), 2 à 30 signes, ni chiffre ni émoji ; Praxis explique un refus. |
| D5 | **Adulte** : son prénom n'est jamais demandé deux fois (seulement le nom de famille à l'étape d'identité). **Parent** : l'étape d'identité s'intitule « Vous, le tuteur du compte », avec l'explication qu'il gère le compte de ses enfants. |
| D6 | **Écran final** : ne jamais redemander ce qui a été choisi ; après l'admission, il ne reste que les jours et les horaires. |
| D7 | **Frères et sœurs jamais dans la même classe** (souvent une seule tablette ; enseignants différents, pour qu'un enseignant absent n'arrête pas toute la famille). On ne le demande pas ; l'écran final le dit comme un avantage quand il y a plusieurs enfants. |
| D8 | **« Pour plusieurs enfants »** : après le premier enfant, le bouton principal dit « Ajouter l'enfant suivant ». |
| D9 | **Absence** : rattrapée seul avant la séance suivante, **avec les outils que l'académie met à disposition** (lecture enregistrée du programme, documents de la Bibliothèque). |
| D10 | **Garde « Vous venez pour apprendre, ou pour enseigner ? »** : « Enseigner » commence ici la candidature d'enseignant, sans invitation, sans doublon. |
| D11 | **Remboursement** : « remboursé dans les 14 jours, moins les séances déjà suivies ». |
| D12 | **Fuseaux horaires** (« bien travailler les fuseaux horaires, sinon ce sera dangereux ») : le fuseau IANA de l'appareil est lu et envoyé à `inscrire_titulaire` (`p_timezone`) ; le récapitulatif le dit en clair (l'heure de la personne d'abord, celle de La Mecque en second) avec « Ce n'est pas mon fuseau » (liste des fuseaux du parcours, `fuseauxProposes`) ; **aucune valeur par défaut** : s'il ne peut pas être lu, il est demandé, et la demande ne part pas sans lui. |
| D13 | **La maquette est abandonnée, l'application fait foi** (relayé par le pilote, 22/11) : chaque enfant passe par toutes ses questions à son prénom, chaque apprenant est un objet distinct, chaque prénom est à sa place (test « deux enfants » de `questionnaire_test.dart`). |

## 1. Quatre chapitres, quatre interludes (maquette v4)

| Chapitre | Écrans (une question chacun) | Interlude |
| :--- | :--- | :--- |
| (avant) | Accueil « Bienvenue chez Rewayah Academy » | |
| 1 Qui apprend | Apprendre ou enseigner · Pour qui (moi, mon enfant, plusieurs enfants) · par apprenant : prénom, âge (enfant seulement, 6 à 17), genre | **Voici votre famille** (« Enchanté » pour un adulte seul) |
| 2 Où en est le niveau | par apprenant : niveau ; lecture (si « lit déjà le Coran » ou « a mémorisé ») ; combien est mémorisé et quels juz ou sourates (si « a mémorisé », sauf « tout le Coran ») ; objectif | **Votre point de départ** |
| 3 Vos cours | langue des explications · deuxième langue (facultative) et langue absente de la liste | **Votre chemin** |
| 4 Votre demande | adresse e-mail (ou Google) · lien envoyé · identité (après la connexion) | **Voici ce que nous avons compris** (avant le compte), puis « Votre demande est en cours » |

La barre a quatre segments ; un chapitre fait est plein, le chapitre courant se remplit à la part de ses
écrans passés (le chapitre 4 compte récapitulatif, adresse, lien envoyé, identité, fin).

## 2. Écrans et réactions de Praxis

Textes exacts : clés `onboarding.*` (`assets/i18n/fr.i18n.json`), recopiées de la maquette. Chaque choix
fait réagir Praxis dans sa bulle (par exemple « 9 ans : noté. », « Mâ châ’ Allah. Quelques détails, si vous
les connaissez. »). Le niveau se dit à la bonne personne (« Je », « Il », « Elle »). L'objectif « La prière
et les invocations » n'existe que pour un enfant ; « Mémoriser » est présélectionné pour qui a déjà
mémorisé ; pour un débutant, « Mémoriser le Coran » dit « Après les bases ».

## 3. Interludes

1. **Famille** : prénoms en avatars ; « Ajouter un autre élève » (6 au plus) ; « Je suivrai aussi des cours » (le parent devient apprenant, sans âge) ; pour « Pour plusieurs enfants », « Ajouter l'enfant suivant » tant qu'il n'y a qu'un apprenant.
2. **Point de départ** : par apprenant, les quatre étapes des bases et l'examen de fin des bases ; départ **probable** surligné (débutant 1 · reconnaît les lettres 1 en révision rapide · lit lentement 2 ou 3 · lit déjà le Coran 3 ou 4 · a mémorisé 4), puis la suite selon l'objectif. Toujours « vérifié à la première séance ».
3. **Chemin** : courbe seulement pour un débutant complet, avec les durées du programme (`programme-rewayah` §3 : prévu 37 / 28 / 24 / 15 semaines, date limite 48 / 36 / 31 / 20 ; 6-9, 10-13, 14-17, 18+), « 3 séances par semaine ». Autres niveaux : « durée précisée après la vérification ». Rigueur : même enseignant, absence rattrapée seul avec les outils de l'académie (D9). Jours et horaires après l'acceptation.
4. **Récapitulatif** : une fiche par apprenant, langue (et langue de secours), fuseau déduit de l'appareil quand il est connu, « Comment avez-vous connu Rewayah ? » (facultatif), puis : la direction lit chaque demande ; remboursement (D11) ; réponses corrigeables après l'acceptation.

## 4. Garde « enseignant » (D10)

« Enseigner » ouvre l'écran « Votre candidature d'enseignant » ; « Commencer ma candidature » prend le
**chemin existant du candidat sans invitation** (CAND-04) : la marque du candidat
(`retenirInvitationEnCours(candidature: true)`), puis `/connexion?mode=creer&candidature=1`, puis l'écran
du code qui, quand le serveur ouvre l'inscription sans code (`ouverture_inscription_candidat`), passe de
lui-même à l'identité et crée la candidature par `inscrire_candidat`. Aucun apprenant n'est créé, aucune
demande d'élève ; le questionnaire ne garde rien de ce chemin. **Limite** : si le serveur n'ouvre pas
l'inscription sans code, l'écran du code le dit (« pas encore ouvertes ») et propose le code ; aucun
compte élève n'est créé pour autant. Le refus serveur `deja_candidat_enseignant` (une demande élève sur un
compte candidat) n'est **pas** codé : lot de suite.

## 5. Où va chaque réponse

Migration `supabase/migrations/20261130979000_onboarding_praxis.sql` (additive, aucun mot d'effacement) ;
scénario `supabase/tests/scenarios_onboarding_praxis.sql`.

| Réponse | Colonne | Valeurs |
| :--- | :--- | :--- |
| Lecture | `candidature_apprenants.riwaya`, `riwaya_autre` | `hafs`, `warsh`, `autre` ; texte de 1 à 40 seulement avec `autre` ; seulement si « lit déjà le Coran » ou « a mémorisé » |
| Combien | `…memorise_quantite` | `quelques_sourates`, `1_5_juz`, `plus_5_juz`, `coran_entier` ; seulement si « a mémorisé » |
| Détail | `…juz smallint[]`, `…sourates text[]` | juz 1 à 30 ; les 17 sourates des bases par code (`fatiha` … `zalzala`) ; jamais avec « tout le Coran » |
| Prière | `…objectif_priere boolean` | « La prière et les invocations », enfant seulement ; `objectif` reste nul (le CHECK d'`objectif` n'est pas réécrit : aucun mot d'effacement) |
| Langue | `…langue_demandee` ; `langue_code` | le code choisi (langues des enseignants) ; `langue_code` (référentiel des classes) n'est rempli que si le code y est |
| Secours | `…langue_secours` | facultative, différente de la langue choisie |
| Absente | `…langue_autre` | texte libre, 1 à 40 |
| Source | `candidatures.source_declaree` | `mosquee`, `proche`, `reseaux`, `recherche`, `autre`, facultative |
| Fuseau | `profiles.timezone` (`p_timezone`) | fuseau IANA lu sur l'appareil ou choisi (D12) ; jamais Europe/Paris par défaut |

`inscrire_titulaire` reçoit `p_source` (8e paramètre ; la forme à sept paramètres est mise de côté dans
`private`, comme au lot B) ; `lister_demandes_admission` rend les nouveaux champs. `moments` quitte
l'onboarding (colonne gardée, vide).

## 6. Après la connexion

Un seul écran : « Votre nom de famille » pour l'adulte (et le parent qui suit des cours), « Vous, le tuteur
du compte » (prénom, nom, genre) pour le parent qui ne suit pas de cours ; « Envoyer ma demande ». Puis
« Votre demande est en cours » : la direction lit ; profils créés sans rien ressaisir ; il ne reste que les
jours et les horaires (D6) ; avec plusieurs enfants, chacun aura sa classe et son enseignant (D7).
« Suivre ma demande » mène à la page d'attente.

## 7. Points ouverts

1. **Placement des non-débutants** : la correspondance niveau vers étape est une proposition ; aucune règle écrite (`programme-rewayah`). À valider par l'architecte pédagogique.
2. **Warsh** : aucune classe n'est prévue au programme. On le note ; on ne le promet pas.
3. **Remboursement de 14 jours** : texte du directeur (D11) ; la règle elle-même reste à harmoniser (`A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`).
4. **Lien ouvert sur un autre appareil (FN-111)** : non résolu ; le code à six chiffres du message reste la voie (`SaisieCodeCourriel`). Brouillon côté serveur : lot de suite.
5. **Adolescent de moins de 18 ans seul** : orienté vers un parent (« Choisissez « Pour mon enfant » »).
6. **`?ref=`** : absent de `main` à ce jour ; la question de la source est donc toujours posée.
7. **Soussou** : langue déclarée par les candidats enseignants mais absente de la maquette ; non affichée, par fidélité. À trancher.
8. **Affichage des nouveaux champs côté direction** : le serveur les rend ; l'écran de la direction ne les montre pas encore (lot de suite).
