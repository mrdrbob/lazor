require! <[ util ]>
{ equal: eq, deep-equal: deep-eq } = require 'assert'
{ to-input, end  } = require 'parse-ls'
{ statement } = (require '../../src/parsing/statement-parser')!

test-rule-fails = (rule, input) -->
	res = input |> to-input |> (rule |> end)
	# console.log (util.inspect res, {depth:null} )
	eq res.success, false

test-rule = (rule, expected-result, input) -->
	res = input |> to-input |> (rule |> end)
	deep-eq { res.success, res.value }, { success: true, value: expected-result }

describe \statement-parser ->
	should-parse-to = test-rule statement
	should-fail = test-rule-fails statement

	describe \expression ->
		specify 'any expression can also be a statement' ->
			'test()' |> should-parse-to do
				type: \expression-statement
				value:
					type: \binary
					left: { type: \identifier, value: \test }
					right: [{
						type: \call
						value: []
					}]
			'a = 123' |> should-parse-to do
				type: \expression-statement
				value:
					type: \binary
					left: { type: \identifier, value: \a }
					right: [{
						type: \=
						value: { type: \integer-literal, value: 123 }
					}]
		specify 'variable declaration is not an expression' ->
			'var text = test()' |> should-parse-to do
				type: \declare
				identifier: \text
				value:
					type: \binary
					left: { type: \identifier, value: \test }
					right: [{
						type: \call
						value: []
					}]
	describe \control-structures ->
		specify 'if then else should work' ->
			'if (3 < 4) true else false' |> should-parse-to do
				type: \if
				condition:
					type: \binary
					left: { type: \integer-literal, value: 3}
					right: [{
						type: \<
						value: { type: \integer-literal, value: 4 }
					}]
				value: 
					type: \expression-statement
					value:
						{ type: \boolean-literal, value: true }
				'else':
					type: \expression-statement
					value:
						{ type: \boolean-literal, value: false }
		specify 'else is optional' ->
			'if (3 < 4) true' |> should-parse-to do
				type: \if
				condition:
					type: \binary
					left: { type: \integer-literal, value: 3}
					right: [{
						type: \<
						value: { type: \integer-literal, value: 4 }
					}]
				value:
					type: \expression-statement
					value:
						{ type: \boolean-literal, value: true }
				'else': { type: \nop }
		specify 'simple while block' ->
			'while (true) { "loop!" }' |> should-parse-to do
				type: \while
				condition: { type: \boolean-literal, value: true }
				value: 
					type: \block
					value: [{
						type: \expression-statement
						value: { type: \string-literal, value: 'loop!' }
					}]
		specify 'while block' ->
			'while (true) { "loop!" }' |> should-parse-to do
				type: \while
				condition: { type: \boolean-literal, value: true }
				value: 
					type: \block
					value: [{ 
						type: \expression-statement
						value: { type: \string-literal, value: 'loop!' }
					}]
		specify 'for block' ->
			'for (index in test) { "loop!" }' |> should-parse-to do
				type: \for
				identifier: \index
				access: \in
				source: { type: \identifier, value: \test }
				value: 
					type: \block
					value: [{ 
						type: \expression-statement
						value: { type: \string-literal, value: 'loop!' }
					}]
	describe 'block' ->
		specify 'final semicolon is optional' ->
			'{ "test"; 4; }' |> should-parse-to do
				type: \block
				value: [{
					type: \expression-statement
					value:
						type: \string-literal
						value: \test
				}, {
					type: \expression-statement
					value:
						type: \integer-literal
						value: 4	
				}]
			'{ "test"; 4 }' |> should-parse-to do
				type: \block
				value: [{
					type: \expression-statement
					value:
						type: \string-literal
						value: \test
				}, {
					type: \expression-statement
					value:
						type: \integer-literal
						value: 4	
				}]
	describe \lambda ->
		specify 'can parse simple lambda' ->
			'() -> 42' |> should-parse-to do
				type: \expression-statement
				value:
					type: \lambda
					arguments: []
					value:
						type: \expression-statement
						value:
							type: \integer-literal
							value: 42
		specify 'can specify arguments' ->
			'(arg1, arg2) -> 42' |> should-parse-to do
				type: \expression-statement
				value:
					type: \lambda
					arguments: [ \arg1, \arg2 ] 
					value:
						type: \expression-statement
						value:
							type: \integer-literal
							value: 42
