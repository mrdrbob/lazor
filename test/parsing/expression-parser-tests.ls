require! <[ util ]>
{ equal: eq, deep-equal: deep-eq } = require 'assert'
{ to-input, end  } = require 'parse-ls'
{ expression } = (require '../../src/parsing/expression-parser')!

test-rule-fails = (rule, input) -->
	res = input |> to-input |> (rule |> end)
	# console.log (util.inspect res, {depth:null} )
	eq res.success, false

test-rule = (rule, expected-result, input) -->
	res = input |> to-input |> (rule |> end)
	deep-eq { res.success, res.value }, { success: true, value: expected-result }

describe \expression-parser ->
	should-parse-to = test-rule expression
	should-fail = test-rule-fails expression

	describe \identifier ->
		specify 'should parse simple identifiers' ->
			\varname |> should-parse-to { type: \identifier, value: \varname }
		specify 'underscores, dashes, and numbers are OK' ->
			'_var_name-34' |> should-parse-to { type: \identifier, value: \_var_name-34 }
		specify 'numbers may not appear at the start' ->
			\43asdf |> should-fail
	
	describe 'true, false, null' ->
		specify 'should parse false' ->
			\false |> should-parse-to { type: \boolean-literal, value: false }
		specify 'should parse true' ->
			\true |> should-parse-to { type: \boolean-literal, value: true }
		specify 'should parse null' ->
			\null |> should-parse-to { type: \null-literal }

	describe \integer ->
		specify 'should parse integers' ->
			\12345 |> should-parse-to { type: \integer-literal, value: 12345 }

	describe \strings ->
		specify 'should parse single-quoted string' ->
			"'string'" |> should-parse-to { type: \string-literal, value: \string }
		specify 'should parse double-quoted string' ->
			'"string"' |> should-parse-to { type: \string-literal, value: \string }
		specify 'can contain quotes of the other type' ->
			'"a \'string\'!"' |> should-parse-to { type: \string-literal, value: "a 'string'!" }
			"'a \"string\"!'" |> should-parse-to { type: \string-literal, value: 'a "string"!' }
		specify 'quote can be escaped' ->
			'"6\\\" sub"' |> should-parse-to { type: \string-literal, value: '6" sub' }
			"'6\\\' sub'" |> should-parse-to { type: \string-literal, value: "6' sub" }
		specify 'slash can be escaped' ->
			'"a\\\\b"' |> should-parse-to { type: \string-literal, value: 'a\\b' }
			"'a\\\\b'" |> should-parse-to { type: \string-literal, value: 'a\\b' }


	describe \array-literal ->
		specify 'can parse simple array' ->
			'[1, 2, 3]' |> should-parse-to do
				type: \array-literal
				value:
					{ type: \integer-literal, value: 1}
					{ type: \integer-literal, value: 2}
					{ type: \integer-literal, value: 3}
		specify 'trailing separator is OK' ->
			'[1, 2, 3, ]' |> should-parse-to do
				type: \array-literal
				value:
					{ type: \integer-literal, value: 1}
					{ type: \integer-literal, value: 2}
					{ type: \integer-literal, value: 3}
		specify 'can be nested' ->
			'[1, [2, 3]]' |> should-parse-to do
				type: \array-literal
				value:
					{ type: \integer-literal, value: 1}
					{ type: \array-literal, value: [
						{ type: \integer-literal, value: 2}
						{ type: \integer-literal, value: 3}
					]}

	describe \object-literal ->
		specify 'can parse simple object' ->
			'{ name: "bob" }' |> should-parse-to do
				type: \object-literal
				value: 
					name: { type: \string-literal, value: \bob }
		specify 'identifiers can be quoted' ->
			'{ "first name": "bob" }' |> should-parse-to do
				type: \object-literal
				value: 
					'first name': { type: \string-literal, value: \bob }
		specify 'empty curlies = empty object literal (not block)' ->
			'{ }' |> should-parse-to do
				type: \object-literal
				value: { }

	describe \group ->
		specify 'does\'t effect simple expressions' ->
			'( "test" )' |> should-parse-to { type: \string-literal, value: \test }

	describe \negate ->
		specify 'can negate things' ->
			'!false' |> should-parse-to { type: \negate, value: { type: \boolean-literal, value: false } }
		specify 'ignores double negation' ->
			'!!false' |> should-parse-to { type: \boolean-literal, value: false }
		specify 'odd negation comes through' ->
			'!!!!!false' |> should-parse-to { type: \negate, value: { type: \boolean-literal, value: false } }

	describe \negative ->
		specify 'can make things negative' ->
			'-4574' |> should-parse-to { type: \negative, value: { type: \integer-literal, value: 4574 } }
		specify 'ignores double negation' ->
			'--4574' |> should-parse-to { type: \integer-literal, value: 4574 }
		specify 'odd negation comes through' ->
			'---4574' |> should-parse-to { type: \negative, value: { type: \integer-literal, value: 4574 } }

	describe \method ->
		specify 'can access properties directly' ->
			'test.value' |> should-parse-to do
				type: \binary
				left:
					type: \identifier
					value: \test
				right: [{
					type: \property
					value: \value
				}]
		specify 'can reference an index' ->
			'test[3]' |> should-parse-to do
				type: \binary
				left:
					type: \identifier
					value: \test
				right: [{
					type: \index
					value:
						type: \integer-literal
						value: 3
				}]
		specify 'can call a method' ->
			'test(5)' |> should-parse-to do
				type: \binary
				left:
					type: \identifier
					value: \test
				right: [{
					type: \call
					value: [{
						type: \integer-literal
						value: 5
					}]
				}]
		specify 'can call a method (no args)' ->
			'test()' |> should-parse-to do
				type: \binary
				left:
					type: \identifier
					value: \test
				right: [{
					type: \call
					value: []
				}]
		specify 'can call a method (multiple args)' ->
			'test(1, 2, "test")' |> should-parse-to do
				type: \binary
				left:
					type: \identifier
					value: \test
				right: [{
					type: \call
					value: [
						{ type: \integer-literal, value: 1 },
						{ type: \integer-literal, value: 2 },
						{ type: \string-literal, value: \test }
					]
				}]
		specify 'can chain methods' ->
			'test.prop[1](5)' |> should-parse-to do
				type: \binary
				left:
					type: \identifier
					value: \test
				right: [
					{ type: \property, value: \prop },
					{ type: \index, value: { type: \integer-literal, value: 1 } },
					{ type: \call, value: [{ type: \integer-literal, value: 5 }] }
				]

	describe \binary ->
		specify 'can add stuff' ->
			'3 + 5' |> should-parse-to do
				type: \binary
				left:
					type: \integer-literal
					value: 3
				right: [{
					type: \+
					value: { type: \integer-literal, value: 5 }
				}]
		specify 'can chain additions' ->
			'3 + 5 - 7' |> should-parse-to do
				type: \binary
				left:
					type: \integer-literal
					value: 3
				right: [
					{ type: \+
					value: { type: \integer-literal, value: 5 } },
					{ type: \-
					value: { type: \integer-literal, value: 7 } }
				]
		specify 'can multiply stuff' ->
			'3 * 5 / 7 % 2' |> should-parse-to do
				type: \binary
				left:
					type: \integer-literal
					value: 3
				right: [
					{ type: \*
					value: { type: \integer-literal, value: 5 } },
					{ type: '/'
					value: { type: \integer-literal, value: 7 } },
					{ type: '%'
					value: { type: \integer-literal, value: 2 } }
				]
		specify 'can compare stuff' ->
			'4 != 5 > 10 == 9' |> should-parse-to do
				type: \binary
				left:
					type: \integer-literal
					value: 4
				right: [
					{ type: '!='
					value: { type: \integer-literal, value: 5 } },
					{ type: '>'
					value: { type: \integer-literal, value: 10 } },
					{ type: '=='
					value: { type: \integer-literal, value: 9 } }
				]
		specify 'can use logic' ->
			'false || true && false' |> should-parse-to do
				type: \binary
				left:
					type: \boolean-literal
					value: false
				right: [
					{ type: '||'
					value: { type: \boolean-literal, value: true } },
					{ type: '&&'
					value: { type: \boolean-literal, value: false } }
				]
		specify 'can assign as an expression' ->
			'a = 5' |> should-parse-to do
				type: \binary
				left:
					type: \identifier
					value: \a
				right: [
					{ type: '='
					value: { type: \integer-literal, value: 5 }}
				]
		specify 'order of operations' ->
			'1 + 2 * 3 > 10 && false' |> should-parse-to do
				type: \binary
				left:
					type: \binary
					left: 
						type: \binary
						left: { type: \integer-literal, value: 1 }
						right: [{ 
							type: '+'
							value:
								type: \binary
								left: { type: \integer-literal, value: 2 }
								right: [{ 
									type: '*'
									value: { type: \integer-literal, value: 3 } 
								}] 
						}] 
					right: [{
						type: '>'
						value: { type: \integer-literal, value: 10 } 
					}] 
				right: [{ 
					type: '&&'
					value: { type: \boolean-literal, value: false } 
				}] 
		specify 'order of operations forced' ->
			res = '1 + 2 * 3 > 10 && false' |> to-input |> (expression |> end)
			res2 = '((1 + (2 * 3)) > 10) && false' |> to-input |> (expression |> end)
			
			delete res.remaining;
			delete res2.remaining;
			deep-eq res2, res
		specify 'space between the operation and the right side is required.' ->
			'1+2' |> should-fail
			# This is necessary, because otherwise 3 <span></span> looks like
			# 3 is less than span is greater than ERROR!
			# TODO: Find a reasonable work around for this

