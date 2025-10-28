#!/usr/bin/env python3
"""
Example: Text completion with vLLM CPU
"""

from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="dummy-key"
)

def simple_completion():
    """Basic completion example"""
    print("=== Simple Completion ===\n")
    
    prompt = "Once upon a time in a faraway land"
    
    response = client.completions.create(
        model="facebook/opt-125m",
        prompt=prompt,
        max_tokens=50,
        temperature=0.8
    )
    
    print(f"Prompt: {prompt}")
    print(f"Completion: {response.choices[0].text}")
    print(f"Tokens: {response.usage.total_tokens}")


def code_completion():
    """Code generation example"""
    print("\n=== Code Completion ===\n")
    
    prompt = """def fibonacci(n):
    \"\"\"Calculate nth Fibonacci number\"\"\"
"""
    
    response = client.completions.create(
        model="facebook/opt-125m",
        prompt=prompt,
        max_tokens=100,
        temperature=0.2,  # Lower temperature for code
        stop=["\n\n"]     # Stop at blank line
    )
    
    print(f"Prompt:\n{prompt}")
    print(f"Generated code:\n{response.choices[0].text}")


def batch_completion():
    """Batch completion example"""
    print("\n=== Batch Completion ===\n")
    
    prompts = [
        "The capital of France is",
        "The largest ocean on Earth is",
        "Python is a programming language that"
    ]
    
    for prompt in prompts:
        response = client.completions.create(
            model="facebook/opt-125m",
            prompt=prompt,
            max_tokens=20,
            temperature=0.5
        )
        
        completion = response.choices[0].text.strip()
        print(f"Q: {prompt}")
        print(f"A: {completion}\n")


if __name__ == "__main__":
    try:
        simple_completion()
        code_completion()
        batch_completion()
    except Exception as e:
        print(f"\nError: {e}")
        print("\nMake sure vLLM is running on port 8000")

