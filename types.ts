export type Product = {
  id: string;
  title: string;
  description: string;
  price: number;
  stock?: number;
};

export type Stock = {
  product_id: string;
  count: number;
}