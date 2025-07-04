const { CostExplorerClient, GetCostAndUsageCommand } = require("@aws-sdk/client-cost-explorer");
const { S3Client, PutObjectCommand, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const https = require("https");

const REGION = process.env.REGION || "us-east-1";
const BUCKET = process.env.REPORT_BUCKET;
const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL;

const ce = new CostExplorerClient({ region: "us-east-1" });
const s3 = new S3Client({ region: REGION });

exports.handler = async () => {
  const now = new Date();
  const end = new Date(now.getFullYear(), now.getMonth(), 1); // 이번달 1일
  const start = new Date(end.getFullYear(), end.getMonth() - 1, 1); // 지난달 1일

  const formatDate = (date) => date.toISOString().split("T")[0];
  const startStr = formatDate(start);
  const endStr = formatDate(end);
  const monthStr = `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, "0")}`;

  const costCommand = new GetCostAndUsageCommand({
    TimePeriod: { Start: startStr, End: endStr },
    Granularity: "MONTHLY",
    Metrics: ["UnblendedCost"],
    GroupBy: [{ Type: "DIMENSION", Key: "SERVICE" }]
  });

  try {
    const result = await ce.send(costCommand);
    const services = result.ResultsByTime?.[0]?.Groups || [];

    let total = 0;
    const lines = ["서비스,금액 (USD)"];
    for (const group of services) {
      const name = group.Keys[0];
      const amount = parseFloat(group.Metrics.UnblendedCost.Amount).toFixed(4);
      total += parseFloat(amount);
      lines.push(`${name},${amount}`);
    }
    lines.push(`합계,${total.toFixed(4)}`);
    const csvContent = lines.join("\n");

    const key = `reports/${monthStr}.csv`;
    await s3.send(new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: csvContent,
      ContentType: "text/csv"
    }));

    const presignedUrl = await getSignedUrl(s3, new GetObjectCommand({
      Bucket: BUCKET,
      Key: key
    }), { expiresIn: 3600 });

    const slackMessage = `📦 *${monthStr} 월별 AWS 서비스별 요금 보고서*\n\n💰 총 요금: *$${total.toFixed(2)} USD*\n📥 CSV 다운로드: ${presignedUrl}`;
    await postToSlack(slackMessage);
  } catch (err) {
    console.error("월별 요금 조회 실패:", err);
  }
};

function postToSlack(text) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ text });
    const req = https.request(SLACK_WEBHOOK_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body)
      }
    }, (res) => {
      res.statusCode === 200 ? resolve() : reject(new Error("Slack 전송 실패"));
    });

    req.on("error", reject);
    req.write(body);
    req.end();
  });
}
