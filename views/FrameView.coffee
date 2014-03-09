View = require( './BaseView.coffee' )
moment = require( 'moment' )
_ = require( 'underscore' )

require( '../assets/css/frame.scss' )

module.exports = class FrameView extends View
	className: "frame"
	template: """
	<div class="header">
		<div class="inner">
			<div class="icons">
				<i class="fa fa-eye"></i>
				<i class="fa fa-bolt"></i>
				<i class="fa fa-triangle">&#9650;</i>
			</div>
			<div><strong>OPC#</strong> <span class="opcId"><%= 39277122883 + id  %></span></div>
			<div class="hdiv"></div>
			<div class="second-row"><strong>D</strong> <span class="time"></span></div>
		</div>
		<div class="timer"></div>
	</div>

	<div class="body">
		<img class="barcode" src="assets/barcode.png" />
		<div class="message"></div>
		<% if (showRead) { %>
			<div class="read"><input disabled <%= read ? 'checked' : '' %> type="checkbox"> Reciept noted</div>
		<% } %>
		<div class="actions">
			<% for (var a=0; a<actions.length; a++) { %>
				<div class="button"><%= actions[a] %><div class="timer"></div></div>
			<% } %>
		</div>
		<% if (message2) { %>
			<div class="message2"><%= message2 %></div>
		<% } %>
		<% if (note) { %>
			<div class="footnotes">
				<div class="note"><%= note %></div>
			</div>
		<% } %>
	</div>
	<div class="footer">
		<div class="menu-button"><i class="fa fa-bars"></i></div>
	</div>
	"""
	initialize: ({@user}) ->
		console.log "frame init with user: ", @user
		#console.log "and model: ", @model

	events:
		'click .footer .menu-button': 'toggleSlide'
		'click .actions .button': 'handleClickAction'
	
	render: =>
		super
		@$el.addClass( @model.get( 'type') )
		@getTime()
		@outputMessage()
		@updateTime()
		this
	
	getTime: =>
		 time = new Date().toString().split('GMT')[0]
		 @$( '.time' ).html( time )
		 setTimeout( @getTime, 100 * 1 )

	handleClickAction: =>
		@model.set( 'seenTime', +moment() ) unless @model.get('seenTime')
		@model.save() 
	tick: 1
	outputMessage: =>
		message = if typeof @model.get('message') == 'string'
			[@model.get('message').replace( 'TIME', @timeOfDay() ) ]
		else
			@model.get('message').map( (m) => m.replace( 'TIME', @timeOfDay() ) )
		
		@model.set( 'message', message )
		total = message.join().length
		breaks = _.reduce( message, ((memo, item) ->
			memo.push(item.length + memo[memo.length - 1])
			memo ), [0])
		#remove first
		breaks = breaks.slice( 1 )
		#remove last
		breaks = breaks.slice( 0, -1 )
		if @model.get( 'seen' )
			@$('.message').html( message.join('<br/><br/>') )
			@doneRendering()
		else	
			text = message.join('').slice( 0, @tick).split('')
			for b in breaks
				text.splice( b, 0, "<br/><br/>") unless text.length == 1
			text = text.join('')
			@$('.message').html( text )
			@tick++
			if @tick <= total
				setTimeout( @outputMessage, 1000 * 0.075 )
			else
				@doneRendering()

	doneRendering: =>
		unless @model.get( 'seen' )
			@model.set( 'seen', +moment() )
			console.log "set seen: #{moment()}"
			@model.save()
		
		@$el.addClass( 'seen' )
		@$('.read input').attr('checked', true)
		

	updateTime: =>
		lastSeen = @model.get( 'seen' )
		currentIndex = @model.collection.indexOf( @model )
		nextOPC = @model.collection.at( currentIndex + 1)
		if lastSeen and @model.get('read')
			leftPercent = @user.getTurnDuration( nextOPC, moment( @model.get('readTime') ) ) 
		else
			leftPercent = 0
		percent = if leftPercent > 100 then 100 else leftPercent
		@$('.actions .timer').css( 'width', "#{ 100 - percent }%" )
		@$el.addClass( 'read' )

		if @model.get('read')
			# console.log "Time elapsed #{ percent }% "
			if percent >= 100
				@trigger( 'next', this )
			else
				setTimeout( @updateTime, 10 * 1 )
		else
			@attachActionHandlers()
			setTimeout( @updateTime, 10 * 1 )

	attachActionHandlers: =>
		unless @attached
			@attached = true
			console.log( 'Attaching action handlers' )
			@$( '.actions .button').click (ev) =>
				@$el.addClass('waiting')
				@$(ev.target).addClass('active')
				console.log( 'click action handler' )
				@model.actionHandler( @user )
				unless @model.get('read')
					@model.set( 'read', +moment() )
					@model.set( 'readTime', +moment() )
					console.log "set read: #{moment()}"
					@model.save()
				else
					console.log( 'already read...' )

	timeOfDay: =>
		read = moment( @model.get( 'seen' ) )
		now = moment()
		if @model.get( 'seen' )
			hours = read.hours()
		else 
			hours = now.hours()
		if hours <= 12 then "Morning"
		else if 12 < hours < 18 then "Afternoon"
		else if hours >= 18 then "Evening"
	
	toggleSlide: (ev) =>
		ev.preventDefault()
		if @$el.hasClass( 'slide' )
			@$el.removeClass('slide').css
				transition: 'margin 0.5s'
				marginLeft: '0px'
				marginRight: '0px'
		else
			@$el.addClass('slide').css
				transition: 'margin 0.5s'
				marginLeft: '150px'
				marginRight: '-150px'
		false
