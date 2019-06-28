:global "telstra_wan_interface" ether1
:global "telstra_wan_speed" 100

:local "queue_stage" ($"telstra_wan_interface")

#MATH
:local "overhead_percent" 98

:local "bucket_size" 4
:local "bucket_size_string" "0.004"

:local "queue_time_msec" 5
:local "bucket_size_mesc" 0
:local "queue_limit" 1000000
:local "max-limit" (($"telstra_wan_speed" * 10000)* 98)

#98percent
:local "level1_percent" 6
:local "level2_percent" 6
:local "level3_percent" 30
:local "level4_percent" 30
:local "level5_percent" 10
:local "level6_percent" 10
:local "level7_percent" 4
:local "level8_percent" 2

:local "top_prioirty_names" ([:toarray {"1"="Network Control" ; 
										"2"="Routing" ;
										"3"="Critical" ;
										"4"="Flash Override" ;
										"5"="Flash" ;
										"6"="Immediate" ;
										"7"="Priority" ;
										"8"="Best Effort"}])

:local "top_prioirty_limit_at" ([:toarray { "1"=($"level1_percent" * $"telstra_wan_speed" * 10000);
											"2"=($"level2_percent" * $"telstra_wan_speed" * 10000);
											"3"=($"level3_percent" * $"telstra_wan_speed" * 10000);
											"4"=($"level4_percent" * $"telstra_wan_speed" * 10000);
											"5"=($"level5_percent" * $"telstra_wan_speed" * 10000);
											"6"=($"level6_percent" * $"telstra_wan_speed" * 10000);
											"7"=($"level7_percent" * $"telstra_wan_speed" * 10000);
											"8"=($"level8_percent" * $"telstra_wan_speed" * 10000);
							}])

#Mikrotik scripting doesn't do decimals so I have to be creative.
:set "bucket_size_mesc" ($"bucket_size" * 1000 * 1000);
:set "overhead_percent" ($"overhead_percent" * 1000);
:set "queue_time_msec" ($"queue_time_msec" * 1000 * 100);
:set "wan_speed" ($"telstra_wan_speed" * 1000 * 100);

:set "bucket_size" ($"bucket_size" * 100);
:set "queue_time_msec" ($"queue_time_msec" * 100);
:set "bucket_size_mesc" ($"bucket_size" * 100);

:set "queue_limit" ($"queue_limit" * $"overhead_percent");
:set "queue_limit" ($"queue_limit" * $"bucket_size");
:set "queue_limit" (($"queue_limit") / $"bucket_size_mesc");
:set "queue_limit" ($"queue_limit" * $"queue_time_msec");
:set "queue_limit" (($"queue_limit") / 10000000000000);
:set "queue_limit" ($"queue_limit" * $"telstra_wan_speed");

:local "queue_namer" ("Telstra-" . [:tostr $"telstra_wan_speed"]  . "M");

:do {
	/queue type add kind=bfifo name=$"queue_namer" bfifo-limit=$"queue_limit"
	:log info ("Success: Adding " . $"queue_namer");
} on-error={ :log info ("Failed:  Adding ". $"queue_namer");};

:local "dscps" ([:toarray {
						"0"=[:toarray { "priority"=8 ; "name"="CS0" ; "mark"="dscp_0" }] ;
						"00"=[:toarray { "priority"=8 ; "name"="no-mark" ; "mark"="no-mark" }] ;
						"56"=[:toarray { "priority"=8 ; "name"="CS7" ; "mark"="dscp_56" }] ;
						"48"=[:toarray { "priority"=8 ; "name"="CS6" ; "mark"="dscp_48" }] ;
						"46"=[:toarray { "priority"=2 ; "name"="CS5 Expedited Forwarding (VoIP)" ; "mark"="dscp_46" }] ;
						"40"=[:toarray { "priority"=8 ; "name"="CS5" ; "mark"="dscp_40" }] ;
						"38"=[:toarray { "priority"=2 ; "name"="CS4 AF43 (High)" ; "mark"="dscp_38" }] ;
						"36"=[:toarray { "priority"=4 ; "name"="CS4 AF42 (Medium)" ; "mark"="dscp_36" }] ;
						"34"=[:toarray { "priority"=6 ; "name"="CS4 AF41 (Low)" ; "mark"="dscp_34" }] ;
						"32"=[:toarray { "priority"=8 ; "name"="CS4" ; "mark"="dscp_32" }] ;
						"30"=[:toarray { "priority"=2 ; "name"="CS3 AF33 (High)" ; "mark"="dscp_30" }] ;
						"28"=[:toarray { "priority"=4 ; "name"="CS3 AF32 (Medium)" ; "mark"="dscp_28" }] ;
						"26"=[:toarray { "priority"=6 ; "name"="CS3 AF31 (Low)" ; "mark"="dscp_26" }] ;
						"24"=[:toarray { "priority"=8 ; "name"="CS3" ; "mark"="dscp_24" }] ;
						"22"=[:toarray { "priority"=2 ; "name"="CS2 AF23 (High)" ; "mark"="dscp_22" }] ;
						"20"=[:toarray { "priority"=4 ; "name"="CS2 AF22 (Medium)" ; "mark"="dscp_20" }] ;
						"18"=[:toarray { "priority"=6 ; "name"="CS2 AF21 (Low)" ; "mark"="dscp_18" }] ;
						"16"=[:toarray { "priority"=8 ; "name"="CS2" ; "mark"="dscp_16" }] ;
						"14"=[:toarray { "priority"=2 ; "name"="CS1 AF13 (High)" ; "mark"="dscp_14" }] ;
						"12"=[:toarray { "priority"=4 ; "name"="CS1 AF12 (Medium)" ; "mark"="dscp_12" }] ;
						"10"=[:toarray { "priority"=6 ; "name"="CS1 AF11 (Low)" ; "mark"="dscp_10"}] ;
						"8"=[:toarray { "priority"=8 ; "name"="CS1" ; "mark"="dscp_8" }] 
				}])
	
:local "top_prioirty_names" ([:toarray { "1"="Network Control" ; 
										"2"="Routing" ;
										"3"="Critical" ;
										"4"="Flash Override" ;
										"5"="Flash" ;
										"6"="Immediate" ;
										"7"="Priority" ;
										"8"="Best Effort"
							}])

:local "dscp_mapping" ([:toarray { 
								"1"=[:toarray { "56" } ] ;
								"2"=[:toarray { "48" } ] ;
								"3"=[:toarray { "46" ; "40" } ] ;
								"4"=[:toarray { "38" ; "36" ; "34" ; "32" } ] ;
								"5"=[:toarray { "30" ; "28" ; "26" ; "24" } ] ;
								"6"=[:toarray { "22" ; "20" ; "18" ; "16" } ] ;
								"7"=[:toarray { "14" ; "12" ; "10" ; "8" } ] ;
								"8"=[:toarray { "0" ; "00" } ]
						}])

:foreach "dscp_key","dscp_values" in=$"dscps" do={
	:do {
		:local "dscp_name" ("dscp_" . $"dscp_key")
		:if ([/ip firewall mangle find comment=($"dscp_name")] = "") do={
			:do {
				/ip firewall mangle add action=mark-packet chain=postrouting comment=$"dscp_name" dscp=$"dscp_key" new-packet-mark=$"dscp_name" passthrough=no
				:log info ("Success: Adding mangle" . $"dscp_name");
			} on-error={ :log info ("Failed: Adding mangle " . $"dscp_name") ; };
		} else={
			:log info ("Success: Exisitng mangle " . $"dscp_name");
		}

	} on-error={ :log info ("Failed: Adding Firewall Managles");};
}

:local "top_name" ( $"telstra_wan_speed" . "M-" . $"telstra_wan_interface" . "-out")
:do {
	/queue tree add bucket-size=$"bucket_size_string" max-limit=$"max-limit" name=$"top_name" parent=$"telstra_wan_interface" queue=$"queue_namer"
} on-error={ :log info ("Failed: Adding queue " . $"top_name") ; };

:foreach "top_prioirty_name_key","top_prioirty_name" in=$"top_prioirty_names" do={
	:local "current_limit" ( $"top_prioirty_limit_at"->$"top_prioirty_name_key")
	:local "current_priority" ( $"top_prioirty_name_key")
	:local "current_name" ( $"telstra_wan_speed" . "M-" . $"telstra_wan_interface" . "-" . $"current_priority" . "-" . $"top_prioirty_name")
	:do {
		/queue tree add bucket-size=$"bucket_size_string" max-limit=$"max-limit" name=$"current_name" parent=$"top_name" queue=$"queue_namer" limit-at=$"current_limit" priority=$"current_priority"
	} on-error={ :log info ("Failed: Adding queue " . $"current_name") ; };
	:foreach "sub_dscps_item" in=($"dscp_mapping"->$"top_prioirty_name_key") do={
		:local "sub_dscps_values" ($"dscps"->$"sub_dscps_item")
		:local "current_dscp_values" ($"dscps"->$"sub_dscps_item");
		:local "queue_stage" ($"current_name")
		:local "current_priority" ($"current_dscp_values"->"priority")
		:local "current_mark" ($"current_dscp_values"->"mark")
		:local "current_name" ( $"telstra_wan_speed" . "M-" . $"telstra_wan_interface" . "-" . $"current_priority" . "-" . ($"current_dscp_values"->"name"))
		:do {
			/queue tree add bucket-size=$"bucket_size_string" max-limit=$"max-limit" name=$"current_name" parent=$"queue_stage" priority=$"current_priority" queue=$"queue_namer" packet-mark=$"current_mark"
		} on-error={ :log info ("Failed: Adding queue " . $"current_name") ; };
	}
}

