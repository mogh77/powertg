do
 function run(msg, matches)
 local reply_id = msg['id']
 local text = 'nerkh'
 local text1 ="  قيمت گروه هاي آنتي اسپم :\n\n\n  ماهيانه سوپرگروه 5000 تومان\n  دو ماهه سوپرگروه9000 تومان\n   سه ماهه سوپرگروه 14000 تومان\n\n —-----------------------------\n\n سفارش : @parsaalemi"
   reply_msg(reply_id, text1, ok_cb, false)
 end
 return {
  description = "!nerkh",
  usage = " !nerkh",
  patterns = {
    "^[#/!][Nn]erkh$",
  },
  run = run
}
end
