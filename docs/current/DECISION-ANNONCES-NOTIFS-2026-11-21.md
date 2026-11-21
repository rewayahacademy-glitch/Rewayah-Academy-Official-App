# Annonces et notifications : panneau de la cloche, annonces qu'on ferme, traduction automatique

**Directeur, 21/11/2026.** Ce document prévaut sur toute règle antérieure sur l'affichage des annonces et des
notifications, en particulier sur « annonces (jusqu'à 5, jamais masquables) » (`PARCOURS-ENSEIGNANT/PLAN.md` §2 et §4.2),
qui est **abrogée**.

Citations du directeur :
- « annonce jamais masquable ? […] c'est faux ça […] on n'est pas obligé de respecter une règle qui n'est pas réaliste. »
- « il faut traduire automatiquement les annonces, l'app est hybride et cosmopolite ; elle doit s'adapter pour le bien des
  users. »
- « je préfère le style C, le dernier. mais fais tout possible pour que le rendu final soit fidèle et responsive, pense
  toujours aux états (quand c'est ouvert, fermé, interactions, etc.) »
- « pour ces pages de notifs, n'oublie pas côté candidats. »
- Constat du même soir : « ça s'empile, toutes les annonces s'empilent et ne se ferment jamais […] imagine si on a 100
  annonces ».

Maquette retenue : **style C**, canevas https://claude.ai/artifact/F2dW256uDwA6eAdtyQNinC (artboard « C. Panneau de la
cloche »). Les règles communes du canevas valent aussi.

## 1. Les règles

1. **Une seule entrée : la cloche.** Sur ordinateur (840 points et plus), elle ouvre un **panneau ancré** de 400 points
   de large sous l'en-tête, hauteur limitée à la fenêtre, qui défile seul (seule exception admise au défilement de la
   page : un panneau flottant, comme un menu). Sur téléphone, elle ouvre une **feuille par le bas** (`AppBottomSheet`,
   90 % de la hauteur au plus, poignée, croix). « عرض الكل » mène à la **page complète** (route existante des
   notifications), qui suit les mêmes lignes.
2. **Trois onglets** dans le panneau, la feuille et la page : « الكل », « الإعلانات », « مطلوب منك » (avec leur nombre
   non lu). `SelecteurSection`, jamais une rangée qui défile.
3. **Une ligne par élément**, deux lignes de texte au plus : icône de la catégorie, titre en gras quand non lu, une
   ligne de texte, l'heure ; l'action quand il y en a une (« تولّي الحصة », « افتح الرابط ») **sur la ligne**.
   Toucher la ligne ouvre le détail (feuille sur téléphone, panneau de lecture sur ordinateur) et la marque lue.
4. **Une annonce se ferme.** Croix sur la ligne et dans le détail. Fermée, elle quitte « الكل » et la page d'accueil ;
   elle reste lisible dans « الإعلانات » 90 jours (durée actuelle du serveur). Lue n'est pas fermée.
5. **Pagination** : 20 éléments à la fois, puis « عرض المزيد » (curseur serveur). Jamais une pile infinie.
6. **Traduction automatique des annonces** : chaque annonce est traduite **au serveur, à l'envoi**, dans les langues de
   l'application (fr, en, ar), par la fonction de traduction déjà en service pour les courriels
   (`supabase/functions/_shared/courriel/traduction.ts`, `GOOGLE_TRADUCTION_CLE`), avec les mêmes protections (le nom
   de la marque, et les passages en arabe d'un texte qui n'est pas traduit vers l'arabe : versets, invocations). Le
   lecteur reçoit le texte **dans la langue de son compte**, avec « عرض النص الأصلي » pour l'original. Si la traduction
   manque ou a échoué : le texte original, jamais un vide, et le serveur réessaie.
7. **Les liens** d'une annonce deviennent un bouton (ANNONCE-LIENS, PR 689).
8. **Tous les rôles**, y compris le **candidat** (portail `/attente`, qui n'a pas la cloche aujourd'hui : il reçoit la
   même cloche dans son en-tête) et l'enseignant actif.
9. **États obligatoires**, à 390, 1280 et 1440, clair et sombre, fr et ar : fermé, ouvert, chargement (squelette), vide
   (une phrase par onglet), erreur (cause et « إعادة المحاولة »), hors ligne, page suivante en cours, élément fermé
   (disparition animée, « تراجع » pendant 5 s), tout lu.
10. **Rien d'étiré sur ordinateur** ; largeur de lecture 800 au plus pour la page complète.

## 2. Le contrat (serveur vers écrans)

À tenir par les deux lots ; l'adaptateur Supabase le respecte, les écrans ne lisent que ce contrat.

- `public.com_mes_annonces(p_limite int default 20, p_avant timestamptz default null, p_langue text default null,
  p_fermees boolean default false)` → `{ "annonces": [ { id, titre, texte, titre_original, texte_original,
  langue_originale, traduite (bool), publiee_le, vue (bool), fermee (bool) } ], "suite": <timestamptz|null> }`.
  `p_fermees = false` : seulement les annonces non fermées (onglet « الكل » et accueil) ; `true` : toutes (onglet
  « الإعلانات »). `suite` est le curseur de la page suivante.
- `public.com_annonce_fermer(p_annonce_id uuid)` et `public.com_annonce_rouvrir(p_annonce_id uuid)` (pour « تراجع »),
  idempotentes, réservées au lecteur de l'annonce.
- Côté Flutter, `PortAnnoncesDirection` gagne `mesAnnonces({int limite = 20, DateTime? avant, bool fermees = false})`
  (rend `PageAnnonces { List<AnnonceRecue> annonces; DateTime? suite; }`), `fermer(String id)`, `rouvrir(String id)` ;
  `AnnonceRecue` gagne `texteOriginal`, `titreOriginal`, `langueOriginale`, `traduite`, `fermee`.
- Les notifications gardent leur port (`liste`, `lues`, `ecarter`, `marquerLue`, `marquerToutesLues`).

## 3. Les lots

| Lot | Contenu | Zone |
| :--- | :--- | :--- |
| ANNONCES-SERVEUR | Migration : table des fermetures et des traductions, les trois fonctions du contrat, pagination ; fonction Edge (ou extension de `courriels-envoi`) qui traduit à l'envoi ; scénarios SQL | `supabase/**`, adaptateur `*_supabase.dart` |
| CLOCHE-C | Panneau, feuille, page complète, détail, tous les états, tous les rôles dont le candidat ; captures | `lib/features/notifications`, `lib/features/com_annonces`, `lib/core/widgets` |
| GUIDE-COMMENTAIRES-PILE | La page des commentaires du guide ne s'empile plus (fils repliés, « en attente » d'abord, 5 fils puis « voir plus ») | `lib/features/admin_guide` |
