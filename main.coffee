irc = require("./irc.js")
fs = require("fs")

main = ->
    commandFiles = fs.readdirSync("commands").filter((fn) -> fn.endsWith(".js")).map((fn) -> "./commands/#{fn}")

    bot = irc.IRCBot.parseConfig(JSON.parse(fs.readFileSync((if process.argv.length > 2 then process.argv[2] else "config.json"))), commandFiles)
    bot.start()

if require.main == module then main()