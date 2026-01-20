import { withStep } from "./step-common/handler.js";

export const handler = withStep({
  name: "lint / eslint",

  async run({ event, octokit }) {
    const { repository, pullRequest } = event;

    const files = await octokit.paginate(
      octokit.rest.pulls.listFiles,
      {
        owner: repository.owner,
        repo: repository.name,
        pull_number: pullRequest.number,
        per_page: 100,
      }
    );

    const annotations = [];

    for (const f of files) {
      if (f.filename.endsWith(".js")) {
        // 예시: 일부러 annotation 많이 생성
        annotations.push({
          path: f.filename,
          start_line: 1,
          end_line: 1,
          annotation_level: "warning",
          message: "예시 lint 경고입니다.",
        });
      }
    }

    if (annotations.length > 0) {
      return {
        conclusion: "neutral",
        title: "Lint warnings",
        summary: `${annotations.length}개의 lint 경고가 발견되었습니다.`,
        annotations,
      };
    }

    return {
      conclusion: "success",
      title: "Lint passed",
      summary: "Lint issue 없음",
    };
  },
});