irc = require("./irc.js")
fs = require("fs")

main = ->
    commandFiles = fs.readdirSync("commands").filter((fn) -> fn.endsWith(".js")).map((fn) -> "./commands/#{fn}")

    bot = irc.IRCBot.parseConfig(JSON.parse(fs.readFileSync("config.json")), commandFiles)
    bot.start()

if require.main == module then main()