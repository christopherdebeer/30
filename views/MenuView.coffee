View = require( './BaseView.coffee' )

module.exports = class MenuView extends View
	className: 'menu'
	template: """
		<ul>
			<li class="disabled">ID: 42342678</li>
			<li class="current">Notifications</li>
			<li class="disabled">Inventory</li>
			<li class="start-over">Start Over</li>
		</ul>
	"""
	events:
		'click .start-over': 'handleClickStartOver'

	handleClickStartOver: ->
		if confirm( 'The Party comends your desire to start over. Are you sure?' )
			localStorage.clear()
			document.location = document.location