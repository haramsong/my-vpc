import { getCoverageSummaryFromWorkflow } from "step-common/github.js";

const COVERAGE_DROP_FAIL = 5; // %p
const COVERAGE_DROP_WARN = 1; // %p

export const handler = withStep({
  name: "test / coverage",

  async run({ event, octokit }) {
    const { repository, pullRequest } = event;

    // head coverage
    const head = await getCoverageSummaryFromWorkflow({
      octokit,
      owner: repository.owner,
      repo: repository.name,
      headSha: pullRequest.headSha,
      workflowName: "test",
    });

    if (!head) {
      return {
        conclusion: "neutral",
        title: "Coverage missing",
        summary: `
        Coverage artifact를 찾지 못했습니다.

        아래와 같이 GitHub Actions 설정이 필요합니다:

        \`\`\`yaml
        name: test

        on:
          pull_request:

        jobs:
          test:
            runs-on: ubuntu-latest
            steps:
              - uses: actions/checkout@v4

              - uses: actions/setup-node@v4
                with:
                  node-version: 20

              - run: npm ci
              - run: npm test -- --coverage --coverageReporters=json-summary

              - uses: actions/upload-artifact@v4
                with:
                  name: coverage
                  path: coverage/coverage-summary.json
        \`\`\`

        확인 사항:
        - upload-artifact step 존재 여부
        - artifact name: \`coverage\`
        - path: \`coverage/coverage-summary.json\`
        `.trim(),
      };
    }

    // base coverage
    const base = await getCoverageSummaryFromWorkflow({
      octokit,
      owner: repository.owner,
      repo: repository.name,
      headSha: pullRequest.baseSha,
      workflowName: "test",
    });

    const headLines = head.lines.pct;
    const baseLines = base?.lines?.pct;

    let diffLine = "";
    let conclusion = "success";

    if (typeof baseLines === "number") {
      const diff = +(headLines - baseLines).toFixed(2);

      diffLine = `\n\nCoverage diff: ${baseLines}% → ${headLines}% (${diff > 0 ? "+" : ""}${diff}%)`;

      if (diff < -COVERAGE_DROP_FAIL) {
        conclusion = "failure";
      } else if (diff < -COVERAGE_DROP_WARN) {
        conclusion = "neutral";
      }
    }

    return {
      conclusion,
      title: "Coverage result",
      summary: `
      라인 커버리지: ${headLines}%
      ${diffLine}
      `.trim(),
    };
  },
});