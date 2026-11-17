// Le choix des conversations d'essai de Praxis (PX-4, directeur : « le directeur
// ne tape jamais une reference »). La liste est celle que la messagerie montre a
// la direction (`PortMessagesMetier.fils`, lecture existante), chaque
// conversation posee par `LigneFil`, la meme ligne que dans les Messages : meme
// titre, meme pastille. On coche une ou plusieurs conversations (dix au plus).
// Aucune ligne n'est recomposee ici.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/case_a_cocher.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../com_messages/entete_fil_contexte.dart' show titreFil;
import '../com_messages/ligne_fil.dart';
import '../com_messages/port_messages_metier.dart';
import '../com_messages/recherche_fils.dart';

/// Les cles des widgets, pour les tests.
abstract final class ClesChoixEssai {
  /// La case d'une conversation.
  static ValueKey<String> case_(String filId) =>
      ValueKey<String>('praxis-essai-case-$filId');

  /// Le champ de recherche.
  static const Key recherche = ValueKey<String>('praxis-essai-recherche');
}

/// Le choix des conversations d'essai.
class ChoixConversationsEssai extends ConsumerStatefulWidget {
  /// Cree le choix.
  const ChoixConversationsEssai({
    required this.choisies,
    required this.onChange,
    super.key,
    this.maximum = 10,
  });

  /// Les conversations cochees.
  final Set<String> choisies;

  /// Recoit l'ensemble voulu.
  final ValueChanged<Set<String>> onChange;

  /// Le nombre de conversations d'essai au plus (la base le verifie aussi).
  final int maximum;

  @override
  ConsumerState<ChoixConversationsEssai> createState() =>
      _ChoixConversationsEssaiEtat();
}

class _ChoixConversationsEssaiEtat
    extends ConsumerState<ChoixConversationsEssai> {
  /// Combien de resultats au plus : la liste est bornee, la recherche affine.
  static const int _bornes = 20;

  final TextEditingController _texte = TextEditingController();
  List<ResumeFil>? _fils;
  bool _chargement = true;
  bool _erreur = false;
  bool _trop = false;

  @override
  void initState() {
    super.initState();
    _texte.addListener(() => setState(() {}));
    unawaited(_charger());
  }

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = false;
    });
    try {
      final List<ResumeFil> fils = await ref
          .read(portMessagesMetierProvider)
          .fils();
      if (!mounted) return;
      setState(() {
        _fils = fils;
        _chargement = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _erreur = true;
        _chargement = false;
      });
    }
  }

  void _basculer(String id, bool valeur) {
    final Set<String> suite = <String>{...widget.choisies};
    if (valeur) {
      if (suite.length >= widget.maximum) {
        setState(() => _trop = true);
        return;
      }
      suite.add(id);
    } else {
      suite.remove(id);
    }
    setState(() => _trop = false);
    widget.onChange(suite);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.praxis;
    if (_chargement) {
      return const Skeleton(hauteur: 96);
    }
    if (_erreur) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(r.essaiListeErreur, style: textes.bodyMedium),
          Ecart.vMd,
          LienFleche(
            libelle: t.commun.reessayer,
            fleche: false,
            onPress: () => unawaited(_charger()),
          ),
        ],
      );
    }
    final List<ResumeFil> tous = _fils ?? <ResumeFil>[];
    if (tous.isEmpty) {
      return Text(r.essaiAucune, style: textes.bodyMedium);
    }
    final List<ResumeFil> trouves = filtrerFils(tous, _texte.text.trim());
    final List<ResumeFil> vus = trouves.take(_bornes).toList(growable: false);
    final DateTime maintenant = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChampRecherche(
          key: ClesChoixEssai.recherche,
          controleur: _texte,
          libelle: t.com.messages.recherche.champ,
          aide: t.com.messages.recherche.aide,
        ),
        Ecart.vMd,
        Semantics(
          liveRegion: true,
          child: Text(
            _trop
                ? r.essaiTrop(nombre: widget.maximum)
                : r.essaiChoisies(nombre: widget.choisies.length),
            style: textes.bodySmall,
          ),
        ),
        Ecart.vSm,
        for (final ResumeFil f in vus)
          Row(
            key: ValueKey<String>('praxis-essai-ligne-${f.id}'),
            children: <Widget>[
              CaseACocher(
                key: ClesChoixEssai.case_(f.id),
                valeur: widget.choisies.contains(f.id),
                libelle: titreFil(f.interlocuteurs, f.objet.libelle),
                onChange: (bool v) => _basculer(f.id, v),
              ),
              Expanded(
                child: LigneFil(
                  fil: f,
                  maintenant: maintenant,
                  onPress: () =>
                      _basculer(f.id, !widget.choisies.contains(f.id)),
                ),
              ),
            ],
          ),
        if (trouves.length > vus.length) ...<Widget>[
          Ecart.vSm,
          Text(r.essaiAffinez(nombre: vus.length), style: textes.bodySmall),
        ],
      ],
    );
  }
}
