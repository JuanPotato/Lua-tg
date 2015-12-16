--[[
    sender.lua by @awkward_potato
    Usage:
        sender = require('sender')
        tg = sender(ip, port)
        tg:send_msg(user_id, text)
        link = tg:export_chat_link(chat_id)
        print(link)
]]--

local socket = require("socket")

local Sender = function(ip, port)
    ip = ip or "localhost"
    port = port or 4458

    return {
        sender = socket.connect(ip, port),

        -- Raw send function
        _send = function(self, command)
            self.sender:send(command)
            local data = self.sender:receive(tonumber(string.match(self.sender:receive("*l"), "ANSWER (%d+)")))
            self.sender:receive("*l") -- End of output
            return data:gsub('\n$','')
        end,
        
        _filter_text = function(self, str)
            return string.gsub(str, "\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\t", "\\t")
        end,

        -- Send function with filters, replies, and previews
        send = function(self, command, reply_id, disable_preview)
            local preview_part = "[enable_preview] "
            local reply_part = ""
            
            if reply_id then
                if type(reply_id) ~= "number" then
                    print("I need an int for reply_id m8")
                else
                    reply_part = "[reply=" .. reply_id .. "] "
                end
            end
            
            if disable_preview then
                preview_part = "[disable_preview] "
            end
            
            return self._send(self, reply_part .. preview_part .. command .. "\n")
        end,

        -- Send message function: groups will be based as negative ids
        send_msg = function(self, user_id, text, reply_id, disable_preview)
            if type(user_id) ~= "number" then
                print("I need an int for user_id m8")
                return
            end

            local user_type = user_id > 0 and "user#" or "chat#"
            local user_id = user_id > 0 and user_id or user_id * -1
            local text = self._filter_text(self, text)

            return self.send(self, "msg " .. user_type .. user_id .. ' "' .. text .. '"', reply_id, disable_preview)
        end,

        -- Get the invite link of a chat
        export_chat_link = function(self, chat_id)
            local chat_id = chat_id < 0 and chat_id * -1 or chat_id
            return self.send(self, "export_chat_link chat#" .. chat_id)
        end,

        -- Removes a user from a chat
        chat_del_user = function(self, chat_id, user_id)
            local chat_id = chat_id < 0 and chat_id * -1 or chat_id
            return self.send(self, "chat_del_user chat#" .. chat_id .. " user#" .. user_id)
        end,

        -- Adds a user to a chat
        chat_add_user = function(self, chat_id, user_id)
            local chat_id = chat_id < 0 and chat_id * -1 or chat_id
            return self.send(self, "chat_add_user chat#" .. chat_id .. " user#" .. user_id)
        end,

        -- Adds a user to a chat
        rename_chat = function(self, chat_id, new_name)
            local chat_id = chat_id < 0 and chat_id * -1 or chat_id
            local new_name = self._filter_text(self, new_name)
            return self.send(self, "rename_chat chat#" .. chat_id .. ' "' .. new_name .. '"')
        end
    }
end

return Sender