"""
This file contains the functions to generate and send the alert to Microsoft Teams
"""

import os
import json
import requests

def generate_alert(template_path, projects, services):
    """
    This function receives the path of the template file and the data to be inserted in the alert.
    """
    print ("10. Opening file")
    billing_dashboard_url = os.environ.get('BILLING_DASHBOARD_URL')
    with open(template_path, "r", encoding="utf-8") as read_file:
        template = json.load(read_file)

    projects0 = projects
    services0 = services
    #print("debug 000")
    #print(services0)

    projects = ', '.join(projects["Project_Name"])
    services = ', '.join(services["Service_Description"])
    print("11. Printing projects")
    print(projects)

    #from datetime import datetime, timedelta
    #yesterday = datetime.now() - timedelta(days=1)
    #yesterday_str = str(yesterday.strftime("%Y-%m-%d"))
    #print("Wczoraj:", yesterday.strftime("%Y-%m-%d"))  # format: RRRR-MM-DD

    condition_name = "GCP Budget Alert"
    summary = "GCP billing costs for previous day."

    template["summary"] = condition_name
    template["body"][0]["text"] = summary
    #next(f for s in template["body"] if s.get("type") == "FactSet"
    # for f in s["facts"] if f.get("title") == "Projects")["value"] = projects

    # Project costs
    project_column = next((col for col in projects0.columns if "project" in col.lower() or "instance" in col.lower()), None)
    cost_column = next((col for col in projects0.columns if "cost" in col.lower()), None)
    # if exist
    if not project_column or not cost_column:
      raise ValueError("Nie znaleziono kolumny project ani costs w dataframe.")
    # facts
    facts = [
      {
        "title": str(row[project_column]),
        "value": f"{row[cost_column]:.2f}"
      }
      for _, row in projects0.iterrows()
    ]
    # Aktualizacja template
    for section in template["body"]:
      if section.get("type") == "FactSet":
        section["facts"] = facts
        break

    facts.append({"title": "", "value": ""})
    facts.append({"title": "GCP service costs for the previous day:", "value": ""})

    # Service costs
    service_column = next((col for col in services0.columns if "service" in col.lower() or "instance" in col.lower()), None)
    cost_column = next((col for col in services0.columns if "cost" in col.lower()), None)
    # if exist
    if not service_column or not cost_column:
      raise ValueError("Error - cant find service costs in dataframe.")
    # facts
    facts = [
      {
        "title": str(row[service_column]),
        "value": f"{row[cost_column]:.2f}"
      }
      for _, row in services0.iterrows()
    ]
    # Aktualizacja template
    for section in template["body"]:
      if section.get("type") == "FactSet":
        section["facts"] = section["facts"] + facts
        break


    #template["potentialAction"][0]["targets"][0]["uri"] = billing_dashboard_url

    #print(template)
    return template

def send_alert(teams_alert):
    """
    This function receives the alert and sends it to Microsoft Teams.
    """
    headers = {"Content-Type": "application/json"}
    # webhook_url = os.environ.get('WEBHOOK_URL')
    webhook_url = "https://prod-123.zzzzzzzzzz.logic.azure.com:443/workflows/xxx/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=zzz"

    try:
        response = requests.post(webhook_url, headers=headers, json=teams_alert, timeout=5)
        response.raise_for_status()
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err) from err
    print("Teams alert successfully sent")
