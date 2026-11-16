// Une conversation ouverte DANS une page, sans la quitter (directeur,
// 14/11/2026, plainte du dossier candidat : « Ecrire a <nom> » le faisait
// sortir du dossier vers les Messages, et il fallait une dizaine de gestes
// pour revenir).
//
// Il n'y a pas de second fil : c'est le meme `FilContextuel` que la page
// Messages (`EspaceMessagesMetier`), donc les memes bulles, le meme envoi
// honnete (« Envoye » sur accuse du serveur), les memes coches de lecture
// (MESSAGERIE-LU) et le meme brouillon. Le temps reel est celui de la veille
// (`etatVeilleMessagesProvider`, MESSAGERIE-TEMPS-REEL) : un signal du
// serveur relit le fil sans squelette, et un message arrive a l'ecran est
// marque lu. Le fil est declare « a l'ecran » (`filAfficheProvider`) tant
// qu'il est ouvert : l'avis « Nouveau message » n'est pas pose pour lui.
//
// Etats : chargement, erreur ou hors ligne (« Reessayer »), fil refuse ou
// absent (rien du fil n'est montre, R-COM-02), contenu, lecture seule (la
// phrase du fil).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/communications/capacites_communication.dart';
import '../../core/communications/veille_messages.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/widgets/vue_etat_communication.dart';
import '../com_vocal/envoi_vocal.dart';
import '../com_vocal/port_enregistreur_vocal.dart';
import 'barre_conversation.dart';
import 'fil_contextuel.dart';
import 'images_du_fil.dart';
import 'port_messages_metier.dart';

/// Le fil [filId], lu, ecrit et suivi en direct dans la page qui le pose.
///
/// Il demande une hauteur bornee (le fil defile seul, champ en bas) : un
/// volet de cote ou une surface plein ecran, jamais le corps d'une page qui
/// defile.
class FilEnPlace extends ConsumerStatefulWidget {
  /// Cree le fil en place.
  const FilEnPlace({
    required this.filId,
    required this.onReplier,
    super.key,
    this.onLu,
    this.onOuvrirMessages,
    this.volet = false,
  });

  /// Le fil a ouvrir.
  final String filId;

  /// CONVERSATIONS-PARTOUT : replie la conversation (le dossier reprend la
  /// place). C'est le retour de la barre compacte, la meme que celle de la
  /// page Messages : aucun titre, aucun lien d'en-tete de plus.
  final VoidCallback onReplier;

  /// Vrai : la conversation vit dans un VOLET de cote (ordinateur). Une croix
  /// « Fermer la conversation » au bord de fin de la barre, qui ne se replie
  /// jamais (MESSAGERIE-COULEURS, pilote, 16/11/2026 : regression de #540).
  /// Faux : une page, la fleche de retour du bord de debut.
  final bool volet;

  /// « Ouvrir dans Messages » (bouton d'icone de la barre), ou `null`.
  final VoidCallback? onOuvrirMessages;

  /// Le fil vient d'etre marque lu par le serveur : la page hote relit ses
  /// badges.
  final VoidCallback? onLu;

  /// La cle du fil rendu, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('fil-en-place');

  @override
  ConsumerState<FilEnPlace> createState() => _FilEnPlaceState();
}

class _FilEnPlaceState extends ConsumerState<FilEnPlace> {
  AsyncValue<FilMetier?> _fil = const AsyncValue<FilMetier?>.loading();

  PortMessagesMetier get _port => ref.read(portMessagesMetierProvider);

  /// Garde pour le fermer au demontage (le `ref` n'y est plus lisible).
  late final FilAfficheControleur _filAffiche;

  @override
  void initState() {
    super.initState();
    _filAffiche = ref.read(filAfficheProvider.notifier);
    unawaited(_charger());
  }

  @override
  void didUpdateWidget(FilEnPlace ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.filId != widget.filId) {
      final String avant = ancien.filId;
      Future<void>.microtask(() => _filAffiche.fermer(avant));
      unawaited(_charger());
    }
  }

  @override
  void dispose() {
    final String id = widget.filId;
    // Apres le rendu en cours : un fournisseur ne change pas pendant un
    // demontage.
    Future<void>.microtask(() => _filAffiche.fermer(id));
    super.dispose();
  }

  Future<void> _charger() async {
    final String id = widget.filId;
    setState(() => _fil = const AsyncValue<FilMetier?>.loading());
    final AsyncValue<FilMetier?> lu = await AsyncValue.guard<FilMetier?>(
      () async {
        final FilMetier? fil = await _port.fil(id);
        // Un fil rendu sous un autre identifiant n'est pas celui demande.
        return fil != null && fil.id == id ? fil : null;
      },
    );
    if (!mounted || widget.filId != id) return;
    setState(() => _fil = lu);
    if (lu.value != null) {
      _filAffiche.ouvrir(id);
      unawaited(_marquerLu(id));
    }
  }

  /// Un signal du serveur relit le fil sans squelette ; un echec garde ce
  /// qui est montre. Un message arrive a l'ecran est marque lu.
  Future<void> _relireEnDirect() async {
    final String id = widget.filId;
    final FilMetier? avant = _fil.value;
    if (avant == null || avant.id != id) return;
    final AsyncValue<FilMetier?> lu = await AsyncValue.guard<FilMetier?>(
      () => _port.fil(id),
    );
    if (!mounted || widget.filId != id) return;
    final FilMetier? fil = lu.value;
    if (fil == null || fil.id != id) return;
    final bool nouveau = fil.messages.length > avant.messages.length;
    setState(() => _fil = AsyncValue<FilMetier?>.data(fil));
    if (nouveau) unawaited(_marquerLu(id));
  }

  Future<void> _marquerLu(String id) async {
    try {
      await _port.marquerLu(id);
    } on Object {
      // Rien n'est affirme : le badge reste, la prochaine ouverture relance.
      return;
    }
    if (mounted) widget.onLu?.call();
  }

  Future<void> _envoyer(String filId, String texte, String cle) =>
      _port.envoyer(filId, texte, cle);

  Future<void> _envoyerVocal(
    String filId,
    EnregistrementVocal vocal,
    String cle,
  ) => ref
      .read(portEnvoiVocalProvider)
      .envoyer(
        destination: DestinationVocal.fil(filId),
        vocal: vocal,
        cleIdempotence: cle,
      );

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      etatVeilleMessagesProvider.select((EtatVeilleMessages e) => e.rang),
      (int? _, int _) => unawaited(_relireEnDirect()),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    // Chargement, erreur, fil refuse : la barre de retour seule, puis l'etat.
    // Jamais une surface sans sortie.
    Widget etat(Widget contenu) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BarreRetourConversation(
          onRetour: widget.volet ? null : widget.onReplier,
          onFermer: widget.volet ? widget.onReplier : null,
          libelle: t.com.messages.entree.replier,
        ),
        Expanded(child: SingleChildScrollView(child: contenu)),
      ],
    );
    if (_fil.isLoading) {
      return etat(
        const VueEtatCommunication(etat: EtatCommunication.chargement),
      );
    }
    if (_fil.hasError) {
      return etat(
        VueEtatCommunication.depuisErreur(
          _fil.error!,
          horsLigne: horsLigne,
          onReessayer: _charger,
        ),
      );
    }
    final FilMetier? fil = _fil.value;
    if (fil == null) {
      return etat(
        const VueEtatCommunication(
          etat: EtatCommunication.permissionRefusee,
          dependance: 'COM-BR-01',
        ),
      );
    }
    return KeyedSubtree(
      key: FilEnPlace.cle,
      child: FilContextuel(
        key: ValueKey<String>('fil-en-place-${fil.id}'),
        fil: fil,
        // La mise en page de la messagerie refaite : une barre compacte
        // (avatar a cote du nom), le fil pleine page, ses marges.
        pleinEcran: true,
        // Un volet : une croix au bord de fin, une barre qui ne se replie
        // jamais. Une page : la fleche de retour du bord de debut.
        onRetour: widget.volet ? null : widget.onReplier,
        onFermer: widget.volet ? widget.onReplier : null,
        barreFixe: widget.volet,
        libelleRetour: t.com.messages.entree.replier,
        onOuvrirMessages: widget.onOuvrirMessages,
        // COM-BR-16 : tant que la capacite n'est pas lue, l'ecriture reste
        // fermee.
        ecritureOuverte:
            ref
                .watch(capacitesCommunicationProvider)
                .value
                ?.peut(CapaciteCommunication.ecrireDansFil) ??
            false,
        onEnvoyer: (String texte, String cle) => _envoyer(fil.id, texte, cle),
        images: imagesDuFil(ref, fil.id).source,
        onAimer: imagesDuFil(ref, fil.id).aimer,
        onEnvoyerImage: imagesDuFil(ref, fil.id).envoyer,
        onAnnulerImage: imagesDuFil(ref, fil.id).annuler,
        onEnvoyerVocal: vocalOuvert(ref)
            ? (EnregistrementVocal v, String cle) =>
                  _envoyerVocal(fil.id, v, cle)
            : null,
      ),
    );
  }
}
