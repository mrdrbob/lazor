parse = (require './parsing/full-parser')

module.exports = (view-path, temp-path, globals = {}) ->
	view-path-provider = (require './io/file-system-provider') view-path
	temp-path-provider = (require './io/file-system-provider') temp-path

	transpiler = (require './transpiler') globals
	full-parser = require './parsing/full-parser'

	compiler = (require './compiler') temp-path-provider, view-path-provider, transpiler, full-parser
	view-engine = (require './view-engine') compiler, globals
	view-engine

