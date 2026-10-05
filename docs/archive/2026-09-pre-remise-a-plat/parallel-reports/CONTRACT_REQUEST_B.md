# CONTRACT_REQUEST_B

Demandes de l'**agent B** (`ENS-03`, surface `lib/features/salle_enseignant/`).
Aucune n'a été contournée : ce qui manque est écrit ici, et le code livré
fonctionne sans, avec l'écart nommé.

---

## 1. Lire le droit de présenter depuis le panneau — `VueSalle.peutPresenter`

**Priorité : haute. Une ligne dans un fichier de l'Agent Z.**

### Le fait

`CapacitesSalle.peutPublierDonnees` est parsé depuis `can_publish_data` et
documenté « Réservé à l'enseignant : c'est lui qui présente le Coran ».
`VueSalle` expose `peutParler` (`peutPublier`) et `peutMontrer`
(`peutPublierVideo`) — **mais pas** l'équivalent pour les données.

Le panneau de l'agent B ne peut le lire nulle part :

- `VideoSessionProvider` n'expose pas l'`AccesSalle` avec lequel on a rejoint
  (`_acces` est privé dans `livekit_session_provider.dart:36`, sans getter) ;
- `salle_page.dart` le détient dans `_SallePageEtat._acces`, un State privé ;
- l'API publique du panneau est **figée** à `({required String seanceId})` par
  `TEACHER_FILE_OWNERSHIP.md` §3 : rien d'autre ne peut y entrer ;
- lire `sessionProvider.role` est explicitement interdit pour décider d'une
  commande de salle (le rôle vient du **jeton**, pas du compte).

### La demande

Dans `lib/features/salle/vue_salle.dart`, à côté de `peutParler` et
`peutMontrer` :

```dart
/// Le jeton autorise la diffusion du contenu presente (`can_publish_data`).
///
/// Reserve a l'enseignant : c'est lui qui presente le Coran. Un enseignant sans
/// ce droit ne doit voir aucune commande de presentation, plutot qu'un bouton
/// que le serveur refusera.
final bool peutPresenter;   // capacites?.peutPublierDonnees ?? false
```

C'est la première consommation de cette capacité dans tout le dépôt (l'audit le
dit : « la capacité existe côté jeton, la consommation n'existe pas »).

### Ce que B fait en attendant

`VuePresentation.depuis(..., peutPresenter: ...)` **porte déjà le paramètre** et
il est couvert par un test (`sans le droit de presenter, aucune commande n est
active`). Le panneau le passe à `true` avec un commentaire qui renvoie à cette
demande : **une seule ligne changera** le jour où le getter existe. Jusque-là, le
point d'insertion doit porter la condition (voir `AGENT_B_REPORT.md` §4).

Variante acceptable, si l'Agent Z préfère ne pas toucher `VueSalle` : un getter
`AccesSalle? get accesCourant` sur `VideoSessionProvider`. **Moins souhaitable** :
il ouvrirait l'objet d'accès (donc le jeton signé) à toutes les features, là où
un booléen dérivé ne dit que ce qui est nécessaire.

---

## 2. Journaliser un tour de page — **demande différée, pas un besoin de ce lot**

Le panneau reçoit `seanceId` et ne s'en sert aujourd'hui que comme identité de la
salle dans laquelle il parle. Si le protocole demande un jour « qui a présenté
quoi, et quand », il faudra une écriture serveur (donc une migration, donc un
autre lot) : le contenu présenté est **éphémère par décision d'architecture**
(`SOCLE_SALLE_REPORT.md` §7.5) et ne laisse aucune trace.

Aucune action attendue dans ce lot. C'est écrit ici pour que le paramètre
`seanceId` ne passe pas pour un oubli.

---

## 3. Ce que B **n'a pas** demandé, et pourquoi

| Envie | Pourquoi elle n'est pas une demande |
| :--- | :--- |
| extraire `_ListePresence`, `_Cadre`, `_Seul` de `salle_page.dart` | le panneau n'affiche ni participants ni scène vidéo : la hiérarchie les place dans `salle_page`, et les demander aurait été le premier pas vers un second écran de salle |
| un composant partagé « page de mushaf » | trois lignes de composition sont dupliquées depuis `coran_page.dart`. Le plafond est écrit dans le code (`ponytail:`) : extraction à la **troisième** surface qui rend du Coran, pas avant |
| un état `offline` propre à la salle | `PageImmersive` refuse le bandeau hors ligne à dessein, et le protocole interdit un second signal concurrent. L'état du lien est dit par le moteur, et le panneau n'en ajoute pas un deuxième |
| une clé i18n pour « Ouvrir le Coran » | `salle.ouvrirCoran` existait sans appelant depuis le lot N3. Elle en a un maintenant |
