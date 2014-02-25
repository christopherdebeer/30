require( './assets/css/style.scss' )
require('cssify').byUrl( '//netdna.bootstrapcdn.com/font-awesome/4.0.3/css/font-awesome.css' )

jQuery = window.$ = $ = require('jquery')
_ = require('underscore')
moment = require('moment')
window.Backbone = Backbone = require('backbone')
Backbone.LocalStorage = require("backbone.localstorage");
Backbone.$ = $


window.app = app =
	models: {}
	views: {}
	controllers: {}
	collections: {}


FrameView = require( './views/FrameView.coffee')
SplashView = require( './views/SplashView.coffee')
AlertView = require( './views/AlertView.coffee')
View = require( './views/BaseView.coffee')

startId = 3354234567
seedTime = 1000 * 60 # * 60 * 24
DATA = [{
		id: startId + 1
		message: [ 
			"Official Party Member Correspondence Device",
			"OPMCD Uplinking...."]
		priority: 0.01
		},{
		id: startId + 2
		message: [ 
			"TIME Comrade,", 
			"The Party is delighted to inform you that tomorrow will be the 2014 Ministry of Plenty Annual Party Census."]
		priority: 1
		},{
		id: startId + 3
		message: [ 
			"TIME Comrade,", 
			"The Party knows all, find consolation in that."]
		priority: 6
		},{
		id: startId + 4
		message: [ 
			"TIME Comrade,", 
			"Patience..."
		]
		priority: 6
}]


class app.models.User extends Backbone.Model
	defaults:
		firstName: ''
		lastName: ''
		start: +moment().startOf( 'day' )
		turns: 0
	url: '/user'
	localStorage: new Backbone.LocalStorage("user-store")

	getCurrentOPC: (collection) =>
		turns = @get('turns')
		today = moment().startOf( 'day' )
		limit = Math.min( turns, collection.length - 1 )
		opc = collection.at( limit )
		read = opc.get( 'read' )
		console.log "opc[#{ limit }] read: #{ !!read } turns: #{ turns }"
		console.log "now: ", today.toDate()
		if read
			whenRead = moment( read ).startOf( 'day' )
			console.log "read: ", whenRead.toDate()
			if @getNextTurn( collection.at(limit + 1) , today, whenRead )
				@set( 'turns', turns + 1 )
				@save()
				limit = Math.min( @get('turns'), collection.length - 1 )
				opc = collection.at( limit ) 
			console.log "show opc[#{limit}] "
		opc

	getNextTurn: (opc, today, whenRead) =>
		hours = today.diff( whenRead, 'hours' )
		sinceLastTurn = @get( 'priority' ) * hours / 6
		console.log "hours since last turn #{sinceLastTurn}"
		sinceLastTurn >= 1

class app.collections.OPCCollection extends Backbone.Collection
	model: (attributes, options) ->
		new app.models.OPC( attributes, options )
	localStorage: new Backbone.LocalStorage("opc-store")

class app.models.OPC extends Backbone.Model
	defaults:
		message: ['default message']
		id: 0
		read: false
		priority: 3

	url: '/opc'
	localStorage: new Backbone.LocalStorage("opc-store")

class app.controllers.Main extends Backbone.Router
	routes:
		'': 'init'

	init: ->
		app.$el = $('body')
		console.log "Init..."
		@findOrCreateUser (user) =>
			console.log "All is good."
			app.user = @user =user
			splash = new SplashView( model: @user )
			splash.render()
			app.$el.append splash.el
			menu = new Menu( model: @user )
			menu.render()
			app.$el.append menu.el
			setTimeout( =>
				splash.remove()
				@showFrame()
			, 1000 * 2 )

	showFrame: =>	
		window.opcs = opcs = new app.collections.OPCCollection()
		p = opcs.fetch()
		cont = =>
			for item in DATA
				opc = new app.models.OPC( item )
				opcs.add( opc ).save() unless opcs.contains( opc )
			opc = @user.getCurrentOPC( opcs )
			console.log opc
			frame = new FrameView( model: opc )
			frame.on( 'alerts', (x) -> app.controllers.alerts.show(x) )
			frame.render()
			app.$el.append frame.el
		p.done( cont )
		p.fail( cont )

	findOrCreateUser: (cb) ->
		console.log "Find or create User..."
		user = new app.models.User( id: 1 )
		init = user.fetch()
		init.done -> cb( user )
		init.fail ->
			console.log "User not found. Creating..."
			user.save()
			cb( user )

class Menu extends View
	className: 'menu'
	template: """
		<ul>
			<li class="disabled">ID: 42342678</li>
			<li class="disabled">Work</li>
			<li class="start-over">Start Over</li>
		</ul>
	"""
	events:
		'click .start-over': 'handleClickStartOver'

	handleClickStartOver: ->
		if confirm( 'The Party comends your desire to start over. Are you sure?' )
			localStorage.clear()
			document.location = document.location

class app.controllers.Alerts
	show: (objects) ->
		msgs = ($(o).text() for o in objects)
		model = new Backbone.Model( messages: msgs )
		alert = new AlertView( model: model )
		$('body').append( alert.render().$el ) 
$ ->
	app.controllers.alerts = new app.controllers.Alerts()
	app.controllers.main = new app.controllers.Main()
	Backbone.history.start()


