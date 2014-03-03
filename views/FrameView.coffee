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
		<div class="read"><input disabled <%= read ? 'checked' : '' %> type="checkbox"> Reciept noted</div>
		<div class="actions">
			<div class="button">OK</div>
		</div>
		<% if (note) { %>
			<div class="footnotes">
				<div class="note"><%= note %></div>
			</div>
		<% } else { %>
			<img src="" alt="">
		<% } %>
	</div>
	<div class="footer">
		<div class="menu-button"><i class="fa fa-bars"></i></div>
	</div>
	"""
	initialize: ({@user}) ->
		console.log "frame init with user: ", @user

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
	
	getTime: ->
		 time = new Date().toString().split('GMT')[0]
		 @$( '.time' ).html( time )
		 setTimeout( @getTime, 1000 * 1 )

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
		if lastSeen
			leftPercent = @user.getTurnDuration( nextOPC, moment( lastSeen ) ) 
		else
			leftPercent = 5
		percent = if leftPercent > 100 then 100 else leftPercent
		@$('.timer').css( 'width', "#{ percent }%" )
		if leftPercent >= 100
			console.log "Time elapsed", percent, leftPercent
			@$el.addClass( 'read' )
			@$( '.actions .button').click =>
				@model.set( 'read', +moment() )
				console.log "set read: #{moment()}"
				@model.save()
				@trigger( 'next', this )
		else
			console.log "time %:", percent
			setTimeout( @updateTime, 1000 * 1 )


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
