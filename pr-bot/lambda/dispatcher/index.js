import { verifyGithubSignature } from "./github.js";
import { invokeStep } from "./invoke.js";
import { claimDeliveryId } from "./dedupe.js";

export async function handler(event) {
  try {
    // HTTP API v2
    const headers = event.headers || {};
    const githubEvent = headers["x-github-event"];
    const deliveryId = headers["x-github-delivery"];
    const signature = headers["x-hub-signature-256"];

    const rawBody = event.isBase64Encoded
      ? Buffer.from(event.body, "base64")
      : Buffer.from(event.body || "");

    // 1️⃣ 서명 검증
    const valid = await verifyGithubSignature({
      rawBody,
      signature,
    });

    if (!valid) {
      console.warn("Invalid GitHub signature", deliveryId);
      return { statusCode: 401, body: "invalid signature" };
    }

    const okToProcess = await claimDeliveryId(deliveryId);

    if (!okToProcess) {
      console.log("Duplicate delivery ignored:", deliveryId);
      return ok(); // ✅ 중복이면 step 실행 안 하고 바로 200
    }

    const payload = JSON.parse(rawBody.toString("utf-8"));
    const action = payload.action;

    // 지금은 PR 이벤트만 처리
    if (githubEvent !== "pull_request") {
      return ok();
    }

    if (!["opened", "synchronize", "reopened"].includes(action)) {
      return ok();
    }

    // 2️⃣ 공통 컨텍스트 생성
    const ctx = {
      deliveryId,
      event: githubEvent,
      action,
      repository: {
        owner: payload.repository.owner.login,
        name: payload.repository.name,
      },
      pullRequest: {
        number: payload.pull_request.number,
        headSha: payload.pull_request.head.sha,
      },
    };

    // 3️⃣ step 라우팅
    const steps = [];

    if (action === "opened") {
      steps.push(
        process.env.STEP_LINT_FUNCTION,
        process.env.STEP_TEST_FUNCTION,
        process.env.STEP_DEPENDENCY_FUNCTION,
        // process.env.STEP_REVIEW_FUNCTION
      );
    }

    if (action === "synchronize") {
      steps.push(
        process.env.STEP_LINT_FUNCTION,
        process.env.STEP_TEST_FUNCTION
      );
    }

    // 4️⃣ 비동기 invoke
    await Promise.all(
      steps.map((fn) => invokeStep(fn, ctx))
    );

    return ok();
  } catch (err) {
    console.error("dispatcher error", err);
    // ❗ webhook retry 폭탄 방지
    return ok();
  }
}

function ok() {
  return {
    statusCode: 200,
    body: "ok",
  };
}