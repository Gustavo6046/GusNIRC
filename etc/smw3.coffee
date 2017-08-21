irc = require("../irc.js")
EventEmitter = require("events")
fs = require("fs")
##
# +-----------------+
# | Sentient Mushes |
# +-----------------+
# W  A  R  Z  O  N  E
#
#==============
# A team deathmatch game
# by Gustavo6046
#===============
#
# MIT License as always :)
##

botNames = (fs.readFileSync("etc/botnames.txt") + '').split("\n")

moreOrLess = (num) ->
    (Math.random() * 2 - 1) * num

randomChance = (percent) ->
    if percent == 0
        return false

    if percent == 100
        return true

    return Math.random() <= percent / 100

subclasses = (a, b) ->
    (a is b) or (a.prototype instaneOf b)

gametypes = {}
games = {}

class SMWDamageType
    constructor: (@message) ->

    obituary: (weapon, other, damage) =>
        return @message
            # insert obituary parameters below in subclasses
            .replace("%w", weapon.name)
            .replace("%o", other.name)
            .replace("%k", weapon.owner.name)
            .replace("%d", damage)
            # insert obituary parameters above in subclasses
            .replace("%%", "%")

class SMWWeapon
    constructor: (@game, @owner) ->
        @accuracy = 100
        @numAmmo = 15
        @damage = 25
        @damageRand = 9
        @altDamage = 40
        @altDamageRand = 18
        @ammoUse = 1
        @altAmmoUse = 2
        @name = "Standard Gun"
        @properties = {}
        @cost = 20
        @damageType = new SMWDamageType("%k shot %o down generically!")
        @altDamageType = new SMWDamageType("%k shot %o down quickier!")

    sendDamage: (other, instigator, damage, dtype) =>
        @game.reply("#{instigator.name} shot #{other.name} with a(n) #{@name}!")

        @game.gametype.gameEvent("takeDamage", [other, instigator, damage, dtype])

    shoot: (other) =>
        if not @canHit(other) or not @useAmmo(@ammoUse)
            return false

        @sendDamage(other, @owner, damage + moreOrLess(damageRand), @myDamageType)

        return true

    altShoot: (other) =>
        if not @canHit(other) or not @useAmmo(@altAmmoUse)
            return false

        @sendDamage(other, @owner, altDamage + moreOrLess(altDamageRand), @altDamageType)

        return true

    canHit: (other) ->
        b = randomChance(accuracy)

        if not b?
            @game.reply("#{@owner.name}'s #{@name} misses #{other.name}!")

        return b

    rateSelf: (other) ->
        return moreOrLess(50) # default: pick a random weapon from inventory
    
    useAmmo: (amount) =>
        if @numAmmo < amount
            @game.reply("#{ownwer}'s #{name} does not have enough ammo (#{@numAmmo}/#{amount}) to fire!")

            return false

        @numAmmo -= amount

        return true

class SMWGametype
    @keyName: "default"

    initName: ->
        return "default"

    initProps: ->

    constructor: (@game) ->
        @initProps()
        @gameName = @initName()

        @events = {}

    initPlayer: (player) ->

    initRatedGame: ->
        @game.deadPlayers = []

    gameEvent: (event, args) =>
        if @events[event]?
            @events[event](@, args)

    onDeath: (player) ->

    scoreKill: (player, killer) ->

    attitudeTo: (from, other) ->
        # 0 = ignore
        # 1 = ally
        # 2 = enemy
        # 3 = fear

        return 0

class MushMatch extends SMWGametype
    @keyName: "Warzone"

    initProps: =>
        @allWeapons = [
            SMWWeapon
        ]

        @defaultWeapons = [

        ]

        @events = {
            takeDamage: ((gametype, other, instigator, damage, dtype) ->
                other.attributes.health -= damage
                
                if other.attributes.health < 0
                    gametype.game.reply(dtype.obituary(@, other, damage))
                    gametype.scoreKill(other, instigator)
                    gametype.game.killPlayer(other.name)
            )

            infect: ((gametype, other, target) ->
                target.attributes["bMush"] = true
                other.attributes.money += 10

                gametype.game.reply("#{target.name} was infected by #{other.name}! They are now mush! +10$")
            ),

            aids: ((gametype, other, target, weapon) ->
                immuneDmg = weapon.properties.aidsPower + moreOrless(weapon.properties.aidsMutation)
                target.attributes["immune"] -= immuneDmg

                gametype.game.reply("#{other.name} shot an AIDS BIC (Ballistic Injection Container) into #{target.name}! It took #{immuneDmg} immune damage! They now has a quantified immune level of #{target.attributes["immune"]} in the classic Rehermann scale!")

                if target.attributes["immune"] <= 0
                    gametype.game.reply("#{target.name} received an AIDS overdose!")

                    target.kill()
            ),

            spike: ((gametype, other, target) ->
                if not other.bIsMush
                    gametype.game.reply("#{other.name} forgot they are a human!")

                else if randomChance(20)
                    gametype.game.reply("#{other.name} fails to extract a spore for infection!")

                else
                    immuneDmg = 1.5 + moreOrLess(0.75)
                    # ^ if only there was some easy way of NOT hardcoding this... :/

                    gametype.game.reply("#{other.name} extracts a spore and spikes #{target.name} discreetly! They receive #{immuneDmg} damage!")
                    target.attributes["immune"] -= immuneDmg

                    if target.attributes["immune"] <= 0
                        gametype.gameEvent("infect", [other, target])
            )
        }

    checkWinCondition: =>
        hasMush = hasHuman = false

        for p in @game.alivePlayers()
            if p.attributes.bMush
                hasMush = true

            if not p.attributes.bMush
                hasHuman = true

        if not (hasMush or hasHuman)
            @game.reply("Everyone is dead or otherwise out of the game! It's a tie!")

        else if not hasMush
            @game.reply("Humans win!!")

        else if not hasHuman
            @game.reply("Mushes win!")

    onDeath: (player) =>
        @checkWinCondition()

    scoreKill: (player, killer) ->
        killer.attributes.money += 8

    attitudeTo: (from, other) ->
        # 0 = ignore
        # 1 = ally
        # 2 = enemy
        # 3 = fear

        if other.attributes.bMush == from.attributes.bMush
            return 1

        else
            return 2

    initPlayer: (player) ->
        return {
            bMush: randomChance(30)

            weapons: (->
                res = {}
                
                for k, v of @defaultWeapons
                    res[k] = new v(@game, player)

                return res
            )()
            
            health: 100
            maxHealth: 100
            immune: 10
            money: 35
        }


class SMWGame
    constructor: (@conn, @channel, @gametype, @reply) ->
        if games[@conn][@channel]?
            @sendMessage("Error: Game already running on this channel! (#{games[@channel].gametype.gameName})")

            return

        games[@conn][@channel] = @

        @players = {}
        @turns = []
        @deadPlayers = []
        @currentTurn = 0

    stopGame: =>
        games[@conn][@channel] = undefined

        if games[@conn] is {}
            games[@conn] = undefined

    alivePlayers: =>
        return [(if p not in @deadPlayers then p else null) for _, p of @players].filter((x) -> x?)

    onDeath: (player) =>
        @gametype.onDeath(player)

    addBot: (name) =>
        @players[name.toLowerCase()] = new SMWBot(@, playerName)
        @turns.push(@players[name.toLowerCase()])

    addBots: (many) ->
        for _ in [1..many]
            addbot(botNames[Math.floor(Math.random() * (botNames.length - 1))])

    joinMsg: (player) =>
        return @gametype.joinMessage(player)

    startGame: =>
        @gametype.initRatedGame()
        @deadPlayers = []
        @currentTurn = 0

    passTurn: =>
        while turns[@currentTurn] not in @deadPlayers
            @currentTurn++

        if @currentTurn >= @turns.length
            @currentTurn = 0

        @turns[@currentTurn].onTurn()

    sendMessage: (message) =>
        @conn.send("PRIVMSG #{@channel} :#{message}")

    getPlayer: (playerName) =>
        p = @players[playerName.toLowerCase()]

        if p in @deadPlayers
            return null

        else
            return p

    addPlayer: (playerName) =>
        if playerName.toLowerCase() in [x.name.toLowerCase() for x in @deadPlayers]
            msg.reply("You can't join: you're dead or otherwise excluded until game restarts!")

        @players[playerName.toLowerCase()] = new SMWPlayer(@, playerName)
        @turns.push(@players[playerName.toLowerCase()])

    killPlayer: (playername) =>
        @players[playerName.toLowerCase()].kill()

    initPlayer: (player) =>
        return @gametype.initPlayer(player)

    @findGame: (conn, channel) ->
        return games[conn][channel]

class SMWPlayer
    constructor: (@game, @name) ->
        @ready = false
        @attributes = @game.initPlayer(@)

        if not @attributes? then @attributes = {}

        @game.sendMessage("Welcome to the #{@game.gametype.gameName} game, #{@name}! #{@game.joinMsg(@)}")
        
    kill: =>
        @game.sendMessage("#{@name} is out of the game!")
        @game.deadPlayers.push(@name.toLowerCase)
        @game.onDeath(@)

    onTurn: ->

class SMWBot extends SMWPlayer
    onTurn: ->
        # wip

        @game.passTurn()

gametypeOf = (name) ->
    console.dir(gametypes)

    return gametypes[name.toLowerCase()]

module.exports = {
    SMWPlayer: SMWPlayer
    SMWGame: SMWGame
    SMWGametype: SMWGametype
    SMWBot: SMWBot
    SMWWeapon: SMWWeapon
    SMWDamageType: SMWDamageType
    
    gametypeOf: gametypeOf
}