from langchain.llms import OpenAI
from langchain_core.messages import HumanMessage
import os

# Load API key securely
api_key = os.getenv("OPENAI_API_KEY")

# Initialize the model
llm = OpenAI(temperature=0.7)

response = llm.invoke("What is a language model?")
# Or with message format:
# response = llm.invoke([HumanMessage(content="What is a language model?")])
print(response)