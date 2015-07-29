parse = (require './parsing/full-parser')

module.exports = (view-path, temp-path) ->
	view-path-provider = (require './io/virtual-path-provider') view-path
	temp-path-provider = (require './io/virtual-path-provider') temp-path
	compiler = (require './default-compiler') temp-path-provider, view-path-provider
	(require './view-engine') compiler

