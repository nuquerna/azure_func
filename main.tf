terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.92.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  features {}
}

resource "azurerm_resource_group" "training" {
  name     = "rg-nuq-epm-2024"
  location = "polandcentral"
}

resource "azurerm_cosmosdb_account" "cosmo" {
  location            = "polandcentral"
  name                = "cos-nuq-epm-2024"
  offer_type          = "Standard"
  resource_group_name = azurerm_resource_group.training.name
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Eventual"
  }

  capabilities {
    name = "EnableServerless"
  }

  geo_location {
    failover_priority = 0
    location          = "Poland Central"
  }
}

resource "azurerm_cosmosdb_sql_database" "products_app" {
  account_name        = azurerm_cosmosdb_account.cosmo.name
  name                = "products-db"
  resource_group_name = azurerm_resource_group.training.name
}

resource "azurerm_cosmosdb_sql_container" "products" {
  account_name        = azurerm_cosmosdb_account.cosmo.name
  database_name       = azurerm_cosmosdb_sql_database.products_app.name
  name                = "products"
  partition_key_path  = "/id"
  resource_group_name = azurerm_resource_group.training.name

  # Cosmos DB supports TTL for the records
  default_ttl = -1

  indexing_policy {
    excluded_path {
      path = "/*"
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "stock" {
  account_name        = azurerm_cosmosdb_account.cosmo.name
  database_name       = azurerm_cosmosdb_sql_database.products_app.name
  name                = "stock"
  partition_key_path  = "/id"
  resource_group_name = azurerm_resource_group.training.name

  # Cosmos DB supports TTL for the records
  default_ttl = -1

  indexing_policy {
    excluded_path {
      path = "/*"
    }
  }
}

resource "azurerm_storage_account" "storage" {
  name                     = var.container_name
  location                 = "polandcentral"

  account_replication_type = "LRS"
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  resource_group_name      = azurerm_resource_group.training.name

  static_website {
    index_document = "index.html"
  }
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "workspace-nuq-epm-2024"
  location            = "polandcentral"
  resource_group_name = azurerm_resource_group.product_service_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 10
}

resource "azurerm_application_insights" "products_service_fa" {
  name             = "appins-nuq-epm-2024"
  application_type = "web"
  location         = "polandcentral"

  resource_group_name = azurerm_resource_group.training.name
  workspace_id = azurerm_log_analytics_workspace.law.id
}

resource "azurerm_storage_share" "products_service_fa" {
  name  = "fa-products-service-share"
  quota = 2

  storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_app_service_plan" "product_service_plan" {
  name                = "sp-nuq-epm-2024"
  location            = "polandcentral"
  resource_group_name = azurerm_resource_group.training.name

  kind = "FunctionApp"

  sku {
    size = "Y1"
    tier = "Dynamic"
  }

  tags = {
    environment = "training"
  }
}

resource "azurerm_app_configuration" "products_config" {
  location            = "polandcentral"
  name                = "psc-nuq-epm-2024"
  resource_group_name = azurerm_resource_group.training.name

  sku = "free"
}

resource "azurerm_api_management" "core_apim" {
  location        = "polandcentral"
  name            = "rg-ps-nuq-epm-2024"
  publisher_email = "pavel_kastsiuk1@epam.com"
  publisher_name  = "Pavel Kastsiuk"

  resource_group_name = azurerm_resource_group.training.name
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_api" "products_api" {
  api_management_name = azurerm_api_management.core_apim.name
  name                = "products-service-api"
  resource_group_name = azurerm_resource_group.training.name
  revision            = "1"

  display_name = "Products Service API"

  protocols = ["https"]
}

data "azurerm_function_app_host_keys" "products_keys" {
  name = azurerm_windows_function_app.products_service.name
  resource_group_name = azurerm_resource_group.training.name
}

resource "azurerm_api_management_backend" "products_fa" {
  name = "products-service-backend"
  resource_group_name = azurerm_resource_group.training.name
  api_management_name = azurerm_api_management.core_apim.name
  protocol = "http"
  url = "https://${azurerm_windows_function_app.products_service.name}.azurewebsites.net/api"
  description = "Products API"

  credentials {
    certificate = []
    query = {}

    header = {
      "x-functions-key" = data.azurerm_function_app_host_keys.products_keys.default_function_key
    }
  }
}

resource "azurerm_api_management_api_policy" "api_policy" {
  api_management_name = azurerm_api_management.core_apim.name
  api_name            = azurerm_api_management_api.products_api.name
  resource_group_name = azurerm_resource_group.training.name

  xml_content = <<XML
  <policies>
    <inbound>
      <set-backend-service backend-id="${azurerm_api_management_backend.products_fa.name}"/>
      <base/>
    </inbound>
    <backend>
      <base/>
    </backend>
    <outbound>
      <base/>
    </outbound>
    <on-error>
      <base/>
    </on-error>
  </policies>
  XML
}

resource "azurerm_api_management_api_operation" "http_get_product" {
  api_management_name = azurerm_api_management.core_apim.name
  api_name            = azurerm_api_management_api.products_api.name
  display_name        = "Get Product"
  method              = "GET"
  operation_id        = "getProduct"
  resource_group_name = azurerm_resource_group.training.name
  url_template        = "/products/{productId}"
}

resource "azurerm_api_management_api_operation" "http_get_product_list" {
  api_management_name = azurerm_api_management.core_apim.name
  api_name            = azurerm_api_management_api.products_api.name
  display_name        = "Get Product list"
  method              = "GET"
  operation_id        = "getProductList"
  resource_group_name = azurerm_resource_group.training.name
  url_template        = "/products"
}

resource "azurerm_api_management_api_operation" http-post-product" {
  api_management_name = azurerm_api_management.core_apim.name
  api_name            = azurerm_api_management_api.products_api.name
  display_name        = "Add Product"
  method              = "Post"
  operation_id        = "postProduct"
  resource_group_name = azurerm_resource_group.training.name
  url_template        = "/products"
}

resource "azurerm_windows_function_app" "products_service" {
  name     = "fa-nuq-epm-2024"
  location = "polandcentral"

  service_plan_id     = azurerm_service_plan.product_service_plan.id
  resource_group_name = azurerm_resource_group.training.name

  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  functions_extension_version = "~4"
  builtin_logging_enabled     = false

  site_config {
    always_on = false

    application_insights_key               = azurerm_application_insights.products_service_fa.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.products_service_fa.connection_string
    use_32_bit_worker = true

    cors {
      allowed_origins = ["https://portal.azure.com"]
    }
    application_stack {
      node_version = "~16"
    }
  }

 app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.storage.primary_connection_string
    WEBSITE_CONTENTSHARE                     = azurerm_storage_share.products_service_fa.name
  }

  # The app settings changes cause downtime on the Function App. e.g. with Azure Function App Slots
  # Therefore it is better to ignore those changes and manage app settings separately off the Terraform.
  lifecycle {
    ignore_changes = [
      app_settings,
      site_config["application_stack"], // workaround for a bug when azure just "kills" your app
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-resource-id"],
      tags["hidden-link: /app-insights-conn-string"]
    ]
  }
}