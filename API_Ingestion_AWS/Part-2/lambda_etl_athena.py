import boto3
import os
import time

glue = boto3.client("glue")
athena = boto3.client("athena")

def lambda_handler(event, context):
    glue_job_name = os.environ["GLUE_JOB_NAME"]
    athena_db = os.environ["ATHENA_DATABASE"]
    athena_query = os.environ["ATHENA_QUERY"]
    athena_output = os.environ["ATHENA_OUTPUT"]

    try:
        # ---- Step 1: Start Glue Job ----
        print(f"Starting Glue Job: {glue_job_name}")
        glue_response = glue.start_job_run(JobName=glue_job_name)
        job_run_id = glue_response["JobRunId"]

        # ---- Step 2: Wait for Glue completion ----
        status = "RUNNING"
        while status in ["RUNNING", "STARTING", "STOPPING"]:
            time.sleep(30)
            run_state = glue.get_job_run(JobName=glue_job_name, RunId=job_run_id)
            status = run_state["JobRun"]["JobRunState"]
            print(f"Glue Job {job_run_id} status: {status}")

        if status != "SUCCEEDED":
            raise Exception(f"Glue job failed with status: {status}")

        # ---- Step 3: Run Athena Query ----
        print(f"Running Athena query: {athena_query}")
        athena_response = athena.start_query_execution(
            QueryString=athena_query,
            QueryExecutionContext={"Database": athena_db},
            ResultConfiguration={"OutputLocation": athena_output}
        )

        query_execution_id = athena_response["QueryExecutionId"]

        # ---- Step 4: Wait for Athena completion ----
        query_status = "RUNNING"
        while query_status in ["RUNNING", "QUEUED"]:
            time.sleep(5)
            result = athena.get_query_execution(QueryExecutionId=query_execution_id)
            query_status = result["QueryExecution"]["Status"]["State"]

        if query_status != "SUCCEEDED":
            raise Exception(f"Athena query failed with status: {query_status}")

        print(f"Athena query succeeded: {query_execution_id}")
        return {
            "statusCode": 200,
            "body": f"Glue and Athena workflow completed successfully. Query ID: {query_execution_id}"
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": str(e)
        }

