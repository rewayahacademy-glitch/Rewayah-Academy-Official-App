# Rewayah : complément immatriculation, identité et publication

Version 0.1, 7 octobre 2026. Document séparé à transmettre à Claude avec BR0B.

**Statut : proposition d'architecture et contrat de réalisation. Aucune migration ni modification du frontend, de GitHub ou de Supabase n'a été exécutée pour ce complément. Le document BR0B canonique demeure inchangé.**

## 1. Décision recommandée

Attribuer un matricule permanent, lisible et aléatoire à chaque profil de personne, élèves, tuteurs et personnel compris. Classer les personnes par leurs rôles dans des colonnes, badges et filtres séparés. Pour une évaluation rendue publique, attribuer en plus un code participant limité à cette évaluation.

| Identifiant | Exemple fictif | Fonction et visibilité |
|---|---|---|
| UUID interne existant | UUID de `profiles.id` | Relations, Auth et autorisations ; conserver les clés existantes. Pas d'identifiant destiné à la lecture publique. |
| Matricule permanent | `RA-7K3M-P8XT-2V6N` | Référence stable d'une personne dans l'app ; visible à elle-même et aux personnes autorisées. |
| Code participant d'évaluation | `EV-7K3MP-8XT2V` | Affichage de la participation et des résultats dans une évaluation ; différent dans une autre évaluation. |
| Catégorie d'affichage | `EL · RA-7K3M-P8XT-2V6N` | Badge Élève séparé du matricule ; même principe pour Tuteur et Personnel. |

Le matricule ne contient ni nom, ni initiales, ni date de naissance, ni pays, ni sexe, ni famille, ni rang d'inscription. Son caractère aléatoire rend sa déduction difficile, sans en faire un secret d'accès. L'app sait retrouver son propriétaire sous contrôle d'autorisation ; le public ne doit disposer d'aucun annuaire reliant ce code à l'identité réelle.

Un identifiant masquant le nom est un **pseudonyme**, pas une garantie d'anonymat : une petite liste de participants, une photo, une classe connue ou un classement peuvent encore permettre une reconnaissance. Afficher le nom et le code ensemble révèle volontairement leur correspondance.

## 2. Ce qui existe réellement et ce qui manque

### Sources examinées

- GitHub : `rewayahacademy-glitch/Rewayah-Academy-Official-App`, branche de pilotage examinée au commit `708ef8f59bfefae89db071764d3f90a7d6b13322`, fichier `14_controleur/CT-BR.md`, règle **BR-CT-16**. Lecture reconfirmée par le connecteur GitHub le 7 octobre.
- PDF cockpit « Suivi Rewayah - Claude », extraction locale de la source fournie ; décision **K-44** sur les photos dans la Classe.
- Supabase PROD `gggmtelinlpseweouyav` : lecture du catalogue des colonnes, contraintes et fonctions le 7 octobre. Aucun nom, matricule réel ou dossier personnel n'a été lu pour cette vérification.

BR-CT-16 demande déjà un identifiant élève unique et immuable pour distinguer les homonymes dans le roster, les observations et les présents. Cette demande n'a donc pas totalement disparu. Cependant, elle ne définit pas le format confidentiel, la généralisation à toutes les personnes ou le choix d'affichage public des évaluations.

Supabase contient déjà :

- `profiles.id` : UUID, clé primaire liée à `auth.users.id` ; ne pas le remplacer.
- `profiles.immutable_id` : texte obligatoire avec contrainte `profiles_immutable_id_unique`.
- `profiles.role` : rôle principal actuel ; ne pas le transformer implicitement en système multirôle.
- `id_sequences(code, last_value)` et `next_immutable_id(role_code, initials)`.
- Deux appels confirmés au générateur : `creer_profil_inscription` et `creer_profil_enfant`, avec initiales calculées à partir du prénom et du nom.
- Des lectures de cet identifiant dans `eleves_en_attente_v`, `mes_affectations_v`, `mes_seances_v`, `profils_du_foyer_v`, `session_peers_v`, `teacher_roster_v`. Ces noms désignent des vues existantes, pas des publications anonymes à réutiliser telles quelles.

Le format réellement produit est :

```text
ROLE-INITIALES-COMPTEUR_SUR_6_CARACTERES
```

**Trois problèmes concrets :** les initiales donnent un indice personnel ; le compteur est prévisible et révèle l'ordre d'inscription au sein d'un rôle ; le compteur unique par rôle impose une écriture sur une même ligne lors des créations concurrentes de ce rôle.

**Problème de longévité confirmé :** le `lpad(..., 6, '0')` actuel tronque les valeurs dépassant six caractères. Une lecture SQL pure sur PROD a renvoyé `999999`, puis `100000` pour `1000000` et aussi `100000` pour `1000001`. À partir d'un million d'attributions dans un rôle, la partie numérique perd donc son unicité. Les initiales peuvent différer, mais des collisions complètes deviennent possibles ; la contrainte UNIQUE refuse alors l'écriture, sans réparer le générateur. Aucune séquence n'a été incrémentée pendant ce contrôle.

Le nouveau matricule traite ces défauts sans réécrire les UUID ni les relations existantes. L'immutabilité effective devra être assurée et testée : le nom `immutable_id` ne constitue pas à lui seul une protection contre la modification.

## 3. Format permanent et unicité

**Format retenu : `RA-XXXX-XXXX-XXXX`.** `RA` identifie Rewayah ; les douze caractères suivants sont entièrement aléatoires, regroupés par quatre pour la lecture et la dictée.

Alphabet de génération : `0123456789ABCDEFGHJKMNPQRSTVWXYZ`, soit 32 caractères ; pas de I, L, O ou U. Il reste nécessaire d'utiliser une police distinguant nettement les caractères. Le choix de cet alphabet et du format est une recommandation de ce complément, pas un format déjà présent dans Supabase.

| Longueur aléatoire | Espace possible | Probabilité approximative d'au moins une collision de tirage à 1 million de codes, avant traitement |
|---|---:|---:|
| 8 caractères | 2^40 | 36,5 % |
| 10 caractères | 2^50 | 0,0444 % |
| **12 caractères** | **2^60** | **0,0000434 %** |

Calcul : approximation anniversaire `1 - exp(-n(n-1)/(2N))`, pour des tirages uniformes indépendants. La comparaison vise le matricule global ; un code d'évaluation à dix caractères est unique seulement dans son événement. À dix millions de matricules, le risque de collision de tirage à douze caractères reste d'environ 0,00434 %.

**Une collision de tirage est toujours possible. Aucun doublon stocké n'est admis :** contrainte UNIQUE ou PRIMARY KEY en base, nouveau tirage sur la seule collision de code, et transaction atomique. Ne pas se contenter de vérifier l'existence puis d'insérer, car deux requêtes peuvent s'intercaler.

Règles de génération :

1. Génération exclusivement côté serveur avec un générateur cryptographiquement sûr, uniforme sur 60 bits. Ni `Math.random`, ni date, ni compteur, ni hachage non secret du nom ou de l'UUID.
2. Nouvelle tentative uniquement sur la contrainte d'unicité du code, maximum cinq tirages ; au-delà, échec contrôlé et alerte. Ne pas masquer une autre erreur SQL.
3. Une création réessayée pour le même profil retourne le matricule déjà attribué ; elle ne le régénère pas.
4. Matricule immuable après attribution ; changement de rôle, nom, Classe ou statut sans changement de matricule.
5. Code retiré jamais réattribué à une autre personne. Voir le registre durable proposé en §8.
6. À la saisie, accepter minuscules et séparateurs attendus, puis produire la forme canonique. Une conversion O vers 0 et I/L vers 1 peut être acceptée à la saisie, jamais à la génération. Rejeter les caractères Unicode ressemblants et toute longueur incorrecte ; pas de recherche floue qui sélectionnerait automatiquement une autre personne.
7. Afficher le code entier, bouton Copier et sens de lecture gauche à droite, y compris dans l'interface arabe, par exemple avec `<bdi dir="ltr">`. Le préfixe et les tirets n'ajoutent aucune entropie.

Douze caractères sont le compromis retenu pour plusieurs millions de personnes. Pas de checksum en V1 : il rallongerait le code sans apporter l'unicité, déjà garantie en base. Un scan peut faciliter la saisie ; un QR contenant seulement le matricule ne donne aucun accès au dossier.

## 4. Classification des personnes

Ne pas inscrire le rôle dans le matricule permanent : une personne peut devenir enseignante, rester tuteur ou recevoir une nouvelle responsabilité. Deux catégories ne doivent pas entraîner deux matricules pour le même profil canonique.

| Regroupement demandé | Badge proposé | Source métier à utiliser |
|---|---|---|
| Élèves, mineurs et adultes | EL | Rôle `student` ; sous-type dans les données élève autorisées. Le code ne révèle pas l'âge. |
| Tuteurs | TU | Rôle `guardian` ou statut effectif validé selon les contrats existants. |
| Personnel | PE | Regroupement calculé côté serveur à partir des rôles et fonctions autorisés. |
| Enseignant, sous-catégorie personnel | EN | Rôle `teacher`. |
| Administration | AD | Rôle `admin` ou capacité administrative explicitement accordée. |
| Contrôle | CT | Rôle `controller` ou capacité correspondante. |
| Comptabilité | CP | Rôle `accountant` ou capacité correspondante. |

Les badges sont des libellés d'interface, jamais une source d'autorisation. Un filtre Personnel peut réunir plusieurs fonctions. Le backend actuel possède un rôle principal ; les responsabilités supplémentaires doivent suivre le modèle de capacités du projet, sans inventer des rôles ou élargir des droits par simple badge.

Afficher par défaut un matricule et le ou les badges pertinents au contexte. Dans un contexte public d'évaluation, omettre les badges inutiles. Chaque enfant possède son propre matricule, distinct de celui du tuteur ; aucune portion commune ne révèle le foyer.

Le matricule garantit l'unicité d'une référence, **pas l'absence de doubles comptes d'un même être humain**. Les homonymes restent distincts ; ne pas fusionner automatiquement sur nom, email familial ou date de naissance. Une fusion de dossiers exige une vérification habilitée, une traçabilité et une règle de conservation des références historiques.

## 5. Évaluations : liste des participants et résultats

### Les choix de l'administrateur

Configurer séparément la visibilité de la liste avant l'évaluation et celle des résultats après correction. Une liste publiable n'implique pas des notes publiables. Une publication n'est jamais déclenchée simplement par la fin de l'évaluation.

| Option d'affichage | Rendu fictif | Usage |
|---|---|---|
| **ID uniquement**, choix initial proposé | `EV-7K3MP-8XT2V · 17/20` | Publication sans nom ; code participant propre à cette évaluation. |
| Nom réel uniquement | `Nom réel · 17/20` | Publication nominative autorisée et explicitement choisie. |
| Nom réel et ID | `Nom réel · EV-7K3MP-8XT2V · 17/20` | Publication nominative avec repère pour distinguer les homonymes. |

Ces trois choix satisfont la demande « noms réels et/ou IDs ». Le libellé de l'interface doit préciser quel ID sera montré. En espace interne autorisé, l'administrateur peut aussi choisir le **matricule permanent**. En publication publique, le code d'évaluation est recommandé ; publier le matricule permanent doit être une option distincte, explicite, soumise aux mêmes contrôles de diffusion et signalant sa corrélabilité entre événements.

### Codes participants

- Format : `EV-XXXXX-XXXXX`, dix caractères aléatoires du même alphabet, soit 50 bits.
- Un code par couple `(evaluation_id, profile_id)`, stable entre la liste et les résultats de cette évaluation, y compris lors d'une republication.
- Unicité `(evaluation_id, participant_code)` garantie en base, avec nouveau tirage sur collision. Le code n'a pas à être unique entre toutes les évaluations.
- Générer indépendamment du matricule ; ne pas en publier un extrait ou un simple hachage stable. Pas de numéro de ligne susceptible de changer avec le tri.
- Le participant retrouve son propre code dans son espace authentifié ; le tuteur autorisé retrouve celui de son enfant. Ne pas envoyer une liste nominative globale pour permettre cette reconnaissance.
- Ne pas régénérer les codes au rafraîchissement de la page ; cela casserait les repères. Une publication antérieure du nom et du code n'est pas rendue anonyme en masquant ensuite le nom.

### Contrôles de publication

Politique serveur pour chaque évaluation : audience `private`, `participants`, `academy` ou `public` ; mode d'identité `id_only`, `real_name` ou `both` ; source d'ID `evaluation_alias` ou `registration_code` ; visibilité distincte pour roster et résultats ; état brouillon/publié/retiré, dates et révision de publication.

L'audience `participants` ne donne pas implicitement accès aux notes des autres : la liste des résultats visibles et leur périmètre doivent être explicitement définis. Le backend vérifie le droit de publication de l'administrateur, les choix de diffusion applicables à chaque personne et les règles validées pour les mineurs. Le consentement de visibilité dans la Classe ne doit pas être supposé couvrir une diffusion sur Internet. La base légale et les règles applicables aux pays d'activité restent à valider avec le responsable du projet ; ce complément ne conclut pas à une autorisation juridique générale.

Un écran de prévisualisation indique l'audience, les champs visibles et les participants non publiables. Si une règle interdit la diffusion d'un nom ou d'un résultat, le serveur le masque ou exclut la ligne selon la politique retenue ; la bascule d'interface ne permet pas de la contourner. Toute modification nominative est auditée : acteur, évaluation, ancienne/nouvelle politique, date et motif si requis.

La réponse publique doit être fabriquée avec une liste explicite de champs autorisés : code ou nom autorisé, résultat autorisé, rang si choisi. En mode ID uniquement, aucune propriété ne contient le nom, l'UUID du profil, le matricule permanent, une photo, un email, le foyer, des remarques privées ou un lien vers un dossier. Contrôler également les exports, attributs HTML, fichiers joints et caches. Cacher le nom par CSS est insuffisant.

Retrait ou restriction : désactiver l'accès, invalider les caches contrôlés par l'app et les exports servis par elle. Les copies et captures déjà téléchargées ne peuvent pas être récupérées de façon garantie. Les publications nominatives doivent donc être un choix conscient.

La décision cockpit K-44 concernant les photos chez l'enseignant, l'administration et les camarades de Classe demeure applicable dans son périmètre. Ce complément ne retire pas ces photos internes et n'étend pas cette permission au public.

## 6. Utilité au-delà de l'affichage

| Usage | Décision et limite |
|---|---|
| Homonymes, roster, observations, présence | Oui, référence stable supplémentaire ; satisfaire BR-CT-16 sans remplacer le champ nom ni les UUID de liaison. |
| Assistance et recherche administrative | Oui, recherche exacte sur code, limitée aux personnes que l'agent a le droit de consulter. Le matricule n'est pas une preuve d'identité suffisante pour une récupération de compte. |
| Imports et rapprochements | Oui, référence d'import vérifiée et liée à l'UUID ; contrôler le périmètre de l'import et les doublons de dossiers. |
| Exports internes, attestations, suivi | Oui selon audience ; éviter de rendre le matricule global public par défaut. La vérification publique d'un certificat utilise un jeton propre au document. |
| Évaluations publiques | Code d'évaluation recommandé ; aucune correspondance publique entre événements. |
| Journal d'audit | UUID comme référence technique d'acteur et de cible ; matricule éventuellement pour la consultation autorisée. Ne pas recopier systématiquement les noms. |
| Authentification, permissions, liens de foyer | Le matricule n'accorde aucun droit et ne remplace pas les relations métier ou le compte Auth. |

Ne pas exposer un endpoint public « matricule vers email/nom ». Ne pas transformer un code visible en lien de connexion, invitation, récupération de mot de passe ou jeton d'accès. Ces fonctions utilisent des jetons séparés, à expiration et au périmètre adapté.

## 7. Connexion : possible comme identifiant, pas nécessaire en V1

**Décision proposée : conserver les mécanismes de connexion existants en V1.** Ajouter d'abord le matricule pour l'identité métier et les publications. La connexion par matricule peut constituer une extension ultérieure si elle résout un besoin réel, notamment de saisie chez les élèves.

Supabase documente la connexion par mot de passe avec email ou téléphone ; un matricule métier ne devient pas automatiquement un identifiant reconnu par `signInWithPassword`. Ne pas fabriquer des emails à partir des matricules ni remplacer les identités Auth existantes.

Si la connexion par matricule est ajoutée : un service serveur dédié résout le matricule en identité Auth dans un périmètre privé, puis utilise le mécanisme Auth validé avec une preuve supplémentaire, par exemple le mot de passe. Il doit rendre des erreurs génériques, limiter les tentatives et ne jamais renvoyer l'email de résolution. Éviter la journalisation des secrets et l'exposition d'une clé privilégiée au navigateur. Ce parcours doit être revu séparément, y compris ses sessions, sa récupération de compte et sa résistance à l'énumération ; pas de contournement par émission artisanale de JWT.

Le matricule seul, un code participant public ou un PIN commun ne peuvent jamais connecter quelqu'un. Préserver les protections particulières du personnel et les parcours enfant/foyer déjà prévus. En cas de perte du matricule, le retrouver après authentification ou via une assistance habilitée, sans rendre le dossier accessible à qui connaît le code.

## 8. Contrat de données et migration additive

Les noms suivants sont **proposés** ; vérifier les objets existants avant de créer la migration. Le document est un contrat de comportement, pas du SQL à exécuter aveuglément.

### Matricules permanents

Préférer un registre dédié `person_registrations` :

| Champ proposé | Contrainte / fonction |
|---|---|
| `registration_code` | Texte canonique, PRIMARY KEY, CHECK de format `^RA-[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$`. |
| `profile_id` | UUID lié au `profiles.id` existant, UNIQUE ; NOT NULL à l'attribution, nullable uniquement après effacement autorisé. |
| `issued_at` | Horodatage serveur de l'attribution ; accès privé, durée de conservation à définir. |

L'effacement d'un profil peut dissocier `profile_id` sans supprimer ni réattribuer le code réservé. Les contraintes PostgreSQL autorisent plusieurs valeurs NULL pour un UNIQUE ordinaire ; cela permet plusieurs codes retirés sans propriétaire. Protéger le registre contre suppression, changement de code et rattachement d'un code retiré à un autre profil. Une réserve de codes sans nom ne justifie pas de conserver indéfiniment la correspondance personnelle ou tous les audits.

Créer le profil et son matricule dans une seule transaction serveur ; traiter les conflits de code sans rejouer des effets métier déjà validés. Garantir un seul matricule actif par profil, y compris en cas de concurrence et de réessai. Exposer `registration_code` dans les DTO internes autorisés, sans dupliquer une seconde source de vérité éditable dans `profiles`.

Conserver `profiles.immutable_id` comme référence historique durant la transition, sous accès autorisé ; il peut être recherché en assistance privée. Les lecteurs et écritures existants doivent continuer à fonctionner. Ne pas annoncer que le problème est résolu tant que les nouvelles créations appellent encore exclusivement le générateur initiales/compteur. Adapter tous les parcours d'inscription, d'enfant, de personnel et d'import, pas seulement les deux fonctions confirmées.

Dans une seconde migration compatible, arrêter la génération des anciens codes en donnant à `immutable_id` une valeur opaque compatible ou en révisant ses exigences, après inventaire des dépendances et des versions de clients encore utilisées. Conserver la correspondance des anciens codes nécessaires dans une table privée d'alias historiques. Cette étape doit être conçue et testée avant la bascule ; ne pas tronquer un compteur pour maintenir artificiellement le vieux format.

### Codes d'évaluation et publication

Prévoir un stockage privé de correspondance `evaluation_participant_aliases` avec UUID d'évaluation, UUID de profil et `participant_code` canonique. Contraintes : UNIQUE `(evaluation_id, profile_id)`, UNIQUE `(evaluation_id, participant_code)`, clés étrangères et champs NOT NULL. Liaison et périmètre d'évaluation décidés par le serveur ; ne pas accepter un `profile_id` arbitraire sans vérifier la participation.

La table privée de correspondance est protégée par RLS, droits de colonnes et/ou RPC dédiée selon le modèle du projet. Le public accède uniquement à une projection ou un snapshot de publication autorisé. Réutiliser les évaluations et résultats existants après leur inventaire ; ne pas créer un deuxième module d'évaluation concurrent.

Les snapshots publics ne doivent pas contenir de colonnes privées cachées. Leur version, le mode choisi et les champs diffusés doivent pouvoir être audités. La mise à jour de politique et des lignes publiques doit être atomique afin de ne pas servir un mélange de deux modes. Une modification de politique ne réautorise pas des résultats non publiables.

### Déploiement et performance

1. Sur une branche dédiée, ajouter ce complément et les migrations nouvelles ; ne pas éditer BR0B canonique.
2. Inventorier références à `immutable_id`, consommateurs frontend, inscriptions, imports, exports et objets d'évaluation ; identifier le contrat multirôle réellement autorisé.
3. Réconcilier STAGING avec les migrations du projet selon BR0B avant de tester ce lot. Le staging vide constaté dans l'audit BR0B n'est pas une preuve de compatibilité.
4. Ajouter le registre, l'attribution atomique et les API privées ; attribuer les matricules manquants par lots relançables, en conservant UUID et anciens codes. Surveiller erreurs, verrous et durée des lots.
5. Adapter progressivement les ports frontend : matricule distinct du nom, filtres par rôle, copie accessible ; actualiser les vues/DTO concernés sans élargir leurs droits.
6. Ajouter les codes d'évaluation, politiques de publication, prévisualisation et exports dédiés ; aucune ouverture publique par défaut.
7. Tester la compatibilité, préparer le retour applicatif à l'ancien affichage sans supprimer les matricules déjà attribués, puis déployer selon les gates du projet.

Les contraintes uniques créent leurs index B-tree : ne pas ajouter des index identiques. Recherche exacte sur forme canonique, pagination et index de l'évaluation ; pas de scan global ni de calcul aléatoire à chaque lecture. Supprimer le compteur global du nouveau parcours évite ce point de contention, sans garantir à lui seul la capacité de toute l'app. Les RLS, jointures, volumes d'exports et pics de consultations des résultats doivent être mesurés séparément avec un volume représentatif. Ne pas introduire de partitionnement uniquement pour stocker des matricules.

## 9. Exigences à intégrer par Claude, sans réécrire BR0B

| Référence complémentaire | Critère d'acceptation |
|---|---|
| IMM-01 Couverture | Tout profil humain créé ou existant possède un matricule, indépendamment de son rôle ou de son accès au login. Pas de codes réservés aux élèves uniquement. |
| IMM-02 Confidentialité | Aucun élément du matricule dérivé du nom, rôle, âge, foyer ou rang ; aucune API publique de résolution d'identité. |
| IMM-03 Unicité | Contrainte base ; test d'une collision forcée et de deux attributions concurrentes ; un seul matricule actif pour un profil. |
| IMM-04 Stabilité | Renommage, changement de rôle, promotion d'âge, réactivation et réessai conservent le matricule ; modification directe interdite. |
| IMM-05 Classification | Badges et filtres issus des données autorisées ; aucun parsing du code pour déterminer les droits. |
| IMM-06 Publication | Liste et résultats ont des décisions distinctes ; ID, nom et les deux sont disponibles selon droits et règles de diffusion. |
| IMM-07 Périmètre | Code d'évaluation stable dans un événement, généré indépendamment dans les autres ; pas de matricule permanent public par défaut. |
| IMM-08 Minimisation | En mode ID, inspecter JSON, HTML, CSV/PDF et caches : aucun nom, photo, UUID ou lien de dossier privé ne fuit. |
| IMM-09 Autorisations | Utilisateur A ne peut pas lire le registre, dossier ou résultat privé de B en remplaçant un code connu ; le tuteur accède seulement aux enfants autorisés. |
| IMM-10 Connexion | Aucun login ou reset par code seul ; parcours existants inchangés en V1, extension par matricule isolée et revue si ajoutée. |
| IMM-11 Migration | UUID et relations préservés ; vieux clients, imports et vues vérifiés ; nouveau générateur compatible avec la fin de l'ancien compteur. |
| IMM-12 Cycle de vie | Code retiré non réattribué ; effacement dissocie les données selon la politique validée ; aucune fuite du registre d'alias historiques. |
| IMM-13 Publication concurrente | Changement de mode atomique, accès retiré et caches contrôlés invalidés ; publication refusée sans permission adéquate. |
| IMM-14 Volume | Lookup exact indexé et pagination vérifiés ; génération de lot sans doublons ; mesure du parcours de publication au volume cible, distincte du test de génération. |

Tester également le cas nom identique pour deux élèves, le profil tuteur ayant une responsabilité personnel, le matricule mal saisi, l'ID public d'une autre évaluation et une personne ne permettant pas la publication nominative. Utiliser des données synthétiques en staging, jamais publier des résultats réels pour tester.

Livrables de réalisation : migrations additives, inventaire des consommateurs, ports/DTO modifiés, règles d'accès et publication, tests ciblés, procédure de transition et de retour applicatif. Les noms de fichiers et numéros de migrations sont à fixer après réconciliation du dépôt ; ne pas réserver ici un numéro pouvant entrer en conflit avec les lots BR0B.

## 10. Références techniques consultées

Consultées le 7 octobre 2026. Les choix RA/EV, longueurs, badges et parcours proposés sont des décisions de conception de ce complément.

- [OWASP : prévention des références directes non autorisées](https://cheatsheetseries.owasp.org/cheatsheets/Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.html) : un identifiant complexe ne remplace pas le contrôle d'autorisation sur chaque objet.
- [Supabase : authentification par mot de passe](https://supabase.com/docs/guides/auth/passwords) : connexion documentée avec email ou téléphone ; récupération avec protection contre l'énumération.
- [PostgreSQL : fonctions de chaînes, lpad](https://www.postgresql.org/docs/current/functions-string.html) : troncature lorsque la chaîne dépasse la longueur demandée, confirmée ici sur PROD par une expression sans écriture.
- [PostgreSQL : contraintes](https://www.postgresql.org/docs/current/ddl-constraints.html) : unicité, clés étrangères, index associés et traitement des NULL.
- [GitHub : BR-CT-16, source figée examinée](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/708ef8f59bfefae89db071764d3f90a7d6b13322/14_controleur/CT-BR.md).

## 11. Instruction prête à transmettre à Claude

> Lire ce complément avec BR0B canonique sans modifier ce dernier. Vérifier le dépôt et Supabase, puis proposer les migrations additives et les adaptations frontend conformes à IMM-01 à IMM-14. Préserver les UUID, les relations, les anciens identifiants nécessaires et les décisions de confidentialité internes du cockpit. Implémenter un matricule permanent RA aléatoire pour toutes les personnes, avec classification séparée ; utiliser par défaut un code participant EV propre à chaque évaluation publique et permettre à l'administration de choisir ID, nom réel ou les deux dans le cadre des règles serveur de diffusion. Garder la connexion actuelle en V1. Aucun changement de production avant vérification en staging et respect des gates de déploiement du projet.

