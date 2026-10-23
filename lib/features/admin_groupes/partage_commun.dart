import 'package:uuid/uuid.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_partage_pedagogique.dart';
import '../../core/i18n/strings.g.dart';

/// Ce qu'une ecriture de partage a rendu, traduit une fois pour toutes les
/// feuilles de PED-APRES-1 (ADM-PED-APR-02 et 03).
enum ResultatPartage {
  /// Le serveur a confirme.
  ok,

  /// La valeur lue etait perimee : une autre personne de la direction a
  /// modifie entre-temps. L'ecran relit et informe, il n'ecrase jamais.
  conflit,

  /// La personne connectee n'a pas le droit.
  refuse,

  /// Le serveur ne sert pas encore ce reglage.
  indisponible,

  /// Pas de reseau : rien n'est envoye.
  horsLigne,

  /// Echec (reseau, serveur) : la valeur precedente est conservee.
  echec,
}

/// Traduit une erreur du port en [ResultatPartage]. Aucune cause technique ne
/// passe : seul le genre compte pour ce que l'ecran dit.
ResultatPartage resultatDe(Object erreur) => switch (erreur) {
  ConflitPartage() => ResultatPartage.conflit,
  PermissionInsuffisante() => ResultatPartage.refuse,
  CapaciteIndisponible() => ResultatPartage.indisponible,
  _ => ResultatPartage.echec,
};

/// La phrase d'un resultat d'ecriture (`null` pour un succes : le texte du
/// succes depend de l'action).
String? phraseDe(ResultatPartage resultat) {
  final l = t.admin.groupes.partage;
  return switch (resultat) {
    ResultatPartage.ok => null,
    ResultatPartage.conflit => l.conflit,
    ResultatPartage.refuse => l.refuse,
    ResultatPartage.indisponible => l.indisponible,
    ResultatPartage.horsLigne => l.horsLigne,
    ResultatPartage.echec => l.echec,
  };
}

/// Une cle d'idempotence neuve : une par geste, jamais reutilisee apres un
/// succes (un double envoi du meme geste porte la meme cle).
String nouvelleCleGeste() => const Uuid().v4();
