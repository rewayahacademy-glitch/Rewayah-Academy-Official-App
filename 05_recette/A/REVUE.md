# Revue adversariale LA-R (25/09/2026)

**Synthèse** : Revue en lecture seule du diff `origin/ui/tuteur-v1...HEAD` (34 fichiers, HEAD=750aab9) et des captures. Deux synthèses de vérification apportées : lentille maquettes (2 constats), lentille honnêteté (8 constats majeurs + 5 mineurs + 1 de preuve). Aucun fichier du lot modifié lors de cette revue.

---

## Tableau des constats

| Lentille | Gravité | Fichier:Ligne | Constat | Preuve | Correction attendue |
|----------|---------|---|---|---|---|
| maquettes | bloquant | `test/capture/la2_inscription_capture_test.dart:165-210, 46-49` | Les captures des étapes 'identité' et 'genre' (8 fichiers : 390x844/1440x900, clair/sombre) et la planche 'genre, maquette \| capture' affichent en réalité l'écran 'usage' (1 sur 4), pas les étapes identité/genre. Le test monte le widget directement sur `Routes.inscriptionIdentite` / `Routes.inscriptionGenre` avec un brouillon vierge ; le garde-fou `exigerEtapesPrecedentes` redirige alors immédiatement vers `/inscription/usage` car aucune réponse d'usage n'a été saisie au préalable. Le code fonctionnel des écrans semble correct par lecture, mais aucune capture réelle de ces deux écrans n'existe, et la planche genre compare en fait la maquette du genre à l'écran usage. | Vérification par lecture d'image : `C:\RA\pilotage\05_recette\A\captures\la2_genre_390x844_light.png`, `la2_genre_1440x900_dark.png` et `la2_identite_390x844_light.png` affichent tous « 1 sur 4 / Quel type de compte souhaitez-vous créer ? » (écran usage), identiques à `la2_usage_390x844_light.png`. La planche `la2_genre_contre_maquette.png` compare la maquette 'onboarding Mble d.png' (étape genre, 2 cartes côte à côte) au même écran usage, pas à l'écran genre réel (visible dans `genre_etape.dart` : 2 CarteChoixInscription côte à côte via Row/Expanded, jamais montrées en capture). Le rapport LA-2.md et la preuve du tableau affirment à tort une conformité. | Corriger `test/capture/la2_inscription_capture_test.dart` pour atteindre réellement les étapes identité et genre avant capture (taper 'Continuer' depuis usage rempli, comme le fait déjà `monterJusquAuRecap`), reproduire les 8 captures et la planche genre\|maquette avec le vrai contenu, puis corriger le rapport et la preuve du tableau. |
| maquettes | mineur | `C:\RA\pilotage\05_recette\A\captures\la2_recapitulatif_contre_maquette.png` | La planche maquette\|capture du récapitulatif affiche à droite un rectangle CTA violet 'Créer mon compte' et le lien 'Se déconnecter' presque seuls, sans le corps de la liste visible : le rendu compare est dominé par un vide. | Observation directe : `la2_recapitulatif_contre_maquette.png` (partie droite très majoritairement vide avant le CTA) vs `la2_recapitulatif_390x844_light.png` (liste bien présente, rectangle groupe conforme). Déjà partiellement reconnu comme 'piège connu' (débordement) mais le rendu ici est une planche quasi vide. | Si le format de maquette composite déforme la taille logique au point de rendre la planche illisible, restreindre la comparaison à la portion pertinente plutôt qu'à l'image composite entière. |
| honnetete | majeur | `lib/features/parcours_offres/bloc_parcours.dart:46-53` | Quand la lecture échoue, BlocParcours n'affiche rien. Or en production, sans 0043, `parcoursFoyerProvider` lit `v_parcours_onboarding` (inexistante), la lecture échoue et le bloc disparaît sans rien dire. Aucun bouton ne mène à `/tuteur/parcours/:eleveId`, et l'état « indisponible » K5 de la page n'est atteignable que par URL. LA-4 est déclaré « fait » avec des « gestes réels » qui ne passent qu'avec FauxServiceOffres. | `bloc_parcours.dart:46-48` : `if (!parcours.hasValue) { return const SizedBox.shrink(); }`, commentaire « Idem en erreur ». `service_offres.dart:132` : `.from('v_parcours_onboarding')`. Service classe 42P01 et PGRST205 en `PanneParcours.indisponible`, mais le bloc ne regarde pas cette classe. | Si l'erreur est `PanneParcours.indisponible`, BlocParcours doit montrer une carte « questionnaire pas encore disponible » (K5), et un test doit le vérifier. Sinon, LA-4 repasse en_cours au tableau. |
| honnetete | majeur | `lib/features/parcours_offres/parcours_offres_page.dart:77-84` | Une règle métier est codée côté client : niveau `debut_lettres` donne l'objectif `apprendre_a_lire` et saute la question. Le mandat LA-4 demande « branches serveur seulement ». L'auteur écrit que 0043 ne rend aucune règle et que ce point attend confirmation du coordinateur, mais LA-4 est passé à « fait ». | `parcours_offres_page.dart:80` `bool get _debutant => _niveau == NiveauDeclare.debutLettres;` et :82-84 `_debutant ? ObjectifApprentissage.apprendreALire : ...`. Déclaration LA-4 : « Point à faire confirmer par COORD ». | Retirer la règle ou la lire depuis le serveur une fois le coordinateur d'accord. En attendant, LA-4 ne doit pas être « fait ». |
| honnetete | majeur | `lib/core/offres/service_offres.dart:115, 125` | Les appels `.order` ont bien `ascending`, mais aucun test ne vérifie le sens du tri. La définition de « fait » exige « .order avec ascending + test ». C'est vrai aussi pour `service_acceptations.dart:91` (`ascending: false`), que LA-3 déclare « vérifié » sans test. | `git grep .order(` : `service_offres.dart:115` et `:125` `.order('ordre', ascending: true)`, `service_acceptations.dart:91` `.order('accepted_at', ascending: false)`. `git grep ascending` dans test/parcours et test/features : aucun résultat. Le seul test d'ordre ne porte que sur `etapeParcours`, pas sur la requête. | Ajouter un test qui vérifie le paramètre `ascending` passé à la requête pour `langues_cours`, `cohortes_age` et `contract_acceptances`. |
| honnetete | majeur | `test/capture/la2_inscription_capture_test.dart:281-305` | LA-2 est passé à « fait » alors que deux points restent ouverts. Le test « récapitulatif, maquette \| capture » échoue (débordement de 58 px, non corrigé), et `test/accessibilite/clavier_test.dart:43-51` est rouge depuis df8c97c. Or « fait » exige que les écarts soient corrigés. | Preuve LA-2 3/3 : « 20/21 tests passés (1 échec documenté...) » et « Un écart documenté non corrigé ». demandes/A.md A-4 : « le test reste rouge ». L'échec est invisible dans une passe par défaut. | Corriger le débordement du récapitulatif ou justifier l'écart dans le test. Tant que A-4 n'est pas levée et que le débordement reste, remettre LA-2 en_cours. |
| honnetete | mineur | `lib/features/parcours_offres/bloc_parcours.dart:61` | Tant que `reglesAcademieProvider` n'a pas de valeur, le minimum vaut 0. Le bloc peut afficher « Une classe démarre à partir de 0 élèves » : une fausse information. | `bloc_parcours.dart:61` `final int minimum = regles.value?.minimumLancement ?? 0;`, puis `libelles_parcours.dart:276-277`. | Sans règle lue, afficher une phrase sans nombre au lieu d'injecter 0. |
| honnetete | mineur | `lib/features/parcours_offres/parcours_offres_page.dart:91` | Si le fuseau est inconnu, la page prend Europe/Paris, une valeur codée en dur. Les horaires sont affichés à l'heure de Paris, alors que `parcours.offresRaison` dit « affichés à votre heure locale ». | `parcours_offres_page.dart:91` `String get _fuseauVu => _fuseau ?? 'Europe/Paris';`. La valeur parcours.offresRaison est « Ces horaires sont affichés à votre heure locale. » | Utiliser le fuseau de l'appareil au lieu d'une valeur fixe, ou dire explicitement quel fuseau est utilisé. |
| honnetete | mineur | `lib/core/capacites/consentements_supabase.dart:94` | La documentation cite une mauvaise demande : elle renvoie à « la demande A-2 » pour brancher `portConsentementsProvider`. Dans demandes/A.md, A-2 est le rappel de B-3 ; c'est A-3 qui porte ce besoin. La même erreur se trouve dans `consentement_observation_page.dart:241`. | `consentements_supabase.dart:93-94`. `consentement_observation_page.dart:241`. demandes/A.md : « A-3 (25/09, LA-3) ». | Remplacer A-2 par A-3 dans les deux commentaires. |
| honnetete | mineur | `lib/features/dossier/signature_page.dart:50-51` | La variante élève adulte ne dépend que de `?pour=moi`, qui vient d'un brouillon en mémoire. Après un rechargement, un élève adulte voit la variante responsable légal. La même version est enregistrée quelle que soit la variante, donc l'accord ne correspond pas à la personne. | `signature_page.dart:50-51`. Clés `consentement.texte.caseResponsable` « J'accepte ces modalités pour mon enfant » et `caseAdulte` « J'accepte ces modalités ». Déclaration LA-3 : « Après un rechargement, le brouillon est perdu ». | Déduire la variante d'une donnée persistée plutôt que du brouillon, ou afficher une case neutre quand l'usage est inconnu. |
| honnetete | mineur | `lib/features/inscription/brouillon_inscription.dart` + `assets/i18n/fr.i18n.json:1289-1292` | Les valeurs i18n sont passées à « classe », mais les noms de clés contiennent encore « Groupe » (parcours.etatGroupeEnFormation, etatGroupeEnFormationDetail, etatGroupeConfirme, etatGroupeConfirmeDetail). La lentille interdit ce vocabulaire aussi dans les clés. | `fr.i18n.json:1289` `"etatGroupeEnFormation": "Classe en cours de constitution"`, `:1291` `"etatGroupeConfirme": "Classe confirmée"`. Règles dures : vocabulaire « Classe », pas « groupe ». | Renommer les clés (etatClasseEnFormation...), en vérifiant qu'aucun appelant hors lot A ne les utilise, ou consigner une demande au coordinateur. |
| preuve | majeur | `C:\RA\lot-a\assets\i18n\fr.i18n.json:285` (clé `connexion.recuperation.lienRefuse`) | Le texte affiche à l'utilisateur dans l'état 'connexion refusée' de l'écran de récupération (LA-1) contient le mot interdit 'session' : « Ce lien n'a pas pu ouvrir votre session. Demandez-en un nouveau ci-dessous. » Le vocabulaire imposé (« Classe », « Séance », Sayyid/Sayyida, « Interface guidée », « Ajouter un profil élève » ; interdits : « Session », « Cours en cours », « Ajouter enfant », « mode enfant », « groupe », codes internes) est violé dans un texte réellement rendu à l'écran. | Vérification directe : `C:\RA\lot-a\assets\i18n\fr.i18n.json:285` et code généré `lib/core/i18n/strings_fr.g.dart:2323` (même texte) ; utilisé dans `lib/features/connexion/recuperation_page.dart:332` via `t.connexion.recuperation.lienRefuse`. Le déclaratif LA-1 ne mentionne cette chaîne nulle part. | Reformuler sans le mot 'session', par exemple « Ce lien n'a pas pu vous connecter. Demandez-en un nouveau ci-dessous. » ou équivalent, puis relancer `dart run slang` et recommitter le généré. |

---

## Synthèses de vérification

### Synthèse 1 : Lentille maquettes, vérification des captures (lecture seule)

Revue adversariale du lot A (lentille maquettes / carte des fonctions), lecture seule, aucun fichier modifié. Vérifications faites :
- Textes exacts des cartes d'usage LA-2 : assets/i18n/fr.i18n.json:335-338, conformes au mandat.
- Lien « Je suis enseignant » présent.
- `.order(...)` avec `ascending:true` confirmé (service_offres.dart:115, 125).
- Absence de vocabulaire interdit dans les espaces de noms du lot A.
- Absence d'import de `CarteChoixFoyer` / `formulaire_profil_eleve` (conformité B-3).
- Planches LA-1 (aucune maquette dédiée, constat déjà consigné), LA-3 vs M6 (conforme), LA-4 (bloc accueil/question âge conformes par lecture).

**Défaut bloquant vérifié** : Les captures des étapes 'identité' et 'genre' de LA-2 (8 fichiers + planche) affichent l'écran 'usage' en raison du garde-fou `exigerEtapesPrecedentes`. La preuve du tableau affirme à tort une conformité vérifiée pour l'écran genre qui n'a jamais été capturé réellement.

**Défaut mineur** : La planche récapitulatif-vs-maquette est quasi vide (piège connu du format composite, mais rendu peu exploitable).

### Synthèse 2 : Lentille honnêteté, diff et structure (lecture seule)

Revue en lecture seule du diff `origin/ui/tuteur-v1...HEAD` (34 fichiers, HEAD 750aab9), lentille honnêteté.

**Ce qui est conforme** :
- Clés gelées identiques à `cefab7f` : salle.bandeauPermanent, contrat.pointEnregistrement, enseignant.profil.contratAccuse.
- Texte signé : la version signée d'origine n'est pas réécrite. Versions_contrat.dart ajoute une version 2026-09-obs.
- Case jamais précochée (_cochee = false), bouton désactivé tant qu'elle n'est pas cochée.
- Aucune acceptation présumée : un échec de lecture est affiché comme tel.
- Valeurs de visites lues depuis GuardianObservationPolicy, sans nombre codé.
- i18n : seuls les espaces de noms du lot A sont touchés.
- Aucun STUB restant dans les dossiers du lot.
- États indisponible, hors ligne et erreur présents dans la page du questionnaire.

**Défauts d'honnêteté principaux** :
- En production (0043 absent), BlocParcours se tait en cas d'erreur : l'état indisponible n'est atteignable par aucun bouton.
- La branche débutant est une règle codée côté client, alors que LA-4 est marqué « fait ».
- Aucun test ne vérifie le sens des `.order`.
- LA-2 est marqué « fait » avec un écart de maquette non corrigé et un test clavier rouge.
- Défauts mineurs : « session » à l'écran, clés « Groupe », « 0 élèves » possible, fuseau Europe/Paris codé, renvois A-2 au lieu de A-3, variante adulte perdue au rechargement.

---

## Résumé des gravités

- **Bloquant** : 1
- **Majeur** : 5
- **Mineur** : 8 (y compris preuve majeur qui est une violation de vocabulaire à l'écran)

**Heure de fin de revue** : 2026-09-25 04:10 (approx., tâche asynchrone).
