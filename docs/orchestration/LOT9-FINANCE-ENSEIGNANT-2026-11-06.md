# Lot 9, FINANCE-ENSEIGNANT (PLAN-LOTS 22 h), bilan du 06/11/2026

Décision du directeur, 06/11/2026 vers 22:12 UTC, relayée par le garde-cap : « pour payer les
enseignants […] on passera par wise, qui permet d'importer un fichier excel pour le bulk paiement. tu
dois préparer un système qui peut importer les données des enseignants pour qu'ils reçoivent leurs
paiements via wise (juste un CSV)... après le lancement on va connecter pawa pay et éventuellement
verto ».

## D'abord ce qui est faux, bloqué ou non prouvé

0. **Le Yémen est interdit par Wise** (https://wise.com/help/articles/2978049/where-can-i-use-wise :
   « Sudan, Syria, Yemen, Venezuela… », ni envoi ni réception, un compte utilisé depuis ces pays peut
   être restreint). Les enseignants qui vivent au Yémen ne peuvent pas être payés par Wise : la
   direction les paie autrement et le note (« Noter un versement fait »). **Refus à la saisie** (accord
   du garde-cap) : le serveur refuse un compte dont le pays (adresse du titulaire) a le virement
   bancaire « indisponible » dans `public.referentiel_paiement` (source unique, CAND-L6 ; aucun réglage
   nouveau). **Le Yémen n'y est pas encore « indisponible »** : la migration du lot CAND-BANQUE le pose ;
   d'ici là, rien ne bloque. Un enseignant au Yémen peut donner le compte d'un proche dans un autre pays
   (testé : Arabie saoudite acceptée).
   Tableau des pays (aide Wise, 06/11) : Nigéria, Côte d'Ivoire, Sénégal, Arabie saoudite : USD par
   SWIFT listé (2974947), aucun n'est interdit (2978049) ; Arabie saoudite **prouvée par le directeur**
   (il y vit et l'a testée) ; monnaie locale : NGN listé, XOF non (Sénégal) ou non trouvé (Côte
   d'Ivoire), SAR contradictoire entre deux pages.
 Wise envoie des USD par SWIFT vers un compte
   en USD en Guinée, au Mali, en Mauritanie, au Sénégal, au Maroc, en Égypte et en Arabie saoudite
   (https://wise.com/help/articles/2974947) pour un virement simple ; aucune page ne dit qu'un
   **paiement groupé** passe par cette voie. **Des banques intermédiaires peuvent retenir des frais sur
   un virement SWIFT en USD ; Wise ne les garantit pas ; non vérifié.** Le seul enseignant actuel est
   en Guinée.
2. **Voie SWIFT USD seule.** Une devise (USD, source et cible), un modèle : décision du directeur du
   06/11 (22:30 UTC). Aucune autre devise n'est codée.
3. **Frais Wise : tranché par le directeur** (06/11, 22:30 UTC) : l'académie les paie
   (`amountCurrency = target`, réglage `versement.wise_type_montant`).
4. **Modèle Wise : celui téléchargé par le directeur le 06/11/2026** (« Envoyer vers des comptes
   bancaires », USD vers USD), ses 17 en-têtes posés par défaut dans la migration. Si Wise change son
   modèle, une version nouvelle se pose (`poser_modele_wise`), sans rien effacer.
5. **Aucune migration installée.** Rejouées seulement sur un Postgres 16 nu (stub + toutes les
   migrations du dépôt). Ordre : **après `20261110210000` (lot 2)** ; elles appellent
   `releve_paie_mensuel` sans le redéfinir.
6. **Le scénario Wise remplace le relevé de paie dans sa transaction** par un relevé fixe : il prouve
   l'export, pas le calcul du dû.
7. **Captures** : 24 captures de widgets, 390 et 1440, FR et AR, avec de faux ports
   (`docs/current/captures/E2E/finance-enseignant/`). Pas le robot de la pile locale, pas la production.
8. **Scénarios SQL hors CI** (`.github/` interdit aux agents) : lignes plus bas.
9. **Coordonnées stockées en clair** (Wise en a besoin). Protection : RLS, aucun droit direct
   (service_role compris), lecture complète par l'export seul (direction, comptabilité), chaque export
   journalisé. Pas de chiffrement de colonne.
11. **Deux modèles de courriel ajoutés** dans `supabase/functions/_shared/courriel/` (fr, ar ; traduits à
    l'envoi pour les autres langues) : `coordonnees_versement_changees`,
    `coordonnees_versement_validees`. **La fonction Edge `courriels-envoi` doit être redéployée** pour
    les connaître ; sans cela, ces courriels restent en file. Tests Deno du dossier : 33 verts.
12. **Démonstration du Comptable** : `lib/features/demo/comptable/coordonnees_versement_demo.dart`
    ajouté et branché (lib et `test/support`), pour que la route de démonstration de « Recevoir mes
    paiements » ne dise pas « Pas encore disponible ».
10. **Fichiers retirés et déplacé** (accord du garde-cap, 06/11) : retirés
    `lib/features/paiements_recus/etat_mes_moyens.dart` et `feuille_ajout_moyen.dart` ; déplacé
    `lib/core/capacites/port_mes_moyens_paiement.dart` vers `lib/features/demo/comptable/`.
    `docs/current/INVENTAIRE-NON-BRANCHE-2026-10-31.md` (ligne 137) cite encore l'ancien chemin.

## 1. Inventaire de l'existant (06/11, `main` 7b3a3f05)

| Élément | État | Sort |
|---|---|---|
| Écran « Recevoir mes paiements » (`lib/features/paiements_recus/`), routé (`/compte/paiements-recus`), rubrique dans Compte et Profil enseignant | présent, branché à l'interface, port sans source | **route, rubrique et emplacements réutilisés ; contenu refondu pour Wise** |
| `PortMesMoyensPaiement` (flux « jeton chez un prestataire ») | production = indisponible | **remplacé** par `PortCoordonneesVersement` ; le fichier reste (démo) |
| `PortPayout`, `PortBeneficiairesPaiement`, `PortCapacitePayout` | bouchons | non touchés |
| `public.payout_methods` (`details jsonb`), `public.payouts` (portefeuille de foyer) | 0 ligne en production | **écartés** : jsonb libre, et rattachés aux familles |
| Paie due : `releve_paie_mensuel`, `paie_a_decaisser` | branchée | **réutilisée** par l'export, jamais recalculée |
| Enregistrement d'un fichier (`portEnregistrementFichierProvider`) | branché (Mes données) | **réutilisé** pour le CSV |
| `mineurDepuisSaisie` (`admin_finance/paiements/paiements_page.dart`) | branché | **réutilisé** pour le montant noté |

## 2. Les sources Wise lues (06/11/2026)

- Modèles et remplissage : https://wise.com/help/articles/2663296 , https://wise.com/help/articles/2663302 ,
  https://wise.com/help/articles/2663295
- Erreurs d'import (UTF-8, 1 000 lignes, 5 Mo, pas de virgule dans `Amount`) : https://wise.com/help/articles/2942777
- `amountCurrency` (`source` : frais déduits ; `target` : montant exact reçu) : https://wise.com/help/articles/5iWcIUdYHyTQMnezSzx4n3
- USD par SWIFT (Guinée, Mali, Mauritanie, Sénégal, Maroc, Égypte, Arabie saoudite) : https://wise.com/help/articles/2974947
- XOF depuis le Royaume-Uni « not quite there yet » : https://wise.com/gb/send-money/send-money-to-senegal
- Frais : « à partir de 0,24 % », variables par devise : https://wise.com/gb/pricing/business

Comparaison des prestataires tout prêts (Stripe Connect, Stripe Global Payouts, Wise), relevée avant
la décision : Stripe Connect UK ne verse qu'aux États-Unis, au Royaume-Uni, dans l'EEE, au Canada et
en Suisse (https://docs.stripe.com/connect/cross-border-payouts) ; Global Payouts couvre SN, CI, GM,
MA, EG, Europe, pas GN, ML, MR, SA (https://docs.stripe.com/global-payouts/recipient-requirements) ;
aucun des deux ne verse sur Wave ou Orange Money.

## 3. Ce qui est construit

### Serveur

- **Compte au nom d'un tiers** (directeur, 06/11, 22:55 UTC) : `name` = le titulaire ; question « Ce
  compte est-il à votre nom ? » ; sinon lien (parent, conjoint, frère ou sœur, autre) et accord daté
  obligatoire. **Tout enregistrement (premier ou changement) n'entre dans le fichier qu'après validation
  par la direction** (`valider_coordonnees_versement`, direction seule, sur la ligne lue ; journalisé) ;
  chaque enregistrement, retrait et validation enfile un courriel à l'enseignant (`courriel_enfiler`,
  catégorie compte). L'export met à part « en attente de validation ». La référence de paiement garde
  le matricule (colonne `referenceNumber`).

- `supabase/migrations/20261110700000_versement_wise_enseignant.sql` (aucun DELETE, DROP ni
  TRUNCATE ; le mot n'apparaît que dans la colonne `deleted_at`) :
  - `versement_coordonnees` : une ligne active par enseignant, ancienne ligne inactive à chaque
    changement ; formats contrôlés (compte, IBAN, SWIFT, pays) ; aucune virgule, guillemet,
    point-virgule ni saut de ligne dans les textes (CSV sain). Prestataire `wise` ; `pawapay` et
    `verto` admis, rien de codé pour eux.
  - `versement_champs_requis` (réglage : champs par devise ; USD posé), `versement_wise_colonnes`
    (réglage : en-têtes du modèle, posés une fois par `poser_modele_wise`, direction seule),
    `versement_journal` (ajout seul : coordonnées enregistrées ou retirées, export, modèle posé).
  - Enseignant : `mes_coordonnees_versement` (numéros masqués sauf les 4 derniers caractères),
    `enregistrer_mes_coordonnees_versement`, `retirer_mes_coordonnees_versement`,
    `mon_journal_coordonnees_versement`.
  - Direction et comptabilité : `versement_coordonnees_direction` (qui est complet, aucune valeur),
    `versement_export_wise(p_mois)` (montant = dû du relevé moins versements notés du mois ;
    sans coordonnées complètes, à part ; plus de 1 000 lignes refusé ; journalisé),
    `versement_exports_direction`.
- `supabase/migrations/20261110710000_versements_paie_notes.sql` : la direction note un versement fait
  (montant, devise, date, mois, moyen, référence d'opération sans espace, note, clé d'idempotence ;
  annulation avec motif, jamais d'effacement ; trésorerie `paie_a_decaisser` en sortie, reprise sans
  taux de change) ; l'enseignant lit les siens (`mes_versements_paie`), sans note interne.
- RLS sur toutes les tables, aucun droit direct ; toutes les fonctions `SECURITY DEFINER`,
  `search_path = ''`, gardes positives.

### Application

- `lib/core/capacites/port_coordonnees_versement.dart`, `coordonnees_versement_supabase.dart`
  (`fichierCsvWise` : écrit les colonnes et lignes rendues, virgule, CRLF, UTF-8 ; aucun calcul) ;
  `port_versements_paie.dart`, `versements_paie_supabase.dart`. Branchés dans `lib/main.dart`.
- Enseignant, `lib/features/paiements_recus/` : « Mes coordonnées de versement » (champs du modèle,
  rendus par le serveur : titulaire, numéro de compte ou IBAN, SWIFT, pays choisi dans la liste,
  ville, adresse ; État aux États-Unis et au Canada seulement ; code postal facultatif),
  « Versements reçus » (état vide compris), historique ; retrait confirmé. La rubrique de Compte et du
  Profil suit la capacité (un non-enseignant ne la voit pas).
- Direction, `lib/features/admin_finance/paiements/` : bloc « Paie des enseignants par Wise » dans
  l'onglet Paiements ; feuille « Coordonnées à valider » (`feuille_valider_coordonnees.dart` :
  titulaire, lien, date de l'accord, numéro masqué, pays, puis « Valider ces coordonnées ») ; feuille « Fichier Wise de la paie » (mois terminé par défaut, lignes et total,
  enseignants aux coordonnées manquantes, « Enregistrer le fichier ») ; feuille « Noter un versement
  fait » (`feuille_noter_versement.dart`). Aucune route nouvelle.
- Textes fr et ar (`comptable.beneficiaires.recevoir.wise`, `admin.finance.paieWise`), sources dans
  `tool/libelles_sources.json`, mots ajoutés à `mots-rewayah`.

## 4. Preuves (locales)

- `supabase/tests/scenarios_versement_wise.sql` : 47 contrôles verts (compte au Yémen refusé quand le
  référentiel le dit indisponible, compte d'un proche en Arabie saoudite accepté ; compte d'un tiers sans accord ou
  sans lien refusé ; un courriel par changement ; validation par la direction seule, sur la ligne lue ;
  l'export ne prend que les coordonnées validées) (dont les 17 colonnes du modèle
  et une ligne relue valeur par valeur ; État exigé aux États-Unis ; version nouvelle du modèle) (refus tuteur, anon, enseignant
  qui lit les coordonnées d'un autre, export par enseignant et tuteur, modèle posé par le comptable ;
  masquage ; remplacement et retrait sans effacement ; montant 51,74 − 20,00 = 31,74 ; manquants ;
  journal).
- `supabase/tests/scenarios_versements_paie.sql` : 20 contrôles verts.
- `scenarios_b18_security_definer`, `scenarios_etape3`, `scenarios_fn115c_rembourser` restent verts.
- Flutter : `test/core/capacites/coordonnees_versement_supabase_test.dart`,
  `versements_paie_supabase_test.dart`, `test/features/paiements_recus/recevoir_paiements_test.dart`,
  `test/features/admin_finance/paie_wise_test.dart` (le CSV comparé colonne par colonne aux colonnes
  rendues, dont les colonnes publiques de Wise `Name`, `sourceCurrency`, `targetCurrency`, `Amount`,
  `amountCurrency`), plus les tests voisins : 394 verts. `dart analyze --fatal-infos` propre ;
  `verifier_jetons` propre ; `verifier_revue` 1055 (comme `main`).

Lignes pour `ci.yml` (pilote) :

```
      - name: Scenarios FINANCE-ENSEIGNANT (paie Wise)
        run: psql -h postgres -U postgres -v ON_ERROR_STOP=1 -f supabase/tests/scenarios_versement_wise.sql
      - name: Scenarios FINANCE-ENSEIGNANT (versements notes)
        run: psql -h postgres -U postgres -v ON_ERROR_STOP=1 -f supabase/tests/scenarios_versements_paie.sql
```

## 5. Après l'installation

1. L'enseignant de Guinée saisit ses coordonnées (compte qui reçoit des USD) ; un premier fichier
   d'un mois réel est importé dans Wise par le directeur, avant le 1er versement (1er au 10/12).
