export type Stock = {
  product_id: string;
  count: number;
}

export type Product = {
  id: string;
  title: string;
  description: string;
  price: number;
};

export type ProductDTO = Product & Pick<Stock, 'count'>
