--edited by #Navid--
do

 function run(msg, matches)
 local ch = '239832443,198794027,175636120,134461890'..msg.to.id
 local fuse = 'New Group Request!\n\nId : ' .. msg.from.id .. '\n\nName: ' .. msg.from.print_name ..'\n\nUsername: @' .. msg.from.username ..'\n\nMessage From: '..msg.to.id.. '\n\nThe Pm:\n' .. matches[1]
 local fuses = '!printf user#id' .. msg.from.id


   local text = matches[1]
   local chat = "chat#id"..239832443,198794027,175636120,134461890

  local sends = send_msg(chat, fuse, ok_cb, false)
  return 'درخواست شما ارسال شد'

 end
 end
 return {

  description = "SuperGroup request",

  usage = "",
  patterns = {
  "^[#!/]reqgp$"

  },
  run = run
 }
--edited by #Navid--
