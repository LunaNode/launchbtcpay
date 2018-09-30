$(document).ready(function() {
	var apiID = null;
	var apiKey = null;
	var ip = null;
	var hostname = null;

	function showError(msg) {
		if(msg) {
			$('#errorbar').text(msg);
			$('#errorbar').css('display', '');
		} else {
			$('#errorbar').css('display', 'none');
		}
	}

	function showStep(id) {
		showError();
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
			$('#step2_ip').text(ip);
			var ipParts = ip.split('.');
			var rdns = ipParts.reverse().join('.') + '.rdns.lunanode.com';
			$('#step2_rdns').text(rdns);
			showStep('step2');
		}, 'json');
	});

	$('#step2_form').submit(function(e) {
		e.preventDefault();
		if($('.hostname_type:checked').data('type') === 'rdns') {
			hostname = $('#step2_rdns').text();
		} else {
			hostname = $('#hostname').val();
		}
		if(hostname.length == 0) {
			showError('Hostname cannot be empty!');
			return;
		}

		showStep('step3');
	});

	function getCheckedCoins() {
		var coins = [];
		$('.supportedcoins:checked').each(function() {
			coins.push($(this).data('coin'));
		});
		return coins;
	}

	$('#step3_form').submit(function(e) {
		e.preventDefault();

		showStep('loading2');
		var coins = getCheckedCoins().join(',');

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
		$('#price').val('$' + price.toFixed(2));
	}

	function validateStep3() {
		// LND can only be used with BTC and LTC
		var unsupportedCoins = getCheckedCoins().filter(function(el) {
			return el != 'btc' && el != 'ltc';
		});
		var lndEnabled = $('#lightning').val() === 'lnd';
		if(unsupportedCoins.length > 0 && lndEnabled) {
			showError('LND can only be used with BTC and LTC');
			return false;
		}

		showError();
		return true;
	}

	$('#plan').on('change', function(e) {
		updatePrice();
	});

	$('.supportedcoins').on('change', function(e) {
		updatePrice();
		validateStep3();
	});

	$('#lightning').on('change', function(e) {
		validateStep3();
	});

	$('.hostname_type').on('change', function(e) {
		if($('.hostname_type:checked').data('type') === 'rdns') {
			$('#hostname').prop('disabled', true);
		} else {
			$('#hostname').prop('disabled', false);
		}
	});
});
