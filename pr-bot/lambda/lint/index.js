import { withStep } from "step-common/handler.js";
import { getLintReportFromWorkflow } from "step-common/github.js";

export const handler = withStep({
  name: "lint / eslint",

  async run({ event, octokit }) {
    const { repository, workflowRunId } = event;

    // 1️⃣ eslint 결과 로드 (workflowRunId 기준)
    const report = await getLintReportFromWorkflow({
      octokit,
      owner: repository.owner,
      repo: repository.name,
      runId: workflowRunId,
    });

    if (!report) {
      return {
        conclusion: "neutral",
        title: "Lint skipped",
        summary: "eslint artifact를 찾지 못했습니다.",
      };
    }

    const annotations = [];
    let errorCount = 0;
    let warningCount = 0;

    for (const file of report) {
      for (const msg of file.messages) {
        const level =
          msg.severity === 2 ? "failure" : "warning";

        if (msg.severity === 2) errorCount++;
        if (msg.severity === 1) warningCount++;

        annotations.push({
          path: file.filePath,
          start_line: msg.line || 1,
          end_line: msg.endLine || msg.line || 1,
          annotation_level: level,
          message: msg.message,
        });
      }
    }

    if (errorCount > 0) {
      return {
        conclusion: "failure",
        title: "Lint errors",
        summary: `❌ ESLint error ${errorCount}개\n⚠️ warning ${warningCount}개`,
        annotations,
      };
    }

    if (warningCount > 0) {
      return {
        conclusion: "neutral",
        title: "Lint warnings",
        summary: `⚠️ ESLint warning ${warningCount}개`,
        annotations,
      };
    }

    return {
      conclusion: "success",
      title: "Lint passed",
      summary: "ESLint 오류 및 경고 없음",
    };
  },
});