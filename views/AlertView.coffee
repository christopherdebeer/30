View = require( './BaseView.coffee' )
require( '../assets/css/alert.scss')

module.exports = class AlertView extends View
	className: 'alert'
	template: """
		<div class="inner">
		<% _(messages).each( function(msg) { %>
			<p><%= msg %></p>
		<% }); %>
		</div>
	"""
	events:
		'click': 'handleClick'

	handleClick: =>
		@remove()