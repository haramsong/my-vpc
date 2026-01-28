import {
  verifyGithubSignature,
  createInstallationToken,
} from "./github.js";
import { invokeStep } from "./invoke.js";
import { claimDeliveryId } from "./dedupe.js";
import { createPendingChecks } from "step-common/check.js";

export async function handler(event) {
  try {
    const headers = event.headers || {};
    const githubEvent = headers["x-github-event"];
    const deliveryId = headers["x-github-delivery"];
    const signature = headers["x-hub-signature-256"];

    console.log("[dispatcher] event received", {
      githubEvent,
      deliveryId,
    });

    const rawBody = event.isBase64Encoded
      ? Buffer.from(event.body, "base64")
      : Buffer.from(event.body || "");

    // 1️⃣ GitHub webhook signature 검증
    const valid = await verifyGithubSignature({ rawBody, signature });
    if (!valid) {
      console.warn("Invalid GitHub signature", deliveryId);
      return response(401, "invalid signature");
    }

    // 2️⃣ delivery 중복 제거
    const okToProcess = await claimDeliveryId(deliveryId);
    if (!okToProcess) {
      console.log("Duplicate delivery ignored:", deliveryId);
      return ok();
    }

    const payload = JSON.parse(rawBody.toString("utf-8"));

    console.log("[dispatcher] payload summary", {
      event: githubEvent,
      action: payload.action,
      workflowName: payload.workflow_run?.name,
      workflowStatus: payload.workflow_run?.status,
      workflowConclusion: payload.workflow_run?.conclusion,
      hasPullRequests: payload.workflow_run?.pull_requests?.length ?? 0,
    });
    /**
     * ======================================
     * pull_request 이벤트
     *  - pending check만 생성
     * ======================================
     */
    if (githubEvent === "pull_request") {
      console.log("[dispatcher] pull_request event detected");
      const action = payload.action;
      if (!["opened", "reopened", "synchronize"].includes(action)) {
        return ok();
      }

      const installationId = payload.installation.id;
      const githubToken = await createInstallationToken({ installationId });

      await createPendingChecks({
        githubToken,
        owner: payload.repository.owner.login,
        repo: payload.repository.name,
        headSha: payload.pull_request.head.sha,
        checks: [
          "lint / eslint",
          "test / coverage",
          "dependency / license",
        ]
      });

      return ok();
    }

    /**
     * ======================================
     * workflow_run 이벤트
     *  - PR workflow 완료 후 step 실행
     * ======================================
     */
    if (githubEvent === "workflow_run") {
      console.log("[dispatcher] workflow_run event detected");
      const run = payload.workflow_run;

      // completed 아닌 경우 무시
      if (run.status !== "completed") {
        console.log("[dispatcher] workflow not completed yet", run.status);
        return ok();
      }

      // PR에서 실행된 workflow만 처리
      if (!run.pull_requests || run.pull_requests.length === 0) {
        console.log("[dispatcher] workflow has no pull_requests, ignored");
        return ok(); // merge / push workflow
      }

      const pr = run.pull_requests[0];
      const installationId = payload.installation.id;
      const githubToken = await createInstallationToken({ installationId });

      const ctx = {
        repository: {
          owner: payload.repository.owner.login,
          name: payload.repository.name,
        },
        pullRequest: {
          number: pr.number,
          headSha: run.head_sha,
        },
        githubToken,
        workflowRunId: run.id,
        workflowName: run.name,
      };

      console.log("[dispatcher] invoking step", {
        workflow: run.name,
        step:
          run.name === "lint"
            ? process.env.STEP_LINT_FUNCTION
            : run.name === "test"
              ? process.env.STEP_TEST_FUNCTION
              : run.name === "dependency"
                ? process.env.STEP_DEPENDENCY_FUNCTION
                : "unknown",
        ctx,
      });

      // workflow 이름 기준으로 step 라우팅
      if (run.name === "lint") {
        await invokeStep(process.env.STEP_LINT_FUNCTION, ctx);
      }

      if (run.name === "test") {
        await invokeStep(process.env.STEP_TEST_FUNCTION, ctx);
      }

      if (run.name === "dependency") {
        await invokeStep(process.env.STEP_DEPENDENCY_FUNCTION, ctx);
      }

      return ok();
    }

    return ok();
  } catch (err) {
    console.error("dispatcher error", err);
    // webhook retry 폭탄 방지
    return ok();
  }
}

function ok() {
  return response(200, "ok");
}

function response(statusCode, body) {
  return { statusCode, body };
}