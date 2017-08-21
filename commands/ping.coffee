irc = require("../irc.js")

ping = (msg, custom, conn) ->
    if custom[0] is ""
        msg.reply("PONG!")

    else
        conn.send("PRIVMSG #{msg.data.privmsg.channel} :PONG! @ #{custom[1]}")

module.exports = [{
    name: "status"
    perform: ping
    matcher: new irc.PrefixedMatcher("ping( (.*))?")
}]