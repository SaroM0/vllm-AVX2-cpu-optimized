#!/usr/bin/env python3
"""
Example: Chat completion with vLLM CPU
Uses OpenAI-compatible API
"""

from openai import OpenAI

# Initialize client
client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="dummy-key",  # vLLM doesn't require real key
)


def chat_example():
    """Simple chat completion example"""
    print("=== Chat Completion Example ===\n")

    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "What is the capital of France?"},
    ]

    print("Sending request...")
    response = client.chat.completions.create(
        model="facebook/opt-125m",  # Change to your deployed model
        messages=messages,
        temperature=0.7,
        max_tokens=100,
    )

    print(f"\nAssistant: {response.choices[0].message.content}")
    print(f"\nTokens used: {response.usage.total_tokens}")
    print(f"Finish reason: {response.choices[0].finish_reason}")


def streaming_example():
    """Streaming chat completion example"""
    print("\n=== Streaming Example ===\n")

    messages = [{"role": "user", "content": "Tell me a short story about a robot."}]

    print("Assistant: ", end="", flush=True)

    stream = client.chat.completions.create(
        model="facebook/opt-125m",
        messages=messages,
        temperature=0.8,
        max_tokens=200,
        stream=True,
    )

    for chunk in stream:
        if chunk.choices[0].delta.content:
            print(chunk.choices[0].delta.content, end="", flush=True)

    print("\n")


def conversation_example():
    """Multi-turn conversation example"""
    print("\n=== Multi-turn Conversation ===\n")

    messages = [{"role": "system", "content": "You are a helpful math tutor."}]

    # First turn
    messages.append({"role": "user", "content": "What is 2 + 2?"})

    response = client.chat.completions.create(
        model="facebook/opt-125m", messages=messages, temperature=0.3, max_tokens=50
    )

    assistant_response = response.choices[0].message.content
    messages.append({"role": "assistant", "content": assistant_response})

    print("User: What is 2 + 2?")
    print(f"Assistant: {assistant_response}\n")

    # Second turn
    messages.append({"role": "user", "content": "Now multiply that by 3"})

    response = client.chat.completions.create(
        model="facebook/opt-125m", messages=messages, temperature=0.3, max_tokens=50
    )

    print("User: Now multiply that by 3")
    print(f"Assistant: {response.choices[0].message.content}")


if __name__ == "__main__":
    try:
        chat_example()
        streaming_example()
        conversation_example()
    except Exception as e:
        print(f"\nError: {e}")
        print("\nMake sure vLLM is running:")
        print("  docker-compose up -d")
        print("  curl http://localhost:8000/health")
