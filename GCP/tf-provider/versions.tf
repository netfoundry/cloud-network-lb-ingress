terraform {
    required_version = ">= 0.13"
    
    required_providers {
        google = {
            source  = "hashicorp/google"
            version = ">= 3.53, < 6.0"
        }
    }

    provider_meta "google" {
            module_name = "blueprints/terraform/canonical-mp/v0.0.1"
    }
}