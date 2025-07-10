"""
This is the main file of the project. 
It is responsible for the execution of the project. 
It uses the BigQuery client to perform a query and get the data. 
Then, it uses the json_operations.py file to generate the alert and send it to Microsoft Teams.
"""

from google.cloud import bigquery
import json_operations as json_op
import functions_framework

@functions_framework.http
def billing_alerts_teams(request):
  try:
    print ("01. Big Query request")
    """
    Fucntion is executed when the endpoint is called.
    It uses the BigQuery client to perform a query and get the data. 
    Then, it uses the json_operations.py file to generate the alert and send it to Microsoft Teams.
    """
    client = bigquery.Client()

    # Perform a query.
    #   -- Costs take a few hours to show up in your BigQuery export,and might take longer than 24 hours.
    query_for_project = """
    SELECT project.name AS `Project_Name`, project.id AS `Project ID`, project.number AS `Project Number`, SUM(CAST(cost AS NUMERIC)) AS `Cost`, SUM( IFNULL( ( SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c WHERE c.type IN ('SUSTAINED_USAGE_DISCOUNT', 'DISCOUNT', 'COMMITTED_USAGE_DISCOUNT', 'FREE_TIER', 'COMMITTED_USAGE_DISCOUNT_DOLLAR_BASE', 'SUBSCRIPTION_BENEFIT', 'RESELLER_MARGIN', 'FEE_UTILIZATION_OFFSET')), 0)) AS `Discounts`, SUM( IFNULL( ( SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c WHERE c.type IN ('CREDIT_TYPE_UNSPECIFIED', 'PROMOTION')), 0)) AS `Promotions and others`, SUM(CAST(cost AS NUMERIC)) + SUM( IFNULL( ( SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c WHERE c.type IN ('SUSTAINED_USAGE_DISCOUNT', 'DISCOUNT', 'COMMITTED_USAGE_DISCOUNT', 'FREE_TIER', 'COMMITTED_USAGE_DISCOUNT_DOLLAR_BASE', 'SUBSCRIPTION_BENEFIT', 'RESELLER_MARGIN', 'FEE_UTILIZATION_OFFSET')), 0)) + SUM( IFNULL( ( SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c WHERE c.type IN ('CREDIT_TYPE_UNSPECIFIED', 'PROMOTION')), 0)) AS `Subtotal` FROM `billing-prd-12345.billing_export.gcp_billing_export_resource_v1_016EA2_5A1CC7_83A403` WHERE usage_start_time >= TIMESTAMP(DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 DAY), "America/Los_Angeles") AND usage_start_time < TIMESTAMP(CURRENT_DATE("America/Los_Angeles"), "America/Los_Angeles") GROUP BY project.name, project.id, project.number HAVING Cost > 0 ORDER BY Subtotal DESC
    """

    query_for_service = """
    SELECT service.description AS `Service_Description`, SUM(CAST(cost AS NUMERIC)) AS `Cost`, SUM( IFNULL( ( SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c WHERE c.type IN ('SUSTAINED_USAGE_DISCOUNT', 'DISCOUNT', 'COMMITTED_USAGE_DISCOUNT', 'FREE_TIER', 'COMMITTED_USAGE_DISCOUNT_DOLLAR_BASE', 'SUBSCRIPTION_BENEFIT', 'RESELLER_MARGIN', 'FEE_UTILIZATION_OFFSET')), 0)) AS `Discounts`, SUM( IFNULL( ( SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c WHERE c.type IN ('CREDIT_TYPE_UNSPECIFIED', 'PROMOTION')), 0)) AS `Promotions and others`, SUM(CAST(cost AS NUMERIC)) + SUM( IFNULL( ( SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c WHERE c.type IN ('SUSTAINED_USAGE_DISCOUNT', 'DISCOUNT', 'COMMITTED_USAGE_DISCOUNT', 'FREE_TIER', 'COMMITTED_USAGE_DISCOUNT_DOLLAR_BASE', 'SUBSCRIPTION_BENEFIT', 'RESELLER_MARGIN', 'FEE_UTILIZATION_OFFSET')), 0)) + SUM( IFNULL( ( SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c WHERE c.type IN ('CREDIT_TYPE_UNSPECIFIED', 'PROMOTION')), 0)) AS `Subtotal` FROM `billing-prd-12345.billing_export.gcp_billing_export_resource_v1_016EA2_5A1CC7_83A403` WHERE usage_start_time >= TIMESTAMP(DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 DAY), "America/Los_Angeles") AND usage_start_time < TIMESTAMP(CURRENT_DATE("America/Los_Angeles"), "America/Los_Angeles") GROUP BY service.description HAVING Cost > 0 ORDER BY Subtotal DESC
    """

    higher_cost_project = client.query_and_wait(query_for_project).to_dataframe()
    higher_cost_service = client.query_and_wait(query_for_service).to_dataframe()
    print("02. GCP project costs for the previous day:")
    print(higher_cost_project)
    print("-----------------------------------")
    print("03. GCP service costs for the previous day:")
    print(higher_cost_service)

    template_path = "template.json"
    teams_alert = json_op.generate_alert(template_path, higher_cost_project, higher_cost_service)
    print("-----------------------------------------")
    print("04. teams_alert:")
    print(teams_alert)
    print("-----------------------------------------")

    json_op.send_alert(teams_alert)
    print("Ok!")
    return "OK", 200  
  except Exception as e:
    print("Exception:", e)

if __name__ == "__main__":
    billing_alerts_teams()
