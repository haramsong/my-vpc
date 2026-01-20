import { LambdaClient, InvokeCommand } from "@aws-sdk/client-lambda";

const lambda = new LambdaClient({});

export async function invokeStep(functionName, payload) {
  if (!functionName) return;

  await lambda.send(
    new InvokeCommand({
      FunctionName: functionName,
      InvocationType: "Event", // async
      Payload: Buffer.from(JSON.stringify(payload)),
    })
  );
}