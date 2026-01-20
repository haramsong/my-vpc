import crypto from "crypto";
import { getParameter } from "./ssm.js";

export async function verifyGithubSignature({ rawBody, signature }) {
  const secretName = process.env.WEBHOOK_SECRET_SSM_NAME;
  const secret = await getParameter(secretName);

  const hmac = crypto
    .createHmac("sha256", secret)
    .update(rawBody)
    .digest("hex");

  const expected = `sha256=${hmac}`;
  return crypto.timingSafeEqual(
    Buffer.from(expected),
    Buffer.from(signature || "")
  );
}