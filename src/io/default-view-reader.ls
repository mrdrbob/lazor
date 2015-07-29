require! <[ fs path ]>
full-parser = require '../parsing/full-parser'

module.exports = (vpp) ->
	read-view = (view-path) ->
		full-path = vpp.full-path view-path
		body = fs.read-file-sync full-path, \utf-8
		full-parser body

	module.exports = read-view
