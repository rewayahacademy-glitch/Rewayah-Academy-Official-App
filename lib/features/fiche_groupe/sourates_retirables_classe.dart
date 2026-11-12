// CORRIGER-SOURATE-DIRECTION (garde-cap, 12/11/2026) : les sourates validees
// d'une Classe que la personne connectee peut retirer, avec le geste
// « Retirer ». Pose sur la fiche de la Classe de la direction (et de
// l'enseignant), sans migration :
//
// * la liste vient de `sourates_retirables_classe` (migration
//   20261123820000) : la direction voit tout, sans limite ; l'enseignant ses
//   validations des 24 dernieres heures, avec leur limite. Le role n'est
//   jamais lu ici : la capacite est la ligne rendue par le serveur ;
// * le nom des sourates vient de `sourates_bases_classe` (meme porte) ;
// * le retrait passe par `retirer_sourate_validee`, avec la confirmation
//   commune ([confirmerRetraitSourate]) : action sensible, bouton en attente
//   anime (`DECISION-FLUIDITE-2026-11-07.md`), rien n'est montre comme fait
//   avant la reponse du serveur ;
// * etats : chargement (squelette), contenu, vide (une phrase, ou rien quand
//   [afficherSiVide] est faux), erreur (phrase et « Reessayer »), hors ligne
//   (phrase, aucun geste).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/skeleton.dart';
import 'retrait_sourate.dart';
import 'sourates_classe.dart';

/// Les sourates retirables de la Classe [groupeId].
class SouratesRetirablesClasse extends ConsumerStatefulWidget {
  /// Cree la section ; [noms] : le prenom de chaque eleve, par `studentId`.
  const SouratesRetirablesClasse({
    required this.groupeId,
    required this.noms,
    this.afficherSiVide = true,
    this.ecartAvant,
    super.key,
  });

  /// L'ecart pose avant la section, seulement quand elle rend quelque chose.
  final Widget? ecartAvant;

  /// La Classe.
  final String groupeId;

  /// Le nom a montrer pour chaque eleve, par `studentId`.
  final Map<String, String> noms;

  /// Faux : rien n'est rendu quand il n'y a rien a retirer (fiche de
  /// l'enseignant, ou la section n'a de sens que pendant 24 h).
  final bool afficherSiVide;

  /// La cle de la phrase du vide.
  static const Key cleVide = ValueKey<String>('sourates-retirables-vide');

  /// La cle de la phrase d'erreur.
  static const Key cleErreur = ValueKey<String>('sourates-retirables-erreur');

  /// La cle de la phrase hors ligne.
  static const Key cleHorsLigne = ValueKey<String>(
    'sourates-retirables-hors-ligne',
  );

  /// La cle du geste « Retirer » de la sourate [numero] de [eleveId].
  static Key cleRetirer(String eleveId, int numero) =>
      ValueKey<String>('sourates-retirables-retirer-$eleveId-$numero');

  @override
  ConsumerState<SouratesRetirablesClasse> createState() =>
      _SouratesRetirablesClasseState();
}

/// Une sourate a retirer, prete a montrer.
class _Ligne {
  const _Ligne(this.eleveId, this.eleve, this.numero, this.sourate, this.fin);

  final String eleveId;
  final String eleve;
  final int numero;
  final String sourate;
  final DateTime? fin;
}

class _SouratesRetirablesClasseState
    extends ConsumerState<SouratesRetirablesClasse> {
  /// La derniere sourate retiree ici, pour le dire.
  String? _faite;

  Future<void> _retirer(_Ligne l) async {
    final bool fait = await confirmerRetraitSourate(
      context,
      nom: l.sourate,
      retirer: (String? motif) => ref
          .read(portSouratesClasseProvider)
          .retirer(eleveId: l.eleveId, numero: l.numero, motif: motif),
    );
    if (!mounted) return;
    if (fait) setState(() => _faite = l.sourate);
    // Relu dans tous les cas : un refus veut dire que la liste a change.
    ref
      ..invalidate(souratesRetirablesProvider(widget.groupeId))
      ..invalidate(souratesClasseProvider(widget.groupeId));
  }

  @override
  Widget build(BuildContext context) {
    final tr = t.souratesRetirables;
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = AppPalette.of(context).inkMuted
        .applyTo(textes.bodySmall ?? const TextStyle());
    // L'heure limite se dit a l'heure du profil : la section ecoute le
    // fuseau (HEURE-PROFIL-PARTOUT).
    ref.watch(monHorlogeProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<Map<String, Map<int, DateTime?>>> retirables = ref.watch(
      souratesRetirablesProvider(widget.groupeId),
    );
    final AsyncValue<Map<String, List<SourateBases>>> sourates = ref.watch(
      souratesClasseProvider(widget.groupeId),
    );
    final bool arabe = LocaleSettings.currentLocale == AppLocale.ar;

    final Widget corps;
    if (retirables.hasError || sourates.hasError) {
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(tr.erreur, key: SouratesRetirablesClasse.cleErreur),
          Ecart.vSm,
          ActionPrincipale(
            libelle: t.commun.reessayer,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            onPress: () => ref
              ..invalidate(souratesRetirablesProvider(widget.groupeId))
              ..invalidate(souratesClasseProvider(widget.groupeId)),
          ),
        ],
      );
    } else if (!retirables.hasValue || !sourates.hasValue) {
      // Sans phrase du vide, rien pendant la lecture : la section ne
      // clignote pas avant de disparaitre.
      if (!widget.afficherSiVide) return const SizedBox.shrink();
      corps = const Skeleton.liste(lignes: 2);
    } else {
      final List<_Ligne> lignes = <_Ligne>[
        for (final MapEntry<String, Map<int, DateTime?>> e
            in retirables.requireValue.entries)
          for (final MapEntry<int, DateTime?> s in e.value.entries)
            _Ligne(
              e.key,
              widget.noms[e.key] ?? '',
              s.key,
              _nom(sourates.requireValue[e.key], s.key, arabe: arabe),
              s.value,
            ),
      ]..sort(_ordre);
      if (lignes.isEmpty && _faite == null && !widget.afficherSiVide) {
        return const SizedBox.shrink();
      }
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_faite case final String nom) ...<Widget>[
            Text(t.cahierSourates.retirerFait(nom: nom), style: discret),
            Ecart.vSm,
          ],
          if (lignes.isEmpty)
            Text(tr.vide, key: SouratesRetirablesClasse.cleVide)
          else if (horsLigne)
            Text(tr.horsLigne, key: SouratesRetirablesClasse.cleHorsLigne)
          else ...<Widget>[
            Text(tr.aide, style: discret),
            for (final _Ligne l in lignes)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(tr.ligne(eleve: l.eleve, sourate: l.sourate)),
                          if (l.fin case final DateTime fin)
                            Text(_limite(fin), style: discret),
                        ],
                      ),
                    ),
                    ActionPrincipale(
                      key: SouratesRetirablesClasse.cleRetirer(
                        l.eleveId,
                        l.numero,
                      ),
                      libelle: t.cahierSourates.retirer,
                      libelleSemantique: tr.retirerPour(
                        sourate: l.sourate,
                        eleve: l.eleve,
                      ),
                      niveau: NiveauAction.destructive,
                      compacte: true,
                      pleineLargeur: false,
                      onPress: () => _retirer(l),
                    ),
                  ],
                ),
              ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ?widget.ecartAvant,
        Text(tr.titre, style: textes.titleMedium),
        Ecart.vSm,
        corps,
      ],
    );
  }

  /// Le nom de la sourate [numero] dans la liste de l'eleve, ou son numero
  /// quand le serveur ne l'a pas rendue.
  static String _nom(
    List<SourateBases>? liste,
    int numero, {
    required bool arabe,
  }) {
    for (final SourateBases s in liste ?? const <SourateBases>[]) {
      if (s.numero == numero) return s.nomPour(arabe: arabe);
    }
    return '$numero';
  }

  /// Par eleve, puis par numero.
  static int _ordre(_Ligne a, _Ligne b) {
    final int parEleve = a.eleve.compareTo(b.eleve);
    return parEleve != 0 ? parEleve : a.numero.compareTo(b.numero);
  }

  /// « Possible jusqu'a 19:30 », ou « jusqu'a demain » quand la limite tombe
  /// le lendemain, a l'heure du profil.
  static String _limite(DateTime fin) {
    final DateTime ici = chezMoi(DateTime.now());
    final DateTime la = chezMoi(fin);
    final bool demain =
        la.year != ici.year || la.month != ici.month || la.day != ici.day;
    final String heure = heureChezMoi(fin);
    return demain
        ? t.souratesRetirables.jusquaDemain(heure: heure)
        : t.souratesRetirables.jusqua(heure: heure);
  }
}
