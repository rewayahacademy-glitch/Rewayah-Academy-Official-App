import '../i18n/strings.g.dart';
import '../tc_outils/intention_pedagogique.dart';
import 'student_concern.dart';

/// Le libelle d'une intention pedagogique.
///
/// **Le meme vocabulaire que les marqueurs d'Agent D**, jamais un second : le
/// lot H traduit l'enum, il n'en invente pas les valeurs.
String libelleIntentionParcours(IntentionPedagogique intention) =>
    switch (intention) {
      IntentionPedagogique.aApprendre => t.tc.parcours.intention.apprendre,
      IntentionPedagogique.aRevoir => t.tc.parcours.intention.revoir,
      IntentionPedagogique.aRenforcer => t.tc.parcours.intention.renforcer,
      IntentionPedagogique.aEntretenir => t.tc.parcours.intention.entretenir,
      IntentionPedagogique.pourEvaluation =>
        t.tc.parcours.intention.evaluation,
    };

/// Le libelle d'une categorie de signalement.
String libelleCategorieSignalement(CategorieSignalement categorie) =>
    switch (categorie) {
      CategorieSignalement.pedagogique =>
        t.tc.parcours.signalement.categorieValeur.pedagogique,
      CategorieSignalement.presence =>
        t.tc.parcours.signalement.categorieValeur.presence,
      CategorieSignalement.technique =>
        t.tc.parcours.signalement.categorieValeur.technique,
      CategorieSignalement.changement =>
        t.tc.parcours.signalement.categorieValeur.changement,
      CategorieSignalement.autre =>
        t.tc.parcours.signalement.categorieValeur.autre,
    };
