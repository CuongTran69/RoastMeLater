#!/usr/bin/env python3
import requests
import json

def test_api():
    api_key = "YOUR_API_KEY_HERE"
    base_url = "YOUR_BASE_URL_HERE"
    model_name = "anthropic:3.7-sonnet"
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": model_name,
        "messages": [
            {"role": "user", "content": "Hello"}
        ],
        "max_tokens": 10
    }
    
    print("🔄 Testing API...")
    print(f"URL: {base_url}")
    print(f"Model: {model_name}")
    print(f"API Key: {api_key[:10]}...")
    
    try:
        response = requests.post(base_url, headers=headers, json=payload, timeout=30)
        print(f"📡 HTTP Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            if "choices" in data and len(data["choices"]) > 0:
                content = data["choices"][0]["message"]["content"]
                print("✅ API hoạt động tốt!")
                print(f"Response: {content}")
            else:
                print("✅ API connected but response format unexpected")
                print(f"Response: {data}")
        else:
            print("❌ API Error")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")

if __name__ == "__main__":
    test_api()
