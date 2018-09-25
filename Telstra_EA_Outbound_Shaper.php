<?php
	$interfaces = array('ether1');
	$overhead_percent = '98';
	$max_limit = '50';
	$bucket_size = '0.004';
	$bucket_size_mesc = $bucket_size * 1000;
	$queue_time_msec = '5';
	$queue_method = 'bfifo';
	$queue_speeds = array('6','10','20','50','100','200');

	$top_prioirty_name = array(
		'1' => 'Network Control',
		'2' => 'Routing',
		'3' => 'Critical',
		'4' => 'Flash Override',
		'5' => 'Flash',
		'6' => 'Immediate',
		'7' => 'Priority',
		'8' => 'Best Effort'
	);
	$top_priority_limit_at_bandwidth_percent = array(
		'1' => '6',
		'2' => '6',
		'3' => '30',
		'4' => '30',
		'5' => '10',
		'6' => '10',
		'7' => '4',
		'8' => '2',
	);

	$dscp_name = array(
		'0' => 'CS0',
		'56' => 'CS7',
		'48' => 'CS6',
		'46' => 'CS5 Expedited Forwarding (VoIP)',
		'40' => 'CS5',
		'38' => 'CS4 AF43 (High)',
		'36' => 'CS4 AF42 (Medium)',
		'34' => 'CS4 AF41 (Low)',
		'32' => 'CS4',
		'30' => 'CS3 AF33 (High)',
		'28' => 'CS3 AF32 (Medium)',
		'26' => 'CS3 AF31 (Low)',
		'24' => 'CS3',
		'22' => 'CS2 AF23 (High)',
		'20' => 'CS2 AF22 (Medium)',
		'18' => 'CS2 AF21 (Low)',
		'16' => 'CS2',
		'14' => 'CS1 AF13 (High)',
		'12' => 'CS1 AF12 (Medium)',
		'10' => 'CS1 AF11 (Low)',
		'8' => 'CS1'
	);

	foreach ($queue_speeds as $speed){
		$queue_limit = $speed * 1000000 * ( $overhead_percent / 100 ) * $bucket_size / $bucket_size_mesc * $queue_time_msec;
		$queue_kind = $queue_method;
		$queue_name =  $speed . 'M';
	
		$output = '/queue type add' . ' ' .
			'kind=' . $queue_method . ' ' .
			'name=' . $speed . 'M' . ' ' .
			$queue_method . '-limit=' . $queue_limit;
		echo "$output\n";
	}


	foreach($interfaces as $interface){
		foreach($top_prioirty_name as $top_id=>$top_name){
			$dscp_full[$interface]['Top Priority'][$top_id]['Name'] = $top_name;
			$dscp_full[$interface]['Top Priority'][$top_id]['Limit At %'] = $top_priority_limit_at_bandwidth_percent[$top_id];
			$dscp_full[$interface]['Top Priority'][$top_id]['Sub Priority'] = array();
		}
	
		foreach ($dscp_name as $dscp=>$values){
			$output = '/ip firewall mangle' . ' ' . 
					'add action=mark-packet' . ' ' .
					'chain=postrouting' . ' ' .
					'comment=dscp_' . $dscp . ' ' .
					'dscp=' . $dscp . ' ' .
					'new-packet-mark=dscp_' . $dscp . ' ' .
					'passthrough=no';
			echo "$output\n";
			$top_prioirty_decimal = ceil(8 - $dscp / 8);
			$padded_hex = str_pad(decbin($dscp),8,'0',STR_PAD_LEFT);
			$sub_prioirty_binary = substr($padded_hex, -3);
			$sub_prioirty_deicmal = 8 - bindec($sub_prioirty_binary);
			$dscp_full[$interface]['Top Priority'][$top_prioirty_decimal]['Sub Priority'][$sub_prioirty_deicmal]['name'] = $dscp_name[$dscp];
			$dscp_full[$interface]['Top Priority'][$top_prioirty_decimal]['Sub Priority'][$sub_prioirty_deicmal]['dscp'] = $dscp;
		}
		
	}
	foreach ($dscp_full as $interface=>$queues){

		$queue_max_limit =  $max_limit * 1000000 * ($overhead_percent/100);
		$queue_type = $max_limit .'M';

		$output =  '/queue tree add' . ' ' .
				'bucket-size=' . $bucket_size . ' ' .
				'max-limit='. $queue_max_limit . ' ' . 
				'name=' . $interface .'-out' . ' ' .
				'parent=' . $interface . ' ' . 
				'queue='. $queue_type;
		echo "$output\n";

		foreach($queues['Top Priority'] as $top_id=>$top_queue){

			$queue_top_limit_at = $max_limit * 1000000 * ($top_queue['Limit At %']/100);
			$queue_top_name = '"' . $interface . '-' . $top_id . '-' . $top_queue['Name'] . '"';
			$queue_top_parent = $interface . '-out priority=' . $top_id;

			$output = '/queue tree add' . ' ' . 
					'bucket-size=' . $bucket_size . ' ' .
					'limit-at=' . $queue_top_limit_at . ' ' . 
					'max-limit='. $queue_max_limit . ' ' . 
					'name=' . $queue_top_name . ' ' . 
					'parent=' . $queue_top_parent . ' ' .
					'queue=' . $queue_type;
			echo "$output\n";

			foreach($top_queue['Sub Priority'] as $sub_id=>$sub_queue){

				$queue_sub_name = '"' . $interface . '-' . $sub_id . '-' . $sub_queue['name'] . '"';
				$queue_sub_parent = '"' . $interface . '-' . $top_id . '-' . $top_queue['Name'] . '"';
				$queue_sub_packet_mark = 'dscp_' . $sub_queue['dscp'];

				$output =  '/queue tree add ' . 
						'bucket-size=' . $bucket_size . ' ' . 
						'max-limit=' . $queue_max_limit . ' ' . 
						'name=' . $queue_sub_name . ' ' . 
						'parent=' . $queue_sub_parent . ' ' . 
						'priority=' . $sub_id . ' ' . 
						'queue=' . $queue_type . ' ' . 
						'packet-mark=' . $queue_sub_packet_mark;

				echo "$output\n";

				if($sub_queue['dscp'] == 0){
					
					$queue_sub_name = '"' . $interface . '-' . $sub_id . '-no-mark' . $sub_queue['name'] . '"';
					$queue_sub_packet_mark = 'no-mark';
					
					$output = '/queue tree add ' . 
							'bucket-size=' . $bucket_size . ' ' . 
							'max-limit=' . $queue_max_limit . ' ' .
							'name=' . $queue_sub_packet_mark . ' ' . 
							'parent=' . $queue_sub_parent . ' ' .
							'priority=' . $sub_id . ' ' . 
							'queue=' . $queue_type . ' ' .
							'packet-mark=' . $queue_sub_packet_mark;
					echo "$output\n";
				}
			}
		}
	}
?>
