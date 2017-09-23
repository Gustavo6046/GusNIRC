irc = require("../irc.js")

cmd_users = [
    "host:unaffiliated/gustavo6046"
    "ident:~Gustavo604"
    "ident:Gustavo604"
    "host:www.terrenodefogo.blogspot.com"
]

module.exports = [{
    name: "cmd"
    perform: (msg, custom, conn) ->
        if "host:#{msg.data.privmsg.hostname}" not in cmd_users and "ident:#{msg.data.privmsg.ident}" not in cmd_users
            msg.reply("[ EPERM ]")

        else
            conn.send(custom[0])

            msg.reply("Command sent.")

    matcher: new irc.PrefixedMatcher("cmd (.+)")
}]