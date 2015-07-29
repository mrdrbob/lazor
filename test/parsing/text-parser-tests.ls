require! <[ util ]>
{ equal: eq, deep-equal: deep-eq } = require 'assert'
{ to-input, end  } = require 'parse-ls'
{ html } = (require '../../src/parsing/text-parser')!

test-rule-fails = (rule, input) -->
	res = input |> to-input |> (rule |> end)
	# console.log (util.inspect res, {depth:null} )
	eq res.success, false

test-rule = (rule, expected-result, input) -->
	res = input |> to-input |> (rule |> end)
	deep-eq { res.success, res.value }, { success: true, value: expected-result }

describe \text-parser ->
	should-parse-to = test-rule html
	should-fail = test-rule-fails html

	specify 'escaped at works' ->
		'@@' |> should-parse-to [{
			type: \encoded
			value: \@
		}]
	specify 'normal text workds' ->
		'something!' |> should-parse-to [{
			type: \encoded
			value: \something!
		}]
	specify 'comments parse' ->
		'<!--Test-->' |> should-parse-to [{
			type: \comment
			value: \Test	
		}]
	specify 'doctype parses' ->
		'<!DOCTYPE html>' |> should-parse-to [{
			type: \declaration
			value: 'DOCTYPE html'
		}]
	specify 'simple self-close tag works' ->
		'<img />' |> should-parse-to [{
			type: \tag
			name: \img
			parts: []
			self-close: true
		}]
	specify 'tag with closing tag works' ->
		'<img></img>' |> should-parse-to [{
			type: \tag
			name: \img
			parts: []
			self-close: false
			body: []
		}]
	specify 'tag with innerText works' ->
		'<img>asdf</img>' |> should-parse-to [{
			type: \tag
			name: \img
			parts: []
			self-close: false
			body: [
				{ type: \encoded, value: \asdf }
			]
		}]
	specify 'tag with attribute works' ->
		'<a href="/">asdf</a>' |> should-parse-to [{
			type: \tag
			name: \a
			parts: [
				{type: \attribute, name: \href, parts: [
					{ type: \encoded, value: '/' }
				]}
			]
			self-close: false
			body: [
				{ type: \encoded, value: \asdf }
			]
		}]
	specify 'can nest tags' ->
		'<div><p>Test</p></div>' |> should-parse-to [{
			type: \tag
			name: \div
			parts: []
			self-close: false
			body: [{
				type: \tag
				name: \p
				parts: []
				self-close: false
				body: [{
					type: \encoded
					value: \Test	
				}]
			}]
		}]

