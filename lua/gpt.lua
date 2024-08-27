local openai = require("openai")
local response = openai.chat_completions({
    model = "gpt-4",
    messages = {
        { role = "user", content = "Hello!" }
    }
})
print(response.choices[1].message.content)


