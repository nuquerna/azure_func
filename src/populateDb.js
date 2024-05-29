require('dotenv').config();
const faker = require('faker');

import { DATABASE_ID, PRODUCTS_CONTAINER, STOCKS_CONTAINER } from './constants';
import { ProductDTO } from './types';

async function run() {
    const { database } = await client.databases.createIfNotExists({ id: DATABASE_ID });
    const { container: products } = await database.containers.createIfNotExists({ id: PRODUCTS_CONTAINER });
    const { container: stocks } = await database.containers.createIfNotExists({ id: STOCKS_CONTAINER });

    for (let i = 0; i < 10; i++) {
        const fakeProduct = {
            id: faker.datatype.uuid(),
            title: faker.commerce.productName(),
            description: faker.lorem.paragraph(),
            price: faker.commerce.price(),
            count: faker.number.int({ max: 100 })
        };

        await products.items.create(fakeProduct);

        const fakeStock = {
            product_id: fakeProduct.id,
            count: faker.datatype.number()
        };

        await stocks.items.create(fakeStock);
    }
}

run().catch(err => {
    console.error(err);
});