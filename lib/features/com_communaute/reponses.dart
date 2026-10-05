// Les reponses d'une publication (`ReplyThread`, spec section 19) et leur
// composer.
//
// Des reponses structurees, pas une conversation : une seule carte a lignes
// fines (K-55, contenus lies), une ligne par reponse, sans bulle ni coeur
// (UX_REVIEW L0 : ne pas forcer `FilDiscussion`, refuser les compteurs
// « J'aime »). Une reponse ecrite ici reste « Envoi en cours » jusqu'a
// l'accuse du serveur, puis rejoint la liste lue ; un echec dit « pas encore
// confirmee » et propose de la renvoyer avec la meme cle (COM-BR-02).
//
// Le texte en cours est un brouillon de session (`PortBrouillons`, spec
// section 8.2), range sous l'identifiant de la publication : changer de
// publication ne melange jamais deux reponses.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/communications/modeles_communication.dart';
import '../../core/communications/port_brouillons.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/menu_actions.dart';
import 'flux_publications.dart';
import 'port_communaute.dart';

/// Une reponse ecrite ici, en attente de l'accuse du serveur.
@immutable
class ReponseEnAttente {
  /// Cree la reponse en attente.
  const ReponseEnAttente({
    required this.cle,
    required this.texte,
    this.echec = false,
  });

  /// La cle d'idempotence, rejouee telle quelle a chaque renvoi.
  final String cle;

  /// Le texte.
  final String texte;

  /// Vrai si l'envoi n'a pas ete confirme.
  final bool echec;

  /// La meme reponse, dans un autre etat.
  ReponseEnAttente avecEchec(bool valeur) =>
      ReponseEnAttente(cle: cle, texte: texte, echec: valeur);
}

/// Les reponses d'une publication (`ReplyThread`).
class FilReponses extends StatelessWidget {
  /// Cree le fil.
  const FilReponses({
    required this.reponses,
    required this.maintenant,
    super.key,
    this.enAttente = const <ReponseEnAttente>[],
    this.peutSignaler = false,
    this.signalees = const <ObjetLie>{},
    this.onSignaler,
    this.onRenvoyer,
  });

  /// Les reponses confirmees, la plus ancienne d'abord.
  final List<ReponseCommunaute> reponses;

  /// Les reponses ecrites ici, pas encore confirmees.
  final List<ReponseEnAttente> enAttente;

  /// L'instant de reference du « Il y a ».
  final DateTime maintenant;

  /// Vrai si la personne peut signaler (capacite du serveur).
  final bool peutSignaler;

  /// Les reponses deja signalees par la personne.
  final Set<ObjetLie> signalees;

  /// Signale une reponse.
  final ValueChanged<ReponseCommunaute>? onSignaler;

  /// Renvoie une reponse non confirmee.
  final ValueChanged<ReponseEnAttente>? onRenvoyer;

  /// La cle de la ligne d'une reponse, pour les tests.
  static ValueKey<String> cleReponse(String id) =>
      ValueKey<String>('communaute-reponse-$id');

  /// La cle de la ligne d'une reponse en attente, pour les tests.
  static ValueKey<String> cleEnAttente(String cle) =>
      ValueKey<String>('communaute-reponse-attente-$cle');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    if (reponses.isEmpty && enAttente.isEmpty) {
      return Text(
        t.com.communaute.reponses.vide,
        style: palette.inkMuted.applyTo(textes.bodyMedium ?? const TextStyle()),
      );
    }
    return CarteGroupee(
      sections: <Widget>[
        for (final ReponseCommunaute r in reponses)
          _LigneReponse(
            key: cleReponse(r.id),
            reponse: r,
            maintenant: maintenant,
            signalee: signalees.contains(r.objet),
            onSignaler: peutSignaler && onSignaler != null
                ? () => onSignaler!(r)
                : null,
          ),
        for (final ReponseEnAttente r in enAttente)
          _LigneEnAttente(
            key: cleEnAttente(r.cle),
            reponse: r,
            onRenvoyer: onRenvoyer == null ? null : () => onRenvoyer!(r),
          ),
      ],
    );
  }
}

class _LigneReponse extends StatelessWidget {
  const _LigneReponse({
    required this.reponse,
    required this.maintenant,
    required this.signalee,
    required this.onSignaler,
    super.key,
  });

  final ReponseCommunaute reponse;
  final DateTime maintenant;
  final bool signalee;
  final VoidCallback? onSignaler;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.com.communaute.reponses;
    final VoidCallback? signaler = signalee ? null : onSignaler;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AvatarNom.enLigne(
          prenom: reponse.auteur.nomAffiche,
          role: ligneAuteurCommunaute(
            reponse.auteur.fonction,
            momentCommunaute(reponse.publieeLe, maintenant),
          ),
          diametre: AppAvatar.petit,
          fin: signaler == null
              ? null
              : MenuActions(
                  points: true,
                  tooltip: r.menu(nom: reponse.auteur.nomAffiche),
                  actions: <EntreeAction>[
                    EntreeAction(libelle: r.signaler, onChoix: signaler),
                  ],
                ),
        ),
        Ecart.vSm,
        Text(
          reponse.texte,
          style: palette.inkStrong.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        if (signalee) ...<Widget>[
          Ecart.vSm,
          Text(
            r.signalee,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}

class _LigneEnAttente extends StatelessWidget {
  const _LigneEnAttente({
    required this.reponse,
    required this.onRenvoyer,
    super.key,
  });

  final ReponseEnAttente reponse;
  final VoidCallback? onRenvoyer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.com.communaute.reponses;
    final VoidCallback? renvoyer = onRenvoyer;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AvatarNom.enLigne(
            prenom: t.com.socle.composants.composer.auteurSoi,
            role: reponse.echec ? r.nonConfirmee : r.enCours,
            diametre: AppAvatar.petit,
          ),
          Ecart.vSm,
          Text(
            reponse.texte,
            style: palette.inkStrong.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          if (reponse.echec && renvoyer != null) ...<Widget>[
            Ecart.vSm,
            ActionPrincipale(
              libelle: r.reessayer,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              compacte: true,
              onPress: renvoyer,
            ),
          ],
        ],
      ),
    );
  }
}

/// Le composer d'une reponse : un champ et « Envoyer la reponse ».
///
/// Le bouton n'est jamais grise : un texte vide se dit sous le champ (K-56).
/// Le texte est garde en brouillon de session sous l'identifiant de la
/// publication, et efface seulement quand l'envoi a ete confirme.
class ComposerReponse extends ConsumerStatefulWidget {
  /// Cree le composer.
  const ComposerReponse({
    required this.publicationId,
    required this.onEnvoyer,
    super.key,
  });

  /// La publication a laquelle on repond.
  final String publicationId;

  /// Envoie le texte ; rend vrai si le serveur l'a confirme.
  final Future<bool> Function(String texte) onEnvoyer;

  /// La cle du champ, pour les tests.
  static const ValueKey<String> cleChamp = ValueKey<String>(
    'communaute-reponse-champ',
  );

  /// La cle de l'action « Envoyer la reponse », pour les tests.
  static const ValueKey<String> cleEnvoyer = ValueKey<String>(
    'communaute-reponse-envoyer',
  );

  @override
  ConsumerState<ComposerReponse> createState() => _ComposerReponseState();
}

class _ComposerReponseState extends ConsumerState<ComposerReponse> {
  final TextEditingController _texte = TextEditingController();
  bool _videSignale = false;
  late final PortBrouillons _brouillons = ref.read(portBrouillonsProvider);

  CleBrouillon get _cle => CleBrouillon(
    type: TypeObjetLie.publication,
    objetId: widget.publicationId,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_restaurer());
  }

  Future<void> _restaurer() async {
    final Brouillon? brouillon = await _brouillons.lire(_cle);
    if (!mounted || brouillon == null || _texte.text.isNotEmpty) return;
    _texte.text = brouillon.texte;
  }

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final String texte = _texte.text.trim();
    if (texte.isEmpty) {
      setState(() => _videSignale = true);
      return;
    }
    // Le champ se vide tout de suite : la reponse apparait dans le fil, en
    // attente de l'accuse. Le brouillon n'est efface qu'apres l'accuse.
    _texte.clear();
    setState(() => _videSignale = false);
    final bool confirme = await widget.onEnvoyer(texte);
    if (confirme) await _brouillons.effacer(_cle);
  }

  @override
  Widget build(BuildContext context) {
    final r = t.com.communaute.reponses;
    final Widget champ = TextField(
      key: ComposerReponse.cleChamp,
      controller: _texte,
      minLines: 1,
      maxLines: 5,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (String texte) {
        unawaited(_brouillons.enregistrer(_cle, texte));
        if (_videSignale && texte.trim().isNotEmpty) {
          setState(() => _videSignale = false);
        }
      },
      decoration: InputDecoration(
        labelText: r.champ,
        hintText: r.aide,
        helperText: _videSignale ? r.champVide : null,
        helperMaxLines: 3,
      ),
    );
    final Widget envoyer = ActionPrincipale(
      key: ComposerReponse.cleEnvoyer,
      libelle: r.envoyer,
      niveau: NiveauAction.secondaire,
      pleineLargeur: false,
      onPress: _envoyer,
    );
    // Etroit (telephone, colonne de bureau) : le bouton passe sous le champ,
    // au bord de fin, pour laisser au champ toute la largeur.
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) =>
          AppGabarit.classe(contraintes.maxWidth) == ClasseLargeur.compacte
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                champ,
                Ecart.vSm,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: envoyer,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(child: champ),
                Ecart.hSm,
                envoyer,
              ],
            ),
    );
  }
}
