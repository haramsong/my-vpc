import { ensureCheckRun, completeCheck, splitAnnotations } from "./check.js";
import { getInstallationOctokit } from "./github.js"

export function withStep({ name, run }) {
  return async function handler(event) {
    const { repository, pullRequest } = event;

    const octokit = await getInstallationOctokit({
      owner: repository.owner,
      repo: repository.name,
    });

    // ✅ idempotent Check Run
    const checkRunId = await ensureCheckRun({
      octokit,
      owner: repository.owner,
      repo: repository.name,
      name,
      headSha: pullRequest.headSha,
    });

    try {
      const result = await run({ event, octokit });

      const { annotations, truncated, restCount } =
        splitAnnotations(result.annotations);

      let summary = result.summary ?? "";
      if (truncated) {
        summary += `\n\n⚠️ 표시되지 않은 annotation ${restCount}개가 더 있습니다.`;
      }

      await completeCheck({
        octokit,
        owner: repository.owner,
        repo: repository.name,
        checkRunId,
        conclusion: result.conclusion ?? "success",
        title: result.title ?? `${name} result`,
        summary,
        annotations,
      });
    } catch (e) {
      await completeCheck({
        octokit,
        owner: repository.owner,
        repo: repository.name,
        checkRunId,
        conclusion: "failure",
        title: `${name} failed`,
        summary: e.message ?? "unknown error",
      });
    }
  };
}