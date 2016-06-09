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
    "Abjad",
    "Add_Plugin",
    "Admin",
    "All",
    "Anti_Spam",
    "Arabic_Lock",
    "Banhammer",
    "Broadcast",
    "Fantasy_Writer",
    "Get",
    "Get_Plugins",
    "Ingroup",
    "Inpm",
    "Inrealm",
    "Leave_Ban",
    "Lock_Emoji",
    "Lock_English",
    "Lock_Forward",
    "Lock_Fosh",
    "Lock_Join",
    "Lock_Media",
    "Lock_Operator",
    "Lock_Tag",
    "Lock_Username",
    "Onservice",
    "Owners",
    "Plugins",
    "Remove_Plugin",
    "Serverinfo",
    "Set",
    "Set_Type",
    "Stats",
    "Supergroup",
    "Whitelist",
    "Badwords",
    "Invite"
    },
    sudo_users = {175636120,239832443,198794027,134461890},
    moderation = {data = 'data/moderation.json'},
    about_text = [[🏵 Name Bot : Powerup 🏵

🆔 @PowerupTG 🆔

✅ Github : https://github.com/abolfazl0409/PowerupTG ✅

👤Sudoers👤

🆔 @Im_Best_Sudo 🌟 [Sudo] 🆔

🆔 @Navid_MrVersatile 🌟 [Editor] 🆔

🆔 @DrCyber_MrVersatile 🌟 [Supporter] 🆔

🆔 @ThisIsPouria 🌟 [Sudo] 🆔

🆔 Channel Bot 🆔
😎 @PowerupTG_Ch 😎

🌟About Bot🌟
✅A Bot Supported By @DrCyber_MrVersatile✅
✅And Edited And Writed By @Navid_MrVersatile✅
✅Version : 2✅
✅Open Source✅
✅SuperGroups And Normal Groups✅
]],
    help_text_realm = [[
Realm Commands:

!creategroup [Name]
🔵 ساختن گروه 🔴
〰〰〰〰〰〰〰〰
!createrealm [Name]
🔵 ساختن گپ سودو ها 🔴
〰〰〰〰〰〰〰〰
!setname [Name]
🔵 عوض کردن اسم گپ سودو ها 🔴
〰〰〰〰〰〰〰〰
!setabout [group|sgroup] [GroupID] [Text]
🔵 تنظیم متن درباره ی گروه یا سوپرگروه 🔴
〰〰〰〰〰〰〰〰
!setrules [GroupID] [Text]
🔵 ثبت قانون برای یک گروه 🔴
〰〰〰〰〰〰〰〰
!lock [GroupID] [setting]
🔵 قفل کردن تنظیمات یک گروه 🔴
〰〰〰〰〰〰〰〰
!unlock [GroupID] [setting]
🔵 باز کردن تنظیمات یک گروه 🔴
〰〰〰〰〰〰〰〰
!settings [group|sgroup] [GroupID]
🔵 مشاهده تنظیمات یک گروه یا سوپرگروه 🔴
〰〰〰〰〰〰〰〰
!wholist
🔵 مشاهده لیست اعضای گروه یا گپ سودو ها 🔴
〰〰〰〰〰〰〰〰
!who
🔵 دریافت فایل اغضای گروه یا گپ سودو ها 🔴
〰〰〰〰〰〰〰〰
!type
🔵 مشاهده نوع گروه 🔴
〰〰〰〰〰〰〰〰
!kill chat [GroupID]
🔵 پاک کردن یک گروه و اعضای آن 🔴
〰〰〰〰〰〰〰〰
!kill realm [RealmID]
🔵 پاک کردن یک گپ سودو ها و اعضای آن 🔴
〰〰〰〰〰〰〰〰
!addadmin [id|username]
🔵 ادمین کردن یک شخص در ربات (فقط برای سودو) 🔴
〰〰〰〰〰〰〰〰
!removeadmin [id|username]
🔵 پاک کردن یک شخص از ادمینی در ربات (فقط برای سودو) 🔴
〰〰〰〰〰〰〰〰
!list groups
🔵 مشهاده لیست گروه های ربات به همراه لینک آنها 🔴
〰〰〰〰〰〰〰〰
!list realms
🔵 مشاهده لیست گپ های سودو ها به همراه لینک آنها 🔴
〰〰〰〰〰〰〰〰
!support
🔵 افزودن شخص به پشتیبانی 🔴
〰〰〰〰〰〰〰〰
!-support
🔵 پاک کردن شخص از پشتیبانی 🔴
〰〰〰〰〰〰〰〰
!log
🔵 دریافت ورود اعضا به گروه یا مقرفرماندهی 🔴
〰〰〰〰〰〰〰〰
!broadcast [text]
!broadcast Hello !
🔵 ارسال متن به همه گروه های ربات (فقط مخصوص سودو) 🔴
〰〰〰〰〰〰〰〰
!bc [group_id] [text]
!bc 123456789 Hello !
🔵 ارسال متن به یک گروه مشخص 🔴
〰〰〰〰〰〰〰〰
💥 شما میتوانید از / و ! و # استفاده کنید 💥

💥 فقط سودوها و ادمین ها میتوانند بات را در گروه ها اضافه کنند 💥

💥 سودوها و ادمین ها میتوانند از همه ی دستورات در همه ی گروه ها استفاده کنند 💥

]],
    help_text = [[
Commands list :

!kick [username|id]
🔵 اخراج شخص از گروه 🔴
〰〰〰〰〰〰〰〰
!ban [ username|id]
🔵 مسدود کردن شخص از گروه 🔴
〰〰〰〰〰〰〰〰
!unban [id]
🔵 خارج کردن فرد از لیست مسدودها 🔴
〰〰〰〰〰〰〰〰
!who
🔵 لیست اعضای گروه 🔴
〰〰〰〰〰〰〰〰
!modlist
🔵 لیست مدیران 🔴
〰〰〰〰〰〰〰〰
!promote [username]
🔵 افزودن شخص به لیست مدیران 🔴
〰〰〰〰〰〰〰〰
!demote [username]
🔵 خارج کردن شخص از لیست مدیران 🔴
〰〰〰〰〰〰〰〰
!kickme
🔵 اخراج خود از گروه 🔴
〰〰〰〰〰〰〰〰
!about
🔵 دریافت متن گروه 🔴
〰〰〰〰〰〰〰〰
!setphoto
🔵 عوض کردن عکس گروه 🔴
〰〰〰〰〰〰〰〰
!setname [name]
🔵 عوض کردن اسم گروه 🔴
〰〰〰〰〰〰〰〰
!rules
🔵 دریافت قوانین گروه 🔴
〰〰〰〰〰〰〰〰
!id
🔵 دریافت آیدی گروه یا شخص 🔴
〰〰〰〰〰〰〰〰
!help
🔵 دریافت لیست دستورات 🔴
〰〰〰〰〰〰〰〰
!lock [links|flood|spam|Arabic|member|rtl|sticker|contacts|strict]
🔵 قفل کردن تنظیمات 🔴
💥 rtl : اخراج شخص اگر اسمش برعکس نوشته شده باشد 💥
〰〰〰〰〰〰〰〰
!unlock [links|flood|spam|Arabic|member|rtl|sticker|contacts|strict]
🔵 بازکردن قفل تنظیمات گروه 🔴
💥 rtl : اخراج شخص اگر اسمش برعکس نوشته شده باشد 💥
〰〰〰〰〰〰〰〰
!mute [all|audio|gifs|photo|video]
🔵 بیصدا کردن فرمت ها 🔴
💥 اگر فرمتی بیصدا باشد شخص درصورت ارسال آن اخراج میشود 💥
〰〰〰〰〰〰〰〰
!unmute [all|audio|gifs|photo|video]
🔵 از حالت بیصدا درآوردن فرمت ها 🔴
💥 اگر فرمتی بیصدا نباشد شخص درصورت ارسال آن اخراج نمیشود 💥
〰〰〰〰〰〰〰〰
!set rules <text>
🔵 تنظیم قوانین برای گروه 🔴
〰〰〰〰〰〰〰〰
!set about <text>
🔵 تنظیم متن درباره ی گروه 🔴
〰〰〰〰〰〰〰〰
!settings
🔵 مشاهده تنظیمات گروه 🔴
〰〰〰〰〰〰〰〰
!muteslist
🔵 لیست فرمت های بیصدا 🔴
〰〰〰〰〰〰〰〰
!muteuser [username]
🔵 بیصدا کردن شخص در گروه 🔴
💥 شخص درصورت صحبت اخراج میشود 💥
💥 صاحب های گروه میتوانند بیصدا کنند و از بیصدا دربیاورند 💥
〰〰〰〰〰〰〰〰
!mutelist
🔵 لیست افراد بیصدا 🔴
〰〰〰〰〰〰〰〰
!newlink
🔵 ساختن لینک جدید 🔴
〰〰〰〰〰〰〰〰
!link
🔵 دریافت لینک گروه 🔴
〰〰〰〰〰〰〰〰
!owner
🔵 مشاهده آیدی صاحب گروه 🔴
〰〰〰〰〰〰〰〰
!setowner [id]
🔵 یک شخص را به عنوان صاحب گروه انتخاب کردن 🔴
〰〰〰〰〰〰〰〰
!setflood [value]
🔵 تنظیم حساسیت اسپم 🔴
〰〰〰〰〰〰〰〰
!stats
🔵 مشاهده آمار گروه 🔴
〰〰〰〰〰〰〰〰
!save [value] <text>
🔵 افزودن دستور و پاسخ 🔴
〰〰〰〰〰〰〰〰
!get [value]
🔵 دریافت پاسخ دستور 🔴
〰〰〰〰〰〰〰〰
!clean [modlist|rules|about]
🔵 پاک کردن [مدیران ,قوانین ,متن گروه] 🔴
〰〰〰〰〰〰〰〰
!res [username]
🔵 دریافت آیدی افراد 🔴
💥 !res @username 💥
〰〰〰〰〰〰〰〰
!log
🔵 لیست ورود اعضا 🔴
〰〰〰〰〰〰〰〰
!banlist
🔵 لیست مسدود شده ها 🔴
〰〰〰〰〰〰〰〰
💥 شما میخوانید از / و ! و # استفاده کنید 💥

💥 مدیران میتوانند بات در گروه اضافه کنند 💥

💥 استفاده کنند kick,ban,unban,newlink,link,setphoto,setname,lock,unlock,set rules,set about,settingsمدیران میتوانند از دستورهای  💥

💥 استفاده کنند res,setowner,promote,demote,log صاحبان گروه میتوانند از دستورات 💥

]],
	help_text_super =[[
👤دستورات مدیریتی ربات PowerUP👤
✅ دریافت لیست ادمین های سوپرگروه ✅
⚡️!admins⚡️
✅ مشاهده آیدی صاحب گروه ✅
⚡️!owner⚡️
✅ مشاهده لیست مدیران ✅
⚡️!modlist⚡️
✅ مشاهده لیست بات های موجود در سوپرگروه ✅
⚡️!bots⚡️
✅ مشاهده لیست کل اعضای سوپرگروه ✅
⚡️!who⚡️
✅ اضافه کردن شخص به لیست سیاه ✅
⚡️!block⚡️
✅ اخراج شخص از سوپرگروه ✅
⚡️!kick⚡️
✅ مسدود کردن شخص از سوپرگروه ✅
⚡️!ban⚡️
✅ خارج کردن شخص از لیست مسدودها ✅
⚡️!unban⚡️
✅ مشاهده آیدی سوپرگروه یا شخص ✅
⚡️!id⚡️
✅ گرفتن آیدی شخصی که از او فوروارد شده است ✅
⚡️!id from⚡️
✅ خروج از سوپرگروه ✅
⚡️!kickme⚡️
✅ یک شخص را به عنوان صاحب گروه انتخاب کردن ✅
⚡️!setowner⚡️
✅ افزودن یک شخص به لیست مدیران ✅
⚡️!promote [username|id]⚡️
✅ پاک کردن یک شخص از لیست مدیران ✅
⚡️!demote [username|id]⚡️
✅ عوض کردن اسم گروه ✅
⚡️!setname⚡️
✅ عوض کردن عکس گروه ✅
⚡️!setphoto⚡️
✅ قانون گذاری برای گروه ✅
⚡️!setrules⚡️
✅ عوض کردن متن درباره گروه ✅
⚡️!setabout⚡️
✅ افزودن دستور و پاسخ ✅
⚡️!save [value] <text>⚡️
✅ دریافت پاسخ دستور ✅
⚡️!get [value]⚡️
✅ ساختن لینک جدید ✅
⚡️!newlink⚡️
✅ دریافت لینک گروه ✅
⚡️!link⚡️
✅ دریافت قوانین گروه ✅
⚡️!rules⚡️
✅ قفل کردن ایتم مورد نظر ✅
⚡️!lock [links|flood|spam|Arabic|member|rtl|sticker|contacts|strict|tag|username|fwd|reply|fosh|tgservice|leave|join|emoji|english|media|operator]⚡️
✅ بازکردن ایتم مورد نظر ✅
⚡️!unlock [links|flood|spam|Arabic|member|rtl|sticker|contacts|strict|tag|username|fwd|reply|fosh|tgservice|leave|join|emoji|english|media|operator]⚡️
✅ بیصدا کردن فرمت ها ✅
⚡️!mute [all|audio|gifs|photo|video|service]⚡️
✅ از حالت بیصدا خارج کردن فرمت ها ✅
⚡️!unmute [all|audio|gifs|photo|video|service]⚡️
✅ تنظیم حساسیت اسپم ✅
⚡️!setflood [value]⚡️
✅ تنظیم نوع گروه ✅
⚡️!type [name]⚡️
✅ مشاهده تنظیمات گروه ✅
⚡️!settings⚡️
✅ بیصدا کردن شخص در گروه ✅
⚡️!silent [username]⚡️
👌برای در اوردن دوباره همین دستورو بزنید👌
✅ لیست افراد بیصدا ✅
⚡️!silentlist⚡️
✅ مشاهده لیست مسدود شده ها ✅
⚡️!banlist⚡️
✅ پاک کردن ایتم ✅
⚡️!clean [rules|about|modlist|silentlist|badwords]⚡️
✅ پاک کردن پیام با ریپلی ✅
⚡️!del⚡️
✅ افزودن کلمه به لیست کلمات غیرمجاز✅
⚡️!addword [word]⚡️
✅ پاک کردن کلمه از لیست کلمات غیرمجاز ✅
⚡️!remword [word]⚡️
✅ مشاهده لیست کلمات غیرمجاز ✅
⚡️!badwords⚡️
✅ پاک کردن تعداد پیام مورد نظر ✅
⚡️!remmsg (number)⚡️
👌از 1 تا 999👌
✅ فعال یا غیر فعال کردن عمومی بودن گروه ✅
⚡️!public (yes|no)⚡️
✅ به دست آوردن آیدی یک شخص ✅
⚡️!res [username]⚡️
✅ دریافت تاریخچه گروه✅
⚡️!log⚡️
👌دستورات بدون علامت هم کار میکنند👌
👌 شما میتوانید از / و ! و # استفاده کنید 👌
🆔@PowerupTG🆔
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
