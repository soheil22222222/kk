package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  ..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")

local f = assert(io.popen('/usr/bin/git describe --tags', 'r'))
VERSION = assert(f:read('*a'))
f:close()

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

  msg = backward_msg_format(msg)

  local receiver = get_receiver(msg)
  print(receiver)
  --vardump(msg)
  --vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
      if redis:get("bot:markread") then
        if redis:get("bot:markread") == "on" then
          mark_read(receiver, ok_cb, false)
        end
      end
    end
  end
end

function ok_cb(extra, success, result)

end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)
  -- See plugins/isup.lua as an example for cron

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end

  -- Before bot was started
  if msg.date < os.time() - 5 then
    print('\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.id == our_id then
    print('\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
    --send_large_msg(*group id*, msg.text) *login code will be sent to GroupID*
    return false
  end

  return true
end

--
function pre_process_service_msg(msg)
   if msg.service then
      local action = msg.action or {type=""}
      -- Double ! to discriminate of normal actions
      msg.text = "!!tgservice " .. action.type

      -- wipe the data to allow the bot to read service messages
      if msg.out then
         msg.out = false
      end
      if msg.from.id == our_id then
         msg.from.id = 0
      end
   end
   return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end
  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
        print(warning)
        send_msg(receiver, warning, ok_cb, false)
        return true
      end
    end
  end
  return false
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches it's enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print("msg matches: ", pattern)

      if is_plugin_disabled_on_chat(plugin_name, receiver) then
        return nil
      end
      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      -- One patterns matches
      return
    end
  end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Save the content of _config to config.lua
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config( )
  local f = io.open('./data/config.lua', "r")
  -- If config.lua doesn't exist
  if not f then
    print ("Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    print("Sudo user: " .. user)
  end
  return config
end

-- Create a basic config.json file and saves it.
function create_config( )
  -- A simple config with basic plugins and ourselves as privileged user
  config = {
    enabled_plugins = {
	"admin",
    "onservice",
    "inrealm",
    "ingroup",
    "inpm",
    "banhammer",
    "stats",
    "anti_spam",
    "owners",
    "arabic_lock",
    "set",
    "get",
    "broadcast",
    "invite",
    "all",
    "leave_ban",
	"supergroup",
	"whitelist",
	"msg_checks"
    },
    sudo_users = {192281402},--Sudo users
    moderation = {data = 'data/moderation.json'},
    about_text = [[F O C U S v2
Sudo: @Xxx_sargardan_xxX

Channel: @Team_Focus

]],
    help_text_realm = [[
📥Realm Commands📤

︿﹀︿﹀︿﹀︿﹀︿﹀︿﹀
💎 /creategroup [نام]

گروه جدید بسازید

💎 /createrealm [نام]
گروه اصلی بسازید
 
💎 /setname [اسم]
اسم گروه اصلی را تغییربدهید

💎 /setabout [GroupId] [Text]
درمورد ان گروه توضیحاتی را بنویسید (ایدی گروه را بدهید)

💎 /setrules [GroupID] [Text]
درمورد ان گروه قوانینی تعیین کنید (ایدی گروه رابدهید)

💎 /lock [GroupID] [setting]
تنظیمات گروهی را قفل بکنید

💎 /unlock [GroupID] [setting]
تنظیمات گروهی را ازقفل در بیاورید

💎 /settings[GroupID]
تنظیمات گروه را تغییر بدهید 

💎 /wholist
لیست تمامی اعضای گروه را با ایدی نشان خواهد داد

💎 /who
لیست تمامی اعضای گروه را باایدی نشان خواهد داد

💎 /type
درمورد نقش گروه بگیرید

💎 /kill chat [GroupID]
تمامی اعضای گروه را حذف میکنید

💎 /kill realm [RealmID]
تمامی اعضای گروه مادر را حذف میکند

💎 /addadmin [id|username]
اضافه شدن به ادمین بات

💎 /removeadmin [id|username]
حذف از ادمینی بات 

💎 /list groups
لیست گروه های بات

💎 /list realms
لیست گروه های اصلی بات

💎 /support
اضافه شدن به ساپورت بات (ترفیع)

💎 /-support
حذف شدن از ساپورت بات 
(تنزل)
💎 /log
تمامی عملیات گروه رامیدهد

💎 /broadcast [text]
فرستادن پیام به تمامی گروه های بات

میتوانید از هردوی کاراکتر های { /و ! } برای دستورات استفاده کنید

︿﹀︿﹀︿﹀︿﹀︿﹀︿﹀

Channel: @Team_Focus
]],
    help_text = [[
English commands:

︽︾︽︾︽︾︽︾︽︾︽︾︽︾
⭕️ /kick [username/id]
You can also do it by reply

⭕️ /ban [username/id]
You can also do it by reply

⭕️ /unban [id]
You can also do it by reply

⭕️ /who
Members list

⭕️ /modlist
Moderators list

⭕️ /promote [username]
Promote someone

⭕️ /demote [username]
Demote someone

⭕️ /kickme
Will kick user

⭕️ /about
Group description

⭕️ /setphoto
Set and locks group photo

⭕️ /setname [name]
Set group name

⭕️ /rules
Group rules

⭕️ /id
Return group id or user id

⭕️ /lock
 [member|name|bots|leave] 

⭕️ /Locks
 [member|name|bots|leaveing] 

⭕️ /unlock
 [member|name|bots|leave]

⭕️ /Unlocks
 [member|name|bots|leaving]

⭕️ /set rules [text]
Set [text] as rules

⭕️ /set about [text]
Set [text] as about

⭕️ /settings
Returns group settings

⭕️ /newlink
Create/revoke your group link

⭕️ /link
Returns group link

⭕️ /owner
Returns group owner id

⭕️ /setowner [id]
Will set id as owner

⭕️ /info [reply/username/none]
returns

⭕️ /setflood [value]
Set [value] as flood sensitivity

⭕️ /stats
Simple message statistics

⭕️ /save [value] [text]
Save [text] as [value]

⭕️ /get [value]
Returns text of [value]

⭕️ /clean [modlist|rules|about]
Will clear [modlist|rules|about] and set it to nil

⭕️ /res [username]
Returns user id

⭕️ /log
Will return group logs
 
⭕️ /banlist
Will return group ban list


︿﹀︿﹀︿﹀︿﹀︿﹀︿﹀
☎️Send /share to get robot number
︿﹀︿﹀︿﹀︿﹀︿﹀︿﹀

Channel: @Team_Focus
]],
	help_text_super =[[
SuperGroup Commands:

︾︽︾︽︾︽︾︽︾︽︾︽

💢 /info
نمایش مشخصات

💢 /setadmins
انتخاب ادمین برای گروه

💢 /owner
ایدی سازنده گروه 

💢 /modlist
لیست مدیران گروه

💢 /bots
لیست تمام بات های داخل گپ

💢 /who
همه ی ایدی های موجود درچت روبهتون میده

💢 /kick 
فرد از گروه حذف میشود

💢 /ban
فرد  از گروه بن میشود

💢 /unban
فرد از گپ ان بن میشود

💢 /setowner
فرد به عنوان صاحب گروه تنظیم میشود

💢 /promote [username|id]
انتخاب مدیر جدید برای گروه

💢 /demote [username|id]
حذف مدیر 

💢 /setname
تغییر نام گروه

💢 /setrules
تنظیم متن به عنوان قوانین

💢 /setabout
تنظیم متن به عنوان توضیحات

💢 /newlink
ساخت لینک جدید

💢 /link
دریافت لینک

💢 /rules
نمایش قوانین گروه

💢 /lock
[links/Flood/spam/Arabic/member/rtl/sticker/contacts/strict/tgservice]
قفل کردن هریک ازاینها

💢 /unlock
[links/flood/spam/Arabic/member/rtl/sticker/contacts/strict/tgservice]
باز کردن هریک از اینها

💢 /mute [all|audio|gifs|photo|video]
قفل کردن هریک از اینها

💢 /unmute [all|audio|gifs|photo|video]
بازکردن هریک ازاینها

💢 /setflood [عدد]
تنظیم حساسیت به اسپم

💢 /settings
نمایش

💢 /muteslist
نمایش لیست میوت

💢 /muteuser [ریپلی/یوزرنیم/ایدی]
لال کردن فرد 

💢 /mutelist
لیست افراد لال شده

💢 /banlist
لیست افرادبن شده

💢 /clean
 [rules|about|modlist|mutelist]

💢 /del
پاکردن پیام با ریپلی

💢 /public [yes|no]
Set chat visibility in pm !chats or !chatlist commands

💢 /res [یوزرنیم]
درمورد اسم و ایدی شخص بهتون میده

💢 /log
تمامب فعالیت های انجام یافته توسط شما ویامدیران رونشون میده [#RTL|#spam|#lockmember]

︾︽︾︽︾︽︾︽︾︽︾︽
میتوانید از دو کاراکتر'!'و'/'برای دادن دستورات استفاده کنید۰

Channel: @Team_Focus

]],
  }
  serialize_to_file(config, './data/config.lua')
  print('saved config into ./data/config.lua')
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)
  --vardump (chat)
end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.json
function load_plugins()
  for k, v in pairs(_config.enabled_plugins) do
    print("Loading plugin", v)

    local ok, err =  pcall(function()
      local t = loadfile("plugins/"..v..'.lua')()
      plugins[v] = t
    end)

    if not ok then
      print('\27[31mError loading plugin '..v..'\27[39m')
	  print(tostring(io.popen("lua plugins/"..v..".lua"):read('*all')))
      print('\27[31m'..err..'\27[39m')
    end

  end
end

-- custom add
function load_data(filename)

	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)

	return data

end

function save_data(filename, data)

	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()

end


-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 2 mins
  postpone (cron_plugins, false, 120)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false
