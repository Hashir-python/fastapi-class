from fastapi import FastAPI
from agent.assistant import assistant_agent
app = FastAPI()


@app.get("/")
def read_root():
    return {"Hello": "World"}

@app.get("/products")
def read_products():
    return {"Name": "Samsung S26 Ultra"}

@app.get("/ask")
def ask_agent(query: str):
    response = assistant_agent.invoke(
    {"messages": [{"role": "user", "content": query}]}
    )
    return {"response": response['messages'][-1].content}
