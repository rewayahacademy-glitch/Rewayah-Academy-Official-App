import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dossier/whatsapp_famille.dart';
import '../../core/i18n/pays_du_fuseau.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/lien_fleche.dart';
import '../inscription/etapes/champ_whatsapp.dart';

/// WHATSAPP-FAMILLE (directeur, 23/11/2026) : sur l'accueil de la famille, une
/// ligne discrete « Ajoutez votre numero WhatsApp » quand le compte n'en a pas
/// (les comptes inscrits avant la demande). Rien n'est affiche quand le numero
/// existe, quand le compte n'a pas de demande, ou quand la lecture echoue.
/// Toucher la ligne ouvre une feuille : le meme champ que l'inscription.
class LigneWhatsappFamille extends ConsumerWidget {
  /// Cree la ligne.
  const LigneWhatsappFamille({super.key});

  /// La cle de la ligne (tests).
  static const Key cleLigne = ValueKey<String>('accueil-whatsapp');

  /// La cle du bouton d'enregistrement de la feuille (tests).
  static const Key cleEnregistrer = ValueKey<String>(
    'accueil-whatsapp-enregistrer',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EtatWhatsapp? etat = ref.watch(monWhatsappProvider).value;
    if (etat == null || !etat.possible || etat.numero != null) {
      return const SizedBox.shrink();
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Padding(
      key: cleLigne,
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LienFleche(
            libelle: t.whatsapp.accueilLigne,
            onPress: () => AppBottomSheet.ouvrir<void>(
              context,
              titre: t.whatsapp.titreFeuille,
              constructeur: (BuildContext _) => const _FeuilleWhatsapp(),
            ),
          ),
          Text(
            t.whatsapp.accueilPourquoi,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeuilleWhatsapp extends ConsumerStatefulWidget {
  const _FeuilleWhatsapp();

  @override
  ConsumerState<_FeuilleWhatsapp> createState() => _FeuilleWhatsappEtat();
}

class _FeuilleWhatsappEtat extends ConsumerState<_FeuilleWhatsapp> {
  String? _numero;
  bool _tente = false;
  bool _envoi = false;
  bool _echec = false;

  Future<void> _enregistrer() async {
    final String? numero = _numero;
    if (_envoi) {
      return;
    }
    if (numero == null) {
      setState(() => _tente = true);
      return;
    }
    final PortWhatsappFamille? port = ref.read(portWhatsappFamilleProvider);
    setState(() {
      _envoi = true;
      _echec = false;
    });
    try {
      if (port == null) {
        throw StateError('whatsapp : aucune source');
      }
      await port.definir(numero);
      ref.invalidate(monWhatsappProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object {
      if (mounted) {
        setState(() {
          _envoi = false;
          _echec = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ChampWhatsapp(
          paysInitial: paysPourIndicatif(),
          tente: _tente,
          onChanged: (String? numero) => setState(() => _numero = numero),
          onValider: _enregistrer,
        ),
        if (_echec) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              t.whatsapp.echec,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          key: LigneWhatsappFamille.cleEnregistrer,
          libelle: t.whatsapp.enregistrer,
          onPress: _envoi ? null : _enregistrer,
          enCours: _envoi,
        ),
      ],
    );
  }
}
