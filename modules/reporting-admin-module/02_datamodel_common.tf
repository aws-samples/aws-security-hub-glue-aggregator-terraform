resource "aws_glue_catalog_database" "reporting_database" {
  name        = lower(replace("${var.name_prefix}reporting", "-", "_")) # The only acceptable characters for database names, table names, and column names are lowercase letters, numbers, and the underscore character.
  description = "Aggregate data from Connected Drive member accounts"
}

