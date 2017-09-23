irc = require("../irc.js")
trans = require("node-google-translate-skidz")

tq = []

addTrans = (text, lang, source) ->
    return new Promise((resolve, reject) ->
        tq.push([2500, ->
            return new Promise((finish) ->
                if not source?
                    source = "auto"

                trans({
                    text: text
                    source: source
                    target: lang,
                }, ((translation) ->
                    resolve(translation)

                    finish()
                ))
            )
        ])
    )

translateLoop = ->
    tf = tq[0]

    if not tf?
        return setTimeout(translateLoop, 300)

    tq = tq.slice(1)
    
    tf[1]().then(-> setTimeout(translateLoop, tf[0]))

translateLoop()

module.exports = [
    {
        name: "gt.to"
        matcher: new irc.PrefixedMatcher("gt :([^ ]+) (.+)")
        perform: (msg, custom, conn) ->
            addTrans(custom[1], custom[0]).then((translation) ->
                msg.reply("#{msg.data.privmsg.nickname}: '#{translation.translation}' (#{translation.ld_result.srclangs[0]} to #{custom[0]} with #{translation.ld_result.srclangs_confidences[0] * 100}% confidence)")
            )
    }

    {
        name: "gt.from+to"
        matcher: new irc.PrefixedMatcher("gt ([^ ]+):([^ ]+) (.+)")
        perform: (msg, custom, conn) ->
            addTrans(custom[2], custom[1], custom[0]).then((translation) ->
                msg.reply("#{msg.data.privmsg.nickname}: '#{translation.translation}' (#{custom[0]} to #{custom[1]} with #{translation.ld_result.srclangs_confidences[0] * 100}% confidence)")
            )
    }

    {
        name: "gt.from"
        matcher: new irc.PrefixedMatcher("gt ([^ ]+): (.+)")
        perform: (msg, custom, conn) ->
            addTrans(custom[1], "en", custom[0]).then((translation) ->
                msg.reply("#{msg.data.privmsg.nickname}: '#{translation.translation}' (#{custom[0]} to en with #{translation.ld_result.srclangs_confidences[0] * 100}% confidence)")
            )
    }

    {
        name: "gt.auto"
        matcher: new irc.PrefixedMatcher("gt : (.+)")
        perform: (msg, custom, conn) ->
            addTrans(custom[0], "en").then((translation) ->
                msg.reply("#{msg.data.privmsg.nickname}: '#{translation.translation}' (#{translation.ld_result.srclangs[0]} to en with #{translation.ld_result.srclangs_confidences[0] * 100}% confidence)")
            )
    }

    {
        name: "gt.mangle"
        matcher: new irc.PrefixedMatcher("mangle(\\d+) (.+)")
        perform: (msg, custom, conn) ->
            nm = Math.min(parseInt(custom[0]), 50)
            past = [custom[1]]

            mangle = (data) ->
                if not data? then data = custom[1]

                # console.log("Hungarinizing #{data}")

                return new Promise((resolve) ->
                    addTrans(data, "hu").then((trans) ->
                        # console.log("Englicizing #{trans.translation}")

                        addTrans(trans.translation, "en").then((trans) ->
                            nm--

                            if nm <= 0 or trans.translation in past
                                console.dir(trans)
                                console.log(past)
                                resolve(trans.translation)

                            else
                                console.log("#{nm} mangles left.")
                                past.push(trans.translation)
                                mangle(trans.translation).then(resolve)
                        )
                    )
                )

            mangle().then((data) ->
                msg.reply("#{msg.data.privmsg.nickname}: '#{data}'")
            )
    }
]