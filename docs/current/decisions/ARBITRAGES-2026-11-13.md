# Arbitrages du 13/11/2026 : académie

**Statut** : consignés, documentation seule, aucun code modifié.
**Auteur des arbitrages** : architecte pédagogique, sur délégation du directeur (« à toi de te débrouiller pour le bien des users »).
**Portée** : décision datée du directeur, 13/11/2026 : « et les points qui attendent ma réponse, je ne vais RIEN répondre [...] alors à toi de te débrouiller pour le bien des users. » Par cette délégation, chaque arbitrage ci-dessous vaut décision datée du 13/11/2026 au sens de `CLAUDE.md`, jusqu'à ce que le directeur en décide autrement.

**Vérité d'abord** : à la date de rédaction, aucun des réglages nommés ci-dessous n'a d'identifiant trouvé dans le code ou les migrations (recherche par mots-clés le 14/11/2026). Chaque réglage est donc à créer, ou à retrouver sous un autre nom, avant d'être tenu pour existant.

---

## 1. Le point de séance tient lieu de cahier pour la paie

- **Décision** : le point de séance fait office de cahier de séance pour le calcul de la paie.
- **Raison** : une seule saisie par l'enseignant, qui sert aussi à la paie, au lieu d'une double saisie.
- **Réglage** : « tient lieu de cahier », à l'état ON. Non trouvé dans le code.

## 2. Bibliothèque visible à tous les élèves, avec un choix « adultes seulement »

- **Décision** : la bibliothèque est visible par défaut pour tous les élèves. L'académie peut la restreindre aux adultes.
- **Raison** : ouvrir l'accès par défaut sert l'élève, et le choix « adultes seulement » couvre les cas où l'accès doit être limité.
- **Réglage** : visibilité de la bibliothèque, valeur par défaut « tous les élèves », option « adultes seulement ». Non trouvé dans le code.

## 3. Légende photo des camarades publiée ; les tuteurs sont prévenus

- **Décision** : la légende de la photo des camarades est publiée. Les tuteurs en sont informés.
- **Raison** : la photo de classe a une valeur pour les élèves, et l'information préalable des tuteurs est la condition d'un usage correct.
- **Réglage** : aucun identifiant trouvé. À vérifier : la publication d'images d'élèves doit respecter l'accord de publication et les règles de données personnelles. Ce point n'a pas été contrôlé dans cette consignation.

## 4. Journal des sorties : reste désactivé

- **Décision** : le journal des sorties reste désactivé.
- **Raison** : la fonction n'est pas prête à être publiée ; la laisser désactivée évite un écran vide ou une donnée partielle.
- **Réglage** : journal des sorties, à l'état OFF. Non trouvé dans le code.

## 5. Pause prière : s'applique même si l'enseignant a désactivé les pauses

- **Décision** : la pause prière s'applique, même lorsque l'enseignant a désactivé les pauses.
- **Raison** : la pause prière relève du cadre de l'académie, pas d'un choix pédagogique de l'enseignant.
- **Réglage** : la pause prière est forcée, quelle que soit la préférence de pause de l'enseignant. Le code contient une clé audio `eleve.accueil.pausePriere` (`lib/core/i18n/cle_audio.dart`), mais aucun réglage de pause prière trouvé.

## 6. Un élève qui recommence obtient une nouvelle échéance

- **Décision** : un élève qui recommence un parcours reçoit une nouvelle échéance.
- **Raison** : une échéance d'origine ne doit pas pénaliser une reprise.
- **Réglage** : échéance de reprise. Non trouvé dans le code.

## 7. Classes vitrines : seuils, ouverture, création, paiement et remboursement

- **Décision** :
  - Taille des groupes : 5 enfants ou 6 adultes, débutants inclus.
  - Ouverture à 4 inscrits.
  - Création automatique dans les cas simples. Le système propose, la direction confirme.
  - Paiement pas avant la formation de la classe.
  - Remboursement intégral si la classe ne se forme pas.
- **Raison** : la classe ne doit pas être facturée avant d'exister, et la direction garde la décision finale sur la création.
- **Réglage** : seuils de taille (5 enfants / 6 adultes), seuil d'ouverture (4 inscrits), mode de création (automatique dans les cas simples, confirmation par la direction). Non trouvés dans le code. À vérifier contre `DECISION-OFFRES-GROUPES-2026-10-09.md`, non relu pour cette consignation.

## 8. Seuils de paie 45 min / 70 min inchangés ; fenêtre payée 60 / 90 min

- **Décision** : les seuils de paie restent à 45 minutes (enfants) et 70 minutes (adultes). La fenêtre payée est de 60 minutes (enfants) et 90 minutes (adultes). Rien n'est payé avant ni après cette fenêtre.
- **Raison** : les seuils existants sont confirmés, et la fenêtre payée encadre la séance sans payer le temps hors cours.
- **Réglage** : seuils 45 / 70 min (inchangés) ; fenêtre payée 60 / 90 min. Les seuils sont cités dans `DECISION-TARIFS-2026-10-18.md` pour la paie. La fenêtre payée n'a pas d'identifiant dans le code.

## 9. Pas de recalcul rétroactif des paies passées ; liste des écarts

- **Décision** : aucune paie passée n'est recalculée. Une liste des écarts dus au bug de reconnexion sera dressée.
- **Raison** : recalculer le passé crée plus d'erreurs qu'il n'en corrige ; la liste rend les écarts visibles pour une décision ultérieure.
- **Réglage** : aucun. La liste des écarts reste à produire.

## 10. Créneaux par pas de 5 minutes, avec la refonte « cabine technique » admin

- **Décision** : les créneaux se règlent par pas de 5 minutes. La refonte « cabine technique » de l'administration accompagne ce changement.
- **Raison** : un pas de 5 minutes laisse régler les horaires sans les arrondir.
- **Réglage** : pas des créneaux = 5 minutes. Non trouvé dans le code. La « cabine technique » n'est référencée que dans un document (`docs/current`) ; sa spécification n'a pas été relue.

## 11. Vocabulaire arabe : الإصدار (version), إعادة التحميل (recharger)

- **Décision** : en arabe, « version » se dit الإصدار et « recharger » se dit إعادة التحميل.
- **Raison** : ce sont les deux termes retenus pour les textes d'interface en arabe.
- **Réglage** : entrées de vocabulaire arabe. À reporter dans la compétence `mots-rewayah` et dans `assets/i18n` quand le lot arabe sera lancé.

## 12. Langues : arabe et anglais complets ; textes juridiques et contrat traduits

- **Décision** : arabe et anglais sont complets. Les textes juridiques et le contrat sont traduits en anglais, avec la mention « En cas de divergence, la version française fait foi ».
- **Raison** : la version française reste la référence juridique ; la traduction sert à la compréhension.
- **Réglage** : langues disponibles = fr, ar, en. Mention de primauté du français sur les textes traduits.
- **Point bloquant à annoncer** : `docs/current/A-FAIRE-LANGUES.md` indique que le lot Langues ne doit pas être lancé avant un nouvel ordre du directeur. Cet arbitrage ne vaut donc pas lancement. Il faut un ordre explicite avant tout travail sur les traductions.

## 13. Courriels aux candidats : envoi à tous, une fois l'arabe en ligne

- **Décision** : les courriels aux candidats sont envoyés à tous (hommes et femmes, anciens et nouveaux), une fois l'arabe en ligne.
- **Raison** : aucun candidat n'est écarté de l'information ; l'envoi attend que la langue arabe soit disponible pour eux.
- **Réglage** : envoi conditionné à la mise en ligne de l'arabe. Non trouvé dans le code.

## 14. Envoi de l'inscription en anglais : la langue enregistrée reste « fr »

- **Décision** : l'inscription peut être envoyée en anglais, mais la langue enregistrée côté serveur reste « fr » tant que le CHECK fr/ar n'est pas élargi.
- **Raison** : la contrainte de base de données n'accepte pas encore l'anglais ; élargir le CHECK est un changement de schéma distinct.
- **Réglage** : langue enregistrée côté serveur = `fr`. Contrainte CHECK fr/ar à élargir plus tard, par une migration propre.
