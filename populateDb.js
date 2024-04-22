require('dotenv').config();
const cosmos = require('@azure/cosmos');
const faker = require('faker');

const endpoint = process.env.COSMOS_ENDPOINT;
const key = process.env.COSMOS_KEY;
const client = new cosmos.CosmosClient({ endpoint, key });

const databaseId = 'products-db';
const containerId = 'products';
const containerId2 = 'stock';

async function run() {
    const { database } = await client.databases.createIfNotExists({ id: databaseId });
    const { container: container1 } = await database.containers.createIfNotExists({ id: containerId });
    const { container: container2 } = await database.containers.createIfNotExists({ id: containerId2 });

    for (let i = 0; i < 10; i++) {
        const fakeProduct = {
            id: faker.datatype.uuid(),
            title: faker.commerce.productName(),
            description: faker.lorem.paragraph(),
            price: faker.commerce.price()
        };

        await container1.items.create(fakeProduct);

        const fakeStock = {
            product_id: fakeProduct.id,
            count: faker.datatype.number()
        };

        await container2.items.create(fakeStock);
    }
}

run().catch(err => {
    console.error(err);
});