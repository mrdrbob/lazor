{ always-new, char, simple, any, $or, then-keep, then-ignore, then-array-concat, as-array, many, maybe, except, text, join-string, at-least-once, map, as-object-with-value, then-set, with-error-message, delay, convert-rule-to-function, fail } = require 'parse-ls'

module.exports = (external-rule = null) ->
	if (!external-rule)
		external-rule = (input) -> fail 'Unexpected input', input
	

	# Top-level rule, with lists
	statement-resolved = null
	statement = delay -> statement-resolved

	util = require './parser-utilities'
	{ space, tab, cr, lf, minus, plus, underscore, dquote, squote, paren-open, paren-close, square-open, square-close, bracket-open, bracket-close, exclamation, dot, comma, semi, question, colon, star, bslash, fslash, percent, eq, ws, digit, lower, upper, letter, eat-ws, eat-req-ws, create-list, identifier }  = util
	{ expression, group, argument-list } = (require './expression-parser') statement

	# Utility for building conditionals
	build-conditional-part = util.build-conditional-part expression, statement

	statement-list = create-list statement, semi

	# var x = value
	declare-statement = 
		always-new -> { type: \declare }
		|> then-ignore (text 'var')
		|> eat-req-ws
		|> then-set \identifier, identifier
		|> eat-ws
		|> then-ignore eq
		|> eat-ws
		|> then-set \value, expression

	# If
	else-statement = 
		text 'else'
		|> eat-ws
		|> then-keep statement

	if-start = build-conditional-part \if

	if-statement = 
		if-start
		|> then-set \else, (else-statement |> $or (always-new -> { type: \nop }))

	while-statement = build-conditional-part \while

	for-statement = 
		always-new -> { type: \for }
		|> then-ignore (text 'for')
		|> eat-ws
		|> then-ignore paren-open
		|> eat-ws
		|> then-set \identifier, identifier
		|> eat-ws
		|> then-set \access, ((text 'in') |> $or (text 'of'))
		|> eat-ws
		|> then-set \source, expression
		|> eat-ws
		|> then-ignore paren-close
		|> eat-ws
		|> then-set \value, statement

	block = 
		always-new -> { type: \block }
		|> then-ignore bracket-open
		|> eat-ws
		|> then-set \value, statement-list
		|> eat-ws
		|> then-ignore bracket-close

	statement-resolved = if-statement
		|> $or while-statement
		|> $or for-statement
		|> $or declare-statement
		|> $or block
		|> $or (expression |> map -> { type: \expression-statement, value: it })
		|> $or external-rule

	{ statement, block, if-statement, for-statement, while-statement, expression, identifier, group, argument-list }
