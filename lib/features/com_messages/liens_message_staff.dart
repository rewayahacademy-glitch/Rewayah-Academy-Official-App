// Les liens d'un message de #Ra_staff (directeur, 14/11/2026) : dans les
// Messages, seule l'equipe peut donner un lien a ouvrir. Sous son message,
// chaque adresse https devient une ligne « LienFleche » qui l'ouvre dans un
// nouvel onglet, sans lien avec la page (`ouvreurOngletProvider`, noopener).
// Aucun autre schema (http, javascript:, data:, mailto:...) ; le texte du
// message, lui, reste du texte. Le message d'une autre personne n'ouvre rien.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_bibliotheque/ouvreur_onglet.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';

/// Au plus tant de liens sous un message.
const int maxLiensParMessage = 3;

final RegExp _candidat = RegExp(r'https://[^\s<>"]+', caseSensitive: false);

/// Les adresses https de [texte], dans l'ordre, sans doublon, au plus
/// [maxLiensParMessage]. La ponctuation qui suit l'adresse dans la phrase
/// (point, virgule, parenthese fermante...) n'en fait pas partie. Pure.
List<Uri> liensHttps(String texte) {
  final List<Uri> liens = <Uri>[];
  for (final RegExpMatch m in _candidat.allMatches(texte)) {
    String brut = m.group(0)!;
    while (brut.isNotEmpty && '.,;:!?)]}»\'’'.contains(brut[brut.length - 1])) {
      brut = brut.substring(0, brut.length - 1);
    }
    final Uri? u = Uri.tryParse(brut);
    if (u == null ||
        u.scheme.toLowerCase() != 'https' ||
        u.host.isEmpty ||
        u.userInfo.isNotEmpty) {
      continue;
    }
    if (!liens.contains(u)) liens.add(u);
    if (liens.length == maxLiensParMessage) break;
  }
  return liens;
}

/// Les liens a ouvrir sous un message de l'equipe, ou rien.
class LiensMessageStaff extends ConsumerWidget {
  /// Cree la liste des liens de [texte].
  const LiensMessageStaff({required this.texte, super.key});

  /// Le texte du message.
  final String texte;

  /// La cle d'une ligne, pour les tests.
  static Key cle(int i) => ValueKey<String>('lien-staff-$i');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OuvreurOnglet? ouvrir = ref.watch(ouvreurOngletProvider);
    final List<Uri> liens = liensHttps(texte);
    // Hors navigateur, ou sans lien : rien n'est rendu, le texte suffit.
    if (ouvrir == null || liens.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: <Widget>[
        for (int i = 0; i < liens.length; i++)
          LienFleche(
            key: cle(i),
            libelle: t.com.messages.liens.ouvrir(site: liens[i].host),
            libelleSemantique: t.com.messages.liens.ouvrirLu(
              site: liens[i].host,
            ),
            alignerEnDebut: true,
            onPress: () => ouvrir(liens[i]),
          ),
      ],
    );
  }
}

/// Le complement d'un message : ses pieces, puis, pour un message de
/// l'equipe, ses liens. `null` quand il n'y a rien.
Widget? complementAvecLiens({
  required Widget? pieces,
  required bool equipe,
  required String texte,
}) {
  if (!equipe || liensHttps(texte).isEmpty) return pieces;
  final Widget liens = LiensMessageStaff(texte: texte);
  if (pieces == null) return liens;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.lg,
    children: <Widget>[pieces, liens],
  );
}
