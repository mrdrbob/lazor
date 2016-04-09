{ is-array, inspect } = require 'util'
encode = require 'ent/encode'
vp = require './io/virtual-path'

module.exports = (compile, globals = {}) ->
	execute = (raw-path, model = {}, view-state = {}, parent = null) ->
		view-path = vp.parse raw-path
		view-function = compile view-path
		output = []

		convert-to-string = (obj) ->
			if typeof obj == \undefined || obj == null
				''
			else if is-array obj
				(for part in obj
					(convert-to-string part)).join ''
			else if obj.type == \encoded
				if obj.value
					obj.value.to-string!
				else
					''
			else
				encode obj.to-string!

		raw = (value) -> { type: \encoded, value }
		write = -> output.push (convert-to-string it)
		body = -> raw parent.body-text
		render = (section, fallback) ->
			if parent.sections[section]
				section-text = parent.sections[section] runtime, view-state, model, {}
				''
			else
				if typeof fallback == \function
					fallback!
				''

		partial = (partial-path, partial-model = null) ->
			result = execute partial-path, partial-model, view-state, null
			write (raw result)
			''

		runtime = { raw, write, body, render, partial, json: JSON.stringify, uri: encodeURIComponent }

		result = view-function runtime, view-state, model, globals
		result.parent = parent

		if result.layout
			result.body-text = (output.join '')
			execute result.layout, model, view-state, result
		else
			output.join ''

	execute
