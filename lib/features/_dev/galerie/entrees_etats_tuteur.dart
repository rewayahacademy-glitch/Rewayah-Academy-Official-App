import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/domain/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/entete_page.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/selecteur_profils.dart';
import '../../../core/widgets/selecteur_theme.dart';
import '../../../core/widgets/skeleton.dart';
import 'catalogue_galerie.dart';

/// Les entrees de galerie des composants partages du chantier Tuteur V1 qui
/// lisent des cles `commun.*` (phase 0c1) : etat systeme, bloc asynchrone,
/// selecteur de profils, en-tete de page, selecteur de theme.
///
/// Dans un fichier a part du catalogue : ces composants et leurs cles i18n
/// arrivent ensemble, et le catalogue n'a qu'une ligne a changer.
List<EntreeGalerie> entreesEtatsTuteur() => <EntreeGalerie>[
  EntreeGalerie(
    nom: 'EtatSysteme',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'bloc, echec avec reessayer',
        (BuildContext _) =>
            const EtatSysteme(nature: NatureEtat.echecServeur, onAction: _rien),
      ),
      EtatGalerie(
        'bloc, indisponible',
        (BuildContext _) => const EtatSysteme(
          nature: NatureEtat.indisponible,
          dependance: 'DB-CPT-03',
        ),
      ),
      EtatGalerie(
        'page, introuvable',
        (BuildContext _) => const EtatSysteme(
          nature: NatureEtat.introuvable,
          portee: PorteeEtat.page,
          onAction: _rien,
        ),
      ),
      EtatGalerie(
        'page, session expiree',
        (BuildContext _) => const EtatSysteme(
          nature: NatureEtat.sessionExpiree,
          portee: PorteeEtat.page,
          onAction: _rien,
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'BlocAsynchrone',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'chargement',
        (BuildContext _) => const BlocAsynchrone<List<String>>(
          valeur: AsyncValue<List<String>>.loading(),
          squelette: Skeleton.liste(lignes: 2, differe: false),
          construire: _listeExemple,
          onReessayer: _rien,
        ),
      ),
      EtatGalerie(
        'contenu',
        (BuildContext _) => const BlocAsynchrone<List<String>>(
          valeur: AsyncData<List<String>>(<String>['Aicha', 'Youssef']),
          squelette: Skeleton.liste(lignes: 2, differe: false),
          construire: _listeExemple,
        ),
      ),
      EtatGalerie(
        'vide',
        (BuildContext _) => const BlocAsynchrone<List<String>>(
          valeur: AsyncData<List<String>>(<String>[]),
          squelette: Skeleton.liste(lignes: 2, differe: false),
          construire: _listeExemple,
          vide: EtatSysteme(nature: NatureEtat.aucunResultat),
        ),
      ),
      EtatGalerie(
        'erreur',
        (BuildContext _) => const BlocAsynchrone<List<String>>(
          valeur: AsyncError<List<String>>(
            FormatException('lecture'),
            StackTrace.empty,
          ),
          squelette: Skeleton.liste(lignes: 2, differe: false),
          construire: _listeExemple,
          onReessayer: _rien,
        ),
      ),
      EtatGalerie(
        'capacite indisponible',
        (BuildContext _) => const BlocAsynchrone<List<String>>(
          valeur: AsyncError<List<String>>(
            CapaciteIndisponible('DB-CPT-03'),
            StackTrace.empty,
          ),
          squelette: Skeleton.liste(lignes: 2, differe: false),
          construire: _listeExemple,
          onReessayer: _rien,
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'SelecteurProfils',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'trois profils, ajout',
        (BuildContext _) => const SelecteurProfils(
          profils: _profilsExemple,
          selectionId: 'e1',
          onSelection: _profilIgnore,
          onAjouter: _rien,
        ),
      ),
      EtatGalerie(
        'second choisi, sans ajout',
        (BuildContext _) => const SelecteurProfils(
          profils: _profilsExemple,
          selectionId: 'e2',
          onSelection: _profilIgnore,
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'EntetePage',
    famille: FamilleComposant.structure,
    etats: <EtatGalerie>[
      EtatGalerie(
        'titre et cloche sans non-lus',
        (BuildContext _) => const EntetePage(
          titre: 'Accueil',
          actions: <Widget>[ClocheNotifications(onPress: _rien)],
        ),
      ),
      EtatGalerie(
        'retour, sous-titre, bascule et non-lus',
        (BuildContext _) => const EntetePage(
          titre: 'Réglages',
          sousTitre: 'Apparence, langue et notifications',
          onRetour: _rien,
          actions: <Widget>[
            SelecteurTheme.entete(),
            ClocheNotifications(onPress: _rien, nonLues: 2),
          ],
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'SelecteurTheme',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'sur carte, theme clair affiche',
        (BuildContext _) => const SelecteurTheme(),
      ),
      EtatGalerie(
        'sur carte, theme sombre affiche',
        (BuildContext _) => Theme(
          data: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          child: const SelecteurTheme(),
        ),
      ),
      EtatGalerie(
        'en-tete',
        (BuildContext _) => const Align(
          alignment: AlignmentDirectional.topStart,
          child: SelecteurTheme.entete(),
        ),
      ),
    ],
  ),
];

/// Trois profils d'exemple : prenoms fictifs, jamais des constantes metier.
const List<ProfilSelectionnable> _profilsExemple = <ProfilSelectionnable>[
  ProfilSelectionnable(
    id: 'e1',
    prenom: 'Aicha',
    etat: 'En séance',
    point: PointStatut.succes,
  ),
  ProfilSelectionnable(
    id: 'e2',
    prenom: 'Youssef',
    etat: 'Dans 3 h',
    point: PointStatut.attention,
  ),
  ProfilSelectionnable(id: 'e3', prenom: 'Karim', etat: 'Aucun cours'),
];

Widget _listeExemple(List<String> prenoms) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[for (final String p in prenoms) Text(p)],
);

void _rien() {}

void _profilIgnore(String id) {}
