# REWAYAH - BR-0B CANONICAL BACKEND BLUEPRINT V0.1

Date: 6 octobre 2026
Statut: ARCHITECTURE / PREPRODUCTION - AUCUNE IMPLEMENTATION AUTORISEE PAR CE DOCUMENT
Portee: backend cible, securite, environnements, releases, tests de production

## 1. Objectif

Construire un backend Rewayah qui soit reconstructible, testable, securise, compatible avec des releases frequentes et extensible sans refonte majeure. Le present document ne modifie ni Supabase PROD, ni Supabase STAGING, ni GitHub, ni Vercel, ni R2, ni LiveKit.

## 2. Hierarchie de verite

Ordre obligatoire en cas de conflit:
1. decision explicite la plus recente du directeur;
2. cockpit/pilotage courant;
3. specifications verticales validees et fichiers *-BR.md;
4. etat live Supabase prouve;
5. code de la branche verticale/release candidate concernee;
6. historique Git utile;
7. hypothese d'agent.

Aucun agent ne doit choisir silencieusement entre deux sources contradictoires.

## 3. Environnements canoniques

### PROD
- Nom: Rewayah PROD (Real Users)
- project_ref: gggmtelinlpseweouyav
- Region: eu-west-1 (Irlande)
- Donnees reelles: OUI
- Tests destructifs: INTERDITS
- Etat actuel: backend historique a conserver comme preuve et source utile, pas comme modele parfait.

### STAGING
- Nom: Rewayah STAGING (test)
- project_ref: xldmmlrnxyabdtvxqbyy
- Region: eu-west-2 (Londres)
- Donnees reelles: JAMAIS
- Tests destructifs: AUTORISES
- Etat initial constate: base applicative vierge.

Regle: aucun secret PROD ne doit etre present dans STAGING lorsque le secret donne acces a une ressource de production.

## 4. Gate avant tout branchement backend massif

Aucune phase BR-1 generale tant que les points suivants ne sont pas clos:
- chaine de migrations canonique reconstruite;
- separation PROD/STAGING prouvee;
- auth et deconnexion multi-compte testees;
- tests negatifs RLS/RPC/Storage/vues;
- strategie KYC et lecture sensible arretee;
- idempotence et concurrence validees pour toutes les commandes critiques;
- rollback et restauration testes;
- release candidate testee avant promotion;
- protection mecanique contre les actions IA non autorisees.

## 5. Modele d'autorisation cible

Rewayah ne doit pas etre modele comme `users.role = admin|teacher|guardian|student` uniquement.

Le modele cible combine:
- RBAC: roles comme bundles administrables de capacites;
- Capabilities: actions atomiques predefinies et versionnees;
- ReBAC: relations telles que guardian_of, teacher_of, member_of, controller_for, assigned_to;
- ABAC: contexte courant, par exemple etat du compte, MFA, fenetre temporelle, affectation, genre compatible, seance en cours, droit encore valide.

Evaluation canonique:
`principal -> capability active -> scope/relation -> contexte -> etat serveur courant -> ALLOW | DENY | REQUIRE_APPROVAL`.

Regles:
- default deny;
- aucune autorisation sensible ne depend uniquement d'un ecran masque;
- aucune autorisation sensible ne depend uniquement d'un JWT ancien;
- les droits revocables et critiques sont relus depuis l'autorite serveur;
- un role personnalise est un nom + bundle de capacites, jamais du SQL/RLS arbitraire;
- pas d'heritage profond de roles;
- separation des fonctions pour les combinaisons toxiques: finance, KYC, privilege management, approbation de paiement;
- break-glass explicite, MFA, raison, duree limitee, audit complet.

## 6. Principals

Types cibles:
- HUMAN
- AI_AGENT
- SERVICE
- DEVICE

Un enfant, un tuteur, un enseignant, un controleur, un comptable et un admin restent des principals humains avec relations et capacites.

Un appareil appaire est un principal technique distinct, revocable, qui ne remplace pas l'identite humaine.

## 7. Agents IA

Un agent IA n'agit jamais comme l'admin humain qu'il observe.

Chaque agent a:
- identite propre;
- delegated_by;
- purpose;
- capability ceiling;
- resource scope;
- valid_from / expires_at;
- environnement;
- limite de volume/risque;
- politique d'approbation.

Niveaux d'autonomie:
- A0: lecture/analyse/rapport;
- A1: brouillons et ecritures reversibles a faible risque;
- A2: actions sensibles bornees par politique;
- A3: approbation humaine obligatoire: permissions, RLS, migrations PROD, KYC sensible, paiement final, remboursement, roles admin, suppression massive;
- A4: impossible pour un agent: s'auto-accorder des droits, desactiver l'audit, modifier son policy engine, obtenir les secrets racine.

Execution cible:
`LLM -> Tool Gateway -> Policy Engine -> ALLOW/DENY/REQUIRE_APPROVAL -> API metier -> DB`.

Aucun agent ne recoit une cle service_role permanente ni un acces SQL production general.

## 8. Domaines et sources de verite

### Identite / foyer
Source: Supabase Auth + DB.
Conserver profiles et relations foyer existantes; ne pas dupliquer sous un nouveau modele.

### Classes / planning
Source: DB versionnee + RPC transactionnelles.
Classe stable, enseignant principal, occurrences, exceptions, capacite, fuseau IANA.

### Salle
Source metier: DB; transport media: LiveKit.
Un token LiveKit n'est emis que pour une seance et une permission actuelles.

### Presence
Source: evenements LiveKit signes + DB.
Distinguer connexion technique, presence academique et incident reseau.
Webhooks dedupliques/idempotents.

### Ressources
Metadonnees en DB, fichiers prives en R2.
URLs signees courtes et controle d'acces courant.

### Finance
Ledger append-only comme autorite; soldes comme projections.
Montants entiers en unite mineure + ISO 4217.

### Audit
Journal append-only, ecrit depuis les frontieres metier de confiance, pas librement par le client.

## 9. Appairage, appareils et deconnexion

Deux systemes doivent rester distincts:
- Auth adulte: session Supabase normale;
- Appareil enfant: code d'appairage court -> jeton appareil revocable -> session enfant.

Exigences:
- le PIN enfant local ne constitue pas une authentification forte;
- le jeton appareil est la vraie barriere et doit etre revocable;
- deux appareils du meme enfant ont des jetons distincts;
- une tablette familiale peut memoriser plusieurs profils enfants;
- un appareil public ne doit pas etre presente comme appareil de confiance persistant;
- rate limit serveur obligatoire sur la consommation des codes d'appairage;
- la deconnexion adulte doit supprimer la session adulte et isoler/purger les caches de compte sans supprimer automatiquement les appairages enfants legitimes;
- test obligatoire A -> logout -> B sur meme appareil, puis hors-ligne: aucune donnee A visible.

## 10. Concurrence et idempotence

Toutes les commandes critiques doivent accepter un command_id/idempotency_key et etre transactionnelles.

Cas obligatoires:
- derniere place d'une classe;
- reservation d'un remplacement urgent;
- creation d'un foyer/profil;
- recharge/credit;
- soumission de paiement;
- traitement webhook;
- annulation/remboursement;
- publication d'une politique;
- operations de delegation ou privilege.

Interdit: `SELECT count(*) -> decision client -> INSERT` pour une ressource rare.
Utiliser contraintes, transaction, lock approprie ou RPC atomique.

## 11. Finance

Regles cibles:
- aucun solde authoritative ecrase manuellement;
- ledger append-only;
- balance = projection reconstruisible;
- idempotence commande + reference fournisseur unique;
- machine d'etat explicite;
- reversal par nouvelle ecriture, pas mutation de l'historique;
- separation initiation / approbation / execution lorsque necessaire;
- donnees de paiement masquees par defaut;
- agregats calcules serveur;
- calcul financier de reference jamais dans Flutter.

## 12. KYC et donnees sensibles

Cible:
- KYC prive;
- pas de lecture directe large depuis table/bucket si une voie auditee existe;
- acces document-par-document apres autorisation serveur courante;
- URL signee courte;
- lecture sensible auditee;
- AI_AGENT refuse par defaut;
- retention/purge/legal hold executes techniquement, pas seulement stockes en metadata;
- conflit historique sur acces Controleur a arbitrer selon decision la plus recente du directeur avant activation.

## 13. R2 / stockage

Les 4 familles R2 PROD sont conservees comme architecture.
STAGING doit utiliser des ressources de test distinctes ou des doubles/simulations lorsque la separation complete n'est pas disponible.

Chaque domaine impose:
- bucket prive;
- object key opaque et unique;
- limite taille;
- validation type/contenu;
- URL signee courte;
- nettoyage des orphelins;
- retention/lifecycle;
- aucun secret dans client/logs/Git.

## 14. RLS, vues et fonctions

RLS automatique: conserver `ensure_rls` / `rls_auto_enable` comme garde de creation de table.
Durcir l'EXECUTE direct de cette fonction sur STAGING avant PROD.

Toutes les vues publiques doivent etre classees:
- security_invoker si elles doivent respecter les droits de l'appelant;
- voie serveur explicite si elles doivent elever les privileges;
- schema non expose si elles sont internes.

SECURITY DEFINER:
- INVOKER par defaut;
- DEFINER seulement avec justification explicite;
- search_path fixe;
- grants minimaux;
- controle serveur complet dans le corps;
- pas de fonction interne appelable par anon/authenticated sans besoin produit.

## 15. Realtime / LiveKit

- canaux prives et scopes etroits;
- pas de souscription globale;
- cleanup explicite a la navigation/background;
- reconnexion avec backoff+jitter;
- reconnexion technique ne doit pas creer une nouvelle presence academique;
- audio prioritaire en mauvaise connexion;
- adaptiveStream/dynacast conserves;
- presence transitoire avec retention minimale;
- la revocation serveur doit bloquer les nouveaux tokens/canaux et etre verifiee a la prochaine action sensible.

## 16. Cache local / offline

Chaque type de donnee locale doit declarer:
- proprietaire logique;
- identite/foyer scope;
- chiffrement requis ou non;
- duree de vie;
- comportement logout;
- comportement switch account;
- comportement offline;
- purge apres synchro si applicable.

Aucune donnee d'un foyer ne doit etre visible apres connexion d'un autre foyer sur le meme appareil.

## 17. Performance et echelle

Ne pas optimiser sur hypothese seule.

Regles:
- pagination curseur;
- champs selectionnes, pas SELECT * par defaut;
- budgets de donnees par ecran;
- pas de N+1;
- index selon requetes mesurees;
- read models/projections pour dashboards;
- autorite ecriture normalisee separee des projections;
- cache et replica jamais utilises pour decider une revocation, un dernier siege, un paiement final ou un privilege sensible.

Evolution extreme future:
- control plane minimal;
- cellules regionales/locales par domaine ou tenant lorsque mesure justifiee;
- transactions locales + evenements inter-cellules;
- analytics asynchrones;
- IDs globaux non dependants d'un compteur global;
- `id_sequences` actuel et chaine globale d'audit sont des candidats a refonte avant scale extreme, pas des changements immediats sans mesure.

## 18. Chaine de migrations et reproductibilite

La production live contient 0039-0042 qui ne sont pas dans main; Git contient 0043 non applique en PROD.

Regle immediate:
- aucune nouvelle migration BR-1 avant reconciliation;
- construire une chaine canonique rejouable sur STAGING vierge;
- ne jamais modifier silencieusement une migration deja appliquee;
- preferer migrations additives;
- expand -> migrate/backfill -> switch -> contract;
- compatibilite frontend N/N-1 pendant la fenetre de release.

STAGING doit devenir la preuve qu'une base Rewayah peut etre reconstruite depuis Git sans copie opaque de PROD.

## 19. Release engineering

Version publique cible: Rewayah 3.x.
Version technique separee du build.

Flux cible:
DEV -> STAGING -> RELEASE CANDIDATE immuable -> smoke tests -> promotion PROD.

Regles:
- pas de deploy direct production avant tests du candidat;
- rollback N-1 documente et teste;
- feature flags serveur pour activation progressive;
- aucune mise a jour PWA ne coupe une seance en cours;
- min_supported_build pour incompatibilite reelle;
- une release DB reste compatible avec le frontend precedent pendant la transition.

## 20. Tests obligatoires avant premiere cohorte

### Autorisation
Matrice principal x capability x relation x etat x operation.
Inclure: deux foyers, compte desactive, JWT ancien, grant revoque, controleur/KYC, agent observant admin, mauvais groupe, mauvaise seance, service principal.

### Integrite
Double clic, retry reseau, webhook duplique/hors ordre, deux inscriptions sur derniere place, deux remplacements simultanes.

### Appareils
Logout/switch account, tablette familiale, deux appareils enfant, appareil revoque, cache offline apres changement de compte.

### Temps
Fuseaux IANA, DST, horloge appareil fausse, voyage, minuit, occurrences recurrentes.

### Reseau/media
Wi-Fi faible, 4G, Wi-Fi -> 4G, UDP bloque, VPN, Safari iOS, Chrome Android, mise en background, reconnexion.

### Panne
Supabase indisponible, LiveKit indisponible, R2 indisponible, Vercel indisponible, email indisponible.

### Recovery
Backup externe, restauration sur STAGING, verification fonctionnelle apres restore.

## 21. Lots de production immediats

### Lot A - Canonical Migration Chain
Livrable: repertoire Git unique qui reproduit exactement le schema valide, incluant la reconciliation 0039-0042 et la decision explicite sur 0043.
Aucune application PROD.

### Lot B - Staging Bootstrap
Livrable: STAGING reconstruit depuis Git, sans donnee reelle et sans secret PROD.

### Lot C - Security Hardening
Livrable: corrections testees sur STAGING des vues, grants, fonctions SECURITY DEFINER, KYC, agent_ro, stale JWT, appairage brute-force.

### Lot D - Session/Device Correctness
Livrable: logout reel, switch account propre, cache scoping, appairage multi-appareil, revocation.

### Lot E - Release Safety
Livrable: release candidate, smoke tests avant promotion, rollback N-1, versioning 3.x, feature flags, protections GitHub/Vercel/Supabase.

### Lot F - BR-1 wiring
Seulement apres PASS A-E et validation du directeur.

## 22. Arbitrages directeur encore ouverts

Ne pas coder ces points sans decision explicite:
- politique finale d'enregistrement des cours et retention;
- acces final KYC du Controleur versus Direction uniquement;
- strategie MFA privilegies et methode de recuperation;
- statut exact de 0043_offres_horaires_et_intentions;
- politique de paiement/PSP finale et activation des vraies transactions;
- seuils de feature rollout et taille de cohorte canary.

## 23. Definition de "pret production"

Une fonctionnalite critique n'est "prete" que si:
- specifiee;
- presente dans le code;
- testee localement;
- testee sur STAGING;
- testee negativement/adversarialement;
- observable;
- rollback connu;
- deployee.

Un ecran high-fi termine ou un contrat frontend termine n'est pas une preuve de disponibilite backend.

