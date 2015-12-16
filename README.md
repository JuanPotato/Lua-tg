# Lua-tg
Allows you to send tg-cli command line commands via tcp in lua

### Usage
```lua
sender = require('sender')
tg = sender(ip, port)
tg:send_msg(user_id, text)
link = tg:export_chat_link(chat_id)
print(link)
```

Thanks to [@topkecleon](https://github.com/topkecleon) for stuff
