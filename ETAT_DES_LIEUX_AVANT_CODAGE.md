# État des lieux avant codage
## Ce qui est prêt, ce qui bloque, ce qui manquait encore

Six documents livrés à ce jour : `AUDIT_ARCHITECTURE_REWAYAH_APP.md`, `DECISIONS_ARCHITECTURE_MVP0.md`, `PLAN_ETAPE_0_ET_1.md`, `PARCOURS_UTILISATEURS_MVP0.md`, `PLAN_ETAPE_2.md`, `COUVERTURE_SPECS_ORIGINALES.md`. Ce document les traverse tous et répond à une seule question : peut-on donner le code à écrire maintenant.

---

## Verdict par étape

| Étape | Peut démarrer aujourd'hui | Ce qui la bloque, s'il y a lieu |
| :--- | :-: | :--- |
| 0 - Socle d'exploitation | **Oui** | Rien |
| 1 - Fondations données et sécurité | **Oui** | Rien. Le schéma, les policies, les 18 scénarios de test ne dépendent d'aucune question ouverte |
| 2 - Thème, cache, routeur | **Oui** | Un seul point non bloquant, le format de compression photo, avec une valeur par défaut déjà proposée |
| 3 - Auth, KYC, appairage | Partiellement | A besoin du seuil d'âge du mode enfant et de la réponse sur la photo publique enseignant |
| 4 - Dashboards | Partiellement | A besoin de l'identité visuelle si vous voulez la fixer avant plutôt qu'après |
| 5 - Visio et présence | Presque | La riwaya du Coran reste à préciser, tout le reste est prêt |
| 6 - Pédagogie | Presque | Le sens exact du "système d'objectifs élèves" reste à préciser |
| 8 - Guard et audit du Contrôleur | **Oui** | Confirmés dans le MVP-0, écrans spécifiés dans PARCOURS |

**La lecture utile de ce tableau** : les deux étapes les plus lourdes et les plus longues à écrire, l'Étape 0 et l'Étape 1, ne dépendent de rien. Un code agent peut commencer aujourd'hui, pendant que vous tranchez le reste cette semaine. Rien ne vous oblige à tout décider avant la première ligne de migration SQL.

---

## La liste unique de ce qui reste à trancher

Elle était dispersée dans quatre documents. La voici rassemblée, avec l'étape que chaque réponse débloque.

| # | Question | Débloque | Statut |
| :-- | :--- | :--- | :--- |
| ~~1~~ | ~~Pre-Download Guard~~ | ~~Étape 8~~ | **Tranché : dans le MVP-0** |
| ~~2~~ | ~~Grille d'audit Contrôleur~~ | ~~Étape 8~~ | **Tranché : dans le MVP-0** |
| ~~3~~ | ~~Portée des cartes cliquables~~ | ~~Étapes 3, 4, 6~~ | **Tranché : sur toute l'application, ADR-013** |
| ~~M~~ | ~~Stratégie de migration~~ | ~~Étape 1, 3~~ | **Tranché : réinscription en cartes pour les nouveaux, onboarding de confirmation avec accès immédiat et délai de 30 jours pour les personnes déjà connues, ADR-014** |
| 4 | Le "système de création d'objectifs élèves" que vous reportez : est-ce la grille d'examen anonyme et l'imputabilité de vos specs, ou autre chose | Étape 6 | Encore ouverte |
| 5 | Un enseignant a-t-il une photo publique visible avant le premier cours | Étape 3, 4 | Encore ouverte |
| 6 | Riwaya du mushaf, Warsh ou Hafs | Étape 5 | Encore ouverte |
| 7 | Identité visuelle, violet de l'app ou vert et or de Rewayah | Étape 2, 4 | Non bloquant pour commencer, les jetons de couleur sont abstraits |
| 8 | Seuil d'âge exact du mode enfant | Étape 3 | Encore ouverte, évoqué 7 à 8 ans sans valeur fixée |
| 9 | Poular dans l'interface élève dès le MVP-0 ou plus tard | Étape 3 | Encore ouverte |
| 10 | Format de compression des photos, WebP par défaut | Étape 2 | Valeur par défaut retenue |
| 11 | Prestataire de payout de remplacement | V1 uniquement | Non bloquant |

**Quatre questions bloquantes ou structurantes sont tranchées.** Il reste principalement des détails, plus rien qui remette en cause l'architecture.

Cinq questions, la 3 en tête, méritent une réponse avant que l'Étape 3 ne soit vraiment attaquée. Les questions 6 et 7 peuvent attendre l'Étape 4 ou 5 sans rien bloquer avant.

---

## Deux angles morts trouvés dans ce scan final, absents de tout document jusqu'ici

Ce ne sont pas des écrans manquants, ce sont des questions opérationnelles. Elles ne bloquent aucune ligne de code, mais elles conditionnent si l'application peut réellement remplacer votre gestion WhatsApp le jour du lancement.

### Bascule des familles et enseignants déjà actifs

Votre académie tourne depuis deux ans, neuf enseignants, des élèves déjà en cours régulier. Aucun document jusqu'ici ne traite comment ces personnes entrent dans la nouvelle application. Trois options, à choisir sans urgence mais à choisir avant le lancement réel :

1. **Reprise manuelle par vous.** Vous créez les comptes enseignants et les foyers existants directement en base ou via l'espace Admin, sans repasser par tout le portail d'attente pour des gens déjà vérifiés depuis deux ans.
2. **Reprise identique au nouveau flux.** Tout le monde repasse par KYC et NDA, même les enseignants de longue date. Plus long, mais aucune exception dans le code à maintenir.
3. **Bascule progressive.** Les nouveaux inscrits passent par l'application dès le premier jour, les familles existantes restent sur WhatsApp jusqu'à une date de bascule fixée, pour ne pas casser ce qui tourne pendant que l'application se stabilise.

Cette décision ne demande aucune ligne de code supplémentaire dans l'immédiat. Elle demande une date et un choix, que vous pouvez fixer en parallèle de l'écriture de l'Étape 1.

### Visibilité des heures pour les enseignants, malgré la finance reportée

La finance entière attend la V1, portefeuille et paie compris, et c'est votre décision. Une conséquence n'a pas été nommée : en MVP-0, un enseignant qui donne ses cours dans l'application **ne voit nulle part combien d'heures il a faites**. Aujourd'hui sur WhatsApp, un compte informel existe probablement d'une manière ou d'une autre.

Ce n'est pas un module financier, ce serait une lecture seule dérivée des cahiers de transmission déjà stockés, sans wallet, sans paiement, sans rien qui touche à Flutterwave ou à un successeur. Simplement une ligne dans `ENS-02` : "12 heures cette semaine". À vous de dire si cela vaut la peine de l'ajouter au MVP-0 pour la confiance des enseignants pendant la transition, ou si vous préférez garder ce terrain entièrement fermé jusqu'à la V1.

---

## Recommandation pour démarrer aujourd'hui, vu la pression que vous décrivez

Ne pas attendre d'avoir réponse aux onze questions pour commencer. Voici l'ordre qui correspond à ce que vous perdez chaque jour :

1. **Aujourd'hui** : transmettez `PLAN_ETAPE_0_ET_1.md` à votre agent de code. Rien ne le bloque. C'est aussi la partie la plus longue à écrire correctement, donc celle qui a le plus à gagner à démarrer tout de suite.
2. **Cette semaine, en parallèle du code** : tranchez les questions 1 à 5, qui déterminent le périmètre réel du produit. La question 3 en particulier, parce qu'elle façonne des écrans que l'Étape 3 va bientôt attaquer.
3. **Avant que l'Étape 3 ne commence réellement**, ce qui vous laisse le temps du code de l'Étape 0 et 1 : fixez les questions 6 à 9.
4. **En tâche de fond, sans bloquer le code** : décidez de votre stratégie de bascule pour les familles et enseignants déjà actifs. C'est vous qui la mènerez, pas votre agent de code.

Le code peut commencer maintenant. Les questions peuvent se répondre à côté, pas avant.
