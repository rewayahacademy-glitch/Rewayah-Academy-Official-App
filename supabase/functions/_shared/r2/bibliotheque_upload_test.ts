import { assertEquals } from "jsr:@std/assert@1";
import {
  detecterMimeReel,
  mimeAnnonceAutorise,
  sha256Hex,
} from "./bibliotheque_upload.ts";

Deno.test("upload bibliotheque: bornes des types et finalites", () => {
  assertEquals(
    mimeAnnonceAutorise("image/png", 10 * 1024 * 1024, "support"),
    true,
  );
  assertEquals(
    mimeAnnonceAutorise("image/png", 10 * 1024 * 1024 + 1, "support"),
    false,
  );
  assertEquals(
    mimeAnnonceAutorise("application/pdf", 50 * 1024 * 1024, "preuve"),
    true,
  );
  assertEquals(mimeAnnonceAutorise("audio/ogg", 1, "preuve"), false);
  assertEquals(mimeAnnonceAutorise("application/zip", 1, "support"), false);
});

Deno.test("upload bibliotheque: detection par signature binaire", () => {
  assertEquals(
    detecterMimeReel(
      new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    ),
    "image/png",
  );
  assertEquals(
    detecterMimeReel(new TextEncoder().encode("%PDF-1.7")),
    "application/pdf",
  );
  assertEquals(detecterMimeReel(new TextEncoder().encode("OggS")), "audio/ogg");
  assertEquals(detecterMimeReel(new TextEncoder().encode("not a pdf")), null);
});

Deno.test("upload bibliotheque: SHA-256 de reference", async () => {
  assertEquals(
    await sha256Hex(new TextEncoder().encode("abc")),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  );
});
