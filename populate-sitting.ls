require! \./lib/ly
require! <[request optimist path fs sh async]>

{Parser} = require \./lib/parser

metaOnly = true
skip = true
funcs = []
ly.forGazette null (id, g, type, entries, files) ->
    return if g.sitting
    return if type isnt /院會紀錄/
    files = [files.0] if metaOnly
    files.forEach (uri) -> funcs.push (done) ->
        fname = path.basename uri
        file = "source/#{id}/#{fname}"
        _, {size}? <- fs.stat file
        return done! unless size
        html = file.replace /\.doc$/, '.html'

        extractMeta = ->
            meta = null
            parser = new Parser do
                output: ->
                output-json: -> meta := it
            try
                parser.parseHtml fs.readFileSync html, \utf8
            catch err
                console.log \err err
            if meta?ad
                g <<< meta{ad,session,sitting}
                console.log id, g
            done!

        _, {size}? <- fs.stat html
        return extractMeta! if size
        console.log \doing file
        output <- sh "/Applications/LibreOffice.app/Contents/MacOS/python unoconv/unoconv  -f html #file" .result
        console.log \converted output
        extractMeta!

err, res <- async.waterfall funcs
console.log \ok, res
fs.writeFileSync \data/gazettes.json JSON.stringify ly.gazettes, null, 4
