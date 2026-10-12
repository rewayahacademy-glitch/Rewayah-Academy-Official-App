import {
  assertEquals,
  assertNotEquals,
  assertRejects,
} from "jsr:@std/assert";
import { signatureConfirmationUpload } from "./confirmation_hmac.ts";

Deno.test("confirmation HMAC binds intent, hash and size", async () => {
  const secret = "test-only-confirmation-secret-32-bytes-minimum";
  const signature = await signatureConfirmationUpload(
    secret,
    "aaaaaaaa-0000-0000-0000-000000000001",
    "b".repeat(64),
    1234,
  );

  assertEquals(signature.length, 64);
  assertNotEquals(
    signature,
    await signatureConfirmationUpload(
      secret,
      "aaaaaaaa-0000-0000-0000-000000000002",
      "b".repeat(64),
      1234,
    ),
  );
  assertNotEquals(
    signature,
    await signatureConfirmationUpload(
      secret,
      "aaaaaaaa-0000-0000-0000-000000000001",
      "b".repeat(64),
      1235,
    ),
  );
});

Deno.test("confirmation HMAC rejects short secrets and malformed data", async () => {
  await assertRejects(() =>
    signatureConfirmationUpload(
      "short",
      "aaaaaaaa-0000-0000-0000-000000000001",
      "b".repeat(64),
      1234,
    )
  );
  await assertRejects(() =>
    signatureConfirmationUpload(
      "test-only-confirmation-secret-32-bytes-minimum",
      "not-an-id",
      "b".repeat(64),
      1234,
    )
  );
});
