--[[
    sender.lua by @awkward_potato
    Usage:
        sender = require('sender')
        tg = sender(ip, port)
        tg:msg(user_id, text)
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
            if output then
                local s = socket.connect(ip, port)
                s:send(command)
                local data = s:receive(tonumber(string.match(s:receive("*l"), "ANSWER (%d+)")))
                s:receive("*l") -- End of output
                s:close()
                return data:gsub('\n$','')
            else
                self.sender:send(command)
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
            local command = 'add_contact %s %q %q'
            return self.send(self, command:format(phone, first_name, last_name))
        end,

        --  Blocks user
        block_user = function(self, user_id)
            local command = 'block_user %s'
            return self.send(self, command:format(user_id))
        end,

-- Begin Channel Stuff

        -- Makes a channel ID in any format compliant with tg
        channelize = function(channel_id)
            channel_id = math.abs(channel_id)
            if tostring(channel_id):len() > 10 then
                return channel_id - 1000000000000
            else
                return channel_id
            end
        end,

        -- Adds a user to a channel/supergroup
        channel_invite = function(self, channel_id, user_id)
            channel_id = self.channelize(channel_id)
            local command = 'channel_invite channel#%s user#%s'
            return self.send(self, command:format(channel_id, user_id))
        end,

        -- Kicks a user from a supergroup
        channel_kick = function(self, channel_id, user_id)
            channel_id = self.channelize(channel_id)
            local command = 'channel_kick channel#%s user#%s'
            return self.send(self, command:format(channel_id, user_id))
        end,

        -- Sets the description for a channel/supergroup
        channel_set_about = function(self, channel_id, about)
            channel_id = self.channelize(channel_id)
            local command ='channel_set_about channel#%s %q'
            local about = self._filter_text(self, about)
            return self.send(self, command:format(channel_id, about))
        end,

        -- Sets an admin for a channel/supergroup
        channel_set_admin = function(self, channel_id, user_id, setting)
            -- Where setting is 0, 1, or 2
            channel_id = self.channelize(channel_id)
            local command = 'channel_set_admin channel#%s user#%s %s'
            return self.send(self, command:format(channel_id, user_id, setting))
        end,

-- End Channel Stuff

        -- Adds a user to a chat
        chat_add_user = function(self, chat_id, user_id)
            local command = 'chat_add_user chat#%s user#%s'
            return self.send(self, command:format(math.abs(chat_id), user_id))
        end,

        -- Removes a user from a chat
        chat_del_user = function(self, chat_id, user_id)
            local command = 'chat_del_user chat#%s user#%s'
            return self.send(self, command:format(math.abs(chat_id), user_id))
        end,

        --  Returns info about chat (id, members, admin, etc.)
        chat_info = function(self, chat_id)
            local command = 'chat_info %s'
            return self.send(self, command:format(math.abs(chat_id)), true)
        end,

        --  Sets chat photo. Photo will be cropped to square
        chat_set_photo = function(self, chat_id, filename)
            local command = 'chat_set_photo chat#%s %s'
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

        --  Deletes contact from contact list
        del_contact = function(self, user_id)
            local command = 'del_contact %s'
            return self.send(self, command:format(user_id))
        end,

        --  Deletes message
        delete_msg = function(self, msg_id)
            local command = 'delete_msg %s'
            return self.send(self, command:format(msg_id))
        end,

        --  Returns card that can be imported by another user with import_card method
        export_card = function(self)
            local command = 'export_card'
            return self.send(self, command, true)
        end,

        -- Get the invite link of a chat
        export_chat_link = function(self, chat_id)
            local command = 'export_chat_link chat#%s'
            return self.send(self, command:format(math.abs(chat_id)), true)
        end,

        --  Get message by id
        get_message = function(self, msg_id)
            local command = 'get_message %s'
            return self.send(self, command:format(msg_id), true)
        end,

        --  Get our user info
        get_self = function(self)
            local command = 'get_self'
            return self.send(self, command, true)
        end,

        --  Gets user by card and prints it name. You can then send messages to him as usual
        import_card = function(self, card)
            local command = 'import_card %s'
            return self.send(self, command:format(card), true)
        end,

        --  Downloads audio file and returns path
        load_audio = function(self, msg_id)
            local command = 'load_audio %s'
            return self.send(self, command:format(msg_id), true)
        end,

        --  Downloads group photo and returns path
        load_chat_photo = function(self, chat_id)
            local command = 'load_chat_photo chat#%s'
            return self.send(self, command:format(math.abs(chat_id)), true)
        end,

        --  Downloads document file and returns path
        load_document = function(self, msg_id)
            local command = 'load_document %s'
            return self.send(self, command:format(msg_id), true)
        end,

        --  Downloads document file thumbnail and returns path
        load_document_thumb = function(self, msg_id)
            local command = 'load_document_thumb %s'
            return self.send(self, command:format(msg_id), true)
        end,

        --  Downloads file and returns path
        load_file = function(self, msg_id)
            local command = 'load_file %s'
            return self.send(self, command:format(msg_id), true)
        end,

        --  Downloads file thumbnail and returns path
        load_file_thumb = function(self, msg_id)
            local command = 'load_file_thumb %s'
            return self.send(self, command:format(msg_id), true)
        end,

        --  Downloads photo and returns path
        load_photo = function(self, msg_id)
            local command = 'load_photo %s'
            return self.send(self, command:format(msg_id), true)
        end,

        --  Downloads a users's photo and returns path
        load_user_photo = function(self, user_id)
            local command = 'load_photo %s'
            return self.send(self, command:format(user_id), true)
        end,

        --  Downloads video and returns path
        load_video = function(self, msg_id)
            local command = 'load_video %s'
            return self.send(self, command:format(msg_id), true)
        end,

        --  Downloads video thumbnail and returns path
        load_video_thumb = function(self, msg_id)
            local command = 'load_video_thumb %s'
            return self.send(self, command:format(msg_id), true)
        end,

        -- Send message function: groups will be based as negative ids
        msg = function(self, user_id, text, reply_id, disable_preview)
            if type(user_id) ~= "number" then
                print("I need an int for user_id m8")
                return
            end

            local command = 'msg %s%s %q'
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
