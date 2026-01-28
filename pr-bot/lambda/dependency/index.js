import AdmZip from "adm-zip";
import { withStep } from "step-common/handler.js";
import { downloadArtifact } from "step-common/github.js";

const allowLicenses = new Set([
  "MIT",
  "Apache-2.0",
  "BSD-2-Clause",
  "BSD-3-Clause",
  "ISC",
]);

const denyLicenses = new Set([
  "GPL-3.0",
  "AGPL-3.0",
  "LGPL-3.0",
]);

export const handler = withStep({
  name: "dependency / license",

  async run({ event, octokit }) {
    const { repository, workflowRunId } = event;

    const zipBuffer = await downloadArtifact({
      octokit,
      owner: repository.owner,
      repo: repository.name,
      runId: workflowRunId,
      artifactName: "dependency",
    });

    // 1️⃣ artifact 없음 → 스킵
    if (!zipBuffer) {
      return {
        conclusion: "neutral",
        title: "License check skipped",
        summary: "라이선스 정보가 수집되지 않았습니다.",
      };
    }

    const zip = new AdmZip(zipBuffer);
    const entry = zip.getEntry("dependency-licenses.json");
    if (!entry) {
      return {
        conclusion: "neutral",
        title: "License report missing",
        summary: "dependency-licenses.json 파일이 없습니다.",
      };
    }

    const data = JSON.parse(entry.getData().toString("utf-8"));

    const denied = [];
    const review = [];

    for (const [pkg, info] of Object.entries(data)) {
      const licenses = String(info.licenses)
        .split(/ OR | AND |\(|\)/)
        .map(l => l.trim())
        .filter(Boolean);

      for (const lic of licenses) {
        if (denyLicenses.has(lic)) {
          denied.push({ pkg, lic });
        } else if (!allowLicenses.has(lic)) {
          review.push({ pkg, lic });
        }
      }
    }

    // 2️⃣ deny 라이선스
    if (denied.length > 0) {
      return {
        conclusion: "failure",
        title: "Blocked licenses detected",
        summary: formatDenied(denied),
      };
    }

    // 3️⃣ review 필요
    if (review.length > 0) {
      return {
        conclusion: "neutral",
        title: "License review required",
        summary: formatReview(review),
      };
    }

    // 4️⃣ 전부 허용
    return {
      conclusion: "success",
      title: "License check passed",
      summary: "모든 dependency 라이선스가 허용 목록에 있습니다.",
    };
  },
});

function formatDenied(items) {
  return [
    "❌ 차단된 라이선스가 발견되었습니다:",
    "",
    ...items.map(i => `- ${i.pkg} → ${i.lic}`),
  ].join("\n");
}

function formatReview(items) {
  return [
    "⚠️ 검토가 필요한 라이선스:",
    "",
    ...items.map(i => `- ${i.pkg} → ${i.lic}`),
  ].join("\n");
}