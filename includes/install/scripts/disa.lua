--
--	FusionPBX
--	Version: MPL 1.1
--
--	The contents of this file are subject to the Mozilla Public License Version
--	1.1 (the "License"); you may not use this file except in compliance with
--	the License. You may obtain a copy of the License at
--	http://www.mozilla.org/MPL/
--
--	Software distributed under the License is distributed on an "AS IS" basis,
--	WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
--	for the specific language governing rights and limitations under the
--	License.
--
--	The Original Code is FusionPBX
--
--	The Initial Developer of the Original Code is
--	Mark J Crane <markjcrane@fusionpbx.com>
--	Copyright (C) 2010
--	the Initial Developer. All Rights Reserved.
--
--	Contributor(s):
--	Mark J Crane <markjcrane@fusionpbx.com>

predefined_destination = "";
max_tries = "3";
digit_timeout = "5000";

function trim (s)
	return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function explode ( seperator, str ) 
	local pos, arr = 0, {}
	for st, sp in function() return string.find( str, seperator, pos, true ) end do -- for each divider found
		table.insert( arr, string.sub( str, pos, st-1 ) ) -- attach chars left of current divider
		pos = sp + 1 -- jump past current divider
	end
	table.insert( arr, string.sub( str, pos ) ) -- attach chars right of last divider
	return arr
end

if ( session:ready() ) then
	session:answer( );
	pin_number = session:getVariable("pin_number");
	sounds_dir = session:getVariable("sounds_dir");
	caller_id_name = session:getVariable("caller_id_name");
	caller_id_number = session:getVariable("caller_id_number");
	predefined_destination = session:getVariable("predefined_destination");
	digit_min_length = session:getVariable("digit_min_length");
	digit_max_length = session:getVariable("digit_max_length");
	gateway = session:getVariable("gateway");
	context = session:getVariable("context");

	--set the sounds path for the language, dialect and voice
		default_language = session:getVariable("default_language");
		default_dialect = session:getVariable("default_dialect");
		default_voice = session:getVariable("default_voice");
		if (not default_language) then default_language = 'en'; end
		if (not default_dialect) then default_dialect = 'us'; end
		if (not default_voice) then default_voice = 'callie'; end

	--set defaults
		if (digit_min_length) then
			--do nothing
		else
			digit_min_length = "2";
		end

		if (digit_max_length) then
			--do nothing
		else
			digit_max_length = "11";
		end

	--if the pin number is provided then require it
		if (pin_number) then
			min_digits = string.len(pin_number);
			max_digits = string.len(pin_number)+1;
			digits = session:playAndGetDigits(min_digits, max_digits, max_tries, digit_timeout, "#", sounds_dir.."/"..default_language.."/"..default_dialect.."/"..default_voice.."/custom/please_enter_the_pin_number.wav", "", "\\d+");
			if (digits == pin_number) then
				--pin is correct
			else
				session:streamFile(sounds_dir.."/"..default_language.."/"..default_dialect.."/"..default_voice.."/custom/your_pin_number_is_incorect_goodbye.wav");
				session:hangup("NORMAL_CLEARING");
				return;
			end
		end

	--if a predefined_destination is provided then set the number to the predefined_destination
		if (predefined_destination) then
			destination_number = predefined_destination;
		else
			dtmf = ""; --clear dtmf digits to prepare for next dtmf request
			destination_number = session:playAndGetDigits(digit_min_length, digit_max_length, max_tries, digit_timeout, "#", sounds_dir.."/"..default_language.."/"..default_dialect.."/"..default_voice.."/custom/please_enter_the_phone_number.wav", "", "\\d+");
			--if (string.len(destination_number) == 10) then destination_number = "1"..destination_number; end
		end

	--set the caller id anme and number
		if (string.len(destination_number) < 7) then
			if (caller_id_name) then
				--caller id name provided do nothing
			else
				caller_id_number = session:getVariable("effective_caller_id_name");
			end
			if (caller_id_number) then
				--caller id number provided do nothing
			else
				caller_id_number = session:getVariable("effective_caller_id_number");
			end
		else 
			if (caller_id_name) then
				--caller id name provided do nothing
			else
				caller_id_number = session:getVariable("outbound_caller_id_name");
			end
			if (caller_id_number) then
				--caller id number provided do nothing
			else
				caller_id_number = session:getVariable("outbound_caller_id_number");
			end
		end

	--transfer or bridge the call
		if (string.len(destination_number) < 7) then
			--local call
			session:execute("transfer", destination_number .. " XML " .. context);
		else
			--remote call
			if (gateway) then
				gateway_table = explode(",",gateway);
				for index,value in pairs(gateway_table) do
					session:execute("bridge", "{continue_on_fail=true,hangup_after_bridge=true,effective_caller_id_name="..caller_id_name..",effective_caller_id_number="..caller_id_number.."}sofia/gateway/"..value.."/"..destination_number);
				end
			else
				session:execute("set", "effective_caller_id_name="..caller_id_name);
				session:execute("set", "effective_caller_id_number="..caller_id_number);
				session:execute("transfer", destination_number .. " XML " .. context);
			end
		end

		--alternate method
			--local session2 = freeswitch.Session("{ignore_early_media=true}sofia/gateway/flowroute.com/"..destination_number);
			--t1 = os.date('*t');
			--call_start_time = os.time(t1);
			--freeswitch.bridge(session, session2);
end

--function HangupHook(s, status, arg)
	--session:execute("info", "");
	--freeswitch.consoleLog("NOTICE", "HangupHook: " .. status .. "\n");
--end
--session:setHangupHook("HangupHook", "");
