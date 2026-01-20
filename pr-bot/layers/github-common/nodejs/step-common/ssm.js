import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";

const ssm = new SSMClient({});
const cache = new Map();

export async function getParameter(name) {
  if (cache.has(name)) {
    return cache.get(name);
  }

  const res = await ssm.send(
    new GetParameterCommand({
      Name: name,
      WithDecryption: true,
    })
  );

  const value = res.Parameter.Value;
  cache.set(name, value);
  return value;
}