// La feuille « Coordonnees a valider » (lot FINANCE-ENSEIGNANT, 06/11/2026 ;
// consigne du directeur du 06/11, 22:55 UTC, relayee par le garde-cap) :
// protection contre le detournement de la paie. Tout enregistrement de
// coordonnees (premier ou changement), et tout compte au nom d'un tiers,
// n'entre dans le fichier Wise qu'apres validation par la direction.
//
// La direction lit ce qu'il faut pour verifier, et rien de plus : le titulaire,
// le lien et la date de l'accord pour un compte d'un tiers, le pays, le numero
// masque sauf les 4 derniers caracteres. Elle valide la ligne qu'elle a lue :
// si l'enseignant a change entre-temps, le serveur refuse. Journalise,
// courriel a l'enseignant (serveur).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/port_coordonnees_versement.dart';
import '../../../core/i18n/pays_iso.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/carte_lignes.dart';
import '../../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import '../../../core/widgets/setting_row.dart';
import '../../../core/widgets/status_pill.dart' show TonEtat;

/// Le lien avec le titulaire, dit par la direction (« parent »).
String lienTitulaireDirection(LienTitulaire l) {
  final x = t.admin.finance.paieWise.lien;
  return switch (l) {
    LienTitulaire.parent => x.parent,
    LienTitulaire.conjoint => x.conjoint,
    LienTitulaire.frereSoeur => x.frereSoeur,
    LienTitulaire.autre => x.autre,
  };
}

/// Le contenu de la feuille : la liste, puis le detail de la ligne touchee.
class FeuilleValiderCoordonnees extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleValiderCoordonnees({super.key});

  /// La cle de la ligne d'un enseignant.
  static Key cleEnseignant(String id) =>
      ValueKey<String>('paie-wise-valider-$id');

  /// La cle du bouton plein.
  static const Key cleAction = ValueKey<String>('paie-wise-valider-action');

  /// La cle du message de reussite.
  static const Key cleFait = ValueKey<String>('paie-wise-valider-fait');

  @override
  ConsumerState<FeuilleValiderCoordonnees> createState() =>
      _FeuilleValiderCoordonneesEtat();
}

class _FeuilleValiderCoordonneesEtat
    extends ConsumerState<FeuilleValiderCoordonnees> {
  late Future<List<EnseignantVersement>> _liste = _lire();
  EnseignantVersement? _choisi;
  bool _enCours = false;
  bool _echec = false;
  bool _fait = false;

  Future<List<EnseignantVersement>> _lire() => ref
      .read(portCoordonneesVersementProvider)
      .enseignants()
      .then(
        (List<EnseignantVersement> l) => <EnseignantVersement>[
          for (final EnseignantVersement e in l)
            if (e.aValider) e,
        ],
      );

  Future<void> _valider(EnseignantVersement e) async {
    if (_enCours) return;
    setState(() {
      _enCours = true;
      _echec = false;
    });
    try {
      await ref
          .read(portCoordonneesVersementProvider)
          .valider(
            enseignantId: e.enseignantId,
            coordonneesId: e.coordonneesId!,
          );
      if (mounted) {
        setState(() {
          _fait = true;
          _liste = _lire();
        });
      }
    } on Object {
      if (mounted) setState(() => _echec = true);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = t.admin.finance.paieWise;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle attenue = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    final EnseignantVersement? e = _choisi;
    if (e == null) {
      return FutureBuilder<List<EnseignantVersement>>(
        future: _liste,
        builder: (BuildContext _, AsyncSnapshot<List<EnseignantVersement>> s) {
          final List<EnseignantVersement>? liste = s.data;
          if (liste == null) {
            return s.hasError
                ? Text(a.erreurValider, style: attenue)
                : const SizedBox(height: AppSpacing.xl);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(a.validerIntro, style: attenue),
              Ecart.vLg,
              if (liste.isEmpty)
                Text(a.aucunAValider, style: attenue)
              else
                CarteLignes(
                  lignes: <Widget>[
                    for (final EnseignantVersement x in liste)
                      SettingRow(
                        key: FeuilleValiderCoordonnees.cleEnseignant(
                          x.enseignantId,
                        ),
                        title: x.matricule == null
                            ? x.nom
                            : '${x.nom} · ${x.matricule}',
                        description: x.compteAMonNom || x.lienTitulaire == null
                            ? a.compteDeLEnseignant
                            : a.compteTiers(
                                lien: lienTitulaireDirection(x.lienTitulaire!),
                              ),
                        lien: true,
                        onPress: () => setState(() {
                          _choisi = x;
                          _fait = false;
                          _echec = false;
                        }),
                      ),
                  ],
                ),
            ],
          );
        },
      );
    }
    final DateTime? accord = e.autoriseLe;
    final DateTime? enregistre = e.enregistreLe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(a.validerIntro, style: attenue),
        Ecart.vLg,
        CarteLignes(
          lignes: <Widget>[
            SettingRow(
              title: e.matricule == null ? e.nom : '${e.nom} · ${e.matricule}',
              description: enregistre == null
                  ? null
                  : a.enregistreLe(date: dateComptable(enregistre)),
            ),
            SettingRow(title: a.titulaire, value: e.titulaire ?? ''),
            SettingRow(
              title: e.compteAMonNom || e.lienTitulaire == null
                  ? a.compteDeLEnseignant
                  : a.compteTiers(
                      lien: lienTitulaireDirection(e.lienTitulaire!),
                    ),
              description: accord == null || e.compteAMonNom
                  ? null
                  : a.accordLe(date: dateComptable(accord)),
            ),
            SettingRow(title: a.numero, value: e.numeroMasque ?? ''),
            if (e.pays case final String p)
              SettingRow(title: a.pays, value: nomDuPays(p)),
          ],
        ),
        Ecart.vLg,
        if (_fait)
          BandeauAttention(
            key: FeuilleValiderCoordonnees.cleFait,
            titre: a.validerTitre,
            message: a.validees,
            ton: TonEtat.succes,
          )
        else ...<Widget>[
          if (_echec) ...<Widget>[
            BandeauAttention(
              titre: a.validerTitre,
              message: a.erreurValider,
              ton: TonEtat.alerte,
            ),
            Ecart.vLg,
          ],
          ActionPrincipale(
            key: FeuilleValiderCoordonnees.cleAction,
            libelle: a.validerAction,
            enCours: _enCours,
            onPress: () => unawaited(_valider(e)),
          ),
        ],
      ],
    );
  }
}
