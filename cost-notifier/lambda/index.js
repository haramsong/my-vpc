const { CostExplorerClient, GetCostAndUsageCommand } = require("@aws-sdk/client-cost-explorer");
const https = require("https");

const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL;
const client = new CostExplorerClient({ region: "us-east-1" });

exports.handler = async () => {
  const now = new Date();
  const todayDate = now.toISOString().split("T")[0];
  const todayDay = now.getDate();
  const thisMonth = now.getMonth() + 1;

  // 어제 날짜 계산
  const yesterday = new Date(now);
  yesterday.setDate(yesterday.getDate() - 1);
  const startYesterday = yesterday.toISOString().split("T")[0];

  // 이번달 첫날
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split("T")[0];

  try {
    // 어제 비용 조회
    const costYesterday = await client.send(
      new GetCostAndUsageCommand({
        TimePeriod: { Start: startYesterday, End: todayDate },
        Granularity: "DAILY",
        Metrics: ["UnblendedCost"],
      })
    );

    // 이번달 비용 조회
    const costThisMonth = await client.send(
      new GetCostAndUsageCommand({
        TimePeriod: { Start: startOfMonth, End: todayDate },
        Granularity: "MONTHLY",
        Metrics: ["UnblendedCost"],
      })
    );

    const yesterdayAmount =
      costYesterday.ResultsByTime?.[0]?.Total?.UnblendedCost?.Amount || "0";

    const thisMonthAmount =
      costThisMonth.ResultsByTime?.[0]?.Total?.UnblendedCost?.Amount || "0";

    const message = `> *💸 ${thisMonth}월 ${todayDay}일 요금 정산 💸*\n` +
      `💰 어제( ${startYesterday} )의 AWS 사용 요금: *$${parseFloat(yesterdayAmount).toFixed(10)} USD*\n` +
      `📊 이번달 (${thisMonth}월) 누적 AWS 사용 요금: *$${parseFloat(thisMonthAmount).toFixed(10)} USD*`;

    console.log("메세지 전송:", message);
    await postToSlack(message);
  } catch (error) {
    console.error("비용 조회 실패", error);
  }
};

function postToSlack(text) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ text });
    const req = https.request(SLACK_WEBHOOK_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(body) }
    }, (res) => {
      res.statusCode === 200 ? resolve() : reject(new Error("Slack 전송 실패"));
    });

    req.on("error", reject);
    req.write(body);
    req.end();
  });
}
