resource "aws_athena_workgroup" "query_workgroup" {
  name          = "${var.name_prefix}reporting-workgroup"
  description   = "process named query for PCR"
  force_destroy = true
  tags          = var.custom_tags

  configuration {
    enforce_workgroup_configuration = false
    result_configuration {
      output_location = "s3://${module.reporting_bucket.s3_id}/queries_output/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

resource "aws_athena_named_query" "view_sh_events_latest" {
  name        = "${var.name_prefix}reporting.create_view_latest_sh"
  description = "create view with lastest finding event id"
  database    = aws_glue_catalog_database.reporting_database.name
  workgroup   = aws_athena_workgroup.query_workgroup.id
  query       = <<-EOT
    CREATE OR REPLACE VIEW securityhub_finding_last_event AS 
        SELECT 
            finding.Id,
            max(finding.UpdatedAt) as lastUpdatedAt
        FROM "pcr_dev_jerome_reporting"."securityhub_finding_events"
        CROSS JOIN UNNEST(detail.findings) as t(finding)    
        GROUP BY finding.Id
  EOT
}


resource "aws_athena_named_query" "query_sh_latest_findings_count" {
  name        = "${var.name_prefix}reporting.sh_findings_unresolved_count"
  description = "count security-hub findings unresolved for each severity"
  database    = aws_glue_catalog_database.reporting_database.name
  workgroup   = aws_athena_workgroup.query_workgroup.id
  query       = <<-EOT
     SELECT
        e.detail.findings[1].AwsAccountId as AwsAccountId,
        e.detail.findings[1].Severity.Label as Severity_Label,    
        count(*) as count
    FROM "${aws_glue_catalog_database.reporting_database.name}"."${aws_glue_catalog_table.securityhub_findings_events_table.name}" AS e
    INNER JOIN "${aws_glue_catalog_database.reporting_database.name}"."securityhub_finding_last_event" AS v
        on e.detail.findings[1].Id = v.Id
        and e.detail.findings[1].UpdatedAt = v.lastUpdatedAt
    WHERE e.detail.findings[1].Workflow.Status <> 'RESOLVED'
    GROUP BY e.detail.findings[1].AwsAccountId, e.detail.findings[1].Severity.Label 
  EOT
}



resource "aws_athena_named_query" "query_sh_findings_unresolved" {
  name        = "${var.name_prefix}reporting.sh_findings_unresolved_summary"
  description = "all security-hub findings not resolved, mainly descriptive columns"
  database    = aws_glue_catalog_database.reporting_database.name
  workgroup   = aws_athena_workgroup.query_workgroup.id
  query       = <<-EOT
    SELECT
        e.detail.findings[1].AwsAccountId as AwsAccountId,
        e.detail.findings[1].Region as Region,
        e.detail.findings[1].Id as Id,
        e.detail.findings[1].Severity.Label as Severity_Label,    
        e.detail.findings[1].Title as Title,
        e.detail.findings[1].Description as Description,
        
        -- lifecycle
        e.detail.findings[1].RecordState as RecordState,
        e.detail.findings[1].Workflow.Status as Workflow_Status,    

        -- resource  
        e.detail.findings[1].Resources[1].Type as Resources_Type,
        e.detail.findings[1].Resources[1].Id as Resources_Id, 
        -- e.detail.findings[1].ProductFields as ProductFields,        

        -- how to fix        
        -- e.detail.findings[1].Compliance.Status as Compliance_Status,
        -- e.detail.findings[1].Remediation.Recommendation.Text as Remediation_Recommendation_Text,
        e.detail.findings[1].Remediation.Recommendation.Url as Remediation_Recommendation_Url,
        
        -- when
        -- detail.findings[1].CreatedAt as CreatedAt,
        e.detail.findings[1].FirstObservedAt as FirstObservedAt,
        e.detail.findings[1].LastObservedAt as LastObservedAt,
        e.detail.findings[1].UpdatedAt as UpdatedAt

        -- who said that
        -- e.detail.findings[1].ProductArn as ProductArn,
        -- e.detail.findings[1].Types as Types,
        -- e.detail.findings[1].CompanyName as CompanyName,
        -- e.detail.findings[1].ProductName as ProductName,    
        -- e.detail.findings[1].GeneratorId as GeneratorId,  
        
    FROM "${aws_glue_catalog_database.reporting_database.name}"."${aws_glue_catalog_table.securityhub_findings_events_table.name}" AS e 
    INNER JOIN "${aws_glue_catalog_database.reporting_database.name}"."securityhub_finding_last_event" AS v
        ON e.detail.findings[1].Id = v.Id
        AND e.detail.findings[1].UpdatedAt = v.lastUpdatedAt   
    WHERE e.detail.findings[1].Workflow.Status <> 'RESOLVED'         
    -- ORDER BY creation_date desc
  EOT
}


resource "aws_athena_named_query" "query_sh_findings_report" {
  name        = "${var.name_prefix}reporting.sh_findings_unresolved_report"
  description = "all security-hub findings events not resolved, descriptive columns for finding and AWS account"
  database    = aws_glue_catalog_database.reporting_database.name
  workgroup   = aws_athena_workgroup.query_workgroup.id
  query       = <<-EOT
    SELECT
        e.detail.findings[1].AwsAccountId as AwsAccountId,
        e.detail.findings[1].Region as Region,
        e.detail.findings[1].Id as Id,
        e.detail.findings[1].Severity.Label as Severity_Label,    
        e.detail.findings[1].Title as Title,
        e.detail.findings[1].Description as Description,
            
        -- lifecycle
        e.detail.findings[1].RecordState as RecordState,
        e.detail.findings[1].Workflow.Status as Workflow_Status,    

        -- resource  
        e.detail.findings[1].Resources[1].Type as Resources_Type,
        e.detail.findings[1].Resources[1].Id as Resources_Id, 
        -- e.detail.findings[1].ProductFields as ProductFields,        

        -- how to fix        
        -- e.detail.findings[1].Compliance.Status as Compliance_Status,
        -- e.detail.findings[1].Remediation.Recommendation.Text as Remediation_Recommendation_Text,
        e.detail.findings[1].Remediation.Recommendation.Url as Remediation_Recommendation_Url,
            
        -- when
        -- detail.findings[1].CreatedAt as CreatedAt,
        e.detail.findings[1].FirstObservedAt as FirstObservedAt,
        e.detail.findings[1].LastObservedAt as LastObservedAt,
        e.detail.findings[1].UpdatedAt as UpdatedAt,

        -- who said that
        -- e.detail.findings[1].ProductArn as ProductArn,
        -- e.detail.findings[1].Types as Types,
        -- e.detail.findings[1].CompanyName as CompanyName,
        -- e.detail.findings[1].ProductName as ProductName,    
        -- e.detail.findings[1].GeneratorId as GeneratorId,  
        
        -- a.account_id,
        -- a.creation_date,
        a.account_type,
        -- a.org_ou_id, 
        a.account_friendly_name,
        -- a.description,

        a.primary_responsible,
        a.manager_responsible,
        -- a.sec_responsible,
        -- a.cost_data.it_responsible,
        -- a.cost_data.domain_responsible,
        -- a.cost_data.product_responsible,

        a.cost_data.cmdb_id,
        a.cost_data.app_name
        -- a.cost_data.department,
        -- a.cost_data.domain_department,
        -- a.cost_data.product_department,
        -- a.cost_data.domain_id,
        -- a.cost_data.product_id,
        -- a.account_stage,
        -- a.approval_status,
        -- a.org_status,
        -- a.fpc_status    

    FROM "${aws_glue_catalog_database.reporting_database.name}"."${aws_glue_catalog_table.securityhub_findings_events_table.name}" AS e 
    INNER JOIN "${aws_glue_catalog_database.reporting_database.name}"."securityhub_finding_last_event" AS v
        ON e.detail.findings[1].Id = v.Id
        AND e.detail.findings[1].UpdatedAt = v.lastUpdatedAt
    WHERE e.detail.findings[1].Workflow.Status <> 'RESOLVED'         
    -- ORDER BY creation_date desc
  EOT
}