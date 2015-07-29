{ inspect } = require 'util'
{ equal: eq, deep-equal: deep-eq } = require 'assert'
{ to-input, end  } = require 'parse-ls'
full-parser = (require '../../src/parsing/full-parser').as-rule

should-fail = (input) ->
	res = input |> to-input |> (html |> end)
	eq res.success, false

should-result = (expected-result, input) -->
	res = input |> to-input |> (full-parser |> end)
	deep-eq { res.success, res.value }, { success: true, value: expected-result }

describe \full-parser ->
	specify 'should handle normal html' ->
		'<span>Hello!</span>' |> should-result [{
			type: \tag
			name: \span
			parts: []
			self-close: false
			body: [{
				type: \encoded
				value: \Hello!
			}]
		}]
	specify 'should handle simple expression' ->
		'@5' |> should-result [{
			type: \encode
			value:
				type: \integer-literal
				value: 5
		}]
	specify 'should handle mix and match' ->
		'<tag @(3 + 5) class="alt">Hi, @name</tag>' |> should-result [{
			type: \tag
			name: \tag
			self-close: false
			parts: [{
				type: \encode
				value:
					type: \binary
					left:
						type: \integer-literal
						value: 3
					right: [{
						type: \+
						value:
							type: \integer-literal
							value: 5	
					}]
			},{
				type: \attribute
				name: \class
				parts: [{
					type: \encoded
					value: \alt	
				}]
			}]
			body: [{
				type: \encoded
				value: 'Hi, '
			},{
				type: \encode
				value:
					type: \identifier
					value: \name	
			}]
		}]
	specify 'params can be used to avoid conflicts' ->
		'@(5) <!DOCTYPE html>' |> should-result [{
			type: \encode
			value:
				type: \integer-literal
				value: 5
		}, {
			type: \encoded
			value: ' '
		}, {
			type: \declaration
			value: 'DOCTYPE html'
		}]
	specify 'for loops OK' ->
		'@for(x in y) { 10 }' |> should-result [{
			type: \for
			identifier: \x
			access: \in
			source:
				type: \identifier
				value: \y
			value:
				type: \block
				value: [{
					type: \expression-statement
					value:
						type: \integer-literal
						value: 10	
				}]
		}]
	specify 'tags nested in blocks' ->
		'@{ "hi"; <tag /> }' |> should-result [{
			type: \block-silent
			value: [{
				type: \expression-statement
				value:
					type: \string-literal
					value: \hi
			}, {
				type: \tag
				name: \tag
				self-close: true
				parts: []
			}]
		}]
	specify 'nesting works without separators' ->
		'<div> @{ "nested" <span>Hello</span> } </div>' |> should-result [{
			type: \tag
			name: \div
			parts: []	
			self-close: false
			body: [{
				type: \encoded
				value: ' '
			},{
				type: \block-silent
				value: [{
					type: \expression-statement
					value:
						type: \string-literal
						value: \nested	
				},{
					type: \tag
					name: \span
					parts: []
					self-close: false
					body: [{
						type: \encoded
						value: \Hello	
					}]	
				}]
			}, {
				type: \encoded
				value: ' '	
			}]
		}]
	specify '@section works' ->
		'@section footer { <p>Footer!</p>  }' |> should-result [{
			type: \section
			identifier: \footer
			value:
				type: \block
				value: [{
					type: \tag
					name: \p
					parts: []
					self-close: false
					body: [{
						type: \encoded
						value: \Footer!	
					}]
				}]
		}]
	specify '@helper works' ->
		'@helper item (arg1, arg2) { <p>Footer!</p>  }' |> should-result [{
			type: \helper
			identifier: \item
			arguments: [ \arg1, \arg2 ]
			value:
				type: \block
				value: [{
					type: \tag
					name: \p
					parts: []
					self-close: false
					body: [{
						type: \encoded
						value: \Footer!	
					}]
				}]
		}]
