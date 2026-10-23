# 05 - PLAN D'IMPLÉMENTATION REWAYAH V3

30 septembre 2026. Spécification arrêtée ; implémentation non exécutée. S'appuyer sur les cinq documents métier V3, puis sur `06` pour les coûts externes. Les règles ne doivent pas être recopiées sous forme de calculs divergents dans chaque écran.

## 1. Architecture des règles

Un service de calcul déterministe produit devis, calendrier facturé, aide, paie et explications. Les interfaces consomment ces résultats avec leur version. La logique de référence, les autorisations et la validation des écritures financières sont contrôlées côté serveur. Le frontend peut prévisualiser, jamais décider seul d'un prix ou crédit réel.

Objets métier requis, à mapper sur l'existant avant de créer quoi que ce soit : version de politique avec date d'effet ; offre vitrine ; demande d'inscription ; groupe et pattern/fuseau ; affectation enseignant ; séance planifiée et séance d'origine d'un rattrapage ; place élève et régime de prix ; facture mensuelle et détail ; journal de solde ; dossier d'aide confidentiel ; engagement de bourse ; lignes de paie ; attribution de bonus mensuel ; barème de frais par corridor ; budget/version de prévision ; événement d'audit.

Chaque devis conserve les entrées utilisées : catégorie/format, foyer éligible, T/O/E, dates de congé, aide, taxe, frais, version et expiration. Toute opération financière autoritaire recalcule ou vérifie le devis côté serveur avant validation. Une modification de règle n'altère jamais un devis accepté ni une écriture clôturée.

## 2. Codé dans le moteur et non modifiable par un écran

| Invariant | Comportement obligatoire |
|---|---|
| Autorisation | Vérifier côté serveur identité, capacité et périmètre à chaque lecture/écriture ; refus par défaut |
| Solde | Écritures append-only et corrections compensatrices ; aucune modification directe d'un montant historique |
| Unicité | Un débit de service par élève, mois et engagement ; changer de version ne crée pas un deuxième débit, mais une écriture compensatrice si nécessaire ; une paie par prestation validée ; un bonus mensuel par bénéficiaire |
| Idempotence | Réexécution d'une demande, d'un job ou d'un événement prestataire sans double crédit/débit/versement |
| Prix | Calcul en unités monétaires précises, devise explicite, arrondi final ; pas de nombres flottants approximatifs pour le ledger |
| Congés | O=0 donne zéro ; appliquer le tarif congé avant prorata d'entrée E/O ; pas de second plancher sur le prorata |
| Cohorte | Un calendrier commun ; absence ordinaire ne crée pas de consommation gratuite ; pas d'échéance individuelle glissante |
| Bourses | Réserver quota et budget atomiquement ; compter les engagements ; préserver une bourse existante malgré baisse de N |
| Remplacements | Une séance ne peut pas être payée deux fois ; aucun transfert rétroactif de paie acquise au gagnant du bonus |
| Dossiers sensibles | Motif orphelin/conversion non accessible aux enseignants, élèves tiers, support général ou IA |
| Preuve paiement | Retour de navigateur ou capture utilisateur ne suffit pas à créditer ; confirmation prestataire ou rapprochement autorisé |
| Secrets | Identifiants API et secrets de paiement absents du client et des journaux utilisateur ; référence sécurisée seulement dans la configuration |
| Version | Les changements prennent effet à une date publiée ; aucune modification rétroactive silencieuse |
| Limites | Capacité pédagogique, quote-part et droits doivent être contrôlés en concurrence, pas seulement au clic UI |

Le mois civil et l'algorithme de cumul/bonus sont des politiques implémentées et versionnées. Ils ne disposent pas d'un simple interrupteur permettant de revenir au mode 30 jours. Un changement de modèle requiert spécification et migration contrôlée. Les nombres suivants restent configurables.

## 3. Paramètres dynamiques de lancement

| Paramètre | Valeur V3 | Modification autorisée |
|---|---|---|
| Prix enfant/adulte | 50 / 60 USD | Directeur, date d'effet et notification |
| Remise familiale | seuils 2/3, montants 5/10 USD individuels | Directeur ; simulation foyer avant publication |
| Base paie enfant/adulte | 20 / 26 USD | Directeur, contrat/version future |
| Bonus incomplet/plein ou multiclasses | 10 / 20 USD, multiclasses à partir de 2 | Directeur |
| Capacité enfant/adulte | 5 / 6, débutants 4 | Directeur ; responsable académique choisit le profil approuvé |
| Minimum d'ouverture | 4 | Directeur ; ouverture sous seuil par autorisation et budget tracés |
| Plafond classes/enseignant | 2 | Directeur via le dispositif de badge |
| Préavis de démarrage | 48 heures | Directeur |
| Attente formation | 14 jours + une extension de 7 jours consentie | Directeur |
| Mise à jour demande | J7 au plus tard et à chaque événement important | Admin opérationnel selon règle |
| Pause personnelle | mois complet, préavis 7 jours | Directeur pour règle ; famille pour sa demande |
| Absence titulaire | 14 jours calendaires maximum | Directeur pour règle ; admin pour affectation |
| Quota gratuit | 3 par tranche complète de 100 payants | Directeur, simulation et engagements conservés |
| BDD | orphelins 12 mois/limite 18 ans ; convertis 6 mois | Directeur ; dossier individuel contrôlé |
| Conversion récente | 24 mois avant demande | Directeur, sans automatiser un jugement religieux |
| Contribution aide partielle | 10 % minimum après coûts directs | Directeur, contrôle global obligatoire |
| Marge nette globale | plancher 40 % | Directeur uniquement par nouvelle version explicite ; aucune dérogation ponctuelle cachée |
| Congés | dates grégoriennes publiées, Ramadan ≤20 jours, Tabaski 10 jours | Admin prépare, directeur publie |
| Plancher mois congé | 25 enfant / 30 adulte | Directeur |
| Sponsoring / API / LiveKit | maxima 300 / 50 / 500 USD mensuels | Directeur ; frais réellement observés séparés |
| Barèmes externes | pourcentage, fixe, devise, taxe, FX, minima/maxima | Comptable prépare, directeur approuve l'activation |
| Régime fiscal | dossier réel par territoire, période et taxe | Comptable renseigne, directeur valide la publication des prix |
| Prévisions et coût de personnel | charges engagées, estimées documentées et réelles distinctes | Comptable ; directeur pour engagement |

Aucune valeur non connue n'est remplacée par zéro afin de faire passer un contrôle. Les prix publics et les plafonds de budget sont des décisions ; leur activation opérationnelle dépend des données de coût et des comptes réellement habilités.

## 4. Permissions par rôle

Le directeur est un administrateur possédant des capacités privilégiées ; ne pas déduire ce statut d'un nom, d'une adresse email dans le client ou d'un champ modifiable par l'utilisateur.

| Action | Directeur | Admin opérationnel | Comptable | Contrôleur | Enseignant | Tuteur / adulte |
|---|---|---|---|---|---|---|
| Publier prix, règles, budgets | Oui | Non | Préparer coûts | Lire | Non | Lire son devis |
| Modifier calendrier de cours | Approuver changement structurel | Préparer/exécuter autorisé | Lire effet financier | Lire | Proposer | Accepter changement concernant sa place |
| Affecter/remplacer un professeur | Oui | Oui, groupes autorisés | Lire paie | Lire | Disponibilités seulement | Lire son groupe |
| Valider niveau/capacité pédagogique | Oui ou délégation académique | Si capacité académique accordée | Non | Lire décision sans notes privées inutiles | Groupes confiés, selon habilitation | Demander réévaluation |
| Instruire une aide | Oui | Uniquement délégation confidentielle explicite | Coûts/montants, pas motif religieux détaillé | Audit restreint | Non | Son dossier ou enfant représenté |
| Accorder aide gratuite/partielle | Oui, contrôle automatique préalable | Non par défaut | Préparer calcul | Lire résultat | Non | Accepter son offre |
| Créditer après paiement manuel | Approuver ou capacité financière dédiée | Non | Rapprocher et soumettre | Lire | Non | Déposer référence/preuve |
| Corriger facture / restituer | Approuver action motivée | Signaler | Préparer écriture compensatrice | Lire | Non | Demander |
| Clôturer paie / envoyer paiement | Autoriser lot final | Non | Préparer et rapprocher | Lire | Lire sa paie/contester | Non |
| Consulter soldes | Périmètre nécessaire | État payé/non payé nécessaire au service | Données financières | Lecture audit | Pas de solde familial | Son solde et enfants autorisés |
| Accorder droits privilégiés | Oui, contrôle renforcé | Non | Non | Non | Non | Non |

Le contrôleur ne devient pas éditeur par le fait de détecter une anomalie. Le support général voit uniquement le contexte utile à la demande. Un enseignant voit une place autorisée et les besoins pédagogiques, pas le montant payé ni le motif d'une aide. À la majorité, ne pas prolonger automatiquement les droits de représentation du tuteur sur les données personnelles et pédagogiques ; le paiement par un parent ne donne pas accès à tout le dossier d'un adulte.

Au lancement avec une seule personne administrative, le directeur peut assumer les tâches opérationnelles et financières avec réauthentification renforcée, motif, preuve et audit. Ne pas prétendre qu'un double contrôle indépendant a eu lieu. Dès délégation, séparer préparation et approbation des versements ; aucun comptable ne s'accorde ses propres droits. Ne pas bloquer la maquette pour créer artificiellement un deuxième employé.

L'IA n'a aucun droit d'écriture financière ou d'attribution. Elle lit seulement les règles publiques et un contexte minimal autorisé ; les dossiers religieux, KYC et secrets sont exclus. Elle transmet un besoin à un humain sans décider du résultat.

## 5. Surfaces et états UI

| Surface canonique | Contenus et actions |
|---|---|
| Classes | Vitrines, compatibilité, choix du pattern, demande personnalisée secondaire |
| Ma demande | Étapes réelles, prochaine mise à jour, échéance, date confirmée quand connue, alternatives et annulation |
| Détail de classe | Professeur affecté et photo, première date, calendrier, fuseaux, statut de la place, règles de reprise |
| Solde et paiements | Solde par élève et total foyer, facture détaillée, prochain débit, recharge, avoir/restitution, échec paiement |
| Absences et pauses | Absence ordinaire sans gratuité, pause mensuelle gratuite, préavis, impact sur le foyer, retour non garanti |
| Aides | Demande confidentielle, durée, montant dû, couverture, échéance et renouvellement ; motif jamais public |
| Enseignant - rémunération | Séances, base, division T, titulaire/astreinte, bonus unique expliqué, mois acquis et mois payé |
| Admin - groupes | Formation, échéances à traiter, affectation, ouverture et exception financée, pauses, capacité |
| Admin - politiques | Paramètres, historique, aperçu avant/après, date d'effet, droits d'approbation |
| Finance | Rapprochements, passifs clients, paies, engagements bourses, budget, marge observée/prévue, alertes capacité |

Une fonction possède un écran de référence ; les autres écrans affichent un résumé avec lien. Éviter plusieurs formulaires contradictoires de pause, remise ou remboursement.

Chaque parcours couvre chargement, vide, succès, erreur, accès interdit, données incomplètes, état périmé et action concurrente. Une aide impossible pour budget insuffisant est expliquée sans exposer les finances de tiers. Une politique modifiée pendant un devis provoque un nouveau devis explicite, pas un montant changé au dernier clic.

Respecter mobile/tablette/vrai desktop, clair/sombre, accessibilité clavier et lecteur d'écran, contrastes, annonces de statut ; les dates et erreurs ne reposent pas sur la couleur seule. DM Sans pour titres français, Plus Jakarta Sans pour texte latin. Préserver les maquettes validées lorsqu'elles correspondent à V3.

## 6. Lots de réalisation

1. **Contrats fonctionnels et fixtures** : rapprocher l'existant des règles CAL/PRIX/AIDE/PROF/CONG/FIN ; identifier les anciens écrans, libellés et calculs de 30 jours. Préparer les données de démonstration et les décisions de version, sans exécuter de migration.
2. **Parcours famille et adulte** : Classes → Ma demande → Confirmation → Solde → Pauses/Aides. Perfectionner l'existant et réaliser les états manquants. Montrer calcul mensuel et congés sur données contrôlées.
3. **Parcours enseignant** : affectation, remplacement, séances, calcul de paie, attribution du bonus et contestation. Empêcher les actions hors périmètre dans l'UI.
4. **Administration et finance** : politiques datées, simulation avant publication, réservations de quota/budget, rapprochements et lots de paiement. Matrice des capacités visible en recette.
5. **Enforcement et intégration financière** : après autorisation d'implémentation correspondante, appliquer les invariants côté serveur, validations prestataires et tests d'isolation. Les écrans des lots précédents ne sont pas une sécurité suffisante pour l'argent réel.
6. **Recette et bascule** : scénario complet par rôle, calculs, droits, incidents et restauration. Activer seulement les corridors avec compte opérationnel et barème approuvé. Aucun débit réel sur la seule base de fixtures.

La préparation UI peut avancer immédiatement. Ce document est un plan ; il n'autorise pas par lui-même un push, une migration, un envoi de paiement ou un déploiement. La reprise des dossiers existants conserve soldes et droits acquis ; aucune re-facturation pour aligner arbitrairement une famille au 1er. La bascule d'un éventuel ancien cycle actif nécessite un devis de transition sans double service facturé et une date d'effet acceptée.

## 7. Recette attendue

| Cas | Résultat attendu |
|---|---|
| Deux enfants + adulte, régime familial | 40 + 40 + 50 = 130 USD pour mois complet normal |
| Un enfant gratuit + un adulte | 0 + 60, le gratuit ne crée pas le palier familial |
| Deux normaux + une aide partielle | Les deux normaux reçoivent 5 USD chacun ; aide calculée à part et non cumulée |
| Deux entrées simultanées dans un foyer | Un même instantané familial cohérent pour les deux devis |
| Nouvelle cohorte démarrant le 12 | Même premier cours et calendrier pour tous ; prorata puis renouvellement commun le 1er |
| 13 séances normales, E=8, enfant 50 | Débit initial 30,77 USD |
| Congé T=13 O=6, enfant familial 40 | Mois complet 25 USD ; entrée E=3 → 12,50 USD |
| Congé T=13 O=6, adulte familial 50 | Mois complet 30 USD ; entrée E=3 → 15 USD |
| O=0 | Aucun débit et aucune division par zéro |
| Absence élève à une séance disponible | Pas de réduction du débit ni de la paie attachée à la place |
| Pause complète annoncée dans le délai | Aucun débit de service sur ce mois ; effet familial annoncé |
| Demande de pause de quelques jours | Information sur absence ordinaire payante ; aucun gel à la séance |
| 99/100/199/200 payants | Plafonds gratuits 0/3/3/6 |
| Quota tombe sous engagements existants | Maintien de la couverture promise ; nouvelles attributions bloquées |
| Deux demandes sur dernière bourse | Une seule attribution finale, quota/budget non dépassés |
| Bourse se termine à 18 ans | Fin à la date annoncée ; devis de continuation accepté, pas de débit surprise |
| Astreint 8 séances / titulaire 5 | Chacun sa paie de séances ; bonus de cette classe attribué à l'astreint |
| Deux classes incomplètes attribuées au même bénéficiaire | Un bonus total de 20 USD |
| Une classe complète à capacité pédagogique de 4 | Bonus 20 USD au bénéficiaire |
| Égalité des séances | Départage déterministe défini dans `03`, pas deux bonus |
| Rattrapage dans mois suivant | Même prestation d'origine ; pas de second débit ni de double paie |
| Webhook répété et réponse navigateur falsifiée | Un seul crédit vérifié ; faux retour sans effet financier |
| Famille tente l'identifiant d'une autre famille | Lecture et modification refusées côté serveur |
| Enseignant modifie bonus/prix dans la requête | Refus côté serveur, montant recalculé à partir de la politique |
| Comptable tente auto-approbation du lot | Refus sans capacité d'approbation ; action tracée |
| Contrôleur / IA tente une mutation | Refus ; aucun contournement par un écran caché |
| Frais manquants ou devise différente | Contrôle financier incomplet visible ; aucun faux coût nul |
| Budget LiveKit approche plafond | Alerte et contrôle des nouvelles ouvertures ; aucune coupure automatique des cours vendus |

Ces tests sont des critères à implémenter. Les exemples arithmétiques du dossier ont été vérifiés ; les permissions et transactions de l'application ne sont pas déclarées testées sans exécution réelle.
