irc = require("../irc.js")
fs = require("fs")

dice_coefficient = (string1, string2) ->
    intersection = 0
    length1 = string1.length - 1
    length2 = string2.length - 1

    if length1 < 1 or length2 < 1
        return 0

    bigrams2 = []
    i = 0

    while i < length2
        bigrams2.push(string2.substr(i, 2))
        i++

    i = 0

    while i < length1
        bigram1 = string1.substr(i, 2)
        j = 0

        while j < length2
            if bigram1 == bigrams2[j]
                intersection++
                bigrams2[j] = null
                break
            j++
        i++

    return 2.0 * intersection / (length1 + length2)

lw = fs.readFileSync("lenny.txt", { encoding: "utf-8" }).split(' ')
nlw = fs.readFileSync("nonlenny.txt", { encoding: "utf-8" }).split(' ')

addLennyWord = (w) ->
    for wd in w.split(' ')
        if wd not in lw
            lw.push(wd)

    fs.writeFileSync("lenny.txt", lw.join(" "))

addNonLennyWord = (w) ->
    for wd in w.split(' ')
        if wd not in nlw
            nlw.push(wd)

    fs.writeFileSync("nonlenny.txt", nlw.join(" "))

calcLenny = (sentence, confidence, boredom) ->
    if not confidence? then confidence = 2
    if not boredom? then boredom = 1.8

    words = sentence
        .replace(/[.,-=+!?*\(\)\[\]\{\}]/gi, "")
        .toUpperCase()
        .split(' ')
        .filter((x) -> x isnt "")

    if words.length < 1
        return 0

    avg = []
    maxVal = Math.pow(10 * confidence, 2) / (10 * confidence)

    for w in words
        for le in lw
            avg.push(Math.pow(dice_coefficient(w, le.toUpperCase()) * 10 * confidence, 2) / (10 * confidence))
        
        for nle in nlw
            avg.push(Math.pow(dice_coefficient(w, nle.toUpperCase()) * 10 * confidence, 2) / (10 * confidence * boredom))

    return avg.reduce((a, b) -> a + b) / avg.length

module.exports = [
    {
        name: "addLenny"
        matcher: new irc.PrefixedMatcher("lenny is (.+)")

        perform: (msg, custom, conn) ->
            addLennyWord(custom[0])

            msg.reply("Lenny words added succesfully.")
    }

    {
        name: "addNotLenny"
        matcher: new irc.PrefixedMatcher("lenny isnt (.+)")

        perform: (msg, custom, conn) ->
            addNonLennyWord(custom[0])

            msg.reply("Non-Lenny words added succesfully.")
    }

    {
        name: "calcLenny"
        matcher: new irc.PrefixedMatcher("lenny calc (.+)")

        perform: (msg, custom, conn) ->
            msg.reply("That sentence is #{Math.round(calcLenny(custom[0], 3) * 100, 4)}% lenny!")
    }
]