clasp = (function ()
{
	function assert(condition, error)
	{
		if (!condition)
		{
			throw new Error(error || 'Assertion failed')
		}
	}
	
	var model = {}
	model.Node = function () {}
	model.Node.prototype = 
	{
		to_string: function ()
		{
			var s = ''
			
			for (var n in this._fields)
			{
				s += this._to_string(this._fields[n])
			}
			
			return s
		},
		
		_to_string: function (node)
		{
			var s = ''
			
			if (node)
			{
				if (node.constructor == Array)
				{
					for (var i=0; i<node.length; i++)
					{
						s += this._to_string(node[i])
					}
				}
				else if (node.to_string)
				{
					s += node.to_string()
				}
				else if (node.constructor == String)
				{
					s += node
				}
				else
				{
					throw new Error('Unknown field type')
				}
			}
			
			return s
		}
	}
	
	var create_node = function (name, fields, prototype)
	{
		prototype = prototype || {}
		model[name] = function ()
		{
			assert(arguments.length == fields.length, 'Wrong number of arguments for '+name)
			this._fields = {}
			this._rule_name = name.toLowerCase()
			
			for (var i=0; i<fields.length; i++)
			{
				this._fields[fields[i]] = arguments[i]
			}
			
			/*
			if (name != 'Ignore')
			{
				console.log('\t', name, this.to_string())
			}*/
		}
		model[name].prototype = {}
		
		for (var n in model.Node.prototype)
		{
			model[name].prototype[n] = model.Node.prototype[n]
		}
		
		for (var n in prototype)
		{
			model[name].prototype[n] = prototype[n]
		}
	}
	
	var node_types = [
		[
			'Ignore',
			['parts'],
			{
				to_string: function ()
				{
					if (clasp.preserve_whitespace)
					{
						return this._to_string(this._fields.parts)
					}
					else
					{
						return ''
					}
				}
			}
		],
		[
			'Comment',
			['comment']
		],
		[
			'Stylesheet',
			['charset', 'imports', 'namespaces', 'contents', 'post']
		],
		[
			'Charset',
			['pre', 'sym', 'charset', 'post', 'terminator']
		],
		[
			'Import',
			['pre', 'sym', 'uri', 'media', 'terminator']
		],
		[
			'Namespace',
			['pre', 'sym', 'prefix', 'uri', 'terminator']
		],
		[
			'Media',
			['pre', 'sym', 'media', 'brace_open', 'rulesets', 'brace_close']
		],
		[
			'Medium',
			['pre', 'medium']
		],
		[
			'Page',
			['pre', 'sym', 'identifier', 'psuedo_page', 'brace_open', 'declarations', 'brace_close']
		],
		[
			'PsuedoPage',
			['pre', 'prefix', 'value']
		],
		[
			'FontFace',
			['pre', 'sym', 'brace_open', 'declarations', 'brace_close']
		],
		[
			'Identifier',
			['pre', 'value']
		],
		[
			'BracketOpen',
			['pre', 'bracket']
		],
		[
			'BracketClose',
			['pre', 'bracket']
		],
		[
			'BraceOpen',
			['pre', 'brace']
		],
		[
			'BraceClose',
			['pre', 'brace']
		],
		[
			'ParenOpen',
			['pre', 'paren']
		],
		[
			'ParenClose',
			['pre', 'paren']
		],
		[
			'Terminator',
			['pre', 'terminator']
		],
		[
			'Separator',
			['pre', 'separator']
		],
		[
			'Operator',
			['pre', 'operator']
		],
		[
			'Combinator',
			['pre', 'combinator']
		],
		[
			'UnaryOperator',
			['pre', 'operator']
		],
		[
			'Property',
			['pre', 'name']
		],
		[
			'Ruleset',
			['pre', 'selectors', 'brace_open', 'declarations', 'brace_close']
		],
		[
			'Selector',
			['parts']
		],
		[
			'SimpleSelector',
			['parts']
		],
		[
			'Hash',
			['pre', 'prefix', 'name']
		],
		[
			'ClassName',
			['pre', 'prefix', 'name']
		],
		[
			'ElementName',
			['prefix', 'name']
		],
		[
			'NamespacePrefix',
			['name', 'inter', 'combinator']
		],
		[
			'Attribute',
			['bracket_open', 'identifier', 'operator', 'value', 'bracket_close']
		],
		[
			'AttributeOperator',
			['pre', 'operator']
		],
		[
			'AttributeValue',
			['pre', 'value']
		],
		[
			'Psuedo',
			['pre', 'prefix', 'value']
		],
		[
			'PsuedoFunction',
			['name', 'parameter']
		],
		[
			'PsuedoParameter',
			['pre', 'paren_open', 'value', 'paren_close']
		],
		[
			'Declaration',
			['pre', 'property', 'separator', 'expression', 'priority', 'terminator'],
			{
				set_terminator: function (terminator)
				{
					this._fields.terminator = terminator
				}
			}
		],
		[
			'Priority',
			['pre', 'sym']
		],
		[
			'Expression',
			['parts']
		],
		[
			'Term',
			['unary_operator', 'value']
		],
		[
			'Function',
			['identifier', 'paren_open', 'expression', 'paren_close']
		],
		[
			'Number',
			['pre', 'value']
		],
		[
			'Percentage',
			['pre', 'value', 'suffix']
		],
		[
			'Length',
			['pre', 'value', 'unit']
		],
		[
			'Ems',
			['pre', 'value', 'unit']
		],
		[
			'Exs',
			['pre', 'value', 'unit']
		],
		[
			'Angle',
			['pre', 'value', 'unit']
		],
		[
			'Time',
			['pre', 'value', 'unit']
		],
		[
			'Frequency',
			['pre', 'value', 'unit']
		],
		[
			'String',
			['pre', 'quote', 'value'],
			{
				to_string: function ()
				{
					return this._to_string(this._fields.pre)
						+ this._fields.quote
						+ this._fields.value.replace(new RegExp(this._fields.quote+'|\\'+this._fields.quote, 'g'), "\\"+this._fields.quote)
						+ this._fields.quote
				}
			}
		],
		[
			'URI',
			['pre', 'prefix', 'paren_open', 'value', 'paren_close']
		],
		[
			'URL',
			['pre', 'value']
		],
		[
			'UnicodeRange',
			['pre', 'prefix', 'value']
		],
		[
			'HexColor',
			['pre', 'prefix', 'value']
		],
		[
			'RequiredSpace',
			['space'],
			{
				to_string: function ()
				{
					if (clasp.preserve_whitespace)
					{
						return this._fields.space
					}
					else
					{
						return ' '
					}
				}
			}
		],
		[
			'AtRule',
			['keyword', 'terms', 'block']
		],
		[
			'AtKeyword',
			['pre', 'prefix', 'name']
		],
		[
			'Block',
			['pre', 'brace_open', 'contents', 'brace_close']
		]
	]
	
	for (var i=0; i<node_types.length; i++)
	{
		create_node(node_types[i][0], node_types[i][1], node_types[i][2])
	}
	
	clasp = {}
	clasp.model = model
	
	if (typeof _clasp_parser != 'undefined')
	{
		clasp.parser = _clasp_parser
	}
	
	clasp.preserve_whitespace = true
	
	return clasp
})()

if (typeof module != 'undefined')
{
	clasp.parser = require('./clasp.parser.node.js')
	module.exports = clasp
}