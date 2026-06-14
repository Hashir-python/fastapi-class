from langchain_groq import ChatGroq
from langchain.agents import create_agent
from dotenv import load_dotenv
import os

load_dotenv()  # Load environment variables from .env file

llm = ChatGroq(
    model="openai/gpt-oss-120b",
    temperature=0,
    max_retries=2,
    api_key=os.getenv("GROQ_API_KEY")    
)


def get_weather(city: str) -> str:
    """Get weather for a given city."""
    # Real API 
    return f"It's currently sunny in {city}!"

def make_pdf(title:str,content:str) -> str:
    """Create a PDF with the given title and content."""
    
    # Real API 
    return f"PDF '{title}' created with content: {content}"

def get_my_name() -> str:
    """Get the AI agent name."""
    return "Niki"

assistant_agent = create_agent(
    model=llm,
    tools=[get_weather, make_pdf, get_my_name],
    system_prompt="You are a helpful assistant"
)