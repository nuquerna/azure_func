import { AzureFunction, Context, HttpRequest } from "@azure/functions";
import { list } from "../data";

const httpTrigger: AzureFunction = async function (
  context: Context,
  req: HttpRequest
): Promise<void> {
  context.log("Get product list function request");

  const response = JSON.stringify(list);

  context.res = {
    status: 200,
    body: response,
    headers: {
      'Content-Type': 'application/json'
    },
  };
};

export default httpTrigger;
