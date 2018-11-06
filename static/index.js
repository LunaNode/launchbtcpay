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
			var autohostname = 'btcpay' + (100000 + Math.floor(Math.random() * 899999)) + '.lndyn.com';
			$('#step2_autohostname').text(autohostname);
			showStep('step2');
		}, 'json');
	});

	$('#step2_form').submit(function(e) {
		e.preventDefault();
		if($('.hostname_type:checked').data('type') === 'autohostname') {
			hostname = $('#step2_autohostname').text();
		} else {
			hostname = $('#hostname').val();
		}
		hostname = hostname.trim();
		if(hostname.length == 0) {
			showError('Hostname cannot be empty!');
			return;
		} else if(hostname.indexOf('http://') !== -1 || hostname.indexOf('https://') !== -1) {
			showError('Please enter just the hostname (e.g. "example.com", without http:// or URL path).');
			return;
		} else if(hostname.indexOf(':') !== -1) {
			showError('Please enter just the hostname (e.g., "example.com" or "btcpay.example.com").')
			return;
		} else if(/^[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$/.test(hostname)) {
			showError('Please enter a hostname like "example.com" or "btcpay.example.com", not an IP address.');
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
			'accelerate': $('#accelerate').prop('checked') ? 'yes' : 'no',
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
		if($('.hostname_type:checked').data('type') === 'autohostname') {
			$('#hostname').prop('disabled', true);
		} else {
			$('#hostname').prop('disabled', false);
		}
	});
});
