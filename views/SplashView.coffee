
View = require( './BaseView.coffee' )
require( '../assets/css/splash.scss')

module.exports = class Splash extends View
	className: 'splash'
	template: """
		<h1>'84<br/><img src="assets/loader.gif" /></h1>
	"""