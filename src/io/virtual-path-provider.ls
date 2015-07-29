require! <[ path ]>

module.exports = (base-path) ->

	full-path = (virtual-path) ->
		if virtual-path.length < 2 || virtual-path[0] != '~' || virtual-path[1] != '/'
			...
		else
			path.join base-path, (virtual-path.substr 2)

	require-path = (virtual-path) ->
		path.join '../', (full-path virtual-path)

	{ full-path, require-path }
