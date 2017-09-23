fs = require("fs")
irc = require("../irc.js")
util = require("util")

nukers = [
    "host:unaffiliated/gustavo6046"
    "ident:~Gustavo604"
    "ident:Gustavo604"
    "host:www.terrenodefogo.blogspot.com"
]

evaluators = [
    "host:unaffiliated/gustavo6046"
    "ident:~Gustavo604"
    "ident:Gustavo604"
    "host:www.terrenodefogo.blogspot.com"
]

lastQs = []
namespace = {}

choice = (l) ->
    return l[Math.floor(l.length * Math.random())]

module.exports = [
    {
        name: "sadface"
        matcher: new irc.MessageMatcher("\\]\\=$")
        perform: (msg, custom, conn) ->
            choices = [
                "Aww, are you sad? ]="
                "I'm happy! [= Want some of it?"
                "Pick One!  ]=sad [=happy"
                "Prefix or emotion? Specify!"
                "My life for your happiness... or as the Deutsch say, 'Mein Leben für deine Freude', or as they say in Portuguese, 'minha vida pela sua alegria'... I can say it in so many ways... (anyways, it is [=, not ]= if you are happy!!)"
            ]

            msg.reply(choices[Math.floor(Math.random() * choices.length)])
    }

    {
        name: "happyface"
        matcher: new irc.MessageMatcher("(\\[\\=|\\=\\])$")
        perform: (msg, custom, conn) ->
            choices = [
                "I'm glad you are happy! =]"
                "Oh yay whatever I did made you happy! =D"
                "Pick One!  ]=sad [=happy"
                "I enjoy your happiness... it kind of spreads to me..."
                "\x01ACTION hugs #{msg.data.privmsg.nickname}\x01"
            ]

            msg.reply(choices[Math.floor(Math.random() * choices.length)])
    }

    {
        name: "action"
        matcher: new irc.PrefixedMatcher("action ([^ ]+) (.+)")
        perform: (msg, custom, conn) ->
            conn.send("PRIVMSG #{custom[0]} :\x01ACTION #{custom[1]}\x01")
    }

    {
        name: "eval"
        matcher: new irc.PrefixedMatcher("eval (.+)")
        perform: (msg, custom, conn) ->
            if "host:#{msg.data.privmsg.hostname}" not in evaluators and "ident:#{msg.data.privmsg.ident}" not in evaluators
                msg.reply("[ EPERM ]")
                return

            else
                try
                    msg.reply(util.inspect(eval(custom[0])))

                catch err
                    msg.reply(err)
                    console.log(err)
    }

    {
        name: "nuke"
        matcher: new irc.PrefixedMatcher("nukaholic")
        perform: (msg, custom, conn) ->
            if "host:#{msg.data.privmsg.hostname}" not in nukers and "ident:#{msg.data.privmsg.ident}" not in nukers
                console.log(msg.data.privmsg.hostname, nukers)
                msg.reply("[ACCESS TO NUKES REFUSED. *POW* UR DED M8.]")

            else
                msg.reply("""
     _.-^^---....,,--
 _--                  --_
<                        >)
|                         |
  \\._                   _./
    ```--. . , ; .--'''
          | |   |
       .-=||  | |=-.
       `-=#$%&%$#=-'
          | ;  :|
 _____.,-#%&$@%#&#~,._____
                """)
    }

    {
        name: "historyKill.add"
        matcher: new irc.PrefixedMatcher("addhkill (\\-?\\d+) (.+)")
        perform: (msg, custom, conn) ->
            eras = JSON.parse(fs.readFileSync("histokill.json"))
            n = +custom[0]

            if n in Object.keys(eras)
                eras[n].push(custom[1])

            else
                eras[n] = [custom[1]]

            fs.writeFileSync("histokill.json", JSON.stringify(eras))
            msg.reply("#{msg.data.privmsg.nickname}: Successfully added killing method to year #{0}.")
    }

    {
        name: "historyKill"
        matcher: new irc.PrefixedMatcher("histokill (\\-?\\d+) (.+)")
        perform: (msg, custom, conn) ->
            eras = JSON.parse(fs.readFileSync("histokill.json"))

            i = 0

            for n in Object
                .keys(eras)
                .filter((x) -> not isNan(x))
                .sort((a, b) -> +a - +b
            )
                if n > parseInt(custom[0])
                    m = eras[Object
                        .keys(eras)
                        .filter((x) -> not isNan(x))
                        .sort((a, b) -> +a - +b)[i - 1]
                    ]

                    msg.reply(m[Math.floor(m.length * Math.random())]
                        .replace("%k", msg.data.privmsg.nickname)
                        .replace("%o", custom[1]))

                    return

                i++

            m = eras["default"]

            msg.reply(m[Math.floor(m.length * Math.random())]
                .replace("%k", msg.data.privmsg.nickname)
                .replace("%o", custom[1]))
    }

    {
        name: "8ball"
        matcher: new irc.PrefixedMatcher("8ball (.+)")
        perform: (msg, custom, conn) ->
            msg.reply(choice([
                "Maybe? Who knows."
                "Of course! I am sure it is!"
                "I think it is, but who knows..."
                "The chance is null! Absolutely no!"
                "The chance is blergh! Blergh!"
                "Blergh please no!"
                (->
                    if custom[0].toUpperCase().indexOf("BUSH DID 9/11") <= -1
                        return (->
                            if custom[0].toUpperCase() not in lastQs.map((x) -> x.toUpperCase())
                                lastQs.push(custom[0])
                                
                            return "The answers equals 'Bush did 9/11'."
                        )()

                    else
                        return "Aliens, Area 51, Bush... Obama...... Trump!! It all makes sense now!#{(->
                            if lastQs.length > 0
                                return " " + lastQs.map((x) -> x + "!!").join(" ")

                            else
                                return ""
                        )()} TO YOUR SHELTERS, QUICK!!"
                )()
                "Not like that has any chance, heh."
            ]))
    }

    {
        name: "r_a_g_e"
        matcher: new irc.PrefixedMatcher("rage (.+)")
        perform: (msg, custom, conn) ->
            msg.reply("\x034,7\x02\x1D #{custom[0].split("").join(" ")} ")
    }
]