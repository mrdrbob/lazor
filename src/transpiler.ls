uniqifier = 0

module.exports = (global-values = {}) ->

	transpile-set = (expressions, joiner = '') ->
		results = []
		for expression in expressions
			results.push (transpile expression)

		results.join joiner

	transpile-map = (value, joiner = '') ->
		results = for key of value
			"\"#{key}\": #{transpile value[key]}"

		results.join joiner

	transpile = (expression, skip-block = false) ->
		switch expression.type
		| \expression-statement => "#{transpile expression.value};\n"
		| \string-literal => JSON.stringify expression.value
		| \array-literal => "[#{transpile-set expression.value, ','}]"
		| \object-literal => "{#{transpile-map expression.value, ','}}"
		| \integer-literal => expression.value.to-string!
		| \identifier => expression.value
		| \null-literal => 'null'
		| \encoded => "write(raw(#{JSON.stringify expression.value}));\n"
		| \comment => "/*\n#{expression.value}\n*/\n"
		| \declaration => "write(raw('<!#{expression.value}>'));\n"
		| \tag =>
			switch expression.name
			| \text => transpile-set expression.body
			| _ =>
				["write(raw('<#{expression.name}'));\n"
				(transpile-set expression.parts)
				(if expression.self-close
					"write(raw(' />'));\n"
				else
					"write(raw('>'));\n
					#{transpile-set expression.body}
					write(raw('</#{expression.name}>'));\n"
				)].join ''
		| \attribute =>
			"write(raw(' #{expression.name}=\"'));\n#{transpile-set expression.parts}write(raw('\"'));\n"
		| \declare => "var #{expression.identifier} = #{transpile expression.value};\n"
		| \if, \while => "if (#{transpile expression.condition}) \n{\n#{transpile expression.value, true}}\n"
		| \for =>
			id = uniqifier++
			switch expression.access
			| \in =>
				"var $$source#{id} = #{transpile expression.source};\n
				var $$length#{id} = $$source#{id}.length;\n
				var $$index#{id} = 0;\n
				var #{expression.identifier};\n
				for ($$index#{id} = 0; $$index#{id} < $$length#{id}; $$index#{id}++)\n
				{\n
				#{expression.identifier} = $$source#{id}[$$index#{id}];\n
				#{transpile expression.value, true}
				}\n"
			| \of =>
				"var $$source#{id} = #{transpile expression.source};\n
				var $$keys#{id} = Object.keys($$source#{id});\n
				var $$length#{id} = $$keys#{id}.length\n
				var $$index#{id} = 0;\n
				var #{expression.identifier};\n
				for ($$index#{id} = 0; $$index#{id} < $$length#{id}; $$index#{id}++)\n
				{\n
				#{expression.identifier} = $$keys#{id}[$$index#{id}];\n
				#{transpile expression.value, true}
				}\n"
			| _ => '/* IF ERR: #{expression.access} */\n'	
		| \lambda =>
			"function (#{expression.arguments.join ','}) {\n#{transpile expression.value, true}}\n"
		| \encode => "write(#{transpile expression.value});\n"
		| \block => 
			if skip-block
				(transpile-set expression.value)
			else
				"{\n#{transpile-set expression.value}}\n"
		| \block-silent => transpile-set expression.value
		| \section =>
			"$$result.sections['#{expression.identifier}'] = #{transpile-function expression.value.value}"
		| \helper =>
			"var #{expression.identifier} = function ( #{expression.arguments.join ','} ) {\n#{transpile expression.value, false}return '';\n};\n"
		| \suppress => transpile expression.value
		| \assign => "#{expression.identifier} = #{transpile expression.value}"
		| \set => "#{expression.identifier} = #{transpile expression.value};\n"
		| \binary => "#{transpile expression.left}#{transpile-set expression.right}"
		| \binary-statement => "#{transpile expression.left}#{transpile-set expression.right};\n"
		| \call => "(#{transpile-set expression.value, ','})"
		| \index => "[#{transpile expression.value}]"
		| \property => ".#{expression.value}"
		| \negate => ".#{transpile expression.value}"
		| '=', '||', '&&', '==', '===', '!=', '!==', '>=', '<=', '>', '<', '+', '-', '/', '*' => " #{expression.type} #{transpile expression.value}"
		| \nop => ''
		| _ =>
			console.log expression
			"/* ERR #{expression.type} */\n"

	transpile-function = (ast) ->
		runtime-values = for glob in transpiler.runtime-globals
			"var #{glob} = runtime.#{glob};\n"

		global-values-str = for glob of global-values
			"var #{glob} = globals.#{glob};\n"

		"function (runtime, viewState, model, globals) {\n
		#{runtime-values.join ''}
		#{global-values-str.join ''}
		var layout = null;\n
		var $$result = {};\n
		$$result.sections = {};\n
		#{transpile-set ast}
		$$result.layout = layout;\n
		return $$result;\n
		};\n"

	transpiler = (ast) -> "module.exports = #{transpile-function ast}"

	transpiler.runtime-globals = <[ write raw uri body render partial ]>

	transpiler
