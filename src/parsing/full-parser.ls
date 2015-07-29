
{ delay, $or, end, map, text, always-new, then-set, then-ignore, convert-rule-to-function  } = require 'parse-ls'

{ at, eat-ws } = require './parser-utilities'

statement-resolved = null
statement = delay -> statement-resolved

{ declaration, comment, tag, html } = (require './text-parser') statement
html-triggers = comment 
	|> $or tag 
	|> $or declaration

{ block, if-statement, for-statement, while-statement, expression, group, identifier, argument-list } = (require './statement-parser') html-triggers

block-statement = 
	block
	|> $or if-statement
	|> $or for-statement
	|> $or while-statement
	|> map ->
		if it.type == \block
			it.type = \block-silent
		it

inline-group = group |> map -> { type: \encode, value: it }
inline-expression = expression |> map -> { type: \encode, value: it }

# @section name { /* block */ }
section-statement = 
	always-new -> { type: \section }
	|> then-ignore (text 'section')
	|> eat-ws
	|> then-set \identifier, identifier
	|> eat-ws
	|> then-set \value, block

helper-statement = 
	always-new -> { type: \helper }
	|> then-ignore (text 'helper')
	|> eat-ws
	|> then-set \identifier, identifier
	|> eat-ws
	|> then-set \arguments, argument-list
	|> eat-ws
	|> then-set \value, block

statement-resolved = section-statement
	|> $or helper-statement
	|> $or inline-group
	|> $or block-statement
	|> $or inline-expression

final-rule = (html |> end)
parse = convert-rule-to-function final-rule
parse.as-rule = final-rule

module.exports = parse

