


import urllib.request
import json
from pyspark.sql.functions import udf, concat_ws
from pyspark.sql.types import StringType

API_KEY = "KEY"  #replace

URL = "https://api.anthropic.com/v1/messages"


# 🔥 CORE AI CALL (GENERIC)
def call_ai(prompt):
    try:
        payload = {
            "model": "claude-sonnet-4-6",
            "max_tokens": 200,
            "messages": [
                {"role": "user", "content": prompt}
            ]
        }

        data = json.dumps(payload).encode("utf-8")

        req = urllib.request.Request(URL, data=data)
        req.add_header("x-api-key", API_KEY)
        req.add_header("anthropic-version", "2023-06-01")
        req.add_header("content-type", "application/json")

        response = urllib.request.urlopen(req)
        result = json.loads(response.read().decode())

        if "content" in result:
            return result["content"][0]["text"]

        if "error" in result:
            return "AI Error: " + result["error"]["message"]

        return "No response"

    except Exception as e:
        return "AI Exception: " + str(e)


# 🔥 UNIVERSAL ENRICH FUNCTION
def enrich_dataframe(df, input_cols, prompt_template):

    # ✅ Handle single column OR multiple columns
    if isinstance(input_cols, list):
        df = df.withColumn("ai_input", concat_ws(", ", *input_cols))
        input_col = "ai_input"
    else:
        input_col = input_cols

    # 🔥 Safe prompt builder
    def ai_wrapper(text):
        try:
            safe_text = str(text)  # ✅ FIX: handles int, null, etc.
            prompt = prompt_template.replace("{input}", safe_text)
            return call_ai(prompt)
        except Exception as e:
            return "AI Exception: " + str(e)

    ai_udf = udf(ai_wrapper, StringType())

    return df.withColumn("ai_response", ai_udf(df[input_col]))