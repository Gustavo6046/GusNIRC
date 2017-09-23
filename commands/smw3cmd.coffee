irc = require("../irc.js")
smw = require("../etc/smw3.js")

module.exports = [
    {
        name: "smw3.host"
        matcher: new irc.PrefixedMatcher("smw3 host (.+)")
        perform: (msg, custom, conn) ->
            if not smw.gametypeOf(custom[0])?
                msg.reply("Game can't be hosted; unexistant gametype!")

            else if smw.SMWGame.findGame(conn, msg.data.privmsg.channel)?
                msg.reply("Game can't be hosted; there is already an SMWGame on this channel!")

            else
                new smw.SMWGame(conn, msg.data.privmsg.channel, new smw.gametypeOf(custom[0]), msg.reply)

                msg.reply("Game hosted succesfully!")
    },

    {
        name: "smw3.stop"
        matcher: new irc.PrefixedMatcher("smw3 stop$")
        perform: (msg, custom, conn) ->
            if not smw.SMWGame.findGame(conn, msg.data.privmsg.channel)?
                msg.reply("No game running already!")

            else
                smw.SMWGame.findGame(conn, msg.data.privmsg.channel).stopGame()

                msg.reply("Game stopped succesfully!!")
    },

    {
        name: "smw3.join"
        matcher: new irc.PrefixedMatcher("smw3 join$")
        perform: (msg, custom, conn) ->
            if not smw.SMWGame.findGame(conn, msg.data.privmsg.channel)?
                msg.reply("No game running!")

            else
                smw.SMWGame.findGame(conn, msg.data.privmsg.channel).addPlayer(msg.data.privmsg.nickname)

                msg.reply("User #{msg.data.privmsg.nickname} joined succesfully!")
    },

    {
        name: "smw3.leave"
        matcher: new irc.PrefixedMatcher("smw3 leave$")
        perform: (msg, custom, conn) ->
            if not smw.SMWGame.findGame(conn, msg.data.privmsg.channel)?
                msg.reply("No game running!")

            else if not smw.SMWGame.findGame(conn, msg.data.privmsg.channel).getPlayer(msg.data.privmsg.nickname)?
                msg.reply("You are not joined yet!")

            else
                smw.SMWGame.findGame(conn, msg.data.privmsg.channel).killPlayer(msg.data.privmsg.nickname)
    },

    {
        name: "smw3.buyWeapon"
        matcher: new irc.PrefixedMatcher("smw3 buygun (.+)")
        perform: (msg, custom, conn) ->
            if not smw.SMWGame.findGame(conn, msg.data.privmsg.channel)?
                msg.reply("No game running!")

            else if not smw.SMWGame.findGame(conn, msg.data.privmsg.channel).getPlayer(msg.data.privmsg.nickname)?
                msg.reply("You are not joined yet!")

            else
                if not smw.SMWGame.findGame(conn, msg.data.privmsg.channel).gametype.allWeapons[custom[0]]?
                    msg.reply("No such weapon!")

                else if smw.SMWGame.findGame(conn, msg.data.privmsg.channel).gametype.allWeapons[custom[0]].cost < smw.SMWGame.findGame(conn, msg.data.privmsg.channel).getPlayer(msg.data.privmsg.nickname).attributes.money
                    msg.reply("Weapon too costly (#{smw.SMWGame.findGame(conn, msg.data.privmsg.channel).getPlayer(msg.data.privmsg.nickname)}/#{smw.SMWGame.findGame(conn, msg.data.privmsg.channel).gametype.allWeapons[custom[0]].cost})!")

                else
                    smw.SMWGame.findGame(conn, msg.data.privmsg.channel).getPlayer(msg.data.privmsg.nickname).attributes.weapons[custom[0]] = new (smw.SMWGame.findGame(conn, msg.data.privmsg.channel).gametype.allWeapons[custom[0]])(smw.SMWGame.findGame(conn, msg.data.privmsg.channel), smw.SMWGame.findGame(conn, msg.data.privmsg.channel).getPlayer(msg.data.privmsg.nick))
                    smw.SMWGame.findGame(conn, msg.data.privmsg.channel).getPlayer(msg.data.privmsg.nickname).attributes.money -= smw.SMWGame.findGame(conn, msg.data.privmsg.channel).gametype.allWeapons[custom[0]].cost

                    msg.reply("Weapon bought successfully!")
    }

    {
        name: "smw3.shoot"
        matcher: new irc.PrefixedMatcher("smw3 shoot (.+) with (.+)")
        perform: (msg, custom, conn) ->
            if not smw.SMWGame.findGame(conn, msg.data.privmsg.channel)?
                msg.reply("No game running!")

            else if not smw.SMWGame.findGame(conn, msg.data.privmsg.channel).getPlayer(msg.data.privmsg.nickname)?
                msg.reply("You are not joined yet!")

            else
                targ = custom[0]
                weap = custom[1]
                game = smw.SMWGame.findGame(conn, msg.data.privmsg.channel)
                user = game.getPlayer(msg.data.privmsg.nickname)

                if weap not in user.attributes.weaopns?
                    msg.reply("No, you don't have that weapon!")

                else
                    user.attributes.weapons[weap].shoot(game.getPlayer(targ))
    }

    {
        name: "smw3.altshoot"
        matcher: new irc.PrefixedMatcher("smw3 altshoot (.+) with (.+)")
        perform: (msg, custom, conn) ->
            if not smw.SMWGame.findGame(conn, msg.data.privmsg.channel)?
                msg.reply("No game running!")

            else if not smw.SMWGame.findGame(conn, msg.data.privmsg.channel).getPlayer(msg.data.privmsg.nickname)?
                msg.reply("You are not joined yet!")

            else
                targ = custom[0]
                weap = custom[1]
                game = smw.SMWGame.findGame(conn, msg.data.privmsg.channel)
                user = game.getPlayer(msg.data.privmsg.nickname)

                if weap not in user.attributes.weaopns?
                    msg.reply("No, you don't have that weapon!")

                else
                    user.attributes.weapons[weap].altShoot(game.getPlayer(targ))
    }
]