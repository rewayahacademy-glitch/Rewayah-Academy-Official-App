# Recrutement des enseignants : état réel et plan pour finir (16/11/2026)

Demande du directeur, 16/11/2026 : « regarde le processus et dis-moi où on en est et donne-moi le
plan qu'on va suivre pour finir, parce que sinon ça va se perdre ». Ce document est **la carte unique**
du chantier. `SUIVI.md` garde le statut de chaque lot ; ce document dit **dans quel ordre** et
**pourquoi**. Toute nouvelle demande du directeur y prend sa place le jour même (règle en fin de page).

Chiffres lus en production le 16/11/2026 vers 13 h (lecture seule, comptes agrégés).

## 1. Le parcours d'un enseignant, de bout en bout

| # | Étape | Qui doit agir | Nombre aujourd'hui | Bouchon ? |
| :--- | :--- | :--- | ---: | :--- |
| 0 | A répondu à un ancien formulaire (papier, QR code, Google) | — | 1 633 réponses | |
| 1 | Reçoit l'invitation « créez votre compte » | l'académie (envoi) | 1 217 réponses **sans candidature dans l'application** | **OUI, n° 3** |
| 2 | Crée son compte et retrouve sa candidature | le candidat | 38 ont un compte **non rattaché** à leur réponse (égarés) | oui |
| 3 | Remplit la salle 1 (questionnaire) | le candidat | 80 candidatures sans réponse envoyée | |
| 4 | Préqualification : examen du dossier | **la direction** | **212 en examen** | **OUI, n° 2** |
| 4 bis | Préqualification : réponse à compléter | le candidat | 117 à compléter | |
| 4 ter | Préqualification : versement impossible | **la direction** (pays) ou le candidat | 57 (31 attendent une **décision de pays**) | **OUI, n° 4** |
| 5 | Vérifications : entretien à planifier | **la direction** (ouvrir des moments) | **43 attendent** ; **0 moment d'entretien jamais ouvert** | **OUI, n° 1** |
| 6 | Confirmée | — | 1 | |
| 7 | Accueil de l'enseignant (salle 3 : contrat, profil, premières classes) | | 0 arrivé | **INCONNU** : jamais parcouru de bout en bout |
| 8 | Première classe | | 0 | INCONNU |

Lecture : le flux est bloqué **avant** l'entretien et **à** l'entretien. Le temps passé hier et
aujourd'hui sur des retouches d'écran n'a fait avancer aucun candidat au-delà de l'étape 5.

## 2. Les goulots, du plus grave au moins grave

1. **Entretiens : aucun moment ouvert.** L'écran pour en ouvrir existe déjà
   (`admin_candidature/creneaux_entretien_page.dart`, fonctions `ouvrir_creneau_entretien`,
   `ouvrir_plage_entretien`). Personne ne s'en est servi. Tant qu'il n'y a pas de moments, les 43
   candidats retenus attendent et écrivent au directeur. Pour 1 500 candidats, il faudra des
   intervieweurs autres que le directeur, donc la **vague 2 (la mission)**.
2. **Examen des dossiers : 212 attendent une seule personne.** Les outils pour aller vite sont à
   moitié livrés : dossier en trois étages et liste en tableau (dans main), mais « précédent /
   suivant » (#516) et la liste à une seule rangée de filtres (#515) ne sont pas fusionnés, et les
   colonnes triables (BE-COLONNES), le tri par l'IA et la délégation n'existent pas.
3. **1 217 réponses jamais arrivées dans l'application.** Les invitations partent sous un plafond
   d'envoi ; 13 adresses sont mal écrites ; 38 personnes ont un compte mais leur réponse n'est pas
   rattachée (la cause est corrigée par #524 pour les prochains, pas pour ces 38).
4. **31 candidats attendent une décision par pays** (13 pays « en vérification » : Algérie, Bénin,
   Burkina Faso, Égypte, Ghana, Guinée, Kenya, Liberia, Mali, Maroc, Niger, Soudan, Tchad). Une
   décision du directeur par pays débloque tout le pays d'un coup.
5. **Après la confirmation, rien n'a été parcouru.** Contrat, profil d'enseignant, salle 3 et
   première classe : on ne sait pas si le chemin fonctionne. Il faut le parcourir **avant** que le
   premier enseignant y arrive.

## 3. Où en sont les lots demandés au départ (vagues 0 et 1)

| Lot | Statut |
| :--- | :--- |
| BE-0a message en double | dans main |
| BE-0b historique détaillé, BE-1a ordre des dossiers et filtres | dans main, installé |
| BE-1d dossier en trois étages, BE-DOSSIER-2 corrections | dans main |
| BE-0c / BE-1c retours, une seule file | dans main |
| BE-VERSEMENT, VERSEMENT-QUESTIONS | dans main, installé |
| BE-1b précédent / suivant | **PR #516 en conflit** |
| BE-LISTE-2 une seule rangée de filtres | **PR #515 arrêtée** : cible non atteinte (572 pt au lieu de 300), version « menu déroulant File » demandée le 16/11 non livrée |
| MAJEUR (18 ans ou plus) | **PR #517 en conflit**, 2 700 lignes, migration à installer avant la fusion |
| BE-COLONNES | pas commencé |
| BE-1e panier de demandes | pas commencé |
| BE-1f grille des disponibilités | pas commencé |
| BE-1g impression, dispense d'entretien, fondateurs | pas commencé |
| Écran « Débloquer le versement » | pas commencé (serveur prêt) |

Retouches faites hors plan les 15 et 16/11, parce qu'elles bloquaient de vraies personnes : Ghana
introuvable (#513), « rien à faire » en attente d'entretien (#521), « Postulez ici » (#523), égarés
(#524), décision et correction du versement (#526 à #529). Encore ouverte : la case Cloudflare (#525,
à voir dans un vrai navigateur).

## 4. Le plan pour finir, dans cet ordre

Une étape ne commence que quand la précédente est livrée ou explicitement mise de côté par le directeur.

**Étape A, aujourd'hui : débloquer les entretiens (goulot 1).**
- Directeur : ouvrir des moments d'entretien dans l'écran existant (ou dire qui interviewe).
- Pilote : parcourir cet écran et le parcours « je choisis un moment » côté candidat, de bout en
  bout, avec un compte de test ; corriger ce qui casse ; puis prévenir les 43 candidats.

**Étape B, aujourd'hui : les 13 pays (goulot 4).** Le pilote présente la liste des 13 pays avec, pour
chacun, ce que Wise permet ; le directeur tranche en une fois ; 31 candidats repartent.

**Étape C, cette semaine : finir les outils d'examen (goulot 2).** Dans l'ordre : #516 (précédent /
suivant) ; #515 refaite selon la révision du 16/11 ; BE-COLONNES ; #517 MAJEUR (à recouper ou
installer) ; écran « Débloquer le versement » ; BE-1g (dispense d'entretien et fondateurs).

**Étape D, cette semaine : les 1 217 réponses perdues (goulot 3).** Rattacher les 38 comptes égarés ;
corriger ou relancer les adresses mal écrites ; relever le plafond d'envoi des invitations ou les
étaler, sur décision du directeur.

**Étape E : parcourir l'après-confirmation (goulot 5).** De « confirmée » à « première classe », avec
un compte de test, avant le premier vrai enseignant. Chaque trou devient un lot de ce plan.

**Étape F : déléguer (vague 2, la mission).** Inviter des associés par courriel, leur donner des droits
à la carte (examiner, interviewer, écrire), pour sortir le directeur du goulot. Sans elle, les
étapes A et C restent limitées à une seule personne.

**Ensuite, dans l'ordre :** vague 3 (listes enregistrées, écrire à une liste), le secrétaire IA
(SEC-0 à SEC-5), vague 4 (Studio), vague 5 (l'IA qui propose). BE-1e et BE-1f s'y placent quand le
directeur le décide.

## 5. Règle pour ne plus rien perdre

1. Toute demande du directeur sur ce chantier prend **le jour même** une ligne dans ce plan (étape)
   et dans `SUIVI.md` (statut). Une demande sans ligne n'existe pas.
2. Une retouche hors plan n'est faite que si elle débloque une personne réelle ; elle est notée au §3.
3. Chaque soir, le pilote relit ce document, met à jour les chiffres du §1 et dit au directeur
   quelle étape avance et laquelle bloque.
4. Un lot n'est pas « fini » tant qu'il n'est pas fusionné, installé et prouvé par le directeur ;
   une PR ouverte depuis plus d'un jour est relancée ou fermée, jamais oubliée.
