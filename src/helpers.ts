import db_client from "./cosmos";

export const getContainer = (currentDatabase: string, currentContainer: string) => {
    const database = db_client.database(currentDatabase);
    const container = database.container(currentContainer);
    return container;
}