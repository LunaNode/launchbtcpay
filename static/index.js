$(document).ready(function() {
	var apiID = null;
	var apiKey = null;
	var ip = null;
	var hostname = null;

	function showError(msg) {
		$('#errorbar').text(msg);
		$('#errorbar').css('display', '');
	}

	function showStep(id) {
		$('#errorbar').css('display', 'none');
		$('.stepdiv').css('display', 'none');
		$('#' + id).css('display', '');

		if(id === 'step3') {
			updatePrice();
		}
	}

	$('#step1_form').submit(function(e) {
		e.preventDefault();
		apiID = $('#api_id').val();
		apiKey = $('#api_key').val();
		$('#api_id').val('');
		$('#api_key').val('');

		if(apiID.length < 5 || apiKey.length < 5) {
			showError('Invalid API ID or API key.');
			return;
		}

		showStep('loading');
		var params = {
			'api_id': apiID,
			'api_key': apiKey,
		};
		$.post('/getip', params, function(data) {
			if(data.error) {
				showStep('step1');
				showError('Error: ' + data.error + '.');
				return;
			}

			ip = data.ip;
			$('#step2_ip').text(data.ip);
			showStep('step2');
		}, 'json');
	});

	$('#step2_form').submit(function(e) {
		e.preventDefault();
		hostname = $('#hostname').val();
		if(hostname.length == 0) {
			showError('Hostname cannot be empty!');
			return;
		}

		showStep('step3');
	});

	$('#step3_form').submit(function(e) {
		e.preventDefault();

		showStep('loading2');
		var coins = [];
		$('.supportedcoins:checked').each(function() {
			coins.push($(this).data('coin'));
		});
		coins = coins.join(',');

		var params = {
			'api_id': apiID,
			'api_key': apiKey,
			'ip': ip,
			'hostname': hostname,
			'sshkey': $('#sshkey').val(),
			'email': $('#email').val(),
			'network': $('#network').val(),
			'coins': coins,
			'lightning': $('#lightning').val(),
			'alias': $('#alias').val(),
			'repository': $('#repository').val(),
			'branch': $('#branch').val(),
			'plan': $('#plan').val(),
		};
		$.post('/launch', params, function(data) {
			if(data.error) {
				showStep('step3');
				showError('Error: ' + data.error + '.');
				return;
			}

			$('#step4_hostname').attr('href', 'https://' + hostname);
			$('#step4_hostname').text(hostname);
			showStep('step4');
		}, 'json');
	});

	function updatePrice() {
		var planOption = $('#plan').find(":selected");
		var price = parseFloat(planOption.data('price'));
		var storage = 60 * $('.supportedcoins:checked').length;
		price += 0.03 * storage;
		$('#price').val('$' + price);
	}

	$('#plan').on('change', function(e) {
		updatePrice();
	});

	$('.supportedcoins').on('change', function(e) {
		updatePrice();
	});
});
