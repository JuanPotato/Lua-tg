--[[
    sender.lua by @awkward_potato
    Usage:
        sender = require('sender')
        tg = sender(ip, port)
        
         f = open("commands.txt")
        for line in f.read().split("\n"):

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
        _send = function(self, command, output)
            if not output then
                self.sender:send(command)
                local data = self.sender:receive(tonumber(string.match(self.sender:receive("*l"), "ANSWER (%d+)")))
                self.sender:receive("*l") -- End of output
                return data:gsub('\n$','')
            else
                local s = socket.connect(ip, port)
                s:send(command)
                s:close()
            end
        end,

        _filter_text = function(self, str)
            return string.gsub(str, "\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\t", "\\t")
        end,

        -- Send function with filters, replies, and previews
        send = function(self, command, reply_id, disable_preview, output)
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

            return self._send(self, reply_part .. preview_part .. command .. "\n", no_output)
        end,

        -- Adds a user as a contact
        add_contact = function(self, phone, first_name, last_name)
            local command = 'add_contact %s "%s" "%s"'
            return self.send(self, command:format(phone, first_name, last_name))
        end,

        --  Blocks user
        block_user = function(self, user_id)
            local command = 'block_user %s'
            return self.send(self, command:format(user_id))
        end,

        -- Adds a user to a chat
        chat_add_user = function(self, chat_id, user_id)
            local command = 'chat_add_user chat#%s user#%s'
            return self.send(self, command:format(math.abs(chat_id), user_id))
        end,

        -- Removes a user from a chat
        chat_del_user = function(self, chat_id, user_id)
            local command = 'chat_del_user _user chat#%s user#%s'
            return self.send(self, command:format(math.abs(chat_id), user_id))
        end,

        --  Returns info about chat (id, members, admin, etc.)
        chat_info = function(self, chat_id)
            local command = 'chat_info %s'
            return self.send(self, command:format(math.abs(chat_id)), true)
        end,

        --  Sets chat photo. Photo will be cropped to square
        chat_set_photo = function(self, chat_id, filename)
            local command = 'chat_set_photo %s %s'
            return self.send(self, command:format(math.abs(chat_id), filename))
        end,

        --  Returns contact list
        contact_list = function(self)
            local command = 'contact_list'
            return self.send(self, command, true)
        end,

        --  Searches user by username
        contact_search = function(self, username)
            local command = 'contact_search %s'
            local username = self._filter_text(self, username)
            return self.send(self, command:format(username), true)
        end,

        -- Get the invite link of a chat
        export_chat_link = function(self, chat_id)
            local command = 'export_chat_link chat#%s'
            return self.send(self, command:format(math.abs(chat_id)), true)
        end,

        -- Send message function: groups will be based as negative ids
        msg = function(self, user_id, text, reply_id, disable_preview)
            if type(user_id) ~= "number" then
                print("I need an int for user_id m8")
                return
            end

            local command = 'msg %s%s "$s"'
            local user_type = user_id > 0 and "user#" or "chat#"
            local text = self._filter_text(self, text)
            return self.send(self, command:format(user_type, math.abs(user_id), text), reply_id, disable_preview)
        end,

        -- Quits telegram-cli immediately
        quit = function(self)
            self.sender:send("quit\n")
        end,

        -- Renames a chat
        rename_chat = function(self, chat_id, new_name)
            local command = 'rename_chat chat#%s %s'
            local new_name = self._filter_text(self, new_name)
            return self.send(self, command:format(math.abs(chat_id), new_name))
        end,

        -- Waits for all queries to end, then quits telegram-cli
        safe_quit = function(self)
            self.sender:send("safe_quit\n")
        end,

        -- Returns message contents
        view = function(self, msg_id)
            local command = 'view %s'
            return self.send(self, command:format(msg_id), true)
        end
    }
end

return Sender
