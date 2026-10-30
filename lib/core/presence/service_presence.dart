import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../observabilite/journal_dev.dart';
import '../session/session_controleur.dart';

/// Les quatorze etats de presence de la Bible section 29.1, plus l'inconnu.
///
/// **Quatorze, ni un de plus ni un de moins** : l'invariant J4 de l'etape 5
/// l'interdit sans decision ecrite, et l'enumere SQL `public.presence_state`
/// les porte dans cet ordre.
///
/// [inconnu] n'est pas un quinzieme etat metier : c'est l'absence d'etat, et
/// c'est l'invariant **J3** qui l'impose. Un etat de presence indisponible --
/// parce que le reseau a coupe, parce que la lecture est refusee, parce que la
/// base rend une valeur que cette version ne connait pas -- s'affiche comme
/// inconnu, **jamais comme « absent »**. La difference n'est pas cosmetique :
/// « absente » est un fait qui compte pour la facturation et pour le suivi
/// pedagogique ; ne pas savoir n'en est pas un.
enum EtatPresence {
  /// Avant l'ouverture de la fenetre d'entree, a T-10 minutes.
  planifiee('planifiee'),

  /// La fenetre est ouverte, personne n'est encore entre.
  enAttente('en_attente'),

  /// Un jeton vient d'etre emis, la connexion est en cours.
  enConnexion('en_connexion'),

  /// Entre, et toujours la.
  presente('presente'),

  /// Entre apres l'heure, au-dela du seuil configure.
  enRetard('en_retard'),

  /// Sorti sans geste volontaire : le lien a lache.
  deconnectee('deconnectee'),

  /// Sorti sans geste volontaire, et la fenetre de retour court encore.
  enReconnexion('en_reconnexion'),

  /// Revenu apres une coupure.
  reconnectee('reconnectee'),

  /// Parti volontairement, bouton de sortie presse.
  sortie('sortie'),

  /// La seance est finie et cette personne n'est jamais entree.
  absente('absente'),

  /// Une absence excusee par decision administrative.
  excusee('excusee'),

  /// La seance est finie, la presence est calculee mais pas consolidee.
  confirmationEnAttente('confirmation_en_attente'),

  /// Un enseignant ou une administration a corrige l'etat calcule.
  corrigeeManuel('corrigee_manuel'),

  /// Etat consolide, immuable.
  finalisee('finalisee'),

  /// **Pas un etat de la base : l'absence de reponse.** Voir J3 ci-dessus.
  inconnu('');

  const EtatPresence(this.valeurSql);

  /// La valeur telle que `public.presence_state` la nomme.
  final String valeurSql;

  /// Lit un etat rendu par la base.
  ///
  /// Se replie sur [inconnu], et c'est la seule reponse tenable : le jour ou la
  /// base gagnerait un quinzieme etat, une application non mise a jour dirait
  /// « je ne sais pas » plutot que d'affirmer une absence qu'elle n'a pas lue.
  static EtatPresence depuisSql(String? valeur) {
    for (final EtatPresence etat in EtatPresence.values) {
      if (etat != EtatPresence.inconnu && etat.valeurSql == valeur) {
        return etat;
      }
    }
    return EtatPresence.inconnu;
  }

  /// Vrai quand l'etat demande une reaction, de l'usager ou de l'enseignant.
  ///
  /// C'est ce qui declenche l'application de l'invariant **J7** : un etat
  /// critique ne se represente jamais par une couleur seule. Le produit le
  /// tient de deux manieres, la pastille qui porte toujours son mot et la
  /// phrase de contexte qui l'accompagne.
  bool get critique => switch (this) {
    EtatPresence.deconnectee ||
    EtatPresence.enReconnexion ||
    EtatPresence.absente ||
    EtatPresence.enRetard ||
    EtatPresence.inconnu => true,
    EtatPresence.planifiee ||
    EtatPresence.enAttente ||
    EtatPresence.enConnexion ||
    EtatPresence.presente ||
    EtatPresence.reconnectee ||
    EtatPresence.sortie ||
    EtatPresence.excusee ||
    EtatPresence.confirmationEnAttente ||
    EtatPresence.corrigeeManuel ||
    EtatPresence.finalisee => false,
  };
}

/// La presence d'une personne a une seance, telle que `presence_seance_v`
/// l'expose.
///
/// **Les inscrits, pas les connectes.** C'est toute la difference avec la liste
/// que publie le moteur temps reel : celui qui n'est jamais arrive n'a aucune
/// piste LiveKit, donc aucune ligne cote moteur -- et c'est precisement de lui
/// que l'enseignant a besoin de savoir quelque chose.
@immutable
class PresenceParticipant {
  /// Cree une ligne de presence.
  const PresenceParticipant({
    required this.profilId,
    required this.role,
    required this.prenom,
    required this.identifiantImmuable,
    required this.etat,
    required this.consolide,
    this.seanceId = '',
    this.entreLe,
    this.derniereTraceLe,
    this.debutSeance,
  });

  /// Lit une ligne de la vue.
  factory PresenceParticipant.depuisJson(Map<String, dynamic> json) =>
      PresenceParticipant(
        seanceId: json['session_id'] as String? ?? '',
        profilId: json['profile_id'] as String? ?? '',
        role: json['role'] as String? ?? '',
        prenom: json['prenom'] as String? ?? '',
        identifiantImmuable: json['identifiant_immuable'] as String? ?? '',
        etat: EtatPresence.depuisSql(json['etat'] as String?),
        consolide: json['consolide'] as bool? ?? false,
        entreLe: DateTime.tryParse(json['entre_le'] as String? ?? '')
            ?.toLocal(),
        derniereTraceLe: DateTime.tryParse(
          json['derniere_trace_le'] as String? ?? '',
        )?.toLocal(),
        debutSeance: DateTime.tryParse(json['started_at'] as String? ?? '')
            ?.toLocal(),
      );

  /// La seance a laquelle cette ligne appartient.
  ///
  /// Vide dans la salle, ou elle ne sert a rien : l'ecran a demande **une**
  /// seance, il sait laquelle. Elle devient indispensable des que plusieurs
  /// seances se lisent d'un coup -- `TUT-06` rapproche chaque etat de son cours,
  /// et sans cette colonne il devrait redemander la presence seance par seance,
  /// c'est-a-dire une requete par ligne de liste.
  final String seanceId;

  /// L'identifiant du profil. **C'est aussi l'identite LiveKit** : la base emet
  /// `identity = profile_id::text`, ce qui permet de rapprocher une ligne de
  /// presence d'une vignette sans table de correspondance.
  final String profilId;

  /// Le role tenu dans la seance : `teacher`, `student`, `guardian_observer`
  /// ou `masked_controller`.
  final String role;

  /// Le prenom. Jamais le nom de famille (ADR-008).
  final String prenom;

  /// L'identifiant immuable, celui qui distingue deux homonymes.
  final String identifiantImmuable;

  /// L'etat derive, ou [EtatPresence.inconnu].
  final EtatPresence etat;

  /// Vrai quand une decision humaine a fige cet etat.
  ///
  /// La vue dit **qu'il** y a eu decision, jamais **pourquoi** : le motif reste
  /// en base et au journal d'audit. C'est ce qui permet a l'enseignant de
  /// distinguer le provisoire du finalise sans exposer un detail administratif
  /// a l'eleve (section 6.6).
  final bool consolide;

  /// Premiere entree constatee, s'il y en a eu une.
  final DateTime? entreLe;

  /// Derniere trace recue, quelle qu'elle soit.
  final DateTime? derniereTraceLe;

  /// Le debut planifie de la seance.
  final DateTime? debutSeance;

  /// L'enseignant de la seance.
  bool get estEnseignant => role == 'teacher';
}

/// La lecture de la presence d'une seance.
abstract interface class ServicePresence {
  /// La presence de tous les participants **que l'appelant a le droit de
  /// voir**.
  ///
  /// La borne est en base, dans la vue : un eleve n'y lit que sa propre ligne,
  /// un enseignant celles de ses seances. Le client ne filtre rien, et c'est
  /// voulu -- un filtre client serait une decoration par-dessus une donnee deja
  /// livree.
  ///
  /// Rend `null` quand la presence est **indisponible** : reseau coupe, lecture
  /// refusee, reponse illisible. `null` n'est pas une liste vide -- une liste
  /// vide dit « personne », `null` dit « je ne sais pas » (invariant J3).
  Future<List<PresenceParticipant>?> presence(String seanceId);
}

/// L'implementation reelle.
class ServicePresenceSupabase implements ServicePresence {
  /// Cree le service.
  const ServicePresenceSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PresenceParticipant>?> presence(String seanceId) async {
    if (seanceId.trim().isEmpty) return null;
    try {
      final List<Map<String, dynamic>> lignes = await _client
          .from('presence_seance_v')
          .select()
          .eq('session_id', seanceId);
      return lignes.map(PresenceParticipant.depuisJson).toList();
    } catch (erreur) {
      // Aucune exception ne remonte a l'ecran : une salle ne se ferme pas
      // parce qu'un tableau de presence n'a pas repondu. L'inconnu est un etat
      // affichable, pas une panne.
      journalDev('presence indisponible : $erreur');
      return null;
    }
  }
}

/// Le service de presence employe par l'application.
final Provider<ServicePresence> servicePresenceProvider =
    Provider<ServicePresence>(
      (Ref ref) => ServicePresenceSupabase(Supabase.instance.client),
    );

/// Chaque combien la presence est relue.
///
/// **Vingt secondes, et ce n'est pas un chiffre rond pris au hasard.** Deux
/// des quatorze etats basculent avec le seul ecoulement du temps, sans qu'aucun
/// evenement ne survienne : `en_reconnexion` devient `deconnectee` au bout de
/// deux minutes, `en_connexion` retombe sur `en_attente` au bout de quatre-vingt
/// dix secondes. Un ecran qui ne relirait qu'aux evenements resterait donc
/// indefiniment sur un « reconnexion en cours » qui n'a plus lieu d'etre. Vingt
/// secondes, c'est un sixieme de la plus courte de ces deux fenetres.
const Duration cadencePresence = Duration(seconds: 20);

/// La presence d'une seance, relue a la [cadencePresence].
///
/// Le flux **ne s'interrompt jamais sur une erreur** : une lecture qui echoue
/// emet `null`, l'ecran affiche l'inconnu, et la lecture suivante a lieu comme
/// prevu. Un `StreamProvider` qui propagerait l'erreur laisserait l'ecran sur
/// un etat d'echec definitif alors que le reseau revient en trois secondes.
///
/// **Une minuterie annulable, et non une boucle `async*` qui attend.** La
/// seconde s'ecrit en trois lignes et parait equivalente ; elle ne l'est pas :
/// son `Future.delayed` continue de courir apres la sortie de la salle, parce
/// que rien ne peut l'interrompre. Le defaut ne s'est pas devine, il a ete
/// **mesure** -- `flutter test` echoue sur « A Timer is still pending even
/// after the widget tree was disposed », et ce que le test dit d'un arbre
/// demonte vaut aussi d'un eleve qui a quitte le cours.
final StreamProviderFamily<List<PresenceParticipant>?, String>
presenceSeanceProvider =
    StreamProvider.family<List<PresenceParticipant>?, String>((
      Ref ref,
      String seanceId,
    ) {
      // D12 (24/10/2026) : une salle ouverte sans billet (page rechargee sur
      // le web, `extra` perdu) demandait la presence avec un identifiant vide
      // toutes les 20 s (`session_id=eq.`, 400 22P02). Sans seance, aucun
      // appel et aucune minuterie : la presence est inconnue, sans plus.
      // R9 (30/10/2026) : liee a la personne connectee. A la deconnexion la
      // presence est refaite, la minuterie de l'ancienne est annulee, et sans
      // personne aucune lecture ne part (`presence_seance_v` en 401, 0,8 s
      // apres la sortie de l'enseignant pendant l'essai K4).
      final String? personne = surveillerPersonneConnectee(ref);
      if (seanceId.trim().isEmpty || personne == null) {
        return Stream<List<PresenceParticipant>?>.value(null);
      }
      final ServicePresence service = ref.watch(servicePresenceProvider);
      final StreamController<List<PresenceParticipant>?> sortie =
          StreamController<List<PresenceParticipant>?>();

      Future<void> lire() async {
        final List<PresenceParticipant>? lignes = await service.presence(
          seanceId,
        );
        // La lecture peut revenir apres la fermeture : une requete en vol
        // n'apprend pas toute seule que la salle s'est fermee.
        if (!sortie.isClosed) {
          sortie.add(lignes);
        }
      }

      final Timer minuterie = Timer.periodic(
        cadencePresence,
        (Timer _) => unawaited(lire()),
      );
      ref.onDispose(() {
        minuterie.cancel();
        unawaited(sortie.close());
      });

      // La premiere lecture est immediate : attendre vingt secondes avant de
      // dire quoi que ce soit laisserait l'ecran sur « inconnu » alors que la
      // reponse est a une requete de distance.
      unawaited(lire());
      return sortie.stream;
    });
