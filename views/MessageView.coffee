FrameView = require('./FrameView.coffee');

module.exports = class MessageView extends FrameView
	template: """
		<div class="header">
			<div class="inner">
				<div><strong>Message#</strong> <span class="opcId"><%= 39277122883 + id  %></span></div>
			</div>
		</div>

		<div class="body">
			<div class="message"></div>
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