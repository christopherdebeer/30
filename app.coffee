require( './assets/css/style.scss' )
require('cssify').byUrl( '//netdna.bootstrapcdn.com/font-awesome/4.0.3/css/font-awesome.css' )

jQuery = window.$ = $ = require('jquery')
_ = require('underscore')
moment = require('moment')
window.Backbone = Backbone = require('backbone')
Backbone.LocalStorage = require("backbone.localstorage");
Backbone.$ = $


FrameView = require( './views/FrameView.coffee')
MessageView = require( './views/MessageView.coffee')
SplashView = require( './views/SplashView.coffee')
AlertView = require( './views/AlertView.coffee')
MenuView = require( './views/MenuView.coffee')
View = require( './views/BaseView.coffee')

START = 3354234567
SEED_TIME = 1 * 60 * 60 * 24
console.log "SEED_TIME is #{SEED_TIME}"


DATA = [{
			message: ["Official Party Member Communication Device","OPMCD Uplinking...."]
			note: "* Patience is a virtue"
			actionHandler: (user) -> user.updateInventory( 'Party Card', 1)
		},
		{
			message: ["You have agreed to the Terms and Conditions."," Long live The Party."]
			type: 'info'
		},
		{
			message: ["TIME Comrade,", "The Party is delighted to inform you that tomorrow will be the 2014 Ministry of Plenty Annual Party Census."]
			type: 'civil'
			priority: SEED_TIME / 24 / 12 / 60 / 3
		},
		{
			priority: SEED_TIME / 24 / 12 / 60 / 3
			message: ["UPDATE:","The Ministry of Love this week has increased your Ration allowance to 29."]
			type: 'civil' 
			actions: ['Queue For Rations']
		},
		{
			message: ["You have recieved 5 Rations."]
			actionHandler: (user) -> user.updateInventory( 'Rations', 5)
		},
		{
			message: "Unless your life is tightly controlled you will never be free."
			type: 'info'
			priority: SEED_TIME / 24 / 12 / 60 / 3
		},
		{
			message: ["FROM: Charlie S.","Sorry for the intrution, but could you spare 1 Ration? I'd give you a Pack of Victory Cigarettes in exchange."]
			type: 'message' 
			actions: ['Accept', 'Decline']
			priority: SEED_TIME / 24 / 12 / 60 / 1.5
			actionHandler: (user, action) ->
				if action is 'Accept'
					user.updateInventory( 'Rations', user.get('inventory')['Rations'] - 1 )
					user.updateInventory( 'Pack V. Cigarettes', 1)
		},
		{
			message: "Have you seen?" 
			actions: ['Concern for Eurasian civilians','Lack of support for our military','Outright dissent', 'Sarcastic laughter', 'None']
			message2: "Report thought crime! It's your duty."
			showRead: false
		},
		{
			message: "There is no Dissent in Oceania. Those who criticise Big Brother are merely confused."
			type: 'info'
		},
		{
			message: ["FROM: Jane M.","Hi, it was great seeing you the other day.", "See you soon."]
			type: 'message'
		},
		{
			message: "INGSOC: Love it or commit a thoughtcrime."
		},
		{
			message: "2 Aeroplanes hit 2 Towers. 3 Buildings are demolished. because 2+2=5"
		},
		{
			message: "What was your sugar intake in the last week? ________"
		},
		{
			message: "Did you exceed that amount this week? Yes? No? "
			type: 'civil'
		},
		{
			message: "Production is up 600% this year. Everything is only getting better."
			type: 'info'
		},
		{
			message: "Your sugar rations have been increased to 24! Ministrty of Love."
			type: 'civil'
		},
		{
			message: "The Anti Sex League wants you! Sign up:  _____ Show your support and appreciation."
		},
		{
			message: "Census: Enter details."
			type: 'civil'
		},
		{
			message: "Have you seen this party member?"
			type: 'info'
		},
		{message: "We all have a duty to look after our planet! Reduce your carbon footprint."},
		{message: "#—— THIS IS THE 000000000. WE NEED TO FIND 00000000 0000000 CAN YOU HELP?"},
		{message: "Have you seen? Concern for eurasian civilians? Lack of support for our military? outright dissent? sarcastic laughter? Report though crime! Because its your patriotic duty."},
		{message: "The traitors are among us now. Be aware!"},
		{message: "INTERNATIONAL THREAT: The Eurasian faction formerly known as Iran has developed nuclear capabilities that threaten your very livelihood. They have gone to far! "},
		{message: "#—— 00000 00000 00000 000 0000 00000 0000 WILL YOU HELP?	"},
		{message: "The Ministry of Love, this week have increased your sugar rations to 15."},
		{message: [ "TIME Comrade,", "The Party knows all, find consolation in that."], type: 'info' },
		{message: [ "TIME Comrade,", "Patience..." ]}
]


class UserModel extends Backbone.Model
	defaults:
		firstName: ''
		lastName: ''
		start: +moment().startOf( 'day' )
		turns: 0
		inventory: {}
	url: '/user'
	localStorage: new Backbone.LocalStorage("user-store")

	getCurrentOPC: (collection) =>
		turns = @get('turns')
		today = moment()
		limit = Math.min( turns, collection.length - 1 )
		opc = collection.at( limit )
		seen = opc.get( 'seen' )
		read = opc.get( 'read' )
		console.log "opc[#{ limit }] read: #{ !!read } seen: #{ !!seen } turns: #{ turns }"
		console.log "now: ", today.toDate()
		if read
			whenSeen = moment( seen )
			console.log "seen: ", whenSeen.toDate()
			if @isNextTurn( collection.at(limit + 1) , whenSeen )
				@set( 'turns', turns + 1 )
				@save()
				limit = Math.min( @get('turns'), collection.length - 1 )
				opc = collection.at( limit ) 
			console.log "show opc[#{limit}] "
		opc

	getTurnDuration: (nextOPC, whenReadLastOPC) =>
		now = moment()
		fraction = now.diff( whenReadLastOPC, 'miliseconds' ) / SEED_TIME
		priority = nextOPC.get( 'priority' ) / SEED_TIME * 1000
		percent = fraction * 100 / priority / ( 2 )
		# console.log "Percent of turn #{percent}% so far."
		percent

	isNextTurn: (opc, whenRead) =>
		@getTurnDuration(opc, whenRead) >= 100

	updateInventory: (key, value) ->
		inventory = @get('inventory')
		inventory[key] = value
		@set('inventory', inventory)
		@save()

class OPCModel extends Backbone.Model
	defaults:
		message: ['default message']
		read: false
		readTime: undefined
		seen: false
		seenTime: undefined
		priority: SEED_TIME / 24 / 12 / 60
		type: 'general'
		note: false
		actions: ['OK']
		message2: false
		showRead: true
	url: '/opc'
	localStorage: new Backbone.LocalStorage("opc-store")
	initialize: ({actionHandler}) ->
		@actionHandler = actionHandler if actionHandler
	actionHandler: (user) -> console.log( 'Action handler fired', user )

class OPCCollection extends Backbone.Collection
	localStorage: new Backbone.LocalStorage("opc-store")
	model: OPCModel

class MainController extends Backbone.Router
	routes:
		'': 'init'

	init: =>
		@app = $el: $('body')
		console.log "Init..."
		@findOrCreateUser =>
			console.log "All is good."
			console.log
			window.opcs = opcs = new OPCCollection()
			p = opcs.fetch()
			
			cont = =>
				console.log opcs
				for item, i in DATA
					item.id = i
					opc = new OPCModel( item )
					unless opcs.contains( opc )
						# console.log('adding/updating OPC:', opc)
						opcs.add( opc ).save() 
					else
						console.log('not adding existing opc:', opc)
				splash = new SplashView( model: @user )
				splash.render()
				@app.$el.append splash.el
				menu = new MenuView( model: @user )
				menu.render()
				@app.$el.append menu.el
				splash.on 'done', =>
					@showFrame()
			p.done( cont )
			p.fail =>
				console.log "OPCS fetch failed...."
				cont()			
			
	showFrame: =>
		opc = @user.getCurrentOPC( opcs )
		console.log "Show frame...", opc.get('id')
		frame = switch opc.get( 'type' )
			when 'message'
				new MessageView( model: opc, user: @user )
			else 
				new FrameView( model: opc, user: @user )
		frame.on( 'next', @newFrame )
		frame.render()
		@app.$el.append frame.el

	newFrame: (frame) =>
		frame.remove()
		@showFrame()

	findOrCreateUser: (cb) =>
		console.log "Find or create User..."
		@user = new UserModel( id: 1 )
		init = @user.fetch()
		init.done => cb()
		init.fail =>
			console.log "User not found. Creating..."
			@user.save()
			cb()

$ ->
	console.log "On Document Ready..."
	main = new MainController()
	Backbone.history.start()


