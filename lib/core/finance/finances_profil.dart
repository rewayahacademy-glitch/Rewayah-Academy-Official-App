// La finance d'un profil eleve et la synthese du foyer, telles qu'une source
// les rend (FI-1c, guide Finance V4 §1.1, §1.2, §1.7, §5.1, §5.2 ; FI-BR-03,
// FI-BR-04).
//
// **Aucun calcul dans Flutter** (FI6) : chaque montant, chaque ligne de
// mensualite et chaque etat arrivent deja arretes. Le total du foyer est une
// LECTURE : jamais un portefeuille, jamais une autorisation (FI1, FIN4-07).
//
// **Donnees par role** (lecon 15, revue FI-1a:96-106) : ces objets ne sont
// rendus qu'au titulaire et a l'eleve adulte pour son seul profil ; l'enfant
// et le second adulte n'en recoivent jamais, meme en chargement ou en
// erreur. L'acces de l'enfant passe par `PortAccesFoyer`, sans montant ni
// cause.

import 'package:flutter/foundation.dart';

import 'montant.dart';

/// L'etat financier d'un profil (guide §5.1 « etats visuels »). Un etat se
/// dit toujours par un texte, jamais par la couleur seule (FI17).
enum EtatFinancier {
  /// Le mois courant est finance.
  finance,

  /// Le profil est en essai (2 seances au plus, gratuites, FI4).
  essai,

  /// Il manque un montant pour financer la prochaine periode.
  manque,

  /// Un paiement attend sa confirmation (FI9).
  enConfirmation,

  /// La periode financee est terminee, sans nouvelle periode.
  expire,

  /// L'inscription est en pause.
  pause,

  /// La nouvelle periode n'est pas financee : place conservee (FI11).
  aRegulariser,
}

/// La nature d'une ligne de mensualite (guide §1.3, §1.8, FI5). Seules les
/// lignes RENDUES s'affichent : jamais une remise qui n'existe pas.
enum NatureLigneMensualite {
  /// Le tarif academique de base.
  tarif,

  /// La remise de rang familial.
  remiseRang,

  /// La reduction du calendrier (prorata du premier mois payant).
  prorata,

  /// La bourse Rewayah (18/10/2026), jamais cumulee avec une autre remise.
  bourse,

  /// La part d'un trimestre ou d'une annee paye d'avance (18/10/2026).
  remisePrepaiement,

  /// Un avoir.
  avoir,

  /// Une taxe, separee du tarif academique (FI13).
  taxe,
}

/// Une ligne de la mensualite, deja arretee.
@immutable
class LigneMensualite {
  /// Cree la ligne.
  const LigneMensualite({
    required this.nature,
    required this.montant,
    this.rang,
  });

  /// Ce que represente la ligne.
  final NatureLigneMensualite nature;

  /// Son montant, signe compris (negatif pour une remise ou un avoir).
  final Montant montant;

  /// Le rang familial du membre payant (3 = troisieme), **rendu par la
  /// source** pour une remise de rang (« Remise familiale 3e membre », guide
  /// §5.2) ; `null` pour les autres lignes, ou quand la source ne le rend pas
  /// (le libelle reste alors « Remise familiale », jamais un rang suppose).
  final int? rang;
}

/// La periode financee d'un profil (FI2) : l'acces depend d'elle, jamais du
/// solde.
@immutable
class PeriodeFinancee {
  /// Cree la periode.
  const PeriodeFinancee({required this.debut, required this.fin});

  /// Le premier jour finance.
  final DateTime debut;

  /// Le dernier jour finance (« jusqu'au »).
  final DateTime fin;
}

/// Le prochain debit mensuel d'un profil (FI3) : mois civil, jamais par
/// seance.
@immutable
class ProchainDebit {
  /// Cree le debit.
  const ProchainDebit({required this.date, required this.montant});

  /// La date du debit.
  final DateTime date;

  /// Son montant, deja arrete.
  final Montant montant;
}

/// La finance d'un profil eleve, pour le titulaire ou l'eleve adulte
/// lui-meme.
@immutable
class FinancesProfil {
  /// Cree la finance d'un profil.
  const FinancesProfil({
    required this.profilId,
    required this.prenom,
    required this.cleAccent,
    required this.estAdulte,
    required this.etat,
    required this.solde,
    required this.mensualite,
    this.cleAvatar,
    this.classe,
    this.age,
    this.periode,
    this.prochainDebit,
    this.lignesMensualite = const <LigneMensualite>[],
    this.essaisUtilises,
    this.manque,
    this.finConservation,
  });

  /// L'identifiant du profil eleve.
  final String profilId;

  /// Le prenom.
  final String prenom;

  /// La cle d'accent du profil (`profileAccentKey`, guide §3) : **rendue par
  /// les donnees et stable**, jamais la position dans une liste (FI15). Elle
  /// ne choisit encore aucune teinte : la decision est portee par TH-2
  /// (revue FI-1a:19, X-1).
  final String cleAccent;

  /// Vrai pour un profil adulte (tarif adulte).
  final bool estAdulte;

  /// La cle de la photo, `null` sans photo (initiale).
  final String? cleAvatar;

  /// Le nom de la classe, deja redige, ou `null`.
  final String? classe;

  /// L'age, seulement s'il est rendu (revue FI-1a E-13).
  final int? age;

  /// L'etat financier.
  final EtatFinancier etat;

  /// Le solde individuel (FI1). Peut etre nul avec un mois finance (FI2).
  final Montant solde;

  /// La periode financee, `null` sans periode (essai, aucun paiement).
  final PeriodeFinancee? periode;

  /// Le prochain debit, `null` quand aucun n'est prevu.
  final ProchainDebit? prochainDebit;

  /// La mensualite totale, deja arretee.
  final Montant mensualite;

  /// Les lignes de la mensualite, dans l'ordre rendu.
  final List<LigneMensualite> lignesMensualite;

  /// Les seances d'essai deja utilisees (« Essai : n/2 »), `null` hors essai.
  final int? essaisUtilises;

  /// Le manque a financer, `null` quand rien ne manque (FIN4-09 : aucun
  /// debit partiel, l'ecran dit le manque).
  final Montant? manque;

  /// La fin de conservation de la place quand la periode est a regulariser.
  final DateTime? finConservation;
}

/// La synthese du foyer, en LECTURE seulement (FI1, guide §5.1).
@immutable
class SyntheseFoyer {
  /// Cree la synthese.
  const SyntheseFoyer({
    required this.totalSoldes,
    required this.aPayerCeMois,
    required this.profilsFinances,
    required this.profils,
    required this.paiementsDuMois,
  });

  /// Le total des soldes, une lecture : jamais un solde depensable.
  final Montant totalSoldes;

  /// Ce qui reste a payer ce mois.
  final Montant aPayerCeMois;

  /// Le nombre de profils dont le mois est finance.
  final int profilsFinances;

  /// Le nombre de profils du foyer.
  final int profils;

  /// Le nombre de paiements du mois.
  final int paiementsDuMois;
}

/// Les finances du foyer vues par le titulaire (FI-BR-03, FI-BR-04).
@immutable
class FinancesFoyer {
  /// Cree la vue.
  const FinancesFoyer({required this.synthese, required this.profils});

  /// La synthese du foyer.
  final SyntheseFoyer synthese;

  /// Une finance par profil, dans l'ordre rendu.
  final List<FinancesProfil> profils;
}
