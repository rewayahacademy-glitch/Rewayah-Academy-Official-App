// Les Messages metier (COM-M01, COM-W01 ; spec section 3, section 16,
// section 17, section 23, section 25).
//
// Une seule page pour le tuteur (`/tuteur/messages`), l'enseignant
// (`/enseignant/messages`) et, par la voie tuteur, l'eleve adulte : le
// routeur donne le retour du role, la page ne lit aucun role. Elle se pose
// dans la coquille du role (aucune destination ajoutee) et dispose ses
// panneaux sur l'espace de travail adaptatif du socle :
//
// - ordinateur : Navigation (la coquille) | Conversations | Fil | Contexte ;
// - tablette : Conversations | Fil, le contexte en feuille ;
// - telephone : une surface a la fois, la liste (`/messages`) OU le fil
//   (`/messages/:filId`), le retour de la page ramene a la liste ; le champ
//   reste au-dessus du clavier logiciel.
//
// Aucune colonne vide : sans fil ouvert, la colonne du fil dit quoi faire ;
// sans liste a montrer (chargement, vide, erreur, indisponible), l'etat
// prend la place de la liste et aucune colonne n'est reservee.
//
// Etats (spec section 25) : chargement (squelette), contenu, vide (« Aucune
// conversation pour le moment. »), erreur (« Reessayer »), hors ligne
// (bandeau des communications, contenu deja lu garde ; sans contenu, l'etat
// hors ligne et « Reessayer »), capacite indisponible (port neutre, sans
// « Reessayer »), fil inaccessible (permission refusee, rien du fil n'est
// rendu : R-COM-02), envoi en cours, envoi non confirme (R-COM-13), non lu
// et action requise (badge).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/communications/espace_travail_adaptatif.dart';
import '../../core/widgets/communications/etats_communication.dart';
import '../../core/widgets/page_shell.dart';
import 'fil_contextuel.dart';
import 'liste_fils.dart';
import 'panneau_contexte_fil.dart';
import 'port_messages_metier.dart';

/// Le chemin de la liste des Messages, depuis l'adresse courante : l'adresse
/// elle-meme pour la liste, sans son dernier segment pour un fil.
String cheminListeMessages(Uri adresse, {required bool filOuvert}) {
  if (!filOuvert) return adresse.path;
  final List<String> segments = adresse.pathSegments;
  return '/${segments.take(segments.length - 1).join('/')}';
}

/// Les Messages metier, page routee du tuteur et de l'enseignant.
class MessagesPage extends StatelessWidget {
  /// Cree la page.
  const MessagesPage({super.key, this.filId, this.cheminRetour});

  /// Le fil demande par l'adresse (`/messages/:filId`), s'il y en a un.
  /// Jamais une autorisation : le port decide (COM-BR-01).
  final String? filId;

  /// Ou mene le retour : la page du role d'ou l'on vient, donnee par le
  /// routeur (jamais lue d'un role). Nul : aucun disque retour.
  final String? cheminRetour;

  void _ouvrirFil(BuildContext context, String id) {
    final String liste = cheminListeMessages(
      GoRouterState.of(context).uri,
      filOuvert: filId != null,
    );
    GoRouter.of(context).go('$liste/${Uri.encodeComponent(id)}');
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.com.messages.titre,
      onRetour: switch (cheminRetour) {
        final String chemin => () => GoRouter.of(context).go(chemin),
        null => null,
      },
      defilante: false,
      child: EspaceMessagesMetier(
        filId: filId,
        onOuvrirFil: (String id) => _ouvrirFil(context, id),
      ),
    );
  }
}

/// L'espace des Messages metier : liste, fil, contexte, et leurs etats.
///
/// Sans route : la page routee et la demonstration le posent, chacune avec
/// sa facon d'ouvrir un fil ([onOuvrirFil]).
class EspaceMessagesMetier extends ConsumerStatefulWidget {
  /// Cree l'espace.
  const EspaceMessagesMetier({
    required this.onOuvrirFil,
    super.key,
    this.filId,
    this.onOuvrirObjet,
    this.horloge = DateTime.now,
  });

  /// Le fil ouvert, ou `null` pour la liste seule.
  final String? filId;

  /// Ouvre un fil (par l'adresse, ou par l'etat de la demonstration).
  final ValueChanged<String> onOuvrirFil;

  /// Ouvre un objet lie du panneau ; par defaut, le routeur.
  final ValueChanged<String>? onOuvrirObjet;

  /// L'heure courante, pour la liste.
  final DateTime Function() horloge;

  /// La cle de la phrase « Choisissez une conversation », pour les tests.
  static const ValueKey<String> cleChoisir = ValueKey<String>(
    'messages-choisir',
  );

  @override
  ConsumerState<EspaceMessagesMetier> createState() =>
      _EspaceMessagesMetierState();
}

class _EspaceMessagesMetierState extends ConsumerState<EspaceMessagesMetier> {
  AsyncValue<List<ResumeFil>> _liste =
      const AsyncValue<List<ResumeFil>>.loading();
  AsyncValue<FilMetier?> _fil = const AsyncValue<FilMetier?>.loading();

  PortMessagesMetier get _port => ref.read(portMessagesMetierProvider);

  @override
  void initState() {
    super.initState();
    _chargerListe();
    final String? id = widget.filId;
    if (id != null) _chargerFil(id);
  }

  @override
  void didUpdateWidget(EspaceMessagesMetier ancien) {
    super.didUpdateWidget(ancien);
    final String? id = widget.filId;
    if (id != ancien.filId && id != null) _chargerFil(id);
  }

  /// Lit la liste. [silencieux] : relecture apres une action (lu, envoi),
  /// la liste deja montree reste en place, et un echec ne l'efface pas.
  Future<void> _chargerListe({bool silencieux = false}) async {
    if (!silencieux) {
      setState(() => _liste = const AsyncValue<List<ResumeFil>>.loading());
    }
    final AsyncValue<List<ResumeFil>> lue =
        await AsyncValue.guard<List<ResumeFil>>(() async {
          final List<ResumeFil> fils = await _port.fils();
          // Defense de surface : une annonce, une publication ou un canal
          // n'ont pas leur place dans les Messages metier.
          return <ResumeFil>[
            for (final ResumeFil f in fils)
              if (estFilMetier(f)) f,
          ];
        });
    if (!mounted) return;
    if (silencieux && lue.hasError) return;
    setState(() => _liste = lue);
  }

  Future<void> _chargerFil(String id) async {
    setState(() => _fil = const AsyncValue<FilMetier?>.loading());
    final AsyncValue<FilMetier?> lu = await AsyncValue.guard<FilMetier?>(
      () async {
        final FilMetier? fil = await _port.fil(id);
        // Un fil rendu sous un autre identifiant n'est pas celui demande :
        // il est traite comme absent, jamais montre a sa place.
        return fil != null && fil.id == id ? fil : null;
      },
    );
    if (!mounted || widget.filId != id) return;
    setState(() => _fil = lu);
    if (lu.value != null) unawaited(_marquerLu(id));
  }

  Future<void> _marquerLu(String id) async {
    try {
      await _port.marquerLu(id);
    } on Object {
      // Le badge reste tel quel : rien n'est affirme.
      return;
    }
    await _chargerListe(silencieux: true);
  }

  Future<void> _envoyer(String filId, String texte, String cle) async {
    await _port.envoyer(filId, texte, cle);
    // L'apercu et l'ordre de la liste suivent le message confirme.
    unawaited(_chargerListe(silencieux: true));
  }

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (horsLigne) ...<Widget>[
          const BandeauHorsLigneCommunication(encadre: true),
          Ecart.vLg,
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints contraintes) =>
                _espace(colonnesPour(contraintes.maxWidth), horsLigne),
          ),
        ),
      ],
    );
  }

  Widget _espace(int colonnes, bool horsLigne) {
    final String? filId = widget.filId;
    final List<ResumeFil>? fils = _liste.hasValue && !_liste.isLoading
        ? _liste.value
        : null;
    final bool contenu = fils != null && fils.isNotEmpty;
    final Widget? listeFils = contenu
        ? ListeFils(
            fils: fils,
            onOuvrir: widget.onOuvrirFil,
            filSelectionne: colonnes > 1 ? filId : null,
            rechercheEnSurface: colonnes == 1,
            horloge: widget.horloge,
          )
        : null;
    final Widget etatListe = _etatListe(horsLigne);

    if (filId == null) {
      return EspaceTravailAdaptatif(
        liste: colonnes == 1 ? (listeFils ?? etatListe) : listeFils,
        surfaceMobile: SurfaceMobile.liste,
        principal: contenu ? _choisir() : etatListe,
      );
    }
    final FilMetier? fil = _fil.hasValue && !_fil.isLoading ? _fil.value : null;
    return EspaceTravailAdaptatif(
      liste: listeFils ?? etatListe,
      principal: _vueFil(filId, horsLigne),
      contexte: fil == null
          ? null
          : PanneauContexteFil(
              key: ValueKey<String>('panneau-${fil.id}'),
              fil: fil,
              onOuvrirObjet: widget.onOuvrirObjet,
            ),
    );
  }

  /// La colonne du fil quand aucun fil n'est ouvert : dire quoi faire,
  /// jamais une colonne vide.
  Widget _choisir() {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final m = t.com.messages;
    return Center(
      key: EspaceMessagesMetier.cleChoisir,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                m.choisirTitre,
                textAlign: TextAlign.center,
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vSm,
            Text(
              m.choisir,
              textAlign: TextAlign.center,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// L'etat de la liste quand elle n'a pas de contenu a montrer.
  Widget _etatListe(bool horsLigne) {
    final m = t.com.messages;
    if (_liste.isLoading) {
      return const SingleChildScrollView(
        child: VueEtatCommunication(etat: EtatCommunication.chargement),
      );
    }
    if (_liste.hasError) {
      return SingleChildScrollView(
        child: _vueErreur(_liste.error!, horsLigne, _chargerListe),
      );
    }
    return SingleChildScrollView(
      child: VueEtatCommunication(
        etat: EtatCommunication.vide,
        titreVide: m.vide,
        phraseVide: m.videDetail,
      ),
    );
  }

  /// La colonne du fil demande : chargement, erreur, inaccessible ou fil.
  Widget _vueFil(String filId, bool horsLigne) {
    if (_fil.isLoading) {
      return const SingleChildScrollView(
        child: VueEtatCommunication(etat: EtatCommunication.chargement),
      );
    }
    if (_fil.hasError) {
      return SingleChildScrollView(
        child: _vueErreur(_fil.error!, horsLigne, () => _chargerFil(filId)),
      );
    }
    final FilMetier? fil = _fil.value;
    if (fil == null) {
      // Absent ou refuse (paire non autorisee, autre foyer) : rien du fil
      // n'est rendu, ni nom, ni objet, ni message (R-COM-02).
      return const SingleChildScrollView(
        child: VueEtatCommunication(
          etat: EtatCommunication.permissionRefusee,
          dependance: 'COM-BR-01',
        ),
      );
    }
    return FilContextuel(
      key: ValueKey<String>('fil-contextuel-${fil.id}'),
      fil: fil,
      onEnvoyer: (String texte, String cle) => _envoyer(fil.id, texte, cle),
    );
  }

  /// Une lecture en echec : capacite absente (sans « Reessayer »), hors
  /// ligne ou echec (avec « Reessayer »).
  Widget _vueErreur(Object erreur, bool horsLigne, VoidCallback reessayer) {
    if (erreur is CapaciteIndisponible) {
      return VueEtatCommunication(
        etat: EtatCommunication.indisponible,
        dependance: erreur.dependance,
      );
    }
    return VueEtatCommunication(
      etat: horsLigne ? EtatCommunication.horsLigne : EtatCommunication.erreur,
      onReessayer: reessayer,
    );
  }
}
