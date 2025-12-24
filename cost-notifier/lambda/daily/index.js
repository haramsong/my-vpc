const { CostExplorerClient, GetCostAndUsageCommand } = require("@aws-sdk/client-cost-explorer");
const https = require("https");

const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL;
const client = new CostExplorerClient({ region: "us-east-1" });

exports.handler = async () => {
  const now = new Date();
  const todayDay = now.getDate();
  const thisMonth = now.getMonth() + 1;

  // 어제 날짜 계산
  const yesterday = new Date(now);
  yesterday.setDate(yesterday.getDate() - 1);
  const startYesterday = yesterday.toISOString().split("T")[0];

  // 이번달 첫날
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split("T")[0];

  try {
    const result = await client.send(
      new GetCostAndUsageCommand({
        TimePeriod: { Start: startOfMonth, End: startYesterday },
        Granularity: "DAILY",
        Metrics: ["UnblendedCost"],
        Filter: {
          Dimensions: {
            Key: "RECORD_TYPE",
            Values: ["Usage"],
          },
        },
      })
    );

    const results = result.ResultsByTime || [];

    console.log('어제자 집계 데이터: ', result.at(-1));

    const yesterdayCost = results.at(-1)?.Total?.UnblendedCost?.Amount || "0";
    const monthlyCost = results.reduce((sum, day) => {
      const amount = parseFloat(day.Total?.UnblendedCost?.Amount || "0");
      return sum + amount;
    }, 0);

    const message = `> *💸 ${thisMonth}월 ${todayDay}일 요금 정산 💸*\n\n` +
      `💰 어제( ${startYesterday} )의 AWS 사용 요금: *$${parseFloat(yesterdayCost).toFixed(2)} USD*\n` +
      `📊 이번달 (${thisMonth}월) 누적 AWS 사용 요금: *$${parseFloat(monthlyCost).toFixed(2)} USD*`;

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
