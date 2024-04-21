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

resource "azurerm_resource_group" "product_service_rg" {
  location = "northeurope"
  name     = "rg-product-service-sand-ne-0024"
}

resource "azurerm_resource_group" "front_end_rg" {
  name     = "rg-frontend-sand-ne-0024"
  location = "northeurope"
}

# resource "azurerm_resource_group" "apim" {
#   name     = "rg-apim-sand-ne-0024"
#   location = "northeurope"
# }

# resource "azurerm_storage_account" "front_end_storage_account" {
#   name                     = var.container_name
#   location                 = "northeurope"

#   account_replication_type = "LRS"
#   account_tier             = "Standard"
#   account_kind             = "StorageV2"
#   resource_group_name      = azurerm_resource_group.front_end_rg.name

#   static_website {
#     index_document = "index.html"
#   }
# }

resource "azurerm_storage_account" "products_service_fa" {
  name     = "stgsangproductsfane0024"
  location = "northeurope"

  account_replication_type = "LRS"
  account_tier             = "Standard"
  account_kind             = "StorageV2"

  resource_group_name = azurerm_resource_group.product_service_rg.name
}

resource "azurerm_storage_share" "products_service_fa" {
  name  = "fa-products-service-share"
  quota = 2

  storage_account_name = azurerm_storage_account.products_service_fa.name
}

resource "azurerm_service_plan" "product_service_plan" {
  name     = "asp-product-service-sand-ne-0024"
  location = "northeurope"

  os_type  = "Windows"
  sku_name = "Y1"

  resource_group_name = azurerm_resource_group.product_service_rg.name
}

resource "azurerm_application_insights" "products_service_fa" {
  name             = "appins-fa-products-service-sand-ne-0024"
  application_type = "web"
  location         = "northeurope"

  resource_group_name = azurerm_resource_group.product_service_rg.name
}

resource "azurerm_app_configuration" "products_config" {
  location            = "northeurope"
  name                = "appconfig-products-service-sand-ne-0024"
  resource_group_name = azurerm_resource_group.product_service_rg.name

  sku = "free"
}

resource "azurerm_api_management" "core_apim" {
  location        = "northeurope"
  name            = "rg-product-service-sand-ne-0024"
  publisher_email = "pavel_kastsiuk1@epam.com"
  publisher_name  = "Pavel Kastsiuk"

  resource_group_name = azurerm_resource_group.product_service_rg.name
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_api" "products_api" {
  api_management_name = azurerm_api_management.core_apim.name
  name                = "products-service-api"
  resource_group_name = azurerm_resource_group.product_service_rg.name
  revision            = "1"

  display_name = "Products Service API"

  protocols = ["https"]
}

data "azurerm_function_app_host_keys" "products_keys" {
  name = azurerm_windows_function_app.products_service.name
  resource_group_name = azurerm_resource_group.product_service_rg.name
}

resource "azurerm_api_management_backend" "products_fa" {
  name = "products-service-backend"
  resource_group_name = azurerm_resource_group.product_service_rg.name
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
  resource_group_name = azurerm_resource_group.product_service_rg.name

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

# resource "azurerm_api_management_api_operation" "http_get_product" {
#   api_management_name = azurerm_api_management.core_apim.name
#   api_name            = azurerm_api_management_api.products_api.name
#   display_name        = "Get Product"
#   method              = "GET"
#   operation_id        = "getProduct"
#   resource_group_name = azurerm_resource_group.product_service_rg.name
#   url_template        = "/products/{productId}"
# }

resource "azurerm_api_management_api_operation" "http_get_product_list" {
  api_management_name = azurerm_api_management.core_apim.name
  api_name            = azurerm_api_management_api.products_api.name
  display_name        = "Get Product list"
  method              = "GET"
  operation_id        = "getProductList"
  resource_group_name = azurerm_resource_group.product_service_rg.name
  url_template        = "/products"
}


resource "azurerm_windows_function_app" "products_service" {
  name     = "fa-products-service-ne-0024"
  location = "northeurope"

  service_plan_id     = azurerm_service_plan.product_service_plan.id
  resource_group_name = azurerm_resource_group.product_service_rg.name

  storage_account_name       = azurerm_storage_account.products_service_fa.name
  storage_account_access_key = azurerm_storage_account.products_service_fa.primary_access_key

  functions_extension_version = "~4"
  builtin_logging_enabled     = false

  site_config {
    always_on = false

    application_insights_key               = azurerm_application_insights.products_service_fa.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.products_service_fa.connection_string

    # For production systems set this to false, but consumption plan supports only 32bit workers
    use_32_bit_worker = true

    # Enable function invocations from Azure Portal.
    cors {
      allowed_origins = ["https://portal.azure.com"]
    }

    application_stack {
      node_version = "~16"
    }
  }

  app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.products_service_fa.primary_connection_string
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