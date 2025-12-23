const { AthenaClient, StartQueryExecutionCommand } = require("@aws-sdk/client-athena");

const athena = new AthenaClient({ region: process.env.AWS_REGION });

exports.handler = async () => {
  const query = `MSCK REPAIR TABLE ${process.env.DATABASE}.${process.env.TABLE}`;

  await athena.send(new StartQueryExecutionCommand({
    QueryString: query,
    ResultConfiguration: {
      OutputLocation: process.env.OUTPUT
    }
  }));

  return { ok: true };
};