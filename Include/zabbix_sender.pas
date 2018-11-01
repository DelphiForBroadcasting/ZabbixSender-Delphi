(*
** Zabbix
** Copyright (C) 2001-2018 Zabbix SIA
**
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software
** Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
**)
 
(**
* Conversion to Pascal Copyright 2018 (c) Oleksandr Nazaruk <mail@freehand.com.ua>
*
*)


unit zabbix_sender;

{$MINENUMSIZE 4}

interface

uses
  System.SysUtils;

const
  _PU = '';
  {$IF Defined(MSWINDOWS)}
    {$IFDEF CPUX64}
      link_zabbix_sender = 'zabbix_sender.dll';
    {$ENDIF}
    {$IFDEF CPUX86}
      link_zabbix_sender = 'zabbix_sender.dll';
    {$ENDIF}
  {$ENDIF}

type
  PZabbix_sender_value = ^TZabbix_sender_value;
  TZabbix_sender_value = packed record
    (* host name, must match the name of target host in Zabbix *)
    host  : MarshaledAString;
    (* the item key *)
    key   : MarshaledAString;
    (* the item value *)
    value : MarshaledAString;
  end;

  PZabbix_sender_info = ^TZabbix_sender_info;
  TZabbix_sender_info = packed record
	  (* number of total values processed *)
	  total : Integer;
	  (* number of failed values *)
	  failed: Integer;
	  (* time in seconds the server spent processing the sent values *)
		time_spent: Double;
  end;


(******************************************************************************
 *                                                                            *
 * Function: zabbix_sender_send_values                                        *
 *                                                                            *
 * Purpose: send values to Zabbix server/proxy                                *
 *                                                                            *
 * Parameters: address   - [IN] zabbix server/proxy address                   *
 *             port      - [IN] zabbix server/proxy trapper port              *
 *             source    - [IN] source IP, optional - can be NULL             *
 *             values    - [IN] array of values to send                       *
 *             count     - [IN] number of items in values array               *
 *             result    - [OUT] the server response/error message, optional  *
 *                         If result is specified it must always be freed     *
 *                         afterwards with zabbix_sender_free_result()        *
 *                         function.                                          *
 *                                                                            *
 * Return value: 0 - the values were sent successfully, result contains       *
 *                         server response                                    *
 *               -1 - an error occurred, result contains error message        *
 *                                                                            *
 ******************************************************************************)
function zabbix_sender_send_values(const address: MarshaledAString; port: Word; const source: MarshaledAString;
		const  values: PZabbix_sender_value; count: Integer; var result: MarshaledAString): Integer;
 cdecl; external link_zabbix_sender name _PU + 'zabbix_sender_send_values';

(******************************************************************************
 *                                                                            *
 * Function: zabbix_sender_parse_result                                       *
 *                                                                            *
 * Purpose: parses the result returned from zabbix_sender_send_values()       *
 *          function                                                          *
 *                                                                            *
 * Parameters: result   - [IN] result to parse                                *
 *             response - [OUT] the operation response                        *
 *                           0 - operation was successful                     *
 *                          -1 - operation failed                             *
 *             info     - [OUT] the detailed information about processed      *
 *                        values, optional                                    *
 *                                                                            *
 * Return value:  0 - the result was parsed successfully                      *
 *               -1 - the result parsing failed                               *
 *                                                                            *
 * Comments: If info parameter was specified but the function failed to parse *
 *           the result info field, then info->total is set to -1.            *
 *                                                                            *
 ******************************************************************************)
function zabbix_sender_parse_result(const result: MarshaledAString; var response: Integer; info: PZabbix_sender_info): Integer;
 cdecl; external link_zabbix_sender name _PU + 'zabbix_sender_parse_result';
(******************************************************************************
 *                                                                            *
 * Function: zabbix_sender_free_result                                        *
 *                                                                            *
 * Purpose: free data allocated by zabbix_sender_send_values() function       *
 *                                                                            *
 * Parameters: ptr   - [IN] pointer to the data to free                       *
 *                                                                            *
 ******************************************************************************)
procedure zabbix_sender_free_result(ptr: Pointer);
 cdecl; external link_zabbix_sender name _PU + 'zabbix_sender_free_result';

implementation

end.
