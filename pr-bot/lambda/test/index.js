import { withStep } from "step-common/handler.js";
import { getCoverageSummaryFromWorkflow } from "step-common/github.js";

export const handler = withStep({
  name: "test / coverage",

  async run({ event, octokit }) {
    const { repository, workflowRunId } = event;

    const summary = await getCoverageSummaryFromWorkflow({
      octokit,
      owner: repository.owner,
      repo: repository.name,
      runId: workflowRunId,
    });

    // ✅ coverage 자체가 없음
    if (!summary) {
      return {
        conclusion: "neutral",
        title: "Tests skipped",
        summary: `
이 저장소에는 테스트 또는 coverage 설정이 없습니다.

- test script 없음
- coverage artifact 없음
        `.trim(),
      };
    }

    const lines = summary.lines.pct;

    // 정책
    if (lines < 70) {
      return {
        conclusion: "failure",
        title: "Low coverage",
        summary: `라인 커버리지가 낮습니다: ${lines}%`,
      };
    }

    return {
      conclusion: "success",
      title: "Coverage OK",
      summary: `라인 커버리지: ${lines}%`,
    };
  },
});