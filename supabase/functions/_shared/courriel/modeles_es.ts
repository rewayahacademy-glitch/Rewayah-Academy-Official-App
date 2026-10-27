// Les e-mails en espagnol, ecrits a la main (« usted »). Ils suivent le sens
// du francais (`modeles_fr.ts`) ; memes liens, memes boutons. Competence `mots-rewayah`.

import { APP } from './gabarit.ts'
import { avisDans, bonjour, dateLongue, type Fabrique, type LangueEcrite, libre, type Parole } from './outils.ts'
import { quandSeance } from './modeles_fr.ts'

const PAROLE: Parole = {
  salut: 'Hola',
  fin: ',',
  salutSeul: 'Hola,',
  note: 'Los detalles están en la aplicación, una vez iniciada la sesión.',
  sujetLibre: 'Un mensaje de Rewayah Academy',
  locale: 'es-ES',
}
const avis = avisDans(PAROLE)

const RAISON: Record<string, string> = {
  compte: 'Recibe este correo electrónico porque concierne a su cuenta de Rewayah Academy.',
  inscription: 'Recibe este correo electrónico porque concierne a una solicitud hecha en Rewayah Academy.',
  classes: 'Recibe este correo electrónico porque concierne a una clase que usted sigue o imparte.',
  facturation: 'Recibe este correo electrónico porque concierne a la facturación de su hogar.',
  recrutement: 'Recibe este correo electrónico porque está en contacto con nuestro equipo de selección.',
  direction: 'Recibe este correo electrónico de la dirección de Rewayah Academy.',
  nouvelles: 'Recibe este correo electrónico porque sigue las novedades de Rewayah Academy.',
}

const MODELES: Record<string, Fabrique> = {
  demande_recue: (d) => avis(d, 'Hemos recibido su solicitud', 'Hemos recibido su solicitud',
    'Hemos recibido su solicitud de horario. La dirección la estudia y le responde en la aplicación.',
    'Seguir mi solicitud', '/tuteur/demandes'),
  demande_presentation: (d) => avis(d, 'Se ha recibido una solicitud de presentación', 'Solicitud de presentación recibida',
    'Se ha recibido una solicitud de presentación. Le espera en la aplicación.',
    'Abrir la solicitud', '/tuteur/demandes'),
  classe_validee: (d) => avis(d, 'Su clase está lista', 'Su clase está lista',
    'La clase correspondiente a su solicitud está lista. Falta asignarle su docente; se le avisará.',
    'Ver la clase', '/tuteur/demandes'),
  enseignant_affecte: (d) => avis(d, 'Se ha asignado un docente a la clase', 'Su clase ya tiene docente',
    'Se ha asignado un docente a la clase. Encontrará su nombre y los horarios en la aplicación.',
    'Ver la clase', '/tuteur/demandes'),
  demande_close: (d) => avis(d, 'Su solicitud ha sido cerrada', 'Su solicitud ha sido cerrada',
    'Su solicitud de horario ha sido cerrada. La respuesta de la dirección está en la aplicación.',
    'Leer la respuesta', '/tuteur/demandes'),
  classe_changee: (d) => avis(d, 'Cambio de clase, mismo horario', 'Cambio de clase',
    'Un alumno de su hogar se ha unido a otra clase, en el mismo horario.',
    'Ver el detalle', '/tuteur/demandes'),
  // Ficha del 27/10/2026, línea 15: los nueve eventos de clases y sesiones.
  classe_creee: (d) => avis(d, 'Su clase está creada', 'Su clase está creada',
    'Se acaba de crear una clase. Su horario y su profesor están en la aplicación.',
    'Ver el horario', '/tuteur'),
  enseignant_change: (d) => avis(d, 'El profesor de la clase cambia', 'El profesor de la clase cambia',
    'Otro profesor toma la clase, en el mismo horario. Su nombre está en la aplicación.',
    'Ver la clase', '/tuteur'),
  eleve_inscrit: (d) => avis(d, 'Un alumno se une a su clase', 'Un alumno se une a su clase',
    'Un alumno se une a su clase. Su ficha está en la aplicación.',
    'Ver mis clases', '/enseignant/classes'),
  eleve_retire: (d) => avis(d, 'Un alumno deja su clase', 'Un alumno deja su clase',
    'Un alumno deja su clase. La lista actualizada está en la aplicación.',
    'Ver mis clases', '/enseignant/classes'),
  creneau_change: (d) => avis(d, 'El horario de la clase cambia', 'El horario de la clase cambia',
    'El horario de la clase cambia. El nuevo horario está en la aplicación.',
    'Ver el nuevo horario', '/tuteur'),
  seance_annulee: (d) => {
    const quand = quandSeance(d, 'es-ES', 'a las')
    return avis(d, 'Una sesión está anulada', 'Una sesión está anulada',
      quand ? `La sesión del ${quand} está anulada.` : 'Una sesión de la clase está anulada.',
      'Ver la planificación', '/tuteur')
  },
  seance_deplacee: (d) => {
    const quand = quandSeance(d, 'es-ES', 'a las')
    return avis(d, 'Una sesión se traslada', 'Una sesión se traslada',
      quand ? `Una sesión se traslada al ${quand}.` : 'Una sesión de la clase se traslada. El nuevo horario está en la aplicación.',
      'Ver el nuevo horario', '/tuteur')
  },
  enseignante_absente: (d) => {
    const quand = quandSeance(d, 'es-ES', 'a las')
    return avis(d, 'El profesor está ausente en una sesión', 'El profesor está ausente en una sesión',
      (quand ? `El profesor está ausente en la sesión del ${quand}.` : 'El profesor está ausente en una sesión de la clase.')
        + ' La dirección le mantiene informado.',
      'Ver la planificación', '/tuteur')
  },
  classe_supprimee: (d) => avis(d, 'La clase está cerrada', 'La clase está cerrada',
    'La clase está cerrada. La dirección se pone en contacto con usted para lo que sigue.',
    'Abrir la aplicación', '/tuteur'),
  remplacement_propose: (d) => avis(d, 'Se le propone una sustitución', 'Se le propone una sustitución',
    'Se le propone la sustitución de una clase. Responda en la aplicación para que la clase quede cubierta.',
    'Ver la sustitución', '/enseignant/journee/remplacements'),
  remplacement_pris: (d) => avis(d, 'La sustitución ha sido asignada', 'La sustitución ha sido asignada',
    'La sustitución de la clase ha sido asignada.',
    'Ver mi jornada', '/enseignant/journee/remplacements'),
  controle_mission_attribuee: (d) => avis(d, 'Se le ha asignado una misión de control', 'Nueva misión de control',
    'Se le ha asignado una misión de control.', 'Abrir la misión', '/controleur'),
  controle_mission_non_controlee: (d) => avis(d, 'Una misión se ha quedado sin verificar', 'Misión sin verificar',
    'Una misión de control se ha quedado sin verificar.', 'Ver los sorteos', '/admin/securite-audit/tirages'),
  paiement_relance: (d) => {
    const j = typeof d.jours_avant === 'number' ? d.jours_avant : null
    const quand = j === null ? 'pronto' : j === 0 ? 'hoy' : j === 1 ? 'mañana' : `dentro de ${j} días`
    return avis(d, `Un pago vence ${quand}`, 'Un pago está por vencer',
      `El pago del mes vence ${quand}. Se realiza en la aplicación, en la sección Pagos, para que las clases continúen sin interrupción.`,
      'Realizar el pago', '/tuteur/foyer/recharge')
  },
  acces_suspendu_paiement: (d) => avis(d, 'Un acceso está suspendido', 'Un acceso está suspendido',
    'No se ha recibido el pago del mes: el acceso a la clase está suspendido. Se restablece en cuanto se recibe el pago.',
    'Realizar el pago', '/tuteur/foyer/recharge'),
  acces_retabli_paiement: (d) => avis(d, 'El acceso se ha restablecido', 'El acceso se ha restablecido',
    'Se ha recibido el pago: el acceso a la clase se ha restablecido.', 'Abrir la aplicación', '/tuteur/foyer/recharge'),
  invitation_foyer: (d) => {
    const qui = typeof d.invite_par === 'string' && d.invite_par.trim() ? d.invite_par.trim() : 'Un miembro de su familia'
    const fin = dateLongue(d.expire_le, PAROLE.locale)
    return {
      sujet: `${qui} le invita a unirse a su hogar en Rewayah Academy`,
      apercu: `${qui} le invita a seguir juntos las clases de la familia.`,
      titre: 'Tiene una invitación a un hogar',
      blocs: [
        { type: 'texte', texte: PAROLE.salutSeul },
        { type: 'texte', texte: `${qui} le invita a unirse a su hogar en Rewayah Academy, para seguir juntos las clases de la familia.` },
        { type: 'texte', texte: 'Inicie sesión con esta dirección de correo electrónico: la invitación le espera en la aplicación.' },
        { type: 'bouton', libelle: 'Abrir la invitación', href: `${APP}/connexion` },
        { type: 'note', texte: (fin ? `La invitación es válida hasta el ${fin}. ` : '') + 'Si no conoce a esta persona, ignore este mensaje.' },
      ],
    }
  },
  lien_inscription: (d) => {
    const quand = dateLongue(d.date_reponse, PAROLE.locale)
    const nom = typeof d.formulaire === 'string' && d.formulaire.trim() ? ` «${d.formulaire.trim()}»` : ''
    const rappel = `${quand ? `El ${quand} respondió` : 'Respondió'} a nuestro formulario${nom}.`
    return {
      sujet: 'Su candidatura a Rewayah Academy: cree su cuenta',
      apercu: rappel,
      titre: 'Su candidatura continúa en la aplicación',
      blocs: [
        { type: 'texte', texte: bonjour(d, PAROLE) },
        { type: 'texte', texte: rappel },
        { type: 'texte', texte: 'Este formulario servía para presentar su candidatura para enseñar el Corán en Rewayah Academy, en clases reducidas y por videollamada.' },
        { type: 'texte', texte: 'Las candidaturas se hacen ahora en la aplicación de Rewayah Academy, y sus respuestas ya están allí. Cree su cuenta con la misma dirección de correo electrónico que en el formulario: su candidatura se encontrará allí por sí sola.' },
        { type: 'bouton', libelle: 'Crear mi cuenta', href: `${APP}/inscription` },
        { type: 'texte', texte: 'Nada que pagar: presentar la candidatura y crear la cuenta son gratuitos. Ningún candidato paga, en ninguna etapa, y la academia nunca le pedirá dinero.' },
        { type: 'note', texte: 'Nunca le pediremos una contraseña ni un pago por mensaje. El enlace lleva a nuestra dirección oficial, app.rewayahacademy.com. Si no ha rellenado este formulario, ignore este mensaje.' },
      ],
    }
  },
  message_libre: (d) => libre(d, PAROLE.sujetLibre),
  nouvelles: (d) => libre(d, PAROLE.sujetLibre),
}

export const ESPAGNOL: LangueEcrite = {
  modeles: MODELES,
  raisons: RAISON,
  desinscription: 'Dejar de recibir estos correos',
}
