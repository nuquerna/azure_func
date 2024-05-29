import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";

import { PRODUCTS_DB, PRODUCTS_CONTAINER, STOCKS_CONTAINER } from "../constants";
import { getContainer } from "../helpers";
import { Product } from "../types";

export async function httpGetProductList(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  context.log('Incoming request from: ', request.url)

  const productsContainer = getContainer(PRODUCTS_DB, PRODUCTS_CONTAINER)
  const stocksContainer = getContainer(PRODUCTS_DB, STOCKS_CONTAINER)

  const { resources: products } = await productsContainer.items.readAll().fetchAll()
  const { resources: stocks } = await stocksContainer.items.readAll().fetchAll()

  const res = products.map(({ id, title, description, price }: Product) => ({
    id, title, description, price,
    count: stocks.find(stock => stock.productId === id)?.count ?? 0
  }))

  return {
    jsonBody: res,
  }
};

app.http('http-get-product-list', {
  methods: ['GET'],
  authLevel: 'function',
  route: 'products',
  handler: httpGetProductList
});