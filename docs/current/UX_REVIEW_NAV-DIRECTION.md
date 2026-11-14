# UX_REVIEW : NAV-REFONTE étape 4, panneau de la direction (part sans décision ouverte)

Date : 11/11/2026. Feu vert du pilote le 11/11/2026, sur `main` 6fe6b35c.
Maquettes : « Panneau de la direction sur ordinateur » et Revue du 09/11.
Captures : `docs/current/captures/E2E/nav-direction/`, faites sur la pile locale sans personne connectée.

**Ce qui n'est pas prouvé.** Le directeur n'a rien vu en production. Le nom et la photo réels d'un compte de la direction au pied de la colonne n'ont pas été capturés : sans personne connectée, le pied montre « Mon compte » et l'initiale.

## Ce lot

| # | Règle | Source | Conclusion | Modification |
| :- | :- | :- | :- | :- |
| 1 | Une commande garde la même place d'un état à l'autre | Nielsen n° 4 ; Apple HIG « Sidebars » | La direction n'avait pas de bouton : à partir de 1200, la colonne était toujours ouverte. | Le même `BoutonPanneau` que les rôles, à partir de 1200, à 16 du bord de début, ouvert comme replié (test en ltr et en rtl). Le choix est gardé par appareil (`navigation.repliee`, partagé avec les rôles). |
| 2 | Le compte en pied, une seule porte vers lui | Material 3 « Navigation drawer » ; maquette de la direction | Il y avait deux entrées vers le compte : le pied (« Administrateur ») et le menu en haut à droite (P1). | Le même `PiedComptePanneau` que les rôles : photo ou initiale, prénom lu sur le profil, menu Mon compte · Thème · Se déconnecter. Le bouton Compte quitte l'en-tête à partir de 600. Au téléphone, la barre et le tiroir ne changent pas. |
| 3 | Rail replié : icônes avec infobulles | Material 3 « Navigation rail » | Déjà en place. | Le pied s'y ajoute : la photo seule, son nom en infobulle. |
| 4 | Un filet visible entre la colonne et la page | Gestalt (séparation des régions) | Le rail Material peignait son fond par-dessus la bordure, et le filet ne se voyait pas, déjà sur `main`. | Le filet est maintenant peint au premier plan. |
| 5 | Texte agrandi, arabe, sombre | WCAG 1.4.4 et 1.4.10 | Vérifié à 800 et 1440, ×1 et ×2, clair et sombre, en ltr et en rtl : le pied reste dans la colonne et aucun mot n'est coupé. | Aucune. |

Les huit domaines ne changent pas : mêmes noms, même ordre, mêmes routes, mêmes droits.

## Ce qui attendait le directeur : tranché le 14/11/2026 (NAV-SOUS-LIENS)

Le directeur ne tranche pas les choix d'interface : règle 19 de `docs/orchestration/CONSIGNES-DIRECTEUR-EN-VIGUEUR.md` (14/11 : « ne lui impose pas mes choix UX, dis-lui d'utiliser les meilleurs standards » ; « ces onglets ne sont pas pour le web »). Les sept points sont arbitrés avec la compétence `design-taste-frontend` (écrans d'application, § Sidebar) et les standards nommés ci-dessous. Branche `claude/nav-sous-liens`.

**Ce qui n'est pas prouvé.** Le directeur n'a rien vu en production. Les captures sont faites sans personne connectée et sans données (page vide sous son titre).
Captures : `docs/current/captures/E2E/nav-sous-liens/` (1440, 1024, 800 et 390 ; fr et ar ; clair et sombre ; panneau ouvert par-dessus la page ; menu du rail ; texte à 200 %).

| # | Point en attente | Règle | Source | Arbitrage | Modification |
| :- | :- | :- | :- | :- | :- |
| 1 | Noms des sections | Des titres de groupe courts, en phrase, à l'encre douce, jamais en capitales espacées. Ils regroupent les domaines sans les réordonner. | Apple HIG « Sidebars » (sections) ; Material 3 « Navigation drawer » (en-têtes de section) ; `design-taste-frontend`, app-screens §3.2 « Groups » | **« Au quotidien »** (Accueil, Opérations, Personnes), **« Académie »** (Pédagogie, Finance) et **« Réglages et contrôle »** (Configuration, Sécurité et audit, Direction). « École » est écarté : `mots-rewayah` (13/11) dit « l'académie », jamais « l'école ». | `SectionAdmin` (`admin_domaine.dart`). Titres dans le panneau et le tiroir ; dans le rail, un filet court entre deux sections. Ordre des huit domaines inchangé. |
| 2 | Retrait des 11 cartes outils de l'Accueil | Une information à un seul endroit ; on ne retire une entrée que si son chemin existe ailleurs. | Nielsen n° 8 (design minimaliste) ; Nielsen n° 6 (reconnaître plutôt que se souvenir) | **Retirées sur tablette et ordinateur, gardées au téléphone.** Chacune des 11 a un sous-lien équivalent : Espace de traitement, Classes à ouvrir, Offres vitrine, Avis des familles, E-mails, Pilotage des horaires, Planning de la semaine, Classes et Communications sous Opérations ; Comptes sous Personnes ; Accès des agents IA sous Sécurité et audit. Le tiroir du téléphone n'a pas de sous-liens : les cartes y restent. | `TableauDeBordPage` : la carte « Outils » n'est rendue que si le panneau ne porte pas les 11 adresses (`SousLiensCoquille.couvre`). |
| 3 | « Demandes d'admission » pour Personnes | Un libellé dit « quoi » ; deux entrées voisines ne portent pas le même mot. | `lib/CLAUDE.md`, « Aucun libellé ambigu » ; Nielsen n° 4 (cohérence) | **« Demandes d'admission »**, au panneau comme dans le sélecteur de la page au téléphone. « Demandes » seul se confondait avec les demandes des familles d'Opérations. Le domaine garde son nom, « Personnes ». | Nouvelle clé `nav.admin.sousLiens.admissions` (fr, ar, en), déclarée dans `tool/libelles_sources.json`. |
| 4 | E-mails rangés dans Communications | La barre latérale mène à des écrans, jamais à des onglets d'une page. Les entrées de même nature sont voisines. | `design-taste-frontend` §3.2 « Nav items are other screens » ; Gestalt (proximité) | **E-mails reste sa propre page.** Dans le panneau, il est rangé juste après Communications, et Avis des familles le suit (tout ce qui parle aux familles). On ne fusionne pas les pages : leurs adresses, leurs droits et leurs tests ne changent pas. | Ordre des sous-liens d'Opérations. |
| 5 | Les 4 vues de Comptes : en sous-liens, ou sélecteur dans la page | Le panneau mène à des lieux ; changer de vue d'une même liste (avec son nombre) est un contrôle segmenté de la page. | Apple HIG « Segmented controls » ; Material 3 « Segmented buttons » ; `DECISION-LISTES-2026-10-23.md` | **Le sélecteur reste dans la page.** Sur ordinateur, quatre vues tiennent en ligne : c'est un contrôle segmenté, pas un menu déroulant de téléphone. Comptes est un seul sous-lien. | Aucune. |
| 6 | À 800 : le panneau pousse-t-il la page, ou passe-t-il par-dessus avec un voile ? | Sous la largeur où panneau et page tiennent côte à côte, le panneau est modal, par-dessus la page avec un voile. | Material 3 « Navigation drawer » (modal sous 1240 dp, standard au-dessus) ; Windows « NavigationView » (compact puis overlay) | **Par-dessus, avec un voile**, de 600 à 1199. Le rail garde le bouton du panneau, à la même place ; le panneau s'ouvre entier (sections et pages du domaine ouvert). Il se ferme par son bouton, par Échap, en touchant le voile ou en choisissant une page. La page garde sa largeur. | `drawer` du `Scaffold` en rail (`_Tiroir(surTablette: true)`). Le rail ouvre aussi les pages d'un domaine en menu (`MenuActions`) : deux gestes vers n'importe quelle page. |
| 7 | En Mode Accessibilité, le panneau est-il ouvert par défaut ? | En Interface guidée, les libellés restent visibles. | `lib/CLAUDE.md`, MA-NAV-1 ; WCAG 2.4.6 | **Oui, à partir de 1200**, tant que la personne ne l'a pas replié elle-même. C'est déjà le comportement (`navigation.repliee` vaut « ouvert » sans choix). Sous 1200, le rail reste replié pour garder la largeur de la page, et le panneau s'ouvre par-dessus. | Aucune. **Limite connue** : sous 1200, le rail de la direction n'affiche pas de libellé sous l'icône en Interface guidée, contrairement à `NavShell`. Ce n'était pas en jeu dans ce lot. |

### Ce que fait le lot, en plus des sept points

- **Sous-liens dans le panneau.** Le domaine ouvert déplie ses pages sous lui, en retrait sur la colonne de son libellé. Les pages viennent des mêmes listes que les sélecteurs des pages : mêmes adresses, mêmes droits. Les pages sans serveur ne sont pas montrées (PORTS-DIRECTION : vue globale de la Finance, réserve de délégation) ; la politique KYC ne l'est qu'à qui peut la régler.
- **La page ouverte** a trois signaux : fond doux, encre d'accent et graisse. Elle est annoncée « sélectionnée » et « lien » au lecteur d'écran (Material 3 ; WCAG 1.4.1).
- **Sélecteur retiré sur ordinateur.** `SousNavigationDomaine` ne se montre plus quand le panneau porte déjà toutes ses sections (`SousLiensCoquille`). Au téléphone, et pour la comptabilité (autre coquille), rien ne change.
- **Clavier (WCAG 2.4.3 et 2.4.11).** Tab suit l'ordre des entrées du panneau (`WidgetOrderTraversalPolicy`), puis passe à la page. L'entrée qui reçoit le focus est amenée dans la vue quand le panneau déplié défile.
- **Texte à 200 % (WCAG 1.4.4).** Un sous-lien n'est jamais coupé : il passe à la ligne et sa rangée grandit.
- **Inchangé.** Huit domaines au plus ; mêmes noms, ordre, routes et droits ; « l'académie » ; `#Ra_staff` et le logo (`BrandLogo`) intacts ; aucun neuvième domaine (Communications et Le Studio restent des pages).

### Vérifications locales (14/11/2026)

- `dart run slang`, `dart analyze --fatal-infos` : aucun problème.
- `verifier_jetons`, `verifier_branchement`, et `verifier_revue` avec les règles de la CI : verts.
- Tests de la coquille : `test/widgets/admin_shell_panneau_test.dart` (sections, sous-liens, page sélectionnée, menu du rail, voile à 800, sélecteur retiré à 1440 et 800 et gardé à 390), `admin_shell_test`, `admin_coque_test` et `admin_ad11_test` (texte à 200 %, clavier, cibles de 48).
- Tests existants adaptés au nouveau geste, sans en retirer une vérification : `choisirSection` (`test/support/selecteur_section.dart`) passe par le sous-lien du panneau ou par le menu du rail quand la page n'a plus de sélecteur. Le rail de 768 ouvre le menu de Personnes avant d'aller aux dossiers.
