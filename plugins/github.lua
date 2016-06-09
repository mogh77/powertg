local function run(msg, matches)
  local eq = URL.escape(matches[1])
     url = "https://api.github.com/users/"..eq
     jstr, res = https.request(url)
     jdat = JSON.decode(jstr)
  if jdat.message then
  return jdat.message
  else
     text = jdat.login..'\n❤️ فالورها : '..jdat.followers..'\n👥 فالوینگ ها : '..jdat.following..'\n🌐 آدرس پروفایل : '..jdat.html_url..'\n'
  local file = download_to_file(jdat.avatar_url,'Avira.webp')
  send_document('channel#id'..msg.to.id,file,ok_cb,false)
  return text
end
end
return {
  description = "Search On Github.com", 
  usage = "",
  patterns = {
    "^[!#/]git (.*)",
  },
  run = run
}
