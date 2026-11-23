import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/whatsapp_direction.dart';
import '../../core/fichiers/ouvrir_onglet.dart';
import '../../core/i18n/isolat_bidi.dart' show isolerSens;
import '../../core/i18n/strings.g.dart';
import '../../core/recrutement/ouvreur_lien.dart' show copierLien;
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';

/// WHATSAPP-FAMILLE (directeur, 23/11/2026) : le numero WhatsApp d'une famille,
/// lu par la direction (feuille d'une demande d'admission, fiche d'un eleve),
/// avec « Ouvrir WhatsApp » (`https://wa.me/<numero sans +>`). Le serveur ne le
/// rend qu'a la direction active, et pas sous masquage d'identite. Les etats :
/// lecture en cours, numero, aucun numero donne, lecture impossible.
class LigneWhatsappDirection extends ConsumerWidget {
  /// Cree la ligne pour [cible].
  const LigneWhatsappDirection({required this.cible, super.key});

  /// La demande ou le profil dont on lit le numero.
  final CibleWhatsapp cible;

  /// La cle de la ligne (tests).
  static const Key cleLigne = ValueKey<String>('whatsapp-direction');

  /// La cle du lien « Ouvrir WhatsApp » (tests).
  static const Key cleOuvrir = ValueKey<String>('whatsapp-direction-ouvrir');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.whatsapp;
    final AsyncValue<String?> lecture = ref.watch(
      whatsappDirectionProvider(cible),
    );
    final String? numero = lecture.value;
    final String valeur = numero != null
        ? isolerSens(numero)
        : lecture.hasError
        ? r.illisible
        : lecture.isLoading
        ? t.commun.chargement
        : r.absent;
    return Padding(
      key: cleLigne,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LigneCleValeur(cle: r.direction, valeur: valeur, chiffres: true),
          if (numero != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                key: cleOuvrir,
                libelle: r.ouvrir,
                onPress: () async {
                  final Uri lien = lienWhatsapp(numero);
                  if (!await ref.read(ouvreurOngletProvider)(lien)) {
                    await copierLien(lien);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
