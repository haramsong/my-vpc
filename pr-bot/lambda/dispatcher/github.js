import crypto from "crypto";
import { App } from "@octokit/app";
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

export async function createInstallationToken({ installationId }) {
  const privateKey = await getParameter(
    process.env.GITHUB_APP_PRIVATE_KEY_SSM_NAME
  );

  const app = new App({
    appId: process.env.GITHUB_APP_ID,
    privateKey,
  });

  const octokit = await app.getInstallationOctokit(installationId);

  const {
    data: { token },
  } = await octokit.request(
    "POST /app/installations/{installation_id}/access_tokens",
    { installation_id: installationId }
  );

  return token;
}