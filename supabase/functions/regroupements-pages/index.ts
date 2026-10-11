import { appelantR2 } from "../_shared/r2/client_appelant.ts";
import { enTetesCors, json, refus } from "../_shared/clients.ts";

type Ligne = Record<string, unknown>;
type Etat = "aFinir" | "pret" | "incomplet";

function entier(value: unknown, fallback: number): number {
  return typeof value === "number" && Number.isInteger(value)
    ? value
    : fallback;
}

function etat(ligne: Ligne): Etat {
  if (ligne.classe != null) return "aFinir";
  return entier(ligne.nombre_eleves, 0) >= entier(ligne.quota, 1)
    ? "pret"
    : "incomplet";
}

function normaliser(value: string): string {
  return value.normalize("NFKD").replace(/\p{M}/gu, "").toLocaleLowerCase(
    "und",
  );
}

function occurrences(ligne: Ligne): Array<Record<string, unknown>> {
  return Array.isArray(ligne.occurrences)
    ? ligne.occurrences.filter((item): item is Record<string, unknown> =>
      item !== null && typeof item === "object" && !Array.isArray(item)
    )
    : [];
}

function tri(a: Ligne, b: Ligne): number {
  const ordre: Record<Etat, number> = { aFinir: 0, pret: 1, incomplet: 2 };
  const state = ordre[etat(a)] - ordre[etat(b)];
  if (state !== 0) return state;
  const eleves = entier(b.nombre_eleves, 0) - entier(a.nombre_eleves, 0);
  if (eleves !== 0) return eleves;
  const ao = occurrences(a)[0] ?? {};
  const bo = occurrences(b)[0] ?? {};
  const jour = entier(ao.jour_iso, 8) - entier(bo.jour_iso, 8);
  if (jour !== 0) return jour;
  const heure = entier(ao.heure, 24) - entier(bo.heure, 24);
  if (heure !== 0) return heure;
  return String(a.regroupement_id ?? "").localeCompare(
    String(b.regroupement_id ?? ""),
  );
}

function correspond(ligne: Ligne, texte: string): boolean {
  if (!texte) return true;
  const classe = ligne.classe !== null && typeof ligne.classe === "object"
    ? ligne.classe as Record<string, unknown>
    : {};
  const champs = normaliser(
    [
      ligne.langue_nom,
      ligne.langue_code,
      ligne.fuseau_iana,
      classe.libelle,
      classe.code_court,
    ].filter((v): v is string => typeof v === "string").join(" "),
  );
  return texte.split(/\s+/).every((terme) => champs.includes(terme));
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: enTetesCors });
  }
  if (request.method !== "POST") return refus("methode non autorisee", 405);

  const compte = await appelantR2(request);
  if (!compte) return refus("authentification requise", 401);

  let body: Record<string, unknown>;
  try {
    const raw: unknown = await request.json();
    if (raw === null || typeof raw !== "object" || Array.isArray(raw)) {
      return refus("requete invalide");
    }
    body = raw as Record<string, unknown>;
  } catch {
    return refus("corps illisible");
  }

  const keys = new Set([
    "texte",
    "public",
    "etat",
    "jour",
    "heure",
    "fuseau",
    "page",
    "taille",
  ]);
  if (Object.keys(body).some((key) => !keys.has(key))) {
    return refus("requete invalide");
  }
  const texte = typeof body.texte === "string" ? body.texte.trim() : "";
  if (texte.length > 160 || texte.split(/\s+/).filter(Boolean).length > 8) {
    return refus("requete invalide");
  }
  if (
    body.public != null && !["enfant", "adulte"].includes(String(body.public))
  ) return refus("requete invalide");
  if (
    body.etat != null &&
    !["aFinir", "pret", "incomplet"].includes(String(body.etat))
  ) return refus("requete invalide");
  const jour = body.jour == null ? null : entier(body.jour, -1);
  const heure = body.heure == null ? null : entier(body.heure, -1);
  if (jour != null && (jour < 1 || jour > 7)) return refus("requete invalide");
  if (heure != null && (heure < 0 || heure > 23)) {
    return refus("requete invalide");
  }
  const page = entier(body.page, 1);
  const taille = entier(body.taille, 25);
  if (page < 1 || taille < 1 || taille > 100 || (page - 1) * taille > 100000) {
    return refus("requete invalide");
  }

  if (body.fuseau != null && typeof body.fuseau !== "string") {
    return refus("requete invalide");
  }
  const fuseau = body.fuseau as string | null | undefined;
  if (fuseau) {
    try {
      new Intl.DateTimeFormat("en", { timeZone: fuseau });
    } catch {
      return refus("requete invalide");
    }
  }

  const { data, error } = await compte.sql.rpc("regroupements_c11bis_admin");
  if (error || !Array.isArray(data)) return refus("liste indisponible", 503);
  const tous = data.filter((row): row is Ligne =>
    row !== null && typeof row === "object" && !Array.isArray(row)
  );

  const axes = tous.filter((row) => {
    if (body.public != null && row.type_public !== body.public) return false;
    if (
      jour != null &&
      !occurrences(row).some((o) => entier(o.jour_iso, -1) === jour)
    ) return false;
    if (
      heure != null &&
      !occurrences(row).some((o) => entier(o.heure, -1) === heure)
    ) return false;
    if (fuseau != null && row.fuseau_iana !== fuseau) return false;
    return correspond(row, normaliser(texte));
  });
  const compteurs: Record<Etat, number> = { aFinir: 0, pret: 0, incomplet: 0 };
  for (const row of axes) compteurs[etat(row)] += 1;

  const filtres = body.etat == null
    ? axes
    : axes.filter((row) => etat(row) === body.etat);
  filtres.sort(tri);
  const debut = (page - 1) * taille;
  return json({
    lignes: filtres.slice(debut, debut + taille),
    total: filtres.length,
    page,
    taille,
    compteurs,
    jours: [
      ...new Set(
        tous.flatMap((row) =>
          occurrences(row).map((o) => entier(o.jour_iso, -1)).filter((n) =>
            n >= 1 && n <= 7
          )
        ),
      ),
    ].sort((a, b) => a - b),
    heures: [
      ...new Set(
        tous.flatMap((row) =>
          occurrences(row).map((o) => entier(o.heure, -1)).filter((n) =>
            n >= 0 && n <= 23
          )
        ),
      ),
    ].sort((a, b) => a - b),
    fuseaux: [
      ...new Set(
        tous.map((row) => row.fuseau_iana).filter((v): v is string =>
          typeof v === "string"
        ),
      ),
    ].sort(),
    total_sans_filtre: tous.length,
    demandes_sans_filtre: tous.reduce(
      (n, row) => n + entier(row.nombre_eleves, 0),
      0,
    ),
  });
});
