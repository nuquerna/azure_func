import { AzureFunction, Context, HttpRequest } from "@azure/functions";
import { CosmosClient } from "@azure/cosmos";

const endpoint = process.env.COSMOS_DB_URL;
const key = process.env.COSMOS_DB_KEY;
const client = new CosmosClient({ endpoint, key });

const httpTrigger: AzureFunction = async function (
  context: Context,
  req: HttpRequest
): Promise<void> {
  const databaseId = "products-db";
  const containerId = "products";

  const container = client.database(databaseId).container(containerId);

  const id = req.params.productId;
  const { resource: product } = await container.item(id).read();

  context.res = {
    status: 200,
    body: product,
  };
};

export default httpTrigger;
