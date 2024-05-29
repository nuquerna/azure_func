import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { Product, ProductDTO, Stock } from "../types";
import { PRODUCTS_DB, PRODUCTS_CONTAINER, STOCKS_CONTAINER } from "../constants";
import { getContainer } from "../helpers";
import { validateProduct } from "../validate";
import faker from 'faker';

export async function httpPostProduct(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  try {
    context.log('Incoming request from: ', request.url)

    const products_db = getContainer(PRODUCTS_DB, PRODUCTS_CONTAINER)
    const stocks_db = getContainer(PRODUCTS_DB, STOCKS_CONTAINER)

    const item = await request.json() as ProductDTO
    validateProduct(item)
    context.log(item, 'request.body')

    const { resource: product_item } = await products_db.items.create<Product>({
      id: faker.string.uuid(),
      title: item.title,
      description: item.description,
      price: item.price
    })

    await stocks_db.items.create<Stock>({ product_id: product_item.id, count: item.count })

    return {
      jsonBody: {
        message: 'Product created!',
        product: item
      }
    }

  } catch (error) {
    context.error(error.message)
    return {
      status: 400,
      jsonBody: {
        message: error.message
      }
    }
  }
};

app.http('http-post-product', {
  methods: ['POST'],
  authLevel: 'function',
  route: 'product',
  handler: httpPostProduct
});