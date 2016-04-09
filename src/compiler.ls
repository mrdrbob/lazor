{ inspect } = require 'util'
vp = require './io/virtual-path'
require! <[ fs path ]>

module.exports = (temp-path-vpp, view-path-vpp, transpiler, full-parser) ->
	cache = {}
	id = 0;

	(view-path) ->
		key = view-path |> vp.to-string
		if cache[key]
			return (require cache[key])


		# Load the body
		body = view-path-vpp.load view-path

		# Parse the body
		ast = full-parser body

		# Transpile to JS
		code = transpiler ast

		# Write to file system
		name = "~/__tmp#{id++}.js" |> vp.parse
		temp-path-vpp.save name, code

		# Cache & return
		require-path = path.resolve (temp-path-vpp.to-file-path name)
		cache[key] = require-path

		return (require require-path)
