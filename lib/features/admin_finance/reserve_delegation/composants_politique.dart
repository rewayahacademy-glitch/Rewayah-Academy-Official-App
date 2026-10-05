// Les composants que partagent les deux panneaux (CPT-DIR-1) : la lecture
// asynchrone a cinq etats, un groupe titre, un champ de politique, le pied
// d'enregistrement et l'historique des versions.
//
// Le champ s'inspire de `_ChampPolitique` (`politiques_commerciales.dart`,
// fichier gele : patron seulement, pas d'import).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/carte_groupee.dart';
import '../../../core/widgets/comptable/ligne_activite.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/local_feedback.dart';
import '../../../core/widgets/skeleton.dart';
import 'saisie_politique.dart';

/// Lit [fournisseur] et rend [construire] : chargement (squelette), contenu,
/// erreur, « Pas encore disponible » (capacite absente) et hors ligne (echec
/// sans reseau). Un echec reste une echec, jamais un contenu vide.
class BlocPolitique<T> extends ConsumerWidget {
  /// Cree le bloc.
  const BlocPolitique({
    required this.fournisseur,
    required this.construire,
    super.key,
  });

  /// La lecture.
  final FutureProvider<T> fournisseur;

  /// Le contenu, une fois la valeur la.
  final Widget Function(T valeur) construire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<T> valeur = ref.watch(fournisseur);
    void relire() => ref.invalidate(fournisseur);
    final Object? erreur = valeur.hasError ? valeur.error : null;
    final bool horsLigne =
        erreur != null &&
        erreur is! CapaciteIndisponible &&
        (ref.watch(horsLigneProvider).value ?? false);
    if (horsLigne) {
      return EtatSysteme(nature: NatureEtat.horsLigne, onAction: relire);
    }
    return BlocAsynchrone<T>(
      valeur: valeur,
      squelette: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Skeleton.texte(lignes: 2),
          Skeleton.liste(lignes: 4),
        ],
      ),
      onReessayer: relire,
      construire: construire,
    );
  }
}

/// Un groupe de reglages : son titre, sa phrase, puis ses contenus dans une
/// seule carte.
class GroupePolitique extends StatelessWidget {
  /// Cree le groupe.
  const GroupePolitique({
    required this.titre,
    required this.enfants,
    super.key,
    this.detail,
    this.enCarte = true,
  });

  /// Le titre.
  final String titre;

  /// Faux quand les contenus portent deja leur propre carte (groupes de
  /// choix) : ils se suivent alors sans seconde carte autour.
  final bool enCarte;

  /// La phrase qui dit ce que regle le groupe.
  final String? detail;

  /// Les contenus, separes par un filet.
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? phrase = detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(header: true, child: Text(titre, style: textes.titleMedium)),
        if (phrase != null) ...<Widget>[
          Ecart.vXs,
          Text(
            phrase,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vMd,
        if (enCarte)
          CarteGroupee(sections: enfants)
        else
          for (int i = 0; i < enfants.length; i++) ...<Widget>[
            if (i > 0) Ecart.vLg,
            enfants[i],
          ],
      ],
    );
  }
}

/// Un champ de politique : le libelle, la consequence en une phrase, la saisie
/// (nombre, montant ou pourcentage) avec son unite, et l'erreur.
class ChampPolitique extends StatelessWidget {
  /// Cree le champ.
  const ChampPolitique({
    required this.libelle,
    required this.consequence,
    required this.suffixe,
    required this.controleur,
    required this.onChange,
    super.key,
    this.erreur,
    this.indice,
    this.actif = true,
  });

  /// Le libelle.
  final String libelle;

  /// Ce que le champ change, en une phrase.
  final String consequence;

  /// L'unite (devise, mois, jours, %).
  final String suffixe;

  /// Le texte saisi.
  final TextEditingController controleur;

  /// Appele a chaque frappe.
  final VoidCallback onChange;

  /// L'erreur de saisie, une fois l'enregistrement tente.
  final String? erreur;

  /// Le texte d'un champ facultatif laisse vide.
  final String? indice;

  /// Faux pendant l'enregistrement.
  final bool actif;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(libelle, style: textes.titleSmall),
        Ecart.vXs,
        Text(
          consequence,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        Semantics(
          label: libelle,
          child: TextField(
            controller: controleur,
            enabled: actif,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(caracteresSaisie),
              LengthLimitingTextInputFormatter(chiffresEntiersMax + 6),
            ],
            onChanged: (String _) => onChange(),
            style: AppTypography.tabulaire(
              textes.bodyLarge ?? const TextStyle(),
            ),
            decoration: InputDecoration(
              suffixText: suffixe,
              hintText: indice,
              errorText: erreur,
              errorMaxLines: 4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Le pied d'un panneau : le retour local, puis « Enregistrer une nouvelle
/// version » seulement quand il y a quelque chose a enregistrer : sinon la
/// phrase le dit, jamais un bouton grise.
class PiedEnregistrement extends StatelessWidget {
  /// Cree le pied.
  const PiedEnregistrement({
    required this.modifie,
    required this.enCours,
    required this.onEnregistrer,
    required this.message,
    required this.messageEstErreur,
    super.key,
  });

  /// Vrai quand le brouillon differe de la version en vigueur.
  final bool modifie;

  /// Vrai pendant l'enregistrement.
  final bool enCours;

  /// Enregistre.
  final VoidCallback onEnregistrer;

  /// Le retour local (succes ou echec), nul sans retour.
  final String? message;

  /// Vrai quand [message] est un echec : il reste affiche.
  final bool messageEstErreur;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final c = t.comptable.direction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LocalFeedback(message: message, persistant: messageEstErreur),
        if (modifie)
          ActionPrincipale(
            libelle: c.enregistrer,
            onPress: onEnregistrer,
            enCours: enCours,
          )
        else
          Text(
            c.aucuneModification,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
      ],
    );
  }
}

/// Les versions enregistrees, de la plus recente a la plus ancienne. Un
/// historique illisible n'empeche pas de lire la politique : il ne s'affiche
/// pas.
class HistoriqueVersions extends ConsumerWidget {
  /// Cree l'historique.
  const HistoriqueVersions({required this.fournisseur, super.key});

  /// La lecture du journal.
  final FutureProvider<List<EntreeJournal>> fournisseur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<EntreeJournal>> valeur = ref.watch(fournisseur);
    final List<EntreeJournal>? entrees = valeur.value;
    if (entrees == null) return const SizedBox.shrink();
    final c = t.comptable.direction;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return GroupePolitique(
      titre: c.historique,
      enfants: <Widget>[
        if (entrees.isEmpty)
          Text(
            c.historiqueVide,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final EntreeJournal e in entrees) LigneActivite(e),
            ],
          ),
      ],
    );
  }
}

/// La phrase d'un echec d'enregistrement : capacite absente, ou issue
/// incertaine (apres une coupure, on ne sait pas si la version est partie).
String phraseEchecEnregistrement(Object erreur) =>
    erreur is CapaciteIndisponible
    ? t.comptable.direction.enregistrementIndisponible
    : t.comptable.direction.erreurEnregistrement;

/// Une cle d'idempotence : la meme tant que le brouillon ne change pas, pour
/// qu'une nouvelle tentative ne cree pas deux versions.
String nouvelleCleIdempotence(String prefixe) =>
    '$prefixe-${DateTime.now().microsecondsSinceEpoch}';
