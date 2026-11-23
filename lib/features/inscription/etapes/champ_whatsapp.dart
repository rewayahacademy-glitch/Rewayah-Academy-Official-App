import 'package:flutter/material.dart';

import '../../../core/i18n/indicatifs_telephoniques.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import 'telephone_etape.dart';

/// WHATSAPP-FAMILLE (directeur, 23/11/2026) : « Votre numero WhatsApp ».
///
/// Le meme champ que le telephone du candidat enseignant
/// ([ChampNumeroTelephone] : drapeau et indicatif a gauche, numero a droite,
/// liste des pays avec recherche) et les memes regles de lecture
/// ([telephoneInternational] : chiffres seulement, longueur, « 0 » national
/// retire). Une phrase dit pourquoi on le demande. Le pays est propose d'apres
/// l'appareil quand [paysInitial] est donne ; rien n'est devine sinon.
///
/// [onChanged] rend le numero international (`+33612345678`) ou `null` tant
/// qu'il ne se lit pas. Aucune erreur avant [tente].
class ChampWhatsapp extends StatefulWidget {
  /// Cree le champ.
  const ChampWhatsapp({
    required this.onChanged,
    this.paysInitial,
    this.tente = false,
    this.onValider,
    super.key,
  });

  /// La cle du champ du numero (tests).
  static const Key numeroKey = ValueKey<String>('whatsapp-numero');

  /// Le pays propose au depart (code ISO), ou `null`.
  final String? paysInitial;

  /// Vrai apres une premiere tentative d'envoi : les erreurs s'affichent.
  final bool tente;

  /// Le numero international, ou `null` quand il ne se lit pas.
  final ValueChanged<String?> onChanged;

  /// Appele quand la personne valide au clavier.
  final VoidCallback? onValider;

  @override
  State<ChampWhatsapp> createState() => _ChampWhatsappState();
}

class _ChampWhatsappState extends State<ChampWhatsapp> {
  final TextEditingController _numero = TextEditingController();
  final FocusNode _focus = FocusNode();
  String? _pays;

  @override
  void initState() {
    super.initState();
    _pays = widget.paysInitial;
  }

  @override
  void dispose() {
    _numero.dispose();
    _focus.dispose();
    super.dispose();
  }

  String? get _international {
    final String? code = indicatifDuPays(_pays);
    return code == null
        ? null
        : telephoneInternational(indicatif: code, saisie: _numero.text);
  }

  String? get _erreur {
    if (!widget.tente) {
      return null;
    }
    final r = t.inscription.telephone;
    if (_pays == null) {
      return r.indicatifManquant;
    }
    if (_numero.text.trim().isEmpty) {
      return r.numeroManquant;
    }
    return _international == null ? r.numeroInvalide : null;
  }

  void _signaler() {
    setState(() {});
    widget.onChanged(_international);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? erreur = _erreur;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.whatsapp.etiquette, style: textes.titleSmall),
        Ecart.vXs,
        Text(
          t.whatsapp.pourquoi,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        // Un numero s'ecrit de gauche a droite, meme en arabe.
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChampNumeroTelephone(
            cle: ChampWhatsapp.numeroKey,
            controleur: _numero,
            focus: _focus,
            pays: _pays,
            indicatif: indicatifDuPays(_pays),
            erreur: erreur,
            onChanged: _signaler,
            onValider: widget.onValider ?? () {},
            onChoisirPays: () async {
              final String? code = await choisirPays(context, _pays);
              if (code != null && mounted) {
                setState(() => _pays = code);
                widget.onChanged(_international);
                _focus.requestFocus();
              }
            },
          ),
        ),
        if (erreur != null) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              erreur,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
