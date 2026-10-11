import {
  type AppelantRecherche,
  appelantRecherche,
} from "../_shared/recherche/appelant.ts";
import { lireCurseur, signerCurseur } from "../_shared/recherche/curseur.ts";

const domaine = "enseignants" as const;
const espaces = new Set(["famille", "eleve", "eleveGuide"]);
const UUID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const TTL_CURSEUR_S = 600;
const MAX_RESULTATS = 50;

interface GroupeEnseignant {
  groupe_id: string;
  teacher_id: string;
  teacher_prenom: string | null;
  teacher_titre: string | null;
  libelle: string;
}

function reponse(
  domaine: string,
  statut: string,
  details: Record<string, unknown> = {},
  code = 200,
): Response {
  return new Response(JSON.stringify({ domaine, statut, ...details }), {
    status: code,
    headers: { ...enTetesCors, "Content-Type": "application/json" },
  });
}

const enTetesCors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(corps: unknown, statut = 200): Response {
  return new Response(JSON.stringify(corps), {
    status: statut,
    headers: { ...enTetesCors, "Content-Type": "application/json" },
  });
}

export function normaliser(texte: string): string {
  return texte.normalize("NFKD")
    .replace(/[\u064b-\u065f\u0670\u0640]/gu, "")
    .replace(/\p{M}/gu, "")
    .toLocaleLowerCase("und")
    .replace(/[\u0622\u0623\u0625]/gu, "\u0627")
    .replace(/\u0649/gu, "\u064a")
    .replace(/[’'\-_]/gu, " ")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/gu, " ")
    .trim();
}

export function requeteValide(texte: unknown): string | null {
  if (typeof texte !== "string") return null;
  const normalisee = normaliser(texte);
  const longueur = Array.from(normalisee).length;
  const termes = normalisee.split(" ").filter(Boolean);
  if (longueur > 160 || termes.length === 0 || termes.length > 8) {
    return null;
  }
  if (
    longueur === 2 && termes.length === 1 &&
    /^\p{Script=Arabic}{2}$/u.test(normalisee)
  ) {
    return normalisee;
  }
  if (longueur < 3) return null;
  return normalisee;
}

function correspondNom(groupe: GroupeEnseignant, termes: string[]): boolean {
  const nom = normaliser(
    [groupe.teacher_titre, groupe.teacher_prenom].filter(Boolean).join(" "),
  );
  return termes.every((terme) => nom.includes(terme));
}

async function contexteAutorise(
  sql: AppelantRecherche["sql"],
  espace: string,
): Promise<"autorise" | "refuse" | "indisponible"> {
  if (!espaces.has(espace)) return "refuse";
  const [
    { data: actif, error: erreurActif },
    { data: role, error: erreurRole },
  ] = await Promise.all([
    sql.rpc("app_account_valid"),
    sql.rpc("app_role"),
  ]);
  if (erreurActif || erreurRole) return "indisponible";
  if (actif !== true) return "refuse";
  if (espace === "famille") return role === "guardian" ? "autorise" : "refuse";
  if (role === "student") return "autorise";
  if (role !== "guardian") return "refuse";
  const { data: autonome, error } = await sql.rpc("ma_capacite_eleve");
  if (error) return "indisponible";
  return autonome === true ? "autorise" : "refuse";
}

async function groupesVisibles(
  sql: AppelantRecherche["sql"],
): Promise<
  { data: GroupeEnseignant[] | null; error: { code?: string } | null }
> {
  const query = sql.from("mes_groupes_famille_v")
    .select("groupe_id,teacher_id,teacher_prenom,teacher_titre,libelle")
    .order("groupe_id", { ascending: true })
    .limit(MAX_RESULTATS + 1);
  return await query as unknown as {
    data: GroupeEnseignant[] | null;
    error: { code?: string } | null;
  };
}

async function traiter(requete: Request): Promise<Response> {
  if (requete.method === "OPTIONS") {
    return new Response("ok", { headers: enTetesCors });
  }
  if (requete.method !== "POST") {
    return reponse(domaine, "requeteInvalide", {}, 405);
  }
  const appelant = await appelantRecherche(requete);
  if (!appelant) return reponse(domaine, "sessionExpiree", {}, 401);

  let corps: Record<string, unknown>;
  try {
    const brut: unknown = await requete.json();
    if (typeof brut !== "object" || brut === null || Array.isArray(brut)) {
      return reponse(domaine, "requeteInvalide", {}, 400);
    }
    corps = brut as Record<string, unknown>;
  } catch {
    return reponse(domaine, "requeteInvalide", {}, 400);
  }

  if (
    Object.keys(corps).some((cle) =>
      !["action", "espace", "requete", "curseur", "limite"].includes(cle)
    )
  ) {
    return reponse(domaine, "requeteInvalide", {}, 400);
  }
  const action = corps.action;
  const espace = typeof corps.espace === "string" ? corps.espace : "";
  if (action !== "portees" && action !== "rechercher") {
    return reponse(domaine, "requeteInvalide", {}, 400);
  }
  const autorisation = await contexteAutorise(appelant.sql, espace);
  if (autorisation !== "autorise") {
    if (action === "portees" && autorisation === "refuse") {
      return json({ portees: [] });
    }
    if (autorisation === "indisponible") {
      return reponse(domaine, "indisponible", {}, 503);
    }
    return reponse(domaine, "contexteRevoque", {}, 403);
  }

  if (action === "portees") {
    const { data, error } = await groupesVisibles(appelant.sql);
    if (error) return reponse(domaine, "indisponible", {}, 503);
    return json({ portees: data?.length ? [domaine] : [] });
  }

  const requeteNormalisee = requeteValide(corps.requete);
  if (requeteNormalisee === null) {
    return reponse(domaine, "requeteInvalide", {}, 400);
  }
  const limite = corps.limite === undefined ? 5 : corps.limite;
  if (
    !Number.isInteger(limite) || (limite as number) < 1 ||
    (limite as number) > 20
  ) {
    return reponse(domaine, "requeteInvalide", {}, 400);
  }

  const secret = Deno.env.get("RECHERCHE_CURSOR_SECRET");
  if (!secret || new TextEncoder().encode(secret).length < 32) {
    return reponse(domaine, "indisponible", {}, 503);
  }
  const contexte = {
    version: 1 as const,
    domaine,
    sujet: appelant.id,
    espace,
    ordre: "groupe_id_asc" as const,
    requete: requeteNormalisee,
  };
  let apres: string | null = null;
  if (corps.curseur !== undefined && corps.curseur !== null) {
    if (typeof corps.curseur !== "string") {
      return reponse(domaine, "curseurPerime", {}, 400);
    }
    const charge = await lireCurseur(corps.curseur, secret, contexte);
    if (!charge) return reponse(domaine, "curseurPerime", {}, 400);
    apres = charge.apres;
  }

  const { data, error } = await groupesVisibles(appelant.sql);
  if (error) {
    return reponse(
      domaine,
      error.code === "42501" ? "contexteRevoque" : "indisponible",
      {},
      error.code === "42501" ? 403 : 503,
    );
  }
  if (!data?.length) return reponse(domaine, "contexteRevoque", {}, 403);
  if (data.length > MAX_RESULTATS) return reponse(domaine, "limite", {}, 429);

  const termes = requeteNormalisee.split(" ");
  const resultats = data
    .filter((groupe) =>
      groupe.groupe_id > (apres ?? "00000000-0000-0000-0000-000000000000")
    )
    .filter((groupe) => Boolean(groupe.teacher_prenom?.trim()))
    .filter((groupe) => correspondNom(groupe, termes))
    .map((groupe) => ({
      type: "enseignant",
      reference: groupe.teacher_id,
      titre: [groupe.teacher_titre, groupe.teacher_prenom].filter(Boolean).join(
        " ",
      ),
      contexte: `Enseignant de la classe ${groupe.libelle}`,
      extrait: null,
      cible: { kind: "enseignant", reference: groupe.teacher_id },
      _apres: groupe.groupe_id,
    }));
  const page = resultats.slice(0, limite as number);
  const aPlus = resultats.length > page.length;
  const cursor = aPlus && page.length
    ? await signerCurseur({
      ...contexte,
      apres: page[page.length - 1]._apres,
      expireLe: Math.floor(Date.now() / 1000) + TTL_CURSEUR_S,
    }, secret)
    : null;
  return reponse(domaine, "ok", {
    elements: page.map(({ _apres: _ignored, ...resultat }) => resultat),
    curseurSuivant: cursor,
    aPlus,
  });
}

if (import.meta.main) {
  Deno.serve(async (requete) => {
    try {
      return await traiter(requete);
    } catch {
      return reponse(domaine, "indisponible", {}, 503);
    }
  });
}
