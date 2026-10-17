import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../theme/app_delais.dart';
import '../theme/app_spacing.dart';
import 'bloc_asynchrone.dart';
import 'etat_systeme.dart';

/// Le squelette d'un chargement que la page conduit elle-meme (DESIGN-GOV
/// 4 bis.6, regle 4).
///
/// [BlocAsynchrone] couvre les pages qui lisent un `AsyncValue`. Celles qui
/// pilotent leur lecture a la main (un indicateur `_chargement`, un `await`
/// dans `initState`) montrent ce composant a la place de leur squelette :
/// il arme les deux seuils de [AppDelais] a son montage et les desarme a son
/// demontage. La page n'a ni minuteur ni etat a ajouter.
///
/// - tout de suite : [squelette] ;
/// - passe [AppDelais.chargementProlonge] : le squelette reste, une phrase dit
///   que c'est long (`NatureEtat.chargementProlonge`), sans rouge ;
/// - passe [AppDelais.requeteMax] : la lecture est tenue pour perdue,
///   `NatureEtat.echecServeur` avec « Reessayer » (borne a
///   [BlocAsynchrone.reessaisMax] pressions, puis la phrase
///   `reessaisEpuises`).
///
/// Une reponse qui arrive apres la perte rend la main a la page : elle
/// remplace ce composant par son contenu.
class ChargementAvecDelais extends StatefulWidget {
  /// Cree le chargement.
  const ChargementAvecDelais({
    required this.squelette,
    required this.onReessayer,
    super.key,
    this.titreEchec,
  });

  /// La forme du contenu pendant le chargement.
  final Widget squelette;

  /// Relance la lecture de la page.
  final VoidCallback onReessayer;

  /// Le titre de l'echec propre a l'ecran. Nul : celui de la nature.
  final String? titreEchec;

  @override
  State<ChargementAvecDelais> createState() => _ChargementAvecDelaisEtat();
}

/// Ou en est l'attente.
enum _Attente { normale, prolongee, perdue }

class _ChargementAvecDelaisEtat extends State<ChargementAvecDelais> {
  Timer? _prolongement;
  Timer? _perte;
  _Attente _attente = _Attente.normale;
  int _reessais = 0;

  @override
  void initState() {
    super.initState();
    _armer();
  }

  @override
  void dispose() {
    _prolongement?.cancel();
    _perte?.cancel();
    super.dispose();
  }

  void _armer() {
    _prolongement?.cancel();
    _perte?.cancel();
    _attente = _Attente.normale;
    _prolongement = Timer(AppDelais.chargementProlonge, () {
      if (mounted && _attente == _Attente.normale) {
        setState(() => _attente = _Attente.prolongee);
      }
    });
    _perte = Timer(AppDelais.requeteMax, () {
      if (mounted) {
        setState(() => _attente = _Attente.perdue);
      }
    });
  }

  bool get _peutReessayer => _reessais < BlocAsynchrone.reessaisMax;

  void _reessayer() {
    if (!_peutReessayer) {
      return;
    }
    setState(() {
      _reessais++;
      _armer();
    });
    widget.onReessayer();
  }

  @override
  Widget build(BuildContext context) {
    switch (_attente) {
      case _Attente.normale:
        return SqueletteDansZone(child: widget.squelette);
      case _Attente.prolongee:
        return SqueletteDansZone(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              widget.squelette,
              Ecart.vMd,
              const EtatSysteme(nature: NatureEtat.chargementProlonge),
            ],
          ),
        );
      case _Attente.perdue:
        final String? titre = widget.titreEchec;
        return EtatSysteme(
          nature: NatureEtat.echecServeur,
          titre: titre,
          phrase: !_peutReessayer
              ? t.commun.etats.reessaisEpuises
              : (titre != null ? '' : null),
          onAction: _peutReessayer ? _reessayer : null,
        );
    }
  }
}

/// Pose [child] dans une zone a hauteur bornee sans jamais deborder : borne
/// (une page de bureau dont la liste occupe le reste de la colonne), le
/// contenu defile ; non borne (la page defile), il se pose tel quel.
///
/// Sert aux squelettes et a leur phrase, qui ne doivent pas faire deborder la
/// zone etiree d'un tableau, surtout a grande echelle de texte.
class SqueletteDansZone extends StatelessWidget {
  /// Cree la zone.
  const SqueletteDansZone({required this.child, super.key});

  /// Le squelette, avec ou sans sa phrase.
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints contraintes) =>
        contraintes.hasBoundedHeight
        ? SingleChildScrollView(child: child)
        : child,
  );
}

/// Redonne a [child] toute la hauteur de la zone etiree qui le contient.
///
/// `BlocAsynchrone` pose son contenu dans une pile qui relache les
/// contraintes : une collection qui occupait « tout le reste » de la colonne
/// ne la remplirait plus. Hauteur bornee : [child] prend toute la hauteur ;
/// non bornee (la page defile) : il se pose tel quel.
class ZoneEtiree extends StatelessWidget {
  /// Cree la zone.
  const ZoneEtiree({required this.child, super.key});

  /// Le contenu qui remplit la zone.
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints contraintes) =>
        contraintes.hasBoundedHeight
        ? SizedBox(height: contraintes.maxHeight, child: child)
        : child,
  );
}
