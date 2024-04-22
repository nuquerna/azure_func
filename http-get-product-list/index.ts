import { AzureFunction, Context } from "@azure/functions";
import { CosmosClient } from "@azure/cosmos";
import { Product, Stock } from "../types";

const endpoint = process.env.COSMOS_DB_URL;
const key = process.env.COSMOS_DB_KEY;
const client = new CosmosClient({ endpoint, key });

const httpTrigger: AzureFunction = async function (
  context: Context
): Promise<void> {
  const databaseId = "products-db";
  const productContainerId = "products";
  const stockContainerId = "stock";

  const productContainer = client
    .database(databaseId)
    .container(productContainerId);
  const stockContainer = client
    .database(databaseId)
    .container(stockContainerId);

  const query = {
    query: `SELECT * FROM c`,
  };

  const productQueryResponse = await productContainer.items
    .query(query)
    .fetchAll();
  const stockQueryResponse = await stockContainer.items.query(query).fetchAll();

  const products = productQueryResponse.resources as Product[];
  const stocks = stockQueryResponse.resources as Stock[];

  products.forEach((product) => {
    const productStock = stocks.find(
      (stock) => stock.product_id === product.id
    );
    product.stock = productStock ? productStock.count : 0;
  });

  context.res = {
    status: 200,
    body: products,
  };
};

export default httpTrigger;
