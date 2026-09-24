# Backlog : vague « Classe et visio » (après le chantier frontend Tuteur V1)

Consigné le 24/09/2026 sur ordre du directeur : **ne rien corriger maintenant**, ne pas sortir du chantier Tuteur en cours.

## BLOQUANT constaté le 24/09 (critique du dossier ChatGPT, sur `cefab7f`)

- **Permission micro absente** : `RECORD_AUDIO` n'est déclaré dans aucun manifeste Android (ni debug, ni profile, ni paquets vidéo), et `Info.plist` iOS n'a pas `NSMicrophoneUsageDescription`. Sans elles, élève et enseignant ne peuvent pas se parler sur mobile. Premier point de la vague Classe et visio (fichiers plateforme, propriété du coordinateur).
- **Trois fenêtres d'entrée différentes** : élève à l'heure du début, enseignant 10 minutes avant, serveur 20 minutes avant. À unifier sur la fenêtre serveur.
- **Validation des dossiers bloquée** si le genre de l'administrateur manque, et aucun écran ne permet de le renseigner.

## Priorité n° 1 de la vague suivante

**Permettre à un élève et à un enseignant de se rencontrer et de se voir** : une seule salle, visio LiveKit fonctionnelle, jeton vidéo délivré par le serveur, entrée depuis la classe pour l'élève et pour l'enseignant, présence. Tout le reste (outils pédagogiques, Coran fidèle) vient après que ce parcours marche réellement.

Prérequis connus (registre `06_registre/00_REGISTRE.md`, dépendances `02_code/00_DEPENDANCES_BACKEND.md`) :
- Migration `0042` appliquée en production qui refuserait tout jeton vidéo (affirmation du correctif non committé `D:\RA_OBS\...\0043_autoriser_jeton_video_verifie_le_bon_compte.sql`, sauvegardé ; à vérifier en base, puis renuméroter au prochain numéro libre).
- Deux salles concurrentes (`/salle` et `/tc/classe`) : arbitrage du directeur pour une salle unique.
- Synchronisation en direct (`lib/core/tc_realtime`), reprise après coupure (`lib/core/tc_etat_partage`) : présents sur `main`, jamais branchés.
- La page du Coran présentée par l'enseignant n'est reçue par aucun écran élève.

## Coran : défauts connus (rendu en production), à traiter dans cette vague, après la visio

Constatés par le directeur le 24/09 :
1. **Ordre inversé** : les versets s'affichent du dernier au premier, lecture du bas vers le haut. Cause prouvée : `lib/core/coran/service_coran.dart:309, 329, 330, 459, 460`, `.order(...)` sans `ascending: true` (postgrest 2.9.1 trie en décroissant par défaut). Même cause : la recherche renvoie les 50 **dernières** occurrences.
2. **Voyelles (harakat) absentes** : la fatha et les autres signes ne s'affichent pas sur presque tous les mots.
3. **Espacement** : mots trop éloignés les uns des autres, interligne trop large.
4. **Mise en forme non officielle** : ne respecte pas le Mushaf du complexe du roi Fahd (Madinah) : pas de pages standard (604 pages, 15 lignes), pas de marquages hizb, juz', rub', sajda, début de sourate, numéros de verset dans leur ornement.
5. **Résumé du directeur** : la version en production n'affiche que des mots bruts éparpillés.
6. **Commandes absentes** pour gérer le Coran (navigation page, sourate, juz', verset agrandi, suivi de la classe, zoom).

Pistes à instruire (sans décision) : police et données de mise en page officielles (KFGQPC / QPC, données de lignes par page), vérification du corpus chargé (6 236 versets, `0013`) et de sa normalisation Unicode (les harakat peuvent être perdus à l'import ou par la police), `layout_lignes_indisponible.dart:51-52` (mise en page fidèle désactivée), gestes de page et boutons en sens contraires (registre §4). Règle permanente : le texte canonique n'est jamais modifié ; sans mise en page de référence, afficher honnêtement le mode verset, jamais une fausse page « Mushaf ».

## Réponses du directeur sur le registre (24/09, soir)

- **Vocabulaire** : à l'écran on dit « Classe », jamais « groupe » (règle déjà imposée aux lots du chantier Tuteur).
- **Deux salles** (`/salle` et `/tc/classe`) : garder la plus complète, y combiner le meilleur de l'autre, puis supprimer le doublon (vague Classe et visio).
- **Lecteur du Coran en double** (`/tc/mushaf` et `/eleve/coran`) : même règle : compléter, combiner, supprimer le doublon.
- **Anciens lots Codex (13-15/09)** : abandon autorisé, mais examiner d'abord ce qui est récupérable comme inspiration (Codex jugé meilleur dans certains domaines).
- **Décision « badges à cinq niveaux »** : OUI, à intégrer aux specs (`docs/current`).

## Points du directeur restés sans réponse dans l'audit (à traiter)

- **Rôle enseignant inaccessible** : bloqué par le KYC, car l'administration n'a pas d'écran pour revoir et accepter les dossiers. À traiter en tête de la vague Classe et visio (sans enseignant validé, pas de rencontre élève-enseignant).
- **Accès de test sans parcours complet** : voir chaque rôle sans créer plusieurs comptes. Réponse retenue : mode démonstration par rôle sur l'aperçu (jamais en production) pour VOIR ; pour tester en vrai, comptes de test par rôle créés et validés par l'admin une fois l'écran de validation livré.
- **Système de jetons d'accès pour agents (comme PISI)** : jamais fonctionnel ; remplacé par l'aperçu de PR, le mode démonstration et les captures ; à ne pas relancer sans décision.

## Autres points consignés pour les vagues suivantes

- Outils de classe de l'enseignant, après-cours, signalement, micro-avis élève, bibliothèque en classe : présents sur `main`, jamais branchés (registre, groupe A).
- Écran de bienvenue enseignant sans bouton ; liste des élèves de l'enseignant refusée par la porte d'accès ; Coran hors salle absent pour l'enseignant (registre, groupes B et C).
- 11 autres appels `.order(...)` sans sens écrit (appareils, séances, créneaux, offres) : à vérifier dans chaque lot qui les consomme.
- [lot C, 24/09] `mes_groupes_famille_v` (`0033:140-170`) : jointure `m` (tous les eleves du foyer) croisee avec `m2`, `count(m2.id)` probablement multiplie quand deux enfants d'un meme foyer sont dans la meme classe (effectif gonfle). Lecture seule, non mesure. Backend.
- [lot C, 24/09] `groupeDepuisLigne` (`groupes_supabase.dart:48-50`) replie un titre absent sur Sayyid : le mandat interdit de deviner le titre ; `EnseignantVM.titre` non nullable (fichiers du coordinateur, demande C-3).
