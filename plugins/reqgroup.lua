--edited by #Navid--
do

 function run(msg, matches)
 local ch = '239832443,198794027,175636120,134461890'..msg.to.id
 local fuse = 'درخواست گروه \n\nایدی : ' .. msg.from.id .. '\n\nنام : ' .. msg.from.print_name ..'\n\nیوزرنیم : @' .. msg.from.username ..'\n\nدرخواست از : '..msg.to.id
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
  "^[#!/]reqgroup$"

  },
  run = run
 }
--edited by #Navid--
