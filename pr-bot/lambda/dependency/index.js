import { withStep } from "./step-common/handler.js";

/**
 * 정책 예시
 * 실제로는 env / config 파일로 분리 가능
 */
const BLOCKED_PACKAGES = ["left-pad", "event-stream"];
const BLOCKED_LICENSES = ["GPL-3.0"];

export const handler = withStep({
  name: "dependency / policy",

  async run({ event, octokit }) {
    const { repository, pullRequest } = event;

    // 1️⃣ PR 변경 파일 목록
    const files = await octokit.paginate(
      octokit.rest.pulls.listFiles,
      {
        owner: repository.owner,
        repo: repository.name,
        pull_number: pullRequest.number,
        per_page: 100,
      }
    );

    // 2️⃣ 의존성 파일 변경 여부 확인
    const dependencyFiles = files.filter((f) =>
      [
        "package.json",
        "package-lock.json",
        "pnpm-lock.yaml",
        "yarn.lock",
      ].some((name) => f.filename.endsWith(name))
    );

    if (dependencyFiles.length === 0) {
      return {
        conclusion: "neutral",
        title: "No dependency changes",
        summary: "의존성 변경이 감지되지 않았습니다.",
      };
    }

    // 3️⃣ base / head package.json 가져오기
    const basePkg = await getPackageJson({
      octokit,
      owner: repository.owner,
      repo: repository.name,
      ref: pullRequest.baseSha ?? "main",
    });

    const headPkg = await getPackageJson({
      octokit,
      owner: repository.owner,
      repo: repository.name,
      ref: pullRequest.headSha,
    });

    if (!basePkg || !headPkg) {
      return {
        conclusion: "neutral",
        title: "Dependency check skipped",
        summary: "package.json을 비교할 수 없어 검사를 건너뜁니다.",
      };
    }

    // 4️⃣ 변경된 dependency 계산
    const changes = diffDependencies(
      basePkg.dependencies,
      headPkg.dependencies
    );

    if (changes.length === 0) {
      return {
        conclusion: "success",
        title: "Dependencies unchanged",
        summary: "의존성 변경이 없습니다.",
      };
    }

    // 5️⃣ 정책 검사
    // 5️⃣ 정책 검사
    const annotations = [];
    let hasBlocker = false;

    for (const c of changes) {
      // 5-1. 패키지 차단
      if (BLOCKED_PACKAGES.includes(c.name)) {
        hasBlocker = true;
        annotations.push({
          path: "package.json",
          start_line: 1,
          end_line: 1,
          annotation_level: "failure",
          message: `금지된 패키지 사용: ${c.name}`,
        });
        continue;
      }

      // 5-2. 라이선스 검사 (추가됨)
      const license = await getPackageLicense(c.name);

      if (license && BLOCKED_LICENSES.includes(license)) {
        hasBlocker = true;
        annotations.push({
          path: "package.json",
          start_line: 1,
          end_line: 1,
          annotation_level: "failure",
          message: `금지된 라이선스(${license})를 사용하는 패키지: ${c.name}`,
        });
        continue;
      }

      // 5-3. Major version 변경 경고
      if (isMajorBump(c.from, c.to)) {
        annotations.push({
          path: "package.json",
          start_line: 1,
          end_line: 1,
          annotation_level: "warning",
          message: `Major version 변경: ${c.name} (${c.from} → ${c.to})`,
        });
      }
    }

    return {
      conclusion: hasBlocker ? "failure" : "neutral",
      title: hasBlocker
        ? "Blocked dependencies found"
        : "Dependency changes detected",
      summary: formatSummary(changes),
      annotations,
    };
  },
});

async function getPackageJson({ octokit, owner, repo, ref }) {
  try {
    const res = await octokit.rest.repos.getContent({
      owner,
      repo,
      path: "package.json",
      ref,
    });

    const content = Buffer.from(
      res.data.content,
      "base64"
    ).toString("utf-8");

    return JSON.parse(content);
  } catch {
    return null;
  }
}

function diffDependencies(base = {}, head = {}) {
  const changes = [];

  const names = new Set([
    ...Object.keys(base),
    ...Object.keys(head),
  ]);

  for (const name of names) {
    if (!base[name]) {
      changes.push({ name, type: "added", to: head[name] });
    } else if (!head[name]) {
      changes.push({ name, type: "removed", from: base[name] });
    } else if (base[name] !== head[name]) {
      changes.push({
        name,
        type: "changed",
        from: base[name],
        to: head[name],
      });
    }
  }

  return changes;
}

function isMajorBump(from, to) {
  if (!from || !to) return false;
  const major = (v) => v.replace(/^[^0-9]*/, "").split(".")[0];
  return major(from) !== major(to);
}

function formatSummary(changes) {
  return changes
    .map((c) => {
      if (c.type === "added")
        return `➕ ${c.name}@${c.to}`;
      if (c.type === "removed")
        return `➖ ${c.name}@${c.from}`;
      return `🔁 ${c.name}: ${c.from} → ${c.to}`;
    })
    .join("\n");
}

const licenseCache = new Map();

async function getPackageLicense(pkgName) {
  if (licenseCache.has(pkgName)) {
    return licenseCache.get(pkgName);
  }

  try {
    const res = await fetch(`https://registry.npmjs.org/${pkgName}`);
    const data = await res.json();

    // 최신 버전 기준 license
    const latest = data["dist-tags"]?.latest;
    const license =
      data.versions?.[latest]?.license ??
      data.license ??
      null;

    licenseCache.set(pkgName, license);
    return license;
  } catch (e) {
    // 라이선스 못 가져오면 "모름"으로 취급
    licenseCache.set(pkgName, null);
    return null;
  }
}