p = require 'path'

parse = (raw-string) -> raw-string.split '/' |> collapse
to-string = (parts) -> parts.join '/'
is-dir = (parts) -> parts.length && parts[parts.length - 1] == ''
is-rooted = (parts) -> parts.length && (parts.0 == '~' || parts.0 == '')
collapse = (parts) ->
	output = []

	if is-rooted
		output.push ''

	for part in parts
		switch part
		| \~ => # do nothing
		| '' => # do nothing
		| '.' => # do nothing
		| '..' =>
			if !output.length || output[output.length - 1] == '~'
				throw 'Cannot back out further'
			else
				output.pop!
		| _ => output.push part

	if is-dir parts
		output.push ''

	output

join = (right, left) -->
	if is-rooted right || !left.length
		right.slice! |> collapse
	else if is-dir left
		left.concat right |> collapse
	else 
		(left.slice 0, left.length - 1).concat right |> collapse

to-web-path = (parts) -> parts |> to-string

to-file-path = (base-path, parts) -->
	if !is-rooted parts
		...
	else
		p.join base-path, ((parts.slice 1, parts.length) |> to-string)


module.exports = { parse, to-string, is-dir, is-rooted, collapse, join, to-web-path, to-file-path }
