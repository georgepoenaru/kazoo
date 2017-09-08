-module(kz_device_test).

-include_lib("eunit/include/eunit.hrl").

-define(MASTER_ACCOUNT, <<"account0000000000000000000000001">>).
-define(DEVICE_1_ID, <<"device00000000000000000000000001">>).
-define(DEVICE_2_ID, <<"device00000000000000000000000002">>).

invalid_parameters_test_() ->
    [?_assertMatch({'error', 'invalid_parameters'}, kz_device:fetch(?MASTER_ACCOUNT, 256))].

validate_fixtures_test_() ->
    {'ok', Schema} = kz_json_schema:fload(<<"devices">>),
    {'ok', Device1} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_1_ID),
    [{"validate device fixture 1", ?_assertMatch({'ok', _}, validate(Schema, Device1))}].

auxiliary_functions_test_() ->
    {'ok', Device1} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_1_ID),
    [?_assert(kz_device:is_device(Device1))
    ,?_assertEqual(<<"device_1_username">>, kz_device:sip_username(Device1))
    ,?_assertEqual(<<"device_1_password">>, kz_device:sip_password(Device1))
    ,?_assertEqual(<<"password">>, kz_device:sip_method(Device1))
    ,?_assertEqual(<<"2600hz.local:7000">>, kz_device:sip_route(Device1))
    ,?_assertEqual(<<"10.26.20.20">>, kz_device:sip_ip(Device1))
    ,?_assertEqual(<<"device-1@4a6863.sip.2600hz.local">>, kz_device:presence_id(Device1))
    ,?_assertEqual(<<"contact">>, kz_device:sip_invite_format(Device1))
    ,?_assertEqual(<<"Test Device 1">>, kz_device:name(Device1))
    ,?_assertEqual(<<"00:15:65:27:C9:8E">>, kz_device:mac_address(Device1))
    ,?_assertEqual(<<"fr-fr">>, kz_device:language(Device1))
    ,?_assertEqual(<<"sip_device">>, kz_device:device_type(Device1))
    ,?_assertEqual(<<"user0000000000000000000000000001">>, kz_device:owner_id(Device1))
    ,?_assertEqual(<<"America/New_York">>, kz_device:timezone(Device1)) 
    ,?_assert(kz_device:enabled(Device1))
    ].

custom_sip_headers_test_() ->
    {'ok', TestDevice} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_1_ID),
    [?_assertEqual(<<"foo">>, kz_device:custom_sip_header_inbound(TestDevice, <<"x-device-header">>))
    ,?_assertEqual(<<"bar">>, kz_device:custom_sip_header_outbound(TestDevice, <<"x-outbound-header">>))
    ,?_assertEqual(<<"Hz">>, kz_device:custom_sip_header_inbound(TestDevice, <<"x-legacy-header">>))
    ,?_assertEqual('undefined', kz_device:custom_sip_header_inbound(TestDevice, <<"x-missing-header">>))
    ,?_assertEqual('undefined', kz_device:custom_sip_header_outbound(TestDevice, <<"x-missing-header">>))
    ].

no_legacy_sip_headers_test_() ->
    {'ok', Device} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_1_ID),
    InCSH = kz_json:from_list([{<<"x-device-header">>, <<"foo">>}]),
    OutCSH = kz_json:from_list([{<<"x-outbound-header">>, <<"bar">>}]),
    CSH = kz_json:from_list([{<<"in">>, InCSH}
                            ,{<<"out">>, OutCSH}
                            ]
                           ),
	TestDevice = kz_device:set_custom_sip_headers(Device, CSH),
    [?_assertEqual(<<"foo">>, kz_device:custom_sip_header_inbound(TestDevice, <<"x-device-header">>))
    ,?_assertEqual(<<"bar">>, kz_device:custom_sip_header_outbound(TestDevice, <<"x-outbound-header">>))
    ,?_assertEqual('undefined', kz_device:custom_sip_header_inbound(TestDevice, <<"x-legacy-header">>))
    ,?_assertEqual('undefined', kz_device:custom_sip_header_inbound(TestDevice, <<"x-missing-header">>))
    ,?_assertEqual('undefined', kz_device:custom_sip_header_outbound(TestDevice, <<"x-missing-header">>))
    ].

no_inbound_sip_headers_test_() ->
    {'ok', Device} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_1_ID),
    LegacyCSH = kz_json:from_list([{<<"x-device-header">>, <<"baz">>}
                                  ,{<<"x-legacy-header">>, <<"Hz">>}
                                  ]),
    OutCSH = kz_json:from_list([{<<"x-outbound-header">>, <<"bar">>}]),
    CSH = kz_json:set_value(<<"out">>, OutCSH, LegacyCSH),
    TestDevice = kz_device:set_custom_sip_headers(Device, CSH),
    [?_assertEqual(<<"baz">>, kz_device:custom_sip_header_inbound(TestDevice, <<"x-device-header">>))
    ,?_assertEqual(<<"bar">>, kz_device:custom_sip_header_outbound(TestDevice, <<"x-outbound-header">>))
    ,?_assertEqual(<<"Hz">>, kz_device:custom_sip_header_inbound(TestDevice, <<"x-legacy-header">>))
    ,?_assertEqual('undefined', kz_device:custom_sip_header_inbound(TestDevice, <<"x-missing-header">>))
    ,?_assertEqual('undefined', kz_device:custom_sip_header_outbound(TestDevice, <<"x-missing-header">>))
    ].

no_outbound_custom_sip_headers_test_() ->
    {'ok', Device} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_1_ID),
    InCSH = kz_json:from_list([{<<"x-device-header">>, <<"foo">>}]),
    LegacyCSH = kz_json:from_list([{<<"x-device-header">>, <<"baz">>}
                                  ,{<<"x-legacy-header">>, <<"Hz">>}
                                  ]),

    CSH = kz_json:set_values([{<<"in">>, InCSH}
                             ]
                            ,LegacyCSH
                            ),
    TestDevice = kz_device:set_custom_sip_headers(Device, CSH),
    [?_assertEqual(<<"foo">>, kz_device:custom_sip_header_inbound(TestDevice, <<"x-device-header">>))
    ,?_assertEqual('undefined', kz_device:custom_sip_header_outbound(TestDevice, <<"x-outbound-header">>))
    ,?_assertEqual(<<"Hz">>, kz_device:custom_sip_header_inbound(TestDevice, <<"x-legacy-header">>))
    ,?_assertEqual('undefined', kz_device:custom_sip_header_inbound(TestDevice, <<"x-missing-header">>))
    ,?_assertEqual('undefined', kz_device:custom_sip_header_outbound(TestDevice, <<"x-missing-header">>))
    ].

custom_sip_headers_schema_test_() ->
    {'ok', Device} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_1_ID),
    InCSH = kz_json:from_list([{<<"x-device-header">>, <<"foo">>}]),
    OutCSH = kz_json:from_list([{<<"x-outbound-header">>, <<"bar">>}]),
    LegacyCSH = kz_json:from_list([{<<"x-device-header">>, <<"baz">>}
                                  ,{<<"x-legacy-header">>, <<"Hz">>}
                                  ]),
    CSH = kz_json:set_values([{<<"in">>, InCSH}
                             ,{<<"out">>, OutCSH}
                             ]
                            ,LegacyCSH
                            ),
    TestDevice = kz_device:set_custom_sip_headers(Device, CSH),
    {'ok', Schema} = kz_json_schema:fload(<<"devices">>),

    [{"valid schema check", ?_assertMatch({'ok', _}, validate(Schema, TestDevice))}
    ,{"invalid header value check", ?_assertMatch({'error', _}, validate(Schema, kz_json:set_value([<<"sip">>, <<"custom_sip_headers">>, <<"out">>, <<"bad">>], kz_json:new(), TestDevice)))}
    ,{"invalid header check", ?_assertMatch({'error', _}, validate(Schema, kz_json:set_value([<<"sip">>, <<"custom_sip_headers">>, <<"out">>, <<"bad@header">>], <<"ok">>, TestDevice)))}
    ].

outbound_flags_test_() ->
    {'ok', OldData} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_1_ID),
    ExpectedOldData = kz_json:decode("{\"static\": [\"device_old_static_flag\"]}"),

    {'ok', NewData} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_2_ID),
    ExpectedNewData = kz_json:decode("{\"dynamic\": [\"not_exported\", \"from_realm\"], \"static\": [\"device_new_static_flag\"]}"),

    MissingData = kz_json:delete_key(<<"outbound_flags">>, NewData),

    UpdatedOldData = kz_device:set_outbound_flags(MissingData, [<<"device_old_static_flag">>]),
    Update = kz_json:from_list([{<<"dynamic">>, [<<"not_exported">>, <<"from_realm">>]}, {<<"static">>, [<<"device_new_static_flag">>]}]),
    UpdatedNewData = kz_device:set_outbound_flags(MissingData, Update),

    StaticUpdate = [<<"device_new_static_flag">>],
    DynamicUpdate = [<<"not_exported">>, <<"from_realm">>],
    UpdateBothNewData = kz_device:set_outbound_flags(MissingData, StaticUpdate, DynamicUpdate),

    [{"verify get for deprecated format"
     ,?_assertEqual(ExpectedOldData, kz_device:outbound_flags(OldData))
     }
    ,{"verify get for new format"
     ,?_assertEqual(ExpectedNewData, kz_device:outbound_flags(NewData))
     }
    ,{"verify get for missing data"
     ,?_assertEqual(kz_json:new(), kz_device:outbound_flags(MissingData))
     }
    ,{"verify deprecated update"
     ,?_assertEqual(ExpectedOldData, kz_device:outbound_flags(UpdatedOldData))
     }
    ,{"verify new update"
     ,?_assertEqual(ExpectedNewData, kz_device:outbound_flags(UpdatedNewData))
     }
    ,{"verify both update"
     ,?_assertEqual(ExpectedNewData, kz_device:outbound_flags(UpdateBothNewData))
     }
    ,{"verify both update with undefined static"
     ,?_assertEqual([], kz_device:outbound_static_flags(kz_device:set_outbound_flags(NewData, 'undefined', [<<"unrelated_flag">>])))
     }
    ,{"verify both update with undefined dynamic"
     ,?_assertEqual([], kz_device:outbound_dynamic_flags(kz_device:set_outbound_flags(NewData, [<<"unrelated_flag">>], 'undefined')))
     }
    ].

outbound_flags_static_test_() ->
    {'ok', OldData} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_1_ID),
    UpdatedOldData = kz_json:get_value(<<"outbound_flags">>, kz_device:set_outbound_static_flags(OldData, [<<"updated_flag">>])),
    ExpectedOldUpdate = kz_json:decode("{\"static\": [\"updated_flag\"]}"),

    {'ok', NewData} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_2_ID),
    UpdatedNewData = kz_json:get_value(<<"outbound_flags">>, kz_device:set_outbound_static_flags(NewData, [<<"updated_flag">>])),
    ExpectedNewUpdate = kz_json:decode("{\"dynamic\": [\"not_exported\", \"from_realm\"], \"static\": [\"updated_flag\"]}"),

    [{"verify get for deprecated format"
     ,?_assertEqual([<<"device_old_static_flag">>], kz_device:outbound_static_flags(OldData))
     }
    ,{"verify get for new format"
     ,?_assertEqual([<<"device_new_static_flag">>], kz_device:outbound_static_flags(NewData))
     }
    ,{"verify set with old format converts to new"
     ,?_assertEqual(ExpectedOldUpdate, UpdatedOldData)
     }
    ,{"verify set with new format"
     ,?_assertEqual(ExpectedNewUpdate, UpdatedNewData)
     }
    ].

outbound_dynamic_flags_test_() ->
    {'ok', OldData} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_1_ID),
    UpdatedOldData = kz_json:get_value(<<"outbound_flags">>, kz_device:set_outbound_dynamic_flags(OldData, [<<"updated_flag">>])),
    ExpectedOldUpdate = kz_json:decode("{\"static\": [\"device_old_static_flag\"], \"dynamic\": [\"updated_flag\"]}"),

    {'ok', NewData} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_2_ID),
    UpdatedNewData = kz_json:get_value(<<"outbound_flags">>, kz_device:set_outbound_dynamic_flags(NewData, [<<"updated_flag">>])),
    ExpectedNewUpdate = kz_json:decode("{\"dynamic\": [\"updated_flag\"], \"static\": [\"device_new_static_flag\"]}"),
    [{"verify get for deprecated format"
     ,?_assertEqual([], kz_device:outbound_dynamic_flags(OldData))
     }
    ,{"verify get for new format"
     ,?_assertEqual([<<"not_exported">>, <<"from_realm">>], kz_device:outbound_dynamic_flags(NewData))
     }
    ,{"verify set with old format converts to new"
     ,?_assertEqual(ExpectedOldUpdate, UpdatedOldData)
     }
    ,{"verify set with new format"
     ,?_assertEqual(ExpectedNewUpdate, UpdatedNewData)
     }
    ].

device_param_setting_test_() ->
    {'ok', Device} = kz_device:fetch(?MASTER_ACCOUNT, ?DEVICE_1_ID),

    Device1 = kz_device:set_sip_username(Device, <<"rick_and_morty">>),
    Device2 = kz_device:set_sip_password(Device, <<"birdperson">>),
    Device3 = kz_device:set_sip_method(Device, <<"OAuth">>),
    Device4 = kz_device:set_sip_route(Device, <<"2600hz.local:8888">>),
    Device5 = kz_device:set_sip_ip(Device, <<"10.26.0.100">>),
    Device6 = kz_device:set_presence_id(Device, <<"rick-1@4a6812.sip.2600hz.local">>),
    Device7 = kz_device:set_sip_invite_format(Device, <<"fax">>),
    Device8 = kz_device:set_name(Device, <<"Rick Sanchez">>),
    Device9 = kz_device:set_mac_address(Device, <<"00:14:65:26:C9:8Z">>),
    Device10 = kz_device:set_language(Device, <<"us-en">>),
    Device11 = kz_device:set_device_type(Device, <<"fax_machine">>),
    Device12 = kz_device:set_owner_id(Device, <<"user0000000000000000000000000002">>),
    Device13 = kz_device:set_enabled(Device, 'false'),	

    [?_assertEqual(<<"rick_and_morty">>, kz_device:sip_username(Device1))
    ,?_assertEqual(<<"birdperson">>, kz_device:sip_password(Device2))
    ,?_assertEqual(<<"OAuth">>, kz_device:sip_method(Device3))
    ,?_assertEqual(<<"2600hz.local:8888">>, kz_device:sip_route(Device4))
    ,?_assertEqual(<<"10.26.0.100">>, kz_device:sip_ip(Device5))
    ,?_assertEqual(<<"rick-1@4a6812.sip.2600hz.local">>, kz_device:presence_id(Device6))
    ,?_assertEqual(<<"fax">>, kz_device:sip_invite_format(Device7))
    ,?_assertEqual(<<"Rick Sanchez">>, kz_device:name(Device8))
    ,?_assertEqual(<<"00:14:65:26:C9:8Z">>, kz_device:mac_address(Device9))
    ,?_assertEqual(<<"us-en">>, kz_device:language(Device10))
    ,?_assertEqual(<<"fax_machine">>, kz_device:device_type(Device11))
    ,?_assertEqual(<<"user0000000000000000000000000002">>, kz_device:owner_id(Device12))
    ,?_assertNot(kz_device:enabled(Device13))
    ].	
			
validate(Schema, Device) ->
    kz_json_schema:validate(Schema
                           ,Device
                           ,[{'schema_loader_fun', fun kz_json_schema:fload/1}]
                           ).
