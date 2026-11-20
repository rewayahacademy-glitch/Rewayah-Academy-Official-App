# Plan de lancement resserré (20/11/2026)

Ordre du directeur (20/11/2026) : « on valide cette maquette pour aller vite. Lance les
chantiers et surtout recadre bien le plan pour ne pas qu'on s'éparpille. »

**Ce qui est faux ou non prouvé** : la maquette du tableau de bord est validée par le directeur
(20/11), mais rien n'est encore dans l'application. Les quatre chantiers ci-dessous viennent
d'être lancés ; aucun n'est fusionné, aucun n'est prouvé en production.

## 1. Quatre chantiers, quatre zones, rien d'autre

Règle : quatre agents au plus, zones de fichiers séparées, une PR par chantier, le pilote
fusionne (`DECISION-QUATRE-AGENTS-2026-11-02.md`). Tout écran touché applique
`CONTRAT-NAVIGATION.md`. Un agent ne sort pas de sa zone ; s'il en a besoin, il s'arrête et le
dit.

| Chantier | But, en une phrase | Lots du suivi | Zone de fichiers | Branche |
| :--- | :--- | :--- | :--- | :--- |
| **1. RACINE** | Plus rien ne pousse la page, la sélection de texte redevient normale, la mise à jour se propose | PE-D8, PE-D9, PE-D11 | `lib/app.dart`, `lib/core/widgets/selection_racine.dart`, `lib/core/version/`, `lib/core/fraicheur/`, `lib/core/widgets/offline_banner.dart`, `lib/features/com_messages/bandeau_messages_hors_direct.dart`, champs de saisie communs | `claude/pe-racine` |
| **2. ENTRÉE** | Le lien reconnaît le candidat ; « Apprendre » ou « Enseigner » ; plus d'écran parasite avant le code d'un invité | PE-A2, PE-A3, PE-A9 (partie écran) | `lib/features/connexion/`, `lib/features/inscription/` | `claude/pe-entree` |
| **3. BUREAU-NAV** | Un seul dossier par personne, le retour ramène d'où l'on vient, l'icône des messages reste, le bouton ne reste plus figé | PE-C1, PE-D4 (bureau), PE-C7 (icône), PE-D12 (délai) | `lib/core/router/`, `lib/core/widgets/admin_shell.dart`, `lib/features/admin_candidature/`, `lib/features/admin_comptes/` et `lib/features/com_messages/apercu_profil_candidat.dart` (liens vers le dossier), `lib/features/notifications/` (destination) | `claude/pe-bureau-nav` |
| **4. VIVANT** | Les composants de mouvement communs entrent dans l'application, et le tableau de bord validé remplace l'ancien | PE-F7, PE-F4, PE-C6 | `lib/core/vivant/` (nouveau), `lib/core/theme/app_radius.dart`, `lib/features/admin_tableau/tableau_de_bord_page.dart` et ses fichiers | `claude/pe-vivant` |

Le chantier 3 ne touche **aucun fichier** de `lib/features/admin_tableau/` : c'est le chantier 4
qui refait la page et y applique lui-même le contrat (un nombre ouvre sa liste filtrée, une
personne ouvre le dossier complet).

## 2. Ce qui est gelé jusqu'à la fusion de ces quatre chantiers

Aucun agent ne commence, même « un petit bout » :
- l'espace de l'élève et des familles (ordre du directeur du 19/11) ;
- l'accueil de l'enseignant, les cartes des Classes (vague E) : après les références ;
- les icônes et Praxis animé dans l'application (PE-F1, PE-F2, PE-F5) ;
- la compétence du mouvement (PE-F6) ;
- Praxis qui range les dossiers (vague G) ;
- l'application Android (estimée, non lancée) ;
- les annonces ciblées, la suppression de message, les gestes de glissement hors de la pile ;
- tout ce qui demande une migration de la base : le garde-fou de cette session interdit
  d'écrire dans `supabase/` ; ces lots (courriels dans la langue, retrait sur 7 jours, rôle
  « associé » côté serveur, dernière connexion, épinglage) attendent le pilote des migrations.

## 3. L'ordre après ces quatre chantiers

1. Les lots qui demandent le serveur, en une seule série de migrations : PE-A1 (courriels),
   PE-A6 (retrait), PE-A7 (avis de créneau), PE-A9 (rôle associé), PE-C2 (dernière connexion),
   PE-C5 (épingler), PE-C10 (complément précoché).
2. Le parcours du candidat : PE-B1 (juz, lectures), PE-B4 et PE-B5 (accueil à trois onglets).
3. La liste des personnes : PE-C4 (tri, complet, gestes groupés), PE-C8 (trois pages).
4. La messagerie : PE-D1, PE-D2.
5. Le reste, sur ordre du directeur.

## 4. Fini veut dire

Une PR ouverte, les vérifications de `CLAUDE.md` passées, les cinq questions du contrat de
navigation répondues dans la PR, la ligne du suivi à jour. Puis fusion par le pilote, puis
preuve par le directeur en production. Avant cela, le statut est « PR ouverte », jamais « fait ».
