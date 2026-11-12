# Lot SUIVI-ATTENTE : le suivi de l'attente de la classe, « comme une livraison »

> Lot demandé par le directeur le 12/11/2026, arbitré par l'architecte pédagogique (arbitrages S1 à S9). Branche `claude/suivi-attente`. Cette fiche est écrite avant le code et mise à jour à la fin. Elle dit d'abord ce qui est faux, bloqué ou non prouvé.

## 0. Ce qui est faux, bloqué ou non prouvé (à lire en premier)

1. **Rien n'est prouvé en production.** Il n'y a aucune demande réelle. L'écran est prouvé par des tests et des captures sur des données de test (S9), pas par le directeur.
2. **« Tout est prêt » n'a pas de notification propre.** Créer l'événement exige de remplacer la contrainte `notifications_evenement_check`, donc un `DROP CONSTRAINT` : interdit à ce lot (zéro `DROP`). L'étape 5 existe à l'écran, calculée par le serveur, mais **aucun message dans l'application ni courriel ne part au moment où elle est atteinte**. Pour le débloquer : l'architecte autorise un fichier à deux mots d'effacement, comme PUSH-1 (`20261112000000`), collé par le directeur dans l'éditeur SQL.
3. **« Entrée en début de mois » n'est pas construite** (`STRATEGIE-FORMATION-DES-CLASSES.md`, tableau de la partie 2). L'écran ne la promet donc pas. Il ne promet que le délai de 14 jours et le point à 7 jours, lus dans `app_config` (clés posées par ce lot, valeurs décidées le 30/09).
4. **Pays d'origine et pays de résidence de l'enseignant n'existaient pas** dans le compte d'un enseignant (`teacher_profiles.country` seul, sens ambigu ; `pays_residence` n'existe que sur la candidature). Ce lot ajoute deux colonnes, que l'enseignant remplit dans son profil. **Tant qu'il ne l'a pas fait, la carte ne montre ni l'un ni l'autre** (jamais « inconnu »).
5. **La photo reste visible ailleurs.** Le réglage « je montre ma photo et mes pays aux familles de mes classes » gouverne la carte de l'étape 4 et la lecture serveur de ce lot. La règle existante `private.photo_visible_par` (photos des personnes) laisse déjà un foyer voir la photo de l'enseignant de ses enfants sur les autres écrans ; ce lot ne la change pas. Un enseignant qui refuse n'est donc pas encore masqué partout : à arbitrer.
6. **Âge de l'enfant** : aucune date de naissance n'est en base. « Sans délai chiffré avant 10 ans » s'appuie sur `student_profiles.cohorte = 'enfant_6_9'` (la tranche 6-9 ans, lue en production comme dans `libelleTranche`) : exact tant que la tranche est tenue à jour.
7. **Heures** : le serveur rend l'heure murale du foyer (`AT TIME ZONE households.timezone`, même expression que `suivi_demandes_horaires_foyer`), et l'écran la dit par les fonctions d'affichage existantes (`libelleJalon`, `deFuseau`). Aucune conversion de fuseau nouvelle ; le lot HORLOGE n'est pas touché.
8. **Deux écrans de suivi coexistent** tant que l'architecte n'a pas tranché : l'ancienne frise à six étapes (`lib/features/suivi_famille`, `suivi_demandes`), que ce lot ne modifie pas (zone `suivi_*` interdite), et le nouvel écran. Les cartes d'accueil de ce lot mènent au nouveau ; l'ancien reste joignable par `/tuteur/demandes`. Recommandation : rediriger `/tuteur/demandes/:id` vers le nouvel écran, puis retirer l'ancien.

## 1. Ce qui est réutilisé (rien n'est refait)

| Existant | Usage |
|---|---|
| `demandes_horaires_famille`, `demande_evenements` (C-20) | Source unique des faits : `envoyee`, `classe_creee`, `en_attente`, `enseignant_affecte`, `eleve_integre`, `premiere_seance_prevue`, `close` |
| `suivi_demandes_horaires_foyer()` (garde, jointures, `peut_decrire_apprenant`) | Même garde et mêmes jointures dans la nouvelle lecture |
| Notifications `classe_validee`, `enseignant_affecte`, `private.notifier_classe`, `private.notification_courriel` | Aucun événement créé ; la table des courriels est complétée |
| `libelles_suivi_demandes.dart` (`libelleJalon`, `jourDateDemande`, `deFuseau`, `hhmmDemande`) | Dates et heures affichées |
| `BlocAsynchrone`, `Skeleton`, `EmptyState`, `EtatSysteme`, `EtatSansDonnees`, `PageShell`, `AppCard`, `LienFleche`, `ActionPrincipale`, `PileCartes`, `PaysEnseignant.parCode`, `AvatarNom`, `PhotoEnseignant` | Composants |
| `AppMouvement` (durées et courbes), `AppIcons` (Phosphor) | Animation au franchissement d'une étape |
| Messages métier (`com_ouvrir_conversation`, `com_envoyer_message`, `PortMessagesMetier`) | « Me présenter » : un message par foyer ou par élève adulte de la classe, par le fil existant (paire autorisée par le serveur) ; aucune messagerie nouvelle |
| Accueils `accueil_famille` (carte `CarteSuiviDemandes`), `accueil_adulte`, `accueil_eleve` | Emplacement de la carte compacte |

## 2. Ce qui est créé

**Serveur** (`20261123960000_suivi_attente.sql`, aucun `DROP`, `DELETE`, `TRUNCATE`) :
- `suivi_attente_foyer()` : une ligne par demande du foyer, avec les cinq étapes, le délai, le cas particulier, la carte de l'enseignant selon S4 (seulement à l'étape 4, seulement si l'enseignant l'autorise).
- `teacher_profiles` : `montre_aux_familles` (vrai pour les nouveaux, faux pour les existants jusqu'à confirmation), `montre_aux_familles_confirme_le`, `pays_origine`, `pays_residence`, `mot_presentation`.
- `regler_presentation_aux_familles(...)` : l'enseignant règle sa visibilité, ses pays et son mot ; lui seul.
- Notification de l'enseignant à l'affectation enrichie (classe, nombre d'élèves, tranche, premier cours) et courriel activé pour `enseignant_affecte` (portées `classe`, `soi`, `foyer`) : c'est une trace, S5 et S8. Cela **amende** la décision du 01/11/2026 (« application seulement ») ; le directeur l'a demandé le 12/11.
- Gabarit de courriel de l'enseignant (fr, ar, en, es, pt).
- `app_config` : `formation_delai_jours` = 14, `formation_point_jours` = 7 (si absentes).
- Scénario `supabase/tests/scenarios_suivi_attente.sql`.

**Application** :
- `lib/core/attente_classe/` : modèle, port, adaptateur Supabase.
- `lib/features/attente_classe/` : l'écran (cinq états), la frise verticale, la carte de l'enseignant, la carte compacte d'accueil, la version simple de l'élève mineur, « Me présenter ».
- Routes ajoutées : `/tuteur/attente/:demandeId`, `/eleve/adulte/attente/:demandeId`, `/eleve/attente/:demandeId`.
- Textes fr et ar, préfixe `suiviAttente`.

## 3. Les cinq étapes et ce qui les franchit

| Étape | Mot | Franchie quand (fait serveur) |
|---|---|---|
| 1 | Demande reçue | événement `envoyee` |
| 2 | Classe en formation | en cours dès l'étape 1 ; franchie à l'étape 3 (pas de date propre : l'écran n'en invente pas) |
| 3 | Classe confirmée | événement `classe_creee` |
| 4 | Enseignant affecté | événement `enseignant_affecte` |
| 5 | Tout est prêt | étapes 3 et 4, élève intégré (`eleve_integre`) et première séance connue ; date = la plus tardive de ces dates |

Cas hors du chemin droit, chacun avec son état et son geste : demande refusée (motif et suite), demande retirée, classe en attente d'enseignant (`en_attente`), liste d'attente, changement de créneau (`creneau_change` récent).

## 4. Choix pris seul

- Le délai affiché est une date limite calculée à partir de la date de la demande et de `formation_delai_jours`. Dépassé, l'écran le dit et dit ce que fait l'académie ; il ne dit jamais « bientôt » quand une date est connue.
- Le réglage de visibilité de l'enseignant vaut faux pour les enseignants existants (aucun n'a confirmé) : la carte ne montre alors que nom et langues.
- Le mot de présentation est limité à 500 caractères, texte libre de l'enseignant, affiché sans modification.

## 5. Angles morts découverts

- Le gabarit de courriel `enseignant_affecte` n'avait pas de branche pour l'enseignant : s'il était parti, l'enseignant aurait lu le texte écrit pour la famille (« Voir la classe », `/tuteur/demandes`).
- La migration `0043` pose des tranches (`enfant_5_7`, `enfant_8_10`...) que des migrations ultérieures ont remplacées (`enfant_6_9`, `enfant_10_13`, `ado_14_17`) : lire la base rejouée, pas `0043`.
- L'accord de publication existant (CAND-PHOTO) vise le site public ; il n'est pas le réglage de ce lot et n'a pas été réutilisé.

## 6. Preuves (mises à jour à la fin)

À remplir : résultats des six vérifications, scénario SQL, captures `docs/current/captures/E2E/suivi-attente/`.
