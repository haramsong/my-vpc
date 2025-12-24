const { CostExplorerClient, GetCostAndUsageCommand } = require("@aws-sdk/client-cost-explorer");
const { AthenaClient, StartQueryExecutionCommand, GetQueryExecutionCommand } = require("@aws-sdk/client-athena");
const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const https = require("https");

const region = process.env.REGION || "us-east-1";
const RESULT_BUCKET = process.env.LOG_BUCKET || "";
const OUTPUT_LOCATION = `s3://${RESULT_BUCKET}/query-results/`;
const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL;

const athenaClient = new AthenaClient({ region });
const ce = new CostExplorerClient({ region: "us-east-1" });
const s3 = new S3Client({ region: region });

const now = new Date();
const start = new Date(now.getFullYear(), now.getMonth() - 1, 1);
const end = new Date(now.getFullYear(), now.getMonth(), 0);

const formatDate = (date) => date.toISOString().split("T")[0];
const startStr = formatDate(start);
const endStr = formatDate(end);
const monthStr = `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, "0")}`;
const yearStr = `${start.getFullYear()}`;
const monthWithoutPadStr = `${start.getMonth() + 1}`;

const queryString = `
SELECT product_product_name,
    ROUND(SUM(line_item_unblended_cost), 3) AS total_cost,
    ROUND(SUM(line_item_blended_cost), 3) AS discounted_cost,
    ROUND(SUM(line_item_unblended_cost) - SUM(line_item_blended_cost), 3) AS net_cost
FROM AwsDataCatalog.cur_database.cost_and_usage_report
WHERE year = '${yearStr}'
    AND month = '${monthWithoutPadStr}'
GROUP BY product_product_name
ORDER BY total_cost DESC
`;

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function parseS3Uri(s3Uri) {
  const match = s3Uri.match(/^s3:\/\/([^\/]+)\/(.+)$/);
  if (!match) throw new Error("Invalid S3 URI: " + s3Uri);
  return { bucket: match[1], key: match[2] };
}

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

exports.handler = async () => {
  const costCommand = new GetCostAndUsageCommand({
    TimePeriod: { Start: startStr, End: endStr },
    Granularity: "MONTHLY",
    Metrics: ["UnblendedCost"],
    Filter: {
      Dimensions: {
        Key: "RECORD_TYPE",
        Values: ["Usage"],
      },
    },
    GroupBy: [{ Type: "DIMENSION", Key: "SERVICE" }]
  });

  try {
    const result = await ce.send(costCommand);
    const services = result.ResultsByTime?.[0]?.Groups || [];

    let total = 0;
    let lines = '';
    for (const group of services) {
      const name = group.Keys[0];
      const rawAmount = Number(group.Metrics.UnblendedCost.Amount);

      if (rawAmount.toFixed(2) === "0.00") continue;

      total += rawAmount;
      lines += `    - ${name} : $${rawAmount.toFixed(2)} USD\n`;
    }

    const startCommand = new StartQueryExecutionCommand({
      QueryString: queryString,
      ResultConfiguration: {
        OutputLocation: OUTPUT_LOCATION,
      },
      QueryExecutionContext: {
        Catalog: "AwsDataCatalog",
        Database: "cur_database",
      },
      WorkGroup: "primary",
    });
    const startResponse = await athenaClient.send(startCommand);
    const queryExecutionId = startResponse.QueryExecutionId;
    console.log("Started query:", queryExecutionId);

    let queryStatus;
    while (true) {
      const getCommand = new GetQueryExecutionCommand({ QueryExecutionId: queryExecutionId });
      const getResponse = await athenaClient.send(getCommand);
      queryStatus = getResponse.QueryExecution.Status.State;
      console.log("Query status:", queryStatus);

      if (queryStatus === "SUCCEEDED") break;
      if (queryStatus === "FAILED" || queryStatus === "CANCELLED") {
        const reason = getResponse.QueryExecution.Status.StateChangeReason;
        console.error("Athena query failed reason:", reason);
        throw new Error(`Query failed or cancelled: ${queryStatus} - ${reason}`);
      }
      await sleep(2000);
    }

    const resultLocation = (await athenaClient.send(new GetQueryExecutionCommand({ QueryExecutionId: queryExecutionId })))
      .QueryExecution.ResultConfiguration.OutputLocation;
    console.log("Query results available at:", resultLocation);

    const { bucket, key } = parseS3Uri(resultLocation);
    const getObjectCommand = new GetObjectCommand({ Bucket: bucket, Key: key });
    const presignedUrl = await getSignedUrl(s3, getObjectCommand, { expiresIn: 7200 });

    const slackMessage = `> 📦 *${monthStr} 월별 AWS 서비스별 요금 보고서*\n\n💰 총 요금: *$${total.toFixed(2)} USD*\n${lines}\n📥 CSV 다운로드: <${presignedUrl}|클릭>`;
    await postToSlack(slackMessage);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Query succeeded",
        presignedUrl,
      }),
    };
  } catch (error) {
    console.error("Error running Athena query:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Error running Athena query",
        error: error.message,
      }),
    };
  }
};