do

local function run(msg, matches)
if matches[1]:lower() == 'pm' then
local txt = URL.escape(matches[2])
local ur = matches[3]
local M = matches[4]
local T = URL.escape(matches[5])--bejaye <toke> tokene boto bezar
  local url = 'https://api.telegram.org/bot234665055:AAGrYFBMQwdIhy-N3AnDih2vqAZ9pdna8Uc/sendMessage?chat_id='..msg.from.id..'&parse_mode=Markdown&text='..M..''..T..''..M..'&disable_web_page_preview=true&reply_markup={"inline_keyboard":[[{"text":"'..txt..'","url":"'..ur..'"}]]}'

local b = http.request(url)
     jstr, res = https.request(url)
     jdat = JSON.decode(jstr)
	 if jdat.ok == "true" then
return "ok"
end
end
end
return {
  patterns = {
 "^[!/#](pm) (.*)~(.*) (.*)/(.*)$",
   },
  run = run,
  }
  end
