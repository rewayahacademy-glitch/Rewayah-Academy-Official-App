export type SuiviAgent = {
  id: string
  titre: string
  type: string
  debut: number
  fin?: number
  etat: 'en cours' | 'terminé' | 'échec' | 'arrêté'
  etapes: number
  outils: number
  derniereAction: string
  tokensEntree: number
  tokensSortie: number
}

declare module 'claude-code' {
  interface PluginState {
    'agents-actifs': { agents: SuiviAgent[]; principal: SuiviAgent; battement: number }
  }
}
