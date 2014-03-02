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
MenuView = require( './views/MenuView.coffee')
View = require( './views/BaseView.coffee')

startId = 3354234567
SEED_TIME = 1 * 60 * 60 * 24
console.log "SEED_TIME is #{SEED_TIME}"


DATA = [{
		id: startId + 1
		message: [ 
			"Official Party Member Correspondence Device",
			"OPMCD Uplinking...."]
		},{
		id: startId + 2
		message: [ 
			"TIME Comrade,", 
			"The Party is delighted to inform you that tomorrow will be the 2014 Ministry of Plenty Annual Party Census."]
		type: 'civil'
		},
		{message: "You have agreed to the Terms and Conditions. Hurray for The Party.", type: 'info'},
		{message: "The ministry of Love this week has increased your sugar rations to 29.", type: 'civil'},
		{message: "Have you seen? Concern for eurasian civilians? Lack of support for our military? outright dissent? sarcastic laughter? Report though crime! Because its your patriotic duty."},
		{message: "There is no Dissent in Oceania. Those who criticise Big Brother are merely confused.", type: 'info'},
		{message: "Unless your life is tightly controlled you will never be free.", type: 'info'},
		{message: "INGSOC: Love it or commit a thoughtcrime."},
		{message: "2 Aeroplanes hit 2 Towers. 3 Buildings are demolished. because 2+2=5"},
		{message: "What was your sugar intake in the last week? ________"},
		{message: "Did you exceed that amount this week? Yes? No? ", type: 'civil'},
		{message: "Production is up 600% this year. Everything is only getting better.", type: 'info'},
		{message: "Your sugar rations have been increased to 24! Ministrty of Love.", type: 'civil'},
		{message: "The Anti Sex League wants you! Sign up:  _____ Show your support and appreciation."},
		{message: "Census: Enter details.", type: 'civil'},
		{message: "Have you seen this party member?", type: 'info'},
		{message: "We all have a duty to look after our planet! Reduce your carbon footprint."},
		{message: "#—— THIS IS THE 000000000. WE NEED TO FIND 00000000 0000000 CAN YOU HELP?"},
		{message: "Have you seen? Concern for eurasian civilians? Lack of support for our military? outright dissent? sarcastic laughter? Report though crime! Because its your patriotic duty."},
		{message: "The traitors are among us now. Be aware!"},
		{message: "INTERNATIONAL THREAT: The Eurasian faction formerly known as Iran has developed nuclear capabilities that threaten your very livelihood. They have gone to far! "},
		{message: "#—— 00000 00000 00000 000 0000 00000 0000 WILL YOU HELP?	"},
		{message: "The Ministry of Love, this week have increased your sugar rations to 15."},
		{
		message: [ 
			"TIME Comrade,", 
			"The Party knows all, find consolation in that."]
		}
		type: 'info',{
		message: [ 
			"TIME Comrade,", 
			"Patience..."
		]}
]


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
		today = moment()
		limit = Math.min( turns, collection.length - 1 )
		opc = collection.at( limit )
		read = opc.get( 'read' )
		console.log "opc[#{ limit }] read: #{ !!read } turns: #{ turns }"
		console.log "now: ", today.toDate()
		if read
			whenRead = moment( read )
			console.log "read: ", whenRead.toDate()
			if @isNextTurn( collection.at(limit + 1) , whenRead )
				@set( 'turns', turns + 1 )
				@save()
				limit = Math.min( @get('turns'), collection.length - 1 )
				opc = collection.at( limit ) 
			console.log "show opc[#{limit}] "
		opc

	getTurnDuration: (nextOPC, whenReadLastOPC) =>
		now = moment()
		fraction = now.diff( whenReadLastOPC, 'seconds' ) / SEED_TIME
		priority = nextOPC.get( 'priority' ) / SEED_TIME
		percent = fraction * 100 / priority / ( 2 )
		# console.log "Percent of turn #{percent}% so far."
		percent

	isNextTurn: (opc, whenRead) =>
		@getTurnDuration(opc, whenRead) >= 100

class app.collections.OPCCollection extends Backbone.Collection
	localStorage: new Backbone.LocalStorage("opc-store")

class app.models.OPC extends Backbone.Model
	defaults:
		message: ['default message']
		read: false
		priority: SEED_TIME / 24 / 12 / 60
		className: 'default' 
	url: '/opc'
	localStorage: new Backbone.LocalStorage("opc-store")
	

class app.models.GeneralOPC extends app.models.OPC
	constructor: ->
		super
		@set( 'className', 'general' )

class app.models.CivilOPC extends app.models.OPC
	constructor: ->
		super
		@set( 'className', 'civil' )

class app.models.InformationalOPC extends app.models.OPC
	constructor: ->
		super
		@set( 'className', 'info' )

class app.controllers.Main extends Backbone.Router
	routes:
		'': 'init'

	init: ->
		app.$el = $('body')
		console.log "Init..."
		@findOrCreateUser (user) =>
			console.log "All is good."
			window.opcs = opcs = new app.collections.OPCCollection()
			p = opcs.fetch()
			for item in DATA
				opc = switch item.type
					when 'info' then new app.models.InformationalOPC( item )
					when 'civil' then new app.models.CivilOPC( item )
					else new app.models.GeneralOPC( item )
				opcs.add( opc ).save() unless opcs.contains( opc )

			app.user = @user = user
			splash = new SplashView( model: @user )
			splash.render()
			app.$el.append splash.el
			menu = new MenuView( model: @user )
			menu.render()
			app.$el.append menu.el
			cont = =>
				splash.on 'done', =>
					@showFrame()
			p.done( cont )
			p.fail( cont )			
			
	showFrame: =>
		opc = @user.getCurrentOPC( opcs )
		console.log opc
		frame = new FrameView( model: opc, user: @user )
		frame.on( 'next', @newFrame )
		frame.render()
		app.$el.append frame.el

	newFrame: (frame) =>
		frame.remove()
		@showFrame()

	findOrCreateUser: (cb) ->
		console.log "Find or create User..."
		user = new app.models.User( id: 1 )
		init = user.fetch()
		init.done -> cb( user )
		init.fail ->
			console.log "User not found. Creating..."
			user.save()
			cb( user )



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


