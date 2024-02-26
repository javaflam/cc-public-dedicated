terraform {

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.62.0"
    }
  }
}

provider "confluent" {}

data "confluent_environment" "demo" {
  id = "env-6o26pj"
}

data "confluent_schema_registry_cluster" "essentials" {
  id = "lsrc-y6x09k"
  environment {
    id = data.confluent_environment.demo.id
  }
}

resource "confluent_kafka_cluster" "dedicated" {
  display_name = "Midgad"
  availability = "MULTI_ZONE"
  cloud        = "AWS"
  region       = "ap-southeast-1"
  dedicated {
    cku = 2
  }
  environment {
    id = data.confluent_environment.demo.id
  }
}

resource "confluent_service_account" "cool-manager" {
  display_name = "cool-manager"
  description  = "Service account to manage 'awesome' Kafka cluster"
}

resource "confluent_role_binding" "cool-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.cool-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.dedicated.rbac_crn
}

resource "confluent_api_key" "cool-manager-kafka-api-key" {
  display_name = "cool-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cool-manager' service account"
  
  # disable_wait_for_ready = true

  owner {
    id          = confluent_service_account.cool-manager.id
    api_version = confluent_service_account.cool-manager.api_version
    kind        = confluent_service_account.cool-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = data.confluent_environment.demo.id
    }
  }

  depends_on = [
    confluent_role_binding.cool-manager-kafka-cluster-admin,
  ]
}

resource "confluent_kafka_topic" "orders" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  topic_name    = "orders"
  rest_endpoint = confluent_kafka_cluster.dedicated.rest_endpoint
  credentials {
    key    = confluent_api_key.cool-manager-kafka-api-key.id
    secret = confluent_api_key.cool-manager-kafka-api-key.secret
  }
}

resource "confluent_service_account" "cool-consumer" {
  display_name = "cool-consumer"
  description  = "Service account to consume from 'orders' topic of 'awesome' Kafka cluster"
}

resource "confluent_api_key" "cool-consumer-kafka-api-key" {
  display_name = "cool-consumer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cool-consumer' service account"

  # disable_wait_for_ready = true

  owner {
    id          = confluent_service_account.cool-consumer.id
    api_version = confluent_service_account.cool-consumer.api_version
    kind        = confluent_service_account.cool-consumer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = data.confluent_environment.demo.id
    }
  }
}

resource "confluent_service_account" "cool-producer" {
  display_name = "cool-producer"
  description  = "Service account to produce to 'orders' topic of 'awesome' Kafka cluster"
}

resource "confluent_api_key" "cool-producer-kafka-api-key" {
  display_name = "cool-producer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cool-producer' service account"

  # disable_wait_for_ready = true

  owner {
    id          = confluent_service_account.cool-producer.id
    api_version = confluent_service_account.cool-producer.api_version
    kind        = confluent_service_account.cool-producer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = data.confluent_environment.demo.id
    }
  }
}

resource "confluent_kafka_acl" "cool-consumer-read-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.orders.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.cool-consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.dedicated.rest_endpoint
  credentials {
    key    = confluent_api_key.cool-manager-kafka-api-key.id
    secret = confluent_api_key.cool-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "cool-consumer-read-on-group" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  resource_type = "GROUP"
  resource_name = "cool_group_"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.cool-consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.dedicated.rest_endpoint
  credentials {
    key    = confluent_api_key.cool-manager-kafka-api-key.id
    secret = confluent_api_key.cool-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "cool-producer-write-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.orders.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.cool-producer.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.dedicated.rest_endpoint
  credentials {
    key    = confluent_api_key.cool-manager-kafka-api-key.id
    secret = confluent_api_key.cool-manager-kafka-api-key.secret
  }
}
