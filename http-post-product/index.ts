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
  
  const product = req.body;
  const { resource: createdProduct } = await container.items.create(product);
  
  context.res = {
    status: 200, 
    body: createdProduct,
  };
};

export default httpTrigger;