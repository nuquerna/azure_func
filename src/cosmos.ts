import { CosmosClient } from "@azure/cosmos";

const endpoint = process.env.COSMOS_DB_URL;
const key = process.env.COSMOS_DB_KEY;

const db_client = new CosmosClient({ endpoint, key });

export default db_client;
