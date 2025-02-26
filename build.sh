#!/bin/bash
set -e

echo "Cleaning up..."
rm -rf package lambda.zip

echo "Creating DynamoDB table if needed..."
python create_table.py

echo "Installing dependencies..."
mkdir -p package
pip install --target ./package -r requirements-lambda.txt

echo "Creating deployment package..."
cd package
zip -r ../lambda.zip .
cd ..

echo "Adding lambda_function.py to the root of the archive..."
cp src/lambdas/ai-assistant/lambda_function.py .
zip -g lambda.zip lambda_function.py
#zip -g lambda.zip src/lambda_function.py

echo "Done! Lambda package created: lambda.zip"
