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

Project by JuanPotato with the help of topkecleon.
