
View = require( './BaseView.coffee' )
require( '../assets/css/splash.scss')

module.exports = class SplashView extends View
	className: 'splash'
	template: """
		<div class="logo">
			<div class="triangle">&#9651;</div>
			<h1>84</h1>
		</div>
	"""
	number: 1984
	render: =>
		super
		@timer = setTimeout( @tick, 2000 )

	tick: =>
		@$('h1').html( @number.toString().slice( 2 ) )
		@number++
		if  @number > 2014
			@timer = setTimeout( @done, 1000 )
		else
			@timer = setTimeout( @tick, 50 ) 

	done: =>
		@trigger( 'done' )
		clearTimeout( @timer )
		@remove()
