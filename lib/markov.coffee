EventEmitter = require('events').EventEmitter
deck = require('deck')
Lazy = require('lazy')
Hash = require('hashish')

clean = (s) ->
    s.toLowerCase().replace(/[^a-z\d]+/g, '_').replace(/^_/, '').replace /_$/, ''

markov = (order) ->
    if !order
        order = 2

    db = {}
    self = {}

    self.fromJSON = (j) ->
        if j instanceof String
            j = JSON.parse(j)

        if j instanceof Buffer
            j = JSON.parse(j.toString('utf-8'))

        self.setDB(j)
        
        return self

    self.seed = (seed, cb) ->
        `var i`
        if seed instanceof EventEmitter
            Lazy(seed).lines.forEach self.seed
            if cb
                seed.on 'error', cb
                seed.on 'end', cb
        else
            text = if Buffer.isBuffer(seed) then seed.toString() else seed
            words = text.split(/\s+/)
            links = []
            i = 0
            while i < words.length
                link = words.slice(i, i + order).join(' ')
                links.push link
                i += order
            if links.length <= 1
                if cb
                    cb null
                return
            i = 1
            while i < links.length
                word = links[i - 1]
                cword = clean(word)
                next = links[i]
                cnext = clean(next)
                node = if Hash.has(db, cword) then db[cword] else
                    count: 0
                    words: {}
                    next: {}
                    prev: {}
                db[cword] = node
                node.count++
                node.words[word] = (if Hash.has(node.words, word) then node.words[word] else 0) + 1
                node.next[cnext] = (if Hash.has(node.next, cnext) then node.next[cnext] else 0) + 1
                if i > 1
                    prev = clean(links[i - 2])
                    node.prev[prev] = (if Hash.has(node.prev, prev) then node.prev[prev] else 0) + 1
                else
                    node.prev[''] = (node.prev[''] or 0) + 1
                i++
            if !Hash.has(db, cnext)
                db[cnext] =
                    count: 1
                    words: {}
                    next: '': 0
                    prev: {}
            n = db[cnext]
            n.words[next] = (if Hash.has(n.words, next) then n.words[next] else 0) + 1
            n.prev[cword] = (if Hash.has(n.prev, cword) then n.prev[cword] else 0) + 1
            n.next[''] = (n.next[''] or 0) + 1
            if cb
                cb null
        return

    self.search = (text) ->
        words = text.split(/\s+/)
        # find a starting point...
        start = null
        groups = {}
        i = 0
        while i < words.length
            word = clean(words.slice(i, i + order).join(' '))
            if Hash.has(db, word)
                groups[word] = db[word].count
            i += order
        deck.pick groups

    self.pick = ->
        deck.pick Object.keys(db)

    self.next = (cur) ->
        if !cur or !db[cur]
            return undefined
        next = deck.pick(db[cur].next)
        next and
            key: next
            word: deck.pick(db[next].words) or undefined

    self.prev = (cur) ->
        if !cur or !db[cur]
            return undefined
        prev = deck.pick(db[cur].prev)
        prev and
            key: prev
            word: deck.pick(db[prev].words) or undefined

    self.forward = (cur, limit) ->
        res = []
        while cur and !limit or res.length < limit
            next = self.next(cur)
            if !next
                break
            cur = next.key
            res.push next.word
        res

    self.backward = (cur, limit) ->
        res = []
        while cur and !limit or res.length < limit
            prev = self.prev(cur)
            if !prev
                break
            cur = prev.key
            res.unshift prev.word
        res

    self.fill = (cur, limit) ->
        res = [ deck.pick(db[cur].words) ]
        if !res[0]
            return []
        if limit and res.length >= limit
            return res
        pcur = cur
        ncur = cur
        while pcur or ncur
            if pcur
                prev = self.prev(pcur)
                pcur = null
                if prev
                    pcur = prev.key
                    res.unshift prev.word
                    if limit and res.length >= limit
                        break
            if ncur
                next = self.next(ncur)
                ncur = null
                if next
                    ncur = next.key
                    res.unshift next.word
                    if limit and res.length >= limit
                        break
        res

    self.respond = (text, limit) ->
        cur = self.search(text) or self.pick()
        self.fill cur, limit

    self.word = (cur) ->
        db[cur] and deck.pick(db[cur].words)

    self.getDB = ->
        return db

    self.setDB = (newd) ->
        db = newd

    return self

module.exports = markov