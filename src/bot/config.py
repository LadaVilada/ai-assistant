import os
import boto3

AWS_REGION = "us-east-1"
DYNAMODB_TABLE = "ChatHistory"

# Подключаемся к DynamoDB
dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
chat_table = dynamodb.Table(DYNAMODB_TABLE)