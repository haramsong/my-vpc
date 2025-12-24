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
    const result = await client.send(
      new GetCostAndUsageCommand({
        TimePeriod: { Start: startOfMonth, End: todayDate },
        Granularity: "DAILY",
        Metrics: ["UnblendedCost"],
        Filter: {
          Dimensions: {
            Key: "RECORD_TYPE",
            Values: ["Usage"],
          },
        },
        GroupBy: [
          { Type: "DIMENSION", Key: "SERVICE" },
        ],
      })
    );

    const results = result.ResultsByTime || [];
    const latestDay = results.at(-1);

    console.log('이번달 집계 데이터: ', results);
    console.log('어제자 예상 집계 데이터: ', latestDay);

    let message = `> *💸 ${thisMonth}월 ${todayDay}일 요금 정산 💸*\n`
    message += `_※ 본 금액은 Cost Explorer 기준 **예상치**입니다._\n\n`

    // 어제 예상 비용 산출
    const yesterdayCost = (latestDay?.Groups ?? []).reduce((sum, group) => {
      const amount = Number(group.Metrics?.UnblendedCost?.Amount ?? 0);
      return sum + amount;
    }, 0);
    message += `💰 어제( ${startYesterday} )의 예상 AWS 사용 요금: *$${parseFloat(yesterdayCost).toFixed(2)} USD*\n`;

    // 어제 자 서비스 별 예상 비용 산출
    if (latestDay?.Groups) {
      for (const group of latestDay.Groups) {
        const serviceName = group.Keys[0];
        const amount = Number(group.Metrics.UnblendedCost.Amount);

        // 표시 기준 0원 제거
        if (amount.toFixed(2) === "0.00") continue;

        message += `    ●  ${serviceName} : $${amount.toFixed(2)} USD\n`;
      }
    }

    // 이번 달 예상 비용 산출
    const monthlyCost = results.reduce((monthSum, day) => {
      const dayTotal = (day.Groups ?? []).reduce((daySum, group) => {
        const amount = Number(group.Metrics?.UnblendedCost?.Amount ?? 0);
        return daySum + amount;
      }, 0);

      return monthSum + dayTotal;
    }, 0);
    message += `📊 이번달 (${thisMonth}월) 누적 예상 AWS 사용 요금: *$${parseFloat(monthlyCost).toFixed(2)} USD*`;

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
