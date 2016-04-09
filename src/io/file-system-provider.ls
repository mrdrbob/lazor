
require! <[ fs ]>
vp = require './virtual-path'

module.exports = (base-path) ->
	to-file-path = vp.to-file-path base-path
	load = (virtual-path) -> fs.read-file-sync (to-file-path virtual-path), \utf-8
	save = (virtual-path, data) -> fs.write-file-sync (to-file-path virtual-path), data

	{ load, save, to-file-path }
