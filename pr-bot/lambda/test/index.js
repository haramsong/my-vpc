const https = require("https");

const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL;

exports.handler = async (event) => {
  const {
    detail: { eventName, eventSource, userIdentity, requestParameters },
    time,
    region,
    account
  } = event;

  const user = userIdentity?.userName || userIdentity?.principalId || "Unknown";
  const paramsStr = requestParameters
    ? JSON.stringify(requestParameters, null, 2).slice(0, 1000)
    : "N/A";

  const message = `> *🚨 AWS 보안 경고 🚨*\n\n` +
    `• *Event*: ${eventName}\n` +
    `• *Service*: ${eventSource}\n` +
    `• *User*: ${user}\n` +
    `• *Account*: ${account}\n` +
    `• *Region*: ${region}\n` +
    `• *Time*: ${time}\n` +
    `• *Params*:\n\`\`\`${paramsStr}\`\`\``;

  await postToSlack(message);
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

