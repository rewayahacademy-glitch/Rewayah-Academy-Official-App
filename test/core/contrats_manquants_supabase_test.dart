// CONTRATS-MANQUANTS : decodage des reponses des RPC de la migration
// 20261016100000 a 20261016100900, telles que les scenarios
// `supabase/tests/scenarios_contrats_*.sql` les fixent (aucun reseau).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/bibliotheque_admin_supabase.dart';
import 'package:rewayah_academy/core/admin/classes_admin_supabase.dart';
import 'package:rewayah_academy/core/admin/fusion_classes_supabase.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart'
    hide PageClasses;
import 'package:rewayah_academy/core/admin/pilotage_supabase.dart';
import 'package:rewayah_academy/core/admin/port_classes_admin.dart';
import 'package:rewayah_academy/core/admin/port_fusion_classes.dart';
import 'package:rewayah_academy/core/admin/port_pilotage.dart';
import 'package:rewayah_academy/core/capacites/enseignants_classe_supabase.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/enseignant/port_remplacements.dart';
import 'package:rewayah_academy/core/enseignant/remplacements_supabase.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/invitations_enseignant_supabase.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_support_actif.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/support_actif_supabase.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/prerequis_enseignant_supabase.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));

  group('classes_admin_page', () {
    test('le filtre devient des parametres serveur', () {
      expect(
        parametresClassesAdmin(
          const FiltreClasses(
            texte: '  garcons ',
            etat: EtatClasseListee.attenteEnseignant,
            enseignantId: FiltreClasses.sansEnseignant,
            remplissage: RemplissageClasse.avecPlaces,
          ),
          page: 0,
          taille: 25,
        ),
        <String, dynamic>{
          'p_page': 1,
          'p_taille': 25,
          'p_texte': 'garcons',
          'p_etat': 'attente_enseignant',
          'p_sans_enseignant': true,
          'p_remplissage': 'avec_places',
        },
      );
      expect(
        parametresClassesAdmin(
          const FiltreClasses(enseignantId: 't1'),
          page: 2,
          taille: 10,
        ),
        <String, dynamic>{'p_page': 2, 'p_taille': 10, 'p_enseignant_id': 't1'},
      );
    });

    test('une page se lit, classe sans enseignant comprise (R7)', () {
      final PageClasses p = pageClassesJson(<String, dynamic>{
        'lignes': <Map<String, dynamic>>[
          <String, dynamic>{
            'groupe_id': 'g1',
            'libelle': 'Garcons',
            'type_public': 'enfant',
            'seuil_max': 5,
            'teacher_id': null,
            'weekday': 1,
            'hour_local': 18,
            'timezone_iana': 'Europe/London',
            'nombre_membres': 5,
            'actif': true,
            'numero_dans_famille': 2,
            'code_court': null,
            'genre': 'hommes',
            'sans_enseignant': true,
            'peut_affecter_enseignant': true,
            'peut_fusionner': true,
            'peut_transferer': false,
          },
        ],
        'total': 1,
        'page': 1,
        'taille': 25,
        'compteurs': <String, dynamic>{
          'active': 0,
          'attente_enseignant': 1,
          'cloturee': 0,
        },
        'jours': <int>[1],
        'heures': <int>[18],
        'fuseaux': <String>['Europe/London'],
        'genres': <String>['hommes'],
        'enseignants': <Map<String, dynamic>>[
          <String, dynamic>{'id': 't1', 'libelle': 'Ibrahim K'},
        ],
        'total_sans_filtre': 3,
      });
      final ClasseListee c = p.lignes.single;
      expect(c.etat, EtatClasseListee.attenteEnseignant);
      expect(c.remplissage, RemplissageClasse.pleine);
      expect(c.fuseau, 'Europe/London');
      expect(c.nom, contains('2'));
      expect(c.peutAffecterEnseignant, isTrue);
      expect(c.peutTransferer, isFalse);
      expect(p.compteurs[EtatClasseListee.attenteEnseignant], 1);
      expect(p.enseignants.single.id, 't1');
      expect(p.totalSansFiltre, 3);
    });
  });

  group('fusion et transfert', () {
    test('noms composes en (libelle, numero), motifs mis en mots', () {
      final ApercuFusion a = apercuFusionJson(<String, dynamic>{
        'source_libelle': 'Filles',
        'source_numero': 1,
        'cible': <String, dynamic>{
          'classe_id': 'g2',
          'libelle': 'Filles',
          'numero': 2,
          'enseignant_prenom': 'Aicha',
          'enseignant_nom': null,
          'membres': 3,
          'capacite': 6,
        },
        'membres_deplaces': 2,
        'enseignant_libere_prenom': null,
        'enseignant_libere_nom': null,
        'familles_notifiees': 2,
      });
      expect(a.sourceNom, isNot(a.cible.nom));
      expect(a.cible.enseignant, 'Aicha');
      expect(a.enseignantLibere, isNull);
      expect(a.membresApres, 5);

      final ResultatFusion refus = resultatFusionJson(<String, dynamic>{
        'statut': 'refusee',
        'motif': 'cible_pleine',
      });
      expect((refus as FusionRefusee).motif, t.admin.fusion.motif.ciblePleine);
      expect(
        resultatFusionJson(<String, dynamic>{'statut': 'deja_faite'}),
        isA<FusionDejaFaite>(),
      );
      expect(motifRefusClasse('nouveau_code'), t.admin.fusion.motif.inconnu);
    });

    test('transfert : trois refus et le succes', () {
      expect(
        (resultatTransfertJson(<String, dynamic>{
          'statut': 'refuse',
          'raison': 'chevauchement',
          'motif': null,
        }) as TransfertRefuse).raison,
        RaisonRefusTransfert.chevauchement,
      );
      final TransfertRefuse autre = resultatTransfertJson(<String, dynamic>{
        'statut': 'refuse',
        'raison': 'autre',
        'motif': 'eleve_absent',
      }) as TransfertRefuse;
      expect(autre.raison, RaisonRefusTransfert.autre);
      expect(autre.motif, t.admin.fusion.motif.eleveAbsent);
      final TransfertFait fait = resultatTransfertJson(<String, dynamic>{
        'statut': 'fait',
        'prenom': 'Yasmine',
        'cible_libelle': 'Filles',
        'cible_numero': 3,
      }) as TransfertFait;
      expect(fait.prenom, 'Yasmine');
    });

    test('historique : type inconnu ecarte', () {
      expect(
        evenementClasseJson(<String, dynamic>{
          'id': 'm1',
          'type': 'fusion_entrante',
          'quand': '2026-10-16T10:00:00Z',
          'autre_libelle': 'Garcons',
          'autre_numero': 1,
          'nombre': 4,
          'prenom': null,
        })?.nombre,
        4,
      );
      expect(
        evenementClasseJson(<String, dynamic>{
          'id': 'm2',
          'type': 'autre',
          'quand': '2026-10-16T10:00:00Z',
        }),
        isNull,
      );
    });
  });

  test('pilotage : ligne, genres et compteurs', () {
    expect(
      parametresPilotage(
        const FiltrePilotage(signal: SignalPilotage.sousMinimum),
        page: 1,
        taille: 25,
      ),
      <String, dynamic>{
        'p_page': 1,
        'p_taille': 25,
        'p_signal': 'sous_minimum',
      },
    );
    final PagePilotage p = pagePilotageJson(<String, dynamic>{
      'lignes': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'enfant|1|18|Europe/Paris',
          'jour': 1,
          'heure': 18,
          'fuseau': 'Europe/Paris',
          'type': 'enfant',
          'classes': 2,
          'effectif': 7,
          'capacite': 10,
          'classes_sous_minimum': 1,
          'classes_attente_enseignant': 1,
          'demandes_en_attente': 4,
          'par_genre': <Map<String, dynamic>>[
            <String, dynamic>{'genre': 'hommes', 'libres': 0, 'manquants': 1},
            <String, dynamic>{'genre': 'femmes', 'libres': 2, 'manquants': 0},
            <String, dynamic>{
              'genre': 'indetermine',
              'libres': 0,
              'manquants': 1,
            },
          ],
        },
      ],
      'total': 1,
      'page': 1,
      'taille': 25,
      'resume': <String, dynamic>{'classes': 2, 'enseignants_manquants': 2},
      'compteurs': <String, dynamic>{'penurie': 1},
      'jours': <int>[1],
      'heures': <int>[18],
      'fuseaux': <String>['Europe/Paris'],
      'total_sans_filtre': 1,
    });
    final LignePilotage l = p.lignes.single;
    expect(l.enseignantsManquants, 2);
    expect(l.enseignantsLibres, 2);
    expect(l.signaux, contains(SignalPilotage.penurie));
    expect(l.tauxRemplissage, 70);
    expect(p.resume.enseignantsManquants, 2);
    expect(p.compteurs[SignalPilotage.sousMinimum], 0);
  });

  test('invitations : forme et quatre issues de la verification', () {
    final Invitation i = invitationJson(<String, dynamic>{
      'code': 'ABCD-EFGH-JKMN',
      'email': 'a@b.fr',
      'expire_le': '2026-10-30T10:00:00Z',
      'etat': 'active',
      'utilisee_le': null,
    });
    expect(i.etat, EtatInvitation.active);
    expect(i.expireLe.toUtc(), DateTime.utc(2026, 10, 30, 10));
    expect(
      resultatInvitationJson(<String, dynamic>{
        'resultat': 'valide',
        'expire_le': '2026-10-30T10:00:00Z',
      }),
      isA<InvitationValide>(),
    );
    expect(
      resultatInvitationJson(<String, dynamic>{
        'resultat': 'expiree',
        'expire_le': '2026-10-01T10:00:00Z',
      }),
      isA<InvitationExpiree>(),
    );
    expect(
      resultatInvitationJson(<String, dynamic>{'resultat': 'deja_utilisee'}),
      isA<InvitationDejaUtilisee>(),
    );
    expect(
      resultatInvitationJson(<String, dynamic>{'resultat': 'inconnue'}),
      isA<InvitationInconnue>(),
    );
  });

  test('support actif : presentation, refus, conflit et absence', () {
    final ResultatActivation faite = resultatActivationJson(<String, dynamic>{
      'statut': 'faite',
      'actif': <String, dynamic>{
        'resource_id': 'r1',
        'titre': 'Tajwid',
        'type': 'pdf',
        'revision': 2,
        'numero_version': 1,
        'position': <String, dynamic>{
          'resource_id': 'r1',
          'type_ancrage': 'page',
          'page': 3,
          'resource_version_id': 'v1',
        },
        'retire': false,
      },
    });
    final SupportActif actif = (faite as ActivationFaite).actif;
    expect(actif.type, TypeRessource.pdf);
    expect(actif.position?.page, 3);
    expect(
      (resultatActivationJson(<String, dynamic>{
        'statut': 'refusee',
        'raison': 'droits_echus',
      }) as ActivationRefusee).raison,
      RefusActivation.droitsEchus,
    );
    expect(
      resultatActivationJson(<String, dynamic>{'statut': 'conflit'}),
      isA<ActivationEnConflit>(),
    );
    expect(supportActifJson(null), isNull);
  });

  test('prerequis de l enseignant', () {
    final p = prerequisEnseignantJson(<String, dynamic>{
      'photo': false,
      'langues': true,
      'fuseau': true,
      'disponibilites': false,
    });
    expect(p.faits, 2);
  });

  test('offres de remplacement : etat et ligne incomplete ecartee', () {
    final OffreCommune? o = offreCommuneJson(<String, dynamic>{
      'seance_id': 's1',
      'groupe_id': 'g1',
      'classe': 'Garcons',
      'numero_dans_famille': 2,
      'debut': '2026-10-20T16:00:00Z',
      'fin': '2026-10-20T17:00:00Z',
      'nb_eleves': 4,
      'etat': 'prise_par_un_collegue',
    });
    expect(o?.etat, EtatOffreCommune.priseParUnCollegue);
    expect(o?.offre.numeroDansFamille, 2);
    expect(
      offreCommuneJson(<String, dynamic>{'seance_id': 's2', 'etat': 'ouverte'}),
      isNull,
    );
  });

  test('bibliotheque : controle complete, classes nommees', () {
    final ControleVersion c = controleJson(<String, dynamic>{
      'criteres': <Map<String, dynamic>>[
        <String, dynamic>{'cle': 'source', 'etat': 'valide'},
        <String, dynamic>{'cle': 'preuve', 'etat': 'bloque'},
      ],
      'publiable': false,
    });
    expect(c.criteres, hasLength(CleCritere.values.length));
    expect(c.criteres.first.etat, EtatCritere.valide);
    expect(
      c.criteres
          .firstWhere((CritereControle k) => k.cle == CleCritere.preuve)
          .etat,
      EtatCritere.bloque,
    );
    expect(
      c.criteres
          .firstWhere((CritereControle k) => k.cle == CleCritere.titulaire)
          .etat,
      EtatCritere.inconnu,
    );
    final ClasseAttribuable a = classeAttribuableJson(<String, dynamic>{
      'id': 'g1',
      'libelle': 'Filles',
      'numero': 4,
      'deja_servie': true,
      'epinglee': false,
    });
    expect(a.nom, contains('4'));
    expect(a.dejaServie, isTrue);
  });

  test('enseignants pour un public : genre par le titre public', () {
    final EnseignantPropose e = enseignantProposeJson(<String, dynamic>{
      'teacher_id': 't1',
      'first_name': null,
      'last_name': null,
      'immutable_id': 'ENS-001',
      'titre_public': 'sayyida',
      'timezone_iana': 'Europe/Paris',
      'classes_actives': 1,
      'creneaux_pris': <Map<String, dynamic>>[
        <String, dynamic>{
          'weekday': 1,
          'hour_local': 18,
          'timezone_iana': 'Europe/Paris',
        },
      ],
      'creneaux_libres': <Map<String, dynamic>>[],
    });
    expect(e.libelle, 'ENS-001');
    expect(e.genre, GenreEnseignant.femme);
    expect(e.creneauxPris.single.heure, 18);
    expect(e.creneauxLibres, isEmpty);
  });

  test('notification classe_changee : libelle et type', () {
    final NotificationTuteur n = notificationDepuis(<String, dynamic>{
      'id': 'n1',
      'evenement': 'classe_changee',
      'params': <String, dynamic>{'motif': 'fusion'},
      'destination': '/tuteur/demandes',
      'cree_le': '2026-10-16T10:00:00Z',
      'lu_le': null,
    }, titrePour: contenuNotificationPour);
    expect(n.titre, t.notifications.evenements.classeChangee);
    expect(n.type, TypeNotification.changementPlanning);
    expect(n.destination, '/tuteur/demandes');
  });
}
