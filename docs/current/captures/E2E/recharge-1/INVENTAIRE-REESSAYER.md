# RECHARGE-1 : inventaire des « Réessayer » et « Recharger » (03/11/2026)

Lecture statique de `lib/` (hors `*.g.dart`, `_dev`, `demo`), faite le 03/11/2026 sur `main` e31b629d.
Elle n'a rien exécuté. Ce qui suit l'inventaire a été corrigé dans la PR RECHARGE-1, avec un test
rouge avant et vert après pour chaque correction, sauf mention contraire.

| Site | Verdict de l'inventaire | Dans cette PR |
|---|---|---|
| `core/router/page_differee.dart` (63 écrans chargés à la demande) | FICTIF après un déploiement, et « hors ligne » à tort | Corrigé : échec classé ; « Recharger » après un déploiement ; retour du réseau qui relance ; test et robot |
| `admin_pedagogie_diagnostics/diagnostics_page.dart:123` | FICTIF (invalide le dérivé, la source garde son erreur) | Corrigé : invalide `versionsProgrammeProvider` ; test rouge avant (1 appel), vert après |
| `foyer/formulaire_profil_eleve.dart:398` | FICTIF (relit la session en mémoire) | Corrigé : redemande la session (`rafraichir`), comme `PageHorsLigne` ; test rouge avant, vert après |
| `salle_seance/resultat_seance.dart:371, :418` | FICTIF, ne peut pas aboutir | Corrigé : le bouton disparaît, la phrase dit où remplir le cahier ; test à 1440 et 390 |
| `salle_enseignant/page_coran_salle.dart:121` | DOUTEUX (sources en cache) | Corrigé : relit les quatre sources ; test rouge avant, vert après |
| `accueil_eleve/accueil_accessibilite.dart:276` | FICTIF en ligne | Corrigé : relit aussi les données de l'accueil. **Non testé** (scénario lourd) ; l'alignement `seanceParServeur` reste à arbitrer |
| `core/router/etats_routeur.dart:261` et `:158` | DOUTEUX | **Non corrigé** : changer la relance de session est une décision (voir plus bas) |
| `salle_seance/salle_seance.dart:3207`, `surface_page_fixe.dart:531/1066` | ABSENT en production | Non corrigé : aucun bouton n'est rendu en production |
| Environ 100 sites RÉELS sans indicateur d'attente | RÉEL, sans retour visuel | Non corrigé : hors périmètre, cause probable d'un « sans effet » perçu |

## Rapport de l'inventaire, tel quel

## Ce qui est faux ou n'est pas prouvé

Quatre « Réessayer » ne font rien d'utile en production (FICTIF), deux autres sont DOUTEUX. Je ne sais pas lequel le directeur a vu. Le plus probable : l'accueil de l'élève en Interface guidée (`accueil_accessibilite.dart:276`). Il y a aussi une cause plus large : beaucoup de « Réessayer » relancent bien la lecture, mais l'écran ne montre aucune attente pendant la relecture. Si le serveur échoue encore, l'écran reste identique, et le bouton paraît sans effet.

Limites de l'analyse : elle est statique. Je n'ai rien exécuté, ni test, ni build, et rien n'a été vérifié en production. Les FICTIF, DOUTEUX, ABSENT et N/A, ainsi que les sites particuliers, je les ai lus à la main. Pour environ 200 lignes RÉEL du type `ref.invalidate(X)`, la vérification est automatique et je ne les ai pas toutes relues une à une. Elle contrôle trois choses : X est bien lu par `ref.watch(X)` dans le même fichier, avec les mêmes arguments de famille ; X ne dépend d'aucun provider asynchrone non invalidé ; aucun nom de fonction locale n'est en double. Elle a retrouvé tous les cas « dérivé » listés ci-dessous. Aucun site n'est resté « non suivi ».

Hors périmètre : `lib/features/_dev/**` (galerie), `lib/features/demo/**` (désactivés en production), `page_differee.dart`, les boutons de navigation pure (« Retour », « Effacer les filtres ») et les « Recharger » qui veulent dire « recharger mon solde », c'est-à-dire aller vers un paiement (`foyer_page:636`, `finances_foyer:130`, `soldes_foyer:201`, `compte/paiements_page:132`, `mes_finances_page:88`).

Rappel Riverpod 3 utile ici : aucune règle `retry` globale dans `main.dart`. Les FutureProvider se relancent donc seuls (10 essais, environ 40 s), sauf ceux qui portent `retry: null`. Invalider un provider dérivé A ne relit pas sa source B en erreur : `ref.watch(B.future)` rend l'erreur gardée en cache.

## FICTIF et DOUTEUX : le code exact à changer

**1. FICTIF : `lib/features/admin_pedagogie_diagnostics/diagnostics_page.dart:123`, écran Diagnostics de la direction.**
- `versionActiveProgrammeProvider` attend `versionsProgrammeProvider.future`. Ce provider n'est pas autoDispose et porte `retry: null` (`core/admin/service_programme.dart:311-316`).
- Le bouton invalide le provider dérivé. Celui-ci relit l'erreur gardée de la source, et l'échec reste affiché.
```dart
// avant
onReessayer: () => ref.invalidate(versionActiveProgrammeProvider),
// après (le dérivé se recalcule, l'import est déjà là)
onReessayer: () => ref.invalidate(versionsProgrammeProvider),
```

**2. FICTIF dans un cas : `lib/features/accueil_eleve/accueil_accessibilite.dart:276`, relayé par la carte de séance (l. 424, `carte_session.dart:562/569`). Écran : accueil de l'élève en Interface guidée.**
- La `CarteSession` de la l. 414 ne passe pas `seanceParServeur`, qui vaut donc `false`.
- Quand la fenêtre est ouverte et que la séance n'est pas encore créée (`horloge_classe` rend alors `session_id` nul, voir `horloge_supabase.dart:101-112`), l'emplacement passe en « accès invérifiable » avec « Réessayer » (`emplacement_entree.dart:160-172`).
- Le bouton ne relit que `horsLigneProvider`, l'état du réseau. Il ne relit jamais `donneesAccueilAccessibiliteProvider`.
- Hors ligne, en revanche, le même bouton est réel.
```dart
// l. 276, avant
onReessayer: () => ref.invalidate(horsLigneProvider),
// après
onReessayer: () => ref
  ..invalidate(horsLigneProvider)
  ..invalidate(donneesAccueilAccessibiliteProvider),
```
Point à faire arbitrer, car il change le comportement : le même état retire aussi « Rejoindre ». `espace_groupe_page.dart:266` passe `seanceParServeur: onRejoindre != null` et `fiche_groupe_page.dart:599` passe `true`. L'aligner ici ajouterait `seanceParServeur: onRejoindre != null,` à `CarteSession(` (l. 414).

**3. FICTIF : `lib/features/foyer/formulaire_profil_eleve.dart:398`, sites l. 405 (echecServeur) et l. 415 (EtatSansDonnees, hors ligne). Écran : ajout d'un profil élève.**
- `porteAjoutProfilProvider` (l. 37) est un `Provider` synchrone qui lit seulement `sessionProvider.porte`.
- L'invalider relit le même état en mémoire. Rien n'est redemandé au serveur, ni le profil ni la session.
```dart
// avant
void relire() => ref.invalidate(porteAjoutProfilProvider);
// après (même geste que PageHorsLigne, etats_routeur.dart:123-138)
void relire() => unawaited(() async {
  try {
    await ref.read(sourceSessionProvider).rafraichir();
  } on Object {
    // reste sur l'état affiché
  }
}());
```
Import à ajouter : `sourceSessionProvider` (`core/session/session_controleur.dart`, déjà importé). `dart:async` est déjà importé.

**4. FICTIF, le bouton ne peut pas aboutir : `lib/features/salle_seance/resultat_seance.dart:371` et `:418`. Écran : fin de séance de l'enseignant, « cahier indisponible ».**
- Le libellé devient « Réessayer », mais l'action est `_ouvrirCahier` (`salle_page.dart:1028`).
- Elle refait `findMatch` sur la même configuration de routes (`cheminCahierOuvrable`, l. 4387). Le résultat est toujours le même.
- Correction : ne plus remplacer le libellé par `t.commun.reessayer` quand `cahierIndisponible`. Masquer l'action « cahier » et garder « Revenir à la journée ».

**5. DOUTEUX : `lib/features/salle_enseignant/page_coran_salle.dart:121`. Écran : Coran dans la salle, côté enseignant.**
- `pageMushafProvider` lit les `AsyncValue` de `pageCorpusProvider`, `layoutPageProvider`, `souratesCoranProvider` et `disponibiliteLayoutProvider` (`core/tc_coran/moteur_mushaf.dart:48-74`).
- Le bouton n'invalide que `pageMushaf` et la police. Après les 10 essais automatiques des sources, il ne relit plus rien.
```dart
onAction: () {
  ref
    ..invalidate(policeMushafDisponibleProvider)
    ..invalidate(pageCorpusProvider(numero))
    ..invalidate(layoutPageProvider(numero))
    ..invalidate(souratesCoranProvider)
    ..invalidate(disponibiliteLayoutProvider);
},
```

**6. DOUTEUX : `lib/core/router/etats_routeur.dart:261`. Écran : démarrage, « La connexion prend plus de temps que prévu ».**
- `_relancer` appelle `rafraichir()`. Il ne fait rien sans session courante (`source_session.dart:56`), ni en session agent (`source_session_agent.dart:37`).
- Sinon, l'événement d'authentification n'est traité qu'après la fin de la lecture en cours (`etats()` est séquentiel, borné par `demarrageMax`).
- À faire arbitrer : `ref.invalidate(sessionProvider)` relancerait tout de suite la résolution, mais remettrait la session à zéro. Je ne propose pas de patch sans décision.
- Même réserve pour la l. 158 (`PageHorsLigne`), sinon RÉEL. La nature horsLigne y sert aussi pour un délai serveur dépassé (`LectureProfil.injoignable` vient d'un `on Object` qui inclut `TimeoutException`).

**Absents en production, pas fictifs mais à annoncer :**
- `salle_seance/salle_seance.dart:3207`, bloc « échec de connexion » de la salle : `onReessayerConnexion` n'est fourni que par la démo, jamais par `salle_page.dart:1295/1753`. Le bloc n'a donc aucun « Réessayer » en production.
- `salle_seance/surface_page_fixe.dart:531/1066`, « support reçu » : `PorteeSupportRecu` n'est posé que par `demo_salle_page.dart:1024`. Pas de bouton en production.

**Réel mais sans retour visuel, cause transversale probable du « sans effet » :**
- Après `invalidate`, l'AsyncValue repasse en chargement en gardant `hasError`. Les écrans qui testent `hasError` d'abord, ou qui utilisent `.when()`, gardent l'erreur affichée, et le bouton ne montre aucune attente (`actionEnCours` n'est pas fourni).
- Exemples : `compte/compte_page.dart:503/558` (`.when`), `bienvenue_page:141`, `regles_page:64`, `fonctionnalites_page:58`, `conservation_donnees_page:61`, `entree_observation_page:277`, `cahier_page:327` (via `vue_cahier.dart:77`), `profil_enseignant_page:139/689`, `protection_enfants_page:101/122`, `mes_groupes_page:71`, `mes_classes_page:176`, `demandes_page:157`, `groupes_page:697`, `plages_disponibilite:102`.
- Environ 100 sites hors `BlocAsynchrone` n'ont aucun indicateur d'attente. `BlocAsynchrone` et `ChargementAvecDelais` en ont un (`_echec(enCours: v.isLoading)`).

## Composants génériques (contrôlés, réels)
- `core/widgets/bloc_asynchrone.dart:213/284` : `_reessayer` limite à 3 pressions, réarme les minuteries puis appelle `onReessayer`. Réel.
- `chargement_avec_delais.dart:128` : même logique. Réel.
- `vue_etat_communication.dart:116/155/166/262/273`, `etat_systeme.dart:111/290`, `reseau/etat_sans_donnees.dart:61`, `selecteur_personne.dart:207/212` : relais purs. Leur verdict est celui de l'appelant.
- `EtatSansDonnees` et `EtatSysteme.sansDonnees` n'apparaissent que si `horsLigne` vaut vrai. Aucun cas trouvé où la nature horsLigne sert à une erreur sans rapport avec le réseau, sauf la réserve de `etats_routeur:158`.

## Tableau complet

Abréviations : ES = echecServeur, HL = horsLigne, CP = chargementProlonge, Bloc = `BlocAsynchrone` ou dérivé (ES, CP et erreur typée), inv = `ref.invalidate`. RELAIS = callback reçu d'un parent ; son verdict est celui de la ligne source du même fichier (`onReessayer:`/`_relire`). N/A prod = le provider rend toujours `CapaciteIndisponible`, ou ne peut pas échouer, donc le bouton n'est jamais rendu.


| Fichier:ligne (sous lib/features sauf core/) | Écran | Nature | Action | Verdict | Correction |
|---|---|---|---|---|---|
| tc_espace_groupe/carte_session.dart:272 | carte_session | HL/lecture/accès | relais | RELAIS | |
| tc_espace_groupe/bloc_cartes_classe.dart:159 | bloc_cartes_classe | HL | inv(cartesClasseProvider) | RÉEL | |
| tc_espace_groupe/bloc_cartes_classe.dart:164 | bloc_cartes_classe | Bloc | inv(cartesClasseProvider) | RÉEL | |
| tc_espace_groupe/espace_groupe_page.dart:254 | espace_groupe | HL/lecture/accès | relais | RELAIS | |
| tc_espace_groupe/espace_groupe_page.dart:338 | espace_groupe | erreur | inv(groupeProvider) | RÉEL | |
| tc_espace_groupe/espace_groupe_page.dart:391 | espace_groupe | HL/lecture/accès | inv(horlogeGroupeProvider, horsLigneProvider) | RÉEL | |
| admin_pedagogie_bibliotheque/porte_bibliotheque.dart:78 | porte_bibliotheque | HL | inv(capacitesBibliothequeProvider) | RÉEL | |
| admin_pedagogie_bibliotheque/porte_bibliotheque.dart:84 | porte_bibliotheque | ES | idem | RÉEL | |
| admin_pedagogie_bibliotheque/porte_bibliotheque.dart:90 | porte_bibliotheque | ES (tentative perdue) | idem | RÉEL | |
| admin_pedagogie_bibliotheque/attribution/attribution_page.dart:271 | attribution | ES (perdue) | _charger() (port) | RÉEL | |
| admin_pedagogie_bibliotheque/attribution/attribution_page.dart:290 | attribution | HL | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/attribution/attribution_page.dart:296 | attribution | ES | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/attribution/attribution_page.dart:341 | attribution | conflit « Recharger » | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/publication/publication_page.dart:276 | publication | ES (perdue) | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/publication/publication_page.dart:295 | publication | HL | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/publication/publication_page.dart:301 | publication | ES | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/publication/publication_page.dart:355 | publication | erreur (_Droits) | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/publication/publication_page.dart:518 | publication | conflit « Recharger » | relais (_charger) | RÉEL | |
| admin_pedagogie_bibliotheque/catalogue/catalogue_page.dart:274 | catalogue biblio | ES (perdue) | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/catalogue/catalogue_page.dart:291 | catalogue biblio | HL | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/catalogue/catalogue_page.dart:297 | catalogue biblio | ES | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/catalogue/catalogue_page.dart:357 | catalogue biblio | page suivante en échec | _pageSuivante() | RÉEL | |
| admin_pedagogie_bibliotheque/fiche/fiche_page.dart:231 | fiche support | ES (perdue) | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/fiche/fiche_page.dart:258 | fiche support | HL | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/fiche/fiche_page.dart:264 | fiche support | ES | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/fiche/fiche_page.dart:313 | fiche support | erreur (_Edition) | _charger() | RÉEL | |
| admin_pedagogie_bibliotheque/fiche/fiche_page.dart:614 | fiche support | conflit « Recharger » | relais (_charger) | RÉEL | |
| journee/journee_page.dart:242 | Journée enseignant | erreur | inv(seancesEnseignantProvider) | RÉEL | |
| journee/journee_page.dart:836 | Journée (entrée) | HL/lecture/accès | inv(seancesEnseignantProvider) | RÉEL | |
| journee/journee_page.dart:1155 | Journée (cahiers) | erreur | inv(cahiersEnRetardProvider) | RÉEL | |
| journee/journee_page.dart:1208 | Journée (alertes) | erreur | inv(seancesEnseignantProvider) | RÉEL | |
| journee/journee_page.dart:1240 | Journée (alertes) | présence illisible | inv(presenceSeanceProvider(enDirect.id)) | RÉEL | |
| journee/journee_page.dart:1293 | Journée | erreur | relais | RELAIS | |
| journee/journee_page.dart:1322 | Journée | HL | relais | RELAIS | |
| journee/journee_page.dart:1329 | Journée | ES | relais | RELAIS | |
| journee/journee_page.dart:1493 | Journée | lecture partielle | relais (inv règles prière, pause, cahiersEnRetard) | RÉEL | |
| suivi_eleve/suivi_eleve_page.dart:87 | Suivi élève | erreur | inv(seancesDeMonSuiviProvider, presenceDuSuiviProvider) | RÉEL | |
| suivi_eleve/suivi_eleve_page.dart:116 | Suivi élève | erreur | relais | RELAIS | |
| suivi_eleve/suivi_eleve_page.dart:144 | Suivi élève | erreur | relais | RÉEL | |
| admin_configuration_politique_kyc/politique_revue_kyc_page.dart:172 | Politique KYC | HL | inv(politiqueRevueKycProvider) | RÉEL | |
| admin_configuration_politique_kyc/politique_revue_kyc_page.dart:176 | Politique KYC | ES | idem | RÉEL | |
| avis_public/avis_public_page.dart:347 | Avis public | Bloc | inv(avisLienOuvertProvider(jeton)) | RÉEL | |
| avis_public/avis_public_page.dart:363 | Avis public | HL | relais | RELAIS | |
| avis_public/avis_public_page.dart:369 | Avis public | ES | relais | RELAIS | |
| suivi_famille/suivi_famille_page.dart:123 | Suivi famille | Bloc | inv(frisesDemandesProvider) (Stream) | RÉEL | |
| suivi_famille/suivi_famille_page.dart:129 | Suivi famille | HL | relais | RELAIS | |
| suivi_famille/suivi_famille_page.dart:135 | Suivi famille | ES | relais | RELAIS | |
| admin_pedagogie_programmes/programmes_page.dart:90 | Programmes | Bloc | inv(versionsProgrammeProvider) | RÉEL | |
| admin_pedagogie_programmes/programmes_page.dart:345 | Programmes | Bloc | inv(niveauxProgrammeProvider(version.id)) | RÉEL | |
| ma_classe_adulte/ma_classe_adulte_page.dart:177 | Ma classe (adulte) | HL | inv(maClasseAdulteProvider) | RÉEL | |
| ma_classe_adulte/ma_classe_adulte_page.dart:182 | Ma classe (adulte) | Bloc | idem | RÉEL | |
| admin_observations/observations_admin_page.dart:311 | Observations (direction) | ES | _recharger() | RÉEL | |
| admin_traitement/traitement_page.dart:167 | Traitement | erreur | inv(dossiersEnAttenteProvider, demandesProvider) | RÉEL | |
| admin_traitement/traitement_page.dart:276 | Traitement | ES | idem | RÉEL | |
| cahier/cahier_page.dart:327 | Cahier | erreur | inv(brouillonCahierProvider(seanceId)) | RÉEL (sans retour visuel) | |
| cahier/selecteur_reprise.dart:215 | Sélecteur de reprise | Bloc | inv(souratesCoranProvider) | RÉEL | |
| cahier/selecteur_reprise.dart:220 | Sélecteur de reprise | ES | relais | RELAIS | |
| tc_catalogue/surface_bibliotheque.dart:257 | Bibliothèque de classe | erreur | inv(donneesCatalogueProvider(groupeId)) | RÉEL | |
| tc_catalogue/rendu_ressource.dart:195 | Rendu ressource | échec d'ouverture | _ouvrir() | RÉEL | |
| tc_catalogue/rendu_ressource.dart:259 | Rendu ressource (image) | erreur de décodage | inv(_imageProvider(versionId)) | RÉEL | même résultat probable |
| tc_catalogue/rendu_ressource.dart:270 | Rendu ressource | image introuvable | idem | RÉEL | même résultat probable |
| tc_catalogue/rendu_ressource.dart:275 | Rendu ressource | erreur | idem | RÉEL | |
| tc_catalogue/rendu_ressource.dart:306 | Rendu ressource | relais `_Echec` | relais | RÉEL | |
| tc_catalogue/detail_ressource_page.dart:85 | Détail ressource | erreur | inv(detailRessourceProvider(id)) | RÉEL | |
| tc_catalogue/support_actif/support_actif_classe.dart:70 | Support actif | HL | inv(supportActifProvider(seanceId)) (Stream) | RÉEL | |
| tc_catalogue/support_actif/support_actif_classe.dart:76 | Support actif | ES | idem | RÉEL | |
| admin_journal/journal_page.dart:221 | Journal | erreur | _recharger() | RÉEL | |
| admin_journal/journal_page.dart:444 | Journal | erreur | relais (onReessayer, puis _recharger) | RÉEL | |
| admin_journal/incidents_page.dart:65 | Incidents | Bloc | inv(incidentsSeancesProvider) | RÉEL | |
| admin_journal/incidents_page.dart:88 | Incidents | HL | relais | RELAIS | |
| admin_journal/incidents_page.dart:94 | Incidents | ES | relais | RELAIS | |
| creneaux/plages_disponibilite.dart:102 | Disponibilités | erreur | inv(monFuseauProvider, disponibilitesProvider(monId)) | RÉEL | |
| alertes/section_alertes.dart:67 | Section alertes | HL | inv(alertesProvider) (Stream) | RÉEL | |
| alertes/section_alertes.dart:72 | Section alertes | Bloc | idem | RÉEL | |
| remplacements/remplacements_page.dart:225 | Remplacements | Bloc | inv(offresCommunesProvider) (Stream) | RÉEL | |
| remplacements/remplacements_page.dart:238 | Remplacements | HL | relais | RELAIS | |
| remplacements/remplacements_page.dart:244 | Remplacements | ES | relais | RELAIS | |
| admin_candidatures/candidatures_page.dart:595 | Candidatures | HL | relais | RELAIS | |
| admin_candidatures/candidatures_page.dart:604 | Candidatures | ES | relais | RELAIS | |
| admin_candidatures/candidatures_page.dart:736 | Candidatures | Bloc | inv(capacitesCandidaturesProvider, pageCandidaturesProvider) | RÉEL | |
| tc_mes_groupes/mes_groupes_page.dart:71 | Mes groupes | erreur | inv(mesGroupesProvider) | RÉEL | |
| bienvenue_enseignant/bienvenue_page.dart:141 | Bienvenue enseignant | erreur | inv(profilEnseignantProvider) | RÉEL (sans retour visuel) | |
| paiements_recus/recevoir_paiements_page.dart:206 | Recevoir paiements | Bloc | inv(mesMoyensPaiementProvider) | RÉEL | |
| paiements_recus/recevoir_paiements_page.dart:211 | Recevoir paiements | HL | relais | RELAIS | |
| paiements_recus/recevoir_paiements_page.dart:407 | Recevoir paiements | Bloc | inv(journalMesMoyensProvider) | RÉEL | |
| admin_invitations/invitations_page.dart:377 | Invitations | Bloc | inv(_liste(role)) (provider affiché, l. 268) | RÉEL | |
| admin_invitations/invitations_page.dart:398 | Invitations | HL | relais | RELAIS | |
| admin_invitations/invitations_page.dart:404 | Invitations | ES | relais | RELAIS | |
| admin_invitations/invitations_familles.dart:174 | Invitations familles | Bloc | inv(famillesImporteesProvider) | RÉEL | |
| admin_invitations/invitations_familles.dart:196 | Invitations familles | HL | relais | RELAIS | |
| admin_invitations/invitations_familles.dart:202 | Invitations familles | ES | relais | RELAIS | |
| dossier/attente_page.dart:145 | Portail d'attente | dossier illisible | inv(etatDossierProvider) | RÉEL | |
| dossier/accords_page.dart:224 | Accords | dossier illisible | inv(etatDossierProvider) | RÉEL | |
| dossier/accords_page.dart:577 | Accords (contrat) | ES | inv(contratEnseignantCourantProvider, maSignatureEnseignantProvider) | RÉEL | |
| dossier/accords_page.dart:586 | Accords (texte altéré) | ES | inv(contratEnseignantCourantProvider) | RÉEL | |
| enseignant_classes/mes_classes_page.dart:176 | Mes classes | erreur | inv(groupesEnseignantProvider) | RÉEL | |
| accueil_famille/accueil_famille_page.dart:151 | Accueil famille | Bloc | inv(elevesDuFoyerProvider) (la source de profilsElevesFoyer) | RÉEL | |
| accueil_famille/accueil_famille_page.dart:400 | Accueil famille | erreur | inv(derniereSeanceProvider(eleveId)) | RÉEL | |
| accueil_famille/ligne_derniere_seance.dart:73 | Accueil famille | erreur | relais | RÉEL | bouton montré même sur CapaciteIndisponible |
| accueil_famille/carte_classe_seance.dart:114 | Accueil famille | erreur | relais | RELAIS | |
| accueil_famille/carte_classe_seance.dart:124 | Accueil famille | erreur | relais | RELAIS | |
| accueil_famille/carte_classe_seance.dart:232 | Accueil famille | erreur | relais (inv(classeDeLEleveProvider)) | RÉEL | |
| accueil_famille/carte_classe_seance.dart:321 | Accueil famille | erreur | relais (inv(prochaineSeanceProvider)) | RÉEL | |
| classe_tuteur/carte_seance_classe.dart:168 | Classe (tuteur) | erreur | relais (inv(prochaineSeanceProvider), classe_tuteur_page:147) | RÉEL | |
| classe_tuteur/catalogue_classes_page.dart:262 | Catalogue des classes | Bloc | inv(elevesDuFoyerProvider) | RÉEL | |
| classe_tuteur/catalogue_classes_page.dart:323 | Catalogue des classes | Bloc | inv(classesProposeesProvider(eleveId)) | RÉEL | |
| classe_tuteur/catalogue_classes_page.dart:645 | Catalogue des classes | envoi | onConfirmer | RÉEL | |
| classe_tuteur/progression_classe_page.dart:86 | Classe : progression | Bloc | inv(progressionEleveProvider(eleveId)) | RÉEL | |
| classe_tuteur/contexte_classe.dart:170 | Classe (tuteur) | Bloc | inv(elevesDuFoyerProvider, contexteClasseProvider(cle)) | RÉEL | |
| classe_tuteur/contexte_classe.dart:296 | Classe (LectureClasse) | Bloc | relais | RELAIS | |
| classe_tuteur/ressources_classe_page.dart:83 | Classe : ressources | Bloc | inv(ressourcesClasseProvider) | RÉEL | |
| classe_tuteur/planning_classe_page.dart:162 | Classe : planning | Bloc | inv(planningClasseProvider(cle)) | RÉEL | |
| classe_tuteur/travail_classe_page.dart:125 | Classe : travail | Bloc | inv(travailClasseProvider(cle)) | RÉEL | |
| classe_tuteur/bloc_observation_classe.dart:197 | Classe : observation | réseau | inv(budgetObservationProvider(seanceId)) | RÉEL | |
| classe_tuteur/bloc_observation_classe.dart:301 | Classe : observation | réseau | relais | RÉEL | |
| controleur/controle_page.dart:85 | Contrôle | ES | inv(missionControleProvider) | N/A prod | le provider rend toujours null |
| controleur/historique_controleur_page.dart:217 | Historique contrôleur | Bloc (valeur locale) | _charger() | RÉEL | |
| controleur/echanges_controleur_page.dart:113 | Échanges contrôleur | Bloc | _chargerListe() | RÉEL | |
| controleur/echanges_controleur_page.dart:151 | Échanges contrôleur | Bloc | _ouvrir(mission) | RÉEL | |
| controleur/observation_controle_page.dart:532 | Observation contrôle | erreur roster | inv(rosterControleProvider(seanceId)) | RÉEL | |
| controleur/compte_rendu_controle_page.dart:518 | Compte rendu contrôle | envoi | transmettreVisiteATerminer() | RÉEL | |
| controleur/complement_rapport_page.dart:256 | Complément rapport | envoi | _envoyer | RÉEL | |
| admin_suppressions/suppressions_page.dart:212 | Suppressions | Bloc | inv(suppressionsAdminProvider) | RÉEL | |
| admin_suppressions/suppressions_page.dart:242 | Suppressions | HL | relais | RELAIS | |
| admin_suppressions/suppressions_page.dart:248 | Suppressions | ES | relais | RELAIS | |
| fiche_groupe/fiche_groupe_page.dart:248 | Fiche groupe | erreur | inv(groupesEnseignantProvider, membresGroupeEnseignantProvider) | RÉEL | |
| fiche_groupe/fiche_groupe_page.dart:567 | Fiche groupe (horloge) | erreur | inv(horlogeClasseLueProvider, horlogeGroupeProvider) | RÉEL | |
| fiche_groupe/fiche_groupe_page.dart:591 | Fiche groupe (carte) | HL/lecture/accès | inv(horsLigne, horlogeGroupe, horlogeClasseLue) | RÉEL | |
| fiche_groupe/bloc_pause_classe.dart:151 | Pause de classe | Bloc | inv(reglagePauseProvider) | RÉEL | |
| fiche_groupe/fiche_eleve_enseignant.dart:684 | Fiche élève (enseignant) | envoi | _envoyer | RÉEL | |
| admin_tirage/tirage_page.dart:126 | Tirage | HL | relais | RELAIS | |
| admin_tirage/tirage_page.dart:132 | Tirage | ES | relais | RELAIS | |
| admin_tirage/tirage_page.dart:155 | Tirage | Bloc | inv(accesTirage, reglesTirage, pageTirages) | RÉEL | |
| admin_tirage/tirage_page.dart:382 | Tirage | Bloc | inv(reglesTirageProvider) | RÉEL | |
| admin_tirage/tirage_page.dart:387 | Tirage | HL | relais | RELAIS | |
| admin_tirage/tirage_page.dart:393 | Tirage | ES | relais | RELAIS | |
| admin_tirage/tirage_page.dart:698 | Tirage | Bloc | inv(candidatsCibleProvider) | RÉEL | |
| admin_tirage/tirage_page.dart:712 | Tirage | HL | relais | RELAIS | |
| admin_tirage/tirage_page.dart:718 | Tirage | ES | relais | RELAIS | |
| admin_tirage/tirage_page.dart:886 | Tirage | Bloc | relais (_relire, l. 98) | RELAIS | |
| suivi_foyer/bloc_compte_rendu.dart:85 | Compte rendu famille | Bloc | inv(compteRenduFamilleProvider(cle)) | RÉEL | |
| suivi_foyer/bloc_compte_rendu.dart:95 | Compte rendu famille | erreur | relais | RELAIS | |
| suivi_foyer/suivi_foyer_page.dart:141 | Suivi foyer | ES | inv(elevesDuFoyerProvider) (la source) | RÉEL | |
| suivi_foyer/suivi_foyer_page.dart:159 | Suivi foyer | Bloc | inv(seancesDuSuivi, presenceDuSuivi, groupesDesSeances) | RÉEL | |
| suivi_foyer/detail_observations_page.dart:90 | Détail observations | erreur | inv(detailObservationsProvider((seanceId, eleveId))) | RÉEL | |
| suivi_foyer/detail_seance_page.dart:89 | Détail séance | Bloc | inv(seancesDuSuivi, presenceDuSuivi) | RÉEL | |
| suivi_foyer/observations_page.dart:88 | Observations (famille) | ES | inv(elevesDuFoyerProvider) | RÉEL | |
| suivi_foyer/observations_page.dart:117 | Observations (famille) | Bloc | inv(mesObservationsProvider(eleveId)) | RÉEL | |
| admin_regroupements/feuille_classe_regroupement.dart:501 | Regroupement : enseignant | Bloc | inv(enseignantsDuPortProvider(_type), comptesProvider) | RÉEL | |
| admin_regroupements/regroupements_page.dart:446 | Regroupements | HL | inv(regroupementsAdmin, pageRegroupementsAdmin) | RÉEL | |
| admin_regroupements/regroupements_page.dart:452 | Regroupements | ES | idem | RÉEL | |
| admin_admissions/admissions_page.dart:241 | Admissions | erreur | inv(pageAdmissionsProvider) | RÉEL | |
| appareils/appairage_page.dart:523 | Appairage | échec de création | _creer() | RÉEL | |
| appareils/appairage_page.dart:533 | Appairage | idem | _creer() | RÉEL | |
| appareils/appairage_page.dart:542 | Appairage | idem | _creer() | RÉEL | |
| appareils/appairage_page.dart:599 | Appairage | caméra | _demarrer() | RÉEL | |
| appareils/appareils_eleve_page.dart:164 | Appareils élève | HL | inv(elevesDuFoyer, appareilsDuFoyer) | RÉEL | |
| appareils/appareils_eleve_page.dart:170 | Appareils élève | Bloc | idem | RÉEL | |
| appareils/appareils_page.dart:72 | Appareils | HL | idem | RÉEL | |
| appareils/appareils_page.dart:77 | Appareils | Bloc | idem | RÉEL | |
| talents/talents_page.dart:93 | Talents | Bloc | inv(etatDossierProvider) | RÉEL | |
| talents/talents_page.dart:300 | Talents | Bloc | inv(autresCompetencesProvider) | RÉEL | |
| parcours_offres/parcours_offres_page.dart:374 | Parcours offres | HL | inv(parcoursFoyerProvider) | RÉEL | |
| parcours_offres/parcours_offres_page.dart:382 | Parcours offres | ES | inv(parcoursFoyerProvider) | RÉEL | |
| parcours_offres/parcours_offres_page.dart:674 | Parcours : offres | erreur | inv(offresCompatiblesProvider) (toute la famille) | RÉEL | |
| admin_demandes/demandes_page.dart:157 | Demandes | erreur | inv(demandesProvider) | RÉEL | |
| admin_comptes/comptes_page.dart:377 | Comptes | Bloc | inv(comptesProvider) | RÉEL | |
| com_annonces/annonces_planifiees.dart:54 | Annonces planifiées | ES/HL | relais | RELAIS | |
| com_annonces/annonces_planifiees.dart:175 | Annonces planifiées | Bloc | inv(annoncesAdministrationProvider) | RÉEL | |
| com_annonces/annonce_detail.dart:38 | Annonce | erreur | inv(annonceProvider(id)) | RÉEL | |
| com_annonces/publier_annonce_classe_page.dart:101 | Publier annonce | ES/HL | inv(annoncesDeClasseProvider(groupeId)) | RÉEL | |
| com_annonces/matrice_audience.dart:91 | Matrice d'audience | Bloc | inv(reglesAudienceProvider) | RÉEL | |
| com_annonces/administration_communications_page.dart:473 | Communications (mesures) | erreur | mesure.relire (annonces, modération, règles) | RÉEL | |
| com_annonces/administration_communications_page.dart:589 | Communications | ES/HL | inv(ciblesPublicationProvider, capacitesCommunicationProvider) | RÉEL | |
| com_annonces/publieur_annonce.dart:336 | Publieur | envoi | publier/programmer | RÉEL | |
| com_annonces/file_moderation.dart:281 | Modération | ES/HL | inv(fileModerationProvider, capacitesModerationProvider) | RÉEL | |
| com_annonces/annonces_de_classe.dart:180 | Annonces de classe | ES/HL | inv(annoncesDeClasseProvider(classeId)) | RÉEL | |
| mfa_controleur/mfa_controleur_page.dart:241 | MFA contrôleur | ES | _charger() | RÉEL | |
| mfa_controleur/mfa_controleur_page.dart:247 | MFA contrôleur | HL (MfaHorsLigne) | _charger() | RÉEL | |
| com_messages/messages_page.dart:382 | Messages | ES/HL | _chargerListe() | RÉEL | |
| com_messages/messages_page.dart:407 | Messages | ES/HL | _chargerFil(id) | RÉEL | |
| com_messages/entree_messages_contexte.dart:344 | Messages en contexte | ES/HL | _charger() | RÉEL | |
| admin_avis/avis_page.dart:463 | Avis | HL | relais | RELAIS | |
| admin_avis/avis_page.dart:469 | Avis | ES | relais | RELAIS | |
| admin_avis/avis_page.dart:578 | Avis | Bloc | inv(avisAdminProvider) | RÉEL | |
| admin_avis/avis_page.dart:661 | Avis | Bloc | inv(avisLiensProvider) | RÉEL | |
| admin_groupes/feuille_reglages_classe.dart:296 | Réglages de classe | ES | inv(creneauxClasseProvider(id)) | RÉEL | |
| admin_groupes/groupes_page.dart:450 | Classes | HL | inv(groupesProvider, pageClassesAdminProvider) | RÉEL | |
| admin_groupes/groupes_page.dart:459 | Classes | erreur | idem | RÉEL | |
| admin_groupes/groupes_page.dart:697 | Classes | erreur | inv(groupesProvider) | RÉEL | |
| admin_groupes/groupes_page.dart:1674 | Création de classe : enseignant | Bloc | inv(enseignantsDuPortProvider(_type), comptesProvider) | RÉEL | |
| admin_groupes/groupes_page.dart:2123 | Ajout d'élève | Bloc | inv(elevesProposablesClasseProvider(id)) | RÉEL | |
| admin_groupes/cahiers_classe.dart:192 | Cahiers de classe | erreur | _lire() (port) | RÉEL | |
| admin_groupes/cahiers_classe.dart:310 | Cahiers de classe | erreur | inv(cahierAdminProvider(cle)) | RÉEL | |
| admin_groupes/reglage_partage.dart:212 | Partage | erreur/HL | inv(partageClasseProvider(id)) | RÉEL | |
| admin_groupes/reglage_partage.dart:476 | Partage | erreur/HL | _lire() | RÉEL | |
| admin_groupes/apercu_familial.dart:175 | Aperçu familial | erreur | inv(comptesRendusEleveProvider(cle)) | RÉEL | |
| admin_groupes/apercu_familial.dart:323 | Aperçu familial | erreur/HL | inv(apercuFamilialProvider(cle)) | RÉEL | |
| accueil_eleve/accueil_accessibilite.dart:223 | Accueil Interface guidée | Bloc | inv(donneesAccueilAccessibiliteProvider) | RÉEL | |
| accueil_eleve/accueil_accessibilite.dart:249 | Accueil Interface guidée | ES | relais | RELAIS | |
| accueil_eleve/accueil_accessibilite.dart:276 | Accueil Interface guidée (carte) | HL / accès invérifiable | inv(horsLigneProvider) seulement | **FICTIF** (accès invérifiable) | voir point 2 |
| accueil_eleve/accueil_accessibilite.dart:424 | idem | idem | relais de la l. 276 | **FICTIF** | voir point 2 |
| accueil_eleve/accueil_eleve_page.dart:321 | Accueil élève | ES/HL | inv(seancesProvider) | RÉEL | |
| accueil_eleve/apres_seance_accessibilite.dart:454 | Après séance (guidée) | erreur | relais | RELAIS | |
| accueil_eleve/apres_seance_accessibilite.dart:469 | Après séance (guidée) | erreur | inv(groupeProvider(id)) | RÉEL | |
| accueil_eleve/apres_seance_accessibilite.dart:497 | Après séance (guidée) | erreur | inv(travailAVenirProvider(contexte)) | RÉEL | |
| accueil_eleve/mon_espace_accessibilite.dart:108 | Mon espace (guidée) | demande non confirmée | _demander(port) | RÉEL | |
| tc_observation_ui/entree_observation_page.dart:277 | Entrée observation | erreur | inv(etatVisiteObservationProvider(seanceId)) (Stream) | RÉEL (sans retour visuel) | |
| tc_observation_ui/entree_observation_page.dart:556 | Entrée observation | Bloc | inv(verificationPrealableProvider(demande)) | RÉEL | |
| tc_observation_ui/entree_observation_page.dart:719 | Entrée observation | erreur | _reverifier, soit inv(verificationPrealable) | RÉEL | |
| tc_observation_ui/entree_observation_page.dart:759/761/773 | Entrée observation | erreur | idem | RÉEL | |
| tc_observation_ui/entree_observation_page.dart:799 | Entrée observation | connexion impossible | _recommencer : inv(moteurVisite, verificationPrealable) | RÉEL | |
| salle/salle_page.dart:2049 | Salle (impasse) | échec d'entrée | _entrer (relit le pré-vol) | RÉEL | |
| salle/salle_page.dart:2203 | Salle (élèves sortis) | erreur | inv(elevesSortisProvider(seanceId)) | RÉEL | |
| salle/salle_page.dart:4363 | Salle (impasse) | échec | relais (_entrer) | RÉEL | |
| salle/salle_page.dart:4441 | Préparation enseignant | pré-vol bloqué | inv(preVolProvider) | RÉEL | |
| salle/salle_page.dart:4480 | Préparation élève | pré-vol/HL | inv(preVolProvider, horsLigneProvider) | RÉEL | |
| salle/preparation_enseignant.dart:311 | Préparation enseignant | pré-vol | relais | RÉEL | |
| salle/preparation_eleve.dart:293/364/422 | Préparation élève | pré-vol/HL | relais | RÉEL | |
| salle/pre_vol_classe.dart:194 | Pré-vol | pré-vol | relais | RÉEL | |
| admin_configuration_regles/regles_page.dart:64 | Règles | erreur | inv(valeursReglesProvider) | RÉEL (sans retour visuel) | |
| salle_seance/surface_page_fixe.dart:531 | Support reçu | erreur support | PorteeSupportRecu.reessayerDe = null | ABSENT en prod | démo seule |
| salle_seance/surface_page_fixe.dart:1066 | Support reçu | idem | relais | ABSENT en prod | |
| salle_seance/salle_seance.dart:3207 | Salle : échec de connexion | HL/reconnexion | actions.onReessayerConnexion = null | ABSENT en prod | démo seule |
| salle_seance/resultat_seance.dart:371 | Fin de séance (enseignant) | cahier indisponible | _ouvrirCahier (même findMatch) | **FICTIF** (ne peut pas aboutir) | voir point 4 |
| salle_seance/resultat_seance.dart:418 | idem, bureau | idem | idem | **FICTIF** | voir point 4 |
| salle_seance/bibliotheque_seance.dart:366 | Bibliothèque de séance | présentation échouée | onPresenter | RÉEL | |
| revenus_enseignant/revenus_enseignant_page.dart:157 | Revenus | HL | inv(revenusEnseignantProvider) | RÉEL | |
| revenus_enseignant/revenus_enseignant_page.dart:177 | Revenus | Bloc | idem | RÉEL | |
| revenus_enseignant/revenus_enseignant_page.dart:865 | Revenus (relevé) | Bloc | inv(releveEnseignantProvider) | RÉEL | |
| revenus_enseignant/revenus_enseignant_page.dart:877 | Revenus (relevé) | HL | relais | RELAIS | |
| admin_courriels/courriels_page.dart:406 | Courriels | HL | relais | RELAIS | |
| admin_courriels/courriels_page.dart:412 | Courriels | ES | relais | RELAIS | |
| admin_courriels/courriels_page.dart:523 | Courriels | Bloc | inv(courrielsCategoriesProvider) | RÉEL | |
| admin_courriels/courriels_page.dart:678 | Courriels | Bloc | inv(courrielsFileProvider) | RÉEL | |
| admin_courriels/courriels_page.dart:744 | Courriels | Bloc | inv(courrielsCategoriesProvider) | RÉEL | |
| admin_courriels/courriels_page.dart:717/894 | Courriels (renvoi) | envoi | port.reessayer(id), puis inv(courrielsFile) | RÉEL | |
| admin_configuration_fonctionnalites/fonctionnalites_page.dart:58 | Fonctionnalités | erreur | inv(valeursFonctionnalitesProvider) | RÉEL (sans retour visuel) | |
| notifications/notifications_page.dart:490 | Notifications | Bloc | inv(notificationsTuteurProvider) | RÉEL | |
| notifications/notifications_page.dart:497 | Notifications | ES/HL | relais | RELAIS | |
| admin_pedagogie_progression/progression_page.dart:74 | Progression | Bloc | inv(progressionProvider) | RÉEL | |
| recrutement/signature_contrat_page.dart:208 | Signature du contrat | Bloc | inv(contratEnseignantCourant, maSignatureEnseignant) | RÉEL | |
| recrutement/signature_contrat_page.dart:228/237/243 | Signature du contrat | ES/HL | relais | RELAIS | |
| recrutement/signature_contrat_page.dart:272 | Signature du contrat | ES | inv(contratEnseignantCourantProvider) | RÉEL | |
| comptable/beneficiaires/beneficiaires_page.dart:104 | Bénéficiaires | Bloc | inv(beneficiairesProvider) | RÉEL | |
| comptable/beneficiaires/beneficiaires_page.dart:127 | Bénéficiaires | HL | relais | RELAIS | |
| comptable/beneficiaires/profil_paiement_page.dart:264 | Profil de paiement | Bloc | inv(profilBeneficiaireProvider(id)) | RÉEL | |
| comptable/beneficiaires/profil_paiement_page.dart:276 | Profil de paiement | HL | relais | RELAIS | |
| comptable/beneficiaires/profil_paiement_page.dart:602 | Profil de paiement (journal) | Bloc | inv(journalBeneficiaireProvider(id)) | RÉEL | |
| comptable/beneficiaires/fil_profil_paiement_page.dart:145 | Fil profil de paiement | ES/HL | _charger() | RÉEL | |
| comptable/aujourdhui/aujourdhui_page.dart:107 | Aujourd'hui (comptable) | HL | inv(aujourdhuiComptableProvider) | RÉEL | |
| comptable/aujourdhui/aujourdhui_page.dart:112 | Aujourd'hui (comptable) | Bloc | idem | RÉEL | |
| comptable/paiements/detail_paiement_page.dart:145 | Détail paiement | Bloc | inv(obligationPayable, journalObligation, demandesValidationObjet) | RÉEL | |
| comptable/paiements/detail_paiement_page.dart:175 | Détail paiement | HL | idem | RÉEL | |
| comptable/paiements/detail_paiement_page.dart:719 | Détail paiement (journal) | Bloc | inv(journalObligationProvider(id)) | RÉEL | |
| comptable/paiements/paiements_page.dart:236 | Paiements (comptable) | Bloc | inv(obligationsPayablesProvider) | RÉEL | |
| comptable/paiements/paiements_page.dart:349 | Paiements (comptable) | HL | idem | RÉEL | |
| comptable/paiements/confirmation/confirmation_payout.dart:492 | Confirmation de versement | issue inconnue | _soumettre | RÉEL | |
| comptable/validation/suivi_validation.dart:75 | Suivi de validation | erreur | inv(demandesValidationObjetProvider(objetId)) | RÉEL | |
| comptable/encaissements/commun_encaissements.dart:89 | Encaissements (bloc commun) | Bloc | relais | RELAIS | |
| comptable/encaissements/commun_encaissements.dart:100 | Encaissements (bloc commun) | HL | relais | RELAIS | |
| comptable/encaissements/contenu_encaissement.dart:201 | Encaissement (journal) | Bloc | inv(journalEncaissementProvider(id)) | RÉEL | |
| comptable/encaissements/contenu_encaissement.dart:235 | Encaissement (détail) | Bloc | inv(detailEncaissementProvider(id)) | RÉEL | |
| comptable/encaissements/encaissements_page.dart:122 | Encaissements | Bloc | inv(listeEncaissementsProvider) | RÉEL | |
| comptable/encaissements/rapprochement_page.dart:52 | Rapprochement | Bloc | inv(elementsRapprochementProvider) | RÉEL | |
| comptable/encaissements/rapprochement/remboursements_avoirs.dart:249 | Remboursements | Bloc | inv(journalEncaissementProvider(id)) | RÉEL | |
| comptable/encaissements/rapprochement/panneau_rapprochement.dart:268 | Rapprochement (journal) | Bloc | inv(journalRapprochementProvider(el.id)) | RÉEL | |
| comptable/encaissements/rapprochement/panneau_rapprochement.dart:306 | Rapprochement (proposition) | Bloc | inv(propositionRapprochementProvider(id)) | RÉEL | |
| comptable/encaissements/rapprochement/espace_rapprochement.dart:140 | Rapprochement (remboursements) | Bloc | inv(remboursementsProvider) | RÉEL | |
| comptable/tresorerie/tresorerie_page.dart:316 | Trésorerie | Bloc | relireTresorerie : inv des 7 providers de trésorerie | RÉEL | |
| comptable/tresorerie/tresorerie_page.dart:326 | Trésorerie | HL | relais | RELAIS | |
| comptable/tresorerie/transfert/transfert_interne.dart:490 | Transfert interne | envoi | _envoyer | RÉEL | |
| comptable/contractuels/obligation_contractuel_page.dart:162 | Obligation (contractuel) | HL | inv(obligationContractuel, journal, demandesValidationObjet) | RÉEL | |
| comptable/contractuels/obligation_contractuel_page.dart:167 | Obligation (contractuel) | Bloc | idem | RÉEL | |
| comptable/contractuels/obligation_contractuel_page.dart:719 | Obligation (journal) | Bloc | inv(journalObligationContractuelProvider(id)) | RÉEL | |
| comptable/contractuels/contractuels_page.dart:114 | Contractuels | HL | inv(obligationsContractuels, contexteCreationObligation) | RÉEL | |
| comptable/contractuels/contractuels_page.dart:119 | Contractuels | Bloc | idem | RÉEL | |
| comptable/contractuels/nouvelle_obligation_page.dart:201 | Nouvelle obligation | HL | inv(contexteCreationObligationProvider) | RÉEL | |
| comptable/contractuels/nouvelle_obligation_page.dart:206 | Nouvelle obligation | Bloc | idem | RÉEL | |
| comptable/graphiques/blocs_graphiques.dart:97 | Graphiques | Bloc | inv(seriesTresorerieProvider) | RÉEL | |
| comptable/graphiques/blocs_graphiques.dart:128 | Graphiques | HL | relais | RELAIS | |
| comptable/graphiques/blocs_graphiques.dart:134 | Graphiques | ES | relais | RELAIS | |
| admin_offres/admin_offres_page.dart:162 | Offres | Bloc | inv(offresAdminProvider) | RÉEL | |
| admin_offres/admin_offres_page.dart:174/180 | Offres | HL/ES | relais | RELAIS | |
| admin_offres/nouvelle_offre_page.dart:159 | Nouvelle offre | Bloc | inv(reglesCreationOffreProvider) | RÉEL | |
| admin_offres/nouvelle_offre_page.dart:165/171 | Nouvelle offre | HL/ES | relais | RELAIS | |
| admin_configuration_protection_enfants/protection_enfants_page.dart:101 | Protection de l'enfance | erreur | inv(responsableProtectionProvider) | RÉEL (sans retour visuel) | |
| admin_configuration_protection_enfants/protection_enfants_page.dart:122 | Protection de l'enfance | erreur | inv(representantUeProvider) | RÉEL (sans retour visuel) | |
| protection_enfants/ligne_responsable.dart:75 | Ligne responsable | erreur | inv(responsableProtectionProvider) | RÉEL | |
| admin_tableau/activite_recente.dart:62 | Tableau (activité) | Bloc | inv(activiteRecenteProvider) | RÉEL | |
| eleve_connexion/scanner_page.dart:324/342/360/383 | Scanner QR | caméra | _demarrer() | RÉEL | |
| admin_pedagogie_evaluations/evaluations_page.dart:88 | Évaluations | Bloc | inv(evaluationsProvider) | RÉEL | |
| admin_pedagogie_evaluations/evaluations_page.dart:411 | Évaluations (élève) | Bloc | inv(comptesProvider) (la source de personnesProposables) | RÉEL | |
| compte/aide_page.dart:51 | Aide | erreur | inv(canalSupportProvider) | RÉEL | |
| compte/mes_donnees_page.dart:337 | Mes données | Bloc | inv(situationSuppressionProvider) | RÉEL | |
| compte/mes_donnees_page.dart:345 | Mes données | HL | relais | RELAIS | |
| compte/securite_page.dart:51 | Sécurité | Bloc | inv(identiteTitulaireProvider) | RÉEL | |
| compte/compte_page.dart:503 | Compte (profils) | erreur | inv(elevesDuFoyerProvider) | RÉEL (sans retour visuel) | `.when()` garde l'erreur |
| compte/compte_page.dart:558 | Compte (profil enfant) | erreur | idem | RÉEL (sans retour visuel) | idem |
| compte/informations_legales_page.dart:69 | Informations légales | Bloc | inv(acceptationsProvider) | RÉEL | |
| compte/compte_tuteur_page.dart:98 | Compte tuteur | Bloc | inv(identiteTitulaireProvider) | RÉEL | |
| compte/acces_page.dart:68 | Accès | Bloc | inv(accesFoyerProvider) | RÉEL | |
| compte/paiements_page.dart:85 | Paiements (foyer) | Bloc | inv(paiementsFoyerProvider) | RÉEL | |
| compte/soldes_foyer.dart:86 | Soldes | HL | inv(soldesFoyerProvider) | RÉEL | |
| compte/soldes_foyer.dart:92 | Soldes | Bloc | idem | RÉEL | |
| compte/informations_page.dart:52 | Informations | Bloc | inv(identiteTitulaireProvider) | RÉEL | |
| compte/langue_courriels_page.dart:164/170 | Langue des courriels | HL/ES | relais | RELAIS | |
| compte/langue_courriels_page.dart:200 | Langue des courriels | Bloc | inv(languesCommunicationProvider) | RÉEL | |
| admin_pilotage/pilotage_page.dart:245 | Pilotage | Bloc | inv(pagePilotageProvider, pageClassesAdminProvider) | RÉEL | repli sur groupesProvider non utilisé en prod (port branché, main.dart:248) |
| admin_pilotage/pilotage_page.dart:269/275 | Pilotage | HL/ES | relais | RELAIS | |
| admin_pilotage/pilotage_page.dart:367 | Pilotage (classes en attente) | Bloc | relais (_relire) | RELAIS | |
| partage_offre/partage_offre_page.dart:110 | Partage d'offre | Bloc | inv(etatDossierProvider) | RÉEL | |
| partage_offre/partage_offre_page.dart:143 | Partage d'offre | Bloc | inv(reglagesCarteProvider) (sources sans erreur, délai fixe) | RÉEL | |
| partage_offre/partage_offre_page.dart:439 | Partage d'offre (carte) | carte en échec | _preparer() | RÉEL | |
| presentation_tuteur/demandes_presentation_page.dart:133 | Demandes de présentation | Bloc | inv(demandesPresentationProvider) | RÉEL | |
| presentation_tuteur/demandes_presentation_page.dart:144/150 | Demandes de présentation | HL/ES | relais | RELAIS | |
| admin_reprises/reprises_page.dart:157 | Reprises | Bloc | inv(reprisesAdminProvider) | RÉEL | |
| admin_reprises/reprises_page.dart:178/184 | Reprises | HL/ES | relais | RELAIS | |
| admin_finance/politiques_commerciales.dart:170 | Politiques commerciales | HL | inv(politiquesCommercialesProvider) | RÉEL | |
| admin_finance/politiques_commerciales.dart:176 | Politiques commerciales | Bloc | idem | RÉEL | |
| admin_finance/vue_globale_finance.dart:154 | Vue globale finance | HL | inv(vueGlobaleFinanceProvider) | RÉEL | |
| admin_finance/vue_globale_finance.dart:181 | Vue globale finance | Bloc | idem | RÉEL | |
| admin_finance/reserve_delegation/composants_politique.dart:58/71 | Réserve et délégation | HL/Bloc | relire (paramètre de l'appelant) | RELAIS | |
| admin_finance/paiements/remboursement_direction.dart:361 | Remboursement | envoi | _rembourser | RÉEL | |
| admin_finance/paiements/factures_mois.dart:256 | Factures du mois | envoi | _emettre | RÉEL | |
| admin_finance/paiements/paiements_page.dart:709 | Paiements (direction) | envoi | _enregistrer | RÉEL | |
| com_studio/elements_enregistres_studio.dart:125/130 | Studio : enregistrés | ES/HL, Bloc | _charger() | RÉEL | |
| com_studio/studio_page.dart:790 | Studio : recherche | erreur | _chercher(texte) | RÉEL | |
| com_studio/studio_page.dart:938 | Studio : canaux | ES/HL | _chargerCanaux() | RÉEL | |
| com_studio/studio_page.dart:964 | Studio : canal | ES/HL | _chargerCanal(id) | RÉEL | |
| com_studio/panneau_partages.dart:259 | Studio : partages | ES/HL | relais (_chargerPartages, studio_page:911) | RELAIS | |
| com_studio/aujourdhui_page.dart:430 | Studio : aujourd'hui | ES/HL | _charger() | RÉEL | |
| com_studio/aujourdhui_page.dart:450 | Studio : brouillons | Bloc | _rechargerBrouillons() | RÉEL | |
| com_studio/brouillons_studio.dart:239 | Studio : brouillons | Bloc | relais | RELAIS | |
| com_studio/brouillons_studio.dart:345 | Studio : brouillons | Bloc | _charger() | RÉEL | |
| com_studio/recherche_studio.dart:160 | Studio : recherche | ES/HL | relais (studio_page:790) | RELAIS | |
| com_vocal/composer_vocal.dart:732 | Message vocal | envoi | _envoyer | RÉEL | |
| com_communaute/flux_publications.dart:256 | Communauté | Bloc | inv(publicationsCommunauteProvider(lecture)) | RÉEL | |
| com_communaute/flux_publications.dart:263 | Communauté | ES/HL | relais | RELAIS | |
| com_communaute/publication_detail.dart:299 | Publication | Bloc | inv(publicationCommunauteProvider(id)) | RÉEL | |
| com_communaute/publication_detail.dart:315 | Publication | ES/HL | relais | RELAIS | |
| com_communaute/publication_detail.dart:508 | Réponses | Bloc | inv(reponsesCommunauteProvider(id)) | RÉEL | |
| com_communaute/communaute_page.dart:274 | Communauté | ES/HL | inv(capacitesCommunaute, categoriesCommunaute) | RÉEL | |
| com_communaute/reponses.dart:326/614 | Réponses | envoi | renvoyer / _envoyer | RÉEL | |
| com_communaute/composer_publication.dart:523 | Composer | envoi | _publier | RÉEL | |
| admin_acces_agents/acces_agents_page.dart:319 | Accès agents | Bloc | _charger() | RÉEL | |
| admin_acces_agents/acces_agents_page.dart:422 | Accès agents | erreur | _charger() | RÉEL | |
| admin_configuration_conservation_donnees/conservation_donnees_page.dart:61 | Conservation | erreur | inv(valeursConservationDonneesProvider) | RÉEL (sans retour visuel) | |
| mon_espace_adulte/mon_espace_adulte_page.dart:263 | Mon espace (adulte) | HL | inv(identiteTitulaire, monEspaceAdulte) | RÉEL | monEspaceAdulte reste indisponible |
| mon_espace_adulte/mon_espace_adulte_page.dart:270 | Mon espace (adulte) | Bloc | inv(identiteTitulaireProvider) | RÉEL | |
| mon_espace_adulte/mon_espace_adulte_page.dart:407 | Mon espace (adulte) | Bloc | inv(monEspaceAdulteProvider) | N/A prod | CapaciteIndisponible |
| tc_mushaf/vue_verset_agrandi.dart:144 | Coran : verset agrandi | indisponible | inv(pageCorpusProvider(numero)) | RÉEL | |
| tc_mushaf/vue_focus_classe.dart:49 | Coran : focus | indisponible | idem | RÉEL | |
| tc_mushaf/vue_page_mushaf.dart:435 | Coran : page | indisponible | idem | RÉEL | |
| tc_mushaf/vue_page_mushaf.dart:498 | Coran : police | police absente | inv(policeMushafDisponibleProvider) | RÉEL | |
| recherche/ecran/ecran_recherche.dart:189 | Recherche | erreur | controleurRecherche.reessayer() | RÉEL | |
| recherche/ecran/ecran_recherche.dart:291/298/307 | Recherche | ES/CP/HL | relais | RELAIS | |
| recherche/ecran/ecran_recherche.dart:379 | Recherche (domaine) | ES | reessayerDomaine() | RÉEL | |
| consentements/consentement_observation_page.dart:134 | Consentement observation | erreur | inv(accordsTitulaireProvider) | RÉEL | |
| consentements/consentement_observation_page.dart:260 | idem | erreur | relais | RÉEL | |
| code_conduite/code_conduite.dart:191 | Code de conduite | erreur | inv(accordsTitulaireProvider) | RÉEL | |
| suivi_demandes/suivi_demandes_page.dart:99 | Suivi des demandes | Bloc | inv(suiviDemandesProvider) (Stream) | RÉEL | |
| suivi_demandes/suivi_demandes_page.dart:110/116 | Suivi des demandes | HL/ES | relais | RELAIS | |
| suivi_demandes/changement_classe_page.dart:83 | Changement de classe | Bloc | inv(suiviDemandesProvider) | RÉEL | |
| suivi_demandes/changement_classe_page.dart:109/115 | Changement de classe | HL/ES | relais | RELAIS | |
| foyer/transactions_foyer.dart:93/98 | Transactions | HL/ES | inv(derniersMouvementsFoyerProvider) | RÉEL | |
| foyer/recharge_foyer.dart:464/470 | Recharge | HL/Bloc | inv(beneficiairesRechargeProvider) | RÉEL | |
| foyer/recharge_foyer.dart:977 | Recharge (vérification) | ES | _actualiser() (revérifie) | RÉEL | |
| foyer/foyer_page.dart:189 | Foyer (place adulte) | Bloc | inv(foyerTitulaireProvider) | N/A prod | CapaciteIndisponible |
| foyer/foyer_page.dart:548/555 | Foyer | HL/Bloc | inv(elevesDuFoyerProvider) | RÉEL | |
| foyer/foyer_page.dart:758/764 | Foyer (identité) | HL/Bloc | inv(identiteTitulaireProvider) | RÉEL | |
| foyer/formulaire_profil_eleve.dart:405 | Ajout de profil élève | ES (porte illisible) | inv(porteAjoutProfilProvider) (sync) | **FICTIF** | voir point 3 |
| foyer/formulaire_profil_eleve.dart:415 | Ajout de profil élève | HL | idem | **FICTIF** | voir point 3 |
| foyer/reprise_foyer.dart:298/616 | Reprise | Bloc | inv(repriseFoyer / demandeRepriseRecue) | N/A prod | CapaciteIndisponible |
| foyer/fiche_eleve_page.dart:116/122 | Fiche élève | HL/Bloc | inv(elevesDuFoyerProvider) | RÉEL | |
| foyer/nos_prix_page.dart:117/122 | Nos prix | HL/ES | inv(politiqueActiveProvider) | RÉEL | |
| foyer/finances_foyer.dart:146/151 | Finances du foyer | HL/ES | inv(financesFoyerProvider) | RÉEL | |
| foyer/resultat_recharge.dart:166/171 | Résultat de recharge | HL/Bloc | inv(suiviRechargeProvider(commandeId)) | RÉEL | |
| foyer/resultat_recharge.dart:177 | Résultat de recharge | ES | relais | RELAIS | |
| foyer/resultat_recharge.dart:266 | Résultat de recharge | ES (formulaire) | setState(_essai++), la clé reconstruit le formulaire | RÉEL | |
| foyer/resultat_recharge.dart:445 | Résultat de recharge | paiement en échec | reprendre(selection) | RÉEL | |
| foyer/acceptation_invitation.dart:309 | Acceptation d'invitation | Bloc | inv(invitationRecueProvider) | N/A prod | CapaciteIndisponible |
| foyer/sortie_forfait.dart:229 | Sortie de forfait | Bloc | inv(forfaitFamilleProvider) | N/A prod | CapaciteIndisponible |
| foyer/fiche/couleur_page.dart:107 | Couleur | erreur | inv(accentsProfilsProvider) | RÉEL | |
| foyer/fiche/finances_page.dart:268/278 | Fiche : finances | HL/ES | inv(mouvementsProfilProvider) | RÉEL | |
| foyer/fiche/finances_page.dart:401/406 | Fiche : finances | HL/ES | relais | RELAIS | |
| foyer/fiche/mouvements_page.dart:262/267 | Fiche : mouvements | HL/ES | relais | RELAIS | |
| profil_enseignant/declaration_choix.dart:393 | Déclaration (langues) | Bloc | inv(referentielLanguesProvider) | RÉEL | |
| profil_enseignant/declaration_choix.dart:401 | idem | ES | relais | RELAIS | |
| profil_enseignant/profil_enseignant_page.dart:139 | Profil enseignant | erreur | inv(profilEnseignantProvider) | RÉEL (sans retour visuel) | |
| profil_enseignant/profil_enseignant_page.dart:689 | Profil enseignant | erreur | inv(acceptationsProvider) | RÉEL (sans retour visuel) | |
| revue_groupe/revue_groupe_page.dart:130 | Revue de groupe | erreur | inv(membresGroupeEnseignant, anomaliesGroupe) | RÉEL | |
| admin_import_inscriptions/import_inscriptions_page.dart:366 | Import des inscrits | Bloc | inv(capacitesImportProvider) | RÉEL | |
| admin_import_inscriptions/import_inscriptions_page.dart:381/387 | Import des inscrits | HL/ES | relais | RELAIS | |
| salle_enseignant/page_coran_salle.dart:121 | Coran (salle, enseignant) | indisponible | inv(pageMushafProvider, policeMushafDisponibleProvider) | **DOUTEUX** | voir point 5 |
| salle_enseignant/panneau_enseignant.dart:380 | Panneau enseignant (page) | indisponible | inv(pageCoranProvider(page)) | RÉEL | |
| salle_enseignant/panneau_enseignant.dart:521 | Panneau enseignant (sourates) | indisponible | inv(souratesProvider) | RÉEL | |
| agent_entree/agent_entree_page.dart:67/167 | Entrée agent | refus | rechargerAdresse() (rechargement de la page web) | RÉEL | |
| core/version/bandeau_nouvelle_version.dart:32 | Bandeau « Recharger » | nouvelle version | rechargerAdresse() | RÉEL | |
| admin_pedagogie_qualite/qualite_page.dart:102 | Qualité | Bloc | inv(anomaliesQualiteProvider) | RÉEL | |
| accueil_inscrits/accueil_inscrits_page.dart:262/269 | Accueil des inscrits | ES/HL | notifier.reessayer(), soit _reclamer (port) | RÉEL | |
| accueil_adulte/accueil_adulte_page.dart:259/265 | Accueil adulte | HL/Bloc | inv(accueilAdulteProvider) | RÉEL | |
| accueil_adulte/historique_seances_adulte_page.dart:80/88 | Historique adulte | HL/Bloc | inv(historiqueSeancesAdulteProvider) | RÉEL | |
| inscription/questionnaire/questionnaire_page.dart:529 | Questionnaire d'inscription | ES | inv(languesCoursProvider) | RÉEL | |
| inscription/etapes/recapitulatif_etape.dart:316 | Inscription : récapitulatif | création échouée | _creer | RÉEL | |
| admin_pedagogie_diagnostics/diagnostics_page.dart:123 | Diagnostics | Bloc | inv(versionActiveProgrammeProvider) | **FICTIF** | voir point 1 |
| admin_pedagogie_diagnostics/diagnostics_page.dart:190 | Diagnostics (file) | Bloc | inv(diagnosticsATraiterProvider) | RÉEL | |
| admin_planning/feuille_remplacant.dart:190 | Remplaçant | Bloc | inv(remplacantsPossiblesProvider(id)) | RÉEL | |
| admin_planning/planning_page.dart:120 | Planning | Bloc | inv(planningSemaine, remplacementsSemaine) | RÉEL | |
| admin_planning/planning_page.dart:143/149 | Planning | HL/ES | relais | RELAIS | |
| admin_planning/planning_page.dart:166 | Planning (bilan) | ES | inv(remplacementsSemaineProvider) | RÉEL | |
| admin_planning/planning_page.dart:280 | Planning (bilan) | ES | relais (l. 166) | RELAIS | |
| admin_planning/feuille_reaffectation.dart:178 | Réaffectation | Bloc | inv(enseignantsReaffectationProvider(id)) | RÉEL | |
| admin_fusion/feuilles_fusion.dart:97/103 | Fusion/transfert | HL/ES | relais | RELAIS | |
| admin_fusion/feuilles_fusion.dart:258/627 | Fusion : cibles | Bloc | inv(classesCiblesProvider) | RÉEL | |
| admin_fusion/feuilles_fusion.dart:340 | Fusion : aperçu | Bloc | inv(apercuFusionProvider) | RÉEL | |
| admin_fusion/feuilles_fusion.dart:532 | Transfert : membres | Bloc | inv(membresTransferablesProvider) | RÉEL | |
| admin_fusion/feuilles_fusion.dart:696 | Historique de classe | Bloc | inv(historiqueClasseProvider) | RÉEL | |
| admin_fusion/feuilles_fusion.dart:272/346/546/641/710 | Fusion (_echec) | ES/HL | relais | RELAIS | |
| admin_candidature/candidature_page.dart:191/199 | Candidature (direction) | HL/ES | relais | RELAIS | |
| admin_candidature/candidature_page.dart:236 | Candidature (direction) | Bloc | inv(detailCandidature, historiqueCandidature, pageCandidatures, capacitesCandidatures) | RÉEL | |
| admin_candidature/feuille_geste.dart:455 | Feuille de geste | geste non confirmé | _envoyer | RÉEL | |
| admin_candidature/feuille_geste.dart:842 | Feuille de geste (responsables) | ES | inv(responsablesPossiblesProvider(id)) | RÉEL | |
| admin_candidature/blocs_candidature.dart:862 | Contact du candidat | erreur | setState(_lecture = _lire()), le port est relu | RÉEL | |
| admin_candidature/blocs_candidature.dart:1087 | Historique de candidature | ES | inv(historiqueCandidatureProvider(id)) | RÉEL | |
| admin_dossiers/visionneuse_piece.dart:427 | Visionneuse de pièce | erreur | relais | RELAIS | |
| admin_dossiers/visionneuse_piece.dart:471/481/495 | Visionneuse de pièce | ES / ressourceExpiree « Recharger » / HL | _charger() (nouvelle URL signée) | RÉEL | |
| admin_dossiers/file_dossiers.dart:67 | File des dossiers | HL | relais | RELAIS | |
| admin_dossiers/revue_dossier.dart:413 | Revue de dossier | erreur | relais (onActualiser) | RELAIS | |
| admin_dossiers/dossiers_page.dart:291/312 | Dossiers | ES/Bloc | actualiserDossiers : inv(dossiersEnAttente, dossierPourRevue, indicateurs) et fileDossiers.actualiser() (invalidateSelf) | RÉEL | |
| admin_dossiers/dossiers_page.dart:391 | Dossiers (suite) | ES | fileDossiers.chargerSuivants() | RÉEL | |
| admin_dossiers/detail_dossier.dart:58 | Détail dossier | Bloc | actualiserDossiers(ref) | RÉEL | |
| admin_dossiers/surfaces_decision.dart:598 | Décision | décision échouée | _confirmer(e) | RÉEL | |
| candidature/candidature_page.dart:78 | Candidature | Bloc | inv(etatDossierProvider) | RÉEL | |
| candidature/candidature_page.dart:123/375 | Candidature | Bloc | inv(questionnaireCandidatProvider) | RÉEL | |
| candidature/lecture_page.dart:92/98 | lecturePage (générique) | Bloc/HL | relais | RELAIS | |
| candidature/recapitulatif_etape.dart:738 | Candidature : récapitulatif | Bloc | inv(conditionsRemunerationCandidatProvider) | RÉEL | |
| candidature/recapitulatif_etape.dart:744 | idem | HL | relais | RELAIS | |
| candidature/question_etape.dart:546 | Candidature : question | Bloc | inv(moyensConfirmesProvider(pays)) | RÉEL | |
| candidature/question_etape.dart:549 | idem | HL | relais | RELAIS | |
| core/widgets/fil_discussion.dart:949 | Fil de discussion | envoi échoué | _tenter(m) | RÉEL | |
| core/router/etats_routeur.dart:158 | Démarrage hors ligne | HL | _reessayer → rafraichir() | RÉEL (réserve) | no-op en session agent ; HL aussi pour un délai serveur |
| core/router/etats_routeur.dart:261 | Démarrage prolongé | CP | _relancer → rafraichir() | **DOUTEUX** | voir point 6 |
| core/widgets/bloc_asynchrone.dart:213/284 | générique | ES/CP | _reessayer (3 au plus) puis onReessayer | RÉEL | |
| core/widgets/chargement_avec_delais.dart:128 | générique | ES (perdue) | _reessayer puis onReessayer | RÉEL | |
| core/widgets/vue_etat_communication.dart:116/155/166/262/273 | générique | ES/HL | relais | RELAIS | |
| core/widgets/etat_systeme.dart:111/290, core/reseau/etat_sans_donnees.dart:61 | générique | HL | relais | RELAIS | |
| core/widgets/selecteur_personne.dart:207/212 | générique | Bloc | relais | RELAIS | |

Écartés, car ce ne sont pas des relectures : `tc_flux_academique/panneau_post_cours.dart:94` (libellé « valider ») et `bloc_avant_prochain_cours.dart:125`, tous deux dans un module non branché selon l'inventaire.