#!/bin/bash
# fix-openai-dependencies.sh

echo "Исправление несовместимостей в пакете OpenAI..."

# Удаляем текущие файлы сборки
rm -rf package lambda.zip

# Создаем пакет с правильными версиями зависимостей
mkdir -p package
cd package

# Устанавливаем конкретные версии, которые гарантированно работают вместе
pip install --target=. openai==1.3.5 httpx==0.24.1 pydantic==1.10.8 requests==2.31.0

# Очищаем лишние файлы для уменьшения размера пакета
find . -type d -name "__pycache__" -exec rm -rf {} +  2>/dev/null || true
find . -type d -name "*.dist-info" -exec rm -rf {} +  2>/dev/null || true
find . -type d -name "*.egg-info" -exec rm -rf {} +  2>/dev/null || true

# Создаем архив с зависимостями
zip -r ../lambda.zip . -x "*.pyc" "*__pycache__*" "*.so" "*.DS_Store" > /dev/null

# Возвращаемся в корневую директорию
cd ..

# Создаем или обновляем файл lambda_function.py
cat > lambda_function.py << 'EOF'
import sys
import os
import json
from openai import OpenAI
from pydantic import BaseModel, ValidationError

# Ensure AWS Lambda finds dependencies
sys.path.insert(0, os.path.join(os.getcwd()))

# Load API key securely
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("Missing OpenAI API key!")

# Initialize OpenAI client with API key (without additional parameters)
client = OpenAI(api_key=api_key)

# Define input validation using Pydantic
class QueryModel(BaseModel):
    question: str
    model: str = "gpt-4o-mini"  # Default to more efficient model

def lambda_handler(event, context):
    try:
        # Parse request body
        body = json.loads(event["body"]) if isinstance(event["body"], str) else event["body"]
        query_data = QueryModel(**body)  # Validates input with Pydantic

    except (KeyError, TypeError, json.JSONDecodeError, ValidationError) as e:
        return {
            "statusCode": 400,
            "body": json.dumps({
                "error": "Invalid or missing 'question' field",
                "details": str(e)
            })
        }

    # Call OpenAI API with latest client format
    try:
        # Removed store=True to avoid any potential issues
        response = client.chat.completions.create(
            model=query_data.model,
            messages=[{"role": "user", "content": query_data.question}]
        )

        # Access response properties using the new structure
        answer = response.choices[0].message.content

        # Include some metadata in response
        return {
            "statusCode": 200,
            "body": json.dumps({
                "answer": answer,
                "model": query_data.model,
                "usage": {
                    "prompt_tokens": response.usage.prompt_tokens,
                    "completion_tokens": response.usage.completion_tokens,
                    "total_tokens": response.usage.total_tokens
                }
            })
        }

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
EOF

# Добавляем lambda_function.py в архив
zip -g lambda.zip lambda_function.py > /dev/null

echo "Архив создан с корректными версиями зависимостей!"
echo "Размер архива: $(du -h lambda.zip | cut -f1)"
echo ""
echo "Для загрузки в Lambda выполните:"
echo "aws lambda update-function-code --function-name ai-assistant --zip-file fileb://lambda.zip"