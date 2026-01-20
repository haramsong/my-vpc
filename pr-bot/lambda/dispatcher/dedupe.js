import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";

const ddb = new DynamoDBClient({});
const TABLE = process.env.DEDUPE_TABLE_NAME;

export async function claimDeliveryId(deliveryId, ttlSeconds = 60 * 60 * 24 * 3) {
  if (!TABLE) throw new Error("DEDUPE_TABLE_NAME is not set");
  if (!deliveryId) return true; // deliveryId 없으면 그냥 처리 (안전 fallback)

  const now = Math.floor(Date.now() / 1000);
  const expiresAt = now + ttlSeconds;

  try {
    await ddb.send(
      new PutItemCommand({
        TableName: TABLE,
        Item: {
          delivery_id: { S: deliveryId },
          expires_at: { N: String(expiresAt) },
        },
        // ✅ 핵심: 이미 있으면 실패 → 중복
        ConditionExpression: "attribute_not_exists(delivery_id)",
      })
    );
    return true; // 최초 처리자
  } catch (e) {
    // ConditionalCheckFailedException이면 "이미 처리됨"
    if (e?.name === "ConditionalCheckFailedException") return false;
    throw e; // 다른 에러는 진짜 장애
  }
}