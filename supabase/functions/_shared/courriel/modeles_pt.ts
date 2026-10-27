// Les e-mails en portugais, ecrits a la main (portugais europeen, tournures
// neutres). Ils suivent le sens du francais (`modeles_fr.ts`) ; memes liens,
// memes boutons. Competence `mots-rewayah`.

import { APP } from './gabarit.ts'
import { avisDans, bonjour, dateLongue, type Fabrique, type LangueEcrite, libre, type Parole } from './outils.ts'
import { quandSeance } from './modeles_fr.ts'

const PAROLE: Parole = {
  salut: 'Olá',
  fin: ',',
  salutSeul: 'Olá,',
  note: 'O detalhe encontra-se na aplicação, depois de iniciar sessão.',
  sujetLibre: 'Uma mensagem da Rewayah Academy',
  locale: 'pt-PT',
}
const avis = avisDans(PAROLE)

const RAISON: Record<string, string> = {
  compte: 'Recebe este e-mail porque diz respeito à sua conta da Rewayah Academy.',
  inscription: 'Recebe este e-mail porque diz respeito a um pedido feito na Rewayah Academy.',
  classes: 'Recebe este e-mail porque diz respeito a uma turma que frequenta ou leciona.',
  facturation: 'Recebe este e-mail porque diz respeito à faturação do seu agregado familiar.',
  recrutement: 'Recebe este e-mail porque está em contacto com o nosso recrutamento.',
  direction: 'Recebe este e-mail da direção da Rewayah Academy.',
  nouvelles: 'Recebe este e-mail porque acompanha as novidades da Rewayah Academy.',
}

const MODELES: Record<string, Fabrique> = {
  demande_recue: (d) => avis(d, 'Recebemos o seu pedido', 'Recebemos o seu pedido',
    'Recebemos o seu pedido de horário. A direção avalia o pedido e responde na aplicação.',
    'Acompanhar o meu pedido', '/tuteur/demandes'),
  demande_presentation: (d) => avis(d, 'Foi recebido um pedido de apresentação', 'Pedido de apresentação recebido',
    'Foi recebido um pedido de apresentação. Está à sua espera na aplicação.',
    'Abrir o pedido', '/tuteur/demandes'),
  classe_validee: (d) => avis(d, 'A sua turma está pronta', 'A sua turma está pronta',
    'A turma correspondente ao seu pedido está pronta. Falta atribuir-lhe o docente; será avisado.',
    'Ver a turma', '/tuteur/demandes'),
  enseignant_affecte: (d) => avis(d, 'Foi atribuído um docente à turma', 'A sua turma já tem docente',
    'Foi atribuído um docente à turma. Encontra o nome e os horários na aplicação.',
    'Ver a turma', '/tuteur/demandes'),
  demande_close: (d) => avis(d, 'O seu pedido foi encerrado', 'O seu pedido foi encerrado',
    'O seu pedido de horário foi encerrado. A resposta da direção está na aplicação.',
    'Ler a resposta', '/tuteur/demandes'),
  classe_changee: (d) => avis(d, 'Mudança de turma, mesmo horário', 'Mudança de turma',
    'Um aluno do seu agregado familiar passou para outra turma, no mesmo horário.',
    'Ver o detalhe', '/tuteur/demandes'),
  // Ficha de 27/10/2026, linha 15: os nove eventos de turmas e sessões.
  classe_creee: (d) => avis(d, 'A sua turma está criada', 'A sua turma está criada',
    'Acaba de ser criada uma turma. O horário e o professor estão na aplicação.',
    'Ver o horário', '/tuteur'),
  enseignant_change: (d) => avis(d, 'O professor da turma muda', 'O professor da turma muda',
    'Outro professor assume a turma, no mesmo horário. O nome está na aplicação.',
    'Ver a turma', '/tuteur'),
  eleve_inscrit: (d) => avis(d, 'Um aluno junta-se à sua turma', 'Um aluno junta-se à sua turma',
    'Um aluno junta-se à sua turma. A ficha está na aplicação.',
    'Ver as minhas turmas', '/enseignant/classes'),
  eleve_retire: (d) => avis(d, 'Um aluno deixa a sua turma', 'Um aluno deixa a sua turma',
    'Um aluno deixa a sua turma. A lista atualizada está na aplicação.',
    'Ver as minhas turmas', '/enseignant/classes'),
  creneau_change: (d) => avis(d, 'O horário da turma muda', 'O horário da turma muda',
    'O horário da turma muda. O novo horário está na aplicação.',
    'Ver o novo horário', '/tuteur'),
  seance_annulee: (d) => {
    const quand = quandSeance(d, 'pt-PT', 'às')
    return avis(d, 'Uma sessão está anulada', 'Uma sessão está anulada',
      quand ? `A sessão de ${quand} está anulada.` : 'Uma sessão da turma está anulada.',
      'Ver o planeamento', '/tuteur')
  },
  seance_deplacee: (d) => {
    const quand = quandSeance(d, 'pt-PT', 'às')
    return avis(d, 'Uma sessão foi adiada', 'Uma sessão foi adiada',
      quand ? `Uma sessão passa para ${quand}.` : 'Uma sessão da turma passa para outro horário. O novo horário está na aplicação.',
      'Ver o novo horário', '/tuteur')
  },
  enseignante_absente: (d) => {
    const quand = quandSeance(d, 'pt-PT', 'às')
    return avis(d, 'O professor está ausente numa sessão', 'O professor está ausente numa sessão',
      (quand ? `O professor está ausente na sessão de ${quand}.` : 'O professor está ausente numa sessão da turma.')
        + ' A direção mantém-no informado.',
      'Ver o planeamento', '/tuteur')
  },
  classe_supprimee: (d) => avis(d, 'A turma está encerrada', 'A turma está encerrada',
    'A turma está encerrada. A direção entra em contacto consigo sobre o que se segue.',
    'Abrir a aplicação', '/tuteur'),
  remplacement_propose: (d) => avis(d, 'É-lhe proposta uma substituição', 'É-lhe proposta uma substituição',
    'É-lhe proposta a substituição de uma aula. Responda na aplicação para que a turma fique assegurada.',
    'Ver a substituição', '/enseignant/journee/remplacements'),
  remplacement_pris: (d) => avis(d, 'A substituição foi atribuída', 'A substituição foi atribuída',
    'A substituição da aula foi atribuída.',
    'Ver o meu dia', '/enseignant/journee/remplacements'),
  controle_mission_attribuee: (d) => avis(d, 'Foi-lhe atribuída uma missão de controlo', 'Nova missão de controlo',
    'Foi-lhe atribuída uma missão de controlo.', 'Abrir a missão', '/controleur'),
  controle_mission_non_controlee: (d) => avis(d, 'Uma missão ficou sem verificação', 'Missão sem verificação',
    'Uma missão de controlo ficou sem verificação.', 'Ver os sorteios', '/admin/securite-audit/tirages'),
  paiement_relance: (d) => {
    const j = typeof d.jours_avant === 'number' ? d.jours_avant : null
    const quand = j === null ? 'em breve' : j === 0 ? 'hoje' : j === 1 ? 'amanhã' : `dentro de ${j} dias`
    return avis(d, `Um pagamento vence ${quand}`, 'Um pagamento está a vencer',
      `O pagamento do mês vence ${quand}. Efetua-se na aplicação, na secção Pagamentos, para que as aulas continuem sem interrupção.`,
      'Efetuar o pagamento', '/tuteur/foyer/recharge')
  },
  acces_suspendu_paiement: (d) => avis(d, 'Um acesso está suspenso', 'Um acesso está suspenso',
    'O pagamento do mês não foi recebido: o acesso à turma está suspenso. Volta assim que o pagamento for recebido.',
    'Efetuar o pagamento', '/tuteur/foyer/recharge'),
  acces_retabli_paiement: (d) => avis(d, 'O acesso foi restabelecido', 'O acesso foi restabelecido',
    'O pagamento foi recebido: o acesso à turma foi restabelecido.', 'Abrir a aplicação', '/tuteur/foyer/recharge'),
  invitation_foyer: (d) => {
    const qui = typeof d.invite_par === 'string' && d.invite_par.trim() ? d.invite_par.trim() : 'Um membro da sua família'
    const fin = dateLongue(d.expire_le, PAROLE.locale)
    return {
      sujet: `${qui} enviou-lhe um convite para o agregado familiar na Rewayah Academy`,
      apercu: `${qui} enviou-lhe um convite para acompanharem juntos as aulas da família.`,
      titre: 'Tem um convite para um agregado familiar',
      blocs: [
        { type: 'texte', texte: PAROLE.salutSeul },
        { type: 'texte', texte: `${qui} enviou-lhe um convite para se juntar ao respetivo agregado familiar na Rewayah Academy, para acompanharem juntos as aulas da família.` },
        { type: 'texte', texte: 'Inicie sessão com este endereço de e-mail: o convite está à sua espera na aplicação.' },
        { type: 'bouton', libelle: 'Abrir o convite', href: `${APP}/connexion` },
        { type: 'note', texte: (fin ? `O convite é válido até ${fin}. ` : '') + 'Se não conhecer esta pessoa, ignore esta mensagem.' },
      ],
    }
  },
  lien_inscription: (d) => {
    const quand = dateLongue(d.date_reponse, PAROLE.locale)
    const nom = typeof d.formulaire === 'string' && d.formulaire.trim() ? ` «${d.formulaire.trim()}»` : ''
    const rappel = `${quand ? `Em ${quand}, respondeu` : 'Respondeu'} ao nosso formulário${nom}.`
    return {
      sujet: 'A sua candidatura à Rewayah Academy: crie a sua conta',
      apercu: rappel,
      titre: 'A sua candidatura continua na aplicação',
      blocs: [
        { type: 'texte', texte: bonjour(d, PAROLE) },
        { type: 'texte', texte: rappel },
        { type: 'texte', texte: 'Este formulário servia para apresentar a sua candidatura para ensinar o Alcorão na Rewayah Academy, em turmas pequenas e por vídeo.' },
        { type: 'texte', texte: 'As candidaturas fazem-se agora na aplicação da Rewayah Academy, e as suas respostas já lá estão. Crie a sua conta com o mesmo endereço de e-mail do formulário: a sua candidatura será encontrada automaticamente.' },
        { type: 'bouton', libelle: 'Criar a minha conta', href: `${APP}/inscription` },
        { type: 'texte', texte: 'Nada a pagar: candidatar-se e criar a conta são gratuitos. Nenhum candidato paga, em nenhuma fase, e a academia nunca lhe pedirá dinheiro.' },
        { type: 'note', texte: 'Nunca lhe pediremos uma palavra-passe nem um pagamento por mensagem. A ligação conduz ao nosso endereço oficial, app.rewayahacademy.com. Se não preencheu este formulário, ignore esta mensagem.' },
      ],
    }
  },
  message_libre: (d) => libre(d, PAROLE.sujetLibre),
  nouvelles: (d) => libre(d, PAROLE.sujetLibre),
}

export const PORTUGAIS: LangueEcrite = {
  modeles: MODELES,
  raisons: RAISON,
  desinscription: 'Deixar de receber estes e-mails',
}
