provider "google" {
  project = "cloo-1714461127593"
}

terraform {
	required_providers {
		google = {
	    version = "~> 4.59.0"
		}
  }
}
