# Lua-tg
Allows you to send tg-cli commands from Lua via TCP.

### Usage
```lua
sender = require('sender')
tg = sender(ip, port)
tg:msg(user_id, text)
link = tg:export_chat_link(chat_id)
print(link)
```

Thanks to [@topkecleon](https://github.com/topkecleon) for petty improvements.
