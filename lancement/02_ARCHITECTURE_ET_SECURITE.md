# Rewayah - contrats techniques et sûreté
Version : 22 septembre 2026. Avant toute migration, inspecter le schéma réel et les données. Ne pas réappliquer mécaniquement les anciens plans SQL.

## Domaines et frontières
| Domaine | Vérité | Contrat minimal |
|---|---|---|
| Identité, foyer, rôles | Supabase Auth + DB | Enfant lié au tuteur, autorisation par capacité et état de compte |
| Académie | DB versionnée | Référentiel, diagnostic, compétence, objectif, niveau, historique de placement |
| Classes et planning | DB + RPC transactionnelles | Classe stable, maître enseignant, occurrences, exceptions, capacité, fuseaux IANA et DST |
| Salle | LiveKit via tokens serveur | Participation limitée à une séance autorisée ; client reçoit URL/token, aucun secret serveur |
| Présence | Événements LiveKit validés + DB | Dédupliquer webhooks, distinguer connexion, présence académique et incident réseau |
| Ressources | Métadonnées DB + R2 privé | Version, licence, type, autorisation de lecture, URL signée courte |
| Finance | Registres déterministes DB | Politique versionnée, opérations idempotentes, séparation des rôles |
| Audit | Journal append-only | Actions sensibles, accès aux enregistrements, rôle de contrôle, changements de politique |

## Règles d'implémentation
1. Inventorier tables, RPC, policies, edge functions, migrations et clients Flutter existants ; aligner le contrat aux noms réellement présents. Ajouter des migrations additives avec stratégie de retour arrière ou de correction, jamais modifier une migration déjà appliquée comme si elle était neuve.
2. Réservation de place concurrente et affectation via transaction serveur avec contrainte d'unicité pertinente ; vérifier chevauchement d'enseignant, capacité, occurrences et changement de fuseau. Réponse explicite pour attente ou conflit.
3. RLS sur toutes les tables exposées. Tester en contexte réel : famille A n'accède pas à B, enseignant voit uniquement ses groupes et la projection nécessaire, contrôleur n'accède pas aux contacts, enfant ne voit ni finances ni KYC. Une UI cachée ne remplace jamais une policy.
4. Le serveur délivre tokens LiveKit par session et par permission, expiration courte. Webhooks signés et idempotents. Le transport de document partagé doit être révisable, rejouable à la reconnexion et distinct des préférences individuelles. Pas d'événements temps réel qui contournent RLS ou l'autorité métier.
5. Stockage R2 : quatre groupes de secrets/buckets validés séparément ; récupérer leurs noms et scopes de l'environnement autorisé avant branchement. Ne jamais deviner un quatrième nom ni faire transiter KYC vers le bucket de ressources publiques. Vérifier upload, relecture, effacement et droits par famille de données. Aucun secret dans le dépôt ou les logs.
6. Protection des mineurs : identité/KYC séparés des photos publiques d'enseignants et portraits visibles en classe ; accès restreint, consentements et retenues configurables ; accès aux enregistrements tracé ; politique de suppression et gel pour litige. Les exigences légales et de localisation doivent être validées avant ouverture réelle des mineurs.
7. Client local : cache borné et effaçable, données sensibles protégées, file hors ligne seulement pour écritures conciliables et idempotentes. Ne pas mettre des autorisations persistantes en cache comme source de vérité. Fuseaux IANA en stockage, UTC pour les instants.
8. Observabilité : corrélation de séance, métriques sur token, webhook, RPC, reconnexion, enregistrement et déploiement ; logs sans secrets ni données privées. Repli visible lorsque visio, présence ou document échoue ; reprise sans double comptage.

## Contrat CI et déploiement web
Établir la chaîne réelle `push main -> workflow GitHub ou intégration Git Vercel -> build Flutter web -> artefact -> URL de production`. Contrôler repo connecté, branche de production, droits Git App, variables d'environnement par environnement, répertoire racine, commandes d'installation/build, artefact `build/web`, configuration SPA/deep links, protection et statuts requis. Ne pas stocker `service_role`, LiveKit secret ni clés R2 dans le bundle public. Reproduire d'abord l'échec à partir d'un commit identifié et des logs ; corriger la cause prouvée puis tester un push inoffensif sur branche de test et un déploiement main autorisé. Un build local réussi n'atteste pas un déploiement automatique.

## Tests probants
Migrations sur DB neuve et copie anonymisée si possible ; RLS inter-foyers et rôles ; concurrence sur dernière place ; récurrence + DST ; enseignant permanent et remplacement ; token refusé hors séance ; webhook dupliqué et hors ordre ; reconnexion ; contrôle de stockage et URL expirée ; parcours multi-rôles ; vérification CI et URL déployée. Rendre les résultats et limites lisibles, aucun `PASS` inventé.
