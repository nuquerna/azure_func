import { AzureFunction, Context, HttpRequest } from "@azure/functions";
import { list } from "../data";

const httpTrigger: AzureFunction = async function (
  context: Context,
  req: HttpRequest
): Promise<void> {
  context.log("Get product by productId");
  const id = req.params.productId;

  if (!id) {
    context.res = {
      status: 404,
      body: "There is no ID",
    };
    return;
  }

  const product = list.find((p) => p.id === id);

  if (!product) {
    context.res = {
      status: 404,
      body: "There is no product by your id",
    };
    return;
  }

  context.res = {
    status: 200,
    body: JSON.stringify(product),
    headers: {
      'Content-Type': 'application/json'
    },
  };
};

export default httpTrigger;
