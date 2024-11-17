## http 1.1 的 streaming response
在 HTTP 1.1的时候，在一个tcp连接上，server发送常规数据，会将 Content-Length 带上，告诉客户端要接收的数据大小。客户端收到指定大小后，就会认为完成。但是如果是从DB里读数据，或者是 streaming 数据，那么server会给分成不同的 CHUNK，带上Transfer-Encoding: Chunked的 Header，此时 content-length是每一次 chunk的大小。直到发完数据，发一个大小为0的数据块，并发两次 CRLF 。客户端通过这样的数据，来确定server数据传输完成。
在 python的 fastAPI的实现里，默认情况下，http 1.1是没有做连接复用的，也就意味着，如果是发完数据，就会立即关闭tcp连接

## http 2.0 的 streaming response
在 http 2.0 的时候，由于同一个tcp连接上的多个http请求，可以并行发送，所以每一个http请求，都有一个 Stream ID，发数据的时候，会发送 DATA frames，发完数据，会在最后一个数据帧上带 END_STREAM标志，通过这个标志，确保消息发送完成


## 一个stream response的fastAPI示例
下面的示例写了一个 /chat接口，这个接口接受一个 POST 请求，POST body格式是 {"message": "anything you may ask"}，之后接口会访问 chatGPT的接口，然后通过 streaming response的方式，逐步返回

```python
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware

from openai import AzureOpenAI
import os
import asyncio
from dotenv import load_dotenv
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

app = FastAPI(debug=True)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
client = AzureOpenAI(
    api_key=os.getenv("AZURE_OPENAI_API_KEY"),
    api_version=os.getenv("AZURE_OPENAI_API_VERSION"),
    azure_endpoint=os.getenv("AZURE_OPENAI_API_BASE")
)

async def sse_chat_generator(prompt):
    try:
        logger.info(f"Sending prompt to API: {prompt}")
        response = client.chat.completions.create(
            model=os.getenv("AZURE_OPENAI_MODEL", "gpt-4o-mini"), 
            messages=[{"role": "user", "content": prompt}],
            stream=True,
        )
        yield "data: " # 加 data: 主要是为了 vue 里的过滤处理。需要看下vue
        for chunk in response:
            if chunk.choices and len(chunk.choices) > 0:
                delta = chunk.choices[0].delta
                if delta and delta.content:
                    yield delta.content 
            await asyncio.sleep(0.01)
    except Exception as e:
        logger.error(f"Error in sse_chat_generator: {e}", exc_info=True)
        yield f"Error: {str(e)}"

@app.post("/chat")
async def chat(request: Request):
    try:
        data = await request.json()
        prompt = data.get("message", "")
        logger.info(f"Received chat request with prompt: {prompt}")
        return StreamingResponse(sse_chat_generator(prompt), media_type="text/event-stream")
    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}", exc_info=True)
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    logger.info("Starting the server...")
    uvicorn.run(app, host="0.0.0.0", port=8080)

```