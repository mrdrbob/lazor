{ inspect } = require 'util'
require! <[ fs path ]>

transpile = require './transpiler'
full-parser = require './parsing/full-parser'

module.exports = (temp-path-vpp, view-path-vpp) ->
	cache = {}
	id = 0;

	(view-path) ->
		if cache[view-path]
			return (require cache[view-path])

		# Generate a temp path
		name = "~/__tmp#{id++}.js"
		temp-full-path = temp-path-vpp.full-path name

		# Load the body
		full-viewpath = view-path-vpp.full-path view-path
		body = fs.read-file-sync full-viewpath, \utf-8

		# Parse the body
		ast = full-parser body

		# Transpile to JS
		code = transpile ast

		# Write to file system
		fs.write-file-sync temp-full-path, code

		# Cache & return
		require-path = temp-path-vpp.require-path name
		cache[view-path] = require-path

		return (require require-path)
