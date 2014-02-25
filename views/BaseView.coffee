Backbone = require( 'backbone' )
_ = require( 'underscore' )
 
module.exports = class View extends Backbone.View
	render: ->
		super
		@$el.html( _.template( @template, @model.attributes ) )
		this
