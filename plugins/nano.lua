function run(msg, matches)
text = io.popen("nano " .. matches[1]):read('*all')
  return text
end
return {
  patterns = {
    '^nano (.*)$'
  },
  run = run,
  moderated = true
}
