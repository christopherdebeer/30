View = require( './BaseView.coffee' )
moment = require( 'moment' )
_ = require( 'underscore' )

require( '../assets/css/frame.scss' )

module.exports = class FrameView extends View
	className: 'frame'
	template: """
	<div class="header">
		<div class="inner">
			<div class="icons">
				<i class="fa fa-eye"></i>
				<i class="fa fa-bolt"></i>
				<i class="fa fa-triangle">&#9650;</i>
			</div>
			<div><strong>OPC#</strong> <span class="opcId"><%= id %></span></div>
			<div class="hdiv"></div>
			<div><strong>D</strong> <span class="time"></span></div>
		</div>
		<div class="timer" data-percent="100"></div>
	</div>

	<div class="body">
		<img class="barcode" src="assets/barcode.png" />
		<div class="message"></div>
		<div class="read"><input disabled <%= read ? 'checked' : '' %> type="checkbox"> Reciept noted</div>
	</div>
	<div class="footer">
		<h4><i class="fa fa-bars"></i> <span class="notices">Public Notices <strong>2</strong></span></h4>
		<div class="inner">
			<p>The Party does not negotiate with terrorists.</p>
			<p>We continue to fight for what you believe.</p>
		</div>
	</div>
	"""
	initialize: ({@user}) ->
		console.log "frame init with user: ", @user

	events:
		'click .footer .notices': 'handleClickFooter'
		'click .footer i': 'toggleSlide'
	
	render: =>
		super
		@outputMessage()
		@updateTime()
		this
	
	getTime: ->
		 new Date().toString().split('GMT')[0]

	tick: 1
	outputMessage: =>
		message = @model.get('message').map( (m) => m.replace( 'TIME', @timeOfDay() ) )
		@model.set( 'message', message )
		total = message.join().length
		breaks = _.reduce( message, ((memo, item) ->
			memo.push(item.length + memo[memo.length - 1])
			memo ), [0])
		#remove first
		breaks = breaks.slice( 1 )
		#remove last
		breaks = breaks.slice( 0, -1 )
		if @model.get( 'read' )
			@$('.message').html( message.join('<br/><br/>') )
		else	
			text = message.join('').slice( 0, @tick).split('')
			for b in breaks
				text.splice( b, 0, "<br/><br/>") unless text.length == 1
			text = text.join('')
			@$('.message').html( text )
			@tick++
			if @tick < total
				setTimeout( @outputMessage, 1000 * 0.075 )
			else
				@model.set( 'read', +moment() )
				@model.save()
				@$('.read input').attr('checked', true)

	updateTime: =>
		lastRead = @model.get( 'read' )
		currentWidth = parseInt( @$('.timer').css( 'width').replace('px', '') )
		if lastRead
			currentIndex = @model.collection.indexOf( @model )
			nextOPC = @model.collection.at( currentIndex + 1)
			leftPercent = @user.getTurnDuration( nextOPC, moment( lastRead ) ) 
			leftPercent = 100 if leftPercent > 100
			@$('.timer').css( 'width', "#{ leftPercent }%" )
			if leftPercent >= 100
				@trigger( 'next', this )
			else
				setTimeout( @updateTime, 1000 * 1 )
		else
			setTimeout( @updateTime, 1000 * 1 )
		@$( '.time' ).html( @getTime() )

	timeOfDay: =>
		read = moment( @model.get( 'read' ) )
		now = moment()
		if read
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

	handleClickFooter: (ev) =>
		ev.preventDefault()
		@trigger( 'alerts', @$('.footer .inner p') )
		false
