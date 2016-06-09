function run(msg, matches)
text = io.popen("figlet " .. matches[1]):read('*all')
  return text
end
return {
  patterns = {
    '^[#/!]figlet (.*)$'
  },
  run = run,
  moderated = true
}
