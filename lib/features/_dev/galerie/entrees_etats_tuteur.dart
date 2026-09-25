import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_finance_foyer.dart';
import '../../../core/domain/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/entete_page.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/ligne_beneficiaire.dart';
import '../../../core/widgets/resultat_par_profil.dart';
import '../../../core/widgets/resume_solde.dart';
import '../../../core/widgets/selecteur_profils.dart';
import '../../../core/widgets/selecteur_theme.dart';
import '../../../core/widgets/selection_profils.dart';
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
  // Les composants partages des ecrans finance (LT-3). Montants en `XTS`,
  // code ISO 4217 reserve aux essais : aucun ne passe pour un prix reel.
  EntreeGalerie(
    nom: 'ResumeSolde',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'total du foyer',
        (BuildContext _) => const ResumeSolde.foyer(
          totaux: <TotalSoldes>[
            TotalSoldes(montantMineur: 4200, devise: 'XTS'),
          ],
          complet: true,
        ),
      ),
      EtatGalerie(
        'total incomplet',
        (BuildContext _) => const ResumeSolde.foyer(
          totaux: <TotalSoldes>[
            TotalSoldes(montantMineur: 1200, devise: 'XTS'),
          ],
          complet: false,
        ),
      ),
      EtatGalerie(
        'profil, solde inconnu',
        (BuildContext _) =>
            const ResumeSolde.profil(prenom: 'Aicha', solde: _soldeInconnu),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'LigneBeneficiaire',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'solde connu, acces actif',
        (BuildContext _) => const LigneBeneficiaire(
          prenom: 'Aicha',
          solde: _soldeConnu,
          acces: 'Accès actif',
          onPress: _rien,
        ),
      ),
      EtatGalerie(
        'solde inconnu',
        (BuildContext _) =>
            const LigneBeneficiaire(prenom: 'Youssef', solde: _soldeInconnu),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'SelectionProfils',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'un profil retenu',
        (BuildContext _) => const SelectionProfils(
          profils: _profilsExemple,
          selection: <String>{'e1'},
          onChange: _selectionIgnoree,
        ),
      ),
      EtatGalerie(
        'tous retenus',
        (BuildContext _) => const SelectionProfils(
          profils: _profilsExemple,
          selection: <String>{'e1', 'e2', 'e3'},
          onChange: _selectionIgnoree,
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'ResultatParProfil',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'trois issues',
        (BuildContext _) => const ResultatParProfil(
          issues: <IssueProfil>[
            IssueProfil(profilId: 'e1', issue: IssueServeur.confirmee),
            IssueProfil(profilId: 'e2', issue: IssueServeur.enAttente),
            IssueProfil(profilId: 'e3', issue: IssueServeur.echouee),
          ],
          prenoms: _prenomsExemple,
        ),
      ),
      EtatGalerie(
        'toutes confirmees',
        (BuildContext _) => const ResultatParProfil(
          issues: <IssueProfil>[
            IssueProfil(profilId: 'e1', issue: IssueServeur.confirmee),
            IssueProfil(profilId: 'e2', issue: IssueServeur.confirmee),
          ],
          prenoms: _prenomsExemple,
        ),
      ),
    ],
  ),
];

const SoldeProfil _soldeConnu = SoldeProfil(
  profilId: 'e1',
  montantMineur: 2400,
  devise: 'XTS',
);

const SoldeProfil _soldeInconnu = SoldeProfil(
  profilId: 'e2',
  montantMineur: null,
  devise: null,
);

const Map<String, String> _prenomsExemple = <String, String>{
  'e1': 'Aicha',
  'e2': 'Youssef',
  'e3': 'Karim',
};

void _selectionIgnoree(Set<String> selection) {}

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
