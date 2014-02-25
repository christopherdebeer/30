View = require( './BaseView.coffee' )
moment = require( 'moment' )
_ = require( 'underscore' )

require( '../assets/css/frame.scss' )

module.exports = class Frame extends View
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

	events:
		'click .footer': 'handleClickFooter'
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
		now = moment()
		hours = 24 - now.hours()
		minutes = 60 - now.minutes()
		left =  hours - ( 1 / 60 / minutes )
		leftPercent = 100 - (left * 100 / 24)
		@$('.timer').css( 'width', "#{ leftPercent }%" )
		@$( '.time' ).html( @getTime() )
		setTimeout( @updateTime, 1000 * 1 )

	timeOfDay: =>
		read = moment( @model.get( 'read' ) )
		now = moment()
		if read
			hours = read.hours()
		else 
			hours = now.getHours()
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

	handleClickFooter: (ev) =>
		ev.preventDefault()
		@trigger( 'alerts', @$('.footer .inner p') )
