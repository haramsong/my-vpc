resource "aws_glue_catalog_database" "cur" {
  name = "cur_database"
}

resource "aws_glue_catalog_table" "cur_table" {
  name          = "cost_and_usage_report"
  database_name = aws_glue_catalog_database.cur.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    classification = "parquet"
  }

  storage_descriptor {
    location      = "s3://${var.cost_notifier_bucket_name}/cur/MyMonthlyCostAndUsage/MyMonthlyCostAndUsage/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "line_item_usage_account_id"
      type = "string"
    }

    columns {
      name = "product_product_name"
      type = "string"
    }

    columns {
      name = "savings_plan_savings"
      type = "double"
    }

    columns {
      name = "line_item_blended_cost"
      type = "double"
    }

    columns {
      name = "line_item_unblended_cost"
      type = "double"
    }

    columns {
      name = "credits_amount"
      type = "double"
    }
  }

  partition_keys {
    name = "year"
    type = "string"
  }

  partition_keys {
    name = "month"
    type = "string"
  }
}
