## Revue adverse CTRL-ROSTER-C7-1b : isolation bidi du libellé « Prénom N. »

**Branche relue :** `origin/corrections/c2-roster-c7-b`, commit `99a7ac6a` (code dans `efc06693`, captures dans `99a7ac6a`). J'ai travaillé en lecture seule dans un worktree jetable, détaché puis retiré. Je n'ai rien poussé.

**Verdict : ACCEPTÉE AVEC RÉSERVES.** Les trois points de la demande sont traités et je les ai prouvés par mutation et par des captures que j'ai produites moi-même. Il ne reste aucun défaut majeur dans le périmètre de l'étape. Les réserves portent sur trois choses : la validation DASH-LIB, l'absence de traduction arabe, et un mot coupé préexistant que j'ai découvert dans le récapitulatif.

### 1. La demande est-elle remplie ?

| Exigence | Constat |
|---|---|
| Isoler « Prénom N. » avec U+2068…U+2069 | Oui. La nouvelle fonction `isolerSens` (`lib/core/i18n/isolat_bidi.dart`) produit FSI + texte + PDI, et laisse un texte vide tel quel. Elle sert à trois endroits : la liste du roster (`OptionChoix.libelle`), le récapitulatif (« Élève précis · … ») et chaque nom des présents dans l'Historique (`r.presents.map(isolerSens).join(', ')`). Les données (`prenomEtInitiale`, `nomAffiche`, rapports) restent sans isolat. |
| Fonction factorisée et partagée avec l'Historique | Oui. Le `_isole` privé de `mes_classes_page.dart` est supprimé et remplacé par `isolerSens`. Le dépôt ne contient plus aucune autre définition d'isolat (vérifié par `grep 2068`). Un seul changement de comportement : un texte vide reste vide, alors qu'il devenait FSI+PDI. Dans Mes Classes, ce cas ne peut pas se produire, car la liste `contexte` contient toujours le segment de l'effectif et `quand` n'est jamais vide. Les tests de `enseignant_classes` passent, COUPE-MOTS-2 compris. |
| Test bidi : nom arabe en interface LTR, nom latin en interface RTL | Oui. Le test tourne en vraie locale arabe (`LocaleSettings.setLocaleSync(ar)`). Il mesure l'ordre visuel du point par `RenderParagraph.getBoxesForSelection`, dans la liste (320 x2 et 1440), dans le récapitulatif et dans l'Historique, pour les deux sens. |
| DASH-LIB | Rien à faire dans cette étape : les libellés attendent la validation du directeur (réserve ci-dessous). |

### 2. Mutations (j'ai annulé la correction, les tests doivent échouer)

- **`isolerSens` rendue identité :** 9 échecs, à savoir le test unitaire et les 8 cas de sens croisé (liste fr 320/1440, liste ar 320/1440, récapitulatif fr e4, récapitulatif ar e1, Historique fr et ar). Les cas où le nom et l'interface ont le même sens passent, ce qui est attendu.
- **Isolat retiré de la liste seule :** 6 échecs (liste fr/ar, bidi liste fr/ar 320/1440).
- **Isolat retiré du récapitulatif seul :** 5 échecs (le libellé du récapitulatif et les 4 cas bidi du récapitulatif).
- **Isolat retiré de l'Historique seul :** 2 échecs (Historique fr et ar).

Chaque endroit qui affiche un nom est donc couvert par au moins un test qui mesure l'ordre réel du rendu, et pas seulement la présence du texte.

### 3. Captures que j'ai produites et ouvertes

J'ai repris le roster de la revue précédente (Mariam S / Abd al-Rahman Ben Salah / عائشة نور) et produit mon propre script de capture, jetable et supprimé ensuite :

- **Liste fr et ar :** 320 x2 sombre, 320 x2 clair, 390 clair, 390 en Interface guidée (`InterfaceMode.enfant`), 1440 sombre.
- **Récapitulatif fr et ar :** 320 x2 sombre, avec le nom arabe sélectionné.
- **Historique fr et ar :** 320 x2 sombre.

Ce que montrent ces captures :

- **En arabe (RTL), noms latins :** « Mariam S. » et « Abd al- / Rahman B. » ont leur point à droite, à la fin du nom. Le défaut de la revue précédente (« .Mariam S ») a disparu.
- **En français (LTR), nom arabe :** « عائشة ن. » a son point à gauche de « ن », c'est-à-dire à la fin de la lecture arabe, en 320 x2 comme en 1440.
- **Récapitulatif :** fr « Élève précis · عائشة / ن. » et ar « عائشة · Élève précis / ن. ». Le point est correct dans les deux cas, et le retour à la ligne se fait entre deux mots.
- **Historique :** fr « Mariam S., Abd al-Rahman B., عائشة ن. ». En ar, chaque nom garde son point en fin de nom et les virgules suivent l'ordre RTL.
- Aucun débordement et aucune exception (`takeException` nul).

### 4. Vérifications outillées

- **`dart analyze --fatal-infos` :** aucun problème.
- **`verifier_revue` :** 1573 violations, autant que sur la base 29a4fc83 mesurée de mon côté. Aucune nouvelle.
- **`verifier_jetons` :** les seules lignes sur le contrôleur viennent de fichiers de démonstration que l'étape ne modifie pas. L'étape n'ajoute aucune violation.
- **Tests avec `--concurrency=2` :** `test/features/controleur`, `test/features/enseignant_classes`, `test/features/demo` et `test/core` donnent +1000 ~10, tous verts. `roster_prenom_initiale_test.dart` passe au complet.
- **Autres appelants :** `nomAffiche` et `prenomEtInitiale` ne sont affichés qu'aux trois endroits isolés. La démo de l'Historique passe par `prenomEtInitiale`, sans isolat dans les données, et son affichage est donc isolé par la page.
- **Règles du dépôt :** aucun secret, aucun rôle lu, aucune modification de thème, de jetons, de `supabase/` ou de `.github/`, aucun branchement serveur (`serveur: []` est cohérent).

### 5. Réserves

1. **[moyen, préexistant, hors étape] Mot coupé dans le titre du récapitulatif à 320 px x2.** « Vérifiez votre observation avant l'envoi. » se lit « votre obse / rvation » en fr comme en ar. Mon test jetable `motsCoupes` sur l'étape 5 échoue avec `['… : observation']`, et il échoue aussi sur la base `29a4fc83`. L'étape ne l'a donc pas introduit, et la revue précédente ne l'avait pas vu, puisqu'elle contrôlait le roster et non le récapitulatif. Il faut une étape dédiée : un titre plus court validé par le directeur, ou une échelle de titre adaptée, plus un test `motsCoupes` sur le récapitulatif.
2. **[mineur] DASH-LIB :** `contextePersonne` et `elevePrecisAide` restent à valider par le directeur.
3. **[mineur, hors périmètre] Pas de clés `controleur.*` dans `ar.i18n.json`.** Les phrases françaises de repli voient leur ponctuation se retourner en RTL. Il faut une traduction validée.

### 6. Statut de preuve

L'étape est **présente dans le code et testée localement** (mutations et captures refaites par moi). Elle n'est **ni testée sur staging ni déployée**.
