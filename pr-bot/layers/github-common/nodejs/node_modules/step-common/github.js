import { Octokit } from "@octokit/rest";

export function createOctokit(githubToken) {
  return new Octokit({
    auth: githubToken,
  });
}

export async function getLatestWorkflowRun({
  octokit,
  owner,
  repo,
  headSha,
  workflowName = "test",
}) {
  const res = await octokit.rest.actions.listWorkflowRunsForRepo({
    owner,
    repo,
    event: "pull_request",
    head_sha: headSha,
    per_page: 1,
  });

  return res.data.workflow_runs.find(
    (r) => r.name === workflowName
  );
}

export async function downloadArtifact({
  octokit,
  owner,
  repo,
  runId,
  artifactName,
}) {
  const artifacts = await octokit.rest.actions.listWorkflowRunArtifacts({
    owner,
    repo,
    run_id: runId,
  });

  const artifact = artifacts.data.artifacts.find(
    (a) => a.name === artifactName
  );

  if (!artifact) return null;

  const download = await octokit.rest.actions.downloadArtifact({
    owner,
    repo,
    artifact_id: artifact.id,
    archive_format: "zip",
  });

  return Buffer.from(download.data);
}

export async function getCoverageSummaryFromWorkflow({
  octokit,
  owner,
  repo,
  headSha,
  workflowName,
  artifactName = "coverage",
}) {
  const run = await getLatestWorkflowRun({
    octokit,
    owner,
    repo,
    headSha,
    workflowName,
  });

  if (!run || run.conclusion !== "success") return null;

  const zipBuffer = await downloadArtifact({
    octokit,
    owner,
    repo,
    runId: run.id,
    artifactName,
  });

  if (!zipBuffer) return null;

  const zip = new (await import("adm-zip")).default(zipBuffer);
  const entry = zip.getEntry("coverage-summary.json");
  if (!entry) return null;

  return JSON.parse(entry.getData().toString("utf-8")).total;
}